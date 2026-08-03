-- Budget Tree — stop `profiles` being bulk-readable
--
-- The SELECT policy was `using (auth.uid() is not null)`: any signed-in user
-- could `GET /rest/v1/profiles?select=*` and walk away with every account's id,
-- username, display name, bio, avatar and last-seen time. That is what made
-- victim enumeration free for the friendship-forgery bugs, and it hands out
-- more than the app ever needs.
--
-- Reads split into two kinds, so they get two mechanisms:
--
--   Rows you have a reason to see  -> RLS. Your own row, plus anyone you have
--                                     a friendship row with in either
--                                     direction. Status is deliberately not
--                                     checked: a *pending* request has to
--                                     render the requester's name and avatar
--                                     before you can accept it.
--
--   Finding a stranger to add      -> a SECURITY DEFINER function. Search
--                                     inherently has to look at rows you can't
--                                     otherwise see, so it is bounded instead:
--                                     a minimum query length, a hard row cap,
--                                     self excluded, and only the columns the
--                                     result row actually renders. Bio,
--                                     status mode and pinned goal are not
--                                     returned for strangers.
--
-- Both functions are `security definer` and executable by `authenticated`, so
-- the Supabase advisor will list them. That is intentional here and is the
-- documented escape hatch for exactly this pattern: they are read-only, they
-- re-derive the caller from auth.uid() rather than trusting an argument, and
-- they return strictly less than the policy they replace.

-- ─────────────────────────────────────────────────────────────────────────
-- SELECT policies
-- ─────────────────────────────────────────────────────────────────────────

drop policy if exists "profiles readable by authenticated" on public.profiles;

drop policy if exists "read own profile" on public.profiles;
create policy "read own profile" on public.profiles
  for select
  using (auth.uid() = id);

-- Friends *and* pending requests in both directions. Without the pending case
-- the requests list would render blank rows.
drop policy if exists "read profiles you are connected to" on public.profiles;
create policy "read profiles you are connected to" on public.profiles
  for select
  using (
    exists (
      select 1
      from public.friendships f
      where (f.requester = auth.uid() and f.addressee = profiles.id)
         or (f.addressee = auth.uid() and f.requester = profiles.id)
    )
  );

-- ─────────────────────────────────────────────────────────────────────────
-- Username search
--
-- `search_path` includes `extensions` because `profiles.username` is citext
-- and citext lives there since 20260802221910 — without it the ILIKE operator
-- doesn't resolve inside the function body.
-- ─────────────────────────────────────────────────────────────────────────

create or replace function public.search_profiles(q text)
returns table (
  id           uuid,
  username     text,
  display_name text,
  avatar_b64   text,
  last_seen_at timestamptz
)
language sql
security definer
stable
set search_path = public, extensions
as $$
  select p.id,
         p.username::text,
         p.display_name,
         p.avatar_b64,
         p.last_seen_at
  from public.profiles p
  where auth.uid() is not null           -- never usable by anon
    and length(btrim(q)) >= 2            -- one letter would page the table
    and p.id <> auth.uid()               -- yourself is not a search result
    and p.username ilike '%' || btrim(q) || '%'
  order by p.username
  limit 20;
$$;

revoke all on function public.search_profiles(text) from public, anon;
grant execute on function public.search_profiles(text) to authenticated;

-- ─────────────────────────────────────────────────────────────────────────
-- Username availability
--
-- Onboarding needs to know whether a name is taken, which is a question about
-- a row the caller must not be able to read. Returning a bare boolean answers
-- it without exposing whose row it is.
-- ─────────────────────────────────────────────────────────────────────────

create or replace function public.username_available(candidate text)
returns boolean
language sql
security definer
stable
set search_path = public, extensions
as $$
  select auth.uid() is not null
     and not exists (
       select 1
       from public.profiles p
       where p.username = btrim(candidate)
         and p.id <> auth.uid()
     );
$$;

revoke all on function public.username_available(text) from public, anon;
grant execute on function public.username_available(text) to authenticated;
