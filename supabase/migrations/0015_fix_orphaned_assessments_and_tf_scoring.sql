-- Backend bug fixes (audit 2026-11-26):
--
-- 1) Orphaned assessments (lesson_id IS NULL) were zombies: students could not
--    see or submit them, and nobody could edit/delete them — every visibility
--    and write check joined assessments -> lessons, which drops NULL lesson_id.
--    0007 introduced those joins when class-scoping landed; published quizzes
--    created before it (or detached by a lesson delete) got stuck.
--    Rule now mirrors the NULL-class_id lesson convention from 0007:
--    a published orphan stays readable by every signed-in student ("legacy
--    shared") and only admins can write it.
--
-- 2) Activities inside DRAFT lessons were playable: assessments read,
--    questions_public and submit_attempt checked the assessment's is_published
--    and class membership but never the parent lesson's is_published. Member
--    visibility now requires the lesson to be published too.
--
-- 3) submit_attempt scored SKIPPED true/false questions as correct whenever
--    the answer key was 'false': coalesce((e.value->>'b')::boolean, false)
--    turned a missing answer into 'false', which then equaled the key.
--    The check now requires an actual 'b' answer. Also hardens the MC cast
--    against non-numeric payloads and restricts submissions to students.
--
-- 4) Lesson deletes can no longer orphan assessments: FK ON DELETE SET NULL
--    -> RESTRICT. Clients already block this UI-side; the DB now enforces it
--    instead of silently producing unreachable rows.
--
-- 5) my_attempted_assessment_ids(): lets the "N to do" badges count attempted
--    assessments without exposing scores. Plain table reads can't be used —
--    "attempts own read" hides unreleased attempts by design.

-- ---------- 1+2: visibility rules ----------

drop policy if exists "assessments read" on assessments;
create policy "assessments read" on assessments for select using (
  is_teacher()
  or (is_published and (
        lesson_id is null                              -- legacy shared quiz
        or exists (select 1 from lessons l
                   where l.id = assessments.lesson_id
                     and l.is_published
                     and (l.class_id is null or is_member(l.class_id)))))
);

drop view questions_public;
create view questions_public with (security_invoker = false) as
  select q.id, q.assessment_id, q.qtype, q.prompt, q.position,
         case when q.qtype = 'multiple_choice' then q.choices end as choices,
         case when q.qtype = 'enumeration'
              then jsonb_build_object('n', jsonb_array_length(q.answer->'items'))
              else '{}'::jsonb end as meta
  from questions q
  join assessments a on a.id = q.assessment_id
  left join lessons l on l.id = a.lesson_id
  where a.is_published
    and (a.lesson_id is null
         or (l.is_published and (l.class_id is null or is_member(l.class_id))));
grant select on questions_public to authenticated;

-- ---------- 1: write rules (orphans are admin-only, like NULL-class lessons) ----------

drop policy if exists "assessments write" on assessments;
create policy "assessments write" on assessments for all
  using ((lesson_id is null and is_admin())
         or exists (select 1 from lessons l where l.id = assessments.lesson_id
                    and teaches_class(l.class_id)))
  with check ((lesson_id is null and is_admin())
              or exists (select 1 from lessons l where l.id = assessments.lesson_id
                         and teaches_class(l.class_id)));

drop policy if exists "questions teacher only" on questions;
create policy "questions teacher only" on questions for all
  using (exists (select 1 from assessments a left join lessons l on l.id = a.lesson_id
                 where a.id = questions.assessment_id
                   and ((a.lesson_id is null and is_admin()) or teaches_class(l.class_id))))
  with check (exists (select 1 from assessments a left join lessons l on l.id = a.lesson_id
                      where a.id = questions.assessment_id
                        and ((a.lesson_id is null and is_admin()) or teaches_class(l.class_id))));

-- ---------- 4: stop creating orphans ----------

alter table assessments drop constraint if exists assessments_lesson_id_fkey;
alter table assessments
  add constraint assessments_lesson_id_fkey
  foreign key (lesson_id) references lessons(id) on delete restrict;

-- ---------- 3: submit_attempt ----------

create or replace function submit_attempt(p_assessment uuid, p_answers jsonb)
returns jsonb language plpgsql security definer set search_path = public as $$
declare v_attempt uuid; v_total int; v_score numeric; v_visible boolean;
begin
  if my_role() is distinct from 'student'::user_role then
    return jsonb_build_object('error', 'Only students can submit attempts');
  end if;
  if not exists (select 1 from assessments a left join lessons l on l.id = a.lesson_id
                 where a.id = p_assessment and a.is_published
                   and (a.lesson_id is null
                        or (l.is_published and (l.class_id is null or is_member(l.class_id))))) then
    return jsonb_build_object('error', 'Assessment not available');
  end if;
  insert into attempts (assessment_id, student_id) values (p_assessment, auth.uid())
    returning id into v_attempt;

  insert into attempt_answers (attempt_id, question_id, answer, chosen_index, earned)
  select
    v_attempt, q.id, e.value,
    case when q.qtype = 'multiple_choice' and (e.value->>'i') ~ '^-?\d+$'
         then (e.value->>'i')::int end,
    case q.qtype
      when 'multiple_choice' then
        case when (e.value->>'i') ~ '^-?\d+$' and (e.value->>'i')::int = q.correct_index
             then 1 else 0 end
      when 'true_false' then
        case when (e.value->>'b') is not null
                  and (e.value->>'b')::boolean = (q.answer->>'correct')::boolean
             then 1 else 0 end
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

  select (a.release_scores = 'immediate' or a.scores_released) into v_visible
  from assessments a where a.id = p_assessment;

  return jsonb_build_object('attempt_id', v_attempt, 'total', v_total,
    'released', v_visible,
    'score', case when v_visible then v_score else null end);
end $$;

-- ---------- 5: attempted-ids for the "N to do" badges (no scores leak) ----------

create or replace function my_attempted_assessment_ids() returns jsonb
language sql stable security definer set search_path = public as $$
  select coalesce(jsonb_agg(distinct assessment_id), '[]'::jsonb)
  from attempts where student_id = auth.uid() and submitted_at is not null;
$$;
