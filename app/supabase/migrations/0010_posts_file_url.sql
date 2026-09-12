-- posts.file_name/file_size_label existed with no actual file_url to open
-- (the pinned Elternbrief card looked like an attachment but had nothing
-- behind it) — add the missing column so attachments are real.
alter table public.posts add column file_url text;
