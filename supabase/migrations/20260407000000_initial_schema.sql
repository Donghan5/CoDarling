-- Enable UUID generation
create extension if not exists "pgcrypto";

-- ============================================================
-- USERS
-- ============================================================
create table if not exists public.users (
  id          uuid primary key references auth.users(id) on delete cascade,
  email       text not null,
  display_name text not null,
  avatar_url  text,
  created_at  timestamptz not null default now()
);

alter table public.users enable row level security;

create policy "Users can read their own profile"
  on public.users for select
  using (auth.uid() = id);

create policy "Users can update their own profile"
  on public.users for update
  using (auth.uid() = id);

create policy "Users can insert their own profile"
  on public.users for insert
  with check (auth.uid() = id);

-- ============================================================
-- COUPLES
-- ============================================================
create table if not exists public.couples (
  id           uuid primary key default gen_random_uuid(),
  user_id_1    uuid not null references public.users(id) on delete cascade,
  user_id_2    uuid references public.users(id) on delete set null,
  invite_code  text unique not null,
  status       text not null default 'pending' check (status in ('pending', 'active')),
  anniversary  date,
  couple_name  text,
  created_at   timestamptz not null default now()
);

alter table public.couples enable row level security;

create policy "Couple members can read their couple"
  on public.couples for select
  using (auth.uid() = user_id_1 or auth.uid() = user_id_2);

create policy "Creator can insert couple"
  on public.couples for insert
  with check (auth.uid() = user_id_1);

create policy "Members can update couple"
  on public.couples for update
  using (auth.uid() = user_id_1 or auth.uid() = user_id_2);

-- Allow reading pending couple by invite code (for join flow)
create policy "Anyone can read pending couple by invite code"
  on public.couples for select
  using (status = 'pending');

-- ============================================================
-- PHOTOS
-- ============================================================
create table if not exists public.photos (
  id         uuid primary key default gen_random_uuid(),
  couple_id  uuid not null references public.couples(id) on delete cascade,
  user_id    uuid not null references public.users(id) on delete cascade,
  image_url  text not null,
  caption    text,
  date       date not null,
  created_at timestamptz not null default now(),
  constraint one_photo_per_user_per_day unique (couple_id, user_id, date)
);

alter table public.photos enable row level security;

create policy "Couple members can read photos"
  on public.photos for select
  using (
    couple_id in (
      select id from public.couples
      where user_id_1 = auth.uid() or user_id_2 = auth.uid()
    )
  );

create policy "Users can insert their own photos"
  on public.photos for insert
  with check (auth.uid() = user_id);

-- ============================================================
-- PROMPTS
-- ============================================================
create table if not exists public.prompts (
  id            uuid primary key default gen_random_uuid(),
  couple_id     uuid not null references public.couples(id) on delete cascade,
  question_text text not null,
  date          date not null,
  created_at    timestamptz not null default now()
);

alter table public.prompts enable row level security;

create policy "Couple members can read prompts"
  on public.prompts for select
  using (
    couple_id in (
      select id from public.couples
      where user_id_1 = auth.uid() or user_id_2 = auth.uid()
    )
  );

-- ============================================================
-- PROMPT REPLIES
-- ============================================================
create table if not exists public.prompt_replies (
  id         uuid primary key default gen_random_uuid(),
  prompt_id  uuid not null references public.prompts(id) on delete cascade,
  user_id    uuid not null references public.users(id) on delete cascade,
  reply_text text not null,
  created_at timestamptz not null default now()
);

alter table public.prompt_replies enable row level security;

create policy "Couple members can read prompt replies"
  on public.prompt_replies for select
  using (
    prompt_id in (
      select p.id from public.prompts p
      join public.couples c on c.id = p.couple_id
      where c.user_id_1 = auth.uid() or c.user_id_2 = auth.uid()
    )
  );

create policy "Users can insert their own replies"
  on public.prompt_replies for insert
  with check (auth.uid() = user_id);

-- ============================================================
-- REACTIONS
-- ============================================================
create table if not exists public.reactions (
  id          uuid primary key default gen_random_uuid(),
  user_id     uuid not null references public.users(id) on delete cascade,
  target_type text not null check (target_type in ('photo', 'prompt_reply')),
  target_id   uuid not null,
  emoji       text not null,
  created_at  timestamptz not null default now(),
  constraint one_reaction_per_user_per_target unique (user_id, target_type, target_id, emoji)
);

alter table public.reactions enable row level security;

create policy "Users can read reactions on their couple's content"
  on public.reactions for select
  using (true); -- fine-grained via app logic; refine as needed

create policy "Users can insert their own reactions"
  on public.reactions for insert
  with check (auth.uid() = user_id);

create policy "Users can delete their own reactions"
  on public.reactions for delete
  using (auth.uid() = user_id);

-- ============================================================
-- STORAGE
-- ============================================================
-- Run in Supabase dashboard or via CLI:
-- insert into storage.buckets (id, name, public) values ('photos', 'photos', false);
