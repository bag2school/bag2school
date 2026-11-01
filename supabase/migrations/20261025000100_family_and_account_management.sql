-- Family management and self-service account deletion.
grant update on public.families to authenticated;

create or replace function public.leave_family_with_transfer(
  p_family_id uuid,
  p_new_owner_profile_id uuid default null
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_user_id uuid := auth.uid();
  v_role public.family_member_role;
begin
  if v_user_id is null then
    raise exception 'not_authenticated';
  end if;

  select role into v_role
  from public.family_members
  where family_id = p_family_id and profile_id = v_user_id
  for update;

  if v_role is null then
    raise exception 'not_a_family_member';
  end if;

  if v_role = 'owner' then
    if p_new_owner_profile_id is null or p_new_owner_profile_id = v_user_id then
      raise exception 'owner_transfer_required';
    end if;

    if not exists (
      select 1 from public.family_members
      where family_id = p_family_id
        and profile_id = p_new_owner_profile_id
        and profile_id <> v_user_id
    ) then
      raise exception 'new_owner_must_be_family_member';
    end if;

    update public.family_members
    set role = 'parent_guardian'
    where family_id = p_family_id and profile_id = v_user_id;

    update public.family_members
    set role = 'owner'
    where family_id = p_family_id and profile_id = p_new_owner_profile_id;

    update public.families
    set created_by = p_new_owner_profile_id
    where id = p_family_id and created_by = v_user_id;
  elsif p_new_owner_profile_id is not null then
    raise exception 'only_owner_can_transfer_ownership';
  end if;

  delete from public.family_members
  where family_id = p_family_id and profile_id = v_user_id;

  return jsonb_build_object('success', true, 'family_id', p_family_id);
end;
$$;

revoke all on function public.leave_family_with_transfer(uuid, uuid) from public;
grant execute on function public.leave_family_with_transfer(uuid, uuid) to authenticated;

create or replace function public.delete_own_account()
returns boolean
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_user_id uuid := auth.uid();
  v_family record;
  v_next_owner uuid;
begin
  if v_user_id is null then
    raise exception 'not_authenticated';
  end if;

  for v_family in
    select f.id, f.created_by,
           exists (
             select 1 from public.family_members fm
             where fm.family_id = f.id and fm.profile_id = v_user_id and fm.role = 'owner'
           ) as is_owner
    from public.families f
    where f.created_by = v_user_id
       or exists (
         select 1 from public.family_members fm
         where fm.family_id = f.id and fm.profile_id = v_user_id
       )
    for update
  loop
    select fm.profile_id into v_next_owner
    from public.family_members fm
    where fm.family_id = v_family.id and fm.profile_id <> v_user_id
    order by (fm.role = 'owner') desc, fm.created_at asc
    limit 1;

    if v_next_owner is null then
      delete from public.families where id = v_family.id;
    else
      if v_family.is_owner then
        update public.family_members
        set role = 'parent_guardian'
        where family_id = v_family.id and profile_id = v_user_id;

        update public.family_members
        set role = 'owner'
        where family_id = v_family.id and profile_id = v_next_owner;
      end if;

      update public.families
      set created_by = v_next_owner
      where id = v_family.id and created_by = v_user_id;
    end if;
  end loop;

  delete from auth.users where id = v_user_id;
  return true;
end;
$$;

revoke all on function public.delete_own_account() from public;
grant execute on function public.delete_own_account() to authenticated;