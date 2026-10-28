# Pack 0.3.0 of the starter content (M8 8b, M7 Q6): a world object and a line for the child on each skill, a home activity on
# each misconception, and the new version. Hebrew with niqqud for the child's lines; plain Hebrew for the parent's.
import json
import os

root = r'D:\Children-Learning-App\content\starter'


def load(name):
    with open(os.path.join(root, name), encoding='utf-8') as f:
        return json.load(f)


def save(name, doc):
    with open(os.path.join(root, name), 'w', encoding='utf-8', newline='\n') as f:
        json.dump(doc, f, ensure_ascii=False, indent=2)
        f.write('\n')


skills = {
    'NUM-A-01': ('stair', 'סוֹפְרִים עַד חָמֵשׁ, לְפִי הַסֵּדֶר'),
    'NUM-A-02': ('stair', 'סוֹפְרִים עַד עֶשֶׂר, לְפִי הַסֵּדֶר'),
    'NUM-A-03': ('stair', 'נוֹגְעִים בְּכָל אֶחָד פַּעַם אַחַת כְּשֶׁסּוֹפְרִים'),
    'NUM-A-04': ('stair', 'יוֹדְעִים כַּמָּה יֵשׁ: הַמִּסְפָּר הָאַחֲרוֹן שֶׁסָּפַרְנוּ'),
    'COL-A-02': ('pool', 'מַצְבִּיעִים עַל אָדֹם, כָּחֹל, צָהֹב וְיָרֹק'),
}
for sid, (obj, line) in skills.items():
    name = f'skill.{sid}.json'
    doc = load(name)
    # Keep the field order readable: after the title block.
    new = {}
    for k, v in doc.items():
        new[k] = v
        if k == 'title':
            new['worldObject'] = obj
            new['childLine'] = [{'t': 'he', 'v': line}]
    save(name, new)

home = {
    'M-CNT-CARD': 'בארוחה, לבקש מהילד להגיש שלושה פירות ולספור אותם בקול. אחרי הספירה לשאול: כמה יש בסך הכול? בלי לתקן, רק לספור שוב יחד.',
    'M-CNT-DOUBLE': 'לסדר חמש כוסות בשורה ולבקש מהילד להזיז כוס אחת הצידה בכל פעם שהוא סופר אותה, כך שאי אפשר לספור אותה פעמיים.',
    'M-CNT-SEQ': 'לשיר יחד שיר ספירה, או לעלות במדרגות ולספור כל מדרגה בקול. חמש דקות מספיקות, בלי לתקן, רק לחזור שוב.',
    'M-CNT-SKIP': 'לשים צעצועים במעגל ולסמן את הראשון בכובע, כדי לדעת איפה הספירה מתחילה ונגמרת. לספור יחד ולגעת בכל אחד פעם אחת.',
}
for tag, text in home.items():
    name = f'misconception.{tag}.json'
    doc = load(name)
    new = {}
    for k, v in doc.items():
        new[k] = v
        if k == 'parentText':
            new['homeActivity'] = [{'t': 'he', 'v': text}]
    save(name, new)

pack = load('pack.json')
pack['version'] = '0.3.0'
pack['minAppVersion'] = '0.3.0'
save('pack.json', pack)
print('ok')
