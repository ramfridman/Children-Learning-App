// Security-engineer proof tests for the Languages Band A branch (SEC-BA-2 in docs/security/findings.md).
//
// SEC-BA-2: "a heritage speaker is never shown a teach screen" is held by the route filter of PackContent.itemsFor, which only filters the
// lesson's `teach` sets. The validator refuses a teach screen among the items of the lesson that names it in `teach`, but not among the
// items of another lesson: such a lesson plays the teach screen to every route, a heritage speaker included.
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:nitznutz/content/models.dart';
import 'package:nitznutz/content/pack_verify.dart';
import 'package:nitznutz/content/schema.dart' show Problem;

import '../tool/pack_builder_lib.dart';
import 'support/pack_fixtures.dart';
import 'support/temp_dir.dart';

const String _languages = '../content/languages';

void main() {
  late Directory dir;
  late PackKey key;

  setUpAll(() async => key = await newTestKey());
  setUp(() {
    final Directory from = languageSource('rus', _languages);
    dir = Directory.systemTemp.createTempSync('nn_sec_ba_');
    for (final FileSystemEntity e in from.listSync()) {
      if (e is File) e.copySync('${dir.path}${Platform.pathSeparator}${e.uri.pathSegments.last}');
    }
  });
  tearDown(() => removeTempDir(dir));

  void change(String file, void Function(Map<String, Object?> doc) edit) {
    final File f = File('${dir.path}${Platform.pathSeparator}$file');
    final Map<String, Object?> doc = jsonDecode(f.readAsStringSync()) as Map<String, Object?>;
    edit(doc);
    f.writeAsStringSync('${const JsonEncoder.withIndent('  ').convert(doc)}\n');
  }

  test(
    'SEC-BA-2: a teach screen is not an item of any lesson (else a heritage speaker is shown it)',
    () async {
      // rus.family-more is a lesson of the same skill with no teach set of its own.
      change('lesson.rus.family-more.json', (Map<String, Object?> l) {
        (l['items']! as List<Object?>).add('rus.a02.tc01');
      });
      BuiltPack? built;
      String problems = '';
      try {
        built = await buildPack(dir, key);
      } on BuildFailed catch (e) {
        problems = e.problems.map((Problem p) => '$p').join('\n');
      }
      if (built != null) {
        // Show what the child would get, then fail: the source must be refused.
        final PackContent rus = PackContent.fromPack(await verifyPack(built.bytes, publicKey: key.publicKey));
        final List<Activity> heritage = rus.itemsFor(rus.lessons['rus.family-more']!, route: 'heritage');
        expect(
          heritage.any((Activity a) => a.teachScreen),
          isFalse,
          reason: 'the pack was signed and a heritage speaker is shown the teach screen rus.a02.tc01 in rus.family-more',
        );
      }
      expect(problems, contains('teach screen'));
    },
  );

  test('SEC-BA-2: itemsOf drops a teach screen even if a pack that was never validated names one among the items', () async {
    final VerifiedPack pack = await verifyPack((await buildPack(dir, key)).bytes, publicKey: key.publicKey);
    final Map<String, Object?> lesson = pack.docs['lesson.rus.family-more.json']! as Map<String, Object?>;
    (lesson['items']! as List<Object?>).add('rus.a02.tc01');
    final PackContent rus = PackContent.fromPack(pack);
    final Lesson l = rus.lessons['rus.family-more']!;
    expect(l.itemIds, contains('rus.a02.tc01'));
    for (final String? route in <String?>['heritage', 'new', 'reader', null]) {
      expect(rus.itemsFor(l, route: route).any((Activity a) => a.teachScreen), isFalse, reason: '$route');
    }
    expect(rus.itemsOf(l), isNotEmpty);
  });

  test('SEC-BA-8: a hear set that names a teach screen does not show it to a heritage speaker', () async {
    final VerifiedPack pack = await verifyPack((await buildPack(dir, key)).bytes, publicKey: key.publicKey);
    final Map<String, Object?> lesson = pack.docs['lesson.rus.pairs-1.json']! as Map<String, Object?>;
    final Map<String, Object?> hear = (lesson['teach']! as List<Object?>)
        .cast<Map<String, Object?>>()
        .firstWhere((Map<String, Object?> s) => s['mode'] == 'hear');
    (hear['items']! as List<Object?>).add('rus.a20.tc01'); // a teach screen of new words
    final PackContent rus = PackContent.fromPack(pack);
    final List<Activity> heritage = rus.itemsFor(rus.lessons['rus.pairs-1']!, route: 'heritage');
    expect(
      heritage.where((Activity a) => a.teachScreen && !(a as SayItActivity).hear).map((Activity a) => a.id),
      isEmpty,
    );
  });
}
