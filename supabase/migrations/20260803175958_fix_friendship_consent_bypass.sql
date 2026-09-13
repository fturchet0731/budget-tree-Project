-- Budget Tree — friendship consent bypass
--
-- `friendships.status` is the authorization key for the entire social layer:
-- the "friends read shared goals" policy on `goals`, the `messages` INSERT
-- policy and the `goal_likes` INSERT policy all reduce to "is there an
-- accepted row joining these two users". Two holes let a user forge one
-- without the other party ever agreeing.
--
--   1. INSERT was `with check (auth.uid() = requester)` and nothing pinned
--      `status`, which is plain `text` with no constraint. A caller could POST
--      a row that was already `accepted`, skipping the request/accept exchange
--      entirely.
--
--   2. UPDATE was `using (auth.uid() = addressee) with check (auth.uid() =
--      addressee)`. Both predicates name only `addressee`, so the addressee of
--      any pending request could rewrite `requester` to an arbitrary third
--      party and flip it to accepted in one statement. WITH CHECK sees only
--      the new row, so no policy expression can pin a column against its old
--      value — that has to be a privilege, not a policy.
--
-- Either one gave an attacker read access to a victim's shared goals (name,
-- target, balance and the full contribution ledger), the ability to send them
-- messages, and the ability to like their goals. Victim ids are readable by
-- any signed-in user through `profiles`, so nothing had to be guessed.
--
-- Matches what the app already does: it only ever inserts `pending` as the
-- requester, and only ever updates `status` as the addressee.

-- ─────────────────────────────────────────────────────────────────────────
-- Only two states exist. Without this, `status` is free text and every
-- comparison against 'accepted' downstream is trusting unvalidated input.
-- ─────────────────────────────────────────────────────────────────────────
do $$
begin
  if not exists (
    select 1 from pg_constraint
    where conname = 'friendships_status_valid'
      and conrelid = 'public.friendships'::regclass
  ) then
    alter table public.friendships
      add constraint friendships_status_valid
      check (status in ('pending', 'accepted'));
  end if;
end $$;

-- ─────────────────────────────────────────────────────────────────────────
-- A new relationship always starts pending. Accepting is the addressee's
-- decision and has to go through the UPDATE path below.
-- ─────────────────────────────────────────────────────────────────────────
drop policy if exists "send friend request" on public.friendships;
create policy "send friend request" on public.friendships
  for insert
  with check (auth.uid() = requester and status = 'pending');

-- ─────────────────────────────────────────────────────────────────────────
-- Freeze the participants at the privilege level.
--
-- RLS cannot express "requester must not change", because WITH CHECK only
-- ever sees the new row. Removing UPDATE on those columns does express it:
-- the statement is rejected before any policy is consulted. `status` is the
-- only thing a client has any reason to change.
--
-- service_role and the table owner are deliberately untouched.
-- ─────────────────────────────────────────────────────────────────────────
revoke update on public.friendships from anon, authenticated;
grant update (status) on public.friendships to authenticated;

-- ─────────────────────────────────────────────────────────────────────────
-- Accepting is addressee-only and strictly pending -> accepted, so a stale
-- or already-accepted row can't be replayed into a different state.
-- ─────────────────────────────────────────────────────────────────────────
drop policy if exists "respond to friend request" on public.friendships;
create policy "respond to friend request" on public.friendships
  for update
  using (auth.uid() = addressee and status = 'pending')
  with check (auth.uid() = addressee and status = 'accepted');
