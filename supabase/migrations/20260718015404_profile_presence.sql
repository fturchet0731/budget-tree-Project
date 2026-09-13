-- Presence: when a user was last active in the app. The client stamps this
-- (throttled) while the user is on the dashboard; friends read it through the
-- existing "profiles readable by authenticated" SELECT policy to show a green
-- "active now" dot in the friends strip. Nullable: legacy rows simply read as
-- never seen. No new policies needed — only the owner can UPDATE their row.
alter table public.profiles
  add column if not exists last_seen_at timestamptz;
