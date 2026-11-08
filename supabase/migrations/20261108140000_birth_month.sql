-- B-29 (age fit), step 5a: a child's month and year of birth are kept on the family's own server beside the school stage, so a
-- new phone gets them back (owner's decision, 2026-11-08, replacing the device-only rule of 2026-11-06). Never the day.
-- They are never logged, sent to a vendor or exported; the age in months is computed on the device and is not stored here.
-- Additive and backward compatible: two nullable columns, no change to any function, no grant to `anon` or `authenticated`
-- (the `app` schema stays closed to them and row level security stays on; the gateway's role already has the table).
alter table app.child_profile
  add column birth_year smallint,
  add column birth_month smallint;

-- Both set or both empty, a real month, and a year in the range the app can hold (the device checks the real range).
alter table app.child_profile
  add constraint child_profile_birth_both check ((birth_year is null) = (birth_month is null)),
  add constraint child_profile_birth_month check (birth_month is null or birth_month between 1 and 12),
  add constraint child_profile_birth_year check (birth_year is null or birth_year between 2010 and 2100);
