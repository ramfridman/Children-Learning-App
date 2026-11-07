"""F6: the other ways a child builds a letter that are right (QA-L52-1, docs/languages/strokes.md section 5.4).

A form's `strokes` are the way its school model writes it. The free-stroke check of LS02 (copy and memory) accepts a letter that
matches the model or any build listed here, so a ball and a stick for a, d and Cyrillic a, a stick and an arch for n, a stick and a
bowl for b and p, a Hebrew bet in one stroke, a Cyrillic M in one zig-zag are not told "not yet". Every build is a few strokes in
the same 100 by 100 box and on the same guide lines as the model; at most MAX_BUILDS a form. The points are whole box units, y down;
a build's strokes are read in any order, like the model's.

These are the builds of the first-grade charts the course follows (docs/languages/strokes.md section 5.4 lists each with the reason
and what the teachers confirm). A build is added only when it can not be taken for another letter of its script; the cross-reading
test (app/test/stroke_alternates_test.dart) reads every build as a letter and refuses the data if another form fits it as well.

Format of an entry: form id -> [(how, [stroke, ...])]; a stroke is a list of [x, y] points, or (points, kind) for a dot or a short
mark. Deterministic; standard library only.
"""

# latin: the ball of a and d (the model's own bowl, closed, or left open as a c) and the stick that stands at its right
_A_OPEN = [[56, 36], [52, 34], [47, 34], [43, 35], [39, 37], [35, 41], [33, 46], [33, 51], [33, 56], [35, 61], [37, 64], [43, 68],
           [46, 69], [50, 69], [53, 68], [56, 66], [61, 62], [63, 55]]
_A_BALL = [[60, 38], [55, 35], [50, 34], [44, 34], [39, 37], [35, 41], [33, 46], [33, 51], [33, 56], [35, 61], [38, 65], [43, 68],
           [48, 69], [53, 68], [58, 66], [61, 62], [63, 56], [63, 48], [62, 42], [60, 38]]
_D_OPEN = [[60, 38], [55, 35], [50, 34], [45, 34], [40, 36], [36, 39], [33, 44], [31, 49], [32, 55], [33, 60], [36, 64], [40, 67],
           [45, 69], [50, 69], [54, 68], [59, 66], [62, 63], [65, 58], [66, 53]]
_D_BALL = _D_OPEN[:-1] + [[66, 52], [65, 45], [63, 40], [60, 38]]

# the bowl of b and p: from the stick, up and over, round to the stick again
_BOWL_B = [[35, 44], [40, 38], [43, 35], [47, 34], [50, 33], [54, 34], [57, 36], [60, 38], [63, 42], [64, 46], [65, 50], [64, 56],
           [62, 61], [59, 65], [54, 68], [50, 69], [44, 67], [40, 64], [37, 60]]
_BOWL_P = [[35, 44], [40, 38], [43, 35], [47, 34], [52, 34], [57, 35], [61, 39], [64, 44], [65, 49], [64, 55], [62, 61], [59, 65],
           [55, 68], [50, 69], [45, 68], [40, 65], [37, 60]]

# cyrillic small a: the ball (closed, or open as a c) and its stick
_RA_OPEN = [[60, 48], [55, 43], [49, 41], [43, 43], [38, 47], [35, 54], [35, 61], [38, 68], [43, 72], [49, 73], [55, 72], [60, 68]]
_RA_BALL = _RA_OPEN + [[62, 62], [62, 54], [60, 48]]
_RA_STICK = [[62, 44], [63, 73]]

ALTERNATES = {
    'latin.a': [
        ('ball and stick', [_A_BALL, [[63, 33], [64, 69]]]),
        ('c and stick', [_A_OPEN, [[63, 33], [64, 69]]]),
    ],
    'latin.d': [
        ('ball and stick', [_D_BALL, [[66, 10], [66, 69]]]),
        ('c and stick', [_D_OPEN, [[66, 10], [66, 69]]]),
    ],
    'latin.n': [
        ('stick and arch', [[[36, 33], [36, 69]],
                            [[36, 48], [37, 42], [40, 38], [43, 35], [47, 34], [50, 34], [55, 34], [59, 36], [62, 38], [63, 41],
                             [64, 45], [64, 69]]]),
    ],
    'latin.t': [
        ('a plus, no hook', [[[47, 21], [47, 66]], [[36, 35], [65, 35]]]),
    ],
    'latin.b': [
        ('stick and bowl', [[[35, 10], [35, 69]], _BOWL_B]),
    ],
    'latin.p': [
        ('stick and bowl', [[[35, 33], [35, 90]], _BOWL_P]),
    ],
    'cyrillic.a': [
        ('ball and stick', [_RA_BALL, _RA_STICK]),
        ('c and stick', [_RA_OPEN, _RA_STICK]),
    ],
    'cyrillic.a.cap': [
        ('roof in one stroke and bar', [[[29, 73], [50, 26], [71, 73]], [[37, 59], [63, 59]]]),
    ],
    'cyrillic.em.cap': [
        ('one zig-zag', [[[26, 73], [26, 26], [50, 67], [74, 26], [74, 73]]]),
        ('two sticks and a v', [[[26, 26], [26, 73]], [[74, 26], [74, 73]], [[26, 26], [50, 67], [72, 26]]]),
        ('a stick, then the rest', [[[26, 26], [26, 73]], [[26, 26], [50, 67], [74, 26], [74, 73]]]),
    ],
    'cyrillic.em': [
        ('one zig-zag', [[[32, 73], [32, 41], [50, 68], [68, 41], [68, 73]]]),
        ('two sticks and a v', [[[32, 41], [32, 73]], [[68, 41], [68, 73]], [[32, 41], [50, 68], [68, 41]]]),
        ('a stick, then the rest', [[[32, 41], [32, 73]], [[32, 41], [50, 68], [68, 41], [68, 73]]]),
    ],
    'hebrew-print.bet': [
        ('base from the right', [[[32, 28], [54, 28], [57, 29], [59, 30], [60, 35], [60, 70]], [[70, 71], [30, 71]]]),
    ],
    'hebrew-print.shin': [
        ('cup and prong', [[[76, 26], [75, 56], [73, 62], [69, 67], [61, 71], [51, 72], [37, 70], [24, 66], [24, 26]],
                           [[50, 26], [50, 51], [49, 55], [47, 59]]]),
    ],
}
