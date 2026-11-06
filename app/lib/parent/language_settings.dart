import 'dart:convert';

import '../content/schemas.dart' show courseRoutes;
import '../engine/course.dart';
import '../engine/presentation.dart';

// The parent's settings for each language of each child (docs/languages/frame.md section 1.4): whether the language is on, and
// the switches of its page. They are kept on the device as one small JSON setting (`languages`), travel inside the family's
// rules document like the parents' promises (child id, then course), and hold ids, enums, booleans and small numbers only.
// Every value is checked when it is read, on the phone and again on the server (`settings-put`); a damaged or hand-edited
// value is dropped, never turned into something else. Only what differs from the default is stored, so a family that never
// turns a language on has nothing here, and the rules document it syncs is exactly what it was before.

/// Where the language settings are kept on the device.
const String languagesSettingKey = 'languages';

/// Russian stress marks on screen: follow the child's route (a new learner sees them, a heritage speaker or a reader does
/// not), or the parent's choice.
enum StressMarks { route, on, off }

/// The question of a course's questionnaire and the answers it takes. Enums only: nothing free-text, nothing sent to a vendor.
/// An answer sets where a placement staircase starts, never where it ends (docs/languages/frame.md section 3.2).
const Map<String, Map<String, List<String>>> languageQuestionnaire = <String, Map<String, List<String>>>{
  Course.eng: <String, List<String>>{
    'knowsLetters': <String>['no', 'some'],
  },
  Course.heb: <String, List<String>>{},
  Course.rus: <String, List<String>>{
    'home': <String>['none', 'oneParent', 'bothParents', 'grandparentsOthers'],
    'understands': <String>['no', 'some', 'most'],
    'speaks': <String>['no', 'words', 'sentences'],
    'letters': <String>['no', 'some', 'most'],
    'reads': <String>['no', 'syllables', 'words', 'sentences'],
  },
};

/// The switches that exist only for some courses (the others are for every course), as the names the document uses.
const Map<String, Set<String>> languageOwnSwitches = <String, Set<String>>{
  Course.eng: <String>{'oralOnly'},
  Course.heb: <String>{'readCheck'},
  Course.rus: <String>{'lettersBefore5', 'stress', 'route'},
};

/// At most this many children have language settings (the family's rules document has room for no more).
const int maxLanguageChildren = 6;

/// What a parent chose for one language of one child. A language that was never touched has the defaults: off.
class LanguageSwitches {
  const LanguageSwitches({
    this.on = false,
    this.voice = false,
    this.personal = true,
    this.oralOnly = false,
    this.lettersBefore5 = false,
    this.stress = StressMarks.route,
    this.readCheck = false,
    this.route,
    this.band,
    this.questionnaire = const <String, String>{},
  });

  /// Reads one course's switches from the document. A key that does not belong to the course, an unknown key, a value of the
  /// wrong kind or out of range, and an answer the questionnaire does not take are all dropped.
  factory LanguageSwitches.fromJson(String course, Object? json) {
    if (!Course.isLanguage(course) || json is! Map<String, Object?>) return const LanguageSwitches();
    final Set<String> own = languageOwnSwitches[course] ?? const <String>{};
    bool flag(String k, bool fallback) => json[k] is bool ? json[k]! as bool : fallback;
    final Object? q = json['q'];
    final Map<String, List<String>> asks = languageQuestionnaire[course]!;
    return LanguageSwitches(
      on: flag('on', false),
      voice: flag('voice', false),
      personal: flag('personal', true),
      oralOnly: own.contains('oralOnly') && flag('oralOnly', false),
      lettersBefore5: own.contains('lettersBefore5') && flag('lettersBefore5', false),
      stress: own.contains('stress') ? _stressOf(json['stress']) : StressMarks.route,
      readCheck: own.contains('readCheck') && flag('readCheck', false),
      route: own.contains('route') && courseRoutes.contains(json['route']) ? json['route']! as String : null,
      band: json['band'] is int && (json['band']! as int) >= 0 && (json['band']! as int) <= 2
          ? json['band']! as int
          : null,
      questionnaire: <String, String>{
        if (q is Map<String, Object?>)
          for (final MapEntry<String, Object?> e in q.entries)
            if (asks[e.key]?.contains(e.value) ?? false) e.key: e.value! as String,
      },
    );
  }

  static StressMarks _stressOf(Object? v) => switch (v) {
    'on' => StressMarks.on,
    'off' => StressMarks.off,
    _ => StressMarks.route,
  };

  /// The language is on for this child: its door shows on the island and it is a land for Today's Adventure. Off hides the door
  /// and keeps everything the child did.
  final bool on;

  /// Voice answers in this language (the microphone, and the download of its recogniser).
  final bool voice;

  /// Scripted personal questions in lessons (name, age, likes, family; never an address).
  final bool personal;

  /// English: no letters yet; keeps the oral gate closed.
  final bool oralOnly;

  /// Russian: letters before age 5; opens the letters gate.
  final bool lettersBefore5;

  /// Russian: stress marks on screen.
  final StressMarks stress;

  /// Hebrew: the parent's own check of reading aloud.
  final bool readCheck;

  /// Russian: `new`, `heritage` or `reader`, or null while it is not known.
  final String? route;

  /// The presentation band for this course when the parent set one (0, 1 or 2), or null to follow the child's age.
  final int? band;

  /// The answers to the course's questionnaire, by question.
  final Map<String, String> questionnaire;

  /// The same, with the given fields changed. [route], [band] and [questionnaire] can be set to null or empty by passing the
  /// matching `clear...` flag, because null alone means "keep".
  LanguageSwitches copyWith({
    bool? on,
    bool? voice,
    bool? personal,
    bool? oralOnly,
    bool? lettersBefore5,
    StressMarks? stress,
    bool? readCheck,
    String? route,
    bool clearRoute = false,
    int? band,
    bool clearBand = false,
    Map<String, String>? questionnaire,
  }) => LanguageSwitches(
    on: on ?? this.on,
    voice: voice ?? this.voice,
    personal: personal ?? this.personal,
    oralOnly: oralOnly ?? this.oralOnly,
    lettersBefore5: lettersBefore5 ?? this.lettersBefore5,
    stress: stress ?? this.stress,
    readCheck: readCheck ?? this.readCheck,
    route: clearRoute ? null : route ?? this.route,
    band: clearBand ? null : band ?? this.band,
    questionnaire: questionnaire ?? this.questionnaire,
  );

  /// Only what differs from the default.
  Map<String, Object?> toJson() => <String, Object?>{
    if (on) 'on': true,
    if (voice) 'voice': true,
    if (!personal) 'personal': false,
    if (oralOnly) 'oralOnly': true,
    if (lettersBefore5) 'lettersBefore5': true,
    if (stress != StressMarks.route) 'stress': stress.name,
    if (readCheck) 'readCheck': true,
    'route': ?route,
    'band': ?band,
    if (questionnaire.isNotEmpty) 'q': questionnaire,
  };

  bool get isDefault => toJson().isEmpty;

  /// The names of the parent switches that are on and that a gate may name (`oralOnly`, `lettersBefore5`).
  Set<String> get gateSwitchesOn => <String>{if (oralOnly) 'oralOnly', if (lettersBefore5) 'lettersBefore5'};

  /// The presentation band for a child of the given age bracket in this course: the parent's choice, else the age's.
  int presentationBand(int ageBand) => presentationBandFor(ageBand: ageBand, override: band);

  @override
  bool operator ==(Object other) =>
      other is LanguageSwitches && jsonEncode(other.toJson()) == jsonEncode(toJson());

  @override
  int get hashCode => jsonEncode(toJson()).hashCode;
}

/// The language settings of a whole family: child id, then course. The document is small and is replaced as a whole.
class FamilyLanguages {
  const FamilyLanguages([this._byChild = const <String, Map<String, LanguageSwitches>>{}]);

  /// Reads the document. Anything that is not a child's id, a language course or a settings object is dropped; what the
  /// document says about more than [maxLanguageChildren] children is cut (the first ones in id order stay).
  factory FamilyLanguages.fromJson(Object? json) {
    if (json is! Map<String, Object?>) return const FamilyLanguages();
    final Map<String, Map<String, LanguageSwitches>> out = <String, Map<String, LanguageSwitches>>{};
    for (final String child in (json.keys.toList()..sort())) {
      final Object? byCourse = json[child];
      if (!_childId.hasMatch(child) ||
          byCourse is! Map<String, Object?> ||
          out.length >= maxLanguageChildren) {
        continue;
      }
      final Map<String, LanguageSwitches> own = <String, LanguageSwitches>{
        for (final String c in Course.languages)
          if (LanguageSwitches.fromJson(c, byCourse[c]) case final LanguageSwitches s when !s.isDefault) c: s,
      };
      if (own.isNotEmpty) out[child] = own;
    }
    return FamilyLanguages(out);
  }

  factory FamilyLanguages.decode(String? text) {
    if (text == null || text.isEmpty) return const FamilyLanguages();
    try {
      return FamilyLanguages.fromJson(jsonDecode(text));
    } on FormatException {
      return const FamilyLanguages();
    }
  }

  /// The same pattern as a child id everywhere (`child-put`).
  static final RegExp _childId = RegExp(r'^[A-Za-z0-9-]{8,64}$');

  final Map<String, Map<String, LanguageSwitches>> _byChild;

  bool get isEmpty => _byChild.isEmpty;

  /// Some child has the voice switch of [course] on (the course's recogniser is wanted).
  bool anyVoice(String course) =>
      _byChild.values.any((Map<String, LanguageSwitches> m) => m[course]?.voice ?? false);

  /// What this child's parent chose for [course] (the defaults if nothing).
  LanguageSwitches of(String childId, String course) =>
      _byChild[childId]?[course] ?? const LanguageSwitches();

  /// The courses that are on for this child, in the fixed order of the doors.
  List<String> enabledFor(String childId) => <String>[
    for (final String c in Course.languages)
      if (of(childId, c).on) c,
  ];

  /// With [switches] set for one language of one child. Returns null if [course] is no language, the id is not a child's, or the
  /// family would then have settings for more than [maxLanguageChildren] children.
  FamilyLanguages? withSwitches(String childId, String course, LanguageSwitches switches) {
    if (!Course.isLanguage(course) || !_childId.hasMatch(childId)) return null;
    if (!_byChild.containsKey(childId) && !switches.isDefault && _byChild.length >= maxLanguageChildren) {
      return null;
    }
    final Map<String, Map<String, LanguageSwitches>> next = <String, Map<String, LanguageSwitches>>{
      for (final MapEntry<String, Map<String, LanguageSwitches>> e in _byChild.entries)
        e.key: Map<String, LanguageSwitches>.of(e.value),
    };
    final Map<String, LanguageSwitches> mine = next[childId] ??= <String, LanguageSwitches>{};
    // Re-read through the document so that a switch that does not belong to the course is dropped here too.
    final LanguageSwitches clean = LanguageSwitches.fromJson(course, switches.toJson());
    if (clean.isDefault) {
      mine.remove(course);
    } else {
      mine[course] = clean;
    }
    if (mine.isEmpty) next.remove(childId);
    return FamilyLanguages(next);
  }

  /// Without anything for [childId] (a removed child's settings go with the child).
  FamilyLanguages without(String childId) => FamilyLanguages(<String, Map<String, LanguageSwitches>>{
    for (final MapEntry<String, Map<String, LanguageSwitches>> e in _byChild.entries)
      if (e.key != childId) e.key: e.value,
  });

  Map<String, Object?> toJson() => <String, Object?>{
    for (final MapEntry<String, Map<String, LanguageSwitches>> e in _byChild.entries)
      e.key: <String, Object?>{
        for (final MapEntry<String, LanguageSwitches> c in e.value.entries) c.key: c.value.toJson(),
      },
  };

  String encode() => jsonEncode(toJson());
}
