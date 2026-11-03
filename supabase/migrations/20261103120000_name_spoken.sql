-- B-42: how a child's name is said (docs/milestones/B42.md section 3.2), additive only. The parent writes the spelling the
-- voice should read (with nikud where the name needs it) next to the nickname; `child-put` saves it, and `name-voice`
-- reads it here, on the server, to make the child's own name clip. A device never sends a name to the voice.
--
-- The check is the narrow rule of supabase/functions/_shared/name_spoken.ts and testvectors/name-spoken.json: Hebrew letters
-- (U+05D0 to U+05EA), their nikud (U+05B0 to U+05BC, the shin and sin dots U+05C1 and U+05C2; never hataf qamats U+05B3 or
-- qamats qatan U+05C7, which the voice is never sent), a space, a hyphen (ASCII or maqaf U+05BE) and a geresh (ASCII
-- apostrophe or U+05F3), 1 to 24 characters; a mark only on a letter and at most three in a row; no leading, trailing or
-- double space; at least one letter. Existing rows have no spelling (null). Deleting a child deletes the row, and the
-- spelling with it (app.delete_child).
--
-- Deploy order: this migration, then the functions (child-put, sync-pull, name-voice), then the app.
alter table app.child_profile
  add column name_spoken text;

alter table app.child_profile
  add constraint child_profile_name_spoken_check check (
    name_spoken is null or (
      char_length(name_spoken) between 1 and 24
      and name_spoken ~ '^([\u05D0-\u05EA][\u05B0-\u05B2\u05B4-\u05BC\u05C1\u05C2]{0,3}|[ ''\u05BE\u05F3-])+$'
      and name_spoken ~ '[\u05D0-\u05EA]'
      and name_spoken !~ '^ '
      and name_spoken !~ ' $'
      and name_spoken !~ '  '
    )
  );
