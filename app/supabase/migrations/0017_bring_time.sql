-- "Bringzeit" — the time a family drops their child off, editable by the
-- family and visible to the team. Reuses the existing "children updatable
-- by own family" RLS policy (is_family_member(family_id)) — no new policy
-- needed for the parent-facing write. *_updated_at/_by let the team-facing
-- Mitteilungen feed surface a "changed" notice without a separate table,
-- the same synthesized-from-live-data pattern already used there.
alter table public.children
  add column bring_time text,
  add column bring_time_note text,
  add column bring_time_updated_at timestamptz,
  add column bring_time_updated_by uuid references public.profiles(id);
