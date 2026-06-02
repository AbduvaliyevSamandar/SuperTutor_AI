-- FCM token storage for push notifications
create table if not exists public.user_fcm_tokens (
    id          uuid primary key default gen_random_uuid(),
    user_id     uuid not null references auth.users(id) on delete cascade,
    token       text not null,
    platform    text not null default 'android', -- android | ios | web
    created_at  timestamptz default now(),
    unique (user_id, token)
);

alter table public.user_fcm_tokens enable row level security;

create policy "Users manage own tokens"
    on public.user_fcm_tokens
    for all
    using (auth.uid() = user_id)
    with check (auth.uid() = user_id);
