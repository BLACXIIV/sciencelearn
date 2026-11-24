-- Students may read the profile rows of teachers whose classes they're
-- enrolled in — needed to show "Ms. Aquino" on the classroom picker and
-- class lists. "profiles read" (0001) only allowed self + staff before.

create policy "profiles teacher of enrolled class" on profiles
  for select using (
    exists (
      select 1
      from enrollments e
      join classes c on c.id = e.class_id
      where e.student_id = auth.uid()
        and c.teacher_id = profiles.id
    )
  );
