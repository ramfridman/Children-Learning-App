import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nitznutz/child/activity_shell.dart' show ActivitySpec;
import 'package:nitznutz/content/arc_checks.dart' show hintFamilyOf, hintFamilyRepresentation;
import 'package:nitznutz/content/models.dart';
import 'package:nitznutz/engine/age.dart';
import 'package:nitznutz/play/balance_session.dart';
import 'package:nitznutz/play/build_pattern_session.dart';
import 'package:nitznutz/play/clock_set_session.dart';
import 'package:nitznutz/play/count_tap_session.dart';
import 'package:nitznutz/play/give_n_session.dart';
import 'package:nitznutz/play/lesson_arc.dart';
import 'package:nitznutz/play/lesson_controller.dart';
import 'package:nitznutz/play/number_line_session.dart';
import 'package:nitznutz/play/robot_path_session.dart';
import 'package:nitznutz/play/shop_pay_session.dart';
import 'package:nitznutz/play/show_predict.dart';
import 'package:nitznutz/play/show_stage.dart';
import 'package:nitznutz/play/sort_drag_session.dart';
import 'package:nitznutz/play/template_session.dart';

import 'support/arc.dart';
import 'support/fakes.dart';
import 'support/harness.dart';
import 'support/starter.dart';

/// The Show and lead players of the templates the pilot did not need (M11 Stage 2, docs/milestones/M11-stage2.md sections 2.1 and 7.3 criterion 10): in
/// a Show the host does every step but the last and the child does that one, in a Together item the host does its first `lead` steps; nothing a Show does
/// is written, a touch while the host acts is no move, a wrong touch is only "let's look again", and with reduced movement every step still comes, in place.
void main() {
  late PackContent content;
  setUpAll(() async {
    await loadAppFonts();
    content = await loadSourcePack();
  });

  final List<AttemptRecord> written = <AttemptRecord>[];
  setUp(written.clear);

  /// The first visit of the lesson that opens with the Show [showId], as a child new to the skill has it (the full Show).
  LessonController showVisit(String showId) {
    final String lesson = content.lessons.values.firstWhere((Lesson l) => l.parts?.show == showId).id;
    return arcController(content, lesson, planOf(content, lesson, PresentationStage.p4, newChild), written);
  }

  /// The visit of the lesson that has [itemId] as its Together item, at the Together step; its lead is [LessonController.step].
  LessonController togetherVisit(String itemId, {SkillStanding standing = newChild}) {
    final String lesson = content.lessons.values
        .firstWhere((Lesson l) => l.parts?.together.any((TogetherItem t) => t.id == itemId) ?? false)
        .id;
    final LessonController c = arcController(
      content,
      lesson,
      planOf(content, lesson, PresentationStage.p4, standing),
      written,
    );
    goTo(c, ArcPart.together);
    return c;
  }

  /// A Show runs to the child's step: the host acts (and a touch is no move), then stops; [child] makes the last step, which ends it with nothing written.
  Future<void> runShow(
    WidgetTester t,
    TemplateSession s,
    LessonController c, {
    required void Function() whileHosting,
    required void Function() afterHost,
    required Future<void> Function() child,
    bool still = false,
  }) async {
    s.stillHost = still;
    await hostSession(t, s);
    s.startHost();
    await t.pump();
    expect(s.hosting, isTrue);
    expect(c.noHelp, isTrue);
    whileHosting();
    await passTime(t, 45000);
    expect(s.hosting, isFalse, reason: 'the host stops, the child has its step');
    expect(s.canMoveOn.value, isTrue, reason: 'a quiet next is offered once the host has done its part');
    afterHost();
    expect(c.solved, isFalse);
    await child();
    expect(c.solved, isTrue);
    expect(written, isEmpty, reason: 'a Show writes nothing');
    // (the lesson goes on after the praise, and the session is reset for the next item: what a test reads of the Show it reads before that)
  }

  group('number_line', () {
    for (final bool still in <bool>[false, true]) {
      testWidgets(
        'a jump Show: the host hops three times, the child the last${still ? ' (reduced movement)' : ''}',
        (WidgetTester t) async {
          final LessonController c = showVisit('show.num-b-01');
          final NumberLineSession s = NumberLineSession(c, c.current as NumberLineActivity);
          await runShow(
            t,
            s,
            c,
            still: still,
            whileHosting: () {
              unawaited(s.choose(14));
              expect(c.solved, isFalse);
            },
            afterHost: () => expect(s.markerAt, 13),
            child: () async {
              // a wrong tick is "let's look again": nothing is written, the marker stays
              await s.choose(16);
              await t.pump(const Duration(milliseconds: 1200));
              expect(c.solved, isFalse);
              expect(s.markerAt, 13);
              await s.choose(14);
            },
          );
          expect(s.markerAt, 14);
          s.dispose();
        },
      );
    }

    testWidgets('a place Show: the host points at ticks, the child puts the frog on the last', (
      WidgetTester t,
    ) async {
      final LessonController c = showVisit('show.num-b-10');
      final NumberLineSession s = NumberLineSession(c, c.current as NumberLineActivity);
      await runShow(
        t,
        s,
        c,
        whileHosting: () {},
        afterHost: () {
          expect(s.markerAt, isNull);
          expect(s.trail, containsAll(<int>[4, 7]));
        },
        child: () => s.choose(7),
      );
      s.dispose();
    });

    testWidgets('a line with ticks of ten takes a touch to the nearest tick when the answer is a tick', (
      WidgetTester t,
    ) async {
      final NumberLineActivity jump = content.activities['b.numb17.7']! as NumberLineActivity;
      expect(jump.snapped(34), jump.snapsToTicks ? 30 : 34);
      final NumberLineActivity estimate = content.activities['c.numc06.1']! as NumberLineActivity;
      expect(estimate.snapsToTicks, isFalse, reason: 'an estimate is touched anywhere');
      expect(estimate.snapped(47), 47);
    });

    testWidgets('a Together lead: the host hops once, then the child says where it lands', (
      WidgetTester t,
    ) async {
      final LessonController c = togetherVisit('b.mathb08.1');
      final NumberLineSession s = NumberLineSession(c, c.current as NumberLineActivity);
      await hostSession(t, s);
      s.startHost();
      await passTime(t, 20000);
      expect(c.leading, isFalse);
      expect(s.markerAt, 10, reason: 'the first hop of [2, 3] from 8');
      expect(written, isEmpty);
      s.dispose();
    });

    test('the tag of a wrong tick: the number the other way round, a count that starts again at the ten, one step for ten', () {
      NumberLineActivity line(String from, Map<String, Object?> edit) {
        final Activity base = content.activities[from]!;
        final Map<String, Object?> json = _copy(base.json);
        final Map<String, Object?> answer = json['answer']! as Map<String, Object?>;
        final Map<String, Object?> scene = json['scene']! as Map<String, Object?>;
        scene.addAll(edit['scene']! as Map<String, Object?>);
        answer.addAll(edit['answer']! as Map<String, Object?>);
        return Activity.fromJson(json, base.assets) as NumberLineActivity;
      }

      final NumberLineActivity decade = line('b.numb02.1', <String, Object?>{
        'scene': <String, Object?>{
          'from': 10,
          'to': 30,
          'start': 19,
          'hops': <int>[1],
        },
        'answer': <String, Object?>{
          'target': 20,
          'misconception': 'M-CNT-SEQ',
          'classifiers': <Object?>[
            <String, Object?>{'when': 'restart_at_ten', 'misconception': 'M-CNT-DECADE'},
            <String, Object?>{'when': 'reversed_number', 'misconception': 'M-NUM-REV'},
          ],
        },
      });
      expect(decade.wrongTagFor(10), 'M-CNT-DECADE');
      expect(decade.wrongTagFor(21), 'M-CNT-SEQ');
      final NumberLineActivity tens = line('b.numb17.7', <String, Object?>{
        'scene': <String, Object?>{
          'from': 20,
          'to': 40,
          'start': 30,
          'hops': <int>[10],
        },
        'answer': <String, Object?>{
          'target': 40,
          'misconception': 'M-CNT-SEQ',
          'mirrorMisconception': 'M-NL-DIR',
          'classifiers': <Object?>[
            <String, Object?>{'when': 'plus_one_for_ten', 'misconception': 'M-PV-ZERO'},
          ],
        },
      });
      expect(tens.wrongTagFor(31), 'M-PV-ZERO');
      expect(tens.wrongTagFor(20), 'M-NL-DIR', reason: 'the mirror of the right tick comes first');
      expect(NumberLineActivity.reverseOf(13), 31);
    });
  });

  group('give_n', () {
    testWidgets('a Show: the host gives two, the child the third, and no more is taken', (
      WidgetTester t,
    ) async {
      final LessonController c = showVisit('show.num-a-06');
      final GiveNSession s = GiveNSession(c, c.current as GiveNActivity);
      final GiveNActivity a = s.activity;
      await runShow(
        t,
        s,
        c,
        whileHosting: () {},
        afterHost: () => expect(s.placed, <int>[0, 1]),
        child: () async {
          final Offset stage = t.getTopLeft(find.byKey(const Key('give-stage')));
          final GiveLayout l = GiveLayout(t.getSize(find.byKey(const Key('give-stage'))), a);
          await t.tapAt(stage + l.pile[2]);
          await t.pump();
          await t.tapAt(stage + l.flower.center);
          await t.pump();
        },
      );
      expect(s.placed, <int>[0, 1, 2]);
      s.dispose();
    });

    testWidgets('a prefilled frame: the objects in it stay, and the child adds only n', (
      WidgetTester t,
    ) async {
      final GiveNActivity a = content.activities['c.numb09.9']! as GiveNActivity;
      expect(a.prefilled, 7);
      expect(a.n, 3);
      expect(a.cellCount, 7 + a.sourceCount);
      final LessonController c = LessonController(
        content: content,
        lesson: content.lessons.values.firstWhere((Lesson l) => l.itemIds.contains(a.id)),
        profileId: 'p-1',
        clock: FixedClock(1793000000000),
        record: (AttemptRecord r) async => written.add(r),
      );
      _goToItem(c, a.id);
      final GiveNSession s = GiveNSession(c, a);
      await hostSession(t, s);
      expect(find.byKey(const Key('give-prefilled-6')), findsOneWidget);
      expect(find.byKey(const Key('give-prefilled-7')), findsNothing);
      expect(find.text('7'), findsOneWidget, reason: 'the counter says what the frame holds');
      s.dispose();
    });

    testWidgets('a Together lead: the host gives the first object', (WidgetTester t) async {
      final LessonController c = togetherVisit('give.ladybugs.2');
      final GiveNSession s = GiveNSession(c, c.current as GiveNActivity);
      await hostSession(t, s);
      s.startHost();
      await passTime(t, 20000);
      expect(c.leading, isFalse);
      expect(s.placed.length, c.step!.lead);
      s.dispose();
    });
  });

  group('the numeral of a give-N item', () {
    test(
      'is read from the prompt (the bubble draws it under the question, as for every activity that has one)',
      () {
        final Activity base = content.activities['give.ladybugs.2']!;
        final Map<String, Object?> json = _copy(base.json);
        json['templateVersion'] = '1.3';
        (json['prompt']! as Map<String, Object?>)['math'] = <Object?>['n:2'];
        final Activity numeral = Activity.fromJson(json, base.assets);
        expect(numeral.promptMath, <String>['n:2']);
      },
    );
  });

  group('count_tap', () {
    testWidgets(
      'a Show: the host touches the objects but the last, the child the last, and it is not asked "how many?"',
      (WidgetTester t) async {
        final LessonController c = showVisit('show.num-a-03');
        final CountTapSession s = CountTapSession(c, c.current as CountTapActivity);
        await runShow(
          t,
          s,
          c,
          whileHosting: () {
            s.tapObject(3);
            expect(s.counted, isNot(contains(3)));
          },
          afterHost: () => expect(s.counted, <int>{0, 1, 2}),
          child: () async => s.tapObject(3),
        );
        expect(s.answering, isFalse);
        s.dispose();
      },
    );

    testWidgets(
      'a Show that touches five in one run (reduced movement): all five are counted, then the sixth is the child\'s',
      (WidgetTester t) async {
        final LessonController c = showVisit('show.num-a-09');
        final CountTapSession s = CountTapSession(c, c.current as CountTapActivity);
        await runShow(
          t,
          s,
          c,
          still: true,
          whileHosting: () {},
          afterHost: () => expect(s.counted.length, 5),
          child: () async => s.tapObject(5),
        );
        s.dispose();
      },
    );

    testWidgets('a Together lead keeps the touched objects counted', (WidgetTester t) async {
      final LessonController c = togetherVisit('count.ladybugs.6');
      final CountTapSession s = CountTapSession(c, c.current as CountTapActivity);
      await hostSession(t, s);
      s.startHost();
      await passTime(t, 20000);
      expect(c.leading, isFalse);
      expect(s.counted.length, c.step!.lead);
      s.dispose();
    });
  });

  group('build_pattern', () {
    testWidgets(
      'a Show: the host lays the first cells in order, the child the last; a wrong picture is "let\'s look again"',
      (WidgetTester t) async {
        final LessonController c = showVisit('show.log-a-08');
        final BuildPatternSession s = BuildPatternSession(c, c.current as BuildPatternActivity);
        final ShowStep last = s.activity.show!.childStep;
        await runShow(
          t,
          s,
          c,
          whileHosting: () {
            unawaited(s.place(last.piece!));
            expect(s.filled.last, isNull);
          },
          afterHost: () => expect(s.filled, <String?>[
            s.activity.show!.hostSteps[0].piece,
            s.activity.show!.hostSteps[1].piece,
            null,
          ]),
          child: () async {
            final String wrong = s.activity.palette.firstWhere((String p) => p != last.piece);
            await s.place(wrong);
            await t.pump(const Duration(milliseconds: 1200));
            expect(s.filled.last, isNull);
            await s.place(last.piece!);
          },
        );
        expect(s.filled.last, last.piece);
        s.dispose();
      },
    );

    testWidgets('a Together lead: the host lays the first place of a copy', (WidgetTester t) async {
      final LessonController c = togetherVisit('log.copy.colours');
      final BuildPatternSession s = BuildPatternSession(c, c.current as BuildPatternActivity);
      await hostSession(t, s);
      s.startHost();
      await passTime(t, 20000);
      expect(c.leading, isFalse);
      expect(s.filled.where((String? f) => f != null).length, c.step!.lead);
      expect(s.filled.first, s.activity.sequence.first);
      s.dispose();
    });

    testWidgets(
      'given cells: a right one stays, a wrong one is replaced, and the tag is that of the picture in the first wrong place',
      (WidgetTester t) async {
        final BuildPatternActivity a = content.activities['log.next.colours']! as BuildPatternActivity;
        expect(a.given.length, 5);
        final LessonController c = LessonController(
          content: content,
          lesson: content.lessons.values.firstWhere((Lesson l) => l.itemIds.contains(a.id)),
          profileId: 'p-1',
          clock: FixedClock(1793000000000),
          record: (AttemptRecord r) async => written.add(r),
        );
        _goToItem(c, a.id);
        final BuildPatternSession s = BuildPatternSession(c, a);
        await hostSession(t, s);
        expect(s.filled.take(5), a.given.values);
        s.clear(0);
        expect(s.filled.first, a.given[0], reason: 'a given cell that is right cannot be taken out');
        // the green ball laid first where the red ball... (the item's palette tag) is written with its tag
        final String green = a.pieceTags.keys.first;
        await s.place(green);
        await s.place(a.sequence[6]);
        await t.pump(const Duration(milliseconds: 200));
        expect(written.single.misconceptionTag, a.pieceTags[green]);
        s.dispose();
      },
    );
  });

  group('balance', () {
    testWidgets('a weighing Show: the host adds blocks, the child the last; the pans level', (
      WidgetTester t,
    ) async {
      final LessonController c = showVisit('show.math-b-18');
      final BalanceSession s = BalanceSession(c, c.current as BalanceActivity);
      await runShow(
        t,
        s,
        c,
        whileHosting: () => unawaited(s.addBlock()),
        afterHost: () {
          expect(s.added, 3);
          expect(s.leftWeight == s.rightWeight, isFalse);
        },
        child: s.addBlock,
      );
      expect(s.added, 4);
      expect(s.leftWeight, s.rightWeight);
      s.dispose();
    });

    testWidgets('a comparing Show puts the things on one group at a time, the host\'s pan first', (
      WidgetTester t,
    ) async {
      final LessonController c = showVisit('show.math-b-09');
      final BalanceSession s = BalanceSession(c, c.current as BalanceActivity);
      await runShow(
        t,
        s,
        c,
        still: true,
        whileHosting: () {},
        afterHost: () {
          expect(s.leftGroups, 2);
          expect(s.rightGroups, 0);
          expect(s.leftWeight, 7);
        },
        child: s.addBlock,
      );
      expect(s.rightWeight, s.leftWeight);
      s.dispose();
    });

    testWidgets('a Together lead: the host puts the first block on', (WidgetTester t) async {
      final LessonController c = togetherVisit('b.mathb02.2');
      final BalanceSession s = BalanceSession(c, c.current as BalanceActivity);
      await hostSession(t, s);
      s.startHost();
      await passTime(t, 20000);
      expect(c.leading, isFalse);
      expect(s.added, c.step!.lead);
      s.dispose();
    });
  });

  group('shop_pay', () {
    testWidgets('a Show: the host lays three tens, the child lays the one; the counter says the sum', (
      WidgetTester t,
    ) async {
      final LessonController c = showVisit('show.num-c-03');
      final ShopPaySession s = ShopPaySession(c, c.current as ShopPayActivity);
      final String one = s.purse.firstWhere((PurseCoin p) => p.kind == 's1').id;
      final String ten = s.purse
          .firstWhere((PurseCoin p) => p.kind == 's10' && !s.onCounter.contains(p.id))
          .id;
      await runShow(
        t,
        s,
        c,
        whileHosting: () => s.toggle(one),
        afterHost: () => expect(s.total, 3000),
        child: () async {
          // a coin of another kind than the one the host left is "let's look again"
          s.toggle(s.purse.firstWhere((PurseCoin p) => p.kind == 's10' && !s.onCounter.contains(p.id)).id);
          await t.pump(const Duration(milliseconds: 1200));
          expect(s.total, 3000);
          s.toggle(one);
        },
      );
      expect(s.total, 3100);
      expect(ten, isNotEmpty);
      s.dispose();
    });

    testWidgets('a Together lead lays the biggest coin of the fewest-coin way', (WidgetTester t) async {
      final LessonController c = togetherVisit('x.mathb17.6');
      final ShopPaySession s = ShopPaySession(c, c.current as ShopPayActivity);
      await hostSession(t, s);
      s.startHost();
      await passTime(t, 20000);
      expect(c.leading, isFalse);
      expect(s.onCounter.length, c.step!.lead);
      expect(s.total, 500, reason: 'the five-shekel coin of a price of 8');
      s.dispose();
    });

    test('a wrong payment is told by how the price was read', () {
      final Activity base = content.activities['c.numc03.1']!;
      final Map<String, Object?> json = _copy(base.json);
      final Map<String, Object?> answer = json['answer']! as Map<String, Object?>;
      answer['misconception'] = 'M-PV-ZERO';
      answer['classifiers'] = <Object?>[
        <String, Object?>{'when': 'paid_digits', 'misconception': 'M-PV-FACE'},
        <String, Object?>{'when': 'paid_reversed', 'misconception': 'M-NUM-REV'},
      ];
      final ShopPayActivity a = Activity.fromJson(json, base.assets) as ShopPayActivity;
      expect(a.price, 3400);
      expect(a.wrongTagFor(700, 2), 'M-PV-FACE', reason: '3 and 4 paid as 7');
      expect(a.wrongTagFor(4300, 7), 'M-NUM-REV');
      expect(a.wrongTagFor(3300, 34), 'M-MONEY-COUNT');
      expect(a.wrongTagFor(3000, 3), 'M-PV-ZERO');
    });
  });

  group('robot_path', () {
    testWidgets(
      'a direct-control Show: the host moves the robot, the child makes the last move onto the flag',
      (WidgetTester t) async {
        final LessonController c = showVisit('show.cs-a-03');
        final RobotPathSession s = RobotPathSession(c, c.current as RobotPathActivity);
        await runShow(
          t,
          s,
          c,
          whileHosting: () => unawaited(s.arrow('right')),
          afterHost: () => expect(s.pos, (2, 0)),
          child: () async {
            await s.arrow('up');
            await t.pump(const Duration(milliseconds: 1200));
            expect(c.solved, isFalse);
            await s.arrow('right');
          },
        );
        expect(s.pos, s.activity.goalAt);
        s.dispose();
      },
    );

    testWidgets('a plan Show: the host lays the cards, the child the last, then the plan runs', (
      WidgetTester t,
    ) async {
      final LessonController c = showVisit('show.cs-a-04');
      final RobotPathSession s = RobotPathSession(c, c.current as RobotPathActivity);
      await runShow(
        t,
        s,
        c,
        whileHosting: () {},
        afterHost: () => expect(s.program, <String>['up', 'up', 'right']),
        // the plan is run on screen before the Show ends: the child's touch starts it, and the time must pass for it
        child: () async {
          unawaited(s.arrow('right'));
          await passTime(t, 3000);
        },
      );
      expect(s.program.length, 4);
      s.dispose();
    });

    testWidgets('a Together lead lays the first arrow', (WidgetTester t) async {
      final LessonController c = togetherVisit('cs.robot.plan.1');
      final RobotPathSession s = RobotPathSession(c, c.current as RobotPathActivity);
      await hostSession(t, s);
      s.startHost();
      await passTime(t, 20000);
      expect(c.leading, isFalse);
      expect(s.program.length, c.step!.lead);
      s.dispose();
    });
  });

  group('clock_set', () {
    testWidgets('a Show: the host turns the short hand hour by hour, the child to the last hour', (
      WidgetTester t,
    ) async {
      final LessonController c = showVisit('show.math-b-15');
      final ClockSetSession s = ClockSetSession(c, c.current as ClockSetActivity);
      await runShow(
        t,
        s,
        c,
        whileHosting: s.next,
        afterHost: () => expect(s.hour, 2),
        child: () async => s.next(),
      );
      expect(s.hour, 3);
      s.dispose();
    });
  });

  group('sort_drag in share mode', () {
    testWidgets('a Together lead deals the first card to the first friend', (WidgetTester t) async {
      final LessonController c = togetherVisit('b.mathb10.1');
      final SortDragSession s = SortDragSession(c, c.current as SortDragActivity);
      expect(s.activity.share, isTrue);
      await hostSession(t, s);
      s.startHost();
      await passTime(t, 20000);
      expect(c.leading, isFalse);
      expect(s.placed.length, c.step!.lead);
      expect(s.placed[s.activity.items.first.id], s.activity.bins.first.id);
      s.dispose();
    });
  });

  group('hint 2 of a sort draws the picture of its family', () {
    for (final (String, String) h in <(String, String)>[
      ('b.shpb03.2', 'the sticks'),
      ('b15.shpa07.2', 'the push'),
      ('b.shpb08.2', 'the push of the solid'),
    ]) {
      testWidgets('${h.$1}: ${h.$2} is drawn on the next picture, which goes to no bin', (
        WidgetTester t,
      ) async {
        final SortDragActivity a = content.activities[h.$1]! as SortDragActivity;
        final String family = hintFamilyOf(a.hints[1].say.vo)!;
        expect(hintFamilyRepresentation.containsKey(family), isTrue);
        final LessonController c = LessonController(
          content: content,
          lesson: content.lessons.values.firstWhere((Lesson l) => l.itemIds.contains(a.id)),
          profileId: 'p-1',
          clock: FixedClock(1793000000000),
          record: (AttemptRecord r) async => written.add(r),
        );
        _goToItem(c, a.id);
        final SortDragSession s = SortDragSession(c, a);
        final ShowArt art = (await t.runAsync(ShowArt.load))!;
        s.showStyle = ShowStyle(art: art, deep: const Color(0xFF1E7F4C), lip: const Color(0xFF1E7F4C));
        await hostSession(t, s);
        c.showHint();
        c.showHint();
        await passTime(t, 800);
        expect(s.hosting, isTrue, reason: 'the motion is on the stage');
        expect(s.showMarks.spot, isNotNull, reason: 'the next picture is lifted to the middle');
        await passTime(t, 20000);
        expect(s.hosting, isFalse);
        expect(s.placed, isEmpty, reason: 'a hint shows how to look, never where to put it');
        expect(s.showMarks.active, isFalse);
        s.dispose();
      });
    }
  });

  group('a borrowed item is one screen, one attempt', () {
    test('no visit of any lesson in parts serves one item twice, whatever the standing and the look', () {
      int visits = 0;
      for (final Lesson l in content.lessons.values.where((Lesson l) => l.parts != null)) {
        for (final SkillStanding standing in <SkillStanding>[newChild, learningChild, masteredChild]) {
          for (final PresentationStage stage in PresentationStage.values) {
            final ArcPlan? plan = planOrNull(content, l.id, stage, standing);
            if (plan == null) continue;
            visits++;
            final List<String> ids = <String>[
              for (final ArcStep s in plan.steps)
                if (s.part != ArcPart.show) s.activity.id,
            ];
            expect(ids.toSet().length, ids.length, reason: '${l.id} $standing ${stage.name}: $ids');
          }
        }
      }
      expect(visits, greaterThan(500));
    });
  });

  group('the guess tiles', () {
    testWidgets('two tiles with a word each: a touch is the guess, lit and nothing more', (
      WidgetTester t,
    ) async {
      final LessonController c = showVisit('show.cs-a-03');
      final RobotPathSession s = RobotPathSession(c, c.current as RobotPathActivity);
      final Activity base = content.activities['show.cs-a-03']!;
      final Map<String, Object?> json = _copy(base.json);
      final Map<String, Object?> predict =
          (json['show']! as Map<String, Object?>)['predict']! as Map<String, Object?>;
      predict['choices'] = <Object?>[
        <String, Object?>{'id': 'o1', 'label': 'a'},
        <String, Object?>{'id': 'o2', 'label': 'b'},
      ];
      final ShowPredict ask = Activity.fromJson(json, base.assets).show!.predict!;
      expect(ask.asksForGuess, isTrue);
      final Future<void> asked = s.ask(ask);
      await t.pumpWidget(
        MaterialApp(
          home: Directionality(
            textDirection: TextDirection.rtl,
            child: Scaffold(
              body: GuessTiles(session: s, predict: ask, spec: ActivitySpec.phone),
            ),
          ),
        ),
      );
      await passTime(t, 3000);
      expect(find.byKey(const Key('guess-o1')), findsOneWidget);
      await t.tap(find.byKey(const Key('guess-o1')));
      await passTime(t, 2000);
      await asked;
      expect(s.guessedId, 'o1');
      expect(written, isEmpty);
      s.dispose();
    });
  });

  group('predict, then watch', () {
    testWidgets(
      'the host asks and waits for a guess, which is written nowhere and told neither right nor wrong',
      (WidgetTester t) async {
        final LessonController c = showVisit('show.cs-a-03');
        final RobotPathSession s = RobotPathSession(c, c.current as RobotPathActivity);
        expect(s.activity.show!.predict, isNotNull);
        await hostSession(t, s);
        s.startHost();
        await passTime(t, 6000);
        // a question with no answers on offer is only asked: the host waits a moment and goes on
        expect(s.predicting.value, isNull);
        expect(s.hosting, isTrue);
        await passTime(t, 45000);
        expect(s.hosting, isFalse);
        expect(written, isEmpty);
        s.dispose();
      },
    );

    testWidgets('with two answers the host waits for the child\'s touch, then runs the example', (
      WidgetTester t,
    ) async {
      final LessonController c = showVisit('show.cs-a-03');
      final RobotPathSession s = RobotPathSession(c, c.current as RobotPathActivity);
      final Activity base = content.activities['show.cs-a-03']!;
      final Map<String, Object?> json = _copy(base.json);
      final Map<String, Object?> predict =
          (json['show']! as Map<String, Object?>)['predict']! as Map<String, Object?>;
      predict['choices'] = <Object?>[
        <String, Object?>{'id': 'o1', 'label': 'a'},
        <String, Object?>{'id': 'o2', 'label': 'b'},
      ];
      final ShowPredict ask = Activity.fromJson(json, base.assets).show!.predict!;
      await hostSession(t, s);
      final Future<void> asked = s.ask(ask);
      await passTime(t, 5000);
      expect(s.predicting.value, ask);
      s.guess('o2');
      await passTime(t, 2000);
      await asked;
      expect(s.predicting.value, isNull);
      expect(s.guessedId, 'o2');
      expect(written, isEmpty);
      s.dispose();
    });
  });
}

/// A deep copy of a document, so that a test may change what it likes.
Map<String, Object?> _copy(Map<String, Object?> m) => jsonDecode(jsonEncode(m)) as Map<String, Object?>;

/// Moves the controller to the item [id] of its lesson (a lesson played flat has every item in order).
void _goToItem(LessonController c, String id) {
  for (int i = 0; i < 60 && c.current.id != id; i++) {
    c.next();
  }
  expect(c.current.id, id, reason: 'the lesson has the item');
}
