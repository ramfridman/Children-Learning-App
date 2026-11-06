#!/usr/bin/env python3
"""ENG-2 pilot slice (L5-2c): writes docs/languages/english/band-b-pilot.md and checks it.

Standard library only, no network, no key. Run:
  python eng_pilot.py D:/nitznutz-l5            # write the file and run the checks
  python eng_pilot.py D:/nitznutz-l5 --check    # checks only
  python eng_pilot.py D:/nitznutz-l5 --broken   # self-test: a broken copy must fail
"""
import json, os, re, sys, copy

ROOT = next((a for a in sys.argv[1:] if not a.startswith("--")), os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
CHECK_ONLY = "--check" in sys.argv
BROKEN = "--broken" in sys.argv
OUT = os.path.join(ROOT, "docs/languages/english/band-b-pilot.md")

GROUP1 = ["s", "a", "t", "p", "i", "n"]
KEY = {"s": "sun", "a": "apple", "t": "tent", "p": "pan", "i": "igloo", "n": "net"}
SND_IPA = {"s": "/s/", "a": "/æ/", "t": "/t/", "p": "/p/", "i": "/ɪ/", "n": "/n/"}
NAME_IPA = {"s": "/ɛs/", "a": "/eɪ/", "t": "/ti/", "p": "/pi/", "i": "/aɪ/", "n": "/ɛn/"}

# ------------------------------------------------------------------ Hebrew frame lines (new, needs-editor)
HE_NEW = [
    ("he-ins-letter-new", "בואו נכיר אות חדשה באנגלית.", "Let's meet a new letter in English.", "LS02 intro, first line"),
    ("he-ltr-sound", "הצליל שלה:", "Its sound:", "carrier before en-snd-<x> (intro, H2, feedback)"),
    ("he-ltr-keyword", "כמו בהתחלה של:", "Like at the start of:", "carrier before the key word (intro, H2)"),
    ("he-ltr-name", "והשם שלה:", "And its name:", "carrier before en-name-<x> (intro, H2, feedback)"),
    ("he-ltr-watch", "הסתכלו איך כותבים אותה.", "Watch how it is written.", "LS02 intro, while the dot walks the path"),
    ("he-ltr-ltr", "באנגלית קוראים וכותבים משמאל לימין.", "In English we read and write from left to right.", "the explicit contrast, once: before the first LS02 item and before the first B-18 item (syllabus §7.2)"),
    ("he-ins-trace", "עכשיו אתם: עברו עם האצבע על הקו, מהנקודה הירוקה.", "Now you: go over the line with your finger, from the green dot.", "LS02 trace, and the one trace of intro"),
    ("he-ins-copy", "כתבו את האות הזאת בקופסה הריקה.", "Write this letter in the empty box.", "LS02 copy"),
    ("he-ins-write-sound", "כתבו את האות שאומרת:", "Write the letter that says:", "LS02 memory, cue sound; carrier before en-snd-<x>"),
    ("he-ins-write-name", "כתבו את האות ששמה:", "Write the letter whose name is:", "LS02 memory, cue name; carrier before en-name-<x>"),
    ("he-ins-sound-letter", "הקשיבו לצליל, וגעו באות שלו.", "Listen to the sound, and touch its letter.", "LS01 sound to letter"),
    ("he-ins-name-letter", "הקשיבו לשם, וגעו באות.", "Listen to the name, and touch the letter.", "LS01 name to letter"),
    ("he-ins-letter-sound", "מה הצליל של האות הזאת? הקשיבו לכפתורים, וגעו בצליל.", "What is this letter's sound? Listen to the buttons, and touch the sound.", "LS01 letter to sound"),
    ("he-ins-letter-name", "מה השם של האות הזאת? הקשיבו לכפתורים, וגעו בשם.", "What is this letter's name? Listen to the buttons, and touch the name.", "LS01 letter to name"),
    ("he-ins-letter-pic", "איזו תמונה מתחילה בצליל של האות? געו בתמונה.", "Which picture starts with the letter's sound? Touch the picture.", "LS01 letter to picture"),
    ("he-ins-tap-all", "געו בכל האותיות שאומרות:", "Touch all the letters that say:", "LS01 tap-all; carrier before en-snd-<x>"),
    ("he-ins-hop", "הקשיבו לצליל, וגררו את פיפ לאבן עם האות שלו.", "Listen to the sound, and drag Pip to the stone with its letter.", "LS11 place"),
    ("he-ins-slide", "החליקו את האצבע מתחת למילה, משמאל לימין.", "Slide your finger under the word, from left to right.", "LS04 graphemes"),
    ("he-ins-slide-pick", "איזו מילה זאת? געו בתמונה שלה.", "Which word is it? Touch its picture.", "LS04, the scored choice"),
    ("he-ins-read-pick", "קראו את המילה, וגעו בתמונה שלה.", "Read the word, and touch its picture.", "LS01 text stem"),
    ("he-ins-read-page", "קראו את המילה, וגעו בעמוד של הסיפור שמראה אותה.", "Read the word, and touch the story page that shows it.", "LS01 text stem in the story scene (B-18 r07)"),
    ("he-ins-boxes", "הקשיבו למילה, וגררו עיגול אחד לכל צליל.", "Listen to the word, and drag one circle for each sound.", "LS03 boxes, count step"),
    ("he-ins-which-box", "באיזו קופסה הצליל:", "In which box is the sound:", "LS03 boxes, which step; carrier before en-snd-<x>"),
    ("he-hint-start", "התחילו בנקודה הירוקה, ולכו עם החץ.", "Start at the green dot, and go with the arrow.", "HL-WRITE H1"),
    ("he-hint-watch-try", "הסתכלו לאט, ואז נסו שוב.", "Watch slowly, then try again.", "HL-WRITE H2"),
    ("he-hint-trace-together", "בואו נעבור על הקו יחד.", "Let's go over the line together.", "HL-WRITE H3"),
    ("he-hint-name-sound", "לכל אות יש שם, ויש צליל.", "Every letter has a name, and a sound.", "H2 of the name and sound items"),
    ("he-hint-mouth", "הסתכלו על הפה.", "Look at the mouth.", "H2 with a mouth picture (LS03, LS04, letter to picture)"),
    ("he-hint-look-letter", "הסתכלו טוב על האות.", "Look carefully at the letter.", "HL-TAPALL H1"),
    ("he-hint-listen-word", "הקשיבו למילה:", "Listen to the word:", "HL-STEM H1 ('read it to me'); carrier before the word"),
    ("he-hint-slide-again", "בואו נחליק שוב, לאט.", "Let's slide again, slowly.", "HL-BLEND H1"),
    ("he-fb-look-alike", "הסתכלו טוב: הן דומות, אבל הן לא אותה אות.", "Look carefully: they look alike, but they are not the same letter.", "first error on a look-alike letter (LOOKALIKE, BD)"),
    ("he-fb-name-not-sound", "זה השם של האות. הצליל שלה:", "That is the letter's name. Its sound:", "LETTERNAME, asked for the sound; carrier before en-snd-<x>"),
    ("he-fb-sound-not-name", "זה הצליל של האות. השם שלה:", "That is the letter's sound. Its name:", "LETTERNAME, asked for the name; carrier before en-name-<x>"),
    ("he-fb-stroke-again", "בואו ננסה את הקו הזה שוב, מהנקודה הירוקה.", "Let's try this line again, from the green dot.", "LS02, a stroke that missed or started at the other end (STROKE-RTL, or no tag)"),
    ("he-fb-round-way", "העיגול של האות הזאת הולך לצד השני.", "This letter's round part goes the other way.", "LS02 STROKE-CW"),
    ("he-fb-lines", "שימו את האות על הקווים.", "Put the letter on the lines.", "LS02 LINES (s a t i n)"),
    ("he-fb-tail", "לאות הזאת יש זנב שיורד מתחת לקו.", "This letter has a tail that goes below the line.", "LS02 LINES for p"),
    ("he-fb-faces", "האות הזאת פונה לצד השני.", "This letter faces the other way.", "LS02 mirror or partner (BD) for p"),
    ("he-fb-watch-order", "ככה כותבים אותה.", "This is how it is written.", "LS02 success: the model replays once in its order"),
    ("he-fb-left-start", "באנגלית מתחילים משמאל.", "In English we start on the left.", "DIR (LS04, LS01 stem, LS03 mirror box)"),
]
HE_REUSED = ["he-fb-right-1", "he-fb-right-2", "he-fb-right-3", "he-fb-right-4", "he-fb-right-5", "he-fb-right-6",
             "he-fb-right-7", "he-fb-right-8", "he-fb-check", "he-fb-thats", "he-fb-listen-again", "he-hint-again",
             "he-hint-showme", "he-ins-story"]

# ------------------------------------------------------------------ hint ladders
LADDERS = [
    ("HL-SND2LTR", "Sound to letter (LS01, letter tiles). H1: he-hint-again + the sound again, held a little longer (the same en-snd clip). H2 (a new representation, the picture the letter was met with): he-ltr-keyword + the key word, with the key-word picture beside the tiles (tent for /t/); the tiles stay as they were. H3: he-hint-showme; the friend taps the letter and its sound plays; the child taps it."),
    ("HL-NAME2LTR", "Name to letter (LS01, letter tiles). H1: he-hint-again + the name again, slowly. H2 (the letter card, sound and picture): he-hint-name-sound + he-ltr-name + the name + he-ltr-sound + the sound, with the key-word picture; the tiles stay. H3: he-hint-showme; the friend taps the letter and its name plays; the child taps it."),
    ("HL-LTR2SND", "Letter to sound or letter to name, 2 choices (one retry only, curriculum §9.2). H1: he-hint-again; the two buttons play again, slowly, each lit as it plays. H2 (the letter card): he-hint-name-sound + he-ltr-name + the name + he-ltr-sound + the sound, the letter big beside its key-word picture; then the buttons play again. H3: he-hint-showme; the friend taps the right button; the child taps it."),
    ("HL-LTR2PIC", "Letter to picture (LS01 text stem: a letter). H1: the letter's sound (en-snd), then each picture's word, slowly. H2 (a new representation, the mouth): he-hint-mouth + the sound, with the mouth picture of the sound (pic.mouth-<x>) beside the letter; then the words again. H3: he-hint-showme; the friend taps the picture and its word plays with the first sound stretched; the child taps it."),
    ("HL-TAPALL", "Tap-all (LS01, a row of letter tiles). H1: he-hint-look-letter; the target letter appears big above the row and its sound plays. H2 (a new representation, the shape laid over): the big letter glides over each tile in turn and fits only on the right ones; the look-alikes are left uncovered. H3: he-hint-showme; the friend taps the first right tile; the child taps the rest."),
    ("HL-HOP", "LS11 place (Pip to the letter stone). H1: he-hint-again + the sound, slowly. H2: he-ltr-keyword + the key word, with the key-word picture on the far bank. H3: he-hint-showme; Pip hops to the right stone and the sound plays; the child drags Pip there."),
    ("HL-WRITE", "LS02 trace, copy and memory (L5 §5.2). H1: he-hint-start; the start dot and the arrow of the stroke the child is on (in memory mode the cue clip plays again first). H2 (a new representation, motion): he-hint-watch-try; the stroke is drawn slowly once, then the box clears. H3: he-hint-trace-together; the item turns into trace mode with the full guide for this try (the same level 3 in all three courses). A missed stroke fades softly and the start dot comes back: never red, no buzzer. In a trace, only an answer at H0 or H1 marks the letter as practised; in copy, each level takes one more step of credit (copy alone counts as H1, E-1)."),
    ("HL-BLEND", "LS04 graphemes (B-18.G1). Before the choice only the sounds play, never the whole word (L5 §5.5). H1: he-hint-slide-again; the slide replays slowly, each letter lit as its sound plays (if a sound has no clip yet, the stretched whole is the H1 replay). H2 (a new representation, tokens with mouths): he-hint-mouth; each sound becomes a token with its mouth picture, left to right; for an M-ENG-DIR error the green start dot on the left and he-fb-left-start come first. H3: he-hint-showme; the friend slides, says the word and points to its picture; the child taps it. After any choice the whole word plays."),
    ("HL-STEM", "LS01 text stem, a word (B-18.G1). H1 'read it to me': he-hint-listen-word + the word clip; the credit drops to 0.8 (L5 §5.1). H2 (a new representation, borrowed from LS04, L5 §5.9): `hints.level2: { \"show\": \"blend_slide\" }` on the stem word, the slide with each sound lit. H3: he-hint-showme; the friend reads the word aloud with the slide and taps its picture; the child taps it."),
    ("HL-BOXES", "LS03 boxes (B-15). H1: he-hint-again + en-robot-<word>, the sounds one by one with a pause, then the word. H2 (a new representation, the mouth): he-hint-mouth; each token gets the mouth picture of its sound as it plays (not hand claps: a clap per syllable would teach M-ENG-SEG-SYLL in a one-syllable word). In the `which` step the tokens light one by one with their sounds, left to right. H3: he-hint-showme; the friend lays the tokens (or taps the box); then the child does it."),
]

# ------------------------------------------------------------------ pictures (new, plus reused from Band A)
PICS = [
    ("pic.sun", "Key word for s. A round yellow sun with short rays, on a plain sky; no face, no text."),
    ("pic.tent", "Key word for t. A small camping tent (a clear triangle from the front), its door open; no text."),
    ("pic.pan", "Key word for p, and a B-18 word. A frying pan with a long handle, seen from the side and a little above: flat, one handle. It must never look like a pot (pic.pot)."),
    ("pic.igloo", "Key word for i. A snow igloo with its round door and the block lines; no person."),
    ("pic.net", "Key word for n. A child's butterfly net: a round hoop with a mesh bag on a stick; no butterfly."),
    ("pic.ant", "One ant, big, side view, six legs, on a plain ground. Friendly, not scary."),
    ("pic.acorn", "One acorn with its cap (the NAME foil for a: acorn starts with the name /eɪ/)."),
    ("pic.ice-cream", "One ice cream cone with one scoop (the NAME foil for i: ice cream starts with the name /aɪ/). No brand."),
    ("pic.eagle", "One eagle perched, whole, side view (the /i/ foil for igloo: eagle starts with /i/, igloo with /ɪ/)."),
    ("pic.stones-path", "LS11 scene: a small stream with three flat stepping stones in a row, each with a blank top where the app draws a letter tile; Pip waits on the near bank; the far bank has grass. The stones are the same size and evenly spaced."),
    ("pic.nap", "Pip asleep on a small bed under a blanket, eyes closed, a soft night light; daytime is fine. No letters (no 'z z z')."),
    ("pic.tap", "Pip taps the frying pan of pic.pan with a wooden spoon, two small motion lines at the spoon. The same Pip as in pic.pat and pic.nap."),
    ("pic.pat", "Pip gently pats the head of the dog (Band A pic.dog, the same dog), the hand flat on its head; the dog looks happy."),
    ("pic.pin", "One push pin (thumbtack), big, side view: a round colored head and a short point. Shown alone, on a plain background."),
    ("pic.pine", "One pine tree (the NAME foil for pin: pin read with the name of i is 'pine')."),
    ("pic.tape", "One roll of clear sticky tape (the NAME foil for tap: tap read with the name of a is 'tape')."),
    ("pic.pot", "A cooking pot: deep, two side handles, a lid. Clearly not a frying pan."),
    ("pic.sock", "One striped sock on its own."),
    ("pic.dog-sit", "The dog of Band A pic.dog, sitting on its back legs (the B-18 word 'sit')."),
    ("pic.mouth-s", "Mouth picture for /s/: the same friendly face, front view, close-up of the mouth: teeth close together, lips a little apart, a small air line. One face for all six mouth pictures."),
    ("pic.mouth-a", "Mouth picture for /æ/: jaw dropped, mouth wide open, the corners pulled a little to the sides (not the round Hebrew /a/)."),
    ("pic.mouth-t", "Mouth picture for /t/: mouth a little open, the tip of the tongue up behind the top teeth (seen through the open lips), a small puff line."),
    ("pic.mouth-p", "Mouth picture for /p/: lips pressed together, a small puff line in front (two frames are fine: closed, then the puff)."),
    ("pic.mouth-i", "Mouth picture for /ɪ/: mouth a little open and relaxed, a small smile, not spread wide (not the /i/ of 'eagle')."),
    ("pic.mouth-n", "Mouth picture for /n/: lips a little apart, tongue tip up behind the top teeth, a small line at the nose (the sound goes through the nose)."),
]
STORY = [
    ("Look! Pip has a pan.", "Pip in a sunny kitchen holds up the frying pan of pic.pan."),
    ("Tap, tap, tap! Pip taps the pan.", "Pip taps the pan with a wooden spoon (as pic.tap); small motion lines."),
    ("Mika has a pin. Mika pins a picture on the wall.", "Mika pins a child's drawing of a sun on a cork board with a push pin."),
    ("Here is the dog. Sit, dog, sit! The dog sits.", "The dog (pic.dog) sits in front of Pip (as pic.dog-sit)."),
    ("Pip pats the dog. Pat, pat, pat!", "Pip pats the dog's head (as pic.pat); the dog wags its tail."),
    ("Pip is sleepy. Pip takes a nap. Shh!", "Pip asleep on a small bed (as pic.nap); Mika holds a finger up to the lips (shh)."),
]
for n, (_, scene) in enumerate(STORY, 1):
    PICS.append((f"pic.story-tap-{n}", f"Story \"Tap, Tap, Nap\" page {n}: {scene} The same Pip, Mika, dog and room on every page; no text."))
REUSED_PICS = ["pic.apple", "pic.egg", "pic.dog"]

# ------------------------------------------------------------------ English clips and pronunciation specs
# (id, shown, say, ipa, stress, traps, check)
CLIPS = []
SND_SAY = {"s": "sss", "a": "aa", "t": "t", "p": "p", "i": "ih", "n": "nnn"}
SND_FB = {"s": "sss… sun", "a": "a… a… apple", "t": "t… tent", "p": "p… pan", "i": "i… i… igloo", "n": "nnn… net"}
SND_TRAP = {
    "s": "an added vowel ('suh'); a lisp; too short to hear",
    "a": "Hebrew /a/ or /ɛ/ ('eh'); the name /eɪ/; a glide at the end",
    "t": "'tuh' (an added vowel); a dental Hebrew t; cut off at the start",
    "p": "'puh' (an added vowel); no puff of air; cut off at the start",
    "i": "Hebrew /i/ ('ee'); the name /aɪ/",
    "n": "an added vowel ('nuh'); too short",
}
SND_CHECK = {
    "s": "a steady hiss held about 0.7 s, no vowel after it",
    "a": "a clear /æ/ held about 0.4 s, jaw open, no glide; not 'eh', not 'ay'",
    "t": "one crisp aspirated burst, no vowel after it",
    "p": "one crisp aspirated burst (a puff), no vowel after it",
    "i": "a short lax /ɪ/ held about 0.4 s; not 'ee', not 'eye'",
    "n": "a steady hum held about 0.7 s, no vowel after it",
}
for x in GROUP1:
    CLIPS.append((f"en-snd-{x}", x, SND_SAY[x], SND_IPA[x], "-", SND_TRAP[x],
                  SND_CHECK[x] + f". The isolated form is for the D2 pilot (voice-brief §5); if it fails, the D2 fallback is '{SND_FB[x]}' under the same id (no item changes)."))
NAME_SAY = {"s": "S.", "a": "A.", "t": "T.", "p": "P.", "i": "I.", "n": "N."}
NAME_TRAP = {"s": "'es' with a Hebrew e; the sound /s/ alone", "a": "a flat Hebrew /e/ with no glide; the sound /æ/",
             "t": "Hebrew /ti/ with a dental t (fine), 'tee' too short", "p": "'pee' with no aspiration",
             "i": "the sound /ɪ/; Hebrew 'ai' (fine if the glide is full)", "n": "'en' with a Hebrew e; the sound /n/ alone"}
for x in GROUP1:
    CLIPS.append((f"en-name-{x}", x, NAME_SAY[x], NAME_IPA[x], "-", NAME_TRAP[x],
                  f"the letter's name {NAME_IPA[x]}, said as a letter name (GA), clearly not its sound {SND_IPA[x]}"))
WORDS = {
    # id-word: (ipa, stress, traps, check)
    "sun": ("/sʌn/", "sun", "/a/ or /u/ for /ʌ/ (M-ENG-UH)", "key word for s: the /s/ clean and a little long at the start; /ʌ/"),
    "tent": ("/tɛnt/", "tent", "the final nt cut to 'ten'; an added vowel 'tenta'", "key word for t: aspirated t at the start; /ɛ/; the final t released and audible"),
    "pan": ("/pæn/", "pan", "said as 'pen' (/ɛ/) or Hebrew /a/", "key word for p and a B-18 word: aspirated p; a clear /æ/ (GA may raise it before n: still clearly not 'pen')"),
    "igloo": ("/ˈɪɡlu/", "IG-loo", "'eegloo' with /i/; stress on the second", "key word for i: lax /ɪ/ first, stressed"),
    "net": ("/nɛt/", "net", "the final t swallowed", "key word for n: /n/ clean at the start; the final t released"),
    "ant": ("/ænt/", "ant", "Hebrew /a/; the final t dropped", "/æ/; the final t audible"),
    "acorn": ("/ˈeɪkɔrn/", "A-corn", "a flat /e/", "/eɪ/ glide at the start, clearly the name of a; rhotic r"),
    "ice-cream": ("/ˈaɪs ˌkrim/", "ICE-cream", "'ais krim' with a Hebrew r (accent only)", "/aɪ/ at the start, clearly the name of i; stress on ice"),
    "eagle": ("/ˈiɡəl/", "EA-gle", "/ɪ/ for /i/", "a long tense /i/ at the start, clearly different from the /ɪ/ of igloo; dark l"),
    "nap": ("/næp/", "nap", "'nep'", "/æ/; the final p released"),
    "tap": ("/tæp/", "tap", "'tep'", "/æ/; the final p released"),
    "pat": ("/pæt/", "pat", "'pet'; a final t flapped or swallowed", "/æ/; the final t released (never a glottal stop here)"),
    "pin": ("/pɪn/", "pin", "'peen' with /i/; 'pen'", "lax /ɪ/, clearly not /i/ and not /ɛ/"),
    "sit": ("/sɪt/", "sit", "'seat' with /i/", "lax /ɪ/; the final t released"),
    "pine": ("/paɪn/", "pine", "", "/aɪ/ full glide"),
    "tape": ("/teɪp/", "tape", "", "/eɪ/ full glide; the final p released"),
    "pot": ("/pɑt/", "pot", "Hebrew /o/ (M-ENG-O, accent)", "GA /ɑ/; the final t released"),
    "sock": ("/sɑk/", "sock", "Hebrew /o/", "GA /ɑ/; the final k released"),
}
for w, (ipa, st, tr, ck) in WORDS.items():
    CLIPS.append((f"en-{w}", w.replace("-", " "), w.replace("-", " ") + ".", ipa, st, tr or "-", ck))
BLENDS = {"pan": "p-aaa-nnn… pan.", "nap": "nnn-aaa-p… nap.", "tap": "t-aaa-p… tap.", "pat": "p-aaa-t… pat.", "pin": "p-iii-nnn… pin."}
for w, say in BLENDS.items():
    CLIPS.append((f"en-blend-{w}", w, say, WORDS[w][0], w, "an added vowel after a stop ('puh'); the vowel too short to hear",
                  "LS04 'whole stretched' clip (L5 §5.5): the continuous sounds (a, i, n, s) stretched into the next one, the stops clipped, no 'uh'; then the word said normally after a short pause. In a scored item it never plays before the first choice: it is the H1 replay when a part has no clip of its own (D2)"))
ROBOT = {"pin": "p. ih. nnn. … pin.", "sit": "sss. ih. t. … sit.", "nap": "nnn. aa. p. … nap."}
for w, say in ROBOT.items():
    CLIPS.append((f"en-robot-{w}", w, say, WORDS[w][0], w, "an added vowel on a stop; gaps too short",
                  "robot talk (voice-brief §5.2): each sound as in en-snd, about 350 ms apart, then the word after about 600 ms. May be assembled from the en-snd clips and en-" + w + " (no voicing of its own)"))
for n, (line, _) in enumerate(STORY, 1):
    CLIPS.append((f"en-st-tap-{n}", line, line, "-", "-", "'taps', 'pats', 'sits' with a weak final s (keep it); 'the' as /ðə/; 'a' as /ə/",
                  "story page: slow, warm, the key word (pan, tap, pin, sit, pat, nap) clearly stressed; the repeated words on a beat"))
EXISTING_EN = None  # filled from pronunciation.csv

# ------------------------------------------------------------------ items
ITEMS = []
def item(**k):
    k.setdefault("flags", "")
    k.setdefault("note", "")
    k.setdefault("spec", None)
    ITEMS.append(k)

INTRO_ORDER = ["s", "a", "t", "p", "i", "n"]
for n, x in enumerate(INTRO_ORDER, 1):
    item(skill="ENG-B-23.G1", id=f"n{n:02d}", tmpl="LS02", mode="intro", scored=False,
         frame=["he-ins-letter-new", "he-ltr-sound", "he-ltr-keyword", "he-ltr-name", "he-ltr-watch", "he-ins-trace"],
         prompt=[f"en-snd-{x}", f"en-{KEY[x]}", f"en-name-{x}"], pics=[f"pic.{KEY[x]}"],
         options=[f"form latin.{x}"], right="-", dist=[], hints="HL-WRITE", rep="embodied",
         note=(f"Bundle opener (E-2), filed under the trace node B-23.G1 (writing-mastery §8 rule 1). Sequence: the letter big → he-ltr-sound + en-snd-{x} → he-ltr-keyword + en-{KEY[x]} with pic.{KEY[x]} → "
               f"he-ltr-name + en-name-{x} → he-ltr-watch while the dot walks the path → he-ins-trace, one trace with the full guide (unscored)."
               + (" The name does not carry the sound (a vowel's name is its long sound), so this intro says both slowly, twice." if x in "ai" else "")),
         spec={"type": "trace", "templateVersion": "2.0", "mode": "intro", "canvas": "letter", "forms": [f"latin.{x}"],
               "prompt": {"vo": "vo:he-ins-letter-new", "sound": f"vo:en-snd-{x}", "keyword": f"vo:en-{KEY[x]}", "name": f"vo:en-name-{x}", "picture": f"pic.{KEY[x]}"}})

def ls01(skill, iid, mode, frame, prompt, options, right, dist, hints, rep, flags="", note="", stem=None, pics=None, all_right=None):
    spec = {"type": "tap_answer", "mode": mode, "options": options}
    if stem: spec["scene"] = {"stem": stem}
    if all_right is not None: spec["answer"] = {"all": True, "correct": all_right}
    else: spec["answer"] = {"correct": right}
    pp = [o for o in options if o.startswith("pic.")] + (pics or [])
    item(skill=skill, id=iid, tmpl="LS01", mode=mode, scored=True, frame=frame, prompt=prompt, pics=pp, options=options,
         right=right, dist=dist, hints=hints, rep=rep, flags=flags, note=note, spec=spec, all_right=all_right)

S = "ENG-B-16"
ls01(S, "i01", "letter tiles", ["he-ins-sound-letter"], ["en-snd-t"], ["tile:t", "tile:f", "tile:l"], "tile:t",
     [("tile:f", "M-ENG-LOOKALIKE"), ("tile:l", "M-ENG-LOOKALIKE")], "HL-SND2LTR", "symbolic", "P")
ls01(S, "i02", "letter tiles", ["he-ins-sound-letter"], ["en-snd-a"], ["tile:a", "tile:o", "tile:d"], "tile:a",
     [("tile:o", "M-ENG-LOOKALIKE"), ("tile:d", "M-ENG-LOOKALIKE")], "HL-SND2LTR", "symbolic", "C")
ls01(S, "i03", "letter tiles", ["he-ins-sound-letter"], ["en-snd-p"], ["tile:p", "tile:q", "tile:b"], "tile:p",
     [("tile:q", "M-ENG-BD"), ("tile:b", "M-ENG-BD")], "HL-SND2LTR", "symbolic", "P",
     note="q and b are p turned over: the b/d family (M-ENG-BD covers p/q). `revisitWith` stays for group 2 (b/d).")
ls01(S, "i04", "letter tiles", ["he-ins-name-letter"], ["en-name-n"], ["tile:n", "tile:h", "tile:m"], "tile:n",
     [("tile:h", "M-ENG-LOOKALIKE"), ("tile:m", "M-ENG-LOOKALIKE")], "HL-NAME2LTR", "symbolic", "C")
ls01(S, "i05", "letter tiles", ["he-ins-name-letter"], ["en-name-i"], ["tile:i", "tile:l", "tile:j"], "tile:i",
     [("tile:l", "M-ENG-LOOKALIKE"), ("tile:j", "M-ENG-LOOKALIKE")], "HL-NAME2LTR", "symbolic")
for iid, x in (("i06", "s"), ("i07", "i"), ("i08", "n")):
    ls01(S, iid, "text stem + sound options", ["he-ins-letter-sound"], [], [f"snd:en-snd-{x}", f"snd:en-name-{x}"], f"snd:en-snd-{x}",
         [(f"snd:en-name-{x}", "M-ENG-LETTERNAME")], "HL-LTR2SND", "symbolic", stem={"text": x},
         note="2 choices: the sound or the name (the syllabus signal 'picks the name when asked for the sound'). On the error: he-fb-check, then he-fb-name-not-sound + the sound.")
for iid, x in (("i09", "s"), ("i10", "t"), ("i11", "p"), ("i12", "a")):
    ls01(S, iid, "text stem + sound options", ["he-ins-letter-name"], [], [f"snd:en-name-{x}", f"snd:en-snd-{x}"], f"snd:en-name-{x}",
         [(f"snd:en-snd-{x}", "M-ENG-LETTERNAME")], "HL-LTR2SND", "symbolic", stem={"text": x},
         note="2 choices: the name or the sound; the same name-sound mix-up seen from the other side (family NAME). On the error: he-fb-check, then he-fb-sound-not-name + the name.")
ls01(S, "i13", "text stem + picture options", ["he-ins-letter-pic"], [], ["pic.ant", "pic.acorn", "pic.egg"], "pic.ant",
     [("pic.acorn", "M-ENG-LETTERNAME"), ("pic.egg", "M-ENG-AE-E")], "HL-LTR2PIC", "pictorial", stem={"text": "a"},
     note="ant, not the key word apple, so the child applies the sound to a new word. acorn starts with the name /eɪ/; egg with /ɛ/, the vowel a Hebrew speaker takes for /æ/. Each picture plays its word on a tap (en-ant, en-acorn, en-egg).")
ls01(S, "i14", "text stem + picture options", ["he-ins-letter-pic"], [], ["pic.igloo", "pic.ice-cream", "pic.eagle"], "pic.igloo",
     [("pic.ice-cream", "M-ENG-LETTERNAME"), ("pic.eagle", "M-ENG-IH")], "HL-LTR2PIC", "pictorial", "C", stem={"text": "i"},
     note="ice cream starts with the name /aɪ/; eagle with /i/, the Hebrew vowel a child hears for /ɪ/ (igloo /ˈɪɡlu/ and eagle /ˈiɡəl/ differ only in that vowel's quality).")
ls01(S, "i15", "tap-all", ["he-ins-tap-all"], ["en-snd-t"], ["tile:t", "tile:i", "tile:t", "tile:f", "tile:l", "tile:t"],
     "tile:t ×3 (cards 1, 3, 6)", [("tile:i", "M-ENG-LOOKALIKE"), ("tile:f", "M-ENG-LOOKALIKE"), ("tile:l", "M-ENG-LOOKALIKE")],
     "HL-TAPALL", "symbolic", all_right=[0, 2, 5],
     note="A row of 6 tiles, left to right (at most 6 under Band B, L5 §5.1). Right only when the three t and no other tile are tapped. i is a taught letter: a tall stick with a mark, the t look-alike inside group 1.")
item(skill=S, id="i16", tmpl="LS11", mode="place", scored=True, frame=["he-ins-hop"], prompt=["en-snd-n"],
     pics=["pic.stones-path"], options=["stone:n", "stone:h", "stone:m"], right="stone:n",
     dist=[("stone:h", "M-ENG-LOOKALIKE"), ("stone:m", "M-ENG-LOOKALIKE")], hints="HL-HOP", rep="embodied",
     note="Pip is dragged to a stone; each stone shows a letter tile (a text face on an LS11 target, L5-1). The embodied representation of B-16.",
     spec={"type": "listen_do", "mode": "place", "scene": "pic.stones-path", "targets": ["txt:n", "txt:h", "txt:m"], "answer": {"correct": "txt:n"}})

W = "ENG-B-19.G1"
T = "ENG-B-23.G1"
CLASSIFY = {
    "s": {"start": "M-ENG-STROKE-RTL", "direction": "M-ENG-STROKE-CW", "lines": "M-ENG-LINES", "mirror": "M-ENG-STROKE-CW"},
    "a": {"start": "M-ENG-STROKE-RTL", "direction": "M-ENG-STROKE-CW", "lines": "M-ENG-LINES"},
    "t": {"start": "M-ENG-STROKE-RTL", "direction": "M-ENG-STROKE-RTL", "lines": "M-ENG-LINES"},
    "p": {"start": "M-ENG-STROKE-RTL", "direction": "M-ENG-STROKE-RTL", "lines": "M-ENG-LINES", "mirror": "M-ENG-BD",
          "partners": {"latin.q": "M-ENG-BD", "latin.b": "M-ENG-BD"}},
    "i": {"start": "M-ENG-STROKE-RTL", "direction": "M-ENG-STROKE-RTL", "lines": "M-ENG-LINES"},
    "n": {"start": "M-ENG-STROKE-RTL", "direction": "M-ENG-STROKE-RTL", "lines": "M-ENG-LINES"},
}
def ls02(iid, x, mode, scored, flags="", **extra):
    frame = {"trace": ["he-ins-trace"], "copy": ["he-ins-copy"]}.get(mode)
    prompt = []
    if mode == "memory":
        frame = ["he-ins-write-sound"] if extra["cue"] == "sound" else ["he-ins-write-name"]
        prompt = [f"en-snd-{x}"] if extra["cue"] == "sound" else [f"en-name-{x}"]
    spec = {"type": "trace", "templateVersion": "2.0", "mode": mode, "canvas": "letter", "forms": [f"latin.{x}"]}
    spec.update(extra)
    spec["prompt"] = {"vo": "vo:" + frame[0]} | ({"target": "vo:" + prompt[0]} if prompt else {})
    spec["classify"] = CLASSIFY[x]
    opt = f"form latin.{x}; " + "; ".join(f"{k} {v}" for k, v in extra.items())
    item(skill=T if mode == "trace" else W, id=iid, tmpl="LS02", mode=mode, scored=scored, frame=frame, prompt=prompt, pics=[], options=[opt], right="ok",
         dist=[(k, v) for k, v in CLASSIFY[x].items() if k != "partners"] + [(f"partner {p}", t) for p, t in CLASSIFY[x].get("partners", {}).items()],
         hints="HL-WRITE", rep="embodied", flags=flags, spec=spec, form=x, cue=extra.get("cue"),
         note={"trace": ("Lead-up practice (E-1): never writing evidence, and a full-guide trace does not count toward 'practised'." if extra.get("guide") == "full" else "Practice (E-1): never writing evidence; right with the start dot at hint level 0 or 1, it marks this letter as practised for B-23.G1."),
               "copy": "Counts like a level-1 hinted answer (E-1).",
               "memory": "Counts in full (E-1)."}[mode])
ls02("t01", "s", "trace", False, guide="full")
for k, x in enumerate(GROUP1):
    ls02(f"t{2 + k:02d}", x, "trace", False, guide="start")
ls02("w03", "a", "copy", True, model="beside")
ls02("w04", "n", "copy", True, model="beside")
for k, x in enumerate(GROUP1):
    ls02(f"w{5 + k:02d}", x, "memory", True, flags="C" if x == "t" else "", cue="sound")
for k, x in enumerate(GROUP1):
    ls02(f"w{11 + k:02d}", x, "memory", True, flags="C" if x == "p" else "", cue="name")

R = "ENG-B-18.G1"
item(skill=R, id="s01", tmpl="LS08", mode="listen + dialogic", scored=False, frame=["he-ins-story"],
     prompt=[f"en-st-tap-{n}" for n in range(1, 7)], pics=[f"pic.story-tap-{n}" for n in range(1, 7)],
     options=["tap a picture: its word (pan, tap, pin, sit, pat, nap)"], right="-", dist=[], hints="-", rep="story",
     note="The word meet (syllabus §4.3 step 1): the six reading words heard with pictures in a story before any is read. A new word set, so it never shares a visit with a new letter group (E-5). Tapping the pan, the pin, the dog sitting or Pip asleep plays en-pan, en-pin, en-sit, en-nap; the spoon plays en-tap, Pip's hand on the dog en-pat.",
     spec={"type": "story", "mode": "listen", "pages": [{"clip": f"vo:en-st-tap-{n}", "picture": f"pic.story-tap-{n}"} for n in range(1, 7)]})
def ls04(iid, word, options, dist, flags=""):
    parts = [{"text": c, "clip": f"vo:en-snd-{c}", "stretch": c in "asin"} for c in word]
    spec = {"type": "blend_slide", "templateVersion": "1.0", "mode": "graphemes",
            "word": {"text": word, "parts": parts, "whole": f"vo:en-{word}", "stretched": f"vo:en-blend-{word}"},
            "answer": {"options": options, "correct": f"pic.{word}"}}
    item(skill=R, id=iid, tmpl="LS04", mode="graphemes", scored=True, frame=["he-ins-slide", "he-ins-slide-pick"],
         prompt=[f"en-snd-{c}" for c in word] + [f"en-blend-{word}", f"en-{word}"], pics=options, options=options,
         right=f"pic.{word}", dist=dist, hints="HL-BLEND", rep="symbolic", flags=flags, spec=spec, word=word,
         note="The slide is practice; only the picture choice is scored (L5 §5.5). Before the choice only the sounds play; the whole word plays after it. Parts: " + " · ".join(f"{c} ({'stretched' if c in 'asin' else 'clipped'})" for c in word) + ".")
ls04("r01", "pan", ["pic.pan", "pic.nap", "pic.pin"], [("pic.nap", "M-ENG-DIR"), ("pic.pin", "M-ENG-FIRSTLETTER-GUESS")], "C")
ls04("r02", "nap", ["pic.nap", "pic.pan", "pic.net"], [("pic.pan", "M-ENG-DIR"), ("pic.net", "M-ENG-FIRSTLETTER-GUESS")])
ls04("r03", "tap", ["pic.tap", "pic.pat", "pic.tape"], [("pic.pat", "M-ENG-DIR"), ("pic.tape", "M-ENG-LETTERNAME")], "C")
ls04("r04", "pat", ["pic.pat", "pic.tap", "pic.pot"], [("pic.tap", "M-ENG-DIR"), ("pic.pot", "M-ENG-FIRSTLETTER-GUESS")])
ls04("r05", "pin", ["pic.pin", "pic.pine", "pic.pan"], [("pic.pine", "M-ENG-LETTERNAME"), ("pic.pan", "M-ENG-FIRSTLETTER-GUESS")])
ls01(R, "r06", "text stem + picture options", ["he-ins-read-pick"], [], ["pic.dog-sit", "pic.sun", "pic.sock"], "pic.dog-sit",
     [("pic.sun", "M-ENG-FIRSTLETTER-GUESS"), ("pic.sock", "M-ENG-FIRSTLETTER-GUESS")], "HL-STEM", "symbolic",
     stem={"text": "sit", "clip": "vo:en-sit"}, note="Read with no slide. 'Read it to me' is H1 (credit 0.8). sun and sock share the first letter only.")
ls01(R, "r07", "text stem + picture options", ["he-ins-read-page"], [], ["pic.story-tap-5", "pic.story-tap-2", "pic.story-tap-1"], "pic.story-tap-5",
     [("pic.story-tap-2", "M-ENG-DIR"), ("pic.story-tap-1", "M-ENG-FIRSTLETTER-GUESS")], "HL-STEM", "story",
     stem={"text": "pat", "clip": "vo:en-pat"}, note="After the story, in its scene: the word card 'pat' and three page pictures (pat, tap, pan). The story representation of B-18.")

B = "ENG-B-15"
def ls03(iid, word, which_snd, which_box):
    units = [{"clip": f"vo:en-snd-{c}", "kind": "vowel" if c in "ai" else "c"} for c in word]
    classify = {"count=1": "M-ENG-SEG-SYLL", "count=4": "M-ENG-ADDVOWEL"}
    mirror = 4 - which_box
    if mirror != which_box:
        classify[f"which={mirror}"] = "M-ENG-DIR"
    spec = {"type": "sound_boxes", "templateVersion": "1.1", "mode": "boxes", "unit": "phoneme",
            "word": {"sprite": f"pic.{'dog-sit' if word == 'sit' else word}", "clip": f"vo:en-{word}", "slow": f"vo:en-robot-{word}", "units": units},
            "steps": ["count", "which"], "answer": {"count": 3, "which": which_box}, "classify": classify}
    item(skill=B, id=iid, tmpl="LS03", mode="boxes", scored=True, frame=["he-ins-boxes", "he-ins-which-box"],
         prompt=[f"en-{word}", f"en-snd-{which_snd}"], pics=[spec["word"]["sprite"]],
         options=[f"tokens into 3 boxes (left to right), then tap the box of {SND_IPA[which_snd]}"], right=f"n=3.w={which_box}",
         dist=[(k, v) for k, v in classify.items()], hints="HL-BOXES", rep="concrete", spec=spec, word=word,
         note=f"Response code `n=3.w={which_box}`. A count of 2, or off by 2 or more, is a retry with no tag; a wrong box other than the mirror box is a retry with no tag.")
ls03("b01", "pin", "n", 3)
ls03("b02", "sit", "s", 1)
ls03("b03", "nap", "a", 2)

# ------------------------------------------------------------------ lessons (visits)
LESSONS = [
    ("V1", "the bundle opens (s a t)", "n01 n02 n03 · i10 · i06 · i02 · i01 · t01 t02 t03 t04", "he-ltr-ltr before t01. The bundle (B-16 with B-23.G1) counts as one new skill (E-2); three new letters, within the ceiling of 3 (frame §4.6 P6)."),
    ("V2", "the bundle continues (p i n)", "n04 n05 n06 · i04 · i07 · i11 · i05 · i08 · i16 · t05 t06 t07", "No new word set (E-5). With t02 to t07 right at hint level 0 or 1, B-23.G1 is practised, so B-19.G1 can open next. The co-play card is shown to the parent after this visit."),
    ("V3", "the four facets mixed; B-19.G1 opens: copy and the first memory writing", "i03 · i12 · i09 · i13 · i14 · i15 · w03 · w04 · w05 w06 w07", "B-19.G1 is the visit's new skill, after the bundle (E-1). Memory with the sound cue, day 1."),
    ("V4", "the word meet (a new word set, no new letters) and sound boxes", "s01 · b01 b02 b03 · w08 w09 w10 · w11 w12 w13", "Memory with the sound cue for p i n, and with the name cue for s a t: each letter meets its two cues on two different days (E-1)."),
    ("V5", "the first reading", "he-ltr-ltr · r01 r02 r03 r04 r05 · r06 · r07 · w14 w15 w16", "Reading words only from s a t p i n; memory with the name cue for p i n (their sound cue was V4)."),
]
COPLAY = {"id": "card.eng.b16.g1", "course": "eng", "skills": ["ENG-B-16", "ENG-B-23.G1"], "kind": "coplay",
          "text": "היום הכירו הילדים שש אותיות באנגלית: s a t p i n. לכל אות יש צליל ויש שם, ובקריאה משתמשים בצליל. משחק לבית: בחרו אות אחת, ומצאו יחד בבית דברים שמתחילים בצליל שלה. אמרו את הצליל עצמו, קצר ונקי, בלי תנועה אחריו.",
          "meaning": "Today the children met six letters in English: s a t p i n. Every letter has a sound and a name, and in reading we use the sound. A game for home: choose one letter, and together find things at home that start with its sound. Say the sound itself, short and clean, with no vowel after it.",
          "review": "needs-editor"}

# ------------------------------------------------------------------ reading the sources
def read(p):
    with open(os.path.join(ROOT, p), encoding="utf-8") as f:
        return f.read()

def sources():
    syl = read("docs/languages/english/syllabus.md")
    skills = set(re.findall(r"^\| (ENG-[ABC]-\d\d(?:\.G\d)?) \|", syl, re.M))
    tags8 = set(re.findall(r"^\| (M-ENG-[A-Z0-9-]+) \|", syl, re.M))
    frame = read("docs/languages/frame.md")
    cat = frame.split("<!-- catalogue:eng:start -->")[1].split("<!-- catalogue:eng:end -->")[0]
    cat_rows = {}
    for m in re.finditer(r"^\| (M-ENG-[A-Z0-9-]+) \| `([a-z0-9._]+)` \| ([^|]+) \| ([A-Z]+) \|", cat, re.M):
        cat_rows[m.group(1)] = (m.group(2), m.group(3).strip(), m.group(4))
    bandA = read("docs/languages/english/band-a-content.md")
    he_a = set(re.findall(r"^\| (he-[a-z0-9-]+) \|", bandA, re.M))
    pics_a = set(re.findall(r"^\| (pic\.[a-z0-9-]+) \|", bandA, re.M))
    csv = read("docs/languages/english/pronunciation.csv")
    en_csv = set(l.split(",")[0] for l in csv.splitlines()[1:] if l)
    latin = json.loads(read("content/languages/strokes/latin.json"))
    forms = {f["id"]: f for f in latin["forms"]}
    l5 = read("docs/milestones/L5.md")
    return dict(skills=skills, tags8=tags8, cat=cat_rows, he_a=he_a, pics_a=pics_a, en_csv=en_csv,
                forms=forms, latin_review=latin["review"], l5=l5, syl=syl)

TEMPLATE_MODES = {  # (template, mode) → a phrase that must appear in L5.md for that mode
    ("LS01", "letter tiles"): "text faces", ("LS01", "text stem + sound options"): "text stem",
    ("LS01", "text stem + picture options"): "text stem", ("LS01", "tap-all"): "tap-all",
    ("LS02", "intro"): "`intro`", ("LS02", "trace"): "`trace`", ("LS02", "copy"): "`copy`", ("LS02", "memory"): "`memory`",
    ("LS03", "boxes"): "`boxes`", ("LS04", "graphemes"): "`graphemes`", ("LS08", "listen + dialogic"): "`dialogic`",
    ("LS11", "place"): "`place`",
}

def checks(src, items):
    errs, ok = [], []
    def need(cond, msg):
        (ok if cond else errs).append(msg)
    he_ids = {h[0] for h in HE_NEW} | src["he_a"]
    pic_ids = {p[0] for p in PICS} | src["pics_a"]
    en_ids = {c[0] for c in CLIPS} | src["en_csv"]
    accent = {t for t, (_, kind, fam) in src["cat"].items() if fam == "ACCENT" or kind.startswith("accent")}
    for h in HE_REUSED:
        need(h in src["he_a"], f"reused Hebrew line {h} exists in the Band A batch")
    for h, he, _, _ in HE_NEW:
        need(h not in src["he_a"], f"new Hebrew id {h} does not clash with Band A")
        need(not re.search(r"[A-Za-z]", he), f"Hebrew line {h} has no Latin letters")
        need(re.search(r"[\u05d0-\u05ea]", he) is not None, f"Hebrew line {h} is Hebrew")
        need(not re.search(r"(^|\s)(אני|אתה|לך|שלך)(\s|[.,:?!]|$)", he),f"Hebrew line {h} has no singular or first-person address")
    for c in CLIPS:
        need(c[0] not in src["en_csv"] or c[0] in ("en-apple", "en-egg"), f"new clip {c[0]} does not clash with pronunciation.csv")
        need(not re.search(r"[\u0590-\u05ff\u0400-\u04ff]", c[1] + c[2]), f"English clip {c[0]} is Latin only")
    need(len({c[0] for c in CLIPS}) == len(CLIPS), "clip ids unique")
    need(len({p[0] for p in PICS}) == len(PICS), "picture ids unique")
    for p in REUSED_PICS:
        need(p in src["pics_a"], f"reused picture {p} has a Band A brief")
    need(src["latin_review"] == "teacher-checked", "the latin stroke set is teacher-checked")
    seen = set()
    by_skill = {}
    for it in items:
        key = it["skill"] + " " + it["id"]
        need(key not in seen, f"{key}: id unique"); seen.add(key)
        need(it["skill"] in src["skills"], f"{key}: skill exists in the syllabus")
        need((it["tmpl"], it["mode"]) in TEMPLATE_MODES and TEMPLATE_MODES[(it["tmpl"], it["mode"])] in src["l5"],
             f"{key}: template {it['tmpl']} mode '{it['mode']}' is specified in L5")
        for h in it["frame"]:
            need(h in he_ids, f"{key}: Hebrew line {h} exists")
        need(it["hints"] == "-" or it["hints"] in {l[0] for l in LADDERS}, f"{key}: hint ladder {it['hints']} is defined")
        for c in it["prompt"]:
            need(c in en_ids, f"{key}: clip {c} has a pronunciation row")
        for o in it["options"]:
            if o.startswith("snd:"):
                need(o[4:] in en_ids, f"{key}: sound option {o} has a row")
        for p in it["pics"]:
            need(p in pic_ids, f"{key}: picture {p} has a brief")
        sp = json.dumps(it["spec"], ensure_ascii=False) if it["spec"] else ""
        for c in re.findall(r"vo:([a-z0-9-]+)", sp):
            need(c in en_ids or c in he_ids, f"{key}: spec clip {c} exists")
        for f in re.findall(r"\"(latin\.[a-z.]+)\"", sp):
            need(f in src["forms"], f"{key}: form {f} exists in latin.json")
        tags = [t for _, t in it["dist"]]
        for t in tags:
            need(t in src["tags8"], f"{key}: tag {t} is defined in syllabus §8")
            need(t in src["cat"], f"{key}: tag {t} is in the frame §4.2 catalogue")
            need(t not in accent, f"{key}: tag {t} is not an accent tag")
        if it["tmpl"] == "LS02":
            need(all(src["cat"].get(t, ("", "", ""))[2] in ("STROKE", "SHAPE") for t in tags), f"{key}: LS02 classify tags are STROKE or SHAPE")
            if it["mode"] == "memory":
                need(bool(it["prompt"]) and it["spec"]["prompt"].get("target"), f"{key}: memory has its cue clip")
            if it["mode"] == "trace":
                need("guide" in it["spec"], f"{key}: trace has a guide")
            if it["mode"] == "copy":
                need(it["spec"].get("model") == "beside", f"{key}: copy has model beside (eng)")
            need(1 <= len(src["forms"].get(it["spec"]["forms"][0], {"strokes": []})["strokes"]) <= 6, f"{key}: form has 1 to 6 strokes")
            need(it["mode"] != "intro" or not it["scored"], f"{key}: intro is unscored")
        if it["tmpl"] in ("LS01", "LS04", "LS11") and it["scored"]:
            opts = it["options"]
            need(len(opts) <= (6 if it["mode"] == "tap-all" else 4), f"{key}: Band B choice limit")
            if it.get("all_right") is not None:
                rights = [opts[i] for i in it["all_right"]]
                wrong = [o for i, o in enumerate(opts) if i not in it["all_right"]]
                need(len(rights) >= 1 and len(wrong) >= 2, f"{key}: tap-all has 1+ right and 2+ wrong")
                need(all(o == rights[0] for o in rights) and rights[0] not in wrong, f"{key}: tap-all rights are one letter")
                need({o for o, _ in it["dist"]} == set(wrong), f"{key}: every wrong card tagged")
            else:
                need(opts.count(it["right"]) == 1, f"{key}: one right answer among the options")
                d_opts = [o for o, _ in it["dist"]]
                need(sorted(d_opts) == sorted(o for o in opts if o != it["right"]), f"{key}: every distractor tagged once")
                need(len(opts) in (2, 3), f"{key}: 2 or 3 choices")
        if it["tmpl"] == "LS03":
            sp = it["spec"]
            need(len(sp["word"]["units"]) == sp["answer"]["count"], f"{key}: units = count")
            need(1 <= sp["answer"]["which"] <= sp["answer"]["count"], f"{key}: which within the count")
        if it["tmpl"] == "LS04":
            w = it["spec"]["word"]
            need("".join(p["text"] for p in w["parts"]) == w["text"], f"{key}: parts join to the word")
        # decodable: every word read in B-18 uses only group-1 graphemes
        if it["skill"] == "ENG-B-18.G1" and it["spec"]:
            sc = it["spec"].get("scene")
            words = [it["spec"].get("word", {}).get("text")] + [sc.get("stem", {}).get("text") if isinstance(sc, dict) else None]
            for w in filter(None, words):
                need(set(w) <= set(GROUP1), f"{key}: '{w}' is decodable with s a t p i n")
        if it["tmpl"] == "LS01" and isinstance(it["spec"].get("scene"), dict) and it["spec"]["scene"].get("stem"):
            need(set(it["spec"]["scene"]["stem"]["text"]) <= set(GROUP1), f"{key}: stem uses taught letters only")
        by_skill.setdefault(it["skill"], []).append(it)
    # per-skill rules
    for sk, its in by_skill.items():
        scored = [i for i in its if i["scored"]]
        two = [i for i in scored if i["tmpl"] in ("LS01", "LS04", "LS11") and len(i["options"]) == 2]
        three = [i for i in scored if i["tmpl"] in ("LS01", "LS04", "LS11") and len(i["options"]) >= 3]
        need(len(two) * 2 <= len(scored), f"{sk}: 2-choice items at most half of the scored ({len(two)}/{len(scored)})")
        need(not two or three, f"{sk}: a skill with 2-choice items has 3-choice items")
        for i in its:
            if "C" in i["flags"]:
                need(i not in two, f"{sk} {i['id']}: a check is not a 2-choice item")
                need("P" not in i["flags"], f"{sk} {i['id']}: a check is not a probe")
                need(i["tmpl"] != "LS03", f"{sk} {i['id']}: an LS03 item is not a check")
            if "P" in i["flags"]:
                need(i["tmpl"] == "LS01" and not i["mode"].startswith("tap-all"), f"{sk} {i['id']}: a probe is a plain LS01 item")
        if sk == "ENG-B-23.G1":
            need(all(i["mode"] in ("intro", "trace") for i in its), f"{sk}: a trace node holds only intro and trace items (E-1)")
            need(not any(c in i["flags"] for i in its for c in "CP"), f"{sk}: a trace node has no check and no probe (E-1)")
            need({i["form"] for i in its if i["mode"] == "trace" and i["spec"].get("guide") == "start"} == set(GROUP1), f"{sk}: every letter has a start-dot trace (practised needs it)")
        if sk == "ENG-B-19.G1":
            need(not any(i["mode"] == "trace" for i in its), f"{sk}: a writing node has no trace item (E-1)")
            need(all(i["mode"] == "memory" for i in its if "C" in i["flags"]), f"{sk}: every check of a writing node is a memory item")
        if sk not in ("ENG-B-15", "ENG-B-23.G1"):
            checks_ = [i for i in its if "C" in i["flags"]]
            need(len(checks_) >= 2 and len({i["right"] if i["tmpl"] != "LS02" else i["form"] for i in checks_}) >= 2,
                 f"{sk}: at least two checks with different answers")
            reps = {i["rep"] for i in scored}
            need(len(reps) >= 2 or sk == "ENG-B-19.G1", f"{sk}: at least two representations among scored items ({sorted(reps)})")
    # set coverage per facet (E-3)
    b16 = by_skill["ENG-B-16"]
    def letter_of(i):
        r = i["right"]
        if r.startswith("tile:") or r.startswith("stone:"): return r.split(":")[1][0]
        if r.startswith("snd:"): return r.split("-")[-1]
        return i["spec"]["scene"]["stem"]["text"] if i["spec"].get("scene") else None
    snd = {letter_of(i) for i in b16 if i["scored"] and (any("en-snd" in c for c in i["prompt"]) or "snd:en-snd" in i["right"] or i["mode"] == "text stem + picture options")}
    name = {letter_of(i) for i in b16 if i["scored"] and (any("en-name" in c for c in i["prompt"]) or "snd:en-name" in i["right"])}
    need(snd == set(GROUP1), f"B-16 sound facet covers every letter ({sorted(snd)})")
    need(name == set(GROUP1), f"B-16 name facet covers every letter ({sorted(name)})")
    intro = {i["spec"]["forms"][0][-1] for i in by_skill["ENG-B-23.G1"] if i["mode"] == "intro"}
    need(intro == set(GROUP1), "B-23.G1 has an intro for every letter (the bundle opener)")
    w = by_skill["ENG-B-19.G1"]
    for cue in ("sound", "name"):
        cov = {i["form"] for i in w if i["mode"] == "memory" and i["cue"] == cue}
        need(cov == set(GROUP1), f"B-19.G1 memory with the {cue} cue covers every letter")
    rset = {i["word"] for i in by_skill["ENG-B-18.G1"] if i.get("word")} | {i["spec"]["scene"]["stem"]["text"] for i in by_skill["ENG-B-18.G1"] if i["tmpl"] == "LS01"}
    need(rset == {"pan", "nap", "tap", "pat", "pin", "sit"}, f"B-18.G1 every word of the set is read once ({sorted(rset)})")
    # lessons reference only real items, every item once
    ids = [i["id"] for i in items]
    used = []
    for _, _, seq, _ in LESSONS:
        used += [t for t in re.findall(r"\b[nirswbt]\d\d\b", seq)]
    need(sorted(used) == sorted(ids), "every item is in exactly one visit")
    need(not re.search(r"[A-Za-z]{2,}", COPLAY["text"].replace("s a t p i n", "")), "co-play card text is Hebrew (bar the letters)")
    return errs, ok

# ------------------------------------------------------------------ rendering
def fmt_opt(o):
    if o.startswith("tile:"): return f"tile `{o[5:]}`"
    if o.startswith("stone:"): return f"stone `{o[6:]}`"
    if o.startswith("snd:"): return f"button {o[4:]}"
    return o

def render(src):
    L = []
    A = L.append
    A("# English course: Band B pilot slice (ENG-2, group 1: s a t p i n)")
    A("")
    A("Owner: english-language-teacher. Date: 2026-11-06. Step L5-2c of `docs/milestones/L5.md` (approved by the owner on 2026-11-06 with every recommendation). Status: **draft for the team. Nothing is built or voiced.** The English is the teacher's (final after the listening check). Every Hebrew line here is a **draft, `\"review\": \"needs-editor\"`**, written without nikud for the hebrew-text-editor, who adds the nikud and the voice text. Every picture is a brief for the design-director. **Voices come later (owner, 2026-11-06):** every line is text with its clip id, listed as pending; nothing is paid.")
    A("")
    A("Built on: `syllabus.md` §2 (ENG-B-15, B-16, B-18.G1, B-19.G1, B-23.G1), §3.1 to §3.4 (group 1, blending, names), §5 (writing), §7 (sessions, Hebrew around the English), §8 (tags); `L5.md` §3.1, §5.1 to §5.5, §5.8, §5.9, §6 (E-1 to E-6), §7, §8; `frame.md` §2.3, §3.3, §4.2, §5.3; `strokes.md` (the `latin` set, teacher-checked); the format of `band-a-content.md`. Made and checked by a script (§12).")
    A("")
    A("## 1. What the slice holds, and why")
    A("- **L5 §8:** the pilot slice of English is group 1 (s a t p i n): **ENG-B-16** (the letters, whole), **ENG-B-23.G1** (tracing them, in the bundle), **ENG-B-19.G1** (copying and writing them from memory, after the bundle) and **ENG-B-18.G1** (the first words read; B-18 was split by group on 2026-11-06). It drives the new templates on real content before the full ENG-2b batch: LS01's new modes (letter tiles, text stem with sound or picture options, tap-all), **LS02 2.0** (intro, trace, copy, memory), LS04 `graphemes`, and **LS03 1.1** `boxes` (three ENG-B-15 items on group-1 words, so LS03 1.1 is tried on the words it must carry; they belong to ENG-2a and move there with it).")
    A("- **Every letter is taught whole (D16, frame §5.3):** each letter opens with an LS02 `intro` (shape, sound in a key word with a picture, name as a separate fact, the dot walks the path, one trace); then practice mixes the four facets: sound ↔ letter both ways, name ↔ letter both ways, letter → picture by its sound, and writing (copy, then memory cued by the sound **and** by the name). Blending uses sounds, never names.")
    A("- **Order inside the group:** s a t p i n (syllabus §3.1, the order that gives words from the first days: at, sat, tap). The writing items keep that order; each letter's start and direction cue comes from its formation family in the stroke data (strokes.md §5.1, Handwriting Without Tears): a is a Magic c letter (start at 2 o'clock, anticlockwise), s starts at 2 o'clock too, t and i are down strokes, p and n go down, then up and over.")
    A("- **Key words** (syllabus §3.1): s sun · a apple · t tent · p pan · i igloo · n net. Reading words (B-18.G1 set, each its own `variantGroup`): **pan, nap, tap, pat, pin, sit**, all decodable with s a t p i n, all CVC with one short vowel, none with a flapped t in its isolated form. They are first heard in an original story (s01) before any is read (syllabus §4.3: meaning first).")
    A("- **Everyday words stay** (owner: do not over-sanitise): a push pin, a frying pan, tape and a nap are ordinary things a child sees at home.")
    A("")
    A("## 2. The rules every item here follows (what differs from Band A)")
    A("- **Band B presentation:** up to 4 choices (tap-all up to 6 cards), 5 to 8 items an activity, short English letters and words on tiles in the teaching font (Nitznutz Letters, lowercase), left to right in isolated runs (F1, F2).")
    A("- **Hebrew frame, English target (D7, F3):** the Hebrew instruction is its own clip, then the English clip. A line ending in a colon is a carrier before an English clip. The Hebrew lines speak to the children in the plural, with no gendered first person (`hebrew-notes.md` §9.1).")
    A("- **Every distractor tagged, with the 2-choice rule (frame §2.3, L5 §5).** The tags of this slice: `M-ENG-LOOKALIKE` and `M-ENG-BD` (SHAPE: a look-alike letter), `M-ENG-LETTERNAME` (NAME: the name taken for the sound, or the sound for the name), `M-ENG-AE-E` and `M-ENG-IH` (CONTRAST: the vowel a Hebrew speaker hears instead), `M-ENG-DIR` (read right to left), `M-ENG-FIRSTLETTER-GUESS` (the first letter only), and in the free-response modes `M-ENG-STROKE-RTL`, `M-ENG-STROKE-CW`, `M-ENG-LINES`, `M-ENG-SEG-SYLL`, `M-ENG-ADDVOWEL`. No accent tag is on a distractor.")
    A("- **Look-alike letters outside the group** (f l o d q b h m j) appear only as wrong tiles that test the shape; they are never an answer and never read. Their tiles have no clip: a tap on one gets he-fb-look-alike, not its name, so no untaught letter is taught by accident.")
    A("- **2-choice items** are the 'sound or name?' items (i06 to i12): one tagged distractor, one retry only, never a check; B-16 also has 3-choice items, and 2-choice items are 7 of its 16 scored items.")
    A("- **Free response** (LS02, LS03): classifiers instead of distractors (L5 §5.2, §5.3); an error they cannot name is a retry with no tag and no evidence. LS02 feedback comes only at the end of a stroke; a missed stroke fades softly and the start dot comes back; never red.")
    A("- **Writing mastery (E-1, Q1 approved; `docs/languages/writing-mastery.md`):** trace is practice, in the trace node ENG-B-23.G1, which is met once every letter is traced once with the start dot only (t02 to t07); copy counts like a level-1 hint; memory counts in full; ENG-B-19.G1 is fresh only with memory successes on two days, one cued by the sound and one by the name. So every letter has a memory item with each cue (w05 to w16).")
    A("- **Set coverage (E-3):** every letter is the right answer of at least one item in each facet (sound, name, writing); every reading word of B-18.G1 is read once; every letter has a start-dot trace in B-23.G1.")
    A("- **Checks (C):** at least two per skill, with different answers, never a 2-choice item, never a probe. For ENG-B-19.G1 the checks are memory items (w07, w14): in a writing node every check is a memory item (frame §2.3, §4.6 P5). The trace node ENG-B-23.G1 has no check and no probe. ENG-B-15's three items here are not checks (free response); its checks come in ENG-2a.")
    A("- **Feedback** (curriculum §9.1, §9.2): right → he-fb-right-1 … 8 + the English clip of the answer (the sound, the name or the word). First error → he-fb-check, then the line the error names: he-fb-look-alike (a look-alike tile), he-fb-name-not-sound or he-fb-sound-not-name (LETTERNAME), he-fb-thats + the chosen picture's word + he-fb-listen-again + the target (a picture foil), he-fb-left-start (DIR). Every picture option plays its own word on a tap (LS01 (b)) and in that diagnostic line: en-ant, en-acorn, en-egg, en-igloo, en-ice-cream, en-eagle, en-pan, en-nap, en-net, en-tap, en-pat, en-tape, en-pot, en-pin, en-pine, en-sit, en-sun, en-sock; on a story page, its page line. LS02: he-fb-stroke-again, he-fb-round-way, he-fb-lines, he-fb-tail, he-fb-faces; after a success he-fb-watch-order and the model replays once in its order (stroke order is not scored, Q2).")
    A("- **Voices later (L5 §7):** every clip below is `voPending`; a pending clip is silent, the line's bubble shows, and a template that waits for a clip's end waits the fixed pause. **No family release of this slice before its sounds are voiced (Q7).**")
    A("- **Characters:** Pip and Mika, as in Band A (working names, design-director).")
    A("")
    A("## 3. Hebrew frame lines (new drafts, `needs-editor`)")
    A("Written by the English teacher for the hebrew-text-editor, who owns the wording, adds the nikud and the voice text (CLAUDE.md: nikud is never generated by a model). The meaning column says what each line must make clear.")
    A("")
    A("| Id | Hebrew (draft, no nikud) | Meaning | Used in | review |")
    A("|---|---|---|---|---|")
    for h, he, en, use in HE_NEW:
        A(f"| {h} | {he} | {en} | {use} | needs-editor |")
    A("")
    A("**Reused from the Band A batch** (final, `text-ready`): " + ", ".join(HE_REUSED) + ".")
    A("")
    A("## 4. Hint ladders (level 2 changes the representation, level 3 is \"show me\")")
    A("| Ladder | Steps |")
    A("|---|---|")
    for k, v in LADDERS:
        A(f"| {k} | {v} |")
    A("")
    A("## 5. Items per skill")
    A("Columns as in the Band A batch: the item; the template and mode; the Hebrew frame; the English prompt (clip ids, §9); the options (tiles, sound buttons, pictures, §10); the right answer; the distractors or classifiers with their tags; the hint ladder; the representation (frame §3.3.1). *not scored* marks practice. **C** an understanding or delayed check; **P** a placement probe (§8). Under each table, the item's template data in the shape of L5 §5 (for the app-developer's generator; clip ids are `vo:` ids).")
    sec = {"ENG-B-16": ("ENG-B-16 Group 1 letters, whole (bundle with ENG-B-23.G1)", "Set (each letter a `variantGroup`): s, a, t, p, i, n. Facets: sound, name (here), tracing (B-23.G1, in the bundle), writing (B-19.G1, after it); the shape is in every item."),
           "ENG-B-23.G1": ("ENG-B-23.G1 Tracing s a t p i n (the trace node, bundled with ENG-B-16)", "`writing: practised` (E-1). Set: s, a, t, p, i, n. The bundle's six intros (the worked example of each letter, with one full-guide trace) and the traces. Met once every letter is traced once with the start dot only, at hint level 0 or 1 (t02 to t07); never mastered, probed or checked, and it never blocks. Every answer here is practice: the classifiers below only choose the feedback line, never misconception evidence."),
           "ENG-B-19.G1": ("ENG-B-19.G1 Copying, then writing s a t p i n from memory (after the bundle)", "`writing: memory` (E-1); prerequisites B-23.G1 and B-16. Set: s, a, t, p, i, n. Forms from `content/languages/strokes/latin.json` (`teacher-checked`, 2026-11-05). Canvas `letter`, the four lines. Classifiers per letter, from the stroke data: **start** (the stroke begun at its other end) → `M-ENG-STROKE-RTL`; **direction** (a round part the other way: s, a) → `M-ENG-STROKE-CW`, (a straight stroke drawn from the wrong end or the bar right to left: t i n p) → `M-ENG-STROKE-RTL`; **lines** (off the guide lines; p's tail not below the base line) → `M-ENG-LINES`; **mirror** (s mirrored, drawn clockwise first) → `M-ENG-STROKE-CW`; (p mirrored, or a q or b instead) → `M-ENG-BD`. A missing i dot, or anything else, is a retry with no tag."),
           "ENG-B-18.G1": ("ENG-B-18.G1 The first words read (group 1)", "Set (each a `variantGroup`): pan, nap, tap, pat, pin, sit. Decodable with s a t p i n only (checked by script). The contrast line he-ltr-ltr plays once before r01."),
           "ENG-B-15": ("ENG-B-15 Split a word into its sounds (LS03 1.1 on group-1 words; ENG-2a items)", "Words: pin, sit, nap (3 sounds each). Unit `phoneme`, steps `count` then `which`. Classifiers (L5 §5.3, eng): one token for the whole word (the syllable count) → `M-ENG-SEG-SYLL`; 4 tokens (a vowel added after a stop, 'puh-i-n') → `M-ENG-ADDVOWEL`; in `which`, the mirror box (counting from the right, the Hebrew direction) → `M-ENG-DIR`.")}
    for sk in ("ENG-B-16", "ENG-B-23.G1", "ENG-B-19.G1", "ENG-B-18.G1", "ENG-B-15"):
        t, s = sec[sk]
        A("")
        A(f"### {t}")
        A(s)
        A("")
        A("| Item | Template | Hebrew frame | English prompt | Options | Right | Distractors (tag) | Hints | Rep. |")
        A("|---|---|---|---|---|---|---|---|---|")
        its = [i for i in ITEMS if i["skill"] == sk]
        for i in its:
            fl = "".join(f" **{c}**" for c in i["flags"])
            ns = "" if i["scored"] else " *not scored*"
            sc = i["spec"].get("scene") if i["spec"] else None
            stem = sc.get("stem") if isinstance(sc, dict) else None
            prompt = ", ".join(i["prompt"]) if i["prompt"] else "-"
            if stem:
                prompt = f"stem `{stem['text']}`" + (f" (read to me: {stem['clip'][3:]})" if stem.get("clip") else "")
            if i["tmpl"] == "LS02" and i["mode"] == "intro":
                prompt = ", ".join(i["prompt"]) + f" (with {i['pics'][0]})"
            opts = "; ".join(fmt_opt(o) for o in i["options"])
            if i["tmpl"] == "LS03": opts += f" (picture {i['pics'][0]})"
            dist = "; ".join(f"{fmt_opt(o)} ({t})" for o, t in i["dist"]) or "-"
            A(f"| {i['id']}{fl}{ns} | {i['tmpl']} {i['mode']} | {', '.join(i['frame'])} | {prompt} | {opts} | {fmt_opt(i['right'])} | {dist} | {i['hints']} | {i['rep']} |")
        A("")
        for i in its:
            if i["note"]:
                A(f"- {i['id']}: {i['note']}")
        A("")
        A("<details><summary>Template data</summary>")
        A("")
        A("```")
        for i in its:
            if i["spec"]:
                A(f"{i['id']}: " + json.dumps(i["spec"], ensure_ascii=False))
        A("```")
        A("</details>")
    A("")
    A("## 6. Lessons (visits)")
    A("Band B shape (syllabus §7.1): the hello routine → 3 retrieval items → one new thing → practice in two representations → a chant or a puppet turn → goodbye; 10 to 12 minutes. The retrieval items and the routine come from the oral skills (Band A and ENG-2a). E-2: the bundle opens with its intro items. E-5: a new letter group and a new word set never share a visit. E-1: memory with each cue on a different day.")
    A("")
    A("| Visit | New thing | Items in order | Why |")
    A("|---|---|---|---|")
    for v, what, seq, why in LESSONS:
        A(f"| {v} | {what} | {seq} | {why} |")
    A("")
    A("## 7. Co-play card (L5 §5.8, D9)")
    A(f"`{COPLAY['id']}` · course `eng` · skills {', '.join(COPLAY['skills'])} · kind `coplay` · shown in the parent area after V2, never voiced, never shown to the child · review `needs-editor`.")
    A("")
    A(f"- Hebrew (draft, no nikud): {COPLAY['text']}")
    A(f"- Meaning: {COPLAY['meaning']}")
    A("- For the editor: the six Latin letters stay as Latin letters in an isolated left-to-right run.")
    A("")
    A("## 8. Placement probes (strand L, level 1: letter sounds)")
    A("i01 (/t/) and i03 (/p/) are served with `purpose: probe` (no hints, warm feedback, no result shown; syllabus §6.3). Strand L is offered only with Band B or C presentation and the parent's \"knows some English letters\" tick. The other levels of strand L (group 2, CVC reading) come with ENG-2b.")
    A("")
    A("## 9. English clips and pronunciation specs (rows for `pronunciation.csv`, status `draft`)")
    A("Accent: General American (D5). `say` is the text for the voice; the shown text never changes to fix a voice. Letter sounds: the row names the isolated form for the D2 pilot and the stretched-word fallback; the pilot picks one later, under the same id (L5 §7.4). Reused rows already in the CSV: en-apple, en-egg.")
    A("")
    A("| id | shown | say | ipa | stress | accent | traps | check | status |")
    A("|---|---|---|---|---|---|---|---|---|")
    for c in CLIPS:
        A("| " + " | ".join(c[:5]) + " | General American | " + " | ".join(c[5:]) + " | draft |")
    A("")
    A("## 10. Pictures for the design-director")
    A("All original, no text in the picture, no brands, no franchise look, the Band A style; drawn from real references (owner's rule). Pip, Mika and the dog are the Band A characters. Letter tiles are drawn by the app in the teaching font, not as pictures. The LS03 tokens and boxes and the LS02 guide lines are the design-director's template layouts (L5-2b, L5-3), not pictures of this list. Reused from Band A, unchanged: " + ", ".join(REUSED_PICS) + ".")
    A("")
    A("| Picture | What it must show | Used by |")
    A("|---|---|---|")
    for p, brief in PICS:
        users = sorted({f"{i['skill'][4:]} {i['id']}" for i in ITEMS if p in i["pics"] or p in json.dumps(i["spec"] or {})})
        if p.startswith("pic.mouth-"): users.append("hints HL-LTR2PIC, HL-BLEND, HL-BOXES")
        if p in ("pic.ant", "pic.acorn") and not users: users = ["B-16 i13"]
        A(f"| {p} | {brief} | {', '.join(users) or '-'} |")
    A("")
    A("## 11. Counts and voicing (counted by the script)")
    A("| Skill | Items | Scored | 2-choice | Checks | Probes |")
    A("|---|---|---|---|---|---|")
    tot = [0] * 5
    for sk in ("ENG-B-16", "ENG-B-23.G1", "ENG-B-19.G1", "ENG-B-18.G1", "ENG-B-15"):
        its = [i for i in ITEMS if i["skill"] == sk]
        row = [len(its), sum(i["scored"] for i in its), sum(1 for i in its if i["scored"] and i["tmpl"] in ("LS01", "LS04", "LS11") and len(i["options"]) == 2),
               sum("C" in i["flags"] for i in its), sum("P" in i["flags"] for i in its)]
        tot = [a + b for a, b in zip(tot, row)]
        A(f"| {sk} | " + " | ".join(map(str, row)) + " |")
    A("| **Total** | " + " | ".join(f"**{n}**" for n in tot) + " |")
    A("")
    bytmpl = {}
    for i in ITEMS:
        bytmpl[f"{i['tmpl']} {i['mode']}"] = bytmpl.get(f"{i['tmpl']} {i['mode']}", 0) + 1
    A("- **By template:** " + "; ".join(f"{k} {v}" for k, v in sorted(bytmpl.items())) + ".")
    en_chars = sum(len(c[2]) for c in CLIPS)
    robot = sum(len(c[2]) for c in CLIPS if c[0].startswith("en-robot"))
    he_chars = sum(len(h[1]) for h in HE_NEW)
    A(f"- **English clips:** {len(CLIPS)} new rows (6 letter sounds, 6 letter names, {len(WORDS)} words, {len(BLENDS)} stretched blends, {len(ROBOT)} robot-talk lines that may be assembled, {len(STORY)} story pages); **{en_chars} characters** of `say` text ({en_chars - robot} without the robot lines). Plus 2 reused rows (en-apple, en-egg).")
    A(f"- **Hebrew clips:** {len(HE_NEW)} new frame lines, **{he_chars} characters** as drafted without nikud (the editor's voice text will differ a little); the co-play card is not voiced.")
    A(f"- **Pictures:** {len(PICS)} new briefs (including 6 story pages and 6 mouth pictures), {len(REUSED_PICS)} reused.")
    A(f"- **Total for one voicing of the slice:** about {en_chars + he_chars} characters, about {(en_chars + he_chars) * 0.08 / 1000:.2f} USD at the list price in `voices.md` (0.08 USD per 1,000). Counting rule: Unicode code points of the `say` text. Not counted: re-takes, the D2 fallback forms if the isolated sounds fail. **Nothing is voiced by Claude**; the owner runs every paid command.")
    A("")
    return "\n".join(L)

def render_checks(errs, ok, broken_ok):
    L = ["## 12. Checked by script, and not checked",
         f"Checked ({len(ok)} checks, **{'all pass' if not errs else str(len(errs)) + ' FAIL'}**, run 2026-11-06 by the generator of this file): every skill id is in `syllabus.md` §2; every tag is defined in syllabus §8 and is in the frame §4.2 catalogue, and none is an accent tag; LS02 classifiers are of family STROKE or SHAPE; every template and mode is specified in `L5.md`; every form id is in `content/languages/strokes/latin.json` and the set is `teacher-checked`, with 1 to 6 strokes; every Hebrew line referenced exists (new here, or `text-ready` in the Band A batch) and has no Latin letter and no singular or first-person address; every English clip referenced has a pronunciation row (here, or in `pronunciation.csv`) and is Latin only, with no id clash; every picture referenced has a brief (here, or in the Band A batch); one right answer among the options and every distractor tagged once; tap-all has at least 1 right and 2 tagged wrong cards and at most 6 cards; at most 4 choices elsewhere; the 2-choice rule (at most half of a skill's scored items, a skill with 2-choice items also has 3-choice items, a 2-choice item is never a check); at least two checks per skill with different answers, never a probe, never LS03 (the trace node B-23.G1 has none: it holds only intro and trace items, with a start-dot trace for every letter; the writing node B-19.G1 has no trace item, and its checks are memory items); probes are plain LS01 items; at least two representations per scored skill (B-19.G1 by the E-1 cue rule instead); intro items unscored, memory items with their cue clip, copy with `model: beside`, trace with a guide; LS03 units equal the count and `which` is inside it; LS04 parts join to the word; every B-18.G1 word and every text stem is decodable with s a t p i n; set coverage: an intro for each letter (in B-23.G1), each letter right in the sound facet and in the name facet, memory with the sound cue and with the name cue for each letter, each B-18.G1 word read once; every item in exactly one visit; the co-play text is Hebrew.",
         f"Self-test: a deliberately broken copy (an accent tag on a distractor, an unknown form id, a 2-choice check, a word with an untaught letter, a missing Hebrew line, one letter missing from the name facet) **{'fails as it should' if broken_ok else 'DID NOT FAIL'}**.",
         "",
         "**Not checked** (cannot be, or not by me): how any clip sounds (nothing is voiced; the listening check comes after voicing, pronunciation-spec §4), whether the isolated sounds are clean (the D2 pilot); the Hebrew wording and nikud (the hebrew-text-editor); the pictures (not drawn yet); that LS01 text faces, tap-all, LS02 2.0, LS03 1.1 and LS04 accept these exact data shapes (they are being built in L5-1 to L5-5; the shapes follow L5 §5 and may need small renames); the free-stroke tolerances (the qa-engineer tunes them); a playthrough; mastery in the simulator.",
         ""]
    return "\n".join(L)

FINDINGS = """## 13. Findings for the plan, and how they were settled (2026-11-06)
The teacher's findings went to the curriculum-expert and the orchestrator; the owner approved the structure changes on 2026-11-06, and the curriculum-expert settled the rest the same day.
1. **ENG-B-18 was gated behind group 2.** Settled (owner, 2026-11-06): B-18 is split into **B-18.G1** (prerequisites B-14, B-16) and **B-18.G2** (B-17, B-18.G1), with B-18 as the roll-up. These reading items are `ENG-B-18.G1`.
2. **LS04 `graphemes`: when the whole word plays.** Settled (L5 §5.5): in a scored item only the parts play during the slide; the child chooses; the whole word plays **after** the choice. Heard first, the choice would be a listening item, and its DIR and LETTERNAME distractors would no longer show a reading error. If a part has no clip (D2), the parts light in silence and the stretched whole is the H1 replay (credit 0.8). In teaching screens and at H3 the whole word follows the parts. The data above need no change (`whole` and `stretched` are both named).
3. **Checks for a writing skill.** Confirmed (frame §2.3, §4.6 P5): in a writing node every check is a memory item, so w07 and w14 stand. A trace node (B-23.G1) has no check and no probe.
4. **LS03 H2 for English phonemes.** Adopted (L5 §5.3): for phoneme units the level-2 hint is the mouth picture of each sound as its token lights; claps stay for syllable and CV units. A clap per sound in a one-syllable word would model `M-ENG-SEG-SYLL`; articulation pictures help beginners segment phonemes (Castiglioni-Spalten and Ehri 2003; Boyer and Ehri 2011).
5. **LS01 feedback for a tile with no clip.** Settled (L5 §5.1, built in L5-1): an untaught look-alike tile has no clip and no speaker; its first-error feedback skips "that is ..." and plays the tag's line (he-fb-look-alike), then the target again. The validator allows a clip-less option only as a SHAPE-tagged distractor.
6. **Text faces on LS11 targets** (i16). Settled: LS11 `place` targets take LS01's text face in L5-1. B-16 no longer depends on it for two representations, since letter → picture items (i13, i14) are `pictorial` (frame §4.6 P7).
7. **B-22 and the chant** (L5 §14 item 4) are in ENG-2b, not in this slice; the syllabus line "the melody needs the owner's OK" is still to be changed to the chant (owner, 2026-11-05) when the teacher next edits the syllabus.
8. **Applied with E-1 (curriculum-expert, 2026-11-06):** the intros (n01 to n06) and the traces moved to the trace node **ENG-B-23.G1** (an `intro` names its group's trace node, writing-mastery §8 rule 1); a start-dot trace was added for every letter (t02 to t07), since B-23.G1 is met only when each letter is traced once with the start dot; the old w01 and w02 are t01 and t05. ENG-B-19.G1 keeps the copy and memory items and opens after the bundle (prerequisites B-23.G1, B-16).
"""

def main():
    src = sources()
    errs, ok = checks(src, ITEMS)
    # self-test with a broken copy
    bad = copy.deepcopy(ITEMS)
    bad[6]["dist"] = [("tile:f", "M-ENG-AE")] + bad[6]["dist"][1:]          # accent tag
    [b for b in bad if b["tmpl"] == "LS02" and b["mode"] == "copy"][0]["spec"]["forms"] = ["latin.zz"]
    [b for b in bad if b["id"] == "i06"][0]["flags"] = "C"                  # 2-choice check
    [b for b in bad if b["id"] == "r06"][0]["spec"]["scene"]["stem"]["text"] = "sock"
    bad[0]["frame"] = bad[0]["frame"] + ["he-missing-line"]
    for b in bad:
        if b["id"] == "i10": b["right"] = "snd:en-snd-t"; b["prompt"] = []
    berrs, _ = checks(src, bad)
    broken_ok = len(berrs) >= 6
    if BROKEN:
        print("broken copy errors:", len(berrs)); [print("  ", e) for e in berrs]
        return
    print(f"checks: {len(ok)} pass, {len(errs)} fail; broken copy fails with {len(berrs)} errors")
    for e in errs: print("FAIL", e)
    if not CHECK_ONLY:
        text = render(src) + "\n" + render_checks(errs, ok, broken_ok) + "\n" + FINDINGS
        with open(OUT, "w", encoding="utf-8", newline="\n") as f:
            f.write(text)
        print("wrote", OUT, len(text), "chars")
    sys.exit(1 if errs or not broken_ok else 0)

if __name__ == "__main__":
    main()
