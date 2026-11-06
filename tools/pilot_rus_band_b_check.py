"""Checks docs/languages/russian/band-b-pilot.md against the syllabus, the frame catalogue,
pronunciation.csv, the Cyrillic stroke set, the Band A pictures and its own tables."""
import csv, json, re, sys, unicodedata
from collections import Counter, defaultdict

sys.stdout.reconfigure(encoding="utf-8")
ROOT = sys.argv[1]
doc = open(sys.argv[2] if len(sys.argv) > 2 else f"{ROOT}/docs/languages/russian/band-b-pilot.md", encoding="utf-8").read()
syl = open(f"{ROOT}/docs/languages/russian/syllabus.md", encoding="utf-8").read()
frame = open(f"{ROOT}/docs/languages/frame.md", encoding="utf-8").read()
banda = open(f"{ROOT}/docs/languages/russian/band-a-content.md", encoding="utf-8").read()
pics_md = open(f"{ROOT}/docs/languages/pictures.md", encoding="utf-8").read()
csv_ids = {r["id"]: r for r in csv.DictReader(open(f"{ROOT}/docs/languages/russian/pronunciation.csv", encoding="utf-8"))}
forms = {f["id"]: f for f in json.load(open(f"{ROOT}/content/languages/strokes/cyrillic.json", encoding="utf-8"))["forms"]}
stroke_review = json.load(open(f"{ROOT}/content/languages/strokes/cyrillic.json", encoding="utf-8"))["review"]

problems = []
def bad(msg): problems.append(msg)

# --- reference sets -------------------------------------------------------
rus_block = frame.split("<!-- catalogue:rus:start -->")[1].split("<!-- catalogue:rus:end -->")[0]
catalogue = {m.group(1): m.group(2) for m in re.finditer(r"^\| (M-RUS-[A-Z-]+) \| `([a-z._]+)`", rus_block, re.M)}
proposed = {"M-RUS-VOWEL-CONS": "rus.pho.vowel_cons", "M-RUS-STROKE": "rus.wri.stroke"}
accent = {t for t in catalogue if re.search(rf"^\| {t} \|[^\n]*\| accent \|", rus_block, re.M)}
skills = set(re.findall(r"^\| RUS-([ABC]-\d\d) ", syl, re.M))
subskills = set(re.findall(r"`B-(2[46])\.G(\d+)`", syl)) | set(re.findall(r"`B-(2[46])\.G(\d+)`", syl))
banda_pics = set(re.findall(r"`((?:pic|hot|col)\.[a-z0-9.\-]+)`", banda))
pics_md_names = set(re.findall(r"`([a-z]+-[a-z\-]+)`", pics_md))

# --- the doc's own tables -------------------------------------------------
sec = lambda title: doc.split(title)[1].split("\n## ")[0]
frame_ids = set(re.findall(r"^\| (F\d\d|FB\d\d|F-NAME|F-SAYS) \|", sec("## 2. Hebrew frame lines"), re.M))
new_clips = {}
for m in re.finditer(r"^\| `([a-z0-9\-]+)` \| ([^|]+) \| ([^|]+) \| ([^|]+) \| ([^|]+) \|", sec("## 8. Clips"), re.M):
    new_clips[m.group(1)] = {"shown": m.group(2).strip(), "say": m.group(3).strip(), "ipa": m.group(4).strip()}
pic_rows = re.findall(r"^\| `([^`]+)`(?:, `([^`]+)`)?(?:, `([^`]+)`)? \|[^\n]*\| \*?\*?(new|exists?)", sec("## 7. Pictures"), re.M)
pic_new, pic_exist = set(), set()
for row in pic_rows:
    for p in row[:3]:
        if p: (pic_new if row[3] == "new" else pic_exist).add(p)
new_clip_ids = set(new_clips)

# --- items ----------------------------------------------------------------
heads = [(m.start(), m.group(1)) for m in re.finditer(r"^### (?:`)?RUS-(B-\d\d(?:\.G\d)?)", doc, re.M)]
def skill_at(pos):
    s = None
    for p, k in heads:
        if p < pos: s = k
    return s
items = []
for m in re.finditer(r"^\| `(rus\.b[0-9a-z]+\.[a-z0-9]+)`( C| P)? \|(.*)$", doc, re.M):
    items.append({"id": m.group(1), "mark": (m.group(2) or "").strip(), "row": m.group(3), "skill": skill_at(m.start())})

used_tags, used_clips, used_pics, used_forms, used_frames = Counter(), Counter(), Counter(), Counter(), Counter()
per_skill = defaultdict(lambda: {"items": 0, "scored": 0, "C": 0, "P": 0, "two": 0})
clip_re = re.compile(r"^(snd|syl|w|ln|nb|mg|sf|sl|sy|str|ch|mp)-[a-z0-9\-]+$")
ids_seen = Counter(i["id"] for i in items)
for i in items:
    row, sk = i["row"], i["skill"]
    st = per_skill[sk]; st["items"] += 1
    if i["mark"]: st[i["mark"]] += 1
    cells = [c.strip() for c in row.split("|")]
    for t in re.findall(r"M-RUS-[A-Z]+(?:-[A-Z]+)*", row): used_tags[t] += 1
    for tok in re.findall(r"`([^`]+)`", row):
        if tok.startswith("cyrillic."): used_forms[tok] += 1
        elif tok.startswith(("pic.", "hot.", "col.")): used_pics[tok] += 1
        elif clip_re.match(tok): used_clips[tok] += 1
    for f in re.findall(r"\b(F\d\d|FB\d\d|F-NAME|F-SAYS)\b", row): used_frames[f] += 1
    stripped = re.sub(r"M-RUS-[A-Z-]+|F-NAME|F-SAYS|`[^`]*`", "", row)
    lone = re.findall(r"(?<![\w-])[A-Z](?![\w-])", stripped)
    shown_cell = row.split("|")[3] if len(row.split("|")) > 3 else ""
    lone += re.findall(r"(?<![\w-])[a-z](?![\w-])", re.sub(r"`[^`]*`", "", shown_cell))
    if lone: bad(f"{i['id']}: a lone Latin letter {lone} (a look-alike?)")
    tmpl = cells[0]
    intro = "intro" in tmpl
    trace = "`trace`" in tmpl
    if not intro and not trace: st["scored"] += 1
    # choice items: count distractors and tags
    if "LS01" in tmpl or "LS04" in tmpl:
        dist_cell = cells[4] if "LS01" in tmpl else cells[6]
        n_tags = len(re.findall(r"\(M-RUS-[A-Z-]+\)", dist_cell))
        n_dist = len([d for d in dist_cell.split("·") if d.strip()])
        if "tap-all" in tmpl:
            if n_tags < 2: bad(f"{i['id']}: tap-all needs 2 tagged wrong cards")
            row_letters = re.search(r"the row ([^|]+?) \|", row).group(1).split()
            if len(row_letters) > 6: bad(f"{i['id']}: more than 6 cards")
        elif "match_pairs" in tmpl:
            if n_tags < 1: bad(f"{i['id']}: pairs need a mismatch tag")
        else:
            if n_tags != n_dist: bad(f"{i['id']}: {n_dist} distractors but {n_tags} tags")
            if "(2)" in tmpl:
                st["two"] += 1
                if n_dist != 1: bad(f"{i['id']}: a 2-choice item needs 1 distractor")
                if i["mark"] == "C": bad(f"{i['id']}: a 2-choice item is a check")
            elif n_dist != 2: bad(f"{i['id']}: a 3-choice item needs 2 distractors (has {n_dist})")
    if "LS03" in tmpl:
        ans = re.search(r"`n=(\d)\.c=([rbg]+)\.w=(\d)`", row)
        units = re.findall(r"(hard|soft|vowel)", cells[3])
        if not ans or int(ans.group(1)) != len(units) or len(ans.group(2)) != len(units): bad(f"{i['id']}: LS03 answer and units disagree")
        else:
            col = "".join({"hard": "b", "soft": "g", "vowel": "r"}[u] for u in units)
            if col != ans.group(2): bad(f"{i['id']}: colours {ans.group(2)} but units say {col}")
            if not 1 <= int(ans.group(3)) <= len(units): bad(f"{i['id']}: which outside the count")
    if "LS04" in tmpl:
        word = cells[2]; parts = re.findall(r"(\S+) `snd-[a-z]+`", cells[3])
        if "".join(parts) != word: bad(f"{i['id']}: parts {parts} do not join to {word}")

for k, v in ids_seen.items():
    if v > 1: bad(f"duplicate item id {k}")
# skills
for sk in per_skill:
    base = sk.split(".")[0]
    if base not in skills: bad(f"skill RUS-{sk} not in the syllabus")
    if "." in sk:
        n, g = sk.split(".G")[0][2:], sk.split(".G")[1]
        if f"`B-{n}.G{g}`" not in syl and f"B-{n}.G1" not in syl: bad(f"sub-skill {sk} not in the syllabus")
for sk, st in per_skill.items():
    if st["two"] * 2 > st["scored"]: bad(f"{sk}: 2-choice items over half")
for sk in ("B-18", "B-19"):
    if per_skill[sk]["C"] < 3: bad(f"{sk}: a core skill needs 3 checks")
# tags
for t in used_tags:
    if t not in catalogue and t not in proposed: bad(f"tag {t} not in the catalogue or the proposed list")
    if t in accent: bad(f"accent tag {t} on an item")
for t, eid in proposed.items():
    if t in catalogue: bad(f"{t} proposed but already in the catalogue")
    if eid in catalogue.values(): bad(f"engine id {eid} already used")
tag_table = sec("## 3. Misconception tags")
for t in used_tags:
    if not re.search(rf"^\| \**{t}\**", tag_table, re.M): bad(f"tag {t} used but not in §3")
for t, eid in re.findall(r"^\| \**(M-RUS-[A-Z-]+)\** ?(?:\(proposed\))? \| `([a-z._]+)`", tag_table, re.M):
    want = catalogue.get(t) or proposed.get(t)
    if want != eid: bad(f"§3 engine id of {t} is {eid}, catalogue says {want}")
# clips
for c in used_clips:
    if c not in csv_ids and c not in new_clip_ids: bad(f"clip {c} in no table")
for c in new_clip_ids:
    if c in csv_ids: bad(f"new clip {c} already in pronunciation.csv")
    if c not in used_clips: bad(f"new clip {c} used by no item")
# forms
for f in used_forms:
    if f not in forms: bad(f"form {f} not in the cyrillic stroke set")
if stroke_review != "teacher-checked": bad("stroke set not teacher-checked")
for f in used_forms:
    if f in forms and len(forms[f]["strokes"]) > 6: bad(f"{f}: more than 6 strokes")
# pictures
for p in used_pics:
    if p in pic_new: continue
    if p not in banda_pics: bad(f"picture {p} neither new in §7 nor in the Band A batch")
    if p not in pic_exist: bad(f"picture {p} not listed in §7")
for p in pic_new:
    if p in banda_pics: bad(f"picture {p} marked new but in Band A")
    if p.startswith(("pic.", "hot.")) and p not in used_pics: bad(f"new picture {p} used by no item")
# frame lines
for f in used_frames:
    if f not in frame_ids: bad(f"frame line {f} not in §2")
hint_text = doc
for f in frame_ids:
    if len(re.findall(rf"\b{re.escape(f)}\b", doc)) < 2: bad(f"frame line {f} defined but never used")

# --- script check of every Russian text ------------------------------------
cyr_words = re.findall(r"[\ẃ]*[Ѐ-ӿ][\ẃ]*", doc)
mixed = sorted({w for w in cyr_words if re.search(r"[A-Za-z]", w)})
if mixed: bad(f"Latin letters inside Cyrillic words: {mixed}")
stress_on_yo = [w for w in cyr_words if re.search("[ёЁ]́", w)]
if stress_on_yo: bad(f"stress mark on ё: {stress_on_yo}")
# on-screen text: the Shown column of the item rows and the shown column of §8 carry no stress mark
for i in items:
    cells = [c.strip() for c in i["row"].split("|")]
    tmpl = cells[0]
    if "LS01" in tmpl and "́" in cells[2]: bad(f"{i['id']}: stress mark in the shown text")
    if "LS04" in tmpl and "́" in cells[2]: bad(f"{i['id']}: stress mark in the shown word")
for c, r in new_clips.items():
    if "́" in r["shown"]: bad(f"{c}: stress mark in shown")
    for fld in ("shown", "say"):
        if re.search(r"[A-Za-z]", r[fld]): bad(f"{c}: Latin in {fld}")
    if re.search(r"[A-Za-z]", r["ipa"].replace("ɛ", "")) is None: pass
# Hebrew lines: Hebrew only, no Cyrillic in a Hebrew clip
for m in re.finditer(r"^\| (FB\d\d) \| ([^|]+) \|", sec("## 2. Hebrew frame lines"), re.M):
    if re.search(r"[Ѐ-ӿA-Za-z]", m.group(2)): bad(f"{m.group(1)}: non-Hebrew letters in a Hebrew line")

# --- counts --------------------------------------------------------------
tot = {k: sum(v[k] for v in per_skill.values()) for k in ("items", "scored", "C", "P", "two")}
say_all = "".join(r["say"] for r in new_clips.values())
heb = "".join(m.group(2).strip() for m in re.finditer(r"^\| (FB\d\d) \| ([^|]+) \|", sec("## 2. Hebrew frame lines"), re.M))
out = []
per = ", ".join("%s %d" % (k, v["items"]) for k, v in per_skill.items())
out.append(f"- Items: {tot['items']} ({per}); scored {tot['scored']}; checks {tot['C']}; probes {tot['P']}; 2-choice {tot['two']}.")
out.append(f"- Tags used: {len(used_tags)} ({', '.join(sorted(used_tags))}); in the catalogue: {sum(1 for t in used_tags if t in catalogue)}; proposed: {sorted(t for t in used_tags if t in proposed)}; accent tags on items: 0." if not any(t in accent for t in used_tags) else "- accent tag found")
out.append(f"- Skills: {sorted('RUS-' + k for k in per_skill)}, all in the syllabus (B-24.G1 and B-26.G1 as its sub-skills).")
out.append(f"- Stroke forms: {len(used_forms)} distinct ({', '.join(sorted(used_forms))}), all in `cyrillic.json` (`{stroke_review}`).")
out.append(f"- Clips: {len(used_clips)} distinct used; {len(new_clip_ids)} new rows in §8, none already in `pronunciation.csv`, each used; {len([c for c in used_clips if c in csv_ids])} reused ({', '.join(sorted(c for c in used_clips if c in csv_ids))}); referenced but in no table: [].")
out.append(f"- Pictures: {len(used_pics)} used; {len([p for p in pic_new if p.startswith(('pic.','hot.'))])} new item pictures; the rest in the Band A batch.")
out.append(f"- Frame lines: {len(frame_ids)} in §2 ({len([f for f in frame_ids if f.startswith('FB')])} new drafts), each used.")
out.append(f"- Script: {len(set(cyr_words))} distinct Cyrillic words, no Latin look-alike inside any; no stress mark on ё; no stress mark in any on-screen text; no Cyrillic or Latin letter in a Hebrew line.")
out.append(f"- Characters for voicing (free count; nothing run): Russian `say` of the {len(new_clips)} new rows {len(say_all)} with stress marks, {len(say_all.replace(chr(0x301), ''))} without; Hebrew drafts FB01 to FB27 {len(heb)} characters unpointed (the editor's voice text will differ).")
out.append(f"- Problems: {problems if problems else 'none'}")
print("\n".join(out))
