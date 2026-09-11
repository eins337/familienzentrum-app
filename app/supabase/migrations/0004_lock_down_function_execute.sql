-- Supabase's default privileges grant EXECUTE on every new function in the
-- public schema directly to anon/authenticated/service_role (so PostgREST
-- can auto-expose RPCs) — the security advisor caught that this silently
-- made every SECURITY DEFINER helper/RPC from 0002_rls.sql callable by
-- signed-out clients via PostgREST's /rpc endpoint, bypassing RLS entirely
-- for the three mutation RPCs (an anonymous client could call
-- toggle_post_like/toggle_event_rsvp/vote_poll and mutate rows despite
-- posts/events RLS being scoped `to authenticated`, since a SECURITY
-- DEFINER function runs as its owner and ignores table RLS altogether).
-- Lock all of them down: internal helpers get no direct API access at
-- all (only RLS policies/triggers call them), the three user-facing
-- RPCs are restricted to `authenticated`.

revoke execute on function public.is_team() from anon, authenticated;
revoke execute on function public.is_admin() from anon, authenticated;
revoke execute on function public.is_family_member(uuid) from anon, authenticated;
revoke execute on function public.current_family_id() from anon, authenticated;
revoke execute on function public.bump_comment_count() from anon, authenticated;
revoke execute on function public.bump_chat_last_message() from anon, authenticated;

revoke execute on function public.toggle_post_like(uuid) from anon, authenticated;
revoke execute on function public.toggle_event_rsvp(uuid) from anon, authenticated;
revoke execute on function public.vote_poll(uuid, int) from anon, authenticated;
grant execute on function public.toggle_post_like(uuid) to authenticated;
grant execute on function public.toggle_event_rsvp(uuid) to authenticated;
grant execute on function public.vote_poll(uuid, int) to authenticated;

-- Also strip the automatic default-privilege grant so any *future*
-- function created in public isn't silently exposed to anon either.
alter default privileges in schema public revoke execute on functions from anon;
