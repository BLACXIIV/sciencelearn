-- PostgREST privileges: RLS governs ROW access, but the `authenticated` API role
-- still needs statement-level GRANTs or every request is 42501 permission denied.
-- Only questions_public was granted in 0001; this grants the rest.
-- (This is what Supabase default privileges normally provide for the schema.)
grant usage on schema public to authenticated;
grant select, insert, update, delete on all tables in schema public to authenticated;
