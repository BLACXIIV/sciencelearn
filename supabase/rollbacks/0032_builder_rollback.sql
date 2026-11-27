-- 0032_builder_rollback.sql — reverts migration 0032_builder.
-- Kept outside migrations/ so `supabase db push` never runs it; apply by
-- hand (psql / dashboard SQL editor) if 0032 must come back out.
--
-- The position reindex is a repair, not schema — it is intentionally NOT
-- reverted (dense positions are safe for old clients; they only read/order
-- by position).

-- Guards off first (they depend on the functions).
drop trigger if exists assessment_publish_guard on assessments;
drop trigger if exists assessment_delete_guard on assessments;
drop function if exists guard_assessment_publish();
drop function if exists guard_assessment_delete();

-- Preview RPC (grant goes with the function).
revoke execute on function preview_questions(uuid) from authenticated;
drop function if exists preview_questions(uuid);
