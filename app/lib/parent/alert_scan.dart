import 'package:drift/drift.dart' show Value;

import '../data/app_database.dart';
import '../speech/alert_words.dart';
import 'alerts.dart';
import 'parent_rules.dart';

/// The parent's choice of whether the child's words are kept with an alert (default on, never more than 30 days).
const String keepWordsKey = 'keep_words';

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
  await db.tidyAlerts(now);
  return fresh;
}

/// A spoken answer's words (the recogniser's hypotheses, best first), looked at once: if they set off an alert it is
/// saved or counted now ([planWordAlert]). The words kept are the hypothesis that matched, only when the parent allows
/// it; nothing else about the answer is stored. [ageBand] is the child's band and [answerWords] the answers of the
/// activity on screen. With [offThread] the words are matched on another isolate, so the lesson never waits for them
/// (the app does this; tests that pump frames by hand do not). Returns true if an alert was saved or counted.
Future<bool> recordWordAlert(
  AppDatabase db, {
  required DateTime now,
  required String profileId,
  required List<String> texts,
  required int ageBand,
  Set<String> answerWords = const <String>{},
  AlertLists? lists,
  bool offThread = false,
}) async {
  final WordMatch? match = offThread
      ? await checkWordsOffThread(texts, ageBand: ageBand, answerWords: answerWords, lists: lists)
      : checkWords(texts, ageBand: ageBand, answerWords: answerWords, lists: lists);
  if (match == null) return false;
  final bool keep = await keepWordsOn(db);
  // One transaction: two answers close together must not both start a new alert.
  return db.transaction(() async {
    final List<WordStep> steps = planWordAlert(
      now: now,
      profileId: profileId,
      match: match,
      keepWords: keep,
      recent: await db.alertsOfChildSince(profileId, now.subtract(repeatWindow)),
    );
    bool changed = false;
    for (final WordStep s in steps) {
      switch (s) {
        case AddAlert(:final AlertDraft draft):
          changed = await _save(db, draft) || changed;
        case CountAgain(:final Alert alert, :final DateTime? at, :final String? words):
          await db.countAlertAgain(alert, at: at, words: words);
          changed = true;
      }
    }
    return changed;
  });
}
