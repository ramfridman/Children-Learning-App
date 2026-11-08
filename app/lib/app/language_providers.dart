import 'dart:typed_data';

import 'package:flutter/services.dart' show AssetManifest, rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show FutureProviderFamily, ProviderFamily;

import '../content/bundled_packs.dart';
import '../content/content_repository.dart';
import '../content/engine_adapter.dart';
import '../content/models.dart';
import '../data/app_database.dart';
import '../engine/course.dart';
import '../engine/engine.dart';
import '../engine/staircase.dart' show PlacementGame;
import '../engine/types.dart' show AttemptEvent;
import '../parent/language_progress.dart';
import '../parent/language_settings.dart';
import '../world/adventure_adapter.dart' show LanguageCourse;
import '../world/course_path.dart';
import '../world/language_placement.dart';
import 'providers.dart' show clockProvider;
import 'reward_providers.dart' show rewardsProvider;
import 'state.dart';

/// The parent's language settings of the family on this device (docs/languages/frame.md section 1.4): which languages are on
/// for each child and their switches. A change is written at once and travels with the family's rules; a child's next tap sees
/// it.
class LanguagesNotifier extends AsyncNotifier<FamilyLanguages> {
  @override
  Future<FamilyLanguages> build() async =>
      FamilyLanguages.decode(await (await ref.watch(databaseProvider.future)).setting(languagesSettingKey));

  /// Sets the switches of one language of one child. False if the family would then have settings for too many children, or
  /// the course is not a language.
  Future<bool> setSwitches(String childId, String course, LanguageSwitches switches) async {
    final FamilyLanguages current = state.value ?? await future;
    final FamilyLanguages? next = current.withSwitches(childId, course, switches);
    if (next == null) return false;
    await (await ref.read(databaseProvider.future)).putSetting(languagesSettingKey, next.encode());
    state = AsyncData<FamilyLanguages>(next);
    return true;
  }
}

final AsyncNotifierProvider<LanguagesNotifier, FamilyLanguages> languagesProvider =
    AsyncNotifierProvider<LanguagesNotifier, FamilyLanguages>(LanguagesNotifier.new);

/// The languages that are on for one child, in the fixed order of the doors, and installed. A language is on in the settings
/// the moment the parent switches it, but it gets a door, an island and a place in Today's Adventure only when its signed pack
/// is also on this device and proves itself ([languagePacksProvider]); until then it is left out. Empty when none qualifies:
/// the map is then the 7-land one. Empty too while either source is still being read; the map waits for both
/// ([languagesReadyProvider]) so that it never shows the 7-land scene first.
final ProviderFamily<List<String>, String> languagesAvailableProvider = Provider.family<List<String>, String>(
  (Ref ref, String childId) {
    final Map<String, PackContent> installed =
        ref.watch(languagePacksProvider).value ?? const <String, PackContent>{};
    return <String>[
      for (final String course in ref.watch(languagesProvider).value?.enabledFor(childId) ?? const <String>[])
        if (installed.containsKey(course)) course,
    ];
  },
);

/// Whether the parent's language settings and the installed language packs have both been read (or failed to be read: the
/// map then has no island). Later changes keep the last answer on show, so the map is never rebuilt from nothing.
final Provider<bool> languagesReadyProvider = Provider<bool>((Ref ref) {
  bool settled(AsyncValue<Object?> v) => v.hasValue || !v.isLoading;
  return settled(ref.watch(languagesProvider)) && settled(ref.watch(languagePacksProvider));
});

/// Where the packs that ship inside the app are read from: the asset manifest and the asset files. Tests give their own.
class BundledAssets {
  const BundledAssets({required this.list, required this.read});

  /// Every asset path of the app.
  final Future<List<String>> Function() list;
  final Future<Uint8List> Function(String asset) read;
}

final Provider<BundledAssets> bundledAssetsProvider = Provider<BundledAssets>(
  (Ref ref) => BundledAssets(
    list: () async => (await AssetManifest.loadFromAssetBundle(rootBundle)).listAssets(),
    read: (String asset) async => (await rootBundle.load(asset)).buffer.asUint8List(),
  ),
);

/// The languages some child has on, as one string: a change of any other switch leaves it as it was, so the packs are not read
/// again for it.
final Provider<String> _languagesOnProvider = Provider<String>(
  (Ref ref) => (ref.watch(languagesProvider).value?.coursesOn ?? const <String>[]).join(','),
);

/// The language packs installed on this device, by course. The bundled pack of each language that is on for some child is installed
/// first (once, the first time; nothing at all for a family with no language on), then every installed pack is read back and
/// proven again. A pack that does not prove itself is put right from the bundle once, and if it still does not it is left out (one
/// damaged course never hurts another, or the lands).
final FutureProvider<Map<String, PackContent>> languagePacksProvider =
    FutureProvider<Map<String, PackContent>>((Ref ref) async {
      // The settings are waited for once; after that only a change in which languages are on reads the packs again.
      await ref.read(languagesProvider.future);
      final String on = ref.watch(_languagesOnProvider);
      final BundledAssets assets = ref.watch(bundledAssetsProvider);
      final ContentRepository repo = ContentRepository(
        installer: await ref.watch(packInstallerProvider.future),
        bundled: () async => throw StateError('the starter pack is not read here'),
      );
      return repo.languagePacks(
        wanted: on.isEmpty ? const <String>[] : on.split(','),
        bundled: BundledLanguagePack.newestOf(await assets.list()),
        read: assets.read,
      );
    });

/// The child's language courses as Today's Adventure, the course home and the parent's progress read them: the installed pack of each
/// language and the child's engine on that course alone (their answers in that pack, replayed), so a revisit stays inside its
/// course.
final FutureProviderFamily<List<LanguageCourse>, String> languageCoursesProvider =
    FutureProvider.family<List<LanguageCourse>, String>((Ref ref, String childId) async {
      final Map<String, PackContent> packs = await ref.watch(languagePacksProvider.future);
      if (packs.isEmpty) return const <LanguageCourse>[];
      final AppDatabase db = await ref.watch(databaseProvider.future);
      final List<Attempt> attempts = await db.attemptsOf(childId);
      final FamilyLanguages family = await ref.watch(languagesProvider.future);
      final int ageBand =
          (await db.allProfiles()).where((Profile p) => p.id == childId).firstOrNull?.ageBand ?? 1;
      return <LanguageCourse>[
        for (final String course in Course.languages)
          if (packs[course] case final PackContent pack?)
            languageCourseOf(pack, attempts, family.of(childId, course), ageBand),
      ];
    });

/// One child's course: the skills below the entry point that the placement game found are assumed (known with a prior of 0.85, until
/// shown otherwise) before the child's answers in this pack are replayed into the engine (docs/languages/frame.md section 3.2).
/// [attempts] may hold every course's answers; only this pack's are read.
LanguageCourse languageCourseOf(
  PackContent pack,
  List<Attempt> attempts,
  LanguageSwitches switches,
  int ageBand,
) {
  final List<Attempt> own = attempts.where((Attempt a) => a.packId == pack.packId).toList();
  final PlacementGame? game = placementGameFor(
    pack,
    own,
    answers: switches.questionnaire,
    presentationBand: switches.presentationBand(ageBand),
  );
  final Set<String> assumed = game == null ? const <String>{} : assumedSkills(pack, game);
  final Engine engine = Engine(catalog: engineCatalog(pack))..assume(assumed);
  engine.replay(own.map(eventOf).toList()..sort((AttemptEvent x, AttemptEvent y) => x.at.compareTo(y.at)));
  return LanguageCourse(
    content: pack,
    engine: engine,
    assumed: assumed,
    placement: game == null ? null : PlacementStatus.of(game),
  );
}

/// What the course home of one child shows (the path, where they stand on it, and what is next), or null when that language is not
/// installed. Invalidate it, with [languageCoursesProvider] and the child's rewards, when a visit has ended.
final FutureProviderFamily<CourseHomeModel?, ({String childId, String course})> courseHomeProvider =
    FutureProvider.family<CourseHomeModel?, ({String childId, String course})>((
      Ref ref,
      ({String childId, String course}) key,
    ) async {
      final List<LanguageCourse> courses = await ref.watch(languageCoursesProvider(key.childId).future);
      final LanguageCourse? c = courses.where((LanguageCourse x) => x.course == key.course).firstOrNull;
      if (c == null) return null;
      final AppDatabase db = await ref.watch(databaseProvider.future);
      final int band =
          (await db.allProfiles()).where((Profile p) => p.id == key.childId).firstOrNull?.ageBand ?? 1;
      return buildCourseHome(
        course: c,
        attempts: await db.attemptsOf(key.childId),
        sessions: await db.sessionsOf(key.childId),
        rewardKeys: <String>[
          for (final Reward r in await ref.watch(rewardsProvider(key.childId).future)) r.awardKey,
        ],
        now: DateTime.fromMillisecondsSinceEpoch(ref.read(clockProvider).nowMs(), isUtc: true),
        band: band,
      );
    });

/// The parent's progress in one language of one child, or null when that language's pack is not installed on this device.
final FutureProviderFamily<LanguageProgress?, ({String childId, String course})> languageProgressProvider =
    FutureProvider.family<LanguageProgress?, ({String childId, String course})>((
      Ref ref,
      ({String childId, String course}) key,
    ) async {
      final List<LanguageCourse> courses = await ref.watch(languageCoursesProvider(key.childId).future);
      final LanguageCourse? c = courses.where((LanguageCourse x) => x.course == key.course).firstOrNull;
      if (c == null) return null;
      final Profile? child = (await (await ref.watch(
        databaseProvider.future,
      )).allProfiles()).where((Profile p) => p.id == key.childId).firstOrNull;
      return buildLanguageProgress(
        content: c.content,
        engine: c.engine,
        now: DateTime.fromMillisecondsSinceEpoch(ref.read(clockProvider).nowMs(), isUtc: true),
        switches: (await ref.watch(languagesProvider.future)).of(key.childId, key.course),
        ageBand: child?.ageBand ?? 1,
        placement: c.placement,
      );
    });
