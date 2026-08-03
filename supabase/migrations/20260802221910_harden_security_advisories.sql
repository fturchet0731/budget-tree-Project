-- Budget Tree — security advisor remediations
--
-- Four findings from the Supabase security advisor:
--   1. citext installed in the public schema
--   2. anon can execute public.rls_auto_enable()          (SECURITY DEFINER)
--   3. authenticated can execute public.rls_auto_enable() (SECURITY DEFINER)
--   4. authenticated can execute public.check_ai_quota()  (SECURITY DEFINER)
--
-- Everything here is safe to re-run and, where a step could plausibly break
-- the app, proves it didn't before committing.

-- ─────────────────────────────────────────────────────────────────────────
-- 1. Move citext out of the public schema
--
-- `profiles.username` is citext, so the column keeps working either way (it
-- references the type by OID), but the *operators* resolve through the search
-- path. PostgREST turns `.eq('username', x)` into `username = 'x'` and
-- `.ilike(...)` into `username ILIKE '...'`, both of which need citext's
-- operators visible — so getting this wrong breaks sign-in and friend search
-- rather than failing loudly at migration time.
--
-- Supabase ships an `extensions` schema and includes it in PostgREST's search
-- path for exactly this reason. The DO block below proves the operators still
-- resolve under that path; if they don't it raises, and since the migration
-- runs in a transaction the move rolls back with it.
-- ─────────────────────────────────────────────────────────────────────────

create schema if not exists extensions;

do $$
begin
  if exists (
    select 1
    from pg_extension e
    join pg_namespace n on n.oid = e.extnamespace
    where e.extname = 'citext' and n.nspname = 'public'
  ) then
    execute 'alter extension citext set schema extensions';
  end if;
end $$;

-- Prove username lookups still resolve under the search path PostgREST uses.
-- These are the two comparisons the app actually issues.
do $$
begin
  perform set_config('search_path', 'public, extensions', true);
  perform 1 from public.profiles where username = 'citext_probe';
  perform 1 from public.profiles where username ilike '%citext_probe%';
exception
  when undefined_function or undefined_object then
    raise exception
      'citext operators are not resolvable after the schema move; aborting so username lookups keep working';
end $$;

-- ─────────────────────────────────────────────────────────────────────────
-- 2 + 3. public.rls_auto_enable()
--
-- Not created by any migration in this repo, so it arrived from outside (the
-- dashboard, or a template). Its behaviour is unknown here, so this revokes
-- the API-facing grants rather than dropping it: that closes both advisories
-- (anon and authenticated can no longer reach it through /rest/v1/rpc) while
-- leaving anything that legitimately calls it as owner or service_role
-- untouched, and it is trivially reversible.
--
-- UPDATE (20260803): identified. It backs the `ensure_rls` ddl_command_end event
-- trigger and auto-enables RLS on new public tables. Keep it. See CLAUDE.md.
-- ─────────────────────────────────────────────────────────────────────────

do $$
declare
  fn record;
begin
  for fn in
    select p.oid::regprocedure as sig
    from pg_proc p
    join pg_namespace n on n.oid = p.pronamespace
    where n.nspname = 'public' and p.proname = 'rls_auto_enable'
  loop
    execute format(
      'revoke all on function %s from public, anon, authenticated', fn.sig);
  end loop;
end $$;

-- ─────────────────────────────────────────────────────────────────────────
-- 4. check_ai_quota
--
-- The old signature reads auth.uid() and had to be granted to `authenticated`
-- so the edge function could call it with the user's JWT. That also exposed it
-- at /rest/v1/rpc/check_ai_quota, where a signed-in user could burn their own
-- AI quota directly. Harmless to others (it only ever touches auth.uid()) but
-- it is API surface with no reason to exist.
--
-- The replacement takes the user id explicitly and is granted to service_role
-- only, so it cannot be reached from the client API at all. Spoofing isn't a
-- concern: the edge function derives that id from `supabase.auth.getUser()`,
-- which validates the access token against the auth server before the id is
-- ever used.
--
-- The old one-argument version keeps its `authenticated` grant for now so the
-- currently deployed edge function keeps working. A follow-up migration
-- revokes it once the new function is live.
-- ─────────────────────────────────────────────────────────────────────────

create or replace function public.check_ai_quota(uid uuid, max_calls integer)
returns boolean
language plpgsql
security definer
set search_path = public
as $$
declare
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

-- Service role only: never reachable from anon or a signed-in client.
revoke all on function public.check_ai_quota(uuid, integer)
  from public, anon, authenticated;
grant execute on function public.check_ai_quota(uuid, integer) to service_role;
