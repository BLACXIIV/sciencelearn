-- 0032_builder.sql — Teacher quiz-builder support.
--
-- 1) preview_questions(p_assessment): teacher-only SECURITY DEFINER RPC that
--    returns the student-view payload — parts (parts_public shape + points)
--    and questions with the EXACT questions_public projection (choices
--    trimmed per qtype + public meta; answer / correct_index are never in
--    the projection) — so a teacher can preview the activity exactly as
--    students see it, including unpublished drafts. Questions order by part
--    position then question position; ungrouped items go last, matching the
--    runner's part-aware sort.
-- 2) assessment_publish_guard: BEFORE UPDATE on assessments blocks
--    is_published false -> true when the activity has zero questions.
--    Only that transition fires — title/release/points/unpublish untouched.
-- 3) assessment_delete_guard: BEFORE DELETE on assessments blocks deleting
--    an activity that has attempts ("Students already took this. Unpublish
--    it instead."). Direct deletes only: assessments.lesson_id is
--    ON DELETE RESTRICT (0015) — lesson/class deletes that still own
--    activities are already rejected by the FK before any assessment row
--    is touched, so they can never trip the trigger.
-- 4) Idempotent position repair: renumber assessment_parts.position per
--    assessment and questions.position per (assessment, part) to dense
--    0..n-1, fixing collisions left by older clients. "is distinct from"
--    makes reruns no-ops.

-- ---------- 1) preview_questions ----------
create or replace function preview_questions(p_assessment uuid)
returns jsonb language plpgsql security definer set search_path = public as $$
declare
  v_ok boolean;
  v_parts jsonb;
  v_questions jsonb;
begin
  -- Teacher scope: owns the lesson's class, or admin for orphan activities.
  -- Same write scope as parts/questions policies (0017).
  select exists (
    select 1
    from assessments a left join lessons l on l.id = a.lesson_id
    where a.id = p_assessment
      and (teaches_class(l.class_id) or (a.lesson_id is null and is_admin())))
  into v_ok;
  if not v_ok then
    return jsonb_build_object('error', 'Not allowed');
  end if;

  -- parts_public shape + points (super-set: the runner reads title,
  -- directions, mode, scored, position; points feeds the editor header).
  select coalesce(jsonb_agg(p.row order by p.pos), '[]'::jsonb)
  into v_parts
  from (
    select p.position pos,
           jsonb_build_object(
             'id', p.id, 'assessment_id', p.assessment_id,
             'title', p.title, 'directions', p.directions,
             'mode', p.mode, 'scored', p.scored,
             'points', p.points, 'position', p.position) as row
    from assessment_parts p
    where p.assessment_id = p_assessment) p;

  -- questions_public projection verbatim (0031): choices trimmed per qtype
  -- + public meta. answer / correct_index are never projected.
  select coalesce(jsonb_agg(x.row order by x.part_pos, x.pos, x.id), '[]'::jsonb)
  into v_questions
  from (
    select coalesce(ap.position, 2147483647) part_pos,
           q.position pos, q.id,
           jsonb_build_object(
             'id', q.id,
             'assessment_id', q.assessment_id,
             'part_id', q.part_id,
             'qtype', q.qtype,
             'prompt', q.prompt,
             'position', q.position,
             'choices', case
                 when q.qtype in ('multiple_choice', 'multi_select',
                                  'fill_blank', 'classification', 'ordering')
                 then q.choices end,
             'meta', (
               case
                 when q.qtype = 'enumeration'
                   then jsonb_build_object('n',
                          jsonb_array_length(q.answer->'items'))
                 when q.qtype = 'multi_select'
                   then jsonb_build_object(
                          'min', coalesce((q.answer->>'min')::int, 0),
                          'max', coalesce((q.answer->>'max')::int,
                                   jsonb_array_length(q.choices)))
                 when q.qtype = 'classification'
                   then jsonb_build_object('buckets',
                          coalesce(q.answer->'buckets', '[]'::jsonb))
                 when q.qtype = 'ordering'
                   then jsonb_build_object('shuffle',
                          coalesce((q.answer->>'shuffle')::boolean, true))
                 else '{}'::jsonb end
               || case when q.answer ? 'context'
                    then jsonb_build_object('context', q.answer->'context')
                    else '{}'::jsonb end)) as row
    from questions q
    left join assessment_parts ap on ap.id = q.part_id
    where q.assessment_id = p_assessment) x;

  return jsonb_build_object('parts', v_parts, 'questions', v_questions);
end $$;

-- Teacher-only: functions default to PUBLIC execute — revoke, then grant
-- authenticated. Anon can never reach it.
revoke execute on function preview_questions(uuid) from public, anon;
grant execute on function preview_questions(uuid) to authenticated;

-- ---------- 2) publish guard ----------
-- Fires only on the is_published false -> true transition with zero
-- questions. Renames, release toggles, unpublish, and score release pass.
create or replace function guard_assessment_publish() returns trigger
language plpgsql set search_path = public as $$
begin
  if new.is_published and not old.is_published
     and not exists (select 1 from questions q
                     where q.assessment_id = new.id) then
    raise exception 'Add questions to publish';
  end if;
  return new;
end $$;

drop trigger if exists assessment_publish_guard on assessments;
create trigger assessment_publish_guard
  before update on assessments
  for each row execute function guard_assessment_publish();

-- ---------- 3) delete guard ----------
-- Fires only when a row leaves `assessments`. assessments.lesson_id is
-- ON DELETE RESTRICT (0015) — deleting a lesson that still owns activities,
-- or a class whose cascade reaches such a lesson, is rejected by the FK
-- itself before any assessment row is touched. The guard therefore only
-- trips on a direct `delete from assessments`.
create or replace function guard_assessment_delete() returns trigger
language plpgsql set search_path = public as $$
begin
  if exists (select 1 from attempts t where t.assessment_id = old.id) then
    raise exception 'Students already took this. Unpublish it instead.';
  end if;
  return old;
end $$;

drop trigger if exists assessment_delete_guard on assessments;
create trigger assessment_delete_guard
  before delete on assessments
  for each row execute function guard_assessment_delete();

-- ---------- 4) position repair ----------
-- Both updates inside one do block -> a single atomic unit (satisfies the
-- wrapped-in-a-transaction requirement regardless of how the file is
-- applied). "is distinct from" makes reruns no-ops, so it is idempotent.
do $$
begin
  -- assessment_parts: dense 0..n-1 per assessment, stable order by
  -- (position, id) so existing relative order survives and dup keys split.
  with ranked as (
    select id,
           row_number() over (partition by assessment_id
                              order by position, id) - 1 as pos
    from assessment_parts)
  update assessment_parts p
     set position = r.pos
  from ranked r
  where p.id = r.id
    and p.position is distinct from r.pos;

  -- questions: dense 0..n-1 per (assessment, part). NULL part_id partitions
  -- together, so ungrouped items get their own dense range.
  with ranked as (
    select id,
           row_number() over (partition by assessment_id, part_id
                              order by position, id) - 1 as pos
    from questions)
  update questions q
     set position = r.pos
  from ranked r
  where q.id = r.id
    and q.position is distinct from r.pos;
end $$;
