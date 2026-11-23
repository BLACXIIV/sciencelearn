-- Classrooms own lessons. Lessons must belong to a class going forward;
-- students only see published lessons in classes where they are ACTIVE members.
-- Classes get join_policy ('open' = instant join, 'approval' = teacher confirms).
-- enrollments.status: 'active' | 'pending'. Legacy NULL-class_id lessons stay
-- readable by everyone and editable only by admins.

alter table lessons
  add column if not exists class_id uuid references classes(id) on delete cascade;

alter table classes
  add column if not exists join_policy text not null default 'open'
    check (join_policy in ('open','approval'));

alter table enrollments
  add column if not exists status text not null default 'active'
    check (status in ('active','pending'));

create index if not exists lessons_class_idx on lessons(class_id);
create index if not exists enrollments_class_student_idx on enrollments(class_id, student_id);

-- May already exist (0004); create-or-replace keeps this migration self-contained.
create or replace function is_admin() returns boolean
language sql security definer stable set search_path = public as $$
  select exists (select 1 from profiles where id = auth.uid() and role = 'admin');
$$;

-- Same for the admin profile-write policy from 0004 (in case it was never applied).
drop policy if exists "profiles admin write" on profiles;
create policy "profiles admin write" on profiles for update
  using (is_admin()) with check (is_admin());

-- Caller is an ACTIVE enrolled student of the class.
create or replace function is_member(p_class uuid) returns boolean
language sql stable security definer set search_path = public as $$
  select exists (select 1 from enrollments
                 where class_id = p_class and student_id = auth.uid() and status = 'active');
$$;

-- Caller owns the class (or is an admin).
create or replace function teaches_class(p_class uuid) returns boolean
language sql stable security definer set search_path = public as $$
  select exists (select 1 from classes
                 where id = p_class and (teacher_id = auth.uid() or is_admin()));
$$;

-- ---- classes: teachers can still browse the directory; only own classes are writable
drop policy if exists "classes teacher" on classes;
drop policy if exists "classes teacher read" on classes;
drop policy if exists "classes teacher write" on classes;
create policy "classes teacher read" on classes for select using (is_teacher());
create policy "classes teacher write" on classes for all
  using (teacher_id = auth.uid() or is_admin())
  with check (teacher_id = auth.uid() or is_admin());

-- ---- enrollments: scoped to own classes (teacher approve/reject/remove)
drop policy if exists "enroll teacher" on enrollments;
create policy "enroll teacher" on enrollments for all
  using (teaches_class(class_id)) with check (teaches_class(class_id));

drop policy if exists "enroll read" on enrollments;
create policy "enroll read" on enrollments for select
  using (student_id = auth.uid() or teaches_class(class_id));

-- ---- lessons: class-scoped visibility, own-class writes
drop policy if exists "lessons read" on lessons;
create policy "lessons read" on lessons for select using (
  class_id is null                       -- legacy shared lessons
  or teaches_class(class_id)
  or (is_published and is_member(class_id))
);

drop policy if exists "lessons write" on lessons;
create policy "lessons write" on lessons for all
  using ((class_id is null and is_admin()) or (class_id is not null and teaches_class(class_id)))
  with check (class_id is not null and teaches_class(class_id));

-- ---- assessments: students only see published ones under visible lessons;
-- teacher writes scoped to lessons in own classes.
drop policy if exists "assessments read" on assessments;
create policy "assessments read" on assessments for select using (
  is_teacher()
  or (is_published and exists (
        select 1 from lessons l where l.id = assessments.lesson_id
          and (l.class_id is null or is_member(l.class_id))))
);

drop policy if exists "assessments write" on assessments;
create policy "assessments write" on assessments for all
  using (exists (select 1 from lessons l where l.id = assessments.lesson_id
                 and teaches_class(l.class_id)))
  with check (exists (select 1 from lessons l where l.id = assessments.lesson_id
                      and teaches_class(l.class_id)));

-- ---- questions: teacher CRUD scoped to own-class assessments
drop policy if exists "questions teacher only" on questions;
create policy "questions teacher only" on questions for all
  using (exists (select 1 from assessments a join lessons l on l.id = a.lesson_id
                 where a.id = questions.assessment_id and teaches_class(l.class_id)))
  with check (exists (select 1 from assessments a join lessons l on l.id = a.lesson_id
                      where a.id = questions.assessment_id and teaches_class(l.class_id)));

-- ---- questions_public view runs as definer; add the same visibility rule so
-- students can't read questions from classes they aren't active members of.
drop view questions_public;
create view questions_public with (security_invoker = false) as
  select q.id, q.assessment_id, q.qtype, q.prompt, q.position,
         case when q.qtype = 'multiple_choice' then q.choices end as choices,
         case when q.qtype = 'enumeration'
              then jsonb_build_object('n', jsonb_array_length(q.answer->'items'))
              else '{}'::jsonb end as meta
  from questions q
  join assessments a on a.id = q.assessment_id
  join lessons l on l.id = a.lesson_id
  where a.is_published
    and (l.class_id is null or is_member(l.class_id));
grant select on questions_public to authenticated;

-- ---- submit_attempt guard: only published assessments under visible lessons.
create or replace function submit_attempt(p_assessment uuid, p_answers jsonb)
returns jsonb language plpgsql security definer set search_path = public as $$
declare v_attempt uuid; v_total int; v_score numeric;
begin
  if not exists (select 1 from assessments a join lessons l on l.id = a.lesson_id
                 where a.id = p_assessment and a.is_published
                   and (l.class_id is null or is_member(l.class_id))) then
    return jsonb_build_object('error', 'Assessment not available');
  end if;
  insert into attempts (assessment_id, student_id) values (p_assessment, auth.uid())
    returning id into v_attempt;

  insert into attempt_answers (attempt_id, question_id, answer, chosen_index, earned)
  select
    v_attempt, q.id, e.value,
    case when q.qtype = 'multiple_choice' then (e.value->>'i')::int end,
    case q.qtype
      when 'multiple_choice' then
        case when (e.value->>'i')::int = q.correct_index then 1 else 0 end
      when 'true_false' then
        case when coalesce((e.value->>'b')::boolean, false) = (q.answer->>'correct')::boolean then 1 else 0 end
      when 'fill_blank' then
        case when lower(trim(coalesce(e.value->>'t',''))) in
                  (select lower(trim(x)) from jsonb_array_elements_text(q.answer->'accepted') x)
             then 1 else 0 end
      when 'identification' then
        case when lower(trim(coalesce(e.value->>'t',''))) in
                  (select lower(trim(x)) from jsonb_array_elements_text(q.answer->'accepted') x)
             then 1 else 0 end
      when 'enumeration' then (
        with exp as (select i, lower(trim(v)) v from jsonb_array_elements_text(q.answer->'items') with ordinality t(v,i)),
             got as (select i, lower(trim(v)) v from jsonb_array_elements_text(
                        coalesce(e.value->'items','[]'::jsonb)) with ordinality t(v,i)),
             matched as (
               select
                 case when (q.answer->>'ordered')::boolean
                   then (select count(*) from exp join got using (i) where exp.v = got.v)
                   else (select coalesce(sum(least(e.n, g.n)), 0)
                           from (select v, count(*) n from exp group by v) e
                           join (select v, count(*) n from got group by v) g using (v))
                 end as n),
             exp_n as (select greatest(count(*), 1) n from exp)
        select case
          when coalesce((q.answer->>'partial')::boolean, true)
               then least(matched.n, exp_n.n)::numeric / exp_n.n
          else case when matched.n >= exp_n.n then 1 else 0 end
        end
        from matched, exp_n)
      else 0
    end
  from questions q
  left join jsonb_each(p_answers) e on e.key = q.id::text
  where q.assessment_id = p_assessment;

  update attempt_answers set is_correct = (earned >= 1) where attempt_id = v_attempt;

  select count(*), coalesce(round(sum(earned) * 100.0 / nullif(count(*),0), 2), 0)
    into v_total, v_score
    from attempt_answers where attempt_id = v_attempt;
  update attempts set score = v_score, total = v_total, submitted_at = now() where id = v_attempt;

  return jsonb_build_object('attempt_id', v_attempt, 'score', v_score, 'total', v_total);
end $$;

-- ---- join_class v2: honors join_policy, returns status so the UI can say
-- "joined" vs "pending approval". Idempotent: rejoining returns current status.
create or replace function join_class(p_code text) returns jsonb
language plpgsql security definer set search_path = public as $$
declare v_class classes%rowtype; v_status text;
begin
  if not exists (select 1 from profiles where id = auth.uid() and role = 'student') then
    return jsonb_build_object('error', 'Only students can join classes');
  end if;
  select * into v_class from classes where code = upper(trim(p_code));
  if not found then
    return jsonb_build_object('error', 'Invalid class code');
  end if;
  select status into v_status from enrollments
    where class_id = v_class.id and student_id = auth.uid();
  if found then
    return jsonb_build_object('class_id', v_class.id, 'name', v_class.name, 'status', v_status);
  end if;
  v_status := case when v_class.join_policy = 'approval' then 'pending' else 'active' end;
  insert into enrollments (class_id, student_id, status)
  values (v_class.id, auth.uid(), v_status);
  return jsonb_build_object('class_id', v_class.id, 'name', v_class.name, 'status', v_status);
end $$;
