import { assert } from "../testassert.ts";
import { type AndroidPolicy, certDigestHex, verifyAndroidKeyAttestation } from "./android.ts";
import { buildChain, GOOD_DIGEST, type Knobs } from "./android_fixture.ts";
import { GOOGLE_ATTESTATION_ROOTS } from "../trust/google_roots.ts";

const CHALLENGE = new Uint8Array(32).fill(5);
const hex = (b: Uint8Array) => [...b].map((x) => x.toString(16).padStart(2, "0")).join("");

const policyFor = (rootPem: string, over: Partial<AndroidPolicy> = {}): AndroidPolicy => ({
  apps: [{ packageName: "com.example.nitznutz", certSha256: [hex(GOOD_DIGEST)] }],
  requireVerifiedBoot: true,
  rootsPem: [rootPem],
  ...over,
});

async function run(
  knobs: Knobs = {},
  opts: Parameters<typeof buildChain>[1] = {},
  over: { policy?: Partial<AndroidPolicy>; challenge?: Uint8Array; nowShift?: number } = {},
) {
  const b = await buildChain(knobs, opts);
  return await verifyAndroidKeyAttestation(
    b.chainDer,
    { challenge: over.challenge ?? CHALLENGE, publicKeySpki: b.deviceSpki },
    policyFor(b.rootPem, over.policy),
    b.nowMs + (over.nowShift ?? 0),
  );
}
const reason = async (p: ReturnType<typeof run>) => {
  const r = await p;
  return r.ok ? "ok" : r.reason;
};

Deno.test("a genuine-looking TEE chain passes and reports the security level and package", async () => {
  const r = await run();
  assert.deepEqual(r, { ok: true, securityLevel: "tee", packageName: "com.example.nitznutz" });
  const s = await run({ attestationLevel: 2 });
  assert.deepEqual(s, { ok: true, securityLevel: "strongbox", packageName: "com.example.nitznutz" });
});

Deno.test("challenge and key must match this enrolment", async () => {
  assert.equal(await reason(run({}, {}, { challenge: new Uint8Array(32).fill(6) })), "challenge_mismatch");
  assert.equal(await reason(run({ challenge: new Uint8Array(32).fill(6) })), "challenge_mismatch");
  assert.equal(await reason(run({}, { otherDeviceKey: true })), "key_mismatch");
});

Deno.test("software-only or inconsistent security levels are refused", async () => {
  assert.equal(await reason(run({ attestationLevel: 0 })), "software_attestation");
  assert.equal(await reason(run({ attestationLevel: 1, keyMintLevel: 2 })), "security_level_mismatch");
  assert.equal(await reason(run({ attestationVersion: 2 })), "attestation_too_old");
});

Deno.test("the key must be a P-256 signing key generated on the device", async () => {
  assert.equal(await reason(run({ algorithm: 1 })), "not_ec_key");
  assert.equal(await reason(run({ curve: 2 })), "not_p256");
  assert.equal(await reason(run({ origin: 2 })), "key_not_generated_on_device");
  assert.equal(await reason(run({ origin: 3 })), "key_not_generated_on_device");
  assert.equal(await reason(run({ purposes: [3] })), "no_sign_purpose");
  assert.equal(await reason(run({ purposes: [] })), "no_sign_purpose");
});

Deno.test("boot state: locked and verified required, unless the policy relaxes it for lab phones", async () => {
  assert.equal(await reason(run({ locked: false })), "bootloader_unlocked_or_unverified");
  assert.equal(await reason(run({ bootState: 2 })), "bootloader_unlocked_or_unverified");
  assert.equal(await reason(run({ omitRootOfTrust: true })), "no_root_of_trust");
  assert.equal(
    await reason(run({ locked: false, bootState: 2 }, {}, { policy: { requireVerifiedBoot: false } })),
    "ok",
  );
});

Deno.test("the app must be ours: package name and signing certificate", async () => {
  assert.equal(await reason(run({ packages: ["com.evil.app"] })), "package_not_allowed");
  assert.equal(await reason(run({ packages: ["com.example.nitznutz", "com.other"] })), "multiple_packages");
  assert.equal(await reason(run({ digests: [new Uint8Array(32).fill(1)] })), "signing_cert_not_allowed");
  assert.equal(
    await reason(run({ digests: [GOOD_DIGEST, new Uint8Array(32).fill(1)] })),
    "signing_cert_not_allowed",
  );
  assert.equal(await reason(run({ digests: [] })), "signing_cert_not_allowed");
  assert.equal(await reason(run({ omitAppId: true })), "no_app_id");
  assert.equal(await reason(run({}, {}, { policy: { apps: [] } })), "package_not_allowed");
});

Deno.test("the certificate chain must be valid, current and end at a trusted root", async () => {
  assert.equal(await reason(run({}, { skipExtension: true })), "no_attestation_extension");
  assert.equal(await reason(run({}, { intermediateIsCa: false })), "issuer_not_ca");
  assert.equal(await reason(run({}, {}, { nowShift: 1000 * 86_400_000 })), "cert_not_valid_now");
  assert.equal(await reason(run({}, {}, { nowShift: -1000 * 86_400_000 })), "cert_not_valid_now");

  // A chain from a different root than the trusted one.
  const a = await buildChain();
  const other = await buildChain();
  assert.equal(
    (await verifyAndroidKeyAttestation(
      a.chainDer,
      { challenge: CHALLENGE, publicKeySpki: a.deviceSpki },
      policyFor(other.rootPem),
      a.nowMs,
    )).ok,
    false,
  );
  // The real Google roots do not trust a test chain.
  const google = GOOGLE_ATTESTATION_ROOTS.map((r) => r.pem);
  const g = await verifyAndroidKeyAttestation(
    a.chainDer,
    { challenge: CHALLENGE, publicKeySpki: a.deviceSpki },
    { ...policyFor(a.rootPem), rootsPem: google },
    a.nowMs,
  );
  assert.deepEqual(g, { ok: false, reason: "untrusted_root" });

  // A leaf signed by someone else (swap in another chain's intermediate).
  const swapped = [a.chainDer[0], other.chainDer[1], a.chainDer[2]];
  assert.equal(
    (await verifyAndroidKeyAttestation(
      swapped,
      { challenge: CHALLENGE, publicKeySpki: a.deviceSpki },
      policyFor(a.rootPem),
      a.nowMs,
    )).ok,
    false,
  );
});

Deno.test("chain length and garbage input are refused without throwing", async () => {
  const a = await buildChain();
  const exp = { challenge: CHALLENGE, publicKeySpki: a.deviceSpki };
  const pol = policyFor(a.rootPem);
  assert.deepEqual(await verifyAndroidKeyAttestation([a.chainDer[0]], exp, pol, a.nowMs), {
    ok: false,
    reason: "chain_length",
  });
  assert.deepEqual(await verifyAndroidKeyAttestation([], exp, pol, a.nowMs), {
    ok: false,
    reason: "chain_length",
  });
  assert.deepEqual(await verifyAndroidKeyAttestation(Array(7).fill(a.chainDer[0]), exp, pol, a.nowMs), {
    ok: false,
    reason: "chain_length",
  });
  assert.equal(
    (await verifyAndroidKeyAttestation([new Uint8Array([1, 2, 3]), new Uint8Array([4])], exp, pol, a.nowMs))
      .ok,
    false,
  );
  assert.equal(
    (await verifyAndroidKeyAttestation([a.chainDer[0], new Uint8Array(0)], exp, pol, a.nowMs)).ok,
    false,
  );
});

Deno.test("the bundled Google roots are intact (fingerprints match what was fetched)", async () => {
  assert.equal(GOOGLE_ATTESTATION_ROOTS.length, 2);
  const expected = [
    "CE:DB:1C:B6:DC:89:6A:E5:EC:79:73:48:BC:E9:28:67:53:C2:B3:8E:E7:1C:E0:FB:E3:4A:9A:12:48:80:0D:FC",
    "6D:9D:B4:CE:6C:5C:0B:29:31:66:D0:89:86:E0:57:74:A8:77:6C:EB:52:5D:9E:43:29:52:0D:E1:2B:A4:BC:C0",
  ];
  for (let i = 0; i < 2; i++) {
    const body = GOOGLE_ATTESTATION_ROOTS[i].pem.replace(/-----[A-Z ]+-----|\s/g, "");
    const der = Uint8Array.from(atob(body), (c) => c.charCodeAt(0));
    const digest = await certDigestHex(der);
    const colon = digest.toUpperCase().match(/../g)!.join(":");
    assert.equal(colon, expected[i]);
    assert.equal(GOOGLE_ATTESTATION_ROOTS[i].sha256, expected[i]);
  }
});
