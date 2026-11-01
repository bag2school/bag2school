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