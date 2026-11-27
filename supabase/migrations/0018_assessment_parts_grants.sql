-- assessment_parts was created in 0017, after 0003's point-in-time
-- "grant ... on all tables" — so authenticated has no privileges on it and
-- every query touching it (incl. the assessments -> parts embed) is 42501.
grant select, insert, update, delete on assessment_parts to authenticated;

-- Default privileges so tables created by future migrations don't hit the
-- same wall (applies to tables created by the migration role from now on).
alter default privileges in schema public
  grant select, insert, update, delete on tables to authenticated;
