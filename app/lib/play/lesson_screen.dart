import 'dart:async';
import 'dart:typed_data';

import '../core/log.dart';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../app/companion.dart';
import '../app/language_providers.dart';
import '../app/look_providers.dart';
import '../app/math_providers.dart';
import '../app/world_providers.dart' show worldProvider, WorldView;
import '../app/providers.dart';
import '../app/reward_providers.dart';
import '../app/state.dart';
import '../app/sync_providers.dart';
import '../app/tutor_providers.dart';
import '../app/voice_input.dart';
import '../characters/character.dart';
import '../child/activity_shell.dart';
import '../child/companion_views.dart';
import '../app/rules_providers.dart';
import '../content/models.dart';
import '../content/served_route.dart';
import '../engine/age.dart' show PresentationStage, SchoolStage;
import '../engine/course.dart';
import '../engine/presentation.dart' show maxChoicesByStage;
import '../data/app_database.dart';
import '../data/behaviour_notes.dart';
import '../design/app_text.dart';
import '../design/board.dart';
import '../design/components.dart';
import '../design/course_text.dart' show DisplayFontScope;
import '../design/layout.dart';
import '../design/stage_spec.dart';
import '../design/token_types.dart' show Band;
import '../design/tokens.g.dart';
import '../parent/alert_scan.dart';
import '../parent/language_settings.dart';
import '../parent/parent_rules.dart';
import '../parent/time_rules.dart';
import '../rooms/goni_skin.dart';
import '../rooms/host_hello.dart';
import '../rooms/host_view.dart';
import '../rooms/moments.dart';
import '../rooms/room_activity.dart';
import '../rooms/room_scene.dart';
import '../rooms/room_spec.dart';
import '../rooms/rooms_provider.dart';
import '../speech/voice_answer.dart';
import '../speech/word_matcher.dart';
import '../strings/he.dart';
import '../tutor/tutor.dart';
import '../voice/voice_bank.dart';
import '../world/adventure_adapter.dart' show LanguageCourse;
import '../voice/voice_director.dart';
import 'activity_frame.dart';
import 'block_demo.dart';
import 'block_layout.dart';
import 'choice_cap.dart';
import 'idle_ladder.dart';
import 'count_tap_session.dart';
import 'flash_session.dart';
import 'build_pattern_session.dart';
import 'give_n_session.dart';
import 'ls01_order_session.dart';
import 'ls01_pairs_session.dart';
import 'ls01_sequence_session.dart';
import 'ls01_sort_session.dart';
import 'ls01_spot_session.dart';
import 'ls01_tap_session.dart';
import 'goni_moment.dart';
import 'lesson_arc.dart';
import 'show_predict.dart';
import 'show_stage.dart';
import 'lesson_controller.dart';
import 'choice_row.dart' show withGrownCard;
import 'name_options.dart';
import 'clock_set_session.dart';
import 'lesson_voice.dart';
import 'meet_rules.dart';
import 'meet_session.dart';
import 'math_signs.dart';
import 'match_pairs_session.dart';
import 'shop_pay_session.dart';
import 'trace_session.dart';
import 'tap_answer_session.dart';
import 'balance_session.dart';
import 'caption_policy.dart';
import 'number_line_session.dart';
import 'robot_path_session.dart';
import 'say_it_session.dart';
import 'say_step.dart';
import 'shape_builder_session.dart';
import 'sort_drag_session.dart';
import 'spot_error_session.dart';
import 'letter_write_session.dart';
import 'listen_do_session.dart';
import 'puppet_talk_session.dart';
import 'read_page_session.dart';
import 'sing_along_session.dart';
import 'sound_boxes_session.dart';
import 'blend_slide_session.dart';
import 'boxes_session.dart';
import 'change_part_session.dart';
import 'story_session.dart';
import 'template_session.dart';

/// Plays one lesson of the installed pack, activity after activity, until the celebration.
class LessonScreen extends ConsumerStatefulWidget {
  const LessonScreen({
    super.key,
    required this.profileId,
    this.lessonId = 'butterflies',
    this.mission,
    this.flow,
    this.course = Course.core,
  });

  final String profileId;
  final String lessonId;

  /// The course the lesson is in: `core` plays the starter pack's lessons, a language course plays that course's own installed pack
  /// (`languagePacksProvider`), so a visit never reads another course's content (docs/milestones/L-course.md, D-9).
  final String course;

  /// An adaptive visit (the placement game of a language course): which activity comes next is the flow's to say.
  final ItemFlow? flow;

  /// A short revisit lesson made for one skill (the bell flag on the map). Null for the pack's own lesson.
  final Lesson? mission;

  @override
  ConsumerState<LessonScreen> createState() => _LessonScreenState();
}

class _LessonScreenState extends ConsumerState<LessonScreen> with WidgetsBindingObserver {
  LessonController? _controller;
  TemplateSession? _session;
  int _sessionIndex = -1;
  late final SessionRecorder _recorder;
  late final SyncRunner _sync;
  late final Future<List<Reward>> Function(String) _evaluate;

  /// The opening demonstration of blocks (see [_openingDemo]): how many lessons this child has opened with one (until it is read, the short
  /// form is shown), and whether this lesson has given its one.
  static const int _fullDemos = 3;
  int _demoLessons = _fullDemos;
  bool _demoGiven = false;

  /// The key of the sticker just earned, shown in the celebration.
  String? _sticker;
  late final Future<int> _visit;
  late final VoiceDirector _director;
  LessonVoice? _voice;

  /// LS09: the quiet fallback of this visit (too many unsure turns switch the rest of the visit's say-it steps to echo, silently),
  /// and whether a say step may use the microphone at all (the parent's switch for this language, and its model on the phone).
  final QuietFallback _quiet = QuietFallback();
  bool _sayOn = false;
  SayStepController? _sayStep;

  /// Changes whenever the say step on screen does, so that the microphone is drawn again (the step is made with its session,
  /// after the screen has built its listener list).
  final ValueNotifier<int> _sayTick = ValueNotifier<int>(0);

  /// For each kind of answer, whether voice has been working for this child (the mic is not offered when it has not).
  int? _visitId;
  bool _visitEnded = false;
  int _spokenNonce = 0;
  int _liveSeen = 0;
  TutorSession? _tutor;
  final String _sessionRef = const Uuid().v4();

  /// The parent's time rules and the minutes already played today before this visit (read once, when it starts).
  ParentRules _rules = const ParentRules();
  int _minutesBefore = 0;
  late final DateTime _startedAt;

  /// How this child's screens look and read in this visit (B-29): read once, when the visit starts, so that nothing changes under the child
  /// mid-activity. A new look (a birthday month, a confirmed stage, a look letter) shows at the next visit.
  LookNow? _look;
  StageSpec? _stageSpec;

  /// This visit introduces the lesson's words: the child has not finished this lesson before (see [LessonController.introVisit]).
  bool _introVisit = true;

  /// Where the child stands in each skill when the visit begins (M11 Stage 2: a Show plays for a skill the child is new to, none for one it has
  /// mastered), read once with the look. Until it is read, or when it cannot be, every skill is new to the child.
  WorldView? _world;

  /// The art of the host's hand in a Show (Kubi's pointer, the ant, the outlines), read with the standing; null where it cannot be read.
  ShowArt? _showArt;
  IdleLadder? _ladder;
  IdleStep? _idleStep;
  bool _ring = false;
  Timer? _ringTimer;
  bool _ladderBusy = false;

  /// The room this lesson is played in and its host (M11), found once when the lesson opens; null for a lesson with no room (the placement
  /// game, a skill that no room claims, rooms switched off).
  RoomSpec? _room;
  HostSpec? _host;
  Timer? _greetTimer;
  Timer? _ceilingTimer;

  /// How long the host's greeting stays at least: long enough to read while it has no voice, and it waits for its voice to end.
  static const Duration _greetingPause = Duration(seconds: 3);

  /// The longest a host's line waits for its voice to end (QA-3: a clip that never reports its end must not hold the screen).
  static const Duration _voiceCeiling = TemplateSession.lineCeilingMax;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    unawaited(_loadLook());
    _director = ref.read(voiceDirectorProvider);
    _recorder = ref.read(sessionRecorderProvider);
    _sync = ref.read(syncRunnerProvider);
    _evaluate = ref.read(rewardEvaluatorProvider);
    _startedAt = DateTime.fromMillisecondsSinceEpoch(ref.read(clockProvider).nowMs());
    final Lesson? mission = widget.mission;
    _visit = _recorder
        .start(
          widget.profileId,
          mission == null ? 'lesson:${widget.lessonId}' : 'mission:${mission.skillIds.first.toLowerCase()}',
        )
        .then((int id) => _visitId = id);
    unawaited(_loadTime());
  }

  Future<void> _loadLook() async {
    // The count of opening demonstrations is read first: the first session is made as soon as the look is known.
    await _loadDemoCount();
    try {
      final (AppDatabase db, FamilyLanguages? languages) = await (
        ref.read(databaseProvider.future),
        widget.course == Course.core ? Future<FamilyLanguages?>.value() : ref.read(languagesProvider.future),
      ).wait;
      final int? courseBand = languages?.of(widget.profileId, widget.course).band;
      // A lesson the child has finished before is a later visit: its Meet screens come again, but nothing is a first meeting any more.
      _introVisit = !(await db.sessionsOf(widget.profileId))
          .any((Session s) => s.plan == 'lesson:${widget.lessonId}' && s.endReason == 'finished');
      final LookNow look = await lookFor(
        db,
        widget.profileId,
        DateTime.fromMillisecondsSinceEpoch(ref.read(clockProvider).nowMs()),
        courseBand: courseBand,
      );
      // The standing in the skills is read with the look: a lesson in parts needs it to choose its screens, and a failure only means that every skill
      // counts as new to the child (the full Show), never that the visit does not open.
      if (widget.mission == null &&
          widget.flow == null &&
          widget.course == Course.core &&
          ref.read(roomsEnabledProvider)) {
        try {
          // Only a lesson in parts needs it, and the reading is not made for any other.
          final PackContent pack = await ref.read(contentProvider.future);
          if (pack.lessons[widget.lessonId]?.parts != null) {
            _world = await ref.read(worldProvider(widget.profileId).future);
            _showArt = await ShowArt.load();
          }
        } on Object {
          _world = null;
        }
      }
      if (!mounted) return;
      setState(() {
        _look = look;
        _stageSpec = StageSpec.of(look.stage);
      });
    } on Object {
      // Without a look the visit plays with the middle one: a failure here must never stop a child.
      if (!mounted) return;
      final LookNow middle = LookNow(
        stage: PresentationStage.p3,
        captionsShown: true,
        schoolStage: SchoolStage.gan5,
      );
      setState(() {
        _look = middle;
        _stageSpec = StageSpec.of(middle.stage);
      });
    }
  }

  Future<void> _loadTime() async {
    try {
      _rules = await ref.read(rulesProvider.future);
      final AppDatabase db = await ref.read(databaseProvider.future);
      final int id = await _visit;
      _minutesBefore = playedMinutesToday(
        (await db.sessionsOf(widget.profileId)).where((Session s) => s.id != id).toList(),
        _startedAt,
      );
    } on Object {
      // Without the rules the lesson simply goes on: a failure here must never stop a child.
    }
  }

  /// Between two activities: has the parent's time run out, with the lock on? Rest hours and the schedule count too.
  bool _timeIsUp() {
    final DateTime now = DateTime.fromMillisecondsSinceEpoch(ref.read(clockProvider).nowMs());
    final int band = ref.read(activeProfileProvider)?.ageBand ?? 1;
    return judgeTime(
      now: now,
      rules: _rules,
      profileId: widget.profileId,
      ageBand: band,
      minutesToday: _minutesBefore + now.difference(_startedAt).inMinutes,
    ).locked;
  }

  /// The words of one spoken answer, looked at once on this phone for the parent's alerts. A failure here never
  /// reaches the child.
  Future<void> _wordAlert(List<String> texts, Set<String> answerWords) async {
    try {
      final DateTime now = DateTime.fromMillisecondsSinceEpoch(ref.read(clockProvider).nowMs());
      final int band = ref.read(activeProfileProvider)?.ageBand ?? 1;
      await recordWordAlert(
        await ref.read(databaseProvider.future),
        now: now,
        profileId: widget.profileId,
        texts: texts,
        ageBand: band,
        answerWords: answerWords,
        offThread: ref.read(alertCheckOffThreadProvider),
      );
    } on Object {
      // Nothing to do: the alert is a note for the parent, and the lesson goes on.
    }
  }

  /// The pause between two beats of a Meet screen, by the look (docs/design/l7-meet-find.md section 4.2): 400 ms for the youngest, 250 for the oldest.
  Duration _breathOf(PresentationStage stage) => Duration(
    milliseconds: switch (stage) {
      PresentationStage.p1 || PresentationStage.p2 => 400,
      PresentationStage.p3 => 300,
      PresentationStage.p4 => 250,
    },
  );

  LessonVoice _makeVoice(LessonController controller) {
    final bool bandA = ref.read(activeProfileProvider)?.ageBand == 0;
    return LessonVoice(
      engine: ref.read(speechEngineProvider),
      lesson: controller,
      session: () => _session,
      silence: bandA ? const Duration(seconds: 2) : const Duration(milliseconds: 1500),
      stopGuide: _director.stop,
      onWords: (List<String> texts, Set<String> answers) => unawaited(_wordAlert(texts, answers)),
      record: (String type, String outcome) {
        unawaited(
          ref
              .read(databaseProvider.future)
              .then(
                (AppDatabase db) => db.recordListen(
                  widget.profileId,
                  DateTime.fromMillisecondsSinceEpoch(ref.read(clockProvider).nowMs(), isUtc: true),
                  type,
                  outcome,
                ),
              ),
        );
      },
      onHome: _home,
    );
  }

  /// The microphone side of a say-it activity, or null when it runs as echo: the parent's voice is off for this language, its model is
  /// not on the phone, or too many turns of this visit came out unsure. The microphone opens only on a tap of the child.
  SayStepController? _makeSayStep(LessonController controller, SayItActivity a) {
    _sayStep?.removeListener(_sayChanged);
    _sayStep?.dispose();
    _sayStep = null;
    // A hearing screen has no microphone; a Meet screen has one (feedback only) when the parent turned voice on for the language.
    if (!_sayOn || (_quiet.echoOnly && !a.teach) || a.hear) return null;
    final bool bandA = ref.read(activeProfileProvider)?.ageBand == 0;
    final SayStepController step = SayStepController(
      engine: ref.read(languageSpeechEngineProvider(a.course)),
      target: WordTarget(course: a.course, forms: a.forms, foils: a.foils, keyWords: a.keyWords),
      silence: bandA ? const Duration(seconds: 2) : const Duration(milliseconds: 1500),
      beforeListen: _director.stop,
      onOutcome: (String outcome) => unawaited(_recordListen('say', outcome)),
      onResult: (SayResult r) async {
        // A Meet screen's microphone is feedback only: it never counts toward the visit's quiet fallback.
        if (!a.teach) {
          _quiet.record(r);
        }
        if (r == SayResult.confident) {
          await controller.sayHeard();
        } else {
          controller.sayTogether();
        }
      },
    );
    step.addListener(_sayChanged);
    return _sayStep = step;
  }

  void _sayChanged() => _sayTick.value++;

  Future<void> _recordListen(String type, String outcome) async {
    try {
      final AppDatabase db = await ref.read(databaseProvider.future);
      await db.recordListen(
        widget.profileId,
        DateTime.fromMillisecondsSinceEpoch(ref.read(clockProvider).nowMs(), isUtc: true),
        type,
        outcome,
      );
    } on Object {
      // Keeping how a listen went is a note for the parent; a failure never reaches the child.
    }
  }

  void _endVisit(String reason) {
    final int? id = _visitId;
    if (id == null || _visitEnded) return;
    _visitEnded = true;
    // The visit is saved first; then the family is told (the runner outlives this screen).
    final SyncRunner sync = _sync;
    _recorder
        .end(id, reason)
        .catchError((Object _) {})
        .then((_) => _giveRewards())
        .whenComplete(() => unawaited(sync.now(force: true)));
  }

  /// What this visit earned: a finished lesson gives a sticker, which is revealed in the celebration. Never throws.
  Future<void> _giveRewards() async {
    try {
      final List<Reward> fresh = await _evaluate(widget.profileId);
      final Reward? sticker = fresh.where((Reward r) => r.kind == 'sticker').firstOrNull;
      if (sticker == null || !mounted) return;
      setState(() => _sticker = sticker.awardKey);
      final AppDatabase db = await ref.read(databaseProvider.future);
      await db.markRewardsSeen(<int>[
        sticker.id,
      ], DateTime.fromMillisecondsSinceEpoch(ref.read(clockProvider).nowMs(), isUtc: true));
    } on Object {
      // The sticker is in the child's collection either way; the reveal is only a nicety.
    }
  }

  /// The app left the screen (home, another app, the notification shade): the microphone closes at once and the guide
  /// stops talking. Nothing keeps listening or speaking behind the child's back.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) return;
    _voice?.hush();
    _sayStep?.stop();
    unawaited(_director.stop());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _endVisit(_endReason());
    // Leaving the lesson silences the guide, but a lesson that was finished lets its last line (the congratulation) end, and
    // never silences a line that the next screen (the ceremony) has already started.
    if (!(_controller?.finished ?? false)) {
      unawaited(_director.stopFor(this));
    }
    _ladder?.stop();
    _ringTimer?.cancel();
    _greetTimer?.cancel();
    _ceilingTimer?.cancel();
    _director.removeListener(_idleHold);
    _voice?.dispose();
    _session?.dispose();
    _sayStep?.removeListener(_sayChanged);
    _sayStep?.dispose();
    _sayTick.dispose();
    _controller?.removeListener(_speak);
    _controller?.dispose();
    super.dispose();
  }

  // ---- the idle ladder (B-29 D5) ----

  /// Starts the ladder of this visit: the look's own stillness. A touch, an answer or a new activity starts it over; a line that plays holds it.
  void _startIdle(LessonController c) {
    final StageSpec? stage = _stageSpec;
    if (stage == null) return;
    _ladder?.stop();
    _ladder = IdleLadder(
      stage: stage,
      onStep: (IdleStep step) => _onIdle(c, step),
      onReset: () => _onIdleReset(c),
    )..start();
    c.addListener(_idleWatch);
    _director.addListener(_idleHold);
  }

  /// The child did something (an answer, a hint, a new activity) that was not the ladder's own doing: the stillness starts over.
  void _idleWatch() {
    if (!_ladderBusy) _ladder?.touch();
  }

  void _idleHold() {
    if (_director.speaking) {
      _ladder?.hold();
    } else {
      _ladder?.release();
    }
  }

  void _onIdle(LessonController c, IdleStep step) {
    final StageSpec? stage = _stageSpec;
    final bool meet = _session is MeetSession;
    // A Meet screen has no help but is still given the ladder's prompts (it has no "not sure", so no offer).
    if (!mounted || stage == null || c.finished || (c.noHelp && !meet)) return;
    _ladderBusy = true;
    try {
      switch (step) {
        case IdleStep.firstPrompt || IdleStep.secondPrompt:
          // Nitzi says the question again (the item's own line, no new voice line), the place it comes from rings once, a hand points. On a
          // Meet screen she says "let's say it together" and the tile breathes, with no hand (docs/design/l7-meet-find.md section 3.6).
          final TemplateSession? now = _session;
          if (now is MeetSession) {
            now.idlePrompt();
            break;
          }
          c.replayPrompt();
          _ringTimer?.cancel();
          if (!MediaQuery.disableAnimationsOf(context)) {
            _ring = true;
            _ringTimer = Timer(const Duration(milliseconds: 1200), () {
              if (mounted) setState(() => _ring = false);
            });
          }
        case IdleStep.offer:
          if (meet) break;
          c.showCaption(He.idleOffer.text);
        case IdleStep.softPause:
          break;
      }
    } finally {
      _ladderBusy = false;
    }
    setState(() => _idleStep = step);
  }

  void _onIdleReset(LessonController c) {
    _ringTimer?.cancel();
    if (_idleStep == IdleStep.offer) c.restoreQuestion(He.idleOffer.text);
    if (mounted) {
      setState(() {
        _idleStep = null;
        _ring = false;
      });
    }
  }

  /// Back to the map. The map hears whether the lesson was finished.
  void _home() =>
      Navigator.of(context).pop((_controller?.finished ?? false) && !(_controller?.endedForRest ?? false));

  String _endReason() {
    final LessonController? c = _controller;
    if (c == null || !c.finished) return 'home';
    return c.endedForRest ? 'limit' : 'finished';
  }

  /// The skill a lesson is played in: that of its first item (every lesson of a language course has one skill). Null for a lesson with no
  /// items.
  String? _lessonSkill(PackContent content, Lesson lesson) =>
      lesson.itemIds.isEmpty ? null : content.activities[lesson.itemIds.first]?.skillId;

  /// How the child is served in a skill of the course (see `servedRoute`): the parent's route, and for a reader the skill's `readerAs` and
  /// what strand 1 of the child's placement found. A land has no routes (null); a skill that is not known is served as the lesson is.
  String? Function(String?) _servedRoutes(PackContent content) {
    if (!Course.isLanguage(content.course)) return (String? _) => null;
    final String? route = ref.read(languagesProvider).value?.of(widget.profileId, content.course).route;
    // Only a reader needs the placement: nothing else is read, so a lesson of a new learner or a heritage speaker starts as before.
    final Set<String> assumed = route != 'reader'
        ? const <String>{}
        : (ref.read(languageCoursesProvider(widget.profileId)).value ?? const <LanguageCourse>[])
              .where((LanguageCourse c) => c.course == content.course)
              .expand((LanguageCourse c) => c.assumed)
              .toSet();
    return (String? skillId) => servedRoute(
      route: route,
      skill: skillId == null ? null : content.skills[skillId],
      assumed: assumed,
      placement: content.placement,
    );
  }

  LessonController _controllerFor(PackContent content, Guide guide) {
    final LessonController? have = _controller;
    if (have != null) return have;
    // How the child is served in a skill of a language course: the parent's route, with a reader resolved by the skill and by what
    // strand 1 of its placement found (a land has no routes). What is not read yet counts as a new learner.
    final String? Function(String?) served = _servedRoutes(content);
    final LookNow look = _look!;
    final int maxChoices = maxChoicesByStage[look.stage.index];
    final OwnName ownName = OwnName(
      childName: ref.read(activeProfileProvider)?.name,
      companionName: guide.character.nameHe,
    );
    final RoomSpec? room = _room = _roomFor(content, widget.mission ?? content.lessons[widget.lessonId]!);
    final HostSpec? host = _host = room == null ? null : HostSpec.byId(room.hostId);
    final ArcPlan? arc = room == null ? null : _planFor(content, content.lessons[widget.lessonId], look);
    final LessonController made = _controller = LessonController(
      content: content,
      captionsShown: look.captionsShown,
      fastHints: look.stage == PresentationStage.p1,
      lesson: widget.mission ?? content.lessons[widget.lessonId]!,
      profileId: widget.profileId,
      sessionId: _visitId,
      record: ref.read(attemptSinkProvider),
      // An answer that is no evidence (a first meeting with a word) is noted on this phone for the parent's alerts, and nowhere else (SEC-L7-1).
      recordNote: (BehaviourNote note) async =>
          (await ref.read(databaseProvider.future)).addBehaviourNote(widget.profileId, note),
      clock: ref.read(clockProvider),
      tutor: _tutor,
      tutorContext: _tutor == null ? null : _tutorContext(guide, content),
      timeIsUp: _timeIsUp,
      flow: widget.flow,
      route: served(_lessonSkill(content, widget.mission ?? content.lessons[widget.lessonId]!)),
      routeOfSkill: served,
      introVisit: _introVisit,
      // The visit's quiet fallback turns a say step that is picture first back into echo, silently.
      echoOnly: () => _quiet.echoOnly,
      // The child's first name goes on the tiles of an own-name item on this phone and nowhere else (decision 25).
      // The look's cap on answer options comes after it (B-29): at most 3, 3, 4 or 5 are shown, the right one always among them.
      personalise: (Activity a) {
        final Activity made = capChoices(ownName.apply(a), maxChoices);
        return room == null ? made : inRoom(made);
      },
      // The host of the room greets before the first item (text with a clip that is still pending, M11 step 1.3).
      arc: arc,
      hostGreeting: host == null || room == null ? null : _greetingOf(host, room),
      hostCheer: host == null
          ? null
          : Spoken(vo: HostHe.clip(host.id, 'cheer'), caption: HostHe.cheers[host.id]!.text),
    );
    made.addListener(_speak);
    // Colour Bay: Goni's colours are parsed now, so that a change of skin never shows an empty frame.
    if (room?.id == RoomId.colors) unawaited(precacheGoni(skinsForLesson(askedItems(made.items))));
    _startIdle(made);
    // The first line is spoken as soon as the lesson opens: the host's greeting, or the first question when the lesson has no host.
    SchedulerBinding.instance.addPostFrameCallback((_) {
      _speak();
      _holdGreeting(made);
    });
    return made;
  }

  /// The screens of this visit of [lesson] when it is in parts (M11 Stage 2) and played in a room: a Show for a skill the child is new to, the host's
  /// lead of a Together item, the Alone items in the order of the fade rule, by the child's level and the look's caps. Null for a lesson that is not in
  /// parts (a mission, a course lesson, a pack made before the arc) and when no plan can be made: it is then played from its flat list of items.
  ArcPlan? _planFor(PackContent content, Lesson? lesson, LookNow look) {
    final LessonParts? parts = lesson?.parts;
    if (lesson == null || parts == null) return null;
    final WorldView? world = _world;
    return ArcPlan.build(
      content: content,
      parts: parts,
      skills: lesson.skillIds,
      caps: ArcCaps.ofStage(look.stage.index),
      standing: (String skill) =>
          world == null ? const SkillStanding() : SkillStanding.of(world.engine, skill, world.now),
      started: (String skill) => world?.engine.state.skills[skill]?.started ?? false,
    );
  }

  /// The host teaches in this moment (a Show, the lead-in of a Together item): its voice is the one that speaks.
  bool _hostTeaches(Moment m) => m == Moment.show || m == Moment.lead;

  /// What [host] says when the lesson opens. The two foreign-language hosts first say their greeting word in the course's own language, then the
  /// Hebrew greeting (`hostHello`): the word's clip goes first in the line and the Hebrew clip follows it, a clip that is not in the pack is
  /// skipped, and the word is written (in its chip) only where a Meet screen may write a word (the letters rule).
  Spoken _greetingOf(HostSpec host, RoomSpec room) {
    final Spoken hebrew = Spoken(
      vo: HostHe.clip(host.id, 'greeting'),
      caption: HostHe.greetings[host.id]!.text,
    );
    final String? hello = hostHello[host.id]?.text;
    if (hello == null) return hebrew;
    final String course = room.name;
    return Spoken(
      vo: HostHe.clip(host.id, 'hello'),
      caption: hebrew.caption,
      target: hebrew.vo,
      show:
          meetShowsWord(
            look: _bandIn(course),
            lettersOpen: ref.read(meetLettersOpenProvider)(widget.profileId, course),
          )
          ? hello
          : null,
    );
  }

  /// The course host's "let's say it together" in a Meet (its text, and its own clip once it is voiced; until then the clip of the companion's
  /// line, which says the same sentence), or null where the lesson has no course host.
  Spoken? _hostTogether(SayItActivity a) {
    final HostSpec? host = _host;
    final Str? line = host == null ? null : HostHe.togethers[host.id];
    if (host == null || line == null) return null;
    final String own = HostHe.clip(host.id, 'together');
    return Spoken(vo: _director.bank?.clip(own) != null ? own : a.together.vo, caption: line.text);
  }

  /// The room of [lesson]: its skill's land, or the language course. None for the placement game (an adaptive visit, not a lesson), for a
  /// skill no room claims, and when rooms are off.
  RoomSpec? _roomFor(PackContent content, Lesson lesson) {
    if (widget.flow != null || !ref.read(roomsEnabledProvider)) return null;
    final String? skill = _lessonSkill(content, lesson);
    return skill == null ? null : RoomSpec.of(content.skills[skill]);
  }

  /// Completes when the voice is quiet, or when [_voiceCeiling] has passed, whichever is first (QA-3). The timer is the screen's own and goes with it.
  Future<void> _quietOrCeiling() {
    final Completer<void> done = Completer<void>();
    _ceilingTimer?.cancel();
    _ceilingTimer = Timer(_voiceCeiling, () {
      if (!done.isCompleted) done.complete();
    });
    unawaited(
      _director.untilQuiet().then((_) {
        _ceilingTimer?.cancel();
        if (!done.isCompleted) done.complete();
      }),
    );
    return done.future;
  }

  /// The template's own tiles, or, while the host of a predict-then-watch Show waits for a guess, the answers of its question in their place.
  Widget? _tilesOf(BuildContext ctx, TemplateSession session, ActivitySpec spec, Activity current) {
    final Widget? own = session.buildTiles(ctx, spec);
    if (!(current.show?.predict?.asksForGuess ?? false)) return own;
    return ValueListenableBuilder<ShowPredict?>(
      valueListenable: session.predicting,
      builder: (BuildContext c, ShowPredict? asked, Widget? _) => asked == null
          ? (own ?? const SizedBox.shrink())
          : GuessTiles(session: session, predict: asked, spec: spec),
    );
  }

  /// A host's line that leads no steps (the lead-in of a tap or a tracing, the hand-over to the companion) ends by itself, once it has been there
  /// for [_greetingPause] and its voice (when it has one) has ended, or at a touch.
  void _holdLead(LessonController c) {
    final int at = c.index;
    _greetTimer?.cancel();
    _greetTimer = Timer(_greetingPause, () {
      unawaited(
        _quietOrCeiling().then((_) {
          if (mounted && c.index == at) c.leadDone();
        }),
      );
    });
  }

  /// The greeting ends by itself, once it has been there for [_greetingPause] and its voice (when it has one) has ended, or at a touch.
  void _holdGreeting(LessonController c) {
    if (c.moment != Moment.greeting) return;
    _greetTimer = Timer(_greetingPause, () {
      unawaited(
        _quietOrCeiling().then((_) {
          if (mounted) c.endGreeting();
        }),
      );
    });
  }

  /// What the tutor may know: ids and enums, from the child's profile (the band and the address form) and the guide.
  TutorContext _tutorContext(Guide guide, PackContent content) {
    final Profile? p = ref.read(activeProfileProvider);
    return TutorContext(
      packId: content.packId,
      packVersion: content.packVersion,
      characterId: guide.character.id,
      band: const <String>['A', 'B', 'C'][(p?.ageBand ?? 1).clamp(0, 2)],
      addressForm: p?.addressForm == 'f' || p?.addressForm == 'm' ? p!.addressForm : 'n',
      childRef: widget.profileId,
      sessionRef: _sessionRef,
    );
  }

  /// Says the guide's newest line in its own voice (the same line asked for again is said again).
  void _speak() {
    final LessonController? c = _controller;
    if (c == null || !mounted) return;
    // A line the tutor made: played in the guide's voice, with the mouth moving.
    if (c.liveNonce != _liveSeen) {
      _liveSeen = c.liveNonce;
      final Uint8List? sound = c.liveLine?.audio;
      if (_voice?.answer.state == MicState.listening) _voice?.hush();
      if (sound != null) {
        final int move = c.actionNonce;
        unawaited(_director.sayBytesNext(sound, owner: this, relevant: () => c.actionNonce == move));
      }
      return;
    }
    if (c.voiceNonce == _spokenNonce) return;
    _spokenNonce = c.voiceNonce;
    // The guide never talks over a listening child, and the mic never hears the guide.
    if (_voice?.answer.state == MicState.listening) _voice?.hush();
    // A line is worth saying only until the child's next move; after that it would be about something already past.
    final int move = c.actionNonce;
    bool relevant() => c.actionNonce == move;
    // A line of a language course is the Hebrew frame clip, then the target clip, and a second target clip when the line has one.
    unawaited(
      _director.sayClips(
        <String?>[c.voice, c.voiceTarget, c.voiceTarget2],
        owner: this,
        relevant: relevant,
        replace: c.voiceReplaces,
      ),
    );
  }

  /// The sound of an answer, from its tile (a speaker, a sound button, a picture): the clips, at once when the child touched
  /// to hear, after the line that is playing otherwise (a hint's own line). When none of the clips has a recording (every clip is
  /// still pending) nothing is played and the result is null, so that a session that waits for the end of a clip takes its own
  /// fixed pause instead (`TemplateSession.sayAndWait`, L5 section 7).
  FutureOr<void> _playClips(List<String> voIds, {bool replace = false}) {
    final LessonController? c = _controller;
    if (c == null || !mounted) return null;
    final VoiceBank? bank = _director.bank;
    if (bank == null || !voIds.any((String id) => bank.clip(id) != null)) return null;
    return _speakClips(c, voIds, replace: replace);
  }

  Future<void> _speakClips(LessonController c, List<String> voIds, {required bool replace}) async {
    if (_voice?.answer.state == MicState.listening) _voice?.hush();
    final int move = c.actionNonce;
    await _director.sayClips(
      voIds,
      owner: this,
      // A hint's sounds are worth hearing only until the child's next move; a touch's own sound is always worth hearing.
      relevant: replace ? null : () => c.actionNonce == move,
      replace: replace,
    );
    // The future of the clips is that of their start: a session that goes on after the end of a line (a chant) waits for the voice.
    await _director.untilQuiet();
  }

  /// Whether the word of the right picture shows after the answer, and whether it carries its stress marks: the child's route and
  /// presentation band in the language, the parent's stress choice (docs/languages/frame.md, LS01 g). Never in a land.
  ({bool captions, bool stress}) _captionsFor(Activity a) {
    if (!a.isLanguage) return (captions: false, stress: true);
    final LanguageSwitches s =
        ref.read(languagesProvider).value?.of(widget.profileId, a.course) ?? const LanguageSwitches();
    final int ageBand = ref.read(activeProfileProvider)?.ageBand ?? 1;
    return (
      captions: captionAfterAnswer(
        course: a.course,
        route: s.route,
        presentationBand: s.presentationBand(ageBand),
      ),
      stress: showsStress(setting: s.stress, route: s.route),
    );
  }

  /// The presentation band of the child in the activity's course (docs/design/languages-l5-ls01.md section 3): the sizes of a tile and of a
  /// text face follow it, not the band letter of the skill.
  Band _presentationBand(Activity a) => _bandIn(a.course);

  Band _bandIn(String course) {
    final LanguageSwitches s =
        ref.read(languagesProvider).value?.of(widget.profileId, course) ?? const LanguageSwitches();
    final int ageBand = ref.read(activeProfileProvider)?.ageBand ?? 1;
    return Band.values[s.presentationBand(ageBand)];
  }

  /// The parent's switch for scripted personal questions in this language (docs/languages/frame.md section 1.4). It fails closed: while
  /// the family's settings are loading, or could not be read, nothing personal is asked (SEC-L4-2); once they are read, a language the
  /// parent never touched keeps the default, on.
  bool _personalAllowed(Activity a) {
    final FamilyLanguages? family = ref.read(languagesProvider).value;
    return family != null && family.of(widget.profileId, a.course).personal;
  }

  /// The demonstration that a rod is ten cubes opens a lesson whose first item with rods this is (docs/design/c1-blocks.md section 6): all
  /// of it for a child's first three such lessons, then its short form. A lesson that says no `demo` (a mission) has none. Once for a lesson.
  BlockDemoKind? _openingDemo(LessonController c, TapAnswerActivity a) {
    if (_demoGiven || c.lesson.demo == null || !BlockLayout.hasRods(a)) return null;
    _demoGiven = true;
    final BlockDemoKind kind = _demoLessons < _fullDemos ? BlockDemoKind.full : BlockDemoKind.short;
    unawaited(_countDemo());
    return kind;
  }

  /// How many lessons with the demonstration this child has opened: read when the lesson starts, one more once this one has (a setting of
  /// this phone, by the child's local id).
  Future<void> _loadDemoCount() async {
    try {
      final AppDatabase db = await ref.read(databaseProvider.future);
      _demoLessons = int.tryParse(await db.setting(_demoKey) ?? '') ?? 0;
    } on Object {
      // Without the count the short form is shown; a failure here never stops a child.
    }
  }

  Future<void> _countDemo() async {
    try {
      final AppDatabase db = await ref.read(databaseProvider.future);
      await db.putSetting(_demoKey, '${_demoLessons + 1}');
    } on Object {
      // The demonstration is only a picture: a count that was not written costs one more full showing.
    }
  }

  String get _demoKey => blockDemoKey(widget.profileId);

  /// A fresh session whenever the lesson moves to the next activity.
  TemplateSession _sessionFor(LessonController c) {
    if (_session == null || _sessionIndex != c.index) {
      final TemplateSession? old = _session;
      final Activity a = c.current;
      final ({bool captions, bool stress}) caption = _captionsFor(a);
      _session = switch (a) {
        CountTapActivity() => CountTapSession(c, a),
        TapAnswerActivity() when a.ls01Mode != null => Ls01TapSession(
          c,
          a,
          band: _presentationBand(a),
          stress: caption.stress,
        ),
        TapAnswerActivity() => TapAnswerSession(
          c,
          a,
          captions: caption.captions,
          stress: caption.stress,
          band: a.isLanguage ? _presentationBand(a) : null,
          demo: _openingDemo(c, a),
          demoLine: c.lesson.demo,
        ),
        StoryActivity() when a.reads => ReadPageSession(c, a, stress: caption.stress),
        StoryActivity() => StorySession(c, a, stress: caption.stress),
        ListenDoActivity() => ListenDoSession(c, a, band: _presentationBand(a), stress: caption.stress),
        SingAlongActivity() => SingAlongSession(c, a, stress: caption.stress),
        SoundBoxesActivity() => SoundBoxesSession(c, a),
        BoxesActivity() => BoxesSession(c, a, band: _presentationBand(a)),
        ChangePartActivity() => ChangePartSession(c, a, band: _presentationBand(a)),
        BlendSlideActivity() => BlendSlideSession(c, a, band: _presentationBand(a), stress: caption.stress),
        PuppetTalkActivity() => PuppetTalkSession(
          c,
          a,
          personalAllowed: _personalAllowed(a),
          stress: caption.stress,
        ),
        FlashActivity() => FlashSession(c, a),
        SortDragActivity() when a.isLanguage => Ls01SortSession(
          c,
          a,
          band: _presentationBand(a),
          stress: caption.stress,
        ),
        SortDragActivity() => SortDragSession(c, a),
        BuildPatternActivity() when a.isLanguage && a.isSequence => Ls01SequenceSession(
          c,
          a,
          band: _presentationBand(a),
          stress: caption.stress,
        ),
        BuildPatternActivity() when a.isLanguage => Ls01OrderSession(
          c,
          a,
          band: _presentationBand(a),
          stress: caption.stress,
        ),
        BuildPatternActivity() => BuildPatternSession(c, a),
        RobotPathActivity() => RobotPathSession(c, a),
        ShapeBuilderActivity() => ShapeBuilderSession(c, a),
        NumberLineActivity() => NumberLineSession(c, a),
        BalanceActivity() => BalanceSession(c, a),
        SpotErrorActivity() when a.isLanguage => Ls01SpotSession(
          c,
          a,
          band: _presentationBand(a),
          stress: caption.stress,
        ),
        SpotErrorActivity() => SpotErrorSession(c, a),
        MatchPairsActivity() when a.isLanguage => Ls01PairsSession(
          c,
          a,
          band: _presentationBand(a),
          stress: caption.stress,
        ),
        MatchPairsActivity() => MatchPairsSession(c, a),
        ShopPayActivity() => ShopPaySession(c, a),
        ClockSetActivity() => ClockSetSession(c, a),
        TraceActivity() => TraceSession(c, a),
        LetterWriteActivity() => LetterWriteSession(c, a),
        GiveNActivity() => GiveNSession(c, a),
        SayItActivity() when a.meetScreen => MeetSession(
          c,
          a,
          say: _makeSayStep(c, a),
          showWord: meetShowsWord(
            look: _presentationBand(a),
            lettersOpen: ref.read(meetLettersOpenProvider)(widget.profileId, a.course),
          ),
          breath: _breathOf(_stageSpec!.stage),
          hostTogether: _hostTogether(a),
        ),
        SayItActivity() => SayItSession(c, a, say: _makeSayStep(c, a)),
      };
      _session!.playClips = _playClips;
      // Kubi has the art for the hand of a Show (his pointer); another host's Show is done by the pointing hand of the hints until it has its own.
      final ShowArt? art = _showArt;
      final RoomSpec? room = _room;
      if (art != null && room != null && _host?.id == 'kubi') {
        _session!.showStyle = ShowStyle(
          art: art,
          deep: room.lip,
          lip: room.lip,
          slow: _look?.stage == PresentationStage.p1 || _look?.stage == PresentationStage.p2,
          still: MediaQuery.disableAnimationsOf(context),
        );
      }
      _session!
        ..untilQuiet = _director.untilQuiet
        ..slowHost = _look?.stage == PresentationStage.p1 || _look?.stage == PresentationStage.p2
        ..stillHost = MediaQuery.disableAnimationsOf(context);
      _sessionIndex = c.index;
      // The old stage is still on screen for this frame; let it go afterwards.
      if (old != null) SchedulerBinding.instance.addPostFrameCallback((_) => old.dispose());
      SchedulerBinding.instance.addPostFrameCallback((_) => _voice?.newQuestion());
      // The host's part of a Show and of a Together item begins once its stage has been drawn; a line that leads no steps ends by itself.
      final TemplateSession made = _session!;
      SchedulerBinding.instance.addPostFrameCallback((_) {
        if (!mounted || _session != made) return;
        made.startHost();
        if (c.leading && (c.step?.lead ?? 0) == 0) _holdLead(c);
      });
    }
    return _session!;
  }

  @override
  Widget build(BuildContext context) {
    // The look is read before anything is drawn, so that the first picture is the look's own and nothing is laid out twice.
    if (_look == null) return const ColoredBox(color: TokenColors.cream);
    final AsyncValue<PackContent> content = _contentOfCourse();
    // A course's voice switch is read before the lesson opens, so that the microphone is decided on what the parent chose for it.
    if (widget.course != Course.core) ref.watch(languagesProvider);
    final AsyncValue<Guide> guide = ref.watch(guideProvider);
    final bool voiceOn = ref.watch(voiceAvailableProvider).value ?? false;
    final bool? tutorOn = ref.watch(tutorAvailableProvider).value;
    final DivisionSign division = ref.watch(divisionSignProvider).value ?? DivisionSign.obelus;
    return content.when(
      loading: () => const ColoredBox(color: TokenColors.cream),
      error: (Object e, StackTrace s) => _Unavailable(onHome: _home),
      data: (PackContent c) {
        // A say-it step needs to know, before its first item, whether the microphone may be offered.
        final bool? sayOn = Course.isLanguage(c.course)
            ? ref.watch(sayItAvailableProvider((childId: widget.profileId, course: c.course))).value
            : false;
        _sayOn = sayOn ?? false;
        if (sayOn == null) return const ColoredBox(color: TokenColors.cream);
        return FutureBuilder<int>(
          future: _visit,
          builder: (BuildContext context, AsyncSnapshot<int> visit) {
            // The guide and its voice load before the first question, so that the first line is heard too.
            final Guide? g = guide.value;
            if (!visit.hasData || g == null || tutorOn == null) {
              return const ColoredBox(color: TokenColors.cream);
            }
            if (tutorOn) _tutor ??= TutorSession(client: ref.read(tutorClientProvider));
            Log.d('helper: lesson opens, tutorOn=$tutorOn');
            final LessonController? open = _controller;
            if (tutorOn && open != null && open.tutor == null) open.attachTutor(_tutor!, _tutorContext(g, c));
            return MathSigns(division: division, child: _lesson(context, c, g, voiceOn));
          },
        );
      },
    );
  }

  /// The pack the lesson plays: the starter pack, or the installed pack of the lesson's language course. A course whose pack is not
  /// installed (or no longer proves itself) is an error, which the screen shows as "the lesson is not ready", never another course's lesson.
  AsyncValue<PackContent> _contentOfCourse() {
    if (widget.course == Course.core) return ref.watch(contentProvider);
    return ref
        .watch(languagePacksProvider)
        .when(
          data: (Map<String, PackContent> packs) {
            final PackContent? pack = packs[widget.course];
            return pack == null
                ? AsyncError<PackContent>(StateError('no pack for ${widget.course}'), StackTrace.current)
                : AsyncData<PackContent>(pack);
          },
          loading: () => const AsyncLoading<PackContent>(),
          error: (Object e, StackTrace s) => AsyncError<PackContent>(e, s),
        );
  }

  /// Whether the microphone may open in a lesson of [pack]: the lands need the parent's one switch; a language course needs that
  /// language's own voice switch too (frame section 1.4: off until a parent turns it on for that language), whatever the global one says.
  bool _voiceAllowedIn(PackContent pack) =>
      pack.course == Course.core ||
      (ref.read(languagesProvider).value?.of(widget.profileId, pack.course).voice ?? false);

  /// The microphone, when a parent turned voice on and saying the answer is the answer (the activity's `voiceAnswer`,
  /// board B-24): where the answer is a tap, a drag or a trace there is no mic at all, not even a faded one. It is never
  /// taken away because listening went badly: a young child is often misheard, and a missing mic would only teach them
  /// that voice does not work.
  Widget? _mic(ActivitySpec spec, TemplateSession session, Activity activity) {
    if (activity is SayItActivity && session is SayItSession) {
      return _sayMic(spec, session.say, session.hasMic);
    }
    if (activity is SayItActivity && session is MeetSession) {
      return session.controlsShown && !session.acted ? _sayMic(spec, session.say, session.hasMic) : null;
    }
    final LessonVoice? v = _voice;
    if (v == null || !activity.voiceAnswer) return null;
    final VoiceAnswerController a = v.answer;
    final bool usable = session.listensNow;
    final MicLook look = switch (a.state) {
      MicState.listening => MicLook.listening,
      MicState.thinking => MicLook.thinking,
      MicState.understood => MicLook.understood,
      MicState.notUnderstood => MicLook.notUnderstood,
      MicState.tapOnly => MicLook.faded,
      MicState.confirming => MicLook.ready,
      MicState.ready => usable ? MicLook.ready : MicLook.faded,
    };
    final Str label = switch (look) {
      MicLook.listening => He.micListeningSemantics,
      MicLook.thinking => He.micThinkingSemantics,
      MicLook.understood => He.micUnderstoodSemantics,
      MicLook.notUnderstood => He.micNotUnderstoodSemantics,
      MicLook.faded => He.micFadedSemantics,
      MicLook.ready => He.micSemantics,
    };
    return MicButton(
      key: const Key('lesson-mic'),
      size: spec.micSize,
      semanticLabel: label.text,
      look: look,
      level: a.level,
      onPressed: (usable || a.state == MicState.confirming) ? a.tap : null,
    );
  }

  /// The microphone of a say-it step: there only when the step has one (a parent's switch for this language is on and its model is on
  /// the phone), and then it opens on a tap of the child, never by itself. It fades after the one more try, and is never taken away
  /// otherwise.
  Widget? _sayMic(ActivitySpec spec, SayStepController? step, bool hasMic) {
    if (step == null || !hasMic) return null;
    final MicLook look = switch (step.state) {
      SayState.listening => MicLook.listening,
      SayState.thinking => MicLook.thinking,
      SayState.heard => MicLook.understood,
      SayState.together => step.canListen ? MicLook.ready : MicLook.faded,
      SayState.ready => MicLook.ready,
      SayState.unavailable => MicLook.faded,
    };
    return MicButton(
      key: const Key('lesson-mic'),
      size: spec.micSize,
      semanticLabel: (look == MicLook.listening ? He.micListeningSemantics : He.micSemantics).text,
      look: look,
      level: step.level,
      onPressed: step.canListen ? step.tap : null,
    );
  }

  Widget _lesson(BuildContext context, PackContent c, Guide guide, bool voiceOn) {
    final LessonController controller = _controllerFor(c, guide);
    if (voiceOn && _voice == null && _voiceAllowedIn(c)) _voice = _makeVoice(controller);
    final StageSpec stageSpec = _stageSpec!;
    final SizeClass sizeClass = AppLayout.of(context).sizeClass;
    final ActivitySpec board = withGrownCard(
      stageSpec.applyTo(ActivitySpec.of(AppLayout.of(context).board), sizeClass),
    );
    return StageScope(
      stage: stageSpec,
      captionsShown: _look!.captionsShown,
      child: _lessonBody(c, guide, controller, board, stageSpec),
    );
  }

  /// What the frame draws of the room: its look, the host (in front in a host beat: the greeting and a Meet screen), and the landmark that
  /// reacts once the item is solved. Null where the lesson has no room.
  RoomScene? _scene(LessonController c, {bool greeting = false, MeetSession? meet}) {
    final RoomSpec? room = _room;
    final HostSpec? host = _host;
    if (room == null || host == null) return null;
    // The host teaches in a Show and in the lead of a Together item: its hand is out on the stage, and the companion listens behind it.
    final bool teaching = !greeting && meet == null && (c.moment == Moment.show || c.moment == Moment.lead);
    final HostPose pose = greeting
        ? HostPose.talk
        : teaching
        ? HostPose.show
        : meet?.hostPose ?? HostPose.idle;
    return RoomScene(
      room: room,
      hostView: HostView(
        host: host,
        pose: pose,
        // The host is announced once, at the greeting.
        semanticLabel: greeting ? HostHe.names[host.id]!.text : null,
        // Goni takes the colour the child just found after a right answer, and only then (a host on screen in a turn: the Show's last step).
        skin: goniSkinFor(c, room),
      ),
      hostMouth: host.mouthShare(pose),
      hostBeat: greeting || meet != null || teaching,
      companionSpeaks: meet?.companionSpeaks ?? false,
      // A Meet screen right after the greeting finds the host in front already: it does not walk in again.
      hostStays: !greeting && c.index == 0,
      solved: c.solved && !c.finished,
    );
  }

  /// The greeting: the host in front with its line in the bubble, the companion behind it listening, the room's stage empty. A touch anywhere
  /// goes on to the first item.
  Widget _greeting(LessonController controller, Guide guide, ActivitySpec board) => Listener(
    behavior: HitTestBehavior.translucent,
    onPointerDown: (_) => controller.endGreeting(),
    child: ActivityFrame(
      spec: board,
      scene: _scene(controller, greeting: true),
      guide: SpeakingCharacter(
        character: guide.character,
        director: _director,
        resting: CharacterState.listen,
        // The host's voice is not the companion's: the companion's mouth stays still while the host speaks.
        voiceOf: 'host',
      ),
      bubbleText: controller.bubble,
      bubbleTarget: controller.bubbleShow == null
          ? null
          : (text: controller.bubbleShow!, course: _room!.name),
      trailTotal: controller.trailLength,
      trailDone: 0,
      onHome: _home,
      showHelp: false,
      stage: (Size room) => const SizedBox.shrink(),
    ),
  );

  Widget _lessonBody(
    PackContent c,
    Guide guide,
    LessonController controller,
    ActivitySpec board,
    StageSpec stageSpec,
  ) {
    return ListenableBuilder(
      listenable: Listenable.merge(<Listenable?>[controller, _voice?.answer, _sayTick]),
      builder: (BuildContext ctx, Widget? _) {
        // The host's greeting is a screen of its own before the first item: no item, no session, no help.
        if (controller.moment == Moment.greeting) return _greeting(controller, guide, board);
        final TemplateSession session = _sessionFor(controller);
        session.bubbleScaler = ActivityFrame.bubbleScaler(ctx);
        session.praise = stageSpec.praise;
        // An item of blocks has its own two layouts (docs/design/c1-blocks.md section 5): they keep the board's own sizes, as every template with
        // its own rows does for now (B-29 D3).
        final Activity now = controller.current;
        final bool blocks = now is TapAnswerActivity && BlockLayout.hasBlocks(now);
        ActivitySpec spec = session.layoutFor(blocks ? ActivitySpec.of(AppLayout.of(ctx).board) : board);
        // A layout whose bubble tail must meet the guide's mouth wherever it stands (the blocks') keeps the board's own caption size: the tail
        // reaches the mouth only through the bubble's height at that size.
        if (spec.tailAtMouth) {
          spec = spec.withLook(
            captionFont: ActivitySpec.of(AppLayout.of(ctx).board).bubbleFont,
            numeralFont: spec.tileFont,
            tile: spec.tileSize,
            slop: spec.tileSlop,
          );
        }
        if (controller.finished) _endVisit(_endReason());
        final bool helpOffered =
            !controller.finished &&
            controller.errors >= 1 &&
            controller.hintLevel < controller.current.hints.length;
        final MicState? heard = _voice?.answer.state;
        // A Meet screen in a course's room: the course host teaches in front, and the companion listens behind it.
        final MeetSession? meet = controller.moment == Moment.meet && session is MeetSession ? session : null;
        final CharacterState resting = controller.tutorThinking
            ? CharacterState.think
            : heard == MicState.listening
            ? CharacterState.listen
            : heard == MicState.thinking
            ? CharacterState.think
            : heard == MicState.notUnderstood
            ? CharacterState.surprised
            : (controller.finished && !controller.endedForRest) || controller.feedback == FeedbackKind.correct
            ? CharacterState.celebrate
            : controller.feedback == FeedbackKind.notYet
            ? CharacterState.encourage
            : _idleStep == IdleStep.softPause
            ? CharacterState.sleepy
            : _idleStep == IdleStep.secondPrompt
            ? CharacterState.talk
            : meet != null
            ? meet.companionPose
            : session is MeetSession
            ? session.pose
            : CharacterState.idle;
        // The font of the item's text (Secular One for a transfer check of letters in another face). Over it, a touch anywhere on the
        // screen is seen by the session first (it ends a demonstration to watch); it is no answer and goes on to what was touched.
        return DisplayFontScope(
          display: controller.current.displayFont,
          child: Listener(
            behavior: HitTestBehavior.translucent,
            onPointerDown: (_) {
              session.onScreenTouch();
              _ladder?.touch();
              // A touch ends the host's line where the host does nothing but say it (a Together lead with no steps to lead, the hand-over).
              if (controller.leading && (controller.step?.lead ?? 0) == 0) controller.leadDone();
            },
            child: ActivityFrame(
              spec: spec,
              scene: _scene(controller, meet: meet),
              guide: SpeakingCharacter(
                character: guide.character,
                director: _director,
                resting: resting,
                // The host's voice is not the companion's: the companion's mouth stays still while the host speaks.
                voiceOf: (meet != null ? !meet.companionSpeaks : _hostTeaches(controller.moment))
                    ? 'host'
                    : guide.character.id,
              ),
              bubbleText: controller.bubble,
              bubbleMath: controller.bubbleMath,
              bubbleAboveTiles: controller.current.isLanguage,
              bubbleTarget: controller.bubbleShow == null
                  ? null
                  : (
                      text: withStress(controller.bubbleShow!, show: _captionsFor(controller.current).stress),
                      course: controller.current.course,
                    ),
              trailTotal: controller.trailLength,
              trailDone: controller.trailDone,
              onHome: _home,
              showHelp: !controller.noHelp,
              // A say-it step has nothing to get wrong and so no hints: its lamp says the word again.
              onHint: controller.finished || controller.noHelp
                  ? null
                  : (session is SayItSession ? session.onReplay : controller.showHint),
              hintGlow: helpOffered || _idleStep == IdleStep.offer,
              promptRing: _ring,
              idleHand: _idleStep != null && idleHandShows(stageSpec, _idleStep!) && session is! MeetSession
                  ? idleHand
                  : null,
              onShowMe: controller.finished || controller.noHelp
                  ? null
                  : (controller.current is SayItActivity
                        ? controller.replayPrompt
                        : () {
                            session.onShowMe();
                            unawaited(controller.unsure());
                          }),
              moveOn: controller.finished || !controller.current.isShow ? null : session.canMoveOn,
              onMoveOn: controller.skipShow,
              tilesRise: session.tilesRise(spec),
              onReplay: controller.finished ? null : controller.replayPrompt,
              mic: controller.finished ? null : _mic(spec, session, controller.current),
              onConfirmYes: heard == MicState.confirming ? _voice?.answer.confirmYes : null,
              onConfirmAgain: heard == MicState.confirming ? _voice?.answer.confirmNo : null,
              stage: (Size room) => session.buildStage(ctx, room, spec),
              hands: controller.finished
                  ? null
                  : (Size room) => session.buildHands(ctx, room, spec) ?? const SizedBox(),
              tiles: controller.finished ? null : _tilesOf(ctx, session, spec, controller.current),
              boardLayer: controller.finished ? null : session.buildBoardLayer(ctx, spec),
              overlay: controller.finished
                  ? LessonCelebration(
                      text: controller.endedForRest
                          ? He.restGoodbye.text
                          : controller.lesson.celebration.caption,
                      sticker: controller.endedForRest ? null : _sticker,
                      onDone: _home,
                      room: _room,
                      host: _host == null
                          ? null
                          : HostView(
                              host: _host!,
                              pose: controller.endedForRest ? HostPose.idle : HostPose.celebrate,
                              // In Colour Bay Goni takes the lesson's colour, or the rainbow when it had no one colour.
                              skin: goniCardSkin(controller, _room),
                            ),
                      cheer: _host == null ? null : HostHe.cheers[_host!.id]?.text,
                      finished: !controller.endedForRest,
                      cameo: SpeakingCharacter(
                        character: guide.character,
                        director: _director,
                        resting: controller.endedForRest ? CharacterState.idle : CharacterState.celebrate,
                        voiceOf: guide.character.id,
                      ),
                    )
                  : null,
            ),
          ),
        );
      },
    );
  }
}

/// Shown when the lesson cannot be loaded: no error text for a child, one calm line and the way home.
class _Unavailable extends StatelessWidget {
  const _Unavailable({required this.onHome});

  final VoidCallback onHome;

  @override
  Widget build(BuildContext context) {
    final BoardClass board = AppLayout.of(context).board;
    return Scaffold(
      body: BoardCanvas(
        background: TokenColors.cream,
        board: board,
        children: <Widget>[
          Positioned.fill(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  const BoardSvg('assets/art/ui/nitzi_sit.svg', width: 160, height: 160),
                  Text(
                    He.lessonUnavailable.text,
                    key: const Key('lesson-unavailable'),
                    style: AppText.fixed(size: 26, weight: 600),
                  ),
                  const SizedBox(height: 12),
                  PebbleButton(
                    key: const Key('activity-home'),
                    semanticLabel: He.homeSemantics.text,
                    onPressed: onHome,
                    child: const BoardSvg('assets/art/ui/home_palm.svg', width: 32, height: 32),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
