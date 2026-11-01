create or replace function public.debug_auth_context()
returns json
language sql
stable
security definer
set search_path = public
as $$
  select json_build_object(
    'uid', auth.uid(),
    'role', auth.role()
  );
$$;

grant execute on function public.debug_auth_context() to authenticated;