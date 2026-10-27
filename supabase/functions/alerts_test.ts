// Alerts, push tokens, the family's settings and the tutor log: who may call what, what is kept, and that the one push
// says only that there is a new alert.
import { assert } from "./_shared/testassert.ts";
import { b64urlDecode } from "./_shared/b64.ts";
import {
  fcmClient,
  notifyParents,
  parseServiceAccount,
  PUSH_TEXT,
  type PushClient,
  type PushResult,
} from "./_shared/fcm.ts";
import { makeHandler, type Services } from "./_shared/handler.ts";
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
import { ALERTS_PER_HOUR_PER_DEVICE, spec as alertCreate } from "./alert-create/handler.ts";
import { spec as alertList } from "./alert-list/handler.ts";
import { spec as alertRead } from "./alert-read/handler.ts";
import { spec as childPut } from "./child-put/handler.ts";
import { spec as pushToken } from "./push-token-register/handler.ts";
import { spec as pushTokenRemove } from "./push-token-remove/handler.ts";
import { spec as settingsGet } from "./settings-get/handler.ts";
import { spec as settingsPut } from "./settings-put/handler.ts";
import { spec as tutorLog } from "./tutor-log/handler.ts";

const KID = "child-aaaa-0001";
const TOKEN = "fcm-token-" + "a".repeat(60);

class FakePush implements PushClient {
  sent: Array<{ token: string; platform: string }> = [];
  result: PushResult = "ok";
  async send(token: string, platform: "android" | "ios") {
    this.sent.push({ token, platform });
    return await Promise.resolve(this.result);
  }
}

async function setup() {
  const store = new FakeStore();
  const push = new FakePush();
  const svc: Services = { ...fakeServices(store), push };
  const h = {
    create: makeHandler(alertCreate, () => svc),
    list: makeHandler(alertList, () => svc),
    read: makeHandler(alertRead, () => svc),
    token: makeHandler(pushToken, () => svc),
    untoken: makeHandler(pushTokenRemove, () => svc),
    get: makeHandler(settingsGet, () => svc),
    put: makeHandler(settingsPut, () => svc),
    log: makeHandler(tutorLog, () => svc),
    kid: makeHandler(childPut, () => svc),
  };
  const parent = await addDevice(store, { family: FAMILY_A, user: USER_A, role: "parent" });
  const parent2 = await addDevice(store, { family: FAMILY_A, user: USER_A, role: "parent" });
  const child = await addDevice(store, { family: FAMILY_A, user: USER_A, role: "child" });
  const other = await addDevice(store, { family: FAMILY_B, user: USER_B, role: "parent" });
  await call(h.kid, parent, "child-put", {
    child_id: KID,
    nickname: "נועה",
    avatar_id: "avatar-noa",
    address_form: "f",
    age_band: 1,
  });
  const alert = (over: Record<string, unknown> = {}) => ({
    child_id: KID,
    category: "frustration",
    severity: "attention",
    count: 0,
    key: "upset:1",
    at: NOW - 1000,
    ...over,
  });
  const j = async (r: Response) => await r.json();
  return { store, push, svc, h, parent, parent2, child, other, alert, j };
}

Deno.test("alert-create: an alert is saved once, a repeat is a duplicate, and an unknown child is refused", async () => {
  const { h, child, alert, j, store } = await setup();
  assert.deepEqual(await j(await call(h.create, child, "alert-create", alert())), { status: "new" });
  assert.deepEqual(await j(await call(h.create, child, "alert-create", alert())), { status: "duplicate" });
  assert.deepEqual(
    await j(await call(h.create, child, "alert-create", alert({ child_id: "child-zzzz-0009", key: "x:2" }))),
    { status: "refused" },
  );
  assert.equal(store.alerts.length, 1);
});

Deno.test("alert-create: what an alert may carry is limited, and only two kinds may carry words", async () => {
  const { h, child, alert } = await setup();
  const bad: Array<[string, Record<string, unknown>]> = [
    ["a child alert without a child", { child_id: undefined }],
    ["words on a time alert", { category: "pastLimit", words: "חרא" }],
    ["free text in the detail", { detail: "he was sad today" }],
    ["a category that does not exist", { category: "shouting" }],
    ["a severity that does not exist", { severity: "panic" }],
    ["words with a link", { category: "disclosure", words: "http://x.example" }],
    ["an unknown field", { transcript: "אני" }],
    ["a key with spaces", { key: "has spaces" }],
  ];
  for (const [why, over] of bad) {
    const body = { ...alert(), ...over };
    for (const k of Object.keys(body)) {
      if ((body as Record<string, unknown>)[k] === undefined) delete (body as Record<string, unknown>)[k];
    }
    assert.equal((await call(h.create, child, "alert-create", body)).status, 400, why);
  }
  const gate = { category: "gateAttempts", severity: "attention", count: 3, key: "gate:1", at: NOW - 1000 };
  assert.equal(
    (await call(h.create, child, "alert-create", gate)).status,
    200,
    "a gate alert needs no child",
  );
  const said = alert({ category: "inappropriateWords", words: "חרא", key: "words:1" });
  assert.equal(
    (await call(h.create, child, "alert-create", said)).status,
    200,
    "swearing may carry the words",
  );
});

Deno.test("alert-create: the parents' other phones get one push that says only that there is a new alert", async () => {
  const { h, child, parent, parent2, alert, push } = await setup();
  await call(h.token, parent, "push-token-register", { token: TOKEN, platform: "android" });
  await call(h.token, parent2, "push-token-register", { token: "other-" + TOKEN, platform: "android" });
  await call(h.create, child, "alert-create", alert());
  assert.equal(push.sent.length, 2, "both parent phones");
  await call(h.create, child, "alert-create", alert());
  assert.equal(push.sent.length, 2, "a duplicate sends nothing");
  // The phone that raised the alert is not told about its own alert.
  await call(h.create, parent, "alert-create", alert({ key: "upset:2" }));
  assert.equal(push.sent.length, 3);
  assert.equal(push.sent[2].token, "other-" + TOKEN);
});

Deno.test("alert-create: a dead push token is removed, a failing push never fails the alert, no push set up is fine", async () => {
  const { h, child, parent, alert, push, store, svc } = await setup();
  await call(h.token, parent, "push-token-register", { token: TOKEN, platform: "android" });
  push.result = "invalid_token";
  assert.equal((await call(h.create, child, "alert-create", alert())).status, 200);
  assert.equal(store.pushTokenRows.length, 0, "the dead token is gone");
  await call(h.token, parent, "push-token-register", { token: TOKEN, platform: "android" });
  push.result = "failed";
  assert.equal((await call(h.create, child, "alert-create", alert({ key: "upset:2" }))).status, 200);
  assert.equal(store.pushTokenRows.length, 1, "a passing failure keeps the token");
  svc.push = undefined;
  assert.equal((await call(h.create, child, "alert-create", alert({ key: "upset:3" }))).status, 200);
});

Deno.test("push-token-remove: a parent phone takes only itself off the list; a child device cannot", async () => {
  const { h, child, parent, parent2, store } = await setup();
  await call(h.token, parent, "push-token-register", { token: TOKEN, platform: "android" });
  await call(h.token, parent2, "push-token-register", { token: "other-" + TOKEN, platform: "android" });
  assert.equal((await call(h.untoken, child, "push-token-remove", {})).status, 403);
  assert.equal(store.pushTokenRows.length, 2);
  assert.equal((await call(h.untoken, parent, "push-token-remove", {})).status, 200);
  assert.equal(store.pushTokenRows.length, 1, "only this phone's token is gone");
  assert.equal((await call(h.untoken, parent, "push-token-remove", {})).status, 200, "twice is fine");
});

Deno.test("alert-create: a device can raise only a limited number of alerts an hour", async () => {
  const { h, child, alert, store } = await setup();
  const hour = Math.floor(NOW / 3_600_000) * 3_600_000;
  store.counters.set(`alert_create/${child.id}/${hour}`, ALERTS_PER_HOUR_PER_DEVICE);
  assert.equal((await call(h.create, child, "alert-create", alert())).status, 429);
});

Deno.test("alert-list and alert-read: parents only, 30 days, newest first, and read marks them", async () => {
  const { h, child, parent, other, alert, j } = await setup();
  await call(h.create, child, "alert-create", alert({ key: "a", at: NOW - 3000 }));
  await call(h.create, child, "alert-create", alert({ key: "b", at: NOW - 1000 }));
  await call(h.create, child, "alert-create", alert({ key: "old", at: NOW - 31 * 86_400_000 }));
  assert.equal(
    (await call(h.list, child, "alert-list", {})).status,
    403,
    "a child device cannot read alerts",
  );
  const list = await j(await call(h.list, parent, "alert-list", {}));
  assert.deepEqual(
    list.alerts.map((a: { key: string }) => a.key),
    ["b", "a"],
    "newest first, nothing older than 30 days",
  );
  assert.ok(list.alerts.every((a: { read_at: unknown }) => a.read_at === null));
  assert.equal((await call(h.read, child, "alert-read", {})).status, 403);
  // Every unread alert is marked, including the one that is about to age out.
  assert.deepEqual(await j(await call(h.read, parent, "alert-read", {})), { marked: 3 });
  assert.deepEqual(await j(await call(h.read, parent, "alert-read", {})), { marked: 0 });
  const after = await j(await call(h.list, parent, "alert-list", {}));
  assert.ok(after.alerts.every((a: { read_at: unknown }) => a.read_at !== null));
  assert.deepEqual(
    (await j(await call(h.list, other, "alert-list", {}))).alerts,
    [],
    "another family sees none",
  );
});

Deno.test("push-token-register: parent phones only, a plain token, and a new token replaces the old one", async () => {
  const { h, child, parent, store } = await setup();
  assert.equal(
    (await call(h.token, child, "push-token-register", { token: TOKEN, platform: "android" })).status,
    403,
  );
  for (const token of ["short", "has spaces " + "a".repeat(30), "<script>" + "a".repeat(30)]) {
    assert.equal(
      (await call(h.token, parent, "push-token-register", { token, platform: "android" })).status,
      400,
      token,
    );
  }
  assert.equal(
    (await call(h.token, parent, "push-token-register", { token: TOKEN, platform: "windows" })).status,
    400,
  );
  await call(h.token, parent, "push-token-register", { token: TOKEN, platform: "android" });
  await call(h.token, parent, "push-token-register", { token: "new-" + TOKEN, platform: "android" });
  assert.equal(store.pushTokenRows.length, 1);
  assert.equal(store.pushTokenRows[0].token, "new-" + TOKEN);
});

Deno.test("settings: parents write, every device reads, the last write wins and counts the versions", async () => {
  const { h, child, parent, other, j } = await setup();
  assert.deepEqual(await j(await call(h.get, child, "settings-get", {})), { rules: null, version: 0 });
  const rules = {
    limitByBand: { A: 15, B: 30, C: 45 },
    restOn: true,
    restStartMinute: 1200,
    restEndMinute: 390,
    lockWhenDone: false,
    keepWords: false,
    schedule: { "3": [[900, 1080]] },
    limitByChild: { [KID]: 20 },
  };
  assert.equal((await call(h.put, child, "settings-put", { rules_json: JSON.stringify(rules) })).status, 403);
  assert.deepEqual(
    await j(await call(h.put, parent, "settings-put", { rules_json: JSON.stringify(rules) })),
    { version: 1 },
  );
  assert.deepEqual(
    await j(await call(h.put, parent, "settings-put", { rules_json: JSON.stringify({ restOn: false }) })),
    { version: 2 },
  );
  const got = await j(await call(h.get, child, "settings-get", {}));
  assert.deepEqual(got, { rules: { restOn: false }, version: 2 });
  assert.deepEqual(await j(await call(h.get, other, "settings-get", {})), { rules: null, version: 0 });
});

Deno.test("settings-put: only a document the app can read gets in", async () => {
  const { h, parent } = await setup();
  const bad: unknown[] = [
    "not json",
    "[1]",
    { limitByBand: { A: 4 } },
    { limitByBand: { A: 181 } },
    { limitByBand: { D: 30 } },
    { limitByBand: { A: 30.5 } },
    { restStartMinute: 1440 },
    { restOn: "yes" },
    { schedule: { "8": [[1, 2]] } },
    { schedule: { "1": [[1, 2], [1, 2], [1, 2], [1, 2]] } },
    { schedule: { "1": [[1]] } },
    { limitByChild: { "x": 30 } },
    { nickname: "נועה" },
    { aiHelper: "yes" },
    { voiceEnabled: true },
  ];
  for (const doc of bad) {
    const rules_json = typeof doc === "string" ? doc : JSON.stringify(doc);
    assert.equal((await call(h.put, parent, "settings-put", { rules_json })).status, 400, rules_json);
  }
  assert.equal((await call(h.put, parent, "settings-put", { rules_json: "x".repeat(4001) })).status, 400);
});

Deno.test("tutor-log: parents only, and it returns what the helper said", async () => {
  const { h, child, parent, store, j } = await setup();
  store.logs.push({
    familyId: FAMILY_A,
    childRef: KID,
    itemId: "count.butterflies.3",
    characterId: "hero-son",
    source: "cache",
    outcome: "ok",
    line: "בּוֹאוּ נִסְפֹּר",
  } as never);
  assert.equal((await call(h.log, child, "tutor-log", {})).status, 403);
  const r = await j(await call(h.log, parent, "tutor-log", {}));
  assert.equal(r.entries.length, 1);
  assert.equal(r.entries[0].line, "בּוֹאוּ נִסְפֹּר");
  assert.equal(r.entries[0].child_id, KID);
});

// ---- the push itself ---------------------------------------------------------------------------------------------
async function serviceAccount() {
  const pair = await crypto.subtle.generateKey(
    {
      name: "RSASSA-PKCS1-v1_5",
      modulusLength: 2048,
      publicExponent: new Uint8Array([1, 0, 1]),
      hash: "SHA-256",
    },
    true,
    ["sign", "verify"],
  );
  const der = new Uint8Array(await crypto.subtle.exportKey("pkcs8", pair.privateKey));
  let bin = "";
  for (const b of der) bin += String.fromCharCode(b);
  // A throwaway key made a moment ago for this test; the markers are built from parts so that no key-shaped text sits in
  // the source for a secret scanner to trip over.
  const marker = (edge: "BEGIN" | "END") => ["-----" + edge, "PRIVATE", "KEY-----"].join(" ");
  const pem = `${marker("BEGIN")}\n${btoa(bin).match(/.{1,64}/g)!.join("\n")}\n${marker("END")}\n`;
  const json = JSON.stringify({
    project_id: "nitznutz-test",
    client_email: "push@nitznutz-test.iam.gserviceaccount.com",
    private_key: pem,
  });
  return { json, publicKey: pair.publicKey };
}

Deno.test("fcm: it signs a token request, caches the token, and sends a message that holds only the fixed phrase", async () => {
  const { json, publicKey } = await serviceAccount();
  const calls: Array<{ url: string; init: RequestInit }> = [];
  let tokenRequests = 0;
  const fetchFn = ((url: string, init: RequestInit) => {
    calls.push({ url, init });
    if (url === "https://oauth2.googleapis.com/token") {
      tokenRequests++;
      return Promise.resolve(new Response(JSON.stringify({ access_token: "tok-1", expires_in: 3600 })));
    }
    return Promise.resolve(new Response("{}", { status: 200 }));
  }) as unknown as typeof fetch;
  const client = fcmClient(json, { fetchFn, nowMs: () => NOW })!;
  assert.ok(client);
  assert.equal(await client.send(TOKEN, "android"), "ok");
  assert.equal(await client.send(TOKEN + "2", "android"), "ok");
  assert.equal(tokenRequests, 1, "the access token is reused");

  // The assertion is a real signed JWT for the right account and scope.
  const form = calls[0].init.body as URLSearchParams;
  const [head, claims, sig] = form.get("assertion")!.split(".");
  const payload = JSON.parse(new TextDecoder().decode(b64urlDecode(claims)!));
  assert.equal(payload.iss, "push@nitznutz-test.iam.gserviceaccount.com");
  assert.equal(payload.scope, "https://www.googleapis.com/auth/firebase.messaging");
  assert.equal(
    await crypto.subtle.verify(
      "RSASSA-PKCS1-v1_5",
      publicKey,
      b64urlDecode(sig)! as BufferSource,
      new TextEncoder().encode(`${head}.${claims}`),
    ),
    true,
  );

  // The message: a token, the fixed phrase, a channel, and nothing else.
  const send = calls[1];
  assert.equal(send.url, "https://fcm.googleapis.com/v1/projects/nitznutz-test/messages:send");
  assert.equal((send.init.headers as Record<string, string>).authorization, "Bearer tok-1");
  const msg = JSON.parse(send.init.body as string);
  assert.deepEqual(Object.keys(msg), ["message"]);
  assert.deepEqual(Object.keys(msg.message).sort(), ["android", "notification", "token"]);
  assert.deepEqual(msg.message.notification, { body: PUSH_TEXT });
  assert.equal(PUSH_TEXT, "יש התראה חדשה");
  assert.equal(JSON.stringify(msg).includes("data"), false, "no data payload at all");
});

Deno.test("fcm: a dead token is told apart from a passing failure, iOS is not sent yet, and a bad secret gives no client", async () => {
  const { json } = await serviceAccount();
  const answer = (status: number) =>
    ((url: string) =>
      Promise.resolve(
        url.includes("oauth2")
          ? new Response(JSON.stringify({ access_token: "t", expires_in: 3600 }))
          : new Response("{}", { status }),
      )) as unknown as typeof fetch;
  assert.equal(await fcmClient(json, { fetchFn: answer(404) })!.send(TOKEN, "android"), "invalid_token");
  assert.equal(await fcmClient(json, { fetchFn: answer(400) })!.send(TOKEN, "android"), "invalid_token");
  assert.equal(await fcmClient(json, { fetchFn: answer(500) })!.send(TOKEN, "android"), "failed");
  assert.equal(await fcmClient(json, { fetchFn: answer(200) })!.send(TOKEN, "ios"), "failed");
  const down = (() => Promise.reject(new Error("offline"))) as unknown as typeof fetch;
  assert.equal(await fcmClient(json, { fetchFn: down })!.send(TOKEN, "android"), "failed");
  assert.equal(fcmClient("not json"), null);
  assert.equal(parseServiceAccount(JSON.stringify({ project_id: "x" })), null);
  assert.equal(
    parseServiceAccount(
      JSON.stringify({ project_id: "nitznutz-test", client_email: "a@b.example.com", private_key: "nope" }),
    ),
    null,
  );
});

Deno.test("fcm: notifyParents never throws and never waits long for a slow push", async () => {
  const store = new FakeStore();
  await store.upsertPushToken(FAMILY_A, "d2d2d2d2-0000-4000-8000-000000000001", TOKEN, "android");
  const slow: PushClient = { send: () => new Promise((r) => setTimeout(() => r("ok"), 5000)) };
  const t0 = performance.now();
  assert.equal(await notifyParents(slow, store, FAMILY_A, "none", 200), 0);
  assert.ok(performance.now() - t0 < 1500, "it gave up after its short wait");
  const broken = {
    pushTokens: () => Promise.reject(new Error("db down")),
    removePushToken: () => Promise.resolve(),
  };
  assert.equal(await notifyParents(new FakePush(), broken, FAMILY_A, "none"), 0);
  assert.equal(await notifyParents(undefined, store, FAMILY_A, "none"), 0);
});

Deno.test("settings-put: the AI helper switch and the keep-the-words switch are part of the family's rules", async () => {
  const { h, parent, child, j } = await setup();
  const rules = { aiHelper: true, keepWords: false, restOn: true };
  assert.deepEqual(
    await j(await call(h.put, parent, "settings-put", { rules_json: JSON.stringify(rules) })),
    {
      version: 1,
    },
  );
  assert.deepEqual(
    (await j(await call(h.get, child, "settings-get", {}))).rules,
    rules,
    "a child device reads them",
  );
});
