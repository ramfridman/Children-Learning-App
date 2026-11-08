import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:nitznutz/content/pack_limits.dart';
import 'package:nitznutz/content/zip_store.dart';

import 'support/companion_fixtures.dart';

/// Counts of the starter source: the pack must stay well inside its limits while Band C is written (M10 plans about 2,500
/// activities and about 7,500 voice lines), and the limits must stay finite and tied together.
int _filesNamed(String prefix) =>
    Directory('../content/starter')
        .listSync()
        .where((FileSystemEntity e) => e.uri.pathSegments.last.startsWith(prefix))
        .length;

void main() {
  test('the limits are the ones M10 was sized with', () {
    expect(PackLimits.voiceLines, 12000);
    expect(PackLimits.files, 24000);
    expect(PackLimits.assets, 2000);
    expect(PackLimits.activities, 3000);
    expect(PackLimits.lessons, 600);
    expect(PackLimits.skills, 600);
    expect(PackLimits.misconceptions, 400);
  });

  test('a zip takes the files of a manifest and the two files that sign it', () {
    expect(ZipLimits.maxEntries, PackLimits.files + 2);
    // A voice pack holds two files a line (its sound and its cues): it can list every line the manifest allows.
    expect(PackLimits.files, greaterThanOrEqualTo(2 * PackLimits.voiceLines));
  });

  test('the starter pack source is under every limit with a tenth to spare', () {
    expect(_filesNamed('activity.'), lessThanOrEqualTo(PackLimits.activities * 0.9));
    expect(_filesNamed('lesson.'), lessThanOrEqualTo(PackLimits.lessons * 0.9));
    expect(_filesNamed('skill.'), lessThanOrEqualTo(PackLimits.skills * 0.9));
    expect(_filesNamed('misconception.'), lessThanOrEqualTo(PackLimits.misconceptions * 0.9));
    expect(Directory('../content/starter').listSync().length, lessThanOrEqualTo(PackLimits.files * 0.5));
    final List<String> lines = voiceLinesOfStarter(bands: const <String>{'A', 'B', 'C'});
    expect(lines.length, lessThanOrEqualTo(PackLimits.voiceLines * 0.9));
  });

  test('the voice lines the companion tests ask for fit one voice pack', () {
    expect(2 * voiceLinesOfStarter().length + 2, lessThanOrEqualTo(ZipLimits.maxEntries));
  });
}
