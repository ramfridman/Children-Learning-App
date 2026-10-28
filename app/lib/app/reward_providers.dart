import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show FutureProviderFamily;

import '../content/engine_adapter.dart';
import '../content/models.dart';
import '../data/app_database.dart';
import '../rewards/award.dart';
import '../rewards/ceremony.dart' show ceremoniesSettingKey;
import '../rewards/outfits.dart';
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

/// The setting for the ceremonies: on unless a parent switched them off (M8, F3). When off, a new trophy goes quietly to the
/// Hall and waits there with a soft glow.
const String ceremoniesKey = ceremoniesSettingKey;

final FutureProvider<bool> ceremoniesOnProvider = FutureProvider<bool>(
  (Ref ref) async => (await (await ref.watch(databaseProvider.future)).setting(ceremoniesKey)) != 'off',
);

/// Whether a trophy or a medal of this child is waiting to be looked at (the Hall's button glows).
final FutureProviderFamily<bool, String> hallWaitingProvider = FutureProvider.family<bool, String>((
  Ref ref,
  String childId,
) async {
  final List<Reward> all = await ref.watch(rewardsProvider(childId).future);
  return all.any(
    (Reward r) => r.seenAt == null && (r.kind == AwardKind.trophy.name || r.kind == AwardKind.medal.name),
  );
});

/// The stickers a child has, in the order they were earned.
final FutureProviderFamily<List<Reward>, String> stickersProvider =
    FutureProvider.family<List<Reward>, String>((Ref ref, String childId) async {
      final List<Reward> all = await ref.watch(rewardsProvider(childId).future);
      return all.where((Reward r) => r.kind == AwardKind.sticker.name).toList();
    });

/// The prize (an outfit id, or `none`) the playing child's companion wears, or null if never chosen. Choosing writes it at
/// once and every screen that draws the companion follows.
class OutfitNotifier extends AsyncNotifier<String?> {
  @override
  Future<String?> build() async {
    final Profile? child = ref.watch(activeProfileProvider);
    if (child == null) return null;
    return (await ref.watch(databaseProvider.future)).outfitOf(child.id);
  }

  Future<void> choose(String outfitId) async {
    final Profile? child = ref.read(activeProfileProvider);
    if (child == null) return;
    await (await ref.read(databaseProvider.future)).setOutfit(child.id, outfitId);
    state = AsyncData<String?>(outfitId);
  }
}

final AsyncNotifierProvider<OutfitNotifier, String?> outfitProvider =
    AsyncNotifierProvider<OutfitNotifier, String?>(OutfitNotifier.new);

/// The outfit the playing child's companion is wearing now (null for none).
Outfit? wornOutfit(AsyncValue<String?> chosen) => outfitById(chosen.value);

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
