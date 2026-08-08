-- Budget Tree — tree health on the profile
--
-- So a friend opening your garden sees whether your tree is thriving, the same
-- signal you see on your own dashboard. Nullable: a user who has never
-- answered a check-in has no score, which the UI renders as "just planted"
-- rather than as zero.
--
-- Two deliberate limits.
--
-- 1. **This is not added to search_profiles.** That SECURITY DEFINER function
--    exists precisely so a stranger searching a username gets less than a
--    friend does, and it already withholds `bio` and the status fields. A
--    behavioural score belongs firmly in that category: "this person has been
--    slipping on their budget" is not something two characters of a username
--    should buy you.
--
-- 2. **The score is client-computed and client-written**, and the "update own
--    profile" policy has no column privilege restriction, so a user can
--    publish any value in range. Accepted: the number is a social flourish,
--    not an authorisation input, and nothing reads it back for a decision. The
--    CHECK below bounds the lie. If it ever needs to be trustworthy, derive it
--    server-side from public.check_ins with a SECURITY DEFINER function
--    instead, since friends cannot read that table directly.
--
-- No new SELECT policy is needed: the two policies from
-- 20260803180819_restrict_profile_reads.sql are row-level, so anyone already
-- allowed to read your profile row gets this column with it.

alter table public.profiles
  add column if not exists health_score smallint;

do $$
begin
  if not exists (
    select 1 from pg_constraint
    where conname = 'profiles_health_score_range'
      and conrelid = 'public.profiles'::regclass
  ) then
    alter table public.profiles
      add constraint profiles_health_score_range
      check (health_score is null or health_score between 0 and 100);
  end if;
end $$;
