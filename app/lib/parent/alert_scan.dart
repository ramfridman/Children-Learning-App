import 'package:drift/drift.dart' show Value;

import '../data/app_database.dart';
import 'alerts.dart';
import 'parent_rules.dart';

/// The parent's choice of whether the child's words are kept with an alert (default on, never more than 30 days).
const String keepWordsKey = 'keep_words';

/// How long an alert, and the words in it, are kept.
const Duration alertKeep = Duration(days: 30);

Future<bool> keepWordsOn(AppDatabase db) async => (await db.setting(keepWordsKey)) != 'off';

Future<bool> _save(AppDatabase db, AlertDraft d) => db.addAlert(
  AlertsCompanion.insert(
    at: d.at,
    profileId: Value<String?>(d.profileId),
    category: d.category.name,
    severity: d.severity.name,
    count: Value<int>(d.count),
    detail: Value<String>(d.detail),
    words: Value<String>(d.words),
    dedupeKey: d.key,
  ),
);

/// Looks through what the device has recorded and saves the alerts that are new. Safe to run as often as wanted: an
/// alert already saved is never repeated. Old alerts go, and the words go at once when the parent does not keep them.
/// Returns how many new alerts there were.
Future<int> runAlertScan(AppDatabase db, {required DateTime now, required ParentRules rules}) async {
  final List<Profile> profiles = await db.allProfiles();
  final List<ChildHistory> children = <ChildHistory>[
    for (final Profile p in profiles)
      ChildHistory(
        profileId: p.id,
        ageBand: p.ageBand,
        sessions: await db.sessionsOf(p.id),
        attempts: await db.attemptsOf(p.id),
      ),
  ];
  final List<AlertDraft> drafts = scanHistory(
    now: now,
    rules: rules,
    children: children,
    events: await db.recentEvents(limit: 200),
  );
  int fresh = 0;
  for (final AlertDraft d in drafts) {
    if (await _save(db, d)) fresh++;
  }
  await db.pruneAlerts(now.subtract(alertKeep));
  if (!await keepWordsOn(db)) await db.clearAlertWords();
  return fresh;
}

/// A spoken answer's words, looked at once: if they set off an alert it is saved now. The words are kept only when the
/// parent allows it. Nothing else about the answer is stored. Returns true if an alert was saved.
Future<bool> recordWordAlert(
  AppDatabase db, {
  required DateTime now,
  required String profileId,
  required List<String> texts,
}) async {
  final AlertDraft? d = wordAlert(
    at: now,
    profileId: profileId,
    texts: texts,
    keepWords: await keepWordsOn(db),
    key: 'words:$profileId:${now.millisecondsSinceEpoch}',
  );
  return d != null && await _save(db, d);
}
