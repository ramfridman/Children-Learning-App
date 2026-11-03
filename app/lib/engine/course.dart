// The courses of the app (docs/languages/frame.md section 1.5). `core` is every existing land (numbers, colours, shapes,
// logic, computer science, maths); `eng`, `heb` and `rus` are the three language courses. A course is the unit that never
// mixes with another: its skills, items, misconception tags, placement, progress and pack are its own.
//
// Plain strings, not an enum: the course travels in pack files, in synced events and in the parent's settings, and every
// place that reads one checks it against [Course.all].

abstract final class Course {
  static const String core = 'core';
  static const String eng = 'eng';
  static const String heb = 'heb';
  static const String rus = 'rus';

  /// The three language courses, in the fixed order the doors and the map use.
  static const List<String> languages = <String>[eng, heb, rus];
  static const List<String> all = <String>[core, eng, heb, rus];

  /// The domain of every skill of a language course; the course itself says which language.
  static const String languagesDomain = 'languages';

  static bool isKnown(String course) => all.contains(course);

  static bool isLanguage(String course) => languages.contains(course);

  /// Whether the course's own text runs right to left: Hebrew does, English and Russian run left to right. The screens of a course
  /// lay out what they read (a path of lessons, its labels) in this direction; the rest of the app stays in Hebrew.
  static bool readsRightToLeft(String course) => course == heb;

  /// The id a language course's pack has (`lang-eng`); null for `core`, whose packs choose their own ids.
  static String? packIdOf(String course) => isLanguage(course) ? 'lang-$course' : null;

  /// The course a pack id belongs to: `lang-eng` is `eng`, any other id is `core`. Null for a `lang-` id that names no
  /// course (such a pack is refused).
  static String? ofPackId(String packId) {
    if (!packId.startsWith(_langPrefix)) return core;
    final String rest = packId.substring(_langPrefix.length);
    return isLanguage(rest) ? rest : null;
  }

  /// The capital letters a language course's skill ids start with (`ENG`); null for `core`.
  static String? skillPrefixOf(String course) => isLanguage(course) ? course.toUpperCase() : null;

  /// The course a skill id belongs to, from its prefix: `ENG-A-01` and `ENG-B-19.G1` are `eng`, everything else `core`.
  static String ofSkillId(String skillId) {
    for (final String c in languages) {
      if (skillId.startsWith('${c.toUpperCase()}-')) return c;
    }
    return core;
  }

  /// The course a misconception tag belongs to: `eng.ph.dir` is `eng`, `M-CNT-DOUBLE` is `core`.
  static String ofTag(String tag) {
    for (final String c in languages) {
      if (tag.startsWith('$c.')) return c;
    }
    return core;
  }

  /// The course an activity or a lesson id belongs to: a language course's ids begin with `<course>.` (`eng.greet.i01`), so no two
  /// courses, and no course and the lands, ever share an id; every other id is `core`.
  static String ofActivityId(String id) {
    for (final String c in languages) {
      if (id.startsWith('$c.')) return c;
    }
    return core;
  }

  /// The course an answer belongs to, read from every field that names one: its skill, its pack, its activity, its misconception
  /// tag and the course it says itself. Null when they disagree: such an answer is damaged or forged, and evidence never crosses
  /// courses.
  static String? ofAnswer({
    required String skillId,
    required String packId,
    String activityId = '',
    String tag = '',
    String? course,
  }) {
    final String own = ofSkillId(skillId);
    if (ofPackId(packId) != own) return null;
    if (activityId.isNotEmpty && ofActivityId(activityId) != own) return null;
    if (tag.isNotEmpty && ofTag(tag) != own) return null;
    if (course != null && course != own) return null;
    return own;
  }

  static const String _langPrefix = 'lang-';
}

/// What a skill id says about itself: `ENG-B-19.G1` is the group `G1` of the skill `ENG-B-19` (docs/languages/frame.md
/// section 3.3.2), taught in the band `B`.
abstract final class SkillIds {
  /// The skill a dotted id belongs to (`HEB-B-14.S1` gives `HEB-B-14`), or null for a plain id.
  static String? parentOf(String skillId) {
    final int dot = skillId.indexOf('.');
    return dot < 0 ? null : skillId.substring(0, dot);
  }

  static bool isSub(String skillId) => skillId.contains('.');

  static final RegExp _band = RegExp(r'^[A-Z]+-([ABC])-\d{2}(?:\.[A-Z]\d{1,2})?$');

  /// 0, 1 or 2 for the band letter A, B or C in the id (where the skill is usually first taught), or -1 for an id of
  /// another shape. This is the content level of a skill; the presentation band comes from the child's age.
  static int levelOf(String skillId) {
    final RegExpMatch? m = _band.firstMatch(skillId);
    return m == null ? -1 : m.group(1)!.codeUnitAt(0) - 0x41;
  }
}
