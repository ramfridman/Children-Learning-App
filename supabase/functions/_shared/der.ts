// A small, strict DER reader for the few structures we must parse ourselves (the Key Attestation
// extension). It handles high tag numbers (the attestation fields use tags such as [709]),
// refuses indefinite lengths, and never reads past the end of its input.

export interface Tlv {
  /** 0 universal, 1 application, 2 context-specific, 3 private */
  cls: number;
  constructed: boolean;
  tag: number;
  /** The content bytes (header removed). */
  value: Uint8Array;
  /** Index just past this element in the input. */
  end: number;
}

export class DerError extends Error {}

export function readTlv(buf: Uint8Array, pos = 0): Tlv {
  if (pos >= buf.length) throw new DerError("eof");
  const first = buf[pos++];
  const cls = first >> 6;
  const constructed = (first & 0x20) !== 0;
  let tag = first & 0x1f;
  if (tag === 0x1f) {
    tag = 0;
    let n = 0;
    for (;;) {
      if (pos >= buf.length || ++n > 4) throw new DerError("bad tag");
      const b = buf[pos++];
      tag = (tag << 7) | (b & 0x7f);
      if ((b & 0x80) === 0) break;
    }
    if (tag < 31) throw new DerError("non-minimal tag");
  }
  if (pos >= buf.length) throw new DerError("eof");
  let len = buf[pos++];
  if (len & 0x80) {
    const n = len & 0x7f;
    if (n === 0 || n > 3) throw new DerError("bad length");
    len = 0;
    for (let i = 0; i < n; i++) {
      if (pos >= buf.length) throw new DerError("eof");
      len = (len << 8) | buf[pos++];
    }
    if (len < 128) throw new DerError("non-minimal length");
  }
  if (pos + len > buf.length) throw new DerError("length overruns input");
  return { cls, constructed, tag, value: buf.subarray(pos, pos + len), end: pos + len };
}

/** All direct children of a constructed element. */
export function children(value: Uint8Array): Tlv[] {
  const out: Tlv[] = [];
  for (let pos = 0; pos < value.length;) {
    const t = readTlv(value, pos);
    out.push(t);
    pos = t.end;
  }
  return out;
}

export function expect(t: Tlv, cls: number, tag: number, what: string): Tlv {
  if (t.cls !== cls || t.tag !== tag) throw new DerError(`expected ${what}`);
  return t;
}

/** A small non-negative INTEGER or ENUMERATED. */
export function smallInt(t: Tlv): number {
  if (t.cls !== 0 || (t.tag !== 2 && t.tag !== 10)) throw new DerError("expected integer");
  const v = t.value;
  if (v.length === 0 || v.length > 6) throw new DerError("integer size");
  if (v[0] & 0x80) throw new DerError("negative integer");
  let n = 0;
  for (const b of v) n = n * 256 + b;
  return n;
}
