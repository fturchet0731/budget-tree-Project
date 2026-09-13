-- Budget Tree — profile "featured goal"
--
-- A user can pin one completed goal to show off on their profile. Friends see
-- it highlighted at the front of that user's garden. Stored as the goal id;
-- the goal itself is read through the existing "friends read shared goals"
-- policy, so featuring only surfaces a goal the user has also shared.
alter table public.profiles
  add column if not exists featured_goal_id text;
