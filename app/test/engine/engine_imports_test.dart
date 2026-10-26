import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('the engine imports no UI, database, file or network code: only dart:math and itself', () {
    final List<File> files = Directory('lib/engine')
        .listSync(recursive: true)
        .whereType<File>()
        .where((File f) => f.path.endsWith('.dart'))
        .toList();
    expect(files.length, greaterThanOrEqualTo(8));
    final RegExp import = RegExp(r'''^\s*(import|export|part)\s+['"]([^'"]+)['"]''', multiLine: true);
    for (final File f in files) {
      for (final RegExpMatch m in import.allMatches(f.readAsStringSync())) {
        final String target = m.group(2)!;
        final bool allowed =
            target == 'dart:math' ||
            (!target.contains(':') && !target.contains('/') && target.endsWith('.dart'));
        expect(allowed, isTrue, reason: '${f.path} imports $target');
      }
    }
  });

  test('nothing in the engine reads the clock, the environment or a random source of its own', () {
    for (final File f in Directory('lib/engine').listSync(recursive: true).whereType<File>()) {
      final String text = f.readAsStringSync();
      expect(text.contains('DateTime.now'), isFalse, reason: '${f.path} reads the clock');
      expect(
        RegExp(r'Random\(\s*\)').hasMatch(text),
        isFalse,
        reason: '${f.path} makes an unseeded generator',
      );
      expect(text.contains('Random.secure'), isFalse, reason: f.path);
    }
  });
}
