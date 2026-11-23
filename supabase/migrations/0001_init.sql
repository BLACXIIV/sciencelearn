create extension if not exists pgcrypto;

create type user_role as enum ('student','teacher','admin');
create type assessment_kind as enum
  ('pre_test','post_test','topic_quiz','problem_solving','final_challenge','practice');

create table profiles (
  id uuid primary key references auth.users on delete cascade,
  full_name text not null default '',
  role user_role not null default 'student',
  avatar_url text,
  created_at timestamptz not null default now()
);

create table classes (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  teacher_id uuid not null references profiles(id),
  created_at timestamptz not null default now()
);
create table enrollments (
  class_id uuid references classes(id) on delete cascade,
  student_id uuid references profiles(id) on delete cascade,
  primary key (class_id, student_id)
);

create table lessons (
  id uuid primary key default gen_random_uuid(),
  subject text not null check (subject in ('Physics','Chemistry','Earth Science')),
  title text not null,
  objectives text not null default '',
  content_md text not null default '',
  thumbnail_key text,            -- Cloudflare R2 object key
  content_key text,              -- R2 key (pdf / video)
  position int not null default 0,
  is_published boolean not null default false,
  created_by uuid references profiles(id),
  created_at timestamptz not null default now()
);

create table lesson_progress (
  student_id uuid references profiles(id) on delete cascade,
  lesson_id uuid references lessons(id) on delete cascade,
  percent int not null default 0 check (percent between 0 and 100),
  completed_at timestamptz,
  updated_at timestamptz not null default now(),
  primary key (student_id, lesson_id)
);

create table assessments (
  id uuid primary key default gen_random_uuid(),
  lesson_id uuid references lessons(id) on delete set null,
  kind assessment_kind not null,
  title text not null,
  description text not null default '',
  time_limit_sec int,
  is_published boolean not null default false,
  created_at timestamptz not null default now()
);

create table questions (
  id uuid primary key default gen_random_uuid(),
  assessment_id uuid not null references assessments(id) on delete cascade,
  prompt text not null,
  choices jsonb not null,               -- ["A","B","C","D"]
  correct_index int not null,
  explanation text not null default '',
  position int not null default 0
);

create table attempts (
  id uuid primary key default gen_random_uuid(),
  assessment_id uuid not null references assessments(id) on delete cascade,
  student_id uuid not null references profiles(id) on delete cascade,
  score numeric(5,2),                   -- percent 0-100
  total int,
  started_at timestamptz not null default now(),
  submitted_at timestamptz
);
create table attempt_answers (
  attempt_id uuid references attempts(id) on delete cascade,
  question_id uuid references questions(id) on delete cascade,
  chosen_index int,
  is_correct boolean,
  primary key (attempt_id, question_id)
);

create table flashcards (id uuid primary key default gen_random_uuid(),
  lesson_id uuid references lessons(id) on delete cascade, front text not null, back text not null);
create table formulas (id uuid primary key default gen_random_uuid(),
  lesson_id uuid references lessons(id) on delete cascade, title text not null, expression text not null, notes text);
create table key_terms (id uuid primary key default gen_random_uuid(),
  lesson_id uuid references lessons(id) on delete cascade, term text not null, definition text not null);

-- ---------- helpers ----------
create or replace function is_teacher() returns boolean
language sql security definer stable set search_path = public as $$
  select exists (select 1 from profiles where id = auth.uid() and role in ('teacher','admin'));
$$;

create or replace function handle_new_user() returns trigger
language plpgsql security definer set search_path = public as $$
begin
  insert into profiles (id, full_name)
  values (new.id, coalesce(new.raw_user_meta_data->>'full_name', split_part(new.email,'@',1)));
  return new;
end $$;
create trigger on_auth_user_created after insert on auth.users
  for each row execute function handle_new_user();

-- Students never see answer keys: read questions_public, submit via submit_attempt()
create view questions_public with (security_invoker = false) as
  select q.id, q.assessment_id, q.prompt, q.choices, q.position
  from questions q join assessments a on a.id = q.assessment_id
  where a.is_published;
grant select on questions_public to authenticated;

create or replace function submit_attempt(p_assessment uuid, p_answers jsonb)
returns jsonb language plpgsql security definer set search_path = public as $$
declare v_attempt uuid; v_total int; v_correct int; v_score numeric;
begin
  insert into attempts (assessment_id, student_id) values (p_assessment, auth.uid())
    returning id into v_attempt;

  insert into attempt_answers (attempt_id, question_id, chosen_index, is_correct)
  select v_attempt, q.id, (e.value)::int, (e.value)::int = q.correct_index
  from questions q
  left join jsonb_each_text(p_answers) e on e.key = q.id::text
  where q.assessment_id = p_assessment;

  select count(*), count(*) filter (where is_correct) into v_total, v_correct
  from attempt_answers where attempt_id = v_attempt;

  v_score := case when v_total = 0 then 0 else round(v_correct * 100.0 / v_total, 2) end;
  update attempts set score = v_score, total = v_total, submitted_at = now() where id = v_attempt;

  return jsonb_build_object('attempt_id', v_attempt, 'score', v_score,
                            'correct', v_correct, 'total', v_total);
end $$;

-- per-student summary used by both apps
create view v_student_progress with (security_invoker = true) as
select p.id as student_id, p.full_name,
  coalesce((select round(avg(percent)) from lesson_progress lp where lp.student_id = p.id), 0) as lessons_pct,
  (select round(avg(a.score)) from attempts a join assessments s on s.id = a.assessment_id
    where a.student_id = p.id and a.submitted_at is not null
      and s.kind in ('topic_quiz','problem_solving','final_challenge')) as quizzes_pct,
  (select a.score from attempts a join assessments s on s.id = a.assessment_id
    where a.student_id = p.id and s.kind = 'pre_test' and a.submitted_at is not null
    order by a.submitted_at desc limit 1) as pre_score,
  (select a.score from attempts a join assessments s on s.id = a.assessment_id
    where a.student_id = p.id and s.kind = 'post_test' and a.submitted_at is not null
    order by a.submitted_at desc limit 1) as post_score
from profiles p where p.role = 'student';

-- ---------- RLS ----------
alter table profiles enable row level security;
alter table classes enable row level security;
alter table enrollments enable row level security;
alter table lessons enable row level security;
alter table lesson_progress enable row level security;
alter table assessments enable row level security;
alter table questions enable row level security;
alter table attempts enable row level security;
alter table attempt_answers enable row level security;
alter table flashcards enable row level security;
alter table formulas enable row level security;
alter table key_terms enable row level security;

create policy "profiles read" on profiles for select using (id = auth.uid() or is_teacher());
create policy "profiles update own" on profiles for update using (id = auth.uid())
  with check (id = auth.uid() and role = (select role from profiles where id = auth.uid()));

create policy "classes teacher" on classes for all using (is_teacher()) with check (is_teacher());
create policy "enroll read" on enrollments for select using (student_id = auth.uid() or is_teacher());
create policy "enroll teacher" on enrollments for all using (is_teacher()) with check (is_teacher());

create policy "lessons read" on lessons for select using (is_published or is_teacher());
create policy "lessons write" on lessons for all using (is_teacher()) with check (is_teacher());

create policy "progress own" on lesson_progress for all
  using (student_id = auth.uid()) with check (student_id = auth.uid());
create policy "progress teacher read" on lesson_progress for select using (is_teacher());

create policy "assessments read" on assessments for select using (is_published or is_teacher());
create policy "assessments write" on assessments for all using (is_teacher()) with check (is_teacher());
create policy "questions teacher only" on questions for all using (is_teacher()) with check (is_teacher());

create policy "attempts own read" on attempts for select using (student_id = auth.uid() or is_teacher());
create policy "answers own read" on attempt_answers for select
  using (exists (select 1 from attempts a where a.id = attempt_id and (a.student_id = auth.uid() or is_teacher())));

create policy "flashcards read" on flashcards for select using (true);
create policy "flashcards write" on flashcards for all using (is_teacher()) with check (is_teacher());
create policy "formulas read" on formulas for select using (true);
create policy "formulas write" on formulas for all using (is_teacher()) with check (is_teacher());
create policy "terms read" on key_terms for select using (true);
create policy "terms write" on key_terms for all using (is_teacher()) with check (is_teacher());
