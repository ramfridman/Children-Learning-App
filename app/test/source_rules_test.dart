import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

// Rules from CLAUDE.md that are cheap to enforce by reading the source.
List<File> dartFiles(String dir) =>
    Directory(dir)
        .listSync(recursive: true)
        .whereType<File>()
        .where((File f) => f.path.endsWith('.dart'))
        .toList();

void main() {
  final List<File> lib = dartFiles('lib');

  test('lib/ is not empty (the scan below would pass vacuously otherwise)', () {
    expect(lib.length, greaterThan(10));
  });

  test('no URL literal in lib/: hosts come only from network_hosts.json', () {
    final RegExp url = RegExp(r'''['"]\s*https?://''');
    for (final File f in lib) {
      expect(url.hasMatch(f.readAsStringSync()), isFalse, reason: f.path);
    }
  });

  test('print and debugPrint are used only by the log helper', () {
    final RegExp printing = RegExp(r'\b(debugPrint|print)\s*\(');
    for (final File f in lib) {
      if (f.path.endsWith('core/log.dart')) continue;
      expect(printing.hasMatch(f.readAsStringSync()), isFalse, reason: f.path);
    }
  });

  test('no secret-looking key in the source tree', () {
    final RegExp secret = RegExp(r'sb_secret_[A-Za-z0-9_-]{8,}|sk-ant-[A-Za-z0-9_-]{8,}|service_role');
    for (final File f in <File>[...lib, ...dartFiles('test')]) {
      if (<String>[
        'source_rules_test.dart',
        'config_and_hosts_test.dart',
        'core/config.dart',
      ].any(f.path.endsWith))
        continue;
      expect(secret.hasMatch(f.readAsStringSync()), isFalse, reason: f.path);
    }
  });

  test('the network-hosts file is registered as an asset', () {
    expect(File('pubspec.yaml').readAsStringSync(), contains('network_hosts.json'));
  });

  test('every dependency is pinned exactly', () {
    final String pubspec = File('pubspec.yaml').readAsStringSync();
    final String deps = pubspec.split('dev_dependencies:').first.split('dependencies:').last;
    for (final String line in deps.split('\n')) {
      final RegExpMatch? m = RegExp(r'^  [a-z_]+: (\S+)$').firstMatch(line);
      if (m == null) continue;
      expect(m.group(1), matches(RegExp(r'^\d+\.\d+\.\d+$')), reason: line);
    }
  });

  test('the Android manifest forbids backups and plain-HTTP traffic', () {
    final String manifest = File('android/app/src/main/AndroidManifest.xml').readAsStringSync();
    expect(manifest, contains('android:allowBackup="false"'));
    expect(manifest, contains('android:usesCleartextTraffic="false"'));
  });
}
