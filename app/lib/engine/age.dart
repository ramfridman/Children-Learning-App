// What the app knows about a child's age, and how (B-29, docs/milestones/B29.md). Three separate facts, kept apart on purpose:
//
//  - the SCHOOL STAGE (gan 3 to grade 3), which a parent confirms. It sets the band (A, B or C), and it is the only age value that
//    syncs. It is never worked out from a birthday.
//  - the MONTH AND YEAR OF BIRTH (never the day), kept on this device only (`ProfileBirths`). From it come the age in months and the
//    presentation stage P1 to P4, in memory, at the moment they are asked for. They are never stored, synced, logged, sent or exported.
//  - the BAND of a profile that has no school stage yet (a child made before B-29): the middle of the band stands in for both.
//
// Presentation (how things look) follows the age; content (which lessons) follows mastery. Nothing here is an input of mastery, of
// the finished lessons or of the path, so a birthday can never change them (`test/birthday_changes_nothing_test.dart`).

/// The school stage a parent confirms for a child. The names are what the gateway takes (`testvectors/profile-sync.json`).
enum SchoolStage {
  gan3('gan3', 0),
  gan4('gan4', 0),
  gan5('gan5', 1),
  grade1('grade1', 1),
  grade2('grade2', 2),
  grade3('grade3', 2);

  const SchoolStage(this.wire, this.band);

  /// The word that travels to the server and back.
  final String wire;

  /// The band this stage sets: 0, 1 or 2 for A, B and C.
  final int band;

  /// The stage a parent is asked about each September: the one after this. Older than grade 3 stays grade 3 (Band C).
  SchoolStage get next => index + 1 < values.length ? values[index + 1] : this;

  /// The stage for a word, or null when it is not exactly one of the six (the server's copy is untrusted like any input).
  static SchoolStage? fromWire(Object? word) {
    if (word is! String) return null;
    for (final SchoolStage s in values) {
      if (s.wire == word) return s;
    }
    return null;
  }

  /// The stage that stands in for a child with only a band: the middle of it (gan 4, gan 5, grade 2).
  static SchoolStage middleOfBand(int band) => switch (band.clamp(0, 2)) {
    0 => gan4,
    1 => gan5,
    _ => grade2,
  };
}

/// The month and year of birth, with no day.
class BirthMonth {
  const BirthMonth(this.year, this.month);

  /// The oldest a child may be, in months, for a birth month to be taken (9;11: the app is for ages 3 to 8, with room).
  static const int maxAgeMonths = 119;

  final int year;
  final int month;

  /// The birth month for [year] and [month], or null when the month is not 1 to 12, lies after [now], or makes the child ten or more.
  static BirthMonth? tryCreate(int year, int month, {required DateTime now}) {
    if (month < 1 || month > 12) return null;
    final BirthMonth born = BirthMonth(year, month);
    final int age = ageInMonths(born, now);
    return age < 0 || age > maxAgeMonths ? null : born;
  }

  @override
  bool operator ==(Object other) => other is BirthMonth && other.year == year && other.month == month;

  @override
  int get hashCode => Object.hash(year, month);

  // The month and year are what this class is for, so a stray `print` or log line must not show them.
  @override
  String toString() => 'BirthMonth(…)';
}

/// The age in whole calendar months at [now]: the day of the month is not known, so a child born in May is 0 months old for all of May.
int ageInMonths(BirthMonth born, DateTime now) => (now.year - born.year) * 12 + (now.month - born.month);

/// How a screen looks for a child's age (the design-director's four stages): P1 up to 3;5, P2 3;6 to 4;11, P3 5;0 to 6;5, P4 6;6 and up.
enum PresentationStage {
  p1,
  p2,
  p3,
  p4;

  /// The stage for [months]; below zero is the youngest.
  static PresentationStage forAgeInMonths(int months) {
    if (months < 42) return p1;
    if (months < 60) return p2;
    if (months < 78) return p3;
    return p4;
  }
}

/// The age at which a profile with only a band is taken to be, in months: the middle of the band (A 4;0, B 6;0, C 7;6).
const List<int> assumedMonthsOfBand = <int>[48, 72, 90];

/// What is known about one child's age at one moment. It is worked out when asked for and never kept: a session reads it once at its
/// start, so nothing changes under a child mid-lesson.
class ChildAge {
  const ChildAge._({
    required this.stage,
    required this.stageConfirmed,
    required this.months,
    required this.presentation,
  });

  /// The school stage: the one a parent confirmed, else the middle of the profile's band.
  final SchoolStage stage;

  /// Whether a parent confirmed [stage] (false for a child made before B-29, until a parent does).
  final bool stageConfirmed;

  /// The age in months from the birth month on this device, or null when no month and year were given.
  final int? months;

  /// The look: from the age in months when it is known, else the middle of the band.
  final PresentationStage presentation;

  /// The band (0, 1, 2) the stage sets. This is what the server gets and what the lessons are chosen by; it never follows [months].
  int get band => stage.band;

  /// The age the look is chosen by: [months] when known, else the middle of the band.
  int get assumedMonths => months ?? assumedMonthsOfBand[band];
}

/// What is known about a child at [now]: [band] is the profile's stored band (used when there is no [stage]), [stage] the confirmed
/// school stage, [birth] the month and year kept on this device.
ChildAge childAge({required int band, SchoolStage? stage, BirthMonth? birth, required DateTime now}) {
  final SchoolStage s = stage ?? SchoolStage.middleOfBand(band);
  final int? months = birth == null ? null : ageInMonths(birth, now);
  return ChildAge._(
    stage: s,
    stageConfirmed: stage != null,
    months: months,
    presentation: PresentationStage.forAgeInMonths(months ?? assumedMonthsOfBand[s.band]),
  );
}

// ---- the rules of the parent's age settings and of the look (B-29 steps 5b, 6 and 7) ----

/// The year the school year [now] belongs to starts in: a school year starts on 1 September, so August 2026 is still 2025's.
int schoolYearOf(DateTime now) => now.month >= 9 ? now.year : now.year - 1;

/// The school stage a year of birth suggests (the Israeli cohort is the calendar year of birth: a child born in 2021 is in gan hova in
/// the school year that starts in 2026). The parent confirms it or chooses another; it is only a suggestion. Clamped to gan 3 and
/// grade 3.
SchoolStage suggestedStage(int year, DateTime now) =>
    SchoolStage.values[(schoolYearOf(now) - year - 3).clamp(0, SchoolStage.values.length - 1)];

/// The look a child sees (docs/design/b29-steps5-6.md section 3.3): from the age, unless the parent chose a look letter for the child, or
/// the parent chose a band for this course (which wins inside that course). A letter clamps the stage into its band (A is P1 or P2, B is
/// P3, C is P4), so "ages 3 to 4" never makes a child of 3;2 look older, and the lessons themselves are not touched.
PresentationStage effectiveStage(ChildAge age, {int? lookBand, int? courseBand}) {
  final int? band = courseBand ?? lookBand;
  if (band == null) return age.presentation;
  return switch (band.clamp(0, 2)) {
    0 => age.presentation == PresentationStage.p1 ? PresentationStage.p1 : PresentationStage.p2,
    1 => PresentationStage.p3,
    _ => PresentationStage.p4,
  };
}

/// What the parent chose for the question captions on this device: by the school stage, always, or never.
enum CaptionSetting {
  auto('auto'),
  on('on'),
  off('off');

  const CaptionSetting(this.word);

  final String word;

  /// The setting for a stored word; anything else is "by stage".
  static CaptionSetting fromWord(String? word) {
    for (final CaptionSetting s in values) {
      if (s.word == word) return s;
    }
    return auto;
  }
}

/// Whether the Hebrew words of the question are drawn: gan 3 and gan 4 do not read yet, so by default they hear the question and see a
/// speaker; gan hova to grade 3 see the words. Nikud stays full whenever they show.
bool captionsShownFor(SchoolStage stage, CaptionSetting setting) => switch (setting) {
  CaptionSetting.on => true,
  CaptionSetting.off => false,
  CaptionSetting.auto => stage.index >= SchoolStage.gan5.index,
};

/// Whether the September card asks about [stage] on [now]: a confirmed stage below grade 3 whose last confirmation was for an earlier
/// school year than this one. [confirmedYear] is the school year of that confirmation; with none recorded the card does not ask.
bool septemberCardDue({required SchoolStage? stage, required int? confirmedYear, required DateTime now}) =>
    stage != null &&
    stage != SchoolStage.grade3 &&
    confirmedYear != null &&
    confirmedYear < schoolYearOf(now);

/// Whether the card that invites the parent to add the age shows: a child with no confirmed stage, unless the parent said "not now"
/// in this school year ([hiddenYear]; the card comes back on the next 1 September).
bool addAgeCardDue({required SchoolStage? stage, required int? hiddenYear, required DateTime now}) =>
    stage == null && (hiddenYear == null || hiddenYear < schoolYearOf(now));

/// Whether the child is [minYears] years old: from the age in months when a month and year were given (a gate "not before 5" opens at
/// 5;0), else from the age of the band, as before (3, 5 or 7).
bool oldEnough(ChildAge age, {required int minYears}) {
  final int? months = age.months;
  return months != null ? months >= minYears * 12 : const <int>[3, 5, 7][age.band] >= minYears;
}
