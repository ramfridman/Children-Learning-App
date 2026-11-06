"""Checks docs/languages/hebrew/band-b-pilot.md against the syllabus, the frame,
the stroke set, the picture folder and pronunciation.csv. Standard library only.
Usage: python -I check_heb_pilot.py <repo-root>"""
import csv, json, os, re, sys, unicodedata
from collections import Counter, defaultdict

root = sys.argv[1]
P = lambda *a: os.path.join(root, *a)
doc = open(P('docs/languages/hebrew/band-b-pilot.md'), encoding='utf-8').read()
syl = open(P('docs/languages/hebrew/syllabus.md'), encoding='utf-8').read()
frame = open(P('docs/languages/frame.md'), encoding='utf-8').read()
strokes = json.load(open(P('content/languages/strokes/hebrew-print.json'), encoding='utf-8'))
pics_on_disk = {f[:-4] for f in os.listdir(P('content/languages/pictures')) if f.endswith('.svg')}
csv_ids = {r['id'] for r in csv.DictReader(open(P('docs/languages/hebrew/pronunciation.csv'), encoding='utf-8'))}

errors, notes = [], []
def err(m): errors.append(m)

# ---- reference sets
syl_skills = set(re.findall(r'^\| (HEB-[ABC]-\d\d) \|', syl, re.M))
groups = ['S1', 'S2', 'S4', 'S5', 'S6', 'S7']
for b in ('14', '15', '24', '26'):  # B-25 retired 2026-11-06 (E-1)
    for g in groups:
        syl_skills.add(f'HEB-B-{b}.{g}')
syl_tags = set(re.findall(r'^\| (M-HEB-[A-Z-]+) \|', syl, re.M))
heb_block = frame.split('<!-- catalogue:heb:start -->')[1].split('<!-- catalogue:heb:end -->')[0]
frame_tags = set(re.findall(r'^\| (M-HEB-[A-Z-]+) \|', heb_block, re.M))
forms = {f['id'] for f in strokes['forms']}
PROPOSED = set()  # LETTER-MIX and READ-PART adopted 2026-11-06 (frame §4.6)

# ---- split the doc into sections
sections = re.split(r'^(#{2,3} .*)$', doc, flags=re.M)
sec = {}
for i in range(1, len(sections), 2):
    sec[sections[i]] = sections[i + 1]
def section(prefix):
    for k, v in sec.items():
        if k.startswith(prefix):
            return v
    raise KeyError(prefix)

# ---- clip definitions: first cell of table rows in sections 4 and 9
defined = set()
for pre in ('## 4.', '## 9.'):
    for line in section(pre).splitlines():
        if line.startswith('|'):
            cells = line.strip().strip('|').split('|')
            for c in cells[:2]:
                for cid in re.findall(r'^\s*`(heb-[ab]-[a-z0-9]+(?:-[a-z0-9]+)*)`', c):
                    defined.add(cid)
# reused rows listed in prose of section 9 (heb-a-w-matos, `-lechem` ...)
reuse = section('## 9.')
for m in re.finditer(r'`(heb-a-[a-z]-[a-z0-9-]+)`', reuse):
    defined.add(m.group(1))
# shorthand `-lechem` after heb-a-w- in the reused line
for m in re.finditer(r'`-([a-z0-9]+)`', reuse):
    defined.add('heb-a-w-' + m.group(1))
for c in list(defined):
    if c.startswith('heb-a-') and c not in csv_ids:
        # expand ranges like heb-a-ok-1 ... -8 handled below
        pass
for n in range(1, 9):
    defined.add(f'heb-a-ok-{n}')
defined.update({'heb-a-try-1', 'heb-a-try-2'})

# ---- new picture list (section 8)
new_pics = set()
for line in section('## 8.').splitlines():
    m = re.match(r'^\| `([a-z0-9-]+)` \|', line)
    if m:
        new_pics.add(m.group(1))
new_pics |= set(re.findall(r'`(letter-mirror-[a-z-]+)`', section('## 8.')))

# ---- S1 decodable check of a written face
LET = set('אבמםלשתר')
QAMATS, PATAH, DAGESH, SHIN_DOT, SIN_DOT, SHVA = 'ָ', 'ַ', 'ּ', 'ׁ', 'ׂ', 'ִ'
VOWELS = {QAMATS, PATAH}
def clusters(w):
    out = []
    for ch in unicodedata.normalize('NFC', w):
        if '֑' <= ch <= 'ׇ':
            if not out:
                return None
            out[-1][1].add(ch)
        else:
            out.append([ch, set()])
    return out
def decodable_s1(w):
    if unicodedata.normalize('NFC', w) != w:
        return 'not NFC'
    cl = clusters(w)
    if cl is None:
        return 'starts with a mark'
    if len(cl) == 1:  # a bare letter face, or a CV unit
        ch, marks = cl[0]
        if ch not in LET:
            return f'letter {ch} not in S1'
        if ch == 'ש' and SHIN_DOT not in marks: return 'shin without its dot'
        if ch == 'ב' and DAGESH not in marks: return 'soft bet (S7)'
        if marks - {QAMATS, PATAH, DAGESH, SHIN_DOT}: return 'a mark not in S1'
        return None
    for i, (ch, marks) in enumerate(cl):
        last = i == len(cl) - 1
        if ch == 'ה':
            if not (last and QAMATS in cl[i - 1][1] and not marks):
                return 'ה not as final ָה'
            continue
        if ch == 'א' and last and not marks and (cl[i - 1][1] & VOWELS):
            continue  # silent final alef after a vowel
        if ch not in LET:
            return f'letter {ch} not in S1'
        if ch == 'ם' and not last: return 'final mem inside a word'
        if ch == 'מ' and last: return 'non-final mem at the end'
        if ch == 'ש' and SHIN_DOT not in marks: return 'shin without its dot'
        if SIN_DOT in marks: return 'sin (S7)'
        if ch == 'ב' and DAGESH not in marks: return 'soft bet (S7)'
        if marks - {QAMATS, PATAH, DAGESH, SHIN_DOT}: return 'a mark not in S1: ' + repr(marks)
        if not last and not (marks & VOWELS): return 'a letter with no vowel inside the word (shva is S3)'
    return None

# ---- items
SKILL_OF = {'5.1': 'HEB-B-24.S1', '5.2': 'HEB-B-14.S1', '5.3': 'HEB-B-15.S1', '5.4': 'HEB-B-24.S1',
            '5.5': None, '5.6': 'HEB-B-26.S1', '5.7': 'HEB-B-19', '5.8': 'HEB-B-20'}  # 5.5 B-25.S1 retired
items = {}
for k, body in sec.items():
    m = re.match(r'### (5\.\d) ', k)
    if not m:
        continue
    skill = SKILL_OF[m.group(1)]
    if skill is None:
        if re.search(r'^\| B-\d\d\.', body, re.M): err(f'section {k} is retired but holds items')
        continue
    if skill not in syl_skills:
        err(f'skill {skill} not in the syllabus')
    hdr = re.search(r'HEB-B-\d\d(\.S1)?', k)
    if m.group(1) != '5.1' and (not hdr or hdr.group(0) != skill):
        err(f'section {k} names {hdr and hdr.group(0)}, expected {skill}')
    for line in body.splitlines():
        mm = re.match(r'^\| (B-\d\d\.(?:i?\d+))( [PC])? \|', line)
        if not mm:
            continue
        cells = [c.strip() for c in line.strip().strip('|').split('|')]
        items[mm.group(1)] = dict(skill=skill, kind=(mm.group(2) or '').strip(), cells=cells, line=line, sec=m.group(1))

# tags, clips, pics, forms, faces per item
tag_uses = Counter()
for iid, it in items.items():
    line = it['line']
    for t in re.findall(r'\[([A-Z][A-Z-]+)(?::[^\]]*)?\]', line):
        tag = 'M-HEB-' + t
        tag_uses[tag] += 1
        if tag in PROPOSED:
            continue
        if tag not in syl_tags: err(f'{iid}: {tag} not in syllabus §5')
        if tag not in frame_tags: err(f'{iid}: {tag} not in the frame catalogue')
    for c in re.findall(r'(heb-[ab]-[a-z0-9-]+)', line):
        if c not in defined and c not in csv_ids:
            err(f'{iid}: clip {c} not defined')
        if c.startswith('heb-a-') and c not in csv_ids:
            err(f'{iid}: reused clip {c} not in pronunciation.csv')
    for p in re.findall(r'pic\.([a-z0-9-]+)', line):
        if p not in pics_on_disk and p not in new_pics:
            err(f'{iid}: picture {p} neither drawn nor in the new list')
        if p in pics_on_disk and p in new_pics:
            err(f'{iid}: picture {p} listed as new but exists')
    for f in re.findall(r'hebrew-print\.([a-z-]+)', line):
        if 'hebrew-print.' + f not in forms:
            err(f'{iid}: form hebrew-print.{f} not in the stroke set')
    faces = re.findall(r'txt:([֐-׿]+)', line)
    it['faces'] = faces
    for w in faces:
        if all('֑' <= ch <= 'ׇ' for ch in w):
            continue  # a lone sign as an LS05 part
        r = decodable_s1(w)
        if r: err(f'{iid}: face {w}: {r}')
    it['mirrors'] = re.findall(r'letter-mirror-([a-z-]+)', line)

# choice items: 3 options, two tagged distractors, every distractor tagged
for iid, it in items.items():
    c = it['cells']
    if it['sec'] in ('5.2', '5.3', '5.7', '5.8'):
        tmpl = c[1]
        dis = c[4]
        if 'explore' in tmpl:
            continue
        if 'match_pairs' in tmpl or 'tap-all' in tmpl or 'LS06' in tmpl:
            n = len(re.findall(r'\[[A-Z-]+', dis))
            if n < 2: err(f'{iid}: fewer than 2 tagged wrong choices')
            if 'tap-all' in tmpl:
                m = re.search(r'a row of (\d)', tmpl)
                if not m or int(m.group(1)) > 6: err(f'{iid}: tap-all row size')
            continue
        segs = [s for s in dis.split(' · ') if s.strip()]
        if len(segs) != 2: err(f'{iid}: {len(segs)} distractors, expected 2 (3 choices)')
        for s in segs:
            if not re.search(r'\[[A-Z-]+', s): err(f'{iid}: untagged distractor: {s}')

# templates and modes (L5 §5)
MODES = {'LS01': ['(a)', '(b)', '(c)', '(d)', 'match_pairs', 'tap-all'], 'LS05': ['explore', 'make'], 'LS06': ['units']}
for iid, it in items.items():
    t = it['cells'][1]
    if it['sec'] in ('5.4', '5.5', '5.6'):
        mode = t.split(',')[0].strip()
        if mode not in ('trace', 'copy', 'memory'): err(f'{iid}: LS02 mode {mode}')
        if mode == 'memory' and 'cue:' not in t: err(f'{iid}: memory without a cue')
        if mode == 'copy' and 'model:' not in t: err(f'{iid}: copy without a model')
        continue
    if it['sec'] == '5.1':
        continue
    fam = t.split()[0]
    if fam not in MODES or not any(m in t for m in MODES[fam]):
        err(f'{iid}: template {t} not in L5 §5')

# letters shown only after their introduction (section 7)
INTRO = {'B-24.i1': 'מ', 'B-24.i2': 'ל', 'B-24.i3': 'ש', 'B-24.i4': 'ר', 'B-24.i5': 'א', 'B-24.i6': 'ב', 'B-24.i7': 'ת', 'B-24.i8': 'ם'}
MIRROR_L = {'bet': 'ב', 'resh': 'ר', 'mem': 'מ', 'resh-secular': 'ר'}
FORM_L = {'mem': 'מ', 'lamed': 'ל', 'shin': 'ש', 'resh': 'ר', 'alef': 'א', 'bet': 'ב', 'tav': 'ת', 'mem-final': 'ם'}
known, seen_items = set(), set()
for line in section('## 7.').splitlines():
    m = re.match(r'^\| (V\d) \|', line)
    if not m:
        continue
    ids = re.findall(r'B-\d\d\.(?:i?\d+)', line)
    for i in ids:
        if i in INTRO: known.add(INTRO[i])
    for i in ids:
        if i not in items: err(f'{m.group(1)}: {i} is not an item'); continue
        seen_items.add(i)
        it = items[i]
        shown = set()
        for w in it['faces']:
            for ch in w:
                if ch in 'אבגדהוזחטיכלמנסעפצקרשתםןךףץ':
                    shown.add(ch)
        if 'ה' in shown and any(w.endswith('ָה') for w in it['faces']): shown.discard('ה')
        shown |= {MIRROR_L[x] for x in it['mirrors']}
        if it['sec'] in ('5.4', '5.5', '5.6'):
            for f in re.findall(r'hebrew-print\.([a-z-]+)', it['cells'][3]):
                shown.add(FORM_L[f])
        if i not in INTRO and not shown <= known:
            err(f'{i} in {m.group(1)} shows {"".join(sorted(shown - known))} before its introduction')
missing = set(items) - seen_items
if missing: err('items in no visit: ' + ', '.join(sorted(missing)))

# counts
# a trace node's items are practice under E-1, not scored
scored = [i for i in items if '.i' not in i and items[i]['cells'][1].find('explore') < 0 and items[i]['sec'] != '5.4']
practice = [i for i in items if items[i]['sec'] == '5.4']
by_skill = Counter(items[i]['skill'] for i in scored)
checks = [i for i in scored if items[i]['kind'] == 'C']
new_clips = sorted(c for c in defined if c.startswith('heb-b-'))
used_clips = set()
for it in items.values():
    used_clips |= set(re.findall(r'(heb-[ab]-[a-z0-9-]+)', it['line']))
# lines of section 4 used only in ladders are fine; report unused new clips
sec5 = doc.split('## 5. The items')[1].split('## 6.')[0]
unused = [c for c in new_clips if c not in sec5]
all_ids_in_doc = {c for c in re.findall(r'(heb-[ab]-[a-z0-9]+(?:-[a-z0-9]+)*)', doc)}
all_ids_in_doc.discard('heb-b-w-shamar')  # named in §9 as not needed
undefined_in_doc = sorted(c for c in all_ids_in_doc if c not in defined and c not in csv_ids)

# singular imperatives (address must be plural)
SING = ['גַּע ', 'גְּעִי', 'כְּתֹב', 'כִּתְבִי', 'קְרָא ', 'קִרְאִי', 'הַקְשֵׁב ', 'הַקְשִׁיבִי', 'הִסְתַּכֵּל ', 'סוֹבֵב ', 'בְּנֵה', 'אַתָּה ', 'אַתְּ ']
lines4 = re.findall(r'^\| `heb-b-[^`]+` \| ([^|]+) \|', section('## 4.'), re.M)
for l in lines4:
    for s in SING:
        if s in l + ' ':
            err(f'singular address in: {l}')
for l in lines4:
    for w in re.findall(r'[֐-׿]+', l):
        if unicodedata.normalize('NFC', w) != w:
            err(f'not NFC: {w}')

tmpl = Counter()
for i, it in items.items():
    t = it['cells'][1]
    if it['sec'] == '5.1': tmpl['LS02 intro'] += 1; continue
    if it['sec'] in ('5.4', '5.5', '5.6'): tmpl['LS02 ' + t.split(',')[0]] += 1; continue
    for k in ['(a)', '(b)', '(c)', '(d)', 'match_pairs', 'tap-all', 'explore', 'make', 'units']:
        if k in t: tmpl[t.split()[0] + ' ' + k] += 1
print('templates:', dict(sorted(tmpl.items())))
print('new clips by kind:', dict(Counter(c.split('-')[2] for c in new_clips)))
print('items:', len(items), '| scored:', len(scored), '| practice traces (B-24.S1):', len(practice), '| teaching screens:', len(items) - len(scored) - len(practice), '| checks:', len(checks))
print('by skill:', dict(sorted(by_skill.items())))
print('tags used:', dict(sorted(tag_uses.items())))
print('tags not in the catalogue (proposed):', sorted(t for t in tag_uses if t in PROPOSED))
print('new clip ids defined:', len(new_clips), '| reused heb-a ids in items:', len({c for c in used_clips if c.startswith("heb-a-")}))
print('clip ids in the whole doc:', len(all_ids_in_doc), '| undefined:', undefined_in_doc)
print('new clips not used anywhere in §5:', unused)
print('pictures used:', len({p for it in items.values() for p in re.findall(r"pic\.([a-z0-9-]+)", it["line"])}),
      '| new listed:', len(new_pics), sorted(new_pics))
# E-1 (writing-mastery §8): the trace node has no check and a start-dot trace for every letter; the writing node has no trace item
trace_forms = {f for i in practice for f in re.findall(r'hebrew-print\.([a-z-]+)', items[i]['cells'][3]) if 'start dot' in items[i]['cells'][1] and 'word' not in items[i]['cells'][1]}
if trace_forms != set(FORM_L): err(f'B-24.S1: no start-dot trace for {sorted(set(FORM_L) - trace_forms)}')
for i in practice:
    if items[i]['kind'] == 'C': err(f'{i}: a trace node has no check (E-1)')
    if not items[i]['cells'][1].startswith('trace'): err(f'{i}: a trace node holds only trace items')
for i, it in items.items():
    if it['sec'] == '5.6':
        mode = it['cells'][1].split(',')[0].strip()
        if mode == 'trace': err(f'{i}: a writing node has no trace item (E-1)')
        if it['kind'] == 'C' and mode != 'memory': err(f'{i}: a check of a writing node is a memory item (E-1)')
cues = {re.search(r'cue: (sound|name)', items[i]['cells'][1]).group(1) for i in items if items[i]['sec'] == '5.6' and 'memory' in items[i]['cells'][1]}
if cues != {'sound', 'name'}: err('B-26.S1: memory items need both cues (E-1)')
print('instruction lines checked for plural address:', len(lines4))
print('ERRORS:', len(errors))
for e in errors: print('  -', e)
