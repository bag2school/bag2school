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