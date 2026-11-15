"""Splits the voice ids of the release into whole GROUPS a child meets together, in the order of the first tests, and writes
docs/audio/voicing-groups.json (the manifest a `--group` option of voice_gen reads) plus a table of characters for each group.

    python tools/voicing_groups.py            # writes the manifest, prints the table
    python tools/voicing_groups.py --check    # prints only; exit 1 if the manifest on disk is out of date

Free: reads files only. A group is: the core lines; the end-of-lesson celebrations; and for each land (a skill domain) and band the
lines of its activities and lessons. A line that several groups use belongs to the EARLIEST group in the order below (so it is
voiced in the first batch that needs it, and a later batch never has to say it again). Characters are Unicode code points of the
master table's voice_text, as voice_gen counts them. The numbers are for ONE narrator.
"""
import csv
import glob
import json
import os
import sys

ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), '..')
OUT = os.path.join(ROOT, 'docs', 'audio', 'voicing-groups.json')
csv.field_size_limit(10 ** 9)
DOMAINS = ['numbers', 'colors', 'shapes', 'logic', 'cs', 'math']          # the order of the lands in the first tests
SKILL_DOMAIN = {'NUM': 'numbers', 'COL': 'colors', 'SHP': 'shapes', 'LOG': 'logic', 'CS': 'cs', 'MATH': 'math'}
ORDER = (['core', 'celebrate'] + ['%s-A' % d for d in DOMAINS] + ['%s-B' % d for d in DOMAINS] + ['%s-C' % d for d in DOMAINS])


def master():
    rows = {}
    with open(os.path.join(ROOT, 'docs', 'review', 'hebrew-master.csv'), encoding='utf-8-sig') as fh:
        for r in csv.DictReader(fh):
            rows[(r['source'], r['id'])] = r
    return rows


def main():
    m = master()
    uses = {}  # vo id -> {group names}
    where = {}  # vo id -> [(source, id)]

    def walk(node, path, name, group):
        p = path + '.' if path else ''
        if isinstance(node, dict):
            vo, cap = node.get('vo'), node.get('caption')
            if isinstance(vo, str) and vo.startswith('vo:') and isinstance(cap, list) and cap and isinstance(cap[0], dict) \
                    and isinstance(cap[0].get('v'), str):
                g = 'celebrate' if vo.startswith('vo:celebrate.') else group
                uses.setdefault(vo, set()).add(g)
                where.setdefault(vo, []).append((name, p + 'caption.0.v'))
            for k, v in node.items():
                walk(v, p + k, name, group)
        elif isinstance(node, list):
            for i, v in enumerate(node):
                walk(v, p + str(i), name, group)

    for f in sorted(glob.glob(os.path.join(ROOT, 'content', 'starter', '*.json'))):
        b = os.path.basename(f)
        if not b.startswith(('activity.', 'lesson.')):
            continue
        with open(f, encoding='utf-8') as fh:
            d = json.load(fh)
        if b.startswith('activity.'):
            dom = d.get('domain')
        else:
            sk = (d.get('skills') or [''])[0]
            dom = SKILL_DOMAIN.get(sk.split('-')[0])
        group = '%s-%s' % (dom, d.get('band'))
        walk(d, '', b, group)
    with open(os.path.join(ROOT, 'content', 'lines', 'core.he.json'), encoding='utf-8') as fh:
        for l in json.load(fh)['lines']:
            vo = 'vo:' + l['id']
            uses.setdefault(vo, set()).add('core')
            where.setdefault(vo, []).append(('content/lines/core.he.json', l['id']))
    groups = {g: [] for g in ORDER}
    unknown = []
    texts = {}
    for vo, gs in sorted(uses.items()):
        known = [g for g in ORDER if g in gs]
        if not known:
            unknown.append(vo)
            continue
        groups[known[0]].append(vo)
        ts = {m[w]['voice_text'] for w in where[vo] if w in m and m[w]['voice_text'].strip()}
        texts[vo] = sorted(ts)[0] if ts else ''
    manifest = {'schema': 'voicing-groups/v1', 'note': 'made by tools/voicing_groups.py; one narrator; chars are of voice_text',
                'groups': [{'name': g, 'ids': groups[g], 'chars': sum(len(texts[v]) for v in groups[g])} for g in ORDER if groups[g]]}
    text = json.dumps(manifest, ensure_ascii=False, indent=1) + '\n'
    sys.stdout.reconfigure(encoding='utf-8')
    total = 0
    print('%-12s %6s %9s' % ('group', 'ids', 'chars'))
    for g in manifest['groups']:
        print('%-12s %6d %9d' % (g['name'], len(g['ids']), g['chars']))
        total += g['chars']
    print('%-12s %6d %9d' % ('total', sum(len(g['ids']) for g in manifest['groups']), total))
    if unknown:
        print('ids with no group:', unknown[:10])
    if '--check' in sys.argv:
        old = open(OUT, encoding='utf-8').read() if os.path.exists(OUT) else ''
        return 0 if old == text else 1
    with open(OUT, 'w', encoding='utf-8', newline='\n') as fh:
        fh.write(text)
    return 0


if __name__ == '__main__':
    sys.exit(main())
