import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app/providers.dart';
import '../app/state.dart';
import '../child/activity_shell.dart';
import '../content/models.dart';
import '../design/app_text.dart';
import '../design/board.dart';
import '../design/components.dart';
import '../design/layout.dart';
import '../design/tokens.g.dart';
import '../strings/he.dart';
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
  int? _visitId;
  bool _visitEnded = false;

  @override
  void initState() {
    super.initState();
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
    _session?.dispose();
    _controller?.dispose();
    super.dispose();
  }

  void _home() => Navigator.of(context).pop();

  LessonController _controllerFor(PackContent content) => _controller ??= LessonController(
    content: content,
    lesson: content.lessons[widget.lessonId]!,
    profileId: widget.profileId,
    sessionId: _visitId,
    record: ref.read(attemptSinkProvider),
    clock: ref.read(clockProvider),
  );

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
    return content.when(
      loading: () => const ColoredBox(color: TokenColors.cream),
      error: (Object e, StackTrace s) => _Unavailable(onHome: _home),
      data: (PackContent c) => FutureBuilder<int>(
        future: _visit,
        builder: (BuildContext context, AsyncSnapshot<int> visit) {
          if (!visit.hasData) return const ColoredBox(color: TokenColors.cream);
          return _lesson(context, c);
        },
      ),
    );
  }

  Widget _lesson(BuildContext context, PackContent c) {
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
        return ActivityFrame(
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
              ? LessonCelebration(text: controller.lesson.celebration.caption, onDone: _home)
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
