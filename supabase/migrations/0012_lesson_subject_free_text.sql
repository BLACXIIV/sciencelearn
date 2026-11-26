-- Custom subjects: teachers can add their own subject names (stored in the
-- app's local subject list), so lessons.subject can no longer be a closed set.
-- Existing rows keep their values; only the CHECK goes away.

alter table lessons drop constraint if exists lessons_subject_check;
