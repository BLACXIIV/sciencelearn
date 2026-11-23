-- Class join codes + student join flow.
-- Teachers create classes; each gets a short auto-generated code.
-- Students redeem the code via join_class (SECURITY DEFINER: enrollments
-- insert is teacher-gated, so the function does it on the student's behalf).

-- Unambiguous alphabet (no 0/O/1/I) so codes are easy to read aloud or type.
create or replace function gen_class_code() returns text
language sql volatile set search_path = public as $$
  select string_agg(substr('ABCDEFGHJKMNPQRSTUVWXYZ23456789',
                           (floor(random() * 30) + 1)::int, 1), '')
  from generate_series(1, 6)
$$;

alter table classes
  add column code text not null default gen_class_code() unique;

-- Students can read only the classes they are enrolled in (name, teacher).
create policy "classes student read enrolled" on classes for select
  using (exists (select 1 from enrollments e
                 where e.class_id = id and e.student_id = auth.uid()));

-- Redeem a code. Errors come back in the payload so the client shows them
-- inline instead of failing on an exception.
create or replace function join_class(p_code text) returns jsonb
language plpgsql security definer set search_path = public as $$
declare v_class classes%rowtype;
begin
  if not exists (select 1 from profiles where id = auth.uid() and role = 'student') then
    return jsonb_build_object('error', 'Only students can join classes');
  end if;
  select * into v_class from classes where code = upper(trim(p_code));
  if not found then
    return jsonb_build_object('error', 'Invalid class code');
  end if;
  insert into enrollments (class_id, student_id)
  values (v_class.id, auth.uid())
  on conflict (class_id, student_id) do nothing;
  return jsonb_build_object('class_id', v_class.id, 'name', v_class.name);
end $$;
