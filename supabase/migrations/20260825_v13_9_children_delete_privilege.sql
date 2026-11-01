-- V13.9
-- Allow authenticated users to issue DELETE on children.
-- RLS policy children_delete_owner remains responsible
-- for restricting deletion to the family owner.

grant delete on table public.children to authenticated;