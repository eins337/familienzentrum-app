-- Parents could INSERT a Krankmeldung but never SELECT or UPDATE their own
-- family's row (only is_team() had SELECT) — meaning the Feed/Profil
-- "active Krankmeldung" status card and the "Zurücknehmen" cancel action
-- could never have worked for parents. Mirrors the existing `children`
-- table's "readable/updatable by own family" pattern.
create policy "sick reports readable by own family" on public.sick_reports
  for select using (is_family_member(family_id));

create policy "sick reports cancellable by own family" on public.sick_reports
  for update using (is_family_member(family_id)) with check (is_family_member(family_id));
