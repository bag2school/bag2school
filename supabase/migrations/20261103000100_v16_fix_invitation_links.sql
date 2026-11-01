-- R-28: invitation links work.
--
-- The previous function used encode(..., 'base64url'), which Postgres does not
-- support (valid formats are base64, hex and escape), so creating a link always
-- failed. The token is now plain hex, the table is reachable by the API role,
-- and this migration also documents the single-use contract.

create unique index if not exists family_invitation_links_token_unique
on public.family_invitation_links (token);

grant select, insert, update
on public.family_invitation_links
to authenticated;

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

  if not exists (
    select 1
    from public.family_members fm
    where fm.family_id = p_family_id
      and fm.profile_id = v_user_id
      and fm.role = 'owner'
  ) then
    raise exception 'Only the family owner can create invitation links';
  end if;

  if p_role not in (
    'parent_guardian'::public.family_member_role,
    'caregiver'::public.family_member_role
  ) then
    raise exception 'Invalid invitation role';
  end if;

  -- A fresh link every time. Old links stay valid until they expire or are
  -- used, but the owner always shares the newest one.
  loop
    v_token := encode(gen_random_bytes(24), 'hex');

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

comment on function public.create_family_invitation_link(uuid, public.family_member_role)
is 'Creates a single-use invitation link token valid for ten minutes.';
