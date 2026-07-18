-- Social interactions: likes on friends' shared goals + 1:1 friend messages.
--
-- goal_likes: one row per (goal, liker). The tally is a count. RLS piggybacks
-- on the goals table's own policies: the `exists (select from goals)` checks
-- run under the querying user's RLS, so "can I see this like / like this
-- goal" reduces to "can I read this goal row" — owners via "own rows",
-- friends via "friends read shared goals" (accepted friendship + shared).
create table if not exists public.goal_likes (
  goal_owner uuid not null references auth.users (id) on delete cascade,
  goal_id    text not null,
  liker      uuid not null references auth.users (id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (goal_owner, goal_id, liker)
);

alter table public.goal_likes enable row level security;

-- Anyone who can read the goal can read (count) its likes.
drop policy if exists "see likes on visible goals" on public.goal_likes;
create policy "see likes on visible goals" on public.goal_likes
  for select
  using (
    liker = auth.uid()
    or goal_owner = auth.uid()
    or exists (
      select 1 from public.goals g
      where g.user_id = goal_likes.goal_owner and g.id = goal_likes.goal_id
    )
  );

-- Only an accepted friend may like, only for themselves, never their own
-- goal, and only while the goal is actually shared (the goals-RLS-filtered
-- exists can only match via the "friends read shared goals" policy here,
-- since liking your own goal is excluded).
drop policy if exists "like a friends shared goal" on public.goal_likes;
create policy "like a friends shared goal" on public.goal_likes
  for insert
  with check (
    liker = auth.uid()
    and liker <> goal_owner
    and exists (
      select 1 from public.goals g
      where g.user_id = goal_likes.goal_owner and g.id = goal_likes.goal_id
        and (g.data->>'sharedWithFriends')::boolean is true
    )
  );

-- Unlike: remove only your own like.
drop policy if exists "remove own like" on public.goal_likes;
create policy "remove own like" on public.goal_likes
  for delete
  using (liker = auth.uid());

-- ------------------------------------------------------------------ messages
-- Minimal 1:1 chat between accepted friends. Bodies are length-capped at the
-- database (1..500 chars) so a hostile client can't store megabytes. No
-- update/delete policies: messages are immutable once sent.
create table if not exists public.messages (
  id         bigint generated always as identity primary key,
  sender     uuid not null references auth.users (id) on delete cascade,
  recipient  uuid not null references auth.users (id) on delete cascade,
  body       text not null,
  created_at timestamptz not null default now(),
  constraint messages_body_len check (char_length(body) between 1 and 500),
  constraint messages_no_self check (sender <> recipient)
);

create index if not exists messages_thread_idx
  on public.messages (sender, recipient, created_at desc);
create index if not exists messages_thread_rev_idx
  on public.messages (recipient, sender, created_at desc);

alter table public.messages enable row level security;

-- Each participant reads their own conversations only.
drop policy if exists "read own conversations" on public.messages;
create policy "read own conversations" on public.messages
  for select
  using (auth.uid() in (sender, recipient));

-- Send only as yourself, and only to an accepted friend.
drop policy if exists "message an accepted friend" on public.messages;
create policy "message an accepted friend" on public.messages
  for insert
  with check (
    sender = auth.uid()
    and exists (
      select 1 from public.friendships f
      where f.status = 'accepted'
        and (
             (f.requester = auth.uid() and f.addressee = messages.recipient)
          or (f.addressee = auth.uid() and f.requester = messages.recipient)
        )
    )
  );
