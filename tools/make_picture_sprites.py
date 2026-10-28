"""Draws the simple placeholder pictures of the Colours, Shapes, Logic and Maths units into content/starter.

Flat shapes in the brand colours, like make_unit_sprites.py: the illustrator replaces each file under the same id
(docs/art/art-brief.md, section 6.6b). Things that come in colours (a ball, a balloon, a flower) are drawn once and
tinted, so every colour of a thing is the same drawing.
"""
import os

OUT = os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', 'content', 'starter')
INK = '#2B2540'

COLOURS = {
    'red': '#E5484D', 'blue': '#2F7FE0', 'yellow': '#FFD84D', 'green': '#4CAF50', 'orange': '#FF9F43',
    'purple': '#9B6BDF', 'pink': '#F48FB1', 'black': '#2B2540', 'white': '#FFFFFF', 'brown': '#8A5A2B',
    'grey': '#9AA0B4',
}


def svg(body, w=100, h=100):
    return ('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 %d %d" width="%d" height="%d">%s</svg>\n'
            % (w, h, w, h, body))


def edge(c):
    return '#B8B3C8' if c == '#FFFFFF' else 'none'


def ball(c):
    return ('<circle cx="50" cy="50" r="38" fill="%s" stroke="%s" stroke-width="3"/>'
            '<ellipse cx="38" cy="36" rx="9" ry="6" fill="#FFFFFF" opacity="0.55" transform="rotate(-30 38 36)"/>'
            % (c, edge(c)))


def balloon(c):
    return ('<ellipse cx="50" cy="42" rx="28" ry="34" fill="%s" stroke="%s" stroke-width="3"/>'
            '<polygon points="46,76 54,76 50,84" fill="%s"/>'
            '<path d="M50 84 Q44 92 50 98" stroke="%s" stroke-width="2.5" fill="none"/>'
            '<ellipse cx="38" cy="28" rx="6" ry="9" fill="#FFFFFF" opacity="0.5"/>' % (c, edge(c), c, INK))


def flower(c):
    petals = ''.join('<circle cx="%d" cy="%d" r="15" fill="%s" stroke="%s" stroke-width="2"/>' % (x, y, c, edge(c))
                     for x, y in ((50, 24), (74, 42), (66, 68), (34, 68), (26, 42)))
    return ('<rect x="47" y="52" width="6" height="44" rx="3" fill="#4CAF50"/>' + petals +
            '<circle cx="50" cy="50" r="12" fill="#FFD84D"/>')


THINGS = {'ball': ball, 'balloon': balloon, 'bloom': flower}

SINGLES = {
    'sun': '<circle cx="50" cy="50" r="22" fill="#FFC531"/>' + ''.join(
        '<line x1="50" y1="8" x2="50" y2="20" stroke="#FFC531" stroke-width="6" stroke-linecap="round" '
        'transform="rotate(%d 50 50)"/>' % a for a in range(0, 360, 45)),
    'grass': '<rect x="0" y="62" width="100" height="38" fill="#4CAF50"/>' + ''.join(
        '<path d="M%d 62 L%d 40 L%d 62" fill="#6BCB6E"/>' % (x, x + 5, x + 10) for x in range(6, 90, 14)),
    'banana_yellow': '<path d="M16 60 Q50 98 90 34 Q84 28 76 36 Q50 78 24 52 Z" fill="#FFD84D" stroke="#C99A00" '
                     'stroke-width="3" stroke-linejoin="round"/>',
    'banana_green': '<path d="M16 60 Q50 98 90 34 Q84 28 76 36 Q50 78 24 52 Z" fill="#8BC34A" stroke="#4E8F2E" '
                    'stroke-width="3" stroke-linejoin="round"/>',
    'plant_seed': '<ellipse cx="50" cy="82" rx="42" ry="10" fill="#8A5A2B"/><ellipse cx="50" cy="66" rx="9" ry="13" fill="#C98F52" stroke="#6B4423" stroke-width="2"/>',
    'plant_sprout': '<ellipse cx="50" cy="86" rx="42" ry="10" fill="#8A5A2B"/><rect x="47" y="48" width="6" height="40" rx="3" fill="#4CAF50"/><ellipse cx="36" cy="46" rx="16" ry="9" fill="#6BCB6E" transform="rotate(-25 36 46)"/><ellipse cx="64" cy="46" rx="16" ry="9" fill="#6BCB6E" transform="rotate(25 64 46)"/>',
    'plant_flower': '<ellipse cx="50" cy="90" rx="42" ry="8" fill="#8A5A2B"/><rect x="47" y="46" width="6" height="46" rx="3" fill="#4CAF50"/><circle cx="50" cy="26" r="10" fill="#FFD84D"/>' + ''.join('<circle cx="%d" cy="%d" r="11" fill="#F48FB1"/>' % (x, y) for x, y in ((50, 12), (66, 26), (60, 42), (40, 42), (34, 26))),
    'egg': '<ellipse cx="50" cy="54" rx="26" ry="34" fill="#FFF3D6" stroke="#E0C48A" stroke-width="3"/>',
    'egg_crack': '<ellipse cx="50" cy="54" rx="26" ry="34" fill="#FFF3D6" stroke="#E0C48A" stroke-width="3"/><polyline points="26,48 38,56 46,44 56,58 66,46 74,54" fill="none" stroke="#8A5A2B" stroke-width="3" stroke-linejoin="round"/>',
    'chick': '<circle cx="50" cy="56" r="30" fill="#FFD84D"/><polygon points="40,54 60,54 50,64" fill="#FF9F43"/><circle cx="40" cy="46" r="4" fill="#2B2540"/><circle cx="60" cy="46" r="4" fill="#2B2540"/>',
    'sock': '<path d="M34 10 H62 V50 L82 66 Q92 80 78 88 Q64 94 52 80 L34 62 Z" fill="#4DA3FF" stroke="#2F7ED8" stroke-width="3" stroke-linejoin="round"/><rect x="34" y="10" width="28" height="12" fill="#FFFFFF"/>',
    'shoe': '<path d="M12 58 Q14 34 32 34 H48 Q54 50 76 54 Q92 58 90 74 H12 Z" fill="#E5484D" stroke="#B02A2E" stroke-width="3" stroke-linejoin="round"/><rect x="12" y="74" width="78" height="10" rx="4" fill="#2B2540"/>',
    'key': '<circle cx="30" cy="40" r="18" fill="none" stroke="#C99A00" stroke-width="8"/><rect x="46" y="36" width="44" height="8" rx="3" fill="#C99A00"/><rect x="76" y="44" width="6" height="14" fill="#C99A00"/><rect x="64" y="44" width="6" height="10" fill="#C99A00"/>',
    'lock': '<path d="M32 46 V34 Q32 14 50 14 Q68 14 68 34 V46" fill="none" stroke="#9AA0B4" stroke-width="8"/><rect x="22" y="44" width="56" height="42" rx="8" fill="#FFC531" stroke="#C99A00" stroke-width="3"/><circle cx="50" cy="62" r="6" fill="#2B2540"/>',
    'brush': '<rect x="8" y="46" width="62" height="10" rx="5" fill="#4DA3FF"/><rect x="62" y="34" width="26" height="22" rx="4" fill="#FFFFFF" stroke="#B8B3C8" stroke-width="2"/>',
    'paste': '<rect x="14" y="36" width="56" height="28" rx="8" fill="#FFFFFF" stroke="#4DA3FF" stroke-width="4"/><rect x="70" y="44" width="16" height="12" rx="3" fill="#4DA3FF"/><path d="M20 50 H60" stroke="#4DA3FF" stroke-width="5"/>',
    'shape_circle': '<circle cx="50" cy="50" r="38" fill="#E5484D"/>',
    'shape_square': '<rect x="14" y="14" width="72" height="72" rx="4" fill="#2F7FE0"/>',
    'shape_triangle': '<polygon points="50,12 90,84 10,84" fill="#4CAF50" stroke-linejoin="round"/>',
    'shape_rect': '<rect x="6" y="28" width="88" height="44" rx="4" fill="#FF9F43"/>',
    'shape_square_tilt': '<rect x="14" y="14" width="72" height="72" rx="4" fill="#2F7FE0" transform="rotate(45 50 50)"/>',
    'shape_triangle_thin': '<polygon points="50,6 66,92 34,92" fill="#4CAF50"/>',
    'shape_triangle_down': '<polygon points="10,16 90,16 50,88" fill="#4CAF50"/>',
    'window': '<rect x="10" y="14" width="80" height="72" rx="4" fill="#CDEBFF" stroke="#8A5A2B" stroke-width="6"/><line x1="50" y1="14" x2="50" y2="86" stroke="#8A5A2B" stroke-width="5"/><line x1="10" y1="50" x2="90" y2="50" stroke="#8A5A2B" stroke-width="5"/>',
    'plate': '<circle cx="50" cy="50" r="40" fill="#FFFFFF" stroke="#B8B3C8" stroke-width="4"/><circle cx="50" cy="50" r="26" fill="#F2F0F8" stroke="#D8D3E6" stroke-width="3"/>',
    'sign': '<polygon points="50,10 92,84 8,84" fill="#FFC531" stroke="#E39A00" stroke-width="6" stroke-linejoin="round"/><rect x="46" y="38" width="8" height="26" rx="3" fill="#2B2540"/><circle cx="50" cy="73" r="4.5" fill="#2B2540"/>',
    'solid_box': '<polygon points="50,10 88,28 50,46 12,28" fill="#E0B070"/><polygon points="12,28 50,46 50,90 12,72" fill="#C98F52"/><polygon points="88,28 50,46 50,90 88,72" fill="#A8743C"/>',
    'line_straight': '<line x1="12" y1="82" x2="88" y2="18" stroke="#2F7FE0" stroke-width="9" stroke-linecap="round"/>',
    'line_curved': '<path d="M12 80 C 30 10, 70 10, 88 80" fill="none" stroke="#E5484D" stroke-width="9" stroke-linecap="round"/>',
    'pos_on': '<rect x="14" y="58" width="72" height="34" rx="4" fill="#C98F52"/><circle cx="50" cy="40" r="18" fill="#E5484D"/>',
    'pos_under': '<rect x="8" y="30" width="84" height="10" rx="3" fill="#8A5A2B"/><rect x="14" y="40" width="7" height="50" fill="#8A5A2B"/><rect x="79" y="40" width="7" height="50" fill="#8A5A2B"/><circle cx="50" cy="74" r="16" fill="#E5484D"/>',
    'pos_in': '<circle cx="50" cy="46" r="20" fill="#E5484D"/><path d="M12 48 H88 L80 92 H20 Z" fill="#C98F52"/>',
    'pos_next': '<rect x="8" y="52" width="40" height="40" rx="4" fill="#C98F52"/><circle cx="74" cy="72" r="18" fill="#E5484D"/>',
    'pos_above': '<circle cx="50" cy="20" r="14" fill="#E5484D"/><rect x="14" y="62" width="72" height="30" rx="4" fill="#C98F52"/>',
    'apple_green': '<circle cx="50" cy="56" r="32" fill="#8BC34A"/><path d="M50 26 Q52 12 62 10" stroke="#6B4423" '
                   'stroke-width="4" fill="none" stroke-linecap="round"/><ellipse cx="64" cy="20" rx="10" ry="5" '
                   'fill="#4CAF50" transform="rotate(-25 64 20)"/>',
}


def main():
    n = 0
    for thing, draw in THINGS.items():
        for name, c in COLOURS.items():
            open(os.path.join(OUT, '%s_%s.svg' % (thing, name)), 'w', encoding='utf-8', newline='\n').write(svg(draw(c)))
            n += 1
    for tag, r in (('s', 14), ('m', 26), ('l', 40)):
        body = ('<circle cx="50" cy="50" r="%d" fill="#E5484D"/><ellipse cx="%d" cy="%d" rx="%d" ry="%d" fill="#FFFFFF" '
                'opacity="0.55" transform="rotate(-30 %d %d)"/>' % (r, 50 - r * 0.25, 50 - r * 0.3, r * 0.22, r * 0.15,
                                                                  50 - r * 0.25, 50 - r * 0.3))
        open(os.path.join(OUT, 'ball_size_%s.svg' % tag), 'w', encoding='utf-8', newline=chr(10)).write(svg(body))
        n += 1
    for name, body in SINGLES.items():
        open(os.path.join(OUT, name + '.svg'), 'w', encoding='utf-8', newline='\n').write(svg(body))
        n += 1
    print('wrote', n)


main()
