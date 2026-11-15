"""The host poses of M11 step 1.2 (docs/design/m11-rooms.md section 7): talk, show and celebrate for the eight hosts other than
Nekudi (whose three poses are the approved sample, drawn by hand), and their comparison sheets.

    python docs/design/m11/make_host_poses.py          # writes the 24 SVGs and the sheets
    python docs/design/m11/make_host_poses.py --sheets # only the sheets

Writes design/assets/<host>-talk.svg, -show.svg, -celebrate.svg for goni, kubi, timi, tzaadon, pnina, host-eng, host-heb, host-rus;
docs/design/m11/<host>_poses.png (same layout as nekudi_poses.png) and docs/design/m11/all_host_poses.png.

Every pose is an original drawing in plain SVG shapes, built from its host's approved still (design/assets/<host>.svg,
app/assets/art/languages/host_<c>.svg): the same proportions, palette (tokens color.character.<host>), face style and line weights,
following Nekudi's sample (design/assets/nekudi-*.svg). Nothing was traced; no franchise character is evoked; no text in a picture.

References looked at before drawing (2026-11-14; facts from Wikipedia, photographs from Bing image search, nothing traced):
  Goni      Wikipedia "Chameleon": five toes fused in two opposed bundles (front feet 2 outer + 3 inner), a claw per toe, a
            prehensile tail used as a fifth limb, eyes that turn independently, colour change. Photos: "chameleon reaching front
            foot forward branch" (the front foot reaching up and forward to the next twig, the toes opening like tongs).
  Kubi      Wikipedia "Tortoise", "Testudinidae" (short limbs, a neck that draws straight back into the shell, a scute-plated
            carapace). Photos: "tortoise raising front leg walking side view" (thick scaly forelimb, elbow out, the forefoot lifted
            forward with blunt nails, columnar hind legs that stay planted).
  Timi      Wikipedia "Octopus": eight muscular-hydrostat arms joined at the base by a web, round suckers on the inner (oral) side,
            arms that coil, stretch and reach out to investigate. Photos: "octopus arm reaching out curled tip suckers" (the tip
            tapers and rolls into a spiral, the suckers on the inside of the curl).
  Tza'adon  His own design only (the still): rounded-square body and head, screen face, sprout on the antenna; the gripper is a
            plain two-jaw round clamp, like any toy claw, no robot from a film or show.
  Pnina     Wikipedia "Pelican": long broad wings, a large throat pouch on the lower bill, fully webbed feet. Photos: "pelican
            standing spreading wings" (the wing opens from the shoulder, the long primaries fan apart at the tip like fingers).
            Redrawn 2026-11-15 with her still (QA: "pale, goose-like"): Wikipedia "Great white pelican" (the pelican that
            migrates through Israel: white coverts and black flight feathers, a pink-and-yellow bill with a red tip, a yellow
            pouch, bare pink skin round the eye, a short shaggy crest, short legs, orange webbed feet) and "Pelican" (the
            downcurved hook at the bill's tip, the pouch on the lower bill, short stout legs, big fully webbed feet). Photos (Bing
            image search): "great white pelican standing side view" (the heavy low body, the thick neck held back, the dark
            primaries at the back of the folded wing), "pelican head close up bill pouch hook" (the flat upper bill with a ridge
            and the hooked nail, the pouch hanging deepest under the bill's middle), "dalmatian pelican spreading wings standing"
            (pale inner wing, dark fanned primaries, the curly nape crest, here her grandmother's curls), "pelican webbed feet
            standing close" (three toes joined by a web with a scalloped edge). Her glasses, flower and teal apron with the coin
            pocket stay; her lilac is stronger, the bill, pouch and feet are clear orange and yellow. This script also writes her
            still (design/assets/pnina.svg) and the bundled copies in app/assets/art/hosts/.
  Pip      Wikipedia "Budgerigar": black scalloped bars on the wing coverts, greenish-black flight feathers, a yellow flash across
            the wing that shows only when the wing is spread, throat spots, zygodactyl feet, long tail. Photos: "budgie stretching
            one wing out" (a wing stretched forward and out, the primaries fanned).
  hyrax     Wikipedia "Rock hyrax": squat body, short neck, rounded ears, whiskers, soft padded feet; the male's long "songs".
            Photos: "rock hyrax standing paws front feet" (plump padded front paws, short toes). It already holds its coral pencil.
  giraffe   Wikipedia "Giraffe": front legs longer than hind, the "knee" (carpal) bends when it drinks or kneels, ossicones with
            hair tufts on females and young, the tail with a dark tuft that curls up when it gallops. Photos: "giraffe lifting front
            leg walking side view" (the lifted front leg bends at the knee, the hoof hangs, then swings forward).
"""
import os
import pathlib
import subprocess
import sys
import tempfile
import html as htmlmod
from math import cos, sin, radians

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.normpath(os.path.join(HERE, '..', '..', '..'))
CHROME = r'C:\Program Files\Google\Chrome\Application\chrome.exe'
CAST = os.path.join(ROOT, 'design', 'assets')
LANG = os.path.join(ROOT, 'app', 'assets', 'art', 'languages')

INK = '#2B2350'
LIP = '#F4A7B4'
TONGUE = '#F27D8E'
SPARK = '#FFC83D'
SHADOW = 'rgba(43,35,80,0.14)'
SHADOW_HOP = 'rgba(43,35,80,0.11)'


# ---- small drawing helpers ----------------------------------------------------------------------------------------------
def f(v):
    return ('%.1f' % v).rstrip('0').rstrip('.')


def spark(cx, cy, r, fill=SPARK):
    k = 0.21 * r
    return ('<path d="M{x} {t} Q{a} {b} {r_} {y} Q{a} {c} {x} {bo} Q{d} {c} {l} {y} Q{d} {b} {x} {t} Z" fill="%s"/>' % fill).format(
        x=f(cx), y=f(cy), t=f(cy - r), bo=f(cy + r), r_=f(cx + r), l=f(cx - r), a=f(cx + k), b=f(cy - k), c=f(cy + k), d=f(cx - k))


def open_mouth(cx, top, w, h, lip=LIP, inner=INK, tongue=TONGUE, gid='mouth'):
    """Nekudi's open mouth: a pink lip, the dark interior, a pink tongue (design-spec 4.1)."""
    l, r, b = cx - w / 2, cx + w / 2, top + h
    out = ('<path d="M%s %s Q%s %s %s %s Q%s %s %s %s Q%s %s %s %s Z" fill="%s"/>' % (
        f(l), f(top), f(cx), f(top - 3), f(r), f(top), f(r - 2), f(b - 2), f(cx), f(b), f(l + 2), f(b - 2), f(l), f(top), lip))
    il, ir, it, ib = l + 7, r - 7, top + 6, b - 8
    out += ('<path d="M%s %s Q%s %s %s %s Q%s %s %s %s Q%s %s %s %s Z" fill="%s"/>' % (
        f(il), f(it), f(cx), f(it - 2), f(ir), f(it), f(ir - 3), f(ib - 1), f(cx), f(ib), f(il + 3), f(ib - 1), f(il), f(it), inner))
    if tongue:
        out += '<ellipse cx="%s" cy="%s" rx="%s" ry="%s" fill="%s"/>' % (f(cx), f(ib - 6), f(w * 0.22), f(max(4, h * 0.13)), tongue)
    return '<g id="%s">%s</g>' % (gid, out)


def line(d, color, w, extra=''):
    return '<path d="%s" fill="none" stroke="%s" stroke-width="%s" stroke-linecap="round" stroke-linejoin="round"%s/>' % (
        d, color, f(w), extra)


def polar(x, y, ang, ln):
    a = radians(ang)
    return x + ln * cos(a), y + ln * sin(a)


def grp(gid, body, tr=''):
    return '<g id="%s"%s>%s</g>' % (gid, (' transform="%s"' % tr) if tr else '', body)


# =========================================================================================================================
# GONI, the chameleon (he). Recolourable skin (the owner's decision of 2026-11-15; docs/design/m11-rooms.md section 5.2).
# Every skin part is drawn in one of eight SENTINEL colours, which together are also his resting look ("mint"): skin, shade,
# belly, rim (the outline round his silhouette and every line drawn on his skin) and four stripe colours that differ only in
# their last digit (they look the same; the app colours them one by one for the rainbow ripple). The app swaps them at parse
# time with flutter_svg's ColorMapper (GONI_SKINS is the table). Eyes, mouth, cheek, beret, sparks and shadow keep their own
# colours. Each pose is drawn twice: first the outline pass (every skin shape in the rim colour, widened by GONI_RIM on each
# side, nothing else), then the picture itself, so the outline follows his whole silhouette in any skin, white and black too.
# =========================================================================================================================
GONI_SENTINEL = dict(skin='#7FD3B0', shade='#5DB894', belly='#C9EFDD', rim='#2B7A63',
                     stripe=('#3E9E80', '#3E9E81', '#3E9E82', '#3E9E83'))
G_BERET, G_BERET_RIM, G_RING = '#B0477A', '#7A2C52', '#FFE6A8'
GONI_RIM = 6  # the outline outside the silhouette, artboard units (about 2 px at the phone host's 168)

# The skins (skin, shade, stripe, belly, rim). The lesson colours take the activity pictures' own fill and shade tone
# (tools/make_logic_sprites.py COLOURS, the same as app/lib/play/hints/hint_marks.dart hintColours), so Goni turns exactly the
# colour of the picture the child found. Black has lighter stripes, belly and rim, so his bands, outline and mouth line read.
GONI_SKINS = {
    'mint': ('#7FD3B0', '#5DB894', '#3E9E80', '#C9EFDD', '#2B7A63'),
    'red': ('#E5484D', '#B8323A', '#9A2630', '#F6AEB0', '#7A1C24'),
    'orange': ('#FF9F43', '#D9762A', '#B85E1C', '#FFD6AE', '#8C4512'),
    'yellow': ('#FFD84D', '#E0A21A', '#C98A10', '#FFF1B8', '#8A5E0A'),
    'green': ('#4CAF50', '#2F8A3A', '#23702D', '#AEDDB0', '#1A5422'),
    'blue': ('#2F7FE0', '#1F5DB0', '#184A8E', '#A9CBF5', '#123A70'),
    'purple': ('#9B6BDF', '#7246B8', '#5A3596', '#D6C4F3', '#432672'),
    'pink': ('#F48FB1', '#D9668F', '#C04E78', '#FCD6E3', '#94345A'),
    'brown': ('#8A5A2B', '#66401C', '#4E3014', '#C9A27C', '#3A230E'),
    'black': ('#2B2540', '#171424', '#4C4568', '#3E3858', '#9A93BA'),
    'white': ('#FFFFFF', '#E2DEEC', '#CFC9DF', '#F4F2F8', '#8A82A6'),
    'grey': ('#9AA0B4', '#767C92', '#5F6579', '#CDD0DA', '#474C5E'),
}
# The rainbow ripple: the four stripes take these in turn (app/lib/play/hints/spot_plans.dart rainbowOrder, the pictures' paint).
GONI_RAINBOW = ('#E5484D', '#FF9F43', '#FFD84D', '#4CAF50', '#2F7FE0', '#9B6BDF')

_GONI = {'outline': False}


def goni_map(skin='mint', ripple=None):
    """The colour mapping the app makes: sentinel -> colour. `ripple` = k colours the stripes rainbowOrder[(i + k) % 6]."""
    s, sh, st, be, ri = GONI_SKINS[skin]
    m = {GONI_SENTINEL['skin']: s, GONI_SENTINEL['shade']: sh, GONI_SENTINEL['belly']: be, GONI_SENTINEL['rim']: ri}
    for i, c in enumerate(GONI_SENTINEL['stripe']):
        m[c] = GONI_RAINBOW[(i + ripple) % 6] if ripple is not None else st
    return m


def gline(d, tone, w):
    """A limb or tail stroke in a skin tone; in the outline pass, the same stroke in the rim colour, wider."""
    if _GONI['outline']:
        return line(d, GONI_SENTINEL['rim'], w + 2 * GONI_RIM)
    return line(d, GONI_SENTINEL[tone], w)


def gell(cx, cy, rx, ry, tone):
    if _GONI['outline']:
        return '<ellipse cx="%s" cy="%s" rx="%s" ry="%s" fill="%s" stroke="%s" stroke-width="%d"/>' % (
            f(cx), f(cy), f(rx), f(ry), GONI_SENTINEL['rim'], GONI_SENTINEL['rim'], 2 * GONI_RIM)
    return '<ellipse cx="%s" cy="%s" rx="%s" ry="%s" fill="%s"/>' % (f(cx), f(cy), f(rx), f(ry), GONI_SENTINEL[tone])


def gshape(d, tone):
    if _GONI['outline']:
        return '<path d="%s" fill="%s" stroke="%s" stroke-width="%d" stroke-linejoin="round"/>' % (
            d, GONI_SENTINEL['rim'], GONI_SENTINEL['rim'], 2 * GONI_RIM)
    return '<path d="%s" fill="%s"/>' % (d, GONI_SENTINEL[tone])


def gx(s):
    """Anything that is not his skin's silhouette (stripes, belly, face, beret, sparks, shadow): drawn only in the picture pass."""
    return '' if _GONI['outline'] else s


def goni_pose(fn):
    """Draws a pose twice, the outline pass under the picture; the ground shadow stays under both."""
    _GONI['outline'] = True
    try:
        rim, _ = fn()
    finally:
        _GONI['outline'] = False
    body, anchors = fn()
    cut = body.index('/>') + 2  # every pose starts with its ground shadow
    rim = rim.replace('id="', 'id="outline-')
    return body[:cut] + grp('outline', rim) + body[cut:], anchors


def goni_foot(x, y, ang, tone, toe=17, w=12):
    """A chameleon's front foot: two opposed toe bundles opening like tongs around the direction `ang` (degrees)."""
    a1 = polar(x, y, ang - 30, toe)
    a2 = polar(x, y, ang + 30, toe)
    return gline('M%s %s L%s %s M%s %s L%s %s' % (f(x), f(y), f(a1[0]), f(a1[1]), f(x), f(y), f(a2[0]), f(a2[1])), tone, w)


def goni_trunk(crest_wave=0.0):
    """The body ellipse, his pale belly and the four stripes (in front of the far legs)."""
    out = gell(268, 360, 110, 76, 'shade') + gell(276, 352, 108, 74, 'skin')
    out += gx('<path d="M184 380 Q278 414 376 378 Q370 412 290 424 Q206 424 184 380 Z" fill="%s"/>' % GONI_SENTINEL['belly'])
    # four bands from the shoulder to the hip, all clear of the head (which covers the trunk up to x 240), each starting 14
    # inside the back's edge
    for i, x in enumerate((256, 290, 324, 356)):
        t = 352 - 74 * (1 - ((x - 276) / 108.0) ** 2) ** 0.5 + 14
        q = 10 + crest_wave
        out += gx(line('M%d %s Q%s 344 %d 394' % (x, f(t), f(x + q), x - 2), GONI_SENTINEL['stripe'][i], 17))
    return grp('trunk', out)


def goni_head(eyes='open', look=(0, 0), mouth='closed', far_look=None):
    """The head of the still, centred at (168, 310); `look` shifts both pupils (the gaze)."""
    lx, ly = look
    fx, fy = far_look if far_look else look
    rim = GONI_SENTINEL['rim']
    out = gell(160, 318, 74, 64, 'shade') + gell(168, 310, 72, 62, 'skin')
    out += gshape('M120 268 Q160 214 214 262 Z', 'skin')
    # a pale jaw line, like the light lip scales of a real chameleon
    out += gx(line('M108 344 Q140 362 178 348', GONI_SENTINEL['belly'], 9))
    out += gx('<ellipse cx="166" cy="246" rx="50" ry="18" fill="%s" stroke="%s" stroke-width="4" transform="rotate(-12 166 246)"/>'
              % (G_BERET, G_BERET_RIM))
    out += gx('<circle cx="168" cy="226" r="7" fill="%s" stroke="%s" stroke-width="3"/>' % (G_BERET, G_BERET_RIM))
    ring = '<circle cx="%d" cy="%d" r="%d" fill="%s" stroke="%s" stroke-width="4"/>'
    if eyes == 'open':
        out += gx(ring % (150, 300, 30, G_RING, rim))
        out += gx('<circle cx="%s" cy="%s" r="16" fill="%s"/>' % (f(146 + lx), f(302 + ly), INK))
        out += gx('<circle cx="%s" cy="%s" r="6" fill="#FFFFFF"/>' % (f(140 + lx), f(296 + ly)))
        out += gx(ring % (200, 296, 16, G_RING, rim))
        out += gx('<circle cx="%s" cy="%s" r="8" fill="%s"/>' % (f(198 + fx * 0.5), f(298 + fy * 0.5), INK))
    else:  # happy closed: the turret lids squeezed into smiling arcs
        out += gx(ring % (150, 300, 30, G_RING, rim))
        out += gx(line('M134 304 Q150 286 166 304', INK, 7))
        out += gx(ring % (200, 296, 16, G_RING, rim))
        out += gx(line('M192 299 Q200 290 208 299', INK, 5))
    if mouth == 'closed':
        # the closed mouth is a line on his skin, so it takes the rim tone (it reads on a black or a white Goni too)
        out += gx(line('M104 336 Q140 356 176 340', rim, 5))
        out += gx('<ellipse cx="170" cy="334" rx="11" ry="7" fill="%s" opacity="0.9"/>' % LIP)
    elif mouth == 'talk':
        out += gx('<ellipse cx="176" cy="332" rx="11" ry="7" fill="%s" opacity="0.9"/>' % LIP)
        out += gx(('<g id="mouth"><path d="M102 334 Q140 352 174 338 Q160 374 126 368 Q106 360 102 334 Z" fill="%s" stroke="%s" '
                   'stroke-width="3"/><path d="M112 342 Q140 354 164 344 Q152 366 128 362 Q114 356 112 342 Z" fill="%s"/>'
                   '<ellipse cx="140" cy="358" rx="11" ry="4.5" fill="%s"/></g>') % (LIP, rim, INK, TONGUE))
    elif mouth == 'show':
        out += gx('<ellipse cx="176" cy="332" rx="11" ry="7" fill="%s" opacity="0.9"/>' % LIP)
        out += gx(('<g id="mouth"><path d="M104 336 Q140 352 172 340 Q156 362 130 360 Q110 354 104 336 Z" fill="%s" stroke="%s" '
                   'stroke-width="3"/><path d="M114 342 Q140 352 162 344 Q152 356 132 355 Q118 351 114 342 Z" fill="%s"/></g>')
                  % (LIP, rim, INK))
    elif mouth == 'cheer':
        out += gx('<ellipse cx="178" cy="330" rx="12" ry="8" fill="%s"/>' % LIP)
        out += gx(('<g id="mouth"><path d="M100 330 Q140 350 176 334 Q166 384 128 380 Q104 372 100 330 Z" fill="%s" stroke="%s" '
                   'stroke-width="3"/><path d="M110 339 Q140 352 166 342 Q158 374 130 372 Q112 366 110 339 Z" fill="%s"/>'
                   '<ellipse cx="140" cy="366" rx="13" ry="5" fill="%s"/></g>') % (LIP, rim, INK, TONGUE))
    return out


GONI_TAIL_D = 'M360 380 C430 380 452 440 414 456 C384 468 362 440 380 422 C392 410 410 420 404 432'


def goni_still():
    """The approved still (design/assets/goni.svg), redrawn in the recolourable skin: the same shapes and places."""
    body = gx('<ellipse cx="270" cy="466" rx="140" ry="11" fill="%s"/>' % SHADOW)
    body += grp('tail', gline(GONI_TAIL_D, 'shade', 26))
    far = gline('M330 400 L344 456', 'shade', 22) + gell(348, 460, 18, 9, 'shade')
    far += gline('M196 396 L186 456', 'shade', 22) + gell(180, 460, 18, 9, 'shade')
    body += grp('legs-far', far)
    body += goni_trunk()
    near = gline('M300 404 L300 458', 'skin', 22) + gell(296, 462, 18, 9, 'skin')
    near += gline('M220 404 L226 458', 'skin', 22) + gell(222, 462, 18, 9, 'skin')
    body += grp('legs-near', near)
    body += grp('head', goni_head())
    return body, dict(mouth=(138, 352), feet=(262, 462))


def goni_talk():
    body = gx('<ellipse cx="270" cy="466" rx="140" ry="11" fill="%s"/>' % SHADOW)
    body += grp('tail', gline(GONI_TAIL_D, 'shade', 26))
    far = gline('M330 400 L344 456', 'shade', 22) + gell(348, 460, 18, 9, 'shade')
    far += gline('M196 396 L186 456', 'shade', 22) + gell(180, 460, 18, 9, 'shade')
    body += grp('legs-far', far)
    body += goni_trunk()
    near = gline('M300 404 L300 458', 'skin', 22) + gell(296, 462, 18, 9, 'skin')
    body += grp('leg-hind', near)
    # the explaining hand: the near front foot lifted forward, toes open a little, under his chin
    arm = gline('M222 398 L184 428 L136 404', 'skin', 22) + goni_foot(130, 400, -120, 'skin', toe=17)
    body += grp('arm-end', arm)
    body += grp('head', goni_head(look=(-6, 0), mouth='talk'), 'rotate(-3 236 330)')
    anchors = dict(mouth=(138, 352), feet=(262, 462))
    return body, anchors


def goni_show():
    body = gx('<ellipse cx="262" cy="466" rx="146" ry="11" fill="%s"/>' % SHADOW)
    inner = grp('tail', gline(GONI_TAIL_D, 'shade', 26))
    far = gline('M330 400 L344 456', 'shade', 22) + gell(348, 460, 18, 9, 'shade')
    far += gline('M200 396 L184 456', 'shade', 22) + gell(178, 460, 18, 9, 'shade')
    inner += grp('legs-far', far)
    inner += goni_trunk()
    near = gline('M300 404 L302 458', 'skin', 22) + gell(298, 462, 18, 9, 'skin')
    inner += grp('leg-hind', near)
    inner += grp('head', goni_head(look=(-8, 7), mouth='show'), 'rotate(9 236 330)')
    # the worked-example hand: the near front leg reaching forward and up under his chin, the two toe bundles open like
    # tongs (a chameleon reaching for the next twig); the tip is between the bundles
    hand = gline('M222 398 L170 420 L98 382', 'skin', 22) + goni_foot(94, 378, -152, 'skin', toe=20, w=13)
    hand += gx('<circle cx="100" cy="382" r="5" fill="#FFFFFF" opacity="0.3"/>')
    inner += grp('hand', hand)
    body += grp('body', inner, 'rotate(-2 262 466)')
    anchors = dict(mouth=(140, 324), hand=(70, 362), feet=(256, 462))
    return body, anchors


def goni_celebrate():
    body = gx('<ellipse cx="266" cy="466" rx="118" ry="9" fill="%s"/>' % SHADOW_HOP)
    body += grp('sparks', gx(spark(84, 196, 16) + spark(300, 160, 11)))
    inner = ''
    # the tail curled up high behind him like a flag, four spots along it in his stripe colours (the rainbow ripple runs
    # along them and the stripes together)
    tail = gline('M360 360 C420 330 436 270 400 248 C372 232 350 262 368 280 C380 292 398 282 392 268', 'shade', 26)
    for (x, y), c in zip([(424, 300), (414, 266), (386, 246), (368, 270)], GONI_SENTINEL['stripe']):
        tail += gx('<circle cx="%d" cy="%d" r="7.5" fill="%s"/>' % (x, y, c))
    inner += grp('tail', tail)
    # all four legs spread in the leap: the front feet reach up and forward (hands up), the hind feet kick back
    far = gline('M330 396 L360 430 L388 432', 'shade', 22) + goni_foot(392, 432, 10, 'shade', toe=15)
    far += gline('M204 390 L164 404 L132 372', 'shade', 22) + goni_foot(128, 366, -110, 'shade', toe=15)
    inner += grp('legs-far', far)
    inner += goni_trunk(crest_wave=6)
    near = gline('M300 404 L326 444 L356 452', 'skin', 22) + goni_foot(360, 452, 15, 'skin', toe=15)
    inner += grp('leg-hind', near)
    inner += grp('head', goni_head(eyes='closed', mouth='cheer'), 'rotate(7 236 330)')
    arm = gline('M226 398 L180 424 L120 404', 'skin', 22) + goni_foot(114, 400, -135, 'skin', toe=16)
    inner += grp('arm-end', arm)
    body += grp('body', inner, 'translate(0 -22) rotate(-4 280 380)')
    anchors = dict(feet=(266, 466), burst=(180, 170))
    return body, anchors


# =========================================================================================================================
# KUBI, the tortoise (he). Palette: skin #BFD38A, skinShade #9FB86C, shell #8CC9A0, tiles #A9DCC0 #7FC2BE #F3DDB8, rim #6E9E7E,
# hat #FF9E8A, hatStripe #FFF6E8, pom #FFC83D.
# =========================================================================================================================
K_SKIN, K_SHADE, K_SHELL, K_RIM = '#BFD38A', '#9FB86C', '#8CC9A0', '#6E9E7E'
K_T1, K_T2, K_T3, K_HAT, K_STRIPE, K_POM = '#A9DCC0', '#7FC2BE', '#F3DDB8', '#FF9E8A', '#FFF6E8', '#FFC83D'


def kubi_shell(pop=0):
    """The dome and its tiles; `pop` lifts the tiles a little out of the shell (his 'shell-tile pop')."""
    out = '<path d="M156 404 C156 290 216 248 284 248 C352 248 410 290 410 404 Z" fill="%s"/>' % K_RIM
    out += '<path d="M168 400 C168 298 222 262 284 262 C346 262 398 298 398 400 Z" fill="%s"/>' % K_SHELL
    p = pop
    tiles = ''
    if p:
        # the sockets the tiles lift out of
        tiles += '<path d="M216 380 L248 320 L280 380 Z" fill="%s" opacity="0.55"/>' % K_RIM
        tiles += '<rect x="292" y="330" width="48" height="48" rx="8" fill="%s" opacity="0.55"/>' % K_RIM
        tiles += '<circle cx="262" cy="296" r="20" fill="%s" opacity="0.55"/>' % K_RIM
        tiles += '<polygon points="372,300 362,317.3 342,317.3 332,300 342,282.7 362,282.7" fill="%s" opacity="0.55"/>' % K_RIM
    tiles += '<g transform="translate(-%s -%s) rotate(-8 248 360)">' % (f(p * 0.4), f(p * 1.1)) if p else '<g>'
    tiles += '<path d="M216 380 L248 320 L280 380 Z" fill="%s"/></g>' % K_T1
    tiles += ('<g transform="translate(%s -%s) rotate(7 316 354)">' % (f(p * 0.5), f(p * 1.0))) if p else '<g>'
    tiles += '<rect x="292" y="330" width="48" height="48" rx="8" fill="%s"/></g>' % K_T3
    tiles += ('<g transform="translate(-%s -%s)">' % (f(p * 0.2), f(p * 1.4))) if p else '<g>'
    tiles += '<circle cx="262" cy="296" r="20" fill="%s"/></g>' % K_T2
    tiles += ('<g transform="translate(%s -%s) rotate(10 352 300)">' % (f(p * 0.6), f(p * 1.2))) if p else '<g>'
    tiles += '<polygon points="372,300 362,317.3 342,317.3 332,300 342,282.7 362,282.7" fill="%s"/></g>' % K_T1
    tiles += '<circle cx="196" cy="340" r="13" fill="%s"/>' % K_T3
    out += tiles
    out += '<rect x="150" y="392" width="266" height="22" rx="11" fill="%s"/>' % K_RIM
    return grp('shell', out)


def kubi_head(look=(0, 0), mouth='closed', eyes='open', hat_tilt=0):
    lx, ly = look
    out = '<ellipse cx="122" cy="314" rx="58" ry="50" fill="%s"/><ellipse cx="128" cy="308" rx="56" ry="48" fill="%s"/>' % (
        K_SHADE, K_SKIN)
    if eyes == 'open':
        out += '<ellipse cx="%s" cy="%s" rx="11" ry="14" fill="%s"/>' % (f(108 + lx), f(300 + ly), INK)
        out += '<circle cx="%s" cy="%s" r="4.5" fill="#FFFFFF"/>' % (f(104 + lx), f(294 + ly))
    else:
        out += line('M96 302 Q108 288 120 302', INK, 6)
    if mouth == 'closed':
        out += line('M78 328 Q100 344 124 330', INK, 5)
        out += '<ellipse cx="132" cy="326" rx="12" ry="7" fill="%s" opacity="0.85"/>' % LIP
    elif mouth == 'talk':
        out += '<ellipse cx="136" cy="324" rx="12" ry="7" fill="%s" opacity="0.85"/>' % LIP
        out += ('<g id="mouth"><path d="M76 326 Q100 342 126 328 Q118 360 98 360 Q80 354 76 326 Z" fill="%s"/>'
                '<path d="M85 333 Q100 342 117 335 Q111 353 98 353 Q87 349 85 333 Z" fill="%s"/>'
                '<ellipse cx="100" cy="349" rx="9" ry="4" fill="%s"/></g>') % (LIP, INK, TONGUE)
    elif mouth == 'show':
        out += '<ellipse cx="134" cy="326" rx="12" ry="7" fill="%s" opacity="0.85"/>' % LIP
        out += ('<g id="mouth"><path d="M78 328 Q100 342 124 330 Q114 350 98 350 Q82 346 78 328 Z" fill="%s"/>'
                '<path d="M86 334 Q100 342 116 336 Q110 345 98 345 Q89 343 86 334 Z" fill="%s"/></g>') % (LIP, INK)
    elif mouth == 'cheer':
        out += '<ellipse cx="138" cy="322" rx="13" ry="8" fill="%s"/>' % LIP
        out += ('<g id="mouth"><path d="M72 320 Q100 340 130 324 Q124 366 100 366 Q76 360 72 320 Z" fill="%s"/>'
                '<path d="M81 329 Q100 341 121 332 Q116 358 100 358 Q84 354 81 329 Z" fill="%s"/>'
                '<ellipse cx="101" cy="353" rx="10" ry="4.5" fill="%s"/></g>') % (LIP, INK, TONGUE)
    hat = ('<path d="M96 270 L150 262 L116 172 Z" fill="%s"/><path d="M108 238 L134 234 L128 218 L112 222 Z" fill="%s"/>'
           '<path d="M114 206 L124 204 L120 194 Z" fill="%s"/><circle cx="116" cy="170" r="13" fill="%s"/>') % (
        K_HAT, K_STRIPE, K_STRIPE, K_POM)
    out += grp('hat', hat, 'rotate(%s 124 266)' % f(hat_tilt) if hat_tilt else '')
    return out


def kubi_forefoot(x, y, ang, color=K_SKIN, nail=K_T3, w=36):
    """A tortoise forefoot: the thick rounded end of the limb and three blunt nails along the direction `ang`."""
    out = '<circle cx="%s" cy="%s" r="%s" fill="%s"/>' % (f(x), f(y), f(w / 2), color)
    for da in (-34, 0, 34):
        nx, ny = polar(x, y, ang + da, w / 2 + 1)
        out += '<ellipse cx="%s" cy="%s" rx="6.5" ry="5" fill="%s" transform="rotate(%s %s %s)"/>' % (
            f(nx), f(ny), nail, f(ang + da), f(nx), f(ny))
    return out


def scales(pts, color=K_SHADE):
    return ''.join('<circle cx="%s" cy="%s" r="%s" fill="%s"/>' % (f(x), f(y), f(r), color) for x, y, r in pts)


def kubi_talk():
    body = '<ellipse cx="270" cy="466" rx="150" ry="11" fill="%s"/>' % SHADOW
    far = '<rect x="330" y="400" width="40" height="64" rx="18" fill="%s"/>' % K_SHADE
    far += '<rect x="186" y="400" width="40" height="64" rx="18" fill="%s"/>' % K_SHADE
    far += '<path d="M398 392 L436 402 L400 412 Z" fill="%s"/>' % K_SHADE
    body += grp('legs-far', far)
    body += kubi_shell()
    body += grp('leg-hind', '<rect x="300" y="404" width="44" height="62" rx="20" fill="%s"/>' % K_SKIN)
    # the explaining hand: the near forefoot lifted, elbow out, nails forward and up
    arm = line('M228 412 L196 444', K_SKIN, 42) + line('M196 444 L146 418', K_SKIN, 36) + kubi_forefoot(138, 412, -150, w=36)
    arm += scales([(204, 436, 4), (184, 436, 3.5), (166, 428, 3.5)])
    body += grp('arm-end', arm)
    neck = line('M188 380 Q150 380 136 330', K_SKIN, 46)
    body += grp('neck', neck)
    body += grp('head', kubi_head(look=(-3, 0), mouth='talk'), 'rotate(-5 160 340)')
    anchors = dict(mouth=(101, 344), feet=(270, 464))
    return body, anchors


def kubi_show():
    body = '<ellipse cx="262" cy="466" rx="154" ry="11" fill="%s"/>' % SHADOW
    inner = ''
    far = '<rect x="330" y="400" width="40" height="64" rx="18" fill="%s"/>' % K_SHADE
    far += '<rect x="190" y="400" width="40" height="64" rx="18" fill="%s"/>' % K_SHADE
    far += '<path d="M398 392 L436 402 L400 412 Z" fill="%s"/>' % K_SHADE
    inner += grp('legs-far', far)
    inner += kubi_shell()
    inner += grp('leg-hind', '<rect x="300" y="404" width="44" height="62" rx="20" fill="%s"/>' % K_SKIN)
    # the neck stretched up and forward out of the shell, so the head looks down along the reaching leg
    inner += grp('neck', line('M190 384 Q146 372 130 296', K_SKIN, 46))
    inner += grp('head', kubi_head(look=(-4, 6), mouth='show'), 'translate(4 -46) rotate(6 128 308)')
    # the worked-example hand: the near forefoot held out level toward the task, three blunt nails at the tip
    hand = line('M228 408 L168 380 L92 356', K_SKIN, 38) + kubi_forefoot(80, 352, -170, w=36)
    hand += scales([(196, 392, 4), (176, 384, 3.5), (150, 372, 4), (128, 366, 3.5), (108, 360, 3)])
    inner += grp('hand', hand)
    body += grp('body', inner, 'rotate(-2 262 466)')
    anchors = dict(mouth=(104, 296), hand=(58, 348), feet=(262, 464))
    return body, anchors


def kubi_celebrate():
    body = '<ellipse cx="270" cy="466" rx="124" ry="9" fill="%s"/>' % SHADOW_HOP
    body += grp('sparks', spark(56, 178, 16) + spark(420, 214, 11))
    inner = ''
    far = '<rect x="336" y="400" width="40" height="56" rx="18" fill="%s" transform="rotate(14 356 404)"/>' % K_SHADE
    far += '<path d="M398 392 L440 392 L404 410 Z" fill="%s"/>' % K_SHADE
    far += line('M200 392 L150 392', K_SHADE, 36) + line('M150 392 L100 362', K_SHADE, 32) + kubi_forefoot(92, 356, -140, color=K_SHADE, w=32)
    inner += grp('legs-far', far)
    inner += kubi_shell(pop=12)
    inner += grp('leg-hind', '<rect x="300" y="404" width="44" height="56" rx="20" fill="%s" transform="rotate(12 322 408)"/>' % K_SKIN)
    inner += grp('neck', line('M190 384 Q140 360 126 262', K_SKIN, 46))
    inner += grp('head', kubi_head(eyes='closed', mouth='cheer', hat_tilt=14), 'translate(0 -66) rotate(10 128 308)')
    arm = line('M228 408 L168 420', K_SKIN, 40) + line('M168 420 L112 398', K_SKIN, 36) + kubi_forefoot(102, 392, -150, w=36)
    arm += scales([(206, 414, 4), (182, 418, 3.5), (150, 412, 3.5), (130, 404, 3)])
    inner += grp('arm-end', arm)
    body += grp('body', inner, 'translate(0 -22) rotate(6 340 460)')
    anchors = dict(feet=(270, 466), burst=(130, 90))
    return body, anchors


# =========================================================================================================================
# TIMI, the octopus (she). Palette: body #B79CF5, bodyShade #9C80E6, sucker #E9DEFF, glassRim #FFC83D, lens #DFF4FF,
# puzzle #FF9E8A.
# =========================================================================================================================
T_BODY, T_SHADE, T_SUCK, T_RIM, T_LENS, T_PUZ = '#B79CF5', '#9C80E6', '#E9DEFF', '#FFC83D', '#DFF4FF', '#FF9E8A'
PUZZLE = 'M378 214 L398 214 Q398 202 408 202 Q418 202 418 214 L438 214 L438 234 Q450 234 450 244 Q450 254 438 254 L438 274 L378 274 Z'


def timi_puzzle(tx, ty, rot, sc):
    """The puzzle piece of the still (centred at 414, 238), moved, turned and scaled about its centre."""
    return '<g transform="translate(%s %s) rotate(%s 414 238) translate(414 238) scale(%s) translate(-414 -238)"><path d="%s" fill="%s"/></g>' % (
        f(tx), f(ty), f(rot), f(sc), PUZZLE, T_PUZ)


def timi_glass(cx, cy, ang):
    """The magnifying glass: its handle runs from the lens toward `ang` (degrees, the hand side)."""
    hx, hy = polar(cx, cy, ang, 30)
    ex, ey = polar(cx, cy, ang, 60)
    return (line('M%s %s L%s %s' % (f(hx), f(hy), f(ex), f(ey)), T_RIM, 9) +
            '<circle cx="%s" cy="%s" r="30" fill="%s"/><circle cx="%s" cy="%s" r="22" fill="%s"/>'
            '<ellipse cx="%s" cy="%s" rx="7" ry="5" fill="#FFFFFF" opacity="0.9"/>') % (
        f(cx), f(cy), T_RIM, f(cx), f(cy), T_LENS, f(cx - 8), f(cy - 8))


def timi_mantle(look=(0, 0), eyes='open', mouth='closed'):
    lx, ly = look
    out = '<ellipse cx="248" cy="290" rx="112" ry="124" fill="%s"/><ellipse cx="258" cy="282" rx="110" ry="122" fill="%s"/>' % (
        T_SHADE, T_BODY)
    out += '<ellipse cx="300" cy="206" rx="26" ry="14" fill="#FFFFFF" opacity="0.35" transform="rotate(-30 300 206)"/>'
    out += line('M250 160 Q244 136 262 130 Q276 128 272 142', T_BODY, 12)
    if eyes == 'open':
        for ex in (218, 294):
            out += '<ellipse cx="%s" cy="%s" rx="18" ry="24" fill="%s"/>' % (f(ex + lx), f(286 + ly), INK)
            out += '<circle cx="%s" cy="%s" r="6.8" fill="#FFFFFF"/><circle cx="%s" cy="%s" r="3.2" fill="#FFFFFF"/>' % (
                f(ex - 7.2 + lx), f(278 + ly), f(ex + 5.1 + lx), f(294 + ly))
    else:
        out += line('M202 290 Q218 270 234 290', INK, 8) + line('M278 290 Q294 270 310 290', INK, 8)
    out += '<ellipse cx="188" cy="330" rx="14" ry="8" fill="%s"/><ellipse cx="324" cy="330" rx="14" ry="8" fill="%s"/>' % (LIP, LIP)
    if mouth == 'closed':
        out += line('M234 330 Q256 350 278 330', INK, 6)
    elif mouth == 'talk':
        out += open_mouth(254, 324, 40, 34)
    elif mouth == 'show':
        out += open_mouth(252, 326, 34, 24, tongue=None)
    elif mouth == 'cheer':
        out += open_mouth(256, 318, 52, 44)
    return grp('head', out)


def timi_bottom(skip_left_outer=False, spread=0):
    out = ''
    if not skip_left_outer:
        out += line('M200 390 C170 440 140 452 120 436 C108 426 116 412 128 418', T_SHADE, 28)
    out += line('M312 390 C342 440 372 452 392 436 C404 426 396 412 384 418', T_SHADE, 28)
    out += line('M236 400 C232 446 212 462 196 456 C186 450 190 438 200 440', T_BODY, 30)
    out += line('M276 400 C280 446 300 462 316 456 C326 450 322 438 312 440', T_BODY, 30)
    out += ''.join('<circle cx="%d" cy="%d" r="4" fill="%s"/>' % (x, y, T_SUCK) for x, y in ((200, 452), (212, 446), (312, 452), (300, 446)))
    return grp('arms-ground', out)


def timi_talk():
    body = '<ellipse cx="256" cy="466" rx="140" ry="11" fill="%s"/>' % SHADOW
    body += timi_bottom()
    # the explaining arm (end side): the glass held out at shoulder height, the arm's tip lifted like a raised finger
    arm = line('M176 352 C132 350 104 320 98 282', T_BODY, 28) + timi_glass(84, 226, 75)
    body += grp('arm-end', arm)
    # the puzzle arm stays up as in the still
    body += grp('arm-start', line('M336 352 C384 344 404 304 396 262', T_BODY, 28) + timi_puzzle(0, 0, 0, 1))
    body += timi_mantle(look=(-6, 0), mouth='talk')
    anchors = dict(mouth=(254, 340), feet=(256, 460))
    return body, anchors


def timi_show():
    body = '<ellipse cx="250" cy="466" rx="146" ry="11" fill="%s"/>' % SHADOW
    inner = timi_bottom(skip_left_outer=True)
    # the glass waits, held up close to her head
    inner += grp('arm-glass', line('M180 330 C150 300 142 262 150 222', T_BODY, 28) + timi_glass(150, 170, 92))
    # the puzzle arm rests low at her side, inside her outline
    rest = line('M336 352 C366 360 374 376 368 392', T_BODY, 28)
    rest += timi_puzzle(-58, 140, 8, 0.8)
    inner += grp('arm-start', rest)
    inner += timi_mantle(look=(-8, 7), mouth='show')
    # the worked-example hand: a free arm reaching out level toward the task, its tip rolled up into a small curl,
    # the suckers on its underside
    hand = line('M196 372 C156 386 112 360 84 336', T_SHADE, 26)
    hand += line('M84 336 C62 318 44 298 56 282 C68 268 90 276 86 292 C84 302 72 303 70 294', T_SHADE, 18)
    hand += ''.join('<circle cx="%s" cy="%s" r="4.5" fill="%s"/>' % (f(x), f(y), T_SUCK) for x, y in (
        (170, 392), (144, 388), (120, 376), (98, 360), (80, 344)))
    inner += grp('hand', hand)
    body += grp('body', inner, 'rotate(-3 256 466)')
    anchors = dict(mouth=(252, 338), hand=(46, 292), feet=(250, 462))
    return body, anchors


def timi_celebrate():
    body = '<ellipse cx="256" cy="466" rx="112" ry="9" fill="%s"/>' % SHADOW_HOP
    bubbles = ''.join('<circle cx="%d" cy="%d" r="%d" fill="%s" stroke="%s" stroke-width="4"/>' % (x, y, r, T_LENS, T_SUCK)
                      for x, y, r in ((60, 300, 10), (78, 258, 7), (446, 318, 10), (428, 276, 7), (454, 240, 5)))
    body += grp('bubbles', bubbles)
    body += grp('sparks', spark(186, 112, 15) + spark(338, 98, 11))
    inner = ''
    # "aha!": every arm up and curling (design-spec 4.5); the ground arms flick out into curls
    ground = line('M200 392 C160 420 126 410 112 384 C102 366 116 352 130 360', T_SHADE, 28)
    ground += line('M312 392 C352 420 386 410 400 384 C410 366 396 352 382 360', T_SHADE, 28)
    ground += line('M236 402 C230 444 210 452 196 444 C186 438 190 426 200 428', T_BODY, 30)
    ground += line('M276 402 C282 444 302 452 316 444 C326 438 322 426 312 428', T_BODY, 30)
    ground += ''.join('<circle cx="%d" cy="%d" r="4" fill="%s"/>' % (x, y, T_SUCK) for x, y in ((200, 440), (212, 436), (312, 440), (300, 436)))
    inner += grp('arms-ground', ground)
    up = line('M170 330 C120 310 96 250 108 190', T_BODY, 28) + timi_glass(112, 132, 85)
    up += line('M342 330 C392 310 416 250 404 196', T_BODY, 28)
    up += timi_puzzle(-14, -86, -10, 1)
    inner += grp('arms-up', up)
    inner += timi_mantle(eyes='closed', mouth='cheer')
    body += grp('body', inner, 'translate(0 -22)')
    anchors = dict(feet=(256, 466), burst=(256, 92))
    return body, anchors


# =========================================================================================================================
# TZA'ADON, the robot (he). Palette: body #6E9BEA, bodyShade #4F7ED6, screen #2B2350, eyes #7FF0FF, panel #CFD5EE,
# sprout #A5D96E, buttons #F46A5E #FFC83D #1A9E9A.
# =========================================================================================================================
Z_BODY, Z_SHADE, Z_EYE, Z_PANEL, Z_SPROUT = '#6E9BEA', '#4F7ED6', '#7FF0FF', '#CFD5EE', '#A5D96E'


def tz_gripper(x, y, ang, open_=34):
    """His round two-jaw gripper: a wrist disc and two curved jaws that open around the direction `ang`."""
    out = '<circle cx="%s" cy="%s" r="15" fill="%s"/>' % (f(x), f(y), Z_PANEL)
    cx, cy = polar(x, y, ang, 17)
    for s in (-1, 1):
        a0 = ang + s * (open_ + 120)
        a1 = ang + s * open_
        p0, p1 = polar(cx, cy, a0, 15), polar(cx, cy, a1, 15)
        sweep = 1 if s < 0 else 0
        out += '<path d="M%s %s A15 15 0 0 %d %s %s" fill="none" stroke="%s" stroke-width="10" stroke-linecap="round"/>' % (
            f(p0[0]), f(p0[1]), sweep, f(p1[0]), f(p1[1]), Z_PANEL)
    return out


def tz_head(eyes='happy', look=(0, 0), mouth='smile', leaves='still'):
    lx, ly = look
    out = '<circle cx="166" cy="214" r="16" fill="%s"/><circle cx="346" cy="214" r="16" fill="%s"/>' % (Z_SHADE, Z_SHADE)
    out += '<rect x="166" y="146" width="180" height="136" rx="44" fill="%s"/>' % Z_SHADE
    out += '<rect x="172" y="140" width="178" height="134" rx="44" fill="%s"/>' % Z_BODY
    out += '<rect x="192" y="162" width="138" height="92" rx="30" fill="%s"/>' % INK
    if eyes == 'happy':
        out += line('M222 210 Q236 190 250 210', Z_EYE, 9) + line('M274 210 Q288 190 302 210', Z_EYE, 9)
    elif eyes == 'big':
        out += line('M218 212 Q236 186 254 212', Z_EYE, 10) + line('M270 212 Q288 186 306 212', Z_EYE, 10)
    else:  # open: two rounded screen eyes, the shine shows the gaze
        for ex in (236, 288):
            out += '<rect x="%s" y="%s" width="22" height="30" rx="11" fill="%s"/>' % (f(ex - 11 + lx), f(186 + ly), Z_EYE)
            out += '<circle cx="%s" cy="%s" r="4" fill="#FFFFFF"/>' % (f(ex - 4 + lx * 1.4), f(194 + ly))
    if mouth == 'smile':
        out += line('M246 230 Q262 242 278 230', Z_EYE, 6)
    elif mouth in ('talk', 'cheer', 'show'):
        w, h, top = dict(talk=(30, 20, 226), cheer=(38, 24, 224), show=(26, 13, 230))[mouth]
        l, r, b = 262 - w / 2, 262 + w / 2, top + h
        d = 'M%s %s Q262 %s %s %s Q%s %s 262 %s Q%s %s %s %s Z' % (f(l), top, top - 2, f(r), top, f(r - 2), b - 2, b, f(l + 2), b - 2, f(l), top)
        tongue = '' if mouth == 'show' else '<ellipse cx="262" cy="%s" rx="7" ry="4" fill="%s"/>' % (f(b - 5), TONGUE)
        out += '<g id="mouth"><path d="%s" fill="%s"/>%s<path d="%s" fill="none" stroke="%s" stroke-width="5" stroke-linejoin="round"/></g>' % (
            d, INK, tongue, d, Z_EYE)
    out += '<ellipse cx="206" cy="234" rx="9" ry="6" fill="%s" opacity="0.8"/><ellipse cx="318" cy="234" rx="9" ry="6" fill="%s" opacity="0.8"/>' % (LIP, LIP)
    if leaves == 'still':
        out += line('M262 140 L262 108', Z_SHADE, 7)
        out += '<path d="M262 108 C240 106 228 92 230 80 C246 80 260 90 262 108 Z" fill="%s"/>' % Z_SPROUT
        out += '<path d="M262 108 C282 100 292 84 288 74 C272 76 262 90 262 108 Z" fill="%s"/>' % Z_SPROUT
    else:  # celebrate: the antenna springs and the sprout opens a third leaf and a small bud
        out += line('M262 140 L252 132 L272 124 L252 116 L272 108 L262 100', Z_SHADE, 6)
        out += '<path d="M262 100 C236 100 220 84 222 70 C242 70 258 82 262 100 Z" fill="%s"/>' % Z_SPROUT
        out += '<path d="M262 100 C288 94 302 76 298 62 C278 64 264 80 262 100 Z" fill="%s"/>' % Z_SPROUT
        out += '<path d="M262 100 C254 82 256 64 266 52 C276 66 272 84 262 100 Z" fill="%s"/>' % Z_SPROUT
        out += '<circle cx="266" cy="48" r="9" fill="#FFC83D"/><circle cx="266" cy="48" r="4" fill="#F46A5E"/>'
    return grp('head', out)


def tz_torso(glow=False):
    out = '<rect x="178" y="300" width="160" height="124" rx="34" fill="%s"/>' % Z_SHADE
    out += '<rect x="184" y="294" width="156" height="122" rx="34" fill="%s"/>' % Z_BODY
    out += '<rect x="214" y="320" width="96" height="70" rx="16" fill="%s"/>' % Z_PANEL
    out += '<circle cx="238" cy="355" r="12" fill="#F46A5E"/><path d="M262 366 L274 343 L286 366 Z" fill="#FFC83D"/>'
    out += '<rect x="292" y="343" width="22" height="22" rx="4" fill="#1A9E9A"/>'
    if glow:
        out += ''.join('<circle cx="%d" cy="%d" r="3" fill="#FFFFFF" opacity="0.8"/>' % (x, y) for x, y in ((234, 351), (272, 354), (299, 350)))
    out += '<rect x="236" y="276" width="40" height="26" rx="8" fill="%s"/>' % Z_SHADE
    return grp('torso', out)


def tz_legs(hop=False):
    if not hop:
        out = ('<rect x="206" y="408" width="34" height="50" rx="12" fill="%s"/><rect x="272" y="408" width="34" height="50" rx="12" fill="%s"/>'
               '<rect x="192" y="446" width="58" height="22" rx="11" fill="%s"/><rect x="262" y="446" width="58" height="22" rx="11" fill="%s"/>') % (
            Z_SHADE, Z_SHADE, Z_PANEL, Z_PANEL)
    else:
        out = ('<rect x="204" y="408" width="34" height="46" rx="12" fill="%s" transform="rotate(10 221 410)"/>'
               '<rect x="274" y="408" width="34" height="46" rx="12" fill="%s" transform="rotate(-10 291 410)"/>'
               '<rect x="186" y="442" width="58" height="22" rx="11" fill="%s" transform="rotate(10 215 453)"/>'
               '<rect x="268" y="442" width="58" height="22" rx="11" fill="%s" transform="rotate(-10 297 453)"/>') % (
            Z_SHADE, Z_SHADE, Z_PANEL, Z_PANEL)
    return grp('legs', out)


def tz_talk():
    body = '<ellipse cx="256" cy="466" rx="110" ry="11" fill="%s"/>' % SHADOW
    body += tz_legs()
    # the explaining hand: elbow bent, the gripper up and a little open
    body += grp('arm-end', line('M184 330 L136 330 L120 282', Z_BODY, 24) + tz_gripper(118, 274, -100, open_=26))
    body += grp('arm-start', line('M328 330 L350 390', Z_BODY, 24) + '<circle cx="352" cy="396" r="18" fill="%s"/>' % Z_PANEL)
    body += tz_torso()
    body += tz_head(eyes='open', look=(-6, 0), mouth='talk', leaves='still')
    anchors = dict(mouth=(262, 236), feet=(256, 466))
    return body, anchors


def tz_show():
    body = '<ellipse cx="250" cy="466" rx="116" ry="11" fill="%s"/>' % SHADOW
    inner = tz_legs()
    inner += grp('arm-start', line('M326 334 L334 380', Z_BODY, 24) + '<circle cx="334" cy="388" r="18" fill="%s"/>' % Z_PANEL)
    inner += tz_torso()
    inner += grp('head-turn', tz_head(eyes='open', look=(-9, 6), mouth='show'), 'rotate(-6 256 282)')
    # the worked-example hand: the arm held out level toward the task; the tip is between the two open jaws
    inner += grp('hand', line('M184 330 L132 318 L86 314', Z_BODY, 24) + tz_gripper(74, 313, 180, open_=30))
    body += grp('body', inner, 'rotate(-3 256 466)')
    anchors = dict(mouth=(254, 240), hand=(44, 316), feet=(250, 466))
    return body, anchors


def tz_celebrate():
    body = '<ellipse cx="256" cy="466" rx="88" ry="9" fill="%s"/>' % SHADOW_HOP
    body += grp('sparks', spark(130, 100, 15) + spark(394, 90, 11))
    inner = tz_legs(hop=True)
    inner += grp('arms', line('M186 326 L146 280 L130 220', Z_BODY, 24) + tz_gripper(128, 210, -95, open_=40) +
                 line('M326 326 L366 280 L382 220', Z_BODY, 24) + tz_gripper(384, 210, -85, open_=40))
    inner += tz_torso(glow=True)
    inner += tz_head(eyes='big', mouth='cheer', leaves='bloom')
    body += grp('body', inner, 'translate(0 -22)')
    anchors = dict(feet=(256, 466), burst=(262, 26))
    return body, anchors


# =========================================================================================================================
# GRANDMA PNINA, the pelican (she). Palette: body #CFD5EE, bodyShade #AEB7DC, beak #F7C98B, beakShade #E6AE6A, apron #1A9E9A,
# apronShade #0F6E6A, flower #FF8C7A, glasses #2B2350, coin #FFC83D (and the still's oranges #FFA46B #FFB27E, leaf #86C474).
# =========================================================================================================================
P_BODY, P_SHADE, P_COVERT = '#C3C6F0', '#9C9FDC', '#D9DBF7'
P_PRIM, P_PRIM_LIT = '#3F3D7A', '#5C5A9E'
P_BEAK, P_BEAKS, P_NAIL = '#FFA27A', '#EE7F58', '#DE4A3C'
P_POUCH, P_POUCHS = '#FFC23D', '#F39A1E'
P_FACE, P_FEET, P_FEETS = '#FFB7AE', '#FF9446', '#DD6E24'
P_APRON, P_APRONS, P_FLOWER = '#1A9E9A', '#0F6E6A', '#FF6F61'


def pn_feet(hop=False):
    """Short thick legs and big webbed feet: three toes joined by a web with a scalloped front edge (photos of pelican feet)."""
    dy = -6 if hop else 0
    out = ''
    for x in (262, 322):
        out += '<rect x="%s" y="%s" width="18" height="%s" rx="8" fill="%s"/>' % (f(x - 9), f(444 + dy), f(22), P_FEETS)
        # the foot: a broad fan of webbing, toes as ridges, scalloped front edge (it points toward the end side, left)
        fx, fy = x - 6, 470 + dy
        out += ('<path d="M%s %s Q%s %s %s %s Q%s %s %s %s Q%s %s %s %s Q%s %s %s %s Q%s %s %s %s Z" fill="%s"/>' % (
            f(fx + 22), f(fy), f(fx + 18), f(fy - 18), f(fx + 4), f(fy - 20), f(fx - 14), f(fy - 14), f(fx - 30), f(fy - 2),
            f(fx - 20), f(fy - 4), f(fx - 14), f(fy + 1), f(fx - 6), f(fy - 3), f(fx + 2), f(fy + 1), f(fx + 12), f(fy - 2), f(fx + 22), f(fy),
            P_FEET))
        out += line('M%s %s L%s %s M%s %s L%s %s' % (f(fx + 6), f(fy - 16), f(fx - 22), f(fy - 4), f(fx + 6), f(fy - 16), f(fx - 4),
                                                     f(fy - 2)), P_FEETS, 2.6)
    return grp('feet', out)


def pn_trunk():
    """The heavy, egg-shaped body sitting low on the short legs, and the short square tail."""
    out = '<path d="M388 392 L432 398 Q438 410 426 418 L382 420 Z" fill="%s"/>' % P_SHADE
    out += '<ellipse cx="286" cy="362" rx="112" ry="94" fill="%s"/><ellipse cx="296" cy="354" rx="108" ry="90" fill="%s"/>' % (
        P_SHADE, P_BODY)
    return grp('trunk', out)


def pn_apron():
    out = '<path d="M206 326 Q262 314 316 330 L312 438 Q262 452 214 440 Z" fill="%s"/>' % P_APRON
    out += '<path d="M206 326 Q262 314 316 330 L316 340 Q262 326 206 338 Z" fill="%s"/>' % P_APRONS
    out += '<rect x="234" y="378" width="56" height="38" rx="10" fill="%s"/>' % P_APRONS
    out += '<circle cx="262" cy="382" r="13" fill="#FFC83D"/><circle cx="262" cy="382" r="7" fill="#E0A21A"/>'
    return grp('apron', out)


def pn_folded_wing():
    """The folded wing on her side: pale coverts over the shoulder, a scalloped row of dark secondaries under them, and the long
    dark primaries crossing back over the tail (as on a standing white pelican, whose black flight feathers show at the back)."""
    out = '<path d="M334 404 Q392 404 448 384 Q454 392 446 398 Q404 430 340 434 Z" fill="%s"/>' % P_PRIM
    out += '<path d="M330 396 Q392 392 440 368 Q446 376 438 384 Q398 414 336 420 Z" fill="%s"/>' % P_PRIM_LIT
    out += ('<path d="M300 318 Q372 300 404 346 Q420 378 398 404 Q386 414 372 406 Q360 418 344 410 Q330 420 316 408 '
            'Q296 380 300 318 Z" fill="%s"/>' % P_PRIM)
    out += '<path d="M302 316 Q370 300 400 344 Q414 372 396 392 Q350 402 318 388 Q298 362 302 316 Z" fill="%s"/>' % P_COVERT
    out += line('M322 336 Q356 330 386 352', P_SHADE, 4, ' opacity="0.6"')
    out += line('M322 362 Q356 360 390 374', P_SHADE, 4, ' opacity="0.45"')
    return grp('wing', out)


def pn_head(eyes='closed', look=(0, 0), beak='closed'):
    """Head, curly crest and flower, glasses over the bare pink skin round the eye, and the pelican's bill: a long flat upper bill
    with a ridge and a red hooked nail at its tip, the big yellow throat pouch hanging under it. `beak`: closed, talk (the upper
    bill lifts), show (a little), cheer (wide)."""
    lx, ly = look
    out = '<ellipse cx="230" cy="194" rx="56" ry="54" fill="%s"/><ellipse cx="236" cy="188" rx="54" ry="52" fill="%s"/>' % (P_SHADE, P_BODY)
    # the swollen forehead running down onto the bill
    out += '<path d="M196 170 Q206 150 232 150 Q214 168 214 196 L196 204 Z" fill="%s"/>' % P_BODY
    # the curly crest at the nape (a grandmother's curls), and the flower pinned in it
    for cx, cy, r in ((282, 150, 14), (292, 172, 12), (268, 136, 12)):
        out += '<circle cx="%s" cy="%s" r="%s" fill="%s"/>' % (f(cx), f(cy), f(r), P_BODY)
        out += line('M%s %s a%s %s 0 1 1 %s %s' % (f(cx - r * 0.5), f(cy + r * 0.1), f(r * 0.5), f(r * 0.5), f(r * 0.6), f(-r * 0.3)),
                    P_SHADE, 3.2)
    for cx, cy in ((260, 128), (251, 140.4), (236.5, 135.6), (236.5, 120.4), (251, 115.6)):
        out += '<circle cx="%s" cy="%s" r="10" fill="%s"/>' % (f(cx), f(cy), P_FLOWER)
    out += '<circle cx="247" cy="128" r="8" fill="#FFC83D"/>'
    lift = dict(closed=0, talk=9, show=4, cheer=15)[beak]
    if lift:
        out += '<path d="M204 210 L60 226 Q130 252 200 240 Z" fill="%s"/>' % INK
        if beak != 'show':
            out += '<ellipse cx="176" cy="234" rx="14" ry="4" fill="%s"/>' % TONGUE
    # the throat pouch: bare yellow skin hanging from the lower bill, deepest under its middle
    pouch = '<path d="M204 222 Q140 230 62 230 Q72 268 118 288 Q168 304 206 266 Z" fill="%s"/>' % P_POUCH
    pouch += '<path d="M78 252 Q120 286 168 286 Q192 282 206 266 Q186 300 136 296 Q98 288 78 252 Z" fill="%s"/>' % P_POUCHS
    pouch += line('M96 246 Q130 262 172 262', '#FFFFFF', 3, ' opacity="0.45"')
    out += grp('pouch', pouch)
    # the upper bill, hinged at the face: flat on top with a ridge, narrowing to the hooked nail
    upper = ('<path d="M208 182 Q140 194 66 214 Q48 218 46 230 Q46 240 56 236 Q60 228 70 228 Q140 226 206 228 Z" fill="%s"/>'
             % P_BEAK)
    upper += '<path d="M206 214 Q140 220 70 228 Q140 226 206 228 Z" fill="%s"/>' % P_BEAKS
    upper += line('M196 198 Q130 208 74 220', P_BEAKS, 3)
    upper += '<path d="M72 214 Q50 216 46 230 Q46 242 56 236 Q58 226 72 226 Z" fill="%s"/>' % P_NAIL
    out += '<g id="mouth">%s</g>' % grp('bill', upper, 'rotate(%s 206 214)' % f(lift) if lift else '')
    # the bare pink skin round the eye, the glasses over it
    out += '<ellipse cx="218" cy="190" rx="24" ry="20" fill="%s"/>' % P_FACE
    out += '<circle cx="216" cy="186" r="21" fill="#FFFFFF" opacity="0.55" stroke="%s" stroke-width="5"/>' % INK
    out += '<circle cx="262" cy="182" r="16" fill="#FFFFFF" opacity="0.55" stroke="%s" stroke-width="5"/>' % INK
    out += line('M237 185 L246 184', INK, 5) + line('M278 180 L292 176', INK, 4)
    if eyes == 'closed':
        out += line('M206 188 Q216 178 226 188', INK, 6) + line('M254 184 Q262 177 270 184', INK, 6)
    else:
        out += '<ellipse cx="%s" cy="%s" rx="7.5" ry="9.5" fill="%s"/><circle cx="%s" cy="%s" r="3" fill="#FFFFFF"/>' % (
            f(214 + lx), f(188 + ly), INK, f(212 + lx), f(184 + ly))
        out += '<ellipse cx="%s" cy="%s" rx="6.5" ry="8.5" fill="%s"/><circle cx="%s" cy="%s" r="2.6" fill="#FFFFFF"/>' % (
            f(260 + lx * 0.8), f(184 + ly), INK, f(258 + lx * 0.8), f(180.5 + ly))
        out += line('M205 162 Q216 156 227 161', INK, 4) + line('M254 160 Q262 155 269 159', INK, 4)
    out += '<ellipse cx="256" cy="214" rx="12" ry="7" fill="%s" opacity="0.9"/>' % LIP
    return grp('head', out)


def pn_neck(d='M262 330 C242 300 238 268 230 236'):
    """A thick, short neck (a resting pelican holds its head close on its shoulders), its front bulging a little."""
    return grp('neck', line(d, P_SHADE, 80) + line(d, P_BODY, 72))


def pn_still():
    """The still (idle): standing, the bill resting a little down along her chest, eyes closed in a smile."""
    body = '<ellipse cx="288" cy="468" rx="132" ry="10" fill="%s"/>' % SHADOW
    body += pn_trunk() + pn_feet() + pn_folded_wing() + pn_neck() + pn_apron()
    body += pn_head(eyes='closed', beak='closed')
    return body, dict(mouth=(150, 232), feet=(288, 470))


def pn_wing_out(shoulder, ang, L, colour=P_BODY, shade=P_SHADE, gid='hand', down=1, D=64, spread=1.0, fingers=5):
    """An open pelican wing seen from the side (Bing photos: pelicans spreading their wings): the inner wing with its coverts
    (`colour`), a scalloped trailing edge of secondaries, and the long primaries at the end separated by slots like fingers
    (`shade`), the leading primary being the tip. Drawn along +x from the shoulder in local units, placed by a transform;
    `down` = 1 hangs the trailing edge below the leading edge whichever way the wing points."""
    a = L * 0.5
    step_x, step_y = 15, 12 * spread
    d = 'M0 -12 Q%s -26 %s -16' % (f(a / 2), f(a))
    pts = []
    for i in range(fingers):
        tx, ty = L - i * step_x, -8 + i * step_y
        d += ' L%s %s Q%s %s %s %s' % (f(tx - 12), f(ty - 6), f(tx + 5), f(ty), f(tx - 12), f(ty + 6))
        if i < fingers - 1:
            d += ' L%s %s' % (f(tx - 20), f(ty + 4))
        pts.append((tx, ty))
    lx, ly = pts[-1]
    # the trailing edge: secondaries, scalloped, back to the body
    x0, y0 = lx - 16, ly + 8
    n = 5
    for i in range(n):
        x1 = x0 - (x0 - 0) / (n - i)
        y1 = y0 + (D - y0) / (n - i)
        d += ' Q%s %s %s %s' % (f((x0 + x1) / 2), f((y0 + y1) / 2 + 14), f(x1), f(y1))
        x0, y0 = x1, y1
    d += ' Q-16 %s 0 -12 Z' % f(D / 2)
    out = '<path d="%s" fill="%s"/>' % (d, shade)
    # the coverts: the lighter inner wing over the base of the feathers
    out += '<path d="M0 -12 Q%s -26 %s -16 Q%s -8 %s 6 Q%s %s %s %s Q%s %s 0 %s Z" fill="%s"/>' % (
        f(a / 2), f(a), f(a + 22), f(a + 16), f(a * 0.8), f(D * 0.5), f(a * 0.35), f(D * 0.62), f(-6), f(D * 0.5), f(D * 0.5), colour)
    out += line('M%s %s Q%s %s %s %s' % (f(a * 0.15), f(D * 0.18), f(a * 0.55), f(D * 0.12), f(a + 8), f(-4)), shade, 4, ' opacity="0.7"')
    flip = down * (1 if abs(((ang + 180) % 360) - 180) <= 90 else -1) < 0
    tr = 'translate(%s %s) rotate(%s)%s' % (f(shoulder[0]), f(shoulder[1]), f(ang), ' scale(1 -1)' if flip else '')
    return grp(gid, out, tr)


def pn_talk():
    body = '<ellipse cx="288" cy="468" rx="132" ry="10" fill="%s"/>' % SHADOW
    # the far wing's dark primaries show at her back; the near wing is lifted forward from the shoulder, primaries open like fingers
    body += pn_folded_wing() + pn_trunk() + pn_feet() + pn_neck() + pn_apron()
    body += pn_head(eyes='open', look=(-3, 0), beak='talk')
    body += pn_wing_out((318, 336), -160, 176, colour=P_COVERT, shade=P_PRIM, gid='wing-end', D=50, spread=1.25, fingers=4)
    anchors = dict(mouth=(150, 232), feet=(288, 470))
    return body, anchors


def pn_show():
    body = '<ellipse cx="276" cy="468" rx="138" ry="10" fill="%s"/>' % SHADOW
    inner = pn_folded_wing() + pn_trunk() + pn_feet() + pn_neck('M262 336 C242 302 236 272 222 244') + pn_apron()
    inner += grp('head-turn', pn_head(eyes='open', look=(-4, 4), beak='show'), 'translate(-6 6) rotate(-4 226 230)')
    # the worked-example hand: the near wing held out level toward the task under her pouch, the long dark primaries fanned;
    # the tip is the leading primary
    inner += pn_wing_out((314, 346), 184, 262, colour=P_COVERT, shade=P_PRIM, D=66)
    body += grp('body', inner, 'rotate(-3 270 466)')
    anchors = dict(mouth=(140, 238), hand=(52, 316), feet=(282, 468))
    return body, anchors


def pn_celebrate():
    body = '<ellipse cx="288" cy="468" rx="106" ry="9" fill="%s"/>' % SHADOW_HOP
    body += grp('sparks', spark(60, 330, 13) + spark(470, 300, 11))
    # both wings raised behind her (side view: the far wing shows beside the near one), the dark primaries spread like fingers,
    # the bill open in a happy head-toss
    inner = pn_wing_out((300, 322), -78, 206, colour=P_SHADE, shade=P_PRIM, gid='wing-far', D=58)
    inner += pn_trunk() + pn_feet(hop=True) + pn_neck('M262 336 C242 300 240 270 232 240') + pn_apron()
    inner += pn_wing_out((332, 340), -52, 190, colour=P_COVERT, shade=P_PRIM, gid='wing-near', D=60)
    inner += grp('head-up', pn_head(eyes='closed', beak='cheer'), 'rotate(10 230 240)')
    body += grp('body', inner, 'translate(0 -18)')
    anchors = dict(feet=(288, 466), burst=(236, 96))
    return body, anchors


def bird_wing(shoulder, ang, L, coverts, primaries, bars=None, flash=None, gid='hand', down=1, D=60, spread=1.0, fingers=5):
    """A small bird's open wing (Pip): the pelican wing's shape, with the budgie's scalloped bars on the coverts and, when
    `flash` is given, the yellow band across the flight feathers that only shows when the wing is spread."""
    g = pn_wing_out((0, 0), 0, L, colour=coverts, shade=primaries, gid='w', D=D, spread=spread, fingers=fingers)
    a = L * 0.5
    extra = ''
    if flash:
        extra += line('M%s %s L%s %s' % (f(a + 16), f(-8), f(a + 4), f(D * 0.4)), flash, 9)
    if bars:
        for r, y in enumerate((D * 0.04, D * 0.22, D * 0.40)):
            x0 = a * (0.12 + 0.1 * r)
            n = 3 - (r > 1)
            d = 'M%s %s' % (f(x0), f(y)) + ''.join(' q7 11 14 0' for _ in range(n))
            extra += line(d, bars, 4)
    flip = down * (1 if abs(((ang + 180) % 360) - 180) <= 90 else -1) < 0
    tr = 'translate(%s %s) rotate(%s)%s' % (f(shoulder[0]), f(shoulder[1]), f(ang), ' scale(1 -1)' if flip else '')
    return grp(gid, g + extra, tr)


# =========================================================================================================================
# PIP, the budgie (the English course; app/assets/art/languages/host_eng.svg). Palette of the still.
# =========================================================================================================================
E_TAIL, E_TAIL2, E_SHADE, E_BODY, E_BELLY, E_WING, E_BAR = '#3E6FD9', '#5B8BEF', '#4E9F33', '#6CC24A', '#93D96B', '#3C7F2A', '#FFD93D'
E_LEG, E_HEADS, E_HEAD, E_CHEEK, E_DOT, E_WHITE, E_CERE, E_BEAK, E_BEAKL = (
    '#8EA3C4', '#E9C22C', '#FFD93D', '#5B6FD6', '#3B2C85', '#FFF7D6', '#4F8FE8', '#9A9C86', '#6F7160')


def pip_tail(fan=False):
    out = ''
    if fan:
        out += '<path d="M262 380 L326 466 Q314 480 300 470 L246 392 Z" fill="%s"/>' % E_TAIL2
        out += '<path d="M278 366 L404 414 Q410 432 392 436 L264 384 Z" fill="%s"/>' % E_TAIL2
    out += '<path d="M270 372 L382 446 Q380 464 360 462 L248 392 Z" fill="%s"/>' % E_TAIL
    out += '<path d="M272 382 L366 442 Q362 452 352 451 L258 396 Z" fill="%s"/>' % E_TAIL2
    return grp('tail', out)


def pip_legs(hop=False):
    out = ''
    for x in (222, 290):
        if hop:
            out += line('M%d 424 L%d 444' % (x, x), E_LEG, 10)
            out += line('M%d 444 l-12 14 M%d 444 l12 14 M%d 444 l0 16' % (x, x, x), E_LEG, 8)
        else:
            out += line('M%d 424 L%d 450' % (x, x), E_LEG, 10)
            out += line('M%d 450 l-16 10 M%d 450 l16 10 M%d 450 l0 14' % (x, x, x), E_LEG, 8)
    return grp('legs', out)


def pip_body():
    out = '<ellipse cx="250" cy="314" rx="104" ry="124" fill="%s"/><ellipse cx="258" cy="308" rx="100" ry="122" fill="%s"/>' % (E_SHADE, E_BODY)
    out += '<ellipse cx="262" cy="336" rx="62" ry="84" fill="%s"/>' % E_BELLY
    return grp('trunk', out)


def pip_folded(cx, cy, rot, gid):
    out = '<ellipse cx="%s" cy="%s" rx="40" ry="90" fill="%s" transform="rotate(%s %s %s)"/>' % (cx, cy, E_WING, rot, cx, cy)
    for k in range(4):
        y = cy - 51 + k * 31.3
        out += line('M%s %s q12.6 20 25.2 0 q12.6 20 25.2 0' % (f(cx - 25.2), f(y)), E_BAR, 5, ' transform="rotate(%s %s %s)"' % (rot, cx, cy))
    return grp(gid, out)


def pip_wing(cx, cy, rot, gid, fan=0, flash=False, rx=36, ry=80):
    """A wing in the still's own drawing (a dark green ellipse with bold yellow scallop bars), placed at (cx, cy) and turned by
    `rot`; with `fan`, its flight feathers open at the tip (the top end) like fingers; with `flash`, the yellow wing flash
    across their base, which a budgie shows only when the wing is spread (Wikipedia)."""
    out = ''
    if fan:
        angs = {3: (-14, 0, 14), 4: (-21, -7, 7, 21)}[fan]
        for a in angs:
            px, py = polar(0, -ry + 30, -90 + a, ry * 0.62)
            out += '<ellipse cx="%s" cy="%s" rx="%s" ry="10" fill="%s" transform="rotate(%s %s %s)"/>' % (
                f(px), f(py), f(ry * 0.4), E_WING, f(a - 90), f(px), f(py))
        if flash:
            out += line('M%s %s Q0 %s %s %s' % (f(-rx * 0.75), f(-ry + 2), f(-ry - 16), f(rx * 0.75), f(-ry + 2)), E_BAR, 8)
    out += '<ellipse cx="0" cy="0" rx="%s" ry="%s" fill="%s"/>' % (f(rx), f(ry), E_WING)
    for k in range(4):
        y = -ry * 0.55 + k * ry * 0.36
        out += line('M%s %s q%s 18 %s 0 q%s 18 %s 0' % (f(-rx * 0.6), f(y), f(rx * 0.3), f(rx * 0.6), f(rx * 0.3), f(rx * 0.6)), E_BAR, 5)
    return grp(gid, out, 'translate(%s %s) rotate(%s)' % (f(cx), f(cy), f(rot)))


def pip_head(eyes='open', look=(0, 0), beak='closed'):
    lx, ly = look
    out = '<circle cx="252" cy="168" r="88" fill="%s"/><circle cx="258" cy="164" r="86" fill="%s"/>' % (E_HEADS, E_HEAD)
    out += '<ellipse cx="300" cy="118" rx="24" ry="10" fill="#FFFFFF" opacity="0.3" transform="rotate(-25 300 118)"/>'
    out += '<ellipse cx="190" cy="210" rx="17" ry="12" fill="%s"/><ellipse cx="326" cy="210" rx="17" ry="12" fill="%s"/>' % (E_CHEEK, E_CHEEK)
    out += ''.join('<circle cx="%d" cy="%d" r="7" fill="%s"/>' % (x, y, E_DOT) for x, y in ((212, 238), (234, 246), (278, 246), (300, 238)))
    if eyes == 'open':
        for ex in (218, 298):
            out += '<circle cx="%d" cy="160" r="21" fill="%s"/>' % (ex, E_WHITE)
            out += '<circle cx="%s" cy="%s" r="16" fill="%s"/>' % (f(ex + lx), f(161 + ly), E_DOT)
            out += '<circle cx="%s" cy="%s" r="5.5" fill="#FFFFFF"/><circle cx="%s" cy="%s" r="2.5" fill="#FFFFFF"/>' % (
                f(ex - 5 + lx), f(154 + ly), f(ex + 5 + lx), f(167 + ly))
    else:
        out += line('M200 166 Q218 146 236 166', E_DOT, 8) + line('M280 166 Q298 146 316 166', E_DOT, 8)
    out += '<rect x="240" y="178" width="34" height="14" rx="7" fill="%s"/>' % E_CERE
    if beak == 'closed':
        out += '<path d="M236 192 Q257 186 278 192 Q276 214 257 226 Q238 214 236 192 Z" fill="%s"/>' % E_BEAK
        out += line('M257 226 Q262 216 264 206', E_BEAKL, 3)
    else:
        h = dict(talk=24, show=16, cheer=30)[beak]
        m = '<path d="M241 204 Q257 210 273 204 Q272 %d 257 %d Q242 %d 241 204 Z" fill="%s"/>' % (204 + h - 2, 204 + h, 204 + h - 2, INK)
        if beak != 'show':
            m += '<ellipse cx="257" cy="%d" rx="8" ry="4" fill="%s"/>' % (204 + h - 6, TONGUE)
        m += '<path d="M247 %d Q257 %d 267 %d Q264 %d 257 %d Q250 %d 247 %d Z" fill="%s"/>' % (
            201 + h, 205 + h, 201 + h, 210 + h, 212 + h, 210 + h, 201 + h, E_BEAK)
        m += '<path d="M236 192 Q257 186 278 192 Q276 206 257 214 Q238 206 236 192 Z" fill="%s"/>' % E_BEAK
        m += line('M257 214 Q262 207 264 200', E_BEAKL, 3)
        out += '<g id="mouth">%s</g>' % m
    return grp('head', out)


def pip_talk():
    body = '<ellipse cx="256" cy="466" rx="110" ry="11" fill="%s"/>' % SHADOW
    body += pip_tail() + pip_body()
    body += pip_folded(346, 318, -12, 'wing-start')
    body += pip_legs()
    # the explaining hand: the end-side wing lifted out and up, its flight feathers open like a raised hand
    body += pip_wing(132, 222, -34, 'wing-end', fan=3, rx=32, ry=76)
    body += pip_head(look=(-5, 0), beak='talk')
    anchors = dict(mouth=(257, 222), feet=(256, 464))
    return body, anchors


def pip_show():
    body = '<ellipse cx="250" cy="466" rx="116" ry="11" fill="%s"/>' % SHADOW
    inner = pip_tail() + pip_body()
    inner += pip_folded(342, 322, -10, 'wing-start')
    inner += pip_legs()
    inner += grp('head-turn', pip_head(look=(-7, 6), beak='show'), 'rotate(-5 258 250)')
    # the worked-example hand: the end-side wing held out level toward the task, the flight feathers fanned; the tip is
    # the leading primary
    inner += pip_wing(170, 286, -92, 'hand', fan=4, rx=34, ry=76)
    body += grp('body', inner, 'rotate(-3 256 466)')
    anchors = dict(mouth=(254, 224), hand=(44, 290), feet=(250, 464))
    return body, anchors


def pip_celebrate():
    body = '<ellipse cx="256" cy="466" rx="88" ry="9" fill="%s"/>' % SHADOW_HOP
    body += grp('sparks', spark(116, 70, 15) + spark(408, 76, 11))
    inner = pip_tail(fan=True) + pip_body() + pip_legs(hop=True)
    # both wings up and spread, the yellow wing flash showing (it shows only when a budgie's wing is open)
    inner += pip_wing(132, 226, -40, 'wing-end', fan=4, flash=True, rx=34, ry=80)
    inner += pip_wing(384, 226, 40, 'wing-start', fan=4, flash=True, rx=34, ry=80)
    inner += pip_head(eyes='closed', beak='cheer')
    body += grp('body', inner, 'translate(0 -22)')
    anchors = dict(feet=(256, 466), burst=(258, 40))
    return body, anchors


# =========================================================================================================================
# THE HYRAX (the Hebrew course; app/assets/art/languages/host_heb.svg). Palette of the still.
# =========================================================================================================================
H_SHADE, H_BODY, H_BELLY, H_PAD, H_TOE, H_EAR, H_EARIN, H_LIGHT, H_EYE, H_WHISK = (
    '#8C6F55', '#A98A6E', '#EADBC6', '#5C4330', '#C9A07E', '#5E4634', '#E2A79C', '#F4EADC', '#3B2C85', '#3E2E22')


def hy_pencil(tx, ty, ang, sc=1.0):
    """The coral pencil of the still, its graphite tip placed at (tx, ty) and pointing toward `ang` (degrees)."""
    p = ('<rect x="170" y="344" width="150" height="30" rx="4" fill="#F07F6E"/><rect x="170" y="360" width="150" height="14" rx="3" fill="#D9604F"/>'
         '<rect x="320" y="344" width="16" height="30" fill="#C9C3D9"/><rect x="336" y="344" width="22" height="30" rx="8" fill="#F4A7B4"/>'
         '<path d="M170 344 L136 359 L170 374 Z" fill="#F2C58F"/><path d="M147 354 L136 359 L147 364 Z" fill="#3B2C85"/>')
    return '<g id="pencil" transform="translate(%s %s) rotate(%s) scale(%s) translate(-136 -359)">%s</g>' % (
        f(tx), f(ty), f(ang - 180), f(sc), p)


def hy_paw(x, y, rot=0, up=False):
    """A plump padded paw; `up` shows its soft pads (Wikipedia: large moist pads on the soles)."""
    out = '<ellipse cx="%s" cy="%s" rx="24" ry="19" fill="%s" transform="rotate(%s %s %s)"/>' % (f(x), f(y), H_BODY, f(rot), f(x), f(y))
    if up:
        out += '<ellipse cx="%s" cy="%s" rx="11" ry="8" fill="%s" opacity="0.55"/>' % (f(x), f(y + 4), H_PAD)
        for dx in (-12, 0, 12):
            tx, ty = x + dx, y - 9 + abs(dx) * 0.25
            out += '<circle cx="%s" cy="%s" r="5.5" fill="%s"/>' % (f(tx), f(ty), H_TOE)
    else:
        out += line('M%s %s q6 6 12 0 q6 6 12 0' % (f(x - 14), f(y + 4)), H_SHADE, 3)
    return out


def hy_head(eyes='open', look=(0, 0), mouth='closed'):
    lx, ly = look
    out = '<circle cx="178" cy="116" r="22" fill="%s"/><circle cx="178" cy="118" r="14" fill="%s"/>' % (H_EAR, H_EARIN)
    out += '<circle cx="334" cy="116" r="22" fill="%s"/><circle cx="334" cy="118" r="14" fill="%s"/>' % (H_EAR, H_EARIN)
    hp = 'M146 186 Q144 98 256 94 Q368 98 366 186 Q356 250 256 286 Q156 250 146 186 Z'
    out += '<path d="%s" fill="%s" transform="translate(-6 6)"/><path d="%s" fill="%s"/>' % (hp, H_SHADE, hp, H_BODY)
    out += '<ellipse cx="304" cy="134" rx="30" ry="12" fill="#FFFFFF" opacity="0.18" transform="rotate(-20 304 134)"/>'
    out += '<ellipse cx="208" cy="160" rx="24" ry="10" fill="%s" transform="rotate(8 208 160)"/>' % H_LIGHT
    out += '<ellipse cx="304" cy="160" rx="24" ry="10" fill="%s" transform="rotate(-8 304 160)"/>' % H_LIGHT
    out += '<path d="M200 220 Q256 196 312 220 Q300 262 256 282 Q212 262 200 220 Z" fill="%s"/>' % H_BELLY
    out += '<ellipse cx="256" cy="290" rx="30" ry="10" fill="%s"/>' % H_LIGHT
    if eyes == 'open':
        for ex in (212, 300):
            out += '<ellipse cx="%s" cy="%s" rx="15" ry="18" fill="%s"/>' % (f(ex + lx), f(190 + ly), H_EYE)
            out += '<circle cx="%s" cy="%s" r="5.5" fill="#FFFFFF"/><circle cx="%s" cy="%s" r="2.6" fill="#FFFFFF"/>' % (
                f(ex - 5 + lx), f(183 + ly), f(ex + 4 + lx), f(197 + ly))
    else:
        out += line('M198 194 Q212 176 226 194', H_EYE, 7) + line('M286 194 Q300 176 314 194', H_EYE, 7)
    out += '<path d="M242 246 Q256 239 270 246 Q266 258 256 260 Q246 258 242 246 Z" fill="%s"/>' % H_EYE
    out += '<ellipse cx="252" cy="246" rx="4.5" ry="2.2" fill="#FFFFFF" opacity="0.5"/>'
    if mouth == 'closed':
        out += line('M256 260 L256 266 M240 268 Q248 276 256 267 Q264 276 272 268', H_EYE, 4.5)
    elif mouth == 'talk':
        out += line('M256 260 L256 264', H_EYE, 4.5) + open_mouth(256, 264, 30, 22)
    elif mouth == 'show':
        out += line('M256 260 L256 264', H_EYE, 4.5) + open_mouth(256, 265, 24, 15, tongue=None)
    elif mouth == 'cheer':
        out += line('M256 260 L256 263', H_EYE, 4.5) + open_mouth(256, 262, 38, 28)
    for d in ('M220 252 q-24 -4 -52 -8', 'M220 262 q-24 -1 -52 0', 'M220 272 q-24 2 -52 8',
              'M292 252 q24 -4 52 -8', 'M292 262 q24 -1 52 0', 'M292 272 q24 2 52 8'):
        out += line(d, H_WHISK, 2.4, ' opacity="0.8"')
    out += '<ellipse cx="186" cy="226" rx="15" ry="8" fill="%s" opacity="0.8"/><ellipse cx="326" cy="226" rx="16" ry="9" fill="%s" opacity="0.8"/>' % (LIP, LIP)
    return grp('head', out)


def hy_feet(hop=False):
    out = ''
    for x, r in ((196, -10 if hop else 0), (316, 10 if hop else 0)):
        g = '<ellipse cx="%d" cy="448" rx="40" ry="18" fill="%s"/><ellipse cx="%d" cy="452" rx="26" ry="9" fill="%s" opacity="0.55"/>' % (x, H_SHADE, x, H_PAD)
        g += ''.join('<circle cx="%d" cy="440" r="6.5" fill="%s"/>' % (x + dx, H_TOE) for dx in (-16, 0, 16))
        out += '<g transform="rotate(%d %d 448)">%s</g>' % (r, x, g) if r else g
    return grp('feet', out)


def hy_trunk():
    out = '<ellipse cx="248" cy="338" rx="142" ry="124" fill="%s"/><ellipse cx="258" cy="330" rx="138" ry="122" fill="%s"/>' % (H_SHADE, H_BODY)
    out += '<ellipse cx="256" cy="372" rx="82" ry="78" fill="%s"/>' % H_BELLY
    return grp('trunk', out)


def hy_talk():
    body = '<ellipse cx="256" cy="466" rx="150" ry="11" fill="%s"/>' % SHADOW
    body += hy_trunk() + hy_feet()
    # the pencil stays in the start-side paw, resting across the belly as in the still
    body += '<g transform="rotate(-32 256 360)">%s</g>' % hy_pencil(136, 359, 180)
    body += grp('paw-start', hy_paw(306, 328))
    body += hy_head(look=(-5, 0), mouth='talk')
    # the explaining hand: the end-side paw lifted beside the cheek, its soft pads showing
    body += grp('arm-end', line('M170 352 L140 300', H_BODY, 36) + hy_paw(136, 290, -20, up=True))
    anchors = dict(mouth=(256, 276), feet=(256, 466))
    return body, anchors


def hy_show():
    body = '<ellipse cx="250" cy="466" rx="152" ry="11" fill="%s"/>' % SHADOW
    inner = hy_trunk() + hy_feet()
    inner += grp('paw-start', hy_paw(300, 376, 10))
    inner += grp('head-turn', hy_head(look=(-7, 7), mouth='show'), 'rotate(-5 256 290)')
    # the worked-example hand: the end-side paw holds the coral pencil out level toward the task; the graphite tip is the
    # pointer
    hand = line('M190 360 L178 326', H_BODY, 36) + hy_pencil(54, 320, 180) + hy_paw(182, 320, -6)
    inner += grp('hand', hand)
    body += grp('body', inner, 'rotate(-3 256 466)')
    anchors = dict(mouth=(254, 280), hand=(46, 323), feet=(250, 466))
    return body, anchors


def hy_celebrate():
    body = '<ellipse cx="256" cy="466" rx="120" ry="9" fill="%s"/>' % SHADOW_HOP
    body += grp('sparks', spark(70, 120, 15) + spark(214, 40, 10))
    inner = hy_trunk() + hy_feet(hop=True)
    # the pencil held up high like a baton, a coral swirl drawn in the air behind its tip
    inner += grp('swirl', line('M402 122 C420 80 470 86 462 122 C456 150 420 140 430 116 C440 92 486 98 488 70', '#F07F6E', 6, ' opacity="0.85"'))
    inner += grp('arms', line('M150 330 L118 250', H_BODY, 36) + hy_paw(116, 238, -15, up=True) +
                 line('M362 330 L392 256', H_BODY, 36))
    inner += hy_pencil(400, 118, -80, 0.8)
    inner += hy_paw(392, 246, 15)
    inner += hy_head(eyes='closed', mouth='cheer')
    body += grp('body', inner, 'translate(0 -22)')
    anchors = dict(feet=(256, 466), burst=(256, 60))
    return body, anchors


# =========================================================================================================================
# THE GIRAFFE (the Russian course; app/assets/art/languages/host_rus.svg). Palette of the still.
# =========================================================================================================================
R_SHADE, R_BODY, R_SPOT, R_MANE, R_KNOB, R_HOOF, R_EARIN, R_MUZ, R_NOSE, R_EYE = (
    '#E8B26A', '#F8D9A0', '#D9823B', '#B8612A', '#6B3E1E', '#5C3A22', '#F4C2B4', '#FBEBCD', '#8A5634', '#3B2C85')


def gi_leg(pts, colour, hoof_ang=90):
    """A long leg through `pts` (hip, knee, hoof) with a knee bump and the cloven hoof at the end, toward `hoof_ang`."""
    d = 'M%s %s' % (f(pts[0][0]), f(pts[0][1])) + ''.join(' L%s %s' % (f(x), f(y)) for x, y in pts[1:])
    out = line(d, colour, 30)
    if len(pts) > 2:
        out += '<circle cx="%s" cy="%s" r="17" fill="%s"/>' % (f(pts[1][0]), f(pts[1][1]), colour)
    x, y = pts[-1]
    # the hoof: the still's dark cap at the end of the leg, cloven by a thin line
    out += '<g transform="rotate(%s %s %s)"><rect x="%s" y="%s" width="30" height="20" rx="7" fill="%s"/>' % (
        f(hoof_ang - 90), f(x), f(y), f(x - 15), f(y - 6), R_HOOF)
    out += '<path d="M%s %s L%s %s" stroke="%s" stroke-width="2.5" stroke-linecap="round"/></g>' % (
        f(x), f(y + 2), f(x), f(y + 13), R_SHADE)
    return out


def gi_stand(x, colour):
    """A standing leg exactly as in the still: a rounded column and its dark hoof."""
    return ('<rect x="%d" y="370" width="30" height="86" rx="12" fill="%s"/><rect x="%d" y="440" width="30" height="18" rx="6" fill="%s"/>' % (
        x, colour, x, R_HOOF))


def gi_neckhead(eyes='open', look=(0, 0), mouth='closed'):
    lx, ly = look
    out = '<path d="M214 330 L226 170 Q256 150 286 170 L300 330 Z" fill="%s"/>' % R_SHADE
    out += '<path d="M220 330 L232 170 Q258 154 284 170 L296 330 Z" fill="%s"/>' % R_BODY
    out += line('M286 172 Q298 250 300 318', R_MANE, 11)
    out += ''.join('<ellipse cx="%d" cy="%d" rx="%d" ry="%d" fill="%s"/>' % (x, y, a, b, R_SPOT) for x, y, a, b in (
        (248, 300, 18, 14), (268, 262, 14, 12), (246, 228, 14, 11), (266, 196, 11, 9)))
    out += '<rect x="219" y="48" width="14" height="46" rx="7" fill="%s"/><circle cx="226" cy="48" r="13" fill="%s"/>' % (R_SHADE, R_KNOB)
    out += '<rect x="283" y="48" width="14" height="46" rx="7" fill="%s"/><circle cx="290" cy="48" r="13" fill="%s"/>' % (R_SHADE, R_KNOB)
    out += '<ellipse cx="164" cy="110" rx="38" ry="16" fill="%s" transform="rotate(18 164 110)"/>' % R_SHADE
    out += '<ellipse cx="168" cy="111" rx="26" ry="9" fill="%s" transform="rotate(18 168 111)"/>' % R_EARIN
    out += '<ellipse cx="350" cy="110" rx="38" ry="16" fill="%s" transform="rotate(-18 350 110)"/>' % R_SHADE
    out += '<ellipse cx="346" cy="111" rx="26" ry="9" fill="%s" transform="rotate(-18 346 111)"/>' % R_EARIN
    out += '<ellipse cx="254" cy="130" rx="74" ry="66" fill="%s"/><ellipse cx="258" cy="126" rx="72" ry="64" fill="%s"/>' % (R_SHADE, R_BODY)
    out += '<ellipse cx="230" cy="86" rx="16" ry="11" fill="%s"/><ellipse cx="292" cy="92" rx="12" ry="9" fill="%s"/>' % (R_SPOT, R_SPOT)
    out += '<ellipse cx="258" cy="172" rx="54" ry="36" fill="%s"/>' % R_MUZ
    out += '<ellipse cx="240" cy="168" rx="5" ry="7" fill="%s"/><ellipse cx="276" cy="168" rx="5" ry="7" fill="%s"/>' % (R_NOSE, R_NOSE)
    if mouth == 'closed':
        out += line('M236 188 Q258 204 280 188', R_EYE, 6)
    elif mouth == 'talk':
        out += open_mouth(258, 184, 36, 24)
    elif mouth == 'show':
        out += open_mouth(258, 186, 28, 16, tongue=None)
    elif mouth == 'cheer':
        out += open_mouth(258, 182, 46, 28)
    if eyes == 'open':
        for ex in (222, 294):
            out += '<ellipse cx="%s" cy="%s" rx="15" ry="19" fill="%s"/>' % (f(ex + lx), f(124 + ly), R_EYE)
            out += '<circle cx="%s" cy="%s" r="6" fill="#FFFFFF"/><circle cx="%s" cy="%s" r="2.6" fill="#FFFFFF"/>' % (
                f(ex - 5 + lx), f(117 + ly), f(ex + 4 + lx), f(131 + ly))
            out += line('M%d 106 l-5 -10 M%d 106 l0 -10 M%d 106 l5 -10' % (ex - 8, ex, ex + 8), R_EYE, 3.5)
    else:
        for ex in (222, 294):
            out += line('M%d 128 Q%d 112 %d 128' % (ex - 14, ex, ex + 14), R_EYE, 7)
            out += line('M%d 118 l-6 -8 M%d 114 l0 -10 M%d 118 l6 -8' % (ex - 9, ex, ex + 9), R_EYE, 3.5)
    out += '<ellipse cx="192" cy="158" rx="13" ry="8" fill="%s" opacity="0.8"/><ellipse cx="324" cy="158" rx="13" ry="8" fill="%s" opacity="0.8"/>' % (LIP, LIP)
    return out


def gi_body():
    out = '<ellipse cx="258" cy="344" rx="112" ry="66" fill="%s"/><ellipse cx="262" cy="338" rx="108" ry="62" fill="%s"/>' % (R_SHADE, R_BODY)
    out += ''.join('<ellipse cx="%d" cy="%d" rx="%d" ry="%d" fill="%s"/>' % (x, y, a, b, R_SPOT) for x, y, a, b in (
        (200, 330, 26, 20), (258, 316, 24, 18), (318, 332, 26, 20), (232, 366, 20, 13), (292, 368, 20, 13)))
    return grp('trunk', out)


def gi_tail(curl=False):
    if curl:
        return grp('tail', line('M352 322 Q400 300 404 262 Q406 236 384 238 Q368 242 378 258', R_SHADE, 8) +
                   '<ellipse cx="380" cy="262" rx="10" ry="15" fill="%s" transform="rotate(40 380 262)"/>' % R_KNOB)
    return grp('tail', line('M352 330 Q384 352 380 392', R_SHADE, 8) + '<ellipse cx="380" cy="402" rx="10" ry="16" fill="%s"/>' % R_KNOB)


def gi_talk():
    body = '<ellipse cx="256" cy="466" rx="128" ry="11" fill="%s"/>' % SHADOW
    body += gi_tail()
    legs = gi_stand(185, R_SHADE) + gi_stand(301, R_SHADE) + gi_stand(275, R_BODY)
    # the explaining hand: the end-side front hoof lifted, the knee bent forward
    legs += gi_leg([(226, 380), (204, 416), (210, 444)], R_BODY, hoof_ang=100)
    body += grp('legs', legs)
    body += gi_body()
    body += grp('head', gi_neckhead(look=(-6, 0), mouth='talk'), 'rotate(-6 258 330)')
    anchors = dict(mouth=(238, 197), feet=(256, 464))
    return body, anchors


def gi_show():
    body = '<ellipse cx="250" cy="466" rx="132" ry="11" fill="%s"/>' % SHADOW
    inner = gi_tail()
    legs = gi_stand(185, R_SHADE) + gi_stand(301, R_SHADE) + gi_stand(275, R_BODY)
    inner += grp('legs', legs)
    # the worked-example hand: the end-side front leg lifted and held out toward the task, the knee bent a little, the
    # cloven hoof at the tip (a giraffe pawing forward); its top is under the body, at the shoulder
    inner += grp('hand', gi_leg([(214, 372), (150, 362), (76, 334)], R_BODY, hoof_ang=-160))
    inner += gi_body()
    inner += grp('head', gi_neckhead(look=(-8, 8), mouth='show'), 'rotate(-14 258 336)')
    body += grp('body', inner, 'rotate(-3 256 466)')
    anchors = dict(mouth=(200, 210), hand=(56, 326), feet=(256, 464))
    return body, anchors


def gi_celebrate():
    body = '<ellipse cx="256" cy="466" rx="100" ry="9" fill="%s"/>' % SHADOW_HOP
    body += grp('sparks', spark(116, 60, 15) + spark(404, 196, 11))
    inner = gi_tail(curl=True)
    # a prancing hop: all four hooves off the ground, both front knees lifted high
    legs = gi_leg([(200, 380), (188, 446)], R_SHADE, hoof_ang=100) + gi_leg([(316, 380), (330, 446)], R_SHADE, hoof_ang=80)
    legs += gi_leg([(226, 376), (190, 404), (204, 436)], R_BODY, hoof_ang=80)
    legs += gi_leg([(290, 376), (326, 404), (312, 436)], R_BODY, hoof_ang=100)
    inner += grp('legs', legs)
    inner += gi_body()
    inner += grp('head', gi_neckhead(eyes='closed', mouth='cheer'), 'rotate(5 258 330)')
    body += grp('body', inner, 'translate(0 -22)')
    anchors = dict(feet=(256, 466), burst=(258, 14))
    return body, anchors


# =========================================================================================================================
HOSTS = [
    # id, file stem, still path, label he/en per pose, room tint, the pose functions, the room's name
    dict(id='goni', still=os.path.join(CAST, 'goni.svg'), tint='#FCE1F0', room='Colour Bay (colors.tint)',
         stillfn=lambda: goni_pose(goni_still), stillLabel='גּוֹנִי – זִקִּית',
         stillNote='redrawn on 2026-11-15 in his recolourable skin (the owner gave him colour; docs/design/m11-rooms.md section 5.2)',
         labels=('גּוֹנִי מְדַבֵּר', 'גּוֹנִי מַרְאֶה', 'גּוֹנִי חוֹגֵג'),
         fns=(lambda: goni_pose(goni_talk), lambda: goni_pose(goni_show), lambda: goni_pose(goni_celebrate)),
         name='Goni the chameleon',
         notes=dict(talk='the near front foot lifted under his chin, toes a little open; mouth open along the jaw',
                    show='the near front foot reaches forward and up as a chameleon reaches for the next twig; the two toe '
                         'bundles open like tongs and the pointer tip is between them; the chin lifts so the leg passes under it',
                    celebrate='a leap with all four feet off the ground, the front feet up, the tail curled high like a flag '
                              'with four spots in his stripe colour, where the rainbow ripple runs'),
         skinNote=('Recolourable skin (docs/design/m11-rooms.md section 5.2): the app maps skin %s, shade %s, belly %s, rim %s '
                   'and stripes %s with flutter_svg ColorMapper; every other colour stays.' % (
                       GONI_SENTINEL['skin'], GONI_SENTINEL['shade'], GONI_SENTINEL['belly'], GONI_SENTINEL['rim'],
                       ' '.join(GONI_SENTINEL['stripe'])))),
    dict(id='kubi', celebrateTop=25, still=os.path.join(CAST, 'kubi.svg'), tint='#DDF3E6', room='Shape Forest',
         labels=('קוּבִּי מְדַבֵּר', 'קוּבִּי מַרְאֶה', 'קוּבִּי חוֹגֵג'), fns=(kubi_talk, kubi_show, kubi_celebrate),
         name='Kubi the tortoise',
         notes=dict(talk='the near forefoot lifted, elbow out, nails up', show='the neck stretched up out of the shell, the '
                    'near forefoot held out level, three blunt nails at the tip', celebrate='a hop, both forefeet up, the '
                    'neck stretched tall, the hat tipped, his shell tiles popping up out of the shell')),
    dict(id='timi', still=os.path.join(CAST, 'timi.svg'), tint='#ECE3FE', room='Riddle Grotto',
         labels=('תִּימִי מְדַבֶּרֶת', 'תִּימִי מַרְאָה', 'תִּימִי חוֹגֶגֶת'), fns=(timi_talk, timi_show, timi_celebrate),
         name='Timi the octopus',
         notes=dict(talk='the glass held out at shoulder height in the end-side arm, the puzzle arm resting low', show='a free '
                    'arm (her lower end-side arm) reaches out level, its tip rolled into a curl and the suckers on its underside; '
                    'the glass waits up by her head', celebrate='"aha!": a hop with every arm up or curling, the glass and '
                    'the puzzle piece held high, bubbles rising')),
    dict(id='tzaadon', celebrateTop=13, still=os.path.join(CAST, 'tzaadon.svg'), tint='#DEEBFC', room='Robot Harbour',
         labels=('צַעֲדוֹן מְדַבֵּר', 'צַעֲדוֹן מַרְאֶה', 'צַעֲדוֹן חוֹגֵג'), fns=(tz_talk, tz_show, tz_celebrate),
         name="Tza'adon the robot",
         notes=dict(talk='elbow bent, the round gripper up and a little open; open screen eyes and an open mouth on the screen',
                    show='the arm held out level, the two jaws of the round gripper open; the tip is between the jaws',
                    celebrate='a hop with both grippers up and open, the chest buttons shining, the antenna springing and '
                              'the sprout opening a third leaf and a bud')),
    dict(id='pnina', celebrateTop=56, still=os.path.join(CAST, 'pnina.svg'), tint='#FEEFD6', room='Market Village', stillfn=pn_still,
         stillLabel='סַבְתָא פְּנִינָה – שַׂקְנַאי',
         labels=('סַבְתָא פְּנִינָה מְדַבֶּרֶת', 'סַבְתָא פְּנִינָה מַרְאָה', 'סַבְתָא פְּנִינָה חוֹגֶגֶת'),
         fns=(pn_talk, pn_show, pn_celebrate), name='Grandma Pnina the pelican',
         notes=dict(talk='the near wing lifted forward with its primaries open like fingers; the upper bill lifts to speak',
                    show='the near wing held out level under her pouch, the long primaries fanned; the tip is the leading '
                         'primary', celebrate='a hop with both wings up and open and a happy head-toss, the bill open')),
    dict(id='host-eng', celebrateTop=51, still=os.path.join(LANG, 'host_eng.svg'), tint='#E1ECF8', room='the English room',
         labels=('host of the English course, talking', 'host of the English course, showing', 'host of the English course, celebrating'),
         fns=(pip_talk, pip_show, pip_celebrate), name='Pip the budgie (English)',
         notes=dict(talk='the end-side wing lifted out and up, its flight feathers open like a raised hand; the beak open',
                    show='the end-side wing held out level, the barred coverts and the fanned flight feathers; the tip is the '
                         'leading primary', celebrate='a hop with both wings up and spread, the yellow wing flash showing '
                         '(the flash shows only when the wing is open), the tail fanned')),
    dict(id='host-heb', celebrateTop=26, still=os.path.join(LANG, 'host_heb.svg'), tint='#FBE4DF', room='the Hebrew room',
         labels=('host of the Hebrew course, talking', 'host of the Hebrew course, showing', 'host of the Hebrew course, celebrating'),
         fns=(hy_talk, hy_show, hy_celebrate), name='the hyrax (Hebrew)',
         notes=dict(talk='the end-side paw lifted beside the cheek with its soft pads showing; the pencil rests in the other paw',
                    show='the end-side paw holds the coral pencil out level; the graphite tip is the pointer',
                    celebrate='a hop with both paws up, the pencil held high like a baton with a coral swirl drawn in the air')),
    dict(id='host-rus', celebrateTop=0, still=os.path.join(LANG, 'host_rus.svg'), tint='#EBE3F7', room='the Russian room',
         labels=('host of the Russian course, talking', 'host of the Russian course, showing', 'host of the Russian course, celebrating'),
         fns=(gi_talk, gi_show, gi_celebrate), name='the giraffe (Russian)',
         notes=dict(talk='the neck leaning toward the task and one front hoof lifted, the knee bent', show='the end-side '
                    'front leg lifted and held out toward the task, the knee a little bent, the cloven hoof at the tip; the '
                    'neck bends so the eyes are on it', celebrate='a prancing hop with both front knees up, the tail curled up '
                    'as a giraffe tail does at a gallop')),
]


BUNDLED = os.path.join(ROOT, 'app', 'assets', 'art', 'hosts')

# The highest point of a celebrate pose (y, artboard units), sparks included. The celebration card's window is shorter than the
# host's box (docs/design/m11-rooms.md section 4: a 150 box in a 140 window, so y < 34 is cut, and the hop lifts it 7% more);
# 72 keeps the whole figure inside the window on the phone and the tablets, at rest and at the top of its hop.
CELEBRATE_TOP = 72


def fit_celebrate(body, anchors, top):
    """Scales a celebrate pose whose highest point (`top`, measured with headless Chrome's getBBox) is above CELEBRATE_TOP about the
    middle of the baseline (256, 472) until it fits. Anchors move with it."""
    if top >= CELEBRATE_TOP:
        return body, anchors
    k = (472 - CELEBRATE_TOP) / (472 - top)
    tr = 'translate(256 472) scale(%.3f) translate(-256 -472)' % k
    anchors = dict((n, (256 + (x - 256) * k, 472 + (y - 472) * k)) for n, (x, y) in anchors.items())
    return grp('fit', body, tr), anchors


def write_svgs(hosts):
    for h in hosts:
        if h.get('stillfn'):
            body, anchors = h['stillfn']()
            anc = '; '.join('%s %d, %d' % (k, v[0], v[1]) for k, v in anchors.items())
            note = h.get('stillNote', '2026-11-15 (QA of M11 Stage 1: she read as a pale goose)')
            skin = ('\n     ' + h['skinNote']) if h.get('skinNote') else ''
            svg = ('<?xml version="1.0" encoding="UTF-8"?>\n<!-- %s, the still (idle). Original drawing in plain shapes, redrawn on '
                   '%s. Written by docs/design/m11/make_host_poses.py; the\n'
                   '     references are in its docstring. Artboard 512, baseline y 472, faces left. Anchors (artboard units): %s.%s -->\n'
                   '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 512 512" role="img" aria-label="%s">\n%s\n</svg>\n') % (
                h['name'], note, anc, skin, h['stillLabel'], body)
            for path in (h['still'], os.path.join(BUNDLED, '%s_idle.svg' % h['id'].replace('-', '_'))):
                with open(path, 'w', encoding='utf-8', newline='\n') as fh:
                    fh.write(svg)
        for pose, fn, label in zip(('talk', 'show', 'celebrate'), h['fns'], h['labels']):
            body, anchors = fn()
            if pose == 'celebrate':
                body, anchors = fit_celebrate(body, anchors, h.get('celebrateTop', CELEBRATE_TOP))
            anc = '; '.join('%s %d, %d' % (k, v[0], v[1]) for k, v in anchors.items())
            head = ('<?xml version="1.0" encoding="UTF-8"?>\n'
                    '<!-- %s, pose "%s" (M11 step 1.2). Original drawing in plain shapes, in the style, proportions and palette of its\n'
                    '     approved still (%s), following Nekudi\'s approved sample (design/assets/nekudi-*.svg). Pose sheet:\n'
                    '     docs/design/m11-rooms.md section 7. Artboard 512, baseline y 472, centre x 256, faces left (celebrate: front).\n'
                    '     %s.\n'
                    '     Anchors (artboard units): %s.\n'
                    '     References (2026-11-14, nothing traced): see the docstring of docs/design/m11/make_host_poses.py, which wrote this file.%s -->\n') % (
                h['name'], pose, os.path.relpath(h['still'], ROOT).replace('\\', '/'), h['notes'][pose], anc,
                ('\n     ' + h['skinNote']) if h.get('skinNote') else '')
            svg = head + ('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 512 512" role="img" aria-label="%s">\n%s\n</svg>\n' % (
                label, body))
            # the bundled copy (Goni's too since 2026-11-15: his recolourable skin replaces the colour-safe files)
            bundled = [os.path.join(BUNDLED, '%s_%s.svg' % (h['id'].replace('-', '_'), pose))]
            for path in [pose_path(h, pose)] + bundled:
                with open(path, 'w', encoding='utf-8', newline='\n') as fh:
                    fh.write(svg)


def pose_path(h, pose):
    return os.path.join(CAST, '%s-%s.svg' % (h['id'], pose))


# ---- sheets -------------------------------------------------------------------------------------------------------------
def uri(p):
    return pathlib.Path(p).as_uri()


def box(x, y, w, h, style='', inner=''):
    return '<div style="position:absolute;left:%.1fpx;top:%.1fpx;width:%.1fpx;height:%.1fpx;box-sizing:border-box;%s">%s</div>' % (
        x, y, w, h, style, inner)


def img(path, x, y, w, h, extra=''):
    return '<img src="%s" style="position:absolute;left:%.1fpx;top:%.1fpx;width:%.1fpx;height:%.1fpx;object-fit:contain;%s">' % (
        uri(path), x, y, w, h, extra)


def render(parts, W, H, out_png):
    doc = '<html><head><meta charset="utf-8"><style>body{margin:0;background:#fff}</style></head><body><div style="position:relative;width:%dpx;height:%dpx">%s</div></body></html>' % (
        W, H, ''.join(parts))
    tmp = tempfile.mkdtemp(prefix='poses_')
    p = os.path.join(tmp, 'p.html')
    with open(p, 'w', encoding='utf-8') as fh:
        fh.write(doc)
    subprocess.run([CHROME, '--headless=new', '--disable-gpu', '--hide-scrollbars', '--force-device-scale-factor=1',
                    '--allow-file-access-from-files', '--virtual-time-budget=6000', '--screenshot=' + out_png,
                    '--window-size=%d,%d' % (W, H), uri(p)], check=True, capture_output=True)
    print(os.path.relpath(out_png, ROOT))


def host_files(h):
    return [(h['still'], 'still (approved)'), (pose_path(h, 'talk'), 'talk'), (pose_path(h, 'show'), 'show (hand out)'),
            (pose_path(h, 'celebrate'), 'celebrate')]


def mapped_copy(path, mapping, tag):
    """A copy of a picture with its colours swapped as the app's ColorMapper will swap them (Goni's skins)."""
    s = open(path, encoding='utf-8').read()
    for a, b in mapping.items():
        s = s.replace(a, b)
    tmp = tempfile.mkdtemp(prefix='skin_')
    out = os.path.join(tmp, '%s_%s' % (tag, os.path.basename(path)))
    open(out, 'w', encoding='utf-8').write(s)
    return out


def _lab(hexc):
    r, g, b = (int(hexc[i:i + 2], 16) / 255 for i in (1, 3, 5))
    lin = [c / 12.92 if c <= 0.04045 else ((c + 0.055) / 1.055) ** 2.4 for c in (r, g, b)]
    x = (0.4124 * lin[0] + 0.3576 * lin[1] + 0.1805 * lin[2]) / 0.95047
    y = 0.2126 * lin[0] + 0.7152 * lin[1] + 0.0722 * lin[2]
    z = (0.0193 * lin[0] + 0.1192 * lin[1] + 0.9505 * lin[2]) / 1.08883
    fx, fy, fz = (t ** (1 / 3) if t > 0.008856 else 7.787 * t + 16 / 116 for t in (x, y, z))
    return 116 * fy - 16, 500 * (fx - fy), 200 * (fy - fz), y


def _contrast(c1, c2):
    l1, l2 = _lab(c1)[3], _lab(c2)[3]
    hi, lo = max(l1, l2), min(l1, l2)
    return (hi + 0.05) / (lo + 0.05)


def goni_checks():
    """Prints the numbers behind section 5.2: the base's distance from every lesson colour, and each skin's rim on the
    room's tint and on its own skin."""
    tint = '#FCE1F0'
    base = GONI_SKINS['mint'][0]
    for name, (sk, sh, st, be, ri) in GONI_SKINS.items():
        L1, a1, b1, _ = _lab(base)
        L2, a2, b2, _ = _lab(sk)
        de = ((L1 - L2) ** 2 + (a1 - a2) ** 2 + (b1 - b2) ** 2) ** 0.5
        print('%-7s dE76 from mint %5.1f | rim on tint %4.1f:1 | rim on skin %4.1f:1 | stripe on skin %4.1f:1' % (
            name, de, _contrast(ri, tint), _contrast(ri, sk), _contrast(st, sk)))


def goni_colours_sheet(out_png):
    """docs/design/m11/goni_colours.png: the four poses in his resting skin on Colour Bay's tint (and on paper and the map's
    cream, where he also stands), then the celebrate pose in every lesson colour and the rainbow ripple frame, then the same
    small and in grey (the outline and the face must read without colour), then the talk pose in the hardest skins."""
    h = HOSTS[0]
    files = host_files(h)
    tint = '#FCE1F0'
    W = 1300
    parts = [box(0, 0, W, 1460, 'background:#FFFFFF')]
    parts.append(box(20, 8, W - 40, 22, 'font:700 16px sans-serif;color:#2B2350',
                     'Goni: resting skin (mint %s) on Colour Bay tint %s; still, talk, show, celebrate at 220 px; '
                     'right: celebrate on paper and on the map cream' % (GONI_SKINS['mint'][0], tint)))
    for i, (fp, lab) in enumerate(files):
        x = 20 + i * 236
        parts.append(box(x, 36, 228, 228, 'background:%s;border-radius:14px' % tint))
        parts.append(img(fp, x + 4, 40, 220, 220))
        parts.append(box(x, 266, 228, 18, 'font:600 13px sans-serif;color:#2B2350;text-align:center', lab.split(' (')[0]))
    for j, bg in enumerate(('#FFFFFF', '#FFF6E8')):
        x = 20 + 4 * 236 + j * 168
        parts.append(box(x, 76, 160, 160, 'background:%s;border-radius:12px;border:1px solid #DDD' % bg))
        parts.append(img(files[3][0], x + 4, 80, 152, 152))
    y0 = 300
    parts.append(box(20, y0, W - 40, 22, 'font:700 16px sans-serif;color:#2B2350',
                     'Celebrate in each lesson colour (the pictures\' own paint), and the rainbow ripple frame; 196 px on the tint'))
    cells = [(n, goni_map(n), n) for n in GONI_SKINS if n != 'mint'] + [('ripple', goni_map('mint', ripple=0), 'rainbow ripple')]
    for k, (tag, mp, lab) in enumerate(cells):
        x = 20 + (k % 6) * 210
        y = y0 + 28 + (k // 6) * 230
        parts.append(box(x, y, 204, 204, 'background:%s;border-radius:12px' % tint))
        parts.append(img(mapped_copy(files[3][0], mp, tag), x + 4, y + 4, 196, 196))
        sw = GONI_SKINS[tag][0] if tag in GONI_SKINS else '#FFFFFF'
        parts.append('<div style="position:absolute;left:%dpx;top:%dpx;width:18px;height:18px;border-radius:9px;background:%s;'
                     'border:2px solid #2B2350"></div>' % (x + 8, y + 182, sw))
        parts.append(box(x, y + 206, 204, 18, 'font:600 13px sans-serif;color:#2B2350;text-align:center', lab))
    y1 = y0 + 28 + 2 * 230 + 8
    parts.append(box(20, y1, W - 40, 22, 'font:700 16px sans-serif;color:#2B2350',
                     'The same at the celebration size on the phone SE (96 px), in colour and in grey (no colour at all)'))
    allc = [('mint', goni_map('mint'))] + [(c[0], c[1]) for c in cells]
    for k, (tag, mp) in enumerate(allc):
        x = 20 + k * 98
        parts.append(box(x, y1 + 28, 94, 94, 'background:%s;border-radius:8px' % tint))
        parts.append(img(mapped_copy(files[3][0], mp, tag + 's'), x, y1 + 28, 94, 94))
        parts.append(box(x, y1 + 128, 94, 94, 'background:%s;border-radius:8px;filter:grayscale(1)' % tint))
        parts.append(img(mapped_copy(files[3][0], mp, tag + 'g'), x, y1 + 128, 94, 94, 'filter:grayscale(1)'))
    y2 = y1 + 236
    parts.append(box(20, y2, W - 40, 22, 'font:700 16px sans-serif;color:#2B2350',
                     'The praise pose (talk) and the still in the hardest skins: white, black, yellow, grey, pink; on the tint and on the bay\'s sand'))
    k = 0
    for tag in ('white', 'black', 'yellow', 'grey', 'pink'):
        for fp, bg in ((files[1][0], tint), (files[0][0], '#F6DFA6')):
            x = 20 + k * 126
            parts.append(box(x, y2 + 28, 120, 120, 'background:%s;border-radius:10px' % bg))
            parts.append(img(mapped_copy(fp, goni_map(tag), tag + 't'), x, y2 + 28, 120, 120))
            k += 1
    parts.append(box(20, y2 + 160, W - 40, 40, 'font:600 12px/1.4 sans-serif;color:#B23A3A', htmlmod.escape(
        'Every skin is a colour mapping of the same four files (the app: flutter_svg ColorMapper, sentinel colours in the files\' '
        'header). Eyes, mouth, cheek, beret, sparks and shadow never change.')))
    render(parts, W, y2 + 210, out_png)


def host_sheet(h, out_png):
    parts = []
    files = host_files(h)
    W = 4 * 300 + 40
    H = 560  # (Goni's colour-safe row retired on 2026-11-15: goni_colours.png shows his skins)
    parts.append(box(0, 0, W, H, 'background:#FFF6E8'))
    for i, (fp, lab) in enumerate(files):
        x = 20 + i * 300
        parts.append(box(x, 10, 280, 280, 'background:#fff;border-radius:16px'))
        parts.append('<svg style="position:absolute;left:%dpx;top:10px;width:280px;height:280px"><path d="M0 %g H280" stroke="#B23A3A" '
                     'stroke-width="1" stroke-dasharray="4 4"/><path d="M140 0 V280" stroke="#B23A3A" stroke-width="1" '
                     'stroke-dasharray="2 6" opacity=".5"/></svg>' % (x, 472 / 512 * 280))
        parts.append(img(fp, x, 10, 280, 280))
        parts.append(box(x, 294, 280, 20, 'font:600 14px sans-serif;color:#2B2350;text-align:center', htmlmod.escape(lab)))
        parts.append(box(x + 6, 322, 180, 180, 'background:%s;border-radius:12px' % h['tint']))
        parts.append(img(fp, x + 12, 328, 168, 168))
        parts.append(box(x + 200, 380, 60, 60, 'background:#fff;border-radius:8px'))
        parts.append(img(fp, x + 206, 386, 48, 48, 'filter:brightness(0)'))
    cap = ('Top: 280 px, dashed line = baseline y 472 of 512, dotted = centre x 256. Below: the phone host size (168) on the room\'s '
           'tint (%s), and a 48 pt black silhouette (design-spec 4.9.3). Only the poses are new; the still is the approved art.' % h['room'])
    parts.append(box(20, H - 52, W - 40, 48, 'font:600 12px/1.4 sans-serif;color:#B23A3A', htmlmod.escape(cap)))
    render(parts, W, H, out_png)


def all_sheet(out_png):
    rows = [dict(id='nekudi', still=os.path.join(CAST, 'nekudi.svg'), tint='#FFE3DF', name='Nekudi the ladybird (approved sample)')] + HOSTS
    cw, gap = 150, 8
    bw = 4 * (cw + gap) + 24
    cols = 3
    bh = cw + 56
    W = cols * bw + 20
    H = ((len(rows) + cols - 1) // cols) * bh + 60
    parts = [box(0, 0, W, H, 'background:#FFF6E8')]
    for k, h in enumerate(rows):
        bx, by = 10 + (k % cols) * bw, 10 + (k // cols) * bh
        parts.append(box(bx + 4, by, bw - 8, bh - 8, 'background:#fff;border-radius:14px'))
        parts.append(box(bx + 14, by + 6, bw - 28, 18, 'font:700 13px sans-serif;color:#2B2350', htmlmod.escape(h['name'])))
        for i, (fp, lab) in enumerate(host_files(h)):
            x = bx + 12 + i * (cw + gap)
            parts.append(box(x, by + 28, cw, cw, 'background:%s;border-radius:10px' % h['tint']))
            parts.append(img(fp, x, by + 28, cw, cw))
            parts.append(box(x, by + 28 + cw + 2, cw, 14, 'font:600 11px sans-serif;color:#5A5378;text-align:center', lab.split(' (')[0]))
    parts.append(box(20, H - 44, W - 40, 40, 'font:600 12px/1.4 sans-serif;color:#B23A3A', htmlmod.escape(
        'The nine hosts of M11: the still and the three poses (talk, show, celebrate), each on its room\'s tint, 150 px. '
        'Nekudi\'s are the approved sample; the other 24 follow it.')))
    render(parts, W, H, out_png)


def nekudi_row():
    return dict(id='nekudi')


def main():
    only = [a for a in sys.argv[1:] if not a.startswith('--')]
    hosts = [h for h in HOSTS if not only or h['id'] in only]
    if '--sheets' not in sys.argv:
        write_svgs(hosts)
    for h in hosts:
        host_sheet(h, os.path.join(HERE, '%s_poses.png' % h['id'].replace('-', '_')))
        if h['id'] == 'goni':
            goni_checks()
            goni_colours_sheet(os.path.join(HERE, 'goni_colours.png'))
    if not only:
        all_sheet(os.path.join(HERE, 'all_host_poses.png'))


if __name__ == '__main__':
    main()
