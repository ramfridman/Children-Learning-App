// The layout rules of the logic land (QA sweep, 2026-11-07), held in CI for every activity of LOG-A-* and LOG-B-* on the three boards
// (the phone, the small phone and the tablet), on the CURRENT sources in content/starter (the audit harness plays the same):
//  - no speech bubble comes within 8 points of an answer tile, and
//  - every picture that a child chooses or reads off a row (the pictures on the answer tiles, in a row of things, the model row of a
//    pattern, the cells of a row to spot the mistake in, and the options that stand on the stage) is at least the token
//    `component.stagePicture.min` (40 points, 1.4 times that on a tablet) on its longest side. A set of things on a tile or a group on
//    the stage is counted, not read, and a picture of a size family is a box that holds a small picture, so they are not measured.
//
// The activities are opened one after the other, each in a lesson of its own, and the boxes are read from the render tree: nothing is
// painted to a picture, so the three boards take under a minute.
//
// To print the numbers of every activity:  flutter test --dart-define=LOGIC_RULES_REPORT=true test/logic_land_rules_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nitznutz/content/models.dart';
import 'package:nitznutz/play/lesson_screen.dart';
import 'package:nitznutz/play/sprite_group.dart';
import 'package:nitznutz/play/stage_picture.dart';
import 'package:nitznutz/play/template_session.dart' show PackSvg;

import 'support/app_harness.dart';
import 'support/harness.dart';
import 'support/starter.dart';

const bool _report = bool.fromEnvironment('LOGIC_RULES_REPORT');

/// The boards: a name and the window (the board and the window are the same size, so a box on the screen is a box on the board).
const Map<String, Size> boards = <String, Size>{
  'phone': Size(852, 393),
  'phone SE': Size(667, 375),
  'tablet': Size(1180, 820),
};

/// The room that a speech bubble keeps from every answer tile.
const double bubbleGap = 8;

/// A picture a child reads, with what it is for (`tile`, `row`, `option`, `model`, `cell`) and the box it is drawn in.
typedef Picture = ({String role, Size box});

/// What a child sees of one activity: the speech bubble, the answer tiles and the pictures.
class LogicShot {
  LogicShot(this.id, this.bubble, this.tiles, this.pictures);

  final String id;
  final Rect? bubble;
  final List<Rect> tiles;
  final List<Picture> pictures;

  /// The smallest distance from the bubble to a tile that stands under it, or null where there is none.
  double? get gap {
    final Rect? b = bubble;
    if (b == null) {
      return null;
    }
    double? least;
    for (final Rect t in tiles) {
      if (t.right > b.left && t.left < b.right) {
        final double g = t.top - b.bottom;
        least = least == null || g < least ? g : least;
      }
    }
    return least;
  }

  /// The picture with the shortest longest side, or null where there is none.
  Picture? get smallest {
    Picture? least;
    for (final Picture p in pictures) {
      if (least == null || p.box.longestSide < least.box.longestSide) {
        least = p;
      }
    }
    return least;
  }
}

Future<void> _wait(WidgetTester t, int ms) async {
  for (int spent = 0; spent < ms; spent += 100) {
    await t.pump(const Duration(milliseconds: 100));
  }
}

bool _keyStarts(Widget w, String prefix) =>
    w.key is ValueKey<String> && (w.key! as ValueKey<String>).value.startsWith(prefix);

/// The pictures under what [of] finds, but those of a set or a group of things, by the role they play.
List<Picture> _pictures(String role, Finder of) {
  final Set<Element> counted = <Element>{
    for (final Element g in find.byType(SpriteGroup).evaluate())
      ...find.descendant(of: find.byWidget(g.widget), matching: find.byType(PackSvg)).evaluate(),
  };
  return <Picture>[
    for (final Element e in find.descendant(of: of, matching: find.byType(PackSvg)).evaluate())
      if (!counted.contains(e)) (role: role, box: e.size!),
  ];
}

/// Opens each logic activity of [content] in a lesson of its own on a window of [window] and reads what is on the screen.
Future<List<LogicShot>> readLogicLand(WidgetTester tester, PackContent content, Size window) async {
  final List<String> ids = <String>[
    for (final Activity a in content.activities.values)
      if (a.skills.any((Skill s) => s.id.startsWith('LOG-'))) a.id,
  ]..sort();
  final AppRig rig = AppRig(content: content);
  await rig.seedFinishedSetup(name: 'נֹעָה');
  await rig.pump(tester, size: window);
  await tester.tap(find.text('נֹעָה'));
  await tester.pumpAndSettle();
  final List<LogicShot> shots = <LogicShot>[];
  for (final String id in ids) {
    final Activity a = content.activities[id]!;
    final NavigatorState nav = tester.state<NavigatorState>(find.byType(Navigator).first);
    nav.push(
      MaterialPageRoute<void>(
        builder: (BuildContext c) => LessonScreen(
          profileId: 'p-1',
          mission: Lesson.mission(
            id: 'rules',
            itemIds: <String>[id],
            skillIds: a.skills.map((Skill s) => s.id).toList(),
            celebration: content.lessons['butterflies']!.celebration,
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 600));
    await _wait(tester, 800);
    final Finder bubble = find.descendant(
      of: find.byKey(const Key('lesson-bubble')),
      matching: find.byKey(const Key('bubble-body')),
    );
    final Finder tiles = find.byKey(const Key('answer-tile'));
    shots.add(
      LogicShot(
        id,
        bubble.evaluate().isEmpty ? null : tester.getRect(bubble),
        <Rect>[for (final Element e in tiles.evaluate()) tester.getRect(find.byWidget(e.widget))],
        <Picture>[
          ..._pictures('tile', tiles),
          ..._pictures('row', find.byKey(const Key('tap-row'))),
          ..._pictures('option', find.byWidgetPredicate((Widget w) => _keyStarts(w, 'option-'))),
          ..._pictures('model', find.byKey(const Key('pattern-model'))),
          ..._pictures('cell', find.byWidgetPredicate((Widget w) => _keyStarts(w, 'cell-'))),
        ],
      ),
    );
    nav.pop();
    await tester.pump(const Duration(milliseconds: 600));
  }
  return shots;
}

void main() {
  setUpAll(() async {
    await loadAppFonts();
  });

  for (final MapEntry<String, Size> board in boards.entries) {
    testWidgets(
      'the logic land on the ${board.key}: the bubble is clear of the tiles, the pictures are not under the token',
      (WidgetTester tester) async {
        final PackContent content = (await tester.runAsync(loadSourcePack))!;
        final List<LogicShot> shots = await readLogicLand(tester, content, board.value);
        expect(shots.length, greaterThanOrEqualTo(135), reason: 'every activity of the logic land is read');
        // A tablet's stage is a card of 552 inside, a phone's is 330 or 270 wide: the token is for the width of the stage.
        final double least = minPictureOf(
          board.value.shortestSide >= 600 ? const Size(552, 268) : const Size(270, 104),
        );
        final List<String> bad = <String>[];
        for (final LogicShot s in shots) {
          final double? gap = s.gap;
          final Picture? smallest = s.smallest;
          if (_report) {
            // ignore: avoid_print
            print(
              '${board.key} ${s.id} gap ${gap?.toStringAsFixed(1) ?? '-'} '
              'smallest ${smallest?.box.longestSide.toStringAsFixed(1) ?? '-'} ${smallest?.role ?? ''}',
            );
          }
          if (gap != null && gap < bubbleGap) {
            bad.add('${s.id}: the bubble is ${gap.toStringAsFixed(1)} from a tile, under $bubbleGap');
          }
          if (smallest != null && smallest.box.longestSide < least) {
            bad.add(
              '${s.id}: a ${smallest.role} picture is ${smallest.box.longestSide.toStringAsFixed(1)}, '
              'under the token $least',
            );
          }
        }
        expect(bad, isEmpty, reason: bad.join('\n'));
      },
    );
  }
}
