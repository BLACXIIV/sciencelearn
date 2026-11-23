-- Score release control per assessment.
-- release_scores 'immediate' = student sees the score right after submit (old behavior).
-- 'manual' = score stays hidden until the teacher sets scores_released = true.
-- Enforced at RLS level: students can't read their own attempt rows until release,
-- and submit_attempt only includes the score in its response when released.

alter table assessments
  add column if not exists release_scores text not null default 'immediate'
    check (release_scores in ('immediate','manual')),
  add column if not exists scores_released boolean not null default false;

drop policy if exists "attempts own read" on attempts;
create policy "attempts own read" on attempts for select using (
  is_teacher()
  or (student_id = auth.uid() and exists (
        select 1 from assessments a where a.id = attempts.assessment_id
          and (a.release_scores = 'immediate' or a.scores_released))));

drop policy if exists "answers own read" on attempt_answers;
create policy "answers own read" on attempt_answers for select using (
  exists (select 1 from attempts t where t.id = attempt_answers.attempt_id and is_teacher())
  or exists (select 1 from attempts t join assessments a on a.id = t.assessment_id
             where t.id = attempt_answers.attempt_id and t.student_id = auth.uid()
               and (a.release_scores = 'immediate' or a.scores_released)));

create or replace function submit_attempt(p_assessment uuid, p_answers jsonb)
returns jsonb language plpgsql security definer set search_path = public as $$
declare v_attempt uuid; v_total int; v_score numeric; v_visible boolean;
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

  select (a.release_scores = 'immediate' or a.scores_released) into v_visible
  from assessments a where a.id = p_assessment;

  return jsonb_build_object('attempt_id', v_attempt, 'total', v_total,
    'released', v_visible,
    'score', case when v_visible then v_score else null end);
end $$;
