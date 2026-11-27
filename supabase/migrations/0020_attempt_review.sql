-- One-shot submissions + post-submit review.
-- 1) submit_attempt refuses when the student already has a submitted attempt
--    (the UI hides the quiz, but the RPC is the real enforcement).
-- 2) review_attempt() returns the student's picks AND the answer keys, but
--    only once scores are visible — same rule as the "own read" RLS:
--    release_scores='immediate' or scores_released. Otherwise students could
--    read keys (and infer scores) before the teacher releases them.

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
  if exists (select 1 from attempts
             where assessment_id = p_assessment and student_id = auth.uid()
               and submitted_at is not null) then
    return jsonb_build_object('error', 'Already submitted');
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

-- Review: {attempted:false} | {attempted:true, released:false}
--       | {attempted:true, released:true, score, total, items:[...]}
-- items[] = {question_id, key (question answer jsonb), correct_index,
--            student (payload or null), is_correct, earned}
create or replace function review_attempt(p_assessment uuid)
returns jsonb language plpgsql security definer set search_path = public as $$
declare v_attempt uuid; v_score numeric; v_total int; v_visible boolean;
begin
  select t.id, t.score, t.total into v_attempt, v_score, v_total
    from attempts t
   where t.assessment_id = p_assessment and t.student_id = auth.uid()
     and t.submitted_at is not null
   order by t.submitted_at desc limit 1;
  if v_attempt is null then
    return jsonb_build_object('attempted', false);
  end if;
  select (a.release_scores = 'immediate' or a.scores_released) into v_visible
    from assessments a where a.id = p_assessment;
  if not coalesce(v_visible, false) then
    return jsonb_build_object('attempted', true, 'released', false);
  end if;
  return jsonb_build_object(
    'attempted', true, 'released', true,
    'score', v_score, 'total', v_total,
    'items', (select coalesce(jsonb_agg(it.row order by it.pos), '[]'::jsonb)
      from (select q.position pos,
        jsonb_build_object(
          'question_id', q.id,
          'key', q.answer,
          'correct_index', q.correct_index,
          'student', aa.answer,
          'is_correct', aa.is_correct,
          'earned', aa.earned) row
        from questions q
        left join attempt_answers aa
          on aa.question_id = q.id and aa.attempt_id = v_attempt
        where q.assessment_id = p_assessment) it));
end $$;

grant execute on function review_attempt(uuid) to authenticated;
