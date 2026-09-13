-- Budget Tree — social layer (friends, shared goals, status)
--
-- Adds two new tables (profiles, friendships) and one additive SELECT policy on
-- the existing `goals` table so accepted friends can read each other's goals
-- that are explicitly marked `data->>'sharedWithFriends' = true`. Budgets are
-- never shared, so the budgets table is untouched. The original "own rows"
-- policy on goals stays — multiple permissive policies are OR'd together.

-- Case-insensitive usernames so "Alice" and "alice" can't both be claimed.
create extension if not exists citext;

-- ---------------------------------------------------------------- profiles
-- One row per user. Readable by any authenticated user (needed for username
-- search and for reading a friend's status-presentation mode). Writable only
-- by its owner.
create table if not exists public.profiles (
  id             uuid primary key references auth.users on delete cascade,
  username       citext unique not null,
  display_name   text,
  status_mode    text not null default 'best',   -- best | average | worst | goal
  status_goal_id text,                            -- set only when status_mode = 'goal'
  updated_at     timestamptz not null default now()
);

alter table public.profiles enable row level security;

drop policy if exists "profiles readable by authenticated" on public.profiles;
create policy "profiles readable by authenticated" on public.profiles
  for select
  using (auth.uid() is not null);

drop policy if exists "insert own profile" on public.profiles;
create policy "insert own profile" on public.profiles
  for insert
  with check (auth.uid() = id);

drop policy if exists "update own profile" on public.profiles;
create policy "update own profile" on public.profiles
  for update
  using (auth.uid() = id)
  with check (auth.uid() = id);

-- ------------------------------------------------------------- friendships
-- A directed request (requester -> addressee) that becomes mutual once
-- accepted. A single row models the whole relationship.
create table if not exists public.friendships (
  requester  uuid not null references auth.users on delete cascade,
  addressee  uuid not null references auth.users on delete cascade,
  status     text not null default 'pending',    -- pending | accepted
  created_at timestamptz not null default now(),
  primary key (requester, addressee),
  check (requester <> addressee)
);

alter table public.friendships enable row level security;

-- Either party can see and remove/cancel the relationship row.
drop policy if exists "see own friendships" on public.friendships;
create policy "see own friendships" on public.friendships
  for select
  using (auth.uid() = requester or auth.uid() = addressee);

drop policy if exists "delete own friendships" on public.friendships;
create policy "delete own friendships" on public.friendships
  for delete
  using (auth.uid() = requester or auth.uid() = addressee);

-- You may only create requests where you are the requester.
drop policy if exists "send friend request" on public.friendships;
create policy "send friend request" on public.friendships
  for insert
  with check (auth.uid() = requester);

-- Only the addressee can flip a pending request to accepted.
drop policy if exists "respond to friend request" on public.friendships;
create policy "respond to friend request" on public.friendships
  for update
  using (auth.uid() = addressee)
  with check (auth.uid() = addressee);

-- --------------------------------------------------- goals: friend read access
-- Additive SELECT policy: an accepted friend may read a goal row that its owner
-- has marked shared. The owner's own "own rows" policy is unaffected.
drop policy if exists "friends read shared goals" on public.goals;
create policy "friends read shared goals" on public.goals
  for select
  using (
    (data->>'sharedWithFriends')::boolean is true
    and exists (
      select 1
      from public.friendships f
      where f.status = 'accepted'
        and (
             (f.requester = auth.uid() and f.addressee = goals.user_id)
          or (f.addressee = auth.uid() and f.requester = goals.user_id)
        )
    )
  );
