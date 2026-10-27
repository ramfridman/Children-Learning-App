import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show FutureProviderFamily;

import '../content/engine_adapter.dart';
import '../content/models.dart';
import '../data/app_database.dart';
import '../parent/progress.dart';
import 'providers.dart';
import 'state.dart';

/// The progress view of one child (by profile id), built from the device's own attempts and sessions. The caller
/// invalidates it before showing the screen, so a parent always sees today's state.
final FutureProviderFamily<Progress, String> progressProvider = FutureProvider.family<Progress, String>((
  Ref ref,
  String profileId,
) async {
  final AppDatabase db = await ref.watch(databaseProvider.future);
  final PackContent content = await ref.watch(contentProvider.future);
  return buildProgress(
    ProgressSource(
      catalog: engineCatalog(content),
      skillInfo: <String, SkillInfo>{
        for (final SkillDoc s in content.skills.values) s.id: SkillInfo(title: s.title, domain: s.domain),
      },
      tagText: <String, String>{for (final TagDoc t in content.tags.values) t.id: t.parentText},
      attempts: (await db.attemptsOf(profileId)).map(eventOf).toList(),
      sessions: await db.sessionsOf(profileId),
      now: DateTime.fromMillisecondsSinceEpoch(ref.read(clockProvider).nowMs()),
    ),
  );
});
