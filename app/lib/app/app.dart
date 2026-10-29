import 'dart:async' show unawaited;

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';

import '../child/calm_loading.dart';
import '../child/ceremony_screen.dart';
import '../child/land_screen.dart';
import '../child/sticker_island.dart';
import '../child/trophy_hall.dart';
import '../rewards/ceremony.dart';
import '../rewards/outfits.dart' show Outfit;
import '../content/models.dart' show Lesson, PackContent;
import '../rewards/award.dart';
import '../world/next_lesson.dart';
import '../world/placement.dart';
import 'reward_providers.dart';
import 'world_providers.dart';
import '../child/rest_scene.dart';
import '../child/companion_views.dart';
import '../child/friends_beach.dart';
import '../characters/character.dart';
import '../child/home_island_name.dart';
import '../child/home_island_screen.dart';
import '../child/home_screen.dart';
import '../child/profile_picker.dart';
import '../data/app_database.dart';
import '../design/layout.dart';
import '../design/theme.dart';
import '../design/token_types.dart';
import '../design/tokens.g.dart';
import '../parent/entry_flow.dart';
import '../play/lesson_screen.dart';
import '../parent/setup_flow.dart';
import '../ui/dev/dev_strings.dart';
import 'companion.dart';
import 'providers.dart';
import '../parent/time_rules.dart';
import 'rules_providers.dart';
import 'push_providers.dart';
import 'sync_providers.dart';
import 'state.dart';
import 'tutor_providers.dart';

/// The app: Hebrew, right to left, phones in landscape and tablets in either orientation. It shows
/// the first-run setup until the device is registered, the PIN is chosen and a child exists; after
/// that the child space (picker, home, activity frame) with the parent area behind the gate.
class NitznutzApp extends ConsumerWidget {
  const NitznutzApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final Profile? active = ref.watch(activeProfileProvider);
    return MaterialApp(
      title: 'Nitznutz',
      debugShowCheckedModeBanner: false,
      locale: const Locale('he'),
      supportedLocales: const <Locale>[Locale('he')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      navigatorKey: ref.watch(navigatorKeyProvider),
      theme: AppTheme.child(),
      builder: (BuildContext context, Widget? child) => SyncScope(
        child: PushScope(
          child: LayoutScope(
            band: active == null ? Band.b : Band.values[active.ageBand],
            child: _OrientationLock(child: child!),
          ),
        ),
      ),
      home: const _Root(),
    );
  }
}

/// Phones are locked to landscape; tablets follow the device (design spec 7.1).
class _OrientationLock extends StatefulWidget {
  const _OrientationLock({required this.child});

  final Widget child;

  @override
  State<_OrientationLock> createState() => _OrientationLockState();
}

class _OrientationLockState extends State<_OrientationLock> {
  SizeClass? _applied;

  @override
  Widget build(BuildContext context) {
    final SizeClass now = AppLayout.of(context).sizeClass;
    if (now != _applied) {
      _applied = now;
      SystemChrome.setPreferredOrientations(
        now == SizeClass.tablet
            ? DeviceOrientation.values
            : const <DeviceOrientation>[DeviceOrientation.landscapeLeft, DeviceOrientation.landscapeRight],
      );
    }
    return widget.child;
  }
}

class _Root extends ConsumerWidget {
  const _Root();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // A start from a push notification goes straight to the gate: until that is known, and while the gate opens, show a
    // loading screen, never the child picker.
    final TapState tap = ref.watch(notificationTapProvider);
    if (tap == TapState.checking) return const ColoredBox(color: TokenColors.cream);
    if (tap == TapState.pending) return const _OpeningParentArea();
    final AsyncValue<AppState> state = ref.watch(appStateProvider);
    return state.when(
      loading: () => const ColoredBox(color: TokenColors.cream),
      error: (Object e, StackTrace s) => const Scaffold(body: Center(child: Text(DevStrings.configProblem))),
      data: (AppState app) {
        if (!app.setupDone) return SetupFlow(onFinished: () => ref.invalidate(appStateProvider));
        final Profile? active = ref.watch(activeProfileProvider);
        // A profile removed in the parent area while it was chosen sends the child back to the picker.
        final Profile? current = active == null
            ? null
            : app.profiles.cast<Profile?>().firstWhere(
                (Profile? p) => p!.id == active.id,
                orElse: () => null,
              );
        if (current == null) {
          // Start getting the characters ready while the child is still choosing, so the map does not have to wait.
          ref.read(resolverProvider);
          ref.read(characterSourceProvider);
          return ProfilePicker(
            profiles: app.profiles,
            onChoose: (Profile p) => ref.read(activeProfileProvider.notifier).choose(p),
            onAdd: () => openParentArea(context, ref),
          );
        }
        return _Home(profile: current);
      },
    );
  }
}

/// Shown for the moment between a tap on a notification and the parent gate.
class _OpeningParentArea extends StatelessWidget {
  const _OpeningParentArea();

  @override
  Widget build(BuildContext context) => const ColoredBox(
    color: TokenColors.parentBg,
    child: Center(child: CircularProgressIndicator(key: Key('opening-parent-area'))),
  );
}

/// The home map of the playing child, with the companion on it. After the first lesson the child is taken to
/// Friends' Beach once, to choose a companion; the plus button next to the companion goes there any time.
class _Home extends ConsumerStatefulWidget {
  const _Home({required this.profile});

  final Profile profile;

  @override
  ConsumerState<_Home> createState() => _HomeState();
}

class _HomeState extends ConsumerState<_Home> {
  final GlobalKey<MapCompanionState> _companion = GlobalKey<MapCompanionState>();

  String get _offeredKey => 'friends_offered:${widget.profile.id}';

  /// The words of the child's island, from the name the parent typed; worked out again only when the name changes.
  late HomeIslandName _island = homeIslandName(widget.profile.name);

  @override
  void didUpdateWidget(_Home old) {
    super.didUpdateWidget(old);
    if (old.profile.name != widget.profile.name) _island = homeIslandName(widget.profile.name);
  }

  Future<void> _openFriends() =>
      Navigator.of(context).push(MaterialPageRoute<void>(builder: (BuildContext c) => const FriendsBeach()));

  @override
  void initState() {
    super.initState();
    // Whatever the child has already earned is looked at once when the map opens (the first time, quietly; M8).
    unawaited(_lookAtRewards());
  }

  /// The first look at what the child has earned. If it gave a trophy or a medal to celebrate, the ceremony follows.
  Future<void> _lookAtRewards() async {
    final List<Reward> fresh = await evaluateRewardsFor(ref, widget.profile.id);
    if (!mounted) return;
    if (fresh.any((Reward r) => r.seenAt == null && (r.kind == 'trophy' || r.kind == 'medal'))) {
      await _maybeCeremony();
    }
  }

  bool _ceremonyOpen = false;

  /// One ceremony for the best award waiting, unless a parent switched ceremonies off (then it waits in the Hall). Called
  /// when a lesson or a revisit mission has ended, so at most one ceremony comes after a lesson (M8, Q8).
  Future<void> _maybeCeremony() async {
    if (_ceremonyOpen || !mounted) return;
    final AppDatabase db = await ref.read(databaseProvider.future);
    final ({Reward reward, Outfit? prize})? due = await nextCeremonyFor(db, widget.profile.id);
    if (due == null || !mounted) return;
    final Reward next = due.reward;
    final Outfit? prize = due.prize;
    _ceremonyOpen = true;
    await db.markRewardsSeen(<int>[
      next.id,
    ], DateTime.fromMillisecondsSinceEpoch(ref.read(clockProvider).nowMs(), isUtc: true));
    if (mounted) {
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (BuildContext c) => CeremonyScreen(awardKey: next.awardKey, prize: prize),
        ),
      );
    }
    _ceremonyOpen = false;
    if (mounted) ref.invalidate(rewardsProvider(widget.profile.id));
  }

  Future<void> _openHall() async {
    await Navigator.of(context)
        .push(MaterialPageRoute<void>(builder: (BuildContext c) => TrophyHall(childId: widget.profile.id)));
    if (mounted) _refreshWorld();
  }

  void _refreshWorld() {
    ref.invalidate(rewardsProvider(widget.profile.id));
    ref.invalidate(worldProvider(widget.profile.id));
  }

  /// A land with skills opens as an island with its objects; it has a way into the lesson if the pack has one for it.
  Future<void> _openLand(Land land) async {
    final TrophyLand trophyLand = TrophyLand.values.byName(land.name);
    final PackContent? content = ref.read(contentProvider).value;
    final bool hasLesson =
        content != null &&
        content.lessons.values.any(
          (Lesson l) => l.skillIds.any((String s) => content.skills[s]?.domain == trophyLand.domain),
        );
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (BuildContext c) => LandScreen(
          childId: widget.profile.id,
          land: trophyLand,
          // A lesson played from the island ends back on the map, as before; a revisit mission ends back on the island, so
          // the child sees the golden star appear.
          onPlay: hasLesson
              ? () async {
                  await _playLand(trophyLand.domain);
                  if (c.mounted) Navigator.of(c).pop();
                }
              : null,
          onMission: (Lesson mission) => _openLesson(mission: mission),
        ),
      ),
    );
    if (mounted) _refreshWorld();
  }

  /// The child's home, from the home island's sign or Today's Adventure. The map stays underneath, so the child comes
  /// back to it where they left it.
  Future<void> _openHome() async {
    await Navigator.of(context)
        .push(MaterialPageRoute<void>(builder: (BuildContext c) => HomeIslandScreen(island: _island)));
    if (mounted) _refreshWorld();
  }

  Future<void> _openStickers() => Navigator.of(context)
      .push(MaterialPageRoute<void>(builder: (BuildContext c) => StickerIsland(childId: widget.profile.id)));

  /// Plays a land: the warm-up first if this is the child's first visit to it (the older ones only), then the lesson the
  /// path has next. The warm-up ends gently and never blocks the way: whatever it shows, the path goes on.
  Future<void> _playLand(String domain) async {
    final PackContent? content = ref.read(contentProvider).value;
    if (content == null) return;
    final AppDatabase db = await ref.read(databaseProvider.future);
    final List<Attempt> history = await db.attemptsOf(widget.profile.id);
    if (widget.profile.ageBand >= 1 &&
        (await ref.read(warmUpProvider.future)) &&
        placementDue(content, domain, history)) {
      final Lesson? warmUp = placementLesson(content, domain);
      if (warmUp != null && !await _openLesson(mission: warmUp)) return;
    }
    if (!mounted) return;
    await _openLesson(lessonId: await _nextLesson(domain));
  }

  /// The lesson the child plays next in a land: the first one on its path that they have not finished, or that the
  /// warm-up showed they already know.
  Future<String?> _nextLesson(String domain) async {
    final PackContent? content = ref.read(contentProvider).value;
    if (content == null) return null;
    final AppDatabase db = await ref.read(databaseProvider.future);
    final Map<String, int> finished = <String, int>{
      for (final String id in placedLessons(content, await db.attemptsOf(widget.profile.id))) id: 1,
    };
    for (final Reward r in ref.read(rewardsProvider(widget.profile.id)).value ?? const <Reward>[]) {
      final ({String lessonId, int n})? s = Awards.stickerOf(r.awardKey);
      if (s != null && s.n > (finished[s.lessonId] ?? 0)) finished[s.lessonId] = s.n;
    }
    return nextLessonId(content: content, domain: domain, finished: finished);
  }

  /// Opens a lesson (or the rest scene when time is up). True when the child played it to its end.
  Future<bool> _openLesson({Lesson? mission, String? lessonId}) async {
    // Time is up (rest hours, the schedule or the daily limit, with the lock on): a calm scene instead of the lesson.
    final ({String id, int band}) child = (id: widget.profile.id, band: widget.profile.ageBand);
    ref.invalidate(timeVerdictProvider(child));
    final TimeVerdict verdict = await ref.read(timeVerdictProvider(child).future);
    if (!mounted) return false;
    if (verdict.locked) {
      await Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (BuildContext c) => RestScene(onBack: () => Navigator.of(c).pop())),
      );
      return false;
    }
    final bool? finished = await Navigator.of(context).push(
      MaterialPageRoute<bool>(
        builder: (BuildContext c) =>
            LessonScreen(profileId: widget.profile.id, mission: mission, lessonId: lessonId ?? 'butterflies'),
      ),
    );
    if (mounted) _refreshWorld();
    // A trophy or a medal the visit earned gets its ceremony back on the map.
    if (mounted) await _maybeCeremony();
    if (!mounted || finished != true) return false;
    if (mission != null) return true;
    final AppDatabase db = await ref.read(databaseProvider.future);
    if (await db.setting(_offeredKey) != null) return true;
    await db.putSetting(_offeredKey, 'yes');
    if (mounted) await _openFriends();
    return true;
  }

  @override
  Widget build(BuildContext context) {
    // The map appears whole: until its character and the guide's voice are ready, a calm loading scene shows instead.
    final AsyncValue<Character> friend = ref.watch(characterForRoleProvider(CharacterRole.mapCompanion));
    final AsyncValue<Guide> guide = ref.watch(guideProvider);
    // Asks the server's helper switch now, while the map shows, so that a lesson finds the answer ready.
    ref.watch(tutorAvailableProvider);
    if ((friend.isLoading && !friend.hasValue) || (guide.isLoading && !guide.hasValue)) {
      return const CalmLoading();
    }
    return _map(friend.value);
  }

  /// The lands that have skills (the counting hills always open, as before). Never the home island: it is not a land
  /// with skills (`TrophyLand` has no `nitzi`) and opens through [_openHome].
  Set<Land> _openableLands() => <Land>{
    Land.counting,
    for (final TrophyLand t
        in ref.watch(worldProvider(widget.profile.id)).value?.lands.keys ?? const <TrophyLand>[])
      Land.values.byName(t.name),
  };

  Widget _map(Character? friend) => HomeScreen(
    childName: _island.name,
    homeIsland: _island,
    onOpenHome: _openHome,
    avatarId: widget.profile.avatar,
    onParents: () => openParentArea(context, ref),
    onSwitchChild: () => ref.read(activeProfileProvider.notifier).choose(null),
    onOpenActivity: () => _playLand('numbers'),
    onOpenLand: _openLand,
    openableLands: _openableLands(),
    stars: ref.watch(goldenStarsProvider(widget.profile.id)).value ?? 0,
    onStickers: _openStickers,
    onHall: _openHall,
    hallGlow: ref.watch(hallWaitingProvider(widget.profile.id)).value ?? false,
    companion: MapCompanion(key: _companion, greetingVoice: 'vo:core.greeting.hello'),
    companionMouth: friend?.mouth,
    onCompanion: () => _companion.currentState?.greet(),
    onFriends: _openFriends,
  );
}

/// Shown instead of the app when the build settings are wrong. Says nothing about the values.
class ConfigProblemApp extends StatelessWidget {
  const ConfigProblemApp({super.key});

  @override
  Widget build(BuildContext context) => const MaterialApp(
    home: Scaffold(body: Center(child: Text(DevStrings.configProblem))),
  );
}
