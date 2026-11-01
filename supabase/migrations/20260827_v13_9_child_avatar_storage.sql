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