-- Make sign-up triggers robust so a glitch in profiles/currency creation
-- never blocks auth.users insert.

create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
as $$
begin
  begin
    insert into public.profiles (user_id, display_name)
    values (new.id, coalesce(new.raw_user_meta_data->>'name', new.email))
    on conflict (user_id) do nothing;
  exception when others then
    -- Swallow profile-side failures so signup itself succeeds.
    raise warning 'handle_new_user profiles insert failed: %', sqlerrm;
  end;
  return new;
end;
$$;

create or replace function public.handle_new_currency()
returns trigger
language plpgsql
security definer
as $$
begin
  begin
    insert into public.user_currency (user_id) values (new.user_id)
    on conflict (user_id) do nothing;
  exception when others then
    raise warning 'handle_new_currency insert failed: %', sqlerrm;
  end;
  return new;
end;
$$;

-- Make sure the right column reference is used (was `new.id` but profiles
-- key column is `user_id`)
drop trigger if exists on_profile_create_currency on public.profiles;
create trigger on_profile_create_currency
  after insert on public.profiles
  for each row execute function public.handle_new_currency();

-- Ensure friend_code is auto-assigned on new profile
create or replace function public.assign_friend_code()
returns trigger
language plpgsql
security definer
as $$
begin
  if new.friend_code is null then
    new.friend_code := upper(substring(md5(random()::text || new.user_id::text) from 1 for 6));
  end if;
  return new;
end;
$$;

drop trigger if exists on_profile_assign_code on public.profiles;
create trigger on_profile_assign_code
  before insert on public.profiles
  for each row execute function public.assign_friend_code();
