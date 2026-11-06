// B-29 (QA guard, step 9, built with step 4): a birthday never changes a finished lesson or a skill's mastery. Presentation follows the
// age; content follows mastery. The same child, with the same answers, is read on the day before and the day after the day the look
// changes from P3 to P4, a year later, and in the September when a new school stage is suggested: the look may change, and nothing
// else does.
import 'dart:io';

import 'package:drift/drift.dart' show Value, driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:nitznutz/app/age_providers.dart';
import 'package:nitznutz/app/providers.dart';
import 'package:nitznutz/app/state.dart';
import 'package:nitznutz/app/world_providers.dart';
import 'package:nitznutz/content/models.dart';
import 'package:nitznutz/data/app_database.dart';
import 'package:nitznutz/engine/age.dart';
import 'package:nitznutz/world/land_placement.dart';
import 'package:nitznutz/world/next_lesson.dart';
import 'package:nitznutz/world/placement.dart';

import 'engine/fixtures.dart' show fingerprint;
import 'support/fakes.dart';
import 'support/starter.dart';

const String kid = 'child-aaaa-0001';

/// The answers of a child who has finished the first [lessons] lessons of every land, all right at the first try.
Future<void> _playLessons(AppDatabase db, PackContent content, int lessons) async {
  int minute = 0;
  for (final String domain in <String>{for (final SkillDoc s in content.skills.values) s.domain}) {
    for (final Lesson l in landPath(content, domain).take(lessons)) {
      for (final String id in l.itemIds) {
        final Activity? a = content.activities[id];
        if (a == null || a.skills.isEmpty) continue;
        await db.recordAttempt(
          AttemptsCompanion.insert(
            at: DateTime.utc(2026, 10, 20, 9).add(Duration(minutes: minute++)),
            profileId: kid,
            packId: 'starter',
            packVersion: '0.10.0',
            lessonId: Value<String>(l.id),
            activityId: a.id,
            activityRevision: a.revision,
            template: a.template,
            templateVersion: a.templateVersion,
            skillId: a.skills.first.id,
            result: 'correct',
            attemptNo: 1,
            hintLevel: 0,
          ),
        );
      }
    }
  }
}

/// Everything the lessons and the mastery are made of for the child, as one text.
class _Reading {
  _Reading(this.age, this.state);

  final ChildAge age;
  final String state;
}

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  TestWidgetsFlutterBinding.ensureInitialized();

  late PackContent content;
  late AppDatabase db;
  setUpAll(() async => content = await loadStarter());

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    await db.addProfile(
      ProfilesCompanion.insert(
        id: kid,
        name: 'נועה',
        avatar: 'avatar-noa',
        addressForm: 'f',
        ageBand: 1,
        createdAt: DateTime.utc(2026, 10, 1),
      ),
    );
    await db.setSchoolStage(kid, SchoolStage.gan5);
    await db.setBirth(kid, const BirthMonth(2020, 5));
    await _playLessons(db, content, 3);
  });
  tearDown(() => db.close());

  Future<_Reading> read(DateTime now) async {
    final ProviderContainer app = ProviderContainer(
      overrides: <Override>[
        databaseProvider.overrideWith((Ref ref) async => db),
        contentProvider.overrideWith((Ref ref) async => content),
        clockProvider.overrideWithValue(FixedClock(now.millisecondsSinceEpoch)),
      ],
    );
    addTearDown(app.dispose);
    final ChildAge age = await app.read(childAgeProvider(kid).future);
    final WorldView world = await app.read(worldProvider(kid).future);
    final List<Attempt> attempts = await db.attemptsOf(kid);
    final Map<String, int> finished = finishedLessons(content, attempts, const <String>[]);
    final StringBuffer b = StringBuffer(fingerprint(world.engine));
    b.writeln(
      'finished ${(finished.entries.toList()..sort((a, c) => a.key.compareTo(c.key))).map((e) => '${e.key}=${e.value}')}',
    );
    final placed = placedByWarmUp(content, attempts);
    b.writeln('placed ${placed.lessons.toList()..sort()} ${placed.skills.toList()..sort()}');
    for (final String domain in <String>{
      for (final SkillDoc s in content.skills.values) s.domain,
    }.toList()..sort()) {
      b.writeln(
        'next $domain ${nextLessonId(content: content, domain: domain, finished: finished, unlocked: world.engine.isUnlocked)}',
      );
    }
    for (final SkillDoc s in content.skills.values) {
      b.writeln(
        'level ${s.id} ${world.engine.state.skills[s.id]?.freshAt} ${world.engine.state.skills[s.id]?.durableAt}',
      );
    }
    return _Reading(age, b.toString());
  }

  test('the day the look changes from P3 to P4, the finished lessons, the next lessons and the mastery stay as they were', () async {
    final _Reading before = await read(DateTime(2026, 10, 31, 23, 59));
    final _Reading after = await read(DateTime(2026, 11, 1, 0, 1));
    expect(before.age.presentation, PresentationStage.p3, reason: 'born 2020-05: 77 months on 31 October');
    expect(
      after.age.presentation,
      PresentationStage.p4,
      reason: '78 months on 1 November: the birthday did happen',
    );
    expect(after.state, before.state);
    expect(after.age.band, before.age.band);
    expect(after.age.stage, before.age.stage);
  });

  test('a year later, and in the September a new stage would be suggested, they are the same too', () async {
    final _Reading start = await read(DateTime(2026, 10, 31));
    for (final DateTime later in <DateTime>[
      DateTime(2027, 9, 1),
      DateTime(2027, 11, 6),
      DateTime(2030, 1, 1),
    ]) {
      final _Reading r = await read(later);
      expect(r.state, start.state, reason: '$later');
      expect(r.age.stage, SchoolStage.gan5, reason: 'the stage changes only when a parent confirms it');
      expect(r.age.band, 1);
    }
  });

  test('the same answers read with no month of birth, a different one, or a different stage give the same mastery and lessons', () async {
    final _Reading with2020 = await read(DateTime(2026, 11, 6));
    await db.setBirth(kid, const BirthMonth(2022, 1));
    final _Reading with2022 = await read(DateTime(2026, 11, 6));
    await db.setBirth(kid, null);
    final _Reading none = await read(DateTime(2026, 11, 6));
    await db.setSchoolStage(kid, SchoolStage.grade1);
    final _Reading otherStage = await read(DateTime(2026, 11, 6));
    expect(otherStage.state, with2020.state, reason: 'a stage of the same band');
    expect(with2022.state, with2020.state);
    expect(none.state, with2020.state);
    expect(
      <PresentationStage?>[with2020.age.presentation, with2022.age.presentation, none.age.presentation],
      <PresentationStage?>[PresentationStage.p4, PresentationStage.p2, PresentationStage.p3],
      reason: 'the look did follow the month and year',
    );
  });

  test('the mastery and the path cannot even name the age (source rule)', () {
    // Files that decide what is finished, what is next and what is known. The warm-up's start prior (`land_placement.dart`) is the one
    // place a stage may be read, and it reads the stage, never an age in months.
    final RegExp age = RegExp(
      r'ChildAge|childAge|BirthMonth|ageInMonths|PresentationStage|birthOf|assumedMonths|\.months\b',
    );
    final List<String> files = <String>[
      for (final String dir in <String>['lib/engine', 'lib/world', 'lib/rewards'])
        for (final FileSystemEntity f in Directory(dir).listSync(recursive: true))
          if (f is File && f.path.endsWith('.dart') && f.path.replaceAll(r'\', '/') != 'lib/engine/age.dart')
            f.path,
    ];
    expect(files.length, greaterThan(20));
    for (final String path in files) {
      expect(age.hasMatch(File(path).readAsStringSync()), isFalse, reason: path);
    }
  });
}
