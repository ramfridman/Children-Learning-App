"""Writes bpe.vocab (piece TAB score) from a sentencepiece bpe.model, with no sentencepiece package: the model is a
protobuf whose field 1 is the repeated pieces (1 piece string, 2 score float32, 3 type varint)."""
import struct
import sys


def varint(b, i):
    shift = 0
    out = 0
    while True:
        c = b[i]
        i += 1
        out |= (c & 0x7F) << shift
        if not c & 0x80:
            return out, i
        shift += 7


def fields(b):
    i = 0
    while i < len(b):
        key, i = varint(b, i)
        num, wire = key >> 3, key & 7
        if wire == 0:
            v, i = varint(b, i)
        elif wire == 1:
            v, i = b[i:i + 8], i + 8
        elif wire == 2:
            n, i = varint(b, i)
            v, i = b[i:i + n], i + n
        elif wire == 5:
            v, i = b[i:i + 4], i + 4
        else:
            raise ValueError('wire type %d' % wire)
        yield num, v


data = open(sys.argv[1], 'rb').read()
rows = []
for num, v in fields(data):
    if num != 1:
        continue
    piece, score = '', 0.0
    for n2, v2 in fields(v):
        if n2 == 1:
            piece = v2.decode('utf-8')
        elif n2 == 2:
            score = struct.unpack('<f', v2)[0]
    rows.append((piece, score))
with open(sys.argv[2], 'w', encoding='utf-8', newline='\n') as f:
    for piece, score in rows:
        f.write('%s\t%s\n' % (piece, score))
print(len(rows), 'pieces ->', sys.argv[2])
