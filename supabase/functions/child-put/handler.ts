// Saves a child of the family: the nickname the parent chose (the one personal text on the server), the avatar, the
// companion, how to address the child and the age band. A child that was deleted can never be saved again.
import { GatewayError } from "../_shared/errors.ts";
import type { FunctionSpec } from "../_shared/handler.ts";
import type { ChildProfile } from "../_shared/store.ts";

export const CHILD_ID = /^[A-Za-z0-9-]{8,64}$/;
/** A nickname: 1 to 24 characters, no control characters and no angle brackets (it is shown in the parent screens). */
// deno-lint-ignore no-control-regex
export const NICKNAME = /^[^\u0000-\u001f\u007f<>]{1,24}$/;

interface Body {
  child_id: string;
  nickname: string;
  avatar_id: string;
  companion_id?: string;
  address_form: "f" | "m" | "n";
  age_band: number;
}

export const spec: FunctionSpec = {
  name: "child-put",
  access: { kind: "device", roles: ["parent"] },
  shape: {
    child_id: { t: "string", max: 64, pattern: CHILD_ID },
    nickname: { t: "string", max: 24, pattern: NICKNAME },
    avatar_id: { t: "string", max: 40, pattern: /^[a-z0-9_-]{2,40}$/ },
    companion_id: { t: "string", max: 40, pattern: /^[a-z0-9-]{2,40}$/, optional: true },
    address_form: { t: "enum", values: ["f", "m", "n"] },
    age_band: { t: "int", min: 0, max: 2 },
  },
  run: async (ctx) => {
    const b = ctx.body as unknown as Body;
    const child: ChildProfile = {
      id: b.child_id,
      nickname: b.nickname,
      avatarId: b.avatar_id,
      companionId: b.companion_id ?? null,
      addressForm: b.address_form,
      ageBand: b.age_band as 0 | 1 | 2,
    };
    const r = await ctx.svc.store.upsertChild(ctx.auth!.device.familyId, child);
    if (r === "deleted") throw new GatewayError("bad_request", "child_deleted");
    return { ok: true };
  },
};
