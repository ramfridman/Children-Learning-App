// The print-direction items of Hebrew Band A (HEB-A-12, `story` 1.1 modes `zones` and `follow`): a page that shows its text. `zones` asks where
// reading starts (the right end of the first line), `follow` has the voice read a word and wait for a touch on it, word by word. Nothing is drawn
// on the page at rest; a wrong touch is the mistake it shows (`order`: the other end, another word; `print_picture`: the picture).
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nitznutz/content/models.dart';
import 'package:nitznutz/content/pack_verify.dart';
import 'package:nitznutz/play/lesson_controller.dart';
import 'package:nitznutz/play/read_page_session.dart';

import '../tool/pack_builder_lib.dart';
import 'support/golden_comparator.dart';
import 'support/harness.dart' show loadAppFonts;
import 'support/l4_rig.dart';
import 'support/pack_fixtures.dart';

const String _languages = '../content/languages';

/// Writes the picture of a screen to a folder instead of comparing it (`NN_SHOTS=<folder> flutter test test/read_page_test.dart`).
class _Shots extends GoldenFileComparator {
  _Shots(this.folder);

  final Directory folder;

  @override
  Future<bool> compare(Uint8List imageBytes, Uri golden) async {
    File('${folder.path}${Platform.pathSeparator}${golden.pathSegments.last}').writeAsBytesSync(imageBytes);
    return true;
  }

  @override
  Future<void> update(Uri golden, Uint8List imageBytes) => compare(imageBytes, golden);
}

void main() {
  final String? shots = Platform.environment['NN_SHOTS'];

  late PackContent heb;

  setUpAll(() async {
    await loadAppFonts();
    useTolerantGoldens(0.03);
    if (shots != null) {
      Directory(shots).createSync(recursive: true);
      goldenFileComparator = _Shots(Directory(shots));
    }
    final PackKey key = await newTestKey();
    heb = PackContent.fromPack(
      await verifyPack(
        (await buildPack(languageSource('heb', _languages), key)).bytes,
        publicKey: key.publicKey,
      ),
    );
  });

  Rig<ReadPageSession> rig(String id) => Rig<ReadPageSession>.ofContent(
    heb,
    'heb.a12.$id',
    (LessonController c, Activity a) => ReadPageSession(c, a as StoryActivity),
  );

  StoryActivity item(String id) => heb.activities['heb.a12.$id']! as StoryActivity;

  group('the items of the pack', () {
    test('the three zone items and the two follow items of the lessons, and the two checks', () {
      expect(
        <String>[
          for (final Lesson l in heb.lessons.values.where((Lesson x) => x.id.startsWith('heb.print-'))) l.id,
        ]..sort(),
        <String>['heb.print-1', 'heb.print-2'],
      );
      expect(heb.lessons['heb.print-1']!.itemIds, <String>['heb.a12.01', 'heb.a12.02', 'heb.a12.03']);
      expect(heb.lessons['heb.print-2']!.itemIds, <String>['heb.a12.04', 'heb.a12.05']);
      for (final String id in <String>['01', '02', '03', '06']) {
        expect(item(id).mode, 'zones', reason: id);
      }
      for (final String id in <String>['04', '05', '07']) {
        expect(item(id).mode, 'follow', reason: id);
      }
      expect(item('06').purpose, 'check');
      expect(item('07').purpose, 'check');
    });

    test('a page shows its text one sentence to a line, and a follow page has the clip of every word', () {
      expect(<int>[for (final List<Object?> l in item('01').pages.first.lines) l.length], <int>[3, 4]);
      expect(item('03').pages.first.lines, hasLength(1));
      final StoryPage follow = item('04').pages.first;
      expect(follow.lines.single.map((w) => w.text), <String>[
        'עַכְשָׁו',
        'הָאַרְנָב',
        'וְהַחֲתוּלָה',
        'מְשַׂחֲקִים',
        'יַחַד.',
      ]);
      expect(follow.lines.single.every((w) => w.clip != null), isTrue);
      expect(follow.lines.single.map((w) => w.clip).toSet(), hasLength(5));
    });

    test('the right zone carries no tag, a wrong one the tag of its mistake, and the item is scored', () {
      for (final String id in <String>['01', '04']) {
        final StoryActivity a = item(id);
        expect(a.unscored, isFalse);
        expect(a.reads, isTrue);
        final Map<String?, String?> tags = <String?, String?>{
          for (final ChoiceOption o in a.options) o.zone: o.misconception,
        };
        expect(tags[id == '01' ? 'line1-start' : 'word'], isNull);
        expect(tags['picture'], 'heb.pk.print_picture');
        expect(tags[id == '01' ? 'line1-end' : 'other'], 'heb.pk.order');
      }
      expect(item('02').options.map((ChoiceOption o) => o.zone), <String>[
        'line1-start',
        'line2-end',
        'picture',
      ]);
    });
  });

  group('zones: where do we start reading?', () {
    testWidgets('nothing is drawn on the page at rest, and the zones are on the print', (
      WidgetTester t,
    ) async {
      final Rig<ReadPageSession> r = rig('01');
      await r.pump(t);
      expect(find.byKey(const Key('read-line-0')), findsOneWidget);
      expect(find.byKey(const Key('read-line-1')), findsOneWidget);
      for (final String z in <String>['line1-start', 'line1-end', 'line2-start', 'line2-end']) {
        expect(find.byKey(Key('read-zone-$z')), findsOneWidget);
        expect(
          find.descendant(of: find.byKey(Key('read-zone-$z')), matching: find.byType(DecoratedBox)),
          findsNothing,
          reason: 'the zone $z is not drawn at rest: it is a place of the print, not a button',
        );
      }
      for (final String k in <String>['read-arrow', 'read-finger']) {
        expect(find.byKey(Key(k)), findsNothing);
      }
      await r.done(t);
    });

    testWidgets('the start of the first line is on the right of the text, its end on the left', (
      WidgetTester t,
    ) async {
      final Rig<ReadPageSession> r = rig('03');
      await r.pump(t);
      final Rect text = t.getRect(find.byKey(const Key('read-line-0')));
      final Rect start = t.getRect(find.byKey(const Key('read-zone-line1-start')));
      final Rect end = t.getRect(find.byKey(const Key('read-zone-line1-end')));
      expect(start.center.dx, greaterThan(text.center.dx));
      expect(end.center.dx, lessThan(text.center.dx));
      expect(start.overlaps(end), isFalse);
      expect(start.width, greaterThanOrEqualTo(48), reason: 'a touch zone is never narrower than a control');
      await r.done(t);
    });

    testWidgets('the start is the right answer; the other end is `order`; the picture is `print_picture`', (
      WidgetTester t,
    ) async {
      final Rig<ReadPageSession> r = rig('03');
      await r.pump(t);
      await t.tap(find.byKey(const Key('read-zone-line1-end')));
      await r.wait(t, 1700);
      await t.tap(find.byKey(const Key('read-picture')));
      await r.wait(t, 1700);
      await t.tap(find.byKey(const Key('read-zone-line1-start')));
      await r.wait(t, 100);
      expect(r.written, <String>['incorrect:o2', 'incorrect:o3', 'correct:o1']);
      expect(
        <String>[for (final AttemptRecord a in r.attempts) a.misconceptionTag],
        <String>['heb.pk.order', 'heb.pk.print_picture', ''],
      );
      await r.wait(t, 1800);
      expect(r.controller.finished, isTrue);
      await r.done(t);
    });

    testWidgets(
      'hint 1 draws the reading arrow, hint 2 reads the page with a finger under it, hint 3 rests the finger on the start',
      (WidgetTester t) async {
        final Rig<ReadPageSession> r = rig('03');
        await r.pump(t);
        r.controller.showHint();
        await r.wait(t, 300);
        expect(find.byKey(const Key('read-arrow')), findsOneWidget);
        await r.wait(t, 3300);
        expect(find.byKey(const Key('read-arrow')), findsNothing, reason: 'the arrow goes after a moment');
        r.controller.showHint();
        await r.wait(t, 300);
        expect(find.byKey(const Key('read-finger')), findsOneWidget);
        expect(
          r.heard.clips,
          contains('vo:heb.heb_a_s2_p1'),
          reason: 'the voice reads the page while the finger moves',
        );
        await r.wait(t, 3500);
        r.controller.showHint();
        await r.wait(t, 800);
        expect(find.byKey(const Key('read-finger')), findsOneWidget);
        expect(
          find.descendant(
            of: find.byKey(const Key('read-zone-line1-start')),
            matching: find.byType(DecoratedBox),
          ),
          findsOneWidget,
        );
        await r.done(t);
      },
    );
  });

  group('follow: touch each word as the voice reads it', () {
    testWidgets('the voice reads the first word and waits; each right touch brings the next word', (
      WidgetTester t,
    ) async {
      final Rig<ReadPageSession> r = rig('05');
      await r.pump(t);
      await r.wait(t, 1200);
      final List<String> words = <String>[
        for (final w in item('05').pages.first.lines.single)
          w.clip!.replaceAll('vo:', '').replaceAll('heb.', ''),
      ];
      expect(r.heard.clips.first, 'vo:${item('05').pages.first.lines.single.first.clip!.substring(3)}');
      for (int i = 0; i < words.length - 1; i++) {
        await t.tap(find.byKey(Key('read-word-$i')));
        await r.wait(t, 1200);
      }
      expect(r.written, isEmpty, reason: 'the words on the way are steps, not answers');
      await t.tap(find.byKey(Key('read-word-${words.length - 1}')));
      await r.wait(t, 100);
      expect(r.written, <String>['correct:o1']);
      await r.wait(t, 1800);
      expect(r.controller.finished, isTrue);
      await r.done(t);
    });

    testWidgets(
      'a touch on another word is `order`, on the picture `print_picture`, and the due word is read again',
      (WidgetTester t) async {
        final Rig<ReadPageSession> r = rig('05');
        await r.pump(t);
        await r.wait(t, 1200);
        r.heard.clear();
        await t.tap(find.byKey(const Key('read-word-2')));
        await r.wait(t, 1800);
        await t.tap(find.byKey(const Key('read-picture')));
        await r.wait(t, 1800);
        expect(
          <String>[for (final AttemptRecord a in r.attempts) a.misconceptionTag],
          <String>['heb.pk.order', 'heb.pk.print_picture'],
        );
        expect(r.session.due, 0, reason: 'a mistake does not move the reading on');
        expect(r.heard.clips, isNotEmpty, reason: 'the voice reads the due word again');
        await r.done(t);
      },
    );

    testWidgets('the words are in a line that starts at the right, and every word is a touch target', (
      WidgetTester t,
    ) async {
      final Rig<ReadPageSession> r = rig('04');
      await r.pump(t);
      final Rect first = t.getRect(find.byKey(const Key('read-word-0')));
      final Rect last = t.getRect(find.byKey(const Key('read-word-1')));
      expect(
        first.center.dx,
        greaterThan(last.center.dx),
        reason: 'the first word is at the right of the second',
      );
      for (int i = 0; i < 5; i++) {
        final Size s = t.getSize(find.byKey(Key('read-word-$i')));
        expect(s.height, greaterThanOrEqualTo(48));
      }
      await r.done(t);
    });
  });

  group('one sentence to a line on the phones (docs/design/languages-band-a-qa.md section 5.2)', () {
    for (final MapEntry<String, Size> b in boards.entries.where(
      (MapEntry<String, Size> e) => e.key.startsWith('phone'),
    )) {
      testWidgets('${b.key}: the picture is the stage, the print stands under it and each line is one row', (
        WidgetTester t,
      ) async {
        final Rig<ReadPageSession> r = rig('04');
        await r.pump(t, size: b.value);
        final Rect stage = t.getRect(find.byKey(const Key('read-stage')));
        final Rect print = t.getRect(find.byKey(const Key('read-print')));
        expect(
          print.top,
          greaterThanOrEqualTo(stage.bottom - 1),
          reason: 'the print is in the answer zone, not in the stage',
        );
        expect(find.byKey(const Key('read-picture')), findsOneWidget);
        final StoryActivity a = item('04');
        final int words = a.pages.first.lines.fold<int>(
          0,
          (int n, List<({String text, String? clip})> l) => n + l.length,
        );
        final List<double> rows = <double>{
          for (int i = 0; i < words; i++)
            t.getRect(find.byKey(Key('read-word-$i'))).center.dy.roundToDouble(),
        }.toList();
        expect(
          rows.length,
          a.pages.first.lines.length,
          reason: 'the words of a line stand in one row: no wrapping',
        );
        for (int i = 0; i < words; i++) {
          expect(t.getSize(find.byKey(Key('read-word-$i'))).height, greaterThanOrEqualTo(48));
        }
        expect(
          print.bottom,
          lessThanOrEqualTo(b.value.height - 24 + 1),
          reason: 'above the edge where no touch place may be',
        );
        await r.done(t);
      });

      testWidgets('${b.key}: a zones page keeps its lines in the answer zone, with its two ends to touch', (
        WidgetTester t,
      ) async {
        final Rig<ReadPageSession> r = rig('01');
        await r.pump(t, size: b.value);
        final Rect stage = t.getRect(find.byKey(const Key('read-stage')));
        expect(t.getRect(find.byKey(const Key('read-print'))).top, greaterThanOrEqualTo(stage.bottom - 1));
        expect(t.getRect(find.byKey(const Key('read-zone-line1-start'))).width, greaterThanOrEqualTo(48));
        expect(t.getRect(find.byKey(const Key('read-zone-line1-end'))).width, greaterThanOrEqualTo(48));
        await r.done(t);
      });
    }

    testWidgets('a tablet keeps the tall stage with the picture and the print in it', (WidgetTester t) async {
      final Rig<ReadPageSession> r = rig('04');
      await r.pump(t, size: boards['tabletLandscape']!);
      final Rect stage = t.getRect(find.byKey(const Key('read-stage')));
      final Rect print = t.getRect(find.byKey(const Key('read-print')));
      expect(stage.contains(print.center), isTrue);
      await r.done(t);
    });
  });

  // The pictures of each state, to look at (they are written only when NN_SHOTS names a folder; nothing is compared).
  if (shots != null) {
    for (final MapEntry<String, Size> b in boards.entries.where(
      (e) => e.key == 'phone' || e.key == 'tabletLandscape',
    )) {
      testWidgets('pictures of the zones page on the ${b.key} board', (WidgetTester t) async {
        final Rig<ReadPageSession> r = rig('01');
        await r.pump(t, size: b.value);
        await expectLater(find.byType(MaterialApp), matchesGoldenFile('zones_rest_${b.key}.png'));
        r.controller.showHint();
        await r.wait(t, 400);
        await expectLater(find.byType(MaterialApp), matchesGoldenFile('zones_hint1_arrow_${b.key}.png'));
        await r.wait(t, 3500);
        r.controller.showHint();
        await r.wait(t, 1500);
        await expectLater(find.byType(MaterialApp), matchesGoldenFile('zones_hint2_finger_${b.key}.png'));
        await r.wait(t, 4000);
        r.controller.showHint();
        await r.wait(t, 800);
        await expectLater(find.byType(MaterialApp), matchesGoldenFile('zones_hint3_${b.key}.png'));
        await r.done(t);
      });
      testWidgets('pictures of the follow page on the ${b.key} board', (WidgetTester t) async {
        final Rig<ReadPageSession> r = rig('04');
        await r.pump(t, size: b.value);
        await r.wait(t, 1000);
        await expectLater(find.byType(MaterialApp), matchesGoldenFile('follow_reading_${b.key}.png'));
        await t.tap(find.byKey(const Key('read-word-0')));
        await r.wait(t, 1600);
        await t.tap(find.byKey(const Key('read-word-1')));
        await r.wait(t, 1600);
        await expectLater(find.byType(MaterialApp), matchesGoldenFile('follow_third_${b.key}.png'));
        await r.done(t);
      });
    }
  }
}
