"""The pattern-strip cards of Riddle Grotto's LOG-A-04, "is this a pattern?" (ages 3 to 4; M11 Stage 2, the curriculum-expert's
recut in content/units/pending/stage2-recuts.json, its `sprites` list). Each card is one row of six pictures that the child sorts
into "repeats" or "does not repeat". Writes content/starter/strip_<name>.svg, 120 x 48:

    python tools/make_pattern_strips.py            # writes the eight cards
    python tools/make_pattern_strips.py --sheet    # also docs/design/m11/pattern-strips-2026-11-16.png (the contact sheet)

The pictures in the cells are the pack's own drawings, taken from tools/make_logic_sprites.py (the ball in the Colour Bay hues,
the Languages cat, dog, fish, star and apple, Riddle Grotto's bird and duck), so the child sorts the cat and the ball they already
know. They are drawn about a fifth of their size, so each one gets a sticker edge: an ink contour a little wider than the
picture (its own shapes, filled and stroked in ink, under it). Without it the 3-unit outline of a 100 canvas is a third of a
point on an 84-point tile and the pictures melt into each other. The ground shadows are left out (a row of six shadows reads
as a line under the row, and a shadow at that size is a smudge).

The row is drawn left to right in the order of the list and the app must never mirror it (patterns never mirror, design-spec
section 8). Whether a row repeats does not depend on the side it is read from, so the answer is the same for a child who reads
from the right; the order is kept for the hints and the voice, which name the places from the list.

The card: paper with an ink edge, six mist wells (color.core.mist) that hold the pictures one per place, so even at the
26-point size of a sorted card in a bin the six places stay six. Nothing marks the place that breaks the rule: finding it is the
task. Colour is the content of the two colour rows (red and blue, green and yellow: the far-apart hues of make_picture_sprites
COLOURS, and green-yellow also far apart in lightness); the animal rows differ by outline (the sitting cat seen from the front,
the standing dog seen from the side, the white duck on its water) and not only by colour. The ball rows keep the ball's own
look in every cell, so the one thing that changes is the colour.

References: the drawings carry their own (tools/make_logic_sprites.py, tools/make_language_pictures.py and _b2.py). For the
card, looked at on 2026-11-16: the early-years "pattern strip" cards of preschool maths (a web search "preschool AB pattern
strip cards"; e.g. the pattern-making activities of nrich.maths.org/13250 and the DIY strips of preschoolinspirations.com):
a long card, the pictures in equal boxes in one row, one picture per box, no arrows and no marks. Ours is our own; no text, no
numeral, no brand.
"""
import os
import pathlib
import re
import subprocess
import sys

ROOT = os.path.normpath(os.path.join(os.path.dirname(os.path.abspath(__file__)), '..'))
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import make_logic_sprites as S   # noqa: E402  (the pictures themselves)

OUT = os.path.join(ROOT, 'content', 'starter')
SHEET = os.path.join(ROOT, 'docs', 'design', 'm11', 'pattern-strips-2026-11-16.png')
INK = S.INK
PAPER = '#FFFFFF'
MIST = '#EDE6F7'   # color.core.mist: wells and empty sockets
W, H = 120, 48

# What each card shows, left to right (stage2-recuts.json `sprites`); the comment is the answer.
STRIPS = {
    'strip_red_blue': ['ball_red', 'ball_blue'] * 3,                                    # repeats (AB)
    'strip_cat_dog': ['cat', 'dog'] * 3,                                                # repeats (AB)
    'strip_green_yellow': ['ball_green', 'ball_yellow'] * 3,                            # repeats (AB)
    'strip_fish_bird': ['fish', 'bird'] * 3,                                            # repeats (AB)
    'strip_mixed_balls': ['ball_red', 'ball_blue', 'ball_green', 'ball_red', 'ball_yellow', 'ball_blue'],  # no rule
    'strip_mixed_things': ['star', 'apple', 'fish', 'cat', 'apple', 'star'],           # no rule
    'strip_red_blue_slip': ['ball_red', 'ball_blue', 'ball_red', 'ball_green', 'ball_red', 'ball_blue'],  # place 4 slips
    'strip_cat_dog_slip': ['cat', 'dog', 'cat', 'dog', 'duck', 'dog'],                 # place 5 slips
}
REPEATS = {'strip_red_blue', 'strip_cat_dog', 'strip_green_yellow', 'strip_fish_bird'}

# The part of each 100 x 100 picture that the cell shows (x, y, side): the drawings leave room round them for their shadow
# and their tile, which a cell of 18 units cannot spare. Each crop is square, so no picture is squeezed.
CROP = {'ball': (8, 8, 84), 'cat': (12, 8, 86), 'dog': (8, 10, 86), 'fish': (6, 8, 88), 'bird': (2, 6, 96),
        'duck': (2, 6, 94), 'star': (8, 6, 86), 'apple': (10, 8, 84)}

PAD = 3.0            # card edge to the first well
GAP = 1.4            # between wells
WELL_H = 30.0        # a well is taller than wide: a slot of the strip
EDGE = 12.0          # the sticker edge, in the units of a 100 canvas (half of it shows outside the picture)

_ELEM = re.compile(r'<(path|ellipse|circle|rect|polygon|line)\b([^>]*?)/>')


def body_of(svg_text):
    """The inside of a picture's <svg> element."""
    return re.sub(r'^<svg[^>]*>|</svg>\s*$', '', svg_text.strip())


def no_shadow(body):
    """Leaves out the soft ground shadows (an ink ellipse at 0.12 or 0.13) and the fish's three air bubbles (rings in
    #5BB8E0): at a fifth of its size a bubble is a speck that strays into the next place."""
    body = re.sub(r'<ellipse[^>]*opacity="0\.1[23]"[^>]*/>', '', body)
    return re.sub(r'<path[^>]*stroke="#5BB8E0"[^>]*/>', '', body)


def ids(body, prefix):
    """Gives the clip ids of one picture a prefix of their own, so six pictures on one card never share one."""
    return re.sub(r'(id="|url\(#)', r'\g<1>' + prefix, body)


def silhouette(body, width):
    """The picture's own shapes, all in ink and stroked [width] wider: the sticker edge under the picture. The see-through
    parts (highlights, the ball's grain, cheeks) lie inside the picture and are left out of it."""
    def one(m):
        tag, attrs = m.group(1), m.group(2)
        if re.search(r'\bopacity="0?\.', attrs):
            return ''
        fill = re.search(r'\bfill="([^"]*)"', attrs)
        sw = re.search(r'\bstroke-width="([^"]*)"', attrs)
        stroked = re.search(r'\bstroke="(?!none)', attrs) is not None
        attrs = re.sub(r'\s(fill|stroke|stroke-width|opacity|stroke-linecap|stroke-linejoin|stroke-dasharray)="[^"]*"', '', attrs)
        own = float(sw.group(1)) if (sw and stroked) else 0.0
        f = 'none' if (fill and fill.group(1) == 'none') else INK
        return ('<%s%s fill="%s" stroke="%s" stroke-width="%.2f" stroke-linejoin="round" stroke-linecap="round"/>'
                % (tag, attrs, f, INK, own + width))
    return _ELEM.sub(one, body)


def scale_of(body):
    """The scale of a Languages picture's outer group (its 256 units shown on the 100 canvas), 1 for the others."""
    m = re.match(r'<g transform="scale\(([\d.]+)\)', body)
    return float(m.group(1)) if m else 1.0


def cell_picture(pics, sprite, prefix):
    """One picture for a cell: the sticker edge, then the drawing, on the 100 canvas."""
    body = no_shadow(body_of(pics[sprite]))
    k = scale_of(body)
    edge = silhouette(ids(body, prefix + 'e'), EDGE / k)
    return edge + ids(body, prefix)


def strip(pics, row):
    n = len(row)
    well_w = (W - 2 * PAD - (n - 1) * GAP) / n
    top = (H - WELL_H) / 2
    parts = ['<rect x="1" y="1" width="%g" height="%g" rx="8" fill="%s" stroke="%s" stroke-width="1.8"/>' % (W - 2, H - 2, PAPER, INK)]
    for i, sprite in enumerate(row):
        x = PAD + i * (well_w + GAP)
        parts.append('<rect x="%.2f" y="%.2f" width="%.2f" height="%.2f" rx="4" fill="%s"/>' % (x, top, well_w, WELL_H, MIST))
    for i, sprite in enumerate(row):
        x = PAD + i * (well_w + GAP)
        kind = 'ball' if sprite.startswith('ball_') else sprite
        cx, cy, side = CROP[kind]
        size = well_w - 0.6          # the picture as wide as its well, its edge just inside it
        s = size / side
        px, py = x + (well_w - size) / 2, H / 2 - size / 2
        parts.append('<g transform="translate(%.3f %.3f) scale(%.5f) translate(%g %g)">%s</g>'
                     % (px, py, s, -cx, -cy, cell_picture(pics, sprite, 's%d' % i)))
    return ('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 %d %d" width="%d" height="%d">%s</svg>\n'
            % (W, H, W, H, ''.join(parts)))


def build():
    pics = S.build()
    return {name: strip(pics, row) for name, row in STRIPS.items()}


def sheet(out=SHEET):
    """Every card as the child meets it: in the tray on an 84-point answer tile (6 points of padding, so the card is 72 wide),
    and sorted into a bin at 26 points (22 on a low bin); then a wide tile and a wide bin row for comparison, and the set in
    grey and as a red-green colour-blind child sees it (deuteranopia, Machado 2009 matrix)."""
    tmp = os.path.join(os.path.dirname(out), '_strips_sheet')
    os.makedirs(tmp, exist_ok=True)
    uri = lambda n: (pathlib.Path(OUT) / (n + '.svg')).as_uri()

    def tile(n, side=84, pad=6):
        return ('<div class="tile" style="width:%dpx;height:%dpx"><img src="%s" style="width:%dpx;height:%dpx;object-fit:contain">'
                '</div>' % (side, side, uri(n), side - 2 * pad, side - 2 * pad))

    def binitem(n, side):
        return '<img src="%s" style="width:%dpx;height:%dpx;object-fit:contain">' % (uri(n), side, side)

    rows = []
    for n in STRIPS:
        rows.append('<div class="r"><div class="n">%s<br><span>%s</span></div>%s<div class="bin">%s%s</div>'
                    '<div class="bin low">%s%s</div><div class="tile wide">%s</div><div class="bin">%s</div></div>'
                    % (n, 'repeats' if n in REPEATS else 'does not repeat', tile(n),
                       binitem(n, 26), binitem(n, 26), binitem(n, 22), binitem(n, 22),
                       '<img src="%s" style="width:180px;height:72px">' % uri(n),
                       '<img src="%s" style="width:65px;height:26px">' % uri(n)))
    allrow = ''.join(tile(n) for n in STRIPS)
    css = ('body{margin:0;padding:14px;background:#FFF6E8;font:12px sans-serif;color:#2B2350;width:960px}'
           'h1{font-size:16px;margin:0 0 4px}h2{font-size:13px;margin:12px 0 6px}'
           '.r{display:flex;align-items:center;gap:14px;height:100px;border-bottom:1px solid #EDE6F7}'
           '.n{width:150px;font-weight:bold}.n span{font-weight:normal;color:#5A5378}'
           '.tile{background:#fff;border-radius:16px;box-shadow:0 3px 0 #DCD3EC;display:flex;align-items:center;'
           'justify-content:center;flex:none}.tile.wide{width:200px;height:84px}'
           '.bin{background:rgba(255,255,255,.88);border:3px solid #E6DDF0;border-radius:16px;padding:6px;display:flex;gap:2px;'
           'align-items:center;justify-content:center;width:120px;height:34px;flex:none}.bin.low{height:30px;width:100px}'
           '.row{display:flex;gap:8px;flex-wrap:wrap}.grey{filter:grayscale(1)}.deut{filter:url(#deut)}'
           '.stage{background:linear-gradient(#E3F2FB 0 62%,#A8DC8C 62% 100%);padding:8px;border-radius:12px}')
    matrix = '0.367 0.861 -0.228 0 0  0.280 0.673 0.047 0 0  -0.012 0.043 0.969 0 0  0 0 0 1 0'
    html = ('<html><head><style>%s</style></head><body>'
            '<svg width="0" height="0" style="position:absolute"><filter id="deut" color-interpolation-filters="linearRGB">'
            '<feColorMatrix type="matrix" values="%s"/></filter></svg>'
            '<h1>LOG-A-04 pattern strips (2026-11-16)</h1>'
            '<div>Each row: the 84 pt tray tile (the card 72 wide), two cards sorted in a bin at 26 pt and at 22 pt (a low bin), '
            'then for comparison a wide tile (the card 180 x 72) and a wide bin item (65 x 26). At 1 px = 1 pt.</div>%s'
            '<h2>The tray, all eight at 84 pt</h2><div class="row stage">%s</div>'
            '<h2>In grey (lightness only)</h2><div class="row stage grey">%s</div>'
            '<h2>Deuteranopia (red-green colour blindness), simulated</h2><div class="row stage deut">%s</div>'
            '</body></html>' % (css, matrix, ''.join(rows), allrow, allrow, allrow))
    page = os.path.join(tmp, 'sheet.html')
    with open(page, 'w', encoding='utf-8') as fh:
        fh.write(html)
    h = 100 * len(STRIPS) + 3 * 150 + 80
    subprocess.run([S.CHROME, '--headless=new', '--disable-gpu', '--hide-scrollbars', '--force-device-scale-factor=2',
                    '--allow-file-access-from-files', '--screenshot=' + out, '--window-size=990,%d' % h,
                    pathlib.Path(page).as_uri()], check=True, capture_output=True)
    for f in os.listdir(tmp):
        os.remove(os.path.join(tmp, f))
    os.rmdir(tmp)
    return out


def main():
    cards = build()
    for name, text in cards.items():
        with open(os.path.join(OUT, name + '.svg'), 'w', encoding='utf-8', newline='\n') as fh:
            fh.write(text)
    print('wrote', len(cards), 'pattern strips to', os.path.relpath(OUT, ROOT))
    if '--sheet' in sys.argv:
        os.makedirs(os.path.dirname(SHEET), exist_ok=True)
        print('sheet', os.path.relpath(sheet(), ROOT))


if __name__ == '__main__':
    main()
