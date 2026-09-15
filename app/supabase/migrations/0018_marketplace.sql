-- Tauschbörse: a cross-group marketplace where any parent can offer or
-- request items (clothes, toys, equipment) that other families can react
-- to — open to every signed-in family/team member, not scoped to a group,
-- mirroring the open-RLS + client-scoped pattern already used for
-- `posts`/`groups`.
create table public.marketplace_items (
  id uuid primary key default gen_random_uuid(),
  author_id uuid not null references public.profiles(id),
  family_id uuid references public.families(id),
  title text not null,
  description text,
  status text not null default 'available' check (status in ('available', 'reserved', 'given_away')),
  created_at timestamptz not null default now()
);

alter table public.marketplace_items enable row level security;

create policy "marketplace items readable by signed-in" on public.marketplace_items
  for select to authenticated using (true);

create policy "marketplace items insertable by author" on public.marketplace_items
  for insert to authenticated with check (author_id = auth.uid());

create policy "marketplace items updatable by author or team" on public.marketplace_items
  for update to authenticated using (author_id = auth.uid() or public.is_team())
  with check (author_id = auth.uid() or public.is_team());

create policy "marketplace items deletable by author or team" on public.marketplace_items
  for delete to authenticated using (author_id = auth.uid() or public.is_team());

alter publication supabase_realtime add table marketplace_items;
