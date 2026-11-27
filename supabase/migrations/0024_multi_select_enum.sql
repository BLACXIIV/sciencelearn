-- Add the multi_select question type to the enum. Kept in its own
-- migration: Postgres won't let a new enum label be referenced in the
-- same transaction that creates it, so the view/function changes that
-- mention 'multi_select' live in 0025.
alter type question_type add value 'multi_select';
