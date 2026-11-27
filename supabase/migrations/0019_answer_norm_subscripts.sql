-- Subscript digits are kept in stored text (they render fine), so answer
-- matching folds them ONLY at compare time: a stored "H2O" still matches a
-- student typing "h2o". Everything else identical to 0017's submit_attempt.

create or replace function answer_norm(t text) returns text
language sql immutable set search_path = public as $$
  select translate(lower(trim(coalesce(t, ''))),
    '₀₁₂₃₄₅₆₇₈₉⁰¹²³⁴⁵⁶⁷⁸⁹',
    '01234567890123456789')
$$;

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
        case when answer_norm(e.value->>'t') in
                  (select answer_norm(x) from jsonb_array_elements_text(q.answer->'accepted') x)
             then 1 else 0 end
      when 'identification' then
        case when answer_norm(e.value->>'t') in
                  (select answer_norm(x) from jsonb_array_elements_text(q.answer->'accepted') x)
             then 1 else 0 end
      when 'enumeration' then (
        with exp as (select i, answer_norm(v) v from jsonb_array_elements_text(q.answer->'items') with ordinality t(v,i)),
             got as (select i, answer_norm(v) v from jsonb_array_elements_text(
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

  select count(*), coalesce(round(sum(aa.earned) * 100.0 / nullif(count(*),0), 2), 0)
    into v_total, v_score
    from attempt_answers aa
    join questions qq on qq.id = aa.question_id
    left join assessment_parts ap on ap.id = qq.part_id
    where aa.attempt_id = v_attempt
      and coalesce(ap.scored, true);
  if v_total = 0 then v_score := null; end if;
  update attempts set score = v_score, total = v_total, submitted_at = now() where id = v_attempt;

  select (a.release_scores = 'immediate' or a.scores_released) into v_visible
    from assessments a where a.id = p_assessment;

  return jsonb_build_object('attempt_id', v_attempt, 'total', v_total,
    'released', v_visible,
    'score', case when v_visible then v_score else null end);
end $$;
