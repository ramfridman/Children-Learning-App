// M11 Stage 1, the parts that need no screen: which room a skill is in, the art's numbers against the generator that draws it, the layer
// geometry, the hosts' anchors against their pose files, the trail's shapes, the greeting of the lesson controller (who speaks, what is
// asked and written), and the rules (nothing counted, nothing timed) as source rules.
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nitznutz/child/activity_shell.dart';
import 'package:nitznutz/content/models.dart';
import 'package:nitznutz/design/board.dart';
import 'package:nitznutz/design/tokens.g.dart';
import 'package:nitznutz/play/activity_frame.dart';
import 'package:nitznutz/play/lesson_controller.dart';
import 'package:nitznutz/rooms/host_places.dart';
import 'package:nitznutz/rooms/host_view.dart';
import 'package:nitznutz/rooms/moments.dart';
import 'package:nitznutz/rooms/room_activity.dart';
import 'package:nitznutz/rooms/room_layout.dart';
import 'package:nitznutz/rooms/room_spec.dart';
import 'package:nitznutz/strings/he.dart' show HostHe, Str;

import 'support/harness.dart';
import 'support/m11_rooms.dart';
import 'support/security_fakes.dart';
import 'support/starter.dart';
import 'support/course_packs.dart';

/// The text of `tools/make_room_art.py`, the source of truth of the art.
final String _generator = File('../tools/make_room_art.py').readAsStringSync();

Color _hex(String h) => Color(0xFF000000 | int.parse(h.substring(1), radix: 16));

/// The WCAG contrast ratio of two opaque colours.
double _contrast(Color a, Color b) {
  final double la = a.computeLuminance(), lb = b.computeLuminance();
  return (math.max(la, lb) + 0.05) / (math.min(la, lb) + 0.05);
}

void main() {
  late PackContent starter;
  setUpAll(() async => starter = await loadStarter());

  group('which room a skill is in', () {
    test('a land is the room of the domain of its skill, a course the room of the course', () {
      final Map<String, RoomId> found = <String, RoomId>{};
      for (final SkillDoc s in starter.skills.values) {
        final RoomSpec? room = RoomSpec.of(s);
        expect(room, isNotNull, reason: '${s.id} (${s.domain}) has a room');
        found.putIfAbsent(s.domain, () => room!.id);
      }
      expect(found, <String, RoomId>{
        'numbers': RoomId.numbers,
        'math': RoomId.math,
        'logic': RoomId.logic,
        'shapes': RoomId.shapes,
        'colors': RoomId.colors,
        'cs': RoomId.cs,
      });
      for (final String course in <String>['eng', 'heb', 'rus']) {
        final PackContent pack = courseContent(course);
        for (final SkillDoc s in pack.skills.values) {
          expect(RoomSpec.of(s)!.id.name, course, reason: s.id);
        }
      }
    });

    test('no skill, no room: the default frame stays where no room applies', () {
      expect(RoomSpec.of(null), isNull);
    });

    test('every room has its own host, trail shape, screen colour and rim', () {
      expect(RoomSpec.all.map((RoomSpec r) => r.hostId).toSet(), hasLength(9));
      expect(RoomSpec.all.map((RoomSpec r) => r.trail).toSet(), hasLength(9));
      expect(RoomSpec.all.map((RoomSpec r) => r.rim).toSet(), hasLength(9));
      expect(RoomSpec.all.map((RoomSpec r) => r.screen).toSet(), hasLength(9));
      for (final RoomSpec r in RoomSpec.all) {
        expect(HostSpec.byId(r.hostId).id, r.hostId);
        expect(HostHe.names.keys, contains(r.hostId));
      }
    });

    test(
      'Colour Bay is the most vivid room: the pink tint screen, its fill as the rim, its deep as the lip',
      () {
        expect(RoomSpec.colors.screen, TokenColors.domainColorsTint);
        expect(RoomSpec.colors.rim, TokenColors.domainColorsFill);
        expect(RoomSpec.colors.lip, TokenColors.domainColorsDeep);
      },
    );

    test("the text on every room's screen colour is at least 7:1 (ink) and 4.5:1 (soft ink)", () {
      for (final RoomSpec r in RoomSpec.all) {
        expect(
          _contrast(TokenColors.ink, r.screen),
          greaterThanOrEqualTo(7),
          reason: '${r.name} ink on its screen',
        );
        expect(
          _contrast(TokenColors.inkSoft, r.screen),
          greaterThanOrEqualTo(4.5),
          reason: '${r.name} soft ink on its screen',
        );
      }
    });
  });

  group('the art and its numbers', () {
    test('all 63 room files, the 36 host pictures (the four of Goni are the recolourable ones) are there and are listed in the pubspec', () {
      for (final RoomSpec r in RoomSpec.all) {
        for (final String part in <String>[
          'far',
          'ground',
          'top',
          'corner',
          'landmark',
          'piece',
          'reacted',
        ]) {
          expect(File(r.art(part)).existsSync(), isTrue, reason: r.art(part));
        }
      }
      for (final HostSpec h in HostSpec.all) {
        for (final HostPose p in HostPose.values) {
          expect(File(h.asset(p)).existsSync(), isTrue, reason: h.asset(p));
        }
      }
      final String pubspec = File('pubspec.yaml').readAsStringSync();
      expect(pubspec, contains('- assets/art/rooms/'));
      expect(pubspec, contains('- assets/art/hosts/'));
    });

    test('the sky of each room is the generator\'s (`SKY` in tools/make_room_art.py)', () {
      for (final RoomSpec r in RoomSpec.all) {
        final RegExpMatch? m = RegExp("'${r.name}': \\(([^)]*)\\)").firstMatch(_generator);
        expect(m, isNotNull, reason: r.name);
        final List<String> parts = m!.group(1)!.split(',').map((String s) => s.trim()).toList();
        Color colour(String p) => p.startsWith("'") ? _hex(p.replaceAll("'", '')) : _hex('#CDEFFF');
        // `SKY_TOP` and `SKY_BOTTOM` are the numbers' sky: named in the generator, spelled out in its constants.
        final Color top = parts[0] == 'SKY_TOP' ? _hex('#CDEFFF') : colour(parts[0]);
        final Color bottom = parts[1] == 'SKY_BOTTOM' ? _hex('#FFF1D6') : colour(parts[1]);
        expect(r.skyTop, top, reason: '${r.name} top');
        expect(r.skyBottom, bottom, reason: '${r.name} bottom');
      }
    });

    test('the layer table is the generator\'s (`LAYERS`)', () {
      final String layers = RegExp(
        r'LAYERS = dict\((.*?)\)\nCOURSES',
        dotAll: true,
      ).firstMatch(_generator)!.group(1)!;
      double number(String key) => double.parse(RegExp('$key=([0-9.]+)').firstMatch(layers)!.group(1)!);
      expect(RoomLayout.far, number('far'));
      expect(RoomLayout.ground, number('ground'));
      expect(RoomLayout.top, number('top'));
      expect(RoomLayout.corner, number('corner'));
      expect(RoomLayout.cornerMaxWidth, number('cornerMaxW'));
      expect(RoomLayout.roomCorner, number('roomCorner'));
      expect(RoomLayout.roomCornerMaxWidth, number('roomCornerMaxW'));
      final RegExpMatch inset = RegExp(r'landmarkInset=\((\d+), (\d+)\)').firstMatch(layers)!;
      expect(RoomLayout.insetX, double.parse(inset.group(1)!));
      expect(RoomLayout.insetY, double.parse(inset.group(2)!));
      for (final (String part, ui.Size size) in <(String, ui.Size)>[
        ('far', RoomLayout.farFile),
        ('ground', RoomLayout.groundFile),
        ('top', RoomLayout.topFile),
        ('corner', RoomLayout.cornerFile),
      ]) {
        final RegExpMatch m = RegExp(
          '$part='
          r'\((\d+), (\d+)\)',
        ).firstMatch(_generator)!;
        expect(size, ui.Size(double.parse(m.group(1)!), double.parse(m.group(2)!)), reason: part);
      }
    });

    test('the course colours of the tokens are the doors\' own panel colours (spec 3.6)', () {
      expect(RoomSpec.eng.rim, _hex('#2C6FB8'));
      expect(RoomSpec.heb.rim, _hex('#D25E4E'));
      expect(RoomSpec.rus.rim, _hex('#6D49B3'));
      expect(RoomSpec.eng.screen, _hex('#E1ECF8'));
      expect(RoomSpec.heb.lip, _hex('#A63A2C'));
      expect(RoomSpec.rus.lip, _hex('#55358F'));
    });
  });

  group('the layers on a stage', () {
    const ui.Size phone = ui.Size(330, 128);

    test('no layer is stretched: each keeps its file\'s aspect and is centred or cornered', () {
      final ui.Rect far = RoomLayout.farBox(phone);
      expect(far.height, closeTo(0.66 * 128, 0.01));
      expect(far.width / far.height, closeTo(8, 0.001));
      expect(far.bottom, 128);
      expect(far.center.dx, closeTo(165, 0.01));
      final ui.Rect ground = RoomLayout.groundBox(phone);
      expect(ground.width / ground.height, closeTo(24, 0.001));
      expect(ground.bottom, 128);
      final ui.Rect top = RoomLayout.topBox(phone);
      expect(top.top, 0);
      expect(top.width / top.height, closeTo(24, 0.001));
      final ui.Rect corner = RoomLayout.cornerBox(phone, course: false);
      expect(corner.width / corner.height, closeTo(1.2, 0.001));
      // 6 in from the start (right) edge, 2 up from the bottom.
      expect(corner.right, 330 - 6);
      expect(corner.bottom, 128 - 2);
    });
  });

  group('the host and the companion in the corner', () {
    test('the host stands in front where the guide stood, the companion is smaller and further out, on one ground line', () {
      for (final BoardClass b in BoardClass.values) {
        final HostPlaces p = HostPlaces.of(b);
        final ActivitySpec guide = ActivitySpec.of(b);
        expect(p.back.width, lessThan(p.front.width), reason: '$b');
        // The companion stands on the outer (start, right) side of the host.
        expect(p.back.center.dx, greaterThan(p.front.center.dx), reason: '$b');
        // The host is a little smaller than the guide alone on a phone and as big on a tablet.
        expect(p.front.width, lessThanOrEqualTo(guide.nitziSize), reason: '$b');
        expect(
          p.bubbleMaxWidth,
          lessThanOrEqualTo(guide.bubbleMaxWidth),
          reason: '$b: the bubble is never wider in a host beat',
        );
        // One ground line: the baselines of the two boxes (472 of 512 down) within 4 points of each other.
        double baseline(ui.Rect r) => r.top + r.height * 472 / 512;
        expect((baseline(p.front) - baseline(p.back)).abs(), lessThanOrEqualTo(4), reason: '$b');
      }
    });

    test('the host\'s mouth is the anchor of its pose file, in the 512 units of the artboard', () {
      for (final HostSpec h in HostSpec.all) {
        for (final HostPose p in <HostPose>[HostPose.talk, HostPose.show]) {
          final Offset share = h.mouthShare(p);
          expect(share.dx, inInclusiveRange(0, 1));
          expect(share.dy, inInclusiveRange(0.2, 0.9), reason: '${h.id} ${p.name}');
        }
      }
      expect(HostSpec.nekudi.mouthShare(HostPose.talk), const Offset(256 / 512, 268 / 512));
    });

    test(
      'the anchors in the code are the ones written in the pose files (Nekudi\'s are the spec\'s table)',
      () {
        for (final HostSpec h in HostSpec.all) {
          if (h.id == 'nekudi') continue;
          final String design = h.id.startsWith('host_') ? 'host-${h.id.substring(5)}' : h.id;
          for (final HostPose p in <HostPose>[HostPose.talk, HostPose.show]) {
            final String text = File('../design/assets/$design-${p.name}.svg').readAsStringSync();
            final RegExpMatch m = RegExp(r'mouth (\d+), (\d+)').firstMatch(text)!;
            final Offset written = Offset(double.parse(m.group(1)!), double.parse(m.group(2)!));
            expect(h.mouthShare(p) * 512, written, reason: '${h.id} ${p.name}');
          }
        }
      },
    );

    test('Goni is drawn in his own recolourable files, as every other host is in his', () {
      expect(HostSpec.goni.asset(HostPose.talk), endsWith('goni_talk.svg'));
      expect(HostSpec.nekudi.asset(HostPose.celebrate), endsWith('nekudi_celebrate.svg'));
    });
  });

  group('the trail\'s sockets', () {
    test('every shape fits its 20 by 20 box (to half a point) and the nine rooms shapes differ pairwise as pictures', () async {
      final List<List<bool>> masks = <List<bool>>[];
      for (final RoomSpec r in RoomSpec.all) {
        expect(r.trail.path.getBounds().left, greaterThanOrEqualTo(-0.5));
        expect(r.trail.path.getBounds().right, lessThanOrEqualTo(20.5));
        expect(r.trail.path.getBounds().top, greaterThanOrEqualTo(-0.5));
        expect(r.trail.path.getBounds().bottom, lessThanOrEqualTo(20.5));
        masks.add(<bool>[
          for (int y = 0; y < 20; y++)
            for (int x = 0; x < 20; x++) r.trail.path.contains(Offset(x + 0.5, y + 0.5)),
        ]);
      }
      for (int i = 0; i < masks.length; i++) {
        expect(masks[i].where((bool b) => b).length, greaterThan(40), reason: 'room $i has a visible shape');
        for (int j = i + 1; j < masks.length; j++) {
          int differing = 0;
          for (int k = 0; k < 400; k++) {
            if (masks[i][k] != masks[j][k]) differing++;
          }
          expect(
            differing,
            greaterThan(24),
            reason: '${RoomSpec.all[i].name} and ${RoomSpec.all[j].name} differ in shape',
          );
        }
      }
    });
  });

  group('the room\'s activity', () {
    test('only the meadow is left out; every other background stays, and the rest of the activity is the same one', () {
      final Activity meadow = starter.activities.values.firstWhere(
        (Activity a) => a.background == 'asset:meadow',
      );
      final Activity played = inRoom(meadow);
      expect(played.background, isNull);
      expect(played.id, meadow.id);
      expect(played.template, meadow.template);
      expect(played.promptLine.caption, meadow.promptLine.caption);
      final Iterable<Activity> others = starter.activities.values.where(
        (Activity a) => a.background != null && a.background != 'asset:meadow',
      );
      for (final Activity a in others) {
        expect(inRoom(a), same(a), reason: '${a.id} keeps ${a.background}');
      }
      final Activity bare = starter.activities.values.firstWhere((Activity a) => a.background == null);
      expect(inRoom(bare), same(bare));
    });
  });

  group('the greeting of the lesson controller', () {
    late Lesson lesson;
    late List<AttemptRecord> written;
    late ControlledClock clock;

    LessonController make({Spoken? greeting}) => LessonController(
      content: starter,
      lesson: lesson,
      profileId: 'p-1',
      clock: clock,
      record: (AttemptRecord r) async => written.add(r),
      hostGreeting: greeting,
    );

    const Spoken hi = Spoken(vo: 'vo:host.nekudi.greeting', caption: 'שלום');

    setUp(() async {
      final (PackContent _, Lesson l) = await roomLesson(RoomId.numbers);
      lesson = l;
      written = <AttemptRecord>[];
      clock = ControlledClock(1793000000000);
    });

    test('with no host the first item is the first screen, as before M11', () {
      final LessonController c = make();
      expect(c.moment, Moment.turn);
      expect(c.moment.speaker, Speaker.companion);
      expect(c.noHelp, isFalse);
      expect(c.bubble, c.current.promptLine.caption);
    });

    test('with a host the lesson opens with its greeting: the host speaks, nothing is asked, no help is on offer', () {
      final LessonController c = make(greeting: hi);
      expect(c.moment, Moment.greeting);
      expect(c.moment.speaker, Speaker.host);
      expect(c.bubble, 'שלום');
      expect(c.voice, 'vo:host.nekudi.greeting');
      expect(c.bubbleMath, isNull);
      expect(c.noHelp, isTrue);
      final int nonce = c.voiceNonce;
      c.replayPrompt();
      c.showHint();
      expect(c.bubble, 'שלום', reason: 'the question is not asked, and no hint is shown, in a greeting');
      expect(c.hintShown, 0);
      expect(c.voiceNonce, nonce);
      expect(written, isEmpty);
    });

    test('the greeting ends once: the first question is asked, help is on offer, and the answer\'s time counts from the end of the greeting', () async {
      final LessonController c = make(greeting: hi);
      clock.advance(const Duration(seconds: 7));
      c.endGreeting();
      expect(c.moment, Moment.turn);
      expect(c.moment.speaker, Speaker.companion);
      expect(c.bubble, c.current.promptLine.caption);
      expect(c.voice, c.current.promptLine.vo);
      expect(c.noHelp, isFalse);
      final int nonce = c.voiceNonce;
      c.endGreeting();
      expect(c.voiceNonce, nonce, reason: 'a second touch does nothing');
      clock.advance(const Duration(seconds: 2));
      await c.chooseOption(rightOption(starter, lesson, 0));
      expect(
        written.single.durationMs,
        2000,
        reason: 'the seconds of the greeting are not the child\'s time',
      );
      expect(written.single.result, 'correct');
    });

    test(
      'the end of the lesson is the host\'s cheer, and a lesson that ends at the greeting writes nothing',
      () async {
        final LessonController c = make(greeting: hi);
        c.endGreeting();
        for (int i = 0; i < lesson.itemIds.length; i++) {
          await c.chooseOption(rightOption(starter, lesson, i));
          c.next();
        }
        expect(c.finished, isTrue);
        expect(c.moment, Moment.cheer);
        expect(c.moment.speaker, Speaker.host);
        expect(
          written,
          hasLength(lesson.itemIds.length),
          reason: 'one attempt for each answer: the greeting and the cheer write none',
        );
      },
    );

    Future<LessonController> finish({Spoken? cheer}) async {
      final LessonController c = LessonController(
        content: starter,
        lesson: lesson,
        profileId: 'p-1',
        clock: clock,
        record: (AttemptRecord r) async => written.add(r),
        hostGreeting: hi,
        hostCheer: cheer,
      );
      c.endGreeting();
      for (int i = 0; i < lesson.itemIds.length; i++) {
        await c.chooseOption(rightOption(starter, lesson, i));
        c.next();
      }
      expect(c.finished, isTrue);
      return c;
    }

    test('at the end the host cheer is the one line said when it already says the lesson praise (not the same words twice)', () async {
      // The lesson's praise is the first words of the cheer, so the two are the same words.
      const Spoken cheer = Spoken(vo: 'vo:host.nekudi.cheer', caption: 'כל הכבוד! ספרתם הכל.');
      final LessonController c = await finish(cheer: cheer);
      expect(lesson.celebration.caption, 'כָּל הַכָּבוֹד!');
      expect(c.voice, 'vo:host.nekudi.cheer');
      expect(c.bubble, cheer.caption);
    });

    test('a praise that says something else is still the companion line, and with no host the celebration is as before', () async {
      const Spoken other = Spoken(vo: 'vo:host.nekudi.cheer', caption: 'יפה מאד! ראיתם היטב.');
      final LessonController c = await finish(cheer: other);
      expect(c.voice, lesson.celebration.vo);
      expect(c.bubble, lesson.celebration.caption);
      final LessonController plain = await finish();
      expect(plain.voice, lesson.celebration.vo);
    });

    test('cheerRepeatsPraise compares the words, not the niqqud or the punctuation', () {
      expect(cheerRepeatsPraise('כָּל הַכָּבוֹד!', 'כל הכבוד, ספרתם הכל.'), isTrue);
      expect(cheerRepeatsPraise('כׇּל הַכָּבוֹד!', 'כָּל הַכָּבוֹד! בְּנִיתֶם.'), isTrue);
      expect(cheerRepeatsPraise('מצוין', 'כל הכבוד!'), isFalse);
      expect(cheerRepeatsPraise('', 'כל הכבוד!'), isFalse);
    });

    test('each moment has one speaker: a Show and the lead-in of a Together item are the hosts', () {
      expect(
        <Moment, Speaker>{for (final Moment m in Moment.values) m: m.speaker},
        <Moment, Speaker>{
          Moment.greeting: Speaker.host,
          Moment.meet: Speaker.host,
          Moment.show: Speaker.host,
          Moment.lead: Speaker.host,
          Moment.turn: Speaker.companion,
          Moment.cheer: Speaker.host,
        },
      );
    });
  });

  group('the host\'s lines', () {
    test('each host has a greeting, a cheer and a name, all with a pending clip, in niqqud where a child reads them', () {
      for (final RoomSpec r in RoomSpec.all) {
        final String id = r.hostId;
        expect(HostHe.greetings[id]!.nikud, isTrue, reason: id);
        expect(HostHe.cheers[id]!.nikud, isTrue, reason: id);
        expect(HostHe.names[id]!.nikud, isFalse, reason: id);
        expect(HostHe.greetings[id]!.review, 'needs-editor');
        expect(HostHe.clip(id, 'greeting'), 'vo:host.$id.greeting');
        // No personal data and no placeholder: a host never says the child's name in Stage 1.
        expect(HostHe.greetings[id]!.text, isNot(contains('{')));
        expect(HostHe.cheers[id]!.text, isNot(contains('{')));
      }
      expect(HostHe.greetings.length, 9);
      expect(HostHe.cheers.length, 9);
    });

    testWidgets(
      'a host line fits its bubble on every board at the band size, at text scale 1.3 too, without widening it',
      (WidgetTester tester) async {
        await loadAppFonts();
        for (final BoardClass b in BoardClass.values) {
          final HostPlaces p = HostPlaces.of(b);
          final ActivitySpec s = ActivitySpec.of(b).forHostBeat(p);
          for (final double scale in <double>[1, 1.3]) {
            for (final Str line in <Str>[...HostHe.greetings.values, ...HostHe.cheers.values]) {
              final ({double font, double height, double width}) fit = ActivityFrame.fitBubble(
                line.text,
                s,
                scaler: TextScaler.linear(scale),
              );
              expect(
                fit.width,
                p.bubbleMaxWidth,
                reason: '$b x$scale: ${line.text} does not widen the bubble',
              );
              expect(fit.height, lessThanOrEqualTo(s.bubbleMaxHeight), reason: '$b x$scale: ${line.text}');
            }
          }
        }
      },
    );
  });

  group('the rules: nothing counted, nothing timed, nothing kept (acceptance criterion 4)', () {
    final List<File> files = <File>[
      for (final FileSystemEntity e in Directory('lib/rooms').listSync())
        if (e is File && e.path.endsWith('.dart')) e,
    ];

    test('the room files hold no counter of right answers, streak, countdown, score or timer', () {
      final RegExp banned = RegExp(
        'streak|countdown|score|timer|counter|combo|lives|penalty|loss',
        caseSensitive: false,
      );
      for (final File f in files) {
        for (final String line in f.readAsLinesSync()) {
          final String code = line.trimLeft();
          if (code.startsWith('//')) continue;
          expect(banned.hasMatch(code), isFalse, reason: '${f.path}: $line');
        }
      }
    });

    test('the room files write nothing: no database, no attempt, no sync, no settings', () {
      final RegExp banned = RegExp(
        'AppDatabase|AttemptRecord|putSetting|SessionRecorder|SyncRunner|SharedPreferences',
      );
      for (final File f in files) {
        expect(banned.hasMatch(f.readAsStringSync()), isFalse, reason: f.path);
      }
    });

    test('the reaction is a function of "solved" alone: it is drawn from no answer, hint or mistake', () {
      final String reaction = File('lib/rooms/stage_reaction.dart').readAsStringSync();
      expect(reaction, isNot(contains('hintLevel')));
      expect(reaction, isNot(contains('errors')));
      expect(reaction, isNot(contains('feedback')));
    });

    test('the host\'s greeting and the pointer\'s rules: no mic is offered in a greeting (a host beat of a land lesson)', () {
      final String screen = File('lib/play/lesson_screen.dart').readAsStringSync();
      final int start = screen.indexOf('Widget _greeting(');
      final String greeting = screen.substring(start, screen.indexOf('Widget _lessonBody('));
      expect(greeting, isNot(contains('mic:')));
      expect(greeting, contains('showHelp: false'));
    });
  });
}
