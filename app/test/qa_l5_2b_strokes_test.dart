// QA of the free-stroke check of LS02 (L5-2b), on samples made by hand by the qa-engineer, NOT derived from the model strokes: each letter
// below was drawn point by point the way a person writes it (sparse points, straight runs and a few curves), so the check is tested against
// shapes it was not tuned on. Three kinds: a neat hand, a "sloppy child" (the same shapes sheared, shifted, wobbled, with the start a little
// off), and the other ways a child really builds a letter (ball and stick, one stroke where the model has two). Then what must be refused.
//
// The rates are printed (run with -r expanded to read them). Proofs of the open defects are `skip`ped with the defect id, so the suite stays
// green; remove the skip when the owner has fixed it.
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:nitznutz/content/strokes.dart';
import 'package:nitznutz/play/stroke_check.dart';

StrokeSet _load(String name) => StrokeSet.fromJson(
  jsonDecode(File('../content/languages/strokes/$name.json').readAsStringSync())! as Map<String, Object?>,
);

final Map<String, StrokeSet> _sets = <String, StrokeSet>{
  for (final String n in <String>['latin', 'cyrillic', 'hebrew-print']) n: _load(n),
};

StrokeForm _form(String id) => _sets[StrokeSet.setOf(id)]!.forms[id]!;

/// A stroke from x, y pairs.
List<Offset> _s(List<num> xy) => <Offset>[
  for (int i = 0; i < xy.length; i += 2) Offset(xy[i].toDouble(), xy[i + 1].toDouble()),
];

/// A tap (a dot).
List<Offset> _tap(num x, num y) => <Offset>[Offset(x.toDouble(), y.toDouble()), Offset(x + 0.4, y + 0.4)];

class _Sample {
  const _Sample(this.form, this.what, this.strokes);
  final String form;
  final String what;
  final List<List<Offset>> strokes;
}

// ---- neat samples, drawn by hand ----

final List<_Sample> _neat = <_Sample>[
  // Latin (x-height 30, base 72)
  _Sample('latin.s', 's', <List<Offset>>[
    _s(<num>[62, 38, 55, 32, 46, 31, 39, 35, 39, 42, 46, 48, 56, 53, 62, 59, 60, 67, 52, 71, 43, 71, 36, 66]),
  ]),
  _Sample('latin.c', 'c', <List<Offset>>[
    _s(<num>[62, 40, 55, 33, 46, 31, 38, 36, 34, 46, 35, 58, 41, 67, 51, 70, 60, 67, 64, 62]),
  ]),
  _Sample('latin.o', 'o', <List<Offset>>[
    _s(<num>[52, 31, 42, 33, 35, 42, 33, 53, 37, 64, 46, 70, 56, 70, 64, 63, 67, 52, 63, 40, 54, 32, 48, 31]),
  ]),
  _Sample('latin.l', 'l', <List<Offset>>[
    _s(<num>[50, 8, 50, 24, 50, 40, 50, 56, 51, 70]),
  ]),
  _Sample('latin.i', 'i', <List<Offset>>[
    _s(<num>[50, 33, 50, 45, 50, 58, 50, 70]),
    _tap(50, 16),
  ]),
  _Sample('latin.t', 't', <List<Offset>>[
    _s(<num>[47, 18, 47, 32, 47, 46, 47, 58, 48, 66, 53, 70, 60, 70, 66, 65]),
    _s(<num>[34, 36, 46, 35, 58, 35, 67, 35]),
  ]),
  _Sample('latin.n', 'n (one stroke, as the model)', <List<Offset>>[
    _s(<num>[36, 34, 36, 52, 36, 70, 36, 56, 37, 44, 42, 37, 50, 34, 58, 36, 63, 42, 64, 52, 64, 70]),
  ]),
  _Sample('latin.a', 'a (one stroke, as the model)', <List<Offset>>[
    _s(<num>[
      62,
      38,
      52,
      33,
      42,
      35,
      35,
      44,
      34,
      56,
      40,
      66,
      50,
      70,
      58,
      66,
      62,
      58,
      63,
      46,
      63,
      34,
      63,
      52,
      64,
      70,
    ]),
  ]),
  _Sample('latin.e', 'e', <List<Offset>>[
    _s(<num>[
      38,
      51,
      52,
      51,
      65,
      50,
      64,
      42,
      58,
      35,
      50,
      32,
      42,
      35,
      36,
      44,
      35,
      56,
      40,
      65,
      48,
      70,
      57,
      68,
      62,
      64,
    ]),
  ]),
  _Sample('latin.b', 'b (one stroke, as the model)', <List<Offset>>[
    _s(<num>[
      35,
      8,
      35,
      30,
      35,
      52,
      35,
      70,
      35,
      54,
      38,
      44,
      45,
      36,
      54,
      34,
      62,
      40,
      65,
      52,
      60,
      64,
      50,
      70,
      41,
      66,
      37,
      60,
    ]),
  ]),
  // Cyrillic (x-height 41, base 73, caps from 26)
  _Sample('cyrillic.a.cap', 'А', <List<Offset>>[
    _s(<num>[50, 26, 44, 38, 40, 50, 35, 62, 29, 73]),
    _s(<num>[50, 26, 56, 38, 61, 50, 66, 62, 71, 73]),
    _s(<num>[38, 59, 50, 59, 62, 59]),
  ]),
  _Sample('cyrillic.em.cap', 'М', <List<Offset>>[
    _s(<num>[26, 26, 26, 40, 26, 55, 26, 73]),
    _s(<num>[74, 26, 74, 40, 74, 55, 74, 73]),
    _s(<num>[26, 26, 36, 42, 44, 56, 50, 67]),
    _s(<num>[72, 26, 64, 42, 56, 56, 50, 67]),
  ]),
  _Sample('cyrillic.en', 'н', <List<Offset>>[
    _s(<num>[36, 41, 36, 55, 36, 73]),
    _s(<num>[64, 41, 64, 55, 64, 73]),
    _s(<num>[36, 57, 50, 57, 64, 57]),
  ]),
  _Sample('cyrillic.te', 'т', <List<Offset>>[
    _s(<num>[32, 42, 50, 42, 69, 42]),
    _s(<num>[50, 42, 50, 58, 50, 73]),
  ]),
  _Sample('cyrillic.o', 'о', <List<Offset>>[
    _s(<num>[60, 45, 52, 41, 44, 42, 38, 48, 35, 58, 38, 67, 45, 72, 53, 73, 60, 68, 63, 58, 61, 49, 55, 43]),
  ]),
  _Sample('cyrillic.es', 'с', <List<Offset>>[
    _s(<num>[63, 46, 56, 42, 47, 41, 40, 45, 36, 54, 37, 63, 43, 70, 52, 73, 61, 70]),
  ]),
  _Sample('cyrillic.u', 'у', <List<Offset>>[
    _s(<num>[64, 41, 58, 58, 52, 72, 44, 90]),
    _s(<num>[36, 41, 42, 52, 50, 64]),
  ]),
  _Sample('cyrillic.sha', 'ш', <List<Offset>>[
    _s(<num>[28, 41, 28, 55, 28, 72]),
    _s(<num>[50, 41, 50, 55, 50, 72]),
    _s(<num>[72, 41, 72, 55, 72, 72]),
    _s(<num>[28, 72, 50, 72, 72, 72]),
  ]),
  // Hebrew print (top 26, base 72)
  _Sample('hebrew-print.bet', 'ב', <List<Offset>>[
    _s(<num>[32, 28, 48, 27, 58, 28, 60, 36, 60, 50, 60, 70]),
    _s(<num>[30, 71, 50, 71, 70, 71]),
  ]),
  _Sample('hebrew-print.resh', 'ר', <List<Offset>>[
    _s(<num>[34, 28, 52, 28, 59, 31, 62, 40, 62, 56, 62, 72]),
  ]),
  _Sample('hebrew-print.dalet', 'ד', <List<Offset>>[
    _s(<num>[30, 28, 50, 28, 69, 28]),
    _s(<num>[57, 28, 57, 50, 57, 72]),
  ]),
  _Sample('hebrew-print.vav', 'ו', <List<Offset>>[
    _s(<num>[44, 28, 52, 28, 52, 50, 52, 72]),
  ]),
  _Sample('hebrew-print.lamed', 'ל', <List<Offset>>[
    _s(<num>[34, 10, 34, 22, 34, 28, 50, 28, 66, 28, 56, 50, 46, 72]),
  ]),
  _Sample('hebrew-print.mem', 'מ', <List<Offset>>[
    _s(<num>[27, 31, 40, 26, 55, 25, 66, 31, 68, 42, 68, 58, 68, 71, 56, 71]),
    _s(<num>[39, 33, 37, 50, 34, 72]),
  ]),
  _Sample('hebrew-print.kaf', 'כ', <List<Offset>>[
    _s(<num>[35, 28, 50, 28, 63, 28, 63, 50, 60, 64, 50, 71, 33, 71]),
  ]),
  _Sample('hebrew-print.het', 'ח', <List<Offset>>[
    _s(<num>[34, 28, 56, 28, 63, 32, 65, 45, 65, 72]),
    _s(<num>[34, 28, 34, 50, 34, 72]),
  ]),
  _Sample('hebrew-print.shin', 'ש', <List<Offset>>[
    _s(<num>[76, 26, 75, 42, 74, 56, 72, 63, 66, 69, 56, 72, 44, 71, 30, 68, 24, 66]),
    _s(<num>[24, 26, 24, 45, 24, 66]),
    _s(<num>[50, 26, 50, 40, 50, 51, 48, 57, 47, 59]),
  ]),
  _Sample('hebrew-print.tav', 'ת', <List<Offset>>[
    _s(<num>[32, 28, 48, 28, 61, 28, 67, 31, 70, 37, 70, 55, 70, 72]),
    _s(<num>[45, 32, 42, 37, 40, 43, 40, 62, 39, 66, 35, 70, 28, 71]),
  ]),
];

/// The ways a child really builds a letter that differ from the model's strokes: ball and stick, a letter in one stroke where the model has
/// two (or the other way round), a hookless t.
final List<_Sample> _alternates = <_Sample>[
  _Sample('latin.a', 'a as a ball, then a stick', <List<Offset>>[
    _s(<num>[60, 38, 50, 32, 40, 36, 34, 48, 36, 62, 46, 70, 56, 68, 62, 58, 62, 46, 58, 38]),
    _s(<num>[63, 33, 63, 50, 64, 70]),
  ]),
  _Sample('latin.d', 'd as a ball, then a stick', <List<Offset>>[
    _s(<num>[60, 38, 50, 32, 40, 36, 34, 48, 36, 62, 46, 70, 56, 68, 62, 58, 62, 46, 58, 38]),
    _s(<num>[66, 8, 66, 40, 66, 70]),
  ]),
  _Sample('latin.n', 'n as a stick, then an arch', <List<Offset>>[
    _s(<num>[36, 34, 36, 52, 36, 70]),
    _s(<num>[36, 52, 40, 40, 48, 34, 57, 35, 63, 42, 64, 55, 64, 70]),
  ]),
  _Sample('latin.b', 'b as a stick, then a bowl', <List<Offset>>[
    _s(<num>[35, 8, 35, 40, 35, 70]),
    _s(<num>[36, 48, 44, 37, 54, 34, 63, 42, 65, 54, 60, 65, 50, 70, 41, 66, 36, 58]),
  ]),
  _Sample('latin.t', 't with no hook (a plus)', <List<Offset>>[
    _s(<num>[47, 20, 47, 40, 48, 70]),
    _s(<num>[34, 36, 50, 35, 67, 35]),
  ]),
  _Sample('hebrew-print.bet', 'ב in one stroke (top, down, base back)', <List<Offset>>[
    _s(<num>[32, 28, 48, 27, 58, 28, 61, 36, 61, 55, 61, 70, 45, 71, 30, 71]),
  ]),
  _Sample('hebrew-print.mem', 'מ with the left leg first', <List<Offset>>[
    _s(<num>[39, 33, 37, 50, 34, 72]),
    _s(<num>[27, 31, 40, 26, 55, 25, 66, 31, 68, 42, 68, 58, 68, 71, 56, 71]),
  ]),
  _Sample('hebrew-print.vav', 'ו a plain stick', <List<Offset>>[
    _s(<num>[52, 28, 52, 50, 52, 72]),
  ]),
  _Sample('cyrillic.a', 'а as a ball, then a stick', <List<Offset>>[
    _s(<num>[60, 50, 50, 44, 40, 48, 36, 58, 40, 69, 50, 73, 58, 68, 61, 58]),
    _s(<num>[62, 44, 62, 58, 63, 73]),
  ]),
  _Sample('cyrillic.em.cap', 'М drawn as one zig-zag', <List<Offset>>[
    _s(<num>[26, 73, 26, 26, 50, 67, 74, 26, 74, 73]),
  ]),
  _Sample('cyrillic.u', 'у as a V then a tail', <List<Offset>>[
    _s(<num>[36, 41, 42, 52, 50, 64]),
    _s(<num>[64, 41, 58, 58, 52, 72, 44, 90]),
  ]),
];

// ---- a sloppy hand: the same shapes sheared, shifted, wobbled, with the start off ----

List<Offset> _sloppy(List<Offset> pts, math.Random r) {
  if (pts.length == 2 && (pts[0] - pts[1]).distance < 1) {
    // A tap: aimed within a few units.
    final Offset d = Offset((r.nextDouble() * 2 - 1) * 5, (r.nextDouble() * 2 - 1) * 5);
    return <Offset>[pts[0] + d, pts[1] + d];
  }
  final double scale = 0.9 + r.nextDouble() * 0.25;
  final double shear = (r.nextDouble() * 2 - 1) * 0.12;
  final Offset shift = Offset((r.nextDouble() * 2 - 1) * 4, (r.nextDouble() * 2 - 1) * 4);
  final double ph = r.nextDouble() * 6.28;
  final Offset startOff = Offset((r.nextDouble() * 2 - 1) * 6, (r.nextDouble() * 2 - 1) * 6);
  final List<Offset> out = <Offset>[];
  for (int i = 0; i < pts.length; i++) {
    final Offset p = pts[i];
    final Offset q = Offset(50 + (p.dx - 50) * scale + (p.dy - 50) * shear, 50 + (p.dy - 50) * scale) + shift;
    final Offset wob = Offset(math.sin(i * 1.3 + ph), math.cos(i * 0.9 + ph)) * 1.6;
    out.add(q + wob + (i < 2 ? startOff : Offset.zero));
  }
  return out;
}

String _verdictOf(StrokeVerdict v) => v.right ? 'ok' : (v.fault == null ? 'unnamed' : v.fault!.name);

/// Plays the strokes of [s] (each stroke as written; a two-point stroke is a tap) and says whether the letter is whole and what each stroke said.
({bool whole, List<String> said}) _play(
  StrokeForm f,
  List<List<Offset>> strokes, {
  List<StrokeForm> partners = const <StrokeForm>[],
}) {
  final LetterChecker c = LetterChecker(f, partners: partners);
  final List<String> said = <String>[];
  for (final List<Offset> st in strokes) {
    said.add(_verdictOf(c.check(st)));
  }
  return (whole: c.complete, said: said);
}

void main() {
  group('neat hand-made letters (adult): all accepted', () {
    test('every sample is accepted whole, in the order drawn and in the reverse order', () {
      final List<String> bad = <String>[];
      for (final _Sample s in _neat) {
        final f = _form(s.form);
        final fwd = _play(f, s.strokes);
        final rev = _play(f, s.strokes.reversed.toList());
        if (!fwd.whole) bad.add('${s.what} ${s.form}: ${fwd.said}');
        if (!rev.whole) bad.add('${s.what} ${s.form} reversed: ${rev.said}');
      }
      // ignore: avoid_print
      print('QA neat hand: ${_neat.length * 2 - bad.length} of ${_neat.length * 2} accepted');
      expect(bad, isEmpty, reason: bad.join('\n'));
    });
  });

  group('a sloppy child hand (the same shapes sheared, wobbled, start off by up to 6)', () {
    test('how many are refused, by script (printed)', () {
      final Map<String, List<int>> tally = <String, List<int>>{};
      final List<String> refused = <String>[];
      for (final _Sample s in _neat) {
        final f = _form(s.form);
        for (int seed = 0; seed < 20; seed++) {
          final math.Random r = math.Random(seed * 31 + 7);
          final strokes = <List<Offset>>[for (final List<Offset> st in s.strokes) _sloppy(st, r)];
          final res = _play(f, strokes);
          final String script = StrokeSet.setOf(s.form);
          final List<int> t = tally.putIfAbsent(script, () => <int>[0, 0]);
          t[1]++;
          if (!res.whole) {
            t[0]++;
            if (seed < 2) refused.add('${s.what} seed $seed: ${res.said}');
          }
        }
      }
      for (final MapEntry<String, List<int>> e in tally.entries) {
        // ignore: avoid_print
        print(
          'QA sloppy child, ${e.key}: ${e.value[0]} of ${e.value[1]} refused (${(100 * e.value[0] / e.value[1]).toStringAsFixed(1)}%)',
        );
      }
      // ignore: avoid_print
      print('QA sloppy examples refused:\n${refused.take(30).join('\n')}');
      final int total = tally.values.fold(0, (int a, List<int> t) => a + t[1]);
      final int bad = tally.values.fold(0, (int a, List<int> t) => a + t[0]);
      // The L5.md target the developer set for the made-up child is at most 1 in 100; a real hand is rougher than a made-up one, so the proof
      // here only guards against a regression to "most refused".
      expect(bad / total, lessThan(0.15), reason: '$bad of $total sloppy letters refused');
    });
  });

  group('other ways a child builds a right letter', () {
    test('which are accepted (printed)', () {
      final List<String> out = <String>[];
      int ok = 0;
      for (final _Sample s in _alternates) {
        final res = _play(_form(s.form), s.strokes);
        if (res.whole) ok++;
        out.add('${res.whole ? 'ACCEPTED' : 'REFUSED '} ${s.what} (${s.form}): ${res.said}');
      }
      // ignore: avoid_print
      print('QA alternates: $ok of ${_alternates.length} accepted\n${out.join('\n')}');
    });

    // The defect: ball-and-stick a/d/b and a stick-then-arch n are the commonest way a 5-year-old builds them (QA-L52-1, owner: curriculum-expert for
    // the stroke data and app-developer for the check). Each of these is refused today (see the print above).
    for (final _Sample s in _alternates.where(
      (_Sample s) => const <String>['latin.a', 'latin.d', 'latin.n', 'latin.b'].contains(s.form),
    )) {
      test('QA-L52-1: ${s.what} is a right letter and is accepted', () {
        final res = _play(_form(s.form), s.strokes);
        expect(res.whole, isTrue, reason: '${res.said}');
      }, skip: 'QA-L52-1 open: a letter built from the strokes in another way (ball and stick) is refused');
    }
  });

  group('what must be refused', () {
    // The letters of the three pilot groups (docs/languages/*/band-b-pilot.md): they are the ones a child meets first.
    const Set<String> pilot = <String>{
      'latin.s',
      'latin.a',
      'latin.t',
      'latin.p',
      'latin.i',
      'latin.n',
      'hebrew-print.mem',
      'hebrew-print.lamed',
      'hebrew-print.shin',
      'hebrew-print.resh',
      'hebrew-print.bet',
      'hebrew-print.tav',
      'hebrew-print.mem-final',
      'cyrillic.a.cap',
      'cyrillic.a',
      'cyrillic.u.cap',
      'cyrillic.u',
      'cyrillic.o.cap',
      'cyrillic.o',
      'cyrillic.em.cap',
      'cyrillic.em',
    };

    /// Eight scribble strokes of 14 random points in the middle of the box, four times, for every form; counts what the check made of them.
    ({int strokes, int right, int named, int completed, List<String> completedForms, List<String> namedPilot})
    scribbles() {
      final math.Random r = math.Random(11);
      int strokes = 0, right = 0, named = 0, completed = 0;
      final List<String> forms = <String>[];
      final List<String> namedPilot = <String>[];
      for (final StrokeSet set in _sets.values) {
        for (final StrokeForm f in set.forms.values) {
          for (int k = 0; k < 4; k++) {
            final LetterChecker c = LetterChecker(f);
            for (int s = 0; s < 8; s++) {
              final List<Offset> sc = <Offset>[
                for (int i = 0; i < 14; i++) Offset(15 + r.nextDouble() * 70, 15 + r.nextDouble() * 70),
              ];
              final StrokeVerdict v = c.check(sc);
              strokes++;
              if (v.right) right++;
              if (v.named) {
                named++;
                if (pilot.contains(f.id)) namedPilot.add('${f.id}: ${v.fault!.name}');
              }
            }
            if (c.complete) {
              completed++;
              forms.add(f.id);
            }
          }
        }
      }
      return (
        strokes: strokes,
        right: right,
        named: named,
        completed: completed,
        completedForms: forms,
        namedPilot: namedPilot,
      );
    }

    test('a random scribble: how often it is accepted, completes a letter or is named (printed)', () {
      final s = scribbles();
      // ignore: avoid_print
      print(
        'QA scribbles: ${s.strokes} strokes, ${s.right} accepted as a stroke, ${s.named} named an error (a row with a misconception tag), '
        '${s.completed} of ${s.strokes ~/ 8} letters completed: ${s.completedForms.toSet().toList()}; named on a pilot letter: ${s.namedPilot.length}',
      );
    });

    test('QA-L52-2a: a random scribble never completes a letter', () {
      final s = scribbles();
      expect(s.completedForms, isEmpty);
    }, skip: 'QA-L52-2 open: a scribble completes latin.d (and loops complete a, d, m)');

    test(
      'QA-L52-2b: a scribble is named nothing (no row against the child), on the letters of the pilot groups',
      () {
        final s = scribbles();
        expect(s.namedPilot, isEmpty);
      },
      skip: 'QA-L52-2 open: a scribble is named start or direction on pilot letters',
    );

    test('a round scribble (loops): printed', () {
      final List<String> bad = <String>[];
      for (final StrokeSet set in _sets.values) {
        for (final StrokeForm f in set.forms.values) {
          final LetterChecker c = LetterChecker(f);
          for (int s = 0; s < 6; s++) {
            final List<Offset> loops = <Offset>[
              for (int i = 0; i < 60; i++)
                Offset(
                  50 + 30 * math.cos(i / 4.0 + s) * (1 - i / 120),
                  50 + 30 * math.sin(i / 4.0 + s) * (1 - i / 120),
                ),
            ];
            if (c.check(loops).right) bad.add(f.id);
          }
          if (c.complete) bad.add('${f.id} COMPLETED');
        }
      }
      // ignore: avoid_print
      print('QA loops accepted as a stroke of: ${bad.toSet().toList()}');
    });

    test('QA-L52-2c: loops (a spiral) never complete a letter', () {
      final List<String> bad = <String>[];
      for (final StrokeSet set in _sets.values) {
        for (final StrokeForm f in set.forms.values) {
          final LetterChecker c = LetterChecker(f);
          for (int s = 0; s < 6; s++) {
            c.check(<Offset>[
              for (int i = 0; i < 60; i++)
                Offset(
                  50 + 30 * math.cos(i / 4.0 + s) * (1 - i / 120),
                  50 + 30 * math.sin(i / 4.0 + s) * (1 - i / 120),
                ),
            ]);
          }
          if (c.complete) bad.add(f.id);
        }
      }
      expect(bad, isEmpty);
    }, skip: 'QA-L52-2 open: a spiral completes latin.a, latin.d and latin.m');

    test('dots anywhere complete no letter that has no dot, and name nothing', () {
      final List<String> bad = <String>[];
      for (final StrokeSet set in _sets.values) {
        for (final StrokeForm f in set.forms.values) {
          if (f.strokes.any((StrokeModel m) => m.kind == StrokeKind.dot)) continue;
          final LetterChecker c = LetterChecker(f);
          for (int x = 10; x <= 90; x += 10) {
            for (int y = 10; y <= 90; y += 10) {
              final StrokeVerdict v = c.check(_tap(x, y));
              if (v.right || v.named) bad.add('${f.id}: a tap at $x,$y was ${_verdictOf(v)}');
            }
          }
          if (c.complete) bad.add('${f.id}: taps completed the letter');
        }
      }
      expect(bad, isEmpty, reason: bad.take(10).join('\n'));
    });

    test('a dot where the letter has a dot completes only that stroke', () {
      final StrokeForm i = _form('latin.i');
      final LetterChecker c = LetterChecker(i);
      expect(c.check(_tap(50, 16)).right, isTrue);
      expect(c.complete, isFalse);
    });

    final List<List<Offset>> lines = <List<Offset>>[
      _s(<num>[50, 10, 50, 40, 50, 75]),
      _s(<num>[50, 30, 50, 55, 50, 75]),
      _s(<num>[20, 50, 50, 50, 80, 50]),
      _s(<num>[25, 25, 50, 50, 75, 75]),
      _s(<num>[75, 25, 50, 50, 25, 75]),
    ];
    List<String> linesAccepted() {
      final List<String> accepted = <String>[];
      for (final StrokeSet set in _sets.values) {
        for (final StrokeForm f in set.forms.values) {
          for (final (int i, List<Offset> l) in lines.indexed) {
            final LetterChecker c = LetterChecker(f);
            c.check(l);
            if (c.complete) accepted.add('${f.id} by line $i');
          }
        }
      }
      return accepted;
    }

    test('a single plain line: which letters it completes (printed)', () {
      // ignore: avoid_print
      print('QA a single plain line completes: ${linesAccepted().join(', ')}');
    });

    test('QA-L52-3: a plain vertical line is not an s, an r (resh) or an n (nun)', () {
      final List<String> accepted = linesAccepted();
      for (final String id in <String>['latin.s', 'hebrew-print.resh', 'hebrew-print.nun']) {
        expect(accepted.any((String a) => a.startsWith('$id ')), isFalse, reason: id);
      }
    }, skip: 'QA-L52-3 open: a straight line down the middle of s, resh and nun is accepted as the letter');

    test('a neat letter taken for another letter: the targets of the three pilot groups, printed', () {
      final List<String> swapped = <String>[];
      for (final _Sample s in _neat) {
        final String script = StrokeSet.setOf(s.form);
        for (final StrokeForm other in _sets[script]!.forms.values) {
          if (other.id == s.form || !pilot.contains(other.id)) continue;
          if (_play(other, s.strokes).whole) {
            swapped.add('${s.form} written, accepted as the target ${other.id}');
          }
        }
      }
      // ignore: avoid_print
      print('QA cross-acceptance on the pilot targets: ${swapped.length}\n${swapped.join('\n')}');
    });

    test(
      'QA-L52-4: a letter that begins like the target is not taken for it at its first stroke (the stem of a t is not an l)',
      () {
        // After the target's last stroke is matched the item ends at once (LetterWriteSession._boxDone), so the strokes the child goes on to write
        // are never read. A wrong letter whose first stroke fits a simpler target is a full success.
        final _Sample t = _neat.firstWhere((_Sample s) => s.form == 'latin.t');
        final LetterChecker forL = LetterChecker(_form('latin.l'));
        final StrokeVerdict v = forL.check(t.strokes.first);
        expect(v.right && forL.complete, isFalse, reason: 'the stem of a t completed an l');
        // The same in Hebrew: the first stroke of a bet (top, down) is a whole resh, so a bet written for resh is a success.
        final _Sample bet = _neat.firstWhere((_Sample s) => s.form == 'hebrew-print.bet');
        final LetterChecker forResh = LetterChecker(_form('hebrew-print.resh'));
        forResh.check(bet.strokes.first);
        expect(forResh.complete, isFalse, reason: 'the first stroke of a bet completed a resh');
      },
      skip: 'QA-L52-4 open: the item ends at the first stroke that completes the target; the rest of what the child writes is never read',
    );
  });

  group('a mirror and a listed look-alike are named, written by hand', () {
    List<List<Offset>> flip(List<List<Offset>> st) => <List<Offset>>[
      for (final List<Offset> s in st) <Offset>[for (final Offset p in s) Offset(100 - p.dx, p.dy)],
    ];

    test('mirrored hand-made letters are refused, and the pilot ones are named mirror', () {
      final List<String> notRefused = <String>[];
      final List<String> notNamed = <String>[];
      for (final _Sample s in _neat) {
        final f = _form(s.form);
        if (LetterChecker.mirrorsOntoItself(f)) continue;
        final res = _play(f, flip(s.strokes));
        if (res.whole) notRefused.add('${s.what}: ${res.said}');
        if (!res.said.contains('mirror')) notNamed.add('${s.what}: ${res.said}');
      }
      // ignore: avoid_print
      print(
        'QA mirror, refused but not named mirror (these write nothing and move the help only):\n${notNamed.join('\n')}',
      );
      expect(notRefused, isEmpty, reason: notRefused.join('\n'));
    });

    test(
      'hand-made Hebrew look-alikes are named partner: כ for ב, ד for ר, ר for ד, ח for ת, and ס is not ם',
      () {
        final List<String> notNamed = <String>[];
        for (final (String target, String written, String sample) in <(String, String, String)>[
          ('hebrew-print.bet', 'hebrew-print.kaf', 'hebrew-print.kaf'),
          ('hebrew-print.resh', 'hebrew-print.dalet', 'hebrew-print.dalet'),
          ('hebrew-print.dalet', 'hebrew-print.resh', 'hebrew-print.resh'),
          ('hebrew-print.tav', 'hebrew-print.het', 'hebrew-print.het'),
        ]) {
          final _Sample s = _neat.firstWhere((_Sample x) => x.form == sample);
          final res = _play(_form(target), s.strokes, partners: <StrokeForm>[_form(written)]);
          // ignore: avoid_print
          print('QA $written written for $target: ${res.said} whole=${res.whole}');
          if (res.whole || !res.said.contains('partner')) {
            notNamed.add('$written for $target: ${res.said} whole=${res.whole}');
          }
        }
        // ignore: avoid_print
        print('QA look-alikes not named partner: ${notNamed.length} ${notNamed.join('; ')}');
      },
    );

    test('b written for d is named, d for b, p for q and the Hebrew ב for כ', () {
      // A hand-made d: a bowl then a stem on the right. The target is b with the partner d.
      final List<List<Offset>> dHand = <List<Offset>>[
        _s(<num>[66, 8, 66, 40, 66, 70]),
        _s(<num>[60, 38, 50, 32, 40, 36, 34, 48, 36, 62, 46, 70, 56, 68, 62, 58, 62, 46, 58, 38]),
      ];
      final StrokeForm b = _form('latin.b');
      final StrokeForm d = _form('latin.d');
      final res = _play(b, dHand, partners: <StrokeForm>[d]);
      // ignore: avoid_print
      print('QA d written for b: ${res.said}');
      expect(res.whole, isFalse);
      // The one-stroke d the model describes.
      final List<List<Offset>> dOne = <List<Offset>>[
        _s(<num>[
          62,
          38,
          52,
          33,
          42,
          35,
          35,
          44,
          34,
          56,
          40,
          66,
          50,
          70,
          58,
          66,
          62,
          58,
          65,
          46,
          66,
          28,
          66,
          10,
          66,
          40,
          66,
          69,
        ]),
      ];
      final res1 = _play(b, dOne, partners: <StrokeForm>[d]);
      // ignore: avoid_print
      print('QA one-stroke d written for b: ${res1.said}');
      expect(res1.whole, isFalse);
    });
  });
}
