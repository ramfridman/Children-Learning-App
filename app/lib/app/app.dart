import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';

import '../child/calm_loading.dart';
import '../child/rest_scene.dart';
import '../child/companion_views.dart';
import '../child/friends_beach.dart';
import '../characters/character.dart';
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

  Future<void> _openFriends() =>
      Navigator.of(context).push(MaterialPageRoute<void>(builder: (BuildContext c) => const FriendsBeach()));

  Future<void> _openLesson() async {
    // Time is up (rest hours, the schedule or the daily limit, with the lock on): a calm scene instead of the lesson.
    final ({String id, int band}) child = (id: widget.profile.id, band: widget.profile.ageBand);
    ref.invalidate(timeVerdictProvider(child));
    final TimeVerdict verdict = await ref.read(timeVerdictProvider(child).future);
    if (!mounted) return;
    if (verdict.locked) {
      await Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (BuildContext c) => RestScene(onBack: () => Navigator.of(c).pop())),
      );
      return;
    }
    final bool? finished = await Navigator.of(
      context,
    ).push(MaterialPageRoute<bool>(builder: (BuildContext c) => LessonScreen(profileId: widget.profile.id)));
    if (!mounted || finished != true) return;
    final AppDatabase db = await ref.read(databaseProvider.future);
    if (await db.setting(_offeredKey) != null) return;
    await db.putSetting(_offeredKey, 'yes');
    if (mounted) await _openFriends();
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

  Widget _map(Character? friend) => HomeScreen(
    childName: widget.profile.name,
    avatarId: widget.profile.avatar,
    onParents: () => openParentArea(context, ref),
    onSwitchChild: () => ref.read(activeProfileProvider.notifier).choose(null),
    onOpenActivity: _openLesson,
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
