-- Student-facing context block (e.g. the equations a classification sorts
-- into). Stored as answer.context (students can't read the key itself), so
-- questions_public projects it into meta for any qtype that carries one.
-- Grading is untouched.

drop view questions_public;
create view questions_public with (security_invoker = false) as
  select q.id, q.assessment_id, q.part_id, q.qtype, q.prompt, q.position,
         case when q.qtype in ('multiple_choice', 'multi_select', 'fill_blank',
                               'classification')
              then q.choices end as choices,
         (case when q.qtype = 'enumeration'
              then jsonb_build_object('n', jsonb_array_length(q.answer->'items'))
              when q.qtype = 'multi_select'
              then jsonb_build_object(
                     'min', coalesce((q.answer->>'min')::int, 0),
                     'max', coalesce((q.answer->>'max')::int,
                                     jsonb_array_length(q.choices)))
              when q.qtype = 'classification'
              then jsonb_build_object('buckets',
                     coalesce(q.answer->'buckets', '[]'::jsonb))
              else '{}'::jsonb end
         || case when q.answer ? 'context'
              then jsonb_build_object('context', q.answer->'context')
              else '{}'::jsonb end) as meta
  from questions q
  join assessments a on a.id = q.assessment_id
  left join lessons l on l.id = a.lesson_id
  where a.is_published
    and (a.lesson_id is null
         or (l.is_published and (l.class_id is null or is_member(l.class_id))));
grant select on questions_public to authenticated;
