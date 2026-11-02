import { assert } from "./testassert.ts";
import { respelled, settingsFor, styleOfLive, VOICE_PROFILE_ID, voiceSpecFor } from "./voice_profile.ts";
import { VOICE_PROFILE } from "./voice_profile_data.ts";
import { checkVoices, renderProfile, type VoicesJson } from "./voice_profile_gen.ts";

const voices: VoicesJson = JSON.parse(
  await Deno.readTextFile(new URL("../../../content/voices.json", import.meta.url)),
);

Deno.test("the checked-in profile is the one content/voices.json makes (run voice_profile_gen.ts when this fails)", async () => {
  const have = await Deno.readTextFile(new URL("./voice_profile_data.ts", import.meta.url));
  assert.equal(have.replaceAll("\r\n", "\n"), await renderProfile(voices));
});

Deno.test("the profile carries the pack's format, model, settings, styles, rules and respellings", () => {
  assert.equal(VOICE_PROFILE.outputFormat, "mp3_44100_64");
  assert.equal(VOICE_PROFILE.modelId, voices.modelId);
  assert.deepEqual(VOICE_PROFILE.settings, voices.settings);
  assert.deepEqual(VOICE_PROFILE.styles, voices.styles);
  assert.deepEqual(VOICE_PROFILE.styleRules, voices.styleRules);
  assert.deepEqual(VOICE_PROFILE.pronunciation, voices.pronunciation);
  assert.ok(VOICE_PROFILE_ID.startsWith("mp3_44100_64.eleven_v4_turbo."), VOICE_PROFILE_ID);
});

Deno.test("the profile id changes with anything that shapes the sound, and with nothing else", async () => {
  const base = await renderProfile(voices);
  const same = await renderProfile(
    { ...voices, voices: { other: 1 }, listPricePer1000Chars: {} } as VoicesJson,
  );
  assert.equal(same, base, "voice ids, prices and notes are not part of the sound");
  for (
    const changed of [
      { ...voices, settings: { ...voices.settings, stability: 0.51 } },
      { ...voices, styles: { ...voices.styles, ask: { stability: 0.61 } } },
      { ...voices, pronunciation: { ...voices.pronunciation, "א": "ב" } },
      { ...voices, outputFormat: "mp3_44100_128" },
      { ...voices, modelId: "eleven_v4" },
    ]
  ) assert.ok(await renderProfile(changed) !== base);
});

Deno.test("a live line is styled by its help level through the pack's own rules", () => {
  assert.equal(styleOfLive(0), "ask");
  assert.equal(styleOfLive(1), "hint");
  assert.equal(styleOfLive(2), "hint");
  assert.equal(styleOfLive(3), "hint3");
  // The same settings the pack would send for those styles: the usual ones with the style's stability on top.
  const all = (stability: number) => ({ similarity_boost: 0.8, stability, use_speaker_boost: true });
  assert.deepEqual(settingsFor(0), all(0.6));
  assert.deepEqual(settingsFor(1), all(0.65));
  assert.deepEqual(settingsFor(2), all(0.65));
  assert.deepEqual(settingsFor(3), all(0.7));
});

Deno.test("style and speed are never sent to a v4 model, and are kept for another", () => {
  const profile = { ...VOICE_PROFILE, settings: { ...VOICE_PROFILE.settings, style: 0.9, speed: 1 } };
  const v4 = settingsFor(0, "eleven_v4_turbo", profile);
  assert.ok(!("style" in v4) && !("speed" in v4));
  assert.equal(v4.stability, 0.6);
  assert.deepEqual([settingsFor(0, "eleven_v3", profile).style, settingsFor(0, "eleven_v3", profile).speed], [
    0.9,
    1,
  ]);
});

Deno.test("the number two is respelled the way the pack respells it", () => {
  assert.equal(respelled("שְׁתַּיִם", VOICE_PROFILE.pronunciation), "שתַּיִם");
  assert.equal(respelled("עוֹד שתיים", VOICE_PROFILE.pronunciation), "עוֹד שתַּיִם");
  assert.equal(
    respelled("בּוֹאוּ נִסְפֹּר", VOICE_PROFILE.pronunciation),
    "בּוֹאוּ נִסְפֹּר",
    "other words are left alone",
  );
  assert.equal(voiceSpecFor("שְׁתַּיִם פְּרָחִים", 3).text, "שתַּיִם פְּרָחִים");
});

Deno.test("a voice spec is the pack's format and model, with explicit settings", () => {
  const s = voiceSpecFor("שָׁלוֹם", 0);
  assert.deepEqual(
    [s.outputFormat, s.modelId, s.text],
    ["mp3_44100_64", VOICE_PROFILE.modelId, "שָׁלוֹם"],
  );
  assert.equal(typeof s.settings.stability, "number");
  assert.equal(typeof s.settings.similarity_boost, "number");
});

Deno.test("the generator refuses a voices file the pack tool would also refuse", () => {
  const bad = (over: Partial<VoicesJson>) => () => checkVoices({ ...voices, ...over });
  assert.throws(bad({ modelId: "gpt-voice" }));
  assert.throws(bad({ outputFormat: "mp3_22050_32" }));
  assert.throws(bad({ outputFormat: "mp3_44100_64&x=1" }));
  assert.throws(bad({ settings: { stability: 0.5 } }), "similarity is explicit");
  assert.throws(bad({ settings: { stability: 1.5, similarity_boost: 0.8 } }));
  assert.throws(bad({ styles: { ...voices.styles, odd: { volume: 1 } } }));
  assert.throws(bad({ styleRules: { nope: ["*.h3"] } }), "a rule names a style that exists");
  assert.throws(bad({ styleRules: { hint: ["*"] } }), "a bare * would match every line");
  checkVoices(voices);
});
