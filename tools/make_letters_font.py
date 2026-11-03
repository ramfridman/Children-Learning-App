"""Builds Nitznutz Letters, the app's font for English and Russian lesson text (docs/languages/fonts.md, option B).

    python tools/make_letters_font.py                 # downloads the pinned Andika 7.000 zip into build/font-cache/
    python tools/make_letters_font.py --zip PATH      # uses a copy of Andika-7.000.zip that is already on disk

Needs fontTools (a dev-only tool, approved by the owner on 2026-11-03; not an app package): `pip install fonttools`.

What it does, for the Medium (500) and Bold (700) weights:
  1. takes Andika 7.000 by SIL Global (OFL 1.1) from the pinned GitHub release and checks the SHA-256 of the zip and of the
     two font files inside it (the numbers below are those in docs/languages/fonts.md section 4). The raw Andika files are
     never written to the repo: the zip stays in build/ (git-ignored);
  2. points U+0430 (Cyrillic small a) at Andika's own two-storey Latin glyph `a`, the form Russian primers print. Latin a
     (U+0061) stays the single-storey `a.SngStory`. Capital А (U+0410) is unchanged;
  3. subsets the font to Basic Latin, Latin-1, the Russian Cyrillic letters (А-я, Ё ё), the combining grave, acute (the
     stress mark), breve and diaeresis, the dotted circle, common punctuation, and the bidi controls the app puts around
     an English or Russian run inside Hebrew (U+2066-U+2069, LRM, RLM). Only the default layout features are kept (kern,
     mark, mkmk, ccmp, locl, ...): the stylistic sets go, so `ss01` (which brings back the double-storey a and g) cannot be
     switched on by mistake;
  4. renames it under OFL condition 3 (the Reserved Font Names "Andika" and "SIL" may not name a changed version, and a
     subset is a changed version, OFL-FAQ 2.6): every name record says Nitznutz Letters, no record carries "Andika" or
     "SIL", and the vendor id is cleared. The original copyright line, the Reserved Font Names and the licence go with the
     fonts in OFL-NitznutzLetters.txt (OFL condition 2 allows them as a stand-alone text file), and FONTLOG-NitznutzLetters.txt
     says what was changed.

Writes (deterministic: the same zip gives the same bytes):
  app/assets/fonts/NitznutzLetters-Medium.ttf
  app/assets/fonts/NitznutzLetters-Bold.ttf
  app/assets/fonts/OFL-NitznutzLetters.txt
  app/assets/fonts/FONTLOG-NitznutzLetters.txt
and prints each file's size and a check of the result (the cmap of U+0061 and U+0430, and no reserved name left).
"""
import argparse
import hashlib
import io
import os
import sys
import urllib.request
import zipfile

from fontTools import subset
from fontTools.ttLib import TTFont

ROOT = os.path.normpath(os.path.join(os.path.dirname(os.path.abspath(__file__)), '..'))
OUT = os.path.join(ROOT, 'app', 'assets', 'fonts')
CACHE = os.path.join(ROOT, 'build', 'font-cache')

URL = 'https://github.com/silnrsi/font-andika/releases/download/v7.000/Andika-7.000.zip'
ZIP_SHA256 = '88ba6ea41ef4a8e5214b090df8fa2983be1babe4843efaa99cdb6078b0e2c070'
ZIP_SIZE = 10127314
SOURCES = {
    'Medium': ('Andika-7.000/Andika-Medium.ttf', 'dccaf8662b5883ff9c3a2a9290ba1793bf93d8237a03e65b22c2eef1a626e164'),
    'Bold': ('Andika-7.000/Andika-Bold.ttf', '3ad43a77a29ea060528be69a9e0e81c9dbbe8dff894a26ae1818d3c472393319'),
}
LICENCE = 'Andika-7.000/OFL.txt'

FAMILY = 'Nitznutz Letters'
PS_FAMILY = 'NitznutzLetters'
BUILD = 1
# 2026-11-03 00:00 UTC in the head table's clock (seconds since 1904-01-01), so a rebuild gives the same bytes.
FIXED_TIME = 3876508800

# What the lessons need, and nothing else (docs/languages/fonts.md section 7).
UNICODES = (
    list(range(0x0020, 0x007F))           # Basic Latin
    + list(range(0x00A0, 0x0100))         # Latin-1: accented letters, « », no-break space
    + [0x0401, 0x0451]                    # Ё ё
    + list(range(0x0410, 0x0450))         # А-Я а-я
    + [0x0300, 0x0301, 0x0306, 0x0308]    # combining grave, acute (stress), breve, diaeresis
    + [0x25CC]                            # dotted circle: a mark shown on its own
    + list(range(0x2010, 0x2016))         # hyphens and dashes
    + list(range(0x2018, 0x201F))         # quotation marks
    + [0x2022, 0x2026, 0x2039, 0x203A, 0x2116]
    + [0x200B, 0x200C, 0x200D, 0x200E, 0x200F, 0x2060, 0xFEFF]
    + list(range(0x2066, 0x206A))         # LRI RLI FSI PDI
)

RESERVED = ('andika', 'sil')


def sha256(data):
    return hashlib.sha256(data).hexdigest()


def load_zip(path):
    if path is None:
        path = os.path.join(CACHE, 'Andika-7.000.zip')
        if not os.path.exists(path):
            os.makedirs(CACHE, exist_ok=True)
            print('downloading', URL)
            with urllib.request.urlopen(URL, timeout=120) as r:
                data = r.read()
            if sha256(data) != ZIP_SHA256:
                sys.exit('the downloaded zip does not have the pinned SHA-256; nothing written')
            with open(path, 'wb') as fh:
                fh.write(data)
    data = open(path, 'rb').read()
    if len(data) != ZIP_SIZE or sha256(data) != ZIP_SHA256:
        sys.exit('%s is not the pinned Andika-7.000.zip (size or SHA-256 differs); nothing written' % path)
    return zipfile.ZipFile(io.BytesIO(data))


def rename(font, style):
    """Every name record says Nitznutz Letters; the ones that only named SIL or its sites are dropped."""
    bold = style == 'Bold'
    legacy_family = FAMILY if bold else '%s %s' % (FAMILY, style)
    full = '%s %s' % (FAMILY, style)
    ps = '%s-%s' % (PS_FAMILY, style)
    names = {
        0: 'Copyright (c) 2004-2025 the authors of the original font, with Reserved Font Names; see OFL-NitznutzLetters.txt. '
           'Changes (c) 2026 the Nitznutz project.',
        1: legacy_family,
        2: 'Bold' if bold else 'Regular',
        3: 'Nitznutz: %s: %d' % (full, BUILD),
        4: full,
        5: 'Version 7.000; Nitznutz Letters build %d' % BUILD,
        6: ps,
        8: 'The Nitznutz project',
        10: 'Nitznutz Letters: a renamed, subset build of an open literacy font for Latin and Cyrillic, with a two-storey '
            'Cyrillic a. See FONTLOG-NitznutzLetters.txt.',
        13: 'This Font Software is licensed under the Open Font License, Version 1.1. The licence and the original '
            'copyright notice are in OFL-NitznutzLetters.txt and at https://openfontlicense.org',
        14: 'https://openfontlicense.org',
        16: FAMILY,
        17: style,
    }
    table = font['name']
    keep_ids = set(names) | {9}  # 9: the designers' own names, as published
    feature_ids = {r.nameID for r in table.names if r.nameID >= 256}
    table.names = [r for r in table.names if r.nameID in keep_ids or r.nameID in feature_ids]
    for r in table.names:
        if r.nameID in names:
            r.string = names[r.nameID]
    for (pid, eid, lid) in {(r.platformID, r.platEncID, r.langID) for r in table.names}:
        for nid, text in names.items():
            if table.getName(nid, pid, eid, lid) is None and pid == 3:
                table.setName(text, nid, pid, eid, lid)
    # A feature name or a designer line that still says a reserved name is dropped.
    table.names = [r for r in table.names if not any(w in r.toUnicode().lower() for w in RESERVED)]
    font['OS/2'].achVendID = 'NONE'


def build(zf, style):
    member, digest = SOURCES[style]
    raw = zf.read(member)
    if sha256(raw) != digest:
        sys.exit('%s does not have the pinned SHA-256; nothing written' % member)
    font = TTFont(io.BytesIO(raw), recalcTimestamp=False)
    for t in font['cmap'].tables:
        if t.isUnicode() and 0x0430 in t.cmap:
            t.cmap[0x0430] = 'a'  # Andika's two-storey a (U+0061 maps to a.SngStory)
    opts = subset.Options()
    opts.name_IDs = ['*']
    opts.name_languages = ['*']
    opts.name_legacy = True
    opts.notdef_outline = True
    opts.glyph_names = True  # keeps the names a, a.SngStory, so the check below (and the app's font test) can read them
    opts.recalc_timestamp = False
    opts.drop_tables += ['Silt', 'Silf', 'Sill', 'Glat', 'Gloc', 'Feat', 'DSIG']
    sub = subset.Subsetter(opts)
    sub.populate(unicodes=UNICODES)
    sub.subset(font)
    rename(font, style)
    font['head'].created = FIXED_TIME
    font['head'].modified = FIXED_TIME
    path = os.path.join(OUT, '%s-%s.ttf' % (PS_FAMILY, style))
    font.save(path)
    return path


def check(path):
    font = TTFont(path)
    cmap = font.getBestCmap()
    leftover = [(r.nameID, r.toUnicode()) for r in font['name'].names if any(w in r.toUnicode().lower() for w in RESERVED)]
    missing = [hex(u) for u in list(range(0x0410, 0x0450)) + [0x0401, 0x0451, 0x0301] if u not in cmap]
    print('  %s: %d bytes, %d glyphs; U+0061 -> %s, U+0430 -> %s, U+0410 -> %s; missing %s; reserved names left %s; vendor %r'
          % (os.path.basename(path), os.path.getsize(path), len(font.getGlyphOrder()), cmap.get(0x61), cmap.get(0x430),
             cmap.get(0x410), missing or 'none', leftover or 'none', font['OS/2'].achVendID))
    if cmap.get(0x430) != 'a' or cmap.get(0x61) != 'a.SngStory' or leftover or missing:
        sys.exit('check failed for %s' % path)


FONTLOG = """FONTLOG for Nitznutz Letters
============================

Nitznutz Letters is the font the Nitznutz app uses for English and Russian lesson text (words, syllables and letter
tiles) for young children. It is a Modified Version of Andika 7.000 (2 June 2025) by SIL Global, released under the
Open Font License 1.1. "Andika" and "SIL" are Reserved Font Names of the original, so this build carries another name
(OFL condition 3). The original copyright notice and the licence are in OFL-NitznutzLetters.txt.

Source
------
Andika-7.000.zip from https://github.com/silnrsi/font-andika/releases/tag/v7.000
  zip SHA-256           88ba6ea41ef4a8e5214b090df8fa2983be1babe4843efaa99cdb6078b0e2c070
  Andika-Medium.ttf     dccaf8662b5883ff9c3a2a9290ba1793bf93d8237a03e65b22c2eef1a626e164
  Andika-Bold.ttf       3ad43a77a29ea060528be69a9e0e81c9dbbe8dff894a26ae1818d3c472393319
Built by tools/make_letters_font.py (fontTools) in the Nitznutz repository.

Changes from the original
-------------------------
2026-11-03 (build 1)
- U+0430 CYRILLIC SMALL LETTER A is mapped to the original font's own two-storey "a" glyph, the form printed in Russian
  primers. No outline was drawn or changed. U+0061 keeps the single-storey a.
- Subset to Basic Latin, Latin-1, the Russian Cyrillic alphabet (with Ё ё), the combining grave, acute, breve and
  diaeresis, the dotted circle, common punctuation and the bidi isolate and mark controls. Only the default OpenType
  layout features are kept; the stylistic sets and the Graphite tables are removed.
- Renamed to "Nitznutz Letters" (Medium and Bold) in every name record; the vendor id is cleared.
"""


def main():
    ap = argparse.ArgumentParser(description=__doc__.split('\n')[0])
    ap.add_argument('--zip', help='a local copy of Andika-7.000.zip (checked against the pinned SHA-256)')
    args = ap.parse_args()
    zf = load_zip(args.zip)
    os.makedirs(OUT, exist_ok=True)
    print('Nitznutz Letters')
    for style in ('Medium', 'Bold'):
        check(build(zf, style))
    licence = zf.read(LICENCE).decode('utf-8').replace('\r\n', '\n')
    with open(os.path.join(OUT, 'OFL-NitznutzLetters.txt'), 'w', encoding='utf-8', newline='\n') as fh:
        fh.write('Nitznutz Letters is a Modified Version of Andika 7.000, renamed under condition 3 below.\n'
                 'What was changed: FONTLOG-NitznutzLetters.txt.\n\n' + licence)
    with open(os.path.join(OUT, 'FONTLOG-NitznutzLetters.txt'), 'w', encoding='utf-8', newline='\n') as fh:
        fh.write(FONTLOG)
    for name in ('OFL-NitznutzLetters.txt', 'FONTLOG-NitznutzLetters.txt'):
        print('  %s: %d bytes' % (name, os.path.getsize(os.path.join(OUT, name))))


if __name__ == '__main__':
    main()
