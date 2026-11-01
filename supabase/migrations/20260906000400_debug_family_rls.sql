create or replace function public.debug_family_rls(
  p_created_by uuid
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
    'created_by', p_created_by,
    'matches', p_created_by = (select auth.uid())
  );
$$;

grant execute on function public.debug_family_rls(uuid) to authenticated;