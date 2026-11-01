create or replace function public.debug_is_family_member(
  p_family_id uuid
)
returns json
language sql
stable
security definer
set search_path = public
as $$
  select json_build_object(
    'auth_uid', auth.uid(),
    'auth_role', auth.role(),
    'family_id', p_family_id,
    'member_exists', exists (
      select 1
      from public.family_members fm
      where fm.family_id = p_family_id
        and fm.profile_id = auth.uid()
    ),
    'is_family_member', public.is_family_member(p_family_id)
  );
$$;

grant execute on function public.debug_is_family_member(uuid)
to authenticated;