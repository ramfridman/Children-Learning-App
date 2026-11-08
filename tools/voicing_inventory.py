"""Counts every line the release voicing would say, from the sources and the master table. Free: reads files, writes nothing.

    python tools/voicing_inventory.py

It repeats what `dart run tool/voice_gen.dart plan` counts (the `vo:` ids of content/starter and the core lines, with the
voice_text of the master table) but for EVERY status, so the owner can see the size of the whole run before the rows are
approved, and then the language packs (content/languages/*/voice-plan.json). The paid tool prints the number that counts; this
script is for the plan (docs/audio/release-voicing-plan.md). A character is a Unicode code point, as voice_gen counts them.
"""
import collections
import csv
import glob
import json
import os
import sys

ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), '..')
csv.field_size_limit(10 ** 9)
OWN = ['core.greeting.hello', 'core.greeting.start', 'core.celebrate.well', 'core.placement.done', 'core.goodbye.next',
       'core.ceremony.bronze', 'core.ceremony.silver', 'core.ceremony.gold', 'core.ceremony.medal']
APPROVED = ('owner-approved', 'voice-ready', 'voiced')


def master():
    rows = {}
    with open(os.path.join(ROOT, 'docs', 'review', 'hebrew-master.csv'), encoding='utf-8-sig') as fh:
        for r in csv.DictReader(fh):
            k = (r['source'], r['id'])
            if k in rows and (rows[k]['voice_text'], rows[k]['status']) != (r['voice_text'], r['status']):
                rows[k] = dict(r, status='duplicate')
            else:
                rows[k] = r
    return rows


def places():
    out = collections.defaultdict(list)

    def walk(node, path, name):
        p = path + '.' if path else ''
        if isinstance(node, dict):
            vo, cap = node.get('vo'), node.get('caption')
            if isinstance(vo, str) and vo.startswith('vo:') and isinstance(cap, list) and cap and isinstance(cap[0], dict) \
                    and isinstance(cap[0].get('v'), str):
                out[vo].append((name, p + 'caption.0.v'))
            for k, v in node.items():
                walk(v, p + k, name)
        elif isinstance(node, list):
            for i, v in enumerate(node):
                walk(v, p + str(i), name)

    for f in sorted(glob.glob(os.path.join(ROOT, 'content', 'starter', '*.json'))):
        b = os.path.basename(f)
        if b.startswith(('activity.', 'lesson.')):
            with open(f, encoding='utf-8') as fh:
                walk(json.load(fh), '', b)
    with open(os.path.join(ROOT, 'content', 'lines', 'core.he.json'), encoding='utf-8') as fh:
        for l in json.load(fh)['lines']:
            out['vo:' + l['id']].append(('content/lines/core.he.json', l['id']))
    return out


def main():
    m = master()
    ids = {}
    problems = []
    for vo, where in places().items():
        texts, sts = set(), set()
        for w in where:
            row = m.get(w)
            if row is None:
                problems.append((vo, 'no master row'))
                continue
            sts.add(row['status'])
            if row['voice_text'].strip():
                texts.add(row['voice_text'])
        if len(texts) != 1:
            problems.append((vo, '%d different voice texts' % len(texts)))
        if texts:
            ids[vo] = (sorted(texts)[0], sts)
    chars = sum(len(t) for t, _ in ids.values())
    distinct = {t for t, _ in ids.values()}
    by = collections.Counter()
    ch = collections.Counter()
    for vo, (t, s) in ids.items():
        k = 'approved' if s <= set(APPROVED) else ('proposed' if 'proposed' in s else 'text-ready')
        by[k] += 1
        ch[k] += len(t)
    print('Hebrew narrators (starter pack + core lines): %d voice ids, %d characters for each narrator' % (len(ids), chars))
    print('  by status: ' + ', '.join('%s %d ids / %d chars' % (k, by[k], ch[k]) for k in sorted(by)))
    print('  distinct texts %d / %d chars (what a once-per-text run would send)' % (len(distinct), sum(map(len, distinct))))
    print('  blocked until fixed: %s' % (problems or 'none'))
    own = [ids['vo:' + i][0] for i in OWN if 'vo:' + i in ids]
    print('  a friend\'s own lines: %d lines, %d characters' % (len(own), sum(map(len, own))))
    for c in ('eng', 'rus', 'heb'):
        with open(os.path.join(ROOT, 'content', 'languages', c, 'voice-plan.json'), encoding='utf-8') as fh:
            d = json.load(fh)
        fl = [x['voice'] for x in d['frameLines'] if x.get('voice')]
        tc = [(x.get('say') or x['shown']) for x in d['targetClips']]
        print('%s pack: %d Hebrew frame lines %d chars; %d target clips %d chars (%d distinct texts, %d chars); %d cut clips' % (
            c, len(fl), sum(map(len, fl)), len(tc), sum(map(len, tc)), len(set(tc)), sum(len(t) for t in set(tc)),
            len(d.get('cutClips', []))))
    return 0


if __name__ == '__main__':
    sys.stdout.reconfigure(encoding='utf-8')
    sys.exit(main())
