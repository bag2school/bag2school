-- V13.9-P.3.1
-- Allow authenticated users to issue UPDATE on children.
-- RLS policy children_update_manager remains responsible
-- for restricting which children can be managed.

grant update on table public.children to authenticated;