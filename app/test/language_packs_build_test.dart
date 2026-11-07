// The pack sources of the three language courses (`content/languages/<course>/pack`, written by `tools/lang_pack.py`) through the real pack
// builder: each is built, signed with a throw-away key, verified, read as the app reads a pack and held to the invariants of
// docs/languages/frame.md section 1.5 and the content checks of F5. The pilot is one skill and one lesson of each course; the same tests
// hold the full Band A packs. A broken copy of a source is refused by the same validator, with the file named.
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:nitznutz/content/models.dart';
import 'package:nitznutz/content/pack_verify.dart';
import 'package:nitznutz/content/schema.dart' show Problem;
import 'package:nitznutz/engine/course.dart';

import '../tool/pack_builder_lib.dart';
import 'support/pack_fixtures.dart';

const String _languages = '../content/languages';

Object? _read(String path) => jsonDecode(File(path).readAsStringSync());

/// A copy of the pack source of [course] to break, in a temporary folder.
Directory _copyOf(String course) {
  final Directory from = languageSource(course, _languages);
  final Directory to = Directory.systemTemp.createTempSync('nn_langsrc_');
  for (final FileSystemEntity e in from.listSync()) {
    if (e is File) e.copySync('${to.path}${Platform.pathSeparator}${e.uri.pathSegments.last}');
  }
  return to;
}

void _change(Directory dir, String file, void Function(Map<String, Object?> doc) edit) {
  final File f = File('${dir.path}${Platform.pathSeparator}$file');
  final Map<String, Object?> doc = jsonDecode(f.readAsStringSync()) as Map<String, Object?>;
  edit(doc);
  f.writeAsStringSync('${const JsonEncoder.withIndent('  ').convert(doc)}\n');
}

void main() {
  late PackKey key;

  setUpAll(() async => key = await newTestKey());

  for (final String course in Course.languages) {
    group('$course: the pack source builds, signs and reads back', () {
      late BuiltPack built;
      late VerifiedPack pack;
      late PackContent content;

      setUpAll(() async {
        built = await buildPack(languageSource(course, _languages), key);
        pack = await verifyPack(built.bytes, publicKey: key.publicKey);
        content = PackContent.fromPack(pack);
      });

      test('the builder is happy with it: no warnings, the file is named lang-$course-<version>', () {
        expect(built.warnings, isEmpty);
        final Map<String, Object?> source = _read('$_languages/$course/course.json')! as Map<String, Object?>;
        final String version = (source['pack']! as Map<String, Object?>)['version']! as String;
        expect(built.fileName, 'lang-$course-$version.nnpack');
        expect(pack.manifest['course'], course);
        expect(Course.ofPackId(pack.id), course);
      });

      test('it is one course through and through (frame 1.5): skills, items, tags, lessons', () {
        expect(content.course, course);
        expect(content.packId, 'lang-$course');
        expect(content.skills, isNotEmpty);
        expect(content.lessons, isNotEmpty);
        for (final String id in content.skills.keys) {
          expect(Course.ofSkillId(id), course, reason: id);
        }
        for (final String id in content.activities.keys) {
          expect(Course.ofActivityId(id), course, reason: id);
        }
        for (final String id in content.tags.keys) {
          expect(Course.ofTag(id), course, reason: id);
        }
        for (final Lesson l in content.lessons.values) {
          expect(Course.ofActivityId(l.id), course, reason: l.id);
          for (final String item in l.itemIds) {
            expect(content.activities, contains(item));
          }
        }
      });

      test('the AI tutor is off for every item (frame 1.6) and every distractor carries its tag', () {
        for (final Activity a in content.activities.values) {
          expect(a.llmAllowed, isFalse, reason: a.id);
        }
        // A choice (a tap, a bubble, a button, a pause of a story) names its distractors and each carries a tag. A sort, a pair, a drum, a
        // story only heard, a personal turn and a say step have no distractors of that kind: their tags are on a card, a face or a classifier,
        // and the validator holds them to the same rule (every wrong thing carries the error it shows).
        int choices = 0;
        for (final MapEntry<String, Object?> e in pack.docs.entries) {
          if (!e.key.startsWith('activity.')) continue;
          final Map<String, Object?> answer =
              (e.value! as Map<String, Object?>)['answer']! as Map<String, Object?>;
          if (answer['type'] != 'choice') continue;
          choices++;
          final Object? correct = answer['correct'];
          final Set<String> right = <String>{
            if (correct is List<Object?>) ...correct.cast<String>() else correct! as String,
          };
          for (final Object? o in answer['options']! as List<Object?>) {
            final Map<String, Object?> option = o! as Map<String, Object?>;
            if (!right.contains(option['id'])) {
              expect(option['misconception'], isNotNull, reason: '${e.key} ${option['id']}');
            }
          }
        }
        expect(choices, greaterThan(20));
      });

      test(
        'no voice is recorded: every line the pack names is pending, and the voice plan lists them all',
        () {
          expect(pack.manifest['vo'], isEmpty);
          final Map<String, Object?> plan =
              _read('$_languages/$course/voice-plan.json')! as Map<String, Object?>;
          final Set<String> planned = <String>{
            for (final Object? c in plan['frameLines']! as List<Object?>)
              (c! as Map<String, Object?>)['vo']! as String,
            for (final Object? c in plan['targetClips']! as List<Object?>)
              (c! as Map<String, Object?>)['vo']! as String,
            // The clips of single words cut from the clip of their page (a `follow` page): pending too, never voiced of their own.
            for (final Object? c in (plan['cutClips'] as List<Object?>? ?? const <Object?>[]))
              (c! as Map<String, Object?>)['vo']! as String,
          };
          expect((pack.manifest['voPending']! as List<Object?>).cast<String>().toSet(), planned);
        },
      );

      test(
        'every Hebrew document is marked for the editor, and the pictures come from the shared library',
        () {
          for (final MapEntry<String, Object?> e in pack.docs.entries) {
            expect((e.value! as Map<String, Object?>)['review'], 'needs-editor', reason: e.key);
          }
          for (final Object? a in pack.manifest['assets']! as List<Object?>) {
            final String id = (a! as Map<String, Object?>)['id']! as String;
            final File shared = File('$_languages/pictures/${id.replaceAll('_', '-')}.svg');
            if (!shared.existsSync()) {
              // Made by the generator, not drawn: the blank target of a count, or a counted thing on a glow.
              expect(id == 'blank' || id.endsWith('_lit'), isTrue, reason: id);
              continue;
            }
            expect(pack.files['$id.svg'], Uint8List.fromList(shared.readAsBytesSync()), reason: id);
          }
        },
      );

      test('a pack of the same sources is the same bytes (the builder is deterministic)', () async {
        final BuiltPack again = await buildPack(languageSource(course, _languages), key);
        expect(again.bytes, built.bytes);
      });
    });
  }

  group('a broken copy of a source is refused, with the file named', () {
    late Directory dir;

    setUp(() => dir = _copyOf('eng'));
    tearDown(() => dir.deleteSync(recursive: true));

    Future<List<Problem>> refused() async {
      try {
        await buildPack(dir, key);
      } on BuildFailed catch (e) {
        return e.problems;
      }
      fail('the broken source was signed');
    }

    test('a prerequisite into another course (invariant 1)', () async {
      _change(dir, 'skill.ENG-A-01.json', (Map<String, Object?> d) {
        d['prerequisites'] = <Object?>[
          <String, Object?>{'skill': 'RUS-A-01', 'weight': 0.8},
        ];
      });
      final List<Problem> p = await refused();
      expect(p.map((Problem x) => x.toString()).join('\n'), contains('RUS-A-01'));
    });

    test('an item that lets the AI tutor in (frame 1.6)', () async {
      _change(dir, 'activity.eng.a01.i01.json', (Map<String, Object?> d) {
        (d['tutor']! as Map<String, Object?>)['llmAllowed'] = true;
      });
      final List<Problem> p = await refused();
      expect(
        p.any((Problem x) => x.toString().contains('llmAllowed') || x.path.contains('tutor')),
        isTrue,
        reason: '$p',
      );
    });

    test('a distractor with no tag (F5)', () async {
      _change(dir, 'activity.eng.a01.i01.json', (Map<String, Object?> d) {
        for (final Object? o in (d['answer']! as Map<String, Object?>)['options']! as List<Object?>) {
          (o! as Map<String, Object?>).remove('misconception');
        }
      });
      final List<Problem> p = await refused();
      expect(p, isNotEmpty);
      expect(p.map((Problem x) => x.toString()).join('\n'), contains('activity.eng.a01.i01.json'));
    });

    test('an item of another course (the id prefix must agree with the course)', () async {
      _change(dir, 'activity.eng.a01.i01.json', (Map<String, Object?> d) => d['course'] = 'rus');
      expect(await refused(), isNotEmpty);
    });

    test('a tag of another course on a distractor (invariant 2)', () async {
      _change(dir, 'activity.eng.a01.i01.json', (Map<String, Object?> d) {
        final List<Object?> options = (d['answer']! as Map<String, Object?>)['options']! as List<Object?>;
        (options[1]! as Map<String, Object?>)['misconception'] = 'rus.lis.sem';
      });
      expect(await refused(), isNotEmpty);
    });

    test('a pack of the wrong id for its course', () async {
      _change(dir, 'pack.json', (Map<String, Object?> d) => d['id'] = 'lang-heb');
      expect(await refused(), isNotEmpty);
    });

    test('a picture that is not in the pack', () async {
      File('${dir.path}${Platform.pathSeparator}pip_leave.svg').deleteSync();
      expect(await refused(), isNotEmpty);
    });

    test('the pack builder names a course that is not a language, and a missing source', () {
      expect(() => languageSource('core', _languages), throwsA(isA<BuildFailed>()));
      expect(() => languageSource('eng', '$_languages/nowhere'), throwsA(isA<BuildFailed>()));
    });
  });

  group('the packs bundled in the app', () {
    final RegExp name = RegExp(r'lang-(eng|heb|rus)-(\d+\.\d+\.\d+)\.nnpack$');
    final Directory folder = Directory('assets/packs');
    final List<File> bundled = <File>[
      if (folder.existsSync())
        for (final File f in folder.listSync().whereType<File>())
          if (name.hasMatch(f.path)) f,
    ];

    test(
      'each is signed by the key of the app, is named for what it holds, is the only one of its course, and is built from the committed sources',
      () async {
        final Uint8List publicKey = readPublicKeyFile('assets/pack_signing_public_key.txt');
        final Set<String> courses = <String>{};
        for (final File f in bundled) {
          final RegExpMatch m = name.firstMatch(f.path)!;
          final String course = m.group(1)!;
          expect(courses.add(course), isTrue, reason: 'two bundled packs of $course');
          final VerifiedPack pack = await verifyPack(f.readAsBytesSync(), publicKey: publicKey);
          expect((pack.id, pack.version, pack.manifest['course']), ('lang-$course', m.group(2), course));
          final Directory source = languageSource(course, _languages);
          final Map<String, Object?> spec = _read('$_languages/$course/course.json')! as Map<String, Object?>;
          expect(
            m.group(2),
            (spec['pack']! as Map<String, Object?>)['version'],
            reason: 'the bundled $course pack is not the version of its sources: build it again',
          );
          for (final FileSystemEntity e in source.listSync()) {
            if (e is! File) continue;
            final String file = e.uri.pathSegments.last;
            if (file == 'pack.json') continue;
            final List<int> expected = <int>[for (final int b in e.readAsBytesSync()) b]
              ..removeWhere((int b) => b == 0x0D);
            expect(
              pack.files[file],
              expected,
              reason: '$course/$file differs from the bundled pack: build it again',
            );
          }
          expect(pack.files.keys.where((String k) => k != 'pack.json').length, source.listSync().length - 1);
        }
      },
      skip: bundled.isEmpty
          ? 'no signed language pack is bundled yet: the owner signs them (docs/languages/band-a-build.md)'
          : false,
    );
  });
}
