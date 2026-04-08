-- Fix: Allow any authenticated user to join a pending couple (i.e. set user_id_2)
-- The existing "Members can update couple" policy uses (user_id_1 OR user_id_2),
-- but user_id_2 is NULL when pending, so new joiners are blocked.

drop policy if exists "Members can update couple" on public.couples;

-- Members can update their own couple (non-join edits like anniversary, couple_name)
create policy "Members can update couple"
  on public.couples for update
  using (auth.uid() = user_id_1 or auth.uid() = user_id_2);

-- Any authenticated user can join a pending couple where user_id_2 is not yet set
drop policy if exists "Anyone can join pending couple" on public.couples;
create policy "Anyone can join pending couple"
  on public.couples for update
  using (status = 'pending' and user_id_2 is null)
  with check (auth.uid() = user_id_2);
