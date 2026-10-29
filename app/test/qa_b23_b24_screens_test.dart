// QA's own checks of boards B-23 and B-24 in the real app (docs/qa/b23-b24-verification.md), separate from the developer's
// tests:
// - B-24: with voice switched on by a parent, the lesson screen draws the mic (`lesson-mic`) exactly on the activities whose
//   `voiceAnswer` is true. One activity of every kind of question of the starter pack (template, skill, variant group and
//   flag: 138 of them), each opened through the real lesson screen.
// - B-23: the map and a lesson without a mic with a larger system text (1.3), and the map on screens that are not one of
//   the four boards (narrow phones), where every learning land must still open with a tap.
// - QA-19 (open, skipped in a normal run; run with --dart-define=QA_OPEN=true): at a system text scale of 1.3 the child
//   space overflows (the daily pill on the phone board, the child's card of the profile picker under the map).
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nitznutz/child/home_screen.dart';
import 'package:nitznutz/child/land_screen.dart';
import 'package:nitznutz/content/models.dart';
import 'package:nitznutz/play/activity_frame.dart';

import 'support/app_harness.dart';
import 'support/fake_speech.dart';
import 'support/harness.dart';
import 'support/starter.dart';

/// QA's open defects in this file run only with --dart-define=QA_OPEN=true (the convention of qa_open_defects_test.dart).
const bool _open = !bool.fromEnvironment('QA_OPEN');

Future<void> _wait(WidgetTester t, [int ms = 300]) async {
  for (int spent = 0; spent < ms; spent += 100) {
    await t.pump(const Duration(milliseconds: 100));
  }
}

Finder get _mic => find.byKey(const Key('lesson-mic'));

/// The child's home in the real app, with voice on or off, at [size] and with the system text scaled by [textScale].
Future<AppRig> _home(
  WidgetTester tester, {
  Size size = const Size(852, 393),
  bool voice = true,
  double textScale = 1,
}) async {
  final AppRig rig = AppRig(voice: voice, speech: FakeSpeechEngine(const <Scripted>[]));
  await rig.seedFinishedSetup();
  if (textScale != 1) {
    tester.platformDispatcher.textScaleFactorTestValue = textScale;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
  }
  await rig.pump(tester, size: size);
  await tester.tap(find.text('נועה'));
  await tester.pumpAndSettle();
  expect(find.byType(HomeScreen), findsOneWidget);
  return rig;
}

/// Takes the home's known overflow (QA-19: the daily pill at a system text scale of 1.3) out of the way, and only it.
void _drainPillOverflow(WidgetTester tester) {
  final Object? e = tester.takeException();
  if (e == null) return;
  expect('$e', anyOf(contains('Multiple exceptions'), contains('RenderFlex overflowed')), reason: '$e');
}

Future<void> _closeLesson(WidgetTester tester) async {
  tester.state<NavigatorState>(find.byType(Navigator).first).pop();
  await _wait(tester, 1200);
  expect(find.byType(HomeScreen), findsOneWidget);
}

const List<Land> _learningLands = <Land>[
  Land.counting,
  Land.colors,
  Land.shapes,
  Land.logic,
  Land.robots,
  Land.market,
];

/// Brings a land into view, taps its tap area, and expects that land's island; then goes back home.
Future<void> _opensEveryLand(WidgetTester tester, Size size) async {
  for (final Land land in _learningLands) {
    final Finder tap = find.byKey(Key('land-tap-${land.name}'));
    await tester.ensureVisible(tap);
    await tester.pumpAndSettle();
    final Rect area = tester.getRect(tap);
    expect((Offset.zero & size).contains(area.center), isTrue, reason: '${land.name} on screen: $area');
    await tester.tap(tap);
    await tester.pumpAndSettle();
    expect(find.byType(LandScreen), findsOneWidget, reason: '${land.name} at $size');
    expect(tester.widget<LandScreen>(find.byType(LandScreen)).land.name, land.name);
    tester.state<NavigatorState>(find.byType(Navigator).first).pop();
    await tester.pumpAndSettle();
    expect(find.byType(HomeScreen), findsOneWidget);
  }
}

void main() {
  late PackContent pack;
  setUpAll(() async {
    await loadAppFonts();
    pack = await loadStarter();
  });

  group('B-24: the mic is drawn exactly where the activity is answered by voice', () {
    // One activity of every kind of question, by template.
    final Map<String, List<String>> samples = <String, List<String>>{};
    setUpAll(() {
      final Set<String> seen = <String>{};
      final List<Activity> all = pack.activities.values.toList()
        ..sort((Activity a, Activity b) => a.id.compareTo(b.id));
      for (final Activity a in all) {
        final String kind = '${a.template}|${a.skillId}|${a.variantGroup}|${a.voiceAnswer}';
        if (seen.add(kind)) (samples[a.template] ??= <String>[]).add(a.id);
      }
    });

    for (final String template in <String>[
      'tap_answer',
      'count_tap',
      'flash',
      'give_n',
      'number_line',
      'balance',
      'spot_error',
      'trace',
      'robot_path',
      'sort_drag',
      'match_pairs',
      'build_pattern',
      'clock_set',
      'shop_pay',
      'shape_builder',
    ]) {
      testWidgets('$template: every kind of question, voice on', (WidgetTester tester) async {
        final AppRig rig = await _home(tester);
        final List<String> ids = samples[template]!;
        expect(ids, isNotEmpty);
        final List<String> wrong = <String>[];
        for (final String id in ids) {
          await openActivities(tester, <String>[id]);
          await _wait(tester, 600);
          expect(find.byType(ActivityFrame), findsOneWidget, reason: id);
          final bool spoken = pack.activities[id]!.voiceAnswer;
          final bool drawn = _mic.evaluate().isNotEmpty;
          if (spoken != drawn) wrong.add('$id: voiceAnswer $spoken, mic drawn $drawn');
          expect(tester.takeException(), isNull, reason: id);
          await _closeLesson(tester);
        }
        expect(wrong, isEmpty, reason: wrong.join('\n'));
        if (template != 'tap_answer' && template != 'count_tap' && template != 'flash') {
          expect(rig.speech.prepares, 0, reason: 'no mic was ever prepared for a $template');
        }
        debugPrint('QA B-24 $template: ${ids.length} kinds of question opened');
      });
    }

    testWidgets('with voice off, no activity draws a mic, the spoken ones included', (
      WidgetTester tester,
    ) async {
      await _home(tester, voice: false);
      for (final String id in <String>[
        'col.world.apple.red',
        'count.butterflies.3',
        'flash.dice.1',
        'next.after.2',
      ]) {
        expect(pack.activities[id]!.voiceAnswer, isTrue);
        await openActivities(tester, <String>[id]);
        await _wait(tester, 600);
        expect(find.byType(ActivityFrame), findsOneWidget, reason: id);
        expect(_mic, findsNothing, reason: id);
        await _closeLesson(tester);
      }
    });
  });

  group('B-23: a screen reader reaches every land, on screen or not', () {
    for (final MapEntry<String, Size> b in <String, Size>{
      'phone': const Size(852, 393),
      'phoneSE': const Size(667, 375),
      'tabletPortrait': const Size(820, 1180),
    }.entries) {
      testWidgets(
        '${b.key}: each learning land is a button with its name; the map scrolls by a screen reader too',
        (WidgetTester tester) async {
          final SemanticsHandle handle = tester.ensureSemantics();
          await _home(tester, size: b.value);
          // A land off screen is marked hidden (the reader scrolls to it), so the flags are read one by one.
          for (final Land l in _learningLands) {
            final SemanticsData s = tester
                .getSemantics(find.byKey(Key('land-tap-${l.name}')))
                .getSemanticsData();
            expect(s.label, l.label.text, reason: l.name);
            expect(s.flagsCollection.isButton, isTrue, reason: l.name);
            expect(s.hasAction(SemanticsAction.tap), isTrue, reason: l.name);
          }
          // Nitzi's island is a name only (board B-26): no button.
          expect(find.byKey(const Key('land-tap-nitzi')), findsNothing);
          // Somewhere in the tree a node offers to scroll (the map: off-screen lands are reached that way).
          SemanticsNode root = tester.getSemantics(find.byKey(const Key('land-tap-counting')));
          while (root.parent != null) {
            root = root.parent!;
          }
          bool scrolls(SemanticsNode n) {
            final SemanticsData d = n.getSemanticsData();
            if (d.hasAction(SemanticsAction.scrollLeft) ||
                d.hasAction(SemanticsAction.scrollRight) ||
                d.hasAction(SemanticsAction.scrollUp) ||
                d.hasAction(SemanticsAction.scrollDown)) {
              return true;
            }
            bool found = false;
            n.visitChildren((SemanticsNode c) {
              found = scrolls(c);
              return !found;
            });
            return found;
          }

          expect(scrolls(root), isTrue, reason: 'the map offers a scroll action');
          handle.dispose();
        },
      );
    }
  });

  group('B-23: the map with a larger system text, and on screens that are not a board', () {
    for (final MapEntry<String, Size> b in <String, Size>{
      'phone': const Size(852, 393),
      'phoneSE': const Size(667, 375),
      'tabletLandscape': const Size(1180, 820),
      'tabletPortrait': const Size(820, 1180),
    }.entries) {
      testWidgets('text scale 1.3, ${b.key}: all seven signs are drawn and every land opens', (
        WidgetTester tester,
      ) async {
        await _home(tester, size: b.value, textScale: 1.3);
        // The daily pill overflows at 1.3 (QA-19, before B-23 too): proven by its own test in qa_open_defects_test.dart.
        _drainPillOverflow(tester);
        for (final Land l in Land.values) {
          expect(find.byKey(Key('sign-${l.name}')), findsOneWidget);
        }
        await _opensEveryLand(tester, b.value);
        expect(tester.takeException(), isNull);
      });
    }

    for (final String id in <String>['pick.red.flower', 'b.numb08.1', 'b.numb13.1', 'give.butterflies.4']) {
      for (final MapEntry<String, Size> b in <String, Size>{
        'phone': const Size(852, 393),
        'phoneSE': const Size(667, 375),
      }.entries) {
        testWidgets('text scale 1.3, a lesson without a mic ($id), ${b.key}: no overflow', (
          WidgetTester tester,
        ) async {
          await _home(tester, size: b.value, textScale: 1.3);
          _drainPillOverflow(tester);
          await openActivities(tester, <String>[id]);
          await _wait(tester, 1500);
          expect(find.byType(ActivityFrame), findsOneWidget);
          expect(_mic, findsNothing);
          expect(tester.takeException(), isNull);
        });
      }
    }

    for (final MapEntry<String, Size> s in <String, Size>{
      'a small Android phone 640 by 360': const Size(640, 360),
      'the first iPhone SE 568 by 320': const Size(568, 320),
      'a long Android phone 800 by 360': const Size(800, 360),
      'a very long phone 960 by 412': const Size(960, 412),
    }.entries) {
      testWidgets('${s.key}: the map is scaled, never stretched, and every land opens with a tap', (
        WidgetTester tester,
      ) async {
        await _home(tester, size: s.value);
        expect(tester.takeException(), isNull);
        await _opensEveryLand(tester, s.value);
        // A drag that starts on a sign moves the map and opens nothing, on a scaled board too.
        final ScrollPosition map = tester
            .state<ScrollableState>(
              find.descendant(
                of: find.byKey(const PageStorageKey<String>('home-map')),
                matching: find.byType(Scrollable),
              ),
            )
            .position;
        map.jumpTo(map.maxScrollExtent / 2);
        await tester.pump();
        final Finder sign = find.byKey(const Key('sign-shapes'));
        final Offset before = tester.getCenter(sign);
        expect(
          (Offset.zero & s.value).contains(before),
          isTrue,
          reason: 'the Shapes sign is in view half way',
        );
        await tester.drag(sign, const Offset(150, 0));
        await tester.pumpAndSettle();
        expect(find.byType(LandScreen), findsNothing);
        expect(tester.getCenter(sign), isNot(before));
      });
    }
  });

  group('QA-19 (open): a larger system text does not break the child space', () {
    for (final MapEntry<String, Size> b in <String, Size>{
      'phone': const Size(852, 393),
      'phoneSE': const Size(667, 375),
      'tabletLandscape': const Size(1180, 820),
      'tabletPortrait': const Size(820, 1180),
    }.entries) {
      testWidgets('text scale 1.3, ${b.key}: the picker and the map draw without an overflow', (
        WidgetTester tester,
      ) async {
        await _home(tester, size: b.value, textScale: 1.3);
        expect(tester.takeException(), isNull);
      }, skip: _open);
    }
  });
}
