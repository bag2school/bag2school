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