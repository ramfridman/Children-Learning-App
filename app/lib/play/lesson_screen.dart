import 'dart:async';
import 'dart:typed_data';

import '../core/log.dart';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../app/companion.dart';
import '../app/language_providers.dart';
import '../app/math_providers.dart';
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
import '../engine/course.dart';
import '../data/app_database.dart';
import '../design/app_text.dart';
import '../design/board.dart';
import '../design/components.dart';
import '../design/layout.dart';
import '../design/token_types.dart' show Band;
import '../design/tokens.g.dart';
import '../parent/alert_scan.dart';
import '../parent/language_settings.dart';
import '../parent/parent_rules.dart';
import '../parent/time_rules.dart';
import '../speech/voice_answer.dart';
import '../speech/word_matcher.dart';
import '../strings/he.dart';
import '../tutor/tutor.dart';
import '../voice/voice_bank.dart';
import '../voice/voice_director.dart';
import 'activity_frame.dart';
import 'block_demo.dart';
import 'block_layout.dart';
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
import 'lesson_controller.dart';
import 'clock_set_session.dart';
import 'lesson_voice.dart';
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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
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
    unawaited(_loadDemoCount());
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
    if (!_sayOn || _quiet.echoOnly) return null;
    final bool bandA = ref.read(activeProfileProvider)?.ageBand == 0;
    final SayStepController step = SayStepController(
      engine: ref.read(languageSpeechEngineProvider(a.course)),
      target: WordTarget(course: a.course, forms: a.forms, foils: a.foils, keyWords: a.keyWords),
      silence: bandA ? const Duration(seconds: 2) : const Duration(milliseconds: 1500),
      beforeListen: _director.stop,
      onOutcome: (String outcome) => unawaited(_recordListen('say', outcome)),
      onResult: (SayResult r) async {
        _quiet.record(r);
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
    _voice?.dispose();
    _session?.dispose();
    _sayStep?.removeListener(_sayChanged);
    _sayStep?.dispose();
    _sayTick.dispose();
    _controller?.removeListener(_speak);
    _controller?.dispose();
    super.dispose();
  }

  /// Back to the map. The map hears whether the lesson was finished.
  void _home() =>
      Navigator.of(context).pop((_controller?.finished ?? false) && !(_controller?.endedForRest ?? false));

  String _endReason() {
    final LessonController? c = _controller;
    if (c == null || !c.finished) return 'home';
    return c.endedForRest ? 'limit' : 'finished';
  }

  LessonController _controllerFor(PackContent content, Guide guide) {
    final LessonController? have = _controller;
    if (have != null) return have;
    final LessonController made = _controller = LessonController(
      content: content,
      lesson: widget.mission ?? content.lessons[widget.lessonId]!,
      profileId: widget.profileId,
      sessionId: _visitId,
      record: ref.read(attemptSinkProvider),
      clock: ref.read(clockProvider),
      tutor: _tutor,
      tutorContext: _tutor == null ? null : _tutorContext(guide, content),
      timeIsUp: _timeIsUp,
      flow: widget.flow,
    );
    made.addListener(_speak);
    // The first question is spoken as soon as the lesson opens.
    SchedulerBinding.instance.addPostFrameCallback((_) => _speak());
    return made;
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
    // A line of a language course is two clips: the Hebrew frame clip, then the target clip.
    unawaited(
      _director.sayClips(
        <String?>[c.voice, c.voiceTarget],
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
  Band _presentationBand(Activity a) {
    final LanguageSwitches s =
        ref.read(languagesProvider).value?.of(widget.profileId, a.course) ?? const LanguageSwitches();
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
        SayItActivity() => SayItSession(c, a, say: _makeSayStep(c, a)),
      };
      _session!.playClips = _playClips;
      _sessionIndex = c.index;
      // The old stage is still on screen for this frame; let it go afterwards.
      if (old != null) SchedulerBinding.instance.addPostFrameCallback((_) => old.dispose());
      SchedulerBinding.instance.addPostFrameCallback((_) => _voice?.newQuestion());
    }
    return _session!;
  }

  @override
  Widget build(BuildContext context) {
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
    if (activity is SayItActivity && session is SayItSession) return _sayMic(spec, session);
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
  Widget? _sayMic(ActivitySpec spec, SayItSession session) {
    final SayStepController? step = session.say;
    if (step == null || !session.hasMic) return null;
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
    final ActivitySpec board = ActivitySpec.of(AppLayout.of(context).board);
    return ListenableBuilder(
      listenable: Listenable.merge(<Listenable?>[controller, _voice?.answer, _sayTick]),
      builder: (BuildContext ctx, Widget? _) {
        final TemplateSession session = _sessionFor(controller);
        session.bubbleScaler = ActivityFrame.bubbleScaler(ctx);
        final ActivitySpec spec = session.layoutFor(board);
        if (controller.finished) _endVisit(_endReason());
        final bool helpOffered =
            !controller.finished &&
            controller.errors >= 1 &&
            controller.hintLevel < controller.current.hints.length;
        final MicState? heard = _voice?.answer.state;
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
            : CharacterState.idle;
        // A touch anywhere on the screen is seen by the session first (it ends a demonstration to watch); it is no answer and goes on to what
        // was touched.
        return Listener(
          behavior: HitTestBehavior.translucent,
          onPointerDown: (_) => session.onScreenTouch(),
          child: ActivityFrame(
            spec: spec,
            guide: SpeakingCharacter(
              character: guide.character,
              director: _director,
              resting: resting,
              voiceOf: guide.character.id,
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
            trailDone: controller.finished ? controller.trailLength : controller.index,
            onHome: _home,
            showHelp: !controller.noHelp,
            // A say-it step has nothing to get wrong and so no hints: its lamp says the word again.
            onHint: controller.finished || controller.noHelp
                ? null
                : (session is SayItSession ? session.onReplay : controller.showHint),
            hintGlow: helpOffered,
            onShowMe: controller.finished || controller.noHelp
                ? null
                : (controller.current is SayItActivity
                      ? controller.replayPrompt
                      : () {
                          session.onShowMe();
                          unawaited(controller.unsure());
                        }),
            onReplay: controller.finished ? null : controller.replayPrompt,
            mic: controller.finished ? null : _mic(spec, session, controller.current),
            onConfirmYes: heard == MicState.confirming ? _voice?.answer.confirmYes : null,
            onConfirmAgain: heard == MicState.confirming ? _voice?.answer.confirmNo : null,
            stage: (Size room) => session.buildStage(ctx, room, spec),
            hands: controller.finished
                ? null
                : (Size room) => session.buildHands(ctx, room, spec) ?? const SizedBox(),
            tiles: controller.finished ? null : session.buildTiles(ctx, spec),
            boardLayer: controller.finished ? null : session.buildBoardLayer(ctx, spec),
            overlay: controller.finished
                ? LessonCelebration(
                    text: controller.endedForRest
                        ? He.restGoodbye.text
                        : controller.lesson.celebration.caption,
                    sticker: controller.endedForRest ? null : _sticker,
                    onDone: _home,
                    cameo: SpeakingCharacter(
                      character: guide.character,
                      director: _director,
                      resting: controller.endedForRest ? CharacterState.idle : CharacterState.celebrate,
                      voiceOf: guide.character.id,
                    ),
                  )
                : null,
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
