// M11 Stage 1 on the lesson screen (acceptance criteria 2, 3 and 4 of docs/milestones/M11.md): in every room the host appears and greets and
// cheers while the companion keeps its corner; the stage reacts when an item is solved, at any hint level, never before the answer and
// never on a wrong one; the reaction is not kept or counted; with "reduce motion" only its end state shows. The real lesson screen over the
// starter pack and the fixture course packs, with the rooms on.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nitznutz/content/models.dart';
import 'package:nitznutz/data/app_database.dart';
import 'package:nitznutz/design/trail_shape.dart';
import 'package:nitznutz/play/lesson_screen.dart';
import 'package:nitznutz/rooms/moments.dart' show cheerRepeatsPraise;
import 'package:nitznutz/rooms/room_spec.dart';
import 'package:nitznutz/strings/he.dart' show HostHe;

import 'support/app_harness.dart';
import 'support/harness.dart';
import 'support/l4_golden.dart' show waitFor;
import 'support/m11_rooms.dart';

const Size _phone = Size(852, 393);

/// The tile of the answer [id]: a land's is `tile-<id>`, a language course's `option-<id>`.
Finder _tile(String id) =>
    find.byWidgetPredicate((Widget w) => w.key == Key('tile-$id') || w.key == Key('option-$id'));

/// The pictures drawn by the landmark's layer: one (the landmark itself, always on the screen) at rest, two (and the room's end state) once the
/// stage has reacted.
Finder get _reactionArt =>
    find.descendant(of: find.byKey(const Key('stage-reaction')), matching: find.byType(SvgPicture));

/// The room's end state, drawn over the landmark only once the stage has reacted.
Finder get _reactedArt => find.descendant(
  of: find.byKey(const Key('stage-reaction')),
  matching: find.byWidgetPredicate((Widget w) => _isAsset(w, '_reacted.svg')),
);

bool _isAsset(Widget w, String name) =>
    w is SvgPicture &&
    w.bytesLoader is SvgAssetLoader &&
    (w.bytesLoader as SvgAssetLoader).assetName.endsWith(name);

Finder _asset(String name) => find.byWidgetPredicate((Widget w) => _isAsset(w, name));

Future<void> _endGreeting(WidgetTester tester) async {
  await tester.tapAt(const Offset(300, 330));
  await waitFor(tester, 600);
}

void main() {
  setUpAll(loadAppFonts);

  group('the host greets, and the companion keeps its corner (criterion 2)', () {
    for (final RoomId room in RoomId.values) {
      testWidgets(
        '${room.name}: the host greets in front of the companion, then goes, and the lesson goes on in the companion\'s corner',
        (WidgetTester tester) async {
          final (PackContent c, Lesson l) = await roomLesson(room);
          await openRoomLesson(tester, c, l, _phone);
          final String host = RoomSpec.byId(room).hostId;
          // The greeting: the host's line, the host in front, the companion behind it, no help, no stage content, no tiles.
          expect(find.byKey(const Key('room-host')), findsOneWidget);
          expect(find.byKey(const Key('activity-nitzi')), findsOneWidget, reason: 'the companion is there');
          expect(find.text(HostHe.greetings[host]!.text), findsOneWidget);
          expect(find.byKey(const Key('lesson-hint')), findsNothing);
          expect(find.byKey(const Key('lesson-show-me')), findsNothing);
          expect(find.byKey(const Key('lesson-mic')), findsNothing);
          expect(find.byKey(const Key('answer-tile')), findsNothing);
          expect(find.byKey(Key('room-backdrop-${room.name}')), findsOneWidget);
          final Rect hostBox = tester.getRect(find.byKey(const Key('room-host')));
          final Rect pal = tester.getRect(find.byKey(const Key('activity-nitzi')));
          expect(hostBox.size.width, greaterThan(pal.size.width), reason: 'the host is in front and larger');
          // A touch goes on to the first question, said by the companion from its own corner; the host has left.
          await _endGreeting(tester);
          expect(find.byKey(const Key('room-host')), findsNothing);
          expect(find.text(HostHe.greetings[host]!.text), findsNothing);
          expect(find.byKey(const Key('lesson-hint')), findsOneWidget);
          expect(find.byKey(const Key('lesson-bubble')), findsOneWidget);
          expect(
            tester.getRect(find.byKey(const Key('activity-nitzi'))).size.width,
            greaterThan(pal.size.width),
          );
        },
      );
    }

    testWidgets('the greeting ends by itself after three seconds, and a touch ends it at once', (
      WidgetTester tester,
    ) async {
      final (PackContent c, Lesson l) = await roomLesson(RoomId.shapes);
      await openRoomLesson(tester, c, l, _phone, wait: 400);
      expect(find.byKey(const Key('room-host')), findsOneWidget);
      await waitFor(tester, 2000);
      expect(
        find.byKey(const Key('room-host')),
        findsOneWidget,
        reason: 'it is still there after two seconds',
      );
      await waitFor(tester, 1500);
      expect(find.byKey(const Key('room-host')), findsNothing, reason: 'it has gone after three');
      expect(find.byKey(const Key('answer-tile')), findsWidgets);
    });

    testWidgets(
      'the host\'s name is announced once, at the greeting, and the landmark and the reaction are not announced at all',
      (WidgetTester tester) async {
        final SemanticsHandle handle = tester.ensureSemantics();
        final (PackContent c, Lesson l) = await roomLesson(RoomId.numbers);
        await openRoomLesson(tester, c, l, _phone);
        expect(find.bySemanticsLabel(HostHe.names['nekudi']!.text), findsOneWidget);
        await _endGreeting(tester);
        expect(find.bySemanticsLabel(HostHe.names['nekudi']!.text), findsNothing);
        await tester.tap(_tile(rightOption(c, l, 0)));
        await waitFor(tester, 400);
        expect(find.bySemanticsLabel('numbers landmark'), findsNothing);
        expect(find.bySemanticsLabel('numbers reacted'), findsNothing);
        handle.dispose();
      },
    );

    testWidgets(
      'the end of the lesson: the room\'s window, the host and the companion side by side, the praise and the host\'s cheer',
      (WidgetTester tester) async {
        final (PackContent c, Lesson l) = await roomLesson(RoomId.cs);
        await openRoomLesson(tester, c, l, _phone);
        await _endGreeting(tester);
        for (int i = 0; i < l.itemIds.length; i++) {
          await tester.tap(_tile(rightOption(c, l, i)));
          await waitFor(tester, 2600);
        }
        expect(find.byKey(const Key('lesson-celebration')), findsOneWidget);
        expect(find.byKey(const Key('room-celebration-window')), findsOneWidget);
        expect(find.byKey(const Key('room-celebration-host')), findsOneWidget);
        expect(
          find.byKey(const Key('lesson-cameo')),
          findsOneWidget,
          reason: 'the companion celebrates beside the host',
        );
        expect(find.text(HostHe.cheers['tzaadon']!.text), findsOneWidget, reason: 'the host\'s cheer');
        expect(
          find.byKey(const Key('room-celebration-praise')).evaluate().isNotEmpty,
          !cheerRepeatsPraise(l.celebration.caption, HostHe.cheers['tzaadon']!.text),
          reason: 'the companion\'s praise follows the cheer, unless it only says the same words again',
        );
        expect(
          find.byKey(const Key('room-celebration-piece')),
          findsOneWidget,
          reason: 'the landmark gains its piece',
        );
        expect(find.byKey(const Key('lesson-done')), findsOneWidget);
      },
    );

    /// The lesson of [room] with a celebration line made from the host's cheer by [caption], played to its end on the phone.
    Future<void> endWith(WidgetTester tester, RoomId room, String Function(String cheer) caption) async {
      final (PackContent c, Lesson l) = await roomLesson(room);
      final Lesson mine = Lesson.mission(
        id: l.id,
        itemIds: l.itemIds,
        skillIds: l.skillIds,
        celebration: Spoken(
          vo: l.celebration.vo,
          caption: caption(HostHe.cheers[RoomSpec.byId(room).hostId]!.text),
        ),
      );
      await openRoomLesson(tester, c, mine, _phone);
      await _endGreeting(tester);
      for (int i = 0; i < mine.itemIds.length; i++) {
        await tester.tap(_tile(rightOption(c, mine, i)));
        await waitFor(tester, 2600);
      }
      expect(find.byKey(const Key('lesson-celebration')), findsOneWidget);
    }

    // The first sentence of the cheer: the praise a lesson says on its own, which the host has just said.
    String firstSentence(String cheer) => cheer.split(RegExp(r'(?<=[!.?]) ')).first;

    for (final RoomId room in RoomId.values) {
      testWidgets('${room.name}: a praise the host\'s cheer already says is not said twice at the end', (
        WidgetTester tester,
      ) async {
        await endWith(tester, room, firstSentence);
        expect(find.byKey(const Key('room-celebration-cheer')), findsOneWidget);
        expect(
          find.byKey(const Key('room-celebration-praise')),
          findsNothing,
          reason: 'the companion does not repeat the words of the host\'s cheer',
        );
      });
    }

    testWidgets('a praise that says something else follows the host\'s cheer, under it', (
      WidgetTester tester,
    ) async {
      await endWith(tester, RoomId.numbers, (String _) => 'מְצֻיָּן, סִיַּמְתֶּם הַכֹּל!');
      final Finder cheer = find.byKey(const Key('room-celebration-cheer'));
      final Finder praise = find.byKey(const Key('room-celebration-praise'));
      expect(cheer, findsOneWidget);
      expect(praise, findsOneWidget);
      expect(
        tester.getTopLeft(cheer).dy,
        lessThan(tester.getTopLeft(praise).dy),
        reason: 'the host cheers first',
      );
    });

    testWidgets(
      'with the rooms off the lesson is as before: no host, the question first, the meadow behind the stage',
      (WidgetTester tester) async {
        final (PackContent c, Lesson l) = await roomLesson(RoomId.numbers);
        final AppRig rig = AppRig(content: c);
        await rig.seedFinishedSetup(name: 'נועה');
        await rig.pump(tester, size: _phone);
        await tester.tap(find.text('נועה'));
        await tester.pumpAndSettle();
        unawaited(
          tester
              .state<NavigatorState>(find.byType(Navigator).first)
              .push(
                MaterialPageRoute<void>(
                  builder: (BuildContext _) => LessonScreen(profileId: roomKid, mission: l),
                ),
              ),
        );
        await waitFor(tester, 800);
        expect(find.byKey(const Key('room-host')), findsNothing);
        expect(find.byKey(const Key('stage-reaction')), findsNothing);
        expect(find.byKey(const Key('room-backdrop-numbers')), findsNothing);
        expect(
          find.byKey(const Key('answer-tile')),
          findsWidgets,
          reason: 'the first screen is the first question',
        );
      },
    );
  });

  group('the stage reacts when an item is solved (criterion 3)', () {
    testWidgets(
      'never before the answer and never on a wrong one; at the first right answer the landmark shows its end state; the next item starts plain',
      (WidgetTester tester) async {
        final (PackContent c, Lesson l) = await roomLesson(RoomId.numbers);
        await openRoomLesson(tester, c, l, _phone);
        await _endGreeting(tester);
        expect(_reactionArt, findsOneWidget, reason: 'the landmark is on the screen at rest');
        expect(_reactedArt, findsNothing);
        await tester.tap(_tile(wrongOption(c, l, 0)));
        await waitFor(tester, 1500);
        expect(_reactedArt, findsNothing, reason: 'a wrong answer does not move the stage');
        await tester.tap(_tile(rightOption(c, l, 0)));
        await waitFor(tester, 300);
        expect(_reactionArt, findsNWidgets(2), reason: 'the landmark and the end state over it');
        expect(_asset('numbers_reacted.svg'), findsOneWidget);
        expect(_asset('numbers_landmark.svg'), findsOneWidget, reason: 'one landmark, in its own place');
        // The page turns: the next item starts with the plain landmark, and nothing is carried over.
        await waitFor(tester, 2500);
        expect(find.byKey(const Key('stage-reaction')), findsOneWidget);
        expect(_reactionArt, findsOneWidget);
        expect(_reactedArt, findsNothing);
      },
    );

    testWidgets(
      'at any hint level, and after a worked example: a right answer after help still reacts, once',
      (WidgetTester tester) async {
        final (PackContent c, Lesson l) = await roomLesson(RoomId.logic);
        final AppRig rig = await openRoomLesson(tester, c, l, _phone);
        await _endGreeting(tester);
        // Three mistakes take the help to the worked example; the answer is then the only move.
        final String wrong = wrongOption(c, l, 0);
        for (int i = 0; i < 3; i++) {
          await tester.tap(_tile(wrong));
          await waitFor(tester, 1800);
          expect(_reactedArt, findsNothing, reason: 'mistake ${i + 1}');
        }
        await waitFor(tester, 3000);
        await tester.tap(_tile(rightOption(c, l, 0)));
        await waitFor(tester, 300);
        expect(_reactionArt, findsNWidgets(2));
        final List<Attempt> rows = await rig.db.attemptsOf(roomKid);
        expect(rows.where((Attempt a) => a.result == 'correct'), hasLength(1));
        expect(
          rows.where((Attempt a) => a.result == 'incorrect'),
          hasLength(3),
          reason: 'the reaction writes nothing',
        );
      },
    );

    testWidgets('after the lamp\'s help (hint level 1) a right answer reacts too', (
      WidgetTester tester,
    ) async {
      final (PackContent c, Lesson l) = await roomLesson(RoomId.shapes);
      await openRoomLesson(tester, c, l, _phone);
      await _endGreeting(tester);
      await tester.tap(find.byKey(const Key('lesson-hint')));
      await waitFor(tester, 2500);
      expect(_reactedArt, findsNothing, reason: 'asking for help is not an answer');
      await tester.tap(_tile(rightOption(c, l, 0)));
      await waitFor(tester, 300);
      expect(_reactionArt, findsNWidgets(2));
    });

    testWidgets(
      'with motion: nothing for the 220 ms after the check, then a motion that ends in a still end state',
      (WidgetTester tester) async {
        final (PackContent c, Lesson l) = await roomLesson(RoomId.numbers);
        await openRoomLesson(tester, c, l, _phone, reduceMotion: false);
        await tester.tapAt(const Offset(300, 330));
        await tester.pump(const Duration(milliseconds: 700));
        await tester.pump(const Duration(milliseconds: 700));
        await tester.tap(_tile(rightOption(c, l, 0)));
        await tester.pump(const Duration(milliseconds: 100));
        expect(_reactedArt, findsNothing, reason: 'it waits for the check badge: 220 ms');
        await tester.pump(const Duration(milliseconds: 350));
        expect(_reactionArt, findsWidgets, reason: 'mid-motion: the landmark is raised');
        await tester.pump(const Duration(milliseconds: 900));
        expect(_reactionArt, findsNWidgets(2), reason: 'the end state stays');
        // The motion is over within 900 ms: what stays is the end state, nothing scaled and no glow.
        await tester.pump(const Duration(milliseconds: 400));
        for (final Element e
            in find
                .descendant(of: find.byKey(const Key('stage-reaction')), matching: find.byType(Transform))
                .evaluate()) {
          expect((e.widget as Transform).transform.getMaxScaleOnAxis(), closeTo(1, 0.0001));
        }
        expect(
          find.descendant(
            of: find.byKey(const Key('stage-reaction')),
            matching: find.byWidgetPredicate(
              (Widget w) =>
                  w is DecoratedBox &&
                  w.decoration is BoxDecoration &&
                  (w.decoration as BoxDecoration).gradient != null,
            ),
          ),
          findsNothing,
        );
      },
    );

    testWidgets('with reduce motion the end state appears with no movement: no scale, no glow', (
      WidgetTester tester,
    ) async {
      final (PackContent c, Lesson l) = await roomLesson(RoomId.cs);
      await openRoomLesson(tester, c, l, _phone);
      await _endGreeting(tester);
      await tester.tap(_tile(rightOption(c, l, 0)));
      await waitFor(tester, 300);
      final Finder scaled = find.descendant(
        of: find.byKey(const Key('stage-reaction')),
        matching: find.byType(Transform),
      );
      for (final Element e in scaled.evaluate()) {
        final Matrix4 m = (e.widget as Transform).transform;
        expect(m.getMaxScaleOnAxis(), closeTo(1, 0.0001), reason: 'nothing is scaled');
      }
      expect(
        find.descendant(
          of: find.byKey(const Key('stage-reaction')),
          matching: find.byWidgetPredicate(
            (Widget w) =>
                w is DecoratedBox &&
                w.decoration is BoxDecoration &&
                (w.decoration as BoxDecoration).gradient != null,
          ),
        ),
        findsNothing,
        reason: 'no glow either',
      );
    });

    for (final RoomId room in RoomId.values) {
      testWidgets('${room.name}: the end state is the room\'s own picture over its landmark', (
        WidgetTester tester,
      ) async {
        final (PackContent c, Lesson l) = await roomLesson(room);
        await openRoomLesson(tester, c, l, _phone);
        await _endGreeting(tester);
        expect(_reactedArt, findsNothing);
        await tester.tap(_tile(rightOption(c, l, 0)));
        await waitFor(tester, 300);
        expect(_asset('${room.name}_reacted.svg'), findsOneWidget);
        expect(
          find.descendant(
            of: find.byKey(const Key('stage-reaction')),
            matching: _asset('${room.name}_landmark.svg'),
          ),
          findsOneWidget,
        );
      });
    }
  });

  group('the rooms differ where they should', () {
    testWidgets(
      'Colour Bay is the most vivid room: the pink tint screen, its rim, and Goni in his resting mint (his own files, no colour mapping)',
      (WidgetTester tester) async {
        final (PackContent c, Lesson l) = await roomLesson(RoomId.colors);
        await openRoomLesson(tester, c, l, _phone);
        expect(_asset('goni_talk.svg'), findsOneWidget);
        expect(_asset('goni_idle.svg'), findsNothing);
        final SvgPicture goni = tester.widget<SvgPicture>(
          find.byWidgetPredicate((Widget w) => _isAsset(w, 'goni_talk.svg')),
        );
        expect(
          (goni.bytesLoader as SvgAssetLoader).colorMapper,
          isNull,
          reason: 'mint is the colours the file is drawn in',
        );
        final ColoredBox screen = tester
            .widgetList<ColoredBox>(find.byType(ColoredBox))
            .firstWhere((ColoredBox b) => b.color == RoomSpec.colors.screen);
        expect(screen.color, const Color(0xFFFCE1F0));
      },
    );

    testWidgets(
      'the landmark has its own place: in the header of a phone, beside the card on the landscape tablet; always drawn, standing alone',
      (WidgetTester tester) async {
        final (PackContent c, Lesson l) = await roomLesson(RoomId.numbers);
        await openRoomLesson(tester, c, l, _phone);
        final Rect header = tester.getRect(find.byKey(const Key('stage-reaction')));
        expect(header.size, const Size(64, 64));
        expect(
          header.top,
          lessThan(tester.getRect(find.byKey(const Key('lesson-stage'))).top),
          reason: 'above the stage',
        );
        expect(
          _asset('numbers_landmark.svg'),
          findsOneWidget,
          reason: 'standing at rest in its own place, not in the stage backdrop',
        );
        await tester.pumpWidget(const SizedBox.shrink());
        await openRoomLesson(tester, c, l, const Size(1180, 820));
        await _endGreeting(tester);
        final Rect card = tester.getRect(find.byKey(const Key('lesson-stage')));
        final Rect landmark = tester.getRect(find.byKey(const Key('stage-reaction')));
        expect(landmark.right, lessThan(card.left), reason: 'in the empty column beside the card');
        expect(landmark.size, const Size(150, 150));
        expect(
          find.descendant(
            of: find.byKey(const Key('stage-reaction')),
            matching: _asset('numbers_landmark.svg'),
          ),
          findsOneWidget,
          reason: 'standing on the ground at rest',
        );
      },
    );

    testWidgets(
      'the sockets of the trail take the room shape, one per item, and the first fills when the first item is solved',
      (WidgetTester tester) async {
        final (PackContent c, Lesson l) = await roomLesson(RoomId.math);
        await openRoomLesson(tester, c, l, _phone);
        await _endGreeting(tester);
        final Finder sockets = find.byWidgetPredicate(
          (Widget w) => w is CustomPaint && w.painter.runtimeType.toString() == '_SocketPainter',
        );
        dynamic painter(int i) => (sockets.evaluate().elementAt(i).widget as CustomPaint).painter;
        bool done(int i) => painter(i).done as bool;
        expect(sockets, findsNWidgets(l.itemIds.length));
        expect(
          <TrailShape>{for (int i = 0; i < l.itemIds.length; i++) painter(i).shape as TrailShape},
          <TrailShape>{TrailShape.orange},
        );
        expect(<bool>[for (int i = 0; i < l.itemIds.length; i++) done(i)], <bool>[false, false, false]);
        await tester.tap(_tile(rightOption(c, l, 0)));
        await waitFor(tester, 2600);
        // The trail fills from the start side (the right in Hebrew): the first socket in the row is the first item.
        expect(<bool>[for (int i = 0; i < l.itemIds.length; i++) done(i)], <bool>[true, false, false]);
      },
    );
  });
}
