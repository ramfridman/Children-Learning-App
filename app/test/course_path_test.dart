// The course home's facts (L-course): the path of a course's lessons with where the child stands on it, what is next, and the placement
// that decides where the path opens. Pure functions over the fixture packs; no database, no widget.
import 'package:flutter_test/flutter_test.dart';
import 'package:nitznutz/app/language_providers.dart' show languageCourseOf;
import 'package:nitznutz/content/models.dart';
import 'package:nitznutz/data/app_database.dart';
import 'package:nitznutz/engine/engine.dart';
import 'package:nitznutz/engine/staircase.dart' show PlacementGame;
import 'package:nitznutz/parent/language_settings.dart';
import 'package:nitznutz/rewards/award.dart';
import 'package:nitznutz/world/adventure_adapter.dart';
import 'package:nitznutz/world/adventure_land.dart';
import 'package:nitznutz/world/course_path.dart';
import 'package:nitznutz/world/language_placement.dart';
import 'package:nitznutz/world/placement.dart' show placementIdFor;
import 'package:nitznutz/world/todays_adventure.dart';

import 'support/course_history.dart';
import 'support/course_packs.dart';
import 'support/sample_pack.dart';

final DateTime _now = DateTime.utc(2026, 11, 4, 9);
final DateTime _earlier = DateTime.utc(2026, 11, 3, 9);

CourseHomeModel _home(
  LanguageCourse course, {
  List<Attempt> attempts = const <Attempt>[],
  List<Session> sessions = const <Session>[],
  List<String> awards = const <String>[],
}) => buildCourseHome(
  course: course,
  attempts: attempts,
  sessions: sessions,
  rewardKeys: awards,
  now: _now,
  band: 0,
);

LanguageCourse _course(
  String course, {
  List<Attempt> attempts = const <Attempt>[],
  LanguageSwitches switches = const LanguageSwitches(on: true),
  int ageBand = 0,
}) => languageCourseOf(courseContent(course), attempts, switches, ageBand);

/// Placement answers `(item, right)` written as the rows the visit writes, one a minute apart.
List<Attempt> _placed(PackContent pack, List<(String, bool)> answers) => <Attempt>[
  for (final (int i, (String, bool) a) in answers.indexed)
    attemptRow(
      pack,
      a.$1,
      result: a.$2 ? 'correct' : 'incorrect',
      lessonId: placementIdFor(pack.course),
      at: _earlier.add(Duration(minutes: i)),
      id: i + 1,
    ),
];

/// A child who answers every probe of the English oral strand right: each level's two probes, up the whole ladder.
const List<(String, bool)> _allRight = <(String, bool)>[
  ('pr_hello_1', true),
  ('pr_hello_2', true),
  ('pr_col_1', true),
  ('pr_col_2', true),
  ('pr_ani_1', true),
  ('pr_ani_2', true),
  ('pr_body_1', true),
  ('pr_body_2', true),
];

void main() {
  group('a child who has not played the course', () {
    test('every stone is further on, the first is next, and the host invites to the visit', () {
      final CourseHomeModel m = _home(_course('eng'));
      expect(m.stones, hasLength(7));
      expect(m.stones.every((PathStone s) => s.state == StoneState.later), isTrue);
      expect(<int>[for (final PathStone s in m.stones) s.number], <int>[1, 2, 3, 4, 5, 6, 7]);
      expect(m.nextIndex, 0);
      expect(m.placementDue, isTrue, reason: 'the first activity of a course is its placement game');
      expect(m.canPlay, isTrue);
      expect(m.pebbleLesson, isNull, reason: 'the pebble starts the visit, not a lesson');
      expect(m.stop.kind, AdventureKind.lesson);
      expect(m.stop.lessonId, 'eng.hello_1');
    });

    test(
      'a course whose pack has no placement game has no invitation: the pebble opens the first lesson',
      () {
        final LanguageCourse c = languageCourseOf(
          PackContent.fromPack(SamplePack.language('eng').verified()),
          const <Attempt>[],
          const LanguageSwitches(on: true),
          1,
        );
        final CourseHomeModel m = _home(c);
        expect(c.placement, isNull);
        expect(m.placementDue, isFalse);
        expect(m.pebbleLesson?.lessonId, 'eng.butterflies');
      },
    );

    test('the path is the course\'s own lessons, in order, with their titles from the pack', () {
      final CourseHomeModel m = _home(_course('heb'));
      expect(m.stones.map((PathStone s) => s.lessonId), <String>[
        'heb.words_1',
        'heb.words_2',
        'heb.rhymes_1',
        'heb.rhymes_2',
        'heb.letters_1',
      ]);
      expect(m.stones.first.title, 'מִלִּים');
      expect(m.course, 'heb');
    });
  });

  group('what the child has finished', () {
    test('a finished lesson is done, and the next stone is the one after it', () {
      final PackContent pack = courseContent('eng');
      final CourseHomeModel m = _home(
        _course('eng'),
        awards: <String>[Awards.sticker('eng.hello_1', 1)],
        sessions: <Session>[sessionRow(1, 'lesson:eng.hello_1', at: _earlier)],
        attempts: <Attempt>[
          attemptRow(pack, 'hi_mika_arrive', at: _earlier, lessonId: 'eng.hello_1', sessionId: 1),
        ],
      );
      expect(m.stones.first.state, StoneState.done);
      expect(m.stones[1].state, StoneState.later);
      expect(m.nextIndex, 1);
      expect(m.stop.lessonId, 'eng.hello_2');
      expect(m.pebbleLesson, isNull, reason: 'the placement has not been played yet');
    });

    test('with every lesson finished the path goes round: the one finished fewest times is next', () {
      final CourseHomeModel m = _home(
        languageCourseOf(
          PackContent.fromPack(SamplePack.language('eng').verified()),
          const <Attempt>[],
          const LanguageSwitches(on: true),
          1,
        ),
        awards: <String>[Awards.sticker('eng.butterflies', 1), Awards.sticker('eng.butterflies', 2)],
        sessions: <Session>[sessionRow(1, 'lesson:eng.butterflies', at: _earlier)],
      );
      expect(m.stones.single.state, StoneState.done);
      expect(m.nextIndex, 0);
      expect(m.canPlay, isTrue);
    });

    test('another course\'s answers and lessons never move this path', () {
      final PackContent rus = courseContent('rus');
      final CourseHomeModel m = _home(
        _course('eng'),
        awards: <String>[Awards.sticker('rus.animals_1', 1)],
        sessions: <Session>[sessionRow(1, 'lesson:rus.animals_1', at: _earlier)],
        attempts: <Attempt>[attemptRow(rus, 'a_cat', at: _earlier, lessonId: 'rus.animals_1', sessionId: 1)],
      );
      expect(m.stones.every((PathStone s) => s.state == StoneState.later), isTrue);
      expect(m.nextIndex, 0);
    });
  });

  group('the placement and where the path opens', () {
    test('a child who answers the whole ladder right is placed two levels up: the lessons below are placed, the next one is the first that is not', () {
      final PackContent pack = courseContent('eng');
      final LanguageCourse c = _course('eng', attempts: _placed(pack, _allRight));
      expect(c.placement!.complete, isTrue);
      expect(
        c.placement!.entryOf('o'),
        2,
        reason: 'the highest level with two thirds right is 3, minus one unit',
      );
      expect(c.assumed, containsAll(<String>['ENG-A-01', 'ENG-A-03']));
      expect(c.assumed, isNot(contains('ENG-A-05')));
      final CourseHomeModel m = _home(c);
      expect(m.stones.map((PathStone s) => s.state), <StoneState>[
        StoneState.placed,
        StoneState.placed,
        StoneState.placed,
        StoneState.placed,
        StoneState.later,
        StoneState.later,
        StoneState.later,
      ]);
      expect(m.nextIndex, 4);
      expect(m.placementDue, isFalse, reason: 'the visits are over');
      expect(m.pebbleLesson?.lessonId, 'eng.animals_1');
    });

    test('a child who misses the first two probes starts at the beginning, and is not asked again', () {
      final PackContent pack = courseContent('eng');
      final LanguageCourse c = _course(
        'eng',
        attempts: _placed(pack, <(String, bool)>[('pr_hello_1', false), ('pr_hello_2', false)]),
      );
      expect(c.placement!.complete, isTrue, reason: 'a beginner does not get eight failures');
      expect(c.assumed, isEmpty);
      final CourseHomeModel m = _home(c);
      expect(m.stones.every((PathStone s) => s.state == StoneState.later), isTrue);
      expect(m.nextIndex, 0);
      expect(m.placementDue, isFalse);
    });

    test('a visit that is not yet the whole placement leaves the host inviting', () {
      final PackContent pack = courseContent('eng');
      final LanguageCourse c = _course(
        'eng',
        attempts: _placed(pack, <(String, bool)>[('pr_hello_1', true)]),
      );
      expect(c.placement!.begun, isTrue);
      expect(c.placement!.complete, isFalse);
      expect(c.assumed, isEmpty, reason: 'a strand that has not stopped places nobody anywhere');
      expect(_home(c).placementDue, isTrue);
    });

    test(
      'the parent\'s questionnaire sets where the staircase starts, and the staircase may still end lower',
      () {
        final PackContent pack = courseContent('eng');
        const LanguageSwitches some = LanguageSwitches(
          on: true,
          questionnaire: <String, String>{'knowsLetters': 'some'},
        );
        final PlacementGame start = placementGameFor(pack, const <Attempt>[], answers: some.questionnaire)!;
        expect(start.stairs('o')!.level, 1);
        expect(start.next(), 'eng.pr_col_1', reason: 'the first probe comes from the level the answer chose');
        // It starts there and may still end lower: two misses at level 1 go down, then two at the floor stop it.
        final LanguageCourse c = _course(
          'eng',
          switches: some,
          attempts: _placed(pack, <(String, bool)>[
            ('pr_col_1', false),
            ('pr_hello_1', false),
            ('pr_hello_2', false),
          ]),
        );
        expect(c.placement!.entryOf('o'), 0);
        expect(_home(c).stones.first.state, StoneState.later);
      },
    );

    test('a lesson the child played is done even when the placement would also have passed it', () {
      final PackContent pack = courseContent('eng');
      final CourseHomeModel m = _home(
        _course('eng', attempts: _placed(pack, _allRight)),
        awards: <String>[Awards.sticker('eng.hello_1', 1)],
      );
      expect(m.stones[0].state, StoneState.done);
      expect(m.stones[1].state, StoneState.placed);
    });

    test('Hebrew places its two strands separately, and a strand that has not stopped places nobody', () {
      final PackContent pack = courseContent('heb');
      // strand l: two right at the floor, two right at level 1, so the ladder tops out; strand c is not played yet
      final LanguageCourse c = _course(
        'heb',
        attempts: _placed(pack, <(String, bool)>[
          ('pr_w_1', true),
          ('pr_w_2', true),
          ('pr_r_1', true),
          ('pr_r_2', true),
        ]),
      );
      expect(c.placement!.entryOf('l'), 0);
      expect(c.placement!.entryOf('c'), isNull);
      expect(c.placement!.complete, isFalse);
      expect(c.assumed, isEmpty);
    });
  });

  group('what is next is the rule of Today\'s Adventure on this course alone', () {
    test('a check that fell due comes first, as the bell of a land does', () {
      final LanguageCourse base = _course('eng');
      final LanguageCourse c = LanguageCourse(
        content: base.content,
        engine: _DueEngine(base.engine),
        placement: base.placement,
      );
      final CourseHomeModel m = _home(c);
      expect(m.stop.kind, AdventureKind.revisit);
      expect(m.stop.skillId, 'ENG-A-01');
      expect(m.stop.land, LanguageLand('eng'));
    });

    test('a check that was taken today is not offered again', () {
      final LanguageCourse base = _course('eng');
      final LanguageCourse c = LanguageCourse(
        content: base.content,
        engine: _DueEngine(base.engine, reviewedToday: true),
        placement: base.placement,
      );
      expect(_home(c).stop.kind, AdventureKind.lesson);
    });

    test(
      'the visits of the course are read: the first visit is a welcome, the next goes on in the same land',
      () {
        final PackContent pack = courseContent('eng');
        final LanguageCourse c = _course('eng');
        expect(_home(c).stop.reason, AdventureReason.welcome);
        final CourseHomeModel after = _home(
          c,
          sessions: <Session>[sessionRow(1, 'lesson:eng.hello_1', at: _now)],
          awards: <String>[Awards.sticker('eng.hello_1', 1)],
          attempts: <Attempt>[
            attemptRow(pack, 'hi_mika_arrive', at: _now, lessonId: 'eng.hello_1', sessionId: 1),
          ],
        );
        expect(after.stop.reason, AdventureReason.sameLand);
        expect(after.stop.lessonId, 'eng.hello_2');
      },
    );

    test('a lesson left after a wrong answer is offered again from the start when it is the only one left: an empty pebble would be worse', () {
      final PackContent butterflies = PackContent.fromPack(SamplePack.language('eng').verified());
      final LanguageCourse c = languageCourseOf(
        butterflies,
        const <Attempt>[],
        const LanguageSwitches(on: true),
        1,
      );
      final CourseHomeModel m = _home(
        c,
        sessions: <Session>[sessionRow(1, 'lesson:eng.butterflies', at: _now, reason: 'home')],
        attempts: <Attempt>[
          attemptRow(
            butterflies,
            'pick.red.flower',
            result: 'incorrect',
            at: _now,
            lessonId: 'eng.butterflies',
            sessionId: 1,
          ),
        ],
      );
      expect(m.canPlay, isTrue);
      expect(m.stop.lessonId, 'eng.butterflies');
    });
  });
}

/// An engine that says one check is due.
class _DueEngine extends Engine {
  _DueEngine(Engine from, {this.reviewedToday = false}) : super(catalog: from.catalog) {
    if (reviewedToday) {
      skill('ENG-A-01').lastReviewDay = Engine.dayKey(DateTime.utc(2026, 11, 4, 9));
    }
  }

  final bool reviewedToday;

  @override
  List<String> dueChecks(DateTime now) => <String>['ENG-A-01'];

  @override
  DateTime? nextCheckAt(String skillId) => DateTime.utc(2026, 11, 3);
}
