import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nitznutz/content/models.dart';
import 'package:nitznutz/engine/age.dart';
import 'package:nitznutz/play/hint_hand.dart';
import 'package:nitznutz/play/lesson_screen.dart';

import 'c1_screens.dart';
import 'harness.dart';

/// Every answer tile and keypad key on the screen: what the speech bubble must keep clear of.
Iterable<Rect> tilesOnScreen(WidgetTester t) sync* {
  for (final Element e in find.byKey(const Key('answer-tile')).evaluate()) {
    yield t.getRect(find.byWidget(e.widget));
  }
  final Finder keys = find.byWidgetPredicate((Widget w) {
    final Key? k = w.key;
    return k is ValueKey<String> && k.value.startsWith('key-');
  });
  for (final Element e in keys.evaluate()) {
    yield t.getRect(find.byWidget(e.widget));
  }
}

/// What the speech bubble covers: one line per tile it lies over; empty when there is no bubble or it keeps clear.
List<String> bubbleOverTiles(WidgetTester t) {
  final Finder bubble = find.byKey(const Key('bubble-body'));
  if (bubble.evaluate().isEmpty) return const <String>[];
  final Rect b = t.getRect(bubble.first);
  return <String>[
    for (final Rect tile in tilesOnScreen(t))
      if (b.intersect(tile) case final Rect hit when hit.width > 0.5 && hit.height > 0.5)
        'the bubble $b covers a tile $tile',
  ];
}

/// What the speech bubble covers of the stage on a phone board: one line when it reaches into it; empty when it keeps clear (B-29,
/// docs/design/b29-caption-overlap.md). The scene is what the child has to count, compare or read, so a bubble over it is a line the
/// content must shorten. A tablet's bubble stands above its stage's card, so tablets are not asked.
List<String> bubbleOverStage(WidgetTester t) {
  final Finder bubble = find.byKey(const Key('bubble-body'));
  final Finder stage = find.byKey(const Key('lesson-stage'));
  if (bubble.evaluate().isEmpty || stage.evaluate().isEmpty) return const <String>[];
  final Rect b = t.getRect(bubble.first);
  final Rect s = t.getRect(stage.first);
  final Rect hit = b.intersect(s);
  return hit.width > 0.5 && hit.height > 0.5
      ? <String>['the bubble $b lies ${hit.width.toStringAsFixed(0)} pt over the stage $s']
      : const <String>[];
}

/// The look a child of the audit has: a school stage and a birth (so the stage of the look P1 to P4), and the captions setting.
typedef AuditLook = ({String name, SchoolStage school, BirthMonth birth, String? captions});

/// The three looks the stage audit crosses with the board: the youngest with its captions turned on, and the two older ones, whose
/// captions show by themselves. (The rig's day is 2026-10-26.)
const List<AuditLook> auditLooks = <AuditLook>[
  (name: 'P1 captions on', school: SchoolStage.gan3, birth: BirthMonth(2023, 8), captions: 'on'),
  (name: 'P3', school: SchoolStage.gan5, birth: BirthMonth(2021, 3), captions: null),
  (name: 'P4', school: SchoolStage.grade2, birth: BirthMonth(2019, 5), captions: null),
];

/// [openOne] with the waits cut down to what the first frame of the bubble needs.
Future<void> openQuickly(WidgetTester t, PackContent content, Activity a) async {
  final NavigatorState nav = t.state<NavigatorState>(find.byType(Navigator).first);
  final Lesson one = Lesson.mission(
    id: 'shot',
    itemIds: <String>[a.id],
    skillIds: a.skills.map((Skill s) => s.id).toList(),
    celebration: content.lessons['butterflies']!.celebration,
  );
  nav.push(
    MaterialPageRoute<void>(
      builder: (BuildContext c) => LessonScreen(profileId: 'p-1', mission: one),
    ),
  );
  await t.pump(const Duration(milliseconds: 400));
  await waitSteps(t, 300);
}

/// What one audit pass found: the bubble over a tile (a defect of the layout, which must stay empty) and, on a phone board asked for it,
/// the bubble over the stage (a line that does not fit its column even at 14 points, a defect of the content that the text editor
/// shortens; counted, not yet failed).
typedef BubbleFindings = ({Map<String, List<String>> overTiles, Map<String, List<String>> overStage});

/// Opens each of [activities] on the board [size] at the system's text size [scale] (for the child of [look], or the oldest look when
/// null), and looks at the bubble at the start and at hint 1, 2 and 3. Returns the activities and states where it lay over a tile and,
/// with [stageToo], over the stage (one line each, naming them), so a failure says what to fix.
///
/// Only the bubble's place is looked at, so the waits are short: the bubble and the tiles stand where they will stand as soon as the
/// frame is built (the hint's hand is not drawn here, `warnIfMissed` taps a lamp the activity may not have).
Future<BubbleFindings> auditBubbles(
  WidgetTester t,
  PackContent content,
  Size size,
  double scale,
  List<Activity> activities, {
  AuditLook? look,
  bool stageToo = false,
}) async {
  t.platformDispatcher.textScaleFactorTestValue = scale;
  addTearDown(t.platformDispatcher.clearAllTestValues);
  await t.runAsync(warmHintHands);
  await startOn(t, content, size, look: look);
  final Map<String, List<String>> failures = <String, List<String>>{};
  final Map<String, List<String>> spills = <String, List<String>>{};
  await collectErrors((List<FlutterErrorDetails> sink) async {
    for (final Activity a in activities) {
      void check(String state) {
        final List<String> p = bubbleOverTiles(t);
        if (p.isNotEmpty) failures['${a.id} $state'] = p.toSet().take(2).toList();
        if (!stageToo) return;
        final List<String> q = bubbleOverStage(t);
        if (q.isNotEmpty) spills['${a.id} $state'] = q;
      }

      await openQuickly(t, content, a);
      check('start');
      for (int level = 1; level <= 3; level++) {
        await t.tap(find.byKey(const Key('lesson-hint')), warnIfMissed: false);
        await waitSteps(t, 300);
        check('hint $level');
      }
      await closeOne(t);
      sink.clear();
    }
  });
  return (overTiles: failures, overStage: spills);
}

/// Every activity of the pack, in id order: what the full audit opens.
List<Activity> allActivities(PackContent c) =>
    c.activities.values.toList()..sort((Activity a, Activity b) => a.id.compareTo(b.id));

/// The longest line the bubble says while [a] is worked on: the question, a hint, a "not yet". The longer the line, the less room it leaves.
int longestLine(Activity a) => <int>[
  a.promptLine.caption.length,
  for (final Hint h in a.hints) h.say.caption.length,
  for (final IncorrectRule r in a.feedback.incorrect) r.say.caption.length,
].reduce(math.max);

/// A sample of every template that the long lines of the pack are in: for each template the [longest] activities by their longest line,
/// and every [stride]th by id, so the sample moves as the content does and still reaches each template's layout.
List<Activity> sampleByTemplate(PackContent c, {int longest = 10, int stride = 10}) {
  final Map<String, List<Activity>> byTemplate = <String, List<Activity>>{};
  for (final Activity a in allActivities(c)) {
    byTemplate.putIfAbsent(a.template, () => <Activity>[]).add(a);
  }
  final Set<Activity> out = <Activity>{};
  for (final List<Activity> group in byTemplate.values) {
    for (int i = 0; i < group.length; i += stride) {
      out.add(group[i]);
    }
    final List<Activity> byLength = <Activity>[...group]
      ..sort((Activity a, Activity b) => longestLine(b).compareTo(longestLine(a)));
    out.addAll(byLength.take(longest));
  }
  return out.toList()..sort((Activity a, Activity b) => a.id.compareTo(b.id));
}

/// One board at one text size, and whether every activity is opened (`full`) or the [sampleByTemplate] of them.
typedef BubbleAuditCase = ({String board, Size size, double scale, bool full});

/// Registers the audit of [cases]: for each, the activities opened on the board at the text size, and any bubble over a tile named.
/// A test file holds a few cases so that the files run side by side (one file is one isolate), each in about three minutes.
void bubbleAuditTests(List<BubbleAuditCase> cases) {
  late PackContent content;
  setUpAll(() async {
    await loadAppFonts();
    content = await loadSourcePack();
  });

  for (final BubbleAuditCase c in cases) {
    testWidgets(
      '${c.full ? 'every activity' : 'a sample of the activities'} of every land on the ${c.board} board at text size ${c.scale}: '
      'no bubble over a tile, at the start and at hint 1, 2 and 3',
      (WidgetTester t) async {
        final List<Activity> activities = c.full ? allActivities(content) : sampleByTemplate(content);
        expect(
          activities.length,
          greaterThan(c.full ? 1000 : 150),
          reason: 'the pack is what the audit looks at',
        );
        final Map<String, List<String>> failures = (await auditBubbles(
          t,
          content,
          c.size,
          c.scale,
          activities,
        )).overTiles;
        final String report = failures.entries
            .map((MapEntry<String, List<String>> e) => '${e.key}: ${e.value}')
            .join('\n');
        expect(failures, isEmpty, reason: report);
      },
      timeout: const Timeout(Duration(minutes: 15)),
    );
  }
}

/// One phone board at one text size and one look: the pinned number of lines that still spill over the stage, and of the states where the
/// bubble's slop-free tile rect still meets a tile (see [bubbleStageAuditTests]).
typedef StageAuditCase = ({String board, Size size, double scale, AuditLook look, int spills, int tiles});

/// Registers the stage audit of [cases] (B-29, docs/design/b29-caption-overlap.md): every activity of the pack is opened on the phone board
/// at the text size, for the child of the look, and the bubble must keep clear of the stage at the start and at hint 1, 2 and 3. A line
/// that does not fit its column even at 14 points drawn spills into the stage: that is a defect of the content, listed here (printed
/// as `SPILL`, id and state) for the hebrew-text-editor to shorten, and its count is pinned per case so it can only go down.
///
/// The bubble over a tile is counted too (`TILE`, pinned): at the youngest look the tiles' hit area reaches 18 points above the drawn tile,
/// and a bubble that keeps its 16 points clear of the drawn tile lies 2 points over that hit area (the tiles are drawn above the bubble,
/// so no tap is lost). It was the same before B-29's caption fit; the older looks have none.
void bubbleStageAuditTests(List<StageAuditCase> cases) {
  late PackContent content;
  setUpAll(() async {
    await loadAppFonts();
    content = await loadSourcePack();
  });

  String lines(Map<String, List<String>> m) =>
      m.entries.map((MapEntry<String, List<String>> e) => '${e.key}: ${e.value}').join('\n');

  for (final StageAuditCase c in cases) {
    testWidgets(
      'every activity on the ${c.board} board at text size ${c.scale}, ${c.look.name}: the bubble keeps clear of the stage '
      '(${c.spills} lines still spill, to be shortened)',
      (WidgetTester t) async {
        final List<Activity> activities = allActivities(content);
        expect(activities.length, greaterThan(1000), reason: 'the pack is what the audit looks at');
        final BubbleFindings found = await auditBubbles(
          t,
          content,
          c.size,
          c.scale,
          activities,
          look: c.look,
          stageToo: true,
        );
        // ignore: avoid_print
        print(
          'COUNT ${c.board} ${c.scale} ${c.look.name} spills ${found.overStage.length} tiles ${found.overTiles.length}',
        );
        for (final String key in found.overStage.keys) {
          // ignore: avoid_print
          print('SPILL ${c.board} ${c.scale} ${c.look.name} $key');
        }
        for (final String key in found.overTiles.keys) {
          // ignore: avoid_print
          print('TILE ${c.board} ${c.scale} ${c.look.name} $key');
        }
        expect(found.overStage.length, c.spills, reason: lines(found.overStage));
        expect(found.overTiles.length, c.tiles, reason: lines(found.overTiles));
      },
      timeout: const Timeout(Duration(minutes: 20)),
    );
  }
}
