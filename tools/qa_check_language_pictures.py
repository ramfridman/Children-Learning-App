"""QA check of the Languages pictures (content/languages/pictures/*.svg), written for the L4 verification.

Usage: python -I tools/qa_check_language_pictures.py content/languages/pictures

Checks each file against docs/art/art-brief.md section 5: only <svg>, <g>, <path>, <rect>, <circle>, <ellipse>, <polygon> and
<clipPath>; no <text>, <style>, filter, mask, href or class; under 40 KB; and the ink (paths flattened, transforms and
clip paths applied, half a stroke added) inside the viewBox, reported at four tolerances. Exit code 0 when no file has a
feature problem, a parse error or a size over 40 KB.
"""
import re, sys, glob, math, os
import xml.etree.ElementTree as ET

ALLOWED = {'svg', 'g', 'path', 'rect', 'circle', 'ellipse', 'polygon', 'clipPath'}
BRIEF_OK_ATTRS = None
NS = '{http://www.w3.org/2000/svg}'


def mat_mul(a, b):
    return (a[0]*b[0]+a[2]*b[1], a[1]*b[0]+a[3]*b[1], a[0]*b[2]+a[2]*b[3], a[1]*b[2]+a[3]*b[3],
            a[0]*b[4]+a[2]*b[5]+a[4], a[1]*b[4]+a[3]*b[5]+a[5])


def parse_transform(t):
    m = (1, 0, 0, 1, 0, 0)
    if not t:
        return m
    for name, args in re.findall(r'(\w+)\s*\(([^)]*)\)', t):
        v = [float(x) for x in re.findall(r'[-+]?(?:\d*\.\d+|\d+\.?)(?:[eE][-+]?\d+)?', args)]
        if name == 'translate':
            n = (1, 0, 0, 1, v[0], v[1] if len(v) > 1 else 0)
        elif name == 'scale':
            n = (v[0], 0, 0, v[1] if len(v) > 1 else v[0], 0, 0)
        elif name == 'rotate':
            a = math.radians(v[0]); c, s = math.cos(a), math.sin(a)
            n = (c, s, -s, c, 0, 0)
            if len(v) == 3:
                n = mat_mul(mat_mul((1, 0, 0, 1, v[1], v[2]), n), (1, 0, 0, 1, -v[1], -v[2]))
        elif name == 'matrix':
            n = tuple(v)
        else:
            raise ValueError('transform ' + name)
        m = mat_mul(m, n)
    return m


def ap(m, x, y):
    return (m[0]*x+m[2]*y+m[4], m[1]*x+m[3]*y+m[5])


def arc_pts(x1, y1, rx, ry, phi, fa, fs, x2, y2, n=24):
    if rx == 0 or ry == 0:
        return [(x2, y2)]
    phi = math.radians(phi); c, s = math.cos(phi), math.sin(phi)
    dx, dy = (x1-x2)/2, (y1-y2)/2
    x1p, y1p = c*dx+s*dy, -s*dx+c*dy
    rx, ry = abs(rx), abs(ry)
    lam = x1p**2/rx**2 + y1p**2/ry**2
    if lam > 1:
        k = math.sqrt(lam); rx *= k; ry *= k
    num = rx**2*ry**2 - rx**2*y1p**2 - ry**2*x1p**2
    den = rx**2*y1p**2 + ry**2*x1p**2
    co = math.sqrt(max(0, num/den)) if den else 0
    if fa == fs:
        co = -co
    cxp, cyp = co*rx*y1p/ry, -co*ry*x1p/rx
    cx, cy = c*cxp - s*cyp + (x1+x2)/2, s*cxp + c*cyp + (y1+y2)/2
    def ang(ux, uy, vx, vy):
        a = math.atan2(ux*vy-uy*vx, ux*vx+uy*vy)
        return a
    t1 = ang(1, 0, (x1p-cxp)/rx, (y1p-cyp)/ry)
    dt = ang((x1p-cxp)/rx, (y1p-cyp)/ry, (-x1p-cxp)/rx, (-y1p-cyp)/ry)
    if not fs and dt > 0:
        dt -= 2*math.pi
    elif fs and dt < 0:
        dt += 2*math.pi
    out = []
    for i in range(1, n+1):
        t = t1 + dt*i/n
        px, py = rx*math.cos(t), ry*math.sin(t)
        out.append((c*px - s*py + cx, s*px + c*py + cy))
    return out


def path_pts(d):
    toks = re.findall(r'[A-Za-z]|[-+]?(?:\d*\.\d+|\d+\.?)(?:[eE][-+]?\d+)?', d)
    pts = []; i = 0; cmd = None; x = y = sx = sy = 0.0; lc = None
    def num():
        nonlocal i
        v = float(toks[i]); i += 1; return v
    while i < len(toks):
        if re.match(r'[A-Za-z]', toks[i]):
            cmd = toks[i]; i += 1
            if cmd in 'Zz':
                x, y = sx, sy; continue
        rel = cmd.islower(); C = cmd.upper()
        if C == 'M':
            nx, ny = num(), num()
            if rel: nx += x; ny += y
            x, y = nx, ny; sx, sy = x, y; pts.append((x, y)); cmd = 'l' if rel else 'L'; lc = None
        elif C == 'L':
            nx, ny = num(), num()
            if rel: nx += x; ny += y
            x, y = nx, ny; pts.append((x, y)); lc = None
        elif C == 'H':
            nx = num(); x = nx + x if rel else nx; pts.append((x, y)); lc = None
        elif C == 'V':
            ny = num(); y = ny + y if rel else ny; pts.append((x, y)); lc = None
        elif C in 'QT':
            if C == 'Q':
                cx1, cy1 = num(), num()
                if rel: cx1 += x; cy1 += y
            else:
                cx1, cy1 = (2*x-lc[0], 2*y-lc[1]) if lc and lc[2] == 'Q' else (x, y)
            nx, ny = num(), num()
            if rel and C == 'Q': nx += x; ny += y
            elif rel and C == 'T': nx += x; ny += y
            for k in range(1, 17):
                t = k/16
                pts.append(((1-t)**2*x+2*(1-t)*t*cx1+t*t*nx, (1-t)**2*y+2*(1-t)*t*cy1+t*t*ny))
            lc = (cx1, cy1, 'Q'); x, y = nx, ny
        elif C in 'CS':
            if C == 'C':
                a1, b1 = num(), num()
                if rel: a1 += x; b1 += y
            else:
                a1, b1 = (2*x-lc[0], 2*y-lc[1]) if lc and lc[2] == 'C' else (x, y)
            a2, b2 = num(), num()
            nx, ny = num(), num()
            if rel:
                a2 += x; b2 += y; nx += x; ny += y
            for k in range(1, 17):
                t = k/16; u = 1-t
                pts.append((u**3*x+3*u*u*t*a1+3*u*t*t*a2+t**3*nx, u**3*y+3*u*u*t*b1+3*u*t*t*b2+t**3*ny))
            lc = (a2, b2, 'C'); x, y = nx, ny
        elif C == 'A':
            rx, ry, ph, fa, fs, nx, ny = num(), num(), num(), num(), num(), num(), num()
            if rel: nx += x; ny += y
            pts.extend(arc_pts(x, y, rx, ry, ph, int(fa), int(fs), nx, ny)); x, y = nx, ny; lc = None
        else:
            raise ValueError('cmd ' + cmd)
    return pts


def f(e, k, d=0.0):
    v = e.get(k)
    return float(re.sub(r'[a-z%]+$', '', v)) if v else d


def shape_pts(e, tag):
    if tag == 'path': return path_pts(e.get('d', ''))
    if tag == 'rect':
        x, y, w, h = f(e, 'x'), f(e, 'y'), f(e, 'width'), f(e, 'height')
        return [(x, y), (x+w, y), (x+w, y+h), (x, y+h)]
    if tag == 'circle':
        cx, cy, r = f(e, 'cx'), f(e, 'cy'), f(e, 'r')
        return [(cx+r*math.cos(a*math.pi/12), cy+r*math.sin(a*math.pi/12)) for a in range(24)]
    if tag == 'ellipse':
        cx, cy, rx, ry = f(e, 'cx'), f(e, 'cy'), f(e, 'rx'), f(e, 'ry')
        return [(cx+rx*math.cos(a*math.pi/12), cy+ry*math.sin(a*math.pi/12)) for a in range(24)]
    if tag == 'polygon':
        v = [float(x) for x in re.findall(r'[-+]?\d*\.?\d+', e.get('points', ''))]
        return list(zip(v[0::2], v[1::2]))
    return []


def bbox(pts):
    if not pts: return None
    xs = [p[0] for p in pts]; ys = [p[1] for p in pts]
    return (min(xs), min(ys), max(xs), max(ys))


def inter(a, b):
    if a is None or b is None: return None
    r = (max(a[0], b[0]), max(a[1], b[1]), min(a[2], b[2]), min(a[3], b[3]))
    return r if r[0] < r[2] and r[1] < r[3] else 'EMPTY'


def analyse(path):
    root = ET.parse(path).getroot()
    problems = []
    vb = [float(x) for x in root.get('viewBox').split()]
    clips = {}
    elems = []
    def local(e): return e.tag.replace(NS, '')
    for e in root.iter():
        t = local(e)
        if t not in ALLOWED: problems.append('tag <%s>' % t)
    for a in root.iter():
        for k, v in a.attrib.items():
            if 'href' in k or k in ('style', 'class', 'filter', 'mask'):
                problems.append('attr ' + k)
            if 'url(' in v and k != 'clip-path':
                problems.append('url() in ' + k)
    # clip bboxes (clipPath children in the clipPath's own coordinate system)
    for e in root.iter():
        if local(e) == 'clipPath':
            pts = []
            for c in e.iter():
                tc = local(c)
                if tc in ('clipPath',): continue
                m = parse_transform(c.get('transform'))
                pts += [ap(m, *p) for p in shape_pts(c, tc)]
            clips[e.get('id')] = bbox(pts)
    worst = [0, 0, 0, 0]
    ink = None
    def walk(e, m, clip):
        nonlocal ink
        t = local(e)
        if t == 'clipPath' or clip == 'EMPTY': return
        mm = mat_mul(m, parse_transform(e.get('transform')))
        cp = e.get('clip-path')
        if cp:
            cid = re.search(r'url\(#([^)]+)\)', cp).group(1)
            cb = clips.get(cid)
            if cb:
                # clip is in element's user space incl. its transform -> world bbox
                corners = [ap(mm, cb[0], cb[1]), ap(mm, cb[2], cb[1]), ap(mm, cb[0], cb[3]), ap(mm, cb[2], cb[3])]
                wb = bbox(corners)
                clip = wb if clip is None else inter(clip, wb)
                if clip == 'EMPTY': return
        if t in ('path', 'rect', 'circle', 'ellipse', 'polygon'):
            if e.get('fill') == 'none' and not e.get('stroke'): pass
            pts = [ap(mm, *p) for p in shape_pts(e, t)]
            b = bbox(pts)
            if b:
                if e.get('stroke') and e.get('stroke') != 'none':
                    sw = f(e, 'stroke-width', 1) * math.sqrt(abs(mm[0]*mm[3]-mm[1]*mm[2])) / 2
                    b = (b[0]-sw, b[1]-sw, b[2]+sw, b[3]+sw)
                if clip is not None:
                    b = inter(b, clip)
                if b and b != 'EMPTY':
                    ink = b if ink is None else (min(ink[0], b[0]), min(ink[1], b[1]), max(ink[2], b[2]), max(ink[3], b[3]))
        for c in e:
            walk(c, mm, clip)
    walk(root, (1, 0, 0, 1, -0, -0), None)
    over = (0, 0, 0, 0)
    if ink:
        over = (max(0, vb[0]-ink[0]), max(0, vb[1]-ink[1]), max(0, ink[2]-(vb[0]+vb[2])), max(0, ink[3]-(vb[1]+vb[3])))
    return vb, ink, over, problems


if __name__ == '__main__':
    d = sys.argv[1]
    rows = []
    for p in sorted(glob.glob(os.path.join(d, '*.svg'))):
        size = os.path.getsize(p)
        try:
            vb, ink, over, probs = analyse(p)
        except Exception as ex:
            rows.append((os.path.basename(p), 'ERR', repr(ex), size)); continue
        rows.append((os.path.basename(p), vb, ink, over, probs, size))
    bad_parse = [r for r in rows if r[1] == 'ERR']
    print('files', len(rows), 'parse errors', len(bad_parse), bad_parse[:5])
    probs = [(r[0], r[4]) for r in rows if r[1] != 'ERR' and r[4]]
    print('feature problems', len(probs), probs[:10])
    print('over 40KB (40960):', [(r[0], r[-1]) for r in rows if r[-1] > 40*1024])
    print('max size', max(r[-1] for r in rows))
    for tol_name, frac in (('>0', 0), ('>0.5% of side', 0.005), ('>2% of side', 0.02), ('>5% of side', 0.05)):
        out = []
        for r in rows:
            if r[1] == 'ERR': continue
            vb, ink, over = r[1], r[2], r[3]
            tol = frac * max(vb[2], vb[3])
            if max(over) > tol + 1e-6: out.append((r[0], tuple(round(x, 1) for x in over)))
        print(tol_name, len(out))
        if frac in (0.02, 0.05) or (frac == 0.005 and len(out) < 30):
            for o in out[:40]: print('   ', o)
    bad = [r for r in rows if r[1] == 'ERR' or r[-1] > 40 * 1024 or (len(r) > 4 and r[4])]
    sys.exit(1 if bad else 0)
