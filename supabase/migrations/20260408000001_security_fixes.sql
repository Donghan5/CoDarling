-- ============================================================
-- SECURITY FIXES (2026-04-08)
-- ============================================================

-- FIX H-2: Reactions SELECT policy was using(true), exposing all reactions
-- to every authenticated user across all couples.
drop policy if exists "Users can read reactions on their couple's content" on public.reactions;

drop policy if exists "Couple members can read reactions" on public.reactions;
create policy "Couple members can read reactions"
  on public.reactions for select
  using (
    user_id in (
      select unnest(array[user_id_1, user_id_2]::uuid[])
      from public.couples
      where user_id_1 = auth.uid() or user_id_2 = auth.uid()
    )
  );

-- FIX M-4: Add explicit DELETE policy on photos (was blocked by default but
-- left undocumented; also needed for a future delete-photo feature).
drop policy if exists "Users can delete their own photos" on public.photos;
create policy "Users can delete their own photos"
  on public.photos for delete
  using (auth.uid() = user_id);

-- FIX M-5: Add invite code expiry column.
-- Existing pending rows get 7 days from now as a grace period.
alter table public.couples
  add column if not exists invite_code_expires_at timestamptz
  default (now() + interval '7 days');

-- FIX C-3: Storage RLS policies for the photos bucket.
-- Without these, storage.objects has no explicit policies and behaviour
-- depends on Supabase defaults, which may allow cross-couple access.

drop policy if exists "Couple members can upload photos" on storage.objects;
create policy "Couple members can upload photos"
  on storage.objects for insert
  to authenticated
  with check (
    bucket_id = 'photos'
    and (storage.foldername(name))[1] in (
      select id::text from public.couples
      where user_id_1 = auth.uid() or user_id_2 = auth.uid()
    )
    and (storage.foldername(name))[2] = auth.uid()::text
  );

drop policy if exists "Couple members can read photos" on storage.objects;
create policy "Couple members can read photos"
  on storage.objects for select
  to authenticated
  using (
    bucket_id = 'photos'
    and (storage.foldername(name))[1] in (
      select id::text from public.couples
      where user_id_1 = auth.uid() or user_id_2 = auth.uid()
    )
  );

drop policy if exists "Users can delete own photos" on storage.objects;
create policy "Users can delete own photos"
  on storage.objects for delete
  to authenticated
  using (
    bucket_id = 'photos'
    and (storage.foldername(name))[2] = auth.uid()::text
  );
