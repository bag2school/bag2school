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