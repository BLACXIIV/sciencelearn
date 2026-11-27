-- Enum labels can't be referenced in the transaction that creates them —
-- the ordering view/grading logic follows in 0031.
alter type question_type add value 'ordering';
