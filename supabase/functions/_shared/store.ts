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

  // Family management
  listActiveDevices(familyId: string): Promise<DeviceSummary[]>;
  /** False if the device is not an active device of that family. */
  revokeDevice(familyId: string, deviceId: string, reason: RevokeReason): Promise<boolean>;
}

export interface Secrets {
  /** Keys for keyed hashes (pairing codes, IP addresses). Never logged, never in the repository. */
  pairingCodeKey: Bytes;
  ipHashKey: Bytes;
}
