-- v2 redesign needs real "Eltern Gruppe X" / "Team Gruppe X" chat channels
-- (README section 5), not just a link to the generic chat list. These are
-- open channels rather than participant_ids-managed 1:1 chats — matching
-- this app's existing precedent for `posts`, which are RLS-readable by any
-- signed-in user with group scoping only enforced client-side, rather than
-- adding per-user array bookkeeping (participant_ids can't self-add under
-- the current "chats updatable by participant" policy anyway, since it
-- checks membership on the row *before* the update).
alter table public.chats add column channel text check (channel in ('eltern', 'team'));

create policy "group chats readable by signed-in" on public.chats
  for select using (is_group and channel is not null);

create policy "group chats insertable by signed-in" on public.chats
  for insert with check (is_group and channel is not null);

create policy "messages readable in group chats" on public.messages
  for select using (exists (select 1 from public.chats c where c.id = messages.chat_id and c.is_group and c.channel is not null));

create policy "messages insertable in group chats" on public.messages
  for insert with check (
    sender_id = auth.uid()
    and exists (select 1 from public.chats c where c.id = messages.chat_id and c.is_group and c.channel is not null)
  );
