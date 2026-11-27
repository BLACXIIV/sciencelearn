-- question_type is a real enum: new labels can't be referenced in the same
-- transaction that adds them, so the label lands alone here and the
-- view/grading logic follows in 0028.
alter type question_type add value 'classification';
