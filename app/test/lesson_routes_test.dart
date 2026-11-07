// Teach screens, hearing screens and routes (docs/languages/band-a-build.md sections 2.6 and 2.6.1): a lesson of a language course may name
// screens that come before its items (`lesson.teach`, each set with the routes that are shown it and its mode), and what a child plays is
// chosen by the route the child is served on. The rules that matter most: a heritage speaker, who knows the words, is never shown a teach
// screen (it may hear a word once, before the lesson asks it); a route never removes, adds or reorders the items of a lesson (R5); a
// screen is shown, not asked: it is never scored, writes nothing, has no microphone, and the engine does not see it.
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:nitznutz/content/engine_adapter.dart';
import 'package:nitznutz/content/models.dart';
import 'package:nitznutz/content/pack_verify.dart';
import 'package:nitznutz/content/schema.dart' show Problem;
import 'package:nitznutz/content/served_route.dart';
import 'package:nitznutz/engine/types.dart';
import 'package:nitznutz/play/lesson_controller.dart';

import '../tool/pack_builder_lib.dart';
import 'support/pack_fixtures.dart';
import 'support/temp_dir.dart';

const String _languages = '../content/languages';

void main() {
  late PackContent rus;
  late Uint8List rusBytes;
  late PackKey rusKey;

  setUpAll(() async {
    rusKey = await newTestKey();
    rusBytes = (await buildPack(languageSource('rus', _languages), rusKey)).bytes;
    rus = PackContent.fromPack(await verifyPack(rusBytes, publicKey: rusKey.publicKey));
  });

  Iterable<Lesson> withTeach() => rus.lessons.values.where((Lesson l) => l.teach.isNotEmpty);
  List<String> ids(Iterable<Activity> items) => <String>[for (final Activity a in items) a.id];
  Set<String> screenIds(Lesson l, {required bool hear}) => <String>{
    for (final TeachSet s in l.teach)
      if (s.hear == hear) ...s.itemIds,
  };

  group('what a route plays', () {
    test('a new learner is shown the teach screens first, then the lesson', () {
      final Lesson l = rus.lessons['rus.family-1']!;
      final List<Activity> items = rus.itemsFor(l, route: 'new');
      final int teach = l.teach.fold(0, (int n, TeachSet s) => n + s.itemIds.length);
      expect(teach, 4);
      expect(items.length, teach + l.itemIds.length);
      expect(items.take(teach).every((Activity a) => a is SayItActivity && a.teach), isTrue);
      expect(ids(items.skip(teach)), l.itemIds);
    });

    test('a child whose route is not set is a new learner, and so is a reader nobody has resolved', () {
      final Lesson l = rus.lessons['rus.family-1']!;
      expect(rus.itemsFor(l).length, rus.itemsFor(l, route: 'new').length);
      expect(ids(rus.itemsFor(l, route: 'reader')), ids(rus.itemsFor(l, route: 'new')));
    });

    test('a heritage speaker is never shown a teach screen: in no lesson of the pack', () {
      expect(withTeach(), isNotEmpty, reason: 'the Russian pack has teach screens');
      for (final Lesson l in rus.lessons.values) {
        for (final Activity a in rus.itemsFor(l, route: 'heritage').where((Activity a) => a.teachScreen)) {
          expect(
            (a as SayItActivity).hear,
            isTrue,
            reason: '${l.id}: ${a.id} is a teach screen, not a hearing screen',
          );
        }
      }
    });

    test('a heritage speaker hears the words of A-20 once, before the lesson that asks them: 4 before pairs-1, 2 before pairs-2', () {
      for (final MapEntry<String, int> e in <String, int>{'rus.pairs-1': 4, 'rus.pairs-2': 2}.entries) {
        final Lesson l = rus.lessons[e.key]!;
        final List<Activity> items = rus.itemsFor(l, route: 'heritage');
        expect(
          items.take(e.value).every((Activity a) => a is SayItActivity && a.hear),
          isTrue,
          reason: e.key,
        );
        expect(ids(items.skip(e.value)), l.itemIds, reason: e.key);
      }
      final Set<String> heard = <String>{
        for (final Lesson l in rus.lessons.values)
          ...rus
              .itemsFor(l, route: 'heritage')
              .where((Activity a) => a.teachScreen)
              .map((Activity a) => a.id),
      };
      expect(heard, <String>{
        for (final int n in <int>[1, 2, 3, 4, 5, 6]) 'rus.a20.th0$n',
      });
    });

    test('each hearing screen is before the first lesson that asks its word', () {
      for (final Lesson l in rus.lessons.values) {
        final Set<String> asked = <String>{
          for (final Activity a in rus.itemsOf(l)) a.promptLine.target ?? '',
        };
        for (final String id in screenIds(l, hear: true)) {
          expect(asked, contains((rus.activities[id]! as SayItActivity).wordClip), reason: '${l.id} $id');
        }
      }
      String short(String id) => id.split('.').last;
      expect(screenIds(rus.lessons['rus.pairs-1']!, hear: true).map(short), <String>{
        'th01',
        'th02',
        'th03',
        'th04',
      });
      expect(screenIds(rus.lessons['rus.pairs-2']!, hear: true).map(short), <String>{'th05', 'th06'});
    });

    test('a new learner is never given a hearing screen, and the sets name one route each', () {
      for (final Lesson l in rus.lessons.values) {
        expect(
          rus.itemsFor(l, route: 'new').any((Activity a) => a is SayItActivity && a.hear),
          isFalse,
          reason: l.id,
        );
        for (final TeachSet s in l.teach) {
          expect(s.routes, s.hear ? <String>{'heritage'} : <String>{'new'}, reason: l.id);
        }
      }
    });

    test('R6.1 and R5: for every lesson and each served route, the screens of the route and then the lesson\'s items, the same for both', () {
      for (final Lesson l in rus.lessons.values) {
        final List<String> items = ids(rus.itemsOf(l));
        expect(items, isNotEmpty, reason: l.id);
        expect(
          items,
          l.itemIds,
          reason: '${l.id}: the items of a lesson are the lesson\'s own, in its order',
        );
        for (final String route in <String>['new', 'heritage']) {
          final List<Activity> played = rus.itemsFor(l, route: route);
          final List<String> screens = <String>[
            for (final TeachSet s in l.teach)
              if (s.routes.contains(route)) ...s.itemIds,
          ];
          expect(ids(played), <String>[...screens, ...items], reason: '${l.id} $route');
          expect(ids(played.where((Activity a) => !a.teachScreen)), items, reason: '${l.id} $route');
        }
      }
    });

    test('a pack that was never validated cannot show a teach screen to a heritage speaker, or a hearing screen to a new learner', () async {
      final VerifiedPack pack = await verifyPack(rusBytes, publicKey: rusKey.publicKey);
      final Map<String, Object?> lesson = pack.docs['lesson.rus.family-1.json']! as Map<String, Object?>;
      final Map<String, Object?> teach = (lesson['teach']! as List<Object?>).first! as Map<String, Object?>;
      teach['routes'] = <String>['new', 'heritage'];
      final PackContent odd = PackContent.fromPack(pack);
      final Lesson l = odd.lessons['rus.family-1']!;
      expect(odd.itemsFor(l, route: 'heritage').length, l.itemIds.length, reason: 'no teach screen');
      expect(odd.itemsFor(l, route: 'new').length, l.itemIds.length + 4);
      teach['mode'] = 'hear'; // the same set, now said to be a hearing set: the filter is by the set
      final PackContent heard = PackContent.fromPack(pack);
      final Lesson hear = heard.lessons['rus.family-1']!;
      expect(
        heard.itemsFor(hear, route: 'new').length,
        l.itemIds.length,
        reason: 'a hearing set is never for a new learner',
      );
      expect(heard.itemsFor(hear, route: 'heritage').length, l.itemIds.length + 4);
    });

    test('a lesson with no teach set plays as it is, whatever the route', () {
      final Lesson l = rus.lessons.values.firstWhere((Lesson x) => x.teach.isEmpty);
      for (final String? route in <String?>[null, 'new', 'heritage', 'reader']) {
        expect(ids(rus.itemsFor(l, route: route)), l.itemIds);
      }
    });
  });

  group('how a reader is served (R1)', () {
    late PlacementDoc placement;
    late Set<String> firstLevel;

    setUpAll(() {
      placement = rus.placement!;
      firstLevel = <String>{
        ...placement.strands.firstWhere((PlacementStrandDoc s) => s.id == '1').levels.first.assumes,
      };
    });

    test('the first level of strand 1 is the five skills of the oral beginnings', () {
      expect(firstLevel, <String>{'RUS-A-01', 'RUS-A-02', 'RUS-A-05', 'RUS-A-07', 'RUS-A-08'});
    });

    test('R6.3: a reader with strand 1 not stopped, stopped at its first level, or past it, in an oral skill and a heritage skill', () {
      final SkillDoc oral = rus.skills['RUS-A-03']!;
      final SkillDoc heritage = rus.skills['RUS-A-17']!;
      expect(oral.readerAs, 'oral');
      expect(heritage.readerAs, 'heritage');
      String served(SkillDoc skill, Set<String> assumed) =>
          servedRoute(route: 'reader', skill: skill, assumed: assumed, placement: placement);
      final Set<String> nearly = <String>{...firstLevel}..remove('RUS-A-08');
      // not stopped, or stopped at the first level (nothing assumed), or only some of the level: the oral skill serves a new learner
      for (final Set<String> assumed in <Set<String>>[
        <String>{},
        <String>{'RUS-A-17'},
        nearly,
      ]) {
        expect(served(oral, assumed), 'new', reason: '$assumed');
        expect(served(heritage, assumed), 'heritage', reason: '$assumed: A-17 says heritage');
      }
      // past the first level: both are heritage
      expect(served(oral, firstLevel), 'heritage');
      expect(served(heritage, firstLevel), 'heritage');
      expect(served(oral, <String>{...firstLevel, 'RUS-A-03', 'RUS-A-06'}), 'heritage');
    });

    test('the other routes, no placement and no skill', () {
      final SkillDoc oral = rus.skills['RUS-A-03']!;
      expect(servedRoute(route: 'heritage', skill: oral, placement: placement), 'heritage');
      expect(
        servedRoute(route: 'new', skill: rus.skills['RUS-A-17'], assumed: firstLevel, placement: placement),
        'new',
      );
      expect(servedRoute(route: null, skill: oral, assumed: firstLevel, placement: placement), 'new');
      expect(
        servedRoute(route: 'reader', skill: oral, assumed: firstLevel),
        'new',
        reason: 'a pack with no placement',
      );
      expect(
        servedRoute(route: 'reader', assumed: firstLevel, placement: placement),
        'heritage',
        reason: 'no skill: the placement decides',
      );
      expect(servedRoute(route: 'reader', skill: rus.skills['RUS-A-17']), 'heritage');
    });

    test('A-01 to A-15 are oral and A-16 to A-20 heritage for a reader', () {
      for (final SkillDoc s in rus.skills.values) {
        final int n = int.parse(s.id.split('-').last);
        expect(s.readerAs, n <= 15 ? 'oral' : 'heritage', reason: s.id);
      }
    });
  });

  group('the teach and hearing screens of the Russian pack', () {
    test(
      'each is a say step flagged as a screen, in a skill of its lesson, and is not an item of any lesson',
      () {
        final Set<String> items = <String>{for (final Lesson l in rus.lessons.values) ...l.itemIds};
        int teach = 0;
        int hear = 0;
        for (final Lesson l in withTeach()) {
          for (final TeachSet s in l.teach) {
            for (final String id in s.itemIds) {
              final Activity a = rus.activities[id]!;
              expect(a, isA<SayItActivity>(), reason: id);
              final SayItActivity say = a as SayItActivity;
              expect(say.teach, isTrue, reason: id);
              expect(
                say.hear,
                s.hear,
                reason: '$id: a hear set holds hearing screens, a teach set teach screens',
              );
              expect(say.unscored, isTrue, reason: id);
              expect(say.scored, isFalse, reason: id);
              expect(say.order, isEmpty, reason: '$id: a screen is always echo');
              expect(say.pictureFirstLine, isNull, reason: id);
              expect(a.skills.map((Skill s) => s.id), l.skillIds.take(1), reason: id);
              expect(items.contains(id), isFalse, reason: id);
              s.hear ? hear++ : teach++;
            }
          }
        }
        expect(teach, 117, reason: 'every word of every teach list of the teachers');
        expect(hear, 6, reason: 'the six words of A-20');
      },
    );

    test('a hearing screen says its line and the word, and shows no word on the screen', () {
      final SayItActivity th = rus.activities['rus.a20.th02']! as SayItActivity;
      expect(th.promptLine.vo, 'vo:rus.f41');
      expect(th.promptLine.caption, 'הַקְשִׁיבוּ:');
      expect(th.promptLine.target, th.wordClip);
      expect(th.promptLine.show, isNull);
    });

    test('the engine does not see them: no item of its catalogue, no representation counted for a skill', () {
      final Catalog catalog = engineCatalog(rus);
      final Set<String> ids = catalog.items.keys.toSet();
      for (final Activity a in rus.activities.values) {
        // A teach screen is never an item; neither is a step that writes no answer (a chant, a personal turn) nor a say step of a skill that
        // is not a speaking one (their words could never be covered by an answer); every other step is.
        final bool noAnswer =
            a.teachScreen || a.unscored || (a is SayItActivity && rus.skills[a.skillId]?.strand != 'spk');
        expect(ids.contains(a.id), !noAnswer, reason: a.id);
      }
      expect(rus.activities.values.where((Activity a) => a.teachScreen), isNotEmpty);
    });

    test('a teach set is put before the lesson that asks its words', () {
      // The animals come in six sets, the lessons ask them in order: the first set before animals-1, the second before animals-2 ...
      final Map<String, List<String>> before = <String, List<String>>{
        for (final Lesson l in rus.lessons.values.where((Lesson x) => x.id.startsWith('rus.animals-')))
          l.id: <String>[for (final TeachSet s in l.teach) ...s.itemIds],
      };
      // The Russian teacher's sets of the QA batch: 5, 4, 3, 4, 4 and 2 words (the giraffe and the whale are in the last two lessons).
      expect(before['rus.animals-1'], hasLength(5));
      expect(before['rus.animals-2'], hasLength(4));
      expect(before['rus.animals-5'], hasLength(4));
      expect(before['rus.animals-6'], hasLength(2), reason: 'the last set stands before the last lesson');
      expect(
        <int>[for (final String id in before.keys.toList()..sort()) before[id]!.length]
            .fold(0, (int a, int b) => a + b),
        22,
      );
      expect(before['rus.animals-1']!.first, 'rus.a05.tc01');
    });
  });

  group('the order of a say step (R4)', () {
    Iterable<SayItActivity> says() =>
        rus.activities.values.whereType<SayItActivity>().where((SayItActivity a) => !a.teach);

    test(
      'there are 28 of them, and each has an order for both routes and a picture-first line with no clip',
      () {
        expect(says().length, 28);
        for (final SayItActivity a in says()) {
          expect(a.order.keys.toSet(), <String>{'new', 'heritage'}, reason: a.id);
          expect(a.pictureFirstLine, isNotNull, reason: a.id);
          expect(a.pictureFirstLine!.target, isNull, reason: '${a.id}: asking for the word must not give it');
          expect(a.pictureFirstLine!.target2, isNull, reason: a.id);
        }
      },
    );

    test('no echo prompt is "what is this? try to say it" (f06): it is "let\'s say it together" (f03) and the word', () {
      for (final SayItActivity a in says()) {
        expect(a.promptLine.vo, 'vo:rus.f03', reason: a.id);
        expect(a.promptLine.target, a.wordClip, reason: a.id);
        expect(a.pictureFirstLine!.vo, anyOf('vo:rus.f06', 'vo:rus.f07'), reason: a.id);
      }
    });

    test('A-15 is picture first for both routes; A-01 and A-14 are echo for a new learner and picture first for a heritage speaker', () {
      for (final SayItActivity a in says()) {
        expect(a.order['heritage'], 'picture', reason: a.id);
        expect(a.order['new'], a.skillId == 'RUS-A-15' ? 'picture' : 'echo', reason: a.id);
        expect(<String>['RUS-A-01', 'RUS-A-14', 'RUS-A-15'], contains(a.skillId), reason: a.id);
      }
    });

    test(
      'the say step of a puppet\'s bubble asks "what do we answer?" (f07), the others "what is this?" (f06)',
      () {
        const Set<String> afterBubble = <String>{'rus.a01.04s', 'rus.a01.05s', 'rus.a14.10s', 'rus.a14.11s'};
        for (final SayItActivity a in says()) {
          expect(
            a.pictureFirstLine!.vo,
            afterBubble.contains(a.id) ? 'vo:rus.f07' : 'vo:rus.f06',
            reason: a.id,
          );
        }
        expect(says().where((SayItActivity a) => afterBubble.contains(a.id)).length, 4);
      },
    );

    test('picturesFirst: by route, and the quiet fallback turns it back into echo; a teach screen is always echo', () {
      final SayItActivity a01 = rus.activities['rus.a01.04s']! as SayItActivity;
      final SayItActivity a15 = rus.activities['rus.a15.01']! as SayItActivity;
      expect(
        <bool>[a01.picturesFirst('new'), a01.picturesFirst(null), a01.picturesFirst('heritage')],
        <bool>[false, false, true],
      );
      expect(<bool>[a15.picturesFirst('new'), a15.picturesFirst('heritage')], <bool>[true, true]);
      expect(
        <bool>[a01.picturesFirst('heritage', echoOnly: true), a15.picturesFirst('new', echoOnly: true)],
        <bool>[false, false],
      );
      expect((rus.activities['rus.a02.tc01']! as SayItActivity).picturesFirst('heritage'), isFalse);
    });
  });

  group('the lesson controller', () {
    LessonController open(String lessonId, String? route, List<AttemptRecord> written) => LessonController(
      content: rus,
      lesson: rus.lessons[lessonId]!,
      profileId: 'kid',
      record: (AttemptRecord r) async => written.add(r),
      route: route,
    );

    test('a new learner starts on a teach screen, a heritage speaker on the first item', () {
      final LessonController fresh = open('rus.family-1', 'new', <AttemptRecord>[]);
      expect(fresh.current, isA<SayItActivity>());
      expect(fresh.items.length, 4 + 4);
      expect(fresh.trailLength, 8);
      final LessonController heritage = open('rus.family-1', 'heritage', <AttemptRecord>[]);
      expect(heritage.current, isA<TapAnswerActivity>());
      expect(heritage.items.length, 4);
      fresh.dispose();
      heritage.dispose();
    });

    test('a teach screen writes no attempt and offers no help', () async {
      final List<AttemptRecord> written = <AttemptRecord>[];
      final LessonController c = open('rus.family-1', 'new', written);
      expect(c.noHelp, isTrue, reason: 'nothing can be got wrong, so there is no lamp and no show me');
      await c.sayItDone();
      c.next();
      expect(written, isEmpty);
      expect(c.index, 1);
      c.dispose();
    });

    test('a heritage speaker opens pairs-1 on a hearing screen: no help, no praise, nothing written, then the next', () {
      final List<AttemptRecord> written = <AttemptRecord>[];
      final LessonController c = open('rus.pairs-1', 'heritage', written);
      expect(c.items.length, 4 + 4);
      final SayItActivity hear = c.current as SayItActivity;
      expect(hear.hear, isTrue);
      expect(c.voice, 'vo:rus.f41');
      expect(c.voiceTarget, hear.wordClip);
      expect(c.pictureFirst, isFalse);
      expect(c.noHelp, isTrue);
      final int said = c.voiceNonce;
      c.hearDone();
      expect(
        c.voiceNonce,
        said,
        reason: 'nothing more is said: the word was heard, and again if the child asked',
      );
      expect(c.solved, isTrue);
      c.next();
      expect(written, isEmpty);
      expect((c.current as SayItActivity).hear, isTrue, reason: 'the second of the four');
      c.dispose();
    });

    LessonController openSay(
      String activity, {
      String? route,
      String? Function(String)? routeOfSkill,
      bool Function()? echoOnly,
    }) => LessonController(
      content: rus,
      lesson: Lesson.mission(
        id: 'say',
        itemIds: <String>[activity],
        skillIds: <String>[rus.activities[activity]!.skillId],
        celebration: rus.lessons['rus.family-1']!.celebration,
      ),
      profileId: 'kid',
      record: (AttemptRecord r) async {},
      route: route,
      routeOfSkill: routeOfSkill,
      echoOnly: echoOnly,
    );

    test('R4: a heritage speaker\'s say step asks first (f07 after a bubble) with no clip; a new learner\'s is echo (f03 and the word)', () {
      final LessonController heritage = openSay('rus.a01.04s', route: 'heritage');
      expect(heritage.pictureFirst, isTrue);
      expect(
        <Object?>[heritage.voice, heritage.voiceTarget, heritage.voiceTarget2, heritage.bubbleShow],
        <Object?>['vo:rus.f07', null, null, null],
      );
      final LessonController fresh = openSay('rus.a01.04s', route: 'new');
      expect(fresh.pictureFirst, isFalse);
      expect(<Object?>[fresh.voice, fresh.voiceTarget], <Object?>['vo:rus.f03', 'vo:rus.w_privet']);
      expect(fresh.bubbleShow, isNull, reason: 'no chip: a Band A step prints no word (band-a-build.md 7.2)');
      final LessonController unset = openSay('rus.a01.04s');
      expect(unset.pictureFirst, isFalse, reason: 'a route that is not set is a new learner');
      for (final LessonController c in <LessonController>[heritage, fresh, unset]) {
        c.dispose();
      }
    });

    test('R4: A-15 is picture first for a new learner too, and no word shows when the voice has said it (no chip in Band A)', () {
      final LessonController c = openSay('rus.a15.01', route: 'new');
      expect(c.pictureFirst, isTrue);
      expect(<Object?>[c.voice, c.voiceTarget, c.bubbleShow], <Object?>['vo:rus.f06', null, null]);
      int told = 0;
      c.addListener(() => told++);
      final int said = c.voiceNonce;
      c.showWord();
      expect(c.bubbleShow, isNull, reason: 'the step has no chip to show');
      expect(c.voiceNonce, said, reason: 'showing the chip says nothing');
      expect(told, 0);
      c.showWord();
      expect(told, 0);
      c.dispose();
    });

    test('R4: the quiet fallback turns picture first back into echo, silently, and the replay asks the question again', () {
      bool quiet = false;
      final LessonController c = openSay('rus.a01.04s', route: 'heritage', echoOnly: () => quiet);
      expect(c.pictureFirst, isTrue);
      c.replayPrompt();
      expect(c.voice, 'vo:rus.f07');
      c.dispose();
      quiet = true;
      final LessonController echo = openSay('rus.a01.04s', route: 'heritage', echoOnly: () => quiet);
      expect(echo.pictureFirst, isFalse);
      expect(<Object?>[echo.voice, echo.voiceTarget], <Object?>['vo:rus.f03', 'vo:rus.w_privet']);
      echo.dispose();
    });

    test('R1: the say step is played by the route of its own skill', () {
      final LessonController c = openSay(
        'rus.a01.04s',
        route: 'new',
        routeOfSkill: (String skill) => skill == 'RUS-A-01' ? 'heritage' : 'new',
      );
      expect(c.pictureFirst, isTrue);
      c.dispose();
    });
  });

  group('a broken copy of the Russian source is refused', () {
    late Directory dir;
    late PackKey key;

    setUpAll(() async => key = await newTestKey());
    setUp(() {
      final Directory from = languageSource('rus', _languages);
      dir = Directory.systemTemp.createTempSync('nn_routes_');
      for (final FileSystemEntity e in from.listSync()) {
        if (e is File) e.copySync('${dir.path}${Platform.pathSeparator}${e.uri.pathSegments.last}');
      }
    });
    tearDown(() => removeTempDir(dir));

    void change(String file, void Function(Map<String, Object?> doc) edit) {
      final File f = File('${dir.path}${Platform.pathSeparator}$file');
      final Map<String, Object?> doc = jsonDecode(f.readAsStringSync()) as Map<String, Object?>;
      edit(doc);
      f.writeAsStringSync('${const JsonEncoder.withIndent('  ').convert(doc)}\n');
    }

    Map<String, Object?> firstSet(Map<String, Object?> lesson) =>
        (lesson['teach']! as List<Object?>).first! as Map<String, Object?>;

    Future<String> refused() async {
      try {
        await buildPack(dir, key);
      } on BuildFailed catch (e) {
        return e.problems.map((Problem p) => '$p').join('\n');
      }
      fail('the broken source was signed');
    }

    test('a teach set may not name the heritage route, and a hearing set may name only it', () async {
      change('lesson.rus.family-1.json', (Map<String, Object?> l) {
        firstSet(l)['routes'] = <String>['new', 'heritage'];
      });
      expect(
        await refused(),
        allOf(
          contains('lesson.rus.family-1.json'),
          contains('teach[0].routes: a set of teach screens is for the new route only'),
        ),
      );
      change('lesson.rus.family-1.json', (Map<String, Object?> l) {
        firstSet(l)['routes'] = <String>['new'];
        firstSet(l)['mode'] = 'hear';
      });
      expect(
        await refused(),
        contains('a set of hearing screens (mode hear) is for the heritage route only'),
      );
    });

    test('the reader is no route of a set: it is resolved before the lesson is built (the schema)', () async {
      change('lesson.rus.family-1.json', (Map<String, Object?> l) {
        firstSet(l)['routes'] = <String>['new', 'reader'];
      });
      expect(await refused(), contains('teach[0].routes[1]: must be one of new, heritage'));
    });

    test('a hearing screen is in a hear set only, and a hear set holds hearing screens only', () async {
      change('lesson.rus.pairs-1.json', (Map<String, Object?> l) {
        final List<Object?> sets = l['teach']! as List<Object?>;
        final Map<String, Object?> teach = sets.first! as Map<String, Object?>;
        final Map<String, Object?> hear = sets.last! as Map<String, Object?>;
        (teach['items']! as List<Object?>).add((hear['items']! as List<Object?>).first);
      });
      expect(await refused(), contains('is a hearing screen, and it is in a hear set only'));
      change('lesson.rus.pairs-1.json', (Map<String, Object?> l) {
        final List<Object?> sets = l['teach']! as List<Object?>;
        (sets.last! as Map<String, Object?>)['items'] = <String>['rus.a20.tc01'];
      });
      expect(await refused(), contains('is a teach screen, and a hear set holds hearing screens'));
    });

    test(
      'a say step has an order and a picture-first line together, and the line has no clip after it',
      () async {
        change('activity.rus.a15.01.json', (Map<String, Object?> a) {
          (a['say']! as Map<String, Object?>).remove('pictureFirst');
        });
        expect(await refused(), contains('order and pictureFirst go together'));
        change('activity.rus.a15.01.json', (Map<String, Object?> a) {
          final Map<String, Object?> say = a['say']! as Map<String, Object?>;
          say['pictureFirst'] = <String, Object?>{
            'vo': 'vo:rus.f06',
            'caption': <Object?>[
              <String, Object?>{'t': 'he', 'v': 'מַה זֶּה? נַסּוּ לְהַגִּיד בְּרוּסִית.'},
            ],
            'target': 'vo:rus.w_mama',
          };
        });
        expect(
          await refused(),
          contains('asks for the word before it is heard: no clip may follow the line'),
        );
      },
    );

    test('a teach or hearing screen is always echo: it has no order', () async {
      change('activity.rus.a20.th01.json', (Map<String, Object?> a) {
        final Map<String, Object?> say = a['say']! as Map<String, Object?>;
        say['order'] = <String, Object?>{'new': 'echo', 'heritage': 'picture'};
        say['pictureFirst'] = <String, Object?>{
          'vo': 'vo:rus.f06',
          'caption': <Object?>[
            <String, Object?>{'t': 'he', 'v': 'מַה זֶּה? נַסּוּ לְהַגִּיד בְּרוּסִית.'},
          ],
        };
      });
      expect(await refused(), contains('a teach or hearing screen is always echo'));
    });

    test('how a skill serves a reader is oral or heritage', () async {
      change('skill.RUS-A-03.json', (Map<String, Object?> s) {
        s['readerAs'] = 'sometimes';
      });
      expect(await refused(), contains('readerAs'));
    });

    test('a teach item must be a teach screen of the pack', () async {
      change('lesson.rus.family-1.json', (Map<String, Object?> l) {
        firstSet(l)['items'] = <String>['rus.a02.02'];
      });
      expect(await refused(), contains('is not a teach screen'));
    });

    test('a teach item must exist', () async {
      change('lesson.rus.family-1.json', (Map<String, Object?> l) {
        firstSet(l)['items'] = <String>['rus.a02.tc99'];
      });
      expect(await refused(), contains('there is no activity "rus.a02.tc99"'));
    });

    test('a teach screen is not also an item of the lesson', () async {
      change('lesson.rus.family-1.json', (Map<String, Object?> l) {
        (l['items']! as List<Object?>).add('rus.a02.tc01');
      });
      expect(await refused(), contains('is a teach screen, so it is not one of the lesson'));
    });
  });
}
