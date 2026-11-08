// B-29 step 6: the stage token group and what it makes of a board. The numbers are the design-director's table (docs/design/b29-steps5-6.md
// section 6.2); the room checks of that section are run here for every stage on every board, so a change to a token that breaks the fit fails.
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nitznutz/child/activity_shell.dart';
import 'package:nitznutz/design/board.dart';
import 'package:nitznutz/design/layout.dart';
import 'package:nitznutz/design/stage_spec.dart';
import 'package:nitznutz/design/tokens.g.dart';
import 'package:nitznutz/engine/age.dart' show PresentationStage;
import 'package:nitznutz/engine/presentation.dart' show maxChoicesByStage;

const Map<BoardClass, SizeClass> _classOf = <BoardClass, SizeClass>{
  BoardClass.phone: SizeClass.phone,
  BoardClass.phoneSE: SizeClass.phoneSE,
  BoardClass.tabletLandscape: SizeClass.tablet,
  BoardClass.tabletPortrait: SizeClass.tablet,
};

void main() {
  StageSpec of(PresentationStage s) => StageSpec.of(s);

  group('the numbers of the table (section 6.2)', () {
    test('answer choices, at most', () {
      expect(
        <int>[for (final PresentationStage s in PresentationStage.values) of(s).maxChoices],
        <int>[3, 3, 4, 5],
      );
      expect(maxChoicesByStage, <int>[3, 3, 4, 5], reason: 'the engine\'s cap and the token agree');
    });

    test('tile, gap and hit slop, phone and tablet', () {
      expect(
        <double>[for (final s in PresentationStage.values) of(s).tile(SizeClass.phone)],
        <double>[96, 96, 88, 80],
      );
      expect(
        <double>[for (final s in PresentationStage.values) of(s).tile(SizeClass.tablet)],
        <double>[112, 112, 104, 96],
      );
      expect(
        <double>[for (final s in PresentationStage.values) of(s).gap(SizeClass.phone)],
        <double>[32, 32, 24, 20],
      );
      expect(
        <double>[for (final s in PresentationStage.values) of(s).gap(SizeClass.tablet)],
        <double>[32, 32, 24, 16],
      );
      expect(
        <double>[for (final s in PresentationStage.values) of(s).slop(SizeClass.phone)],
        <double>[16, 16, 12, 10],
      );
      expect(
        <double>[for (final s in PresentationStage.values) of(s).slop(SizeClass.tablet)],
        <double>[16, 16, 12, 8],
      );
    });

    test('the gap is twice the slop, so a row of tiles that each carry the slop has exactly that gap', () {
      for (final PresentationStage s in PresentationStage.values) {
        for (final SizeClass c in <SizeClass>[SizeClass.phone, SizeClass.tablet]) {
          expect(of(s).gap(c), 2 * of(s).slop(c), reason: '${s.name} $c');
        }
      }
    });

    test('hit area on a phone: 128 for P1 and P2 (2 cm), 112 for P3, 100 for P4', () {
      expect(
        <double>[for (final s in PresentationStage.values) of(s).hitArea(SizeClass.phone)],
        <double>[128, 128, 112, 100],
      );
      expect(
        of(PresentationStage.p1).hitArea(SizeClass.phone),
        greaterThanOrEqualTo(126),
        reason: '2 cm at 160 dpi is 126 points',
      );
    });

    test('numeral and caption sizes', () {
      expect(
        <double>[for (final s in PresentationStage.values) of(s).numeral(SizeClass.phone)],
        <double>[56, 56, 48, 40],
      );
      expect(
        <double>[for (final s in PresentationStage.values) of(s).numeral(SizeClass.tablet)],
        <double>[72, 72, 64, 56],
      );
      expect(
        <double>[for (final s in PresentationStage.values) of(s).caption(SizeClass.phone)],
        <double>[26, 26, 24, 22],
      );
      expect(
        <double>[for (final s in PresentationStage.values) of(s).caption(SizeClass.phoneSE)],
        <double>[24, 24, 22, 20],
      );
      expect(
        <double>[for (final s in PresentationStage.values) of(s).caption(SizeClass.tablet)],
        <double>[32, 32, 30, 28],
      );
      for (final PresentationStage s in PresentationStage.values) {
        for (final SizeClass c in SizeClass.values) {
          expect(of(s).captionFloor(c), of(s).caption(c) - 2, reason: 'the floor is the size less two');
        }
      }
    });

    test('the speaker bubble is 64 on a phone and 72 on a tablet at every stage', () {
      for (final PresentationStage s in PresentationStage.values) {
        expect(of(s).speaker(SizeClass.phone), 64);
        expect(of(s).speaker(SizeClass.phoneSE), 64);
        expect(of(s).speaker(SizeClass.tablet), 72);
      }
    });

    test('the idle ladder, in seconds', () {
      expect(
        <int>[for (int i = 0; i < 4; i++) of(PresentationStage.p1).idle(i).inSeconds],
        <int>[8, 15, 30, 120],
      );
      expect(
        <int>[for (int i = 0; i < 4; i++) of(PresentationStage.p3).idle(i).inSeconds],
        <int>[12, 25, 45, 120],
      );
      expect(
        <int>[for (int i = 0; i < 4; i++) of(PresentationStage.p4).idle(i).inSeconds],
        <int>[20, 40, 60, 120],
      );
    });

    test('motion, celebrations and things moving at once (D6): the oldest get older pacing', () {
      expect(of(PresentationStage.p1).transition.inMilliseconds, 450);
      expect(of(PresentationStage.p3).transition.inMilliseconds, 350);
      expect(of(PresentationStage.p4).transition.inMilliseconds, 280);
      expect(
        <double>[for (final s in PresentationStage.values) of(s).overshoot],
        <double>[1.12, 1.12, 1.08, 1.04],
      );
      expect(
        <int>[for (final s in PresentationStage.values) of(s).tier1.inMilliseconds],
        <int>[800, 800, 700, 500],
      );
      expect(
        <int>[for (final s in PresentationStage.values) of(s).tier2.inMilliseconds],
        <int>[3000, 3000, 2500, 2000],
      );
      expect(of(PresentationStage.p4).tier2SkipAfter, Duration.zero, reason: 'a tap skips it at once');
      expect(of(PresentationStage.p2).tier2SkipAfter.inMilliseconds, 1500);
      expect(<int>[for (final s in PresentationStage.values) of(s).focal], <int>[1, 1, 1, 2]);
    });

    test('the praise pause is the tier-1 celebration and 800 ms: 1,600 as it has been for P1 and P2, then shorter', () {
      expect(
        <int>[for (final s in PresentationStage.values) of(s).praise.inMilliseconds],
        <int>[1600, 1600, 1500, 1300],
      );
    });

    test('land signs: 18 to 15 for the youngest, 20 to 17 and 22 to 19 for the older ones; the "+" pebble 64 or 56', () {
      expect(of(PresentationStage.p2).sign(SizeClass.phone), (size: 18.0, least: 15.0));
      expect(of(PresentationStage.p3).sign(SizeClass.phone), (size: 20.0, least: 17.0));
      expect(of(PresentationStage.p4).sign(SizeClass.tablet), (size: 22.0, least: 19.0));
      expect(<double>[for (final s in PresentationStage.values) of(s).plusPebble], <double>[64, 64, 56, 56]);
    });
  });

  group('the fit, on every board and stage (section 6.2, "checks done on the numbers")', () {
    for (final BoardClass board in BoardClass.values) {
      for (final PresentationStage stage in PresentationStage.values) {
        test('${board.name} ${stage.name}', () {
          final SizeClass c = _classOf[board]!;
          final StageSpec s = of(stage);
          final ActivitySpec base = ActivitySpec.of(board);
          final ActivitySpec look = s.applyTo(base, c);
          // The look's numbers reach the board's spec.
          expect(look.tileSize, s.tile(c));
          expect(look.tileSlop, s.slop(c));
          expect(look.tileFont, s.numeral(c));
          expect(look.bubbleFont, s.caption(c));
          expect(look.tileHeight, s.tile(c), reason: 'a plain tile is as tall as it is wide');
          // Room: the most choices in a row fit the board's tile box, by their drawn size and gap.
          final int n = s.maxChoices;
          final double row = n * s.tile(c) + (n - 1) * s.gap(c);
          expect(
            row,
            lessThanOrEqualTo(base.tilesWidth),
            reason: '$n tiles need $row, the board has ${base.tilesWidth}',
          );
          // The bottom band: the lowest hit edge stays above the 24 points where no touch area may be.
          final double lowest = look.tilesTop + s.tile(c) + s.slop(c);
          expect(
            lowest,
            lessThanOrEqualTo(base.boardHeight - TokenTouch.bottomNoHotspot),
            reason: 'lowest hit edge $lowest',
          );
          // The stage: a hit area never reaches into it (its top is at or under the stage's bottom edge, a card's lip included).
          final double lip = base.stageIsCard ? 6 : 0;
          expect(
            look.tilesTop - s.slop(c),
            greaterThanOrEqualTo(base.stage.bottom + lip),
            reason: 'top of the hit area',
          );
        });
      }
    }
  });

  test('a layout with its own tile height keeps it (blocks), the plain tile takes the stage\'s', () {
    final ActivitySpec tall = ActivitySpec.phone.withStageAndTiles(
      stage: ActivitySpec.phone.stage,
      tilesLeft: 71,
      tilesTop: 244,
      tilesWidth: 534,
      tileHeight: 140,
    );
    expect(of(PresentationStage.p3).applyTo(tall, SizeClass.phone).tileHeight, 140);
    expect(of(PresentationStage.p3).applyTo(ActivitySpec.phone, SizeClass.phone).tileHeight, 88);
  });

  test('without a look the board is the one it has always been (96 and 12)', () {
    expect(ActivitySpec.phone.tileSize, 96);
    expect(ActivitySpec.phone.tileSlop, 12);
    expect(ActivitySpec.tabletLandscape.tileSize, 96);
  });

  testWidgets('StageScope is found below it and by nothing above it', (WidgetTester tester) async {
    StageScope? inside;
    StageScope? outside;
    await tester.pumpWidget(
      Builder(
        builder: (BuildContext c) {
          outside = StageScope.maybeOf(c);
          return StageScope(
            stage: of(PresentationStage.p3),
            captionsShown: false,
            child: Builder(
              builder: (BuildContext c2) {
                inside = StageScope.maybeOf(c2);
                return const SizedBox();
              },
            ),
          );
        },
      ),
    );
    expect(outside, isNull);
    expect(inside!.stage.stage, PresentationStage.p3);
    expect(inside!.captionsShown, isFalse);
  });
}
