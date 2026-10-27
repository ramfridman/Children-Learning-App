// Everything the functions need from the database, as one interface. The real implementation
// (db.ts) talks to Postgres as the least-privilege `app_gateway` role; tests use fake_store.ts.
import type { Bytes } from "./b64.ts";
import type { DeviceRecord } from "./auth.ts";

export type RevokeReason = "parent" | "replaced" | "inactive" | "family_deleted" | "admin";

export interface DeviceSummary {
  id: string;
  role: "parent" | "child";
  platform: "android" | "ios";
  securityLevel: string;
  createdAt: Date;
  lastSeenAt: Date | null;
}

export interface Store {
  // Authentication
  getDevice(id: string): Promise<DeviceRecord | null>;
  isGuardian(userId: string, familyId: string): Promise<boolean>;
  recordNonce(deviceId: string, nonce: string): Promise<boolean>;
  touchDevice(id: string): Promise<void>;

  // Settings and limits
  getConfig(key: string): Promise<unknown | undefined>;
  /** Several settings in one round trip; a missing key is absent from the result. */
  getConfigs(keys: readonly string[]): Promise<Record<string, unknown>>;
  /** Counts one use in the current window; false means the limit is already reached. */
  rateLimitHit(scope: string, key: string, windowStart: Date, limit: number): Promise<boolean>;

  // Enrolment and pairing
  insertChallenge(c: {
    challenge: Bytes;
    purpose: "enroll" | "pair";
    userId: string | null;
    ipHash: Bytes | null;
    expiresAt: Date;
  }): Promise<void>;
  /** False if a live code with the same hash exists (caller picks a new code and retries). */
  insertPairingCode(
    c: { familyId: string; byDevice: string; codeHash: Bytes; expiresAt: Date },
  ): Promise<boolean>;

  /** Marks a challenge used if it is live, unused, of this purpose and (for enrolment) this user's. */
  consumeChallenge(
    c: { challenge: Bytes; purpose: "enroll" | "pair"; userId: string | null },
  ): Promise<boolean>;
  /** Is there an unexpired dev allowlist entry with this secret hash? (Emulators, dev flavour only.) */
  devAllowlistHas(secretHash: Bytes): Promise<boolean>;
  /**
   * In one transaction: find or create the user's family (as guardian), optionally replace one of
   * its devices, and add the new parent device.
   */
  enrolParentDevice(e: {
    userId: string;
    replaceDeviceId: string | null;
    publicKey: Bytes;
    platform: "android" | "ios";
    attestationKind: "key_attestation" | "app_attest" | "dev_allowlist";
    securityLevel: "strongbox" | "tee" | "secure_enclave" | "dev";
    appVersion: string | null;
  }): Promise<
    | { ok: true; deviceId: string; familyId: string }
    | { ok: false; reason: "device_limit" | "key_in_use" | "no_such_device" }
  >;

  /**
   * Pairing step 1: is the challenge live, and does the code match a live pairing code?
   * A wrong code adds one to the challenge's failed attempts; at 5 the challenge is dead.
   */
  pairPeek(c: { challenge: Bytes; codeHash: Bytes }): Promise<
    { ok: true; familyId: string; guardianUserId: string } | {
      ok: false;
      reason: "challenge_invalid" | "bad_code";
    }
  >;
  /** Pairing step 2, atomically: burn the challenge and the code and add the child device. */
  pairComplete(c: {
    challenge: Bytes;
    codeHash: Bytes;
    publicKey: Bytes;
    platform: "android" | "ios";
    attestationKind: "key_attestation" | "app_attest" | "dev_allowlist";
    securityLevel: "strongbox" | "tee" | "secure_enclave" | "dev";
    appVersion: string | null;
  }): Promise<
    | { ok: true; deviceId: string; familyId: string }
    | { ok: false; reason: "challenge_invalid" | "bad_code" | "device_limit" | "key_in_use" }
  >;

  // Family management
  listActiveDevices(familyId: string): Promise<DeviceSummary[]>;
  /** False if the device is not an active device of that family. */
  revokeDevice(familyId: string, deviceId: string, reason: RevokeReason): Promise<boolean>;

  // Content (M6)
  /**
   * Publishes one pack version's item index in one transaction. `older`: a higher version of the pack is already
   * published; `conflict`: this version is published with other contents; `unchanged`: exactly this is published.
   */
  publishContent(p: PublishedPack): Promise<"published" | "unchanged" | "older" | "conflict">;

  // The tutor (M6)
  /** The item, its misconceptions and the speaking character, or null if the pack version has no such item. */
  tutorContext(
    packId: string,
    packVersion: string,
    itemId: string,
    characterId: string,
  ): Promise<TutorContext | null>;
  /** The ids of the items of a pack version that allow the AI tutor, in a fixed order. */
  tutorItemIds(packId: string, packVersion: string): Promise<string[]>;
  cacheGet(k: CacheKey): Promise<CachedLine | null>;
  /** Keeps the line; with `replace`, a line already there for this key is replaced (a reviewed line that was edited). */
  cachePut(k: CacheKey, v: CachedLine, replace?: boolean): Promise<void>;
  /** One atomic call for every cap; nothing is counted when a limit is already reached. */
  tutorTake(p: {
    familyId: string;
    childRef: string;
    sessionRef: string;
    kind: "turn" | "prefetch";
    sessionCap: number;
    dayCap: number;
    prefetchCap: number;
    costCapMicro: number;
    nowMs: number;
  }): Promise<TakeResult>;
  tutorCostAdd(familyId: string, micro: number, nowMs: number): Promise<void>;
  logTutor(row: TutorLogRow): Promise<void>;

  // The parent area (M7b): children, the log of what they did, and deleting a child
  /** Saves a child (the nickname is the one personal text on the server). `deleted`: that child was deleted. */
  upsertChild(familyId: string, c: ChildProfile): Promise<"saved" | "deleted">;
  listChildren(familyId: string): Promise<ChildProfile[]>;
  /** The ids of the children deleted in this family (every device deletes their local data). */
  listTombstones(familyId: string): Promise<string[]>;
  /** Everything about the child, and a tombstone, in one transaction. Idempotent. */
  deleteChild(familyId: string, childId: string): Promise<void>;
  /**
   * Adds events to the log. An event already there (same id) is a duplicate and changes nothing. An event for a child
   * the family does not have (or that was deleted) is refused.
   */
  insertEvents(familyId: string, deviceId: string, events: readonly EventIn[]): Promise<{
    accepted: number;
    duplicates: number;
    refused: string[];
  }>;
  /** The events after the cursor, in the order the server received them, one more than `limit` is looked at. */
  pullEvents(familyId: string, after: number, limit: number): Promise<{ events: EventOut[]; more: boolean }>;

  // Alerts, push tokens, the family's settings and the tutor log (M7b)
  /** `refused`: the alert names a child the family does not have (or that was deleted). */
  insertAlert(familyId: string, deviceId: string, a: AlertIn): Promise<"new" | "duplicate" | "refused">;
  /** Alerts of the family from `sinceMs` on, newest first. */
  listAlerts(familyId: string, sinceMs: number): Promise<AlertOut[]>;
  /** Marks every unread alert of the family read; returns how many. */
  markAlertsRead(familyId: string, nowMs: number): Promise<number>;
  upsertPushToken(
    familyId: string,
    deviceId: string,
    token: string,
    platform: "android" | "ios",
  ): Promise<void>;
  removePushToken(deviceId: string): Promise<void>;
  pushTokens(
    familyId: string,
  ): Promise<Array<{ deviceId: string; token: string; platform: "android" | "ios" }>>;
  getSettings(familyId: string): Promise<{ rules: Record<string, unknown>; version: number } | null>;
  /** Replaces the family's settings (the last write wins); returns the new version, a server counter. */
  putSettings(familyId: string, rules: Record<string, unknown>): Promise<number>;
  /** What the tutor said to the family's children since `sinceMs`, newest first. */
  tutorLogOf(familyId: string, sinceMs: number, limit: number): Promise<TutorLogEntry[]>;
}

// ---- The tutor (M6) ----

export interface TutorContext {
  itemId: string;
  band: "A" | "B" | "C";
  llmAllowed: boolean;
  goal: string;
  promptText: string;
  numberSet: number[];
  allowedActions: string[];
  hintThreshold: number;
  objectIds: string[];
  answers: PublishedAnswer[];
  /** Misconception tag to its description, for the prompt. */
  descriptions: Record<string, string>;
  character: { nameHe: string; gender: "m" | "f"; voiceId: string | null } | null;
}

export interface CacheKey {
  packId: string;
  packVersion: string;
  itemId: string;
  /** A misconception tag, or `default`. */
  mistake: string;
  hintLevel: number;
  band: "A" | "B" | "C";
  addressForm: "f" | "m" | "n";
  characterId: string;
  promptVersion: string;
  validatorVersion: string;
}

export interface CachedLine {
  line: string;
  caption: string | null;
  next: string;
  highlight: string[];
  audio: Uint8Array | null;
}

export type TakeResult = "ok" | "session_cap" | "day_cap" | "prefetch_cap" | "cost_cap";

export interface TutorLogRow {
  familyId: string;
  childRef: string;
  sessionRef: string;
  packId: string;
  packVersion: string;
  itemId: string;
  characterId: string;
  source: "live" | "cache" | "prefetch" | "rule";
  outcome: string;
  line: string | null;
  validatorOk: boolean | null;
  validatorFailures: string[];
  promptVersion: string;
  totalMs: number;
  modelMs: number | null;
  voiceMs: number | null;
  elevenRequestId: string | null;
}

export interface PublishedAnswer {
  id: string;
  value?: number;
  label?: string;
  misconception?: string;
  correct: boolean;
}

export interface PublishedItem {
  itemId: string;
  revision: number;
  template: string;
  band: "A" | "B" | "C";
  skillIds: string[];
  llmAllowed: boolean;
  goal: string;
  promptText: string;
  answers: PublishedAnswer[];
  numberSet: number[];
  allowedActions: string[];
  hintThreshold: number;
  objectIds: string[];
}

export interface PublishedCharacter {
  characterId: string;
  nameHe: string;
  gender: "m" | "f";
  voiceId: string | null;
  personal: boolean;
}

export interface PublishedPack {
  packId: string;
  packVersion: string;
  manifestSha256: string;
  items: PublishedItem[];
  misconceptions: Array<{ tag: string; skillIds: string[]; description: string }>;
  characters: PublishedCharacter[];
}

export interface Secrets {
  /** Keys for keyed hashes (pairing codes, IP addresses). Never logged, never in the repository. */
  pairingCodeKey: Bytes;
  ipHashKey: Bytes;
  /** The content publish secret (only the owner's computer has the other copy). Absent: publishing is unavailable. */
  publishSecret?: string;
}

/** A child as the server knows them. */
export interface ChildProfile {
  id: string;
  nickname: string;
  avatarId: string;
  companionId: string | null;
  addressForm: "f" | "m" | "n";
  ageBand: 0 | 1 | 2;
}

/** One thing a child did, as a device sends it: ids, numbers and fixed words only. */
export interface EventIn {
  id: string;
  childId: string;
  clientAtMs: number;
  engineVersion: number;
  type: "attempt" | "session" | "reward";
  payload: Record<string, unknown>;
}

export interface EventOut extends EventIn {
  seq: number;
  deviceId: string;
}

export interface AlertIn {
  childId: string | null;
  category: string;
  severity: string;
  count: number;
  detail: string;
  words: string;
  key: string;
  clientAtMs: number;
}

export interface AlertOut extends AlertIn {
  id: string;
  deviceId: string;
  readAtMs: number | null;
}

export interface TutorLogEntry {
  atMs: number;
  childRef: string;
  itemId: string;
  characterId: string;
  source: string;
  outcome: string;
  line: string | null;
}
