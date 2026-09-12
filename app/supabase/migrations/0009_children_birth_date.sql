-- Adds a full birth_date alongside the existing birth_year (kept for
-- back-compat / rows that only have a year) so the app can show upcoming
-- birthdays. Nullable: not every child needs one recorded.
alter table public.children add column birth_date date;
