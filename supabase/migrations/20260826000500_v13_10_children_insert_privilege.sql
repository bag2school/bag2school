-- Allow authenticated users to create children
grant insert on public.children to authenticated;

-- Required because the app uses .insert(...).select().single()
grant select on public.children to authenticated;