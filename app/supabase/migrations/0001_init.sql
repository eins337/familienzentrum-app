-- Familienzentrum Lank — initial schema.
-- Mirrors the data model from the prior Firebase/Firestore build, adapted
-- to Postgres + Supabase Auth + Row Level Security.

create extension if not exists "pgcrypto";

-- ─────────────────────────────────────────────────────────────────────────
-- Enums
-- ─────────────────────────────────────────────────────────────────────────
create type user_role as enum ('parent', 'team');
create type post_kind as enum ('foto', 'info', 'termin', 'umfrage');
create type post_visibility as enum ('all', 'group', 'beirat');
create type playdate_status as enum ('pending', 'confirmed', 'declined');

-- ─────────────────────────────────────────────────────────────────────────
-- Core tables
-- ─────────────────────────────────────────────────────────────────────────

create table public.groups (
  id text primary key, -- 'blau' | 'gelb' | 'rot'
  name text not null,
  color text not null,
  child_count int not null default 0,
  created_at timestamptz not null default now()
);

create table public.group_team_members (
  id uuid primary key default gen_random_uuid(),
  group_id text not null references public.groups(id) on delete cascade,
  name text not null,
  title text not null, -- 'Gruppenleitung' | 'Fachkraft'
  sort_order int not null default 0
);

create table public.families (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  created_at timestamptz not null default now()
);

-- profiles.id == auth.users.id (1:1)
create table public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  email text not null unique,
  display_name text not null,
  role user_role not null default 'parent',
  family_id uuid references public.families(id) on delete set null,
  is_admin boolean not null default false,
  group_ids text[] not null default '{}', -- team members: groups they belong to
  staff_title text,
  disabled boolean not null default false,
  notification_settings jsonb not null default '{"posts":true,"chat":true,"playdates":true,"quietHours":false}',
  privacy_settings jsonb not null default '{"contactVisibleInChat":true,"playdateRequestsScope":"group","photoConsentAppOnly":true}',
  push_token text,
  created_at timestamptz not null default now()
);

create table public.family_members (
  family_id uuid not null references public.families(id) on delete cascade,
  user_id uuid not null references public.profiles(id) on delete cascade,
  relation text not null default 'Elternteil', -- 'Mutter' | 'Vater' | 'Abholberechtigt' | ...
  primary key (family_id, user_id)
);

create table public.children (
  id uuid primary key default gen_random_uuid(),
  family_id uuid not null references public.families(id) on delete cascade,
  group_id text references public.groups(id) on delete set null,
  name text not null,
  birth_year int,
  avatar_url text,
  tags text[] not null default '{}', -- 'Nussallergie', 'Vegetarisch', ...
  photo_consent_group boolean not null default true,
  photo_consent_website boolean not null default false,
  created_at timestamptz not null default now()
);

create table public.posts (
  id uuid primary key default gen_random_uuid(),
  author_id uuid not null references public.profiles(id) on delete cascade,
  group_id text references public.groups(id) on delete cascade, -- null = kita-wide
  kind post_kind not null default 'info',
  visibility post_visibility not null default 'all',
  title text,
  body text not null default '',
  pinned boolean not null default false,
  photo_urls text[] not null default '{}',
  file_name text,
  file_size_label text,
  event_date timestamptz,
  event_location text,
  poll jsonb, -- {options:[{label,votes}], voter_ids:[]}
  likes uuid[] not null default '{}',
  rsvps uuid[] not null default '{}',
  comment_count int not null default 0,
  created_at timestamptz not null default now()
);

create table public.post_comments (
  id uuid primary key default gen_random_uuid(),
  post_id uuid not null references public.posts(id) on delete cascade,
  author_id uuid not null references public.profiles(id) on delete cascade,
  body text not null,
  created_at timestamptz not null default now()
);

create table public.chats (
  id uuid primary key default gen_random_uuid(),
  is_group boolean not null default false,
  name text, -- set for group chats ("Eltern Gruppe Blau", "Kita-Team")
  group_id text references public.groups(id) on delete set null,
  participant_ids uuid[] not null default '{}',
  created_at timestamptz not null default now(),
  last_message_at timestamptz not null default now()
);

create table public.messages (
  id uuid primary key default gen_random_uuid(),
  chat_id uuid not null references public.chats(id) on delete cascade,
  sender_id uuid not null references public.profiles(id) on delete cascade,
  body text not null,
  created_at timestamptz not null default now()
);

create table public.playdate_requests (
  id uuid primary key default gen_random_uuid(),
  from_uid uuid not null references public.profiles(id) on delete cascade,
  from_family_id uuid not null references public.families(id) on delete cascade,
  from_child_id uuid not null references public.children(id) on delete cascade,
  to_family_id uuid not null references public.families(id) on delete cascade,
  to_child_id uuid not null references public.children(id) on delete cascade,
  proposed_slots jsonb not null default '[]', -- [{date,time_range,location}]
  status playdate_status not null default 'pending',
  confirmed_slot_index int,
  message text,
  chat_id uuid references public.chats(id) on delete set null,
  created_at timestamptz not null default now()
);

create table public.sick_reports (
  id uuid primary key default gen_random_uuid(),
  child_id uuid not null references public.children(id) on delete cascade,
  family_id uuid not null references public.families(id) on delete cascade,
  group_id text references public.groups(id) on delete set null,
  date_label text not null, -- e.g. "Heute, 10.09."
  reason text,
  acknowledged boolean not null default false,
  created_at timestamptz not null default now()
);

create table public.events (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  event_date date not null,
  time_label text,
  location text,
  group_id text references public.groups(id) on delete set null, -- null = all groups
  rsvp_uids uuid[] not null default '{}',
  created_at timestamptz not null default now()
);

create table public.closures (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  start_date date not null,
  end_date date not null
);

create table public.documents (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  file_url text not null,
  size_label text,
  group_id text references public.groups(id) on delete set null,
  pinned boolean not null default false,
  created_at timestamptz not null default now()
);

create table public.speiseplan (
  id text primary key default 'current',
  items jsonb not null default '[]' -- [{day:'Mo', text:'...'}]
);

create table public.invites (
  email text primary key,
  code text not null,
  role user_role not null default 'parent',
  display_name text not null,
  family_id uuid references public.families(id) on delete set null,
  is_admin boolean not null default false,
  group_ids text[],
  staff_title text,
  created_by uuid references public.profiles(id) on delete set null,
  redeemed_at timestamptz,
  created_at timestamptz not null default now()
);

-- ─────────────────────────────────────────────────────────────────────────
-- Indexes
-- ─────────────────────────────────────────────────────────────────────────
create index posts_group_id_idx on public.posts(group_id);
create index posts_created_at_idx on public.posts(created_at desc);
create index post_comments_post_id_idx on public.post_comments(post_id);
create index messages_chat_id_idx on public.messages(chat_id, created_at);
create index children_family_id_idx on public.children(family_id);
create index playdate_from_family_idx on public.playdate_requests(from_family_id);
create index playdate_to_family_idx on public.playdate_requests(to_family_id);
create index sick_reports_group_idx on public.sick_reports(group_id, acknowledged);

-- ─────────────────────────────────────────────────────────────────────────
-- Helper functions for RLS (SECURITY DEFINER so they bypass RLS themselves
-- and avoid recursive-policy issues when checking the profiles table).
-- ─────────────────────────────────────────────────────────────────────────
create or replace function public.is_team()
returns boolean language sql stable security definer set search_path = public as $$
  select coalesce((select role = 'team' from public.profiles where id = auth.uid()), false);
$$;

create or replace function public.is_admin()
returns boolean language sql stable security definer set search_path = public as $$
  select coalesce((select is_admin from public.profiles where id = auth.uid()), false);
$$;

create or replace function public.is_family_member(p_family_id uuid)
returns boolean language sql stable security definer set search_path = public as $$
  select exists (
    select 1 from public.family_members
    where family_id = p_family_id and user_id = auth.uid()
  );
$$;

create or replace function public.current_family_id()
returns uuid language sql stable security definer set search_path = public as $$
  select family_id from public.profiles where id = auth.uid();
$$;
