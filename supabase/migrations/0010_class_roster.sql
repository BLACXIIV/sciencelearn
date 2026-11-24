-- Picker cards show "N students" to everyone in the class. The existing
-- "enroll read" policy only exposes a student's OWN row, so active members
-- also get read access to their class's roster. is_member() is security
-- definer (0007), so this can't be bypassed for foreign classes.
create policy "enroll read members" on enrollments for select
  using (is_member(class_id));
