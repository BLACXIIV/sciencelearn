-- 0032_builder_test.sql — dev-database verification for migration 0032.
-- Run AFTER 0001-0032 are applied:  psql <dev-url> -f 0032_builder_test.sql
-- Aborts on the first failure (raise exception inside do blocks); prints
-- PASS markers as it goes. Cleans up all seed rows at the end.
--
-- Impersonation: auth.uid() reads request.jwt.claims -> 'sub', so setting
-- the claims string switches the effective user for RLS/RPC gates.

\set QUIET on
\echo '== 0032 builder test =='

-- ---------- seed ----------
begin;

-- Two users: teacher (owns the class) + student (enrolled member).
-- handle_new_user (0002) auto-creates profiles from raw_user_meta_data.
insert into auth.users (id, instance_id, aud, role, email, encrypted_password,
                        email_confirmed_at, created_at, updated_at,
                        raw_app_meta_data, raw_user_meta_data)
values
  ('11111111-1111-1111-1111-111111111111',
   '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated',
   't-dev@test.dev', '', now(), now(), now(), '{}',
   '{"full_name":"Dev Teacher","role":"teacher"}'),
  ('22222222-2222-2222-2222-222222222222',
   '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated',
   's-dev@test.dev', '', now(), now(), now(), '{}',
   '{"full_name":"Dev Student","role":"student"}');

insert into classes (id, name, code, teacher_id) values
  ('aaaaaaaa-0000-0000-0000-000000000001', 'Dev Class', 'DEVTST',
   '11111111-1111-1111-1111-111111111111');

insert into lessons (id, class_id, title, subject, objectives, position,
                     is_published) values
  ('bbbbbbbb-0000-0000-0000-000000000001',
   'aaaaaaaa-0000-0000-0000-000000000001',
   'Dev Lesson', 'Physics', '', 0, true);

insert into enrollments (class_id, student_id, status) values
  ('aaaaaaaa-0000-0000-0000-000000000001',
   '22222222-2222-2222-2222-222222222222', 'active');

-- The activity under test.
insert into assessments (id, lesson_id, kind, title, description,
                         is_published) values
  ('cccccccc-0000-0000-0000-000000000001',
   'bbbbbbbb-0000-0000-0000-000000000001',
   'topic_quiz', 'Dev Quiz', 'dev quiz', false);

-- Parts with COLLIDING positions (all 0) — the repair must dedupe.
insert into assessment_parts (id, assessment_id, title, mode, position)
values
  ('dddddddd-0000-0000-0000-000000000001',
   'cccccccc-0000-0000-0000-000000000001', 'P2', 'multiple_choice', 0),
  ('dddddddd-0000-0000-0000-000000000002',
   'cccccccc-0000-0000-0000-000000000001', 'P1', 'true_false', 0);

-- One question per qtype in part 1, positions colliding at 0 (the old bug).
insert into questions (id, assessment_id, part_id, qtype, prompt, choices,
                       correct_index, answer, position) values
  ('eeeeeeee-0000-0000-0000-000000000001',
   'cccccccc-0000-0000-0000-000000000001',
   'dddddddd-0000-0000-0000-000000000001',
   'multiple_choice', 'mc q', '["a","b"]', 1, null, 0),
  ('eeeeeeee-0000-0000-0000-000000000002',
   'cccccccc-0000-0000-0000-000000000001',
   'dddddddd-0000-0000-0000-000000000001',
   'true_false', 'tf q', '[]', null, '{"correct":true}', 0),
  ('eeeeeeee-0000-0000-0000-000000000003',
   'cccccccc-0000-0000-0000-000000000001',
   'dddddddd-0000-0000-0000-000000000001',
   'fill_blank', 'fb [blank] q', '["x","y"]', 0, null, 0),
  ('eeeeeeee-0000-0000-0000-000000000004',
   'cccccccc-0000-0000-0000-000000000001',
   'dddddddd-0000-0000-0000-000000000001',
   'identification', 'id q', '[]', null, '{"accepted":["ans"]}', 0),
  ('eeeeeeee-0000-0000-0000-000000000005',
   'cccccccc-0000-0000-0000-000000000001',
   'dddddddd-0000-0000-0000-000000000001',
   'enumeration', 'enum q', '[]', null,
   '{"items":["e1","e2"],"ordered":false,"partial":true}', 0),
  ('eeeeeeee-0000-0000-0000-000000000006',
   'cccccccc-0000-0000-0000-000000000001',
   'dddddddd-0000-0000-0000-000000000001',
   'multi_select', 'ms q', '["a","b","c"]', null,
   '{"indexes":[0,2],"min":1,"max":2,"partial":true}', 0),
  ('eeeeeeee-0000-0000-0000-000000000007',
   'cccccccc-0000-0000-0000-000000000001',
   'dddddddd-0000-0000-0000-000000000001',
   'classification', 'cls q', '["i1","i2"]', null,
   '{"buckets":["z1","z2"],"zones":[0,1],"context":"A: eq"}', 0),
  ('eeeeeeee-0000-0000-0000-000000000008',
   'cccccccc-0000-0000-0000-000000000001',
   'dddddddd-0000-0000-0000-000000000001',
   'ordering', 'ord q', '["s1","s2"]', null,
   '{"correct":[0,1],"shuffle":true}', 0),
  -- part 2 + one ungrouped item for the ordering checks
  ('eeeeeeee-0000-0000-0000-000000000009',
   'cccccccc-0000-0000-0000-000000000001',
   'dddddddd-0000-0000-0000-000000000002',
   'true_false', 'p2 q', '[]', null, '{"correct":false}', 0),
  ('eeeeeeee-0000-0000-0000-00000000000a',
   'cccccccc-0000-0000-0000-000000000001',
   null, 'multiple_choice', 'ungrouped', '["a","b"]', 0, null, 0);

-- A second empty assessment for the publish/delete guards.
insert into assessments (id, lesson_id, kind, title) values
  ('cccccccc-0000-0000-0000-000000000002',
   'bbbbbbbb-0000-0000-0000-000000000001',
   'topic_quiz', 'Empty Quiz');

-- Student attempt on the main assessment (drives the delete guard).
insert into attempts (id, assessment_id, student_id, score, total,
                      submitted_at) values
  ('ffffffff-0000-0000-0000-000000000001',
   'cccccccc-0000-0000-0000-000000000001',
   '22222222-2222-2222-2222-222222222222', 80, 10, now());

commit;

-- ---------- T1: position repair ----------
-- Re-run the repair statements verbatim (migration already applied them —
-- this run proves idempotency on the seeded collisions).
\echo 'T1 position repair + idempotent rerun'
begin;
do $$
declare n int;
begin
  with ranked as (
    select id, row_number() over (partition by assessment_id
                                order by position, id) - 1 as pos
    from assessment_parts)
  update assessment_parts p set position = r.pos
  from ranked r where p.id = r.id and p.position is distinct from r.pos;
  get diagnostics n = row_count;
  raise notice 'first run: parts changed = %', n;
  with ranked as (
    select id, row_number() over (partition by assessment_id, part_id
                                order by position, id) - 1 as pos
    from questions)
  update questions q set position = r.pos
  from ranked r where q.id = r.id and q.position is distinct from r.pos;
  get diagnostics n = row_count;
  raise notice 'first run: questions changed = %', n;
end $$;
commit;

do $$
declare
  bad int;
begin
  select count(*) into bad from (
    select assessment_id, position, count(*)
    from assessment_parts
    where assessment_id = 'cccccccc-0000-0000-0000-000000000001'
    group by assessment_id, position having count(*) > 1) d;
  if bad > 0 then raise exception 'FAIL: part positions still collide'; end if;
  if (select count(*) from assessment_parts
      where assessment_id = 'cccccccc-0000-0000-0000-000000000001'
        and position in (0,1)) <> 2 then
    raise exception 'FAIL: parts not dense 0..n-1';
  end if;
  select count(*) into bad from (
    select assessment_id, part_id, position, count(*)
    from questions
    where assessment_id = 'cccccccc-0000-0000-0000-000000000001'
    group by assessment_id, part_id, position having count(*) > 1) d;
  if bad > 0 then raise exception 'FAIL: question positions still collide'; end if;
  raise notice 'PASS T1a: positions dense and unique';
end $$;

-- Idempotency: same statements again must change nothing.
do $$
declare n int;
begin
  with ranked as (
    select id, row_number() over (partition by assessment_id
                                order by position, id) - 1 as pos
    from assessment_parts)
  update assessment_parts p set position = r.pos
  from ranked r where p.id = r.id and p.position is distinct from r.pos;
  get diagnostics n = row_count;
  raise notice 'second run: parts changed = %', n;
  if n <> 0 then raise exception 'FAIL: parts repair not idempotent'; end if;
  with ranked as (
    select id, row_number() over (partition by assessment_id, part_id
                                order by position, id) - 1 as pos
    from questions)
  update questions q set position = r.pos
  from ranked r where q.id = r.id and q.position is distinct from r.pos;
  get diagnostics n = row_count;
  raise notice 'second run: questions changed = %', n;
  if n <> 0 then raise exception 'FAIL: questions repair not idempotent'; end if;
  raise notice 'PASS T1b: repair is idempotent';
end $$;

-- ---------- T2: preview_questions — teacher gets student-view payload ----------
\echo 'T2 preview_questions payload'
set "request.jwt.claims" =
  '{"sub":"11111111-1111-1111-1111-111111111111","role":"authenticated"}';

do $$
declare
  v jsonb;
  keys text[];
  allowed text[] := array['id','assessment_id','part_id','qtype','prompt',
                          'position','choices','meta'];
  leak text[] := array['answer','correct_index','indexes','accepted','zones',
                       'correct','items','min','max','buckets','shuffle',
                       'context','ordered','partial'];
  leaked text;
  part_keys text[];
  pallowed text[] := array['id','assessment_id','title','directions','mode',
                           'scored','points','position'];
begin
  v := preview_questions('cccccccc-0000-0000-0000-000000000001');
  if v ? 'error' then raise exception 'FAIL: teacher denied: %', v; end if;

  -- Question rows: exactly the questions_public key set.
  select array_agg(distinct k) into keys
  from jsonb_array_elements(v->'questions') e,
       lateral jsonb_object_keys(e) k;
  if exists (select 1 from unnest(keys) k where not (k = any(allowed))) then
    raise exception 'FAIL: unexpected keys %', keys;
  end if;
  if not (keys @> allowed and allowed @> keys) then
    raise exception 'FAIL: key set mismatch %', keys;
  end if;

  -- No answer-key material anywhere in the question rows.
  select string_agg(distinct k, ',') into leaked
  from jsonb_array_elements(v->'questions') e,
       lateral jsonb_object_keys(e) k
  where k = any(leak);
  if leaked is not null then
    raise exception 'FAIL: answer keys leaked via %', leaked;
  end if;
  -- meta may only carry the public keys {n,min,max,buckets,shuffle,context}.
  select string_agg(distinct mk, ',') into leaked
  from jsonb_array_elements(v->'questions') e,
       lateral jsonb_object_keys(e->'meta') mk
  where not (mk = any(array['n','min','max','buckets','shuffle','context']));
  if leaked is not null then
    raise exception 'FAIL: meta leaked via %', leaked;
  end if;

  -- Parts carry the student-view fields (+points).
  select array_agg(distinct k) into part_keys
  from jsonb_array_elements(v->'parts') e,
       lateral jsonb_object_keys(e) k;
  if not (part_keys @> pallowed and pallowed @> part_keys) then
    raise exception 'FAIL: part keys mismatch %', part_keys;
  end if;
  raise notice 'PASS T2a: payload shape + no answer keys';
end $$;

-- Ordering: actual id sequence must equal (part.position, q.position),
-- ungrouped last.
do $$
declare
  got uuid[]; want uuid[];
begin
  select array_agg((e->>'id')::uuid order by o.i) into got
  from jsonb_array_elements(
         preview_questions('cccccccc-0000-0000-0000-000000000001')
           ->'questions') with ordinality as o(e,i);

  select array_agg(q.id order by coalesce(p.position, 2147483647),
                                q.position, q.id) into want
  from questions q left join assessment_parts p on p.id = q.part_id
  where q.assessment_id = 'cccccccc-0000-0000-0000-000000000001';

  if coalesce(array_length(got, 1), 0) <> 10 then
    raise exception 'FAIL: expected 10 questions, got %', got;
  end if;
  if got is distinct from want then
    raise exception 'FAIL: order mismatch%got=% want=%', chr(10), got, want;
  end if;
  raise notice 'PASS T2b: part-then-question ordering, ungrouped last';
end $$;

-- Publish the activity (10 questions -> guard passes) so the student can
-- read questions_public for a REAL shape-parity comparison below.
update assessments set is_published = true
where id = 'cccccccc-0000-0000-0000-000000000001';

-- Shape parity vs questions_public (as the STUDENT): same row keys.
set "request.jwt.claims" =
  '{"sub":"22222222-2222-2222-2222-222222222222","role":"authenticated"}';
do $$
declare
  pub_keys text[]; prev_keys text[];
begin
  select array_agg(distinct k) into pub_keys
  from questions_public q, lateral jsonb_object_keys(to_jsonb(q)) k
  where q.assessment_id = 'cccccccc-0000-0000-0000-000000000001';
  select array_agg(distinct k) into prev_keys
  from jsonb_array_elements(
         preview_questions('cccccccc-0000-0000-0000-000000000001')
           ->'questions') e,
       lateral jsonb_object_keys(e) k;
  if pub_keys is null then
    raise exception 'FAIL: student got no questions_public rows';
  end if;
  if not (pub_keys @> prev_keys and prev_keys @> pub_keys) then
    raise exception 'FAIL: preview shape != questions_public: pub=% prev=%',
                    pub_keys, prev_keys;
  end if;
  raise notice 'PASS T2c: preview rows match questions_public shape';
end $$;

-- Denied for a student.
do $$
declare v jsonb;
begin
  v := preview_questions('cccccccc-0000-0000-0000-000000000001');
  if not (v ? 'error') then
    raise exception 'FAIL: student was allowed preview';
  end if;
  raise notice 'PASS T2d: student denied';
end $$;

-- Grant check: anon and public must have NO execute; authenticated must.
-- (Direct privilege assertion — stronger than relying on SET ROLE through
-- a pooler session.)
do $$
begin
  if has_function_privilege('anon', 'preview_questions(uuid)', 'execute')
     or has_function_privilege('public', 'preview_questions(uuid)', 'execute') then
    raise exception 'FAIL: anon/public can execute preview_questions';
  end if;
  if not has_function_privilege('authenticated', 'preview_questions(uuid)', 'execute') then
    raise exception 'FAIL: authenticated cannot execute preview_questions';
  end if;
  raise notice 'PASS T2e: execute granted only to authenticated';
end $$;
reset "request.jwt.claims";

-- ---------- T3: publish guard ----------
\echo 'T3 publish guard'
set "request.jwt.claims" =
  '{"sub":"11111111-1111-1111-1111-111111111111","role":"authenticated"}';

do $$
declare caught boolean := false;
begin
  begin
    update assessments set is_published = true
    where id = 'cccccccc-0000-0000-0000-000000000002';
  exception when others then
    caught := true;
    if sqlerrm <> 'Add questions to publish' then
      raise exception 'FAIL: wrong publish-guard message: %', sqlerrm;
    end if;
  end;
  if not caught then
    raise exception 'FAIL: empty activity published';
  end if;
  raise notice 'PASS T3a: publish blocked at 0 questions';
end $$;

-- Other updates pass through; publish succeeds once a question exists.
insert into questions (id, assessment_id, part_id, qtype, prompt, choices,
                       correct_index, position) values
  ('eeeeeeee-0000-0000-0000-0000000000ff',
   'cccccccc-0000-0000-0000-000000000002', null,
   'multiple_choice', 'q', '["a","b"]', 0, 0);
update assessments set is_published = true
where id = 'cccccccc-0000-0000-0000-000000000002';
update assessments set title = 'Renamed', description = 'd',
       release_scores = 'manual'
where id = 'cccccccc-0000-0000-0000-000000000002';
update assessments set is_published = false
where id = 'cccccccc-0000-0000-0000-000000000002';
\echo 'PASS T3b: publish ok with questions; rename/release/unpublish pass'

-- ---------- T4: delete guard ----------
\echo 'T4 delete guard'

-- With attempts -> blocked with the exact message.
do $$
declare caught boolean := false;
begin
  begin
    delete from assessments
    where id = 'cccccccc-0000-0000-0000-000000000001';
  exception when others then
    caught := true;
    if sqlerrm <> 'Students already took this. Unpublish it instead.' then
      raise exception 'FAIL: wrong delete-guard message: %', sqlerrm;
    end if;
  end;
  if not caught then
    raise exception 'FAIL: activity with attempts was deleted';
  end if;
  if not exists (select 1 from assessments
                 where id = 'cccccccc-0000-0000-0000-000000000001') then
    raise exception 'FAIL: guarded row disappeared anyway';
  end if;
  raise notice 'PASS T4a: delete blocked with attempts';
end $$;

-- Without attempts -> allowed.
delete from assessments where id = 'cccccccc-0000-0000-0000-000000000002';
do $$
begin
  if exists (select 1 from assessments
             where id = 'cccccccc-0000-0000-0000-000000000002') then
    raise exception 'FAIL: empty activity not deleted';
  end if;
  raise notice 'PASS T4b: delete allowed without attempts';
end $$;

-- Delete a LESSON that still owns an activity -> FK ON DELETE RESTRICT
-- (0015) rejects it BEFORE any assessment row is deleted, so the new guard
-- never fires. Expected: 23503, and everything survives.
insert into lessons (id, class_id, title, subject, position, is_published)
values ('bbbbbbbb-0000-0000-0000-000000000002',
        'aaaaaaaa-0000-0000-0000-000000000001',
        'Temp Lesson', 'Physics', 9, true);
insert into assessments (id, lesson_id, kind, title) values
  ('cccccccc-0000-0000-0000-000000000003',
   'bbbbbbbb-0000-0000-0000-000000000002', 'topic_quiz', 'Blocked-owner');
do $$
declare caught boolean := false;
begin
  begin
    delete from lessons where id = 'bbbbbbbb-0000-0000-0000-000000000002';
  exception
    when foreign_key_violation then caught := true;
  end;
  if not caught then
    raise exception 'FAIL: lesson delete was not restricted';
  end if;
  if not exists (select 1 from assessments
                 where id = 'cccccccc-0000-0000-0000-000000000003'
                   and lesson_id = 'bbbbbbbb-0000-0000-0000-000000000002') then
    raise exception 'FAIL: restricted lesson delete touched the activity';
  end if;
  raise notice 'PASS T4c: lesson delete FK-restricted; activity untouched';
end $$;

-- A lesson with NO activities deletes normally.
insert into lessons (id, class_id, title, subject, position, is_published)
values ('bbbbbbbb-0000-0000-0000-000000000004',
        'aaaaaaaa-0000-0000-0000-000000000001',
        'Empty Lesson', 'Physics', 10, true);
delete from lessons where id = 'bbbbbbbb-0000-0000-0000-000000000004';
do $$
begin
  if exists (select 1 from lessons
             where id = 'bbbbbbbb-0000-0000-0000-000000000004') then
    raise exception 'FAIL: empty lesson not deleted';
  end if;
  raise notice 'PASS T4c2: empty lesson deletes normally';
end $$;

-- Delete the CLASS while its lesson still owns an activity -> the lessons
-- cascade hits the same RESTRICT; class + lesson + activity + attempts
-- all survive. The guard does not change this either way.
do $$
declare caught boolean := false;
begin
  begin
    delete from classes where id = 'aaaaaaaa-0000-0000-0000-000000000001';
  exception
    when foreign_key_violation then caught := true;
  end;
  if not caught then
    raise exception 'FAIL: class delete was not restricted';
  end if;
  if not exists (select 1 from classes
                 where id = 'aaaaaaaa-0000-0000-0000-000000000001')
     or not exists (select 1 from attempts
                    where id = 'ffffffff-0000-0000-0000-000000000001')
     or not exists (select 1 from assessments
                    where id = 'cccccccc-0000-0000-0000-000000000001'
                      and lesson_id = 'bbbbbbbb-0000-0000-0000-000000000001') then
    raise exception 'FAIL: restricted class delete lost data';
  end if;
  raise notice 'PASS T4d: class delete FK-restricted; all rows intact';
end $$;

-- A class whose lessons have no activities still cascades cleanly.
insert into classes (id, name, code, teacher_id) values
  ('aaaaaaaa-0000-0000-0000-000000000002', 'Temp Class', 'TMPCLS',
   '11111111-1111-1111-1111-111111111111');
insert into lessons (id, class_id, title, subject, position, is_published)
values ('bbbbbbbb-0000-0000-0000-000000000003',
        'aaaaaaaa-0000-0000-0000-000000000002',
        'NoActivity', 'Physics', 8, false);
delete from classes where id = 'aaaaaaaa-0000-0000-0000-000000000002';
do $$
begin
  if exists (select 1 from classes
             where id = 'aaaaaaaa-0000-0000-0000-000000000002')
     or exists (select 1 from lessons
                where id = 'bbbbbbbb-0000-0000-0000-000000000003') then
    raise exception 'FAIL: empty class did not cascade cleanly';
  end if;
  raise notice 'PASS T4e: class with no activities cascades clean';
end $$;

\echo '== all 0032 tests passed =='

-- ---------- cleanup ----------
-- attempts first (releases the delete guard), then activities ->
-- parts/questions cascade, lessons, classes (teacher_id has no cascade,
-- so classes must go before the users), then auth.users -> profiles ->
-- enrollments cascade.
delete from attempts
where id = 'ffffffff-0000-0000-0000-000000000001';
delete from assessments where id::text like 'cccccccc-%';
delete from lessons where id::text like 'bbbbbbbb-%';
delete from classes where id::text like 'aaaaaaaa-%';
delete from auth.users
where id in ('11111111-1111-1111-1111-111111111111',
             '22222222-2222-2222-2222-222222222222');
\echo 'seed rows removed'
