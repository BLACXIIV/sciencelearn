-- Backfill point totals for attempts submitted before per-part points
-- existed (0021): recompute earned*points and total points over scored
-- questions exactly the way submit_attempt does. Attempts whose questions
-- are all unscored get no subquery row and stay null -> "--" like before.

update attempts t
   set points_earned = sub.pe,
       points_total = sub.pt
  from (
    select aa.attempt_id,
           round(sum(aa.earned * coalesce(ap.points, 1)), 2) pe,
           sum(coalesce(ap.points, 1)) pt
      from attempt_answers aa
      join questions q on q.id = aa.question_id
      left join assessment_parts ap on ap.id = q.part_id
      where coalesce(ap.scored, true)
      group by aa.attempt_id
  ) sub
 where t.id = sub.attempt_id
   and t.points_total is null;
