-- Subscription approval is enforced server-side; client code cannot grant access.
create table if not exists public.smp_subscriptions (
  user_id uuid primary key references auth.users(id) on delete cascade,
  status text not null default 'pending' check (status in ('pending', 'approved', 'rejected')),
  requested_at timestamptz not null default now(),
  starts_at timestamptz,
  expires_at timestamptz,
  decided_by uuid references auth.users(id) on delete set null,
  decided_at timestamptz,
  updated_at timestamptz not null default now()
);

create table if not exists public.smp_subscription_admins (
  user_id uuid primary key references auth.users(id) on delete cascade,
  username text not null unique,
  created_at timestamptz not null default now()
);

alter table public.smp_subscriptions enable row level security;
alter table public.smp_subscription_admins enable row level security;
revoke all on public.smp_subscriptions, public.smp_subscription_admins from anon, authenticated;
grant all on public.smp_subscriptions, public.smp_subscription_admins to service_role;

-- Existing accounts keep access. New accounts created after this migration start pending.
insert into public.smp_subscriptions(user_id, status, requested_at, starts_at)
select id, 'approved', now(), now() from auth.users
on conflict (user_id) do nothing;

-- Promote the owner account if its verified username is already registered.
insert into public.smp_subscription_admins(user_id, username)
select user_id, username from public.smp_usernames where username = 'youssefalalmie'
on conflict (user_id) do update set username = excluded.username;

update public.smp_subscriptions
set status = 'approved', starts_at = coalesce(starts_at, now()), expires_at = null,
    decided_at = coalesce(decided_at, now()), updated_at = now()
where user_id in (select user_id from public.smp_subscription_admins);

create or replace function public.smp_create_pending_subscription()
returns trigger
language plpgsql
security definer
set search_path = public, auth
as $$
begin
  insert into public.smp_subscriptions(user_id, status, requested_at)
  values (new.id, 'pending', now())
  on conflict (user_id) do nothing;
  return new;
end;
$$;

revoke all on function public.smp_create_pending_subscription() from public, anon, authenticated;
drop trigger if exists smp_create_pending_subscription on auth.users;
create trigger smp_create_pending_subscription
after insert on auth.users
for each row execute function public.smp_create_pending_subscription();
