-- Budget Tree — take client write privileges off acorn_messages
--
-- This project still carries Supabase's legacy default privileges, so every
-- table created in `public` is automatically granted the full set to `anon`
-- and `authenticated`, whatever the migration that created it asked for.
-- Verified after pushing 20260808121000: acorn_messages came out with
-- INSERT/UPDATE/DELETE/SELECT for both roles despite that migration granting
-- only select and delete.
--
-- Nothing was actually exposed: RLS is on, and `acorn_messages` has no INSERT
-- and no UPDATE policy, so both are denied for any role that does not bypass
-- RLS. But for this table the privilege ought to match the intent, because the
-- intent is load-bearing rather than cosmetic. The ai-coach function reads this
-- transcript back as the conversation history it feeds to the model, so a row
-- with role = 'assistant' written by a client would let a user put words in
-- Acorn's mouth and steer every later reply. That is the one thing this table's
-- design exists to prevent, and it should not rest on a single mechanism.
--
-- Assistant and user turns alike are written by the edge function under the
-- service role, which bypasses both RLS and these grants.

revoke insert, update, truncate, references, trigger
  on public.acorn_messages from anon, authenticated;

-- Reading and clearing your own conversation stay available to a signed-in
-- user (and are still gated to their own rows by RLS). `anon` keeps nothing
-- useful: with no session auth.uid() is null, so every policy fails anyway.
revoke all on public.acorn_messages from anon;
grant select, delete on public.acorn_messages to authenticated;

do $$
begin
  if has_table_privilege('authenticated', 'public.acorn_messages', 'insert') then
    raise exception 'acorn_messages is still insertable by authenticated';
  end if;
  if has_table_privilege('authenticated', 'public.acorn_messages', 'update') then
    raise exception 'acorn_messages is still updatable by authenticated';
  end if;
  if has_table_privilege('anon', 'public.acorn_messages', 'select') then
    raise exception 'acorn_messages is still readable by anon';
  end if;
  if not has_table_privilege('authenticated', 'public.acorn_messages', 'select') then
    raise exception 'acorn_messages is no longer readable by authenticated';
  end if;
end $$;
