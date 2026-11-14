"""Layout boards of docs/design/m11-rooms.md (M11 Stage 1: a room per place, the host as the teacher of its land, a celebration per
place, the stage that reacts). Every board is drawn at its real size in points with the app's own pictures and fonts, rendered by
headless Chrome into docs/design/m11/*.png:

    python docs/design/m11/make_m11_boards.py

Boards written:
  counting_hills_phone.png  Counting Hills on the phone: Show (Nekudi teaches, the companion watches), Alone (the companion asks),
                            the stage reaction's end state, the celebration.
  robot_harbour_phone.png   Robot Harbour on the phone: Show (predict, then watch; Tza'adon runs the program), Alone (the robot grid
                            and the arrow palette), the celebration.
  host_beat_boards.png      A host beat (Counting Hills, Show) on the four boards: phone, phone SE, tablet landscape and portrait.
  nine_rooms.png            The nine rooms' frames side by side, small (host beat, empty stage), and nine_rooms_grey.png in greyscale.
  nekudi_poses.png          Nekudi's three new poses beside her still, at full size, at the phone's size and as 48 pt silhouettes.

Only existing art is used (design/assets, app/assets/art, content/starter), plus the three Nekudi poses drawn for this step
(design/assets/nekudi-talk.svg, -show.svg, -celebrate.svg). The backdrops are not pictures: they are the code-drawn layers the spec
defines (section 3.2), drawn here in inline SVG from the tokens so the developer can match them. Where the spec needs art that does not
exist yet (Goni's colour-safe skin, the colour-safe pool), the board simulates it with a desaturation filter and says so in its caption.
Every Hebrew line on the boards is a sample for the hebrew-text-editor, not final text. Red captions under a board are for the team.

References for the backdrops (looked at, nothing traced; the shapes are the map's own vocabulary, design-spec 3.2 and 9.6): the
approved boards 04 (world map) and 13, 23, 26 (activity frames); content/starter/meadow.svg (today's backdrop); app/assets/art/world/*
(the landmarks); app/assets/art/languages/door_*.svg (the windows of the three course doors).
"""
import os
import pathlib
import subprocess
import tempfile
import html as htmlmod

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.normpath(os.path.join(HERE, '..', '..', '..'))
CHROME = r'C:\Program Files\Google\Chrome\Application\chrome.exe'
CAST = os.path.join(ROOT, 'design', 'assets')
ART = os.path.join(ROOT, 'app', 'assets', 'art')
PICS = os.path.join(ROOT, 'content', 'starter')
FONTS = os.path.join(ROOT, 'app', 'assets', 'fonts')


def uri(p):
    return pathlib.Path(p).as_uri()


FONT_CSS = ("@font-face{font-family:H;src:url('%s');font-weight:100 900}"
            "@font-face{font-family:S;src:url('%s')}") % (uri(os.path.join(FONTS, 'Heebo-Variable.ttf')),
                                                          uri(os.path.join(FONTS, 'SecularOne-Regular.ttf')))

# ---- tokens (design/tokens.json) ----------------------------------------------------------------------------------------
C = dict(cream='#FFF6E8', paper='#FFFFFF', ink='#2B2350', inkSoft='#5A5378', mist='#EDE6F7', hairline='#E6DDF0', lip='#DCD3EC',
         spark='#FFC83D', sparkDeep='#E0A21A', sparkTint='#FFF1C4', sky='#8FD3F4', skyTint='#E3F4FC', sea='#1A9E9A',
         seaDeep='#0F6E6A', sunset='#FF8A3D', sunsetDeep='#D9692A', scrim='rgba(43,35,80,0.45)', sketch='rgba(43,35,80,0.35)',
         skyTop='#CDEFFF', skyBottom='#FFF1D6', sea1='#A8E3E3', sea2='#6CCBCD', sand='#F6DDB0', sandShade='#E8C48A',
         grass='#A8DB8F', grassShade='#86C474', tree='#8FD3A0', treeShade='#6FBF8C', wood='#B07A52', woodLight='#D7A27A',
         rock='#C9C3D9', rockShade='#A9A1C2', lilac='#B9A2F7')

# ---- the boards (ActivitySpec in app/lib/child/activity_shell.dart) -------------------------------------------------------
B = {
    'phone': dict(W=852, H=393, ctrl=64, eye=(59, 12), hint=(147, 12), home=(729, 12), trail=(344, 26), stage=(71, 96, 330, 128),
                  card=False, bubble=dict(right=603, w=190, top=104, font=26), guide=(617, 80, 176), mic=(661, 260, 88),
                  tiles=(71, 244, 534), host=(597, 88, 168), buddy=(697, 158, 96), hostBubbleRight=591, name='phone 852 x 393'),
    'phoneSE': dict(W=667, H=375, ctrl=64, eye=(16, 8), hint=(96, 8), home=(587, 8), trail=(333, 22), stage=(16, 86, 270, 104),
                    card=False, bubble=dict(right=476, w=176, top=92, font=22), guide=(490, 66, 150), mic=(521, 226, 88),
                    tiles=(8, 214, 480), host=(478, 74, 144), buddy=(565, 128, 86), hostBubbleRight=470, name='phone SE 667 x 375'),
    'tabletL': dict(W=1180, H=820, ctrl=64, eye=(24, 24), hint=(112, 24), home=(1092, 24), trail=(590, 38), stage=(288, 230, 584, 300),
                    card=True, bubble=dict(right=956, w=600, top=112, font=28), guide=(896, 150, 260), mic=(978, 672, 96),
                    tiles=(288, 554, 584), host=(872, 150, 260), buddy=(1004, 250, 152), hostBubbleRight=932,
                    name='tablet landscape 1180 x 820'),
    'tabletP': dict(W=820, H=1180, ctrl=64, eye=(24, 32), hint=(112, 32), home=(732, 32), trail=(410, 46), stage=(24, 372, 772, 300),
                    card=True, bubble=dict(right=596, w=440, top=152, font=28), guide=(596, 112, 200), mic=(44, 172, 96),
                    tiles=(24, 696, 772), host=(572, 128, 184), buddy=(680, 190, 116), hostBubbleRight=566,
                    name='tablet portrait 820 x 1180'),
}


def esc(t):
    return htmlmod.escape(t)


def box(x, y, w, h, style='', inner=''):
    return '<div style="position:absolute;left:%.1fpx;top:%.1fpx;width:%.1fpx;height:%.1fpx;box-sizing:border-box;%s">%s</div>' % (
        x, y, w, h, style, inner)


def img(path, x, y, w, h, extra=''):
    return '<img src="%s" style="position:absolute;left:%.1fpx;top:%.1fpx;width:%.1fpx;height:%.1fpx;object-fit:contain;%s">' % (
        uri(path), x, y, w, h, extra)


def svg_at(x, y, w, h, body, view=None, extra=''):
    vb = view or '0 0 %g %g' % (w, h)
    return ('<svg xmlns="http://www.w3.org/2000/svg" viewBox="%s" style="position:absolute;left:%.1fpx;top:%.1fpx;width:%.1fpx;'
            'height:%.1fpx;overflow:visible;%s">%s</svg>') % (vb, x, y, w, h, extra, body)


# ---- the nine rooms (spec section 3.1) --------------------------------------------------------------------------------------
def backdrop(kind, w, h):
    """The code-drawn backdrop of a room, in the stage's own points (spec 3.2). Returns SVG body."""
    g = lambda i, a, b: ('<defs><linearGradient id="g%s" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="%s"/>'
                         '<stop offset="1" stop-color="%s"/></linearGradient></defs>' % (i, a, b))
    if kind == 'hills':
        stones = ''.join('<ellipse cx="%.1f" cy="%.1f" rx="%.1f" ry="%.1f" fill="#FFFFFF" opacity="0.75"/>' % (
            w * (0.50 + 0.085 * i), h * (0.90 - 0.035 * i), h * 0.045, h * 0.022) for i in range(5))
        return (g('h', C['skyTop'], C['skyBottom']) + '<rect width="%g" height="%g" fill="url(#gh)"/>' % (w, h) +
                '<circle cx="%g" cy="%g" r="%g" fill="%s"/>' % (w * 0.22, h * 1.18, h * 0.62, C['tree']) +
                '<circle cx="%g" cy="%g" r="%g" fill="%s"/>' % (w * 0.62, h * 1.30, h * 0.70, C['tree']) +
                '<circle cx="%g" cy="%g" r="%g" fill="%s"/>' % (w * 0.95, h * 1.10, h * 0.52, C['tree']) +
                '<ellipse cx="%g" cy="%g" rx="%g" ry="%g" fill="%s"/>' % (w * 0.30, h * 1.06, w * 0.45, h * 0.32, C['grass']) +
                '<ellipse cx="%g" cy="%g" rx="%g" ry="%g" fill="%s"/>' % (w * 0.80, h * 1.08, w * 0.42, h * 0.30, C['grassShade']) + stones)
    if kind == 'bay':
        wave = 'M0 %g ' % (h * 0.70) + ''.join('q%g %g %g 0 ' % (w / 16, -h * 0.05, w / 8) + 'q%g %g %g 0 ' % (w / 16, h * 0.05, w / 8)
                                                for _ in range(4)) + 'V%g H0 Z' % h
        return (g('b', '#FFFFFF', '#F5F2F8') + '<rect width="%g" height="%g" fill="url(#gb)"/>' % (w, h) +
                '<path d="%s" fill="%s"/>' % (wave, '#E9E6EF') +
                '<rect y="%g" width="%g" height="%g" fill="%s"/>' % (h * 0.84, w, h * 0.16, '#F1ECE4') +
                '<path d="M0 %g H%g" stroke="%s" stroke-width="1.5" opacity="0.6"/>' % (h * 0.84, w, C['rock']))
    if kind == 'forest':
        trees = ''
        for i, (fx, s, col) in enumerate([(0.10, 0.50, 'tree'), (0.28, 0.66, 'tree'), (0.46, 0.44, 'tree'), (0.63, 0.70, 'tree'),
                                          (0.82, 0.52, 'tree'), (0.97, 0.62, 'tree'),
                                          (0.20, 0.40, 'treeShade'), (0.55, 0.36, 'treeShade'), (0.88, 0.42, 'treeShade')]):
            base = h * 0.86
            th = h * s
            cx = w * fx
            trees += '<path d="M%g %g L%g %g L%g %g Z" fill="%s"/>' % (cx, base - th, cx + th * 0.36, base, cx - th * 0.36, base, C[col])
        return (g('f', C['skyTop'], '#EAF7EE') + '<rect width="%g" height="%g" fill="url(#gf)"/>' % (w, h) + trees +
                '<rect y="%g" width="%g" height="%g" fill="%s"/>' % (h * 0.84, w, h * 0.16, C['grass']))
    if kind == 'grotto':
        drips = ''.join('<path d="M%g 0 Q%g %g %g 0 Z" fill="%s"/>' % (
            w * x0, w * (x0 + 0.03), h * d, w * (x0 + 0.06), C['rock']) for x0, d in
            [(0.02, 0.30), (0.12, 0.18), (0.30, 0.22), (0.52, 0.14), (0.70, 0.26), (0.86, 0.16), (0.93, 0.28)])
        return (g('c', '#F7F3FF', '#ECE3FE') + '<rect width="%g" height="%g" fill="url(#gc)"/>' % (w, h) +
                '<path d="M0 0 H%g V%g Q%g %g %g %g Q%g %g 0 %g Z" fill="%s" opacity="0.55"/>' % (
                    w, h * 0.10, w * 0.5, h * 0.02, w * 0.0, h * 0.10, 0, 0, h * 0.10, C['rock']) +
                '<path d="M0 0 H%g Q%g %g %g %g H0 Z" fill="%s"/>' % (w * 0.07, w * 0.015, h * 0.5, w * 0.05, h, C['rockShade']) +
                '<path d="M%g 0 H%g Q%g %g %g %g H%g Z" fill="%s"/>' % (w, w * 0.93, w * 0.985, h * 0.5, w * 0.95, h, w, C['rockShade']) + drips +
                '<path d="M0 %g Q%g %g %g %g T%g %g V%g H0 Z" fill="%s"/>' % (
                    h * 0.86, w * 0.25, h * 0.80, w * 0.5, h * 0.86, w, h * 0.84, h, C['sand']))
    if kind == 'harbour':
        waves = ''.join('<path d="M%g %g q%g %g %g 0" stroke="#FFFFFF" stroke-width="2" fill="none" stroke-linecap="round" opacity="0.8"/>' % (
            w * x0, h * y0, w * 0.03, -h * 0.03, w * 0.06) for x0, y0 in [(0.08, 0.62), (0.30, 0.70), (0.55, 0.60), (0.78, 0.68)])
        joints = ''.join('<path d="M%g %g V%g" stroke="%s" stroke-width="2"/>' % (w * i / 8, h * 0.82, h, C['wood']) for i in range(1, 8))
        return (g('r', C['skyTop'], '#EEF6FD') + '<rect width="%g" height="%g" fill="url(#gr)"/>' % (w, h) +
                '<rect y="%g" width="%g" height="%g" fill="%s"/>' % (h * 0.52, w, h * 0.32, C['sea1']) + waves +
                '<rect y="%g" width="%g" height="%g" fill="%s"/>' % (h * 0.82, w, h * 0.18, C['woodLight']) + joints +
                '<path d="M0 %g H%g" stroke="%s" stroke-width="2"/>' % (h * 0.82, w, C['wood']))
    if kind == 'market':
        n = 8
        sw = w / n
        stripes = ''.join('<rect x="%g" y="0" width="%g" height="%g" fill="%s"/>' % (i * sw, sw, h * 0.13, '#F59E1B' if i % 2 == 0 else '#FFFFFF')
                          for i in range(n))
        scallops = ''.join('<path d="M%g %g a%g %g 0 0 0 %g 0 Z" fill="%s"/>' % (i * sw, h * 0.13, sw / 2, h * 0.07, sw,
                                                                                 '#F59E1B' if i % 2 == 0 else '#FFFFFF') for i in range(n))
        return (g('m', '#FFF8EC', '#FEEFD6') + '<rect width="%g" height="%g" fill="url(#gm)"/>' % (w, h) + stripes + scallops +
                '<path d="M0 %g H%g" stroke="%s" stroke-width="1.5" opacity="0.5"/>' % (h * 0.13, w, '#A35A00') +
                '<rect y="%g" width="%g" height="%g" fill="%s"/>' % (h * 0.84, w, h * 0.16, C['sand']) +
                '<path d="M0 %g H%g" stroke="%s" stroke-width="2"/>' % (h * 0.84, w, C['sandShade']))
    if kind.startswith('room_'):
        course = kind[5:]
        wall = {'eng': ('#F4F8FD', '#E1ECF8'), 'heb': ('#FEF6F3', '#FBE4DF'), 'rus': ('#F8F4FD', '#EBE3F7')}[course]
        out = g('w' + course, wall[0], wall[1]) + '<rect width="%g" height="%g" fill="url(#gw%s)"/>' % (w, h, course)
        fy = h * 0.82
        if course == 'eng':   # floorboards
            out += '<rect y="%g" width="%g" height="%g" fill="%s"/>' % (fy, w, h - fy, C['woodLight'])
            out += ''.join('<path d="M%g %g V%g" stroke="%s" stroke-width="2"/>' % (w * i / 6, fy, h, C['wood']) for i in range(1, 6))
        elif course == 'heb':  # stone tiles (the hyrax's rocks)
            out += '<rect y="%g" width="%g" height="%g" fill="%s"/>' % (fy, w, h - fy, C['rock'])
            out += ''.join('<rect x="%g" y="%g" width="%g" height="%g" rx="3" fill="%s"/>' % (
                w * i / 7 + 2, fy + 3, w / 7 - 4, h - fy - 6, '#D8D3E4') for i in range(7))
        else:                  # a striped rug
            out += '<rect y="%g" width="%g" height="%g" fill="%s"/>' % (fy, w, h - fy, '#E8DCC6')
            out += '<rect x="%g" y="%g" width="%g" height="%g" rx="4" fill="%s" opacity="0.35"/>' % (w * 0.2, fy + 4, w * 0.6, h - fy - 8, '#6D49B3')
        out += '<path d="M0 %g H%g" stroke="%s" stroke-width="2" opacity="0.6"/>' % (fy, w, C['wood'])
        return out
    return ''


def window_svg(course, s):
    """The landmark of a course room: its door's window, drawn from the door art's shapes (round, arched, square), with sky in it."""
    frame = {'eng': '#2C6FB8', 'heb': '#D25E4E', 'rus': '#6D49B3'}[course]
    glass = '#FFF3C4'
    if course == 'eng':
        return ('<circle cx="%g" cy="%g" r="%g" fill="%s"/><circle cx="%g" cy="%g" r="%g" fill="%s"/>'
                '<path d="M%g %g V%g M%g %g H%g" stroke="%s" stroke-width="%g"/>') % (
            s / 2, s / 2, s * 0.46, frame, s / 2, s / 2, s * 0.34, glass, s / 2, s * 0.16, s * 0.84, s * 0.16, s / 2, s * 0.84, frame, s * 0.06)
    if course == 'heb':
        return ('<path d="M%g %g V%g A%g %g 0 0 1 %g %g V%g Z" fill="%s"/>'
                '<path d="M%g %g V%g A%g %g 0 0 1 %g %g V%g Z" fill="%s"/>'
                '<path d="M%g %g V%g" stroke="%s" stroke-width="%g"/>') % (
            s * 0.14, s * 0.96, s * 0.40, s * 0.36, s * 0.36, s * 0.86, s * 0.40, s * 0.96, frame,
            s * 0.24, s * 0.88, s * 0.42, s * 0.26, s * 0.26, s * 0.76, s * 0.42, s * 0.88, glass,
            s / 2, s * 0.18, s * 0.88, frame, s * 0.05)
    return ('<rect x="%g" y="%g" width="%g" height="%g" rx="%g" fill="%s"/><rect x="%g" y="%g" width="%g" height="%g" rx="%g" fill="%s"/>'
            '<path d="M%g %g V%g M%g %g H%g" stroke="%s" stroke-width="%g"/>') % (
        s * 0.08, s * 0.08, s * 0.84, s * 0.84, s * 0.10, frame, s * 0.18, s * 0.18, s * 0.64, s * 0.64, s * 0.05, glass,
        s / 2, s * 0.18, s * 0.82, s * 0.18, s / 2, s * 0.82, frame, s * 0.06)


TRAIL = {
    'circle': '<circle cx="10" cy="10" r="9"/>',
    'stair': '<path d="M2 18 V3 H8 V8 H13 V13 H18 V18 Z"/>',
    'drop': '<path d="M10 1.5 C14 7.5 17 10.5 17 13.5 A7 7 0 0 1 3 13.5 C3 10.5 6 7.5 10 1.5 Z"/>',
    'tree': '<path d="M10 1 L18 14.5 H12 V19 H8 V14.5 H2 Z"/>',
    'puzzle': '<path d="M2.5 6 H7 C6.2 2.2 13.8 2.2 13 6 H17.5 V9.8 C13.7 9 13.7 16.2 17.5 15.4 V18.5 H2.5 Z"/>',
    'nut': '<path fill-rule="evenodd" d="M5.5 2.2 H14.5 L19 10 L14.5 17.8 H5.5 L1 10 Z M10 6.6 A3.4 3.4 0 1 0 10 13.4 A3.4 3.4 0 1 0 10 6.6 Z"/>',
    'orange': '<path d="M10 4.6 A7.6 7.6 0 1 1 9.99 4.6 Z M10 4.8 C11 1.6 15.5 1 17 2.2 C15.6 5 12.5 5.8 10 4.8 Z"/>',
    'porthole': '<path fill-rule="evenodd" d="M10 1 A9 9 0 1 1 9.99 1 Z M10 4.5 A5.5 5.5 0 1 0 10.01 4.5 Z"/>',
    'arch': '<path d="M3.5 18.5 V9 A6.5 6.5 0 0 1 16.5 9 V18.5 Z"/>',
    'square': '<path fill-rule="evenodd" d="M2 4 Q2 2 4 2 H16 Q18 2 18 4 V16 Q18 18 16 18 H4 Q2 18 2 16 Z M9 5 H5 V9 H9 Z M15 5 H11 V9 H15 Z M9 11 H5 V15 H9 Z M15 11 H11 V15 H15 Z"/>',
}

SPARK = '<path d="M10 3.5 Q11 9 16.5 10 Q11 11 10 16.5 Q9 11 3.5 10 Q9 9 10 3.5 Z" fill="#FFC83D"/>'

# name, Hebrew sample name, tint (screen), rim (stage frame), deep, backdrop, landmark file, trail, host file, host pose for Show
ROOMS = [
    dict(key='numbers', he='גִּבְעוֹת הַסְּפִירָה', en='Counting Hills', tint='#FFE3DF', rim='#F46A5E', deep='#B4233A', bd='hills',
         lm=os.path.join(ART, 'world', 'stair.svg'), trail='stair', host=os.path.join(CAST, 'nekudi-show.svg'), hostName='Nekudi'),
    dict(key='colors', he='מִפְרַץ הַצְּבָעִים', en='Colour Bay', tint=C['cream'], rim=C['sketch'], deep='#5A5378', bd='bay',
         lm=os.path.join(ART, 'world', 'pool.svg'), lmSafe=True, trail='drop', host=os.path.join(CAST, 'goni.svg'), hostSafe=True,
         hostName='Goni (colour-safe skin)'),
    dict(key='shapes', he='יַעַר הַצּוּרוֹת', en='Shape Forest', tint='#DDF3E6', rim='#34A86A', deep='#1E7F4C', bd='forest',
         lm=os.path.join(ART, 'world', 'cone-tree.svg'), trail='tree', host=os.path.join(CAST, 'kubi.svg'), hostName='Kubi'),
    dict(key='logic', he='מְעָרַת הַחִידוֹת', en='Riddle Grotto', tint='#ECE3FE', rim='#8A5CF0', deep='#6B3FD1', bd='grotto',
         lm=os.path.join(ART, 'world', 'pattern-door.svg'), trail='puzzle', host=os.path.join(CAST, 'timi.svg'), hostName='Timi'),
    dict(key='cs', he='נְמַל הָרוֹבּוֹטִים', en='Robot Harbour', tint='#DEEBFC', rim='#2F7FE0', deep='#1F63C7', bd='harbour',
         lm=os.path.join(ART, 'world', 'dock.svg'), trail='nut', host=os.path.join(CAST, 'tzaadon.svg'), hostName="Tza'adon"),
    dict(key='math', he='כְּפַר הַשּׁוּק', en='Market Village', tint='#FEEFD6', rim='#F59E1B', deep='#A35A00', bd='market',
         lm=os.path.join(ART, 'world', 'stall.svg'), trail='orange', host=os.path.join(CAST, 'pnina.svg'), hostName='Grandma Pnina'),
    dict(key='eng', he='אַנְגְּלִית', en='English (door 1)', tint='#E1ECF8', rim='#2C6FB8', deep='#1F5590', bd='room_eng',
         lm='window:eng', trail='porthole', host=os.path.join(ART, 'languages', 'host_eng.svg'), hostName='Pip the budgie'),
    dict(key='heb', he='עִבְרִית', en='Hebrew (door 2)', tint='#FBE4DF', rim='#D25E4E', deep='#A63A2C', bd='room_heb',
         lm='window:heb', trail='arch', host=os.path.join(ART, 'languages', 'host_heb.svg'), hostName='the hyrax'),
    dict(key='rus', he='רוּסִית', en='Russian (door 3)', tint='#EBE3F7', rim='#6D49B3', deep='#55358F', bd='room_rus',
         lm='window:rus', trail='square', host=os.path.join(ART, 'languages', 'host_rus.svg'), hostName='the giraffe'),
]
ROOM = {r['key']: r for r in ROOMS}
SAFE = 'filter:saturate(0.3);'   # stands in for the colour-safe skin / pool that is still to be drawn


# ---- frame pieces --------------------------------------------------------------------------------------------------------
def pebble(x, y, s, icon, fill=None, lipc=None):
    return [box(x, y, s, s, 'border-radius:50%%;background:%s;box-shadow:0 6px 0 %s,0 2px 6px rgba(43,35,80,.10)' % (
        fill or C['paper'], lipc or C['lip'])), img(os.path.join(ART, 'ui', icon), x + s / 2 - 16, y + s / 2 - 16, 32, 32)]


def trail(b, room, n=6, done=2):
    """The progress trail: n sockets in the room's shape, filled from the start side (right)."""
    shape = TRAIL[room['trail']] if room else TRAIL['circle']
    w = n * 20 + (n - 1) * 8 + 16
    cx, top = B[b]['trail']
    x0 = cx - w / 2
    out = [box(x0, top, w, 36, 'background:#fff;border-radius:18px;box-shadow:0 2px 6px rgba(43,35,80,.10)')]
    for i in range(n):
        x = x0 + w - 8 - 20 - i * 28                    # socket i from the start side (right)
        lift = i * 1.4 if room and room['trail'] == 'stair' else 0   # the Counting Hills trail climbs like its staircase
        y = top + 8 - lift + (3.5 if room and room['trail'] == 'stair' else 0)
        if i < done:
            body = '<g fill="%s">%s</g>%s' % (C['sparkTint'], shape, '<g transform="translate(2 2) scale(0.8)">%s</g>' % SPARK)
            body = '<g fill="%s" stroke="%s" stroke-width="1.2">%s</g>' % (C['sparkTint'], C['sparkDeep'], shape) + \
                   '<g transform="translate(2 2) scale(0.8)">%s</g>' % SPARK
        elif i == done:
            body = '<g fill="#FFFFFF" stroke="%s" stroke-width="2.2" stroke-linejoin="round">%s</g>' % (C['ink'], shape)
        else:
            body = '<g fill="%s">%s</g>' % (C['mist'], shape)
        out.append(svg_at(x, y, 20, 20, body, '0 0 20 20'))
    return out


def stage(b, room, inner_parts=None, landmark=True, lit=False):
    """The stage: the room's backdrop in the room's frame; the landmark at the end-bottom corner (inside on phones and portrait,
    beside the card on tablet landscape)."""
    x, y, w, h = B[b]['stage']
    out = []
    card = B[b]['card']
    if card:
        out.append(box(x, y, w, h, 'background:#fff;border-radius:28px;border:4px solid %s;box-shadow:0 6px 0 %s,0 6px 16px rgba(43,35,80,.14)' % (
            room['rim'], room['deep'] if room['key'] != 'colors' else C['lip'])))
        ix, iy, iw, ih = x + 16, y + 16, w - 32, h - 32
        out.append(svg_at(ix, iy, iw, ih, backdrop(room['bd'], iw, ih), extra='border-radius:16px;overflow:hidden'))
    else:
        ix, iy, iw, ih = x, y, w, h
        out.append(box(x - 4, y - 4, w + 8, h + 8, 'border-radius:28px;background:%s;box-shadow:0 2px 6px rgba(43,35,80,.10)' % room['rim']))
        out.append(svg_at(ix, iy, iw, ih, backdrop(room['bd'], iw, ih), extra='border-radius:24px;overflow:hidden'))
    if landmark:
        out += landmark_at(b, room, ix, iy, iw, ih, lit)
    if inner_parts:
        out += inner_parts(ix, iy, iw, ih)
    return out


def landmark_at(b, room, ix, iy, iw, ih, lit=False):
    out = []
    if b == 'tabletL':
        s = 150
        lx, ly = 288 - 24 - s - 8, 230 + 300 - s + 4
        out.append(box(lx + 6, ly + s - 22, s - 12, 22, 'border-radius:50%;background:rgba(43,35,80,0.14)'))
    else:
        s = round(ih * 0.44)
        lx, ly = ix + 6, iy + ih - s - 2
    if lit:
        out.append(box(lx - 8, ly - 8, s + 16, s + 16, 'border-radius:50%%;background:radial-gradient(%s 0%%, rgba(255,241,196,0) 70%%)' % C['sparkTint']))
    if room['lm'].startswith('window:'):
        out.append(svg_at(lx, ly - (ih * 0.30 if b != 'tabletL' else 40), s, s, window_svg(room['lm'][7:], s)))
    else:
        out.append(img(room['lm'], lx, ly, s, s, SAFE if room.get('lmSafe') else ''))
    return out


def bubble(b, text, right=None, tail_y=None, font=None, maxw=None):
    bb = B[b]['bubble']
    r = right or bb['right']
    w = maxw or bb['w']
    f = font or bb['font']
    out = [box(r - w, bb['top'], w, 10, 'overflow:visible;display:flex;justify-content:flex-end;align-items:flex-start',
               '<div dir="rtl" lang="he" style="position:relative;background:#fff;border-radius:24px;padding:8px 16px;'
               'box-shadow:0 6px 0 %s,0 6px 16px rgba(43,35,80,.12);font:500 %dpx/1.7 H;color:%s;text-align:right">%s'
               '<div style="position:absolute;right:-11px;top:%dpx;width:0;height:0;border-top:11px solid transparent;'
               'border-bottom:11px solid transparent;border-left:13px solid #fff"></div></div>' % (
                   C['lip'], f, C['ink'], esc(text), (tail_y or 30)))]
    return out


def character(path, x, y, s, extra=''):
    return img(path, x, y, s, s, extra)


def tile(x, y, s, inner):
    return box(x, y, s, s, 'background:#fff;border:4px solid %s;border-radius:28px;box-shadow:0 6px 0 %s,0 6px 16px rgba(43,35,80,.14);'
               'display:flex;align-items:center;justify-content:center' % (C['hairline'], C['lip']), inner)


def numeral(t, size):
    return '<span dir="ltr" style="font:800 %dpx/1 H;color:%s">%s</span>' % (size, C['ink'], t)


def base(b, room, n=6, done=2, bg=None):
    W, H = B[b]['W'], B[b]['H']
    out = [box(0, 0, W, H, 'background:%s;border:1px solid #C9C3D9' % (bg or room['tint']))]
    s = B[b]['ctrl']
    for k, ic in (('eye', 'eye.svg'), ('hint', 'hint.svg'), ('home', 'home_palm.svg')):
        out += pebble(B[b][k][0], B[b][k][1], s, ic)
    out += trail(b, room, n, done)
    return out


def duo(b, room, host_path=None, host_extra='', buddy_pose='nitzi-listen.svg'):
    """A host beat: the host in front (the speaker's place), the companion half a step behind on the outer side, smaller."""
    hx, hy, hs = B[b]['host']
    bx, by, bs = B[b]['buddy']
    return [character(os.path.join(CAST, buddy_pose), bx, by, bs),
            character(host_path or room['host'], hx, hy, hs, host_extra + ('transform:scaleX(1);'))]


def alone(b):
    gx, gy, gs = B[b]['guide']
    return [character(os.path.join(CAST, 'nitzi-idle.svg'), gx, gy, gs)]


# ---- stage contents -------------------------------------------------------------------------------------------------------
APPLE = os.path.join(PICS, 'apple.svg')


def ten_frame(x, y, cell, filled, lit_cell=None):
    out = [box(x, y, cell * 5, cell * 2, 'background:#fff;border:3px solid %s;border-radius:6px' % C['ink'])]
    for c in range(1, 5):
        out.append(box(x + c * cell - 1, y, 2, cell * 2, 'background:%s' % C['ink']))
    out.append(box(x, y + cell - 1, cell * 5, 2, 'background:%s' % C['ink']))
    for i in range(10):
        r, c = divmod(i, 5)
        cx, cy = x + c * cell, y + r * cell        # a ten-frame fills left to right (it is a number picture: it never mirrors)
        if i < filled:
            out.append(img(APPLE, cx + cell * 0.12, cy + cell * 0.12, cell * 0.76, cell * 0.76))
        if lit_cell is not None and i == lit_cell:
            out.append(box(cx + 3, cy + 3, cell - 6, cell - 6, 'border:3px dashed %s;border-radius:6px;background:rgba(255,241,196,.7)' % C['sparkDeep']))
    return out


def host_hand(tip_x, tip_y, from_y, color='#3F3A7A', r=9):
    """Nekudi's worked-example hand in the stage (the #hand group of nekudi-show.svg): her leg reaches up from the stage's edge."""
    return [svg_at(tip_x - 30, tip_y - 12, 60, from_y - tip_y + 12,
                   '<path d="M%g %g L%g %g L%g %g" stroke="%s" stroke-width="7" stroke-linecap="round" stroke-linejoin="round" fill="none"/>'
                   '<circle cx="30" cy="12" r="%g" fill="%s"/><circle cx="27" cy="9" r="2.5" fill="#fff" opacity=".4"/>' % (
                       40, from_y - tip_y + 12, 36, (from_y - tip_y) * 0.45 + 12, 30, 12 + r * 0.6, color, r, color))]


ARROW = {'right': 'M6 12 H18 M13 7 L18 12 L13 17', 'left': 'M18 12 H6 M11 7 L6 12 L11 17', 'up': 'M12 18 V6 M7 11 L12 6 L17 11',
         'down': 'M12 6 V18 M7 13 L12 18 L17 13'}


def arrow_svg(d, size=24, color=None):
    return '<svg viewBox="0 0 24 24" width="%d" height="%d"><path d="%s" fill="none" stroke="%s" stroke-width="2.6" stroke-linecap="round" stroke-linejoin="round"/></svg>' % (
        size, size, ARROW[d], color or C['ink'])


def robot_grid(x, y, w, h, robot_cell, flag_cell, path=None, cols=4, rows=3, badge=None):
    out = []
    gap = 6
    cw = (w - gap * (cols - 1)) / cols
    ch = (h - gap * (rows - 1)) / rows
    s = min(cw, ch)
    gw = s * cols + gap * (cols - 1)
    gx = x + (w - gw) / 2
    pos = lambda c, r: (gx + c * (s + gap), y + r * (s + gap))
    for r in range(rows):
        for c in range(cols):
            px, py = pos(c, r)
            on_path = path and (c, r) in path
            out.append(box(px, py, s, s, 'background:%s;border:2px solid %s;border-radius:10px' % (
                'rgba(143,211,244,.45)' if on_path else 'rgba(255,255,255,.85)', C['hairline'])))
    if path:
        for i, (c, r) in enumerate(path):
            px, py = pos(c, r)
            out.append(box(px + s - 22, py + s - 22, 20, 20, 'background:#fff;border:2px solid %s;border-radius:50%%;font:700 12px/16px H;'
                           'text-align:center;color:%s' % (C['skyDeep'] if 'skyDeep' in C else '#5BB6E0', C['ink']), str(i + 1)))
    fx, fy = pos(*flag_cell)
    out.append(img(os.path.join(PICS, 'flag.svg'), fx + s * 0.12, fy + s * 0.08, s * 0.76, s * 0.84))
    rx, ry = pos(*robot_cell)
    out.append(img(os.path.join(PICS, 'robot.svg'), rx + s * 0.1, ry + s * 0.06, s * 0.8, s * 0.88))
    return out, pos, s


# ---- the boards -----------------------------------------------------------------------------------------------------------
def board_counting_show(b='phone'):
    room = ROOM['numbers']
    out = base(b, room, n=6, done=0)
    x, y, w, h = B[b]['stage']

    def inner(ix, iy, iw, ih):
        cell = min((ih - 40) / 2, 62) if B[b]['card'] else ih * 0.31
        fw = cell * 5
        fx = ix + iw - fw - (8 if not B[b]['card'] else (iw - fw) / 2 - 40)
        fy = iy + (ih - cell * 2) / 2
        parts = ten_frame(fx, fy, cell, 7, lit_cell=7)
        # the child's counter waits on a little tray at the frame's end side: the child places the last one
        tx = fx - cell * 1.25
        parts.append(box(tx - 4, fy + cell * 0.5 - 4, cell * 1.05, cell * 1.05, 'background:rgba(255,255,255,.9);border-radius:14px;border:2px dashed %s' % C['lip']))
        parts.append(img(APPLE, tx + cell * 0.08, fy + cell * 0.58, cell * 0.8, cell * 0.8))
        # Nekudi's hand points at the place of the next counter (cell 8: the bottom row, third from the left)
        cx = fx + 2.5 * cell
        parts += host_hand(cx, fy + cell * 1.55, iy + ih + 2)
        return parts

    out += stage(b, room, inner)
    hb = B[b]
    out += duo(b, room, os.path.join(CAST, 'nekudi-show.svg'))
    mouth = hb['host'][1] + 0.52 * hb['host'][2]
    out += bubble(b, 'וְעוֹד אֶחָד: עַכְשָׁו אַתֶּם!', right=hb['hostBubbleRight'],
                  tail_y=max(18, mouth - hb['bubble']['top'] - 11), maxw=hb['bubble']['w'] - (hb['bubble']['right'] - hb['hostBubbleRight']))
    return out


def board_counting_alone(b='phone', reacted=False):
    room = ROOM['numbers']
    out = base(b, room, n=6, done=3 if not reacted else 4)

    def inner(ix, iy, iw, ih):
        cell = ih * 0.375
        fw = cell * 5
        fx = ix + iw - fw - 12
        fy = iy + (ih - cell * 2) / 2
        return ten_frame(fx, fy, cell, 9)

    out += stage(b, room, inner, lit=reacted)
    if reacted:
        # the reaction's end state: one step of the staircase is lit and a counting dot stands on its top step (spec 5.1)
        x, y, w, h = B[b]['stage']
        s = round(h * 0.44)
        lx, ly = x + 6, y + h - s - 2
        out.append(svg_at(lx, ly, s, s, '<path d="M24 22 H40 V38 H24 Z" fill="%s" stroke="#2B2540" stroke-width="3"/>'
                          '<circle cx="32" cy="14" r="6" fill="%s" stroke="#2B2540" stroke-width="2"/>' % (C['spark'], '#F46A5E'), '0 0 100 100'))
    out += alone(b)
    out += bubble(b, 'כַּמָּה תַּפּוּחִים יֵשׁ?', tail_y=46)
    tx, ty, tw = B[b]['tiles']
    S, gap = 96, 32
    total = 3 * S + 2 * gap
    x0 = tx + (tw - total) / 2
    for i, t in enumerate(['10', '9', '8']):     # numeral tiles keep the row's order of the existing template
        out.append(tile(x0 + i * (S + gap), ty, S, numeral(t, 56)))
    if reacted:
        out.append(box(x0 + 1 * (S + gap) - 4, ty - 4, S + 8, S + 8, 'border:4px solid %s;border-radius:32px' % C['spark']))
        out.append(box(x0 + 1 * (S + gap) + S - 20, ty - 8, 28, 28, 'background:%s;border-radius:50%%;display:flex;align-items:center;justify-content:center' % C['spark'],
                       '<svg viewBox="0 0 24 24" width="18" height="18"><path d="M5 12.5l4.2 4.2L19 7" fill="none" stroke="#2B2350" stroke-width="3" stroke-linecap="round" stroke-linejoin="round"/></svg>'))
    return out


def board_celebration(b, room, host_pose, line, piece_svg):
    out = base(b, room, n=6, done=6)
    out += stage(b, room)
    out += alone(b)
    W, H = B[b]['W'], B[b]['H']
    out.append(box(0, 0, W, H, 'background:%s' % C['scrim']))
    cw = min(W - 80, 520)
    band = 140
    chh = band + 16 + 46 + 12 + 72 + 6 + 20
    cx, cy = (W - cw) / 2, (H - chh) / 2
    out.append(box(cx, cy, cw, chh, 'background:#fff;border-radius:28px;border:4px solid %s;box-shadow:0 6px 0 %s,0 12px 28px rgba(43,35,80,.18)' % (
        room['rim'], room['deep'])))
    # the room's window: backdrop, the landmark with its new piece, the host and the companion celebrating
    out.append(svg_at(cx + 12, cy + 12, cw - 24, band, backdrop(room['bd'], cw - 24, band), extra='border-radius:20px;overflow:hidden'))
    ls = 104
    lx, ly = cx + 28, cy + 12 + band - ls - 4
    out.append(box(lx - 14, ly - 14, ls + 28, ls + 28, 'border-radius:50%;background:radial-gradient(rgba(255,241,196,.95) 0%, rgba(255,241,196,0) 68%)'))
    if room['lm'].startswith('window:'):
        out.append(svg_at(lx, ly, ls, ls, window_svg(room['lm'][7:], ls)))
    else:
        out.append(img(room['lm'], lx, ly, ls, ls))
    out.append(svg_at(lx, ly, ls, ls, piece_svg, '0 0 100 100'))
    out.append(character(host_pose, cx + cw / 2 - 150, cy + 12 + band - 150, 150))
    out.append(character(os.path.join(CAST, 'nitzi-celebrate.svg'), cx + cw / 2 - 10, cy + 12 + band - 132, 132))
    # the sticker the child earned pops in at the start side of the window
    out.append(box(cx + cw - 12 - 100, cy + 24, 84, 84, 'background:#fff;border-radius:22px;padding:6px;box-shadow:0 6px 16px rgba(43,35,80,.14)',
                   '<img src="%s" style="width:72px;height:72px">' % uri(os.path.join(ART, 'stickers', 'sticker_04.svg'))))
    out.append(box(cx + 16, cy + 12 + band + 12, cw - 32, 46, 'text-align:center',
                   '<span dir="rtl" lang="he" style="font:600 26px/1.7 H;color:%s">%s</span>' % (C['ink'], esc(line))))
    bx = cx + cw / 2 - 36
    out.append(box(bx, cy + 12 + band + 12 + 46 + 10, 72, 72, 'border-radius:50%%;background:%s;box-shadow:0 6px 0 %s' % (C['spark'], C['sparkDeep'])))
    out.append(img(os.path.join(ART, 'ui', 'home_palm.svg'), bx + 18, cy + 12 + band + 12 + 46 + 10 + 18, 36, 36))
    return out


STAIR_PIECE = ('<path d="M12 54 V6 H24 V54 Z" fill="%s" stroke="#2B2540" stroke-width="3" stroke-linejoin="round"/>'
               '<path d="M12 6 H24 V22 H12 Z" fill="%s" stroke="#2B2540" stroke-width="3"/>'
               '<path d="M4 2 L8 8 M32 0 L28 6 M18 -6 V0" stroke="%s" stroke-width="3" stroke-linecap="round"/>') % ('#F46A5E', '#FFC83D', '#E0A21A')
CRATE_PIECE = ('<path d="M50 4 V28" stroke="#2B2540" stroke-width="2.5"/>'
               '<rect x="38" y="10" width="24" height="18" rx="2" fill="#D7A27A" stroke="#2B2540" stroke-width="3"/>'
               '<path d="M38 10 L62 28 M62 10 L38 28" stroke="#B07A52" stroke-width="2"/>')


def board_robot_show(b='phone'):
    room = ROOM['cs']
    out = base(b, room, n=6, done=0)
    x, y, w, h = 71, 96, 330, 282           # the phone's tall stage of the robot templates (B-38)
    out.append(box(x - 4, y - 4, w + 8, h + 8, 'border-radius:28px;background:%s;box-shadow:0 2px 6px rgba(43,35,80,.10)' % room['rim']))
    out.append(svg_at(x, y, w, h, backdrop('harbour', w, h), extra='border-radius:24px;overflow:hidden'))
    s = round(h * 0.30)
    out.append(img(room['lm'], x + 4, y + h - s - 2, s, s))
    parts, pos, cs = robot_grid(x + 14, y + 12, w - 28, h - 70, (0, 0), (2, 1), path=[(1, 0), (2, 0), (2, 1)])
    out += parts
    # the program, read left to right (arrows are absolute directions and never mirror)
    py = y + h - 50
    for i, d in enumerate(['right', 'right', 'down']):
        out.append(box(x + 90 + i * 52, py, 44, 44, 'background:#fff;border:2px solid %s;border-radius:12px;display:flex;align-items:center;'
                       'justify-content:center;box-shadow:0 3px 0 %s' % (C['hairline'], C['lip']), arrow_svg(d, 26)))
    out.append(box(x + 90 + 2 * 52 - 4, py - 4, 52, 52, 'border:3px solid %s;border-radius:15px' % C['sky']))
    hb = B[b]
    out += duo(b, room)
    out += bubble(b, 'צַעַד, וְעוֹד צַעַד, וּלְמַטָּה. בִּיפּ־בּוּפּ!', right=hb['hostBubbleRight'], tail_y=40,
                  maxw=hb['bubble']['w'] - (hb['bubble']['right'] - hb['hostBubbleRight']))
    return out


def board_robot_alone(b='phone'):
    room = ROOM['cs']
    out = base(b, room, n=6, done=2)
    x, y, w, h = 71, 96, 330, 282
    out.append(box(x - 4, y - 4, w + 8, h + 8, 'border-radius:28px;background:%s;box-shadow:0 2px 6px rgba(43,35,80,.10)' % room['rim']))
    out.append(svg_at(x, y, w, h, backdrop('harbour', w, h), extra='border-radius:24px;overflow:hidden'))
    s = round(h * 0.30)
    out.append(img(room['lm'], x + 4, y + h - s - 2, s, s))
    parts, pos, cs = robot_grid(x + 14, y + 12, w - 28, h - 70, (0, 0), (3, 2))
    out += parts
    py = y + h - 46
    for i in range(5):
        out.append(box(x + 90 + i * 32, py + 8, 22, 22, 'border:2px solid %s;border-radius:50%%;background:rgba(255,255,255,.7)' % C['lip']))
    out += alone(b)
    out += bubble(b, 'תְּנוּ לָרוֹבּוֹט הוֹרָאוֹת אֶל הַדֶּגֶל.', tail_y=46)
    # the arrow palette under the bubble (as built), the run button in sunset
    for i, d in enumerate(['left', 'up']):
        out += [box(419 + i * 64, 252, 56, 56, 'border-radius:50%%;background:#fff;box-shadow:0 6px 0 %s;display:flex;align-items:center;justify-content:center' % C['lip'], arrow_svg(d, 28))]
    out += [box(419 + 2 * 64, 252, 56, 56, 'border-radius:50%%;background:#fff;box-shadow:0 6px 0 %s' % C['lip'])]
    for i, d in enumerate(['down', 'right']):
        out += [box(419 + i * 64, 318, 56, 56, 'border-radius:50%%;background:#fff;box-shadow:0 6px 0 %s;display:flex;align-items:center;justify-content:center' % C['lip'], arrow_svg(d, 28))]
    out += [box(419 + 2 * 64, 318, 56, 56, 'border-radius:50%%;background:%s;box-shadow:0 6px 0 %s;display:flex;align-items:center;justify-content:center' % (C['sunset'], C['sunsetDeep']),
                '<svg viewBox="0 0 24 24" width="24" height="24"><path d="M8 5 L19 12 L8 19 Z" fill="#2B2350"/></svg>')]
    out += [box(419 + 2 * 64 + 14, 252 + 16, 28, 24, '', '<svg viewBox="0 0 28 24" width="28" height="24"><path d="M9 3 H25 V21 H9 L2 12 Z M13 8 L20 16 M20 8 L13 16" fill="none" stroke="#2B2350" stroke-width="2.4" stroke-linejoin="round" stroke-linecap="round"/></svg>')]
    return out


def board_nine(room):
    b = 'phone'
    out = base(b, room, n=6, done=2)
    out += stage(b, room)
    hb = B[b]
    extra = SAFE if room.get('hostSafe') else ''
    out += duo(b, room, host_extra=extra)
    out += bubble(b, room['he'], right=hb['hostBubbleRight'], tail_y=40, maxw=hb['bubble']['w'] - 12)
    return out


# ---- the page ---------------------------------------------------------------------------------------------------------------
def page(boards, out_png, width_px, scale=1.0, grey=False):
    """boards: list of (parts, w, h, caption)."""
    cells = []
    for parts, w, h, cap in boards:
        cells.append('<div style="display:inline-block;vertical-align:top;margin:10px;width:%dpx">'
                     '<div style="position:relative;width:%dpx;height:%dpx;overflow:hidden"><div style="position:absolute;left:0;top:0;'
                     'width:%dpx;height:%dpx;transform:scale(%g);transform-origin:0 0">%s</div></div>'
                     '<div style="font:600 12px/1.4 sans-serif;color:#B23A3A;margin-top:4px;white-space:pre-wrap">%s</div></div>' % (
                         w * scale, w * scale, h * scale, w, h, scale, ''.join(parts), esc(cap)))
    doc = ('<html><head><meta charset="utf-8"><style>%s body{margin:0;background:#fff;width:%dpx;%s}</style></head><body>%s</body></html>' % (
        FONT_CSS, width_px, 'filter:grayscale(1);' if grey else '', ''.join(cells)))
    tmp = tempfile.mkdtemp(prefix='m11_')
    path = os.path.join(tmp, 'p.html')
    with open(path, 'w', encoding='utf-8') as fh:
        fh.write(doc)
    # height: rows of the inline blocks
    height, row_w, row_h = 0, 0, 0
    for _, w, h, cap in boards:
        bw, bh = w * scale + 20, h * scale + 20 + 18 * (cap.count('\n') + 1) + 6
        if row_w + bw > width_px:
            height += row_h
            row_w, row_h = 0, 0
        row_w += bw
        row_h = max(row_h, bh)
    height += row_h + 10
    subprocess.run([CHROME, '--headless=new', '--disable-gpu', '--hide-scrollbars', '--force-device-scale-factor=1',
                    '--allow-file-access-from-files', '--virtual-time-budget=6000', '--screenshot=' + out_png,
                    '--window-size=%d,%d' % (width_px, int(height)), uri(path)], check=True, capture_output=True)
    print(os.path.basename(out_png))


def nekudi_sheet(out_png):
    parts = []
    names = [('nekudi.svg', 'still (approved)'), ('nekudi-talk.svg', 'talk'), ('nekudi-show.svg', 'show (hand out)'),
             ('nekudi-celebrate.svg', 'celebrate')]
    W = 4 * 300 + 40
    parts.append(box(0, 0, W, 560, 'background:%s' % C['cream']))
    for i, (f, lab) in enumerate(names):
        x = 20 + i * 300
        parts.append(box(x, 10, 280, 280, 'background:#fff;border-radius:16px'))
        parts.append(svg_at(x, 10, 280, 280, '<path d="M0 %g H280" stroke="#B23A3A" stroke-width="1" stroke-dasharray="4 4"/>'
                            '<path d="M140 0 V280" stroke="#B23A3A" stroke-width="1" stroke-dasharray="2 6" opacity=".5"/>' % (472 / 512 * 280)))
        parts.append(img(os.path.join(CAST, f), x, 10, 280, 280))
        parts.append(box(x, 294, 280, 20, 'font:600 14px sans-serif;color:%s;text-align:center' % C['ink'], esc(lab)))
        # at the phone's front size (168) on the room's tint, and as a 48 pt silhouette
        parts.append(box(x + 6, 322, 180, 180, 'background:#FFE3DF;border-radius:12px'))
        parts.append(img(os.path.join(CAST, f), x + 12, 328, 168, 168))
        parts.append(box(x + 200, 380, 60, 60, 'background:#fff;border-radius:8px'))
        parts.append(img(os.path.join(CAST, f), x + 206, 386, 48, 48, 'filter:brightness(0)'))
    parts.append(box(20, 512, W - 40, 40, 'font:600 12px/1.4 sans-serif;color:#B23A3A',
                     esc('Top: 280 px, dashed line = baseline y 472 of 512, dotted = centre x 256. Below: the phone host size (168) on the Counting '
                         'Hills tint, and a 48 pt black silhouette (design-spec 4.9.3). Only the poses are new; the still is the approved art.')))
    page([(parts, W, 560, '')], out_png, W + 20)


def main():
    out = HERE
    hb = B['phone']
    page([(board_counting_show('phone'), 852, 393, 'Counting Hills, phone, SHOW (host beat): Nekudi in front (168, show pose), the companion half a step behind '
                                                   '(96, listen), the bubble\'s tail at Nekudi\'s mouth. Her hand in the stage points at the 8th place; the child '
                                                   'drags the last apple. Unscored: no tiles, no mic.'),
          (board_counting_alone('phone'), 852, 393, 'Counting Hills, phone, ALONE: the companion alone in the corner (176) asks; the host has stepped out. '
                                                    'The staircase stands at the stage\'s end-bottom corner, the trail climbs like it.'),
          (board_counting_alone('phone', reacted=True), 852, 393, 'Counting Hills, phone, the STAGE REACTION\'s end state after a right answer: the top '
                                                                  'step lit and a dot on it (reduce motion shows only this). Not counted, not kept: '
                                                                  'the next item starts plain.'),
          (board_celebration('phone', ROOM['numbers'], os.path.join(CAST, 'nekudi-celebrate.svg'), 'כָּל הַכָּבוֹד! סְפַרְתֶּם הַכֹּל.', STAIR_PIECE),
           852, 393, 'Counting Hills, phone, CELEBRATION: the room\'s window on the card, the staircase gains one step (gold), Nekudi and the companion '
                     'celebrate, the sticker pops in, one way home.')],
         os.path.join(out, 'counting_hills_phone.png'), 1784)
    page([(board_robot_show('phone'), 852, 393, 'Robot Harbour, phone, SHOW (predict, then watch): Tza\'adon (still; his show pose is to be drawn) runs the '
                                                'program, the path lights cell by cell (1, 2, 3); before it, the child tapped where the robot would stop '
                                                '(unscored). Arrows read left to right and never mirror.'),
          (board_robot_alone('phone'), 852, 393, 'Robot Harbour, phone, ALONE: the robot grid in the tall stage, the arrow palette under the bubble '
                                                 '(as built, B-38); the companion asks, the host has stepped out. The dock at the stage corner.'),
          (board_celebration('phone', ROOM['cs'], os.path.join(CAST, 'tzaadon.svg'), 'כָּל הַכָּבוֹד! הָרוֹבּוֹט הִגִּיעַ לַדֶּגֶל.', CRATE_PIECE),
           852, 393, 'Robot Harbour, phone, CELEBRATION: the dock gains a crate lifted on its line; Tza\'adon (still) and the companion; the sticker; '
                     'home.')],
         os.path.join(out, 'robot_harbour_phone.png'), 1784)
    page([(board_counting_show('phone'), 852, 393, 'phone: host (597, 88, 168), companion (697, 158, 96)'),
          (board_counting_show('phoneSE'), 667, 375, 'phone SE: host (478, 74, 144), companion (565, 128, 86)'),
          (board_counting_show('tabletL'), 1180, 820, 'tablet landscape: host (872, 150, 260), companion (1004, 250, 152); the landmark beside the card'),
          (board_counting_show('tabletP'), 820, 1180, 'tablet portrait: host (572, 128, 184), companion (680, 190, 116); bubble right edge 566')],
         os.path.join(out, 'host_beat_boards.png'), 2100, scale=1.0)
    nine = [(board_nine(r), 852, 393, '%s: host %s, trail "%s"' % (r['en'], r['hostName'], r['trail'])) for r in ROOMS]
    page(nine, os.path.join(out, 'nine_rooms.png'), 3 * 403 + 20, scale=0.45)
    page(nine, os.path.join(out, 'nine_rooms_grey.png'), 3 * 403 + 20, scale=0.45, grey=True)
    nekudi_sheet(os.path.join(out, 'nekudi_poses.png'))


if __name__ == '__main__':
    main()
