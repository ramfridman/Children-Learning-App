// The logic land audit (math-teacher, 2026-11-06): one picture of every logic activity (LOG-A-* and LOG-B-*) as the child first
// sees it, on the phone board (852 x 393), right to left with the real fonts. It plays the CURRENT sources in content/starter (not
// the signed pack, which is older), so the pictures show what a sweep would change.
//
// It writes PNGs and checks nothing, so it is off in CI. Run it with:
//   flutter test --dart-define=LOGIC_AUDIT=true --dart-define=LOGIC_AUDIT_OUT=<folder> test/qa_logic_audit_test.dart
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nitznutz/content/models.dart';
import 'package:nitznutz/content/pack_verify.dart';
import 'package:nitznutz/play/lesson_screen.dart';

import 'support/app_harness.dart';
import 'support/harness.dart';

const bool _run = bool.fromEnvironment('LOGIC_AUDIT');
const String _out = String.fromEnvironment('LOGIC_AUDIT_OUT', defaultValue: 'build/logic-audit');

/// The starter pack's manifest, with the docs and pictures read from the sources in content/starter.
Future<PackContent> _fromSources() async {
  final VerifiedPack signed = await verifyPack(
    File('assets/packs/starter-0.10.0.nnpack').readAsBytesSync(),
    publicKey: unhex(File('assets/pack_signing_public_key.txt').readAsStringSync()),
  );
  final Map<String, Object?> docs = <String, Object?>{};
  final Map<String, Uint8List> files = <String, Uint8List>{};
  final List<Map<String, Object?>> assets = <Map<String, Object?>>[];
  for (final FileSystemEntity e in Directory('../content/starter').listSync()) {
    if (e is! File) continue;
    final String name = e.uri.pathSegments.last;
    final Uint8List bytes = e.readAsBytesSync();
    files[name] = bytes;
    if (name.endsWith('.json')) docs[name] = jsonDecode(utf8.decode(bytes));
    if (name.endsWith('.svg')) {
      assets.add(<String, Object?>{'id': name.substring(0, name.length - 4), 'file': name});
    }
  }
  final Map<String, Object?> manifest = Map<String, Object?>.of(signed.manifest)..['assets'] = assets;
  return PackContent.fromPack(
    VerifiedPack(
      manifestBytes: signed.manifestBytes,
      signature: signed.signature,
      manifestSha256: signed.manifestSha256,
      manifest: manifest,
      docs: docs,
      files: files,
    ),
  );
}

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

  testWidgets('logic land audit pictures, phone', skip: !_run, (WidgetTester tester) async {
    final PackContent content = (await tester.runAsync(_fromSources))!;
    final List<String> ids =
        content.activities.values
            .where((Activity a) => a.skills.any((Skill s) => s.id.startsWith('LOG-')))
            .map((Activity a) => a.id)
            .toList()
          ..sort();
    Directory(_out).createSync(recursive: true);
    final AppRig rig = AppRig(content: content);
    await rig.seedFinishedSetup(name: 'נֹעָה');
    await rig.pump(tester, size: const Size(852, 393));
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
      File('$_out/${skill}__$id.png').writeAsBytesSync(png!.buffer.asUint8List());
      image.dispose();
      nav.pop();
      await tester.pump(const Duration(milliseconds: 600));
    }
    // ignore: avoid_print
    print('logic audit: ${ids.length} pictures in $_out');
  });
}
