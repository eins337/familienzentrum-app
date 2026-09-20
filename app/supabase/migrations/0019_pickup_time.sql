-- Mirrors 0017_bring_time.sql for pick-up: Bringzeit alone wasn't enough,
-- families also need to record when they collect their child.
alter table public.children
  add column pickup_time text,
  add column pickup_time_note text,
  add column pickup_time_updated_at timestamptz,
  add column pickup_time_updated_by uuid references public.profiles(id);
