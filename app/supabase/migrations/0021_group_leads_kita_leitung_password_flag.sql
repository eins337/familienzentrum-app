-- Adds: a settable Gruppenleitung (group lead) per group, a Kita-Leitung
-- flag admins can grant to staff, and a must_change_password flag so a
-- first login via invite code can be forced straight into a password
-- change (after which the invite code stops working as a password).

alter table public.groups add column lead_profile_id uuid references public.profiles(id) on delete set null;
alter table public.profiles add column kita_leitung boolean not null default false;
alter table public.profiles add column must_change_password boolean not null default false;

-- kita_leitung is a privilege flag like role/is_admin — without this, RLS
-- would let any signed-in user grant it to themselves directly via the
-- REST API, bypassing the admin-only UI entirely (must_change_password
-- carries no such risk, since setting it on yourself is harmless).
drop policy "profiles self update" on public.profiles;
create policy "profiles self update" on public.profiles for update to authenticated
  using (id = auth.uid())
  with check (
    id = auth.uid()
    and role = (select role from public.profiles where id = auth.uid())
    and is_admin = (select is_admin from public.profiles where id = auth.uid())
    and kita_leitung = (select kita_leitung from public.profiles where id = auth.uid())
  );
