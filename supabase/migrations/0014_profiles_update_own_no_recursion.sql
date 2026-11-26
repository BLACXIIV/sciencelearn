-- "profiles update own" carried a raw self-referencing subquery in WITH CHECK:
--   role = (select role from profiles where id = auth.uid())
-- Any subquery on profiles inside a profiles policy re-enters RLS evaluation
-- on the same relation -> 42P17 infinite recursion -> EVERY profile update
-- failed (avatar keys, settings, anything). Wrap the self-lookup in a
-- security-definer function so the check sees a scalar, not a table hit.
-- plpgsql (not sql) keeps the body opaque to the inliner.

create or replace function my_role() returns user_role
language plpgsql security definer stable set search_path = public as $$
begin
  return (select role from profiles where id = auth.uid());
end;
$$;

drop policy "profiles update own" on profiles;
create policy "profiles update own" on profiles for update
  using (id = auth.uid())
  with check (id = auth.uid() and role = my_role());
