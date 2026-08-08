-- Budget Tree — check-ins
--
-- The app's record of what the user actually *did*, as opposed to what they
-- planned. On each pay day (and each goal watering) the user confirms how the
-- period went, optionally recording what they really spent per branch. This is
-- the only plan-versus-actual data in the system, and it is what tree health
-- and the coach's reflections are built on.
--
-- Same shape as the other SyncedStore-backed collections: keyed (user_id, id)
-- with the whole model in a `data` jsonb column, so the model's toJson/fromJson
-- is the entire schema and adding a field needs no migration.
--
-- Only *resolved* check-ins (confirmed or missed) are ever written here.
-- Pending ones are derived client-side from the budgets' pay schedules, so
-- there is no cross-device merge to get wrong: every write to this table is
-- monotonic and re-writing the same row is a no-op.
--
-- Explicit DDL rather than the `(like public.budgets including all)` idiom used
-- by the initial schema: LIKE copies column defaults and the primary key but
-- **not** RLS policies, so the copy reads as though it inherits security it
-- does not.

create table if not exists public.check_ins (
  user_id    uuid not null references auth.users on delete cascade,
  id         text not null,
  data       jsonb not null,
  updated_at timestamptz not null default now(),
  primary key (user_id, id)
);

-- Redundant on paper: the `ensure_rls` ddl_command_end event trigger (backed by
-- public.rls_auto_enable()) already turned RLS on for this table the moment it
-- was created. Stated anyway so this migration describes its own end state, and
-- as a reminder that the trigger enables RLS *without* adding a policy — which
-- leaves a table deny-all until the one below exists.
alter table public.check_ins enable row level security;

drop policy if exists "own rows" on public.check_ins;
create policy "own rows" on public.check_ins
  for all
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

-- `auto_expose_new_tables` is left unset in config.toml, which means new
-- entities are NOT reachable through the Data API roles without an explicit
-- grant. The older tables predate that default and rely on the legacy
-- behaviour; this one cannot. Verify after pushing with:
--   select has_table_privilege('authenticated', 'public.check_ins', 'select');
grant select, insert, update, delete on public.check_ins to authenticated;
