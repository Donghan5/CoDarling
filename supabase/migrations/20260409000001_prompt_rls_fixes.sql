-- ============================================================
-- PROMPT RLS FIXES & CONSTRAINTS
-- ============================================================
-- Adds:
--   1. UNIQUE(couple_id, date) on prompts — prevents duplicate daily prompts
--      and allows upsert-based auto-creation from the client.
--   2. INSERT policy on prompts — allows couple members to create their
--      daily prompt (needed for client-side upsert in getTodayPrompt).
--   3. INSERT / UPDATE / DELETE policies on prompt_replies — were missing
--      from the initial schema.
-- ============================================================

-- 1. Unique constraint so upsert onConflict works correctly
alter table public.prompts
  add constraint if not exists prompts_couple_date_unique
  unique (couple_id, date);

-- 2. INSERT policy on prompts (couple members can create their daily prompt)
do $$
begin
  if not exists (
    select 1 from pg_policies
    where schemaname = 'public'
      and tablename = 'prompts'
      and policyname = 'Couple members can insert prompts'
  ) then
    execute $policy$
      create policy "Couple members can insert prompts"
        on public.prompts for insert
        with check (
          couple_id in (
            select id from public.couples
            where user_id_1 = auth.uid() or user_id_2 = auth.uid()
          )
        )
    $policy$;
  end if;
end $$;

-- 3a. Prompt replies — users can update their own reply
do $$
begin
  if not exists (
    select 1 from pg_policies
    where schemaname = 'public'
      and tablename = 'prompt_replies'
      and policyname = 'Users can update their own replies'
  ) then
    execute $policy$
      create policy "Users can update their own replies"
        on public.prompt_replies for update
        using (auth.uid() = user_id)
        with check (auth.uid() = user_id)
    $policy$;
  end if;
end $$;

-- 3b. Prompt replies — users can delete their own reply
do $$
begin
  if not exists (
    select 1 from pg_policies
    where schemaname = 'public'
      and tablename = 'prompt_replies'
      and policyname = 'Users can delete their own replies'
  ) then
    execute $policy$
      create policy "Users can delete their own replies"
        on public.prompt_replies for delete
        using (auth.uid() = user_id)
    $policy$;
  end if;
end $$;
