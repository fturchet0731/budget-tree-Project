-- Budget Tree — initial schema
--
-- One table per local store. Each row is keyed by (user_id, id) where `id` is
-- the app-generated model id, and the whole model lives in a single `data`
-- jsonb column. This maps 1:1 onto each model's toJson/fromJson, so the schema
-- never needs to change when a model gains a field. Row Level Security
-- restricts every user to only their own rows.

create table if not exists public.budgets (
  user_id    uuid not null references auth.users on delete cascade,
  id         text not null,
  data       jsonb not null,
  updated_at timestamptz not null default now(),
  primary key (user_id, id)
);

create table if not exists public.goals        (like public.budgets including all);
create table if not exists public.categories   (like public.budgets including all);
create table if not exists public.achievements (like public.budgets including all);

-- Enable Row Level Security and add an "own rows only" policy on every table.
do $$
declare t text;
begin
  foreach t in array array['budgets','goals','categories','achievements'] loop
    execute format('alter table public.%I enable row level security;', t);
    execute format('drop policy if exists "own rows" on public.%I;', t);
    execute format($p$
      create policy "own rows" on public.%I
        for all
        using (auth.uid() = user_id)
        with check (auth.uid() = user_id);
    $p$, t);
  end loop;
end $$;
