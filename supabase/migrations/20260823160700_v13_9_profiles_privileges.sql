-- Bag2School V13.9
-- Profiles table privileges.
--
-- RLS policies already restrict authenticated users
-- to their own profile. This grant provides the
-- table-level SELECT privilege required for RLS.

grant select on table public.profiles to authenticated;