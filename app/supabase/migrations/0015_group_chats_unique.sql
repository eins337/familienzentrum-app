-- Prevent duplicate "Eltern Gruppe X" / "Team Gruppe X" channels if two
-- people tap the shortcut for the first time at nearly the same moment.
create unique index chats_group_channel_unique on public.chats (group_id, channel) where is_group and channel is not null;
