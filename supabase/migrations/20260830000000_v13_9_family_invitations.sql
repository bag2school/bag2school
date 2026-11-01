-- ============================================================
-- V13.9-S — FAMILY INVITATIONS
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