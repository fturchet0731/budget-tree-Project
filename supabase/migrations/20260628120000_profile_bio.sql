-- Budget Tree — profile bio + drop "featured goal"
--
-- Profiles gain a free-text `bio` shown on the user's profile (in the dashboard
-- social sidebar and to friends). The "feature one completed goal" mechanic is
-- removed: a profile now simply shows every goal the owner has marked shared
-- (`data->>'sharedWithFriends'`), so the single per-goal privacy toggle is the
-- only control. The old `featured_goal_id` column is no longer used.
alter table public.profiles
  add column if not exists bio text;

alter table public.profiles
  drop column if exists featured_goal_id;
