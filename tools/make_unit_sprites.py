"""Draws the simple placeholder sprites of the Counting Hills unit into content/starter.

They are deliberately plain (flat shapes, the brand colours): the real drawings come from the illustrator (see
docs/art/art-brief.md) and replace these files one by one under the same asset ids, with no change to any activity.
Every sprite has a "_lit" twin with a soft glow, used when a child touches it while counting.
"""
import os

OUT = os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', 'content', 'starter')

INK = '#2B2540'
GLOW = '<circle cx="50" cy="50" r="48" fill="#FFE680" opacity="0.75"/>'


def svg(body, w=100, h=100):
    return ('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 %d %d" width="%d" height="%d">%s</svg>\n'
            % (w, h, w, h, body))


SPRITES = {
    'ladybug': ('<ellipse cx="50" cy="56" rx="30" ry="26" fill="#E5484D"/><circle cx="50" cy="30" r="14" fill="%s"/>'
                '<line x1="50" y1="32" x2="50" y2="82" stroke="%s" stroke-width="3"/>'
                '<circle cx="38" cy="52" r="5" fill="%s"/><circle cx="62" cy="52" r="5" fill="%s"/>'
                '<circle cx="40" cy="68" r="4" fill="%s"/><circle cx="60" cy="68" r="4" fill="%s"/>'
                % ((INK,) * 6)),
    'star': ('<polygon points="50,8 61,38 93,38 67,57 77,88 50,69 23,88 33,57 7,38 39,38" fill="#FFC531" '
             'stroke="#E39A00" stroke-width="3" stroke-linejoin="round"/>'),
    'apple': ('<circle cx="50" cy="56" r="32" fill="#E5484D"/><path d="M50 26 Q52 12 62 10" stroke="#6B4423" '
              'stroke-width="4" fill="none" stroke-linecap="round"/><ellipse cx="64" cy="20" rx="10" ry="5" '
              'fill="#4CAF50" transform="rotate(-25 64 20)"/>'),
    'fish': ('<ellipse cx="44" cy="50" rx="30" ry="20" fill="#FF9F43"/><polygon points="70,50 94,32 94,68" '
             'fill="#FF9F43"/><circle cx="32" cy="45" r="4" fill="%s"/>' % INK),
    'bird': ('<circle cx="46" cy="54" r="30" fill="#4DA3FF"/><polygon points="74,50 94,56 74,62" fill="#FFB020"/>'
             '<circle cx="58" cy="46" r="4" fill="%s"/><ellipse cx="38" cy="60" rx="14" ry="9" fill="#2F7ED8"/>' % INK),
    'duck': ('<circle cx="46" cy="56" r="30" fill="#FFD84D"/><polygon points="74,54 96,60 74,66" fill="#FF9F43"/>'
             '<circle cx="58" cy="48" r="4" fill="%s"/><ellipse cx="36" cy="62" rx="13" ry="8" fill="#F2B800"/>' % INK),
    'cat': ('<polygon points="20,40 24,10 44,28" fill="#9AA0B4"/><polygon points="80,40 76,10 56,28" fill="#9AA0B4"/>'
            '<circle cx="50" cy="56" r="34" fill="#B7BCCD"/><circle cx="38" cy="52" r="5" fill="%s"/>'
            '<circle cx="62" cy="52" r="5" fill="%s"/><polygon points="46,62 54,62 50,68" fill="#E86AA6"/>'
            % (INK, INK)),
    'dog': ('<ellipse cx="22" cy="48" rx="12" ry="24" fill="#8A5A2B"/><ellipse cx="78" cy="48" rx="12" ry="24" '
            'fill="#8A5A2B"/><circle cx="50" cy="54" r="32" fill="#C98F52"/><circle cx="38" cy="48" r="5" '
            'fill="%s"/><circle cx="62" cy="48" r="5" fill="%s"/><ellipse cx="50" cy="64" rx="9" ry="6" '
            'fill="%s"/>' % (INK, INK, INK)),
    'tick': ('<circle cx="50" cy="50" r="42" fill="#4CAF50"/><polyline points="28,52 44,68 74,34" fill="none" '
             'stroke="#FFFFFF" stroke-width="10" stroke-linecap="round" stroke-linejoin="round"/>'),
    'cross': ('<circle cx="50" cy="50" r="42" fill="#E5484D"/><line x1="32" y1="32" x2="68" y2="68" stroke="#FFFFFF" '
              'stroke-width="10" stroke-linecap="round"/><line x1="68" y1="32" x2="32" y2="68" stroke="#FFFFFF" '
              'stroke-width="10" stroke-linecap="round"/>'),
    'basket_target': ('<path d="M12 44 H88 L78 88 H22 Z" fill="#C98F52"/><path d="M12 44 H88" stroke="#8A5A2B" '
                      'stroke-width="6" stroke-linecap="round"/><path d="M30 44 C30 14 70 14 70 44" fill="none" '
                      'stroke="#8A5A2B" stroke-width="5"/>'),
}

# Scenes where nothing is: a nest, a bowl and a basket with nothing in them (the empty set, NUM-A-14).
SCENES = {
    'nest_empty': ('<rect width="400" height="225" fill="#CDEBFF"/><rect y="170" width="400" height="55" fill="#8CCB6B"/>'
                   '<ellipse cx="200" cy="150" rx="90" ry="34" fill="#A9743C"/><ellipse cx="200" cy="140" rx="70" '
                   'ry="22" fill="#7A4F26"/>'),
    'bowl_empty': ('<rect width="400" height="225" fill="#FFF1CC"/><rect y="170" width="400" height="55" fill="#E7C98F"/>'
                   '<path d="M110 120 H290 C290 190 110 190 110 120 Z" fill="#6EC1E4"/><ellipse cx="200" cy="120" '
                   'rx="90" ry="14" fill="#BFE8F7"/>'),
    'basket_empty': ('<rect width="400" height="225" fill="#E6F6D8"/><rect y="170" width="400" height="55" fill="#8CCB6B"/>'
                     '<path d="M120 110 H280 L262 190 H138 Z" fill="#C98F52"/><path d="M120 110 H280" stroke="#8A5A2B" '
                     'stroke-width="8" stroke-linecap="round"/><ellipse cx="200" cy="112" rx="80" ry="12" '
                     'fill="#7A4F26"/>'),
}


def main():
    for name, body in SPRITES.items():
        open(os.path.join(OUT, name + '.svg'), 'w', encoding='utf-8', newline='\n').write(svg(body))
        if name not in ('tick', 'cross', 'basket_target'):
            open(os.path.join(OUT, name + '_lit.svg'), 'w', encoding='utf-8', newline='\n').write(svg(GLOW + body))
    for name, body in SCENES.items():
        open(os.path.join(OUT, name + '.svg'), 'w', encoding='utf-8', newline='\n').write(svg(body, 400, 225))
    print('wrote', len(SPRITES) + len(SCENES) + len([n for n in SPRITES if n not in ('tick', 'cross', 'basket_target')]))


main()
