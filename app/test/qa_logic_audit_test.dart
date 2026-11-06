// The logic land audit (math-teacher, 2026-11-06): one picture of every logic activity (LOG-A-* and LOG-B-*) as the child first
// sees it, on the phone board (852 x 393), right to left with the real fonts. It plays the CURRENT sources in content/starter (not
// the signed pack, which is older), so the pictures show what a sweep would change. Each board (the phone, the small phone, the
// tablet) has a folder of its own under the output folder.
//
// It writes PNGs and checks nothing, so it is off in CI. Run it with:
//   flutter test --dart-define=LOGIC_AUDIT=true --dart-define=LOGIC_AUDIT_OUT=<folder> test/qa_logic_audit_test.dart
// and, to see only some activities (their ids, comma-separated): --dart-define=LOGIC_AUDIT_IDS=b.logb02.2,log.size.last
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nitznutz/content/models.dart';
import 'package:nitznutz/play/lesson_screen.dart';

import 'support/app_harness.dart';
import 'support/harness.dart';
import 'support/starter.dart';

const bool _run = bool.fromEnvironment('LOGIC_AUDIT');
const String _out = String.fromEnvironment('LOGIC_AUDIT_OUT', defaultValue: 'build/logic-audit');
const String _only = String.fromEnvironment('LOGIC_AUDIT_IDS');

/// The boards that are drawn: a folder name and the window.
const Map<String, Size> _boards = <String, Size>{
  'phone': Size(852, 393),
  'phoneSE': Size(667, 375),
  'tablet': Size(1180, 820),
};

Future<void> _wait(WidgetTester t, int ms) async {
  for (int spent = 0; spent < ms; spent += 100) {
    await t.pump(const Duration(milliseconds: 100));
  }
  await t.pump(const Duration(milliseconds: 50));
}

void main() {
  setUpAll(() async {
    await loadAppFonts();
  });

  for (final MapEntry<String, Size> board in _boards.entries) {
    testWidgets('logic land audit pictures, ${board.key}', skip: !_run, (WidgetTester tester) async {
      await _draw(tester, board.key, board.value);
    });
  }
}

Future<void> _draw(WidgetTester tester, String board, Size window) async {
  final PackContent content = (await tester.runAsync(loadSourcePack))!;
  final List<String> ids =
      content.activities.values
          .where((Activity a) => a.skills.any((Skill s) => s.id.startsWith('LOG-')))
          .map((Activity a) => a.id)
          .where((String id) => _only.isEmpty || _only.split(',').contains(id))
          .toList()
        ..sort();
  final String folder = '$_out/$board';
  Directory(folder).createSync(recursive: true);
  final AppRig rig = AppRig(content: content);
  await rig.seedFinishedSetup(name: 'נֹעָה');
  await rig.pump(tester, size: window);
  await tester.tap(find.text('נֹעָה'));
  await tester.pumpAndSettle();
  for (final String id in ids) {
    final Activity a = content.activities[id]!;
    final NavigatorState nav = tester.state<NavigatorState>(find.byType(Navigator).first);
    final Lesson one = Lesson.mission(
      id: 'audit',
      itemIds: <String>[id],
      skillIds: a.skills.map((Skill s) => s.id).toList(),
      celebration: content.lessons['butterflies']!.celebration,
    );
    nav.push(
      MaterialPageRoute<void>(
        builder: (BuildContext c) => LessonScreen(profileId: 'p-1', mission: one),
      ),
    );
    await tester.pump(const Duration(milliseconds: 600));
    await _wait(tester, 1200);
    final Element root = find.byType(MaterialApp).evaluate().first;
    final ui.Image image = (await tester.runAsync<ui.Image>(() => captureImage(root)))!;
    final ByteData? png = await tester.runAsync<ByteData?>(
      () => image.toByteData(format: ui.ImageByteFormat.png),
    );
    final String skill = a.skills.first.id;
    File('$folder/${skill}__$id.png').writeAsBytesSync(png!.buffer.asUint8List());
    image.dispose();
    nav.pop();
    await tester.pump(const Duration(milliseconds: 600));
  }
  // ignore: avoid_print
  print('logic audit: ${ids.length} pictures in $folder');
}
