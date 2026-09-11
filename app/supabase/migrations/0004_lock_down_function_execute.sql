-- Supabase's default privileges grant EXECUTE on every new function in the
-- public schema directly to anon/authenticated/service_role (so PostgREST
-- can auto-expose RPCs) — the security advisor caught that this silently
-- made every SECURITY DEFINER helper/RPC from 0002_rls.sql callable by
-- signed-out clients via PostgREST's /rpc endpoint, bypassing RLS entirely
-- for the three mutation RPCs (an anonymous client could call
-- toggle_post_like/toggle_event_rsvp/vote_poll and mutate rows despite
-- posts/events RLS being scoped `to authenticated`, since a SECURITY
-- DEFINER function runs as its owner and ignores table RLS altogether).
--
-- `authenticated` keeps EXECUTE on the four RLS helper functions
-- (is_team/is_admin/is_family_member/current_family_id): they're called
-- from *inside* RLS policy expressions (`using (public.is_team())`),
-- which Postgres evaluates in the querying role's context — it checks
-- EXECUTE privilege against the caller before the SECURITY DEFINER body
-- ever runs, so revoking it from authenticated breaks every policy that
-- references them (found the hard way: "permission denied for function
-- is_team", 42501, on the very first authenticated request after an
-- earlier draft of this migration revoked from authenticated too).
-- `anon` never needs it — no policy here is ever scoped `to anon`, so
-- anon-role requests never trigger evaluation of these functions via
-- RLS, only via direct (and now blocked) /rpc calls.
--
-- The two trigger functions (bump_comment_count/bump_chat_last_message)
-- are conventionally exempt from that same invoker-EXECUTE check since
-- they're invoked by the trigger manager rather than a direct call, but
-- grant authenticated EXECUTE anyway — zero security cost (they only
-- recompute a derived counter/timestamp) and one less thing to be wrong
-- about twice.
--
-- The three mutation RPCs are restricted to `authenticated` only.

revoke execute on function public.is_team() from anon, authenticated;
revoke execute on function public.is_admin() from anon, authenticated;
revoke execute on function public.is_family_member(uuid) from anon, authenticated;
revoke execute on function public.current_family_id() from anon, authenticated;
grant execute on function public.is_team() to authenticated;
grant execute on function public.is_admin() to authenticated;
grant execute on function public.is_family_member(uuid) to authenticated;
grant execute on function public.current_family_id() to authenticated;

revoke execute on function public.bump_comment_count() from anon, authenticated;
revoke execute on function public.bump_chat_last_message() from anon, authenticated;
grant execute on function public.bump_comment_count() to authenticated;
grant execute on function public.bump_chat_last_message() to authenticated;

revoke execute on function public.toggle_post_like(uuid) from anon, authenticated;
revoke execute on function public.toggle_event_rsvp(uuid) from anon, authenticated;
revoke execute on function public.vote_poll(uuid, int) from anon, authenticated;
grant execute on function public.toggle_post_like(uuid) to authenticated;
grant execute on function public.toggle_event_rsvp(uuid) to authenticated;
grant execute on function public.vote_poll(uuid, int) to authenticated;

-- Also strip the automatic default-privilege grant so any *future*
-- function created in public isn't silently exposed to anon either.
alter default privileges in schema public revoke execute on functions from anon;
