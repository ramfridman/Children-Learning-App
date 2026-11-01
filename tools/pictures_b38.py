"""B-38: the pictures that the B-15 content asked for, drawn again as real pictures (design-director, 2026-11-01).

Imported by make_picture_sprites.py, which writes them with the rest (same ids, viewBox 0 0 100 100, plain shapes only: no
script, href, image, style, use, url() or text, so no font is needed and the pack's SVG rules hold).

References (facts and the look only; every drawing is our own, nothing traced or copied):
- The tap ("open the tap", step_tap): the basin pillar tap with a cross-head handle and water running into a white basin
  (Wikimedia Commons search "bathroom faucet running water", 2026-11-01); the parts of a tap from https://en.wikipedia.org/wiki/Tap_(valve)
  (spout, handle or lever, aerator at the tip, chrome-plated brass, blue for cold).
- The soap and the towel: an everyday bar of soap with foam bubbles; a hand towel hanging over a chrome rail, its woven band near
  the hem (looked at as common household objects; no photograph copied).
- The shoe-box cuboid (solid_box) and the cube (solid_cube): adult shoe boxes are about 33 x 19 x 12 cm with a shallow lid that
  sits over the top (packaging size guides found by a web search "standard shoe box dimensions cm", 2026-11-01). Both solids use the
  same drawing (front face true, depth at 40 degrees and half length), so only their proportions differ: the box is long and low
  (its big face is a rectangle), the cube's faces are squares.
- The cat and the basket (pos_cat_in, pos_cat_on, pos_cat_next): photographs of cats sitting in round, low wicker baskets
  (Wikimedia Commons search "cat in wicker basket", 2026-11-01): a thick rolled rim, woven bands, the head and chest above the rim
  with the paws on it; a seated cat seen from the front, its tail round its paws. The grey of the pack's own `cat` is kept.
"""

INK = '#2B2540'

# ---------------------------------------------------------------- the hand-washing steps


def step_tap():
    """A chrome basin tap, opened: its handle turned, water running from the spout into the basin."""
    chrome, shade, edge = '#D5DCE6', '#A9B4C3', '#6E7A8C'
    water, water_deep = '#9ED8F5', '#5BB6E0'
    return ''.join([
        # the basin, seen a little from above
        '<path d="M6 74 Q6 96 50 96 Q94 96 94 74 Z" fill="#E9EEF5" stroke="#B9C3D3" stroke-width="2" stroke-linejoin="round"/>',
        '<ellipse cx="50" cy="74" rx="44" ry="10" fill="#F7F9FC" stroke="#B9C3D3" stroke-width="2"/>',
        '<ellipse cx="54" cy="76" rx="34" ry="6.5" fill="#DCE5F0"/>',
        # the water landing: a small pool and ripples
        '<ellipse cx="66" cy="78" rx="12" ry="3" fill="%s" opacity="0.8"/>' % water,
        '<ellipse cx="66" cy="78" rx="17" ry="4.2" fill="none" stroke="%s" stroke-width="1.4" opacity="0.7"/>' % water_deep,
        # the tap: the base on the basin's edge, the pillar, the spout
        '<ellipse cx="30" cy="70" rx="13" ry="4" fill="%s" stroke="%s" stroke-width="1.6"/>' % (shade, edge),
        '<rect x="23" y="36" width="14" height="34" rx="5" fill="%s" stroke="%s" stroke-width="1.8"/>' % (chrome, edge),
        '<rect x="26" y="39" width="3" height="28" rx="1.5" fill="#FFFFFF" opacity="0.8"/>',
        '<path d="M34 42 H58 Q68 42 68 52 V55" fill="none" stroke="%s" stroke-width="11" stroke-linecap="round" '
        'stroke-linejoin="round"/>' % edge,
        '<path d="M34 42 H58 Q68 42 68 52 V55" fill="none" stroke="%s" stroke-width="7.4" stroke-linecap="round" '
        'stroke-linejoin="round"/>' % chrome,
        '<path d="M38 40.2 H57" stroke="#FFFFFF" stroke-width="1.8" stroke-linecap="round" opacity="0.85"/>',
        # the aerator at the tip
        '<rect x="62.5" y="53" width="11" height="5" rx="1.8" fill="%s" stroke="%s" stroke-width="1.4"/>' % (shade, edge),
        # the handle: a single lever on a round cap, lifted up to let the water run, with the blue cold dot on the cap
        '<path d="M30 30 L14 15" stroke="%s" stroke-width="8.6" stroke-linecap="round"/>' % edge,
        '<path d="M30 30 L14 15" stroke="%s" stroke-width="5.4" stroke-linecap="round"/>' % chrome,
        '<path d="M26 24.5 L17 16" stroke="#FFFFFF" stroke-width="1.4" stroke-linecap="round" opacity="0.85"/>',
        '<path d="M21.5 37 Q21.5 27 30 27 Q38.5 27 38.5 37 Z" fill="%s" stroke="%s" stroke-width="1.8" '
        'stroke-linejoin="round"/>' % (chrome, edge),
        '<circle cx="30" cy="32" r="2.6" fill="#4DA3FF" stroke="%s" stroke-width="0.9"/>' % edge,
        # the running water: a clear column, a light streak, two drops of splash
        '<path d="M64 58 H72 Q73 68 71.5 77 H64.5 Q63 68 64 58 Z" fill="%s" opacity="0.92"/>' % water,
        '<path d="M66.3 60 Q65.8 68 66.6 75" stroke="#FFFFFF" stroke-width="1.6" fill="none" stroke-linecap="round" opacity="0.9"/>',
        '<path d="M70 60 V75" stroke="%s" stroke-width="1" opacity="0.6"/>' % water_deep,
        '<circle cx="56" cy="74" r="1.8" fill="%s"/><circle cx="79" cy="73" r="1.6" fill="%s"/>' % (water_deep, water_deep),
    ])


def step_soap():
    """A bar of soap, wet and foaming, on a little dish."""
    return ''.join([
        # the dish
        '<ellipse cx="50" cy="80" rx="40" ry="9" fill="#CFE9F2" stroke="#8FBFD1" stroke-width="2"/>',
        '<ellipse cx="50" cy="78" rx="31" ry="5.5" fill="#E6F4F9"/>',
        # the bar: the side, then the top, rounded
        '<path d="M18 62 Q18 74 30 75 H70 Q82 74 82 62 V58 H18 Z" fill="#E77FAE" stroke="#B9527F" stroke-width="2" '
        'stroke-linejoin="round"/>',
        '<rect x="18" y="46" width="64" height="22" rx="11" fill="#F7A8CB" stroke="#B9527F" stroke-width="2"/>',
        '<rect x="26" y="50" width="48" height="13" rx="6.5" fill="#FBC4DD"/>',
        '<path d="M30 52.5 H52" stroke="#FFFFFF" stroke-width="2.4" stroke-linecap="round" opacity="0.9"/>',
        # the foam and the bubbles
        '<path d="M22 48 Q24 40 32 42 Q36 34 45 39 Q52 33 58 40 Q66 37 68 45 Q60 49 50 47 Q38 50 22 48 Z" '
        'fill="#FFFFFF" stroke="#C9DDEA" stroke-width="1.6" stroke-linejoin="round"/>',
    ] + [
        '<circle cx="%s" cy="%s" r="%s" fill="#FFFFFF" fill-opacity="0.75" stroke="#8FC6E4" stroke-width="1.6"/>'
        '<circle cx="%s" cy="%s" r="%s" fill="#FFFFFF"/>' % (x, y, r, x - r * 0.35, y - r * 0.35, r * 0.28)
        for x, y, r in ((34, 26, 7.5), (52, 18, 9), (70, 27, 6), (80, 14, 4.5), (22, 14, 4))
    ])


def step_towel():
    """A soft hand towel hanging over a chrome rail, with the woven band near its hem."""
    blue, blue_shade, blue_edge = '#7CC4E8', '#5AA9D3', '#3E87B5'
    return ''.join([
        # the rail and its two holders
        '<rect x="6" y="12" width="6" height="14" rx="2" fill="#A9B4C3" stroke="#6E7A8C" stroke-width="1.4"/>',
        '<rect x="88" y="12" width="6" height="14" rx="2" fill="#A9B4C3" stroke="#6E7A8C" stroke-width="1.4"/>',
        '<rect x="8" y="16" width="84" height="6" rx="3" fill="#D5DCE6" stroke="#6E7A8C" stroke-width="1.4"/>',
        # the back half of the towel, hanging behind (shorter, in shade)
        '<path d="M22 19 H78 V66 Q50 70 22 66 Z" fill="%s" stroke="%s" stroke-width="1.8" stroke-linejoin="round"/>'
        % (blue_shade, blue_edge),
        # the front half: over the rail, a soft roll at the top, down to a hem that sways a little
        '<path d="M20 18 Q20 13 26 13 H74 Q80 13 80 18 L81 86 Q66 90 50 87 Q34 84 19 87 Z" fill="%s" stroke="%s" '
        'stroke-width="2" stroke-linejoin="round"/>' % (blue, blue_edge),
        '<path d="M22 22 Q50 26 78 22" fill="none" stroke="%s" stroke-width="1.6" opacity="0.7"/>' % blue_edge,
        # the woven band: two white lines with a lighter field between
        '<path d="M19.6 68 Q50 71 80.6 68 L80.8 77 Q50 80 19.4 77 Z" fill="#B8E2F6"/>',
        '<path d="M19.6 68 Q50 71 80.6 68" fill="none" stroke="#FFFFFF" stroke-width="2.2"/>',
        '<path d="M19.4 77 Q50 80 80.8 77" fill="none" stroke="#FFFFFF" stroke-width="2.2"/>',
        # soft folds of the cloth
        '<path d="M36 26 Q34 46 37 64" fill="none" stroke="%s" stroke-width="2" stroke-linecap="round" opacity="0.55"/>' % blue_shade,
        '<path d="M62 26 Q65 46 62 64" fill="none" stroke="%s" stroke-width="2" stroke-linecap="round" opacity="0.55"/>' % blue_shade,
        '<path d="M50 30 Q49 48 51 63" fill="none" stroke="#FFFFFF" stroke-width="1.6" stroke-linecap="round" opacity="0.45"/>',
    ])


# ---------------------------------------------------------------- the solids: a shoe-box cuboid and a cube, drawn the same way


def _cuboid(x, y, w, h, d, top, front, side, edge, lid=0.0, lid_colours=None):
    """A box with its front face true (left x, top y, width w, height h) and its depth d drawn at 40 degrees, half length.
    With [lid], the top [lid] points of the front and the side are a lid that sits a little proud of the box."""
    import math
    dx = d * 0.5 * math.cos(math.radians(40))
    dy = d * 0.5 * math.sin(math.radians(40))

    def pts(p):
        return ' '.join('%.2f,%.2f' % q for q in p)
    out = [
        '<polygon points="%s" fill="%s" stroke="%s" stroke-width="2" stroke-linejoin="round"/>'
        % (pts([(x + w, y), (x + w + dx, y - dy), (x + w + dx, y - dy + h), (x + w, y + h)]), side, edge),
        '<polygon points="%s" fill="%s" stroke="%s" stroke-width="2" stroke-linejoin="round"/>'
        % (pts([(x, y), (x + w, y), (x + w, y + h), (x, y + h)]), front, edge),
    ]
    if lid:
        lf, ls = lid_colours
        p = 1.2  # how far the lid stands out
        out += [
            '<polygon points="%s" fill="%s" stroke="%s" stroke-width="2" stroke-linejoin="round"/>'
            % (pts([(x + w + p, y - p), (x + w + dx + p, y - dy - p), (x + w + dx + p, y - dy + lid), (x + w + p, y + lid)]),
               ls, edge),
            '<polygon points="%s" fill="%s" stroke="%s" stroke-width="2" stroke-linejoin="round"/>'
            % (pts([(x - p, y - p), (x + w + p, y - p), (x + w + p, y + lid), (x - p, y + lid)]), lf, edge),
            # the shadow the lid casts on the box under it
            '<rect x="%.2f" y="%.2f" width="%.2f" height="2.2" fill="%s" opacity="0.18"/>' % (x, y + lid + 1, w, INK),
        ]
        x, y, w, dx, dy = x - p, y - p, w + 2 * p, dx, dy
    out.append('<polygon points="%s" fill="%s" stroke="%s" stroke-width="2" stroke-linejoin="round"/>'
               % (pts([(x, y), (x + w, y), (x + w + dx, y - dy), (x + dx, y - dy)]), top, edge))
    return ''.join(out)


def solid_box():
    """A shoe box: long and low (33 x 19 x 12), with its lid on. Its big face is a rectangle."""
    w = 66.0
    h = w * 12 / 33 * 1.15   # a little taller than true, so it reads on a small tile
    d = w * 19 / 33
    return _cuboid(10, 46, w, h, d, '#F0CC8E', '#D9A55E', '#B98243', '#7A5222', lid=9,
                   lid_colours=('#E3B56F', '#C58E4C'))


def solid_cube():
    """A cube: every face a square. Drawn exactly like the box, so the two differ only in their proportions."""
    s = 46.0
    return _cuboid(20, 40, s, s, s, '#9FDDB0', '#4CAF50', '#2F8A3F', '#1E6B2D') + (
        '<path d="M24 44 V80" stroke="#FFFFFF" stroke-width="2" stroke-linecap="round" opacity="0.35"/>')


# ---------------------------------------------------------------- the cat and the basket (SHP-A-08)

FUR, FUR_SHADE, FUR_EDGE, WHITE, PINK = '#B7BCCD', '#9AA0B4', '#5F6577', '#F5F5FA', '#F2A1C4'
WICKER, WICKER_DARK, WICKER_LIGHT, WICKER_EDGE = '#D9A45B', '#B07A35', '#EBC58A', '#7A5222'


def _cat_head(cx, cy, s):
    """A cat's head, front view, centred on (cx, cy), [s] = 1 for a head about 30 wide."""
    def P(x, y):
        return '%.2f,%.2f' % (cx + x * s, cy + y * s)
    sw = 1.6 * s
    return ''.join([
        # ears, with their pink insides
        '<polygon points="%s %s %s" fill="%s" stroke="%s" stroke-width="%.2f" stroke-linejoin="round"/>'
        % (P(-14, -3), P(-11, -19), P(-2, -11), FUR, FUR_EDGE, sw),
        '<polygon points="%s %s %s" fill="%s" stroke="%s" stroke-width="%.2f" stroke-linejoin="round"/>'
        % (P(14, -3), P(11, -19), P(2, -11), FUR, FUR_EDGE, sw),
        '<polygon points="%s %s %s" fill="%s"/>' % (P(-11.5, -6), P(-10.2, -15), P(-5, -10.5), PINK),
        '<polygon points="%s %s %s" fill="%s"/>' % (P(11.5, -6), P(10.2, -15), P(5, -10.5), PINK),
        # the head, a little wider than tall, with soft cheeks
        '<ellipse cx="%.2f" cy="%.2f" rx="%.2f" ry="%.2f" fill="%s" stroke="%s" stroke-width="%.2f"/>'
        % (cx, cy, 15.5 * s, 13.5 * s, FUR, FUR_EDGE, sw),
        # tabby marks on the forehead
        ''.join('<path d="M%s L%s" stroke="%s" stroke-width="%.2f" stroke-linecap="round"/>' % (P(x, -12.2), P(x * 0.8, -7.5), FUR_SHADE, 1.8 * s)
                for x in (-4, 0.01, 4)),
        # the white muzzle
        '<ellipse cx="%.2f" cy="%.2f" rx="%.2f" ry="%.2f" fill="%s"/>' % (cx - 4 * s, cy + 5.5 * s, 5.5 * s, 4.3 * s, WHITE),
        '<ellipse cx="%.2f" cy="%.2f" rx="%.2f" ry="%.2f" fill="%s"/>' % (cx + 4 * s, cy + 5.5 * s, 5.5 * s, 4.3 * s, WHITE),
        # eyes, friendly, with a glint
        '<ellipse cx="%.2f" cy="%.2f" rx="%.2f" ry="%.2f" fill="%s"/>' % (cx - 6 * s, cy - 1 * s, 2.6 * s, 3.2 * s, INK),
        '<ellipse cx="%.2f" cy="%.2f" rx="%.2f" ry="%.2f" fill="%s"/>' % (cx + 6 * s, cy - 1 * s, 2.6 * s, 3.2 * s, INK),
        '<circle cx="%.2f" cy="%.2f" r="%.2f" fill="#FFFFFF"/>' % (cx - 5.2 * s, cy - 2.2 * s, 0.9 * s),
        '<circle cx="%.2f" cy="%.2f" r="%.2f" fill="#FFFFFF"/>' % (cx + 6.8 * s, cy - 2.2 * s, 0.9 * s),
        # nose and mouth
        '<polygon points="%s %s %s" fill="#E86AA6" stroke="#B9527F" stroke-width="%.2f" stroke-linejoin="round"/>'
        % (P(-2.2, 2.6), P(2.2, 2.6), P(0, 4.8), 0.8 * s),
        '<path d="M%s Q%s %s M%s Q%s %s" fill="none" stroke="%s" stroke-width="%.2f" stroke-linecap="round"/>'
        % (P(0, 4.8), P(-1.5, 8), P(-4, 7), P(0, 4.8), P(1.5, 8), P(4, 7), FUR_EDGE, 1.1 * s),
        # whiskers
        ''.join('<path d="M%s L%s" stroke="%s" stroke-width="%.2f" stroke-linecap="round" opacity="0.7"/>'
                % (P(sx * 8, 5 + dy * 0.6), P(sx * 19, 3 + dy * 2.2), FUR_EDGE, 0.8 * s)
                for sx in (-1, 1) for dy in (0, 1.6)),
    ])


def _cat_sitting(cx, base, s):
    """A cat sitting, seen from the front, its paws on the line y = [base]; about 46 * s high."""
    def P(x, y):
        return '%.2f,%.2f' % (cx + x * s, base + y * s)
    sw = 1.6 * s
    return ''.join([
        # the tail, round the paws from behind the body
        '<path d="M%s Q%s %s Q%s %s" fill="none" stroke="%s" stroke-width="%.2f" stroke-linecap="round"/>'
        % (P(10, -6), P(22, -4), P(19, -1.5), P(12, 1.5), P(-3, 0.5), FUR_EDGE, 7.6 * s),
        '<path d="M%s Q%s %s Q%s %s" fill="none" stroke="%s" stroke-width="%.2f" stroke-linecap="round"/>'
        % (P(10, -6), P(22, -4), P(19, -1.5), P(12, 1.5), P(-3, 0.5), FUR_SHADE, 4.6 * s),
        # the body, a soft pear
        '<path d="M%s C%s %s %s C%s %s %s Z" fill="%s" stroke="%s" stroke-width="%.2f" stroke-linejoin="round"/>'
        % (P(0, -30), P(-16, -28), P(-17, -2), P(0, -1), P(17, -2), P(16, -28), P(0, -30), FUR, FUR_EDGE, sw),
        # the white chest
        '<path d="M%s C%s %s %s C%s %s %s Z" fill="%s"/>'
        % (P(0, -26), P(-8, -24), P(-8, -6), P(0, -4), P(8, -6), P(8, -24), P(0, -26), WHITE),
        # the front legs and white paws (an L to a point: B-36 found a V here that was given a point, a stray line up the chest)
        '<path d="M%s L%s" stroke="%s" stroke-width="%.2f" stroke-linecap="round" opacity="0.8"/>' % (P(-2.5, -14), P(-2.5, -4), FUR_SHADE, 1.2 * s),
        '<path d="M%s L%s" stroke="%s" stroke-width="%.2f" stroke-linecap="round" opacity="0.8"/>' % (P(2.5, -14), P(2.5, -4), FUR_SHADE, 1.2 * s),
        '<ellipse cx="%.2f" cy="%.2f" rx="%.2f" ry="%.2f" fill="%s" stroke="%s" stroke-width="%.2f"/>' % (cx - 5 * s, base - 2.2 * s, 4.6 * s, 2.8 * s, WHITE, FUR_EDGE, 1.2 * s),
        '<ellipse cx="%.2f" cy="%.2f" rx="%.2f" ry="%.2f" fill="%s" stroke="%s" stroke-width="%.2f"/>' % (cx + 5 * s, base - 2.2 * s, 4.6 * s, 2.8 * s, WHITE, FUR_EDGE, 1.2 * s),
        _cat_head(cx, base - 36 * s, s),
    ])


def _basket_back(cx, rim, rx):
    """The inside of an open basket: the far half of its rim and the dark hollow."""
    ry = rx * 0.22
    return ('<ellipse cx="%.2f" cy="%.2f" rx="%.2f" ry="%.2f" fill="%s" stroke="%s" stroke-width="2"/>'
            '<ellipse cx="%.2f" cy="%.2f" rx="%.2f" ry="%.2f" fill="#7A5222" opacity="0.85"/>'
            % (cx, rim, rx, ry, WICKER_DARK, WICKER_EDGE, cx, rim + ry * 0.15, rx * 0.86, ry * 0.7))


def _basket_front(cx, rim, rx, depth):
    """The front of a round, low wicker basket: woven bands, upright ribs and a thick rolled rim on top."""
    ry = rx * 0.22
    bx = rx * 0.8   # the bottom is narrower than the rim
    bottom = rim + depth
    body = ('<path d="M%.2f %.2f Q%.2f %.2f %.2f %.2f H%.2f Q%.2f %.2f %.2f %.2f A%.2f %.2f 0 0 0 %.2f %.2f Z" fill="%s" '
            'stroke="%s" stroke-width="2" stroke-linejoin="round"/>'
            % (cx + rx, rim, cx + rx, bottom - 2, cx + bx, bottom, cx - bx, cx - rx, bottom - 2, cx - rx, rim,
               rx, ry, cx + rx, rim, WICKER, WICKER_EDGE))
    out = [body]
    # woven bands: curves that follow the rim, darker under each band
    for k in range(1, 4):
        y = rim + depth * k / 4
        w = rx - (rx - bx) * k / 4
        out.append('<path d="M%.2f %.2f Q%.2f %.2f %.2f %.2f" fill="none" stroke="%s" stroke-width="1.8" opacity="0.9"/>'
                   % (cx - w + 0.8, y, cx, y + ry * 1.9, cx + w - 0.8, y, WICKER_DARK))
    # upright ribs and the light on the weave between them
    for k in range(-3, 4):
        t = k / 3.6
        x0 = cx + t * rx * 0.97
        x1 = cx + t * bx * 0.95
        y0 = rim + ry * (1 - t * t) ** 0.5 * 0.9 + 1.5
        out.append('<path d="M%.2f %.2f L%.2f %.2f" stroke="%s" stroke-width="1.3" opacity="0.55"/>'
                   % (x0, y0, x1, bottom - 1.5, WICKER_DARK))
    for k in range(-3, 3):
        t = (k + 0.5) / 3.6
        for j in range(4):
            y = rim + depth * (j + 0.5) / 4 + ry * (1 - t * t) ** 0.5 * 0.8
            if y > bottom - 2:
                continue
            x = cx + t * (rx - (rx - bx) * (j + 0.5) / 4) * 0.97
            out.append('<ellipse cx="%.2f" cy="%.2f" rx="%.2f" ry="1.2" fill="%s" opacity="0.8"/>'
                       % (x, y, rx * 0.07, WICKER_LIGHT))
    # the rolled rim (only its near half shows in front of what is inside)
    out.append('<path d="M%.2f %.2f A%.2f %.2f 0 0 0 %.2f %.2f" fill="none" stroke="%s" stroke-width="7" stroke-linecap="round"/>'
               % (cx - rx, rim, rx, ry, cx + rx, rim, WICKER_EDGE))
    out.append('<path d="M%.2f %.2f A%.2f %.2f 0 0 0 %.2f %.2f" fill="none" stroke="%s" stroke-width="4.6" stroke-linecap="round"/>'
               % (cx - rx, rim, rx, ry, cx + rx, rim, WICKER_LIGHT))
    out.append(''.join('<path d="M%.2f %.2f l2.2 -2.6" stroke="%s" stroke-width="1.2" stroke-linecap="round"/>'
                       % (cx + rx * (k / 7.0) - 1, rim + ry * (1 - (k / 7.0) ** 2) ** 0.5 + 1.3, WICKER_DARK)
                       for k in range(-6, 7)))
    return ''.join(out)


def _basket_lid(cx, rim, rx):
    """A low, domed wicker lid on the basket, with a little knob."""
    ry = rx * 0.22
    top = rim - rx * 0.32
    return ''.join([
        '<path d="M%.2f %.2f Q%.2f %.2f %.2f %.2f Q%.2f %.2f %.2f %.2f A%.2f %.2f 0 0 1 %.2f %.2f Z" fill="%s" stroke="%s" '
        'stroke-width="2" stroke-linejoin="round"/>'
        % (cx - rx, rim, cx - rx * 0.9, top, cx, top, cx + rx * 0.9, top, cx + rx, rim, rx, ry, cx - rx, rim,
           WICKER, WICKER_EDGE),
        '<path d="M%.2f %.2f Q%.2f %.2f %.2f %.2f" fill="none" stroke="%s" stroke-width="1.6" opacity="0.8"/>'
        % (cx - rx * 0.7, rim - 3, cx, top + ry * 0.2, cx + rx * 0.7, rim - 3, WICKER_DARK),
        '<path d="M%.2f %.2f A%.2f %.2f 0 0 0 %.2f %.2f" fill="none" stroke="%s" stroke-width="6" stroke-linecap="round"/>'
        % (cx - rx, rim, rx, ry, cx + rx, rim, WICKER_EDGE),
        '<path d="M%.2f %.2f A%.2f %.2f 0 0 0 %.2f %.2f" fill="none" stroke="%s" stroke-width="3.8" stroke-linecap="round"/>'
        % (cx - rx, rim, rx, ry, cx + rx, rim, WICKER_LIGHT),
    ])


def _ground(cx, y, rx):
    return '<ellipse cx="%.2f" cy="%.2f" rx="%.2f" ry="3.2" fill="%s" opacity="0.12"/>' % (cx, y, rx, INK)


def pos_cat_in():
    """The cat in the basket: head and paws over the rim, the rest of it inside."""
    cx, rim, rx, depth = 50, 62, 36, 28
    # the front paws rest on the rim and hang over it a little: a white paw with two toe lines
    paws = ''.join('<path d="M%.2f %.2f Q%.2f %.2f %.2f %.2f Q%.2f %.2f %.2f %.2f Z" fill="%s" stroke="%s" stroke-width="1.5" '
                   'stroke-linejoin="round"/><path d="M%.2f %.2f v2.6 M%.2f %.2f v2.6" stroke="%s" stroke-width="1" '
                   'stroke-linecap="round"/>'
                   % (x - 5, rim + 4, x - 5.4, rim + 10.5, x, rim + 10.5, x + 5.4, rim + 10.5, x + 5, rim + 4,
                      WHITE, FUR_EDGE, x - 1.7, rim + 7.4, x + 1.7, rim + 7.4, FUR_SHADE) for x in (40, 60))
    # the front legs come down out of the basket, behind its near rim; only the paws lie over it
    legs = ''.join('<path d="M%.2f %.2f V%.2f M%.2f %.2f V%.2f" stroke="%s" stroke-width="1.5"/>'
                   '<rect x="%.2f" y="%.2f" width="9" height="16" fill="%s"/>'
                   % (x - 4.5, rim - 8, rim + 8, x + 4.5, rim - 8, rim + 8, FUR_EDGE, x - 4.5, rim - 9, FUR) for x in (40, 60))
    shoulders = ('<path d="M33 %d Q34 44 50 43 Q66 44 67 %d Z" fill="%s" stroke="%s" stroke-width="1.6"/>'
                 % (rim + 8, rim + 8, FUR, FUR_EDGE))
    return ''.join([
        _ground(cx, rim + depth + 1, rx * 0.95),
        _basket_back(cx, rim, rx),
        shoulders,
        '<path d="M43 %d Q50 48 57 %d Z" fill="%s"/>' % (rim + 8, rim + 8, WHITE),
        legs,
        _cat_head(50, 36, 1.12),
        _basket_front(cx, rim, rx, depth),
        paws,
    ])


def pos_cat_on():
    """The cat sitting on the basket's closed lid."""
    cx, rim, rx, depth = 50, 70, 34, 22
    return ''.join([
        _ground(cx, rim + depth + 1, rx * 0.95),
        _basket_back(cx, rim, rx),
        _basket_front(cx, rim, rx, depth),
        _basket_lid(cx, rim, rx),
        _cat_sitting(50, rim - 8.5, 1.02),
    ])


def pos_cat_next():
    """The cat sitting on the ground beside the open, empty basket."""
    bx, rim, rx, depth = 32, 64, 26, 24
    return ''.join([
        _ground(bx, rim + depth + 1, rx * 0.95),
        _ground(74, 89, 15),
        _basket_back(bx, rim, rx),
        _basket_front(bx, rim, rx, depth),
        _cat_sitting(74, 89, 1.12),
    ])


PICTURES = {
    'step_tap': step_tap(),
    'step_soap': step_soap(),
    'step_towel': step_towel(),
    'solid_box': solid_box(),
    'solid_cube': solid_cube(),
    'pos_cat_in': pos_cat_in(),
    'pos_cat_on': pos_cat_on(),
    'pos_cat_next': pos_cat_next(),
}

# The shapes of the Logic, Shapes and builder activities in colours. Red and orange were too close in lightness for a child who
# does not see red and green apart (LOG-B-09 "not orange" puts the two squares side by side): red is now the teaching red of
# design-spec 9.3 (#D62F2F, contrast 2.4 against orange, was 1.9), and every shape has a rim of its own colour, darker.
SHAPE_COLOURS = {'red': '#D62F2F', 'blue': '#2F7FE0', 'green': '#4CAF50', 'yellow': '#FFC531', 'orange': '#FF9F43'}
SHAPE_RIMS = {'red': '#A82020', 'blue': '#1F5FB0', 'green': '#2E8A3E', 'yellow': '#D9A514', 'orange': '#D9781E'}
SHAPE_BODIES = {
    'circle': '<circle cx="50" cy="50" r="37" fill="%s" stroke="%s" stroke-width="3"/>',
    'square': '<rect x="15" y="15" width="70" height="70" rx="4" fill="%s" stroke="%s" stroke-width="3" stroke-linejoin="round"/>',
    'triangle': '<polygon points="50,13.5 89,83 11,83" fill="%s" stroke="%s" stroke-width="3" stroke-linejoin="round"/>',
    'rect': '<rect x="7" y="29" width="86" height="42" rx="4" fill="%s" stroke="%s" stroke-width="3" stroke-linejoin="round"/>',
}
