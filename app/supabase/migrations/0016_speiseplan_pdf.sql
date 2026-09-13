-- v2 redesign replaces the structured per-day-text Speiseplan with a PDF
-- upload (KW-tagged), which also gets filed under Infos → Dokumente and
-- announced in the Feed — matching the design handoff's Beitrag-erstellen
-- spec. `items` stays for now (harmless, just unused going forward) rather
-- than a destructive drop.
alter table public.speiseplan add column file_url text;
alter table public.speiseplan add column file_name text;
alter table public.speiseplan add column kw int;
alter table public.speiseplan add column updated_at timestamptz not null default now();
