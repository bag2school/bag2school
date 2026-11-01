-- R-01 follow-up: table privileges for the API roles.
--
-- The schema was created by the postgres role, and the hosted project does not
-- grant the API roles by default, so every REST call failed with
-- "permission denied for table profiles". Row level security still decides which
-- rows a user may see; these grants only let the roles reach the tables.

grant usage on schema public to anon, authenticated;

grant select on all tables in schema public to anon;
grant select, insert, update, delete on all tables in schema public to authenticated;

grant usage, select on all sequences in schema public to anon, authenticated;

grant execute on all functions in schema public to anon, authenticated;

-- Future tables and functions created by migrations.
alter default privileges in schema public
  grant select on tables to anon;

alter default privileges in schema public
  grant select, insert, update, delete on tables to authenticated;

alter default privileges in schema public
  grant usage, select on sequences to anon, authenticated;

alter default privileges in schema public
  grant execute on functions to anon, authenticated;
