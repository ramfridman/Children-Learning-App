// Hands for the tests of the free-stroke check (LS02): the stroke sets of the teacher-checked files, and strokes written from the model the
// way an adult and a made-up child write (a seeded generator, so the same samples come back every run). The child is deliberately extreme.
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' show Offset;

import 'package:nitznutz/content/strokes.dart';
import 'package:nitznutz/play/stroke_check.dart';
import 'package:nitznutz/play/stroke_geometry.dart';

StrokeSet loadStrokeSet(String name) => StrokeSet.fromJson(
  jsonDecode(File('../content/languages/strokes/$name.json').readAsStringSync())! as Map<String, Object?>,
);

/// The three print sets by name (run from the `app` folder, as `flutter test` does).
final Map<String, StrokeSet> strokeSets = <String, StrokeSet>{
  for (final String n in <String>['latin', 'cyrillic', 'hebrew-print']) n: loadStrokeSet(n),
};

StrokeForm strokeForm(String id) => strokeSets[StrokeSet.setOf(id)]!.forms[id]!;

class StrokeHand {
  const StrokeHand({
    required this.jitter,
    required this.wobble,
    required this.startOff,
    required this.scale,
    required this.shift,
  });

  /// An adult: close to the model.
  static const StrokeHand adult = StrokeHand(
    jitter: 0.25,
    wobble: 1.2,
    startOff: 2.5,
    scale: 0.03,
    shift: 1.5,
  );

  /// A child: a shaky line, a start that is a little off, a letter a little too big or small and a little to one side.
  static const StrokeHand child = StrokeHand(jitter: 0.6, wobble: 3.2, startOff: 7, scale: 0.08, shift: 4);

  /// Per-point shake, the slow wander of the hand (units), how far the start may be off, how far the size may be off, how far the place may be.
  final double jitter, wobble, startOff, scale, shift;
}

/// A stroke as a finger writes it: points a unit or so apart, a slow wander (not independent noise at every point), a small shake.
List<Offset> writeStroke(StrokeModel m, math.Random r, StrokeHand h, {List<Offset>? path}) {
  final double scale = 1 + (r.nextDouble() * 2 - 1) * h.scale;
  final Offset shift = Offset((r.nextDouble() * 2 - 1) * h.shift, (r.nextDouble() * 2 - 1) * h.shift);
  Offset place(Offset p) => (p - const Offset(50, 50)) * scale + const Offset(50, 50) + shift;
  if (m.kind == StrokeKind.dot) {
    // A tap is aimed: half the care of a start.
    final Offset c =
        place(m.start) +
        Offset((r.nextDouble() * 2 - 1) * h.startOff / 2, (r.nextDouble() * 2 - 1) * h.startOff / 2);
    return <Offset>[c, c + const Offset(0.5, 0.5)];
  }
  final List<Offset> shape = path ?? m.points;
  // A finger reports a point every unit or so, and a hand wanders over a distance: a short mark is nearly straight.
  final List<Offset> base = resampleStroke(shape, math.max(4, math.min(40, strokeLength(shape).round())));
  final double wander = h.wobble * math.min(1.0, strokeLength(base) / 45);
  final double phase = r.nextDouble() * math.pi * 2;
  final double phase2 = r.nextDouble() * math.pi * 2;
  final Offset startOff = Offset(
    (r.nextDouble() * 2 - 1) * h.startOff,
    (r.nextDouble() * 2 - 1) * h.startOff,
  );
  return <Offset>[
    for (final (int i, Offset p) in base.indexed)
      place(p) +
          Offset((r.nextDouble() * 2 - 1) * h.jitter, (r.nextDouble() * 2 - 1) * h.jitter) +
          Offset(math.sin(i / 9 + phase), math.cos(i / 11 + phase2)) * wander +
          startOff * math.max(0, 1 - i / 8),
  ];
}

/// Every stroke of [form] written by [h], as the child would, in the given order.
List<List<Offset>> writeLetter(StrokeForm form, int seed, StrokeHand h, {bool shuffle = false}) {
  final math.Random r = math.Random(seed);
  final List<int> order = List<int>.generate(form.strokes.length, (int i) => i);
  if (shuffle) order.shuffle(r);
  return <List<Offset>>[for (final int i in order) writeStroke(form.strokes[i], r, h)];
}

List<Offset> mirrorStroke(List<Offset> pts) => <Offset>[for (final Offset p in pts) Offset(100 - p.dx, p.dy)];

/// Every stroke of a build (the model's or another right build), written by [h] in the order given.
List<List<Offset>> writeBuild(List<StrokeModel> build, int seed, StrokeHand h) {
  final math.Random r = math.Random(seed);
  return <List<Offset>>[for (final StrokeModel m in build) writeStroke(m, r, h)];
}

/// What the session does with a child who writes [written] when the target is [target]: a stroke the check takes is kept; once the target is
/// whole the rest of what is drawn is only collected, and when the child stops everything drawn is read against the whole script
/// (`LetterWriteSession._settled`). True when the item would count as a success.
bool countedForTarget(StrokeForm target, Iterable<StrokeForm> script, List<List<Offset>> written) {
  final LetterChecker c = LetterChecker(target);
  final List<List<Offset>> drawn = <List<Offset>>[];
  for (final List<Offset> s in written) {
    drawn.add(s);
    if (!c.complete) c.check(s);
  }
  return c.complete && c.otherLetter(script, drawn) == null;
}
