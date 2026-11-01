-- ============================================================
-- V13.9-U — FAMILY INVITATION LINKS
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