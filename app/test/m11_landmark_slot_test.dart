// M11 Stage 1, QA defect D1 (the stage's reaction was not visible): the room's landmark has a place of its own on every board and for every
// layout of the stage the templates use, and nothing else is in it. These are the layout rules, without a screen: for the four boards and
// every board layout of `choice_row.dart` and the robot's, the place is on the board, at least the least size, clear of the stage, the answer
// tiles, the header's buttons (with their tap margins), the trail, the bubble's column, the guide and the host pair and the microphone.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nitznutz/child/activity_shell.dart';
import 'package:nitznutz/design/board.dart';
import 'package:nitznutz/design/token_types.dart' show Band;
import 'package:nitznutz/play/choice_row.dart';
import 'package:nitznutz/play/robot_path_session.dart' show RobotPathSession;
import 'package:nitznutz/rooms/host_places.dart';
import 'package:nitznutz/rooms/landmark_slot.dart';

/// Every layout a template gives the board (the functions `TemplateSession.layoutFor` calls), for [board].
List<(String, ActivitySpec)> _layouts(BoardClass board) {
  final ActivitySpec base = ActivitySpec.of(board);
  return <(String, ActivitySpec)>[
    ('the board', base),
    ('speaker room', withSpeakerRoom(base)),
    ('side speakers', withSideSpeakers(base)),
    for (final Band band in Band.values)
      for (final bool wide in <bool>[false, true])
        for (final bool second in <bool>[false, true])
          ('ls01 $band wide $wide second $second', withLs01Zones(base, band, wide: wide, secondRow: second)),
    ('tall stage', withTallStage(base)),
    ('meet', withMeetStage(base)),
    ('picture stage', withPictureStage(base)),
    ('stage at least 200', withStageAtLeast(base, 200, tilesBox: 120)),
    ('wide stage', withWideStage(base)),
    ('robot', RobotPathSession.laidOut(base)),
  ];
}

/// What the landmark must keep clear of on [board] in layout [s], listed on its own (not read back from the implementation).
Map<String, Rect> _others(BoardClass board, ActivitySpec s) {
  final HostPlaces pair = HostPlaces.of(board);
  const double pebble = 64;
  const double slop = 12;
  final double rim = s.stageIsCard ? 6 : 4;
  return <String, Rect>{
    'eye': Rect.fromLTWH(s.eyeLeft, s.controlsTop, pebble, pebble).inflate(slop),
    'lamp': Rect.fromLTWH(s.hintLeft, s.controlsTop, pebble, pebble).inflate(slop),
    'home': Rect.fromLTWH(
      board.size.width - s.homeRight - pebble,
      s.controlsTop,
      pebble,
      pebble,
    ).inflate(slop),
    'stage': s.stage.inflate(rim),
    'tiles': Rect.fromLTWH(s.tilesLeft, s.tilesTop - s.tileSlop, s.tilesWidth, s.tileHeight + 2 * s.tileSlop),
    'guide': Rect.fromLTWH(s.nitziLeft, s.nitziTop, s.nitziSize, s.nitziSize),
    'host': pair.front,
    'companion behind the host': pair.back,
    'microphone': Rect.fromLTWH(s.micLeft, s.micTop, s.micSize, s.micSize),
  };
}

void main() {
  group('the landmark\'s place: on the board, big enough, and alone', () {
    for (final BoardClass board in BoardClass.values) {
      test('${board.name}: every layout of the templates leaves it a place clear of everything', () {
        final Rect screen = Offset.zero & board.size;
        for (final (String name, ActivitySpec s) in _layouts(board)) {
          final LandmarkPlace place = LandmarkSlot.of(board, s);
          final String what = '${board.name}, $name';
          expect(
            screen.contains(place.box.topLeft) && screen.contains(place.box.bottomRight),
            isTrue,
            reason: '$what: on the board $place',
          );
          expect(
            place.box.shortestSide,
            greaterThanOrEqualTo(LandmarkSlot.least),
            reason: '$what: at least ${LandmarkSlot.least}',
          );
          expect(place.box.width, place.box.height, reason: '$what: square');
          _others(board, s).forEach((String other, Rect r) {
            expect(
              r.overlaps(place.box),
              isFalse,
              reason: '$what: the landmark ${place.box} is over the $other $r',
            );
          });
          if (place.inHeader) {
            // The trail, shortened by the landmark's room, ends clear of it; the buttons are level with it.
            final double trailEnd = s
                .trailRoom(board.size.width, endReserve: LandmarkSlot.reserve(place.box))
                .right;
            expect(
              trailEnd,
              lessThanOrEqualTo(place.box.left - ActivitySpec.trailClear + 0.001),
              reason: '$what: the trail ends before the landmark',
            );
            expect(place.box.top, lessThanOrEqualTo(s.controlsTop), reason: '$what: level with the header');
          }
        }
      });
    }

    test('a phone has it in the header, as tall as the buttons (the small phone 56); a tablet has it big, beside the card or down the margin', () {
      expect(LandmarkSlot.of(BoardClass.phone, ActivitySpec.phone).box.size, const Size(64, 64));
      expect(LandmarkSlot.of(BoardClass.phoneSE, ActivitySpec.phoneSE).box.size, const Size(56, 56));
      final LandmarkPlace landscape = LandmarkSlot.of(
        BoardClass.tabletLandscape,
        ActivitySpec.tabletLandscape,
      );
      expect(landscape.inHeader, isFalse);
      expect(landscape.box.size, const Size(150, 150));
      expect(
        landscape.box.right,
        lessThan(ActivitySpec.tabletLandscape.stage.left),
        reason: 'in the empty column beside the card',
      );
      expect(
        landscape.box.bottom,
        closeTo(ActivitySpec.tabletLandscape.stage.bottom + LandmarkSlot.gap, 0.01),
        reason: 'standing on the card\'s bottom line',
      );
      final LandmarkPlace portrait = LandmarkSlot.of(BoardClass.tabletPortrait, ActivitySpec.tabletPortrait);
      expect(portrait.inHeader, isFalse);
      expect(portrait.box.size, const Size(118, 118));
    });

    test('a wide card on the landscape tablet takes the column away: the landmark is smaller and stands down the margin, under the tiles', () {
      final ActivitySpec wide = withWideStage(ActivitySpec.tabletLandscape);
      final LandmarkPlace place = LandmarkSlot.of(BoardClass.tabletLandscape, wide);
      expect(place.inHeader, isFalse);
      expect(place.box.size.width, lessThan(150));
      expect(place.box.size.width, greaterThanOrEqualTo(80));
      expect(place.box.left, LandmarkSlot.margin);
      expect(place.box.top, greaterThan(wide.tilesTop + wide.tileHeight), reason: 'under the tiles');
    });

    test(
      'the place does not depend on the line in the bubble or on a host: it is the same for the same layout',
      () {
        for (final BoardClass board in BoardClass.values) {
          final ActivitySpec s = ActivitySpec.of(board);
          expect(LandmarkSlot.of(board, s), LandmarkSlot.of(board, s.forHostBeat(HostPlaces.of(board))));
        }
      },
    );
  });
}
