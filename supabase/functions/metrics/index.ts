import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
const SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
// METRICS_SECRET is set via `supabase secrets set METRICS_SECRET=...`
// Used by Grafana Agent as the Bearer token.
const METRICS_SECRET = Deno.env.get("METRICS_SECRET") ?? "";

// Service-role client — bypasses RLS for all queries
const supabase = createClient(SUPABASE_URL, SERVICE_ROLE_KEY, {
  auth: { persistSession: false },
});

Deno.serve(async (req: Request) => {
  // ── Auth check ─────────────────────────────────────────────────────────────
  // Accepts: Bearer <METRICS_SECRET>  (for Grafana Agent only)
  // User JWTs are intentionally rejected — this endpoint exposes aggregate
  // business data (user counts, couple stats) that should not be accessible
  // to individual app users.
  const authHeader = req.headers.get("Authorization") ?? "";
  const token = authHeader.startsWith("Bearer ") ? authHeader.slice(7) : "";

  if (!METRICS_SECRET || token !== METRICS_SECRET) {
    return text("Unauthorized", 401);
  }

  // ── Collect metrics ────────────────────────────────────────────────────────
  try {
    const lines: string[] = [];
    const now = Date.now();

    // --- Server-side business metrics ---

    const { count: userCount } = await supabase
      .from("users")
      .select("*", { count: "exact", head: true });

    const { data: coupleCounts } = await supabase.rpc("get_couple_counts");

    const today = new Date().toISOString().split("T")[0];
    const { count: photosToday } = await supabase
      .from("photos")
      .select("*", { count: "exact", head: true })
      .eq("date", today);

    const { count: totalPhotos } = await supabase
      .from("photos")
      .select("*", { count: "exact", head: true });

    // DB response time (simple health probe)
    const dbProbeStart = Date.now();
    await supabase.from("users").select("id").limit(1);
    const dbResponseMs = Date.now() - dbProbeStart;

    emit(lines, "codarling_users_total", "gauge", "Total registered users", [
      { labels: {}, value: userCount ?? 0 },
    ]);

    if (coupleCounts) {
      emit(lines, "codarling_couples_total", "gauge", "Total couples by status",
        (coupleCounts as { status: string; count: number }[]).map((r) => ({
          labels: { status: r.status },
          value: r.count,
        }))
      );
    }

    emit(lines, "codarling_photos_today", "gauge", "Photos uploaded today", [
      { labels: {}, value: photosToday ?? 0 },
    ]);

    emit(lines, "codarling_photos_total", "gauge", "Total photos all time", [
      { labels: {}, value: totalPhotos ?? 0 },
    ]);

    emit(lines, "codarling_db_response_ms", "gauge",
      "Database health probe response time (ms)", [
        { labels: {}, value: dbResponseMs },
      ]
    );

    // --- Client-side aggregated traffic (last 5 minutes) ---

    const fiveMinAgo = new Date(now - 5 * 60 * 1000).toISOString();
    const { data: rows } = await supabase
      .from("app_metrics")
      .select("table_name, operation, latency_ms, is_error")
      .gte("created_at", fiveMinAgo);

    if (rows && rows.length > 0) {
      type Group = { total: number; errors: number; latencies: number[] };
      const groups = new Map<string, Group>();

      for (const r of rows as {
        table_name: string;
        operation: string;
        latency_ms: number;
        is_error: boolean;
      }[]) {
        const key = `${r.table_name}|${r.operation}`;
        const g = groups.get(key) ?? { total: 0, errors: 0, latencies: [] };
        g.total++;
        if (r.is_error) g.errors++;
        g.latencies.push(r.latency_ms);
        groups.set(key, g);
      }

      const reqPoints: MetricPoint[] = [];
      const errPoints: MetricPoint[] = [];
      const p50Points: MetricPoint[] = [];
      const p95Points: MetricPoint[] = [];
      const p99Points: MetricPoint[] = [];

      for (const [key, g] of groups) {
        const [table, operation] = key.split("|");
        const lbl = { table, operation };
        const sorted = [...g.latencies].sort((a, b) => a - b);
        reqPoints.push({ labels: lbl, value: g.total });
        errPoints.push({ labels: lbl, value: g.errors });
        p50Points.push({ labels: { ...lbl, quantile: "0.5" },  value: pct(sorted, 50) });
        p95Points.push({ labels: { ...lbl, quantile: "0.95" }, value: pct(sorted, 95) });
        p99Points.push({ labels: { ...lbl, quantile: "0.99" }, value: pct(sorted, 99) });
      }

      emit(lines, "codarling_requests_total", "gauge",
        "API requests from Flutter clients (last 5 min)", reqPoints);
      emit(lines, "codarling_errors_total", "gauge",
        "API errors from Flutter clients (last 5 min)", errPoints);
      emit(lines, "codarling_latency_ms", "gauge",
        "API latency percentiles from Flutter clients (last 5 min, ms)",
        [...p50Points, ...p95Points, ...p99Points]);
    }

    return new Response(lines.join("\n") + "\n", {
      headers: { "Content-Type": "text/plain; version=0.0.4; charset=utf-8" },
    });
  } catch (err) {
    console.error("[metrics] error:", err);
    return text("Internal Server Error", 500);
  }
});

// ── Helpers ───────────────────────────────────────────────────────────────────

type MetricPoint = { labels: Record<string, string | number>; value: number };

function emit(
  lines: string[],
  name: string,
  type: string,
  help: string,
  points: MetricPoint[]
): void {
  lines.push(`# HELP ${name} ${help}`);
  lines.push(`# TYPE ${name} ${type}`);
  for (const p of points) {
    const lbl = Object.entries(p.labels)
      .map(([k, v]) => `${k}="${v}"`)
      .join(",");
    lines.push(lbl ? `${name}{${lbl}} ${p.value}` : `${name} ${p.value}`);
  }
  lines.push("");
}

function pct(sorted: number[], p: number): number {
  if (sorted.length === 0) return 0;
  return sorted[Math.max(0, Math.ceil((p / 100) * sorted.length) - 1)];
}

function text(body: string, status: number): Response {
  return new Response(body, { status, headers: { "Content-Type": "text/plain" } });
}
