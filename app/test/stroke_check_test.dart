// The free-stroke check of LS02 (L5 section 5.2): it must accept adult and child-like samples of every form of the three print sets in any
// stroke order, and refuse their mirror images and look-alikes with the right classifier. The samples are made up from the teacher-checked
// stroke data with a seeded generator: an adult writes close to the model; a child wobbles, starts a little off, and is a little too big or small.
import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:nitznutz/content/strokes.dart';
import 'package:nitznutz/play/stroke_check.dart';
import 'package:nitznutz/play/stroke_geometry.dart';

import 'support/stroke_hands.dart';

void main() {
  group('a letter written the right way is accepted', () {
    for (final MapEntry<String, StrokeSet> set in strokeSets.entries) {
      for (final (String who, StrokeHand hand) in <(String, StrokeHand)>[
        ('an adult', StrokeHand.adult),
        ('a child', StrokeHand.child),
      ]) {
        test('${set.key}: every form, written by $who, five times each, in the order written and in any order', () {
          final List<String> failures = <String>[];
          for (final StrokeForm f in set.value.forms.values) {
            for (int seed = 0; seed < 5; seed++) {
              for (final bool shuffle in <bool>[false, true]) {
                final LetterChecker c = LetterChecker(f);
                final List<String> verdicts = <String>[];
                for (final List<Offset> s in writeLetter(f, seed * 7 + 1, hand, shuffle: shuffle)) {
                  final StrokeVerdict v = c.check(s);
                  verdicts.add(v.right ? 'ok' : (v.fault?.name ?? 'unnamed'));
                }
                if (!c.complete) {
                  final List<String> nums = <String>[
                    for (int k = 0; k < f.strokes.length; k++)
                      if (!c.done[k] && f.strokes[k].kind != StrokeKind.dot)
                        () {
                          final r = LetterChecker.measure(
                            writeLetter(f, seed * 7 + 1, hand, shuffle: shuffle)[shuffle ? 0 : k],
                            f.strokes[k].points,
                          );
                          return 's$k start ${r.start.toStringAsFixed(1)} turn ${r.turn.toStringAsFixed(0)} mean ${r.mean.toStringAsFixed(1)} cov ${r.covered.toStringAsFixed(2)}';
                        }(),
                  ];
                  failures.add('${f.id} seed $seed${shuffle ? ' shuffled' : ''}: $verdicts $nums');
                }
              }
            }
          }
          // An adult is always accepted. The made-up child is deliberately extreme (a start up to 10 units off, a wander of 3, a letter 8%
          // off in size and 4 units off in place, all together): at most 1 letter in 100 of those may be refused. The qa-engineer tunes the
          // tolerances on real samples.
          final int allowed = identical(hand, StrokeHand.adult)
              ? 0
              : (set.value.forms.length * 10 * 0.01).ceil();
          expect(
            failures.length,
            lessThanOrEqualTo(allowed),
            reason:
                '${failures.length} of ${set.value.forms.length * 10} written wrong\n${failures.take(12).join('\n')}',
          );
        });
      }
    }
  });

  group('a mirror image is refused and named', () {
    // The letters of the three pilot groups (docs/languages/*/band-b-pilot.md): their mirror images must come back as `mirror`.
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
    for (final MapEntry<String, StrokeSet> set in strokeSets.entries) {
      test(
        '${set.key}: every letter that is not its own mirror, written mirrored by an adult and by a child',
        () {
          final List<String> notRefused = <String>[];
          final List<String> notNamed = <String>[];
          int tried = 0;
          for (final StrokeForm f in set.value.forms.values) {
            if (LetterChecker.mirrorsOntoItself(f)) continue;
            for (final StrokeHand h in <StrokeHand>[StrokeHand.adult, StrokeHand.child]) {
              tried++;
              final LetterChecker c = LetterChecker(f);
              final List<String> verdicts = <String>[];
              final math.Random r = math.Random(3);
              for (final StrokeModel m in f.strokes) {
                final StrokeVerdict v = c.check(mirrorStroke(writeStroke(m, r, h)));
                verdicts.add(v.right ? 'ok' : (v.fault?.name ?? 'unnamed'));
              }
              if (c.complete) notRefused.add('${f.id}: $verdicts');
              if (pilot.contains(f.id) && !verdicts.contains('mirror')) notNamed.add('${f.id}: $verdicts');
            }
          }
          expect(notRefused, isEmpty, reason: 'a mirrored letter was accepted, of $tried');
          expect(
            notNamed,
            isEmpty,
            reason: 'a mirrored pilot letter was refused but not named mirror, of $tried',
          );
        },
      );
    }
  });

  group('a look-alike is refused and named', () {
    // The pairs the three pilot slices list as partners (the item's classify map).
    const List<(String, String)> pairs = <(String, String)>[
      ('latin.p', 'latin.q'),
      ('latin.p', 'latin.b'),
      ('latin.b', 'latin.d'),
      ('hebrew-print.mem', 'hebrew-print.tet'),
      ('hebrew-print.resh', 'hebrew-print.dalet'),
      ('hebrew-print.bet', 'hebrew-print.kaf'),
      ('hebrew-print.tav', 'hebrew-print.het'),
      ('hebrew-print.mem-final', 'hebrew-print.samekh'),
      ('cyrillic.u', 'cyrillic.che'),
      ('cyrillic.o.cap', 'cyrillic.es.cap'),
      ('cyrillic.a.cap', 'cyrillic.el.cap'),
      ('cyrillic.sha', 'cyrillic.shcha'),
    ];
    for (final (String target, String other) in pairs) {
      test('$other written for $target', () {
        final StrokeForm t = strokeForm(target);
        final StrokeForm o = strokeForm(other);
        for (final StrokeHand h in <StrokeHand>[StrokeHand.adult, StrokeHand.child]) {
          final LetterChecker c = LetterChecker(t, partners: <StrokeForm>[o]);
          final math.Random r = math.Random(5);
          final List<String> verdicts = <String>[];
          for (final StrokeModel m in o.strokes) {
            final StrokeVerdict v = c.check(writeStroke(m, r, h));
            verdicts.add(
              v.right
                  ? 'ok'
                  : (v.fault == StrokeFault.partner ? 'partner:${v.partner}' : (v.fault?.name ?? 'unnamed')),
            );
          }
          expect(c.complete, isFalse, reason: '$other drawn for $target counted as it: $verdicts');
          expect(
            verdicts.any((String v) => v == 'partner:$other'),
            isTrue,
            reason: 'never named as the look-alike: $verdicts',
          );
        }
      });
    }
  });

  group('the other errors it can name', () {
    test('a stroke begun at its other end is a start error', () {
      for (final String id in <String>['latin.t', 'latin.l', 'cyrillic.te.cap', 'hebrew-print.vav']) {
        final StrokeForm f = strokeForm(id);
        final LetterChecker c = LetterChecker(f);
        final StrokeVerdict v = c.check(
          writeStroke(
            f.strokes.first,
            math.Random(1),
            StrokeHand.adult,
            path: f.strokes.first.points.reversed.toList(),
          ),
        );
        expect(v.right, isFalse, reason: id);
        expect(v.fault, StrokeFault.start, reason: id);
      }
    });

    test('a ring the other way round is a direction error', () {
      // Only a ring (o, samekh) is begun anywhere and goes round the other way; an open arc drawn back from its start is a path no hand makes
      // (a c the wrong way round is its mirror image, named `mirror` above).
      for (final String id in <String>['latin.o', 'cyrillic.o.cap', 'hebrew-print.samekh']) {
        final StrokeForm f = strokeForm(id);
        final StrokeModel m = f.strokes.first;
        final List<Offset> round = <Offset>[m.points.first, ...m.points.skip(1).toList().reversed];
        final LetterChecker c = LetterChecker(f);
        final StrokeVerdict v = c.check(writeStroke(m, math.Random(2), StrokeHand.adult, path: round));
        expect(v.right, isFalse, reason: id);
        expect(v.fault, anyOf(StrokeFault.direction, StrokeFault.start), reason: id);
      }
    });

    test('the right shape too small and too low is a lines error', () {
      for (final String id in <String>['latin.s', 'latin.n', 'cyrillic.a', 'hebrew-print.lamed']) {
        final StrokeForm f = strokeForm(id);
        final LetterChecker c = LetterChecker(f);
        final List<Offset> small = <Offset>[
          for (final Offset p in resampleStroke(f.strokes.first.points, 30))
            Offset(50 + (p.dx - 50) * 0.45, 88 + (p.dy - 50) * 0.3),
        ];
        final StrokeVerdict v = c.check(small);
        expect(v.right, isFalse, reason: id);
        expect(v.fault, StrokeFault.lines, reason: id);
      }
    });

    test('a scribble is a retry with no name', () {
      final math.Random r = math.Random(9);
      for (final String id in <String>['latin.a', 'cyrillic.zhe.cap', 'hebrew-print.alef']) {
        final LetterChecker c = LetterChecker(strokeForm(id));
        final List<Offset> scribble = <Offset>[
          for (int i = 0; i < 30; i++) Offset(30 + r.nextDouble() * 40, 20 + r.nextDouble() * 60),
        ];
        final StrokeVerdict v = c.check(scribble);
        expect(v.right, isFalse, reason: id);
        expect(v.named, isFalse, reason: id);
      }
    });

    test('a dot is a tap near its point, and a tap elsewhere is nothing', () {
      final LetterChecker c = LetterChecker(strokeForm('latin.i'));
      final StrokeModel dot = strokeForm('latin.i').strokes.last;
      expect(
        c.check(<Offset>[dot.start + const Offset(40, 0), dot.start + const Offset(40.5, 0.5)]).named,
        isFalse,
      );
      expect(c.done.last, isFalse);
      expect(
        c.check(<Offset>[dot.start + const Offset(4, 3), dot.start + const Offset(4.5, 3.5)]).right,
        isTrue,
      );
      expect(c.done.last, isTrue);
    });

    test('stroke order does not matter: the dot first, then the stem', () {
      final StrokeForm f = strokeForm('latin.i');
      final LetterChecker c = LetterChecker(f);
      final math.Random r = math.Random(4);
      expect(c.check(writeStroke(f.strokes.last, r, StrokeHand.adult)).right, isTrue);
      expect(c.check(writeStroke(f.strokes.first, r, StrokeHand.adult)).right, isTrue);
      expect(c.complete, isTrue);
    });
  });
}
