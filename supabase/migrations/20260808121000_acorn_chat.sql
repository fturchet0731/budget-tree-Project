-- Budget Tree — Acorn chat, structured reflections, and per-kind AI quota
--
-- Three things the conversational coach needs, in one migration because the
-- quota change and the chat table have to land together.
--
-- ORDERING: deploy the edge function BEFORE pushing this migration.
--   supabase functions deploy ai-coach
--   supabase db push
-- The two-argument check_ai_quota is kept below so an older deployment keeps
-- working during the gap, the same way 20260802222136 handled its cutover.

-- ------------------------------------------------- acorn_messages
--
-- The saved conversation. Real columns like `messages`, not the SyncedStore
-- `data` jsonb pattern, and immutable once written.
--
-- The important part is who may write. **Both turns are inserted by the
-- ai-coach edge function under the service role, which bypasses RLS, and the
-- client has no insert policy at all.** That is deliberate: the function reads
-- this table back as the conversation history it feeds to the model, so if a
-- client could insert a row with role = 'assistant' it could put words in
-- Acorn's mouth and steer every later reply. Taking the write away from the
-- client is what makes the stored transcript trustworthy as prompt context.
-- Do not add an insert policy here.

create table if not exists public.acorn_messages (
  id         bigint generated always as identity primary key,
  user_id    uuid not null references auth.users (id) on delete cascade,
  role       text not null,
  body       text not null,
  created_at timestamptz not null default now(),
  constraint acorn_messages_role_valid check (role in ('user', 'assistant')),
  constraint acorn_messages_body_len check (char_length(body) between 1 and 2000)
);

create index if not exists acorn_messages_user_created_idx
  on public.acorn_messages (user_id, created_at desc);

alter table public.acorn_messages enable row level security;

drop policy if exists "read own acorn chat" on public.acorn_messages;
create policy "read own acorn chat" on public.acorn_messages
  for select using (auth.uid() = user_id);

-- "Clear this conversation" is the one write a client is allowed.
drop policy if exists "delete own acorn chat" on public.acorn_messages;
create policy "delete own acorn chat" on public.acorn_messages
  for delete using (auth.uid() = user_id);

-- No INSERT policy (see above) and no UPDATE policy: the transcript is
-- append-only from the server and immutable thereafter, like `messages`.

-- config.toml leaves auto_expose_new_tables unset, so new entities are not
-- reachable by the Data API roles without an explicit grant. Note insert is
-- deliberately absent even here.
grant select, delete on public.acorn_messages to authenticated;

-- ------------------------------------------------- ai_reflections.report
--
-- A reflection is now a short presentation Acorn walks the user through, so it
-- needs its parts separated (headline, strengths, weaknesses, suggestions,
-- closing) rather than one blob of prose. Nullable, and `text` stays NOT NULL,
-- so a reflection written by an older function deployment still stores.
alter table public.ai_reflections
  add column if not exists report jsonb;

-- ------------------------------------------------- per-kind AI quota
--
-- One shared hourly bucket meant a long chat starved the budget wizard: the
-- counter increments before dispatch, so 25 messages left five calls and the
-- next plan request returned rate_limited, which the app surfaces as an
-- unexplained "AI unavailable". Splitting the bucket by kind keeps the abuse
-- cap tight on the expensive planning actions while letting a conversation
-- actually be a conversation.
alter table private.ai_usage
  add column if not exists kind text not null default 'all';

do $$
begin
  if exists (
    select 1 from pg_constraint
    where conname = 'ai_usage_pkey'
      and conrelid = 'private.ai_usage'::regclass
  ) then
    alter table private.ai_usage drop constraint ai_usage_pkey;
  end if;
end $$;

alter table private.ai_usage
  add constraint ai_usage_pkey primary key (user_id, kind, window_start);

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
  n      integer;
begin
  if uid is null then return false; end if;
  insert into private.ai_usage (user_id, kind, window_start, count)
    values (uid, coalesce(kind, 'all'), bucket, 1)
  on conflict (user_id, kind, window_start)
    do update set count = private.ai_usage.count + 1
  returning count into n;
  return n <= max_calls;
end;
$$;

-- MANDATORY after create-or-replace: Postgres grants EXECUTE to PUBLIC on a
-- newly created function, so without this the quota check would be callable at
-- /rest/v1/rpc/check_ai_quota and a user could burn their own allowance (or
-- anyone else's, since uid is a parameter). Same rule as the two-argument
-- version; see the CLAUDE.md note.
revoke all on function public.check_ai_quota(uuid, integer, text)
  from public, anon, authenticated;
grant execute on function public.check_ai_quota(uuid, integer, text)
  to service_role;

-- Self-verifying probe, mirroring 20260803184819: fail the migration loudly
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
