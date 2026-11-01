"""B-36 part D: the 17 new pictures of the second representations (design-director, 2026-11-01).

Spec: docs/curriculum/b36-second-representations.md, section 6 (D1 to D5). Imported by make_picture_sprites.py, which writes them with
the rest; `python tools/pictures_b36.py` writes only these 17. Same rules as pictures_b38.py: viewBox 0 0 100 100, plain shapes
only (no script, href, image, style, use, url() or text, so no font is needed, no gradient or clip path), absolute coordinates,
no transform, and every file a few KB (the hint readers stop at 64 KB). The outlines and the open shape keep their outline as the
FIRST polygon or polyline of the file, because the B-40 hint reader `outlineOf` takes the first one.

References (facts and the look only; every drawing is our own, nothing traced or copied):
- The tin can (obj_can): https://en.wikipedia.org/wiki/Steel_and_tin_cans (upright cylinder; common food cans are about 1.2 to 1.6
  times as tall as they are wide, e.g. No. 2 about 87 x 116 mm; a three-piece can has a rim, the double seam, at the top and the
  bottom, slightly wider than the body; stiffening ribs round the wall; a paper label glued round the side), and its photograph
  "an empty tin can" (silver, ribbed, rims at both ends), looked at 2026-11-01.
- The toy drum (obj_drum): https://en.wikipedia.org/wiki/Snare_drum (shell, a head on top, a hoop or counterhoop holding each
  head); the toy side drum of the National Maritime Museum (https://www.rmg.co.uk/collections/objects/rmgc-object-6278: red,
  black and yellow hoops, the cords in a zigzag round the shell); photographs of children's drums on Wikimedia Commons (search
  "toy drum", 2026-11-01): red hoops, a yellow shell with blue triangles between the zigzag cords, a pale head. Wider than tall.
- The party hat (obj_party_hat): https://en.wikipedia.org/wiki/Party_hat (a cone of thin card with printed designs, an elastic
  under the chin); party-hat craft guides and shop listings found by a web search "cone party hat pom pom fringe" (2026-11-01):
  a pompom on the point, a fringe round the rim, stripes or dots. The elastic is left out: it is not part of the cone.
- The wrapped gift (obj_gift): photographs of wrapped presents on Wikimedia Commons (search "gift wrapping present",
  2026-11-01): a box in red paper, a ribbon round it both ways crossing on the top, a bow where they cross. A long, low box (not
  a cube), drawn with the same oblique view as pictures_b38's shoe box and cube.
- The mitten (obj_mitten): https://en.wikipedia.org/wiki/Mitten (one pocket for the four fingers, the thumb in its own part at
  the side), and photographs of knitted mittens on Wikimedia Commons (search "knitted mittens", 2026-11-01): a round top, the
  thumb starting about half way down the side, a dotted knit, a ribbed cuff a little wider than the wrist.
- The toy boat (obj_toy_boat): photographs of toy and model sailboats on Wikimedia Commons (search "wooden toy sailboat",
  2026-11-01): a painted wooden hull, low at the stern and rising to the bow, one mast with a mainsail behind it and a jib in
  front, a pennant at the masthead. Drawn floating on a ripple, so the hull (a shoe's outline) reads as a boat.
- The cat (pos_cat_under, pos_cat_above): the B-38 cat and basket (pictures_b38.py). The leaping cat: Muybridge's
  photographs of a cat galloping and jumping (Wikimedia Commons search "cat jumping", 2026-11-01): the body stretched out, the
  front legs reaching forward, the hind legs pushed back, the tail out behind. Its head stays turned to us, as the sitting cat's.
- The numerals (glyph_*): the strokes are the trace template's own (tools/band_b3.py GLYPHS, copied here so the pictures do not
  import the content generator); `_rev` is the exact mirror about the middle (x -> 100 - x). Fischer (2011), cited in the spec:
  children reverse mainly the left-facing digits.
- The outlines (outline_*): the empty place of the shape builder (shape_builder_session.dart draws it as a grey silhouette),
  with a dashed rim so it reads as "a place for a shape", not a shape.
"""
import math
import os

from pictures_b38 import (FUR, FUR_EDGE, FUR_SHADE, INK, WHITE, _basket_back, _basket_front, _basket_lid, _cat_head,
                          _cat_sitting, _cuboid, _ground)


def _pts(p):
    return ' '.join('%.2f,%.2f' % q for q in p)


# ---------------------------------------------------------------- D1: the empty outlines (SHP-A-06)


def _outline(points):
    """An empty place: a pale grey silhouette with a dashed ink rim. No colour, so colour gives no answer away."""
    return ('<polygon points="%s" fill="%s" fill-opacity="0.10" stroke="%s" stroke-opacity="0.62" stroke-width="3.6" '
            'stroke-dasharray="7 7" stroke-linejoin="round" stroke-linecap="round"/>' % (_pts(points), INK, INK))


def outline_triangle_down():
    """The triangle of shape_triangle (50,13.5 89,83 11,83) turned upside down: its point at the bottom."""
    return _outline([(11, 17), (89, 17), (50, 86.5)])


def outline_square_tilt():
    """A square standing on a corner (turned 45 degrees). Its corners are written out, not a rotated rect, so the hint reader
    finds the real corners."""
    return _outline([(50, 8), (92, 50), (50, 92), (8, 50)])


# ---------------------------------------------------------------- D2: the cat under and above the basket (SHP-A-08)

WOOD, WOOD_SHADE, WOOD_EDGE = '#D9A86A', '#B98243', '#7A5222'


def pos_cat_under():
    """The basket (with its lid, as in pos_cat_on) on a wall shelf; the cat sits on the floor under it, with a clear gap."""
    cx, rim, rx, depth = 50, 20, 24, 14   # the basket's bottom sits on the shelf at y = 34
    shelf = ''.join([
        # the brackets, then the plank with its front edge
        '<polygon points="%s" fill="%s" stroke="%s" stroke-width="1.8" stroke-linejoin="round"/>'
        % (_pts([(x, 38), (x + 10 * s, 38), (x, 52)]), WOOD_SHADE, WOOD_EDGE) for x, s in ((15, 1), (85, -1))
    ]) + (
        '<rect x="8" y="33" width="84" height="6" rx="1.5" fill="%s" stroke="%s" stroke-width="1.8"/>'
        '<path d="M10 35.2 H90" stroke="#F0CC8E" stroke-width="1.4" stroke-linecap="round"/>' % (WOOD, WOOD_EDGE))
    return ''.join([
        shelf,
        _basket_back(cx, rim, rx),
        _basket_front(cx, rim, rx, depth),
        _basket_lid(cx, rim, rx),
        _ground(50, 95, 20),
        _cat_sitting(50, 95, 0.82),
    ])


def _leg(x0, y0, bx, by, x1, y1, w, colour):
    """A leg from the hip or shoulder (x0, y0) through a soft bend (bx, by) to the paw (x1, y1), [w] thick, with a white paw."""
    d = 'M%.2f %.2f Q%.2f %.2f %.2f %.2f' % (x0, y0, bx, by, x1, y1)
    return ('<path d="%s" fill="none" stroke="%s" stroke-width="%.2f" stroke-linecap="round"/>'
            '<path d="%s" fill="none" stroke="%s" stroke-width="%.2f" stroke-linecap="round"/>'
            '<ellipse cx="%.2f" cy="%.2f" rx="%.2f" ry="%.2f" fill="%s" stroke="%s" stroke-width="1.2"/>'
            % (d, FUR_EDGE, w + 3, d, colour, w, x1, y1, w * 0.72, w * 0.5, WHITE, FUR_EDGE))


def _cat_leaping():
    """The cat in mid-leap, stretched out, going left: front legs reaching forward, hind legs pushed back, the tail behind, its
    head turned to us. About 84 wide and 42 high, between y = 6 and y = 48."""
    return ''.join([
        # the tail, out behind and up
        '<path d="M76 27 Q88 25 93 13" fill="none" stroke="%s" stroke-width="7.6" stroke-linecap="round"/>' % FUR_EDGE,
        '<path d="M76 27 Q88 25 93 13" fill="none" stroke="%s" stroke-width="4.6" stroke-linecap="round"/>' % FUR_SHADE,
        # the far legs, in shade: a hind leg pushed back, a front leg reaching forward
        _leg(72, 33, 82, 34, 88, 41, 4.6, FUR_SHADE),
        _leg(36, 33, 26, 35, 15, 37, 4.6, FUR_SHADE),
        # the body, long and a little arched
        '<path d="M28 26 Q32 16 52 17 Q72 16 79 24 Q82 33 72 36 Q52 40 34 37 Q26 34 28 26 Z" fill="%s" stroke="%s" '
        'stroke-width="1.6" stroke-linejoin="round"/>' % (FUR, FUR_EDGE),
        # tabby stripes on the back
        ''.join('<path d="M%.2f 17.6 Q%.2f 21 %.2f 24" fill="none" stroke="%s" stroke-width="1.8" stroke-linecap="round"/>'
                % (x, x + 1.2, x + 0.4, FUR_SHADE) for x in (50, 57, 64)),
        # the white belly and chest
        '<path d="M32 33 Q42 39 58 37 Q48 41 36 38 Z" fill="%s"/>' % WHITE,
        # the near legs: the hind leg bends at the hock, the front leg reaches out and down
        _leg(68, 33, 84, 38, 91, 46, 5.4, FUR),
        _leg(39, 33, 28, 41, 18, 44, 5.4, FUR),
        # the haunch, round over the top of the hind leg
        '<path d="M62 33 Q64 24 72 25 Q79 27 76 34 Q70 38 62 33 Z" fill="%s" stroke="%s" stroke-width="1.3" '
        'stroke-linejoin="round"/>' % (FUR, FUR_EDGE),
        _cat_head(30, 21, 0.8),
    ])


def pos_cat_above():
    """The cat leaping over the basket, high above it, not touching; the basket is pos_cat_on's (same place, same lid). Its
    shadow on the lid shows it is above."""
    cx, rim, rx, depth = 50, 70, 34, 22
    return ''.join([
        _ground(cx, rim + depth + 1, rx * 0.95),
        _basket_back(cx, rim, rx),
        _basket_front(cx, rim, rx, depth),
        _basket_lid(cx, rim, rx),
        '<ellipse cx="52" cy="62" rx="17" ry="2.6" fill="%s" opacity="0.16"/>' % INK,
        _cat_leaping(),
    ])


# ---------------------------------------------------------------- D3: the numerals, right way and mirrored (NUM-B-07)


def _arc(cx, cy, rx, ry, a0, a1, n=24):
    out = []
    for k in range(n + 1):
        t = math.radians(a0 + (a1 - a0) * k / n)
        out.append([round(cx + rx * math.cos(t)), round(cy + ry * math.sin(t))])
    return out


def _thin(pts):
    out = []
    for p in pts:
        if not out or p != out[-1]:
            out.append(p)
    return out


# The trace template's strokes (tools/band_b3.py GLYPHS), in a 100 x 100 box.
GLYPH_STROKES = {
    '1': [[[36, 30], [54, 12], [54, 90]]],
    '3': [_thin(_arc(48, 30, 22, 18, -150, 90, 12) + _arc(48, 68, 26, 20, -90, 150, 14))],
    '7': [[[22, 14], [78, 14], [40, 90]]],
    # The trace's 8 starts its top loop at the top and then jumps straight down to the bottom loop, a line through the top loop;
    # here both loops start where they meet, so the picture is a plain 8 (same loops, same sizes).
    '8': [_thin(_arc(50, 31, 20, 18, 90, 450, 20) + _arc(50, 69, 24, 21, -90, 270, 22))],
}


def _glyph(n, mirror=False):
    """A numeral as one round-ended line in ink, the weight of a child's thick marker; the same weight for every numeral, so a
    mirrored one differs only in its direction."""
    out = []
    for stroke in GLYPH_STROKES[n]:
        pts = [((100 - x) if mirror else x, y) for x, y in stroke]
        d = 'M%s %s ' % pts[0] + ' '.join('L%s %s' % p for p in pts[1:])
        out.append('<path d="%s" fill="none" stroke="%s" stroke-width="9" stroke-linecap="round" stroke-linejoin="round"/>'
                   % (d, INK))
    return ''.join(out)


# ---------------------------------------------------------------- D4: four straight sides and a gap (SHP-B-04)


def shape_open_quad():
    """A square's four straight sides with its bottom-left corner missing: one clear gap, as shape_open has (same stroke).
    Slate grey (the robot's grey), not blue: SHP-B-04's bins and items use blue #2F7FE0 (shape_square), light blue #4DA3FF
    (shape_curved), purple, red, orange and green, so its colour matches no bin and gives no answer away. Solid, not dashed, so
    it is not the empty outline (outline_*)."""
    return ('<polyline points="16,64 16,16 84,16 84,84 36,84" fill="none" stroke="#6E7488" stroke-width="8" '
            'stroke-linejoin="round" stroke-linecap="round"/>')


# ---------------------------------------------------------------- D5: solids in the child's world (SHP-B-08)


def _band(cx, y1, y2, rx, ry):
    """The front of a cylinder between heights y1 and y2: its top and bottom edges follow the near half of the ellipse."""
    return ('M%.2f %.2f A%.2f %.2f 0 0 0 %.2f %.2f V%.2f A%.2f %.2f 0 0 1 %.2f %.2f Z'
            % (cx - rx, y1, rx, ry, cx + rx, y1, y2, rx, ry, cx - rx, y2))


def obj_can():
    """A tin can: silver, a little taller than wide, rims at the top and the bottom, ribs round the metal and a plain label."""
    cx, top, bottom, rx, ry = 50, 18, 86, 26, 7
    metal, shade, edge, light = '#D5DCE6', '#A9B4C3', '#6E7A8C', '#F4F7FB'
    out = [
        '<ellipse cx="50" cy="%d" rx="27" ry="4" fill="%s" opacity="0.12"/>' % (bottom + 6, INK),
        # the body
        '<path d="%s" fill="%s" stroke="%s" stroke-width="2" stroke-linejoin="round"/>' % (_band(cx, top, bottom, rx, ry), metal, edge),
        # shade on the right, light on the left
        '<path d="%s" fill="%s" opacity="0.8"/>' % (_band(cx + 17, top + 3, bottom - 2, 9, ry * 0.5), shade),
    ]
    # ribs round the bare metal above and below the label
    for y in (top + 6, top + 10, bottom - 10, bottom - 6):
        out.append('<path d="M%.2f %.2f A%.2f %.2f 0 0 0 %.2f %.2f" fill="none" stroke="%s" stroke-width="1.3" opacity="0.9"/>'
                   % (cx - rx + 1, y, rx - 1, ry, cx + rx - 1, y, edge))
    out += [
        # the label: red, with a cream band and a leaf, no words
        '<path d="%s" fill="#E5484D" stroke="#A82020" stroke-width="1.6" stroke-linejoin="round"/>' % _band(cx, top + 14, bottom - 16, rx, ry),
        '<path d="%s" fill="#FFF3D6"/>' % _band(cx, top + 25, bottom - 29, rx, ry),
        '<path d="M43 %.2f Q50 %.2f 57 %.2f Q50 %.2f 43 %.2f Z" fill="#4CAF50" stroke="#2E8A3E" stroke-width="1.2"/>'
        % (top + 34, top + 27, top + 34, top + 41, top + 34),
        '<path d="%s" fill="#FFFFFF" opacity="0.35"/>' % _band(cx - 15, top + 15, bottom - 17, 4, ry * 0.4),
        # the light streak on the metal
        '<path d="M%.2f %.2f V%.2f" stroke="%s" stroke-width="3" stroke-linecap="round" opacity="0.9"/>'
        % (cx - 16, top + 6, top + 11, light),
        '<path d="M%.2f %.2f V%.2f" stroke="%s" stroke-width="3" stroke-linecap="round" opacity="0.9"/>'
        % (cx - 16, bottom - 11, bottom - 5, light),
        # the bottom rim (the seam), a little wider than the body
        '<path d="M%.2f %.2f A%.2f %.2f 0 0 0 %.2f %.2f" fill="none" stroke="%s" stroke-width="5" stroke-linecap="round"/>'
        % (cx - rx - 0.6, bottom - 1.5, rx + 0.6, ry, cx + rx + 0.6, bottom - 1.5, edge),
        '<path d="M%.2f %.2f A%.2f %.2f 0 0 0 %.2f %.2f" fill="none" stroke="%s" stroke-width="2.4" stroke-linecap="round"/>'
        % (cx - rx - 0.6, bottom - 1.5, rx + 0.6, ry, cx + rx + 0.6, bottom - 1.5, metal),
        # the top: the rim, and the lid sunk a little inside it
        '<ellipse cx="%d" cy="%d" rx="%.2f" ry="%.2f" fill="%s" stroke="%s" stroke-width="2"/>' % (cx, top, rx + 0.8, ry + 0.4, light, edge),
        '<ellipse cx="%d" cy="%.2f" rx="%.2f" ry="%.2f" fill="%s" stroke="%s" stroke-width="1.2"/>'
        % (cx, top + 0.6, rx - 3.2, ry - 1.4, metal, shade),
        '<ellipse cx="%d" cy="%.2f" rx="%.2f" ry="%.2f" fill="none" stroke="%s" stroke-width="1" opacity="0.8"/>'
        % (cx, top + 0.8, rx - 10, ry - 3.4, shade),
    ]
    return ''.join(out)


def obj_drum():
    """A toy drum: wider than tall, red hoops at the top and the bottom, a yellow shell with blue triangles between the zigzag
    cords, and a pale head on top."""
    cx, top, bottom, rx, ry = 50, 32, 76, 40, 11
    red, red_edge, shell, shell_edge, blue = '#E5484D', '#A82020', '#FFC531', '#D9A514', '#2F7FE0'
    hoop = 7
    out = [
        '<ellipse cx="50" cy="%d" rx="40" ry="5" fill="%s" opacity="0.12"/>' % (bottom + 9, INK),
        # the shell
        '<path d="%s" fill="%s" stroke="%s" stroke-width="2" stroke-linejoin="round"/>' % (_band(cx, top, bottom, rx, ry), shell, shell_edge),
    ]
    # the zigzag: the cords go from the top hoop to the bottom hoop and back, round the near side of the shell
    y_hi, y_lo = top + hoop, bottom - hoop
    n = 9
    pts = []
    for k in range(n + 1):
        a = math.radians(-90 + 180 * k / n)   # -90 = the left edge, 90 = the right edge, seen from the front
        x = cx + rx * math.sin(a) * 0.985
        dy = ry * math.cos(a)
        pts.append((x, (y_hi if k % 2 == 0 else y_lo) + dy))
    for k in range(n):
        # the triangle that points down from the top hoop between two cords is blue
        if k % 2 == 1:
            continue
        a0, a1 = math.radians(-90 + 180 * k / n), math.radians(-90 + 180 * (k + 2) / n) if k + 2 <= n else None
        if a1 is None:
            continue
        x0, x2 = cx + rx * math.sin(a0) * 0.985, cx + rx * math.sin(a1) * 0.985
        out.append('<polygon points="%s" fill="%s" stroke-linejoin="round"/>'
                   % (_pts([(x0, y_hi + ry * math.cos(a0)), (x2, y_hi + ry * math.cos(a1)), pts[k + 1]]), blue))
    out.append('<polyline points="%s" fill="none" stroke="#FFFFFF" stroke-width="2.6" stroke-linejoin="round" '
               'stroke-linecap="round"/>' % _pts(pts))
    out += [
        # light on the shell's left
        '<path d="%s" fill="#FFFFFF" opacity="0.25"/>' % _band(cx - 27, y_hi + 1, y_lo - 1, 4, ry * 0.5),
        # the bottom hoop
        '<path d="%s" fill="%s" stroke="%s" stroke-width="2" stroke-linejoin="round"/>' % (_band(cx, bottom - hoop, bottom, rx + 1, ry), red, red_edge),
        # the top hoop, and the head inside it
        '<path d="%s" fill="%s" stroke="%s" stroke-width="2" stroke-linejoin="round"/>' % (_band(cx, top, top + hoop, rx + 1, ry), red, red_edge),
        '<ellipse cx="%d" cy="%d" rx="%.2f" ry="%.2f" fill="%s" stroke="%s" stroke-width="2"/>' % (cx, top, rx + 1, ry, red, red_edge),
        '<ellipse cx="%d" cy="%.2f" rx="%.2f" ry="%.2f" fill="#FFF3D6" stroke="#E0C48A" stroke-width="1.4"/>' % (cx, top + 0.4, rx - 4, ry - 2.4),
        '<ellipse cx="%d" cy="%.2f" rx="%.2f" ry="%.2f" fill="#FFFFFF" opacity="0.6"/>' % (cx - 10, top - 1.5, 10, 2.4),
        # the little studs that hold the cords on the hoops
    ]
    out.append(''.join('<circle cx="%.2f" cy="%.2f" r="1.6" fill="#FFF3D6" stroke="%s" stroke-width="0.8"/>' % (x, y, red_edge)
                       for x, y in pts))
    return ''.join(out)


def obj_party_hat():
    """A party hat: a cone of card with dots, a fringe round its rim and a pompom on the point."""
    apex, base, rx, ry = (50, 13), 82, 31, 8.5
    body, edge = '#9B6BDF', '#5F3A9E'

    def at(y):
        """Half the width and the depth of the cone's cut at height y."""
        t = (y - apex[1]) / (base - apex[1])
        return rx * t, ry * t
    out = [
        '<ellipse cx="50" cy="%.2f" rx="30" ry="4" fill="%s" opacity="0.12"/>' % (base + 9, INK),
        # the cone: two straight sides and the near half of the rim
        '<path d="M%.2f %.2f L%.2f %.2f L%.2f %.2f A%.2f %.2f 0 0 1 %.2f %.2f Z" fill="%s" stroke="%s" stroke-width="2" '
        'stroke-linejoin="round"/>' % (50 - rx, base, apex[0], apex[1], 50 + rx, base, rx, ry, 50 - rx, base, body, edge),
        # the shade on its right side
        '<path d="M%.2f %.2f L%.2f %.2f A%.2f %.2f 0 0 1 %.2f %.2f Z" fill="%s" opacity="0.22"/>'
        % (apex[0], apex[1] + 2, 50 + rx - 1, base, rx - 1, ry, 64, base + ry * 0.92, edge),
    ]
    # the dots: each placed on the cone's front, smaller near the point
    for (fy, fx, colour) in ((0.30, 0.1, '#FFC531'), (0.52, -0.42, '#FFFFFF'), (0.55, 0.38, '#F48FB1'), (0.78, -0.05, '#FFC531'),
                             (0.80, 0.62, '#FFFFFF'), (0.80, -0.68, '#F48FB1')):
        y = apex[1] + (base - apex[1]) * fy
        w, d = at(y)
        x = 50 + fx * w
        r = 2.2 + 3.2 * fy
        out.append('<circle cx="%.2f" cy="%.2f" r="%.2f" fill="%s" stroke="%s" stroke-width="0.9"/>'
                   % (x, y + d * (1 - fx * fx) ** 0.5 * 0.6, r, colour, edge))
    # the fringe round the rim: little paper strips along the near half
    strips = []
    for k in range(15):
        a = math.radians(180 - 180 * (k + 0.5) / 15)
        x = 50 + (rx + 1) * math.cos(a)
        y = base + ry * math.sin(a)
        strips.append('<path d="M%.2f %.2f L%.2f %.2f" stroke="%s" stroke-width="3.6" stroke-linecap="round"/>'
                      % (x, y - 1.5, x + (x - 50) * 0.04, y + 5, '#FFC531' if k % 2 else '#F48FB1'))
    out += strips
    out.append('<path d="M%.2f %.2f A%.2f %.2f 0 0 0 %.2f %.2f" fill="none" stroke="%s" stroke-width="3" stroke-linecap="round"/>'
               % (50 - rx, base, rx, ry, 50 + rx, base, edge))
    # the pompom: a fluffy ball of yarn on the point
    fluff = ''.join('<circle cx="%.2f" cy="%.2f" r="3.4" fill="#FFC531"/>'
                    % (50 + 7.6 * math.cos(math.radians(a)), 10 + 7.6 * math.sin(math.radians(a))) for a in range(0, 360, 40))
    out.append('<circle cx="50" cy="10" r="9.6" fill="#D9A514"/>' + fluff +
               '<circle cx="50" cy="10" r="7" fill="#FFC531"/>'
               '<path d="M45 8 Q47 4 51 5 M49 13 Q52 15 55 12 M44 12 L46 13" fill="none" stroke="#D9A514" stroke-width="1.2" '
               'stroke-linecap="round"/><circle cx="46.5" cy="6.6" r="1.8" fill="#FFFFFF" opacity="0.7"/>')
    return ''.join(out)


def obj_gift():
    """A wrapped present: a long, low box (not a cube) in red paper, a gold ribbon round it both ways, a bow on top."""
    x, y, w, h, d = 10, 52, 62, 35, 46
    dx = d * 0.5 * math.cos(math.radians(40))
    dy = d * 0.5 * math.sin(math.radians(40))
    gold, gold_edge, gold_shade = '#FFC531', '#B98A10', '#E3A912'
    out = ['<ellipse cx="52" cy="%.2f" rx="42" ry="4" fill="%s" opacity="0.12"/>' % (y + h + 4, INK),
           _cuboid(x, y, w, h, d, '#F27A7E', '#E5484D', '#B8323A', '#8E1B22')]
    rb = 4.2   # half the ribbon's width
    mx = x + w / 2
    # the ribbon down the front, and on the top from the front to the back
    out.append('<polygon points="%s" fill="%s" stroke="%s" stroke-width="1.2"/>'
               % (_pts([(mx - rb, y), (mx + rb, y), (mx + rb, y + h), (mx - rb, y + h)]), gold, gold_edge))
    out.append('<polygon points="%s" fill="%s" stroke="%s" stroke-width="1.2"/>'
               % (_pts([(mx - rb, y), (mx + rb, y), (mx + rb + dx, y - dy), (mx - rb + dx, y - dy)]), gold, gold_edge))
    # the ribbon round the side, and on the top from left to right, half way back
    k0, k1 = 0.5 - rb / d * 2 * 0.62, 0.5 + rb / d * 2 * 0.62
    sx = lambda k: x + w + dx * k
    sy = lambda k: y - dy * k
    out.append('<polygon points="%s" fill="%s" stroke="%s" stroke-width="1.2"/>'
               % (_pts([(sx(k0), sy(k0)), (sx(k1), sy(k1)), (sx(k1), sy(k1) + h), (sx(k0), sy(k0) + h)]), gold_shade, gold_edge))
    out.append('<polygon points="%s" fill="%s" stroke="%s" stroke-width="1.2"/>'
               % (_pts([(x + dx * k0, sy(k0)), (sx(k0), sy(k0)), (sx(k1), sy(k1)), (x + dx * k1, sy(k1))]), gold, gold_edge))
    # the bow, where the ribbons cross on the top
    bx, by = mx + dx / 2, y - dy / 2
    loop = ('<path d="M%.2f %.2f Q%.2f %.2f %.2f %.2f Q%.2f %.2f %.2f %.2f Z" fill="%s" stroke="%s" stroke-width="1.6" '
            'stroke-linejoin="round"/>')
    out += [
        # the two tails
        '<path d="M%.2f %.2f L%.2f %.2f L%.2f %.2f Z" fill="%s" stroke="%s" stroke-width="1.4" stroke-linejoin="round"/>'
        % (bx, by, bx - 10, by + 9, bx - 5, by + 9.5, gold_shade, gold_edge),
        '<path d="M%.2f %.2f L%.2f %.2f L%.2f %.2f Z" fill="%s" stroke="%s" stroke-width="1.4" stroke-linejoin="round"/>'
        % (bx, by, bx + 11, by + 7, bx + 7, by + 9.5, gold_shade, gold_edge),
        # the two loops
        loop % (bx, by, bx - 20, by - 18, bx - 15, by - 2, bx - 10, by + 3, bx, by, gold, gold_edge),
        loop % (bx, by, bx + 20, by - 18, bx + 15, by - 2, bx + 10, by + 3, bx, by, gold, gold_edge),
        '<path d="M%.2f %.2f Q%.2f %.2f %.2f %.2f M%.2f %.2f Q%.2f %.2f %.2f %.2f" fill="none" stroke="%s" stroke-width="1.2" '
        'stroke-linecap="round" opacity="0.8"/>' % (bx - 3, by - 2, bx - 11, by - 10, bx - 14, by - 4,
                                                   bx + 3, by - 2, bx + 11, by - 10, bx + 14, by - 4, gold_edge),
        # the knot
        '<ellipse cx="%.2f" cy="%.2f" rx="4.2" ry="3.6" fill="%s" stroke="%s" stroke-width="1.4"/>' % (bx, by - 0.5, gold_shade, gold_edge),
        '<path d="M%.2f %.2f H%.2f" stroke="#FFFFFF" stroke-width="1.2" stroke-linecap="round" opacity="0.7"/>' % (bx - 2, by - 2, bx + 1),
    ]
    return ''.join(out)


# ---------------------------------------------------------------- D6: the look-alikes of LOG-A-09 (what goes together)


def _inside(poly, x, y):
    """Is (x, y) inside the polygon? (even-odd ray cast) Used to keep the knit dots on the mitten."""
    c = False
    for (x1, y1), (x2, y2) in zip(poly, poly[1:] + poly[:1]):
        if (y1 > y) != (y2 > y) and x < x1 + (y - y1) * (x2 - x1) / (y2 - y1):
            c = not c
    return c


def obj_mitten():
    """A knitted mitten, standing with its fingers up: one round pocket for the four fingers, the thumb out on its own at the
    side, a ribbed cuff. Pink with cream dots, so it is not the blue sock's colour: it looks like a sock only by being soft,
    knitted and cuffed, and the thumb says it is for the hand."""
    knit, knit_edge, knit_shade, cream = '#E8609E', '#A8336B', '#C9447F', '#FFF3D6'
    cuff, cuff_edge = '#7C4DCC', '#4E2A8E'
    body = ('M43 67 L41.5 59 C31 61 19.5 54 17.5 43 C16 34 23.5 29.5 30 33.5 C34 36 37 40.5 39 43 '
            'L37.5 33 C37 14 49 6 60 6 C73 6 81 17 80 33 L76 67 Z')
    out = [
        '<ellipse cx="58" cy="94" rx="24" ry="3.2" fill="%s" opacity="0.12"/>' % INK,
        '<path d="%s" fill="%s" stroke="%s" stroke-width="2.2" stroke-linejoin="round"/>' % (body, knit, knit_edge),
        # shade down the right side of the hand, and on the thumb's underside
        '<path d="M72 12 C79 20 80.5 31 78.8 46 L75.4 66 L69.5 66 C73 50 74.5 28 72 12 Z" fill="%s" opacity="0.7"/>' % knit_shade,
        '<path d="M19 47 C23 55 31 59 41 58.5 L41.5 59 C31 61 19.5 54 17.5 43 Z" fill="%s" opacity="0.7"/>' % knit_shade,
        # the seam between the thumb and the hand
        '<path d="M39 43 Q38.2 50 41.2 57" fill="none" stroke="%s" stroke-width="1.6" stroke-linecap="round"/>' % knit_edge,
    ]
    # the knit dots, in staggered rows, only where they fall well inside the mitten
    hand = [(43, 66), (40.5, 44), (39, 33), (40, 20), (48, 10), (60, 8), (72, 10), (78, 21), (78, 34), (74.5, 66)]
    thumb = [(41, 57.5), (32, 59), (22, 54), (18.5, 44), (22, 34), (30, 35), (38, 45)]
    for row, y in enumerate(range(16, 64, 8)):
        for x in range(23 + (row % 2) * 5, 80, 10):
            if _inside(hand, x - 3.5, y) and _inside(hand, x + 3.5, y) and _inside(hand, x, y - 4) or \
                    _inside(thumb, x - 2.5, y) and _inside(thumb, x + 2.5, y) and _inside(thumb, x, y - 3) and _inside(thumb, x, y + 3):
                out.append('<circle cx="%d" cy="%d" r="2.1" fill="%s"/>' % (x, y, cream))
    # a soft light on the left of the hand
    out.append('<path d="M44 20 C45 14 50 11 55 10.5" fill="none" stroke="#FFFFFF" stroke-width="2.6" stroke-linecap="round" '
               'opacity="0.55"/>')
    # the cuff: a ribbed band a little wider than the wrist, a rolled edge at the top
    out.append('<rect x="41" y="65" width="36" height="24" rx="4" fill="%s" stroke="%s" stroke-width="2.2"/>' % (cuff, cuff_edge))
    out.append(''.join('<path d="M%.1f 70 V86" stroke="%s" stroke-width="1.6" stroke-linecap="round" opacity="0.8"/>'
                       % (x, cuff_edge) for x in (46.5, 51.8, 57.1, 62.4, 67.7, 73)))
    out.append('<rect x="40" y="63" width="38" height="7" rx="3.5" fill="%s" stroke="%s" stroke-width="2"/>' % (cuff, cuff_edge))
    out.append('<path d="M42 65.4 H57" stroke="#FFFFFF" stroke-width="1.6" stroke-linecap="round" opacity="0.5"/>')
    return ''.join(out)


def obj_toy_boat():
    """A wooden toy sailboat seen from the side, bow to the right, floating on a ripple: a yellow hull with a red stripe, a mast,
    two white sails and a red pennant. The hull alone is a shoe's outline (low at the back, the bow up at the front, as the
    shoe's toe is), and that is its trap; the sails and the water say it is a boat."""
    hull, hull_edge, hull_shade, stripe, stripe_edge = '#FFC531', '#B98A10', '#E3A912', '#E5484D', '#A82020'
    sail, sail_edge, wood, wood_edge = '#FFF6E0', '#8A90A6', '#B07A35', '#7A5222'
    water, water_edge = '#9ED4FF', '#4DA3FF'
    out = [
        # the mast, and the pennant at its top, blowing back
        '<rect x="47.6" y="9" width="3.6" height="50" rx="1.6" fill="%s" stroke="%s" stroke-width="1.2"/>' % (wood, wood_edge),
        '<path d="M49 9.5 L35 13 L49 16.5 Z" fill="%s" stroke="%s" stroke-width="1.3" stroke-linejoin="round"/>' % (stripe, stripe_edge),
        '<circle cx="49.4" cy="8.4" r="2" fill="%s" stroke="%s" stroke-width="1"/>' % (wood, wood_edge),
        # the mainsail behind the mast (to the stern), its back edge curved by the wind
        '<path d="M47 18 Q36 34 19 50 L47 50 Z" fill="%s" stroke="%s" stroke-width="1.8" stroke-linejoin="round"/>' % (sail, sail_edge),
        # the seams of the sail cloth
        '<path d="M40.5 30 L47 30 M32 40 L47 40" fill="none" stroke="%s" stroke-width="1.1" stroke-linecap="round" opacity="0.55"/>'
        % sail_edge,
        # the boom under it
        '<path d="M20 51 H48" stroke="%s" stroke-width="2.6" stroke-linecap="round"/>' % wood_edge,
        # the jib in front of the mast, to the bow
        '<path d="M52 19 Q66 34 78 49 L52 49 Z" fill="%s" stroke="%s" stroke-width="1.8" stroke-linejoin="round"/>' % (sail, sail_edge),
        '<path d="M52 30 L61 30 M52 40 L69.5 40" fill="none" stroke="%s" stroke-width="1.1" stroke-linecap="round" opacity="0.55"/>'
        % sail_edge,
        # the hull: a low stern on the left, the deck rising to the bow on the right, a round bottom
        '<path d="M9 52 Q48 58 93 46 Q90 63 75 73 Q66 77 52 77 L22 77 Q12 74 11 62 Z" fill="%s" stroke="%s" stroke-width="2.2" '
        'stroke-linejoin="round"/>' % (hull, hull_edge),
        # shade under the belly
        '<path d="M12 66 Q30 70 52 70 Q72 70 86 60 Q80 69 72 73 Q64 77 52 77 L22 77 Q13 74 12 66 Z" fill="%s" opacity="0.85"/>' % hull_shade,
        # the red stripe along the side, under the deck
        '<path d="M10 55.5 Q48 61.5 91.5 50 L90 54.6 Q48 66 10.6 60.2 Z" fill="%s" stroke="%s" stroke-width="1.2" '
        'stroke-linejoin="round"/>' % (stripe, stripe_edge),
        # the deck edge, a light line along the top
        '<path d="M11 52.6 Q48 58.4 91 47.2" fill="none" stroke="#FFE79A" stroke-width="1.6" stroke-linecap="round"/>',
    ]
    # two round portholes
    out.append(''.join('<circle cx="%d" cy="%.1f" r="3" fill="#CDEBFF" stroke="%s" stroke-width="1.4"/>' % (x, y, hull_edge)
                       for x, y in ((40, 67.6), (56, 67.2))))
    # the water: a ripple the hull sits in, with a wave crest along its top
    waves = 'M4 78 ' + ' '.join('Q%d %d %d 78' % (x + 6, 74 if k % 2 else 82, x + 12) for k, x in enumerate(range(4, 88, 12)))
    out.append('<path d="%s L96 78 Q94 88 50 90 Q6 88 4 78 Z" fill="%s" opacity="0.9"/>' % (waves.replace('M4 78 ', 'M4 78 ', 1), water))
    out.append('<path d="%s" fill="none" stroke="%s" stroke-width="2.4" stroke-linecap="round" stroke-linejoin="round"/>'
               % (waves, water_edge))
    out.append('<path d="M24 85 Q30 83 36 85 M60 86 Q66 84 72 86" fill="none" stroke="#FFFFFF" stroke-width="1.6" '
               'stroke-linecap="round" opacity="0.8"/>')
    return ''.join(out)


PICTURES = {
    'outline_triangle_down': outline_triangle_down(),
    'outline_square_tilt': outline_square_tilt(),
    'pos_cat_under': pos_cat_under(),
    'pos_cat_above': pos_cat_above(),
    'glyph_3': _glyph('3'),
    'glyph_3_rev': _glyph('3', mirror=True),
    'glyph_8': _glyph('8'),
    'glyph_7': _glyph('7'),
    'glyph_7_rev': _glyph('7', mirror=True),
    'glyph_1': _glyph('1'),
    'shape_open_quad': shape_open_quad(),
    'obj_can': obj_can(),
    'obj_drum': obj_drum(),
    'obj_party_hat': obj_party_hat(),
    'obj_gift': obj_gift(),
    'obj_mitten': obj_mitten(),
    'obj_toy_boat': obj_toy_boat(),
}


if __name__ == '__main__':
    out_dir = os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', 'content', 'starter')
    for name, body in PICTURES.items():
        with open(os.path.join(out_dir, name + '.svg'), 'w', encoding='utf-8', newline='\n') as f:
            f.write('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 100 100" width="100" height="100">%s</svg>\n' % body)
    print('wrote', len(PICTURES))
