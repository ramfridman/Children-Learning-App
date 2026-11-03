// B-42: the child's own name clip. A parent device asks with two ids; the spelling and the voice are read on the server; the
// four checks of every function run; a kill switch and a daily cap hold; nothing is stored or logged. Mocks only: the voice
// here is a fake, no key is read and nothing reaches a provider.
import { assert } from "./_shared/testassert.ts";
import { type VoiceAnswer, type VoiceClient, VoiceFailed, type VoiceRequest } from "./_shared/elevenlabs.ts";
import { makeHandler, type Services } from "./_shared/handler.ts";
import {
  NAME_VOICE_FORMAT,
  NAME_VOICE_SETTINGS,
  nameVoiceSettings,
  spellingHash,
} from "./_shared/name_voice.ts";
import {
  addDevice,
  call,
  fakeServices,
  FakeStore,
  FAMILY_A,
  FAMILY_B,
  NOW,
  USER_A,
  USER_B,
} from "./_shared/testkit.ts";
import { spec as childPut } from "./child-put/handler.ts";
import { spec as nameVoice } from "./name-voice/handler.ts";

class FakeVoice implements VoiceClient {
  calls: VoiceRequest[] = [];
  deleted: string[] = [];
  fail: VoiceFailed | null = null;
  /** The provider refuses to delete (a key without the history permission). */
  keepsHistory = false;
  speak(req: VoiceRequest): Promise<VoiceAnswer> {
    this.calls.push(req);
    if (this.fail) return Promise.reject(this.fail);
    return Promise.resolve({
      audio: Uint8Array.from({ length: 4000 }, (_, i) => i % 251),
      mime: "audio/mpeg",
      requestId: "req-1",
      historyItemId: "hist1abcdef",
    });
  }
  deleteHistory(id: string) {
    this.deleted.push(id);
    return Promise.resolve(!this.keepsHistory);
  }
}

const KID = "child-aaaa-0001";
const NAME = "נֹעָה";
const NITZI = "nitzi";

async function setup(
  over: { enabled?: boolean; voice?: boolean; withSpelling?: boolean; companion?: string } = {},
) {
  const store = new FakeStore();
  store.config.set("name_voice_enabled", over.enabled ?? true);
  store.config.set("elevenlabs_model_id", "eleven_v4_turbo");
  store.characters.set(NITZI, { nameHe: "ניצי", gender: "f", voiceId: "voice-nitzi-0001", personal: false });
  store.characters.set("other-friend", {
    nameHe: "other",
    gender: "m",
    voiceId: "voiceother0001",
    personal: false,
  });
  store.characters.set("hero-son", {
    nameHe: "hero",
    gender: "m",
    voiceId: "voicepersonal01",
    personal: true,
  });
  store.characters.set("quiet", { nameHe: "שקט", gender: "m", voiceId: null, personal: false });
  const voice = new FakeVoice();
  const svc: Services = { ...fakeServices(store), ...(over.voice === false ? {} : { voice }) };
  const put = makeHandler(childPut, () => svc);
  const h = makeHandler(nameVoice, () => svc);
  const parent = await addDevice(store, { family: FAMILY_A, user: USER_A, role: "parent" });
  const child = await addDevice(store, { family: FAMILY_A, user: USER_A, role: "child" });
  const other = await addDevice(store, { family: FAMILY_B, user: USER_B, role: "parent" });
  await call(put, parent, "child-put", {
    child_id: KID,
    nickname: "נועה",
    ...(over.withSpelling === false ? {} : { name_spoken: NAME }),
    ...(over.companion ? { companion_id: over.companion } : {}),
    avatar_id: "avatar-noa",
    address_form: "f",
    age_band: 1,
  });
  const ask = (d = parent, body: Record<string, unknown> = { child_id: KID, character_id: NITZI }) =>
    call(h, d, "name-voice", body);
  return { store, voice, h, parent, child, other, ask };
}

/** Everything the function logs while [run] goes: it must never hold the name. */
async function logged(run: () => Promise<unknown>): Promise<string[]> {
  const lines: string[] = [];
  const original = console.log;
  console.log = (...args: unknown[]) => void lines.push(args.map(String).join(" "));
  try {
    await run();
  } finally {
    console.log = original;
  }
  return lines;
}

Deno.test("name-voice: a parent gets the clip of the child's name, made from the spelling the server holds", async () => {
  const { voice, ask } = await setup();
  const r = await ask();
  assert.equal(r.status, 200);
  const body = await r.json();
  assert.deepEqual(Object.keys(body).sort(), ["audio", "chars", "mime", "spelling_hash"]);
  assert.equal(body.spelling_hash, await spellingHash(NAME), "what the clip was made from, as a hash");
  assert.equal(body.mime, "audio/mpeg");
  assert.equal(body.chars, NAME.length + 1);
  assert.equal(atob(body.audio).length, 4000);
  assert.equal(voice.calls.length, 1);
  assert.deepEqual(voice.calls[0], {
    voiceId: "voice-nitzi-0001",
    modelId: "eleven_v4_turbo",
    text: `${NAME},`,
    timeoutMs: 8000,
    outputFormat: "mp3_44100_64",
    settings: { stability: 0.5, similarity_boost: 0.8, use_speaker_boost: true },
  });
  assert.deepEqual(voice.deleted, ["hist1abcdef"], "the provider's copy is deleted at once");
});

Deno.test("name-voice: the format and settings are those of the recorded lines in content/voices.json", async () => {
  const cfg = JSON.parse(await Deno.readTextFile(new URL("../../content/voices.json", import.meta.url)));
  assert.equal(NAME_VOICE_FORMAT, cfg.outputFormat);
  assert.deepEqual(NAME_VOICE_SETTINGS, cfg.settings);
});

Deno.test("name-voice: nothing is stored and nothing logged holds the name", async () => {
  const { store, ask, h, parent } = await setup();
  const lines = await logged(async () => {
    await ask();
    await ask(parent, { child_id: KID, character_id: "nobody" });
    await call(h, parent, "name-voice", { child_id: KID, character_id: NITZI, name: NAME });
  });
  assert.ok(lines.length >= 3);
  for (const line of lines) {
    assert.ok(!line.includes(NAME) && !line.includes("נועה"), `the log holds a name: ${line}`);
    assert.ok(!line.includes("audio"), line);
  }
  assert.equal(store.cache.size, 0, "no sound is kept");
  assert.equal(store.logs.length, 0, "and no tutor log row is written");
  assert.ok(
    [...store.costMicro.keys()].every((k) => k.startsWith(FAMILY_A)),
    "the cost goes to the family's ledger, as a number",
  );
});

Deno.test("name-voice: the cost is added to the family's ledger by the characters, never the name", async () => {
  const { store, ask } = await setup();
  await ask();
  const day = Math.floor(NOW / 86_400_000);
  const settings = nameVoiceSettings({});
  assert.equal(
    store.costMicro.get(`${FAMILY_A}/${day}`),
    ((NAME.length + 1) / 1000) * settings.priceVoicePer1k,
  );
});

Deno.test("name-voice: the body is two ids and nothing else; a name sent by the phone is refused", async () => {
  const { ask, voice, parent } = await setup();
  for (
    const bad of [
      { child_id: KID },
      { character_id: NITZI },
      { child_id: KID, character_id: NITZI, name: "נועה" },
      { child_id: KID, character_id: NITZI, text: "x" },
      { child_id: "short", character_id: NITZI },
      { child_id: KID, character_id: "NITZI!" },
      { child_id: KID, character_id: "x".repeat(41) },
      { child_id: 5, character_id: NITZI },
    ]
  ) {
    assert.equal((await ask(parent, bad)).status, 400, JSON.stringify(bad));
  }
  assert.equal(voice.calls.length, 0);
});

Deno.test("name-voice: the four checks - a child device, another family, a revoked device, no signature", async () => {
  const { h, store, child, other, ask, voice, parent } = await setup();
  assert.equal((await ask(child)).status, 403, "the role allows only a parent device");
  assert.equal((await ask(other)).status, 404, "another family has no such child");
  const revoked = await addDevice(store, { family: FAMILY_A, user: USER_A, role: "parent", revoked: true });
  assert.equal((await ask(revoked)).status, 401);
  assert.equal(
    (await call(h, parent, "name-voice", { child_id: KID, character_id: NITZI }, { token: "tok.bad" }))
      .status,
    401,
  );
  assert.equal(
    (await h(new Request("https://x.test/functions/v1/name-voice", { method: "POST", body: "{}" }))).status,
    401,
  );
  const replay = crypto.randomUUID();
  assert.equal(
    (await call(h, parent, "name-voice", { child_id: KID, character_id: NITZI }, { nonce: replay }))
      .status,
    200,
  );
  assert.equal(
    (await call(h, parent, "name-voice", { child_id: KID, character_id: NITZI }, { nonce: replay }))
      .status,
    401,
    "a nonce is used once",
  );
  assert.equal(
    (await call(h, parent, "name-voice", { child_id: KID, character_id: NITZI }, { ts: NOW - 120_000 }))
      .status,
    401,
    "the time must be within a minute",
  );
  assert.equal(voice.calls.length, 1, "only the one good call reached the voice");
});

Deno.test("name-voice: the kill switch - off, or never set, makes no call", async () => {
  for (const enabled of [false, undefined]) {
    const { store, voice, ask } = await setup({ enabled: true });
    if (enabled === undefined) store.config.delete("name_voice_enabled");
    else store.config.set("name_voice_enabled", enabled);
    const r = await ask();
    assert.equal(r.status, 503);
    assert.deepEqual(await r.json(), { error: "unavailable" });
    assert.equal(voice.calls.length, 0);
  }
});

Deno.test("name-voice: with no voice key, or no model, it is unavailable and spends nothing", async () => {
  const noKey = await setup({ voice: false });
  assert.equal((await noKey.ask()).status, 503);
  const noModel = await setup();
  noModel.store.config.delete("elevenlabs_model_id");
  assert.equal((await noModel.ask()).status, 503);
  assert.equal(noModel.voice.calls.length, 0);
});

Deno.test("name-voice: no spelling, an unknown child or character, and a character with no voice are refused before any call", async () => {
  const none = await setup({ withSpelling: false });
  assert.equal((await none.ask()).status, 400, "the parent has not written how the name is said");
  const { ask, voice, parent } = await setup();
  assert.equal((await ask(parent, { child_id: "child-zzzz-9999", character_id: NITZI })).status, 404);
  assert.equal((await ask(parent, { child_id: KID, character_id: "nobody" })).status, 400);
  const silent = await setup({ companion: "quiet" });
  assert.equal(
    (await silent.ask(silent.parent, { child_id: KID, character_id: "quiet" })).status,
    503,
    "a friend with no voice yet",
  );
  assert.equal(silent.voice.calls.length, 0);
  assert.equal(voice.calls.length, 0);
  assert.equal(none.voice.calls.length, 0);
});

Deno.test("name-voice: a spelling that is not the narrow rule is refused even if the store holds it", async () => {
  const { store, ask, voice } = await setup();
  store.children.get(FAMILY_A)!.get(KID)!.nameSpoken = "Noa!";
  assert.equal((await ask()).status, 400);
  assert.equal(voice.calls.length, 0);
});

Deno.test("name-voice: a family may make so many clips a day, then it is told so; the next day it may again", async () => {
  const { store, ask, voice, parent } = await setup();
  store.config.set("name_voice_day_cap", 3);
  for (let i = 0; i < 3; i++) assert.equal((await ask()).status, 200);
  const over = await ask();
  assert.equal(over.status, 429);
  assert.deepEqual(await over.json(), { error: "rate_limited" });
  assert.equal(voice.calls.length, 3, "the fourth did not reach the voice");
  assert.equal((await ask(parent)).status, 429);
  const tomorrow = await setup();
  tomorrow.store.config.set("name_voice_day_cap", 1);
  assert.equal((await tomorrow.ask()).status, 200);
  assert.equal((await tomorrow.ask()).status, 429);
  assert.deepEqual(nameVoiceSettings({}), {
    enabled: false,
    dayCap: 20,
    modelId: null,
    priceVoicePer1k: 300_000,
    costCapMicro: 500_000,
  });
});

Deno.test("name-voice: a voice that fails is unavailable to the parent, never an error with a body", async () => {
  for (const reason of ["timeout", "status", "network", "empty"] as const) {
    const { voice, ask } = await setup();
    voice.fail = new VoiceFailed(reason, "HTTP 500");
    const r = await ask();
    assert.equal(r.status, 503, reason);
    assert.deepEqual(await r.json(), { error: "unavailable" });
    assert.deepEqual(voice.deleted, []);
  }
});

Deno.test("name-voice: nothing in the function reads a key or the environment", async () => {
  for (const file of ["name-voice/handler.ts", "_shared/name_voice.ts", "_shared/name_spoken.ts"]) {
    const text = await Deno.readTextFile(new URL(file, import.meta.url));
    assert.ok(!/Deno\.env|API_KEY|apiKey|console\./.test(text), file);
  }
});

Deno.test("name-voice: the provider's history is deleted with one more try; if it stays, one fixed line says so and the clip is still returned (SEC-B42-1)", async () => {
  const kept = await setup();
  kept.voice.keepsHistory = true;
  const lines = await logged(async () => {
    const r = await kept.ask();
    assert.equal(r.status, 200, "the money is spent: the clip is returned");
    await r.body?.cancel();
  });
  assert.deepEqual(kept.voice.deleted, ["hist1abcdef", "hist1abcdef"], "two tries");
  const keptLines = lines.filter((l) => l.includes("history_kept"));
  assert.equal(keptLines.length, 1);
  assert.equal(JSON.parse(keptLines[0]).fn, "name-voice");
  for (const l of lines) {
    assert.ok(!l.includes("hist1abcdef") && !l.includes(NAME), `a log line holds an id or a name: ${l}`);
  }

  const fine = await setup();
  const fineLines = await logged(async () => {
    await (await fine.ask()).body?.cancel();
  });
  assert.deepEqual(fine.voice.deleted, ["hist1abcdef"], "one try when it works");
  assert.ok(!fineLines.some((l) => l.includes("history_kept")));
});

Deno.test("name-voice: only the child's own friend is voiced - the one chosen, or the house character (SEC-B42-2)", async () => {
  const house = await setup();
  for (const character_id of ["other-friend", "hero-son"]) {
    const r = await house.ask(house.parent, { child_id: KID, character_id });
    assert.equal(r.status, 400, character_id);
  }
  assert.equal(house.voice.calls.length, 0, "no voice call for a character the child does not have");
  assert.equal((await house.ask()).status, 200, "the house character speaks for a child with no friend");

  const chose = await setup({ companion: "hero-son" });
  assert.equal((await chose.ask(chose.parent, { child_id: KID, character_id: "hero-son" })).status, 200);
  assert.equal(chose.voice.calls[0].voiceId, "voicepersonal01");
  assert.equal(
    (await chose.ask(chose.parent, { child_id: KID, character_id: "other-friend" })).status,
    400,
    "not a friend the child did not choose",
  );
  assert.equal(
    (await chose.ask()).status,
    200,
    "the house character is still allowed (a friend that is not installed)",
  );
});

Deno.test("name-voice: a family at its daily spend cap gets no more paid clips, and nothing is spent (SEC-B42-4)", async () => {
  const { store, ask, voice } = await setup();
  const day = Math.floor(NOW / 86_400_000);
  store.costMicro.set(`${FAMILY_A}/${day}`, 499_999);
  assert.equal((await ask()).status, 200, "just under the cap");
  store.costMicro.set(`${FAMILY_A}/${day}`, 500_000);
  const r = await ask();
  assert.equal(r.status, 429);
  assert.deepEqual(await r.json(), { error: "rate_limited" });
  assert.equal(voice.calls.length, 1, "the second did not reach the voice");
  store.config.set("tutor_cost_cap_micro", 900_000);
  assert.equal((await ask()).status, 200, "the cap is the owner's setting");
});
