-- ============================================================
-- PROMPT RLS FIXES
-- ============================================================
-- Adds missing UPDATE / DELETE policies on prompt_replies.
-- Prompts are managed server-side (seeded via migration or admin),
-- so no client INSERT policy is needed on the prompts table.
-- ============================================================

-- Prompt replies — users can update their own reply
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

-- Prompt replies — users can delete their own reply
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
