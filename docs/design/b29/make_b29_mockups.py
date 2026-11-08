"""Mockups of docs/design/b29-steps5-6.md (B-29 steps 5 and 6), rendered by headless Chrome into docs/design/b29/*.png.

    python -I docs/design/b29/make_b29_mockups.py

Step 5 (parent area): the child form with the month-and-year pickers and the school stage, the child's settings page with the
"age and school stage" and "screens" cards (the look letter and the captions setting), and the parent area's September and
"add the age" cards. Adult UI, Heebo, no nikud, the parent's visual language of app/test/goldens/parent_language_page_eng_phone.png.

Step 6 (presentation by stage): one counting item on the four boards at the four presentation stages P1 to P4, and the first
idle prompt. The stage pictures are cut from the app's own goldens (lesson_1_red_flower_*; the mockup's question and tiles are a counting item drawn over that stage); the controls, the guide and
the hand are the app's own SVGs; the bubble, the tiles and the hit areas are drawn to this spec's numbers.

Labels in English and the dashed hit areas are for the team, never in the app. No drawing of a real thing is made here, so no
outside reference was needed.
"""
import os
import pathlib
import subprocess
import tempfile

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.normpath(os.path.join(HERE, '..', '..', '..'))
GOLD = os.path.join(ROOT, 'app', 'test', 'goldens')
UI = os.path.join(ROOT, 'app', 'assets', 'art', 'ui')
HINTS = os.path.join(ROOT, 'app', 'assets', 'art', 'hints')
CAST = os.path.join(ROOT, 'design', 'assets')
FONT = os.path.join(ROOT, 'app', 'assets', 'fonts', 'Heebo-Variable.ttf')
CHROME = r'C:\Program Files\Google\Chrome\Application\chrome.exe'

INK, INK_SOFT, NIGHT, SEA, PARENT_BG, PAPER, HAIRLINE, CREAM, LIP = (
    '#2B2350', '#5A5378', '#3B2C85', '#1A9E9A', '#F6F1FA', '#FFFFFF', '#E6DDF0', '#FFF6E8', '#DCD3EC')
SEA_TINT, SKY_TINT, TEAM = '#DDF3F2', '#E3F4FC', '#B23A3A'


def uri(p):
    return pathlib.Path(p).as_uri()


HEAD = """<!doctype html><html><head><meta charset="utf-8"><style>
@font-face { font-family: Heebo; src: url('%s'); font-weight: 100 900; }
* { box-sizing: border-box; margin: 0; padding: 0; }
body { font-family: Heebo, sans-serif; color: %s; background: #FFFFFF; }
</style></head><body>""" % (uri(FONT), INK)


def render(name, html, w, h):
    out = os.path.join(HERE, name)
    with tempfile.NamedTemporaryFile('w', suffix='.html', delete=False, encoding='utf-8') as f:
        f.write(HEAD + html + '</body></html>')
        path = f.name
    subprocess.run([CHROME, '--headless=new', '--disable-gpu', '--hide-scrollbars', '--force-device-scale-factor=1',
                    '--allow-file-access-from-files', '--virtual-time-budget=3000',
                    '--screenshot=' + out, '--window-size=%d,%d' % (w, h), uri(path)], check=True,
                   stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    os.unlink(path)
    print('wrote', out)


# ---------------------------------------------------------------------------------------------------------------------------
# Step 5: the parent area
# ---------------------------------------------------------------------------------------------------------------------------

CHECK = ('<svg width="16" height="16" viewBox="0 0 24 24" style="margin-inline-end:6px"><path d="M4 12.5 L10 18 L20 6" '
         'fill="none" stroke="#FFFFFF" stroke-width="3" stroke-linecap="round" stroke-linejoin="round"/></svg>')


def chip(text, selected=False, ltr=False):
    d = ' dir="ltr"' if ltr else ''
    if selected:
        return ('<span class="chip sel"><span style="display:inline-flex;align-items:center">%s<span%s>%s</span></span></span>'
                % (CHECK, d, text))
    return '<span class="chip"><span%s>%s</span></span>' % (d, text)


PARENT_CSS = """<style>
.page { background: %(bg)s; direction: rtl; min-height: 100%%; }
.bar { height: 56px; background: %(night)s; color: #fff; display: flex; align-items: center; padding: 0 16px; gap: 24px; }
.bar .t { font-size: 20px; font-weight: 700; }
.col { margin: 0 auto; padding: 16px; }
.card { background: #fff; border: 2px solid %(hair)s; border-radius: 16px; padding: 16px; margin-bottom: 16px; }
.h1 { font-size: 28px; font-weight: 800; line-height: 1.3; }
.h2 { font-size: 20px; font-weight: 700; line-height: 1.35; margin-bottom: 8px; }
.h3 { font-size: 16px; font-weight: 700; line-height: 1.5; }
.lab { font-size: 16px; font-weight: 700; line-height: 1.4; padding: 20px 0 8px; }
.sub { font-size: 13px; font-weight: 700; color: %(soft)s; padding: 10px 0 6px; }
.small { font-size: 13px; font-weight: 500; line-height: 1.45; color: %(soft)s; }
.body { font-size: 16px; font-weight: 400; line-height: 1.5; }
.chips { display: flex; flex-wrap: wrap; gap: 8px; }
.grid { display: grid; gap: 8px; } .g4 { grid-template-columns: repeat(4, 1fr); } .g3 { grid-template-columns: repeat(3, 1fr); }
.grid .chip { padding: 0 6px; }
.chip { height: 40px; min-width: 48px; padding: 0 14px; border: 1.5px solid %(ink)s; border-radius: 8px; display: inline-flex;
        align-items: center; justify-content: center; font-size: 15px; font-weight: 700; background: #fff; }
.chip.sel { background: %(sea)s; border-color: %(sea)s; color: #fff; }
.btn { height: 44px; min-width: 88px; padding: 0 20px; border-radius: 12px; display: inline-flex; align-items: center;
       justify-content: center; font-size: 16px; font-weight: 700; background: %(night)s; color: #fff; }
.btn.q { background: #fff; color: %(night)s; border: 2px solid %(night)s; }
.btn.small { height: 36px; min-width: 64px; font-size: 14px; padding: 0 12px; }
.field { height: 52px; border: 1px solid %(soft)s; border-radius: 4px; background: #fff; padding: 0 12px; display: flex;
         align-items: center; font-size: 16px; }
.note { background: %(seatint)s; border-radius: 12px; padding: 10px 12px; margin-top: 10px; font-size: 13px; font-weight: 500;
        line-height: 1.45; color: %(ink)s; display: flex; gap: 8px; align-items: flex-start; }
.status { margin-top: 8px; font-size: 13px; font-weight: 700; color: %(ink)s; }
.div { height: 1px; background: %(hair)s; margin: 14px 0; }
.row { display: flex; align-items: center; gap: 12px; }
.grow { flex: 1; }
.av { width: 70px; height: 70px; border-radius: 50%%; padding: 3px; border: 3px solid transparent; }
.av.sel { border-color: %(night)s; }
.cb { width: 18px; height: 18px; border-radius: 3px; background: %(night)s; display: inline-block; margin: 0 4px 0 16px; }
.bottom { display: flex; justify-content: center; gap: 12px; padding: 8px 16px 12px; background: %(bg)s;
          border-top: 1px solid %(hair)s; }
.team { position: absolute; left: 0; right: 0; border-top: 2px dashed %(team)s; direction: ltr; font: 12px sans-serif;
        color: %(team)s; padding: 2px 6px; }
</style>""" % dict(bg=PARENT_BG, night=NIGHT, hair=HAIRLINE, soft=INK_SOFT, ink=INK, sea=SEA, seatint=SEA_TINT, team=TEAM)

YEARS = [str(y) for y in range(2017, 2025)]  # DOM order = reading order: the earliest at the start (right)
MONTHS = ['ינואר', 'פברואר', 'מרץ', 'אפריל', 'מאי', 'יוני', 'יולי', 'אוגוסט', 'ספטמבר', 'אוקטובר', 'נובמבר', 'דצמבר']
STAGES = ['גן טרום־טרום חובה', 'גן טרום חובה', 'גן חובה', 'כיתה א׳', 'כיתה ב׳', 'כיתה ג׳ ומעלה']

INFO = ('<svg width="18" height="18" viewBox="0 0 24 24" style="flex:none;margin-top:1px"><circle cx="12" cy="12" r="10" '
        'fill="%s"/><rect x="11" y="10" width="2.4" height="8" rx="1.2" fill="#fff"/><circle cx="12.2" cy="6.8" r="1.5" '
        'fill="#fff"/></svg>' % SEA)
CAL = ('<svg width="28" height="28" viewBox="0 0 24 24" style="flex:none"><rect x="3" y="5" width="18" height="16" rx="3" '
       'fill="#fff" stroke="%s" stroke-width="2"/><rect x="3" y="5" width="18" height="5" rx="2" fill="%s"/><rect x="7" y="2.5" '
       'width="2" height="5" rx="1" fill="%s"/><rect x="15" y="2.5" width="2" height="5" rx="1" fill="%s"/><circle cx="12" '
       'cy="15.5" r="2.3" fill="#FFC83D"/></svg>' % (NIGHT, NIGHT, NIGHT, NIGHT))


def age_fields(year='2021', month='מרץ', stage=2, suggested=True, compact=False):
    """The one widget the form and the settings page share (AgeFields): month and year, then the school stage."""
    out = []
    out.append('<div class="lab">חודש ושנת לידה <span class="small" style="font-weight:500">(לא חובה)</span></div>')
    out.append('<div class="small">נשמר בחשבון המשפחה כדי שמכשיר חדש יכיר אותו, ולא נמסר לאף אחד. בעזרתו המסכים מתאימים לגיל.</div>')
    out.append('<div class="sub">שנה</div><div class="grid g4">%s</div>' % ''.join(chip(y, y == year, ltr=True) for y in YEARS))
    out.append('<div class="sub">חודש</div><div class="grid g4">%s</div>' % ''.join(chip(m, m == month) for m in MONTHS))
    if year:
        out.append('<div style="margin-top:8px"><span class="btn q small">ניקוי</span></div>')
    out.append('<div class="lab">שלב הלימודים השנה</div>')
    out.append('<div class="small">קובע מאיפה מתחילים בכל אי. משם הילד מתקדם לפי מה שהוא יודע.</div>')
    out.append('<div class="grid g3" style="margin-top:10px">%s</div>' % ''.join(chip(s, i == stage) for i, s in enumerate(STAGES)))
    if suggested:
        out.append('<div class="note">%s<span>לפי שנת הלידה הצענו גן חובה. אפשר לשנות, למשל אם הילד נשאר שנה נוספת '
                   'בגן חובה.</span></div>' % INFO)
    return ''.join(out)


def form_page(width, maxw=520):
    avatars = ''.join('<img class="av%s" src="%s">' % (' sel' if i == 1 else '', uri(os.path.join(CAST, a)))
                      for i, a in enumerate(['avatar-itai.svg', 'avatar-noa.svg', 'avatar-tamar.svg']))
    langs = ''.join('<div class="row" style="height:48px"><span class="cb"></span><span class="body">%s</span></div>' % t
                    for t in ['אנגלית', 'עברית: אותיות וצלילים', 'רוסית'])
    inner = (
        '<div class="h1">הוספת ילד או ילדה</div>'
        '<div class="lab">שם</div><div class="field">נועה</div>'
        + age_fields() +
        '<div class="lab">בחירת דמות</div><div class="row">%s</div>' % avatars +
        '<div class="lab">פנייה בלשון</div><div class="chips">%s%s%s</div>' % (chip('נקבה', True), chip('זכר'), chip('רבים')) +
        '<div class="lab">שפות</div><div class="small">אפשר לשנות אחר כך בהגדרות.</div>' + langs)
    return ('%s<div class="page" style="width:%dpx"><div class="col" style="max-width:%dpx">%s</div>'
            '<div class="bottom"><span class="btn q">חזרה</span><span class="btn">שמירה</span></div></div>'
            % (PARENT_CSS, width, maxw, inner))


def settings_page(width, title='ההגדרות של נועה', look=None, reading=0, second=False):
    looks = ['לפי הגיל', 'גילאי 3 עד 4', 'גילאי 5 עד 6', 'גילאי 7 עד 8']
    reads = ['לפי שלב הלימודים', 'להציג', 'להסתיר']
    card1 = ('<div class="card"><div class="h2">גיל ושלב לימודים</div>'
             '<div class="row" style="min-height:48px"><div class="grow"><div class="h3">שלב הלימודים</div>'
             '<div class="body">גן חובה</div></div></div>'
             '<div class="div" style="margin:8px 0"></div>'
             '<div class="row" style="min-height:48px"><div class="grow"><div class="h3">חודש ושנת לידה</div>'
             '<div class="body">מרץ 2021</div></div></div>'
             '<div style="margin-top:12px"><span class="btn q">שינוי</span></div></div>')
    card2 = ('<div class="card"><div class="h2">התאמת המסכים</div>'
             '<div class="h3">המראה במסכים</div>'
             '<div class="small">ברירת המחדל לפי הגיל. אפשר לבחור מראה של קבוצת גיל אחרת: כמה תשובות יש על המסך, גודל הכתב '
             'ואורך החגיגות. השיעורים עצמם לא משתנים.</div>'
             '<div class="chips" style="margin-top:10px">%s</div>'
             '<div class="status">עכשיו: מראה של גילאי 5 עד 6</div>'
             '<div class="div"></div>'
             '<div class="h3">כתוביות לשאלות</div>'
             '<div class="small">ניצי תמיד מקריאה את השאלה. מספרים ושם הילד מופיעים תמיד. ההגדרה הזאת נשמרת רק במכשיר הזה.</div>'
             '<div class="chips" style="margin-top:10px">%s</div>'
             '<div class="status">עכשיו: מוצגות (גן חובה)</div></div>'
             % (''.join(chip(t, (look is None and i == 0) or look == i) for i, t in enumerate(looks)),
                ''.join(chip(t, i == reading) for i, t in enumerate(reads))))
    card3 = ('<div class="card"><div class="h2">שפות</div><div class="small">דלת לכל שפה באי השפות.</div>'
             '<div class="div"></div><div class="row"><span class="body grow">אנגלית</span><span class="btn q small">הגדרות</span></div>'
             '<div class="div"></div><div class="row"><span class="body grow">עברית</span><span class="btn q small">הגדרות</span></div>'
             '</div>')
    return ('%s<div class="page" style="width:%dpx"><div class="bar"><span style="font-size:24px">&#8594;</span>'
            '<span class="t">%s</span></div><div class="col" style="max-width:640px">%s%s%s</div></div>'
            % (PARENT_CSS, width, title, card1, card2, card3))


def age_page(width):
    note = ('<div class="note">%s<span>השינוי יחול מהפעם הבאה שהילד ישחק. השיעורים שכבר נלמדו וההתקדמות נשארים.</span></div>'
            % INFO)
    return ('%s<div class="page" style="width:%dpx"><div class="bar"><span style="font-size:24px">&#8594;</span>'
            '<span class="t">גיל ושלב לימודים: נועה</span></div><div class="col" style="max-width:640px">%s%s</div>'
            '<div class="bottom"><span class="btn q">ביטול</span><span class="btn">שמירה</span></div></div>'
            % (PARENT_CSS, width, age_fields(suggested=False), note))


def area_page(width):
    sept = ('<div class="card" style="border-color:%s"><div class="row" style="align-items:flex-start">%s<div class="grow">'
            '<div class="h2" style="margin-bottom:4px">שנת לימודים חדשה</div>'
            '<div class="body">נועה עולה לכיתה א׳?</div>'
            '<div class="small" style="margin-top:4px">השיעורים שכבר נלמדו נשארים. השינוי יחול מהפעם הבאה שהילד ישחק.</div>'
            '<div class="row" style="margin-top:12px;flex-wrap:wrap;gap:8px"><span class="btn">כן, כיתה א׳</span>'
            '<span class="btn q">להשאיר בגן חובה</span><span class="btn q">שלב אחר</span></div></div></div></div>'
            % (SEA, CAL))
    add = ('<div class="card"><div class="h2" style="margin-bottom:4px">התאמה לגיל: איתי</div>'
           '<div class="body">אפשר להוסיף חודש ושנת לידה ולאשר את שלב הלימודים, כדי שהמסכים יתאימו לגיל. לא חובה.</div>'
           '<div class="row" style="margin-top:12px;gap:8px"><span class="btn">להוספה</span><span class="btn q">לא עכשיו</span></div></div>')
    rest = ('<div class="card"><div class="h2">התראות</div><span class="btn q">לפתוח את ההתראות</span></div>'
            '<div class="card"><div class="h2">ילדים</div><div class="row"><span class="body grow">נועה</span>'
            '<span class="btn q small">התקדמות</span><span class="btn small" style="background:#B4233A">הסרה</span></div>'
            '<div style="margin-top:6px"><span class="btn q small">הגדרות</span></div></div>')
    return ('%s<div class="page" style="width:%dpx"><div class="bar"><span style="font-size:20px">&#128274;</span>'
            '<span class="t">אזור ההורים</span></div><div class="col">%s%s%s</div></div>' % (PARENT_CSS, width, sept, add, rest))


def screen_line(y, text):
    return '<div class="team" style="top:%dpx">%s</div>' % (y, text)


def parent_mocks():
    render('p5_form_phone.png', '<div style="position:relative">%s%s</div>'
           % (form_page(852), screen_line(393 - 64, 'phone screen: what shows before scrolling (393 pt, less the 64 pt button bar)')),
           852, 1300)
    render('p5_form_phoneSE.png', '<div style="position:relative">%s%s</div>'
           % (form_page(667), screen_line(375 - 64, 'phone SE screen (375 pt, less the button bar)')), 667, 1330)
    render('p5_form_tabletPortrait.png', form_page(820), 820, 1300)
    render('p5_settings_phone.png', '<div style="position:relative">%s%s</div>'
           % (settings_page(852), screen_line(393, 'phone screen (393 pt)')), 852, 1010)
    render('p5_settings_tabletLandscape.png', settings_page(1180), 1180, 1010)
    render('p5_age_page_phone.png', '<div style="position:relative">%s%s</div>'
           % (age_page(852), screen_line(393 - 64, 'phone screen (393 pt, less the button bar)')), 852, 900)
    render('p5_area_cards_phone.png', '<div style="position:relative">%s%s</div>'
           % (area_page(852), screen_line(393, 'phone screen (393 pt)')), 852, 760)


# ---------------------------------------------------------------------------------------------------------------------------
# Step 6: presentation by stage
# ---------------------------------------------------------------------------------------------------------------------------

# The activity frame of each board (app/lib/child/activity_shell.dart, ActivitySpec), in board points.
BOARDS = {
    'phone': dict(W=852, H=393, ctrl=64, top=12, eye=59, hint=147, home=59, trail=(266, 26), stage=(71, 96, 330, 128),
                  nitzi=(617, 80, 176), bubble=dict(left=413, top=104, w=190), tiles=(71, 244, 534),
                  gold='lesson_1_red_flower_phone.png', gstage=(71, 96, 330, 128)),
    'phoneSE': dict(W=667, H=375, ctrl=64, top=8, eye=16, hint=96, home=16, trail=(256, 22), stage=(16, 86, 270, 104),
                    nitzi=(490, 66, 150), bubble=dict(left=300, top=92, w=176), tiles=(8, 214, 480),
                    gold='lesson_1_red_flower_phone.png', gstage=(71, 96, 330, 128)),
    'tabletLandscape': dict(W=1180, H=820, ctrl=72, top=24, eye=24, hint=112, home=24, trail=(512, 38), stage=(288, 230, 584, 306),
                            nitzi=(896, 150, 260), bubble=dict(right=224, top=112, w=600), tiles=(288, 554, 584),
                            gold='lesson_1_red_flower_tablet_landscape.png', gstage=(288, 230, 584, 306)),
    'tabletPortrait': dict(W=820, H=1180, ctrl=72, top=32, eye=24, hint=112, home=24, trail=(332, 46), stage=(24, 372, 772, 306),
                           nitzi=(596, 112, 200), bubble=dict(right=224, top=152, w=440), tiles=(24, 696, 772),
                           gold='lesson_1_red_flower_tablet_portrait.png', gstage=(24, 372, 772, 306)),
}

# This spec's numbers per stage (section 6.2 of b29-steps5-6.md): tile drawn size, gap, slop and numeral per (phone, tablet);
# caption size per board; captions shown by the school stage's default reading setting.
STAGE = {
    'P1': dict(tile=(96, 112), gap=(32, 32), slop=(16, 16), num=(56, 72), cap=None, n=3, age='up to 3;5', school='gan 3'),
    'P2': dict(tile=(96, 112), gap=(32, 32), slop=(16, 16), num=(56, 72), cap=None, n=3, age='3;6 to 4;11', school='gan 4'),
    'P3': dict(tile=(88, 104), gap=(24, 24), slop=(12, 12), num=(48, 64), cap=dict(phone=24, phoneSE=22, tabletLandscape=30,
               tabletPortrait=30), n=4, age='5;0 to 6;5', school='gan hova / grade 1'),
    'P4': dict(tile=(80, 96), gap=(20, 16), slop=(10, 8), num=(40, 56), cap=dict(phone=22, phoneSE=20, tabletLandscape=28,
               tabletPortrait=28), n=5, age='6;6 and up', school='grade 2 / 3'),
}
QUESTION = 'כַּמָּה פְּרָחִים יֵשׁ בַּשָּׂדֶה?'


def crop(src, sx, sy, sw, sh, dx, dy, dw, dh, iw, ih):
    kx, ky = dw / sw, dh / sh
    return ('<div style="position:absolute;left:%spx;top:%spx;width:%spx;height:%spx;background:url(\'%s\') no-repeat;'
            'background-size:%spx %spx;background-position:%spx %spx"></div>'
            % (dx, dy, dw, dh, uri(src), iw * kx, ih * ky, -sx * kx, -sy * ky))


def pebble(x, y, s, icon, isz):
    return ('<div style="position:absolute;left:%spx;top:%spx;width:%spx;height:%spx;border-radius:50%%;background:#fff;'
            'box-shadow:0 6px 0 %s, 0 2px 6px rgba(43,35,80,0.10);display:flex;align-items:center;justify-content:center">'
            '<img src="%s" style="width:%spx;height:%spx"></div>' % (x, y, s, s, LIP, uri(os.path.join(UI, icon)), isz, isz))


def trail(x, y):
    dots = ''.join('<span style="width:20px;height:20px;border-radius:50%%;background:%s;display:inline-block"></span>' % '#EDE6F7'
                   for _ in range(3))
    return ('<div style="position:absolute;left:%spx;top:%spx;height:36px;padding:0 10px;border-radius:18px;background:#fff;'
            'display:flex;gap:8px;align-items:center">%s<span style="width:20px;height:20px;border-radius:50%%;border:2px solid %s;'
            'display:inline-block"></span><img src="%s" style="width:22px;height:22px"></div>'
            % (x, y, dots, INK, uri(os.path.join(UI, 'spark.svg'))))


SPEAKER = ('<svg width="34" height="34" viewBox="0 0 24 24"><path d="M3 9 H7 L12 5 V19 L7 15 H3 Z" fill="%s"/>'
           '<path d="M15.5 9 Q17.5 12 15.5 15" fill="none" stroke="%s" stroke-width="2" stroke-linecap="round"/>'
           '<path d="M18 6.5 Q21.5 12 18 17.5" fill="none" stroke="%s" stroke-width="2" stroke-linecap="round"/></svg>'
           % (INK, INK, INK))


def tail(x, y):
    return ('<div style="position:absolute;left:%spx;top:%spx;width:0;height:0;border-top:10px solid transparent;'
            'border-bottom:10px solid transparent;border-left:14px solid #fff"></div>' % (x, y))


def bubble(b, B, stage, idle=False):
    S = STAGE[stage]
    bb = B['bubble']
    if S['cap'] is None:
        # Captions hidden: a speaker bubble (64, the speakerBubble token of Band A) at the end of the bubble's place, by the mouth.
        s = 64 if b.startswith('phone') else 72
        right_edge = (bb['left'] + bb['w']) if 'left' in bb else B['W'] - bb['right']
        x, y = right_edge - s, bb['top'] + 8
        ring = ''
        if idle:
            ring = ''.join('<div style="position:absolute;left:%spx;top:%spx;width:%spx;height:%spx;border-radius:50%%;'
                           'border:3px solid %s;opacity:%s"></div>' % (x - d, y - d, s + 2 * d, s + 2 * d, '#8FD3F4', o)
                           for d, o in ((8, 0.9), (16, 0.45)))
        return (ring + '<div style="position:absolute;left:%spx;top:%spx;width:%spx;height:%spx;border-radius:50%%;background:#fff;'
                'box-shadow:0 6px 0 %s;display:flex;align-items:center;justify-content:center">%s</div>%s'
                % (x, y, s, s, LIP, SPEAKER, tail(x + s - 4, y + s / 2 - 10)))
    size = S['cap'][b]
    pos = ('left:%spx;' % bb['left']) if 'left' in bb else ('right:%spx;' % bb['right'])
    right_edge = (bb['left'] + bb['w']) if 'left' in bb else B['W'] - bb['right']
    box = ('<div style="position:absolute;%stop:%spx;max-width:%spx;%sbackground:#fff;border-radius:24px;padding:8px 16px;'
           'box-shadow:0 6px 0 %s;direction:rtl;font-size:%spx;font-weight:500;line-height:1.7;color:%s">%s</div>'
           % (pos, bb['top'], bb['w'], 'width:%spx;' % bb['w'] if 'left' in bb else '', LIP, size, INK, QUESTION))
    return box + tail(right_edge - 2, bb['top'] + 22)


def tiles(b, B, stage, labels=True):
    S = STAGE[stage]
    k = 0 if b.startswith('phone') else 1
    t, g, sl, num, n = S['tile'][k], S['gap'][k], S['slop'][k], S['num'][k], S['n']
    x0, y0, w0 = B['tiles']
    total = n * t + (n - 1) * g
    left = x0 + (w0 - total) / 2
    out = []
    values = list(range(2, 2 + n)) if n < 5 else list(range(1, 6))
    for i in range(n):
        x = left + total - t - i * (t + g)  # the first value at the start (right), as the app's tile row
        v = values[i]
        dots = ''.join('<span style="width:%spx;height:%spx;border-radius:50%%;background:%s;display:inline-block;margin:0 1.5px">'
                       '</span>' % (t * 0.08, t * 0.08, INK_SOFT) for _ in range(v))
        out.append('<div style="position:absolute;left:%spx;top:%spx;width:%spx;height:%spx;border-radius:%spx;background:#fff;'
                   'border:4px solid %s;box-shadow:0 6px 0 %s;display:flex;flex-direction:column;align-items:center;'
                   'justify-content:center"><div style="font-size:%spx;font-weight:800;line-height:1">%s</div>'
                   '<div style="margin-top:%spx;direction:ltr">%s</div></div>'
                   % (x, y0, t, t, 24 if t < 100 else 28, HAIRLINE, LIP, num, v, t * 0.08, dots))
        if labels:
            out.append('<div style="position:absolute;left:%spx;top:%spx;width:%spx;height:%spx;border:1.5px dashed %s;'
                       'border-radius:6px"></div>' % (x - sl, y0 - sl, t + 2 * sl, t + 2 * sl, TEAM))
    if labels:
        out.append('<div style="position:absolute;left:%spx;top:%spx;font:11px sans-serif;color:%s;direction:ltr">'
                   'tile %s, gap %s, hit %s x %s</div>' % (left, y0 + t + sl + 4, TEAM, t, g, t + 2 * sl, t + 2 * sl))
    return ''.join(out)


def board(b, stage, idle=False, labels=True):
    B = BOARDS[b]
    W, H = B['W'], B['H']
    gsrc = os.path.join(GOLD, B['gold'])
    gw, gh = {'phone': (852, 393), 'tabletLandscape': (1180, 820), 'tabletPortrait': (820, 1180)}[
        'phone' if b.startswith('phone') else b]
    out = ['<div style="position:relative;width:%spx;height:%spx;background:%s;overflow:hidden">' % (W, H, CREAM)]
    c = B['ctrl']
    out.append(pebble(B['eye'], B['top'], c, 'eye.svg', c * 0.5))
    out.append(pebble(B['hint'], B['top'], c, 'hint.svg', c * 0.55))
    out.append(pebble(W - B['home'] - c, B['top'], c, 'home_palm.svg', c * 0.55))
    out.append(trail(*B['trail']))
    sx, sy, sw, sh = B['gstage']
    dx, dy, dw, dh = B['stage']
    out.append(crop(gsrc, sx, sy, sw, sh, dx, dy, dw, dh, gw, gh))
    nx, ny, ns = B['nitzi']
    out.append('<img src="%s" style="position:absolute;left:%spx;top:%spx;width:%spx;height:%spx">'
               % (uri(os.path.join(CAST, 'nitzi-talk.svg' if idle else 'nitzi-idle.svg')), nx, ny, ns, ns))
    out.append(bubble(b, B, stage, idle))
    out.append(tiles(b, B, stage, labels and not idle))
    if idle:
        # The hand points at the stage (what to look at), never at a tile.
        hs = 80 if b.startswith('phone') else 120
        hw = hs * 102 / 142
        # The fingertip between the two flowers, a little above the hills; the hand comes up from below, over the grass.
        tx, ty = dx + dw * 0.50, dy + dh * 0.42
        out.append('<img src="%s" style="position:absolute;left:%spx;top:%spx;width:%spx;height:%spx;transform:rotate(180deg)">'
                   % (uri(os.path.join(HINTS, 'hand_point.svg')), tx - hw / 2, ty, hw, hs))
    out.append('<div style="position:absolute;left:0;right:0;bottom:0;height:24px;background:repeating-linear-gradient(45deg,'
               '#EDE6F7 0 6px,%s 6px 12px);opacity:0.6"></div>' % CREAM)
    out.append('</div>')
    return ''.join(out)


def sheet(b, stages, name, idle=False, notes=None):
    B = BOARDS[b]
    parts = []
    for i, st in enumerate(stages):
        S = STAGE[st]
        head = notes[i] if notes else ('%s  (%s, usual school stage %s)  captions %s, at most %d choices'
                                       % (st, S['age'], S['school'], 'hidden: speaker bubble' if S['cap'] is None
                                          else 'shown at %s pt' % S['cap'][b], S['n']))
        parts.append('<div style="font:bold 14px sans-serif;color:%s;padding:10px 4px 6px;direction:ltr">%s · %s</div>%s'
                     % (INK, b, head, board(b, st, idle=idle)))
    html = '<div style="background:#fff;padding:0 8px 8px">%s</div>' % ''.join(parts)
    render(name, html, B['W'] + 16, len(stages) * (B['H'] + 34) + 12)


def stage_mocks():
    for b in BOARDS:
        sheet(b, ['P1', 'P2', 'P3', 'P4'], 'p6_stages_%s.png' % b)
    sheet('phone', ['P2'], 'p6_idle_phone.png', idle=True,
          notes=['P2 idle prompt at 8 s: Nitzi says the question again, the speaker bubble rings once, the hand points at the stage'])


if __name__ == '__main__':
    parent_mocks()
    stage_mocks()
