"""Writes docs/review/hebrew-review.md and .csv: every Hebrew text that still needs a person's review."""
import csv
import glob
import json
import os
import re

os.chdir(os.path.join(os.path.dirname(os.path.abspath(__file__)), '..'))
HEB = re.compile('[\u0590-\u05ff]')
rows = []  # (group, source, id, text, status, kind)


def has_he(s):
    return bool(HEB.search(s))


def has_nikud(s):
    return any('\u05b0' <= c <= '\u05c7' for c in s)


# 1. app strings (He class)
src = open('app/lib/strings/he.dart', encoding='utf-8').read()
for m in re.finditer(r"static const Str (\w+) = Str\(\s*'((?:[^'\\]|\\.)*)'(\s*,\s*nikud:\s*true)?", src):
    name, text, nk = m.group(1), m.group(2), m.group(3)
    text = re.sub(r'\\u([0-9a-fA-F]{4})', lambda u: chr(int(u.group(1), 16)), text.replace(chr(92) + "'", "'"))
    rows.append(('1. App screens and buttons', 'app/lib/strings/he.dart', name, text,
                 'needs-editor', 'child (nikud)' if nk else 'adult'))

# 2. core voice lines
core = json.load(open('content/lines/core.he.json', encoding='utf-8'))
for l in core['lines']:
    rows.append(('2. Core voice lines (spoken by every friend)', 'content/lines/core.he.json', l['id'], l['text'],
                 core.get('review', 'needs-editor'), 'child (nikud)'))

# 3. starter content: every Hebrew string in the JSON files
def walk(o, path, out):
    if isinstance(o, dict):
        for k, v in o.items():
            walk(v, path + [k], out)
    elif isinstance(o, list):
        for i, v in enumerate(o):
            walk(v, path + [str(i)], out)
    elif isinstance(o, str) and has_he(o):
        out.append(('.'.join(path), o))


for f in sorted(glob.glob('content/starter/*.json')):
    if os.path.basename(f) == 'pack.json':
        continue
    d = json.load(open(f, encoding='utf-8'))
    found = []
    walk(d, [], found)
    status = d.get('review', 'needs-editor') if isinstance(d, dict) else 'needs-editor'
    for p, t in found:
        rows.append(('3. Lesson content (skills, activities, misconceptions)', os.path.basename(f), p, t, status,
                     'child (nikud)' if has_nikud(t) else 'adult/title'))

# 4. tutor lines
for f in sorted(glob.glob('content/tutor-lines/*.json')):
    d = json.load(open(f, encoding='utf-8'))
    for l in d:
        rows.append(('4. Reviewed helper (tutor) lines', os.path.basename(f),
                     '%s / mistake %s / hint %s / band %s' % (l['item'], l['mistake'], l['hint'], l['band']),
                     l['say'], l.get('review', 'needs-editor'), 'child (nikud)' if has_nikud(l['say']) else 'child'))

# 5. word lists
for f, label in (('app/lib/speech/alert_lists.dart', '5. Alert word lists (for an editor and someone who works with children)'),
                 ('app/lib/speech/lexicon.dart', '6. Helper lexicon (the words the AI helper may use)')):
    t = open(f, encoding='utf-8').read()
    words = sorted(set(re.findall(r"'([\u0590-\u05ff][^']*)'", t)))
    for w in words:
        rows.append((label, f, '', w, 'needs-editor', 'word'))

groups = []
for r in rows:
    if r[0] not in groups:
        groups.append(r[0])

os.makedirs('docs/review', exist_ok=True)
with open('docs/review/hebrew-review.csv', 'w', encoding='utf-8-sig', newline='') as fh:
    w = csv.writer(fh)
    w.writerow(['group', 'source', 'id', 'text', 'status', 'kind', 'correction (fill in)', 'comment'])
    for r in rows:
        w.writerow(list(r) + ['', ''])

out = ['# Hebrew texts waiting for review', '',
       'Made by `tools/export-hebrew-review.py` on 2026-10-28 from the repository as it is now (M8 merged). '
       'Every text below is a draft written by Claude. Nothing is approved until you say so.', '',
       'How to review: open `hebrew-review.csv` in Excel or Google Sheets, write a fix in **correction** (leave it empty if the '
       'text is fine) and notes in **comment**, then send the file back. Claude applies the fixes, marks the texts approved and '
       'voices again only the lines that changed (the cost is shown first, as always).', '',
       'What to look at: spelling and niqqud; grammar and agreement (plural, neutral, no line says the child\'s name or '
       'the speaker\'s gender); a word a 3 to 8 year old knows; sentences short enough to say in one breath; nothing '
       'that scolds, frightens or compares.', '',
       '| Group | Texts |', '|---|---|']
for g in groups:
    out.append('| %s | %d |' % (g, sum(1 for r in rows if r[0] == g)))
out.append('| **Total** | **%d** |' % len(rows))
out.append('')
for g in groups:
    out.append('## ' + g)
    out.append('')
    gr = [r for r in rows if r[0] == g]
    if gr[0][5] == 'word':
        out.append('Source: `%s`. One word per entry.' % gr[0][1])
        out.append('')
        out.append(' · '.join(r[3] for r in gr))
        out.append('')
        continue
    out.append('| Source | Id | Text | Status |')
    out.append('|---|---|---|---|')
    for r in gr:
        out.append('| %s | %s | %s | %s |' % (r[1], r[2], r[3].replace('|', '/'), r[4]))
    out.append('')
open('docs/review/hebrew-review.md', 'w', encoding='utf-8', newline='\n').write('\n'.join(out))
print(len(rows), [(g, sum(1 for r in rows if r[0] == g)) for g in groups])
