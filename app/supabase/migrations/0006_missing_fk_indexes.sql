-- Covering indexes for foreign key columns the performance advisor
-- flagged as missing (avoids sequential scans on FK-based lookups/joins,
-- and on cascading deletes).

create index chats_group_id_idx on public.chats(group_id);
create index children_group_id_idx on public.children(group_id);
create index documents_group_id_idx on public.documents(group_id);
create index events_group_id_idx on public.events(group_id);
create index family_members_user_id_idx on public.family_members(user_id);
create index group_team_members_group_id_idx on public.group_team_members(group_id);
create index invites_created_by_idx on public.invites(created_by);
create index invites_family_id_idx on public.invites(family_id);
create index messages_sender_id_idx on public.messages(sender_id);
create index playdate_requests_chat_id_idx on public.playdate_requests(chat_id);
create index playdate_requests_from_child_id_idx on public.playdate_requests(from_child_id);
create index playdate_requests_from_uid_idx on public.playdate_requests(from_uid);
create index playdate_requests_to_child_id_idx on public.playdate_requests(to_child_id);
create index post_comments_author_id_idx on public.post_comments(author_id);
create index posts_author_id_idx on public.posts(author_id);
create index profiles_family_id_idx on public.profiles(family_id);
create index sick_reports_child_id_idx on public.sick_reports(child_id);
create index sick_reports_family_id_idx on public.sick_reports(family_id);
