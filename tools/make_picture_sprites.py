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
    for name, body in SINGLES.items():
        open(os.path.join(OUT, name + '.svg'), 'w', encoding='utf-8', newline='\n').write(svg(body))
        n += 1
    print('wrote', n)


main()
