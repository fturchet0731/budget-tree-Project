-- Budget Tree — AI usage rate limiting + reflections UPDATE policy
--
-- 1. Per-user rate limiting for the `ai-coach` edge function, which proxies the
--    paid Anthropic API. Without a cap, anyone holding the public anon key
--    could invoke the function without limit and run up the API bill. A tiny
--    hourly counter table plus a SECURITY DEFINER helper give the function an
--    atomic "am I under quota?" check keyed to the authenticated caller.
--
-- 2. The missing UPDATE policy on ai_reflections, so the client's cross-device
--    upsert (INSERT ... ON CONFLICT DO UPDATE) can refresh an existing period
--    instead of silently failing the update half under RLS.

-- ------------------------------------------------------------- ai_usage
-- One row per (user, hour bucket). RLS is enabled with NO policies, so the
-- table is invisible to direct client access; only the SECURITY DEFINER
-- function below (which runs as the table owner) ever touches it.
create table if not exists public.ai_usage (
  user_id      uuid not null references auth.users on delete cascade,
  window_start timestamptz not null,
  count        integer not null default 0,
  primary key (user_id, window_start)
);

alter table public.ai_usage enable row level security;

-- Old rows are worthless once their window passes; keep the table small.
create index if not exists ai_usage_window_idx
  on public.ai_usage (window_start);

-- Atomically record one call for the current caller in the current hour and
-- return whether they are still within [max_calls] for the hour. Runs as the
-- definer so it can write to the RLS-locked table, but it only ever operates on
-- auth.uid(), so a caller can never affect another user's counter. Returns
-- false for an unauthenticated caller (auth.uid() is null).
create or replace function public.check_ai_quota(max_calls integer)
returns boolean
language plpgsql
security definer
set search_path = public
as $$
declare
  uid    uuid := auth.uid();
  bucket timestamptz := date_trunc('hour', now());
  n      integer;
begin
  if uid is null then
    return false;
  end if;

  insert into public.ai_usage (user_id, window_start, count)
    values (uid, bucket, 1)
  on conflict (user_id, window_start)
    do update set count = public.ai_usage.count + 1
  returning count into n;

  return n <= max_calls;
end;
$$;

-- Only signed-in users may call it; revoke the implicit public/anon grant.
revoke all on function public.check_ai_quota(integer) from public, anon;
grant execute on function public.check_ai_quota(integer) to authenticated, service_role;

-- ------------------------------------------- ai_reflections: UPDATE policy
-- The client upserts reflections (INSERT ... ON CONFLICT DO UPDATE). Without an
-- UPDATE policy the update half is denied by RLS, so refreshing an existing
-- weekly/monthly reflection silently no-ops. Allow a user to update only their
-- own rows.
drop policy if exists "update own reflections" on public.ai_reflections;
create policy "update own reflections" on public.ai_reflections
  for update
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);
