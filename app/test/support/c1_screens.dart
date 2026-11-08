import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nitznutz/content/models.dart';
import 'package:nitznutz/content/pack_verify.dart';
import 'package:nitznutz/engine/age.dart' show BirthMonth, SchoolStage;
import 'package:nitznutz/parent/age_settings.dart';
import 'package:nitznutz/play/lesson_screen.dart';

import '../../tool/pack_builder_lib.dart';
import 'app_harness.dart';
import 'pack_fixtures.dart';

/// The pack as the source folder builds it, signed with a throw-away key (as `mastery_reachable_test.dart` does): the Band C
/// activities of batch C1 are in it before any signed pack is published.
///
/// [edit] may change the documents before the pack is read (a test that needs an item no content has yet).
Future<PackContent> loadSourcePack({void Function(Map<String, Object?> docs)? edit}) async {
  final VerifiedPack pack = await loadSourceVerified();
  edit?.call(pack.docs);
  return PackContent.fromPack(pack);
}

/// The source folder built and verified, its documents still open to a test's edit.
Future<VerifiedPack> loadSourceVerified() async {
  final PackKey key = await newTestKey();
  final BuiltPack built = await buildPack(Directory('../content/starter'), key);
  return verifyPack(built.bytes, publicKey: key.publicKey);
}

/// The four boards the child's screens are laid out on (design/board.dart), with the name each is reported under.
const List<(String, Size)> boards = <(String, Size)>[
  ('phone', Size(852, 393)),
  ('phoneSE', Size(667, 375)),
  ('tabletL', Size(1180, 820)),
  ('tabletP', Size(820, 1180)),
];

/// The Band C activities of a pack, in id order.
List<Activity> bandCActivities(PackContent c) => <Activity>[
  for (final String id in (c.activities.keys.where((String k) => k.startsWith('c.')).toList()..sort()))
    c.activities[id]!,
];

/// Waits [ms] in steps of 100 ms (a lesson animates in steps; one long pump would skip them).
Future<void> waitSteps(WidgetTester t, int ms) async {
  for (int spent = 0; spent < ms; spent += 100) {
    await t.pump(const Duration(milliseconds: 100));
  }
}

/// Opens a lesson of the one activity [a] (as a revisit mission is opened) on the screen [t] shows; the child is chosen already.
Future<void> openOne(WidgetTester t, PackContent content, Activity a) async {
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
  await t.pump(const Duration(milliseconds: 600));
  await waitSteps(t, 1500);
}

/// Closes the lesson [openOne] opened.
Future<void> closeOne(WidgetTester t) async {
  t.state<NavigatorState>(find.byType(Navigator).first).pop();
  await t.pump(const Duration(milliseconds: 400));
}

/// Pumps the app on [board] with the child of the rig chosen, ready for [openOne].
Future<AppRig> startOn(
  WidgetTester t,
  PackContent content,
  Size board, {
  ({String name, SchoolStage school, BirthMonth birth, String? captions})? look,
}) async {
  final AppRig rig = AppRig(content: content);
  // The child is of the oldest look (Band C, grade 2): the lessons of Band C show up to five choices, which the look of a younger child would
  // cap (B-29). The stage audit asks for another look.
  await rig.seedFinishedSetup(name: 'נֹעָה', ageBand: look?.school.band ?? 2);
  if (look != null) {
    await rig.db.confirmStage('p-1', look.school, DateTime(2026, 10, 26));
    await rig.db.setBirth('p-1', look.birth);
    if (look.captions != null) await rig.db.putSetting(readingKey('p-1'), look.captions!);
  }
  await rig.pump(t, size: board);
  await t.tap(find.text('נֹעָה'));
  await t.pumpAndSettle();
  return rig;
}

/// What a screen showed that it must not: a thrown error (an overflow), or the speech bubble over an answer tile.
List<String> problemsOnScreen(WidgetTester t, List<FlutterErrorDetails> thrown) {
  final List<String> out = <String>[
    for (final FlutterErrorDetails d in thrown) d.exceptionAsString().split('\n').first,
  ];
  thrown.clear();
  final Finder bubble = find.byKey(const Key('bubble-body'));
  if (bubble.evaluate().isNotEmpty) {
    final Rect b = t.getRect(bubble.first);
    for (final Element e in find.byKey(const Key('answer-tile')).evaluate()) {
      final Rect tile = t.getRect(find.byWidget(e.widget));
      final Rect hit = b.intersect(tile);
      if (hit.width > 0.5 && hit.height > 0.5) out.add('the bubble $b covers a tile $tile');
    }
  }
  return out;
}

/// Runs [body] and gives back every error the framework reported while it ran (an overflow is reported, not thrown).
Future<List<FlutterErrorDetails>> collectErrors(
  Future<void> Function(List<FlutterErrorDetails> sink) body,
) async {
  final void Function(FlutterErrorDetails)? before = FlutterError.onError;
  final List<FlutterErrorDetails> sink = <FlutterErrorDetails>[];
  FlutterError.onError = sink.add;
  try {
    await body(sink);
  } finally {
    FlutterError.onError = before;
  }
  return sink;
}
