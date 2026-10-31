"""B-40 hint hands, version 3 (design-director, 2026-10-31). Writes the art the app loads, as plain SVG.

    python docs/design/b40/make_hint_hands.py            writes app/assets/art/hints/*.svg
    python docs/design/b40/make_hint_hands.py --tone2    also writes a darker skin tone to the scratch folder (an offer)

Files (all original drawings in plain shapes; no raster, no filter, no mask, no text; flutter_svg-safe: paths, circles,
ellipses, groups with transforms, clipPath):
- hand_left_0.svg ... hand_left_5.svg   a child's LEFT hand seen from the back (the way a child sees its own raised
                                         hand), thumb toward the middle (on the right); k fingers raised.
- hand_right_0.svg ... hand_right_5.svg  the same drawing mirrored: the RIGHT hand, thumb on the left.
- hand_point.svg                         the helper's pointing hand (P12): sky, index finger long, the other fingers
                                         curled, the thumb resting along them, a short wrist, no cuff.

viewBox: counting hands 0 0 112 174 (54 x 84 pt on a phone; the wrist's bottom centre at (45, 170) left, (67, 170) right);
the pointing hand 0 0 102 142 (52 x 72 pt) with the fingertip at POINT_TIP (37.9, 127.5): the anchor the app places on
the target.

Finger order (design-spec P3, F12; the curriculum plan does not say otherwise): 1 index, 2 + middle, 3 + ring,
4 + little, 5 + thumb.

References looked at before drawing (facts only; nothing copied or traced):
- Hand proportions and the knuckle arc (middle finger highest, index and ring about level, the little finger reaching
  the ring finger's top joint; the knuckles of all three joint rows follow the same arc): Clip Studio Tips,
  "How to Draw: Hands" (tips.clip-studio.com/en-us/articles/8233) and "Drawing the Hands" (articles/8210).
- A child's hand: more soft tissue, so the knuckles read as dimples, not bumps, and the fingers are shorter and
  thicker against the palm (same sources).
- Kindergarten finger-counting cards (Wunderkiddy "Finger counting" flashcards, looked at 2026-10-31; Illustrative
  Mathematics K unit 2 "Math Fingers"): one simple, large hand per card, flat warm skin, folded fingers drawn as
  folded (curled, never missing), each raised finger clearly separated from the next.
- Version 3, the folded thumb (looked at 2026-10-31 in the built-in browser, Bing image search): stock photos of a
  hand from the back with four fingers up and the thumb folded in (the thumb side is a smooth edge with a slight bulge,
  the thumb itself hidden), and of a hand from the back with the index finger up (the thumb's edge and knuckle show at
  the side of the fist, just under the index knuckle); cartoon finger-counting cards (most draw the PALM side, where
  the thumb crosses the folded fingers; from the back it does not). A fist from the back: the four knuckles make one
  soft rounded top.
- Pointer icons (the common "pointing down" hand): back of the hand, three curled fingers as a row of knuckles,
  the thumb along the side.
"""
import math
import os
import sys

ROOT = os.path.abspath(os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', '..', '..'))
OUT = os.path.join(ROOT, 'app', 'assets', 'art', 'hints')

# Skin: design/tokens.json character.kidSkin[0] (#F1C7A5) with a shade and a light derived from it.
# Outline: character.nitzi.nose (#7A2E4E), the warm plum the characters' mouths are drawn with.
TONE1 = dict(skin='#F1C7A5', shade='#E2A57F', light='#F8DCC4', nail='#FBE9DA', crease='#C98563', line='#7A2E4E')
TONE2 = dict(skin='#C68B62', shade='#A9704B', light='#D7A27C', nail='#E6BE9F', crease='#8C5536', line='#5E2A35')
# The helper's pointer (P12) stays sky: brand.skyDeep outline; paper and skyTint fills; the shadow token.
# 2026-10-31 (B-40 part 2 review): on the sky stage the thin outline let the white hand melt into the sky, so the outline is
# half as thick again (POINT_OW), the shade a little deeper and the shadow a little darker; the viewBox grew by 3 on each side
# so the thicker outline is never cut.
SKYHAND = dict(skin='#FFFFFF', shade='#C4E6F8', light='#FFFFFF', nail='#E3F4FC', crease='#8FD3F4', line='#5BB6E0')
SHADOW = 'rgba(43,35,80,0.14)'

OW = 2.6  # outline width in viewBox units (about 1.1 pt at 84 pt tall)

# ---------------------------------------------------------------- the counting hand (LEFT hand, back view)
# Drawn in a 124 x 200 frame. Each finger: base point on the knuckle arc, lean (degrees, + = toward the thumb), length, width,
# and where the back of the hand's top edge crosses it (palm_y), so the shading of a folded finger stops there.
VB_W, VB_H = 112, 174   # cropped to the drawing; drawn in a 124 x 200 frame, moved by (-12, -24)
FINGERS = {
    'little': dict(b=(30, 106), a=-9, L=45, w=14.6, palm_y=100),
    'ring':   dict(b=(46, 97), a=-3, L=58, w=16.0, palm_y=95),
    'middle': dict(b=(62.5, 94), a=1, L=64, w=16.8, palm_y=93),
    'index':  dict(b=(79, 97), a=5, L=57, w=16.4, palm_y=95.5),
}
ORDER = ['index', 'middle', 'ring', 'little', 'thumb']

# The thumb is the thickest digit (22 at its root, 17.6 at the tip; the fingers are 14.6 to 16.8). It starts low on the
# side of the hand near the wrist. Raised (5, the owner's good example): it leans out 28 degrees, past the outline of
# the hand, with an open web between it and the index finger; its tip reaches the index knuckle's height. Folded (0 to
# 4): see THUMB_TUCK below (version 2 laid it across the front of the palm, which the owner found strange).
THUMB_UP = dict(tr='translate(80 170) rotate(28)', L=76, w=23.0, tip=0.78)
# Folded (0 to 4), version 3 (the owner, 2026-10-31: the thumb laid across the front of the palm read as strange):
# seen from the back, a folded thumb is tucked against the side of the hand and mostly hidden behind it. Only its outer
# edge shows, a soft strip along the thumb side of the hand from near the wrist up to just under the index knuckle, with
# the rounded tip, a sliver of nail seen edge-on and one knuckle crease. It is drawn BEHIND the back of the hand (like the
# raised thumb), so the hand's own outline runs over it. Frame coordinates (the 124 x 200 frame).
THUMB_TUCK = ('M80 171 C90 162 98.5 150 101.5 137 C103.5 127 104 117 101 111.5 C98.5 106.5 92.5 106 89.5 111 '
              'C87 116 86 140 80 171 Z')
THUMB_TUCK_SHADE = 'M101.5 105 C106 116 105 134 99 152 C94 166 86 174 76 180 L112 180 L112 100 Z'
THUMB_TUCK_NAIL = 'M99.2 110.4 C102.4 112.2 103 117 102.6 121.8 C101 122.4 99.4 121.4 98.8 119.6 C98.4 116.4 98.4 113 99.2 110.4 Z'
THUMB_TUCK_CREASE = 'M95.6 134 Q99 133 101.6 135.4'
PALM_THUMB_EDGE = 'M90.6 99 C94.5 102 96 107.5 96 114 C96 122 95 128 93 134 C90 150 86 166 80.5 173'


def _rot(px, py, a, ox, oy):
    r = math.radians(a)
    return (ox + px * math.cos(r) - py * math.sin(r), oy + px * math.sin(r) + py * math.cos(r))


def finger_path(L, w, tip=0.86, root=14):
    """A finger pointing up in local coordinates: base centre at (0,0), extends `root` below into the palm, tapers a
    little to a round tip at y = -L."""
    tw = w * tip
    r = tw / 2
    return ('M%.2f %.2f L%.2f %.2f C%.2f %.2f %.2f %.2f %.2f %.2f L%.2f %.2f Z' % (
        -w / 2, root, -tw / 2, -L + r,
        -tw / 2, -L - r * 0.34, tw / 2, -L - r * 0.34, tw / 2, -L + r,
        w / 2, root))


def capsule_path(L, w, tip=0.92, root=12):
    """Like finger_path but rounded at the root too (a thumb part drawn in front of the hand)."""
    tw = w * tip
    r, rb = tw / 2, w / 2
    return ('M%.2f %.2f L%.2f %.2f C%.2f %.2f %.2f %.2f %.2f %.2f L%.2f %.2f C%.2f %.2f %.2f %.2f %.2f %.2f Z' % (
        -w / 2, root - rb, -tw / 2, -L + r,
        -tw / 2, -L - r * 0.34, tw / 2, -L - r * 0.34, tw / 2, -L + r,
        w / 2, root - rb,
        w / 2, root + rb * 0.34, -w / 2, root + rb * 0.34, -w / 2, root - rb))


def folded_path(w, h=None, root=14):
    """A folded finger seen from the back: the knuckle and the first bone turned away, a short rounded dome."""
    h = h if h is not None else w * 0.72
    return ('M%.2f %.2f L%.2f %.2f C%.2f %.2f %.2f %.2f %.2f %.2f L%.2f %.2f Z' % (
        -w / 2, root, -w / 2, -h + w * 0.42, -w / 2, -h - w * 0.12, w / 2, -h - w * 0.12, w / 2, -h + w * 0.42, w / 2, root))


# The back of the hand: widest across the knuckles, narrowing to the wrist; on the thumb side it runs down to the
# web, where the thumb leaves it.
PALM = ('M20 116 C18 102 25 97 36 95.5 C50 91.5 70 91 84 94.5 C93 96.5 96 104 96 114 C96 122 95 128 93 134 '
        'C90 150 86 166 80 174 L80 188 C69 194 45 194 34 188 L34 174 C24 166 20 150 20 132 Z')
WRIST_CREASE = 'M41 176 Q57 181 73 176'


def _nail(tw, L):
    return ('M%.2f %.2f C%.2f %.2f %.2f %.2f %.2f %.2f L%.2f %.2f C%.2f %.2f %.2f %.2f %.2f %.2f Z' % (
        -tw * 0.3, -L + tw * 0.62, -tw * 0.3, -L + tw * 0.12, tw * 0.3, -L + tw * 0.12, tw * 0.3, -L + tw * 0.62,
        tw * 0.3, -L + tw * 0.98, tw * 0.1, -L + tw * 1.08, 0, -L + tw * 1.08, -tw * 0.3, -L + tw * 0.98))


def counting_hand_svg(k, tone, mirror=False):
    """A child's LEFT hand from the back with k fingers up (mirror=True gives the RIGHT hand).
    Paint order: one outline under the hand (so it reads as one soft shape), the raised thumb, the raised fingers
    (nail, joint creases, the far side shaded), the back of the hand over their roots, the folded fingers (domes:
    the knuckle turned away, with the bend line), and last the folded thumb in front with its own outline."""
    t = tone
    up = set(ORDER[:k])
    outline, under, over, clips = [], [], [], []
    cid = [0]

    def clip(d, tr):
        cid[0] += 1
        clips.append('<clipPath id="c%d"><path d="%s" transform="%s"/></clipPath>' % (cid[0], d, tr))
        return 'url(#c%d)' % cid[0]

    def line(d, tr='', colour=None, w=1.5):
        return '<path d="%s" transform="%s" fill="none" stroke="%s" stroke-width="%.1f" stroke-linecap="round"/>' % (
            d, tr, colour or t['crease'], w)

    def digit(d, tr, w, L, tip, nail=True, shade_to=20, crease=True):
        """fill + far-side shade + nail + middle-joint creases of one raised digit (local coordinates)."""
        c = clip(d, tr)
        g = '<g clip-path="%s"><path d="%s" transform="%s" fill="%s"/>' % (c, d, tr, t['skin'])
        g += '<rect x="%.2f" y="-90" width="%.2f" height="%.2f" transform="%s" fill="%s"/></g>' % (
            w * 0.2, w, 90 + shade_to, tr, t['shade'])
        if nail:
            g += '<path d="%s" transform="%s" fill="%s" stroke="%s" stroke-width="1.2"/>' % (_nail(w * tip, L), tr, t['nail'], t['crease'])
        if crease:
            jy = -L * 0.5
            g += line('M%.2f %.2f Q0 %.2f %.2f %.2f' % (-w * 0.24, jy, jy - 2.4, w * 0.24, jy), tr)
            g += line('M%.2f %.2f Q0 %.2f %.2f %.2f' % (-w * 0.16, jy + 3.4, jy + 1.6, w * 0.16, jy + 3.4), tr, w=1.3)
        return g

    # the raised thumb, behind the back of the hand (its root is hidden there)
    if 'thumb' in up:
        th = THUMB_UP
        d = capsule_path(th['L'], th['w'], tip=th['tip'], root=10)
        outline.append('<path d="%s" transform="%s"/>' % (d, th['tr']))
        under.append(digit(d, th['tr'], th['w'], th['L'], th['tip'], crease=False))
        jy = th['L'] * 0.6
        under.append(line('M-5.5 -%.1f Q0 -%.1f 5.5 -%.1f' % (jy, jy + 2.8, jy), th['tr']))
        under.append(line('M-4 -%.1f Q0 -%.1f 4 -%.1f' % (jy - 3.4, jy - 1.8, jy - 3.4), th['tr'], w=1.3))
    else:
        # the folded thumb, tucked against the side of the hand, behind it: only its outer edge shows
        outline.append('<path d="%s"/>' % THUMB_TUCK)
        c = clip(THUMB_TUCK, '')
        under.append('<g clip-path="%s"><path d="%s" fill="%s"/><path d="%s" fill="%s"/></g>' % (
            c, THUMB_TUCK, t['skin'], THUMB_TUCK_SHADE, t['shade']))
        under.append('<path d="%s" fill="%s" stroke="%s" stroke-width="1.2"/>' % (THUMB_TUCK_NAIL, t['nail'], t['crease']))
        under.append(line(THUMB_TUCK_CREASE, w=1.5))

    folded = []
    for name in ['little', 'ring', 'middle', 'index']:
        f = FINGERS[name]
        w, L = f['w'], f['L']
        tr = 'translate(%.1f %.1f) rotate(%.1f)' % (f['b'][0], f['b'][1], f['a'])
        if name in up:
            d = finger_path(L, w)
            outline.append('<path d="%s" transform="%s"/>' % (d, tr))
            under.append(digit(d, tr, w, L, 0.86))
        else:
            # a fist (0): wider, lower knuckles that overlap into one soft rounded top; 1 to 4: the folded finger
            d = folded_path(w * 1.22, h=w * 0.84) if k == 0 else folded_path(w * 1.04, h=w * 1.08)
            outline.append('<path d="%s" transform="%s"/>' % (d, tr))
            folded.append((d, tr, w, f))

    # the cleft between two raised neighbours, above the back of the hand
    names = ['little', 'ring', 'middle', 'index']
    for i in range(3):
        a, b = FINGERS[names[i]], FINGERS[names[i + 1]]
        if names[i] in up and names[i + 1] in up:
            x = (a['b'][0] + a['w'] / 2 + b['b'][0] - b['w'] / 2) / 2
            top = min(a['b'][1], b['b'][1]) - 15
            under.append(line('M%.1f %.1f L%.1f %.1f' % (x, top, x + 0.3, top + 16), colour=t['line'], w=OW * 0.85))

    # the back of the hand
    outline.append('<path d="%s"/>' % PALM)
    c = clip(PALM, '')
    over.append('<g clip-path="%s"><path d="%s" fill="%s"/>'
                '<path d="M86 96 C98 108 99 150 82 192 L114 192 L114 90 Z" fill="%s"/>'
                '</g>' % (c, PALM, t['skin'], t['shade']))
    if 'thumb' in up:
        # the web between the thumb and the index finger, where the thumb leaves the hand
        over.append(line('M95.6 117 Q95 126 92.5 134', colour=t['line'], w=OW * 0.8))
    for name in names:   # knuckle dimples
        f = FINGERS[name]
        kx, ky = _rot(0, 8, f['a'], f['b'][0], f['b'][1])
        over.append(line('M%.1f %.1f q2.6 -1.6 5.2 0' % (kx - 2.6, ky), w=1.4))
    over.append(line(WRIST_CREASE))

    # the folded fingers, over the back of the hand: shaded below the knuckle, lit on top, the bend line
    for (d, tr, w, f) in folded:
        c = clip(d, tr)
        cut = f['palm_y'] - f['b'][1]
        g = '<g clip-path="%s"><path d="%s" transform="%s" fill="%s"/>' % (c, d, tr, t['skin'])
        g += '<rect x="%.2f" y="-40" width="%.2f" height="%.2f" transform="%s" fill="%s"/>' % (w * 0.2, w, 40 + cut, tr, t['shade'])
        g += '</g>'
        g += line('M%.2f %.2f Q0 %.2f %.2f %.2f' % (-w * 0.32, -w * 0.42, -w * 0.18, w * 0.32, -w * 0.42), tr, w=1.7)
        g += '<ellipse cx="%.2f" cy="%.2f" rx="%.2f" ry="%.2f" transform="%s" fill="%s"/>' % (
            -w * 0.12, -w * 0.72, w * 0.22, w * 0.11, tr, t['light'])
        over.append(g)
    # folded neighbours: a short cleft between the domes
    for i in range(3):
        a, b = FINGERS[names[i]], FINGERS[names[i + 1]]
        if names[i] not in up or names[i + 1] not in up:
            x = (a['b'][0] + a['w'] / 2 + b['b'][0] - b['w'] / 2) / 2
            # (in the fist the knuckles overlap, so the cleft starts at the valley between the two domes)
            top = max(a['b'][1], b['b'][1]) - 8.5 if k == 0 else min(a['b'][1], b['b'][1]) - 10
            over.append(line('M%.1f %.1f L%.1f %.1f' % (x, top, x + 0.2, max(a['palm_y'], b['palm_y']) + 1), colour=t['line'], w=OW * 0.8))

    # the folded thumb: the hand's own outline runs over it, where the thumb is tucked against the side
    if 'thumb' not in up:
        over.append(line(PALM_THUMB_EDGE, colour=t['line'], w=OW * 0.85))

    body = ('<g fill="%s" stroke="%s" stroke-width="%.1f" stroke-linejoin="round">%s</g>' % (t['line'], t['line'], OW * 2, ''.join(outline))
            + ''.join(under) + ''.join(over))
    if mirror:
        body = '<g transform="translate(124 -24) scale(-1 1)">%s</g>' % body
    else:
        body = '<g transform="translate(-12 -24)">%s</g>' % body
    label = 'יד ימין' if mirror else 'יד שמאל'
    return ('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 %d %d" role="img" aria-label="%s %d">'
            '<defs>%s</defs>%s</svg>\n') % (VB_W, VB_H, label, k, ''.join(clips), body)


# ---------------------------------------------------------------- the pointing hand (P12)
POINT_OW = OW * 3.3  # the pointer's outline (the counting hands keep OW * 2)
POINT_TURN = 200  # degrees: the finger points down and a little left, the wrist goes to the upper right


def _point_local():
    """The pointing hand in local coordinates, finger UP, fingertip at (0,0): a RIGHT hand, back of the hand toward
    us, so the thumb is on the left; after the turn it is on the right (upper) side."""
    idx = finger_path(50, 16.5, tip=0.88, root=16)                       # index; its base at (0,50)
    palm = ('M-8.5 44 C-11 58 -10 76 -4 86 C2 96 18 99 30 96 C42 93 49 83 48 70 C47 58 44 50 37 46 '
            'C28 42 8 42 -8.5 44 Z')
    wrist = 'M3 84 L4 112 C13 118 29 118 37 111 L38 84 Z'
    curled = [(16.5, 47, 15.0), (30, 49.5, 14.2), (41.5, 55, 12.6)]     # middle, ring, little: a row of knuckles
    thumb = finger_path(34, 20, tip=0.86, root=16)                       # thick, from low on the side, out past the hand
    th_tr = 'translate(-1 84) rotate(-56)'
    return idx, palm, wrist, curled, thumb, th_tr


# The viewBox is cropped to the drawn hand (measured from a render, 2 units of air), so the app can size it by height.
POINT_VB = (102, 142)
POINT_TIP = (37.9, 127.5)  # the fingertip in the viewBox: the anchor the app puts on the target


def pointing_hand_svg(tone=SKYHAND):
    t = tone
    idx, palm, wrist, curled, thumb, th_tr = _point_local()
    outl, fills, det = [], [], []

    def shape(d, tr, fill):
        outl.append('<path d="%s" transform="%s" stroke-width="%.1f" stroke-linejoin="round"/>' % (d, tr, POINT_OW))
        fills.append('<path d="%s" transform="%s" fill="%s"/>' % (d, tr, fill))

    shape(wrist, '', t['skin'])
    shape(palm, '', t['skin'])
    for (x, y, w) in curled:
        shape(folded_path(w, h=w * 0.8), 'translate(%.1f %.1f)' % (x, y), t['skin'])
    shape(idx, 'translate(0 50)', t['skin'])
    shape(thumb, th_tr, t['skin'])
    # shading: the little-finger side of the palm, the far side of the index, the curled fingers turned away
    clips = ('<clipPath id="pp"><path d="%s"/></clipPath><clipPath id="pi"><path d="%s" transform="translate(0 50)"/></clipPath>'
             % (palm, idx))
    pshade = '<g clip-path="url(#pp)"><path d="M38 42 C52 58 50 90 26 104 L64 104 L64 36 Z" fill="%s"/></g>' % t['shade']
    ishade = '<g clip-path="url(#pi)"><rect x="3.2" y="-4" width="12" height="42" fill="%s"/></g>' % t['shade']
    cshade = ''.join('<path d="%s" transform="translate(%.1f %.1f)" fill="%s"/>' % (folded_path(w * 0.7, h=w * 0.55, root=0), x + w * 0.1, y - 1, t['shade'])
                     for (x, y, w) in curled)
    det.append('<path d="M5 47 Q14 44 24 47" fill="none" stroke="%s" stroke-width="1.5" stroke-linecap="round"/>' % t['crease'])
    for (x, y, w) in curled:
        det.append('<path d="M%.1f %.1f Q%.1f %.1f %.1f %.1f" fill="none" stroke="%s" stroke-width="1.5" stroke-linecap="round"/>' % (
            x - w * 0.28, y - w * 0.02, x, y + w * 0.22, x + w * 0.28, y - w * 0.02, t['crease']))
    for (x0, y0) in ((23.4, 44.5), (36.6, 47.5)):
        det.append('<path d="M%.1f %.1f L%.1f %.1f" stroke="%s" stroke-width="%.1f" stroke-linecap="round"/>' % (x0, y0, x0 + 0.6, y0 + 9, t['line'], OW * 0.8))
    det.append('<path d="M-4.2 8.6 C-4.2 3.2 4.2 3.2 4.2 8.6 L4.2 12.6 C4.2 15.6 -4.2 15.6 -4.2 12.6 Z" fill="%s" stroke="%s" stroke-width="1.2"/>' % (t['nail'], t['crease']))
    det.append('<path d="M-4 25 Q0 23 4 25 M-3 28.5 Q0 27 3 28.5" fill="none" stroke="%s" stroke-width="1.4" stroke-linecap="round"/>' % t['crease'])
    det.append('<path d="%s" transform="%s" fill="%s" stroke="%s" stroke-width="1.2"/>' % (_nail(20 * 0.86, 34), th_tr, t['nail'], t['crease']))
    det.append('<path d="M-5 -14 Q0 -16.6 5 -14" transform="%s" fill="none" stroke="%s" stroke-width="1.5" stroke-linecap="round"/>' % (th_tr, t['crease']))
    det.append('<path d="M-8 60 Q-9.5 67 -8 73" fill="none" stroke="%s" stroke-width="%.1f" stroke-linecap="round"/>' % (t['line'], OW * 0.8))
    det.append('<path d="M10 96 Q20 100 31 96" fill="none" stroke="%s" stroke-width="1.4" stroke-linecap="round"/>' % t['crease'])
    body = ('<g fill="%s" stroke="%s">%s</g>' % (t['line'], t['line'], ''.join(outl))
            + fills[0] + fills[1] + pshade + ''.join(fills[2:5]) + cshade + fills[5] + ishade + fills[6] + ''.join(det))
    shadow = '<g transform="translate(-2.5 -4)" fill="#2B2350" fill-opacity="0.2" stroke="#2B2350" stroke-opacity="0.2">%s</g>' % ''.join(outl)
    g = '<g transform="translate(%.1f %.1f) rotate(%d)">%s%s</g>' % (POINT_TIP[0], POINT_TIP[1], POINT_TURN, shadow, body)
    return ('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 %d %d" role="img" aria-label="יד מצביעה">'
            '<defs>%s</defs>%s</svg>\n') % (POINT_VB[0], POINT_VB[1], clips, g)


def main():
    os.makedirs(OUT, exist_ok=True)
    for k in range(6):
        with open(os.path.join(OUT, 'hand_left_%d.svg' % k), 'w', encoding='utf-8', newline='\n') as fh:
            fh.write(counting_hand_svg(k, TONE1))
        with open(os.path.join(OUT, 'hand_right_%d.svg' % k), 'w', encoding='utf-8', newline='\n') as fh:
            fh.write(counting_hand_svg(k, TONE1, mirror=True))
    with open(os.path.join(OUT, 'hand_point.svg'), 'w', encoding='utf-8', newline='\n') as fh:
        fh.write(pointing_hand_svg())
    if '--tone2' in sys.argv:
        d = os.environ.get('B40_TMP', os.path.join(os.environ.get('TEMP', '.'), 'b40_tone2'))
        os.makedirs(d, exist_ok=True)
        for k in range(6):
            for m, side in ((False, 'left'), (True, 'right')):
                with open(os.path.join(d, 'hand_%s_%d.svg' % (side, k)), 'w', encoding='utf-8') as fh:
                    fh.write(counting_hand_svg(k, TONE2, mirror=m))
        print(d)


if __name__ == '__main__':
    main()
