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
