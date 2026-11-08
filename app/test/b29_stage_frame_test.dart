// B-29 step 6 on the activity frame: the tiles' size and hit area follow the look, the row fits on every board for the most choices the look
// allows, hidden captions become a speaker bubble that replays the question (and keep a number sentence), the idle prompt rings the bubble
// and points into the stage and never at a tile, and with no look the frame is the one it has always been.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nitznutz/child/activity_shell.dart';
import 'package:nitznutz/design/board.dart';
import 'package:nitznutz/design/components.dart';
import 'package:nitznutz/design/layout.dart';
import 'package:nitznutz/design/stage_spec.dart';
import 'package:nitznutz/design/token_types.dart' show Band;
import 'package:nitznutz/design/tokens.g.dart';
import 'package:nitznutz/engine/age.dart' show PresentationStage;
import 'package:nitznutz/play/activity_frame.dart';
import 'package:nitznutz/play/idle_ladder.dart';
import 'package:nitznutz/play/math_run.dart';

import 'support/harness.dart';

const Map<BoardClass, Size> _size = <BoardClass, Size>{
  BoardClass.phone: Size(852, 393),
  BoardClass.phoneSE: Size(667, 375),
  BoardClass.tabletLandscape: Size(1180, 820),
  BoardClass.tabletPortrait: Size(820, 1180),
};

Future<void> _pump(
  WidgetTester tester,
  BoardClass board, {
  PresentationStage? stage,
  bool captions = true,
  int choices = 3,
  List<String>? math,
  bool ring = false,
  bool hand = false,
  VoidCallback? onReplay,
}) async {
  final Size size = _size[board]!;
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final StageSpec? look = stage == null ? null : StageSpec.of(stage);
  final ActivitySpec base = ActivitySpec.of(board);
  final SizeClass c = sizeClassFor(size);
  final ActivitySpec spec = look == null ? base : look.applyTo(base, c);
  Widget frame() => ActivityFrame(
    spec: spec,
    bubbleText: 'כַּמָּה פְּרָחִים יֵשׁ בַּשָּׂדֶה?',
    bubbleMath: math,
    stage: (Size room) => const SizedBox(),
    trailTotal: 5,
    trailDone: 1,
    onHome: () {},
    onReplay: onReplay,
    promptRing: ring,
    idleHand: hand ? idleHand : null,
    tiles: TileRow(
      children: <Widget>[
        for (int i = 0; i < choices; i++)
          AnswerTile(
            key: Key('tile-$i'),
            semanticLabel: '$i',
            onPressed: () {},
            child: Text('$i', style: TextStyle(fontSize: spec.tileFont)),
          ),
      ],
    ),
  );
  await tester.pumpWidget(
    MaterialApp(
      locale: const Locale('he'),
      home: Directionality(
        textDirection: TextDirection.rtl,
        child: LayoutScope(
          band: Band.b,
          child: look == null ? frame() : StageScope(stage: look, captionsShown: captions, child: frame()),
        ),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  setUpAll(loadAppFonts);

  group('the answer tiles follow the look', () {
    for (final BoardClass board in BoardClass.values) {
      for (final PresentationStage stage in PresentationStage.values) {
        testWidgets(
          '${board.name} ${stage.name}: the most choices fit, are the stage\'s size and stay clear of the bottom band',
          (WidgetTester tester) async {
            final StageSpec s = StageSpec.of(stage);
            final SizeClass c = sizeClassFor(_size[board]!);
            await _pump(tester, board, stage: stage, choices: s.maxChoices);
            expect(tester.takeException(), isNull, reason: 'no overflow with ${s.maxChoices} tiles');
            final Finder tiles = find.byType(AnswerTile);
            expect(tiles, findsNWidgets(s.maxChoices));
            for (final Element e in tiles.evaluate()) {
              final Size hit = e.size!;
              expect(hit.width, s.hitArea(c), reason: 'the hit area is the tile and its slop each side');
              expect(hit.height, s.hitArea(c));
              final Rect r = tester.getRect(find.byWidget(e.widget));
              expect(
                r.bottom,
                lessThanOrEqualTo(_size[board]!.height - TokenTouch.bottomNoHotspot),
                reason: 'the bottom band',
              );
            }
            // The tiles as drawn are whole on the board (the end margins of a full row may reach a few points past it: they are only touch).
            for (final Element e in find.byKey(const Key('answer-tile')).evaluate()) {
              final Rect r = tester.getRect(find.byWidget(e.widget));
              expect(r.left, greaterThanOrEqualTo(0), reason: 'a drawn tile is whole on the board');
              expect(r.right, lessThanOrEqualTo(_size[board]!.width));
            }
            // The drawn tile inside the hit area.
            final Size drawn = tester.getSize(find.byKey(const Key('answer-tile')).first);
            expect(drawn, Size(s.tile(c), s.tile(c)));
          },
        );
      }
    }

    testWidgets('on a phone the youngest have a hit area of 128 points, 2 cm', (WidgetTester tester) async {
      await _pump(tester, BoardClass.phone, stage: PresentationStage.p1, choices: 3);
      expect(tester.getSize(find.byType(AnswerTile).first), const Size(128, 128));
      // The gap between two drawn tiles is 32.
      final Rect a = tester.getRect(find.byKey(const Key('answer-tile')).at(0));
      final Rect b = tester.getRect(find.byKey(const Key('answer-tile')).at(1));
      expect((a.left - b.right).abs(), 32);
    });

    testWidgets('the drawn tiles of a row sit where the board puts them, whatever the slop', (
      WidgetTester tester,
    ) async {
      for (final PresentationStage stage in PresentationStage.values) {
        await _pump(tester, BoardClass.phone, stage: stage, choices: 3);
        final Rect first = tester.getRect(find.byKey(const Key('answer-tile')).first);
        expect(
          first.top,
          ActivitySpec.phone.tilesTop,
          reason: '${stage.name}: the tile\'s top is the board\'s, the slop is above it',
        );
      }
    });

    testWidgets('with no look the frame is the one it has always been: tiles 96, hit area 120', (
      WidgetTester tester,
    ) async {
      await _pump(tester, BoardClass.phone, choices: 3);
      expect(tester.getSize(find.byType(AnswerTile).first), const Size(120, 120));
      expect(tester.getSize(find.byKey(const Key('answer-tile')).first), const Size(96, 96));
    });
  });

  group('captions hidden: a speaker bubble in the place of the words', () {
    testWidgets('the words are not drawn; the speaker replays the question when touched', (
      WidgetTester tester,
    ) async {
      int replays = 0;
      await _pump(
        tester,
        BoardClass.phone,
        stage: PresentationStage.p1,
        captions: false,
        onReplay: () => replays++,
      );
      expect(find.byKey(const Key('lesson-bubble')), findsNothing);
      expect(find.textContaining('פְּרָחִים'), findsNothing);
      expect(find.byKey(const Key('lesson-speaker-bubble')), findsOneWidget);
      expect(tester.getSize(find.byKey(const Key('speaker-body'))), const Size(64, 64));
      await tester.tap(find.byKey(const Key('lesson-speaker-bubble')));
      expect(replays, 1);
    });

    testWidgets('on a tablet the speaker is 72 points', (WidgetTester tester) async {
      await _pump(tester, BoardClass.tabletLandscape, stage: PresentationStage.p2, captions: false);
      expect(tester.getSize(find.byKey(const Key('speaker-body'))), const Size(72, 72));
    });

    testWidgets('captions shown: the caption, no speaker', (WidgetTester tester) async {
      await _pump(tester, BoardClass.phone, stage: PresentationStage.p3, captions: true);
      expect(find.byKey(const Key('lesson-bubble')), findsOneWidget);
      expect(find.byKey(const Key('lesson-speaker-bubble')), findsNothing);
    });

    testWidgets('a number sentence still shows, under the speaker', (WidgetTester tester) async {
      await _pump(
        tester,
        BoardClass.phone,
        stage: PresentationStage.p2,
        captions: false,
        math: <String>['n:3', 'op:+', 'n:2', 'op:=', '?'],
      );
      expect(find.byKey(const Key('lesson-speaker-bubble')), findsOneWidget);
      expect(find.byType(MathRun), findsOneWidget);
    });

    testWidgets('the numerals on the tiles show whatever the setting says', (WidgetTester tester) async {
      await _pump(tester, BoardClass.phone, stage: PresentationStage.p1, captions: false, choices: 3);
      for (final String n in <String>['0', '1', '2']) {
        expect(find.text(n), findsOneWidget);
      }
    });

    testWidgets('the speaker stands inside the board on every board and is not over a tile', (
      WidgetTester tester,
    ) async {
      for (final BoardClass board in BoardClass.values) {
        await _pump(tester, board, stage: PresentationStage.p1, captions: false);
        final Rect speaker = tester.getRect(find.byKey(const Key('speaker-body')));
        final Size size = _size[board]!;
        expect(
          Rect.fromLTWH(0, 0, size.width, size.height).contains(speaker.topLeft),
          isTrue,
          reason: board.name,
        );
        expect(
          Rect.fromLTWH(0, 0, size.width, size.height).contains(speaker.bottomRight),
          isTrue,
          reason: board.name,
        );
        final Rect firstTile = tester.getRect(find.byType(AnswerTile).first);
        expect(speaker.overlaps(firstTile), isFalse, reason: board.name);
      }
    });
  });

  group('the idle prompt', () {
    testWidgets('rings the speaker once, in the sky colour, and the caption bubble when there is one', (
      WidgetTester tester,
    ) async {
      await _pump(tester, BoardClass.phone, stage: PresentationStage.p2, captions: false, ring: true);
      expect(find.byKey(const Key('speaker-ring')), findsOneWidget);
      await _pump(tester, BoardClass.phone, stage: PresentationStage.p3, captions: true, ring: true);
      expect(find.byKey(const Key('bubble-ring')), findsOneWidget);
      await _pump(tester, BoardClass.phone, stage: PresentationStage.p3, captions: true, ring: false);
      expect(find.byKey(const Key('bubble-ring')), findsNothing);
    });

    for (final BoardClass board in BoardClass.values) {
      for (final PresentationStage stage in PresentationStage.values) {
        testWidgets('${board.name} ${stage.name}: the hand\'s fingertip is in the stage, never on a tile', (
          WidgetTester tester,
        ) async {
          await _pump(tester, board, stage: stage, hand: true, choices: StageSpec.of(stage).maxChoices);
          expect(find.byKey(const Key('idle-hand')), findsOneWidget);
          final ActivitySpec spec = StageSpec.of(stage)
              .applyTo(ActivitySpec.of(board), sizeClassFor(_size[board]!));
          final double inset = spec.stageIsCard ? 16 : 0;
          final Size room = spec.stageIsCard
              ? Size(spec.stage.width - 32, spec.stage.height - 32)
              : spec.stage.size;
          final Offset tip = Offset(spec.stage.left + inset, spec.stage.top + inset) + idleTarget(room);
          expect(spec.stage.contains(tip), isTrue, reason: 'the stage is $spec.stage, the tip $tip');
          for (final Element e in find.byType(AnswerTile).evaluate()) {
            expect(
              tester.getRect(find.byWidget(e.widget)).contains(tip),
              isFalse,
              reason: 'a tile is not where the hand points',
            );
          }
          expect(tester.takeException(), isNull);
        });
      }
    }
  });
}
