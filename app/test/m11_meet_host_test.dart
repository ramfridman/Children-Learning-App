// The Meet screen with its course host (docs/design/m11-rooms.md section 6, the 11 points), in the three language rooms: Pip (English), Alfi
// the hyrax (Hebrew) and Gosha the giraffe (Russian) introduce the new words, the companion stands behind them listening and keeps the
// microphone's feedback; the teaching rules of L7 are the same with or without the host. One group per point; the last group is "rooms off":
// the Meet is as it was.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nitznutz/characters/character.dart' show CharacterState;
import 'package:nitznutz/child/companion_views.dart' show SpeakingCharacter;
import 'package:nitznutz/content/models.dart';
import 'package:nitznutz/design/components.dart';
import 'package:nitznutz/design/course_text.dart' show TargetChip;
import 'package:nitznutz/design/trail_shape.dart';
import 'package:nitznutz/play/activity_frame.dart';
import 'package:nitznutz/play/hint_hand.dart' show HintHand;
import 'package:nitznutz/play/speaking_badge.dart';
import 'package:nitznutz/rooms/host_hello.dart';
import 'package:nitznutz/rooms/host_places.dart';
import 'package:nitznutz/rooms/host_view.dart';
import 'package:nitznutz/strings/he.dart' show HostHe;

import 'support/fake_speech.dart';
import 'support/harness.dart';
import 'support/l7_rig.dart';

typedef _Course = ({String course, String lesson, String host, bool story, TrailShape trail});

const _Course _eng = (
  course: 'eng',
  lesson: 'eng.greet-1',
  host: 'host_eng',
  story: false,
  trail: TrailShape.porthole,
);
const _Course _rus = (
  course: 'rus',
  lesson: 'rus.family-1',
  host: 'host_rus',
  story: false,
  trail: TrailShape.square,
);
const _Course _heb = (
  course: 'heb',
  lesson: 'heb.words-1',
  host: 'host_heb',
  story: true,
  trail: TrailShape.arch,
);

const Size _phone = Size(852, 393);
const Key _host = Key('room-host');
const Key _tile = Key('say-done');
const Key _mic = Key('lesson-mic');

ActivityFrame _frame(WidgetTester t) => t.widget<ActivityFrame>(find.byType(ActivityFrame));

HostPose _pose(WidgetTester t) => (_frame(t).scene!.hostView as HostView).pose;

CharacterState _companionPose(WidgetTester t) =>
    t.widget<SpeakingCharacter>(find.byType(SpeakingCharacter)).resting;

Rect _rect(WidgetTester t, Key k) => t.getRect(find.byKey(k));

/// The host's "together" line of [host] (text), and its clip as the fake voice names it.
String _line(String host) => HostHe.togethers[host]!.text;

/// The companion's own clip of the same sentence (`f03`) in the first Meet screen of [c]'s lesson, as the fake voice names it.
String _ownClip(Map<String, PackContent> packs, _Course c) {
  final PackContent pack = packs[c.course]!;
  final Activity first = pack
      .itemsFor(pack.lessons[c.lesson]!, route: 'new')
      .firstWhere((Activity a) => a is SayItActivity && a.meetScreen);
  return (first as SayItActivity).together.vo.substring('vo:'.length);
}

String _hostClip(String host) => HostHe.clip(host, 'together').substring('vo:'.length);

Future<void> _until(WidgetTester t, bool Function() done, {int maxMs = 15000}) async {
  for (int i = 0; i < maxMs ~/ 100 && !done(); i++) {
    await t.pump(const Duration(milliseconds: 100));
  }
  expect(done(), isTrue, reason: 'reached within ${maxMs ~/ 1000} s');
}

/// Turns the pages of the Hebrew lesson's story (the host's greeting comes first), after which its first Meet page follows.
Future<void> _passStory(WidgetTester t) async {
  await _until(t, () => find.byKey(const Key('story-turn')).evaluate().isNotEmpty);
  await l7Wait(t, 600);
  for (int i = 0; i < 5; i++) {
    await t.tap(find.byKey(const Key('story-turn')));
    await l7Wait(t, 300);
  }
  await l7Wait(t, 2500);
}

Future<void> _atMeet(WidgetTester t, _Course c) async {
  if (c.story) await _passStory(t);
  await _until(t, () => find.byKey(const Key('say-picture')).evaluate().isNotEmpty);
}

Future<void> _atTogether(WidgetTester t, _Course c) async {
  await _atMeet(t, c);
  await _until(t, () => find.text(_line(c.host)).evaluate().isNotEmpty);
  await l7Wait(t, 500);
}

void main() {
  late Map<String, PackContent> packs;

  setUpAll(() async {
    await loadAppFonts();
    packs = <String, PackContent>{
      for (final String c in <String>['eng', 'rus', 'heb']) c: await buildCourse(c),
    };
  });

  Future<L7Rig> open(
    WidgetTester t,
    _Course c, {
    Size size = _phone,
    int band = 1,
    bool voice = false,
    List<Scripted> script = const <Scripted>[],
    bool reduceMotion = true,
    bool lettersOpen = false,
    bool rooms = true,
    Set<String> extraRefs = const <String>{},
  }) => openCourseLesson(
    t,
    c.course,
    packs[c.course]!,
    lesson: c.lesson,
    size: size,
    band: band,
    voice: voice,
    script: script,
    reduceMotion: reduceMotion,
    lettersOpen: lettersOpen,
    pastOpener: false,
    rooms: rooms,
    extraRefs: extraRefs,
  );

  // ---- point 1: the speaker of the beats is the course host, in front; the companion behind it, listening ----
  group('point 1: the host speaks the beats, the companion listens behind it', () {
    for (final _Course c in <_Course>[_eng, _rus, _heb]) {
      testWidgets('${c.course}: the host in front at its place, the companion in the back place, in listen', (
        WidgetTester t,
      ) async {
        await open(t, c);
        await _atTogether(t, c);
        final HostPlaces p = HostPlaces.phone;
        expect(_frame(t).scene!.hostBeat, isTrue);
        expect(_frame(t).scene!.companionSpeaks, isFalse);
        expect(_rect(t, _host), p.front, reason: 'the host stands in front');
        expect(_rect(t, const Key('activity-nitzi')), p.back, reason: 'the companion in the back place');
        expect(_companionPose(t), CharacterState.listen);
        expect(_frame(t).scene!.hostView, isA<HostView>());
        expect(((_frame(t).scene!.hostView) as HostView).host.id, c.host);
      });
    }

    testWidgets(
      'the host\'s poses follow the beats: talk at its lines, show while the word is said, still at the child\'s turn',
      (WidgetTester t) async {
        await open(t, _eng);
        final List<HostPose> seen = <HostPose>[];
        for (int i = 0; i < 140; i++) {
          await t.pump(const Duration(milliseconds: 100));
          if (find.byKey(const Key('say-picture')).evaluate().isEmpty) continue;
          final HostPose now = _pose(t);
          if (seen.isEmpty || seen.last != now) seen.add(now);
        }
        expect(seen.take(6).toList(), <HostPose>[
          HostPose.talk,
          HostPose.show,
          HostPose.talk,
          HostPose.show,
          HostPose.talk,
          HostPose.idle,
        ], reason: 'opener, the word, its meaning, the word, "together", then the child\'s turn');
        expect(seen, isNot(contains(HostPose.celebrate)));
      },
    );

    testWidgets('the companion\'s mouth stays still while the host speaks (the host has the voice)', (
      WidgetTester t,
    ) async {
      await open(t, _eng);
      await _atTogether(t, _eng);
      expect(t.widget<SpeakingCharacter>(find.byType(SpeakingCharacter)).voiceOf, 'host');
    });

    testWidgets('the host\'s name is read once, at the greeting, not on every Meet screen', (
      WidgetTester t,
    ) async {
      final SemanticsHandle h = t.ensureSemantics();
      await open(t, _eng);
      await l7Wait(t, 300);
      expect(
        find.bySemanticsLabel(HostHe.names['host_eng']!.text),
        findsOneWidget,
        reason: 'at the greeting',
      );
      await _atMeet(t, _eng);
      expect(find.bySemanticsLabel(HostHe.names['host_eng']!.text), findsNothing);
      h.dispose();
    });
  });

  // ---- point 2: M4 "let's say it together" is the host's line ----
  group('point 2: "let\'s say it together" is the host\'s line', () {
    for (final _Course c in <_Course>[_eng, _rus, _heb]) {
      testWidgets(
        '${c.course}: its text in the bubble, the companion\'s clip of the same sentence until the host is voiced',
        (WidgetTester t) async {
          final L7Rig r = await open(t, c);
          await _atTogether(t, c);
          expect(find.text(_line(c.host)), findsOneWidget);
          expect(
            r.said,
            isNot(contains(_hostClip(c.host))),
            reason: 'no clip invented: the host is not voiced yet',
          );
          expect(
            r.said.where((String l) => l == _ownClip(packs, c)),
            isNotEmpty,
            reason: 'the existing clip of the same sentence plays, then the word',
          );
        },
      );
    }

    testWidgets('once the host\'s own clip is in the voice it is the one that plays, not the companion\'s', (
      WidgetTester t,
    ) async {
      final L7Rig r = await open(t, _eng, extraRefs: <String>{HostHe.clip('host_eng', 'together')});
      await _atTogether(t, _eng);
      await l7Wait(t, 600);
      expect(r.said, contains(_hostClip('host_eng')));
      expect(r.said.where((String l) => l == _ownClip(packs, _eng)), isEmpty);
      final int at = r.said.indexOf(_hostClip('host_eng'));
      expect(
        r.said[at + 1],
        'eng.en_hello',
        reason: 'the word follows the line, as the item\'s own target clip',
      );
    });

    test('the three lines are the editor\'s, marked for review, with a clip id each', () {
      for (final String host in <String>['host_eng', 'host_heb', 'host_rus']) {
        expect(HostHe.togethers[host]!.review, 'needs-editor', reason: host);
        expect(HostHe.togethers[host]!.nikud, isTrue);
        expect(HostHe.clip(host, 'together'), 'vo:host.$host.together');
      }
    });
  });

  // ---- point 3: the microphone's feedback stays the companion's; "I said it" closes in silence ----
  group('point 3: the microphone\'s feedback is the companion\'s, in the back place', () {
    testWidgets('heard: the tail moves to the companion behind the host, nobody moves, the screen closes', (
      WidgetTester t,
    ) async {
      final L7Rig r = await open(t, _eng, voice: true, script: <Scripted>[Scripted.says('hello')]);
      await _atTogether(t, _eng);
      final Rect host = _rect(t, _host);
      final Rect back = _rect(t, const Key('activity-nitzi'));
      await t.tap(find.byKey(_mic));
      await _until(t, () => _frame(t).scene!.companionSpeaks, maxMs: 4000);
      await l7Wait(t, 200);
      expect(_frame(t).scene!.companionSpeaks, isTrue);
      expect(_frame(t).scene!.hostBeat, isTrue, reason: 'the host stays in front');
      expect(_companionPose(t), CharacterState.encourage);
      expect(_pose(t), HostPose.idle);
      expect(t.widget<SpeakingCharacter>(find.byType(SpeakingCharacter)).voiceOf, 'nitzi');
      expect(_rect(t, _host), host, reason: 'nobody moves');
      expect(_rect(t, const Key('activity-nitzi')), back);
      expect(
        t.widget<BoardBubble>(find.byKey(const Key('lesson-bubble'))).tailAtEnd,
        isTrue,
        reason: 'a wedge that reaches past the host to the companion\'s mouth',
      );
      expect(
        find.text(_line('host_eng')),
        findsNothing,
        reason: 'the bubble holds the companion\'s line now',
      );
      expect(r.said.any((String l) => l.contains('heard')), isTrue, reason: 'the "heard" line was said');
      await l7Wait(t, 6000);
      expect(t.takeException(), isNull);
    });

    testWidgets('"I said it": nothing is said, the host\'s line stays and the screen closes', (
      WidgetTester t,
    ) async {
      final L7Rig r = await open(t, _eng);
      await _atTogether(t, _eng);
      final int said = r.said.length;
      await t.tap(find.byKey(_tile));
      await l7Wait(t, 800);
      expect(_frame(t).scene!.companionSpeaks, isFalse);
      expect(find.text(_line('host_eng')), findsOneWidget);
      expect(r.said.length, said, reason: 'a silent close');
      await l7Wait(t, 3000);
      expect(
        find.byKey(const Key('meet-thumb-0')),
        findsOneWidget,
        reason: 'the next word\'s screen: the first is in the strip',
      );
    });
  });

  // ---- point 4: the idle prompt re-voices the host's line, with no hand ----
  testWidgets('point 4: the idle prompt says the host\'s "together" line again, and no hand points', (
    WidgetTester t,
  ) async {
    final L7Rig r = await open(t, _eng);
    await _atTogether(t, _eng);
    final int line = r.said.where((String l) => l == _ownClip(packs, _eng)).length;
    await l7Wait(t, 16000);
    expect(
      r.said.where((String l) => l == _ownClip(packs, _eng)).length,
      greaterThan(line),
      reason: 'the idle prompt says the line again (the clip of the host\'s line until it is voiced)',
    );
    expect(find.text(_line('host_eng')), findsOneWidget);
    expect(_frame(t).idleHand, isNull, reason: 'a hand would teach "touch the picture to go on"');
  });

  // ---- point 5: the pair in the corner, the frame's pieces do not move between the screens of a set ----
  group('point 5: layout', () {
    const Map<String, (Size, double, double)> boards = <String, (Size, double, double)>{
      // size, the bubble's right edge, its widest
      'phone': (Size(852, 393), 591, 178),
      'phoneSE': (Size(667, 375), 470, 170),
      'tabletLandscape': (Size(1180, 820), 932, 600),
      'tabletPortrait': (Size(820, 1180), 566, 410),
    };
    for (final MapEntry<String, (Size, double, double)> b in boards.entries) {
      testWidgets(
        '${b.key}: the bubble takes the host-beat edge and width, the back place is clear of the microphone and "I said it"',
        (WidgetTester t) async {
          await open(t, _eng, size: b.value.$1, voice: true);
          await _atTogether(t, _eng);
          final Rect bubble = _rect(t, const Key('lesson-bubble'));
          expect(bubble.right, closeTo(b.value.$2, 0.6));
          expect(bubble.width, lessThanOrEqualTo(b.value.$3 + 0.5));
          final Rect back = _rect(t, const Key('activity-nitzi'));
          expect(back.overlaps(t.getRect(find.byKey(_mic))), isFalse, reason: 'clear of the microphone');
          expect(back.overlaps(t.getRect(find.byKey(_tile))), isFalse, reason: 'clear of "I said it"');
          expect(back.overlaps(bubble), isFalse);
        },
      );
    }

    testWidgets('the frame\'s pieces stay where they are from one screen of a set to the next', (
      WidgetTester t,
    ) async {
      await open(t, _eng, voice: true);
      await _atTogether(t, _eng);
      Map<String, Rect> pieces() => <String, Rect>{
        'trail': t.getRect(find.byType(ProgressTrail)),
        'home': _rect(t, const Key('activity-home')),
        'host': _rect(t, _host),
        'back': _rect(t, const Key('activity-nitzi')),
        'mic': _rect(t, _mic),
        'tile': _rect(t, _tile),
        'card': _rect(t, const Key('lesson-stage')),
      };
      final Map<String, Rect> first = pieces();
      await t.tap(find.byKey(_tile));
      await _until(t, () => find.byKey(const Key('meet-thumb-0')).evaluate().isNotEmpty);
      await _until(
        t,
        () =>
            find.byKey(_tile).evaluate().isNotEmpty &&
            t
                    .widget<AnimatedOpacity>(
                      find.ancestor(of: find.byKey(_tile), matching: find.byType(AnimatedOpacity)).first,
                    )
                    .opacity ==
                1,
      );
      expect(pieces(), first);
    });
  });

  // ---- point 6: the Meet card stands on the course's backdrop ----
  group('point 6: the Meet card on the course backdrop', () {
    for (final (_Course c, Size size) in <(_Course, Size)>[
      (_eng, _phone),
      (_rus, Size(667, 375)),
      (_eng, Size(820, 1180)),
      (_heb, _phone),
    ]) {
      testWidgets(
        '${c.course} on ${size.width.toInt()} x ${size.height.toInt()}: the room\'s backdrop under the card',
        (WidgetTester t) async {
          await open(t, c, size: size);
          await _atMeet(t, c);
          final Finder backdrop = find.byKey(Key('room-backdrop-${c.course}'));
          expect(backdrop, findsOneWidget);
          final Rect card = _rect(t, const Key('meet-card'));
          final Rect stage = t.getRect(backdrop);
          expect(
            stage.inflate(0.5).contains(card.topLeft) && stage.inflate(0.5).contains(card.bottomRight),
            isTrue,
            reason: 'the card is inside the backdrop',
          );
          // The landmark (the course's window) stands in a place of its own: clear of the card and of the thumbnails.
          final Rect stageBox = _rect(t, const Key('lesson-stage'));
          expect(stageBox.overlaps(t.getRect(find.byType(ProgressTrail))), isFalse);
        },
      );
    }
  });

  // ---- point 7: Find is the child's turn: the host is off screen, the companion at its own place ----
  testWidgets('point 7: at the Find the host has gone and the companion stands in its own place', (
    WidgetTester t,
  ) async {
    await open(t, _eng);
    await _atMeet(t, _eng);
    await _until(
      t,
      () =>
          find.byKey(_tile).evaluate().isNotEmpty &&
          t
                  .widget<AnimatedOpacity>(
                    find.ancestor(of: find.byKey(_tile), matching: find.byType(AnimatedOpacity)).first,
                  )
                  .opacity ==
              1,
    );
    await t.tap(find.byKey(_tile));
    await _until(t, () => find.byKey(const Key('meet-thumb-0')).evaluate().isNotEmpty);
    await _until(
      t,
      () =>
          find.byKey(_tile).evaluate().isNotEmpty &&
          t
                  .widget<AnimatedOpacity>(
                    find.ancestor(of: find.byKey(_tile), matching: find.byType(AnimatedOpacity)).first,
                  )
                  .opacity ==
              1,
    );
    await t.tap(find.byKey(_tile));
    await _until(t, () => find.byKey(const Key('option-o2')).evaluate().isNotEmpty);
    await l7Wait(t, 600);
    expect(_frame(t).scene!.hostBeat, isFalse);
    expect(find.byKey(_host), findsNothing, reason: 'the host has gone');
    expect(
      _rect(t, const Key('activity-nitzi')),
      const Rect.fromLTWH(617, 80, 176, 176),
      reason: 'the guide\'s own place',
    );
  });

  // ---- point 8: motion ----
  group('point 8: motion', () {
    testWidgets('between the screens of a set nobody moves: the host does not leave or walk in again', (
      WidgetTester t,
    ) async {
      await open(t, _eng, reduceMotion: false);
      await _atTogether(t, _eng);
      final Rect front = _rect(t, _host);
      await t.tap(find.byKey(_tile));
      for (int i = 0; i < 40; i++) {
        await t.pump(const Duration(milliseconds: 100));
        expect(find.byKey(_host), findsOneWidget, reason: 'at ${i * 100} ms');
        expect(_rect(t, _host), front, reason: 'at ${i * 100} ms');
      }
      expect(find.byKey(const Key('meet-thumb-0')), findsOneWidget, reason: 'the second screen was reached');
    });

    testWidgets(
      'the host walks in on the first Meet screen after a child\'s turn and is not there before it',
      (WidgetTester t) async {
        await open(t, _heb, reduceMotion: false);
        await _until(t, () => find.byKey(const Key('story-turn')).evaluate().isNotEmpty);
        expect(find.byKey(_host), findsNothing, reason: 'the story is the companion\'s turn');
        for (int i = 0; i < 5; i++) {
          await t.tap(find.byKey(const Key('story-turn')));
          await l7Wait(t, 300);
        }
        await _until(t, () => find.byKey(_host).evaluate().isNotEmpty);
        expect(
          _rect(t, _host).left,
          greaterThan(HostPlaces.phone.front.left),
          reason: 'coming in from the start edge',
        );
        await l7Wait(t, 1200);
        expect(_rect(t, _host), HostPlaces.phone.front);
      },
    );

    testWidgets('right after the greeting the host is in front already: it does not walk in a second time', (
      WidgetTester t,
    ) async {
      await open(t, _eng, reduceMotion: false);
      await _until(t, () => find.byKey(const Key('say-picture')).evaluate().isNotEmpty);
      expect(_rect(t, _host), HostPlaces.phone.front, reason: 'at the first frame of the Meet');
    });
  });

  // ---- point 9: one socket per set, in the course's shape ----
  group('point 9: the trail', () {
    for (final _Course c in <_Course>[_eng, _rus, _heb]) {
      testWidgets(
        '${c.course}: the socket takes the course\'s shape and a set of Meet screens is one socket',
        (WidgetTester t) async {
          await open(t, c);
          await _atMeet(t, c);
          final ProgressTrail trail = t.widget<ProgressTrail>(find.byType(ProgressTrail));
          expect(trail.shape, c.trail);
          final List<Activity> items = packs[c.course]!.itemsFor(
            packs[c.course]!.lessons[c.lesson]!,
            route: 'new',
          );
          final int meets = items
              .where((Activity a) => a is SayItActivity && a.meetScreen && (a.meet?.position ?? 0) > 0)
              .length;
          expect(
            trail.total,
            items.length - meets,
            reason: 'a Meet screen after the first of its set is not a socket of its own',
          );
          expect(trail.done, lessThanOrEqualTo(1), reason: 'at most the story before the first set');
        },
      );
    }
  });

  // ---- point 11: the speaking badge is as it was; the host has no pointer ----
  testWidgets(
    'point 11: the host has no pointer on a Meet screen, and the badge is at the top start corner of the card',
    (WidgetTester t) async {
      await open(t, _eng);
      await _atTogether(t, _eng);
      final Rect card = _rect(t, const Key('meet-card'));
      final Rect badge = t.getRect(find.byType(SpeakingBadge).first);
      expect(_frame(t).idleHand, isNull);
      expect(find.byType(HintHand), findsNothing);
      expect(find.byKey(const Key('idle-hand')), findsNothing);
      // The disc is centred 10 points inside the card's top start (right) corner: where it is with the rooms off.
      expect(badge.center.dx, closeTo(card.right - 10, 0.6));
      expect(badge.center.dy, closeTo(card.top + 10, 0.6));
    },
  );

  // ---- the greeting word of the two foreign-language hosts ----
  group('the greeting word in the course\'s language', () {
    testWidgets('its clip plays before the Hebrew greeting when the voice has it', (WidgetTester t) async {
      final L7Rig r = await open(
        t,
        _eng,
        extraRefs: <String>{HostHe.clip('host_eng', 'hello'), HostHe.clip('host_eng', 'greeting')},
      );
      await l7Wait(t, 2500);
      expect(r.said.take(2).toList(), <String>['host.host_eng.hello', 'host.host_eng.greeting']);
    });

    testWidgets('with no clip the greeting is the Hebrew line alone and nothing breaks', (
      WidgetTester t,
    ) async {
      final L7Rig r = await open(t, _eng);
      await l7Wait(t, 2500);
      expect(r.said.where((String l) => l.startsWith('host.')), isEmpty);
      expect(find.text(HostHe.greetings['host_eng']!.text), findsOneWidget);
      expect(find.byType(TargetChip), findsNothing);
    });

    testWidgets('the word is written in its chip for a look C child whose letters are open', (
      WidgetTester t,
    ) async {
      await open(t, _eng, band: 2, lettersOpen: true);
      await l7Wait(t, 1200);
      expect(find.text(hostHello['host_eng']!.text), findsOneWidget);
    });

    testWidgets('look A never shows text, whatever the letters gate says', (WidgetTester t) async {
      await open(t, _eng, band: 0, lettersOpen: true);
      await l7Wait(t, 1200);
      expect(find.byType(TargetChip), findsNothing);
    });

    testWidgets('the Hebrew course has no greeting word', (WidgetTester t) async {
      await open(t, _heb, band: 2, lettersOpen: true);
      await l7Wait(t, 1200);
      expect(find.byType(TargetChip), findsNothing);
      expect(hostHello.keys, <String>['host_eng', 'host_rus']);
    });
  });

  // ---- rooms off: the Meet as it was ----
  testWidgets(
    'rooms off: the Meet is as before: no host, the companion says the activity\'s own line and speaks the beats',
    (WidgetTester t) async {
      final L7Rig r = await open(t, _eng, rooms: false);
      await _until(t, () => find.byKey(const Key('say-picture')).evaluate().isNotEmpty);
      await l7Wait(t, 7000);
      expect(_frame(t).scene, isNull);
      expect(find.byKey(_host), findsNothing);
      expect(find.text(_line('host_eng')), findsNothing);
      expect(r.said.where((String l) => l == _ownClip(packs, _eng)), isNotEmpty);
      expect(t.widget<SpeakingCharacter>(find.byType(SpeakingCharacter)).voiceOf, 'nitzi');
    },
  );
}
