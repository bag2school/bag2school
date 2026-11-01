-- ============================================================
-- Bag2School V13.9
-- Direct family join through invitation code RPC
-- ============================================================

create or replace function public.join_family_with_invitation_code(
  p_code text
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  current_user_id uuid;
  invitation_code public.family_invitation_codes%rowtype;
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
  into invitation_code
  from public.family_invitation_codes
  where code = upper(trim(p_code))
    and is_active = true
  order by created_at desc
  limit 1;

  if not found then
    return jsonb_build_object(
      'success', false,
      'reason', 'not_found'
    );
  end if;

  if invitation_code.expires_at <= now() then
    update public.family_invitation_codes
    set is_active = false
    where id = invitation_code.id;

    return jsonb_build_object(
      'success', false,
      'reason', 'expired'
    );
  end if;

  select *
  into existing_member
  from public.family_members
  where family_id = invitation_code.family_id
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
    invitation_code.family_id,
    current_user_id,
    invitation_code.role::family_member_role,
    coalesce(
      nullif(trim(member_display_name), ''),
      'Bag2School User'
    )
  );

  return jsonb_build_object(
    'success', true,
    'reason', 'joined',
    'family_id', invitation_code.family_id,
    'code_id', invitation_code.id,
    'role', invitation_code.role
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
on function public.join_family_with_invitation_code(text)
to authenticated;