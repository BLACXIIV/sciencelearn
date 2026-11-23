-- Question types for teacher-built activities.
-- MC keeps choices/correct_index; other types store their key in questions.answer:
--   true_false:      {"correct": true}
--   fill_blank:      {"accepted": ["volcano","a volcano"]}      (case-insensitive, trimmed)
--   identification:  {"accepted": ["..."]}                      (same match rule)
--   enumeration:     {"items": ["a","b","c"], "ordered": false, "partial": true}
-- attempt_answers gains answer jsonb (student payload) + earned numeric (0..1, allows
-- enumeration partial credit). is_correct stays as the "fully correct" flag.
create type question_type as enum
  ('multiple_choice','true_false','fill_blank','enumeration','identification');

alter table questions
  add column qtype question_type not null default 'multiple_choice',
  add column answer jsonb,
  alter column choices drop not null,
  alter column correct_index drop not null;

alter table attempt_answers
  add column answer jsonb,
  add column earned numeric(4,3);

-- Student-facing view: never exposes answer keys. choices only for MC;
-- meta carries the enumeration item count so runners know how many blanks to draw.
drop view questions_public;
create view questions_public with (security_invoker = false) as
  select q.id, q.assessment_id, q.qtype, q.prompt, q.position,
         case when q.qtype = 'multiple_choice' then q.choices end as choices,
         case when q.qtype = 'enumeration'
              then jsonb_build_object('n', jsonb_array_length(q.answer->'items'))
              else '{}'::jsonb end as meta
  from questions q join assessments a on a.id = q.assessment_id
  where a.is_published;
grant select on questions_public to authenticated;

-- Answer payload shape per question id:
--   MC {i: n}  TF {b: bool}  fill_blank/identification {t: "..."}  enumeration {items: [...]}
create or replace function submit_attempt(p_assessment uuid, p_answers jsonb)
returns jsonb language plpgsql security definer set search_path = public as $$
declare v_attempt uuid; v_total int; v_score numeric;
begin
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
