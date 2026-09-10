-- Row Level Security — mirrors the access model from the prior Firestore
-- rules: signed-in users can read most kita-wide content, only Kita-Team
-- (role='team') can write posts/events/docs, only admins manage
-- invites/families/team roles, and families only ever touch their own data.

alter table public.groups enable row level security;
alter table public.group_team_members enable row level security;
alter table public.families enable row level security;
alter table public.profiles enable row level security;
alter table public.family_members enable row level security;
alter table public.children enable row level security;
alter table public.posts enable row level security;
alter table public.post_comments enable row level security;
alter table public.chats enable row level security;
alter table public.messages enable row level security;
alter table public.playdate_requests enable row level security;
alter table public.sick_reports enable row level security;
alter table public.events enable row level security;
alter table public.closures enable row level security;
alter table public.documents enable row level security;
alter table public.speiseplan enable row level security;
alter table public.invites enable row level security;

-- groups / group_team_members ------------------------------------------------
create policy "groups readable by signed-in" on public.groups for select to authenticated using (true);
create policy "groups writable by team" on public.groups for all to authenticated using (public.is_team()) with check (public.is_team());

create policy "group team readable by signed-in" on public.group_team_members for select to authenticated using (true);
create policy "group team writable by team" on public.group_team_members for all to authenticated using (public.is_team()) with check (public.is_team());

-- families --------------------------------------------------------------
create policy "families readable by signed-in" on public.families for select to authenticated using (true);
create policy "families writable by admin" on public.families for all to authenticated using (public.is_admin()) with check (public.is_admin());
create policy "families updatable by team" on public.families for update to authenticated using (public.is_team()) with check (public.is_team());

-- family_members ----------------------------------------------------------
create policy "family members readable by signed-in" on public.family_members for select to authenticated using (true);
create policy "family members writable by admin" on public.family_members for all to authenticated using (public.is_admin()) with check (public.is_admin());

-- profiles ----------------------------------------------------------------
create policy "profiles readable by signed-in" on public.profiles for select to authenticated using (true);
create policy "profiles self insert" on public.profiles for insert to authenticated with check (id = auth.uid());
create policy "profiles self update" on public.profiles for update to authenticated
  using (id = auth.uid())
  with check (
    id = auth.uid()
    and role = (select role from public.profiles where id = auth.uid())
    and is_admin = (select is_admin from public.profiles where id = auth.uid())
  );
create policy "profiles admin manage" on public.profiles for all to authenticated using (public.is_admin()) with check (public.is_admin());

-- children ------------------------------------------------------------------
create policy "children readable by signed-in" on public.children for select to authenticated using (true);
create policy "children writable by team" on public.children for all to authenticated using (public.is_team()) with check (public.is_team());
create policy "children updatable by own family" on public.children for update to authenticated
  using (public.is_family_member(family_id)) with check (public.is_family_member(family_id));

-- posts + comments ----------------------------------------------------------
create policy "posts readable by signed-in" on public.posts for select to authenticated using (true);
create policy "posts insert by team" on public.posts for insert to authenticated with check (public.is_team() and author_id = auth.uid());
create policy "posts update by team" on public.posts for update to authenticated using (public.is_team()) with check (public.is_team());
create policy "posts delete by team" on public.posts for delete to authenticated using (public.is_team());

create policy "comments readable by signed-in" on public.post_comments for select to authenticated using (true);
create policy "comments insert by author" on public.post_comments for insert to authenticated with check (author_id = auth.uid());

-- chats + messages ------------------------------------------------------------
create policy "chats readable by participant" on public.chats for select to authenticated using (auth.uid() = any(participant_ids));
create policy "chats insertable by participant" on public.chats for insert to authenticated with check (auth.uid() = any(participant_ids));
create policy "chats updatable by participant" on public.chats for update to authenticated using (auth.uid() = any(participant_ids));

create policy "messages readable by chat participant" on public.messages for select to authenticated using (
  exists (select 1 from public.chats c where c.id = chat_id and auth.uid() = any(c.participant_ids))
);
create policy "messages insertable by chat participant" on public.messages for insert to authenticated with check (
  sender_id = auth.uid()
  and exists (select 1 from public.chats c where c.id = chat_id and auth.uid() = any(c.participant_ids))
);

-- playdate_requests -------------------------------------------------------
create policy "playdates readable by involved parties" on public.playdate_requests for select to authenticated using (
  public.is_team() or public.is_family_member(from_family_id) or public.is_family_member(to_family_id)
);
create policy "playdates insertable by requester" on public.playdate_requests for insert to authenticated with check (
  from_uid = auth.uid() and public.is_family_member(from_family_id)
);
create policy "playdates updatable by involved family" on public.playdate_requests for update to authenticated using (
  public.is_family_member(from_family_id) or public.is_family_member(to_family_id)
);

-- sick_reports ----------------------------------------------------------
create policy "sick reports readable by team" on public.sick_reports for select to authenticated using (public.is_team());
create policy "sick reports insertable by own family" on public.sick_reports for insert to authenticated with check (public.is_family_member(family_id));
create policy "sick reports updatable by team" on public.sick_reports for update to authenticated using (public.is_team()) with check (public.is_team());

-- events / closures / documents / speiseplan -------------------------------
create policy "events readable by signed-in" on public.events for select to authenticated using (true);
create policy "events writable by team" on public.events for all to authenticated using (public.is_team()) with check (public.is_team());

create policy "closures readable by signed-in" on public.closures for select to authenticated using (true);
create policy "closures writable by team" on public.closures for all to authenticated using (public.is_team()) with check (public.is_team());

create policy "documents readable by signed-in" on public.documents for select to authenticated using (true);
create policy "documents writable by team" on public.documents for all to authenticated using (public.is_team()) with check (public.is_team());

create policy "speiseplan readable by signed-in" on public.speiseplan for select to authenticated using (true);
create policy "speiseplan writable by team" on public.speiseplan for all to authenticated using (public.is_team()) with check (public.is_team());

-- invites -------------------------------------------------------------------
-- No anon/authenticated policy grants read access at all: redemption happens
-- exclusively through the `redeem-invite` Edge Function using the service
-- role key, which bypasses RLS entirely. Only admins manage invites here.
create policy "invites managed by admin" on public.invites for all to authenticated using (public.is_admin()) with check (public.is_admin());

-- ─────────────────────────────────────────────────────────────────────────
-- Narrow RPCs for parent-side interactions that would otherwise need a
-- broad UPDATE grant on posts/events (likes, RSVPs, poll votes). Each is
-- SECURITY DEFINER so it can touch exactly one column safely.
-- ─────────────────────────────────────────────────────────────────────────
create or replace function public.toggle_post_like(p_post_id uuid)
returns void language plpgsql security definer set search_path = public as $$
begin
  if not exists (select 1 from public.posts where id = p_post_id) then
    raise exception 'post not found';
  end if;
  update public.posts set likes = case
    when auth.uid() = any(likes) then array_remove(likes, auth.uid())
    else array_append(likes, auth.uid())
  end
  where id = p_post_id;
end;
$$;
grant execute on function public.toggle_post_like(uuid) to authenticated;

create or replace function public.toggle_event_rsvp(p_event_id uuid)
returns void language plpgsql security definer set search_path = public as $$
begin
  update public.events set rsvp_uids = case
    when auth.uid() = any(rsvp_uids) then array_remove(rsvp_uids, auth.uid())
    else array_append(rsvp_uids, auth.uid())
  end
  where id = p_event_id;
end;
$$;
grant execute on function public.toggle_event_rsvp(uuid) to authenticated;

create or replace function public.vote_poll(p_post_id uuid, p_option_index int)
returns void language plpgsql security definer set search_path = public as $$
declare
  v_poll jsonb;
  v_options jsonb;
  v_voters jsonb;
begin
  select poll into v_poll from public.posts where id = p_post_id for update;
  if v_poll is null then
    raise exception 'post has no poll';
  end if;
  v_voters := coalesce(v_poll->'voter_ids', '[]'::jsonb);
  if v_voters @> to_jsonb(auth.uid()::text) then
    return; -- already voted, no-op
  end if;
  v_options := v_poll->'options';
  v_options := jsonb_set(
    v_options, array[p_option_index::text, 'votes'],
    to_jsonb(coalesce((v_options->p_option_index->>'votes')::int, 0) + 1)
  );
  v_voters := v_voters || to_jsonb(auth.uid()::text);
  update public.posts set poll = jsonb_set(jsonb_set(v_poll, '{options}', v_options), '{voter_ids}', v_voters)
  where id = p_post_id;
end;
$$;
grant execute on function public.vote_poll(uuid, int) to authenticated;

-- keep posts.comment_count in sync --------------------------------------
create or replace function public.bump_comment_count()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  if tg_op = 'INSERT' then
    update public.posts set comment_count = comment_count + 1 where id = new.post_id;
  elsif tg_op = 'DELETE' then
    update public.posts set comment_count = greatest(comment_count - 1, 0) where id = old.post_id;
  end if;
  return null;
end;
$$;
create trigger post_comments_bump_count
  after insert or delete on public.post_comments
  for each row execute function public.bump_comment_count();

-- keep chats.last_message_at in sync -------------------------------------
create or replace function public.bump_chat_last_message()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  update public.chats set last_message_at = new.created_at where id = new.chat_id;
  return new;
end;
$$;
create trigger messages_bump_chat
  after insert on public.messages
  for each row execute function public.bump_chat_last_message();
