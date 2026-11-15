#!/usr/bin/env python3
"""Writes the three language voice-pilot specs (audition/v1) and prints their character counts.

Plan only. This script makes no network call and needs no key. It only writes JSON and counts characters
(Unicode code points, as app/tool/voice_gen counts them). The paid step is `audition-batch run`, typed by the owner.

  python docs/languages/make_pilot_specs.py                 # round 1 of all three languages (the files in git)
  python docs/languages/make_pilot_specs.py round2 --he nitzi,hero-son      # only a second Hebrew round (optional)
  python docs/languages/make_pilot_specs.py --count         # counts only, writes nothing

All Hebrew in the clips is a DRAFT for listening ("review": "needs-editor"); none of it is shipped text.
"""
import json
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
GATE = {"stability": 0.5, "similarity_boost": 0.75, "use_speaker_boost": True}
ROBUST = {"stability": 1.0}  # "Robust" end of the stability range: tested on a few sounds only

# ---------------------------------------------------------------- candidates (see voices.md section 2)
# The owner chose the English and Russian course voices himself on 2026-11-08 (content/voices.json), so there is no voice-picking
# round for them any more: ONE pilot per language, with the full content (every sound, the pairs, the stress words, the chunks, the
# Hebrew frame set), for his two voices. The Hebrew course keeps its reduced round 1 with the three known voices.
EN = ["lang-en-female", "lang-en-male"]
RU = ["lang-ru-female", "lang-ru-male"]
HE = ["nitzi", "hero-son", "climber-tzuri"]
CONTROL = "nitzi"  # the Hebrew house voice, as a control for "does a Hebrew voice speak the target language"

# Hebrew frame lines: DRAFT wording for the listening test only (the hebrew-text-editor owns the real words).
HE_FRAME = [
    ("he-listen", "הקשיבו למילה."),
    ("he-your-turn", "עכשיו אתם. אמרו את המילה."),
]
HE_LONG = ("he-long", "ברוכים הבאים. היום נלמד מילים חדשות, לאט, ואחר כך נשחק בהן.")
HE_EXTRA = [("he-nice", "איזו מילה יפה.")]


def clip(cid, text, lang, voice, note="", tests="", allow=None, settings=None, model=None):
    c = {"id": cid, "character": voice}
    if lang != "he":  # Hebrew is the tool's default language_code, so a Hebrew clip carries no key
        c["language"] = lang
    c["text"] = text
    if model:
        c["model"] = model
    if allow:
        c["allow"] = allow
    if settings:
        c["settings"] = settings
    if tests:
        c["tests"] = tests
    if note:
        c["note"] = note
    return c


# ================================================================ ENGLISH
EN_SOUND_KEYS = [  # (id, ipa, stretched keyword fallback)
    ("s", "s", "sssun."), ("m", "m", "mmmap."), ("t", "t", "t... tent."), ("p", "p", "p... pan."),
    ("ae", "æ", "aaapple."), ("i", "ɪ", "iiigloo."), ("o", "ɑ", "oooctopus."), ("u", "ʌ", "uuup."),
    ("w", "w", "wwweb."), ("v", "v", "vvvan."), ("th", "θ", "thhhumb."), ("dh", "ð", "thhhis."),
]
EN_ROUND1_SOUNDS = ["s", "m", "t", "ae", "w", "th"]
EN_WRITTEN_STRETCH = [("s", "ssssss."), ("m", "mmmmmm."), ("v", "vvvvvv."), ("w", "wwwwww."), ("th", "thhhhhh.")]
EN_CV = [("ma", "mæ"), ("sa", "sæ"), ("ti", "tɪ"), ("pu", "pʌ"), ("wi", "wɪ"), ("thi", "θɪ")]
EN_PAIRS = ["wet", "vet", "three", "tree", "ship", "sheep", "man", "men", "hat", "hot", "hut", "sing", "sin"]
EN_PAIRS_R1 = ["wet", "vet", "three", "tree", "ship", "sheep"]
EN_WORDS = ["banana", "elephant", "window", "yellow", "teacher", "apple"]
EN_CHUNKS = [("hello", "Hello."), ("whats-this", "What's this? It's a cat."), ("thank-you", "Thank you."),
             ("i-like-bananas", "I like bananas.")]


def english(voices, rnd, model_check_voice=None):
    out = []
    for v in voices:
        k = v.replace("lang-en-", "en-")
        full = rnd == 2
        snd = [s for s in EN_SOUND_KEYS if full or s[0] in EN_ROUND1_SOUNDS]
        for sid, ipa, _ in snd:
            out.append(clip(f"{k}-01-{sid}-ipa", f"/{ipa}/", "en", v, allow=["ipa"],
                            tests=f"isolated /{ipa}/: the sound alone, no added vowel, nothing cut"))
        for sid, ipa, kw in snd:
            out.append(clip(f"{k}-01-{sid}-word", kw, "en", v,
                            tests="decision-2 fallback: the key word with the sound stretched or doubled"))
        for sid, text in (EN_WRITTEN_STRETCH if full else EN_WRITTEN_STRETCH[:2]):
            out.append(clip(f"{k}-01-{sid}-held", text, "en", v, tests="the sound written long: held, steady, no vowel"))
        if full:
            for sid in ["s", "m", "t", "ae"]:
                ipa = [x for x in EN_SOUND_KEYS if x[0] == sid][0][1]
                out.append(clip(f"{k}-01-{sid}-ipa-robust", f"/{ipa}/", "en", v, allow=["ipa"],
                                settings=ROBUST, tests="same as the IPA clip at stability 1.0: more even?"))
        for sid, ipa in (EN_CV if full else EN_CV[:2]):
            out.append(clip(f"{k}-02-{sid}", f"/{ipa}/", "en", v, allow=["ipa"],
                            tests=f"CV unit /{ipa}/ as one syllable, not two letters, not 'ma-uh'"))
        if full:
            out.append(clip(f"{k}-02-rt-k", "/k/", "en", v, allow=["ipa"], tests="robot talk: /k/ with no vowel"))
            out.append(clip(f"{k}-02-rt-cat", "cat.", "en", v, tests="robot talk: the whole word after /k/ /æ/ /t/"))
            out.append(clip(f"{k}-02-rt-caaat", "caaat.", "en", v, tests="stretch and blend version"))
        for w in (EN_PAIRS if full else EN_PAIRS_R1):
            out.append(clip(f"{k}-03-{w}", f"{w}.", "en", v, tests="minimal pair: this word alone; same pitch and length as its pair"))
        if full:
            out.append(clip(f"{k}-03-wet-bare", "wet", "en", v, tests="bare word, no full stop: stable or odd?"))
            out.append(clip(f"{k}-03-vet-bare", "vet", "en", v, tests="bare word, no full stop"))
        for w in (EN_WORDS if full else ["banana", "elephant", "window"]):
            out.append(clip(f"{k}-04-{w}", f"{w}.", "en", v, tests="stress trap word: stress, weak vowels, w/th/r"))
        for cid, text in (EN_CHUNKS if full else EN_CHUNKS[1:2]):
            out.append(clip(f"{k}-04-{cid}", text, "en", v, tests="a chunk at natural pace, weak forms weak, no Israeli accent"))
        frame = HE_FRAME + ([HE_LONG] + HE_EXTRA if full else [HE_LONG])
        for cid, text in (frame if full else [HE_FRAME[0], HE_LONG]):
            out.append(clip(f"{k}-05-{cid}", text, "he", v,
                            tests="Hebrew instruction, a separate clip: native Israeli Hebrew? same warmth as the English clips?"))
    if rnd == 2 and model_check_voice:
        k = model_check_voice.replace("lang-en-", "en-")
        for cid, text, allow in [("s-ipa", "/s/", ["ipa"]), ("s-word", "sssun.", None), ("wet", "wet.", None),
                                 ("vet", "vet.", None), ("three", "three.", None), ("tree", "tree.", None),
                                 ("banana", "banana.", None), ("whats-this", "What's this? It's a cat.", None)]:
            out.append(clip(f"{k}-06-turbo-{cid}", text, "en", model_check_voice, allow=allow, model="eleven_v4_turbo",
                            tests="same text on Turbo (half the price): worse than v4?"))
    return out


# ================================================================ RUSSIAN  (texts from russian/pronunciation.csv `say`)
U = "́"


def stress(t):
    """Marks the stress with U+0301 after the vowel written as '*' in t (kept readable in this file)."""
    return t.replace("*", U)


RU_SOUNDS = [("snd-m", "ммм"), ("snd-mj", "мь"), ("snd-s", "ссс"), ("snd-sh", "шшш"), ("snd-a", "а"),
             ("snd-y", "ы"), ("snd-k", "к"), ("snd-shch", "щщщ")]
RU_SOUNDS_R1 = ["snd-m", "snd-s", "snd-sh", "snd-y", "snd-k", "snd-shch"]
RU_IPA = [("snd-y-ipa", "/ɨ/"), ("snd-shch-ipa", "/ɕː/"), ("snd-m-ipa", "/mː/")]
RU_STRETCH = [("str-som-1", "с-с-сом"), ("str-som-2", "со-о-ом"), ("str-som-3", "сом-м-м")]
RU_SYL = [("syl-ma", "ма"), ("syl-mja", "мя"), ("syl-my", "мы"), ("syl-mi", "ми"), ("syl-la", "ла"), ("syl-lja", "ля")]
RU_PAIRS = [("mp-luk", "лук"), ("mp-ljuk", "люк"), ("mp-sel", "сел"), ("mp-sjel", "съел"), ("mp-mal", "мал"),
            ("mp-mjal", "мял"), ("mp-byl", "был"), ("mp-bil", "бил")]
RU_WORDS = [  # say column (stress marks as in the CSV)
    ("w-mama", "ма*ма"), ("w-moloko", "молоко*"), ("w-voda", "вода*"), ("w-vody", "во*ды"), ("w-ruka", "рука*"),
    ("w-ruku", "ру*ку"), ("w-lisa", "лиса*"), ("w-kon", "конь"), ("w-dub", "дуб"), ("w-hleb", "хлеб"),
    ("w-yozh", "ёж"), ("w-yolka", "ёлка"), ("w-shchuka", "щу*ка"), ("w-mjach", "мяч"), ("w-ryba", "ры*ба"),
    ("w-zhiraf", "жира*ф"), ("w-solntse", "со*лнце"), ("w-zdravstvujte", "здра*вствуйте"), ("w-chto", "что"),
    ("w-pozhalujsta", "пожа*луйста"), ("w-spasibo", "спаси*бо"), ("w-lozhka", "ло*жка"), ("w-skazka", "ска*зка"),
    ("w-deti", "де*ти"), ("w-tsyplyonok", "цыплёнок"), ("w-yabloko", "я*блоко"),
]
RU_WORDS_R1 = ["w-moloko", "w-ruka", "w-yolka", "w-zdravstvujte", "w-chto", "w-shchuka"]
RU_NOMARK = [("w-moloko-nomark", "молоко"), ("w-ruka-nomark", "рука"), ("w-mama-nomark", "мама")]
RU_IPA_WORD = [("w-moloko-ipa", "/məlɐˈko/")]
RU_SENT = [("sen-1", "Я ви*жу ко*шку."), ("sen-2", "Э*то кот.")]


def russian(voices, rnd, model_check_voice=None):
    out = []
    for v in voices:
        k = v.replace("lang-ru-", "ru-")
        full = rnd == 2
        for cid, t in RU_SOUNDS:
            if full or cid in RU_ROUND1:
                out.append(clip(f"{k}-01-{cid}", stress(t), "ru", v, tests="isolated sound, not the letter name; no vowel after it"))
        for cid, t in (RU_IPA if full else RU_IPA[:2]):
            out.append(clip(f"{k}-01-{cid}", t, "ru", v, allow=["ipa"], tests="IPA form of the same sound: cleaner than the letters?"))
        for cid, t in RU_STRETCH:
            out.append(clip(f"{k}-01-{cid}", t, "ru", v, tests="stretched sound inside a word, then the word natural"))
        for cid, t in RU_SYL:
            out.append(clip(f"{k}-02-{cid}", t, "ru", v, tests="syllable: hard/soft consonant, a true ы, a single syllable"))
        if full:
            out.append(clip(f"{k}-02-slide-mma", "ммма", "ru", v, tests="syllable slide: consonant held then merged"))
        for cid, t in (RU_PAIRS if full else RU_PAIRS[:4]):
            out.append(clip(f"{k}-03-{cid}", t + ".", "ru", v, tests="minimal pair word: same pitch and length as its pair"))
        for cid, t in RU_WORDS:
            if full or cid in RU_WORDS_R1:
                out.append(clip(f"{k}-04-{cid}", stress(t) + ".", "ru", v, tests="stress, vowel reduction, hard/soft, the trap in pronunciation.csv"))
        for cid, t in (RU_NOMARK if True else []):
            out.append(clip(f"{k}-04-{cid}", t + ".", "ru", v, tests="same word WITHOUT U+0301: does the voice stress it right alone?"))
        if full:
            for cid, t in RU_IPA_WORD:
                out.append(clip(f"{k}-04-{cid}", t, "ru", v, allow=["ipa"], tests="stress through IPA instead of U+0301"))
            for cid, t in RU_SENT:
                out.append(clip(f"{k}-04-{cid}", stress(t), "ru", v, tests="short sentence at a calm pace"))
            out.append(clip(f"{k}-04-call-ruka", stress("ру-ка*-а"), "ru", v, tests="calling a word: stress stays on ка"))
            out.append(clip(f"{k}-04-aw-moloko", stress("мо-ло-ко*"), "ru", v, tests="as-written clip (skills C-11, C-21 only)"))
        frame = HE_FRAME + ([HE_LONG] + HE_EXTRA if full else [HE_LONG])
        for cid, text in (frame if full else [HE_FRAME[0], HE_LONG]):
            out.append(clip(f"{k}-05-{cid}", text, "he", v,
                            tests="Hebrew instruction, a separate clip: native Israeli Hebrew? same warmth as the Russian clips?"))
    if rnd == 2 and model_check_voice:
        k = model_check_voice.replace("lang-ru-", "ru-")
        for cid, t in [("snd-m", "ммм"), ("snd-sh", "шшш"), ("syl-my", "мы"), ("mp-luk", "лук."), ("mp-ljuk", "люк."),
                       ("w-moloko", stress("молоко*") + "."), ("w-ruka", stress("рука*") + "."),
                       ("sen-1", stress("Я ви*жу ко*шку."))]:
            out.append(clip(f"{k}-06-turbo-{cid}", t, "ru", model_check_voice, model="eleven_v4_turbo",
                            tests="same text on Turbo (half the price): worse than v4?"))
    return out


RU_ROUND1 = set(RU_SOUNDS_R1)

# ================================================================ HEBREW COURSE
HE_CONT = [("mem", "מְ", "מממממ"), ("shin", "שְׁ", "שששששש"), ("samekh", "ס", "סססססס"), ("lamed", "לְ", "לללללל"),
           ("fe", "פ", "ףףףףףף")]
HE_CV = [("ma", "מָ"), ("mi", "מִ"), ("mo", "מוֹ"), ("mu", "מוּ"), ("me", "מֵ"), ("ba", "בָּ"), ("ta", "תָּ"),
         ("ku", "קוּ"), ("pi", "פִּי")]
HE_CV_IPA = [("ma", "ma"), ("mi", "mi"), ("shu", "ʃu")]
HE_DAGESH = [("ba-dagesh", "בָּ"), ("ba-soft", "בָ"), ("ka-dagesh", "כָּ"), ("ka-soft", "כָ"), ("pa-dagesh", "פָּ"), ("pa-soft", "פָ")]
HE_PAIRS = [("shar-shin", "שָׁר."), ("shar-sin", "שָׂר."), ("kelev", "כֶּלֶב."), ("chalav", "חֶלֶב."),
            ("gan", "גַּן."), ("gam", "גַּם."), ("sefer", "סֵפֶר."), ("safar", "סָפַר.")]
HE_WORDS = [("glida", "גְּלִידָה."), ("yalda", "יַלְדָּה."), ("yeled", "יֶלֶד."), ("shabbat", "שַׁבָּת."),
            ("chatul", "חָתוּל."), ("pizza", "פִּיצָה.")]
HE_UNITS = [("pi-tsa", "פִּי… צָה… פִּיצָה."), ("ka-dur", "כַּ… דּוּר… כַּדּוּר.")]
HE_NAMES = [("gimel", "גִּימֶל."), ("vav", "וָו."), ("yod", "יוֹד."), ("kof", "קוֹף."), ("tsadi", "צָדִי.")]
HE_R1_CONT = ["mem", "shin", "samekh"]
HE_R1_CV = ["ma", "mi", "mu", "ba", "ku"]
HE_R1_WORDS = ["glida", "yeled", "chatul"]


def hebrew(voices, rnd, model_check_voice=None):
    out = []
    for v in voices:
        k = v.replace("lang-he-", "he-")
        full = rnd == 2
        for cid, pointed, held in HE_CONT:
            if full or cid in HE_R1_CONT:
                out.append(clip(f"{k}-01-{cid}-pointed", pointed, "he", v, tests="the sound alone as the Ministry writes it: no added vowel"))
                out.append(clip(f"{k}-01-{cid}-held", held, "he", v, tests="the letter repeated: held about 0.7 s, steady, the sound not the name"))
        for cid, pointed in HE_CV:
            if full or cid in HE_R1_CV:
                out.append(clip(f"{k}-02-{cid}", pointed, "he", v, tests="one clean CV syllable, level pitch, not the letter name, nothing after the vowel"))
        for cid, ipa in (HE_CV_IPA if full else HE_CV_IPA[:2]):
            out.append(clip(f"{k}-02-{cid}-ipa", f"/{ipa}/", "he", v, allow=["ipa"], tests="IPA form: cleaner than the pointed letter?"))
        if full:
            for cid, t in HE_DAGESH:
                out.append(clip(f"{k}-02-{cid}", t, "he", v, tests="dagesh pair: b/v, k/ch, p/f heard apart at the start of a clip"))
        for cid, t in (HE_PAIRS if full else HE_PAIRS[:2] + HE_PAIRS[2:4]):
            out.append(clip(f"{k}-03-{cid}", t, "he", v, tests="minimal pair word: same pitch and length as its pair"))
        for cid, t in HE_WORDS:
            if full or cid in HE_R1_WORDS:
                out.append(clip(f"{k}-04-{cid}", t, "he", v, tests="stress and shva of a single word"))
        for cid, t in (HE_UNITS if full else HE_UNITS[:1]):
            out.append(clip(f"{k}-04-units-{cid}", t, "he", v, tests="unit by unit, about 300 ms apart, then whole; no stretched vowels"))
        if full:
            for cid, t in HE_NAMES:
                out.append(clip(f"{k}-04-name-{cid}", t, "he", v, tests="letter name in the editor's chosen form"))
        for cid, t in (HE_FRAME if True else []):
            out.append(clip(f"{k}-05-{cid}", t, "he", v, tests="Hebrew instruction as its own clip; the next clip is the target word (see voices.md, split-clip rule)"))
        if full:
            out.append(clip(f"{k}-05-{HE_LONG[0]}", HE_LONG[1], "he", v, tests="a short Hebrew passage: the teaching register"))
    if rnd == 2 and model_check_voice:
        k = model_check_voice.replace("lang-he-", "he-")
        for cid, t in [("mem-held", "מממממ"), ("ma", "מָ"), ("ba", "בָּ"), ("sefer", "סֵפֶר."), ("safar", "סָפַר."),
                       ("glida", "גְּלִידָה."), ("chatul", "חָתוּל."), ("pi-tsa", "פִּי… צָה… פִּיצָה.")]:
            out.append(clip(f"{k}-06-turbo-{cid}", t, "he", model_check_voice, model="eleven_v4_turbo",
                            tests="same text on Turbo (half the price): worse than v4?"))
    return out


# ================================================================ writing and counting
TITLES = {
    "english": "English course voice pilot, round {r}: which voice can say General American sounds, syllables, words and a Hebrew frame.",
    "russian": "Russian course voice pilot, round {r}: which voice can say standard Russian sounds, syllables, words and a Hebrew frame.",
    "hebrew": "Hebrew course voice pilot, round {r}: which voice can say isolated sounds, CV units, stress and shva words, and a teaching frame.",
}


NEEDS = {
    "english": "The key 'language' (en) and English texts are NOT yet accepted by app/tool/audition_lib.dart and voice_text_lib.dart (hand-off H1 in voices.md): run only after the app-developer has made that change. ",
    "russian": "The key 'language' (ru), Cyrillic texts and U+0301 are NOT yet accepted by app/tool/audition_lib.dart and voice_text_lib.dart (hand-off H1 in voices.md): run only after the app-developer has made that change. ",
    "hebrew": "This file is accepted by today's tool as it is (checked with the free plan command). The IPA clips are in pilot-ipa.json and wait for hand-off H1 in voices.md. ",
}


def spec(lang, clips, rnd):
    return {
        "schema": "audition/v1",
        "title": TITLES[lang].format(r=rnd),
        "review": "needs-editor",
        "note": ("Written by the voice-and-sound-director on 2026-11-03 (docs/languages/voices.md). PLAN ONLY: nothing has been run or paid. "
                 + NEEDS[lang]
                 + "The owner has to put the voice ids into content/voices.json first (docs/languages/voices-candidates.json). "
                 + "All Hebrew in the clips is draft wording for listening, not shipped text."),
        "defaults": {"model": "eleven_v4", "format": "mp3_44100_64", "settings": GATE},
        "clips": clips,
    }


def write(path, s):
    NL = chr(10)
    with open(path, "w", encoding="utf-8", newline=NL) as f:
        f.write("{" + NL)
        for key in ["schema", "title", "review", "note", "defaults"]:
            f.write("  " + json.dumps(key) + ": " + json.dumps(s[key], ensure_ascii=False) + "," + NL)
        f.write("  " + chr(34) + "clips" + chr(34) + ": [" + NL)
        f.write(("," + NL).join("    " + json.dumps(c, ensure_ascii=False) for c in s["clips"]))
        f.write(NL + "  ]" + NL + "}" + NL)


def chars(c):
    return len(c["text"])


def arg(name, default):
    if name in sys.argv:
        return sys.argv[sys.argv.index(name) + 1].split(",")
    return default


def main():
    rnd = 2 if "round2" in sys.argv else 1  # round2 now only means a second Hebrew round
    en_v = arg("--en", EN)
    ru_v = arg("--ru", RU)
    he_v = arg("--he", HE if rnd == 1 else HE[:2])
    # English and Russian: always the full content (the old round 2), no Turbo comparison clips (the language packs are voiced on v4), no control.
    sets = {"english": english(en_v, 2, None), "russian": russian(ru_v, 2, None),
            "hebrew": hebrew(he_v, rnd, he_v[0])}
    total = 0
    for lang, clips in sets.items():
        ids = [c["id"] for c in clips]
        assert len(ids) == len(set(i.lower() for i in ids)), "duplicate id in " + lang
        assert all(len(c["text"]) <= 300 for c in clips)
        v4 = sum(chars(c) for c in clips if c.get("model") != "eleven_v4_turbo")
        tu = sum(chars(c) for c in clips if c.get("model") == "eleven_v4_turbo")
        total += v4 + tu
        print(f"{lang:8} round {rnd}: {len(clips):4} clips, v4 {v4:5} chars, turbo {tu:4} chars, "
              f"list cost {v4 * 0.08 / 1000 + tu * 0.04 / 1000:.4f} USD")
        if "--count" not in sys.argv:
            name = "pilot.json" if (rnd == 1 or lang != "hebrew") else "pilot-round2.json"
            groups = [(name, clips)]
            if lang == "hebrew":  # IPA-only clips need hand-off H1; the rest runs on today's tool
                groups = [(name, [c for c in clips if "allow" not in c]),
                          (name.replace(".json", "-ipa.json").replace("pilot-ipa", "pilot-ipa"),
                           [c for c in clips if "allow" in c])]
                groups[1] = ("pilot-ipa.json" if rnd == 1 else "pilot-round2-ipa.json", groups[1][1])
            if lang != "hebrew" and rnd == 2:
                continue  # a second Hebrew round must not overwrite the English and Russian pilots
            for fname, group in groups:
                write(os.path.join(HERE, lang, fname), spec(lang, group, rnd))
    print(f"all three: {total} chars")


if __name__ == "__main__":
    main()
