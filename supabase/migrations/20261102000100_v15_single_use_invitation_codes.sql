-- R-25: invitation codes are single use.
--
-- The join function used to insert the new member but leave the code active,
-- so the same four letters kept working for every later account within the ten
-- minute window. Now the code is marked used in the same transaction, which
-- also makes the app generate a fresh one the next time the owner opens the
-- invite screen.

alter table public.family_invitation_codes
  add column if not exists used_at timestamptz,
  add column if not exists used_by uuid
    references public.profiles(id) on delete set null;

create or replace function public.join_family_with_invitation_code(
  p_code text
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  current_user_id uuid := auth.uid();
  invitation_code public.family_invitation_codes%rowtype;
  existing_member public.family_members%rowtype;
  member_display_name text;
begin
  if current_user_id is null then
    return jsonb_build_object('success', false, 'reason', 'not_authenticated');
  end if;

  -- Lock the row so two phones cannot join with the same code at once.
  select *
  into invitation_code
  from public.family_invitation_codes
  where code = upper(trim(p_code))
    and is_active = true
  order by created_at desc
  limit 1
  for update;

  if not found then
    return jsonb_build_object('success', false, 'reason', 'not_found');
  end if;

  if invitation_code.used_at is not null then
    return jsonb_build_object('success', false, 'reason', 'used');
  end if;

  if invitation_code.expires_at <= now() then
    update public.family_invitation_codes
    set is_active = false
    where id = invitation_code.id;

    return jsonb_build_object('success', false, 'reason', 'expired');
  end if;

  select *
  into existing_member
  from public.family_members
  where family_id = invitation_code.family_id
    and profile_id = current_user_id
  limit 1;

  if found then
    return jsonb_build_object('success', false, 'reason', 'already_member');
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
    coalesce(nullif(trim(member_display_name), ''), 'Bag2School User')
  );

  -- Single use: the code stops working the moment it is accepted.
  update public.family_invitation_codes
  set is_active = false,
      used_at = now(),
      used_by = current_user_id
  where id = invitation_code.id;

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

comment on function public.join_family_with_invitation_code(text) is
  'Joins the calling account to a family and consumes the single-use code.';
