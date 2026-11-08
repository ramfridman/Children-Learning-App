import '../content/models.dart';

// The choice cap (B-29 step 6, docs/design/b29-steps5-6.md section 6.4): a safety net, not the way content is written. An item with more
// answer options than the look allows (P1 and P2 three, P3 four, P4 five) shows only as many as fit: the right option or options first, then
// the options that carry a misconception tag, then the rest, each group in its authored order; the ones kept stay in their authored order, so
// a row of numbers stays ascending. The cap counts answer options only, never the things on the stage (counting may show more). The activity
// that comes back is a new one with fewer options, so `optionCount` (which the two-choice retry rule reads) is the count after the cap.

/// The ids of the options of [options] that stay when at most [max] are shown. Every right option stays, even when they alone are more than
/// [max] (a tap-all of four is never cut to three).
List<String> keptOptionIds(List<({String id, bool correct, bool tagged})> options, int max) {
  if (options.length <= max) return <String>[for (final o in options) o.id];
  final Set<String> keep = <String>{
    for (final o in options)
      if (o.correct) o.id,
  };
  for (final o in options.where((o) => !o.correct && o.tagged)) {
    if (keep.length < max) keep.add(o.id);
  }
  for (final o in options.where((o) => !o.correct && !o.tagged)) {
    if (keep.length < max) keep.add(o.id);
  }
  return <String>[
    for (final o in options)
      if (keep.contains(o.id)) o.id,
  ];
}

/// [a] with at most [max] answer options (see the top of this file), or [a] itself when it has no options, has no more than [max], or is not
/// a choice. The item is rebuilt from its own document, so everything else about it is as authored.
Activity capChoices(Activity a, int max) {
  if (a is! ChoiceActivity || (a as ChoiceActivity).options.length <= max) return a;
  final Object? answer = a.json['answer'];
  if (answer is! Map<String, Object?>) return a;
  final Object? raw = answer['options'];
  if (raw is! List<Object?>) return a;
  final Object? right = answer['correct'];
  final Set<String> correct = right is String
      ? <String>{right}
      : right is List<Object?>
      ? <String>{for (final Object? r in right) r! as String}
      : <String>{};
  final List<Map<String, Object?>> all = <Map<String, Object?>>[
    for (final Object? o in raw) o! as Map<String, Object?>,
  ];
  final Set<String> kept = keptOptionIds(<({String id, bool correct, bool tagged})>[
    for (final Map<String, Object?> o in all)
      (id: o['id']! as String, correct: correct.contains(o['id']), tagged: o['misconception'] != null),
  ], max).toSet();
  return Activity.fromJson(<String, Object?>{
    ...a.json,
    'answer': <String, Object?>{
      ...answer,
      'options': <Map<String, Object?>>[
        for (final Map<String, Object?> o in all)
          if (kept.contains(o['id'])) o,
      ],
    },
  }, a.assets);
}
