-- B-29 (age fit), step 3: the school stage a parent confirms for a child (gan 3 to grade 3, never the school's name or year) is
-- the one new age value on the server, and the family's rules may carry a look letter for each child (inside `rules`, which
-- needs no change: it is a document the gateway checks). The month and year of birth are not here and never will be: they stay on
-- the device. Additive and backward compatible: a nullable column, and a function replaced with itself plus one statement.
alter table app.child_profile
  add column school_stage text
  check (school_stage is null or school_stage in ('gan3', 'gan4', 'gan5', 'grade1', 'grade2', 'grade3'));

-- Deleting a child takes that child's look letter out of the family's settings too, and counts the change as a new version, so
-- every phone takes it (as the ribbons and the language settings already do).
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
  update app.family_settings
     set rules = jsonb_set(rules, '{looks}', (rules -> 'looks') - p_child),
         version = version + 1,
         updated_at = now()
   where family_id = p_family
     and jsonb_typeof(rules -> 'looks') = 'object'
     and jsonb_exists(rules -> 'looks', p_child);
  delete from app.child_profile where family_id = p_family and id = p_child;
  insert into app.deleted_child (family_id, child_id) values (p_family, p_child)
  on conflict (family_id, child_id) do nothing;
end
$$;
