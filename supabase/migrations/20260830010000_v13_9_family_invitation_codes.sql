-- ============================================================
-- V13.9-T — FAMILY INVITATION CODES
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