"""Draws the Israeli coins and notes of the shop (content/starter/coin_*.svg and note_*.svg). Our own drawings of the VALUE side of each
coin and the front of each note, the sides a child knows them by: the big numeral, the metal (gold-coloured for the half shekel and the
10 agorot, silver for 1, 2 and 5 shekels, silver ring round a gold centre for 10 shekels), the scalloped edge of the 5 shekel coin, and the
soft colours of the current notes (20 red, 50 green, 100 orange, 200 blue). No portrait is drawn on a note, and no text: the numerals are
drawn as thick strokes, so that every picture is plain shapes and needs no font.

    python tools/make_coin_sprites.py

Facts used, from the public list of the current coins and notes of the new shekel (https://en.wikipedia.org/wiki/Israeli_new_shekel,
read on 2026-10-28, with its photographs as the reference for the look): the coin diameters 10 agorot 22 mm, half shekel 26 mm, 1 shekel
18 mm, 2 shekels 21.6 mm, 5 shekels 24 mm, 10 shekels 23 mm with a 16 mm core; the notes 20 (129 x 71 mm), 50 (136), 100 (143), 200 (150).
The app draws each coin at its real relative size.
"""
import math
import os

OUT = os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', 'content', 'starter')

GOLD = {'base': '#D8A23D', 'edge': '#A87518', 'light': '#F3D27E', 'ink': '#7A5210'}
SILVER = {'base': '#C6CAD2', 'edge': '#8D939F', 'light': '#EEF0F4', 'ink': '#5B6270'}


def svg(w, h, body, defs=''):
    return '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 %s %s" width="%s" height="%s">%s%s</svg>\n' % (
        w, h, w, h, '<defs>%s</defs>' % defs if defs else '', body)


# ---------------------------------------------------------------- numerals as strokes, in a 100 x 100 box each
def arc(cx, cy, rx, ry, a0, a1, n=20):
    return [[cx + rx * math.cos(math.radians(a0 + (a1 - a0) * k / n)), cy + ry * math.sin(math.radians(a0 + (a1 - a0) * k / n))] for k in range(n + 1)]


GLYPH = {
    '0': [arc(50, 50, 30, 44, -90, -450, 28)],
    '1': [[[34, 28], [56, 8], [56, 92]]],
    '2': [arc(50, 31, 29, 23, -180, 25, 14) + [[20, 92], [82, 92]]],
    '3': [arc(48, 28, 25, 20, -150, 90, 12) + arc(48, 70, 29, 22, -90, 150, 14)],
    '5': [[[78, 8], [30, 8], [24, 46]] + arc(48, 68, 31, 25, -125, 140, 16)],
}


def digits(text, x, y, h, colour, width, extra=''):
    """The digits of [text], each [h] high, from the left edge x with the top at y; returns (svg, total width)."""
    out, cx = '', x
    gw = h * 0.62
    for ch in text:
        for stroke in GLYPH[ch]:
            pts = ' '.join('%.1f,%.1f' % (cx + gw * 0.5 + (px - 50) / 100 * gw * 1.15, y + py / 100 * h) for px, py in stroke)
            out += '<polyline points="%s" fill="none" stroke="%s" stroke-width="%s" stroke-linecap="round" stroke-linejoin="round" %s/>' % (pts, colour, width, extra)
        cx += gw * 1.05
    return out, cx - x


def centred(text, cx, cy, h, colour, width):
    _, w = digits(text, 0, 0, h, colour, width)
    return digits(text, cx - w / 2, cy - h / 2, h, colour, width)[0]


def fraction_half(cx, cy, h, colour, width):
    one = digits('1', cx - h * 0.3, cy - h * 0.5, h * 0.42, colour, width)[0]
    two = digits('2', cx + h * 0.02, cy + h * 0.04, h * 0.42, colour, width)[0]
    bar = '<line x1="%.1f" y1="%.1f" x2="%.1f" y2="%.1f" stroke="%s" stroke-width="%s" stroke-linecap="round"/>' % (
        cx - h * 0.25, cy + h * 0.22, cx + h * 0.28, cy - h * 0.22, colour, width * 0.8)
    return one + two + bar


# ---------------------------------------------------------------- coins
def shape(kind, r, fill, stroke_colour, sw):
    if kind == 'scallop':  # the 5 shekel coin has a wavy edge
        pts = []
        for k in range(361):
            t = math.radians(k)
            rr = r * (0.965 + 0.035 * math.cos(12 * t))
            pts.append('%.2f,%.2f' % (50 + rr * math.cos(t), 50 + rr * math.sin(t)))
        return '<polygon points="%s" fill="%s" stroke="%s" stroke-width="%s" stroke-linejoin="round"/>' % (' '.join(pts), fill, stroke_colour, sw)
    return '<circle cx="50" cy="50" r="%s" fill="%s" stroke="%s" stroke-width="%s"/>' % (r, fill, stroke_colour, sw)


def milling(r, colour, n=60):
    """The tiny marks round the rim of a coin."""
    s = ''
    for k in range(n):
        a = math.radians(k * 360 / n)
        s += '<line x1="%.1f" y1="%.1f" x2="%.1f" y2="%.1f" stroke="%s" stroke-width="1" opacity="0.55"/>' % (
            50 + (r - 3.6) * math.cos(a), 50 + (r - 3.6) * math.sin(a), 50 + r * math.cos(a), 50 + r * math.sin(a), colour)
    return s


def shine(c):
    return ('<path d="M18 36 A36 36 0 0 1 50 14" fill="none" stroke="%s" stroke-width="4" stroke-linecap="round" opacity="0.7"/>' % c['light'])


def plain_coin(c, number, kind='round', half=False):
    s = shape(kind, 47, c['base'], c['edge'], 4)
    s += milling(47, c['edge']) if kind == 'round' else ''
    s += '<circle cx="50" cy="50" r="38" fill="none" stroke="%s" stroke-width="1.8" opacity="0.8"/>' % c['light']
    s += '<circle cx="50" cy="50" r="35.5" fill="none" stroke="%s" stroke-width="1.2" opacity="0.5"/>' % c['edge']
    # a dotted ring where the words are on a real coin
    for k in range(34):
        a = math.radians(k * 360 / 34 - 90)
        if 130 < (k * 360 / 34) < 230:
            continue
        s += '<circle cx="%.1f" cy="%.1f" r="1.5" fill="%s" opacity="0.75"/>' % (50 + 41.5 * math.cos(a), 50 + 41.5 * math.sin(a), c['edge'])
    if half:
        s += fraction_half(50, 48, 58, c['ink'], 7.5)
    else:
        s += centred(number, 50, 49, 46 if len(number) == 1 else 40, c['ink'], 8.5 if len(number) == 1 else 7.5)
    # the two short lines for "new shekel" under the numeral
    s += '<line x1="34" y1="74" x2="66" y2="74" stroke="%s" stroke-width="2.4" stroke-linecap="round" opacity="0.8"/>' % c['ink']
    s += '<line x1="40" y1="80" x2="60" y2="80" stroke="%s" stroke-width="2" stroke-linecap="round" opacity="0.6"/>' % c['ink']
    return svg(100, 100, s + shine(c))


def bimetal_coin():
    ring, core = SILVER, GOLD
    s = '<circle cx="50" cy="50" r="47" fill="%s" stroke="%s" stroke-width="4"/>' % (ring['base'], ring['edge'])
    s += milling(47, ring['edge'])
    for k in range(40):  # the dots of the inscription on the ring
        a = math.radians(k * 360 / 40)
        s += '<circle cx="%.1f" cy="%.1f" r="1.3" fill="%s" opacity="0.8"/>' % (50 + 40 * math.cos(a), 50 + 40 * math.sin(a), ring['edge'])
    s += '<circle cx="50" cy="50" r="33.5" fill="%s" stroke="%s" stroke-width="2.4"/>' % (core['base'], ring['edge'])
    s += '<circle cx="50" cy="50" r="29" fill="none" stroke="%s" stroke-width="1.4" opacity="0.8"/>' % core['light']
    s += centred('10', 50, 48, 34, core['ink'], 6.8)
    s += '<line x1="38" y1="68" x2="62" y2="68" stroke="%s" stroke-width="2.2" stroke-linecap="round" opacity="0.75"/>' % core['ink']
    return svg(100, 100, s + shine(ring))


# ---------------------------------------------------------------- notes
NOTES = {
    # value: (width of the drawing for 71 mm = 100 high, gradient from, to, line colour)
    20: (182, '#E0343F', '#F8B2BC', '#9B1F2B'),
    50: (192, '#2F9E4F', '#CBE58A', '#1E6B34'),
    100: (201, '#EE8420', '#F9DA7B', '#A85A10'),
    200: (211, '#2D6FC1', '#86D6DB', '#1C4A85'),
}


def mix(a, b, t):
    """The colour a fraction t of the way from a to b (hex strings)."""
    pa = [int(a[i:i + 2], 16) for i in (1, 3, 5)]
    pb = [int(b[i:i + 2], 16) for i in (1, 3, 5)]
    return '#%02X%02X%02X' % tuple(round(x + (y - x) * t) for x, y in zip(pa, pb))


def motif(value, w, light, dark):
    """A faint picture of what is on the real note: palm branches, a citrus tree, almond blossom, autumn leaves."""
    cx = w * 0.58
    s = '<g opacity="0.5">'
    if value == 20:
        for sgn in (-1, 1):
            s += '<path d="M%.0f 90 Q%.0f 56 %.0f 36" fill="none" stroke="%s" stroke-width="3" stroke-linecap="round"/>' % (cx, cx + sgn * 8, cx + sgn * 28, light)
            for t in range(5):
                s += '<line x1="%.0f" y1="%d" x2="%.0f" y2="%d" stroke="%s" stroke-width="2" stroke-linecap="round"/>' % (
                    cx + sgn * (4 + t * 5), 78 - t * 8, cx + sgn * (14 + t * 5), 70 - t * 9, light)
    elif value == 50:
        s += '<rect x="%.0f" y="64" width="5" height="26" fill="%s"/><circle cx="%.0f" cy="46" r="21" fill="%s"/>' % (cx - 2, light, cx, light)
        for dx, dy in ((-8, 40), (7, 36), (4, 54), (-10, 54)):
            s += '<circle cx="%.0f" cy="%d" r="4" fill="%s"/>' % (cx + dx, dy, dark)
    elif value == 100:
        s += '<path d="M%.0f 90 Q%.0f 62 %.0f 28" fill="none" stroke="%s" stroke-width="3" stroke-linecap="round"/>' % (cx - 26, cx - 6, cx + 22, light)
        for fx, fy in ((cx - 12, 74), (cx + 2, 56), (cx + 14, 42), (cx + 22, 30)):
            for k in range(5):
                a = math.radians(k * 72 - 90)
                s += '<circle cx="%.1f" cy="%.1f" r="4" fill="%s"/>' % (fx + 5 * math.cos(a), fy + 5 * math.sin(a), light)
    else:
        for lx, ly, rot in ((cx - 20, 50, -30), (cx + 6, 66, 20), (cx, 34, 60), (cx + 24, 52, -50)):
            s += '<g transform="translate(%.0f %d) rotate(%d)"><path d="M0 -13 C10 -6 10 8 0 14 C-10 8 -10 -6 0 -13 Z" fill="%s"/></g>' % (lx, ly, rot, light)
    return s + '</g>'


def note(value):
    w, c0, c1, line = NOTES[value]
    # a soft fade from one colour to the other, made of rounded layers (a gradient would need url(), which the pictures may not use)
    s = '<rect x="2" y="2" width="%d" height="96" rx="7" fill="%s"/>' % (w - 4, c1)
    layers = 28
    for k in range(layers):
        t = (k + 1) / layers
        s += '<rect x="2" y="2" width="%.1f" height="96" rx="7" fill="%s"/>' % (min(w - 4, (w - 4) * (1 - t) + 14), mix(c0, c1, 1 - t))
    s += '<rect x="2" y="2" width="%d" height="96" rx="7" fill="none" stroke="%s" stroke-width="3"/>' % (w - 4, line)
    s += '<rect x="8" y="8" width="%d" height="84" rx="5" fill="none" stroke="#FFFFFF" stroke-width="1.6" opacity="0.7"/>' % (w - 16)
    for k in range(6):  # fine printed lines
        y = 16 + k * 13
        s += '<path d="M12 %d Q%d %d %d %d T%d %d" fill="none" stroke="#FFFFFF" stroke-width="1.2" opacity="0.35"/>' % (y, w * 0.25, y - 6, w * 0.5, y, w - 12, y)
    s += motif(value, w, '#FFFFFF', line)
    # the pale window where the portrait is on a real note: no person is drawn
    s += '<ellipse cx="%d" cy="58" rx="19" ry="29" fill="#FFFFFF" opacity="0.3"/><ellipse cx="%d" cy="58" rx="19" ry="29" fill="none" stroke="#FFFFFF" stroke-width="2" opacity="0.8"/>' % (w - 38, w - 38)
    # the big numeral, outlined as on the real notes, and the small one in the top corner
    text = str(value)
    big_h = 52
    x0 = 16
    s += digits(text, x0, 28, big_h, line, 17)[0]
    s += digits(text, x0, 28, big_h, '#FFFFFF', 9)[0]
    small = digits(text, 0, 0, 16, '#FFFFFF', 3.2)[1]
    s += digits(text, w - 14 - small, 12, 16, '#FFFFFF', 3.2)[0]
    return svg(w, 100, s)


def main():
    files = {
        'coin_a10': plain_coin(GOLD, '10'),
        'coin_h50': plain_coin(GOLD, '', half=True),
        'coin_s1': plain_coin(SILVER, '1'),
        'coin_s2': plain_coin(SILVER, '2'),
        'coin_s5': plain_coin(SILVER, '5', kind='scallop'),
        'coin_s10': bimetal_coin(),
    }
    for v in NOTES:
        files['note_%d' % v] = note(v)
    for name, body in files.items():
        with open(os.path.join(OUT, name + '.svg'), 'w', encoding='utf-8', newline='\n') as fh:
            fh.write(body)
    print('wrote', len(files), 'drawings')


if __name__ == '__main__':
    main()
