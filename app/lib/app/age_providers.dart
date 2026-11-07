import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show FutureProviderFamily;

import '../data/app_database.dart';
import '../data/profile_age.dart';
import '../engine/age.dart';
import 'providers.dart' show clockProvider;
import 'state.dart';

/// What the app knows about one child's age right now (B-29): the school stage, the band it sets, and (when a parent gave the month and
/// year of birth, kept on this device) the age in months and the look P1 to P4. It is worked out when read and never stored. A screen or
/// a session reads it once at its start, so nothing changes under a child mid-lesson; a birthday changes the look only at the next start,
/// and never the lessons, the finished lessons or the mastery, which this does not feed.
final FutureProviderFamily<ChildAge, String> childAgeProvider = FutureProvider.family<ChildAge, String>((
  Ref ref,
  String childId,
) async {
  final AppDatabase db = await ref.watch(databaseProvider.future);
  final Profile profile = (await db.allProfiles()).firstWhere((Profile p) => p.id == childId);
  return childAge(
    band: profile.ageBand,
    stage: profile.confirmedStage,
    birth: await db.birthOf(childId),
    now: DateTime.fromMillisecondsSinceEpoch(ref.read(clockProvider).nowMs()),
  );
});
