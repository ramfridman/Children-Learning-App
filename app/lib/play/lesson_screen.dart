import 'dart:async';
import 'dart:typed_data';

import '../core/log.dart';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../app/companion.dart';
import '../app/providers.dart';
import '../app/state.dart';
import '../app/tutor_providers.dart';
import '../app/voice_input.dart';
import '../characters/character.dart';
import '../child/activity_shell.dart';
import '../child/companion_views.dart';
import '../content/models.dart';
import '../data/app_database.dart';
import '../design/app_text.dart';
import '../design/board.dart';
import '../design/components.dart';
import '../design/layout.dart';
import '../design/tokens.g.dart';
import '../speech/voice_answer.dart';
import '../strings/he.dart';
import '../tutor/tutor.dart';
import '../voice/voice_director.dart';
import 'activity_frame.dart';
import 'count_tap_session.dart';
import 'give_n_session.dart';
import 'lesson_controller.dart';
import 'lesson_voice.dart';
import 'tap_answer_session.dart';
import 'template_session.dart';

/// Plays one lesson of the installed pack, activity after activity, until the celebration.
class LessonScreen extends ConsumerStatefulWidget {
  const LessonScreen({super.key, required this.profileId, this.lessonId = 'butterflies'});

  final String profileId;
  final String lessonId;

  @override
  ConsumerState<LessonScreen> createState() => _LessonScreenState();
}

class _LessonScreenState extends ConsumerState<LessonScreen> with WidgetsBindingObserver {
  LessonController? _controller;
  TemplateSession? _session;
  int _sessionIndex = -1;
  late final SessionRecorder _recorder;
  late final Future<int> _visit;
  late final VoiceDirector _director;
  LessonVoice? _voice;

  /// For each kind of answer, whether voice has been working for this child (the mic is not offered when it has not).
  int? _visitId;
  bool _visitEnded = false;
  int _spokenNonce = 0;
  int _liveSeen = 0;
  TutorSession? _tutor;
  final String _sessionRef = const Uuid().v4();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _director = ref.read(voiceDirectorProvider);
    _recorder = ref.read(sessionRecorderProvider);
    _visit = _recorder.start(widget.profileId, 'lesson:${widget.lessonId}').then((int id) => _visitId = id);
  }

  LessonVoice _makeVoice(LessonController controller) {
    final bool bandA = ref.read(activeProfileProvider)?.ageBand == 0;
    return LessonVoice(
      engine: ref.read(speechEngineProvider),
      lesson: controller,
      session: () => _session,
      silence: bandA ? const Duration(seconds: 2) : const Duration(milliseconds: 1500),
      stopGuide: _director.stop,
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

  void _endVisit(String reason) {
    final int? id = _visitId;
    if (id == null || _visitEnded) return;
    _visitEnded = true;
    _recorder.end(id, reason).catchError((Object _) {});
  }

  /// The app left the screen (home, another app, the notification shade): the microphone closes at once and the guide
  /// stops talking. Nothing keeps listening or speaking behind the child's back.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) return;
    _voice?.hush();
    unawaited(_director.stop());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _endVisit(_controller?.finished ?? false ? 'finished' : 'home');
    // Leaving the lesson silences the guide.
    unawaited(_director.stop());
    _voice?.dispose();
    _session?.dispose();
    _controller?.removeListener(_speak);
    _controller?.dispose();
    super.dispose();
  }

  /// Back to the map. The map hears whether the lesson was finished.
  void _home() => Navigator.of(context).pop(_controller?.finished ?? false);

  LessonController _controllerFor(PackContent content, Guide guide) {
    final LessonController? have = _controller;
    if (have != null) return have;
    final LessonController made = _controller = LessonController(
      content: content,
      lesson: content.lessons[widget.lessonId]!,
      profileId: widget.profileId,
      sessionId: _visitId,
      record: ref.read(attemptSinkProvider),
      clock: ref.read(clockProvider),
      tutor: _tutor,
      tutorContext: _tutor == null ? null : _tutorContext(guide, content),
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
      if (sound != null) unawaited(_director.sayBytes(sound));
      return;
    }
    if (c.voiceNonce == _spokenNonce) return;
    _spokenNonce = c.voiceNonce;
    // The guide never talks over a listening child, and the mic never hears the guide.
    if (_voice?.answer.state == MicState.listening) _voice?.hush();
    unawaited(_director.say(c.voice));
  }

  /// A fresh session whenever the lesson moves to the next activity.
  TemplateSession _sessionFor(LessonController c) {
    if (_session == null || _sessionIndex != c.index) {
      final TemplateSession? old = _session;
      final Activity a = c.current;
      _session = switch (a) {
        CountTapActivity() => CountTapSession(c, a),
        TapAnswerActivity() => TapAnswerSession(c, a),
        GiveNActivity() => GiveNSession(c, a),
      };
      _sessionIndex = c.index;
      // The old stage is still on screen for this frame; let it go afterwards.
      if (old != null) SchedulerBinding.instance.addPostFrameCallback((_) => old.dispose());
      SchedulerBinding.instance.addPostFrameCallback((_) => _voice?.newQuestion());
    }
    return _session!;
  }

  @override
  Widget build(BuildContext context) {
    final AsyncValue<PackContent> content = ref.watch(contentProvider);
    final AsyncValue<Guide> guide = ref.watch(guideProvider);
    final bool voiceOn = ref.watch(voiceAvailableProvider).value ?? false;
    final bool? tutorOn = ref.watch(tutorAvailableProvider).value;
    return content.when(
      loading: () => const ColoredBox(color: TokenColors.cream),
      error: (Object e, StackTrace s) => _Unavailable(onHome: _home),
      data: (PackContent c) => FutureBuilder<int>(
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
          return _lesson(context, c, g, voiceOn);
        },
      ),
    );
  }

  /// The microphone, whenever a parent turned voice on. It is never taken away because listening went badly: a young
  /// child is often misheard, and a missing mic would only teach them that voice does not work.
  Widget? _mic(ActivitySpec spec, TemplateSession session) {
    final LessonVoice? v = _voice;
    if (v == null) return null;
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

  Widget _lesson(BuildContext context, PackContent c, Guide guide, bool voiceOn) {
    final LessonController controller = _controllerFor(c, guide);
    if (voiceOn && _voice == null) _voice = _makeVoice(controller);
    final ActivitySpec spec = ActivitySpec.of(AppLayout.of(context).board);
    return ListenableBuilder(
      listenable: Listenable.merge(<Listenable?>[controller, _voice?.answer]),
      builder: (BuildContext ctx, Widget? _) {
        final TemplateSession session = _sessionFor(controller);
        if (controller.finished) _endVisit('finished');
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
            : controller.finished || controller.feedback == FeedbackKind.correct
            ? CharacterState.celebrate
            : controller.feedback == FeedbackKind.notYet
            ? CharacterState.encourage
            : CharacterState.idle;
        return ActivityFrame(
          guide: SpeakingCharacter(
            character: guide.character,
            director: _director,
            resting: resting,
            voiceOf: guide.character.id,
          ),
          bubbleText: controller.bubble,
          trailTotal: controller.items.length,
          trailDone: controller.finished ? controller.items.length : controller.index,
          onHome: _home,
          onHint: controller.finished ? null : controller.showHint,
          hintGlow: helpOffered,
          onShowMe: controller.finished ? null : () => controller.unsure(),
          onReplay: controller.finished ? null : controller.replayPrompt,
          mic: controller.finished ? null : _mic(spec, session),
          onConfirmYes: heard == MicState.confirming ? _voice?.answer.confirmYes : null,
          onConfirmAgain: heard == MicState.confirming ? _voice?.answer.confirmNo : null,
          stage: (Size room) => session.buildStage(ctx, room, spec),
          tiles: controller.finished ? null : session.buildTiles(ctx, spec),
          overlay: controller.finished
              ? LessonCelebration(
                  text: controller.lesson.celebration.caption,
                  onDone: _home,
                  cameo: SpeakingCharacter(
                    character: guide.character,
                    director: _director,
                    resting: CharacterState.celebrate,
                    voiceOf: guide.character.id,
                  ),
                )
              : null,
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
