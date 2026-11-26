-- Per-teacher app settings blob. First key: settings.subjects — the custom
-- subject list, synced so a subject added on web exists on the phone too.
-- Future device-independent prefs join as more keys. "profiles update own"
-- already lets each user write their own row; "profiles read" covers reads.

alter table profiles
  add column if not exists settings jsonb not null default '{}';
