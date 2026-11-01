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