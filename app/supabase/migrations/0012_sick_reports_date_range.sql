-- v2 redesign: Krankmeldung moves from a free-text "Zeitraum" field to a
-- real multi-day calendar range, and needs to support "active now" status
-- cards on Feed/Profil plus a parent-facing "Zurücknehmen" (cancel) action.
alter table public.sick_reports add column start_date date;
alter table public.sick_reports add column end_date date;
alter table public.sick_reports add column cancelled boolean not null default false;

-- Backfill existing rows so start_date/end_date are never null going
-- forward for new inserts; old free-text rows just collapse to "today".
update public.sick_reports set start_date = created_at::date, end_date = created_at::date where start_date is null;

alter table public.sick_reports alter column start_date set not null;
alter table public.sick_reports alter column end_date set not null;
