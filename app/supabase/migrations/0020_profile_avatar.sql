-- User profile pictures. The "avatars" storage bucket (0003_storage.sql)
-- only let the team write to it — fine for child avatars set by staff, but
-- wrong for a user uploading their own photo. Scope uploads by a
-- {uid}/filename path prefix so a user can only write/delete their own.
alter table public.profiles add column avatar_url text;

drop policy "avatars writable by team" on storage.objects;
drop policy "avatars deletable by team" on storage.objects;

create policy "avatars writable by owner or team"
  on storage.objects for insert to authenticated
  with check (bucket_id = 'avatars' and (public.is_team() or (storage.foldername(name))[1] = auth.uid()::text));

create policy "avatars updatable by owner or team"
  on storage.objects for update to authenticated
  using (bucket_id = 'avatars' and (public.is_team() or (storage.foldername(name))[1] = auth.uid()::text))
  with check (bucket_id = 'avatars' and (public.is_team() or (storage.foldername(name))[1] = auth.uid()::text));

create policy "avatars deletable by owner or team"
  on storage.objects for delete to authenticated
  using (bucket_id = 'avatars' and (public.is_team() or (storage.foldername(name))[1] = auth.uid()::text));
