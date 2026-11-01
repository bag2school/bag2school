-- ============================================================
-- Bag2School V13.9
-- Validate family invitation code through a secure RPC.
-- Users do not need to be family members to validate a code.
-- ============================================================

create or replace function public.validate_family_invitation_code(
  p_code text
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  invitation_code public.family_invitation_codes%rowtype;
begin
  select *
  into invitation_code
  from public.family_invitation_codes
  where code = upper(trim(p_code))
    and is_active = true
  order by created_at desc
  limit 1;

  if not found then
    return jsonb_build_object(
      'valid', false,
      'reason', 'not_found'
    );
  end if;

  if invitation_code.expires_at <= now() then
    update public.family_invitation_codes
    set is_active = false
    where id = invitation_code.id;

    return jsonb_build_object(
      'valid', false,
      'reason', 'expired'
    );
  end if;

  return jsonb_build_object(
    'valid', true,
    'reason', 'valid',
    'family_id', invitation_code.family_id,
    'code_id', invitation_code.id,
    'role', invitation_code.role,
    'expires_at', invitation_code.expires_at
  );
end;
$$;

grant execute
on function public.validate_family_invitation_code(text)
to authenticated;