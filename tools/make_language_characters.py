"""The model sheet of the Languages characters (docs/languages/pictures.md section 2, batch 3 step 1), for the owner's OK
before any of their 60 pictures is drawn.

    python tools/make_language_characters.py

Writes docs/design/languages/characters_model_sheet.png (rendered by headless Chrome from SVG pieces made in a temporary
folder; nothing else is written). The sheet shows:
  Mika, the friend of the English and Russian courses: front, side, happy, thinking, a soft frown (no tear).
  Pip, the English puppet and host (the budgerigar of host_eng.svg): front (the door host), side, three expressions.
  Sasha (Са́ша), the Russian puppet and host (the giraffe of host_rus.svg): front (the door host), side, three expressions.
  The one family of all three courses: everyone in a row from the front and from the side, each face in the three
  expressions, and how the same people make the many family shapes of the personal turns (frame.md 5.2: two parents,
  one parent, grandparents, siblings; pets and "someone else" are their own cards).
  Everyone again at 64 px.

Style: the project's cast (design/assets: the avatars and the Hero Squad) for the people: flat shapes, big dark eyes with a
white spark, pink cheeks, a small smile, round soft limbs; with the thin ink outline of the approved Languages objects,
because the people stand next to those objects in the same activities. Pip and Sasha keep the look of their door art
(no outline, big ringed eyes). No text in any picture, no franchise look, no real person.

Mika: about 5, gender-neutral (short dark curls, a plain yellow T-shirt and teal shorts, bare feet so feet and toes read,
five separate fingers when a hand is drawn large). The family is diverse and warm: a mixed family with five skin tones
across three generations; the grandfather walks with a cane; the grandmother wears round glasses and the grandfather a
flat cap (the Russian brief); the brother and sister are about 9 (taller than Mika, the sister a little taller), the baby
a toddler with no clear gender (white romper). Clothes colours differ person to person, so each is told apart without
colour of skin or hair.

References looked at on 2026-11-03 (proportions and poses; the people are our own): children's height by age (a child of
5 is about 110 cm, of 9 about 133 cm, an adult about 165 to 175 cm, a toddler about 85 cm; the head is about a fifth of
a 5-year-old's height and an eighth of an adult's, here exaggerated to the cast's big-head proportions);
the cast's own boards (design/assets/avatar-*.svg, hero-*.svg) for faces and limbs; the hosts (tools/make_languages_art.py
and its references: Wikipedia Budgerigar and Giraffe, with their lead photographs) for Pip and Sasha; for a budgerigar
in profile, the Wikipedia Budgerigar photographs (the long tail, the round head, the hooked beak with the cere above).
"""
import os
import pathlib
import shutil
import subprocess
import sys
import tempfile

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import make_language_pictures as m  # noqa: E402
from make_language_pictures_b2 import bumpy  # noqa: E402

ROOT = m.ROOT
OUT = os.path.join(ROOT, 'docs', 'design', 'languages', 'characters_model_sheet.png')
LANG = os.path.join(ROOT, 'app', 'assets', 'art', 'languages')
INK, WHITE, CREAM, CHROME = m.INK, m.WHITE, m.CREAM, m.CHROME
CHEEK = '#FF9DB0'
MOUTH = '#7A2E3E'
SW = 3


def f(v):
    return ('%.1f' % v).rstrip('0').rstrip('.')


def P(d, fill, sw=SW, stroke=INK, op=None):
    o = ' opacity="%s"' % op if op is not None else ''
    st = ' stroke="%s" stroke-width="%s" stroke-linejoin="round" stroke-linecap="round"' % (stroke, sw) if sw else ''
    return '<path d="%s" fill="%s"%s%s/>' % (d, fill, st, o)


def L(d, color=INK, w=SW, op=None):
    o = ' opacity="%s"' % op if op is not None else ''
    return '<path d="%s" fill="none" stroke="%s" stroke-width="%s" stroke-linecap="round" stroke-linejoin="round"%s/>' % (d, color, w, o)


def E(cx, cy, rx, ry, fill, sw=SW, stroke=INK, op=None):
    return P(m.ell(cx, cy, rx, ry), fill, sw, stroke, op)


def RR(x, y, w, h, r, fill, sw=SW):
    return P(m.rrect(x, y, w, h, min(r, w / 2, h / 2)), fill, sw)


SKIN = {1: '#F6D2B5', 2: '#E8B48A', 3: '#C68B5E', 4: '#9A6440', 5: '#6E432A'}

FAMILY = [
    dict(id='grandfather', H=212, hr=25, skin=4, hair='cap', hairc='#C9C5D4', top='#E8E4EE', vest='#8A6A50', bottom='trousers',
         bottomc='#5E5A70', shoes='#4A3A30', extras={'beard', 'cane'}, adult=True),
    dict(id='grandmother', H=204, hr=25, skin=1, hair='bun', hairc='#C9C5D4', top='#B9A2F7', cardigan=True, bottom='skirt',
         bottomc='#6C40D0', shoes='#7A4A24', extras={'glasses'}, adult=True),
    dict(id='father', H=226, hr=26, skin=2, hair='short', hairc='#5A3E28', top='#2F7FE0', bottom='trousers',
         bottomc='#5E5A70', shoes='#3A3550', extras={'beard'}, adult=True),
    dict(id='mother', H=218, hr=26, skin=5, hair='bun', hairc='#2A2030', top='#36A852', bottom='trousers',
         bottomc='#3B5FB8', shoes='#E04F9E', extras={'earrings'}, adult=True),
    dict(id='sister', H=176, hr=27, skin=3, hair='ponytail', hairc='#2A2030', dress='#FF8A3D', shoes='#2F7FE0', extras=set()),
    dict(id='brother', H=168, hr=27, skin=4, hair='curls', hairc='#2A2030', top='#E53935', bottom='shorts', bottomc='#3B5FB8',
         shoes='#3A3550', extras=set()),
    dict(id='mika', H=142, hr=28, skin=3, hair='curls', hairc='#3A2A24', top='#FFC83D', bottom='shorts', bottomc='#1A9E9A',
         shoes=None, extras=set()),
    dict(id='baby', H=96, hr=24, skin=4, hair='tuft', hairc='#3A2A24', romper=WHITE, shoes=None, extras=set(), baby=True),
]
BY_ID = {p['id']: p for p in FAMILY}


def geometry(sp):
    H, r = sp['H'], sp['hr']
    hc = -H + r
    body = H - 2 * r
    sh = -H + 2 * r + body * 0.05
    hip = sh + body * (0.46 if sp.get('baby') else 0.42)
    tw = r * (1.9 if sp.get('adult') else 1.62 if not sp.get('baby') else 1.7)
    lw = tw * 0.36
    aw = lw * 0.82
    arm = body * (0.44 if not sp.get('baby') else 0.4)
    return H, r, hc, body, sh, hip, tw, lw, aw, arm


# ---- faces ---------------------------------------------------------------------------------------------------------

def face_front(r, hc, expr):
    ex, ey, er = r * 0.36, hc + r * 0.1, r * 0.13
    mw, my = r * 0.26, hc + r * 0.46
    out = []
    lx, ly = (er * 0.3, -er * 0.35) if expr == 'think' else (0, 0)
    for sx in (-1, 1):
        out.append(E(sx * ex + lx, ey + ly, er, er * 1.15, INK, 0))
        out.append('<circle cx="%s" cy="%s" r="%s" fill="%s"/>' % (f(sx * ex + lx - er * 0.35), f(ey + ly - er * 0.4), f(er * 0.38), WHITE))
        out.append(E(sx * r * 0.58, hc + r * 0.36, r * 0.17, r * 0.1, CHEEK, 0, op=0.6))
    if expr == 'happy':
        out.append(P('M %s %s Q 0 %s %s %s Z' % (f(-mw), f(my - 2), f(my + mw * 1.3), f(mw), f(my - 2)), MOUTH, 2.5))
        out.append(P('M %s %s Q 0 %s %s %s Q 0 %s %s %s Z' % (f(-mw * 0.55), f(my + mw * 0.55), f(my + mw * 1.2), f(mw * 0.55),
                                                               f(my + mw * 0.55), f(my + mw * 0.35), f(-mw * 0.55), f(my + mw * 0.55)),
                       '#F28AA0', 0))
    elif expr == 'think':
        out.append(L('M %s %s Q %s %s %s %s' % (f(-mw * 0.4), f(my + 4), f(mw * 0.1), f(my + 1), f(mw * 0.55), f(my - 1)), INK, 2.5))
        out.append(L('M %s %s Q %s %s %s %s' % (f(ex - er), f(ey - er * 2.6), f(ex), f(ey - er * 3.4), f(ex + er * 1.2), f(ey - er * 2.7)), INK, 2.5))
        out.append(L('M %s %s Q %s %s %s %s' % (f(-ex - er), f(ey - er * 2.2), f(-ex), f(ey - er * 2.5), f(-ex + er * 1.1), f(ey - er * 2.2)), INK, 2.5))
        for k, (dx, dy, rr) in enumerate(((r * 1.15, -r * 0.9, r * 0.08), (r * 1.35, -r * 1.2, r * 0.11), (r * 1.6, -r * 1.55, r * 0.15))):
            out.append(E(dx, hc + dy, rr, rr, WHITE, 2))
    elif expr == 'frown':
        out.append(L('M %s %s Q 0 %s %s %s' % (f(-mw * 0.7), f(my + mw * 0.45), f(my - mw * 0.15), f(mw * 0.7), f(my + mw * 0.45)), INK, 2.5))
        for sx in (-1, 1):
            out.append(L('M %s %s L %s %s' % (f(sx * (ex + er * 1.1)), f(ey - er * 1.7), f(sx * (ex - er * 0.9)), f(ey - er * 2.4)), INK, 2.5))
    else:
        out.append(L('M %s %s Q 0 %s %s %s' % (f(-mw * 0.7), f(my), f(my + mw * 0.7), f(mw * 0.7), f(my)), MOUTH, 2.5))
    return out


def face_side(r, hc):
    return [E(-r * 0.5, hc + r * 0.02, r * 0.12, r * 0.14, INK, 0),
            '<circle cx="%s" cy="%s" r="%s" fill="%s"/>' % (f(-r * 0.54), f(hc - r * 0.03), f(r * 0.045), WHITE),
            E(-r * 0.3, hc + r * 0.36, r * 0.15, r * 0.09, CHEEK, 0, op=0.6),
            L('M %s %s Q %s %s %s %s' % (f(-r * 0.86), f(hc + r * 0.48), f(-r * 0.74), f(hc + r * 0.58), f(-r * 0.6), f(hc + r * 0.5)), MOUTH, 2.5)]


# ---- hair ----------------------------------------------------------------------------------------------------------

def hair_back_front(sp, r, hc):
    st, c = sp['hair'], sp['hairc']
    if st == 'curls':
        return [P(bumpy(0, hc - r * 0.12, r * 1.12, r * 1.08, 14, 0.12), c)]
    if st == 'bun':
        return [E(0, hc - r * 1.08, r * 0.4, r * 0.36, c), E(0, hc - r * 0.1, r * 1.06, r * 1.04, c)]
    if st == 'ponytail':
        return [P('M %s %s C %s %s, %s %s, %s %s C %s %s, %s %s, %s %s Z'
                  % (f(r * 0.7), f(hc - r * 0.6), f(r * 1.5), f(hc - r * 0.4), f(r * 1.5), f(hc + r * 1.0), f(r * 1.2), f(hc + r * 1.3),
                     f(r * 1.0), f(hc + r * 0.8), f(r * 0.9), f(hc), f(r * 0.7), f(hc - r * 0.6)), c),
                E(0, hc - r * 0.1, r * 1.05, r * 1.04, c)]
    if st == 'short':
        return [E(0, hc - r * 0.12, r * 1.05, r * 1.02, c)]
    if st == 'cap':
        return [E(0, hc - r * 0.05, r * 1.04, r * 1.0, c)]
    return []


def hair_top_front(sp, r, hc):
    st, c = sp['hair'], sp['hairc']
    if st == 'curls':
        return [P(bumpy(0, hc - r * 0.62, r * 0.86, r * 0.42, 9, 0.2, 3.3), c, 0)] + [
            E(x * r, hc - r * (0.72 - abs(x) * 0.25), r * 0.26, r * 0.24, c, 0) for x in (-0.6, -0.3, 0, 0.3, 0.6)]
    if st in ('bun', 'short', 'ponytail'):
        return [P('M %s %s C %s %s, %s %s, %s %s C %s %s, %s %s, %s %s Z'
                  % (f(-r * 0.98), f(hc - r * 0.05), f(-r * 0.92), f(hc - r * 1.16), f(r * 0.92), f(hc - r * 1.16), f(r * 0.98), f(hc - r * 0.05),
                     f(r * 0.6), f(hc - r * 0.62), f(-r * 0.25), f(hc - r * 0.72), f(-r * 0.98), f(hc - r * 0.05)), c)]
    if st == 'cap':
        cap = '#7A7490'
        return [P('M %s %s C %s %s, %s %s, %s %s Z' % (f(-r * 1.04), f(hc - r * 0.36), f(-r * 0.92), f(hc - r * 1.2), f(r * 0.92), f(hc - r * 1.2),
                                                       f(r * 1.04), f(hc - r * 0.36)), cap),
                RR(-r * 1.1, hc - r * 0.5, r * 2.2, r * 0.2, r * 0.1, '#5E5A70')]
    if st == 'tuft':
        return [L('M %s %s C %s %s, %s %s, %s %s' % (f(-r * 0.1), f(hc - r * 0.95), f(-r * 0.2), f(hc - r * 1.35), f(r * 0.3), f(hc - r * 1.35),
                                                    f(r * 0.15), f(hc - r * 1.08)), c, 4)]
    return []


def hair_side(sp, r, hc):
    st, c = sp['hair'], sp['hairc']
    cap = ('M %s %s C %s %s, %s %s, %s %s C %s %s, %s %s, %s %s C %s %s, %s %s, %s %s Z'
           % (f(-r * 0.88), f(hc - r * 0.42), f(-r * 0.5), f(hc - r * 1.22), f(r * 1.2), f(hc - r * 1.12), f(r * 1.08), f(hc + r * 0.28),
              f(r * 0.86), f(hc + r * 0.5), f(r * 0.5), f(hc + r * 0.34), f(r * 0.42), f(hc + r * 0.02),
              f(r * 0.1), f(hc - r * 0.42), f(-r * 0.4), f(hc - r * 0.55), f(-r * 0.88), f(hc - r * 0.42)))
    if st == 'curls':
        return [P(bumpy(r * 0.32, hc - r * 0.2, r * 0.92, r * 0.9, 12, 0.13, 0.4), c),
                P(bumpy(r * 0.05, hc - r * 0.72, r * 0.72, r * 0.36, 9, 0.22, 3.3), c, 0)] + [
            E(x * r, hc - r * (0.8 - abs(x - 0.1) * 0.25), r * 0.24, r * 0.22, c, 0) for x in (-0.55, -0.25, 0.05, 0.35, 0.65)]
    out = [P(cap, c)]
    if st == 'bun':
        out.insert(0, E(r * 0.78, hc - r * 0.86, r * 0.36, r * 0.34, c))
    if st == 'ponytail':
        out.insert(0, P('M %s %s C %s %s, %s %s, %s %s Z' % (f(r * 0.9), f(hc - r * 0.5), f(r * 1.8), f(hc - r * 0.3), f(r * 1.6), f(hc + r * 1.2),
                                                             f(r * 1.0), f(hc + r * 0.2)), c))
    if st == 'cap':
        out = [P(cap, sp['hairc']), P('M %s %s C %s %s, %s %s, %s %s Z' % (f(-r * 0.9), f(hc - r * 0.38), f(-r * 0.6), f(hc - r * 1.22),
                                                                            f(r * 1.1), f(hc - r * 1.16), f(r * 1.06), f(hc - r * 0.36)), '#7A7490'),
               P('M %s %s L %s %s L %s %s Z' % (f(-r * 0.9), f(hc - r * 0.42), f(-r * 1.4), f(hc - r * 0.3), f(-r * 0.8), f(hc - r * 0.3)), '#5E5A70')]
    if st == 'tuft':
        out = [L('M %s %s C %s %s, %s %s, %s %s' % (f(0), f(hc - r * 0.98), f(-r * 0.1), f(hc - r * 1.35), f(r * 0.4), f(hc - r * 1.35),
                                                   f(r * 0.25), f(hc - r * 1.08)), c, 4)]
    return out


# ---- bodies --------------------------------------------------------------------------------------------------------

def person_front(sp, expr='smile'):
    H, r, hc, body, sh, hip, tw, lw, aw, arm = geometry(sp)
    skin = SKIN[sp['skin']]
    top = sp.get('top') or sp.get('dress') or sp.get('romper')
    out = []
    if 'cane' in sp['extras']:
        out.append(L('M %s %s L %s %s Q %s %s %s %s' % (f(tw * 0.95), f(-2), f(tw * 0.95), f(sh + arm * 0.9), f(tw * 0.95), f(sh + arm * 0.7),
                                                       f(tw * 0.75), f(sh + arm * 0.72)), '#7A4A24', 6))
    gap = tw * 0.06
    for sx in (-1, 1):
        x = sx * (gap / 2 + lw / 2) - lw / 2
        legc = skin
        if sp.get('bottom') == 'trousers':
            legc = sp['bottomc']
        out.append(RR(x, hip - 4, lw, -hip + 2, lw * 0.45, legc))
        if sp.get('bottom') == 'shorts' or sp.get('romper'):
            out.append(RR(x - 1, hip - 4, lw + 2, (-hip) * 0.42, lw * 0.3, sp.get('bottomc') or sp.get('romper')))
        if sp['shoes']:
            out.append(E(x + lw / 2 + sx * lw * 0.18, -lw * 0.22, lw * 0.68, lw * 0.32, sp['shoes']))
        else:
            out.append(E(x + lw / 2 + sx * lw * 0.15, -lw * 0.2, lw * 0.6, lw * 0.28, skin))
    if sp.get('bottom') == 'skirt':
        out.append(P('M %s %s L %s %s C %s %s, %s %s, %s %s L %s %s Z' % (f(-tw / 2), f(hip - 6), f(-tw * 0.72), f(-H * 0.1), f(-tw * 0.3), f(-H * 0.07),
                                                                          f(tw * 0.3), f(-H * 0.07), f(tw * 0.72), f(-H * 0.1), f(tw / 2), f(hip - 6)),
                       sp['bottomc']))
    for sx in (-1, 1):
        ax = sx * (tw / 2 + aw * 0.25) - aw / 2
        long_sleeve = sp.get('adult')
        out.append('<g transform="rotate(%s %s %s)">' % (f(sx * 5), f(sx * tw / 2), f(sh)))
        out.append(RR(ax, sh + aw * 0.1, aw, arm, aw / 2, top if long_sleeve and not sp.get('vest') else skin))
        if not long_sleeve or sp.get('vest'):
            out.append(RR(ax, sh + 2, aw, arm * 0.3, aw * 0.4, top))
        out.append(E(ax + aw / 2, sh + arm + aw * 0.2, aw * 0.62, aw * 0.62, skin))
        out.append('</g>')
    if sp.get('dress'):
        hem = hip + (-hip) * 0.42
        out.append(P('M %s %s L %s %s C %s %s, %s %s, %s %s L %s %s C %s %s, %s %s, %s %s Z'
                     % (f(-tw / 2), f(sh + 4), f(-tw * 0.78), f(hem), f(-tw * 0.3), f(hem + 6), f(tw * 0.3), f(hem + 6), f(tw * 0.78), f(hem),
                        f(tw / 2), f(sh + 4), f(tw * 0.2), f(sh - 2), f(-tw * 0.2), f(sh - 2), f(-tw / 2), f(sh + 4)), sp['dress']))
    else:
        out.append(RR(-tw / 2, sh, tw, hip - sh + body * 0.05, tw * 0.3, top))
        if sp.get('vest'):
            out.append(P('M %s %s L %s %s L %s %s L %s %s Z' % (f(-tw / 2), f(sh + 6), f(-tw * 0.12), f(sh + body * 0.18), f(-tw * 0.12), f(hip + body * 0.04),
                                                                f(-tw / 2), f(hip + body * 0.04)), sp['vest'], 0))
            out.append(P('M %s %s L %s %s L %s %s L %s %s Z' % (f(tw / 2), f(sh + 6), f(tw * 0.12), f(sh + body * 0.18), f(tw * 0.12), f(hip + body * 0.04),
                                                                f(tw / 2), f(hip + body * 0.04)), sp['vest'], 0))
            out.append(RR(-tw / 2, sh, tw, hip - sh + body * 0.05, tw * 0.3, 'none'))
        if sp.get('cardigan'):
            out.append(L('M 0 %s L 0 %s' % (f(sh + 6), f(hip + body * 0.04)), INK, 2.5))
            out += [E(-tw * 0.08, sh + body * k, 2.6, 2.6, '#FFC83D', 1.5) for k in (0.12, 0.22, 0.32)]
    out.append(RR(-r * 0.24, hc + r * 0.7, r * 0.48, sh - hc - r * 0.6, r * 0.2, skin))
    out += hair_back_front(sp, r, hc)
    for sx in (-1, 1):
        out.append(E(sx * r * 0.98, hc + r * 0.12, r * 0.2, r * 0.24, skin))
    out.append(E(0, hc, r, r * 1.02, skin))
    out += hair_top_front(sp, r, hc)
    out += face_front(r, hc, expr)
    if 'beard' in sp['extras']:
        bc = sp['hairc']
        out.append(P('M %s %s C %s %s, %s %s, %s %s C %s %s, %s %s, %s %s C %s %s, %s %s, %s %s Z'
                     % (f(-r * 0.86), f(hc + r * 0.3), f(-r * 0.8), f(hc + r * 1.2), f(r * 0.8), f(hc + r * 1.2), f(r * 0.86), f(hc + r * 0.3),
                        f(r * 0.5), f(hc + r * 0.62), f(r * 0.3), f(hc + r * 0.34), f(0), f(hc + r * 0.36),
                        f(-r * 0.3), f(hc + r * 0.34), f(-r * 0.5), f(hc + r * 0.62), f(-r * 0.86), f(hc + r * 0.3)), bc))
        if expr == 'happy':
            out.append(P('M %s %s Q 0 %s %s %s Z' % (f(-r * 0.24), f(hc + r * 0.48), f(hc + r * 0.78), f(r * 0.24), f(hc + r * 0.48)), MOUTH, 2))
        elif expr == 'frown':
            out.append(L('M %s %s Q 0 %s %s %s' % (f(-r * 0.2), f(hc + r * 0.6), f(hc + r * 0.48), f(r * 0.2), f(hc + r * 0.6)), INK, 2.5))
        else:
            out.append(L('M %s %s Q 0 %s %s %s' % (f(-r * 0.2), f(hc + r * 0.5), f(hc + r * 0.64), f(r * 0.2), f(hc + r * 0.5)), MOUTH, 2.5))
    if 'glasses' in sp['extras']:
        for sx in (-1, 1):
            out.append(E(sx * r * 0.36, hc + r * 0.1, r * 0.24, r * 0.24, 'none', 2.5))
        out.append(L('M %s %s Q 0 %s %s %s' % (f(-r * 0.12), f(hc + r * 0.06), f(hc), f(r * 0.12), f(hc + r * 0.06)), INK, 2.5))
    if 'earrings' in sp['extras']:
        out += [E(sx * r * 0.98, hc + r * 0.42, 3, 3, '#FFC83D', 1.5) for sx in (-1, 1)]
    return out


def person_side(sp):
    H, r, hc, body, sh, hip, tw, lw, aw, arm = geometry(sp)
    skin = SKIN[sp['skin']]
    top = sp.get('top') or sp.get('dress') or sp.get('romper')
    out = []
    dark = '#2A2433'
    legc = sp['bottomc'] if sp.get('bottom') == 'trousers' else skin
    for k, dx in ((1, lw * 0.25), (0, -lw * 0.3)):
        out.append(RR(dx - lw / 2, hip - 4, lw, -hip + 2, lw * 0.45, legc))
        out.append(P(m.rrect(dx - lw / 2, hip - 4, lw, -hip + 2, lw * 0.45), dark, 0, op=0.18 if k else 0))
        if sp.get('bottom') == 'shorts' or sp.get('romper'):
            out.append(RR(dx - lw / 2 - 1, hip - 4, lw + 2, (-hip) * 0.42, lw * 0.3, sp.get('bottomc') or sp.get('romper')))
        out.append(E(dx - lw * 0.3, -lw * 0.22, lw * 0.78, lw * 0.3, sp['shoes'] or skin))
    if sp.get('bottom') == 'skirt':
        out.append(P('M %s %s L %s %s L %s %s L %s %s Z' % (f(-tw * 0.32), f(hip - 6), f(-tw * 0.5), f(-H * 0.1), f(tw * 0.5), f(-H * 0.1),
                                                            f(tw * 0.32), f(hip - 6)), sp['bottomc']))
    if sp.get('dress'):
        hem = hip + (-hip) * 0.42
        out.append(P('M %s %s L %s %s L %s %s L %s %s Z' % (f(-tw * 0.3), f(sh + 4), f(-tw * 0.55), f(hem), f(tw * 0.55), f(hem), f(tw * 0.3), f(sh + 4)),
                     sp['dress']))
    else:
        out.append(RR(-tw * 0.32, sh, tw * 0.64, hip - sh + body * 0.05, tw * 0.25, top))
        if sp.get('vest'):
            out.append(RR(-tw * 0.32, sh + 4, tw * 0.5, hip - sh, tw * 0.2, sp['vest']))
    long_sleeve = sp.get('adult') and not sp.get('vest')
    out.append('<g transform="rotate(-6 0 %s)">' % f(sh))
    out.append(RR(-aw / 2, sh + aw * 0.1, aw, arm, aw / 2, top if long_sleeve else skin))
    if not long_sleeve:
        out.append(RR(-aw / 2 - 1, sh, aw + 2, arm * 0.36, aw * 0.4, top))
    out.append(E(0, sh + arm + aw * 0.2, aw * 0.62, aw * 0.62, skin))
    out.append('</g>')
    if 'cane' in sp['extras']:
        out.append(L('M %s %s L %s %s Q %s %s %s %s' % (f(-tw * 0.7), f(-2), f(-tw * 0.7), f(sh + arm * 0.95), f(-tw * 0.7), f(sh + arm * 0.75),
                                                       f(-tw * 0.15), f(sh + arm * 0.98)), '#7A4A24', 6))
    out.append(RR(-r * 0.2, hc + r * 0.7, r * 0.44, sh - hc - r * 0.6, r * 0.2, skin))
    hs = hair_side(sp, r, hc)
    if sp['hair'] in ('bun', 'ponytail', 'curls'):
        out.append(hs.pop(0))
    out.append(E(r * 0.05, hc, r, r * 1.02, skin))
    out.append(E(-r * 0.98, hc + r * 0.14, r * 0.15, r * 0.15, skin))
    out.append(P('M %s %s C %s %s, %s %s, %s %s' % (f(r * 0.2), f(hc - r * 0.06), f(r * 0.46), f(hc - r * 0.12), f(r * 0.48), f(hc + r * 0.36),
                                                   f(r * 0.22), f(hc + r * 0.32)), skin, 2.5))
    out.append(L('M %s %s Q %s %s %s %s' % (f(r * 0.27), f(hc + r * 0.04), f(r * 0.38), f(hc + r * 0.12), f(r * 0.28), f(hc + r * 0.24)), INK, 2))
    out += hs
    out += face_side(r, hc)
    if 'beard' in sp['extras']:
        out.append(P('M %s %s C %s %s, %s %s, %s %s C %s %s, %s %s, %s %s Z'
                     % (f(r * 0.3), f(hc + r * 0.3), f(r * 0.2), f(hc + r * 1.1), f(-r * 0.8), f(hc + r * 1.1), f(-r * 0.82), f(hc + r * 0.62),
                        f(-r * 0.5), f(hc + r * 0.7), f(-r * 0.1), f(hc + r * 0.5), f(r * 0.3), f(hc + r * 0.3)), sp['hairc']))
    if 'glasses' in sp['extras']:
        out.append(E(-r * 0.52, hc + r * 0.04, r * 0.24, r * 0.24, 'none', 2.5))
        out.append(L('M %s %s L %s %s' % (f(-r * 0.28), f(hc), f(r * 0.2), f(hc - r * 0.02)), INK, 2.5))
    return out


def shadow(rx, ry=7):
    return '<ellipse cx="0" cy="0" rx="%s" ry="%s" fill="%s" opacity="0.12"/>' % (f(rx), f(ry), INK)


# ---- Pip (the budgerigar) and Sasha (the giraffe), in the look of their door art -----------------------------------

PIP = dict(green='#6CC24A', green_d='#4E9F33', belly='#93D96B', yellow='#FFD93D', face='#E9C22C', cheek='#5B6FD6',
           cere='#4F8FE8', beak='#9A9C86', tail='#3E6FD9', wing='#3C7F2A', feet='#8EA3C4')


def pip_side():
    c = PIP
    out = ['<ellipse cx="256" cy="470" rx="120" ry="12" fill="%s" opacity="0.12"/>' % INK]
    out.append('<path d="M 300 340 L 460 452 Q 456 470 436 466 L 288 372 Z" fill="%s"/>' % c['tail'])
    for x in (238, 270):
        out.append('<path d="M %d 410 L %d 452 M %d 452 l -18 8 M %d 452 l 16 8" fill="none" stroke="%s" stroke-width="10" '
                   'stroke-linecap="round"/>' % (x, x, x, x, c['feet']))
    out.append('<ellipse cx="262" cy="320" rx="96" ry="112" fill="%s"/>' % c['green'])
    out.append('<ellipse cx="236" cy="346" rx="58" ry="78" fill="%s"/>' % c['belly'])
    out.append('<path d="M 262 252 C 340 250, 372 330, 344 410 C 316 380, 290 330, 262 252 Z" fill="%s"/>' % c['wing'])
    for k in range(4):
        y = 286 + k * 28
        out.append('<path d="M %d %d q 10 10 20 0 q 10 10 20 0" fill="none" stroke="%s" stroke-width="5" stroke-linecap="round"/>'
                   % (284 + k * 6, y, c['yellow']))
    out.append('<circle cx="236" cy="172" r="92" fill="%s"/>' % c['face'])
    out.append('<circle cx="230" cy="164" r="84" fill="%s"/>' % c['yellow'])
    out.append('<path d="M 300 120 q 14 6 22 18 M 310 150 q 12 6 16 18" fill="none" stroke="%s" stroke-width="5" stroke-linecap="round"/>'
               % c['green_d'])
    out.append('<ellipse cx="196" cy="214" rx="18" ry="12" fill="%s"/>' % c['cheek'])
    out += ['<circle cx="%d" cy="%d" r="6" fill="#3B2C85"/>' % xy for xy in ((176, 240), (198, 248), (220, 252))]
    out.append('<rect x="130" y="168" width="26" height="14" rx="7" fill="%s"/>' % c['cere'])
    out.append('<path d="M 132 182 Q 104 190 110 222 Q 130 212 150 196 Z" fill="%s"/>' % c['beak'])
    out.append('<circle cx="186" cy="156" r="21" fill="#FFF7D6"/><circle cx="182" cy="158" r="13" fill="#3B2C85"/>'
               '<circle cx="177" cy="153" r="4.5" fill="%s"/>' % WHITE)
    return out


def pip_head(expr):
    c = PIP
    out = ['<circle cx="256" cy="380" r="150" fill="%s"/>' % c['green'],
           '<circle cx="256" cy="200" r="150" fill="%s"/>' % c['face'],
           '<circle cx="252" cy="192" r="140" fill="%s"/>' % c['yellow']]
    out += ['<ellipse cx="%d" cy="262" rx="28" ry="20" fill="%s"/>' % (x, c['cheek']) for x in (150, 362)]
    out += ['<circle cx="%d" cy="%d" r="9" fill="#3B2C85"/>' % xy for xy in ((196, 320), (226, 334), (286, 334), (316, 320))]
    out.append('<rect x="228" y="232" width="56" height="22" rx="11" fill="%s"/>' % c['cere'])
    out.append('<path d="M 222 254 Q 256 244 290 254 Q 288 290 256 310 Q 224 290 222 254 Z" fill="%s"/>' % c['beak'])
    for x in (186, 326):
        if expr == 'happy':
            out.append('<path d="M %d 200 Q %d 172 %d 200" fill="none" stroke="#3B2C85" stroke-width="12" stroke-linecap="round"/>'
                       % (x - 30, x, x + 30))
        else:
            dx, dy = (8, -10) if expr == 'think' else (0, 4)
            out.append('<circle cx="%d" cy="196" r="36" fill="#FFF7D6"/><circle cx="%d" cy="%d" r="22" fill="#3B2C85"/>'
                       '<circle cx="%d" cy="%d" r="7" fill="%s"/>' % (x, x + dx, 196 + dy, x + dx - 7, 196 + dy - 8, WHITE))
    if expr == 'think':
        out.append('<path d="M 296 136 Q 326 112 360 130" fill="none" stroke="%s" stroke-width="10" stroke-linecap="round"/>' % c['green_d'])
        out += ['<circle cx="%d" cy="%d" r="%d" fill="%s" stroke="%s" stroke-width="4"/>' % (x, y, rr, WHITE, INK)
                for x, y, rr in ((410, 120, 12), (440, 82, 17), (470, 40, 23))]
    if expr == 'frown':
        out += ['<path d="M %d %d L %d %d" fill="none" stroke="%s" stroke-width="10" stroke-linecap="round"/>' % (a, b, cc, d, c['green_d'])
                for a, b, cc, d in ((150, 150, 210, 130), (362, 150, 302, 130))]
        out += ['<path d="M %d 186 Q %d 172 %d 186" fill="%s"/>' % (x - 36, x, x + 36, c['yellow']) for x in (186, 326)]
    return out


GIR = dict(base='#F8D9A0', patch='#D9823B', line='#FCEBC8', mane='#B8612A', tuft='#6B3E1E', muzzle='#FBEBCD', body='#E8B26A',
           ear_in='#F4C2B4', eye='#3B2C85')


def sasha_side():
    c = GIR
    out = ['<ellipse cx="270" cy="470" rx="140" ry="12" fill="%s" opacity="0.12"/>' % INK]
    out.append('<path d="M 400 330 Q 432 352 428 392" fill="none" stroke="%s" stroke-width="8" stroke-linecap="round"/>' % c['body'])
    out.append('<ellipse cx="428" cy="400" rx="10" ry="16" fill="%s"/>' % c['tuft'])
    for x, col in ((236, c['body']), (372, c['body']), (264, c['base']), (344, c['base'])):
        out.append('<rect x="%d" y="350" width="30" height="104" rx="12" fill="%s"/>' % (x - 15, col))
        out.append('<rect x="%d" y="440" width="30" height="18" rx="6" fill="#5C3A22"/>' % (x - 15))
    out.append('<ellipse cx="304" cy="340" rx="118" ry="64" fill="%s"/>' % c['body'])
    out.append('<ellipse cx="300" cy="334" rx="108" ry="56" fill="%s"/>' % c['base'])
    out += ['<ellipse cx="%d" cy="%d" rx="22" ry="16" fill="%s"/>' % (x, y, c['patch']) for x, y in ((250, 320), (304, 310), (356, 324), (282, 356), (334, 358))]
    out.append('<path d="M 214 330 L 168 168 Q 196 148 226 166 L 276 322 Z" fill="%s"/>' % c['body'])
    out.append('<path d="M 222 322 L 180 172 Q 198 162 216 172 L 262 316 Z" fill="%s"/>' % c['base'])
    out += ['<ellipse cx="%d" cy="%d" rx="11" ry="9" fill="%s"/>' % (x, y, c['patch']) for x, y in ((206, 210), (222, 256), (238, 298))]
    out.append('<path d="M 226 166 L 276 322" fill="none" stroke="%s" stroke-width="10" stroke-linecap="round"/>' % c['mane'])
    for x in (176, 200):
        out.append('<rect x="%d" y="42" width="14" height="46" rx="7" fill="%s"/><circle cx="%d" cy="42" r="13" fill="%s"/>' % (x - 7, c['body'], x, c['tuft']))
    out.append('<ellipse cx="236" cy="96" rx="36" ry="15" fill="%s" transform="rotate(-16 236 96)"/>' % c['body'])
    out.append('<ellipse cx="232" cy="96" rx="24" ry="8" fill="%s" transform="rotate(-16 232 96)"/>' % c['ear_in'])
    out.append('<ellipse cx="170" cy="130" rx="70" ry="60" fill="%s"/>' % c['body'])
    out.append('<ellipse cx="166" cy="126" rx="62" ry="54" fill="%s"/>' % c['base'])
    out.append('<ellipse cx="112" cy="156" rx="38" ry="30" fill="%s"/>' % c['muzzle'])
    out.append('<ellipse cx="96" cy="146" rx="5" ry="7" fill="#8A5634"/>')
    out.append('<path d="M 96 172 Q 112 182 128 172" fill="none" stroke="%s" stroke-width="5" stroke-linecap="round"/>' % c['eye'])
    out.append('<ellipse cx="156" cy="110" rx="16" ry="20" fill="%s"/><circle cx="150" cy="102" r="6" fill="%s"/>' % (c['eye'], WHITE))
    out.append('<path d="M 140 88 l -6 -10 M 150 86 l -2 -12 M 160 88 l 2 -11" fill="none" stroke="%s" stroke-width="4" stroke-linecap="round"/>' % c['eye'])
    out.append('<ellipse cx="168" cy="152" rx="13" ry="8" fill="#F4A7B4" opacity="0.8"/>')
    return out


def sasha_head(expr):
    c = GIR
    out = ['<path d="M 214 512 L 226 300 Q 256 280 286 300 L 298 512 Z" fill="%s"/>' % c['body']]
    out += ['<ellipse cx="%d" cy="%d" rx="12" ry="10" fill="%s"/>' % (x, y, c['patch']) for x, y in ((246, 380), (268, 440), (244, 490))]
    for x in (206, 306):
        out.append('<rect x="%d" y="40" width="16" height="56" rx="8" fill="%s"/><circle cx="%d" cy="40" r="16" fill="%s"/>' % (x - 8, c['body'], x, c['tuft']))
    for x, a in ((130, 18), (382, -18)):
        out.append('<ellipse cx="%d" cy="140" rx="48" ry="20" fill="%s" transform="rotate(%d %d 140)"/>' % (x, c['body'], a, x))
        out.append('<ellipse cx="%d" cy="141" rx="32" ry="11" fill="%s" transform="rotate(%d %d 141)"/>' % (x, c['ear_in'], a, x))
    out.append('<ellipse cx="256" cy="180" rx="104" ry="94" fill="%s"/>' % c['body'])
    out.append('<ellipse cx="256" cy="174" rx="96" ry="86" fill="%s"/>' % c['base'])
    out.append('<ellipse cx="256" cy="236" rx="62" ry="44" fill="%s"/>' % c['muzzle'])
    out += ['<ellipse cx="%d" cy="226" rx="6" ry="9" fill="#8A5634"/>' % x for x in (234, 278)]
    out += ['<ellipse cx="%d" cy="214" rx="18" ry="11" fill="#F4A7B4" opacity="0.8"/>' % x for x in (174, 338)]
    for x in (210, 302):
        if expr == 'happy':
            out.append('<path d="M %d 160 Q %d 132 %d 160" fill="none" stroke="%s" stroke-width="11" stroke-linecap="round"/>' % (x - 24, x, x + 24, c['eye']))
        else:
            dx, dy = (6, -8) if expr == 'think' else (0, 4)
            out.append('<ellipse cx="%d" cy="%d" rx="22" ry="27" fill="%s"/><circle cx="%d" cy="%d" r="7" fill="%s"/>'
                       % (x + dx, 156 + dy, c['eye'], x + dx - 7, 148 + dy, WHITE))
            out.append('<path d="M %d 128 l -6 -12 M %d 124 l 0 -13 M %d 128 l 6 -12" fill="none" stroke="%s" stroke-width="4" stroke-linecap="round"/>'
                       % (x - 12, x, x + 12, c['eye']))
    if expr == 'happy':
        out.append('<path d="M 226 252 Q 256 286 286 252 Z" fill="%s"/>' % MOUTH)
    elif expr == 'think':
        out.append('<path d="M 240 262 Q 262 254 282 256" fill="none" stroke="%s" stroke-width="6" stroke-linecap="round"/>' % c['eye'])
        out.append('<path d="M 284 112 Q 306 98 330 110" fill="none" stroke="%s" stroke-width="7" stroke-linecap="round"/>' % c['mane'])
        out += ['<circle cx="%d" cy="%d" r="%d" fill="%s" stroke="%s" stroke-width="4"/>' % (x, y, rr, WHITE, INK)
                for x, y, rr in ((400, 70, 12), (432, 40, 16), (466, 14, 20))]
    elif expr == 'frown':
        out.append('<path d="M 232 268 Q 256 252 280 268" fill="none" stroke="%s" stroke-width="6" stroke-linecap="round"/>' % c['eye'])
        out += ['<path d="M %d %d L %d %d" fill="none" stroke="%s" stroke-width="7" stroke-linecap="round"/>' % (a, b, cc, d, c['mane'])
                for a, b, cc, d in ((182, 120, 230, 106), (330, 120, 282, 106))]
    else:
        out.append('<path d="M 230 258 Q 256 278 282 258" fill="none" stroke="%s" stroke-width="6" stroke-linecap="round"/>' % c['eye'])
    return out


# ---- the sheet -----------------------------------------------------------------------------------------------------

def svg(parts, vb):
    return '<svg xmlns="http://www.w3.org/2000/svg" viewBox="%s">%s</svg>\n' % (' '.join(f(v) for v in vb), ''.join(parts))


def figure_svg(parts, sp, pad=1.0):
    H, r = sp['H'], sp['hr']
    w = max(r * 3.8, H * 0.5)
    top = H + r * 0.7
    return svg(['<g>%s</g>' % shadow(r * 1.6)] + parts, (-w / 2, -top, w, top + 12))


def head_svg(parts, sp):
    H, r = sp['H'], sp['hr']
    hc = -H + r
    return svg(parts, (-r * 2.0, hc - r * 2.0, r * 4.0, r * 3.6))


def lineup(view):
    xs, parts, x = [], [], 0
    for sp in FAMILY:
        w = sp['hr'] * 3.0
        x += w / 2
        body = person_front(sp) if view == 'front' else person_side(sp)
        parts.append('<g transform="translate(%s 0)">%s%s</g>' % (f(x), shadow(sp['hr'] * 1.5), ''.join(body)))
        x += w / 2 + 14
    return svg(parts, (-10, -250, x + 10, 262))


def group_card(ids, bg):
    xs, parts, x = [], [], 0
    for i in ids:
        sp = BY_ID[i]
        w = sp['hr'] * 3.0
        x += w / 2
        parts.append('<g transform="translate(%s 0)">%s%s</g>' % (f(x), shadow(sp['hr'] * 1.4), ''.join(person_front(sp))))
        x += w / 2 + 6
    pad = 20
    return svg(['<rect x="%s" y="-252" width="%s" height="276" rx="24" fill="%s"/>' % (f(-pad), f(x + 2 * pad), bg)] + parts,
               (-pad, -252, x + 2 * pad, 276))


def build(tmp):
    pieces = {}

    def put(name, text):
        pieces[name] = os.path.join(tmp, name + '.svg')
        with open(pieces[name], 'w', encoding='utf-8') as fh:
            fh.write(text)

    mika = BY_ID['mika']
    put('mika-front', figure_svg(person_front(mika), mika))
    put('mika-side', figure_svg(person_side(mika), mika))
    for e in ('happy', 'think', 'frown'):
        put('mika-' + e, head_svg(person_front(mika, e), mika))
    shutil.copy(os.path.join(LANG, 'host_eng.svg'), os.path.join(tmp, 'pip-front.svg'))
    pieces['pip-front'] = os.path.join(tmp, 'pip-front.svg')
    put('pip-side', svg(pip_side(), (0, 0, 512, 512)))
    for e in ('happy', 'think', 'frown'):
        put('pip-' + e, svg(pip_head(e), (40, 0, 480, 512)))
    shutil.copy(os.path.join(LANG, 'host_rus.svg'), os.path.join(tmp, 'sasha-front.svg'))
    pieces['sasha-front'] = os.path.join(tmp, 'sasha-front.svg')
    put('sasha-side', svg(sasha_side(), (0, 0, 512, 512)))
    for e in ('happy', 'think', 'frown'):
        put('sasha-' + e, svg(sasha_head(e), (40, 0, 480, 512)))
    put('family-front', lineup('front'))
    put('family-side', lineup('side'))
    for sp in FAMILY:
        for e in ('happy', 'think', 'frown'):
            put('%s-%s' % (sp['id'], e), head_svg(person_front(sp, e), sp))
        put(sp['id'] + '-small', figure_svg(person_front(sp), sp))
    cards = (('card-two-parents', ('mother', 'mika', 'father'), '#DEEBFC'), ('card-one-parent', ('father', 'baby'), '#FCE1F0'),
             ('card-grandparents', ('grandmother', 'mika', 'grandfather'), '#FEEFD6'), ('card-siblings', ('sister', 'brother', 'mika'), '#DDF3E6'))
    for name, ids, bg in cards:
        put(name, group_card(ids, bg))
    return pieces, [c[0] for c in cards]


def html(pieces, cards):
    def img(name, w, h=None, cls='c'):
        return '<img class="%s" src="%s" style="width:%dpx;height:%dpx">' % (cls, pathlib.Path(pieces[name]).as_uri(), w, h or w)

    def row(title, names, labels, w=200, h=None):
        cells = ''.join('<div class="cell">%s<span>%s</span></div>' % (img(n, w, h), lab) for n, lab in zip(names, labels))
        return '<h2>%s</h2><div class="row">%s</div>' % (title, cells)

    exprs = ['happy', 'thinking', 'a soft frown (no tear)']
    body = '<h1>Languages characters: model sheet for the owner (2026-11-03)</h1>'
    body += row('Mika, the friend (English and Russian): about 5, gender-neutral',
                ['mika-front', 'mika-side', 'mika-happy', 'mika-think', 'mika-frown'], ['front', 'side'] + exprs)
    body += row('Pip, the English puppet and host (a budgerigar)', ['pip-front', 'pip-side', 'pip-happy', 'pip-think', 'pip-frown'],
                ['front (the door host)', 'side'] + exprs)
    body += row('Sasha (Са́ша), the Russian puppet and host (a giraffe)', ['sasha-front', 'sasha-side', 'sasha-happy', 'sasha-think', 'sasha-frown'],
                ['front (the door host)', 'side'] + exprs)
    body += '<h2>The family of all three courses, front and side (grandfather, grandmother, father, mother, sister, brother, Mika, the baby)</h2>'
    body += '<div class="row">%s</div><div class="row">%s</div>' % (img('family-front', 1180, 250, 'w'), img('family-side', 1180, 250, 'w'))
    body += '<h2>Each face in the three expressions (happy, thinking, a soft frown)</h2><div class="row">'
    for sp in FAMILY:
        if sp['id'] == 'mika':
            continue
        body += '<div class="cell">%s%s%s<span>%s</span></div>' % (img(sp['id'] + '-happy', 110), img(sp['id'] + '-think', 110),
                                                                   img(sp['id'] + '-frown', 110), sp['id'])
    body += '</div>'
    body += '<h2>The same people make the family shapes of the personal turns (frame 5.2; pets and "someone else" are their own cards)</h2>'
    body += '<div class="row">%s</div>' % ''.join('<div class="cell">%s<span>%s</span></div>' % (img(c, 270, 230, 'k'), c.replace('card-', '').replace('-', ' '))
                                                  for c in cards)
    small = ['mika-front', 'pip-front', 'sasha-front'] + [sp['id'] + '-small' for sp in FAMILY if sp['id'] != 'mika']
    body += '<h2>At 64 px</h2><div class="row">%s</div>' % ''.join(img(n, 64, cls='s') for n in small)
    return ('<html><body style="margin:0;padding:16px;background:#FFF6E8;width:1240px;font:14px sans-serif;color:#2B2350">'
            '<style>h1{font-size:22px;margin:4px 0 8px}h2{font-size:15px;margin:18px 0 6px}.row{display:flex;flex-wrap:wrap;gap:10px}'
            '.cell{text-align:center;display:flex;flex-direction:column;align-items:center}.c,.w{background:#fff;border-radius:16px}'
            '.w{width:auto!important}.k{width:auto!important}.s{background:#fff;border-radius:10px}.cell span{margin-top:4px}</style>%s</body></html>' % body)


def main():
    tmp = tempfile.mkdtemp(prefix='nitznutz_chars_')
    try:
        pieces, cards = build(tmp)
        page = os.path.join(tmp, 'sheet.html')
        with open(page, 'w', encoding='utf-8') as fh:
            fh.write(html(pieces, cards))
        subprocess.run([CHROME, '--headless=new', '--disable-gpu', '--hide-scrollbars', '--force-device-scale-factor=1',
                        '--allow-file-access-from-files', '--screenshot=' + OUT, '--window-size=1272,2330',
                        pathlib.Path(page).as_uri()], check=True, capture_output=True)
        print('sheet', os.path.relpath(OUT, ROOT))
        if '--keep' in sys.argv:
            keep = os.path.join(os.environ.get('TEMP', tmp), 'nitznutz_chars_keep')
            shutil.rmtree(keep, ignore_errors=True)
            shutil.copytree(tmp, keep)
            print('pieces', keep)
    finally:
        shutil.rmtree(tmp, ignore_errors=True)


if __name__ == '__main__':
    main()
