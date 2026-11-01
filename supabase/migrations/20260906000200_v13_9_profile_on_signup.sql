-- Bag2School V13.9
-- Automatically create a public profile for every new Auth user.

create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.profiles (
  id,
  display_name,
  preferred_title
)
values (
  new.id,
  coalesce(
    nullif(trim(new.raw_user_meta_data ->> 'display_name'), ''),
    'Bag2School User'
  ),
  coalesce(
    nullif(trim(new.raw_user_meta_data ->> 'display_name'), ''),
    'Bag2School User'
  )
)
  on conflict (id) do nothing;

  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;

create trigger on_auth_user_created
  after insert on auth.users
  for each row
  execute function public.handle_new_user();