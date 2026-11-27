-- Progress rings now mean completion, not score:
--   lessons_pct     = avg progress across ALL published lessons of the class
--                     (unopened lessons count as 0 — same basis as the
--                     per-lesson list, which renders them at 0%)
--   quizzes_done_pct= submitted / total published assessments in the class
-- quizzes_pct stays the score average (used by "Quiz average" tiles).

create or replace view v_class_student_progress with (security_invoker = true) as
select e.class_id,
       p.id as student_id,
       p.full_name,
       coalesce((select round(coalesce(sum(lp.percent), 0)::numeric
                              / nullif(count(l.id), 0))
                   from lessons l
                   left join lesson_progress lp
                     on lp.lesson_id = l.id and lp.student_id = p.id
                  where l.class_id = e.class_id and l.is_published), 0) as lessons_pct,
       (select round(avg(a.score)) from attempts a
        join assessments s on s.id = a.assessment_id
        join lessons l on l.id = s.lesson_id
        where a.student_id = p.id and a.submitted_at is not null
          and l.class_id = e.class_id
          and s.kind in ('topic_quiz','problem_solving','final_challenge')) as quizzes_pct,
       (select a.score from attempts a
        join assessments s on s.id = a.assessment_id
        join lessons l on l.id = s.lesson_id
        where a.student_id = p.id and s.kind = 'pre_test'
          and l.class_id = e.class_id and a.submitted_at is not null
        order by a.submitted_at desc limit 1) as pre_score,
       (select a.score from attempts a
        join assessments s on s.id = a.assessment_id
        join lessons l on l.id = s.lesson_id
        where a.student_id = p.id and s.kind = 'post_test'
          and l.class_id = e.class_id and a.submitted_at is not null
        order by a.submitted_at desc limit 1) as post_score,
       coalesce((select round(count(distinct a.assessment_id) * 100.0
                              / nullif(count(distinct s.id), 0))::numeric
                   from assessments s
                   join lessons l on l.id = s.lesson_id
                   left join attempts a
                     on a.assessment_id = s.id and a.student_id = p.id
                     and a.submitted_at is not null
                  where s.is_published and l.class_id = e.class_id), 0) as quizzes_done_pct
from enrollments e
join profiles p on p.id = e.student_id
where e.status = 'active' and p.role = 'student';

grant select on v_class_student_progress to authenticated;
