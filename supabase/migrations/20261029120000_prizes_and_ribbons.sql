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

-- Deleting a child also removes the parents' promises for that child from the family's settings (and counts the change as
-- a new version, so every phone takes it).
create or replace function app.delete_child(p_family uuid, p_child text) returns void
language plpgsql
security definer
set search_path = pg_catalog, app
as $$
begin
  delete from app.event where family_id = p_family and child_id = p_child;
  delete from app.alert where family_id = p_family and child_id = p_child;
  delete from app.tutor_log where family_id = p_family and child_ref = p_child;
  -- The tutor's daily count for this child (the key is the child's id).
  delete from app.usage_counter where scope = 'tutor_day' and key = left(p_child, 100);
  update app.family_settings
     set rules = jsonb_set(rules, '{ribbons}', (rules -> 'ribbons') - p_child),
         version = version + 1,
         updated_at = now()
   where family_id = p_family
     and jsonb_typeof(rules -> 'ribbons') = 'object'
     and jsonb_exists(rules -> 'ribbons', p_child);
  delete from app.child_profile where family_id = p_family and id = p_child;
  insert into app.deleted_child (family_id, child_id) values (p_family, p_child)
  on conflict (family_id, child_id) do nothing;
end
$$;
