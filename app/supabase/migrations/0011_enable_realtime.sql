-- The app streams these tables via supabase_flutter's .stream() (Postgres
-- Changes over Realtime), but no table was ever added to the
-- supabase_realtime publication — so every .stream() call failed with
-- RealtimeSubscribeException ("Please check Realtime is enabled").
alter publication supabase_realtime add table
  posts,
  post_comments,
  chats,
  messages,
  invites,
  families,
  children,
  profiles,
  events,
  closures,
  documents,
  family_members,
  sick_reports,
  playdate_requests;
