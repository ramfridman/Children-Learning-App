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
import '../rewards/sticker_design.dart';
import '../engine/engine.dart' show Engine;
import '../voice/voice_director.dart';
import '../world/next_lesson.dart';
import '../world/adventure_adapter.dart';
import '../world/placement.dart';
import '../world/todays_adventure.dart';
import '../world/welcome_adapter.dart';
import '../world/welcome_lines.dart';
import '../world/welcome_table.dart';
import '../child/adventure_line.dart' show AdventureLine, adventureLine;
import 'bottle_hold.dart';
import 'welcome_hold.dart';
import 'welcome_providers.dart';
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
import '../core/log.dart';
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

class _HomeState extends ConsumerState<_Home> with WidgetsBindingObserver {
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
    WidgetsBinding.instance.addObserver(this);
    // Whatever the child has already earned is looked at once when the map opens (the first time, quietly; M8).
    unawaited(_lookAtRewards());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _welcome?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // The app left the front: the welcome stops, as for a touch.
    if (state != AppLifecycleState.resumed) _welcome?.skip();
  }

  /// The first look at what the child has earned. If it gave a trophy or a medal to celebrate, the ceremony follows, and
  /// only after it the day's welcome (a ceremony is never talked over).
  Future<void> _lookAtRewards() async {
    final List<Reward> fresh = await evaluateRewardsFor(ref, widget.profile.id);
    if (!mounted) return;
    if (fresh.any((Reward r) => r.seenAt == null && (r.kind == 'trophy' || r.kind == 'medal'))) {
      await _maybeCeremony();
    }
    if (mounted) await _offerWelcome();
  }

  /// The daily welcome in progress, if there is one: the friend's words in the bubble, the pill's glow, the voice.
  WelcomeHold? _welcome;
  bool _welcomeBusy = false;

  /// Whether the map is the screen the child sees: nothing (a lesson, the friend choice, the parent area, a ceremony, the
  /// rest scene) lies on top of it.
  bool get _mapInFront => (ModalRoute.of(context)?.isCurrent ?? true) && !_ceremonyOpen;

  /// The daily welcome (B-42, docs/milestones/B42.md section 2): once a day for each child, the first time their map is
  /// shown and settled, the friend greets them and says what the bottle holds. Never on top of something else: if the map is
  /// not in front, or the parent's time is up, it waits for the next time the map comes back (this runs again then).
  Future<void> _offerWelcome() async {
    if (_welcomeBusy || _welcome != null || !mounted || !ref.read(welcomeEnabledProvider)) return;
    _welcomeBusy = true;
    try {
      await _giveWelcome();
    } on Object catch (e) {
      // The welcome is a gift: whatever goes wrong with it (a pack or a voice that fails to load) never reaches the child.
      Log.d('welcome: skipped (${e.runtimeType})');
    } finally {
      _welcomeBusy = false;
    }
  }

  Future<void> _giveWelcome() async {
    final Profile child = widget.profile;
    if (!_mapInFront) return;
    final AppDatabase db = await ref.read(databaseProvider.future);
    final int today = Engine.dayKey(
      DateTime.fromMillisecondsSinceEpoch(ref.read(clockProvider).nowMs(), isUtc: true),
    );
    if (await db.welcomeDayOf(child.id) == today) return;
    // The parent's time is up: the rest scene is all this child can open, so no adventure is offered.
    final ({String id, int band}) who = (id: child.id, band: child.ageBand);
    ref.invalidate(timeVerdictProvider(who));
    if ((await ref.read(timeVerdictProvider(who).future)).locked) return;
    // The pack may still be loading when the map first opens: wait for it rather than skip the day's welcome.
    final PackContent content = await ref.read(contentProvider.future);
    final ({TodaysAdventure stop, WorldView world, List<Attempt> attempts})? adventure =
        await _adventureNow();
    if (adventure == null) return;
    final WelcomeTable table = await ref.read(welcomeTableProvider.future);
    final Uint8List? nameClip = await ref.read(nameClipProvider(child.id).future);
    final bool warmUpOn = await ref.read(warmUpProvider.future);
    // The map appears whole: the welcome waits for the friend and the voice to be ready, then for the map to be drawn.
    await ref.read(characterForRoleProvider(CharacterRole.mapCompanion).future);
    await ref.read(guideProvider.future);
    await WidgetsBinding.instance.endOfFrame;
    if (!mounted || !_mapInFront) return;

    final List<String> lines = welcomeLines(
      stop: adventure.stop,
      today: today,
      hasNameClip: nameClip != null,
      warmUpDue: (TrophyLand land) =>
          child.ageBand >= 1 && warmUpOn && placementDue(content, land.domain, adventure.attempts),
      skillOfLesson: (String lessonId, TrophyLand land) => firstSkillInLand(content, lessonId, land),
      table: table,
    );
    final VoiceDirector director = ref.read(voiceDirectorProvider);
    final List<WelcomeStep> steps = _welcomeSteps(lines, table, nameClip);
    // Whole or not at all: a missing recording, or the sound off, makes the whole welcome text (no half-voiced sequence).
    final bool voiced =
        ref.read(welcomeSpokenProvider) &&
        steps.every((WelcomeStep s) => director.bank?.has(s.voice!) ?? false);
    if (voiced) await director.prefetch(<String>[for (final WelcomeStep s in steps) s.voice!]);
    if (!mounted || !_mapInFront) return;

    // Written when the welcome starts: leaving, a crash or a skip never brings it back the same day.
    await db.setWelcomeDay(child.id, today);
    final WelcomeHold hold = WelcomeHold(director, gap: _welcomeGap(child.ageBand));
    setState(() => _welcome = hold);
    await hold.run(steps, voiced: voiced);
    if (mounted) setState(() => _welcome = null);
    // The listeners of the bubble and the pill go with the next frame; the notifiers are let go after it.
    WidgetsBinding.instance.addPostFrameCallback((_) => hold.dispose());
  }

  /// The sentences of [lines]: the first (a greeting) carries the child's name in its caption whenever the child has a usable
  /// name, and the name clip when there is one; the last points at the bottle.
  List<WelcomeStep> _welcomeSteps(List<String> lines, WelcomeTable table, Uint8List? nameClip) {
    final bool named = _island.name.isNotEmpty;
    final List<WelcomeStep> steps = <WelcomeStep>[];
    for (final String id in lines) {
      if (id == welcomeNameClip) continue;
      steps.add(
        WelcomeStep(
          text: table.text(id),
          withName: named && steps.isEmpty,
          voice: id,
          nameClip: steps.isEmpty ? nameClip : null,
          pointsAtBottle: id == welcomeClose,
        ),
      );
    }
    return steps;
  }

  /// The pause between two sentences: the youngest get the longest (B42.md 2.5).
  Duration _welcomeGap(int band) => Duration(milliseconds: const <int>[500, 350, 300][band.clamp(0, 2)]);

  bool _ceremonyOpen = false;

  /// One ceremony for the best award waiting, unless a parent switched ceremonies off (then it waits in the Hall). Called
  /// when a lesson or a revisit mission has ended, so at most one ceremony comes after a lesson (M8, Q8).
  Future<void> _maybeCeremony() async {
    if (_ceremonyOpen || !mounted) return;
    _welcome?.skip();
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
    // Back on the map: if the day's welcome could not come before (something lay on top of it), it comes now.
    unawaited(_offerWelcome());
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

  /// The child's home, from the home island's sign or Today's Adventure: the bottle, the friend at its door, the sticker
  /// book and the lighthouse (the Trophy Hall). The map stays underneath, so the child comes back to it where they left
  /// it; the Hall, the album and a lesson started from the bottle come back to the home.
  Future<void> _openHome() async {
    final String id = widget.profile.id;
    final GlobalKey<MapCompanionState> friend = GlobalKey<MapCompanionState>();
    final BottleHold bottle = BottleHold(ref.read(voiceDirectorProvider));
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        // A consumer of its own: the lantern's glow and the sticker on the book follow the rewards while the home is open.
        builder: (BuildContext c) => Consumer(
          builder: (BuildContext c, WidgetRef ref, Widget? _) {
            final List<Reward> stickers = ref.watch(stickersProvider(id)).value ?? const <Reward>[];
            return HomeIslandScreen(
              island: _island,
              // It waves when the child arrives, silently (B-26 decision 6: nothing is voiced here yet).
              companion: MapCompanion(key: friend, waveOnStart: true),
              onCompanion: () => friend.currentState?.greet(),
              onBottle: () => _openTodaysAdventure(bottle),
              bottleLine: bottle.line,
              bottleWobble: bottle.wobble,
              // Going to the book or the lighthouse drops the stop that the line was waiting to open.
              onStickers: () {
                bottle.drop();
                unawaited(_openStickers());
              },
              onHall: () {
                bottle.drop();
                unawaited(_openHall());
              },
              hallGlow: ref.watch(hallWaitingProvider(id)).value ?? false,
              sticker: stickers.isEmpty ? firstStickerAsset : stickerAsset(stickers.last.awardKey),
            );
          },
        ),
      ),
    );
    bottle.dispose();
    if (mounted) _refreshWorld();
  }

  /// What the bottle in the child's home opens: today's adventure (docs/curriculum/todays-adventure-rule.md). This is the
  /// only place that decides it, and it is worked out when the child taps, from their visits and what is due then. A call
  /// for help opens the revisit mission of the map's own bell, a lesson goes the way of the land's play pebble (the warm-up
  /// first when it is due), and a game played again opens that lesson. Each comes back to the home; nothing is lost if
  /// the bottle is never tapped. The friend's bubble on the home says the line for the stop ([adventureLine]), in its
  /// voice when the pack has the recording, and the stop opens when the line has been seen and heard ([BottleHold]); a
  /// second touch opens it at once, and leaving the home drops it. With nothing to open the bottle only wobbles.
  Future<void> _openTodaysAdventure(BottleHold bottle) async {
    // A second touch while the line waits goes on at once; while the stop is still being worked out it is not a second stop.
    if (bottle.waiting) return bottle.releaseNow();
    if (bottle.busy) return;
    if (ref.read(contentProvider).value == null) return;
    bottle.busy = true;
    try {
      final ({TodaysAdventure stop, WorldView world, List<Attempt> attempts})? adventure =
          await _adventureNow();
      if (adventure == null || !mounted || bottle.gone) return;
      final TodaysAdventure stop = adventure.stop;
      final AdventureLine? words = adventureLine(stop);
      if (words == null) {
        bottle.nudge();
        return;
      }
      if (!await bottle.hold(words) || !mounted || bottle.gone) return;
      await _openStop(stop, adventure.world);
    } finally {
      bottle.clear();
      bottle.busy = false;
    }
  }

  /// Today's Adventure for the playing child as of now, with the world and the answers it was worked out from (null while
  /// the pack is not loaded). The bottle and the daily welcome both ask here, so they can never disagree about the stop.
  Future<({TodaysAdventure stop, WorldView world, List<Attempt> attempts})?> _adventureNow() async {
    final PackContent? content = ref.read(contentProvider).value;
    if (content == null) return null;
    final String id = widget.profile.id;
    final AppDatabase db = await ref.read(databaseProvider.future);
    final WorldView world = await ref.read(worldProvider(id).future);
    final List<Reward> rewards = await ref.read(rewardsProvider(id).future);
    final List<Attempt> attempts = await db.attemptsOf(id);
    final TodaysAdventure stop = todaysAdventureFor(
      content: content,
      engine: world.engine,
      attempts: attempts,
      sessions: await db.sessionsOf(id),
      finished: finishedLessons(content, attempts, rewards.map((Reward r) => r.awardKey)),
      now: DateTime.fromMillisecondsSinceEpoch(ref.read(clockProvider).nowMs(), isUtc: true),
      band: widget.profile.ageBand,
    );
    return (stop: stop, world: world, attempts: attempts);
  }

  Future<void> _openStop(TodaysAdventure stop, WorldView world) async {
    switch (stop.kind) {
      case AdventureKind.revisit:
        final Lesson? mission = world.missionFor(stop.skillId!);
        if (mission != null) await _openLesson(mission: mission);
      case AdventureKind.lesson:
        await _playLand(stop.land!.domain);
      case AdventureKind.replay:
        await _openLesson(lessonId: stop.lessonId);
      case AdventureKind.none:
        break;
    }
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
    final String id = widget.profile.id;
    final List<Reward> rewards = ref.read(rewardsProvider(id)).value ?? const <Reward>[];
    final Map<String, int> finished = finishedLessons(
      content,
      await db.attemptsOf(id),
      rewards.map((Reward r) => r.awardKey),
    );
    return nextLessonId(content: content, domain: domain, finished: finished);
  }

  /// Opens a lesson (or the rest scene when time is up). True when the child played it to its end.
  Future<bool> _openLesson({Lesson? mission, String? lessonId}) async {
    // Time is up (rest hours, the schedule or the daily limit, with the lock on): a calm scene instead of the lesson.
    _welcome?.skip();
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
    // The sound of the child's name (if a parent made one) is ready before the friend is touched.
    ref.watch(nameClipProvider(widget.profile.id));
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

  Widget _map(Character? friend) => Listener(
    // Any touch stops the welcome; the touch itself goes on to do what it always does.
    behavior: HitTestBehavior.translucent,
    onPointerDown: (_) => _welcome?.skip(),
    child: _homeScreen(friend),
  );

  Widget _homeScreen(Character? friend) => HomeScreen(
    childName: _island.name,
    welcome: _welcome?.shown,
    pillGlow: _welcome?.glow,
    homeIsland: _island,
    onOpenHome: _openHome,
    avatarId: widget.profile.avatar,
    onParents: () => openParentArea(context, ref),
    onSwitchChild: () => ref.read(activeProfileProvider.notifier).choose(null),
    onOpenActivity: () => _playLand('numbers'),
    onOpenLand: _openLand,
    openableLands: _openableLands(),
    stars: ref.watch(goldenStarsProvider(widget.profile.id)).value ?? 0,
    hallGlow: ref.watch(hallWaitingProvider(widget.profile.id)).value ?? false,
    companion: MapCompanion(key: _companion, greetingVoice: 'vo:core.greeting.hello'),
    companionMouth: friend?.mouth,
    onCompanion: _greetFriend,
    onFriends: _openFriends,
  );

  /// A touch on the friend: it waves and greets. When the child's name clip has been made, it says the name and then the
  /// map bubble's shared clip, so it says what the bubble shows (the name, then the question about the bottle); without a
  /// name clip it says its hello, as before.
  void _greetFriend() {
    final Uint8List? name = ref.read(nameClipProvider(widget.profile.id)).value;
    final bool bubble = name != null && (ref.read(voiceDirectorProvider).bank?.has(homeBubbleVoice) ?? false);
    _companion.currentState?.greet(voice: bubble ? homeBubbleVoice : null, nameClip: bubble ? name : null);
  }
}

/// Shown instead of the app when the build settings are wrong. Says nothing about the values.
class ConfigProblemApp extends StatelessWidget {
  const ConfigProblemApp({super.key});

  @override
  Widget build(BuildContext context) => const MaterialApp(
    home: Scaffold(body: Center(child: Text(DevStrings.configProblem))),
  );
}
