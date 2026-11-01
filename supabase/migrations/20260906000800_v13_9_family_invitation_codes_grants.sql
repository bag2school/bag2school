-- Bag2School V13.9
-- Grant table privileges for authenticated family owners.
-- RLS policies remain responsible for restricting access.

grant select on public.family_invitation_codes to authenticated;
grant insert on public.family_invitation_codes to authenticated;
grant update on public.family_invitation_codes to authenticated;