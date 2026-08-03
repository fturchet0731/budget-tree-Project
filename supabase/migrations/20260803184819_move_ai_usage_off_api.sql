-- Budget Tree — take `ai_usage` off the API surface entirely
--
-- Advisory: "Table public.ai_usage has RLS enabled, but no policies exist."
--
-- That state was deliberate, not an oversight. RLS with zero policies is
-- deny-all for every role that isn't the owner or BYPASSRLS, and the only
-- thing that touches this table is `check_ai_quota`, a SECURITY DEFINER
-- function that runs as the owner and so is unaffected. Confirmed against the
-- live API: an anon request for `/rest/v1/ai_usage?select=*` returns `[]`, not
-- rows. Nothing leaked, and the advisory is a false positive as a *security*
-- finding — the lint can't tell "locked down on purpose" from "policies were
-- forgotten, so this table is accidentally unusable".
--
-- It is still worth acting on, because it points at something real: a table
-- that must never be client-reachable was sitting in the API-exposed schema,
-- relying on RLS as its only barrier. `config.toml` exposes `public` and
-- `graphql_public` only, so moving it to `private` removes the endpoint
-- outright rather than leaving one that answers with an empty array. Same
-- reasoning that put `check_ai_quota` behind service_role: the strongest
-- control is not being reachable at all.
--
-- RLS stays enabled on the moved table. It is redundant now, but it keeps the
-- table locked if `private` is ever exposed by accident.

create schema if not exists private;

-- Nothing outside the owner and SECURITY DEFINER functions has any business
-- here, so the schema itself is not traversable by the API roles.
revoke all on schema private from public, anon, authenticated;

do $$
begin
  if exists (
    select 1
    from pg_class c
    join pg_namespace n on n.oid = c.relnamespace
    where c.relname = 'ai_usage' and n.nspname = 'public'
  ) then
    execute 'alter table public.ai_usage set schema private';
  end if;
end $$;

-- Belt and braces: even inside `private`, the API roles hold no privileges.
revoke all on table private.ai_usage from public, anon, authenticated;

-- ─────────────────────────────────────────────────────────────────────────
-- Repoint the quota function.
--
-- Fully qualified *and* search_path pinned: the qualification is what makes it
-- correct, the pin is what stops a later schema shadowing it. Grants survive
-- CREATE OR REPLACE, but they are restated so this migration alone describes
-- the end state.
-- ─────────────────────────────────────────────────────────────────────────

create or replace function public.check_ai_quota(uid uuid, max_calls integer)
returns boolean
language plpgsql
security definer
set search_path = private, public
as $$
declare
  bucket timestamptz := date_trunc('hour', now());
  n      integer;
begin
  if uid is null then
    return false;
  end if;

  insert into private.ai_usage (user_id, window_start, count)
    values (uid, bucket, 1)
  on conflict (user_id, window_start)
    do update set count = private.ai_usage.count + 1
  returning count into n;

  return n <= max_calls;
end;
$$;

revoke all on function public.check_ai_quota(uuid, integer)
  from public, anon, authenticated;
grant execute on function public.check_ai_quota(uuid, integer) to service_role;

-- Prove the function still works against the moved table before committing.
-- A failure here aborts the transaction and rolls the move back, rather than
-- leaving the AI coach failing closed on every request.
do $$
declare
  probe uuid := '00000000-0000-0000-0000-000000000000';
  under boolean;
begin
  -- No FK row exists for the probe id, so do the insert/rollback in a
  -- savepoint-free way: just confirm the function body parses and resolves by
  -- calling it inside a subtransaction we discard.
  begin
    select public.check_ai_quota(probe, 1) into under;
    raise exception 'probe_rollback';
  exception
    when foreign_key_violation then
      -- Expected: the table resolved and the FK fired. That is the proof.
      null;
    when others then
      if sqlerrm = 'probe_rollback' then
        null;
      else
        raise exception
          'check_ai_quota no longer resolves after the schema move: %', sqlerrm;
      end if;
  end;
end $$;
