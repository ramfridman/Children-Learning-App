"""Draws the simple placeholder pictures of the Colours, Shapes, Logic and Maths units into content/starter.

Flat shapes in the brand colours, like make_unit_sprites.py: the illustrator replaces each file under the same id
(docs/art/art-brief.md, section 6.6b). Things that come in colours (a ball, a balloon, a flower) are drawn once and
tinted, so every colour of a thing is the same drawing.
"""
import math
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
    'stick_long': '<rect x="4" y="44" width="92" height="12" rx="6" fill="#C98F52" stroke="#8A5A2B" stroke-width="3"/>',
    'stick_short': '<rect x="28" y="44" width="44" height="12" rx="6" fill="#C98F52" stroke="#8A5A2B" stroke-width="3"/>',
    'stone': '<path d="M14 74 Q10 48 34 34 Q58 22 78 38 Q94 52 86 74 Z" fill="#9AA0B4" stroke="#6E7488" stroke-width="3" stroke-linejoin="round"/>',
    'feather': '<path d="M20 84 Q18 30 74 14 Q80 56 34 78 Z" fill="#CDEBFF" stroke="#7FB6D9" stroke-width="3" stroke-linejoin="round"/><path d="M20 84 L62 36" stroke="#7FB6D9" stroke-width="3" stroke-linecap="round"/>',
    'coin': '<circle cx="50" cy="50" r="38" fill="#FFC531" stroke="#C99A00" stroke-width="5"/><circle cx="50" cy="50" r="26" fill="none" stroke="#E39A00" stroke-width="3"/>',
    'time_morning': '<rect width="100" height="100" rx="12" fill="#FFE8C2"/><circle cx="26" cy="70" r="20" fill="#FFC531"/><rect y="72" width="100" height="28" fill="#8CCB6B"/>',
    'time_noon': '<rect width="100" height="100" rx="12" fill="#CDEBFF"/><circle cx="50" cy="26" r="20" fill="#FFC531"/><rect y="78" width="100" height="22" fill="#8CCB6B"/>',
    'time_evening': '<rect width="100" height="100" rx="12" fill="#FFB38A"/><circle cx="74" cy="70" r="20" fill="#FF8A3D"/><rect y="72" width="100" height="28" fill="#6E9F58"/>',
    'time_night': '<rect width="100" height="100" rx="12" fill="#2B3A6B"/><circle cx="64" cy="32" r="18" fill="#FFF3C2"/><circle cx="72" cy="28" r="15" fill="#2B3A6B"/><circle cx="24" cy="24" r="3" fill="#FFFFFF"/><circle cx="34" cy="50" r="2.5" fill="#FFFFFF"/><circle cx="82" cy="62" r="3" fill="#FFFFFF"/>',
    'step_tap': '<path d="M16 40 H58 Q70 40 70 52 V60 H58 V50 H16 Z" fill="#9AA0B4" stroke="#6E7488" stroke-width="3"/><rect x="10" y="30" width="16" height="10" fill="#6E7488"/><path d="M62 66 Q58 78 62 84 Q66 78 62 66 Z" fill="#4DA3FF"/>',
    'step_soap': '<rect x="14" y="40" width="72" height="36" rx="12" fill="#F48FB1" stroke="#D8648F" stroke-width="3"/><circle cx="30" cy="30" r="8" fill="#FFFFFF" stroke="#CDEBFF" stroke-width="2"/><circle cx="48" cy="24" r="6" fill="#FFFFFF" stroke="#CDEBFF" stroke-width="2"/>',
    'step_towel': '<rect x="16" y="16" width="68" height="70" rx="6" fill="#4DA3FF"/><rect x="16" y="30" width="68" height="8" fill="#FFFFFF" opacity="0.7"/><rect x="16" y="52" width="68" height="8" fill="#FFFFFF" opacity="0.7"/>',
    'step_paste': '<rect x="8" y="58" width="70" height="12" rx="6" fill="#4DA3FF"/><rect x="62" y="48" width="26" height="22" rx="4" fill="#FFFFFF" stroke="#B8B3C8" stroke-width="2"/><path d="M14 52 H50" stroke="#FFFFFF" stroke-width="8" stroke-linecap="round"/>',
    'step_brush': '<rect x="8" y="58" width="70" height="12" rx="6" fill="#4DA3FF"/><rect x="62" y="46" width="26" height="24" rx="4" fill="#FFFFFF" stroke="#B8B3C8" stroke-width="2"/>',
    'step_rinse': '<path d="M20 28 H80 L72 82 H28 Z" fill="#CDEBFF" stroke="#7FB6D9" stroke-width="4" stroke-linejoin="round"/><path d="M28 48 H72" stroke="#4DA3FF" stroke-width="5"/>',
    'robot': '<rect x="26" y="34" width="48" height="44" rx="10" fill="#9AA0B4" stroke="#6E7488" stroke-width="3"/><rect x="34" y="16" width="32" height="22" rx="8" fill="#B7BCCD" stroke="#6E7488" stroke-width="3"/><circle cx="43" cy="27" r="4" fill="#4DA3FF"/><circle cx="57" cy="27" r="4" fill="#4DA3FF"/><line x1="50" y1="16" x2="50" y2="6" stroke="#6E7488" stroke-width="3"/><circle cx="50" cy="5" r="4" fill="#E5484D"/><rect x="34" y="78" width="10" height="12" rx="3" fill="#6E7488"/><rect x="56" y="78" width="10" height="12" rx="3" fill="#6E7488"/>',
    'flag': '<line x1="30" y1="10" x2="30" y2="92" stroke="#6B4423" stroke-width="6" stroke-linecap="round"/><polygon points="30,12 82,28 30,46" fill="#E5484D"/>',
    'apple_green': '<circle cx="50" cy="56" r="32" fill="#8BC34A"/><path d="M50 26 Q52 12 62 10" stroke="#6B4423" '
                   'stroke-width="4" fill="none" stroke-linecap="round"/><ellipse cx="64" cy="20" rx="10" ry="5" '
                   'fill="#4CAF50" transform="rotate(-25 64 20)"/>',
}

# ---- more pictures for the extra activities (9b-2): shapes in colours, things in three sizes, more stories and pairs ----
SHAPE_COLOURS = {'red': '#E5484D', 'blue': '#2F7FE0', 'green': '#4CAF50', 'yellow': '#FFC531', 'orange': '#FF9F43'}
SHAPE_BODIES = {
    'circle': '<circle cx="50" cy="50" r="38" fill="%s"/>',
    'square': '<rect x="14" y="14" width="72" height="72" rx="4" fill="%s"/>',
    'triangle': '<polygon points="50,12 90,84 10,84" fill="%s"/>',
    'rect': '<rect x="6" y="28" width="88" height="44" rx="4" fill="%s"/>',
}
MORE = {
    'cloud': '<ellipse cx="50" cy="56" rx="38" ry="20" fill="#D6DDEB"/><circle cx="34" cy="48" r="16" fill="#D6DDEB"/><circle cx="58" cy="42" r="20" fill="#D6DDEB"/>',
    'rain': '<ellipse cx="50" cy="36" rx="36" ry="18" fill="#9AA0B4"/><circle cx="34" cy="30" r="14" fill="#9AA0B4"/><circle cx="58" cy="26" r="17" fill="#9AA0B4"/>' + ''.join('<line x1="%d" y1="62" x2="%d" y2="76" stroke="#4DA3FF" stroke-width="5" stroke-linecap="round"/>' % (x, x - 4) for x in (30, 46, 62, 76)),
    'rainbow': ''.join('<path d="M%d 80 A%d %d 0 0 1 %d 80" fill="none" stroke="%s" stroke-width="7"/>' % (10 + i * 8, 40 - i * 8, 40 - i * 8, 90 - i * 8, c) for i, c in enumerate(('#E5484D', '#FF9F43', '#FFD84D', '#4CAF50', '#4DA3FF'))),
    'bowl': '<path d="M12 44 H88 C88 90 12 90 12 44 Z" fill="#F48FB1" stroke="#D8648F" stroke-width="3"/>',
    'spoon': '<ellipse cx="50" cy="26" rx="16" ry="20" fill="#C9CFDD" stroke="#9AA0B4" stroke-width="3"/><rect x="45" y="44" width="10" height="48" rx="5" fill="#C9CFDD" stroke="#9AA0B4" stroke-width="3"/>',
    'pencil': '<rect x="10" y="40" width="64" height="20" fill="#FFC531" stroke="#C99A00" stroke-width="3"/><polygon points="74,40 94,50 74,60" fill="#F2D7A6"/><polygon points="88,47 94,50 88,53" fill="#2B2540"/><rect x="4" y="40" width="10" height="20" fill="#F48FB1"/>',
    'paper': '<rect x="20" y="10" width="60" height="80" rx="4" fill="#FFFFFF" stroke="#B8B3C8" stroke-width="3"/>' + ''.join('<line x1="30" y1="%d" x2="70" y2="%d" stroke="#CDEBFF" stroke-width="3"/>' % (y, y) for y in (28, 42, 56, 70)),
    'line_straight_flat': '<line x1="10" y1="50" x2="90" y2="50" stroke="#2F7FE0" stroke-width="9" stroke-linecap="round"/>',
    'line_curved_wave': '<path d="M8 50 C 22 20, 36 80, 50 50 S 78 20, 92 50" fill="none" stroke="#E5484D" stroke-width="9" stroke-linecap="round"/>',
    'line_straight_up': '<line x1="50" y1="10" x2="50" y2="90" stroke="#2F7FE0" stroke-width="9" stroke-linecap="round"/>',
    'line_curved_arc': '<path d="M20 86 C 6 40, 40 10, 86 20" fill="none" stroke="#E5484D" stroke-width="9" stroke-linecap="round"/>',
}

# ---- Band B pictures (9b-3): shades, polygons, solids, towers, rules, days, clocks, a frog and a block ----
BAND_B = True


def poly(n, c, r=38, rot=-90):
    pts = []
    for k in range(n):
        a = math.radians(rot + 360 * k / n)
        pts.append('%.1f,%.1f' % (50 + r * math.cos(a), 52 + r * math.sin(a)))
    return '<polygon points="%s" fill="%s" stroke-linejoin="round"/>' % (' '.join(pts), c)


def clock(hour):
    a = math.radians(hour * 30 - 90)
    x, y = 50 + 24 * math.cos(a), 50 + 24 * math.sin(a)
    ticks = ''.join('<line x1="%.1f" y1="%.1f" x2="%.1f" y2="%.1f" stroke="#2B2540" stroke-width="3" stroke-linecap="round"/>'
                    % (50 + 36 * math.cos(math.radians(k * 30)), 50 + 36 * math.sin(math.radians(k * 30)),
                       50 + 42 * math.cos(math.radians(k * 30)), 50 + 42 * math.sin(math.radians(k * 30))) for k in range(12))
    return ('<circle cx="50" cy="50" r="46" fill="#FFFFFF" stroke="#2B2540" stroke-width="5"/>' + ticks +
            '<line x1="50" y1="50" x2="50" y2="14" stroke="#4DA3FF" stroke-width="4" stroke-linecap="round"/>'
            '<line x1="50" y1="50" x2="%.1f" y2="%.1f" stroke="#E5484D" stroke-width="7" stroke-linecap="round"/>'
            '<circle cx="50" cy="50" r="5" fill="#2B2540"/>' % (x, y))


def tower(n):
    return ''.join('<rect x="30" y="%d" width="40" height="%d" rx="3" fill="%s" stroke="#FFFFFF" stroke-width="2"/>'
                   % (88 - 14 * (k + 1), 14, ('#4DA3FF', '#FFC531')[k % 2]) for k in range(n))


def day(n):
    dots = ''.join('<circle cx="%d" cy="%d" r="6" fill="#2B2540"/>' % (22 + (k % 4) * 19, 40 + (k // 4) * 22) for k in range(n))
    return '<rect x="8" y="12" width="84" height="78" rx="10" fill="#FFFFFF" stroke="#4DA3FF" stroke-width="5"/><rect x="8" y="12" width="84" height="20" rx="10" fill="#4DA3FF"/>' + dots


SHADES = {'blue': ('#CFE6FF', '#5AA6F2', '#1F4E9C'), 'green': ('#D7F2C8', '#5BBE5A', '#2A6F2F'),
          'red': ('#FFD0D0', '#E5484D', '#8E1B22'), 'purple': ('#E6D8FA', '#9B6BDF', '#52308F')}
BAND_B_SPRITES = {
    'shape_pentagon': poly(5, '#9B6BDF'), 'shape_hexagon': poly(6, '#FF9F43'), 'shape_quad': poly(4, '#4CAF50', 40, -45),
    'shape_open': '<polyline points="12,84 50,14 88,84 24,84" fill="none" stroke="#E5484D" stroke-width="8" stroke-linejoin="round" stroke-linecap="round"/>',
    'shape_curved': '<path d="M12 84 Q50 -10 88 84 Z" fill="#4DA3FF"/>',
    'solid_cylinder': '<ellipse cx="50" cy="24" rx="30" ry="10" fill="#9ED0EC"/><rect x="20" y="24" width="60" height="52" fill="#4DA3FF"/><ellipse cx="50" cy="76" rx="30" ry="10" fill="#4DA3FF"/><ellipse cx="50" cy="24" rx="30" ry="10" fill="#9ED0EC"/>',
    'solid_cone': '<polygon points="50,10 84,80 16,80" fill="#E5484D"/><ellipse cx="50" cy="80" rx="34" ry="10" fill="#B02A2E"/>',
    'solid_sphere': '<circle cx="50" cy="50" r="38" fill="#9B6BDF"/><ellipse cx="38" cy="36" rx="10" ry="7" fill="#FFFFFF" opacity="0.5" transform="rotate(-30 38 36)"/>',
    'solid_pyramid': '<polygon points="50,10 90,78 50,90 10,78" fill="#FFC531"/><polygon points="50,10 90,78 50,90" fill="#E39A00"/>',
    'rule_colour': '<circle cx="34" cy="38" r="22" fill="#E5484D"/><circle cx="66" cy="38" r="22" fill="#4DA3FF"/><circle cx="50" cy="66" r="22" fill="#FFC531"/>',
    'rule_shape': '<circle cx="28" cy="34" r="18" fill="#9AA0B4"/><rect x="52" y="16" width="36" height="36" fill="#9AA0B4"/><polygon points="50,56 78,92 22,92" fill="#9AA0B4"/>',
    'rule_size': '<circle cx="28" cy="64" r="12" fill="#9AA0B4"/><circle cx="62" cy="52" r="26" fill="#9AA0B4"/>',
    'frog': '<ellipse cx="50" cy="62" rx="32" ry="24" fill="#4CAF50"/><circle cx="34" cy="38" r="12" fill="#6BCB6E"/><circle cx="66" cy="38" r="12" fill="#6BCB6E"/><circle cx="34" cy="38" r="6" fill="#FFFFFF"/><circle cx="66" cy="38" r="6" fill="#FFFFFF"/><circle cx="34" cy="38" r="3" fill="#2B2540"/><circle cx="66" cy="38" r="3" fill="#2B2540"/><path d="M36 66 Q50 76 64 66" fill="none" stroke="#2B2540" stroke-width="3" stroke-linecap="round"/>',
    'coin_silver': '<circle cx="50" cy="50" r="46" fill="#C9CED8" stroke="#8E96A6" stroke-width="5"/><circle cx="50" cy="50" r="36" fill="none" stroke="#E8EBF1" stroke-width="3"/>',
    'coin_gold': '<circle cx="50" cy="50" r="46" fill="#E6B422" stroke="#A47E0B" stroke-width="5"/><circle cx="50" cy="50" r="31" fill="#C9CED8" stroke="#E6B422" stroke-width="4"/>',
    'note_green': '<rect x="3" y="20" width="94" height="60" rx="7" fill="#9BD58C" stroke="#4E8F3E" stroke-width="4"/><circle cx="50" cy="50" r="22" fill="none" stroke="#4E8F3E" stroke-width="3"/>',
    'note_red': '<rect x="3" y="20" width="94" height="60" rx="7" fill="#F2A39B" stroke="#B8453B" stroke-width="4"/><circle cx="50" cy="50" r="22" fill="none" stroke="#B8453B" stroke-width="3"/>',
    'block': '<rect x="14" y="14" width="72" height="72" rx="8" fill="#FFC531" stroke="#E39A00" stroke-width="5"/><rect x="30" y="30" width="40" height="40" rx="4" fill="#FFE08A"/>',
}


def inner(thing):
    """The drawing inside the svg tags of a sprite that make_unit_sprites.py already made."""
    text = open(os.path.join(OUT, thing + '.svg'), encoding='utf-8').read()
    return text[text.index('>') + 1:text.rindex('</svg>')]


def main():
    n = 0
    for thing, draw in THINGS.items():
        for name, c in COLOURS.items():
            open(os.path.join(OUT, '%s_%s.svg' % (thing, name)), 'w', encoding='utf-8', newline='\n').write(svg(draw(c)))
            n += 1
    for shape, body in SHAPE_BODIES.items():
        for cname, c in SHAPE_COLOURS.items():
            open(os.path.join(OUT, 'shape_%s_%s.svg' % (shape, cname)), 'w', encoding='utf-8', newline=chr(10)).write(svg(body % c))
            n += 1
    for name, body in BAND_B_SPRITES.items():
        open(os.path.join(OUT, name + '.svg'), 'w', encoding='utf-8', newline=chr(10)).write(svg(body))
        n += 1
    for c, (l1, l2, l3) in SHADES.items():
        for k, col in enumerate((l1, l2, l3), start=1):
            open(os.path.join(OUT, 'shade_%s_%d.svg' % (c, k)), 'w', encoding='utf-8', newline=chr(10)).write(
                svg('<circle cx="50" cy="50" r="38" fill="%s"/>' % col))
            n += 1
    for k in range(1, 7):
        open(os.path.join(OUT, 'tower_%d.svg' % k), 'w', encoding='utf-8', newline=chr(10)).write(svg(tower(k)))
        n += 1
    for k in range(1, 8):
        open(os.path.join(OUT, 'day_%d.svg' % k), 'w', encoding='utf-8', newline=chr(10)).write(svg(day(k)))
        n += 1
    for h in range(1, 13):
        open(os.path.join(OUT, 'clock_%d.svg' % h), 'w', encoding='utf-8', newline=chr(10)).write(svg(clock(h)))
        n += 1
    for name, body in MORE.items():
        open(os.path.join(OUT, name + '.svg'), 'w', encoding='utf-8', newline=chr(10)).write(svg(body))
        n += 1
    # a thing in three sizes: the same drawing, scaled about the middle
    for thing in ('star', 'apple', 'fish'):
        for tag, k in (('s', 0.4), ('m', 0.68), ('l', 1.0)):
            body = '<g transform="translate(50 50) scale(%s) translate(-50 -50)">%s</g>' % (k, inner(thing))
            open(os.path.join(OUT, '%s_size_%s.svg' % (thing, tag)), 'w', encoding='utf-8', newline=chr(10)).write(svg(body))
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
