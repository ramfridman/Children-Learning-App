"""Constants and small helpers the recipes of tools/lang_pack.py share (see lang_recipes.py)."""
import re

DOMAIN = 'languages'
REPRESENTATIONS = ('concrete', 'pictorial', 'story', 'embodied', 'symbolic')
PURPOSES = ('learn', 'practice', 'probe', 'repair', 'check')
CHECK_TYPES = ('practice', 'transfer', 'reverse', 'error_spotting', 'explain_back', 'predict')
HINT_ACTIONS = ('replay_prompt_slow', 'highlight_objects_sequentially', 'show_fingers', 'worked_example')

# Band A has no reading (band-a-build.md 7.2 and 7.6): no step prints a target-language word and no bin a printed word, except in the
# skills whose content is letters, the child's own name and print.
LETTER_SKILLS_OF_BAND_A = ('HEB-A-10', 'HEB-A-11', 'HEB-A-12')

# The Hebrew a screen reader says of an activity when the item gives none (adult text: needs-editor like every generated text).
ALT = {
    'tap_answer': {2: 'שְׁתֵּי תְּמוּנוֹת', 3: 'שָׁלוֹשׁ תְּמוּנוֹת'},
    'listen_do': 'תְּמוּנָה וְחָבֵר שֶׁעוֹשֶׂה מַה שֶּׁאוֹמְרִים',
    'puppet_talk': 'בֻּבָּה שֶׁמְּדַבֶּרֶת',
    'say_it': 'תְּמוּנָה וּמִלָּה לוֹמַר',
    'sing_along': 'תְּמוּנוֹת שֶׁל שִׁיר',
    'sound_boxes': 'תּוֹף וְתְמוּנָה שֶׁל מִלָּה',
    'story': 'סִפּוּר בִּתְמוּנוֹת',
    'count_tap': 'עֲצָמִים לִסְפֹּר',
    'sort_drag': 'תְּמוּנוֹת וְקֻפְסָאוֹת לְמִיּוּן',
    'match_pairs': 'זוּגוֹת לְחַבֵּר',
    'build_pattern': 'תְּמוּנוֹת לְסַדֵּר',
    'trace': 'דֶּרֶךְ לָלֶכֶת עָלֶיהָ בְּאֶצְבַּע',
}
PAGE_ALT = 'עַמּוּד בַּסִּפּוּר'
PICTURE_LABEL = 'תְּמוּנָה'
SOUND_LABEL = 'צְלִיל'
# What a screen reader says of a place of a command (adult text, needs-editor).
PLACE_LABELS = {'on': 'עַל', 'under': 'מִתַּחַת', 'by': 'לְיַד', 'in': 'בְּתוֹךְ', 'big': 'הַגָּדוֹל', 'small': 'הַקָּטָן'}

# A touch area of a Band A command is at least this share of the picture's side (validator: minBandAHotspot).
MIN_SHARE = 0.2812

# The rail where the things of a drag wait, left of the scene, and the places of the first three (the fixture layout of the tests).
RAIL = [(0.02, 0.05), (0.02, 0.355), (0.02, 0.66)]
RAIL_SIDE = 0.29


def slug(text):
    return re.sub(r'[^a-z0-9]+', '-', text.lower()).strip('-')


def rect(r):
    """[x, y, w, h] as the schema's place."""
    return {'x': round(r[0], 4), 'y': round(r[1], 4), 'w': round(r[2], 4), 'h': round(r[3], 4)}


def overlap(a, b, eps=0.001):
    return a[0] < b[0] + b[2] - eps and b[0] < a[0] + a[2] - eps and a[1] < b[1] + b[3] - eps and b[1] < a[1] + a[3] - eps


def derived_svg(how, source):
    """The bytes of a picture the generator makes: a thing on a soft gold glow (`lit`, from the thing's own picture), or nothing (`blank`)."""
    head = '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 256 256" width="256" height="256">'
    if how == 'blank' or source is None:
        return (head + '</svg>\n').encode('utf-8')
    text = source.decode('utf-8')
    inner = text[text.index('>', text.index('<svg')) + 1:text.rindex('</svg>')]
    glow = ('<circle cx="128" cy="128" r="124" fill="#FFE27A" opacity="0.35"/><circle cx="128" cy="128" r="104" fill="#FFD84D" '
            'opacity="0.45"/>')
    return (head + glow + inner + '</svg>\n').encode('utf-8')
