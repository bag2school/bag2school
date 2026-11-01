-- Bag2School: hosted setup (all local migrations in order + grants).
-- Paste this once into the Supabase SQL Editor of a fresh project.
-- Generated from supabase/migrations; do not edit by hand.

-- ============================================================
-- 20260823_0730_v13_6_foundation.sql
-- ============================================================

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

-- ============================================================
-- 20260823160700_v13_9_profiles_privileges.sql
-- ============================================================

-- Bag2School V13.9
-- Profiles table privileges.
--
-- RLS policies already restrict authenticated users
-- to their own profile. This grant provides the
-- table-level SELECT privilege required for RLS.

grant select on table public.profiles to authenticated;
-- ============================================================
-- 20260823162500_v13_9_profile_identity.sql
-- ============================================================

-- Bag2School V13.9
-- Profile identity and family relationship.
--
-- profiles:
--   gender          = user identity
--   preferred_title = how Bagi addresses the user
--
-- family_members:
--   relationship    = relationship within the family

alter table public.profiles
  add column if not exists gender text;

alter table public.profiles
  add column if not exists preferred_title text;

alter table public.family_members
  add column if not exists relationship text;
-- ============================================================
-- 20260823170000_v13_9_profile_update_grant.sql
-- ============================================================

-- Bag2School V13.9
-- Grant the authenticated role the SQL privilege required
-- to update its own profile row.
--
-- RLS remains responsible for restricting which profile row
-- an authenticated user is allowed to update.

grant update on table public.profiles to authenticated;

-- ============================================================
-- 20260825_v13_9_children_delete_privilege.sql
-- ============================================================

-- V13.9
-- Allow authenticated users to issue DELETE on children.
-- RLS policy children_delete_owner remains responsible
-- for restricting deletion to the family owner.

grant delete on table public.children to authenticated;
-- ============================================================
-- 20260826000500_v13_10_children_insert_privilege.sql
-- ============================================================

-- Allow authenticated users to create children
grant insert on public.children to authenticated;

-- Required because the app uses .insert(...).select().single()
grant select on public.children to authenticated;
-- ============================================================
-- 20260827_v13_9_child_avatar_storage.sql
-- ============================================================

-- =========================================================
-- Bag2School V13.9-P.3.1
-- Child Profile Gender + Private Avatar Storage Foundation
--
-- Avatar access rules:
--
-- Owner:
--   - Can view/manage child avatar
--
-- Parent / Guardian:
--   - Can view/manage child avatar
--
-- Caregiver:
--   - Cannot access the real child avatar
--   - Flutter displays a local default avatar based on gender
--
-- Adult profile avatars:
--   - Every authenticated user can manage only their own avatar
-- =========================================================


-- =========================================================
-- 1. CHILD PROFILE GENDER
-- =========================================================

alter table public.children
  add column if not exists gender text;

comment on column public.children.gender is
  'Child gender used for identity and default avatar selection.';


-- =========================================================
-- 2. PRIVATE AVATAR STORAGE BUCKET
-- =========================================================

insert into storage.buckets (
  id,
  name,
  public,
  file_size_limit,
  allowed_mime_types
)
values (
  'bag2school-avatars',
  'bag2school-avatars',
  false,
  5242880,
  array[
    'image/jpeg',
    'image/png',
    'image/webp'
  ]
)
on conflict (id) do update
set
  public = false,
  file_size_limit = 5242880,
  allowed_mime_types = array[
    'image/jpeg',
    'image/png',
    'image/webp'
  ];


-- =========================================================
-- STORAGE PATH STRUCTURE
--
-- profiles/{user_id}/avatar.jpg
--
-- children/{child_id}/avatar.jpg
-- =========================================================


-- =========================================================
-- 3. SAFE CHILD AVATAR ACCESS HELPER
--
-- Only Owner and Parent/Guardian pass
-- because can_manage_child() already enforces:
--
-- owner
-- parent_guardian
--
-- Caregiver returns false.
-- =========================================================

create or replace function public.can_manage_child_avatar(
  p_child_id_text text
)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select case
    when p_child_id_text is null then false
    when p_child_id_text !~* '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$'
      then false
    else public.can_manage_child(p_child_id_text::uuid)
  end;
$$;


-- =========================================================
-- 4. ADULT PROFILE AVATAR POLICIES
--
-- Path:
-- profiles/{auth.uid()}/avatar.jpg
-- =========================================================


drop policy if exists bag2school_avatar_profile_select_own
on storage.objects;

create policy bag2school_avatar_profile_select_own
on storage.objects
for select
to authenticated
using (
  bucket_id = 'bag2school-avatars'
  and (storage.foldername(name))[1] = 'profiles'
  and (storage.foldername(name))[2] = (select auth.uid())::text
);


drop policy if exists bag2school_avatar_profile_insert_own
on storage.objects;

create policy bag2school_avatar_profile_insert_own
on storage.objects
for insert
to authenticated
with check (
  bucket_id = 'bag2school-avatars'
  and (storage.foldername(name))[1] = 'profiles'
  and (storage.foldername(name))[2] = (select auth.uid())::text
);


drop policy if exists bag2school_avatar_profile_update_own
on storage.objects;

create policy bag2school_avatar_profile_update_own
on storage.objects
for update
to authenticated
using (
  bucket_id = 'bag2school-avatars'
  and (storage.foldername(name))[1] = 'profiles'
  and (storage.foldername(name))[2] = (select auth.uid())::text
)
with check (
  bucket_id = 'bag2school-avatars'
  and (storage.foldername(name))[1] = 'profiles'
  and (storage.foldername(name))[2] = (select auth.uid())::text
);


drop policy if exists bag2school_avatar_profile_delete_own
on storage.objects;

create policy bag2school_avatar_profile_delete_own
on storage.objects
for delete
to authenticated
using (
  bucket_id = 'bag2school-avatars'
  and (storage.foldername(name))[1] = 'profiles'
  and (storage.foldername(name))[2] = (select auth.uid())::text
);


-- =========================================================
-- 5. CHILD AVATAR SELECT
--
-- Only Owner and Parent/Guardian can see the real photo.
--
-- Caregiver is denied.
-- =========================================================


drop policy if exists bag2school_avatar_child_select_manager
on storage.objects;

create policy bag2school_avatar_child_select_manager
on storage.objects
for select
to authenticated
using (
  bucket_id = 'bag2school-avatars'
  and (storage.foldername(name))[1] = 'children'
  and public.can_manage_child_avatar(
    (storage.foldername(name))[2]
  )
);


-- =========================================================
-- 6. CHILD AVATAR INSERT
--
-- Owner and Parent/Guardian only.
-- =========================================================


drop policy if exists bag2school_avatar_child_insert_manager
on storage.objects;

create policy bag2school_avatar_child_insert_manager
on storage.objects
for insert
to authenticated
with check (
  bucket_id = 'bag2school-avatars'
  and (storage.foldername(name))[1] = 'children'
  and public.can_manage_child_avatar(
    (storage.foldername(name))[2]
  )
);


-- =========================================================
-- 7. CHILD AVATAR UPDATE / REPLACE
--
-- Owner and Parent/Guardian only.
-- =========================================================


drop policy if exists bag2school_avatar_child_update_manager
on storage.objects;

create policy bag2school_avatar_child_update_manager
on storage.objects
for update
to authenticated
using (
  bucket_id = 'bag2school-avatars'
  and (storage.foldername(name))[1] = 'children'
  and public.can_manage_child_avatar(
    (storage.foldername(name))[2]
  )
)
with check (
  bucket_id = 'bag2school-avatars'
  and (storage.foldername(name))[1] = 'children'
  and public.can_manage_child_avatar(
    (storage.foldername(name))[2]
  )
);


-- =========================================================
-- 8. CHILD AVATAR DELETE
--
-- Owner and Parent/Guardian only.
-- =========================================================


drop policy if exists bag2school_avatar_child_delete_manager
on storage.objects;

create policy bag2school_avatar_child_delete_manager
on storage.objects
for delete
to authenticated
using (
  bucket_id = 'bag2school-avatars'
  and (storage.foldername(name))[1] = 'children'
  and public.can_manage_child_avatar(
    (storage.foldername(name))[2]
  )
);


-- =========================================================
-- SECURITY NOTES
--
-- Bucket is PRIVATE.
--
-- Child real avatar:
--   Owner            YES
--   Parent/Guardian  YES
--   Caregiver        NO
--
-- Caregiver receives no Storage access and Flutter must
-- display a local gender-based default avatar instead.
-- =========================================================
-- ============================================================
-- 20260827000100_v13_9_children_update_privilege.sql
-- ============================================================

-- V13.9-P.3.1
-- Allow authenticated users to issue UPDATE on children.
-- RLS policy children_update_manager remains responsible
-- for restricting which children can be managed.

grant update on table public.children to authenticated;
-- ============================================================
-- 20260827130000_v13_9_avatar_storage_foundation.sql
-- ============================================================

-- =========================================================
-- Bag2School V13.9-P.3.1
-- Avatar Storage Foundation
--
-- Storage structure:
--
-- profiles/<user_id>/<filename>
-- children/<child_id>/<filename>
--
-- Rules:
-- - Users can manage their own profile avatar.
-- - Owner and Parent/Guardian can manage child avatars.
-- - Caregiver cannot access child avatar files.
-- =========================================================


-- =========================================================
-- STORAGE BUCKET
-- =========================================================

insert into storage.buckets (
  id,
  name,
  public
)
values (
  'bag2school-avatars',
  'bag2school-avatars',
  false
)
on conflict (id) do nothing;


-- =========================================================
-- PROFILE AVATARS
--
-- Path:
-- profiles/<auth_user_id>/<filename>
--
-- Every authenticated user can manage only their own avatar.
-- =========================================================


drop policy if exists
  "bag2school_profile_avatar_select_own"
on storage.objects;

create policy
  "bag2school_profile_avatar_select_own"
on storage.objects
for select
to authenticated
using (
  bucket_id = 'bag2school-avatars'
  and (storage.foldername(name))[1] = 'profiles'
  and (storage.foldername(name))[2] = auth.uid()::text
);


drop policy if exists
  "bag2school_profile_avatar_insert_own"
on storage.objects;

create policy
  "bag2school_profile_avatar_insert_own"
on storage.objects
for insert
to authenticated
with check (
  bucket_id = 'bag2school-avatars'
  and (storage.foldername(name))[1] = 'profiles'
  and (storage.foldername(name))[2] = auth.uid()::text
);


drop policy if exists
  "bag2school_profile_avatar_update_own"
on storage.objects;

create policy
  "bag2school_profile_avatar_update_own"
on storage.objects
for update
to authenticated
using (
  bucket_id = 'bag2school-avatars'
  and (storage.foldername(name))[1] = 'profiles'
  and (storage.foldername(name))[2] = auth.uid()::text
)
with check (
  bucket_id = 'bag2school-avatars'
  and (storage.foldername(name))[1] = 'profiles'
  and (storage.foldername(name))[2] = auth.uid()::text
);


drop policy if exists
  "bag2school_profile_avatar_delete_own"
on storage.objects;

create policy
  "bag2school_profile_avatar_delete_own"
on storage.objects
for delete
to authenticated
using (
  bucket_id = 'bag2school-avatars'
  and (storage.foldername(name))[1] = 'profiles'
  and (storage.foldername(name))[2] = auth.uid()::text
);


-- =========================================================
-- CHILD AVATARS
--
-- Path:
-- children/<child_id>/<filename>
--
-- Only Owner and Parent/Guardian can access/manage.
--
-- public.can_manage_child() already checks:
-- owner + parent_guardian
--
-- Caregiver is intentionally excluded.
-- =========================================================


drop policy if exists
  "bag2school_child_avatar_select_manager"
on storage.objects;

create policy
  "bag2school_child_avatar_select_manager"
on storage.objects
for select
to authenticated
using (
  bucket_id = 'bag2school-avatars'
  and (storage.foldername(name))[1] = 'children'
  and public.can_manage_child(
    ((storage.foldername(name))[2])::uuid
  )
);


drop policy if exists
  "bag2school_child_avatar_insert_manager"
on storage.objects;

create policy
  "bag2school_child_avatar_insert_manager"
on storage.objects
for insert
to authenticated
with check (
  bucket_id = 'bag2school-avatars'
  and (storage.foldername(name))[1] = 'children'
  and public.can_manage_child(
    ((storage.foldername(name))[2])::uuid
  )
);


drop policy if exists
  "bag2school_child_avatar_update_manager"
on storage.objects;

create policy
  "bag2school_child_avatar_update_manager"
on storage.objects
for update
to authenticated
using (
  bucket_id = 'bag2school-avatars'
  and (storage.foldername(name))[1] = 'children'
  and public.can_manage_child(
    ((storage.foldername(name))[2])::uuid
  )
)
with check (
  bucket_id = 'bag2school-avatars'
  and (storage.foldername(name))[1] = 'children'
  and public.can_manage_child(
    ((storage.foldername(name))[2])::uuid
  )
);


drop policy if exists
  "bag2school_child_avatar_delete_manager"
on storage.objects;

create policy
  "bag2school_child_avatar_delete_manager"
on storage.objects
for delete
to authenticated
using (
  bucket_id = 'bag2school-avatars'
  and (storage.foldername(name))[1] = 'children'
  and public.can_manage_child(
    ((storage.foldername(name))[2])::uuid
  )
);
-- ============================================================
-- 20260827140000_v13_9_children_gender.sql
-- ============================================================

-- =========================================================
-- Bag2School V13.9-P.3.1
-- Child gender foundation
--
-- Used for:
-- - Default child avatar selection
-- - Gender-aware UI presentation
--
-- Avatar upload remains restricted to:
-- Owner + Parent/Guardian
-- =========================================================

alter table public.children
add column if not exists gender text;
-- ============================================================
-- 20260830000000_v13_9_family_invitations.sql
-- ============================================================

-- ============================================================
-- V13.9-S â€” FAMILY INVITATIONS
-- ============================================================

create table if not exists public.family_invitations (
  id uuid primary key default gen_random_uuid(),

  family_id uuid not null
    references public.families(id)
    on delete cascade,

  invited_profile_id uuid not null,

  invited_email text not null,

  invited_by_profile_id uuid not null,

  invitation_code text not null unique,

  role public.family_member_role not null,

  status text not null default 'pending'
    check (status in ('pending', 'accepted', 'declined', 'cancelled')),

  created_at timestamptz not null default now(),
  responded_at timestamptz
);


-- ============================================================
-- PREVENT DUPLICATE PENDING INVITATIONS
-- ============================================================

create unique index if not exists family_invitations_pending_unique
on public.family_invitations (family_id, invited_profile_id)
where status = 'pending';


-- ============================================================
-- ROW LEVEL SECURITY
-- ============================================================

alter table public.family_invitations enable row level security;


-- ------------------------------------------------------------
-- INVITEE
-- Can see invitations addressed to their own profile.
-- ------------------------------------------------------------

create policy "Invitee can view own invitations"
on public.family_invitations
for select
to authenticated
using (
  invited_profile_id = auth.uid()
);


-- ------------------------------------------------------------
-- FAMILY OWNER
-- Can view invitations belonging to their family.
-- ------------------------------------------------------------

create policy "Owner can view family invitations"
on public.family_invitations
for select
to authenticated
using (
  exists (
    select 1
    from public.family_members fm
    where fm.family_id = family_invitations.family_id
      and fm.profile_id = auth.uid()
      and fm.role = 'owner'
  )
);


-- ------------------------------------------------------------
-- FAMILY OWNER
-- Can create invitations.
-- ------------------------------------------------------------

create policy "Owner can create invitations"
on public.family_invitations
for insert
to authenticated
with check (
  invited_by_profile_id = auth.uid()

  and role in (
    'parent_guardian'::public.family_member_role,
    'caregiver'::public.family_member_role
  )

  and exists (
    select 1
    from public.family_members fm
    where fm.family_id = family_invitations.family_id
      and fm.profile_id = auth.uid()
      and fm.role = 'owner'
  )
);


-- ------------------------------------------------------------
-- INVITEE
-- Can respond to their own invitation.
-- ------------------------------------------------------------

create policy "Invitee can respond to own invitation"
on public.family_invitations
for update
to authenticated
using (
  invited_profile_id = auth.uid()
)
with check (
  invited_profile_id = auth.uid()
);

-- ============================================================
-- ACCEPT FAMILY INVITATION
-- ============================================================

create or replace function public.accept_family_invitation(
  invitation_id uuid
)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  invitation_record public.family_invitations;
  profile_name text;
begin

  -- Get invitation for current user
  select *
  into invitation_record
  from public.family_invitations
  where id = invitation_id
    and invited_profile_id = auth.uid()
    and status = 'pending';

  if not found then
    raise exception 'Invitation not found or is no longer pending';
  end if;

  -- Get display name from profiles
  select display_name
  into profile_name
  from public.profiles
  where id = auth.uid();

  -- Add user to family
  insert into public.family_members (
    family_id,
    profile_id,
    role,
    display_name
  )
  values (
    invitation_record.family_id,
    auth.uid(),
    invitation_record.role,
    coalesce(profile_name, invitation_record.invited_email)
  );

  -- Mark invitation accepted
  update public.family_invitations
  set
    status = 'accepted',
    responded_at = now()
  where id = invitation_id;

end;
$$;


-- ============================================================
-- INVITEE CAN EXECUTE ACCEPT FUNCTION
-- ============================================================

grant execute on function public.accept_family_invitation(uuid)
to authenticated;

-- ============================================================
-- ACCEPT FAMILY INVITATION
-- ============================================================

create or replace function public.accept_family_invitation(
  invitation_id uuid
)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  invitation_record public.family_invitations;
  profile_name text;
begin

  -- Get the pending invitation for the current user
  select *
  into invitation_record
  from public.family_invitations
  where id = invitation_id
    and invited_profile_id = auth.uid()
    and status = 'pending';

  if not found then
    raise exception 'Invitation not found or is no longer pending';
  end if;

  -- Get the user's display name
  select display_name
  into profile_name
  from public.profiles
  where id = auth.uid();

  -- Add the invited user as a family member
  insert into public.family_members (
    family_id,
    profile_id,
    role,
    display_name
  )
  values (
    invitation_record.family_id,
    auth.uid(),
    invitation_record.role,
    coalesce(profile_name, invitation_record.invited_email)
  );

  -- Mark invitation as accepted
  update public.family_invitations
  set
    status = 'accepted',
    responded_at = now()
  where id = invitation_id;

end;
$$;


grant execute on function public.accept_family_invitation(uuid)
to authenticated;

-- ============================================================
-- FIND PROFILE BY EMAIL FOR FAMILY INVITATION
-- ============================================================

create or replace function public.find_profile_by_email(
  lookup_email text
)
returns table (
  id uuid,
  display_name text,
  email text
)
language plpgsql
security definer
set search_path = public, auth
as $$
begin
  -- Only authenticated users can use this function.
  if auth.uid() is null then
    raise exception 'Not authenticated';
  end if;

  return query
  select
    p.id,
    p.display_name,
    u.email
  from auth.users u
  join public.profiles p
    on p.id = u.id
  where lower(u.email) = lower(trim(lookup_email))
  limit 1;
end;
$$;

grant execute on function public.find_profile_by_email(text)
to authenticated;
-- ============================================================
-- 20260830010000_v13_9_family_invitation_codes.sql
-- ============================================================

-- ============================================================
-- V13.9-T â€” FAMILY INVITATION CODES
-- ============================================================

create table if not exists public.family_invitation_codes (
  id uuid primary key default gen_random_uuid(),

  family_id uuid not null
    references public.families(id)
    on delete cascade,

  code text not null,

  created_by_profile_id uuid not null,

  expires_at timestamptz not null
    default (now() + interval '10 minutes'),

  is_active boolean not null default true,

  created_at timestamptz not null default now()
);

-- ============================================================
-- UNIQUE ACTIVE CODE
-- ============================================================

create unique index if not exists family_invitation_codes_active_unique
on public.family_invitation_codes (code)
where is_active = true;

-- ============================================================
-- PERFORMANCE INDEX
-- ============================================================

create index if not exists family_invitation_codes_lookup_idx
on public.family_invitation_codes (code);

-- ============================================================
-- ROW LEVEL SECURITY
-- ============================================================

alter table public.family_invitation_codes enable row level security;

-- ============================================================
-- FAMILY OWNER
-- CAN VIEW THEIR FAMILY INVITATION CODES
-- ============================================================

drop policy if exists "Owner can view family invitation codes"
on public.family_invitation_codes;

create policy "Owner can view family invitation codes"
on public.family_invitation_codes
for select
to authenticated
using (
  exists (
    select 1
    from public.family_members fm
    where fm.family_id = family_invitation_codes.family_id
      and fm.profile_id = auth.uid()
      and fm.role = 'owner'
  )
);

-- ============================================================
-- FAMILY OWNER
-- CAN CREATE INVITATION CODES
-- ============================================================

drop policy if exists "Owner can create invitation codes"
on public.family_invitation_codes;

create policy "Owner can create invitation codes"
on public.family_invitation_codes
for insert
to authenticated
with check (
  created_by_profile_id = auth.uid()
  and exists (
    select 1
    from public.family_members fm
    where fm.family_id = family_invitation_codes.family_id
      and fm.profile_id = auth.uid()
      and fm.role = 'owner'
  )
);

-- ============================================================
-- FAMILY OWNER
-- CAN UPDATE FAMILY INVITATION CODES
-- ============================================================

drop policy if exists "Owner can update family invitation codes"
on public.family_invitation_codes;

create policy "Owner can update family invitation codes"
on public.family_invitation_codes
for update
to authenticated
using (
  exists (
    select 1
    from public.family_members fm
    where fm.family_id = family_invitation_codes.family_id
      and fm.profile_id = auth.uid()
      and fm.role = 'owner'
  )
)
with check (
  exists (
    select 1
    from public.family_members fm
    where fm.family_id = family_invitation_codes.family_id
      and fm.profile_id = auth.uid()
      and fm.role = 'owner'
  )
);
-- ============================================================
-- 20260902162002_add_role_to_family_invitation_codes.sql
-- ============================================================

-- ============================================================
-- ADD ROLE TO FAMILY INVITATION CODES
-- ============================================================

alter table public.family_invitation_codes
add column if not exists role text;

-- ============================================================
-- VALIDATE INVITATION ROLE
-- ============================================================

alter table public.family_invitation_codes
add constraint family_invitation_codes_role_check
check (
  role in (
    'parentGuardian',
    'caregiver'
  )
);
-- ============================================================
-- 20260902162723_fix_family_invitation_code_roles.sql
-- ============================================================

-- ============================================================
-- FIX FAMILY INVITATION CODE ROLES
-- ============================================================

-- Remove old incorrect constraint.
alter table public.family_invitation_codes
drop constraint if exists family_invitation_codes_role_check;


-- ============================================================
-- CHANGE DEFAULT ROLE
-- ============================================================

alter table public.family_invitation_codes
alter column role drop default;


-- ============================================================
-- VALID ROLES
-- ============================================================

alter table public.family_invitation_codes
add constraint family_invitation_codes_role_check
check (
  role in (
    'parentGuardian',
    'caregiver'
  )
);
-- ============================================================
-- 20260906000100_debug_auth_context.sql
-- ============================================================

create or replace function public.debug_auth_context()
returns json
language sql
stable
security definer
set search_path = public
as $$
  select json_build_object(
    'uid', auth.uid(),
    'role', auth.role()
  );
$$;

grant execute on function public.debug_auth_context() to authenticated;
-- ============================================================
-- 20260906000200_v13_9_profile_on_signup.sql
-- ============================================================

-- Bag2School V13.9
-- Automatically create a public profile for every new Auth user.

create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.profiles (
  id,
  display_name,
  preferred_title
)
values (
  new.id,
  coalesce(
    nullif(trim(new.raw_user_meta_data ->> 'display_name'), ''),
    'Bag2School User'
  ),
  coalesce(
    nullif(trim(new.raw_user_meta_data ->> 'display_name'), ''),
    'Bag2School User'
  )
)
  on conflict (id) do nothing;

  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;

create trigger on_auth_user_created
  after insert on auth.users
  for each row
  execute function public.handle_new_user();
-- ============================================================
-- 20260906000300_v13_9_family_join_requests.sql
-- ============================================================

-- Bag2School V13.9
-- Family join requests

create table if not exists public.family_join_requests (
  id uuid primary key default gen_random_uuid(),
  family_id uuid not null references public.families(id) on delete cascade,
  profile_id uuid not null references public.profiles(id) on delete cascade,
  invitation_code_id uuid references public.family_invitation_codes(id) on delete set null,
  status text not null default 'pending',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),

  constraint family_join_requests_status_check
    check (status in ('pending', 'approved', 'rejected'))
);

create index if not exists family_join_requests_family_id_idx
  on public.family_join_requests(family_id);

create index if not exists family_join_requests_profile_id_idx
  on public.family_join_requests(profile_id);

create index if not exists family_join_requests_invitation_code_id_idx
  on public.family_join_requests(invitation_code_id);

alter table public.family_join_requests enable row level security;

drop policy if exists family_join_requests_select_own on public.family_join_requests;
create policy family_join_requests_select_own
on public.family_join_requests
for select
to authenticated
using (
  profile_id = (select auth.uid())
);

drop policy if exists family_join_requests_insert_own on public.family_join_requests;
create policy family_join_requests_insert_own
on public.family_join_requests
for insert
to authenticated
with check (
  profile_id = (select auth.uid())
);

drop policy if exists family_join_requests_update_owner on public.family_join_requests;
create policy family_join_requests_update_owner
on public.family_join_requests
for update
to authenticated
using (
  public.is_family_owner(family_id)
)
with check (
  public.is_family_owner(family_id)
);

grant select, insert on public.family_join_requests to authenticated;
grant update on public.family_join_requests to authenticated;
-- ============================================================
-- 20260906000400_debug_family_rls.sql
-- ============================================================

create or replace function public.debug_family_rls(
  p_created_by uuid
)
returns json
language sql
stable
security definer
set search_path = public
as $$
  select json_build_object(
    'auth_uid', auth.uid(),
    'auth_role', auth.role(),
    'created_by', p_created_by,
    'matches', p_created_by = (select auth.uid())
  );
$$;

grant execute on function public.debug_family_rls(uuid) to authenticated;
-- ============================================================
-- 20260906000500_v13_9_create_family_rpc.sql
-- ============================================================

-- Bag2School V13.9
-- Atomic family creation RPC

create or replace function public.create_family(
  p_family_name text,
  p_display_name text
)
returns public.families
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user_id uuid;
  v_family public.families;
begin
  v_user_id := auth.uid();

  if v_user_id is null then
    raise exception 'Not authenticated';
  end if;

  if not exists (
    select 1
    from public.profiles
    where id = v_user_id
  ) then
    raise exception 'Profile not found';
  end if;

  insert into public.families (
    name,
    created_by
  )
  values (
    trim(p_family_name),
    v_user_id
  )
  returning * into v_family;

  insert into public.family_members (
    family_id,
    profile_id,
    role,
    display_name
  )
  values (
    v_family.id,
    v_user_id,
    'owner',
    trim(p_display_name)
  );

  return v_family;
end;
$$;

grant execute on function public.create_family(text, text)
to authenticated;
-- ============================================================
-- 20260906000600_debug_is_family_member.sql
-- ============================================================

create or replace function public.debug_is_family_member(
  p_family_id uuid
)
returns json
language sql
stable
security definer
set search_path = public
as $$
  select json_build_object(
    'auth_uid', auth.uid(),
    'auth_role', auth.role(),
    'family_id', p_family_id,
    'member_exists', exists (
      select 1
      from public.family_members fm
      where fm.family_id = p_family_id
        and fm.profile_id = auth.uid()
    ),
    'is_family_member', public.is_family_member(p_family_id)
  );
$$;

grant execute on function public.debug_is_family_member(uuid)
to authenticated;
-- ============================================================
-- 20260906000700_v13_9_family_members_grants.sql
-- ============================================================

grant select on public.family_members to authenticated;
grant insert on public.family_members to authenticated;
grant update on public.family_members to authenticated;
grant delete on public.family_members to authenticated;
-- ============================================================
-- 20260906000800_v13_9_family_invitation_codes_grants.sql
-- ============================================================

-- Bag2School V13.9
-- Grant table privileges for authenticated family owners.
-- RLS policies remain responsible for restricting access.

grant select on public.family_invitation_codes to authenticated;
grant insert on public.family_invitation_codes to authenticated;
grant update on public.family_invitation_codes to authenticated;
-- ============================================================
-- 20260906000900_v13_9_validate_family_invitation_code_rpc.sql
-- ============================================================

-- ============================================================
-- Bag2School V13.9
-- Validate family invitation code through a secure RPC.
-- Users do not need to be family members to validate a code.
-- ============================================================

create or replace function public.validate_family_invitation_code(
  p_code text
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  invitation_code public.family_invitation_codes%rowtype;
begin
  select *
  into invitation_code
  from public.family_invitation_codes
  where code = upper(trim(p_code))
    and is_active = true
  order by created_at desc
  limit 1;

  if not found then
    return jsonb_build_object(
      'valid', false,
      'reason', 'not_found'
    );
  end if;

  if invitation_code.expires_at <= now() then
    update public.family_invitation_codes
    set is_active = false
    where id = invitation_code.id;

    return jsonb_build_object(
      'valid', false,
      'reason', 'expired'
    );
  end if;

  return jsonb_build_object(
    'valid', true,
    'reason', 'valid',
    'family_id', invitation_code.family_id,
    'code_id', invitation_code.id,
    'role', invitation_code.role,
    'expires_at', invitation_code.expires_at
  );
end;
$$;

grant execute
on function public.validate_family_invitation_code(text)
to authenticated;
-- ============================================================
-- 20260908000100_fix_family_invitation_code_role_constraint.sql
-- ============================================================

-- ============================================================
-- Bag2School V13.9
-- Fix invitation code role constraint to match family_member_role
-- ============================================================

-- Remove old incorrect constraint first.
alter table public.family_invitation_codes
drop constraint if exists family_invitation_codes_role_check;

-- Convert existing invitation codes to the database role format.
update public.family_invitation_codes
set role = 'parent_guardian'
where role = 'parentGuardian';

-- Add the corrected constraint.
alter table public.family_invitation_codes
add constraint family_invitation_codes_role_check
check (
  role in (
    'parent_guardian',
    'caregiver'
  )
);
-- ============================================================
-- 20260908000200_v13_9_family_invitation_direct_join_rls.sql
-- ============================================================

-- ============================================================
-- Bag2School V13.9
-- Allow direct family join through a valid invitation code
-- ============================================================

drop policy if exists family_members_insert_invitation on public.family_members;

create policy family_members_insert_invitation
on public.family_members
for insert
to authenticated
with check (
  profile_id = (select auth.uid())
  and exists (
    select 1
    from public.family_invitation_codes ic
    where ic.family_id = family_members.family_id
      and ic.role = family_members.role::text
      and ic.is_active = true
      and ic.expires_at > now()
  )
);
-- ============================================================
-- 20260908000300_v13_9_join_family_with_invitation_code_rpc.sql
-- ============================================================

-- ============================================================
-- Bag2School V13.9
-- Direct family join through invitation code RPC
-- ============================================================

create or replace function public.join_family_with_invitation_code(
  p_code text
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  current_user_id uuid;
  invitation_code public.family_invitation_codes%rowtype;
  existing_member public.family_members%rowtype;
  member_display_name text;
begin
  current_user_id := auth.uid();

  if current_user_id is null then
    return jsonb_build_object(
      'success', false,
      'reason', 'not_authenticated'
    );
  end if;

  select *
  into invitation_code
  from public.family_invitation_codes
  where code = upper(trim(p_code))
    and is_active = true
  order by created_at desc
  limit 1;

  if not found then
    return jsonb_build_object(
      'success', false,
      'reason', 'not_found'
    );
  end if;

  if invitation_code.expires_at <= now() then
    update public.family_invitation_codes
    set is_active = false
    where id = invitation_code.id;

    return jsonb_build_object(
      'success', false,
      'reason', 'expired'
    );
  end if;

  select *
  into existing_member
  from public.family_members
  where family_id = invitation_code.family_id
    and profile_id = current_user_id
  limit 1;

  if found then
    return jsonb_build_object(
      'success', false,
      'reason', 'already_member'
    );
  end if;

  select display_name
  into member_display_name
  from public.profiles
  where id = current_user_id
  limit 1;

  insert into public.family_members (
    family_id,
    profile_id,
    role,
    display_name
  )
  values (
    invitation_code.family_id,
    current_user_id,
    invitation_code.role::family_member_role,
    coalesce(
      nullif(trim(member_display_name), ''),
      'Bag2School User'
    )
  );

  return jsonb_build_object(
    'success', true,
    'reason', 'joined',
    'family_id', invitation_code.family_id,
    'code_id', invitation_code.id,
    'role', invitation_code.role
  );

exception
  when others then
    return jsonb_build_object(
      'success', false,
      'reason', 'error',
      'message', sqlerrm
    );
end;
$$;

grant execute
on function public.join_family_with_invitation_code(text)
to authenticated;
-- ============================================================
-- 20260909000100_owner_only_add_child.sql
-- ============================================================

-- ============================================================
-- Bag2School V13.9
-- Only Family Owner can add children
-- ============================================================

drop policy if exists children_insert_manager
on public.children;

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
      and fm.role = 'owner'
  )
);
-- ============================================================
-- 20260914000100_v13_9_family_invitation_links.sql
-- ============================================================

-- ============================================================
-- V13.9-U â€” FAMILY INVITATION LINKS
-- ============================================================

create table if not exists public.family_invitation_links (
  id uuid primary key default gen_random_uuid(),

  family_id uuid not null
    references public.families(id)
    on delete cascade,

  token text not null unique,

  created_by_profile_id uuid not null,

  role public.family_member_role not null
    check (
      role in (
        'parent_guardian'::public.family_member_role,
        'caregiver'::public.family_member_role
      )
    ),

  expires_at timestamptz not null
    default (now() + interval '10 minutes'),

  is_active boolean not null default true,

  used_at timestamptz,

  used_by_profile_id uuid,

  created_at timestamptz not null default now()
);

-- ============================================================
-- PERFORMANCE
-- ============================================================

create index if not exists family_invitation_links_token_idx
on public.family_invitation_links (token);

create index if not exists family_invitation_links_family_id_idx
on public.family_invitation_links (family_id);

-- ============================================================
-- ROW LEVEL SECURITY
-- ============================================================

alter table public.family_invitation_links enable row level security;

-- ============================================================
-- FAMILY OWNER
-- CAN VIEW THEIR FAMILY LINKS
-- ============================================================

drop policy if exists "Owner can view family invitation links"
on public.family_invitation_links;

create policy "Owner can view family invitation links"
on public.family_invitation_links
for select
to authenticated
using (
  exists (
    select 1
    from public.family_members fm
    where fm.family_id = family_invitation_links.family_id
      and fm.profile_id = auth.uid()
      and fm.role = 'owner'
  )
);

-- ============================================================
-- FAMILY OWNER
-- CAN CREATE LINKS
-- ============================================================

drop policy if exists "Owner can create family invitation links"
on public.family_invitation_links;

create policy "Owner can create family invitation links"
on public.family_invitation_links
for insert
to authenticated
with check (
  created_by_profile_id = auth.uid()

  and role in (
    'parent_guardian'::public.family_member_role,
    'caregiver'::public.family_member_role
  )

  and exists (
    select 1
    from public.family_members fm
    where fm.family_id = family_invitation_links.family_id
      and fm.profile_id = auth.uid()
      and fm.role = 'owner'
  )
);

-- ============================================================
-- FAMILY OWNER
-- CAN UPDATE / DISABLE LINKS
-- ============================================================

drop policy if exists "Owner can update family invitation links"
on public.family_invitation_links;

create policy "Owner can update family invitation links"
on public.family_invitation_links
for update
to authenticated
using (
  exists (
    select 1
    from public.family_members fm
    where fm.family_id = family_invitation_links.family_id
      and fm.profile_id = auth.uid()
      and fm.role = 'owner'
  )
)
with check (
  exists (
    select 1
    from public.family_members fm
    where fm.family_id = family_invitation_links.family_id
      and fm.profile_id = auth.uid()
      and fm.role = 'owner'
  )
);
-- ============================================================
-- 20260914000200_v13_9_create_family_invitation_link_rpc.sql
-- ============================================================

-- ============================================================
-- V13.9-V â€” CREATE FAMILY INVITATION LINK RPC
-- ============================================================

create or replace function public.create_family_invitation_link(
  p_family_id uuid,
  p_role public.family_member_role
)
returns public.family_invitation_links
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  v_user_id uuid;
  v_token text;
  v_link public.family_invitation_links;
begin
  v_user_id := auth.uid();

  if v_user_id is null then
    raise exception 'Not authenticated';
  end if;

  -- Only the family owner can create invitation links.
  if not exists (
    select 1
    from public.family_members fm
    where fm.family_id = p_family_id
      and fm.profile_id = v_user_id
      and fm.role = 'owner'
  ) then
    raise exception 'Only the family owner can create invitation links';
  end if;

  -- Only supported invitation roles are allowed.
  if p_role not in (
    'parent_guardian'::public.family_member_role,
    'caregiver'::public.family_member_role
  ) then
    raise exception 'Invalid invitation role';
  end if;

  -- Generate a unique random token.
  loop
    v_token := encode(gen_random_bytes(24), 'base64url');

    exit when not exists (
      select 1
      from public.family_invitation_links fil
      where fil.token = v_token
    );
  end loop;

  insert into public.family_invitation_links (
    family_id,
    token,
    created_by_profile_id,
    role,
    expires_at
  )
  values (
    p_family_id,
    v_token,
    v_user_id,
    p_role,
    now() + interval '10 minutes'
  )
  returning * into v_link;

  return v_link;
end;
$$;

grant execute on function public.create_family_invitation_link(
  uuid,
  public.family_member_role
) to authenticated;
-- ============================================================
-- 20260920000100_v13_9_consume_family_invitation_link_rpc.sql
-- ============================================================

-- Bag2School V13.9-S
-- Consume family invitation link
-- Single-use invitation link with direct family join
-- ============================================================

create or replace function public.consume_family_invitation_link(
  p_token text
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  current_user_id uuid;
  invitation_link public.family_invitation_links%rowtype;
  existing_member public.family_members%rowtype;
  member_display_name text;
begin
  current_user_id := auth.uid();

  if current_user_id is null then
    return jsonb_build_object(
      'success', false,
      'reason', 'not_authenticated'
    );
  end if;

  select *
  into invitation_link
  from public.family_invitation_links
  where token = trim(p_token)
    and is_active = true
    and used_at is null
  order by created_at desc
  limit 1
  for update;

  if not found then
    return jsonb_build_object(
      'success', false,
      'reason', 'not_found'
    );
  end if;

  if invitation_link.expires_at <= now() then
    update public.family_invitation_links
    set is_active = false
    where id = invitation_link.id;

    return jsonb_build_object(
      'success', false,
      'reason', 'expired'
    );
  end if;

  select *
  into existing_member
  from public.family_members
  where family_id = invitation_link.family_id
    and profile_id = current_user_id
  limit 1;

  if found then
    return jsonb_build_object(
      'success', false,
      'reason', 'already_member'
    );
  end if;

  select display_name
  into member_display_name
  from public.profiles
  where id = current_user_id
  limit 1;

  insert into public.family_members (
    family_id,
    profile_id,
    role,
    display_name
  )
  values (
    invitation_link.family_id,
    current_user_id,
    invitation_link.role::family_member_role,
    coalesce(
      nullif(trim(member_display_name), ''),
      'Bag2School User'
    )
  );

  update public.family_invitation_links
  set
    is_active = false,
    used_at = now(),
    used_by_profile_id = current_user_id
  where id = invitation_link.id;

  return jsonb_build_object(
    'success', true,
    'reason', 'joined',
    'family_id', invitation_link.family_id,
    'link_id', invitation_link.id,
    'role', invitation_link.role
  );

exception
  when others then
    return jsonb_build_object(
      'success', false,
      'reason', 'error',
      'message', sqlerrm
    );
end;
$$;

grant execute
on function public.consume_family_invitation_link(text)
to authenticated;
-- ============================================================
-- 20261025000100_family_and_account_management.sql
-- ============================================================

-- Family management and self-service account deletion.
grant update on public.families to authenticated;

create or replace function public.leave_family_with_transfer(
  p_family_id uuid,
  p_new_owner_profile_id uuid default null
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_user_id uuid := auth.uid();
  v_role public.family_member_role;
begin
  if v_user_id is null then
    raise exception 'not_authenticated';
  end if;

  select role into v_role
  from public.family_members
  where family_id = p_family_id and profile_id = v_user_id
  for update;

  if v_role is null then
    raise exception 'not_a_family_member';
  end if;

  if v_role = 'owner' then
    if p_new_owner_profile_id is null or p_new_owner_profile_id = v_user_id then
      raise exception 'owner_transfer_required';
    end if;

    if not exists (
      select 1 from public.family_members
      where family_id = p_family_id
        and profile_id = p_new_owner_profile_id
        and profile_id <> v_user_id
    ) then
      raise exception 'new_owner_must_be_family_member';
    end if;

    update public.family_members
    set role = 'parent_guardian'
    where family_id = p_family_id and profile_id = v_user_id;

    update public.family_members
    set role = 'owner'
    where family_id = p_family_id and profile_id = p_new_owner_profile_id;

    update public.families
    set created_by = p_new_owner_profile_id
    where id = p_family_id and created_by = v_user_id;
  elsif p_new_owner_profile_id is not null then
    raise exception 'only_owner_can_transfer_ownership';
  end if;

  delete from public.family_members
  where family_id = p_family_id and profile_id = v_user_id;

  return jsonb_build_object('success', true, 'family_id', p_family_id);
end;
$$;

revoke all on function public.leave_family_with_transfer(uuid, uuid) from public;
grant execute on function public.leave_family_with_transfer(uuid, uuid) to authenticated;

create or replace function public.delete_own_account()
returns boolean
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_user_id uuid := auth.uid();
  v_family record;
  v_next_owner uuid;
begin
  if v_user_id is null then
    raise exception 'not_authenticated';
  end if;

  for v_family in
    select f.id, f.created_by,
           exists (
             select 1 from public.family_members fm
             where fm.family_id = f.id and fm.profile_id = v_user_id and fm.role = 'owner'
           ) as is_owner
    from public.families f
    where f.created_by = v_user_id
       or exists (
         select 1 from public.family_members fm
         where fm.family_id = f.id and fm.profile_id = v_user_id
       )
    for update
  loop
    select fm.profile_id into v_next_owner
    from public.family_members fm
    where fm.family_id = v_family.id and fm.profile_id <> v_user_id
    order by (fm.role = 'owner') desc, fm.created_at asc
    limit 1;

    if v_next_owner is null then
      delete from public.families where id = v_family.id;
    else
      if v_family.is_owner then
        update public.family_members
        set role = 'parent_guardian'
        where family_id = v_family.id and profile_id = v_user_id;

        update public.family_members
        set role = 'owner'
        where family_id = v_family.id and profile_id = v_next_owner;
      end if;

      update public.families
      set created_by = v_next_owner
      where id = v_family.id and created_by = v_user_id;
    end if;
  end loop;

  delete from auth.users where id = v_user_id;
  return true;
end;
$$;

revoke all on function public.delete_own_account() from public;
grant execute on function public.delete_own_account() to authenticated;
-- ============================================================
-- 20261101000100_v14_delete_account_rpc.sql
-- ============================================================

-- R-10: account deletion.
--
-- Google Play requires apps that let people create an account to also let them
-- delete it. The app calls this function with the user's own token; everything
-- the account owns is removed first (families cascade to members, children,
-- grants, invitations and join requests), then the auth row itself, so nothing
-- is left orphaned.

create or replace function public.delete_my_account()
returns void
language plpgsql
security definer
set search_path = public, auth
as $$
declare
  uid uuid := auth.uid();
begin
  if uid is null then
    raise exception 'Not authenticated';
  end if;

  -- Families this account created. Cascades to child rows, memberships,
  -- access grants, invitation codes/links and join requests.
  delete from public.families where created_by = uid;

  -- Membership in other people's families, then the profile itself.
  delete from public.family_members where profile_id = uid;
  delete from public.profiles where id = uid;

  -- Finally the auth account, so the email can be used again.
  delete from auth.users where id = uid;
end;
$$;

revoke all on function public.delete_my_account() from public;
grant execute on function public.delete_my_account() to authenticated;

comment on function public.delete_my_account() is
  'Deletes the calling account, its memberships and any family it owns.';

-- ============================================================
-- 20261101000200_v14_api_role_grants.sql
-- ============================================================

-- R-01 follow-up: table privileges for the API roles.
--
-- The schema was created by the postgres role, and the hosted project does not
-- grant the API roles by default, so every REST call failed with
-- "permission denied for table profiles". Row level security still decides which
-- rows a user may see; these grants only let the roles reach the tables.

grant usage on schema public to anon, authenticated;

grant select on all tables in schema public to anon;
grant select, insert, update, delete on all tables in schema public to authenticated;

grant usage, select on all sequences in schema public to anon, authenticated;

grant execute on all functions in schema public to anon, authenticated;

-- Future tables and functions created by migrations.
alter default privileges in schema public
  grant select on tables to anon;

alter default privileges in schema public
  grant select, insert, update, delete on tables to authenticated;

alter default privileges in schema public
  grant usage, select on sequences to anon, authenticated;

alter default privileges in schema public
  grant execute on functions to anon, authenticated;

