-- Bag2School V13.9
-- Grant the authenticated role the SQL privilege required
-- to update its own profile row.
--
-- RLS remains responsible for restricting which profile row
-- an authenticated user is allowed to update.

grant update on table public.profiles to authenticated;
