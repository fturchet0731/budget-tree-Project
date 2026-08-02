-- Budget Tree — close the last security advisory: drop the legacy quota check.
--
-- Companion to 20260802221910. That migration added
-- `check_ai_quota(uuid, integer)` for service_role only, but deliberately left
-- the old `check_ai_quota(integer)` granted to `authenticated` so the
-- then-deployed edge function kept working through the change.
--
-- The edge function now calls the two-argument version with the service role,
-- so the old one has no caller. Dropping it rather than only revoking it: it
-- reads auth.uid() and exists solely to be called by a signed-in user, which is
-- exactly the exposure the advisory flagged, and leaving a disabled
-- SECURITY DEFINER function around invites it being re-granted later by
-- accident.
--
-- Run this only after `supabase functions deploy ai-coach` has gone out with
-- the two-argument call, otherwise AI requests fail closed on the quota check.

drop function if exists public.check_ai_quota(integer);
