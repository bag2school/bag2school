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