import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:nitznutz/content/capabilities.dart';
import 'package:nitznutz/content/schemas.dart';

void main() {
  test('versions compare as numbers', () {
    expect(compareSemver('1.10.0', '1.9.0'), greaterThan(0));
    expect(compareSemver('1.0.0', '1.0.0'), 0);
    expect(compareSemver('0.9.9', '1.0.0'), lessThan(0));
    expect(compareSemver('2.0.0', '1.99.99'), greaterThan(0));
    expect(compareTemplateVersion('1.10', '1.9'), greaterThan(0));
    expect(compareTemplateVersion('2.0', '1.99'), greaterThan(0));
    expect(compareTemplateVersion('1.0', '1.0'), 0);
  });

  test('the app version the packs are checked against is the one in pubspec.yaml', () {
    final String pubspec = File('pubspec.yaml').readAsStringSync();
    final RegExpMatch m = RegExp(r'^version:\s*(\d+\.\d+\.\d+)', multiLine: true).firstMatch(pubspec)!;
    expect(AppCapabilities.current.appVersion, m.group(1));
  });

  test('the capabilities list every template the schemas can play', () {
    expect(AppCapabilities.current.templates, supportedTemplates);
    expect(supportedTemplates.keys, containsAll(<String>['tap_answer', 'count_tap', 'give_n']));
  });

  test('a manifest is compatible when its app and template needs are met', () {
    const AppCapabilities caps = AppCapabilities(
      appVersion: '1.2.0',
      templates: <String, String>{'count_tap': '1.1'},
    );
    Map<String, Object?> manifest(String app, Map<String, Object?> templates) => <String, Object?>{
      'minAppVersion': app,
      'templates': templates,
    };
    expect(caps.incompatibility(manifest('1.2.0', <String, Object?>{'count_tap': '1.1'})), isNull);
    expect(caps.incompatibility(manifest('1.0.0', <String, Object?>{'count_tap': '1.0'})), isNull);
    expect(caps.incompatibility(manifest('1.3.0', <String, Object?>{})), contains('1.3.0'));
    expect(caps.incompatibility(manifest('1.0.0', <String, Object?>{'count_tap': '1.2'})), contains('1.2'));
    expect(caps.incompatibility(manifest('1.0.0', <String, Object?>{'other': '1.0'})), contains('other'));
  });
}
