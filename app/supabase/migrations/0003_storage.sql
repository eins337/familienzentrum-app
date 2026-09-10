-- Storage buckets for post photos, child avatars, and Kita documents.
-- All private (not publicly listable) — any signed-in user may read, only
-- Kita-Team may write, matching the same "closed area" model as the rest
-- of the app.

insert into storage.buckets (id, name, public)
values
  ('post-photos', 'post-photos', false),
  ('avatars', 'avatars', false),
  ('documents', 'documents', false)
on conflict (id) do nothing;

create policy "post-photos readable by signed-in"
  on storage.objects for select to authenticated
  using (bucket_id = 'post-photos');
create policy "post-photos writable by team"
  on storage.objects for insert to authenticated
  with check (bucket_id = 'post-photos' and public.is_team());
create policy "post-photos deletable by team"
  on storage.objects for delete to authenticated
  using (bucket_id = 'post-photos' and public.is_team());

create policy "avatars readable by signed-in"
  on storage.objects for select to authenticated
  using (bucket_id = 'avatars');
create policy "avatars writable by team"
  on storage.objects for insert to authenticated
  with check (bucket_id = 'avatars' and public.is_team());
create policy "avatars deletable by team"
  on storage.objects for delete to authenticated
  using (bucket_id = 'avatars' and public.is_team());

create policy "documents readable by signed-in"
  on storage.objects for select to authenticated
  using (bucket_id = 'documents');
create policy "documents writable by team"
  on storage.objects for insert to authenticated
  with check (bucket_id = 'documents' and public.is_team());
create policy "documents deletable by team"
  on storage.objects for delete to authenticated
  using (bucket_id = 'documents' and public.is_team());
