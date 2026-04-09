import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
const SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
const FCM_SERVICE_ACCOUNT_KEY = Deno.env.get("FCM_SERVICE_ACCOUNT_KEY")!;

const supabase = createClient(SUPABASE_URL, SERVICE_ROLE_KEY, {
  auth: { persistSession: false },
});

interface WebhookPayload {
  type: "INSERT" | "UPDATE" | "DELETE";
  table: string;
  schema: string;
  record: Record<string, unknown>;
  old_record: Record<string, unknown> | null;
}

Deno.serve(async (req: Request) => {
  try {
    const payload = (await req.json()) as WebhookPayload;

    if (payload.type !== "INSERT") {
      return new Response("Ignored: not INSERT", { status: 200 });
    }

    const uploaderUserId = payload.record.user_id as string | undefined;
    const coupleId = payload.record.couple_id as string | undefined;

    if (!uploaderUserId || !coupleId) {
      return new Response("Missing user_id or couple_id", { status: 400 });
    }

    // 1. Get couple to find partner
    const { data: couple, error: coupleError } = await supabase
      .from("couples")
      .select("user_id_1, user_id_2")
      .eq("id", coupleId)
      .single();

    if (coupleError || !couple) {
      console.error("Couple not found:", coupleError);
      return new Response("Couple not found", { status: 404 });
    }

    const partnerUserId =
      couple.user_id_1 === uploaderUserId
        ? couple.user_id_2
        : couple.user_id_1;

    if (!partnerUserId) {
      return new Response("No partner in couple", { status: 200 });
    }

    // 2. Get uploader display name
    const { data: uploader } = await supabase
      .from("users")
      .select("display_name")
      .eq("id", uploaderUserId)
      .single();

    const displayName = (uploader?.display_name as string) ?? "Your partner";

    // 3. Get partner's FCM tokens
    const { data: tokens, error: tokenError } = await supabase
      .from("fcm_tokens")
      .select("token")
      .eq("user_id", partnerUserId);

    if (tokenError || !tokens || tokens.length === 0) {
      console.log("No FCM tokens for partner:", partnerUserId);
      return new Response("No tokens", { status: 200 });
    }

    // 4. Get OAuth2 access token for FCM HTTP v1
    const accessToken = await getAccessToken();
    const serviceAccount = JSON.parse(FCM_SERVICE_ACCOUNT_KEY);
    const projectId = serviceAccount.project_id as string;

    // 5. Send push to each device token
    const results = await Promise.allSettled(
      tokens.map((t: { token: string }) =>
        sendFcmMessage(accessToken, projectId, t.token, {
          title: `${displayName}이(가) 사진을 올렸어요!`,
          body: "오늘의 사진을 확인해보세요",
          data: {
            type: "photo_uploaded",
            couple_id: coupleId,
          },
        })
      )
    );

    // 6. Clean up invalid tokens
    const invalidTokens: string[] = [];
    for (let i = 0; i < results.length; i++) {
      const result = results[i];
      if (result.status === "rejected") {
        const reason = String(result.reason ?? "");
        if (reason.includes("UNREGISTERED") || reason.includes("INVALID_ARGUMENT")) {
          invalidTokens.push(tokens[i].token);
        }
      }
    }

    if (invalidTokens.length > 0) {
      await supabase
        .from("fcm_tokens")
        .delete()
        .in("token", invalidTokens);
      console.log(`Cleaned ${invalidTokens.length} invalid tokens`);
    }

    const sent = results.filter((r) => r.status === "fulfilled").length;
    return new Response(
      JSON.stringify({ sent, failed: results.length - sent }),
      { status: 200, headers: { "Content-Type": "application/json" } }
    );
  } catch (err) {
    console.error("[push-notification] error:", err);
    return new Response("Internal Server Error", { status: 500 });
  }
});

// ── FCM HTTP v1 helpers ────────────────────────────────────────

interface FcmPayload {
  title: string;
  body: string;
  data?: Record<string, string>;
}

async function sendFcmMessage(
  accessToken: string,
  projectId: string,
  deviceToken: string,
  payload: FcmPayload
): Promise<void> {
  const url = `https://fcm.googleapis.com/v1/projects/${projectId}/messages:send`;

  const res = await fetch(url, {
    method: "POST",
    headers: {
      Authorization: `Bearer ${accessToken}`,
      "Content-Type": "application/json",
    },
    body: JSON.stringify({
      message: {
        token: deviceToken,
        notification: {
          title: payload.title,
          body: payload.body,
        },
        data: payload.data ?? {},
        android: {
          priority: "high",
          notification: {
            channel_id: "codarling_default",
            click_action: "FLUTTER_NOTIFICATION_CLICK",
          },
        },
      },
    }),
  });

  if (!res.ok) {
    const errorBody = await res.text();
    throw new Error(`FCM error ${res.status}: ${errorBody}`);
  }
}

async function getAccessToken(): Promise<string> {
  const serviceAccount = JSON.parse(FCM_SERVICE_ACCOUNT_KEY);

  const now = Math.floor(Date.now() / 1000);
  const header = { alg: "RS256", typ: "JWT" };
  const claimSet = {
    iss: serviceAccount.client_email as string,
    scope: "https://www.googleapis.com/auth/firebase.messaging",
    aud: "https://oauth2.googleapis.com/token",
    iat: now,
    exp: now + 3600,
  };

  const encoder = new TextEncoder();

  const base64url = (data: Uint8Array): string => {
    let binary = "";
    for (const byte of data) binary += String.fromCharCode(byte);
    return btoa(binary)
      .replace(/\+/g, "-")
      .replace(/\//g, "_")
      .replace(/=+$/, "");
  };

  const headerB64 = base64url(encoder.encode(JSON.stringify(header)));
  const claimB64 = base64url(encoder.encode(JSON.stringify(claimSet)));
  const signInput = `${headerB64}.${claimB64}`;

  const pemContents = (serviceAccount.private_key as string)
    .replace(/-----BEGIN PRIVATE KEY-----/, "")
    .replace(/-----END PRIVATE KEY-----/, "")
    .replace(/\n/g, "");

  const binaryDer = Uint8Array.from(atob(pemContents), (c) => c.charCodeAt(0));

  const key = await crypto.subtle.importKey(
    "pkcs8",
    binaryDer,
    { name: "RSASSA-PKCS1-v1_5", hash: "SHA-256" },
    false,
    ["sign"]
  );

  const signature = await crypto.subtle.sign(
    "RSASSA-PKCS1-v1_5",
    key,
    encoder.encode(signInput)
  );

  const signatureB64 = base64url(new Uint8Array(signature));
  const jwt = `${signInput}.${signatureB64}`;

  const tokenRes = await fetch("https://oauth2.googleapis.com/token", {
    method: "POST",
    headers: { "Content-Type": "application/x-www-form-urlencoded" },
    body: `grant_type=urn:ietf:params:oauth:grant-type:jwt-bearer&assertion=${jwt}`,
  });

  if (!tokenRes.ok) {
    throw new Error(`OAuth token error: ${await tokenRes.text()}`);
  }

  const tokenData = await tokenRes.json();
  return tokenData.access_token as string;
}
