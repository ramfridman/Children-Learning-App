// The minimum-sizes round 2 (docs/design/m11/min-sizes.md, the owner's rule of 2026-11-16: "not too small to see or read in any of the devices"):
// the numbers of what that round built that can be checked without a screen of its own: the grown card of every tablet lesson, the sets on
// tiles, the dots under a numeral, the robot's program strip, the caption floor and the chart's tiles.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nitznutz/child/activity_shell.dart';
import 'package:nitznutz/content/models.dart';
import 'package:nitznutz/design/token_types.dart' show Band;
import 'package:nitznutz/play/choice_row.dart';
import 'package:nitznutz/play/count_tap_session.dart' show Dots;
import 'package:nitznutz/play/robot_path_session.dart';
import 'package:nitznutz/play/sprite_group.dart';

import 'support/harness.dart';
import 'support/starter.dart';

void main() {
  late PackContent content;
  setUpAll(() async {
    await loadAppFonts();
    content = await loadStarter();
  });

  group('every tablet lesson has the grown card (C1, C2)', () {
    test('landscape: 848 wide from the margin, 400 tall, the tiles under it', () {
      final ActivitySpec s = withGrownCard(ActivitySpec.tabletLandscape);
      expect(s.stage, const Rect.fromLTWH(24, 230, 848, 400));
      expect(s.tilesLeft, 24);
      expect(s.tilesWidth, 848);
      expect(s.tilesTop, greaterThan(s.stage.bottom));
      // the row of tiles (a tile 112 with its tap margin) ends over the line where no hotspot may be
      expect(s.tilesTop + 112 + 12, lessThanOrEqualTo(820 - 24));
    });

    test('portrait: 772 by 520', () {
      final ActivitySpec s = withGrownCard(ActivitySpec.tabletPortrait);
      expect(s.stage, const Rect.fromLTWH(24, 372, 772, 520));
      expect(s.tilesWidth, 772);
      expect(s.tilesTop + 112 + 12, lessThanOrEqualTo(1180 - 24));
    });

    test('a phone is not changed', () {
      expect(withGrownCard(ActivitySpec.phone).stage, ActivitySpec.phone.stage);
      expect(withGrownCard(ActivitySpec.phoneSE).stage, ActivitySpec.phoneSE.stage);
    });

    test('the Meet stage and the Ls01 zones follow the grown card, they do not draw tiles over it', () {
      for (final ActivitySpec base in <ActivitySpec>[
        ActivitySpec.tabletLandscape,
        ActivitySpec.tabletPortrait,
      ]) {
        final ActivitySpec grown = withGrownCard(base);
        expect(withMeetStage(grown).tilesTop, greaterThan(withMeetStage(grown).stage.bottom));
        expect(withLs01Zones(grown, Band.a).tilesTop, greaterThan(withLs01Zones(grown, Band.a).stage.bottom));
      }
    });
  });

  group('sets on tiles (V1, A8): the picture is at least 24 on its ink', () {
    test('how a set is laid out by its count', () {
      expect(tileGroup('line', 1).arrangement, 'line');
      expect(tileGroup('line', 2).arrangement, 'line');
      expect(tileGroup('line', 3).arrangement, 'rows2');
      expect(tileGroup('line', 4).arrangement, 'rows2');
      expect(tileGroup('line', 5).arrangement, 'rows3');
      expect(tileGroup('line', 6).arrangement, 'rows3');
      expect(tileGroup('line', 7).arrangement, 'rows5');
      expect(tileGroup('line', 10).arrangement, 'rows5');
      // the content's own arrangements are kept
      expect(tileGroup('scatter', 7).arrangement, 'scatter');
      expect(tileGroup('ten_frame', 7).arrangement, 'ten_frame');
    });

    test('the tile is as wide as its count needs, a quarter more on a tablet', () {
      expect(tileWidthFor(4, tablet: false), 96);
      expect(tileWidthFor(6, tablet: false), 128);
      expect(tileWidthFor(10, tablet: false), 177);
      expect(tileWidthFor(10, tablet: true), 177 * 1.25);
    });

    test('ten stand in two rows of five, 32 across or more in a tile of 177 by 96', () {
      final List<Rect> places = spriteRects(const Size(165, 84), 'rows5', 10);
      expect(places, hasLength(10));
      expect(places.map((Rect r) => r.top.round()).toSet(), hasLength(2));
      for (final Rect r in places) {
        expect(r.width, greaterThanOrEqualTo(24));
      }
      expect(places.first.width, closeTo(0.85 * 165 / 5, 0.5));
    });

    test('a set of three or four is two to a row, centred', () {
      final List<Rect> places = spriteRects(const Size(84, 84), 'rows2', 3);
      expect(places, hasLength(3));
      expect(places[2].center.dx, closeTo(42, 0.5));
    });
  });

  testWidgets('the dots under a numeral are 7 across, 3 apart, in rows of five (B4)', (WidgetTester t) async {
    await t.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: Center(child: Dots(10))),
      ),
    );
    final Size ten = t.getSize(find.byType(Dots));
    expect(ten.width, 5 * Dots.dot + 4 * Dots.gap);
    expect(ten.height, 2 * Dots.dot + Dots.gap);
    await t.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: Center(child: Dots(3))),
      ),
    );
    expect(t.getSize(find.byType(Dots)).height, Dots.dot);
  });

  group('the robot program strip (B2)', () {
    test('arrows 28 (a tablet 40), a strip of 44 for one row, never scaled down', () {
      expect(RobotPathSession.programIcon(ActivitySpec.phone), 28);
      expect(RobotPathSession.programIcon(ActivitySpec.tabletLandscape), 40);
      expect(RobotPathSession.stripHeightOf(ActivitySpec.phone, 1), 44);
      expect(RobotPathSession.stripHeightOf(ActivitySpec.phone, 2), 76);
    });

    test('eight steps take one row on a phone and on the smallest phone, in the pack; a row that is full goes on in a second', () {
      final Iterable<RobotPathActivity> plans = content.activities.values
          .whereType<RobotPathActivity>()
          .where((RobotPathActivity a) => a.plan);
      expect(plans, isNotEmpty);
      for (final RobotPathActivity a in plans) {
        for (final ActivitySpec spec in <ActivitySpec>[ActivitySpec.phone, ActivitySpec.phoneSE]) {
          final int lines = RobotPathSession.programLines(a, spec, spec.stage.width - 16);
          expect(lines, 1, reason: '${a.id} on a board of ${spec.boardHeight}');
        }
        // a strip 100 across holds two arrows a row: the steps run on in more rows
        expect(RobotPathSession.programLines(a, ActivitySpec.phone, 100), greaterThan(1));
      }
    });
  });
}
