-- Signup-chosen role: reads 'role' from user metadata (defaults to student).
-- DEV ONLY — self-selecting 'teacher' is a privilege-escalation path;
-- restrict to invites/approval before production.
create or replace function handle_new_user() returns trigger
language plpgsql security definer set search_path = public as $$
declare v_role text := coalesce(new.raw_user_meta_data->>'role', 'student');
begin
  if v_role not in ('student','teacher','admin') then v_role := 'student'; end if;
  insert into profiles (id, full_name, role)
  values (
    new.id,
    coalesce(new.raw_user_meta_data->>'full_name', split_part(new.email,'@',1)),
    v_role::user_role
  );
  return new;
end $$;

-- Skip email confirmation entirely (dev convenience; remove before production).
create or replace function auto_confirm_user() returns trigger
language plpgsql as $$
begin
  new.email_confirmed_at := coalesce(new.email_confirmed_at, now());
  return new;
end $$;
drop trigger if exists auto_confirm_user on auth.users;
create trigger auto_confirm_user before insert on auth.users
  for each row execute function auto_confirm_user();

-- Confirm any accounts still pending.
update auth.users set email_confirmed_at = now() where email_confirmed_at is null;
