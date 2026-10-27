import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show FutureProviderFamily;

import '../data/app_database.dart';
import '../parent/parent_rules.dart';
import '../parent/time_rules.dart';
import 'providers.dart';
import 'state.dart';

const String _rulesKey = 'parent_rules';

/// The parent's time rules of this device. Changing them writes the setting at once; a child's next tap uses them.
class RulesNotifier extends AsyncNotifier<ParentRules> {
  @override
  Future<ParentRules> build() async =>
      ParentRules.decode(await (await ref.watch(databaseProvider.future)).setting(_rulesKey));

  Future<void> set(ParentRules rules) async {
    await (await ref.read(databaseProvider.future)).putSetting(_rulesKey, rules.encode());
    state = AsyncData<ParentRules>(rules);
  }
}

final AsyncNotifierProvider<RulesNotifier, ParentRules> rulesProvider =
    AsyncNotifierProvider<RulesNotifier, ParentRules>(RulesNotifier.new);

/// Local time now, from the app's clock (tests fake it).
DateTime localNow(Ref ref) => DateTime.fromMillisecondsSinceEpoch(ref.read(clockProvider).nowMs());

/// May this child start playing now? Reads the rules and today's sessions.
final FutureProviderFamily<TimeVerdict, ({String id, int band})> timeVerdictProvider =
    FutureProvider.family<TimeVerdict, ({String id, int band})>((
      Ref ref,
      ({String id, int band}) child,
    ) async {
      final ParentRules rules = await ref.watch(rulesProvider.future);
      final AppDatabase db = await ref.watch(databaseProvider.future);
      final DateTime now = localNow(ref);
      return judgeTime(
        now: now,
        rules: rules,
        profileId: child.id,
        ageBand: child.band,
        minutesToday: playedMinutesToday(await db.sessionsOf(child.id), now),
      );
    });
