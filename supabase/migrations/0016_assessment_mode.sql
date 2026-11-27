-- Quiz mode chosen when creating an activity; presets the question editor's
-- type. `kind` stays required for progress reporting — new activities all use
-- 'topic_quiz' so their scores still count toward the quizzes average.
alter table assessments add column mode text not null default 'multiple_choice';
