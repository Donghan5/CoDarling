-- ============================================================
-- APP METRICS — client-side telemetry buffer
-- ============================================================

create table if not exists public.app_metrics (
  id           uuid primary key default gen_random_uuid(),
  user_id      uuid not null references auth.users(id) on delete cascade,
  table_name   text not null,      -- e.g. 'photos', 'couples', 'users', 'auth'
  operation    text not null,      -- e.g. 'select', 'insert', 'upload', 'sign_in_google'
  latency_ms   integer not null,
  is_error     boolean not null default false,
  error_type   text,               -- runtime type of the exception, if any
  metadata     jsonb,
  created_at   timestamptz not null default now()
);

alter table public.app_metrics enable row level security;

-- Authenticated users can insert their own metric records
drop policy if exists "Users can insert own metrics" on public.app_metrics;
create policy "Users can insert own metrics"
  on public.app_metrics for insert
  with check (auth.uid() = user_id);

-- Only service_role bypasses RLS and can SELECT (used by the Edge Function)
-- No SELECT policy for authenticated role — users cannot read each other's telemetry

-- Indexes for efficient Edge Function aggregation queries
create index idx_app_metrics_created_at on public.app_metrics (created_at desc);
create index idx_app_metrics_table_op   on public.app_metrics (table_name, operation);

-- ============================================================
-- CLEANUP FUNCTION — deletes records older than 7 days
-- ============================================================
create or replace function public.cleanup_old_metrics()
returns void
language plpgsql
security definer
as $$
begin
  delete from public.app_metrics
  where created_at < now() - interval '7 days';
end;
$$;

-- Schedule via pg_cron if available on your Supabase plan:
-- select cron.schedule('cleanup-old-metrics', '0 3 * * *', 'select public.cleanup_old_metrics()');

-- ============================================================
-- COUPLE COUNTS HELPER — used by the metrics Edge Function
-- ============================================================
create or replace function public.get_couple_counts()
returns table(status text, count bigint)
language sql
security definer
stable
as $$
  select status, count(*)::bigint
  from public.couples
  group by status;
$$;
