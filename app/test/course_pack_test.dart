// One signed pack per course (docs/languages/frame.md section 1.5): a language pack is built, signed, installed and loaded
// like the starter pack, under the id `lang-<course>`, and the starter pack is built as it always was.
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nitznutz/content/content_repository.dart';
import 'package:nitznutz/content/models.dart';
import 'package:nitznutz/content/pack_installer.dart';
import 'package:nitznutz/content/pack_verify.dart';
import 'package:nitznutz/data/app_database.dart';
import 'package:nitznutz/engine/course.dart';

import '../tool/pack_builder_lib.dart';
import 'support/pack_fixtures.dart';
import 'support/sample_pack.dart';

void main() {
  late PackKey key;
  late Directory dir;
  late AppDatabase db;
  late PackInstaller installer;
  late ContentRepository repo;

  setUpAll(() async => key = await newTestKey());

  setUp(() {
    dir = Directory.systemTemp.createTempSync('nn_course_');
    db = AppDatabase(NativeDatabase.memory());
    installer = PackInstaller(
      root: Directory('${dir.path}${Platform.pathSeparator}packs'),
      registry: DbPackRegistry(db),
      publicKey: key.publicKey,
    );
    repo = ContentRepository(installer: installer, bundled: () async => Uint8List(0));
  });

  tearDown(() async {
    await db.close();
    dir.deleteSync(recursive: true);
  });

  Map<String, Object?> manifestOf(Uint8List pack) =>
      jsonDecode(utf8.decode(unzip(pack)[manifestName]!))! as Map<String, Object?>;

  test('the builder leaves a pack without a course exactly as it was: no course on the manifest', () async {
    final Map<String, Object?> m = manifestOf((await buildSamplePack(key)).bytes);
    expect(m.containsKey('course'), isFalse);
    expect(m['id'], 'sample-pack');
  });

  for (final String course in Course.languages) {
    test('$course: a language pack is built, installed and loaded under lang-$course', () async {
      final BuiltPack built = await buildSamplePack(key, sample: SamplePack.language(course));
      expect(manifestOf(built.bytes)['course'], course);
      expect(built.fileName, 'lang-$course-1.0.0.nnpack');
      final InstallResult r = await installer.install(built.bytes);
      expect(r.outcome, InstallOutcome.installed);
      final PackContent? content = await repo.languagePack(course);
      expect(content, isNotNull);
      expect(content!.course, course);
      expect(content.packId, 'lang-$course');
      expect(await repo.installedLanguages(), <String>[course]);
      for (final String other in Course.languages.where((String c) => c != course)) {
        expect(await repo.languagePack(other), isNull, reason: 'only $course is installed');
      }
    });
  }

  test('two courses are two packs side by side, and the doors list them in their fixed order', () async {
    await installer.install((await buildSamplePack(key, sample: SamplePack.language('rus'))).bytes);
    await installer.install((await buildSamplePack(key, sample: SamplePack.language('eng'))).bytes);
    expect(await repo.installedLanguages(), <String>['eng', 'rus']);
    expect((await repo.languagePack('eng'))!.skills.keys.first, startsWith('ENG-'));
    expect((await repo.languagePack('rus'))!.skills.keys.first, startsWith('RUS-'));
  });

  test('a newer version of a course replaces the old one; there is never two of a course', () async {
    await installer.install(
      (await buildSamplePack(key, sample: SamplePack.language('eng'), version: '1.0.0')).bytes,
    );
    await installer.install(
      (await buildSamplePack(key, sample: SamplePack.language('eng'), version: '1.1.0')).bytes,
    );
    expect((await db.allInstalledPacks()).map((InstalledPack p) => '${p.id}@${p.version}'), <String>[
      'lang-eng@1.1.0',
    ]);
  });

  test('a language course that is asked for by a name that is no language is refused', () async {
    expect(() => repo.languagePack('core'), throwsArgumentError);
    expect(() => repo.languagePack('fra'), throwsArgumentError);
  });

  test(
    'the builder refuses a language pack under another name, and another pack under a language\'s name',
    () async {
      final SamplePack wrongName = SamplePack.language('eng');
      wrongName.manifest['id'] = 'english-course';
      await expectLater(buildSamplePack(key, sample: wrongName), throwsA(isA<BuildFailed>()));

      final SamplePack wrongCourse = SamplePack();
      wrongCourse.manifest['id'] = 'lang-eng';
      await expectLater(buildSamplePack(key, sample: wrongCourse), throwsA(isA<BuildFailed>()));
    },
  );
}
