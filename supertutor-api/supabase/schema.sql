-- SuperTutor AI — Supabase schema
-- Run this in Supabase Dashboard → SQL Editor.

-- 1. Profiles (extends auth.users)
create table if not exists public.profiles (
  user_id uuid primary key references auth.users(id) on delete cascade,
  display_name text,
  english_level text default 'A1',
  streak_days int default 0,
  last_active_date date,
  created_at timestamptz default now()
);

-- 2. Learning sessions
create table if not exists public.sessions (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  subject text not null,
  started_at timestamptz default now(),
  ended_at timestamptz,
  duration_seconds int default 0,
  messages_count int default 0
);

create index if not exists sessions_user_idx on public.sessions(user_id, started_at desc);

-- 3. RLS (Row Level Security)
alter table public.profiles enable row level security;
alter table public.sessions enable row level security;

drop policy if exists "profiles self read" on public.profiles;
create policy "profiles self read"
  on public.profiles for select
  using (auth.uid() = user_id);

drop policy if exists "profiles self upsert" on public.profiles;
create policy "profiles self upsert"
  on public.profiles for all
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

drop policy if exists "sessions self read" on public.sessions;
create policy "sessions self read"
  on public.sessions for select
  using (auth.uid() = user_id);

drop policy if exists "sessions self write" on public.sessions;
create policy "sessions self write"
  on public.sessions for all
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

-- 4. Auto-create profile when a user signs up
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
as $$
begin
  insert into public.profiles (user_id, display_name)
  values (new.id, coalesce(new.raw_user_meta_data->>'name', new.email))
  on conflict (user_id) do nothing;
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- 5. Streak trigger: update streak_days + last_active_date whenever a session starts
create or replace function public.update_streak_on_session()
returns trigger
language plpgsql
security definer
as $$
declare
  today date := current_date;
  last_active date;
  current_streak int;
begin
  select last_active_date, streak_days
    into last_active, current_streak
    from public.profiles
   where user_id = new.user_id;

  if last_active is null then
    current_streak := 1;
  elsif last_active = today then
    return new;
  elsif last_active = today - 1 then
    current_streak := coalesce(current_streak, 0) + 1;
  else
    current_streak := 1;
  end if;

  update public.profiles
     set last_active_date = today,
         streak_days = current_streak
   where user_id = new.user_id;

  return new;
end;
$$;

drop trigger if exists on_session_started on public.sessions;
create trigger on_session_started
  after insert on public.sessions
  for each row execute function public.update_streak_on_session();

-- 6a. Vocabulary entries (saved words)
create table if not exists public.vocabulary_entries (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  word text not null,
  language text not null,
  translation_uz text,
  definition text,
  saved_at timestamptz default now(),
  last_reviewed_at timestamptz,
  unique (user_id, word, language)
);

alter table public.vocabulary_entries enable row level security;
drop policy if exists "vocab self all" on public.vocabulary_entries;
create policy "vocab self all"
  on public.vocabulary_entries for all
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

-- 6b. Quiz results
create table if not exists public.quiz_results (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  subject text not null,
  level text,
  score int default 0,
  total int default 0,
  percentage int default 0,
  weak_topics text[] default '{}',
  created_at timestamptz default now()
);

create index if not exists quiz_results_user_idx
  on public.quiz_results(user_id, created_at desc);

alter table public.quiz_results enable row level security;
drop policy if exists "quiz self all" on public.quiz_results;
create policy "quiz self all"
  on public.quiz_results for all
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

-- 6c. Gamification: hearts, XP, gems, daily goal
create table if not exists public.user_currency (
  user_id uuid primary key references auth.users(id) on delete cascade,
  hearts int default 5,
  max_hearts int default 5,
  xp_total int default 0,
  gems int default 50,
  streak_freezes int default 0,
  last_heart_refill_at timestamptz default now(),
  updated_at timestamptz default now()
);

alter table public.user_currency enable row level security;
drop policy if exists "currency self all" on public.user_currency;
create policy "currency self all"
  on public.user_currency for all
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

create table if not exists public.daily_goals (
  user_id uuid not null references auth.users(id) on delete cascade,
  date date not null default current_date,
  target_xp int not null default 20,
  earned_xp int not null default 0,
  primary key (user_id, date)
);

alter table public.daily_goals enable row level security;
drop policy if exists "daily self all" on public.daily_goals;
create policy "daily self all"
  on public.daily_goals for all
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

create table if not exists public.achievements (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  badge_code text not null,
  earned_at timestamptz default now(),
  unique (user_id, badge_code)
);

alter table public.achievements enable row level security;
drop policy if exists "ach self all" on public.achievements;
create policy "ach self all"
  on public.achievements for all
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

-- Auto-create currency row on signup
create or replace function public.handle_new_currency()
returns trigger
language plpgsql
security definer
as $$
begin
  insert into public.user_currency (user_id) values (new.id)
  on conflict (user_id) do nothing;
  return new;
end;
$$;

drop trigger if exists on_profile_create_currency on public.profiles;
create trigger on_profile_create_currency
  after insert on public.profiles
  for each row execute function public.handle_new_currency();

-- Backfill: every existing profile gets a currency row
insert into public.user_currency (user_id)
  select user_id from public.profiles
  on conflict (user_id) do nothing;

-- 6d. Personalized learner notes
create table if not exists public.learner_notes (
  user_id uuid not null references auth.users(id) on delete cascade,
  subject text not null,
  notes text default '',
  updated_at timestamptz default now(),
  primary key (user_id, subject)
);

alter table public.learner_notes enable row level security;
drop policy if exists "notes self all" on public.learner_notes;
create policy "notes self all"
  on public.learner_notes for all
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

-- 6e. Daily lesson tracking
create table if not exists public.daily_lesson_progress (
  user_id uuid not null references auth.users(id) on delete cascade,
  date date not null default current_date,
  chat_done bool default false,
  quiz_done bool default false,
  srs_done bool default false,
  primary key (user_id, date)
);

alter table public.daily_lesson_progress enable row level security;
drop policy if exists "daily lesson self all" on public.daily_lesson_progress;
create policy "daily lesson self all"
  on public.daily_lesson_progress for all
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

-- 6. Aggregate view for dashboard
create or replace view public.user_stats as
select
  s.user_id,
  count(*)::int                                                as total_sessions,
  coalesce(sum(s.duration_seconds), 0)::int                    as total_seconds,
  coalesce(sum(s.messages_count), 0)::int                      as total_messages,
  count(*) filter (where s.subject = 'english')::int           as english_sessions,
  count(*) filter (where s.subject = 'math')::int              as math_sessions,
  max(s.started_at)                                            as last_session_at
from public.sessions s
group by s.user_id;
