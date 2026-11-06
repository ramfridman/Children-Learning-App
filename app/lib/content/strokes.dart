import 'dart:ui' show Offset;

// The stroke data of a script (docs/languages/strokes.md, format `nitznutz.strokes/1`): where every stroke of every letter starts, goes
// and ends in a box of 100 by 100 units. It travels inside the course's signed pack as a document `strokes.<set>.json` and is read only
// after the pack passed the schema and the cross-file rules (`strokesSchema`, `ls02_checks.dart`), so these classes do not defend
// against a wrong shape. A child's own strokes are never kept here: they are compared in memory and dropped with the session.

enum StrokeKind {
  /// Traced and checked along its path.
  line,

  /// The dot of i, j, Cyrillic yo: a tap near its point.
  dot,

  /// A real stroke too short to trace as a path (a leg, a flag, a breve): checked by where it starts and which way it goes.
  short,
}

StrokeKind _kind(String s) => switch (s) {
  'dot' => StrokeKind.dot,
  'short' => StrokeKind.short,
  _ => StrokeKind.line,
};

List<Offset> _points(Object? json) => <Offset>[
  for (final Object? p in json! as List<Object?>)
    Offset(((p! as List<Object?>)[0]! as num).toDouble(), ((p as List<Object?>)[1]! as num).toDouble()),
];

/// One stroke of a letter.
class StrokeModel {
  const StrokeModel({
    required this.kind,
    required this.points,
    required this.moves,
    required this.d,
    this.retrace = false,
  });

  factory StrokeModel.fromJson(Map<String, Object?> json) => StrokeModel(
    kind: _kind(json['kind']! as String),
    points: _points(json['points']),
    moves: <String>[for (final Object? m in json['moves']! as List<Object?>) m! as String],
    d: json['d']! as String,
    retrace: json['retrace'] == true,
  );

  /// A stroke of another right build of a letter: only its kind and its centre line are kept, it is never drawn.
  factory StrokeModel.fromBuildJson(Map<String, Object?> json) => StrokeModel(
    kind: _kind(json['kind']! as String),
    points: _points(json['points']),
    moves: const <String>[],
    d: '',
    retrace: json['retrace'] == true,
  );

  final StrokeKind kind;

  /// The centre line, from where the stroke starts to where it ends.
  final List<Offset> points;

  /// The way it goes in words (`down`, `right`, `cw` ...), in order.
  final List<String> moves;

  /// The same stroke as a smooth path (M, L and C in box units), for drawing the model and the "watch it drawn" motion.
  final String d;

  /// The model goes back over its own line (n, m, h, a, d).
  final bool retrace;

  Offset get start => points.first;
  Offset get end => points.last;

  /// The total length of the centre line, in box units.
  double get length {
    double sum = 0;
    for (int i = 1; i < points.length; i++) {
      sum += (points[i] - points[i - 1]).distance;
    }
    return sum;
  }
}

/// One letter (a form): a capital and a small letter are two forms, and so is a Hebrew final.
class StrokeForm {
  const StrokeForm({
    required this.id,
    required this.char,
    required this.strokes,
    this.alternates = const <List<StrokeModel>>[],
  });

  factory StrokeForm.fromJson(Map<String, Object?> json) => StrokeForm(
    id: json['id']! as String,
    char: json['char']! as String,
    strokes: <StrokeModel>[
      for (final Object? s in json['strokes']! as List<Object?>)
        StrokeModel.fromJson(s! as Map<String, Object?>),
    ],
    alternates: <List<StrokeModel>>[
      for (final Object? b in (json['alternates'] as List<Object?>?) ?? const <Object?>[])
        <StrokeModel>[
          for (final Object? s in (b! as Map<String, Object?>)['strokes']! as List<Object?>)
            StrokeModel.fromBuildJson(s! as Map<String, Object?>),
        ],
    ],
  );

  final String id;

  /// The letter as text (for a screen reader and a model drawn in the font's place).
  final String char;

  /// The model: the strokes in the order the school chart writes them. This is what is drawn, walked and traced.
  final List<StrokeModel> strokes;

  /// The other builds of the letter that are right (a ball and a stick for a; at most four, in the same box). The free-stroke check
  /// accepts a letter built from the model or from any of these; nothing else uses them.
  final List<List<StrokeModel>> alternates;

  /// The model and then the other builds.
  Iterable<List<StrokeModel>> get builds => <List<StrokeModel>>[strokes, ...alternates];
}

/// The forms of one script, with the lines they sit on.
class StrokeSet {
  const StrokeSet({
    required this.name,
    required this.rtl,
    required this.ink,
    required this.guides,
    required this.solidGuides,
    required this.forms,
  });

  factory StrokeSet.fromJson(Map<String, Object?> json) => StrokeSet(
    name: json['set']! as String,
    rtl: json['direction'] == 'rtl',
    ink: (json['ink']! as num).toDouble(),
    guides: <String, double>{
      for (final MapEntry<String, Object?> g in (json['guides']! as Map<String, Object?>).entries)
        g.key: (g.value! as num).toDouble(),
    },
    solidGuides: <String>{for (final Object? g in json['solidGuides']! as List<Object?>) g! as String},
    forms: <String, StrokeForm>{
      for (final Object? f in json['forms']! as List<Object?>)
        (f! as Map<String, Object?>)['id']! as String: StrokeForm.fromJson(f as Map<String, Object?>),
    },
  );

  final String name;

  /// The script is written from the right (Hebrew).
  final bool rtl;

  /// The width of the ink in box units.
  final double ink;

  /// The lines a letter sits on, as y in the box (`base`, `x`, `top` ...); [solidGuides] are drawn solid, the others dashed.
  final Map<String, double> guides;
  final Set<String> solidGuides;
  final Map<String, StrokeForm> forms;

  /// The set a form id belongs to (`latin.s`, `cyrillic.a.cap`, `hebrew-print.mem` -> its text before the first dot).
  static String setOf(String formId) => formId.substring(0, formId.indexOf('.'));
}
