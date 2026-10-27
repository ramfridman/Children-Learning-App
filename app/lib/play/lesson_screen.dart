import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app/companion.dart';
import '../app/providers.dart';
import '../app/state.dart';
import '../characters/character.dart';
import '../child/activity_shell.dart';
import '../child/companion_views.dart';
import '../content/models.dart';
import '../design/app_text.dart';
import '../design/board.dart';
import '../design/components.dart';
import '../design/layout.dart';
import '../design/tokens.g.dart';
import '../strings/he.dart';
import '../voice/voice_director.dart';
import 'activity_frame.dart';
import 'count_tap_session.dart';
import 'give_n_session.dart';
import 'lesson_controller.dart';
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

class _LessonScreenState extends ConsumerState<LessonScreen> {
  LessonController? _controller;
  TemplateSession? _session;
  int _sessionIndex = -1;
  late final SessionRecorder _recorder;
  late final Future<int> _visit;
  late final VoiceDirector _director;
  int? _visitId;
  bool _visitEnded = false;
  int _spokenNonce = 0;

  @override
  void initState() {
    super.initState();
    _director = ref.read(voiceDirectorProvider);
    _recorder = ref.read(sessionRecorderProvider);
    _visit = _recorder.start(widget.profileId, 'lesson:${widget.lessonId}').then((int id) => _visitId = id);
  }

  void _endVisit(String reason) {
    final int? id = _visitId;
    if (id == null || _visitEnded) return;
    _visitEnded = true;
    _recorder.end(id, reason).catchError((Object _) {});
  }

  @override
  void dispose() {
    _endVisit(_controller?.finished ?? false ? 'finished' : 'home');
    // Leaving the lesson silences the guide.
    unawaited(_director.stop());
    _session?.dispose();
    _controller?.removeListener(_speak);
    _controller?.dispose();
    super.dispose();
  }

  /// Back to the map. The map hears whether the lesson was finished.
  void _home() => Navigator.of(context).pop(_controller?.finished ?? false);

  LessonController _controllerFor(PackContent content) {
    final LessonController? have = _controller;
    if (have != null) return have;
    final LessonController made = _controller = LessonController(
      content: content,
      lesson: content.lessons[widget.lessonId]!,
      profileId: widget.profileId,
      sessionId: _visitId,
      record: ref.read(attemptSinkProvider),
      clock: ref.read(clockProvider),
    );
    made.addListener(_speak);
    // The first question is spoken as soon as the lesson opens.
    SchedulerBinding.instance.addPostFrameCallback((_) => _speak());
    return made;
  }

  /// Says the guide's newest line in its own voice (the same line asked for again is said again).
  void _speak() {
    final LessonController? c = _controller;
    if (c == null || !mounted || c.voiceNonce == _spokenNonce) return;
    _spokenNonce = c.voiceNonce;
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
    }
    return _session!;
  }

  @override
  Widget build(BuildContext context) {
    final AsyncValue<PackContent> content = ref.watch(contentProvider);
    final AsyncValue<Guide> guide = ref.watch(guideProvider);
    return content.when(
      loading: () => const ColoredBox(color: TokenColors.cream),
      error: (Object e, StackTrace s) => _Unavailable(onHome: _home),
      data: (PackContent c) => FutureBuilder<int>(
        future: _visit,
        builder: (BuildContext context, AsyncSnapshot<int> visit) {
          // The guide and its voice load before the first question, so that the first line is heard too.
          final Guide? g = guide.value;
          if (!visit.hasData || g == null) return const ColoredBox(color: TokenColors.cream);
          return _lesson(context, c, g);
        },
      ),
    );
  }

  Widget _lesson(BuildContext context, PackContent c, Guide guide) {
    final LessonController controller = _controllerFor(c);
    final ActivitySpec spec = ActivitySpec.of(AppLayout.of(context).board);
    return ListenableBuilder(
      listenable: controller,
      builder: (BuildContext ctx, Widget? _) {
        final TemplateSession session = _sessionFor(controller);
        if (controller.finished) _endVisit('finished');
        final bool helpOffered =
            !controller.finished &&
            controller.errors >= 1 &&
            controller.hintLevel < controller.current.hints.length;
        final CharacterState resting = controller.finished || controller.feedback == FeedbackKind.correct
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
