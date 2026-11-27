-- Fill in the Blank v2: cloze-with-options. The prompt carries a literal
-- [blank] token marking the gap; choices/correct_index hold the word bank
-- and key (same columns as multiple_choice). Legacy fill_blank rows keep
-- answer.accepted + typed answers — grading picks the branch by data shape.
--
-- 1) questions_public exposes choices for fill_blank
-- 2) submit_attempt: fill_blank = index match when correct_index is set,
--    else the original accepted-text match

drop view questions_public;
create view questions_public with (security_invoker = false) as
  select q.id, q.assessment_id, q.part_id, q.qtype, q.prompt, q.position,
         case when q.qtype in ('multiple_choice', 'multi_select', 'fill_blank')
              then q.choices end as choices,
         case when q.qtype = 'enumeration'
              then jsonb_build_object('n', jsonb_array_length(q.answer->'items'))
              when q.qtype = 'multi_select'
              then jsonb_build_object(
                     'min', coalesce((q.answer->>'min')::int, 0),
                     'max', coalesce((q.answer->>'max')::int,
                                     jsonb_array_length(q.choices)))
              else '{}'::jsonb end as meta
  from questions q
  join assessments a on a.id = q.assessment_id
  left join lessons l on l.id = a.lesson_id
  where a.is_published
    and (a.lesson_id is null
         or (l.is_published and (l.class_id is null or is_member(l.class_id))));
grant select on questions_public to authenticated;

create or replace function submit_attempt(p_assessment uuid, p_answers jsonb)
returns jsonb language plpgsql security definer set search_path = public as $$
declare v_attempt uuid; v_total int; v_score numeric; v_visible boolean;
        v_pts_earned numeric; v_pts_total numeric;
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
    case when q.qtype in ('multiple_choice', 'fill_blank')
              and (e.value->>'i') ~ '^-?\d+$'
         then (e.value->>'i')::int end,
    case q.qtype
      when 'multiple_choice' then
        case when (e.value->>'i') ~ '^-?\d+$' and (e.value->>'i')::int = q.correct_index
             then 1 else 0 end
      when 'multi_select' then (
        with picks as (
          select distinct (v::int) i
            from jsonb_array_elements_text(
              coalesce(e.value->'sel', '[]'::jsonb)) v
           where v ~ '^-?\d+$'),
        keys as (
          select distinct (v::int) i
            from jsonb_array_elements_text(
              coalesce(q.answer->'indexes', '[]'::jsonb)) v
           where v ~ '^-?\d+$'),
        agg as (
          select
            (select count(*) from picks p join keys k on k.i = p.i) hits,
            (select count(*) from picks p left join keys k on k.i = p.i
              where k.i is null) misses,
            greatest((select count(*) from keys), 1) kn)
        select case
          when coalesce((q.answer->>'partial')::boolean, true)
            then greatest(agg.hits - agg.misses, 0)::numeric / agg.kn
          else case when agg.misses = 0 and agg.hits >= agg.kn then 1 else 0 end
        end
        from agg)
      when 'true_false' then
        case when (e.value->>'b') is not null
                  and (e.value->>'b')::boolean = (q.answer->>'correct')::boolean
             then 1 else 0 end
      when 'fill_blank' then
        case
          -- Options mode (v2): pick the option that fills the blank.
          when q.correct_index is not null then
            case when (e.value->>'i') ~ '^-?\d+$'
                      and (e.value->>'i')::int = q.correct_index
                 then 1 else 0 end
          -- Legacy typed mode: accepted-answer text match.
          else
            case when answer_norm(e.value->>'t') in
                      (select answer_norm(x) from jsonb_array_elements_text(q.answer->'accepted') x)
                 then 1 else 0 end
        end
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
  -- Point aggregates: each item is worth its part's `points` (ungrouped = 1).
  select coalesce(round(sum(aa.earned * coalesce(ap.points, 1)), 2), 0),
         coalesce(sum(coalesce(ap.points, 1)), 0)
    into v_pts_earned, v_pts_total
    from attempt_answers aa
    join questions qq on qq.id = aa.question_id
    left join assessment_parts ap on ap.id = qq.part_id
    where aa.attempt_id = v_attempt
      and coalesce(ap.scored, true);
  if v_total = 0 then
    v_score := null; v_pts_earned := null; v_pts_total := null;
  end if;
  update attempts
     set score = v_score, total = v_total,
         points_earned = v_pts_earned, points_total = v_pts_total,
         submitted_at = now()
   where id = v_attempt;

  select (a.release_scores = 'immediate' or a.scores_released) into v_visible
    from assessments a where a.id = p_assessment;

  return jsonb_build_object('attempt_id', v_attempt, 'total', v_total,
    'released', v_visible,
    'points_earned', v_pts_earned, 'points_total', v_pts_total,
    'score', case when v_visible then v_score else null end);
end $$;
