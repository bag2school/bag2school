-- Bag2School V13.9
-- Atomic family creation RPC

create or replace function public.create_family(
  p_family_name text,
  p_display_name text
)
returns public.families
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user_id uuid;
  v_family public.families;
begin
  v_user_id := auth.uid();

  if v_user_id is null then
    raise exception 'Not authenticated';
  end if;

  if not exists (
    select 1
    from public.profiles
    where id = v_user_id
  ) then
    raise exception 'Profile not found';
  end if;

  insert into public.families (
    name,
    created_by
  )
  values (
    trim(p_family_name),
    v_user_id
  )
  returning * into v_family;

  insert into public.family_members (
    family_id,
    profile_id,
    role,
    display_name
  )
  values (
    v_family.id,
    v_user_id,
    'owner',
    trim(p_display_name)
  );

  return v_family;
end;
$$;

grant execute on function public.create_family(text, text)
to authenticated;