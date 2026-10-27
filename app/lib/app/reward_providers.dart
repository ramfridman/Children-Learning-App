import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show FutureProviderFamily;

import '../content/engine_adapter.dart';
import '../content/models.dart';
import '../data/app_database.dart';
import '../rewards/award.dart';
import '../rewards/reward_service.dart';
import 'providers.dart';
import 'state.dart';

/// Works out and keeps what children have earned. Needs the pack (for the skills) and the database.
final FutureProvider<RewardService> rewardServiceProvider = FutureProvider<RewardService>((Ref ref) async {
  final PackContent content = await ref.watch(contentProvider.future);
  return RewardService(
    db: await ref.watch(databaseProvider.future),
    catalog: engineCatalog(content),
    domains: <String, String>{for (final SkillDoc s in content.skills.values) s.id: s.domain},
    nowMs: ref.read(clockProvider).nowMs,
  );
});

/// Everything one child has been given, oldest first. Invalidated whenever something was given.
final FutureProviderFamily<List<Reward>, String> rewardsProvider =
    FutureProvider.family<List<Reward>, String>(
      (Ref ref, String childId) async => (await ref.watch(databaseProvider.future)).rewardsOf(childId),
    );

/// The golden stars a child has (one for each skill that reached lasting understanding).
final FutureProviderFamily<int, String> goldenStarsProvider = FutureProvider.family<int, String>((
  Ref ref,
  String childId,
) async {
  final List<Reward> all = await ref.watch(rewardsProvider(childId).future);
  return all.where((Reward r) => r.kind == AwardKind.star.name).length;
});

/// The stickers a child has, in the order they were earned.
final FutureProviderFamily<List<Reward>, String> stickersProvider =
    FutureProvider.family<List<Reward>, String>((Ref ref, String childId) async {
      final List<Reward> all = await ref.watch(rewardsProvider(childId).future);
      return all.where((Reward r) => r.kind == AwardKind.sticker.name).toList();
    });

/// Asks for whatever the child has earned, and refreshes what shows it. Returns the awards given just now. Safe to
/// call as often as wanted; it never throws to the caller (a child must never be stopped by it).
Future<List<Reward>> evaluateRewards(Ref ref, String childId) async {
  try {
    final RewardService service = await ref.read(rewardServiceProvider.future);
    final List<Reward> fresh = await service.evaluate(childId);
    if (fresh.isNotEmpty && ref.mounted) ref.invalidate(rewardsProvider(childId));
    return fresh;
  } on Object {
    return const <Reward>[];
  }
}

/// The same thing as a function a screen can keep and call after it is gone (the app's providers outlive a screen).
final Provider<Future<List<Reward>> Function(String)> rewardEvaluatorProvider =
    Provider<Future<List<Reward>> Function(String)>(
      (Ref ref) =>
          (String childId) => evaluateRewards(ref, childId),
    );

/// The same, from a widget.
Future<List<Reward>> evaluateRewardsFor(WidgetRef ref, String childId) async {
  try {
    final RewardService service = await ref.read(rewardServiceProvider.future);
    final List<Reward> fresh = await service.evaluate(childId);
    if (fresh.isNotEmpty && ref.context.mounted) ref.invalidate(rewardsProvider(childId));
    return fresh;
  } on Object {
    return const <Reward>[];
  }
}
