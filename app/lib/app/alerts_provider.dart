import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/app_database.dart';
import '../parent/alert_scan.dart';
import '../parent/parent_rules.dart';
import 'providers.dart';
import 'rules_providers.dart';
import 'state.dart';

/// The alerts, newest first. Invalidated whenever a scan found something or the parent opens the screen.
final FutureProvider<List<Alert>> alertsProvider = FutureProvider<List<Alert>>(
  (Ref ref) async => (await ref.watch(databaseProvider.future)).allAlerts(),
);

/// How many alerts the parent has not seen.
final FutureProvider<int> unreadAlertsProvider = FutureProvider<int>(
  (Ref ref) async => (await ref.watch(databaseProvider.future)).unreadAlertCount(),
);

/// Looks for new alerts (the parent area calls this when it opens) and refreshes the lists.
Future<void> scanForAlerts(WidgetRef ref) async {
  final AppDatabase db = await ref.read(databaseProvider.future);
  final ParentRules rules = await ref.read(rulesProvider.future);
  final int fresh = await runAlertScan(
    db,
    now: DateTime.fromMillisecondsSinceEpoch(ref.read(clockProvider).nowMs()),
    rules: rules,
  );
  if (fresh >= 0) {
    ref.invalidate(alertsProvider);
    ref.invalidate(unreadAlertsProvider);
  }
}
