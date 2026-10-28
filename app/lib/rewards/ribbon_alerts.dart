import 'package:drift/drift.dart' show Value;

import '../data/app_database.dart';
import 'award.dart';
import 'ribbons.dart';

/// Tells the parents that a trophy with a promise on it was earned (M8, F2). The alert holds only the child and the trophy's
/// key: the words of the promise are looked up on the parent's own phone, and are never in the alert, the push, an event or
/// a log. One alert for each child and trophy, however many times it is looked at. Returns how many new alerts were saved.
Future<int> raiseRibbonAlerts(
  AppDatabase db, {
  required String childId,
  required List<Reward> fresh,
  required DateTime now,
}) async {
  final Map<String, String> promises =
      decodeRibbons(await db.setting('ribbons'))[childId] ?? const <String, String>{};
  if (promises.isEmpty) return 0;
  int saved = 0;
  for (final Reward r in fresh) {
    if (r.kind != AwardKind.trophy.name || !promises.containsKey(r.awardKey)) continue;
    final bool isNew = await db.addAlert(
      AlertsCompanion.insert(
        at: now,
        profileId: Value<String?>(childId),
        category: 'ribbonEarned',
        severity: 'info',
        detail: Value<String>(r.awardKey),
        dedupeKey: 'ribbon:$childId:${r.awardKey}',
      ),
    );
    if (isNew) saved++;
  }
  return saved;
}
