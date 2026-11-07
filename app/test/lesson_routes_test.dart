// Teach screens and routes (docs/languages/band-a-build.md section 2.4): a lesson of a language course may name teach screens (`lesson.teach`,
// each set with the routes that are shown it), and what a child plays is chosen by the child's route. The rule that matters most: a heritage
// speaker, who knows the words, is never shown a teach screen. A teach screen is shown, not asked: it is never scored, writes nothing, has no
// microphone, and the engine does not see it.
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:nitznutz/content/engine_adapter.dart';
import 'package:nitznutz/content/models.dart';
import 'package:nitznutz/content/pack_verify.dart';
import 'package:nitznutz/content/schema.dart' show Problem;
import 'package:nitznutz/engine/types.dart';
import 'package:nitznutz/play/lesson_controller.dart';

import '../tool/pack_builder_lib.dart';
import 'support/pack_fixtures.dart';

const String _languages = '../content/languages';

void main() {
  late PackContent rus;

  setUpAll(() async {
    final PackKey key = await newTestKey();
    final VerifiedPack pack = await verifyPack(
      (await buildPack(languageSource('rus', _languages), key)).bytes,
      publicKey: key.publicKey,
    );
    rus = PackContent.fromPack(pack);
  });

  Iterable<Lesson> withTeach() => rus.lessons.values.where((Lesson l) => l.teach.isNotEmpty);

  group('what a route plays', () {
    test('a new learner is shown the teach screens first, then the lesson', () {
      final Lesson l = rus.lessons['rus.family-1']!;
      final List<Activity> items = rus.itemsFor(l, route: 'new');
      final int teach = l.teach.fold(0, (int n, TeachSet s) => n + s.itemIds.length);
      expect(teach, 4);
      expect(items.length, teach + l.itemIds.length);
      expect(items.take(teach).every((Activity a) => a is SayItActivity && a.teach), isTrue);
      expect(<String>[for (final Activity a in items.skip(teach)) a.id], l.itemIds);
    });

    test('a reader is shown them, and so is a child whose route is not set (a new learner)', () {
      final Lesson l = rus.lessons['rus.family-1']!;
      expect(rus.itemsFor(l, route: 'reader').length, rus.itemsFor(l, route: 'new').length);
      expect(rus.itemsFor(l).length, rus.itemsFor(l, route: 'new').length);
    });

    test('a heritage speaker is never shown a teach screen: in no lesson of the pack', () {
      expect(withTeach(), isNotEmpty, reason: 'the Russian pack has teach screens');
      for (final Lesson l in rus.lessons.values) {
        final List<Activity> items = rus.itemsFor(l, route: 'heritage');
        expect(<String>[for (final Activity a in items) a.id], l.itemIds, reason: l.id);
        expect(items.any((Activity a) => a.teachScreen), isFalse, reason: l.id);
      }
    });

    test('even a pack that names the heritage route cannot show it a teach screen', () {
      final Lesson l = rus.lessons['rus.family-1']!;
      final Lesson wrong = Lesson.mission(
        id: 'x',
        itemIds: l.itemIds,
        skillIds: l.skillIds,
        celebration: l.celebration,
      );
      expect(rus.itemsFor(wrong, route: 'heritage').length, l.itemIds.length);
    });

    test('a lesson with no teach set plays as it is, whatever the route', () {
      final Lesson l = rus.lessons.values.firstWhere((Lesson x) => x.teach.isEmpty);
      for (final String? route in <String?>[null, 'new', 'heritage', 'reader']) {
        expect(<String>[for (final Activity a in rus.itemsFor(l, route: route)) a.id], l.itemIds);
      }
    });
  });

  group('the teach screens of the Russian pack', () {
    test('each is a say step flagged as a teach screen, in a skill of its lesson, and is not an item of any lesson', () {
      final Set<String> items = <String>{for (final Lesson l in rus.lessons.values) ...l.itemIds};
      int screens = 0;
      for (final Lesson l in withTeach()) {
        for (final TeachSet s in l.teach) {
          expect(s.routes, everyElement(anyOf('new', 'reader')), reason: l.id);
          for (final String id in s.itemIds) {
            final Activity a = rus.activities[id]!;
            screens++;
            expect(a, isA<SayItActivity>(), reason: id);
            expect((a as SayItActivity).teach, isTrue, reason: id);
            expect(a.unscored, isTrue, reason: id);
            expect(a.scored, isFalse, reason: id);
            expect(a.skills.map((Skill s) => s.id), l.skillIds.take(1), reason: id);
            expect(items.contains(id), isFalse, reason: id);
          }
        }
      }
      expect(screens, 117, reason: 'every word of every teach list of the teachers');
    });

    test('the engine does not see them: no item of its catalogue, no representation counted for a skill', () {
      final Catalog catalog = engineCatalog(rus);
      final Set<String> ids = catalog.items.keys.toSet();
      for (final Activity a in rus.activities.values) {
        expect(ids.contains(a.id), !a.teachScreen, reason: a.id);
      }
      expect(rus.activities.values.where((Activity a) => a.teachScreen), isNotEmpty);
    });

    test('a teach set is put before the lesson that asks its words', () {
      // The animals come in six sets, the lessons ask them in order: the first set before animals-1, the second before animals-2 ...
      final Map<String, List<String>> before = <String, List<String>>{
        for (final Lesson l in rus.lessons.values.where((Lesson x) => x.id.startsWith('rus.animals-')))
          l.id: <String>[for (final TeachSet s in l.teach) ...s.itemIds],
      };
      expect(before['rus.animals-1'], hasLength(5));
      expect(before['rus.animals-2'], hasLength(4));
      expect(
        before['rus.animals-5'],
        hasLength(6),
        reason: 'the fifth and the sixth set both come before animals-5',
      );
      expect(before['rus.animals-1']!.first, 'rus.a05.tc01');
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
    tearDown(() => dir.deleteSync(recursive: true));

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

    test('a teach set may not name the heritage route (the schema)', () async {
      change('lesson.rus.family-1.json', (Map<String, Object?> l) {
        firstSet(l)['routes'] = <String>['new', 'heritage'];
      });
      expect(
        await refused(),
        allOf(
          contains('lesson.rus.family-1.json'),
          contains('teach[0].routes[1]: must be one of new, reader'),
        ),
      );
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
