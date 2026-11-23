-- Admin portal support: let role 'admin' manage profiles (change user roles).
-- is_teacher() already treats admin as staff for reads; this adds admin WRITES.
create or replace function is_admin() returns boolean
language sql security definer stable set search_path = public as $$
  select exists (select 1 from profiles where id = auth.uid() and role = 'admin');
$$;

-- Admins may update ANY profile row (role management). Own-row policy already
-- exists; policies OR together, so this only adds cross-user writes.
create policy "profiles admin write" on profiles for update
  using (is_admin()) with check (is_admin());
