-- ============================================================
-- SECURITY HARDENING (2026-04-09)
-- ============================================================

-- CRIT-1: photos INSERT RLS lacked couple_id membership check.
-- A user who knows another couple's UUID could inject photos into that couple.
drop policy if exists "Users can insert their own photos" on public.photos;
create policy "Users can insert their own photos"
  on public.photos for insert
  with check (
    auth.uid() = user_id
    and couple_id in (
      select id from public.couples
      where user_id_1 = auth.uid() or user_id_2 = auth.uid()
    )
  );

-- CRIT-2: reactions INSERT lacked target ownership check.
-- A user could react to any UUID regardless of couple membership.
drop policy if exists "Users can insert their own reactions" on public.reactions;
create policy "Users can insert their own reactions"
  on public.reactions for insert
  with check (
    auth.uid() = user_id
    and (
      (
        target_type = 'photo'
        and target_id in (
          select id from public.photos
          where couple_id in (
            select id from public.couples
            where user_id_1 = auth.uid() or user_id_2 = auth.uid()
          )
        )
      )
      or
      (
        target_type = 'prompt_reply'
        and target_id in (
          select pr.id
          from public.prompt_replies pr
          join public.prompts p on pr.prompt_id = p.id
          where p.couple_id in (
            select id from public.couples
            where user_id_1 = auth.uid() or user_id_2 = auth.uid()
          )
        )
      )
    )
  );

-- HIGH-3: "Anyone can join pending couple" policy did not enforce
-- invite_code_expires_at, allowing expired codes to be used via direct API calls.
drop policy if exists "Anyone can join pending couple" on public.couples;
create policy "Anyone can join pending couple"
  on public.couples for update
  using (
    status = 'pending'
    and user_id_2 is null
    and (invite_code_expires_at is null or invite_code_expires_at > now())
  )
  with check (auth.uid() = user_id_2);
