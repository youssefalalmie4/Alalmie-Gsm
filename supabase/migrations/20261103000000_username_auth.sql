-- Username lookup stays private; passwords remain managed by Supabase Auth.
create table if not exists public.smp_usernames (
  username text primary key,
  user_id uuid not null unique references auth.users(id) on delete cascade,
  created_at timestamptz not null default now(),
  constraint smp_usernames_format check (username ~ '^[a-z0-9][a-z0-9._-]{2,23}$')
);

alter table public.smp_usernames enable row level security;
revoke all on public.smp_usernames from anon, authenticated;
grant select on public.smp_usernames to service_role;

create or replace function public.smp_sync_auth_username()
returns trigger
language plpgsql
security definer
set search_path = public, auth
as $$
declare
  normalized_username text;
begin
  delete from public.smp_usernames where user_id = new.id;
  normalized_username := lower(btrim(coalesce(new.raw_user_meta_data ->> 'username', '')));

  if normalized_username = '' or new.email_confirmed_at is null then
    return new;
  end if;

  if normalized_username !~ '^[a-z0-9][a-z0-9._-]{2,23}$' then
    raise exception 'Username must be 3-24 characters: a-z, 0-9, dot, underscore, or hyphen';
  end if;

  insert into public.smp_usernames(username, user_id)
  values (normalized_username, new.id);
  return new;
end;
$$;

revoke all on function public.smp_sync_auth_username() from public, anon, authenticated;

drop trigger if exists smp_sync_auth_username on auth.users;
create trigger smp_sync_auth_username
after insert or update of raw_user_meta_data, email_confirmed_at on auth.users
for each row execute function public.smp_sync_auth_username();

-- Backfill verified accounts that were created before username lookup was installed.
do $$
declare
  existing_user record;
begin
  for existing_user in
    select id from auth.users
    where email_confirmed_at is not null
      and coalesce(raw_user_meta_data ->> 'username', '') <> ''
    order by created_at, id
  loop
    begin
      update auth.users
      set raw_user_meta_data = raw_user_meta_data
      where id = existing_user.id;
    exception when unique_violation then
      null;
    end;
  end loop;
end;
$$;
