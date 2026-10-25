// Test-only: builds a structurally faithful Android Key Attestation chain (root, intermediate, leaf
// carrying the KeyDescription extension) so every refusal can be exercised. Real Google chains are
// proven on a real phone in Phase G.
import "npm:reflect-metadata@0.2.2";
import * as x509 from "npm:@peculiar/x509@2.2.0";
import type { Bytes } from "../b64.ts";
import { KEY_DESCRIPTION_OID } from "./android.ts";

const concat = (parts: Uint8Array[]) => Uint8Array.from(parts.flatMap((p) => [...p]));
const lenBytes = (n: number) => n < 128 ? [n] : n < 256 ? [0x81, n] : [0x82, n >> 8, n & 0xff];

export const der = (tag: number, ...parts: Uint8Array[]): Uint8Array => {
  const body = concat(parts);
  return Uint8Array.from([tag, ...lenBytes(body.length), ...body]);
};
export const int = (n: number) => {
  const bytes: number[] = [];
  let v = n;
  do {
    bytes.unshift(v & 0xff);
    v = Math.floor(v / 256);
  } while (v > 0);
  if (bytes[0] & 0x80) bytes.unshift(0);
  return der(0x02, Uint8Array.from(bytes));
};
export const enumerated = (n: number) => Uint8Array.from([0x0a, 0x01, n]);
export const octets = (b: Uint8Array) => der(0x04, b);
export const seq = (...p: Uint8Array[]) => der(0x30, ...p);
export const set = (...p: Uint8Array[]) => der(0x31, ...p);
export const bool = (v: boolean) => Uint8Array.from([0x01, 0x01, v ? 0xff : 0x00]);

/** Explicit context tag [n], constructed, supporting high tag numbers such as [709]. */
export function ctx(n: number, ...parts: Uint8Array[]): Uint8Array {
  const body = concat(parts);
  const tag: number[] = [];
  if (n < 31) tag.push(0xa0 | n);
  else {
    tag.push(0xbf);
    const groups = [n & 0x7f];
    for (let v = n >> 7; v > 0; v >>= 7) groups.unshift((v & 0x7f) | 0x80);
    tag.push(...groups);
  }
  return Uint8Array.from([...tag, ...lenBytes(body.length), ...body]);
}

export interface Knobs {
  attestationVersion?: number;
  attestationLevel?: number;
  keyMintLevel?: number;
  challenge?: Uint8Array;
  algorithm?: number;
  curve?: number;
  origin?: number;
  purposes?: number[];
  locked?: boolean;
  bootState?: number;
  packages?: string[];
  digests?: Uint8Array[];
  omitRootOfTrust?: boolean;
  omitAppId?: boolean;
}

export const GOOD_DIGEST = new Uint8Array(32).fill(0xab);

export function keyDescription(k: Knobs): Uint8Array {
  const hardware = [
    ctx(1, set(...(k.purposes ?? [2]).map(int))),
    ctx(2, int(k.algorithm ?? 3)),
    ctx(10, int(k.curve ?? 1)),
    ctx(702, int(k.origin ?? 0)),
    ...(k.omitRootOfTrust ? [] : [
      ctx(
        704,
        seq(
          octets(new Uint8Array(32)),
          bool(k.locked ?? true),
          enumerated(k.bootState ?? 0),
          octets(new Uint8Array(32)),
        ),
      ),
    ]),
  ];
  const appIdInner = seq(
    set(
      ...(k.packages ?? ["com.example.nitznutz"]).map((p) =>
        seq(octets(new TextEncoder().encode(p)), int(1))
      ),
    ),
    set(...(k.digests ?? [GOOD_DIGEST]).map(octets)),
  );
  const software = k.omitAppId ? [] : [ctx(709, octets(appIdInner))];
  return seq(
    int(k.attestationVersion ?? 300),
    enumerated(k.attestationLevel ?? 1),
    int(300),
    enumerated(k.keyMintLevel ?? k.attestationLevel ?? 1),
    octets(k.challenge ?? new Uint8Array(32).fill(5)),
    octets(new Uint8Array(0)),
    seq(...software),
    seq(...hardware),
  );
}

const ALG = { name: "ECDSA", hash: "SHA-256" } as const;
const KEYGEN = { name: "ECDSA", namedCurve: "P-256" } as const;

export interface Built {
  chainDer: Uint8Array[];
  rootPem: string;
  deviceSpki: Bytes;
  /** Private half of the attested key, so a test can self-sign as the phone would. */
  devicePrivateKey: CryptoKey;
  nowMs: number;
}

export async function buildChain(
  k: Knobs = {},
  o: {
    leafValid?: [number, number];
    intermediateIsCa?: boolean;
    skipExtension?: boolean;
    otherDeviceKey?: boolean;
  } = {},
): Promise<Built> {
  const nowMs = 1_800_000_000_000;
  const day = 86_400_000;
  const mk = async () => await crypto.subtle.generateKey(KEYGEN, true, ["sign", "verify"]);
  const [rootKp, midKp, leafKp] = [await mk(), await mk(), await mk()];
  const root = await x509.X509CertificateGenerator.createSelfSigned({
    serialNumber: "01",
    name: "CN=Test Attestation Root",
    notBefore: new Date(nowMs - 400 * day),
    notAfter: new Date(nowMs + 400 * day),
    signingAlgorithm: ALG,
    keys: rootKp,
    extensions: [new x509.BasicConstraintsExtension(true, undefined, true)],
  });
  const mid = await x509.X509CertificateGenerator.create({
    serialNumber: "02",
    subject: "CN=Test Intermediate",
    issuer: root.subject,
    notBefore: new Date(nowMs - 300 * day),
    notAfter: new Date(nowMs + 300 * day),
    signingAlgorithm: ALG,
    publicKey: midKp.publicKey,
    signingKey: rootKp.privateKey,
    extensions: [new x509.BasicConstraintsExtension(o.intermediateIsCa ?? true, undefined, true)],
  });
  const [from, to] = o.leafValid ?? [nowMs - day, nowMs + day];
  const leaf = await x509.X509CertificateGenerator.create({
    serialNumber: "03",
    subject: "CN=Android Keystore Key",
    issuer: mid.subject,
    notBefore: new Date(from),
    notAfter: new Date(to),
    signingAlgorithm: ALG,
    publicKey: leafKp.publicKey,
    signingKey: midKp.privateKey,
    extensions: o.skipExtension
      ? []
      : [new x509.Extension(KEY_DESCRIPTION_OID, false, keyDescription(k) as Bytes)],
  });
  const spki = new Uint8Array(await crypto.subtle.exportKey("spki", leafKp.publicKey)) as Bytes;
  const other = o.otherDeviceKey
    ? new Uint8Array(await crypto.subtle.exportKey("spki", (await mk()).publicKey)) as Bytes
    : spki;
  return {
    chainDer: [leaf, mid, root].map((c) => new Uint8Array(c.rawData)),
    rootPem: root.toString("pem"),
    deviceSpki: other,
    devicePrivateKey: leafKp.privateKey,
    nowMs,
  };
}
