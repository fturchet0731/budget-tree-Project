-- Budget Tree — fix "column reference \"kind\" is ambiguous" in check_ai_quota
--
-- The per-kind quota function added in 20260808121000 named its parameter
-- `kind`, the same as the private.ai_usage.kind column added in the same
-- migration. Postgres could not tell which `kind` the `on conflict (user_id,
-- kind, window_start)` inference list meant (PL/pgSQL variable vs table
-- column), so every call raised 42702 `column reference "kind" is ambiguous`.
-- The ai-coach edge function fails closed on a quota-check error, so this made
-- the AI coach report "unavailable" for every signed-in user.
--
-- Fix without changing the signature (the edge function calls this by named
-- arg `kind`, so the parameter name must stay `kind`): read the parameter into
-- a local `k` before any SQL that has the table in scope, insert `k` instead of
-- the bare parameter, and target the conflict by its constraint name rather
-- than a column-inference list. That leaves no unqualified `kind` in any
-- statement where the column is visible, so the ambiguity is gone.
--
-- create-or-replace re-grants EXECUTE to PUBLIC, so the revoke below is
-- mandatory (see the CLAUDE.md note and 20260808121000). Signature is unchanged
-- (uuid, integer, text), so no deploy-ordering dance is needed.

create or replace function public.check_ai_quota(
  uid uuid,
  max_calls integer,
  kind text
)
returns boolean
language plpgsql
security definer
set search_path = private, public
as $$
declare
  bucket timestamptz := date_trunc('hour', now());
  k      text := coalesce(kind, 'all');
  n      integer;
begin
  if uid is null then return false; end if;
  insert into private.ai_usage (user_id, kind, window_start, count)
    values (uid, k, bucket, 1)
  on conflict on constraint ai_usage_pkey
    do update set count = private.ai_usage.count + 1
  returning count into n;
  return n <= max_calls;
end;
$$;

-- MANDATORY after create-or-replace (same as 20260808121000): PUBLIC gets
-- EXECUTE on a freshly (re)created function, which would expose it at
-- /rest/v1/rpc/check_ai_quota where a user could spend anyone's quota (uid is a
-- parameter). Lock it back down to the service role only.
revoke all on function public.check_ai_quota(uuid, integer, text)
  from public, anon, authenticated;
grant execute on function public.check_ai_quota(uuid, integer, text)
  to service_role;

-- Self-verifying probe, mirroring 20260808121000: fail the migration loudly
-- here rather than discovering at runtime that the grants drifted.
do $$
begin
  if has_function_privilege(
       'authenticated', 'public.check_ai_quota(uuid, integer, text)', 'execute')
  then
    raise exception 'check_ai_quota(uuid,integer,text) is still executable by authenticated';
  end if;
  if not has_function_privilege(
       'service_role', 'public.check_ai_quota(uuid, integer, text)', 'execute')
  then
    raise exception 'check_ai_quota(uuid,integer,text) is not executable by service_role';
  end if;
end $$;
