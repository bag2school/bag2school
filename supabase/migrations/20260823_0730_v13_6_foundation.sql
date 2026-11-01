-- Bag2School V13.6
-- Supabase Foundation: profiles, families, family_members, children, access grants.
-- No Schedule/Homework/Preparation/Notification tables are migrated in this step.
--
-- IMPORTANT:
-- This migration is intended to be tested locally first with:
--   supabase db reset
-- It should NOT be pushed to the remote project yet.

create extension if not exists "pgcrypto";

-- =========================================================
-- ENUMS
-- =========================================================

do $$
begin
  create type public.family_member_role as enum (
    'owner',
    'parent_guardian',
    'caregiver'
  );
exception
  when duplicate_object then null;
end
$$;

-- =========================================================
-- PROFILES
-- One application profile per Supabase Auth user.
-- =========================================================

create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  display_name text not null,
  avatar_url text,
  language text not null default 'en',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- =========================================================
-- FAMILIES
-- Owner is represented by the family_members role = owner.
-- =========================================================

create table if not exists public.families (
  id uuid primary key default gen_random_uuid(),
  name text not null default 'My Family',
  created_by uuid not null references public.profiles(id) on delete restrict,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- =========================================================
-- FAMILY MEMBERS
-- =========================================================

create table if not exists public.family_members (
  id uuid primary key default gen_random_uuid(),
  family_id uuid not null references public.families(id) on delete cascade,
  profile_id uuid not null references public.profiles(id) on delete cascade,
  role public.family_member_role not null,
  display_name text not null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (family_id, profile_id)
);

-- Exactly one Owner at most per family.
create unique index if not exists family_members_one_owner_idx
  on public.family_members (family_id)
  where role = 'owner';

-- =========================================================
-- CHILDREN
-- =========================================================

create table if not exists public.children (
  id uuid primary key default gen_random_uuid(),
  family_id uuid not null references public.families(id) on delete cascade,
  name text not null,
  grade text not null,
  avatar_url text,
  birth_date date,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists children_family_id_idx
  on public.children (family_id);

-- =========================================================
-- CHILD ACCESS GRANTS
-- One grant per child/member pair.
-- =========================================================

create table if not exists public.child_access_grants (
  id uuid primary key default gen_random_uuid(),
  child_id uuid not null references public.children(id) on delete cascade,
  family_member_id uuid not null references public.family_members(id) on delete cascade,

  view_schedule boolean not null default false,
  edit_schedule boolean not null default false,

  view_homework boolean not null default false,
  edit_homework boolean not null default false,

  view_preparation boolean not null default false,
  edit_preparation boolean not null default false,

  view_exam boolean not null default false,
  edit_exam boolean not null default false,

  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),

  unique (child_id, family_member_id)
);

create index if not exists child_access_grants_member_idx
  on public.child_access_grants (family_member_id);

create index if not exists child_access_grants_child_idx
  on public.child_access_grants (child_id);

-- =========================================================
-- UPDATED_AT HELPER
-- =========================================================

create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists profiles_set_updated_at on public.profiles;
create trigger profiles_set_updated_at
before update on public.profiles
for each row execute function public.set_updated_at();

drop trigger if exists families_set_updated_at on public.families;
create trigger families_set_updated_at
before update on public.families
for each row execute function public.set_updated_at();

drop trigger if exists family_members_set_updated_at on public.family_members;
create trigger family_members_set_updated_at
before update on public.family_members
for each row execute function public.set_updated_at();

drop trigger if exists children_set_updated_at on public.children;
create trigger children_set_updated_at
before update on public.children
for each row execute function public.set_updated_at();

drop trigger if exists child_access_grants_set_updated_at on public.child_access_grants;
create trigger child_access_grants_set_updated_at
before update on public.child_access_grants
for each row execute function public.set_updated_at();

-- =========================================================
-- SECURITY DEFINER HELPERS
-- These avoid recursive RLS checks when asking whether the
-- current user belongs to a family.
-- =========================================================

create or replace function public.is_family_member(p_family_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1
    from public.family_members fm
    where fm.family_id = p_family_id
      and fm.profile_id = (select auth.uid())
  );
$$;

create or replace function public.is_family_owner(p_family_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1
    from public.family_members fm
    where fm.family_id = p_family_id
      and fm.profile_id = (select auth.uid())
      and fm.role = 'owner'
  );
$$;

create or replace function public.can_manage_child(p_child_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1
    from public.children c
    join public.family_members fm
      on fm.family_id = c.family_id
    where c.id = p_child_id
      and fm.profile_id = (select auth.uid())
      and fm.role in ('owner', 'parent_guardian')
  );
$$;

-- =========================================================
-- RLS
-- =========================================================

alter table public.profiles enable row level security;
alter table public.families enable row level security;
alter table public.family_members enable row level security;
alter table public.children enable row level security;
alter table public.child_access_grants enable row level security;

-- ---------------------------------------------------------
-- profiles
-- ---------------------------------------------------------

drop policy if exists profiles_select_own on public.profiles;
create policy profiles_select_own
on public.profiles
for select
to authenticated
using ((select auth.uid()) = id);

drop policy if exists profiles_insert_own on public.profiles;
create policy profiles_insert_own
on public.profiles
for insert
to authenticated
with check ((select auth.uid()) = id);

drop policy if exists profiles_update_own on public.profiles;
create policy profiles_update_own
on public.profiles
for update
to authenticated
using ((select auth.uid()) = id)
with check ((select auth.uid()) = id);

-- ---------------------------------------------------------
-- families
-- ---------------------------------------------------------

grant select, insert on public.families to authenticated;

drop policy if exists families_select_member on public.families;
create policy families_select_member
on public.families
for select
to authenticated
using (public.is_family_member(id));

drop policy if exists families_insert_creator on public.families;
create policy families_insert_creator
on public.families
for insert
to authenticated
with check (created_by = (select auth.uid()));

drop policy if exists families_update_owner on public.families;
create policy families_update_owner
on public.families
for update
to authenticated
using (public.is_family_owner(id))
with check (public.is_family_owner(id));

drop policy if exists families_delete_owner on public.families;
create policy families_delete_owner
on public.families
for delete
to authenticated
using (public.is_family_owner(id));

-- ---------------------------------------------------------
-- family_members
-- Members can see members in their own family.
-- Only Owner can insert/update/delete membership rows.
-- ---------------------------------------------------------

drop policy if exists family_members_select_member on public.family_members;
create policy family_members_select_member
on public.family_members
for select
to authenticated
using (public.is_family_member(family_id));

drop policy if exists family_members_insert_owner on public.family_members;
create policy family_members_insert_owner
on public.family_members
for insert
to authenticated
with check (public.is_family_owner(family_id));

drop policy if exists family_members_update_owner on public.family_members;
create policy family_members_update_owner
on public.family_members
for update
to authenticated
using (public.is_family_owner(family_id))
with check (public.is_family_owner(family_id));

drop policy if exists family_members_delete_owner on public.family_members;
create policy family_members_delete_owner
on public.family_members
for delete
to authenticated
using (
  public.is_family_owner(family_id)
  and role <> 'owner'
);

-- ---------------------------------------------------------
-- children
-- Owner + Parent/Guardian manage children.
-- All family members may view children in the family.
-- ---------------------------------------------------------

drop policy if exists children_select_member on public.children;
create policy children_select_member
on public.children
for select
to authenticated
using (public.is_family_member(family_id));

drop policy if exists children_insert_manager on public.children;
create policy children_insert_manager
on public.children
for insert
to authenticated
with check (
  exists (
    select 1
    from public.family_members fm
    where fm.family_id = children.family_id
      and fm.profile_id = (select auth.uid())
      and fm.role in ('owner', 'parent_guardian')
  )
);

drop policy if exists children_update_manager on public.children;
create policy children_update_manager
on public.children
for update
to authenticated
using (public.can_manage_child(id))
with check (public.can_manage_child(id));

drop policy if exists children_delete_owner on public.children;
create policy children_delete_owner
on public.children
for delete
to authenticated
using (
  exists (
    select 1
    from public.children c
    join public.family_members fm
      on fm.family_id = c.family_id
    where c.id = children.id
      and fm.profile_id = (select auth.uid())
      and fm.role = 'owner'
  )
);

-- ---------------------------------------------------------
-- child_access_grants
-- Only Owner manages grants.
-- Owner can read all grants in the family.
-- A member can read their own grant.
-- ---------------------------------------------------------

drop policy if exists child_access_grants_select on public.child_access_grants;
create policy child_access_grants_select
on public.child_access_grants
for select
to authenticated
using (
  exists (
    select 1
    from public.family_members fm
    join public.children c
      on c.family_id = fm.family_id
    where c.id = child_access_grants.child_id
      and (
        public.is_family_owner(fm.family_id)
        or child_access_grants.family_member_id = fm.id
      )
  )
);

drop policy if exists child_access_grants_insert_owner on public.child_access_grants;
create policy child_access_grants_insert_owner
on public.child_access_grants
for insert
to authenticated
with check (
  exists (
    select 1
    from public.child_access_grants existing
    where false
  )
  or public.is_family_owner(
    (select c.family_id
     from public.children c
     where c.id = child_access_grants.child_id)
  )
);

drop policy if exists child_access_grants_update_owner on public.child_access_grants;
create policy child_access_grants_update_owner
on public.child_access_grants
for update
to authenticated
using (
  public.is_family_owner(
    (select c.family_id
     from public.children c
     where c.id = child_access_grants.child_id)
  )
)
with check (
  public.is_family_owner(
    (select c.family_id
     from public.children c
     where c.id = child_access_grants.child_id)
  )
);

drop policy if exists child_access_grants_delete_owner on public.child_access_grants;
create policy child_access_grants_delete_owner
on public.child_access_grants
for delete
to authenticated
using (
  public.is_family_owner(
    (select c.family_id
     from public.children c
     where c.id = child_access_grants.child_id)
  )
);
