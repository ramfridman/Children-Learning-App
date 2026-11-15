// M11 Stage 1, Goni's colours (docs/design/m11-rooms.md section 5.2, the owner's decision of 2026-11-15): the colour table against the picture
// files and against the generator that draws them, what the answer's colour is in the pack's data, when Goni wears it (only after a right
// answer, never before or during a question), and how the host picture changes (the cross-fades, the arrival, the ripple, reduce motion).
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nitznutz/content/models.dart';
import 'package:nitznutz/play/goni_moment.dart';
import 'package:nitznutz/play/lesson_controller.dart';
import 'package:nitznutz/rooms/goni_skin.dart';
import 'package:nitznutz/rooms/host_view.dart';
import 'package:nitznutz/rooms/room_spec.dart';

import 'support/m11_rooms.dart';
import 'support/security_fakes.dart';
import 'support/starter.dart';

/// The text of `docs/design/m11/make_host_poses.py`, the table's source.
final String _generator = File('../docs/design/m11/make_host_poses.py').readAsStringSync();

Color _hex(String h) => Color(0xFF000000 | int.parse(h.substring(1), radix: 16));

/// What the mapper does to the colour [from] (the placeholders of the files), with the argument names the parser gives.
Color _map(GoniSkin skin, String from) => skin.substitute(null, 'path', 'fill', _hex(from));

const String _skinSentinel = '#7FD3B0';
const String _shadeSentinel = '#5DB894';
const String _bellySentinel = '#C9EFDD';
const String _rimSentinel = '#2B7A63';
const List<String> _stripeSentinels = <String>['#3E9E80', '#3E9E81', '#3E9E82', '#3E9E83'];

/// What the files draw that is never recoloured: the ink (pupils), the eye ring, the lip, the beret and its edge, the sparks and the tongue.
const List<String> _stays = <String>[
  '#2B2350',
  '#FFE6A8',
  '#F4A7B4',
  '#B0477A',
  '#7A2C52',
  '#FFC83D',
  '#F27D8E',
  '#FFFFFF',
];

void main() {
  late PackContent starter;
  setUpAll(() async => starter = await loadStarter());

  group('the colour table', () {
    test('every lesson colour maps the eight placeholders together, and leaves everything else as drawn', () {
      expect(GoniSkin.colours, hasLength(11));
      for (final String name in GoniSkin.colours) {
        final GoniSkin skin = GoniSkin.of(name)!;
        final RegExpMatch row = RegExp("'$name': \\(([^)]*)\\)").firstMatch(_generator)!;
        final List<String> t = RegExp('#[0-9A-Fa-f]{6}')
            .allMatches(row.group(1)!)
            .map((RegExpMatch m) => m.group(0)!)
            .toList();
        expect(t, hasLength(5), reason: name);
        expect(_map(skin, _skinSentinel), _hex(t[0]), reason: '$name skin');
        expect(_map(skin, _shadeSentinel), _hex(t[1]), reason: '$name shade');
        for (final String stripe in _stripeSentinels) {
          expect(_map(skin, stripe), _hex(t[2]), reason: '$name stripe $stripe');
        }
        expect(_map(skin, _bellySentinel), _hex(t[3]), reason: '$name belly');
        expect(_map(skin, _rimSentinel), _hex(t[4]), reason: '$name rim');
        for (final String other in _stays) {
          expect(_map(skin, other), _hex(other), reason: '$name leaves $other');
        }
        // A fill with a transparency (the ground shadow) is never touched, even when its colour is a placeholder's.
        const Color shadow = Color(0x242B7A63);
        expect(skin.substitute(null, 'ellipse', 'fill', shadow), shadow);
      }
    });

    test('mint is the colours the files are drawn in: it changes nothing', () {
      for (final String c in <String>[
        _skinSentinel,
        _shadeSentinel,
        _bellySentinel,
        _rimSentinel,
        ..._stripeSentinels,
        ..._stays,
      ]) {
        expect(_map(GoniSkin.mint, c), _hex(c), reason: c);
      }
      final RegExpMatch mint = RegExp("'mint': \\(([^)]*)\\)").firstMatch(_generator)!;
      expect(mint.group(1), contains(_skinSentinel));
      expect(mint.group(1), contains(_rimSentinel));
    });

    test(
      'the ripple keeps the skin mint and gives the four bands the rainbow, shifted by one at each step',
      () {
        const List<String> rainbow = <String>[
          '#E5484D',
          '#FF9F43',
          '#FFD84D',
          '#4CAF50',
          '#2F7FE0',
          '#9B6BDF',
        ];
        for (int k = 0; k < GoniSkin.rippleSteps; k++) {
          final GoniSkin step = GoniSkin.ripple.atStep(k);
          expect(_map(step, _skinSentinel), _hex(_skinSentinel));
          expect(_map(step, _rimSentinel), _hex(_rimSentinel));
          for (int band = 0; band < 4; band++) {
            expect(
              _map(step, _stripeSentinels[band]),
              _hex(rainbow[(band + k) % 6]),
              reason: 'step $k band $band',
            );
          }
        }
        expect(GoniSkin.ripple.atStep(GoniSkin.rippleSteps).step, 0, reason: 'a step past the last wraps');
      },
    );

    test('the same skin is equal (the picture cache keys on it), another skin or step is not', () {
      expect(GoniSkin.of('red'), GoniSkin.of('red'));
      expect(GoniSkin.of('red').hashCode, GoniSkin.of('red').hashCode);
      expect(GoniSkin.of('red'), isNot(GoniSkin.of('blue')));
      expect(GoniSkin.ripple.atStep(1), GoniSkin.ripple.atStep(1));
      expect(GoniSkin.ripple.atStep(1), isNot(GoniSkin.ripple.atStep(2)));
      expect(GoniSkin.ripple, isNot(GoniSkin.mint));
      expect(GoniSkin.of('mint'), isNull, reason: 'mint is the resting look, not a colour to find');
      expect(GoniSkin.of(null), isNull);
    });

    test('the four picture files draw only the eight placeholders and the colours that never change', () {
      final Set<String> allowed = <String>{
        _skinSentinel,
        _shadeSentinel,
        _bellySentinel,
        _rimSentinel,
        ..._stripeSentinels,
        ..._stays,
      }.map((String c) => c.toUpperCase()).toSet();
      for (final HostPose pose in HostPose.values) {
        final String file = HostSpec.goni.asset(pose);
        expect(file, endsWith('goni_${pose.name}.svg'), reason: 'Goni has no colour-safe files any more');
        final String text = File(file).readAsStringSync();
        final Set<String> found = RegExp('#[0-9A-Fa-f]{6}')
            .allMatches(text)
            .map((RegExpMatch m) => m.group(0)!.toUpperCase())
            .toSet();
        expect(found.difference(allowed), isEmpty, reason: file);
        for (final String sentinel in <String>[
          _skinSentinel,
          _shadeSentinel,
          _bellySentinel,
          _rimSentinel,
          ..._stripeSentinels,
        ]) {
          expect(found, contains(sentinel), reason: '$file draws $sentinel');
        }
      }
      for (final String safe in <String>['idle', 'talk', 'show', 'celebrate']) {
        expect(File('assets/art/hosts/goni_${safe}_safe.svg').existsSync(), isFalse);
      }
    });
  });

  group('the colour the child found', () {
    TapAnswerActivity pick(bool Function(TapAnswerActivity a) test) =>
        starter.activities.values.whereType<TapAnswerActivity>().firstWhere(test);

    test(
      'it is the one colour name in the right option\'s picture id: the last part of `asset:balloon_red`',
      () {
        final Map<String, int> found = <String, int>{};
        for (final TapAnswerActivity a in starter.activities.values.whereType<TapAnswerActivity>()) {
          if (starter.skills[a.skillId]?.domain != 'colors') continue;
          final String? name = answerColour(a);
          if (name != null) found.update(name, (int n) => n + 1, ifAbsent: () => 1);
          expect(skinForAnswer(a), name == null ? GoniSkin.ripple : GoniSkin.of(name), reason: a.id);
        }
        expect(
          found.keys,
          containsAll(<String>['red', 'blue', 'green', 'yellow']),
          reason: 'the colour lessons ask for the colours',
        );
        expect(found.keys.toSet().difference(GoniSkin.colours.toSet()), isEmpty);
      },
    );

    test('a shade (`shade_blue_2`), an item with no picture to name the colour, and an item that is not a choice take the ripple', () {
      final TapAnswerActivity shade = pick(
        (TapAnswerActivity a) => a.options.any(
          (ChoiceOption o) => o.id == a.correctId && (o.sprite ?? '').startsWith('asset:shade_'),
        ),
      );
      expect(answerColour(shade), isNull, reason: shade.id);
      expect(skinForAnswer(shade), GoniSkin.ripple);
      final Activity sort = starter.activities.values.firstWhere((Activity a) => a is SortDragActivity);
      expect(answerColour(sort), isNull);
      expect(skinForAnswer(sort), GoniSkin.ripple);
      final TapAnswerActivity numeral = pick(
        (TapAnswerActivity a) => a.options.any((ChoiceOption o) => o.numeral != null),
      );
      expect(answerColour(numeral), isNull);
    });

    test('a lesson card has the one colour every scored item asked for, else the ripple', () {
      final List<TapAnswerActivity> coloured = <TapAnswerActivity>[
        for (final TapAnswerActivity a in starter.activities.values.whereType<TapAnswerActivity>())
          if (starter.skills[a.skillId]?.domain == 'colors' && answerColour(a) != null) a,
      ];
      final TapAnswerActivity first = coloured.first;
      final TapAnswerActivity same = coloured.firstWhere(
        (TapAnswerActivity a) => answerColour(a) == answerColour(first) && a != first,
      );
      final TapAnswerActivity other = coloured.firstWhere(
        (TapAnswerActivity a) => answerColour(a) != answerColour(first),
      );
      expect(skinForLesson(<Activity>[first, same]), GoniSkin.of(answerColour(first)));
      expect(skinForLesson(<Activity>[first, other]), GoniSkin.ripple);
      final Activity sort = starter.activities.values.firstWhere((Activity a) => a is SortDragActivity);
      expect(
        skinForLesson(<Activity>[first, same, sort]),
        GoniSkin.ripple,
        reason: 'an item with no single colour makes it the ripple',
      );
      expect(skinForLesson(const <Activity>[]), GoniSkin.ripple);
      final Activity probe = Activity.fromJson(<String, Object?>{
        ...first.json,
        'purpose': 'probe',
      }, first.assets);
      expect(askedItems(<Activity>[first, probe, same]), <Activity>[
        first,
        same,
      ], reason: 'a probe is not an item the child answers');
      expect(answeredByChild(first), isTrue);
      expect(answeredByChild(probe), isFalse);
    });

    test('a lesson\'s precache has each skin it can need, and the ripple\'s four steps when any item has no single colour', () {
      final TapAnswerActivity red = starter.activities.values.whereType<TapAnswerActivity>().firstWhere(
        (TapAnswerActivity a) => answerColour(a) == 'red',
      );
      expect(skinsForLesson(<Activity>[red, red]), <GoniSkin>{GoniSkin.of('red')!});
      final Activity sort = starter.activities.values.firstWhere((Activity a) => a is SortDragActivity);
      expect(skinsForLesson(<Activity>[red, sort]), <GoniSkin>{
        GoniSkin.of('red')!,
        for (int k = 0; k < GoniSkin.rippleSteps; k++) GoniSkin.ripple.atStep(k),
      });
    });
  });

  group('when Goni wears it', () {
    late Lesson lesson;
    late List<AttemptRecord> written;

    LessonController make() => LessonController(
      content: starter,
      lesson: lesson,
      profileId: 'p-1',
      clock: ControlledClock(1793000000000),
      record: (AttemptRecord r) async => written.add(r),
      hostGreeting: const Spoken(vo: 'vo:host.goni.greeting', caption: 'שלום'),
    );

    setUp(() async {
      final (PackContent _, Lesson l) = await roomLesson(RoomId.colors);
      lesson = l;
      written = <AttemptRecord>[];
    });

    test('mint at every frame from the first question until the answer is judged; his colour once it is right; mint again before the next question', () async {
      final LessonController c = make();
      final List<(bool, FeedbackKind, GoniSkin?)> frames = <(bool, FeedbackKind, GoniSkin?)>[];
      c.addListener(() => frames.add((c.solved, c.feedback, goniSkinFor(c, RoomSpec.colors))));
      void mint(String when) => expect(goniSkinFor(c, RoomSpec.colors), isNull, reason: when);

      mint('at the greeting');
      c.endGreeting();
      mint('when the first question is shown');
      c.replayPrompt();
      mint('when the question is asked again');
      await c.chooseOption(wrongOption(starter, lesson, 0));
      mint('after a wrong answer');
      c.showHint();
      mint('at the first hint');
      c.showHint();
      mint('at the second hint');
      await c.unsure();
      mint('after "not sure"');

      final Activity first = c.current;
      await c.chooseOption(rightOption(starter, lesson, 0));
      expect(c.solved, isTrue);
      expect(
        goniSkinFor(c, RoomSpec.colors),
        skinForAnswer(first),
        reason: 'the colour the child just found, once the answer is right',
      );
      expect(goniSkinFor(c, RoomSpec.colors), isNotNull);
      expect(goniSkinFor(c, RoomSpec.numbers), isNull, reason: 'only in Colour Bay');
      expect(goniSkinFor(c, null), isNull, reason: 'with the rooms off nothing changes');

      c.next();
      mint('when the next question is shown');
      expect(c.bubble, c.current.promptLine.caption, reason: 'the next question is on the screen');

      for (final (bool solved, FeedbackKind feedback, GoniSkin? skin) in frames) {
        if (!(solved && feedback == FeedbackKind.correct)) {
          expect(
            skin,
            isNull,
            reason: 'a frame that is not after a right answer: solved=$solved feedback=$feedback',
          );
        }
      }
      expect(frames.where((f) => f.$3 != null), isNotEmpty);
      expect(frames.last.$3, isNull);
    });

    test('a lesson that ends: no skin on the last frame of a turn, the card has the lesson\'s skin (not when it ended for rest)', () async {
      final LessonController c = make();
      c.endGreeting();
      for (int i = 0; i < lesson.itemIds.length; i++) {
        await c.chooseOption(rightOption(starter, lesson, i));
        c.next();
      }
      expect(c.finished, isTrue);
      expect(goniSkinFor(c, RoomSpec.colors), isNull, reason: 'the card has its own skin, not the answer\'s');
      expect(goniCardSkin(c, RoomSpec.colors), skinForLesson(askedItems(c.items)));
      expect(goniCardSkin(c, RoomSpec.shapes), isNull);
      expect(goniCardSkin(c, null), isNull);
    });
  });

  group('the host picture', () {
    Widget host({
      GoniSkin? skin,
      HostPose pose = HostPose.celebrate,
      HostSpec spec = HostSpec.goni,
      bool reduced = false,
      bool hop = true,
    }) => MediaQuery(
      data: MediaQueryData(disableAnimations: reduced),
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Center(
          child: SizedBox(
            width: 200,
            height: 200,
            child: HostView(host: spec, pose: pose, skin: skin, hop: hop),
          ),
        ),
      ),
    );

    /// The picture on top: the newest child of the switcher (an older one is still fading out during a change).
    GoniSkin? drawn(WidgetTester tester) {
      final SvgPicture top = tester.widgetList<SvgPicture>(find.byType(SvgPicture)).last;
      return (top.bytesLoader as SvgAssetLoader).colorMapper as GoniSkin?;
    }

    Duration fade(WidgetTester tester) =>
        tester.widget<AnimatedSwitcher>(find.byType(AnimatedSwitcher)).duration;

    testWidgets('mint has no colour mapping; a change of pose alone cross-fades in 140 ms', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(host(pose: HostPose.idle));
      expect(drawn(tester), isNull);
      await tester.pumpWidget(host(pose: HostPose.talk));
      expect(drawn(tester), isNull);
      expect(fade(tester), const Duration(milliseconds: 140));
    });

    testWidgets(
      'a skin comes in over 250 ms and goes back to mint over 400 ms, with the pose change that goes with it',
      (WidgetTester tester) async {
        await tester.pumpWidget(host(pose: HostPose.talk));
        await tester.pumpWidget(host(pose: HostPose.celebrate, skin: GoniSkin.of('red')));
        expect(drawn(tester), GoniSkin.of('red'));
        expect(fade(tester), const Duration(milliseconds: 250));
        await tester.pump(const Duration(milliseconds: 300));
        expect(find.byType(SvgPicture), findsOneWidget, reason: 'the old picture has faded out');
        await tester.pump(const Duration(seconds: 1));
        await tester.pumpWidget(host(pose: HostPose.talk));
        expect(drawn(tester), isNull);
        expect(fade(tester), const Duration(milliseconds: 400));
        await tester.pump(const Duration(milliseconds: 100));
        expect(find.byType(SvgPicture), findsNWidgets(2), reason: 'still cross-fading at 100 ms of 400');
        await tester.pump(const Duration(milliseconds: 400));
        expect(find.byType(SvgPicture), findsOneWidget);
      },
    );

    testWidgets(
      'a host that appears wearing a skin shows mint for one frame and then takes it; with reduce motion it has it at once',
      (WidgetTester tester) async {
        await tester.pumpWidget(host(skin: GoniSkin.of('blue')));
        expect(drawn(tester), isNull);
        await tester.pump();
        expect(drawn(tester), GoniSkin.of('blue'));
        expect(fade(tester), const Duration(milliseconds: 250));
        await tester.pump(const Duration(seconds: 1));

        await tester.pumpWidget(const SizedBox());
        await tester.pumpWidget(host(skin: GoniSkin.of('blue'), reduced: true));
        expect(drawn(tester), GoniSkin.of('blue'));
      },
    );

    testWidgets('the ripple steps every 350 ms with 120 ms between steps, then holds the last step', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(host(skin: GoniSkin.ripple));
      await tester.pump();
      expect(drawn(tester), GoniSkin.ripple.atStep(0));
      final List<int> steps = <int>[];
      await tester.pump(const Duration(milliseconds: 100));
      for (int i = 0; i < 4; i++) {
        if (i > 0) expect(fade(tester), GoniSkin.rippleFade, reason: 'between two steps');
        steps.add(drawn(tester)!.step);
        await tester.pump(const Duration(milliseconds: 350));
      }
      expect(steps, <int>[0, 1, 2, 3]);
      await tester.pump(const Duration(seconds: 3));
      expect(drawn(tester), GoniSkin.ripple.atStep(3), reason: 'it holds the last step through the praise');
      expect(find.byType(SvgPicture), findsOneWidget);
      await tester.pumpWidget(host());
      expect(drawn(tester), isNull);
      expect(fade(tester), const Duration(milliseconds: 400));
      await tester.pump(const Duration(seconds: 1));
    });

    testWidgets('with reduce motion there is no ripple: one still rainbow frame, in and out by cross-fade', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(host(pose: HostPose.talk, reduced: true));
      await tester.pumpWidget(host(pose: HostPose.celebrate, skin: GoniSkin.ripple, reduced: true));
      expect(drawn(tester), GoniSkin.ripple.atStep(0));
      expect(fade(tester), const Duration(milliseconds: 250));
      for (int i = 0; i < 6; i++) {
        await tester.pump(const Duration(milliseconds: 350));
        expect(drawn(tester), GoniSkin.ripple.atStep(0), reason: 'never steps');
      }
      await tester.pumpWidget(host(pose: HostPose.talk, reduced: true));
      expect(drawn(tester), isNull);
      expect(fade(tester), const Duration(milliseconds: 400));
      await tester.pump(const Duration(seconds: 1));
    });

    testWidgets(
      'the celebrate pose hops as it starts, unless the hop is turned off (the last step of a Show)',
      (WidgetTester tester) async {
        double lift() =>
            tester.widget<FractionalTranslation>(find.byType(FractionalTranslation)).translation.dy;
        await tester.pumpWidget(host(pose: HostPose.talk));
        await tester.pumpWidget(host(pose: HostPose.celebrate));
        await tester.pump(const Duration(milliseconds: 100));
        expect(lift(), lessThan(-0.05), reason: 'the first hop is at its top');
        await tester.pump(const Duration(seconds: 1));
        expect(lift(), 0);

        await tester.pumpWidget(host(pose: HostPose.talk, hop: false));
        await tester.pumpWidget(host(pose: HostPose.celebrate, hop: false));
        await tester.pump(const Duration(milliseconds: 100));
        expect(lift(), 0, reason: 'no hop');
        await tester.pump(const Duration(seconds: 1));
      },
    );

    testWidgets('another host ignores a skin', (WidgetTester tester) async {
      await tester.pumpWidget(host(spec: HostSpec.kubi, skin: GoniSkin.of('red')));
      await tester.pump();
      expect(drawn(tester), isNull);
    });
  });
}
