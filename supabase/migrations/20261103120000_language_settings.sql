-- L0 (the Languages category): the parents' language settings for each child (which languages are on and their switches) travel
-- inside the family's settings under the key `languages`, child id first, like the parents' promises (at most 6 children, a
-- few hundred characters each; the gateway checks the shape). With thirty promises of sixty letters beside them the document can
-- pass 8 KB, so the limit on its size is widened to 12 KB (the gateway takes 10,000 characters). Widening only: nothing that
-- fitted before is refused now.
do $$
declare c text;
begin
  for c in
    select conname from pg_constraint
     where conrelid = 'app.family_settings'::regclass and contype = 'c' and pg_get_constraintdef(oid) like '%pg_column_size%'
  loop
    execute format('alter table app.family_settings drop constraint %I', c);
  end loop;
end $$;
alter table app.family_settings add constraint family_settings_rules_check check (
  jsonb_typeof(rules) = 'object' and pg_column_size(rules) <= 12288
);

-- Deleting a child takes that child's language settings out of the family's settings too, and counts the change as a new
-- version, so every phone takes it. Additive: the function is replaced with itself plus one statement; nothing else changes.
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
  update app.family_settings
     set rules = jsonb_set(rules, '{languages}', (rules -> 'languages') - p_child),
         version = version + 1,
         updated_at = now()
   where family_id = p_family
     and jsonb_typeof(rules -> 'languages') = 'object'
     and jsonb_exists(rules -> 'languages', p_child);
  delete from app.child_profile where family_id = p_family and id = p_child;
  insert into app.deleted_child (family_id, child_id) values (p_family, p_child)
  on conflict (family_id, child_id) do nothing;
end
$$;
