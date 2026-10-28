-- M8b: the prize a child's companion wears (an id of the app and nothing else), the alert that tells a parent a trophy with a
-- promise was earned, and room in the family's settings for the parents' promises (at most 30, 60 characters each).
alter table app.child_profile
  add column outfit_id text check (outfit_id is null or outfit_id ~ '^[a-z0-9-]{2,20}$');

do $$
declare c text;
begin
  for c in
    select conname from pg_constraint
     where conrelid = 'app.alert'::regclass and contype = 'c' and pg_get_constraintdef(oid) like '%pastLimit%'
  loop
    execute format('alter table app.alert drop constraint %I', c);
  end loop;
  for c in
    select conname from pg_constraint
     where conrelid = 'app.family_settings'::regclass and contype = 'c' and pg_get_constraintdef(oid) like '%pg_column_size%'
  loop
    execute format('alter table app.family_settings drop constraint %I', c);
  end loop;
end $$;

alter table app.alert add constraint alert_category_check check (
  category in ('pastLimit', 'restHours', 'gateAttempts', 'guessing', 'frustration', 'inappropriateWords',
               'disclosure', 'absence', 'ribbonEarned')
);
alter table app.family_settings add constraint family_settings_rules_check check (
  jsonb_typeof(rules) = 'object' and pg_column_size(rules) <= 8192
);
