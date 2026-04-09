-- ============================================================
-- FCM TOKENS
-- ============================================================
create table if not exists public.fcm_tokens (
  id         uuid primary key default gen_random_uuid(),
  user_id    uuid not null references public.users(id) on delete cascade,
  token      text not null,
  device_id  text not null,
  platform   text not null default 'android' check (platform in ('android', 'ios', 'web')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint unique_user_device unique (user_id, device_id)
);

alter table public.fcm_tokens enable row level security;

create policy "Users can read their own tokens"
  on public.fcm_tokens for select
  using (auth.uid() = user_id);

create policy "Users can insert their own tokens"
  on public.fcm_tokens for insert
  with check (auth.uid() = user_id);

create policy "Users can update their own tokens"
  on public.fcm_tokens for update
  using (auth.uid() = user_id);

create policy "Users can delete their own tokens"
  on public.fcm_tokens for delete
  using (auth.uid() = user_id);

create or replace function public.update_updated_at_column()
returns trigger as $$
begin
  NEW.updated_at = now();
  return NEW;
end;
$$ language plpgsql;

create trigger set_fcm_tokens_updated_at
  before update on public.fcm_tokens
  for each row
  execute function public.update_updated_at_column();
