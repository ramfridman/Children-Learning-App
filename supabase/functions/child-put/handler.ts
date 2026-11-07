// Saves a child of the family: the nickname the parent chose (the one personal text on the server), the avatar, the
// companion, the prize it wears, how to address the child, the age band and (B-29) the school stage the parent confirmed.
// A child that was deleted can never be saved again. The month and year of birth are not here and cannot be sent: they stay
// on the device (the shape refuses every key it does not name).
import { GatewayError } from "../_shared/errors.ts";
import type { FunctionSpec } from "../_shared/handler.ts";
import type { ChildProfile } from "../_shared/store.ts";

export const CHILD_ID = /^[A-Za-z0-9-]{8,64}$/;
/** A nickname: 1 to 24 characters, no control characters and no angle brackets (it is shown in the parent screens). */
// deno-lint-ignore no-control-regex
export const NICKNAME = /^[^\u0000-\u001f\u007f<>]{1,24}$/;

/** The school stage a parent confirms (never the school's name or year). Mirrored in `testvectors/profile-sync.json`. */
export const SCHOOL_STAGES = ["gan3", "gan4", "gan5", "grade1", "grade2", "grade3"] as const;
export type SchoolStage = typeof SCHOOL_STAGES[number];
/** The band (0, 1, 2 for A, B, C) each stage sets: the band comes from the stage, never from an age in months. */
export const BAND_OF_STAGE: Record<SchoolStage, 0 | 1 | 2> = {
  gan3: 0,
  gan4: 0,
  gan5: 1,
  grade1: 1,
  grade2: 2,
  grade3: 2,
};

interface Body {
  child_id: string;
  nickname: string;
  avatar_id: string;
  companion_id?: string;
  outfit_id?: string;
  address_form: "f" | "m" | "n";
  age_band: number;
  school_stage?: SchoolStage;
}

export const spec: FunctionSpec = {
  name: "child-put",
  access: { kind: "device", roles: ["parent"] },
  shape: {
    child_id: { t: "string", max: 64, pattern: CHILD_ID },
    nickname: { t: "string", max: 24, pattern: NICKNAME },
    avatar_id: { t: "string", max: 40, pattern: /^[a-z0-9_-]{2,40}$/ },
    companion_id: { t: "string", max: 40, pattern: /^[a-z0-9-]{2,40}$/, optional: true },
    outfit_id: { t: "string", max: 20, pattern: /^[a-z0-9-]{2,20}$/, optional: true },
    address_form: { t: "enum", values: ["f", "m", "n"] },
    age_band: { t: "int", min: 0, max: 2 },
    school_stage: { t: "enum", values: SCHOOL_STAGES, optional: true },
  },
  run: async (ctx) => {
    const b = ctx.body as unknown as Body;
    // The stage and the band are one fact: a stage that says another band than the one sent is a mistake, not a choice.
    if (b.school_stage !== undefined && BAND_OF_STAGE[b.school_stage] !== b.age_band) {
      throw new GatewayError("bad_request", "school_stage_band");
    }
    const child: ChildProfile = {
      id: b.child_id,
      nickname: b.nickname,
      avatarId: b.avatar_id,
      companionId: b.companion_id ?? null,
      outfitId: b.outfit_id ?? null,
      addressForm: b.address_form,
      ageBand: b.age_band as 0 | 1 | 2,
      // Absent keeps the stored stage (the store does not overwrite with null).
      schoolStage: b.school_stage ?? null,
    };
    const r = await ctx.svc.store.upsertChild(ctx.auth!.device.familyId, child);
    if (r === "deleted") throw new GatewayError("bad_request", "child_deleted");
    return { ok: true };
  },
};
