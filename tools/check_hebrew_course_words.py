"""Check the decodable words of the Hebrew course (docs/languages/hebrew/syllabus.md, section 3).

Written by the hebrew-text-editor, 2026-11-03. For every word of steps S1 to S8 it finds the earliest
step whose letters and signs are enough to read it, and reports a word that needs a later step than
the one it is listed in. It also reports an invalid final form, a shin with no dot, and a word that is not
in canonical (NFC) order. Words of S9 to S12 are only listed (they are read by hand).

    python -I tools/check_hebrew_course_words.py [docs/languages/hebrew/syllabus.md]
    python -I tools/check_hebrew_course_words.py --text FILE...   (hygiene of any file: NFC order, final letters, shin dots)

Rules (syllabus section 3): ב כ פ with a dagesh belong to S1/S4/S6, without it to S7; שׂ and ך ף are S7;
a final ָה is S1, a final ֶה/ֵה is S6; a shva on the first letter or a hataf is S8; a silent shva is S3;
a patah gnuva (רוּחַ) is S7; a silent א inside a word is S7. A first-letter א only carries the vowel.
"""
import sys; sys.stdout.reconfigure(encoding="utf-8")
# Checks the decodable words of docs/languages/hebrew/syllabus.md section 3 (S1..S8 steps)
# usage: python -I check_syllabus.py <syllabus.md>
import re, sys, unicodedata

SHVA='\u05B0'; HSEG='\u05B1'; HPAT='\u05B2'; HQAM='\u05B3'; HIRIQ='\u05B4'; TSERE='\u05B5'; SEGOL='\u05B6'
PATAH='\u05B7'; QAMATS='\u05B8'; HOLAM='\u05B9'; QUBUTS='\u05BB'; DAGESH='\u05BC'; SHIN='\u05C1'; SIN='\u05C2'
QQ='\u05C7'
FINALS='ךםןףץ'
BASE=lambda c: '\u05D0'<=c<='\u05EA'

def clusters(w):
    out=[]
    for ch in w:
        if BASE(ch): out.append([ch,set()])
        else: out[-1][1].add(ch)
    return out

def need(word):
    cl=clusters(word); n=len(cl); req=1; why=[]
    def up(s,r):
        nonlocal req
        if s>req: req=s
        if s>1: why.append(f"{r}:{s}")
    for i,(c,m) in enumerate(cl):
        last=(i==n-1); first=(i==0)
        prev=cl[i-1] if i else None
        prevm=prev[1] if prev else set()
        vowels=m & {PATAH,QAMATS,HIRIQ,TSERE,SEGOL,HOLAM,QUBUTS,HSEG,HPAT,HQAM}
        # final-form sanity
        if c in FINALS and not last: why.append("BAD final mid-word "+c); up(99,c)
        if c in 'כמנפצ' and last and n>1: why.append("BAD non-final at end "+c); up(99,c)
        if c in 'אלמרשת':
            pass
        if c=='ש':
            if SHIN in m: up(1,'שׁ')
            elif SIN in m: up(7,'שׂ')
            else: why.append("BAD shin no dot"); up(99,c)
        elif c=='א':
            if vowels or SHVA in m or first: up(1,'א')  # carries a vowel / vowel carrier at the start
            else: up(1 if last else 7,'א silent '+('end' if last else 'inside'))
        elif c in 'בכפ':
            if DAGESH in m: up({'ב':1,'כ':4,'פ':6}[c],c+'ּ')
            else: up(7,c+' soft')
        elif c in 'ךףץם' :
            up({'ך':7,'ף':7,'ץ':6,'ם':1}[c],c)
        elif c in 'מלתר': up(1,c)
        elif c in 'נןדיס': up(2,c)
        elif c=='ג': up(4,c)
        elif c=='ו':
            if HOLAM in m: up(4,'וֹ')
            elif DAGESH in m and not vowels: up(5,'וּ')
            elif vowels: up(4,'ו consonant')
            else: up(4,'ו bare?')
        elif c=='ה':
            if last and prevm & {QAMATS}: up(1,'final ָה')
            elif last and prevm & {SEGOL,TSERE}: up(6,'final ֶה')
            else: up(4,'ה consonant')
        elif c in 'חקע':
            if c in 'חע' and last and PATAH in m and prev and (prevm & {TSERE,HIRIQ,QUBUTS,HOLAM} or prev[0] in 'וי'):
                up(7,'patah gnuva '+c)
            else: up(5,c)
        elif c in 'צזט': up(6,c)
        elif c=='ש': pass
        else: why.append("UNKNOWN letter "+c); up(99,c)
        # signs
        if m & {PATAH,QAMATS} and not (c in 'חע' and last and PATAH in m and why and 'gnuva' in why[-1]): up(1,'a')
        if HIRIQ in m: up(2,'ִ')
        if HOLAM in m: up(4,'ֹ')
        if QUBUTS in m: up(5,'ֻ')
        if TSERE in m or SEGOL in m: up(6,'e')
        if SHVA in m:
            if first: up(8,'shva at start')
            elif c=='ך' and last: up(7,'ךְ')
            else: up(3,'silent shva')
        if m & {HSEG,HPAT,HQAM}: up(8,'hataf')
        if QQ in m: why.append('qamats qatan'); up(99,'QQ')
        # vowel letters
        if c=='י' and prevm & {HIRIQ}: pass
    return req,why

def hebrew_tokens(s):
    return [t.replace('\u2013', '') for t in re.findall(r'[\u05B0-\u05C7\u05D0-\u05EA\u2013]+', s) if t.strip('\u2013')]

def main(path):
    txt=open(path,encoding='utf-8').read()
    total=bad=0
    for line in txt.splitlines():
        m=re.match(r'\|\s*\*\*S(\d+)\*\*\s*\|(.*)',line)
        if not m: continue
        step=int(m.group(1))
        cells=[c.strip() for c in line.strip().strip('|').split('|')]
        words=hebrew_tokens(cells[4])
        if step>=9: 
            print(f"S{step}: {len(words)} tokens (manual): {' '.join(words)}"); continue
        for w in words:
            total+=1
            if w!=unicodedata.normalize('NFC',w): print(f"  NFC-different: {w}")
            r,why=need(w)
            flag=''
            if r>step: flag=f"  <-- needs S{r} ({', '.join(why)})"; bad+=1
            if r>=99: flag=f"  <-- INVALID ({', '.join(why)})"
            if flag: print(f"S{step} {w}{flag}")
    print(f"checked {total} words in S1-S8, {bad} need a later step")
    # minimum-step report
    for line in txt.splitlines():
        m=re.match(r'\|\s*\*\*S(\d+)\*\*\s*\|(.*)',line)
        if not m or int(m.group(1))>8: continue
        step=int(m.group(1)); cells=[c.strip() for c in line.strip().strip('|').split('|')]
        early=[w for w in hebrew_tokens(cells[4]) if need(w)[0]<step]
        if early: print(f"S{step} words that could sit earlier: "+' '.join(f"{w}(S{need(w)[0]})" for w in early))
def hygiene(paths):
    """Text hygiene for any file (the Band A batches, the pronunciation CSV): every Hebrew word is in canonical (NFC)
    order, no final letter inside a word and no non-final letter at the end (a hard final pe, פ, is allowed: פִּיפּ), and a
    pointed word has a dot on every shin. (U+05C7 on כׇל is the pack's standard on screen; it is never sent to a voice.)"""
    bad = total = pointed = 0
    for path in paths:
        for n, line in enumerate(open(path, encoding='utf-8').read().splitlines(), 1):
            for tok in re.findall(r'[֐-׿]+', line):
                if not re.search('[א-ת]', tok):
                    continue
                total += 1
                marks = bool(re.search('[ְ-ׇ]', tok))
                pointed += marks
                msgs = []
                if tok != unicodedata.normalize('NFC', tok): msgs.append('not NFC')
                core = re.sub('[־ֿ׀׃ׅׄ׆]', '', tok)
                if not BASE(core[0]):
                    msgs.append('a mark with no letter before it')
                    core = core.lstrip(''.join(chr(c) for c in range(0x0591, 0x05C8)))
                if not core or re.sub('[ְ-ׇ]', '', core) in ('הממ', 'המממ'):
                    continue  # the interjection "hmm" (הַמְּמ…, המממ) is written as the curriculum writes it
                cl = clusters(core)
                for i, (c, m) in enumerate(cl):
                    last = i == len(cl) - 1
                    if c in FINALS and not last: msgs.append('final letter inside: ' + c)
                    if c in 'כמנצ' and last and len(cl) > 1: msgs.append('non-final letter at the end: ' + c)
                    if c == 'ש' and marks and SHIN not in m and SIN not in m: msgs.append('shin without a dot')
                    if c == 'ש' and SHIN in m and SIN in m: msgs.append('shin and sin dots')
                if msgs:
                    bad += 1
                    print('%s:%d %s  <-- %s' % (path, n, tok, '; '.join(msgs)))
    print('hygiene: %d Hebrew words (%d pointed) in %d file(s), %d to look at' % (total, pointed, len(paths), bad))


if len(sys.argv) > 1 and sys.argv[1] == '--text':
    hygiene(sys.argv[2:])
else:
    main(sys.argv[1] if len(sys.argv) > 1 else 'docs/languages/hebrew/syllabus.md')
