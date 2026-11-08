import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show FutureProviderFamily;

import '../data/app_database.dart';
import '../data/profile_age.dart';
import '../engine/age.dart';
import '../parent/age_settings.dart';
import '../parent/look_settings.dart';
import 'providers.dart' show clockProvider;
import 'state.dart';

/// How a child's screens look and read at one moment (B-29): the look P1 to P4, whether the question's Hebrew words are drawn, and the school
/// stage the captions default follows. Worked out from what is stored when asked for; never kept. A session reads it once at its start.
class LookNow {
  const LookNow({required this.stage, required this.captionsShown, required this.schoolStage});

  final PresentationStage stage;

  /// The words of the question are drawn (else a speaker stands in their place).
  final bool captionsShown;

  /// The confirmed stage, else the middle of the band.
  final SchoolStage schoolStage;
}

/// The look and captions of [childId] at [now]. [courseBand] is a language course's own band choice, which wins inside that course.
/// A child that is not in the database gets the middle of Band B.
Future<LookNow> lookFor(AppDatabase db, String childId, DateTime now, {int? courseBand}) async {
  // The four reads go out together: a lesson waits for them before it draws, so they are as quick as one.
  final (List<Profile> profiles, BirthMonth? birth, String? looks, CaptionSetting captions) = await (
    db.allProfiles(),
    db.birthOf(childId),
    db.setting(looksSettingKey),
    db.captionSettingOf(childId),
  ).wait;
  final Profile? profile = profiles.where((Profile p) => p.id == childId).firstOrNull;
  final ChildAge age = childAge(
    band: profile?.ageBand ?? 1,
    stage: profile?.confirmedStage,
    birth: profile == null ? null : birth,
    now: now,
  );
  return LookNow(
    stage: effectiveStage(age, lookBand: FamilyLooks.decode(looks).bandOf(childId), courseBand: courseBand),
    captionsShown: captionsShownFor(age.stage, captions),
    schoolStage: age.stage,
  );
}

/// The look a parent's pages show for a child ("now: the look of ages 5 to 6"). Invalidate it when a setting changes.
final FutureProviderFamily<LookNow, String> lookNowProvider = FutureProvider.autoDispose
    .family<LookNow, String>((Ref ref, String childId) async {
      final AppDatabase db = await ref.watch(databaseProvider.future);
      return lookFor(db, childId, DateTime.fromMillisecondsSinceEpoch(ref.read(clockProvider).nowMs()));
    });

/// The looks the parent chose for the family's children (a letter for each), as stored on this device.
final FutureProvider<FamilyLooks> familyLooksProvider = FutureProvider.autoDispose<FamilyLooks>((
  Ref ref,
) async {
  final AppDatabase db = await ref.watch(databaseProvider.future);
  return FamilyLooks.decode(await db.setting(looksSettingKey));
});

/// The captions setting of one child on this device.
final FutureProviderFamily<CaptionSetting, String> captionSettingProvider = FutureProvider.autoDispose
    .family<CaptionSetting, String>((Ref ref, String childId) async {
      final AppDatabase db = await ref.watch(databaseProvider.future);
      return db.captionSettingOf(childId);
    });
