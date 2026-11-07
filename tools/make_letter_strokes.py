"""F6: the letter stroke data of the Languages courses (docs/languages/frame.md section 2.1 F6, template LS02; format in
docs/languages/strokes.md). One generator for the four sets:

    python tools/make_letter_strokes.py            # writes content/languages/strokes/<set>.json and checks every form
    python tools/make_letter_strokes.py --sheet    # also renders one contact sheet per set (headless Chrome)
    python tools/make_letter_strokes.py --fit      # also measures each print form against its font, in headless Chrome

Sets: latin (English, 26 small and 26 capital print letters), cyrillic (Russian, 33 capitals and 33 small print letters),
hebrew-print (22 letters and 5 finals) and hebrew-script (the same 27 in the school script, by direction group). The
paths themselves are in tools/strokes_latin.py, strokes_cyrillic.py and strokes_hebrew.py, each with its references at
the top. A path is written in the units of its font (1000 to the em, y up from the baseline, x from the glyph origin) so
it can be read against the font's own measures; this file moves it into the trace box (100 by 100, y down) and centres the
letter on the box's middle.

Every form is checked by script (check_form): the strokes stay inside the box, every stroke but a dot or a short mark is
long enough to trace, each set's start rule holds (or the stroke says why not), no stroke goes back over itself or crosses
itself unless its data says the model does (retrace, loop), and the letter sits on its guide lines. With --fit, every
stroke of a print letter must lie inside the ink of the letter as the app draws it (Nitznutz Letters Bold, Heebo 700),
and the strokes together must cover that ink, so the letter a child traces is the letter on the tile.

Deterministic: the same input writes the same files. Standard library only (Chrome for the sheets and --fit).
"""
import json
import math
import os
import re
import subprocess
import sys

TOOLS = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.normpath(os.path.join(TOOLS, '..'))
OUT = os.path.join(ROOT, 'content', 'languages', 'strokes')
SHEETS = os.path.join(ROOT, 'docs', 'design', 'languages')
FONTS = os.path.join(ROOT, 'app', 'assets', 'fonts')
CHROME = r'C:\Program Files\Google\Chrome\Application\chrome.exe'
SCHEMA = 'nitznutz.strokes/1'
INK = 9           # the width of the ink line in box units (fonts.md section 5: about 9 percent of the box)
EDGE = 4          # a centre line keeps this far from the box edge, so the ink stays inside
MIN_TRACE = 25    # the trace validator's shortest stroke (app/lib/content/pack_validation.dart)
MAX_POINTS = 60   # the trace schema's longest polyline (app/lib/content/schemas.dart)
MAX_STROKES = 6
MAX_BUILDS = 4    # the other right builds of a letter (tools/strokes_alternates.py), besides the model's own

sys.path.insert(0, TOOLS)


# ---------------------------------------------------------------------------------------------------- the path language
# A stroke is a string of commands in font units: M x y, L x y, C x1 y1 x2 y2 x y, and A cx cy rx ry a0 a1 (an elliptical
# arc about its centre, angles in degrees, counter-clockwise as seen when a0 < a1; drawn as cubic pieces). An arc that does
# not start where the pen is gets a straight line to its start first, so a path never jumps.

def _arc_cubics(cx, cy, rx, ry, a0, a1):
    n = max(1, int(math.ceil(abs(a1 - a0) / 90.0 - 1e-9)))
    out = []
    for i in range(n):
        t0 = math.radians(a0 + (a1 - a0) * i / n)
        t1 = math.radians(a0 + (a1 - a0) * (i + 1) / n)
        k = 4.0 / 3.0 * math.tan((t1 - t0) / 4.0)
        p0 = (cx + rx * math.cos(t0), cy + ry * math.sin(t0))
        p3 = (cx + rx * math.cos(t1), cy + ry * math.sin(t1))
        p1 = (p0[0] - k * rx * math.sin(t0), p0[1] + k * ry * math.cos(t0))
        p2 = (p3[0] + k * rx * math.sin(t1), p3[1] - k * ry * math.cos(t1))
        out.append((p0, p1, p2, p3))
    return out


def parse(path):
    """The segments of a path, each ('L', p0, p1) or ('C', p0, p1, p2, p3), in font units."""
    tok = re.findall(r'[MLCA]|-?\d+(?:\.\d+)?', path)
    segs, pen, i = [], None, 0
    while i < len(tok):
        cmd = tok[i]
        i += 1
        nums = []
        while i < len(tok) and tok[i] not in 'MLCA':
            nums.append(float(tok[i]))
            i += 1
        if cmd == 'M':
            pen = (nums[0], nums[1])
            nums = nums[2:]
            cmd = 'L'
        if cmd == 'L':
            for k in range(0, len(nums), 2):
                p = (nums[k], nums[k + 1])
                segs.append(('L', pen, p))
                pen = p
        elif cmd == 'C':
            for k in range(0, len(nums), 6):
                p1, p2, p3 = (nums[k], nums[k + 1]), (nums[k + 2], nums[k + 3]), (nums[k + 4], nums[k + 5])
                segs.append(('C', pen, p1, p2, p3))
                pen = p3
        elif cmd == 'A':
            for k in range(0, len(nums), 6):
                cubics = _arc_cubics(*nums[k:k + 6])
                if pen is not None and math.dist(pen, cubics[0][0]) > 0.5:
                    segs.append(('L', pen, cubics[0][0]))
                for c in cubics:
                    segs.append(('C',) + c)
                pen = cubics[-1][3]
    if not segs:
        raise ValueError('empty path: %r' % path)
    return segs


def _bez(p0, p1, p2, p3, t):
    u = 1 - t
    return (u ** 3 * p0[0] + 3 * u * u * t * p1[0] + 3 * u * t * t * p2[0] + t ** 3 * p3[0],
            u ** 3 * p0[1] + 3 * u * u * t * p1[1] + 3 * u * t * t * p2[1] + t ** 3 * p3[1])


def dense(segs, step=0.5):
    """Points every `step` box units (or closer) along the segments, which are already in box units."""
    pts = [segs[0][1]]
    for s in segs:
        if s[0] == 'L':
            n = max(1, int(math.ceil(math.dist(s[1], s[2]) / step)))
            pts += [(s[1][0] + (s[2][0] - s[1][0]) * k / n, s[1][1] + (s[2][1] - s[1][1]) * k / n) for k in range(1, n + 1)]
        else:
            rough = math.dist(s[1], s[2]) + math.dist(s[2], s[3]) + math.dist(s[3], s[4])
            n = max(4, int(math.ceil(rough / step)))
            pts += [_bez(s[1], s[2], s[3], s[4], k / n) for k in range(1, n + 1)]
    return pts


def length(pts):
    return sum(math.dist(pts[i - 1], pts[i]) for i in range(1, len(pts)))


def _dp(pts, eps):
    """Douglas-Peucker: keeps the corners exactly and drops the points a straight run does not need."""
    if len(pts) < 3:
        return list(pts)
    a, b = pts[0], pts[-1]
    dx, dy = b[0] - a[0], b[1] - a[1]
    n = math.hypot(dx, dy)
    best, idx = -1.0, 0
    for i in range(1, len(pts) - 1):
        p = pts[i]
        d = math.dist(p, a) if n < 1e-6 else abs(dy * p[0] - dx * p[1] + b[0] * a[1] - b[1] * a[0]) / n
        if d > best:
            best, idx = d, i
    if best <= eps:
        return [a, b]
    return _dp(pts[:idx + 1], eps)[:-1] + _dp(pts[idx:], eps)


def polyline(pts):
    """The trace template's polyline: whole box units, 2 to 60 points, no repeated point."""
    eps = 0.45
    while True:
        out = []
        for p in _dp(pts, eps):
            q = [int(round(p[0])), int(round(p[1]))]
            if not out or q != out[-1]:
                out.append(q)
        if len(out) == 1:
            out.append([out[0][0], out[0][1] + 1])
        if len(out) <= MAX_POINTS:
            return out
        eps *= 1.3


# ---------------------------------------------------------------------------------------------------- moves (directions)
COMPASS = ['right', 'down-right', 'down', 'down-left', 'left', 'up-left', 'up', 'up-right']


def compass(dx, dy):
    """The direction of a move in the box (y down) in plain words."""
    a = math.degrees(math.atan2(dy, dx)) % 360
    return COMPASS[int(((a + 22.5) % 360) // 45)]


def moves(segs):
    """The stroke's moves, in order: a straight run by its direction, a curve by its turn (cw or ccw as seen on the
    screen); a curve that hardly turns counts as straight. Repeats are merged."""
    out = []
    for s in segs:
        if s[0] == 'L':
            if math.dist(s[1], s[2]) < 0.5:
                continue
            m = compass(s[2][0] - s[1][0], s[2][1] - s[1][1])
        else:
            pts = dense([s], 0.5)
            turn = 0.0
            for i in range(2, len(pts)):
                a = math.atan2(pts[i - 1][1] - pts[i - 2][1], pts[i - 1][0] - pts[i - 2][0])
                b = math.atan2(pts[i][1] - pts[i - 1][1], pts[i][0] - pts[i - 1][0])
                turn += (b - a + math.pi) % (2 * math.pi) - math.pi
            if abs(math.degrees(turn)) < 30:
                m = compass(s[4][0] - s[1][0], s[4][1] - s[1][1])
            else:
                m = 'cw' if turn > 0 else 'ccw'   # y down: a positive turn is clockwise on the screen
        if not out or out[-1] != m:
            out.append(m)
    return out


# ---------------------------------------------------------------------------------------------------- geometry checks
def _seg_cross(a, b, c, d):
    def orient(p, q, r):
        return (q[0] - p[0]) * (r[1] - p[1]) - (q[1] - p[1]) * (r[0] - p[0])
    o1, o2, o3, o4 = orient(a, b, c), orient(a, b, d), orient(c, d, a), orient(c, d, b)
    return o1 * o2 < 0 and o3 * o4 < 0


def self_crossings(pts):
    """Places where a stroke crosses its own line (a loop). Uses a 1-unit resampling; neighbouring pieces never count."""
    q = resample(pts, 1.0)
    hits = []
    for i in range(len(q) - 1):
        for j in range(i + 3, len(q) - 1):
            if _seg_cross(q[i], q[i + 1], q[j], q[j + 1]):
                hits.append(q[i])
    return hits


def retraces(pts, near=1.6, gap=6.0, skip=()):
    """Lengths of the stroke that run back over an earlier part of the same stroke (closer than `near` units to a point
    at least `gap` units earlier along it). A closed shape that only meets its own start is not a retrace, and neither is
    the place where a loop crosses itself (`skip`)."""
    q = resample(pts, 0.5)
    total = 0.5 * (len(q) - 1)
    run = 0.0
    for j in range(len(q)):
        sj = 0.5 * j
        for i in range(0, j):
            si = 0.5 * i
            if sj - si < gap:
                break
            if math.dist(q[i], q[j]) < near and not (si < 4 and sj > total - 4) and                     not any(math.dist(q[j], c) < 4 for c in skip):
                run += 0.5
                break
    return run


def resample(pts, step):
    out = [pts[0]]
    carry = 0.0
    for i in range(1, len(pts)):
        a, b = pts[i - 1], pts[i]
        d = math.dist(a, b)
        t = step - carry
        while t <= d:
            out.append((a[0] + (b[0] - a[0]) * t / d, a[1] + (b[1] - a[1]) * t / d))
            t += step
        carry = d - (t - step)
    if math.dist(out[-1], pts[-1]) > 1e-6:
        out.append(pts[-1])
    return out


# ---------------------------------------------------------------------------------------------------- building a set
class Form:
    """One letter form: `strokes` is a list of (path, options); options may hold kind ('line', 'dot', 'short'), retrace,
    loop, startOk (why the start rule does not apply) and note."""

    def __init__(self, fid, char, strokes, sits, **meta):
        self.id, self.char, self.raw, self.sits, self.meta = fid, char, strokes, sits, meta


def S(path, **opts):
    return (path, opts)


def build_set(spec):
    """spec: a module with SET (the header) and FORMS (Form objects), and its own start rule `start_rule(form, i, stroke)`."""
    head = spec.SET
    s, base = head['em'], head['baseline']
    metrics = head.get('metrics', {})
    forms, problems = [], []
    for f in spec.FORMS:
        segs_font = [parse(p) for p, _ in f.raw]
        if f.char in metrics:
            lft, rgt = metrics[f.char][0], metrics[f.char][1]
        else:
            xs = [p[0] for segs in segs_font for p in dense_font(segs)]
            lft, rgt = min(xs), max(xs)
        mid = (lft + rgt) / 2.0
        k = s / 1000.0

        def tr(p):
            return (50 + (p[0] - mid) * k, base - p[1] * k)
        strokes = []
        for (path, opts), segs in zip(f.raw, segs_font):
            bsegs = [(g[0],) + tuple(tr(p) for p in g[1:]) for g in segs]
            pts = dense(bsegs)
            st = {'kind': opts.get('kind', 'line')}
            st['d'] = ' '.join(_fmt(g) for g in _join(bsegs))
            st['points'] = polyline(pts)
            st['start'] = st['points'][0]
            st['end'] = st['points'][-1]
            st['moves'] = moves(bsegs) if st['kind'] == 'line' else ['dot' if st['kind'] == 'dot' else moves(bsegs)[0]]
            if opts.get('retrace'):
                st['retrace'] = True
            if opts.get('loop'):
                st['loop'] = True
            if opts.get('startOk'):
                st['startOk'] = opts['startOk']
            if opts.get('note'):
                st['note'] = opts['note']
            st['_dense'] = pts
            strokes.append(st)
        form = {'id': f.id, 'char': f.char}
        for key in ('name', 'case', 'final', 'group', 'groupProposed', 'notes'):
            if key in f.meta:
                form[key] = f.meta[key]
        form['sits'] = list(f.sits)
        form['strokes'] = strokes
        builds = alternates(f.id)
        if builds:
            form['alternates'] = builds
        form['_mid'] = mid
        problems += ['%s %s: %s' % (spec.SET['set'], f.id, m) for m in check_form(form, head, spec)]
        forms.append(form)
    return forms, problems


def alternates(form_id):
    """The other right builds of a letter (tools/strokes_alternates.py): each a few strokes of whole box units, with the retrace
    flag worked out from the line itself. No `d`, no `moves`: a build is only compared with the child's strokes, never drawn."""
    from strokes_alternates import ALTERNATES
    out = []
    for how, strokes in ALTERNATES.get(form_id, []):
        built = []
        for pts in strokes:
            st = {'kind': 'line', 'points': [list(p) for p in pts]}
            if retraces([tuple(p) for p in dense_points(pts)]) >= 3:
                st['retrace'] = True
            built.append(st)
        out.append({'how': how, 'strokes': built})
    return out


def dense_points(pts, step=0.5):
    """Points every `step` units along a polyline of box units."""
    segs = [('L', tuple(pts[i - 1]), tuple(pts[i])) for i in range(1, len(pts))]
    return dense(segs, step)


def dense_font(segs):
    return dense(segs, 4.0)


def _join(segs):
    """Path commands for the box: one M, then L and C."""
    out = [('M', segs[0][1])]
    for g in segs:
        out.append((g[0],) + g[2:])
    return out


def _fmt(cmd):
    def n(v):
        r = round(v, 1)
        return ('%d' % r) if r == int(r) else ('%.1f' % r)
    return cmd[0] + ' ' + ' '.join('%s %s' % (n(p[0]), n(p[1])) for p in cmd[1:])


def check_form(form, head, spec):
    out = []
    st = form['strokes']
    if not 1 <= len(st) <= MAX_STROKES:
        out.append('has %d strokes (1 to %d allowed)' % (len(st), MAX_STROKES))
    guides = head['guides']
    body = []
    out += check_alternates(form)
    for i, s in enumerate(st):
        pts = s['_dense']
        tag = 'stroke %d' % (i + 1)
        if any(not (EDGE <= x <= 100 - EDGE and EDGE <= y <= 100 - EDGE) for x, y in pts):
            out.append('%s leaves the box (keep %d units from the edge)' % (tag, EDGE))
        if not 2 <= len(s['points']) <= MAX_POINTS:
            out.append('%s has %d points' % (tag, len(s['points'])))
        ln = length(pts)
        if s['kind'] == 'line' and ln < MIN_TRACE:
            out.append('%s is %.1f long: shorter than %d, so it must be a dot or a short mark' % (tag, ln, MIN_TRACE))
        if s['kind'] in ('dot', 'short') and ln >= MIN_TRACE:
            out.append('%s is marked %s but is %.1f long' % (tag, s['kind'], ln))
        if s['kind'] == 'line':
            loops = self_crossings(pts)
            if loops and not s.get('loop'):
                out.append('%s crosses itself at %s, and the data does not say the model has a loop' % (tag, _p(loops[0])))
            if s.get('loop') and not loops:
                out.append('%s is marked loop but does not cross itself' % tag)
            back = retraces(pts, skip=loops)
            if back >= 3 and not s.get('retrace'):
                out.append('%s goes back over itself for %.1f units, and the data does not say the model retraces' % (tag, back))
            if s.get('retrace') and back < 3:
                out.append('%s is marked retrace but does not go back over itself' % tag)
        why = spec.start_rule(form, i, s)
        if why and not s.get('startOk'):
            out.append('%s: %s' % (tag, why))
        if s['kind'] == 'line':
            body += pts
    # the letter sits on its lines: the top of its body at the upper line, the bottom at the lower (centre lines sit about
    # half an ink width inside the outline, so the tolerance is the inset plus a little)
    if body and form['sits']:
        top_line, bottom_line = form['sits']
        inset = head.get('inset', INK / 2.0)
        top = min(p[1] for p in body)
        bottom = max(p[1] for p in body)
        if top_line and abs(top - (guides[top_line] + inset)) > head.get('lineTolerance', 4.5):
            out.append('top of the letter at %.1f, its line %s is at %.1f' % (top, top_line, guides[top_line]))
        if bottom_line and abs(bottom - (guides[bottom_line] - inset)) > head.get('lineTolerance', 4.5):
            out.append('bottom of the letter at %.1f, its line %s is at %.1f' % (bottom, bottom_line, guides[bottom_line]))
    return out


def check_alternates(form):
    """The other builds of a letter keep the model's caps: at most MAX_BUILDS, 1 to MAX_STROKES strokes, whole units inside the
    box, 2 to MAX_POINTS points, a line long enough to trace, and never the model's own strokes again."""
    out = []
    builds = form.get('alternates', [])
    if len(builds) > MAX_BUILDS:
        out.append('has %d other builds (%d allowed)' % (len(builds), MAX_BUILDS))
    model = [s['points'] for s in form['strokes']]
    for b, build in enumerate(builds):
        tag = 'build %d (%s)' % (b + 1, build['how'])
        if not 1 <= len(build['strokes']) <= MAX_STROKES:
            out.append('%s has %d strokes (1 to %d allowed)' % (tag, len(build['strokes']), MAX_STROKES))
        if [s['points'] for s in build['strokes']] == model:
            out.append('%s is the model itself' % tag)
        for i, s in enumerate(build['strokes']):
            pts = s['points']
            if not 2 <= len(pts) <= MAX_POINTS:
                out.append('%s stroke %d has %d points' % (tag, i + 1, len(pts)))
            if any(not (EDGE <= x <= 100 - EDGE and EDGE <= y <= 100 - EDGE) for x, y in pts):
                out.append('%s stroke %d leaves the box (keep %d units from the edge)' % (tag, i + 1, EDGE))
            if s['kind'] == 'line' and length(pts) < MIN_TRACE:
                out.append('%s stroke %d is %.1f long: shorter than %d' % (tag, i + 1, length(pts), MIN_TRACE))
    return out


def _p(p):
    return '(%d, %d)' % (round(p[0]), round(p[1]))


def top_start(form, i, s, slack=0.25):
    """The common start rule: a stroke starts at its top (within a quarter of its height), the way all three school
    models teach ("start at the top")."""
    if s['kind'] != 'line':
        return None
    ys = [p[1] for p in s['_dense']]
    h = max(ys) - min(ys)
    if s['_dense'][0][1] > min(ys) + max(3.0, slack * h):
        return 'starts at y %.0f, below its top (%.0f): the models start at the top' % (s['_dense'][0][1], min(ys))
    return None


def public(form):
    f = {k: v for k, v in form.items() if not k.startswith('_')}
    f['strokes'] = [{k: v for k, v in s.items() if not k.startswith('_')} for s in form['strokes']]
    return f


def write_set(spec, forms):
    head = {k: v for k, v in spec.SET.items() if k != 'metrics'}
    doc = {'schema': SCHEMA, **head, 'count': len(forms), 'forms': [public(f) for f in forms]}
    os.makedirs(OUT, exist_ok=True)
    path = os.path.join(OUT, spec.SET['set'] + '.json')
    text = json.dumps(doc, ensure_ascii=False, indent=1)
    # keep each point list on one line, so a diff shows what moved
    text = re.sub(r'\[\s+(-?\d+),\s+(-?\d+)\s+\]', r'[\1, \2]', text)
    text = re.sub(r'"points": \[\s+((?:\[\d+, \d+\],?\s*)+)\]', lambda m: '"points": [' + re.sub(r',\s+', ', ', m.group(1).strip()) + ']', text)
    text = re.sub(r'"(moves|sits)": \[\s+([^\]]*?)\s+\]', lambda m: '"%s": [%s]' % (m.group(1), re.sub(r',\s+', ', ', m.group(2))), text)
    with open(path, 'w', encoding='utf-8', newline='\n') as fh:
        fh.write(text + '\n')
    return path


# ---------------------------------------------------------------------------------------------------- sheets and fit
COLOURS = ['#1E9E8F', '#E8742A', '#7A4FD0', '#D6457F', '#4C9A2A', '#9A6B3C']


def _font_css():
    import base64

    def url(name):
        # the fonts go into the page itself, so headless Chrome never draws a fallback font before a file has loaded
        with open(os.path.join(FONTS, name), 'rb') as fh:
            return 'data:font/ttf;base64,' + base64.b64encode(fh.read()).decode('ascii')
    return ("@font-face{font-family:NL;src:url('%s');font-weight:700}"
            "@font-face{font-family:HB;src:url('%s');font-weight:100 900}" % (url('NitznutzLetters-Bold.ttf'), url('Heebo-Variable.ttf')))


def cell_svg(form, head, size, numbers=True):
    s, base = head['em'], head['baseline']
    parts = ['<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 100 100" width="%d" height="%d">' % (size, size),
             '<rect x="0" y="0" width="100" height="100" rx="6" fill="#FFFFFF"/>']
    for name, y in head['guides'].items():
        dash = '' if name in head.get('solidGuides', ()) else ' stroke-dasharray="2 1.6"'
        parts.append('<line x1="2" x2="98" y1="%.1f" y2="%.1f" stroke="#8FCFE0" stroke-width="0.6"%s/>' % (y, y, dash))
    if head.get('font'):
        fam = head['font']['css']
        x0 = 50 - form['_mid'] * s / 1000.0
        parts.append('<text x="%.2f" y="%.2f" font-family="%s" font-weight="700" font-size="%.2f" fill="#E9E4F5" direction="ltr">%s</text>'
                     % (x0, base, fam, s, _esc(form['char'])))
    for i, st in enumerate(form['strokes']):
        c = COLOURS[i % len(COLOURS)]
        if st['kind'] == 'dot':
            x, y = st['points'][0]
            parts.append('<circle cx="%s" cy="%s" r="4.5" fill="%s" opacity="0.85"/>' % (x, y, c))
        else:
            parts.append('<path d="%s" fill="none" stroke="%s" stroke-width="%d" stroke-linecap="round" stroke-linejoin="round" opacity="0.55"/>' % (st['d'], c, INK))
            parts.append('<path d="%s" fill="none" stroke="%s" stroke-width="1.1" stroke-linecap="round" stroke-linejoin="round"/>' % (st['d'], c))
            parts.append(_arrow(st['_dense'], c))
    if numbers:
        placed = []
        for i, st in enumerate(form['strokes']):
            c = COLOURS[i % len(COLOURS)]
            x0, y0 = x, y = st['_dense'][0]
            while any(math.dist((x, y), q) < 7 for q in placed):
                x, y = x + 6, y - 5        # a later stroke starting at the same place: its number moves aside
            if (x, y) != (x0, y0):
                parts.append('<line x1="%.1f" y1="%.1f" x2="%.1f" y2="%.1f" stroke="%s" stroke-width="0.9"/>' % (x0, y0, x, y, c))
                parts.append('<circle cx="%.1f" cy="%.1f" r="1.6" fill="%s"/>' % (x0, y0, c))
            placed.append((x, y))
            parts.append('<circle cx="%.1f" cy="%.1f" r="4.2" fill="%s" stroke="#FFFFFF" stroke-width="0.8"/>' % (x, y, c))
            parts.append('<text x="%.1f" y="%.1f" font-family="Arial" font-weight="700" font-size="6" fill="#FFFFFF" text-anchor="middle">%d</text>' % (x, y + 2.1, i + 1))
    parts.append('</svg>')
    return ''.join(parts)


def _arrow(pts, colour):
    """An arrowhead at the end of the stroke and one a third of the way along, pointing the way the stroke goes."""
    out = []
    total = length(pts)
    for frac in (0.4, 1.0):
        target = total * frac
        acc = 0.0
        idx = len(pts) - 1
        for i in range(1, len(pts)):
            acc += math.dist(pts[i - 1], pts[i])
            if acc >= target:
                idx = i
                break
        j = max(0, idx - 4)
        x, y = pts[idx]
        dx, dy = x - pts[j][0], y - pts[j][1]
        n = math.hypot(dx, dy) or 1
        dx, dy = dx / n, dy / n
        sz = 3.4
        a = (x + dx * sz * 0.6, y + dy * sz * 0.6)
        b = (x - dx * sz - dy * sz * 0.7, y - dy * sz + dx * sz * 0.7)
        c = (x - dx * sz + dy * sz * 0.7, y - dy * sz - dx * sz * 0.7)
        out.append('<path d="M %.1f %.1f L %.1f %.1f L %.1f %.1f Z" fill="%s"/>' % (a + b + c + (colour,)))
    return ''.join(out)


def _esc(t):
    return t.replace('&', '&amp;').replace('<', '&lt;')


def _chrome(html, png=None, w=0, h=0, dump=False):
    tmp = os.path.join(SHEETS, '_strokes_tmp.html')
    with open(tmp, 'w', encoding='utf-8') as fh:
        fh.write(html)
    uri = 'file:///' + tmp.replace('\\', '/')
    try:
        if dump:
            r = subprocess.run([CHROME, '--headless=new', '--disable-gpu', '--allow-file-access-from-files',
                                '--virtual-time-budget=8000', '--dump-dom', uri], check=True, capture_output=True)
            return r.stdout.decode('utf-8')
        subprocess.run([CHROME, '--headless=new', '--disable-gpu', '--hide-scrollbars', '--force-device-scale-factor=1',
                        '--allow-file-access-from-files', '--virtual-time-budget=5000', '--screenshot=' + png,
                        '--window-size=%d,%d' % (w, h), uri], check=True, capture_output=True)
    finally:
        os.remove(tmp)


def sheet(spec, forms, cols=9, size=150, name=None):
    head = spec.SET
    cells = ''.join('<div class="c">%s<span>%s &nbsp;<b>%s</b></span></div>' % (cell_svg(f, head, size), _esc(f['id']), _esc(f['char']))
                    for f in forms)
    w = cols * (size + 12) + 24
    rows = (len(forms) + cols - 1) // cols
    h = 70 + rows * (size + 34) + 24
    title = '%s: %d forms, %s. Numbered dots: where each stroke starts; arrows: its way. Faint letter: %s.' % (
        head['set'], len(forms), head['review'], head['font']['family'] if head.get('font') else 'no font (our own model)')
    html = ('<html><head><meta charset="utf-8"><style>%s body{margin:0;padding:12px;background:#FFF6E8;width:%dpx;'
            'font:13px Arial;color:#2B2350}.c{display:inline-block;width:%dpx;margin:6px;text-align:center;vertical-align:top}'
            '.c svg{display:block;border-radius:8px}h1{font-size:15px;margin:4px 6px 10px}</style></head><body><h1>%s</h1>%s'
            '</body></html>' % (_font_css(), w - 24, size, _esc(title), cells))
    png = os.path.join(SHEETS, 'strokes_%s.png' % head['set']) if not name else os.path.join(os.environ.get('STROKES_LOOK', SHEETS), name + '.png')
    _chrome(html, png, w, h)
    return png


def fit(spec, forms, k=4):
    """Draws each print letter in its font on a canvas and measures (a) how much of each stroke lies in the ink and
    (b) how much of the ink is within reach of some stroke. Returns {form id: (per-stroke inside fractions, coverage)}."""
    head = spec.SET
    s, base = head['em'], head['baseline']
    data = []
    for f in forms:
        strokes = [[[round(x * k, 1), round(y * k, 1)] for x, y in resample(st['_dense'], 0.7)] for st in f['strokes']]
        data.append({'id': f['id'], 'ch': f['char'], 'x0': (50 - f['_mid'] * s / 1000.0) * k, 'strokes': strokes,
                     'kinds': [st['kind'] for st in f['strokes']]})
    js = """
const D=%s, FAM='%s', SIZE=%f, BASE=%f, K=%d, REACH=%f;
async function go(){
 await document.fonts.load('700 100px '+FAM, D.map(d=>d.ch).join(''));
 const cv=document.createElement('canvas');cv.width=100*K;cv.height=100*K;const c=cv.getContext('2d',{willReadFrequently:true});
 const out={};
 for(const d of D){c.clearRect(0,0,cv.width,cv.height);c.fillStyle='#000';c.font='700 '+SIZE+'px '+FAM;c.textBaseline='alphabetic';
  c.fillText(d.ch,d.x0,BASE);const im=c.getImageData(0,0,cv.width,cv.height).data;const ink=(x,y)=>{x=Math.round(x);y=Math.round(y);
  if(x<0||y<0||x>=cv.width||y>=cv.height)return false;return im[(y*cv.width+x)*4+3]>110;};
  const near=(x,y,r)=>{for(let dy=-r;dy<=r;dy+=1)for(let dx=-r;dx<=r;dx+=1){if(dx*dx+dy*dy<=r*r&&ink(x+dx,y+dy))return true;}return false;};
  const inside=d.strokes.map(st=>{let n=0;for(const p of st){if(near(p[0],p[1],1))n++;}return n/st.length;});
  const all=[].concat(...d.strokes);let tot=0,cov=0;
  for(let y=0;y<cv.height;y+=3)for(let x=0;x<cv.width;x+=3){if(!ink(x,y))continue;tot++;
   for(const p of all){const dx=p[0]-x,dy=p[1]-y;if(dx*dx+dy*dy<=REACH*REACH){cov++;break;}}}
  out[d.id]=[inside,tot?cov/tot:1];}
 document.getElementById('o').textContent=JSON.stringify(out);}
go();""" % (json.dumps(data, ensure_ascii=False), head['font']['css'], s * k, base * k, k, head.get('reach', 7.5) * k)
    html = '<html><head><meta charset="utf-8"><style>%s</style></head><body><pre id="o">wait</pre><script>%s</script></body></html>' % (_font_css(), js)
    dom = _chrome(html, dump=True)
    m = re.search(r'<pre id="o">(.*?)</pre>', dom, re.S)
    txt = m.group(1).replace('&quot;', '"').replace('&amp;', '&')
    return json.loads(txt)


def all_specs():
    import importlib
    out = []
    for name in ('strokes_latin', 'strokes_cyrillic', 'strokes_hebrew'):
        try:
            mod = importlib.import_module(name)
        except ModuleNotFoundError as e:
            if e.name != name:
                raise
            continue
        out += list(getattr(mod, 'SPECS', [mod]))
    return out


def main(argv):
    specs = all_specs()
    only = [a.split('=', 1)[1] for a in argv if a.startswith('--only=')]
    if only:
        specs = [s for s in specs if s.SET['set'] in only[0].split(',')]
    bad = []
    for spec in specs:
        forms, problems = build_set(spec)
        if '--fit' in argv and spec.SET.get('font'):
            res = fit(spec, forms)
            worst = []
            for f in forms:
                inside, cover = res[f['id']]
                for i, v in enumerate(inside):
                    if f['strokes'][i]['kind'] == 'line' and v < spec.SET.get('minInside', 0.9):
                        problems.append('%s %s: stroke %d is %.0f%% inside the font ink' % (spec.SET['set'], f['id'], i + 1, 100 * v))
                if cover < spec.SET.get('minCover', 0.9):
                    problems.append('%s %s: the strokes reach only %.0f%% of the font ink' % (spec.SET['set'], f['id'], 100 * cover))
                worst.append((min(inside), cover, f['id']))
            worst.sort()
            print('fit %s: lowest inside %s; lowest cover %s' % (spec.SET['set'], ', '.join('%s %.2f' % (w[2], w[0]) for w in worst[:4]),
                                                                   ', '.join('%s %.2f' % (w[2], w[1]) for w in sorted(worst, key=lambda t: t[1])[:4])))
        look = [a.split('=', 1)[1].split(',') for a in argv if a.startswith('--look=')]
        if look:
            pick = [f for f in forms if f['id'] in look[0]]
            if pick:
                print('look', sheet(spec, pick, cols=4, size=380, name='look_%s' % spec.SET['set']))
            continue
        path = write_set(spec, forms)
        print('wrote %d forms to %s' % (len(forms), os.path.relpath(path, ROOT)))
        if '--sheet' in argv:
            print('sheet', os.path.relpath(sheet(spec, forms), ROOT))
        bad += problems
    for p in bad:
        print('CHECK', p)
    if bad:
        print('%d problems' % len(bad))
        return 1
    print('all forms pass the checks')
    return 0


if __name__ == '__main__':
    sys.exit(main(sys.argv[1:]))
