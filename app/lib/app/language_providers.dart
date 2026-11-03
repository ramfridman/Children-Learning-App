import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show FutureProviderFamily, ProviderFamily;

import '../content/content_repository.dart';
import '../content/engine_adapter.dart';
import '../content/models.dart';
import '../content/pack_verify.dart' show PackRejected;
import '../data/app_database.dart';
import '../engine/course.dart';
import '../engine/engine.dart';
import '../engine/types.dart' show AttemptEvent;
import '../parent/language_progress.dart';
import '../parent/language_settings.dart';
import '../world/adventure_adapter.dart' show LanguageCourse;
import 'providers.dart' show clockProvider;
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

/// The languages that are on for one child, in the fixed order of the doors. Empty when none is: the map is then the 7-land one.
final ProviderFamily<List<String>, String> languagesOnProvider = Provider.family<List<String>, String>(
  (Ref ref, String childId) => ref.watch(languagesProvider).value?.enabledFor(childId) ?? const <String>[],
);

/// The language packs installed on this device, by course. A pack that does not prove itself again is left out (one damaged
/// course never hurts another, or the lands).
final FutureProvider<Map<String, PackContent>> languagePacksProvider =
    FutureProvider<Map<String, PackContent>>((Ref ref) async {
      final ContentRepository repo = ContentRepository(
        installer: await ref.watch(packInstallerProvider.future),
        bundled: () async => throw StateError('language packs are never bundled'),
      );
      final Map<String, PackContent> out = <String, PackContent>{};
      for (final String course in await repo.installedLanguages()) {
        try {
          final PackContent? pack = await repo.languagePack(course);
          if (pack != null) out[course] = pack;
        } on PackRejected {
          continue;
        }
      }
      return out;
    });

/// The child's language courses as Today's Adventure and the parent's progress read them: the installed pack of each
/// language and the child's engine on that course alone (their answers in that pack, replayed), so a revisit stays inside its
/// course.
final FutureProviderFamily<List<LanguageCourse>, String> languageCoursesProvider =
    FutureProvider.family<List<LanguageCourse>, String>((Ref ref, String childId) async {
      final Map<String, PackContent> packs = await ref.watch(languagePacksProvider.future);
      if (packs.isEmpty) return const <LanguageCourse>[];
      final List<Attempt> attempts = await (await ref.watch(databaseProvider.future)).attemptsOf(childId);
      return <LanguageCourse>[
        for (final String course in Course.languages)
          if (packs[course] case final PackContent pack?)
            LanguageCourse(
              content: pack,
              engine: Engine(catalog: engineCatalog(pack))
                ..replay(
                  attempts.where((Attempt a) => a.packId == pack.packId).map(eventOf).toList()
                    ..sort((AttemptEvent x, AttemptEvent y) => x.at.compareTo(y.at)),
                ),
            ),
      ];
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
      );
    });
