-- Bag2School V13.9-S
-- Consume family invitation link
-- Single-use invitation link with direct family join
-- ============================================================

create or replace function public.consume_family_invitation_link(
  p_token text
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  current_user_id uuid;
  invitation_link public.family_invitation_links%rowtype;
  existing_member public.family_members%rowtype;
  member_display_name text;
begin
  current_user_id := auth.uid();

  if current_user_id is null then
    return jsonb_build_object(
      'success', false,
      'reason', 'not_authenticated'
    );
  end if;

  select *
  into invitation_link
  from public.family_invitation_links
  where token = trim(p_token)
    and is_active = true
    and used_at is null
  order by created_at desc
  limit 1
  for update;

  if not found then
    return jsonb_build_object(
      'success', false,
      'reason', 'not_found'
    );
  end if;

  if invitation_link.expires_at <= now() then
    update public.family_invitation_links
    set is_active = false
    where id = invitation_link.id;

    return jsonb_build_object(
      'success', false,
      'reason', 'expired'
    );
  end if;

  select *
  into existing_member
  from public.family_members
  where family_id = invitation_link.family_id
    and profile_id = current_user_id
  limit 1;

  if found then
    return jsonb_build_object(
      'success', false,
      'reason', 'already_member'
    );
  end if;

  select display_name
  into member_display_name
  from public.profiles
  where id = current_user_id
  limit 1;

  insert into public.family_members (
    family_id,
    profile_id,
    role,
    display_name
  )
  values (
    invitation_link.family_id,
    current_user_id,
    invitation_link.role::family_member_role,
    coalesce(
      nullif(trim(member_display_name), ''),
      'Bag2School User'
    )
  );

  update public.family_invitation_links
  set
    is_active = false,
    used_at = now(),
    used_by_profile_id = current_user_id
  where id = invitation_link.id;

  return jsonb_build_object(
    'success', true,
    'reason', 'joined',
    'family_id', invitation_link.family_id,
    'link_id', invitation_link.id,
    'role', invitation_link.role
  );

exception
  when others then
    return jsonb_build_object(
      'success', false,
      'reason', 'error',
      'message', sqlerrm
    );
end;
$$;

grant execute
on function public.consume_family_invitation_link(text)
to authenticated;