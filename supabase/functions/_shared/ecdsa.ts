// ECDSA signature verification on the NIST curves P-256 and P-384, in plain BigInt arithmetic.
//
// Why this exists: the Edge runtime's WebCrypto only accepts P-256 with SHA-256 and P-384 with
// SHA-384. Google's attestation chains contain certificates signed with SHA-256 by a P-384 key, so
// the runtime refuses links of a perfectly valid chain. This module checks those links.
//
// It only ever handles public values (a certificate, its issuer's public key, a signature), so
// there is nothing secret to leak through timing and no constant-time code is needed. It is used
// only as a fallback when WebCrypto throws. It verifies, it never signs.
//
// Points are kept in Jacobian coordinates (X, Y, Z) meaning (X/Z², Y/Z³); Z = 0 is the point at
// infinity. Both curves have a = -3.

export type CurveName = "P-256" | "P-384";

interface Curve {
  p: bigint;
  n: bigint;
  b: bigint;
  gx: bigint;
  gy: bigint;
  /** Size of a coordinate or scalar in bytes. */
  size: number;
}

const CURVES: Record<CurveName, Curve> = {
  "P-256": {
    p: 0xffffffff00000001000000000000000000000000ffffffffffffffffffffffffn,
    n: 0xffffffff00000000ffffffffffffffffbce6faada7179e84f3b9cac2fc632551n,
    b: 0x5ac635d8aa3a93e7b3ebbd55769886bc651d06b0cc53b0f63bce3c3e27d2604bn,
    gx: 0x6b17d1f2e12c4247f8bce6e563a440f277037d812deb33a0f4a13945d898c296n,
    gy: 0x4fe342e2fe1a7f9b8ee7eb4a7c0f9e162bce33576b315ececbb6406837bf51f5n,
    size: 32,
  },
  "P-384": {
    p: 0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffeffffffff0000000000000000ffffffffn,
    n: 0xffffffffffffffffffffffffffffffffffffffffffffffffc7634d81f4372ddf581a0db248b0a77aecec196accc52973n,
    b: 0xb3312fa7e23ee7e4988e056be3f82d19181d9c6efe8141120314088f5013875ac656398d8a2ed19d2a85c8edd3ec2aefn,
    gx: 0xaa87ca22be8b05378eb1c71ef320ad746e1d3b628ba79b9859f741e082542a385502f25dbf55296c3a545e3872760ab7n,
    gy: 0x3617de4a96262c6f5d9e98bf9292dc29f8f41dbd289a147ce9da3113b5f0b8c00a60b1ce1d7e819d7a431d7c90ea0e5fn,
    size: 48,
  },
};

type Point = readonly [bigint, bigint, bigint];

const mod = (a: bigint, m: bigint): bigint => ((a % m) + m) % m;

function modPow(base: bigint, exp: bigint, m: bigint): bigint {
  let result = 1n;
  let b = mod(base, m);
  for (let e = exp; e > 0n; e >>= 1n) {
    if (e & 1n) result = (result * b) % m;
    b = (b * b) % m;
  }
  return result;
}

const toBig = (bytes: Uint8Array): bigint => {
  let n = 0n;
  for (const x of bytes) n = (n << 8n) | BigInt(x);
  return n;
};

function double(c: Curve, [x, y, z]: Point): Point {
  const { p } = c;
  if (z === 0n || y === 0n) return [1n, 1n, 0n];
  const delta = (z * z) % p;
  const gamma = (y * y) % p;
  const beta = (x * gamma) % p;
  const alpha = mod(3n * (x - delta) * (x + delta), p);
  const x3 = mod(alpha * alpha - 8n * beta, p);
  const z3 = mod((y + z) * (y + z) - gamma - delta, p);
  const y3 = mod(alpha * (4n * beta - x3) - 8n * gamma * gamma, p);
  return [x3, y3, z3];
}

function add(c: Curve, a: Point, b: Point): Point {
  const { p } = c;
  const [x1, y1, z1] = a;
  const [x2, y2, z2] = b;
  if (z1 === 0n) return b;
  if (z2 === 0n) return a;
  const z1z1 = (z1 * z1) % p;
  const z2z2 = (z2 * z2) % p;
  const u1 = (x1 * z2z2) % p;
  const u2 = (x2 * z1z1) % p;
  const s1 = (((y1 * z2) % p) * z2z2) % p;
  const s2 = (((y2 * z1) % p) * z1z1) % p;
  const h = mod(u2 - u1, p);
  const r = mod(s2 - s1, p);
  if (h === 0n) return r === 0n ? double(c, a) : [1n, 1n, 0n];
  const hh2 = (2n * h) % p;
  const i = (hh2 * hh2) % p;
  const j = (h * i) % p;
  const r2 = (2n * r) % p;
  const v = (u1 * i) % p;
  const x3 = mod(r2 * r2 - j - 2n * v, p);
  const y3 = mod(r2 * (v - x3) - 2n * s1 * j, p);
  const z3 = mod(((z1 + z2) * (z1 + z2) - z1z1 - z2z2) * h, p);
  return [x3, y3, z3];
}

function multiply(c: Curve, k: bigint, pt: Point): Point {
  let acc: Point = [1n, 1n, 0n];
  for (let i = k.toString(2).length - 1; i >= 0; i--) {
    acc = double(c, acc);
    if ((k >> BigInt(i)) & 1n) acc = add(c, acc, pt);
  }
  return acc;
}

/** Reads r and s from a DER ECDSA-Sig-Value (a SEQUENCE of two INTEGERs), the form certificates use. */
function readSignature(sig: Uint8Array): [bigint, bigint] | null {
  let pos = 0;
  const header = (): number | null => {
    // A one- or two-byte length; the signatures here are far under 64 KB.
    const len = sig[pos + 1];
    if (len === undefined) return null;
    if (len < 0x80) {
      pos += 2;
      return len;
    }
    if (len === 0x81 && sig[pos + 2] !== undefined) {
      pos += 3;
      return sig[pos - 1];
    }
    return null;
  };
  if (sig[pos] !== 0x30) return null;
  const total = header();
  if (total === null || pos + total !== sig.length) return null;
  const ints: bigint[] = [];
  for (let k = 0; k < 2; k++) {
    if (sig[pos] !== 0x02) return null;
    const len = header();
    if (len === null || len === 0 || pos + len > sig.length) return null;
    if (sig[pos] & 0x80) return null; // negative
    ints.push(toBig(sig.subarray(pos, pos + len)));
    pos += len;
  }
  return pos === sig.length ? [ints[0], ints[1]] : null;
}

/**
 * Verifies an ECDSA signature over an already-computed hash.
 *
 * @param publicPoint the public key as an uncompressed point: 0x04 ‖ X ‖ Y
 * @param digest the hash of the signed data (any length: it is cut to the curve's size as ECDSA says)
 * @param signature DER encoded, as in certificates
 */
export function ecdsaVerifyDigest(
  curve: CurveName,
  publicPoint: Uint8Array,
  digest: Uint8Array,
  signature: Uint8Array,
): boolean {
  const c = CURVES[curve];
  if (publicPoint.length !== 1 + 2 * c.size || publicPoint[0] !== 4) return false;
  const qx = toBig(publicPoint.subarray(1, 1 + c.size));
  const qy = toBig(publicPoint.subarray(1 + c.size));
  if (qx >= c.p || qy >= c.p) return false;
  // The public key must lie on the curve: y² = x³ − 3x + b (mod p).
  if (mod(qy * qy, c.p) !== mod(qx * qx * qx - 3n * qx + c.b, c.p)) return false;

  const rs = readSignature(signature);
  if (!rs) return false;
  const [r, s] = rs;
  if (r < 1n || r >= c.n || s < 1n || s >= c.n) return false;

  let e = toBig(digest);
  const excess = digest.length * 8 - c.n.toString(2).length;
  if (excess > 0) e >>= BigInt(excess);

  const w = modPow(s, c.n - 2n, c.n);
  const u1 = mod(e * w, c.n);
  const u2 = mod(r * w, c.n);
  const sum = add(c, multiply(c, u1, [c.gx, c.gy, 1n]), multiply(c, u2, [qx, qy, 1n]));
  if (sum[2] === 0n) return false;
  const zInv = modPow(sum[2], c.p - 2n, c.p);
  const x = mod(sum[0] * zInv * zInv, c.p);
  return mod(x, c.n) === r;
}
