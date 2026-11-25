-- Per-class student progress: same metrics as v_student_progress, but each row
-- is one active enrollment and every metric is filtered to THAT class's
-- lessons/assessments. Powers the class-scoped teacher dashboard + roster chips.
create view v_class_student_progress with (security_invoker = true) as
select e.class_id,
       p.id as student_id,
       p.full_name,
       coalesce((select round(avg(lp.percent)) from lesson_progress lp
                 join lessons l on l.id = lp.lesson_id
                 where lp.student_id = p.id and l.class_id = e.class_id), 0) as lessons_pct,
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
        order by a.submitted_at desc limit 1) as post_score
from enrollments e
join profiles p on p.id = e.student_id
where e.status = 'active' and p.role = 'student';

grant select on v_class_student_progress to authenticated;
