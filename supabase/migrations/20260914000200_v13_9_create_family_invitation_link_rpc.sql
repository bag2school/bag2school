-- ============================================================
-- V13.9-V — CREATE FAMILY INVITATION LINK RPC
-- ============================================================

create or replace function public.create_family_invitation_link(
  p_family_id uuid,
  p_role public.family_member_role
)
returns public.family_invitation_links
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  v_user_id uuid;
  v_token text;
  v_link public.family_invitation_links;
begin
  v_user_id := auth.uid();

  if v_user_id is null then
    raise exception 'Not authenticated';
  end if;

  -- Only the family owner can create invitation links.
  if not exists (
    select 1
    from public.family_members fm
    where fm.family_id = p_family_id
      and fm.profile_id = v_user_id
      and fm.role = 'owner'
  ) then
    raise exception 'Only the family owner can create invitation links';
  end if;

  -- Only supported invitation roles are allowed.
  if p_role not in (
    'parent_guardian'::public.family_member_role,
    'caregiver'::public.family_member_role
  ) then
    raise exception 'Invalid invitation role';
  end if;

  -- Generate a unique random token.
  loop
    v_token := encode(gen_random_bytes(24), 'base64url');

    exit when not exists (
      select 1
      from public.family_invitation_links fil
      where fil.token = v_token
    );
  end loop;

  insert into public.family_invitation_links (
    family_id,
    token,
    created_by_profile_id,
    role,
    expires_at
  )
  values (
    p_family_id,
    v_token,
    v_user_id,
    p_role,
    now() + interval '10 minutes'
  )
  returning * into v_link;

  return v_link;
end;
$$;

grant execute on function public.create_family_invitation_link(
  uuid,
  public.family_member_role
) to authenticated;