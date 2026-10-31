import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nitznutz/content/models.dart';
import 'package:nitznutz/design/board.dart';
import 'package:nitznutz/play/hint_hand.dart';
import 'package:nitznutz/play/lesson_screen.dart';
import 'package:nitznutz/play/shop_pay_session.dart';

import 'support/app_harness.dart';
import 'support/harness.dart';
import 'support/starter.dart';

/// B-40 level 3 of the shop and of sort and drag: the pointing hand comes from below, so that its body lies under the fingertip and
/// never covers what stands above the target: the running total and the gold places on the counter, and the label of a bin. Taken
/// on the real lesson screen of the four boards, at every moment the hand is shown (with "reduce motion" the hand is at its stop
/// at once, so every picture of the demonstration is a stop).
void main() {
  late PackContent content;
  setUpAll(() async {
    await loadAppFonts();
    content = await loadStarter();
  });

  final List<(String, Size)> boards = <(String, Size)>[
    ('phone', BoardClass.phone.size),
    ('phone_se', BoardClass.phoneSE.size),
    ('tablet_landscape', BoardClass.tabletLandscape.size),
    ('tablet_portrait', BoardClass.tabletPortrait.size),
  ];

  /// The box of the pointing hand as it is drawn, whichever way it is turned: the box that holds its four corners, on the board.
  Rect handBox(WidgetTester t) {
    final RenderBox box = t.renderObject<RenderBox>(find.byType(PointingHand).first);
    final List<Offset> corners = <Offset>[
      for (final Offset c in <Offset>[
        Offset.zero,
        Offset(box.size.width, 0),
        Offset(0, box.size.height),
        Offset(box.size.width, box.size.height),
      ])
        box.localToGlobal(c),
    ];
    final Iterable<double> xs = corners.map((Offset o) => o.dx);
    final Iterable<double> ys = corners.map((Offset o) => o.dy);
    return Rect.fromLTRB(
      xs.reduce((double a, double b) => a < b ? a : b),
      ys.reduce((double a, double b) => a < b ? a : b),
      xs.reduce((double a, double b) => a > b ? a : b),
      ys.reduce((double a, double b) => a > b ? a : b),
    );
  }

  List<Rect> rectsOf(WidgetTester t, Finder f) => <Rect>[
    for (int i = 0; i < f.evaluate().length; i++) t.getRect(f.at(i)),
  ];

  /// The fingertip of the hand: the middle of its tap ripple.
  Offset? fingertip(WidgetTester t) {
    final Finder ripple = find.byWidgetPredicate(
      (Widget w) => w.key is ValueKey<String> && (w.key! as ValueKey<String>).value.startsWith('ripple-'),
    );
    return ripple.evaluate().isEmpty ? null : t.getCenter(ripple.first);
  }

  /// The app on a board of [size], at the child's home.
  Future<void> openApp(WidgetTester t, Size size) async {
    await t.runAsync(warmHintHands);
    final AppRig rig = AppRig();
    await rig.seedFinishedSetup(name: 'נֹעָה');
    await rig.pump(t, size: size);
    await t.tap(find.text('נֹעָה'));
    await t.pumpAndSettle();
  }

  /// Opens [activity] as a lesson, presses the lamp three times and calls [sample] every 100 ms for as long as the hand is shown
  /// (the first two levels play for 6 s each, as in the golden pictures).
  Future<void> demonstration(
    WidgetTester t,
    String activity,
    void Function(Rect hand, Offset? tip, bool newStop) sample,
  ) async {
    final Lesson one = Lesson.mission(
      id: 'shot',
      itemIds: <String>[activity],
      skillIds: content.activities[activity]!.skills.map((Skill s) => s.id).toList(),
      celebration: content.lessons['butterflies']!.celebration,
    );
    final NavigatorState nav = t.state<NavigatorState>(find.byType(Navigator).first);
    nav.push(
      MaterialPageRoute<void>(
        builder: (BuildContext c) => LessonScreen(profileId: 'p-1', mission: one),
      ),
    );
    await t.pump(const Duration(milliseconds: 600));
    for (int spent = 0; spent < 2500; spent += 100) {
      await t.pump(const Duration(milliseconds: 100));
    }
    for (int level = 1; level <= 3; level++) {
      await t.tap(find.byKey(const Key('lesson-hint')), warnIfMissed: false);
      await t.pump(const Duration(milliseconds: 60));
      if (level < 3) {
        for (int spent = 0; spent < 6000; spent += 100) {
          await t.pump(const Duration(milliseconds: 100));
        }
      }
    }
    bool seen = false;
    Offset? last;
    for (int step = 0; step < 300; step++) {
      await t.pump(const Duration(milliseconds: 100));
      if (find.byType(PointingHand).evaluate().isEmpty) {
        if (seen) break;
        continue;
      }
      seen = true;
      final Offset? tip = fingertip(t);
      sample(handBox(t), tip, tip != last);
      last = tip;
    }
    expect(seen, isTrue, reason: '$activity: the hand was shown');
    nav.pop();
    await t.pump(const Duration(milliseconds: 600));
  }

  group('shop level 3', () {
    for (final (String, Size) board in boards) {
      testWidgets(
        'the hand never covers the running total or the places, and ends on each coin and the button, ${board.$1}',
        (WidgetTester t) async {
          await openApp(t, board.$2);
          for (final ShopPayActivity a in content.activities.values.whereType<ShopPayActivity>()) {
            int totals = 0;
            int stops = 0;
            await demonstration(t, a.id, (Rect hand, Offset? tip, bool newStop) {
              final String why = '${a.id} on ${board.$1}';
              final List<Rect> total = rectsOf(t, find.byKey(const Key('running-total')));
              totals += total.length;
              for (final Rect r in <Rect>[
                ...total,
                ...rectsOf(t, find.byKey(const Key('hint-place'))),
                ...rectsOf(t, find.byKey(const Key('hint-place-full'))),
                ...rectsOf(t, find.byKey(const Key('price'))),
              ]) {
                expect(hand.overlaps(r), isFalse, reason: '$why: the hand $hand covers $r');
              }
              if (newStop) {
                stops++;
                final List<Rect> targets = <Rect>[
                  for (final Rect r in rectsOf(
                    t,
                    find.byWidgetPredicate(
                      (Widget w) =>
                          w.key is ValueKey<String> && (w.key! as ValueKey<String>).value.startsWith('coin-'),
                    ),
                  ))
                    r.deflate(CoinFace.pad),
                  t.getRect(find.byKey(const Key('pay'))).deflate(PurseLayout.payMargin),
                ];
                expect(
                  targets.any((Rect r) => r.inflate(2).contains(tip!)),
                  isTrue,
                  reason: '$why: the fingertip $tip is on a coin or on the button',
                );
              }
            });
            expect(
              totals,
              greaterThan(0),
              reason: '${a.id}: the total was on the counter while the hand was shown',
            );
            expect(stops, greaterThanOrEqualTo(2), reason: '${a.id}: a coin at least, and the button');
          }
        },
      );
    }
  });

  group('sort and drag level 3', () {
    for (final (String, Size) board in boards) {
      testWidgets('the hand never covers the label of a bin, ${board.$1}', (WidgetTester t) async {
        final List<SortDragActivity> sorts = content.activities.values
            .whereType<SortDragActivity>()
            .where((SortDragActivity a) => !a.share)
            .toList();
        expect(sorts, isNotEmpty);
        await openApp(t, board.$2);
        for (final SortDragActivity a in sorts) {
          await demonstration(t, a.id, (Rect hand, Offset? tip, bool newStop) {
            for (final SortBin b in a.bins) {
              final Rect label = t.getRect(find.text(b.label));
              expect(
                hand.overlaps(label),
                isFalse,
                reason: '${a.id} on ${board.$1}: the hand $hand covers the label "${b.label}" at $label',
              );
            }
          });
        }
      });
    }
  });
}
