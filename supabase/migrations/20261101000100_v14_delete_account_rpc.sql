-- R-10: account deletion.
--
-- Google Play requires apps that let people create an account to also let them
-- delete it. The app calls this function with the user's own token; everything
-- the account owns is removed first (families cascade to members, children,
-- grants, invitations and join requests), then the auth row itself, so nothing
-- is left orphaned.

create or replace function public.delete_my_account()
returns void
language plpgsql
security definer
set search_path = public, auth
as $$
declare
  uid uuid := auth.uid();
begin
  if uid is null then
    raise exception 'Not authenticated';
  end if;

  -- Families this account created. Cascades to child rows, memberships,
  -- access grants, invitation codes/links and join requests.
  delete from public.families where created_by = uid;

  -- Membership in other people's families, then the profile itself.
  delete from public.family_members where profile_id = uid;
  delete from public.profiles where id = uid;

  -- Finally the auth account, so the email can be used again.
  delete from auth.users where id = uid;
end;
$$;

revoke all on function public.delete_my_account() from public;
grant execute on function public.delete_my_account() to authenticated;

comment on function public.delete_my_account() is
  'Deletes the calling account, its memberships and any family it owns.';
