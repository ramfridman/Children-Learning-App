-- The live helper now speaks like the voice packs (44.1 kHz, 64 kbps, the pack's model and settings, the pack's
-- respellings). A cached clip is only served for the voice profile it was made with, so every older 22 kHz clip is
-- unreachable: `voice_profile` joins the cache key. Older rows get the profile `legacy`, which no request asks for
-- (they are not copied to a new pack version and the 90-day sweep removes them). The reviewed lines are made again by
-- the owner's prewarm.
alter table app.tutor_cache
  add column voice_profile text not null default 'legacy' check (char_length(voice_profile) between 1 and 80);

alter table app.tutor_cache drop constraint tutor_cache_pkey;
alter table app.tutor_cache add primary key (pack_id, pack_version, item_id, mistake, hint_level, band, address_form,
  character_id, prompt_version, validator_version, voice_profile);

-- 64 kbps is twice the bytes of 32 kbps: a longest line (20 words) may pass 64 KB, so the limit is 128 KB (16 seconds).
alter table app.tutor_cache drop constraint tutor_cache_audio_check;
alter table app.tutor_cache add constraint tutor_cache_audio_check check (octet_length(audio) <= 131072);
