import 'dart:async';

import 'package:flutter/material.dart';

import '../child/activity_shell.dart';
import '../content/hint_ladder.dart';
import '../content/models.dart';
import '../design/components.dart';
import 'choice_row.dart';
import 'lesson_controller.dart';
import 'template_session.dart';

/// What the language templates of L4 whose answer is a choice share (a story's pause, a command, a rhyme's gap, a puppet's bubble):
/// the child's choice goes to the controller by option id (so the tag, the hint ladder, the one retry of a two-choice item and a probe's
/// single answer are all the controller's), a right answer waits out the praise and goes on, a "not yet" shows for a moment and lets
/// the child try again, and the tiles pulse to invite a touch. A template adds its own stage and what its hints draw.
abstract class ChoiceSession extends TemplateSession {
  ChoiceSession(super.controller, this.activity, this.choice, {this.stress = true});

  final Activity activity;
  final ChoiceActivity choice;
  final bool stress;

  List<ChoiceOption> get options => choice.options;
  String get correctId => choice.correctId;

  String? chosenId;
  AnswerState chosenState = AnswerState.idle;
  bool busy = false;

  /// The tile a hint lights now.
  int? litTile;

  TextDirection get rowDirection => rowDirectionOf(activity.course, TextDirection.rtl);

  /// Some option has a clip that a speaker can play (the tiles then keep the room under them).
  bool get hasSpeakers => options.any((ChoiceOption o) => o.clip != null);

  /// The tiles stand higher when they have speakers under them; a template with another stage overrides this.
  @override
  ActivitySpec layoutFor(ActivitySpec base) => hasSpeakers ? withSpeakerRoom(base) : base;

  /// The child chose [id]: the controller scores it. A picture with a clip says its word as it is chosen.
  Future<void> choose(String id) async {
    if (busy || chosenState == AnswerState.correct) return;
    if (controller.guided && id != correctId) return;
    final ChoiceOption o = options.firstWhere((ChoiceOption o) => o.id == id);
    busy = true;
    chosenId = id;
    if (o.clip != null && o.text == null) playClips?.call(<String>[o.clip!], replace: true);
    onChosen(o);
    final Outcome out = await controller.chooseOption(id);
    if (disposed) return;
    if (out.correct) {
      chosenState = AnswerState.correct;
      notify();
      onRight();
    } else if (out.settled) {
      // A probe's one answer: nothing "not yet" is shown, and the lesson goes on after the pause.
      chosenState = AnswerState.selected;
      notify();
      later(TemplateSession.praisePause, controller.next);
    } else {
      chosenState = AnswerState.notYet;
      notify();
      onWrong();
      later(TemplateSession.notYetPause, () {
        chosenId = null;
        chosenState = AnswerState.idle;
        busy = false;
        notify();
      });
    }
  }

  /// A touch on the option, before the controller has scored it (a template may move something).
  void onChosen(ChoiceOption o) {}

  /// The right answer was accepted: the lesson goes on after the praise. A story goes on to its last page first.
  void onRight() => later(TemplateSession.praisePause, controller.next);

  /// A "not yet" is showing.
  void onWrong() {}

  void sayOption(ChoiceOption o) {
    if (o.clip != null) playClips?.call(<String>[o.clip!], replace: true);
  }

  // ---- waiting ----

  /// Waits [d], and never fires after the session has gone (the timer is the session's own).
  Future<void> pause(Duration d) {
    final Completer<void> c = Completer<void>();
    later(d, c.complete);
    return c.future;
  }

  /// Plays [ids] and waits until they have been played (at most [atMost]); with no player (a test) it waits [without] instead.
  Future<void> sayAndWait(
    List<String> ids, {
    bool replace = false,
    Duration without = const Duration(milliseconds: 700),
    Duration atMost = const Duration(seconds: 8),
  }) async {
    final FutureOr<void> played = playClips?.call(ids, replace: replace);
    if (played is Future<void>) {
      await Future.any(<Future<void>>[played, pause(atMost)]);
    } else {
      await pause(without);
    }
  }

  // ---- hints and replay ----

  @override
  void onReset() {
    chosenId = null;
    chosenState = AnswerState.idle;
    busy = false;
    litTile = null;
    notify();
  }

  @override
  void onReplay() => pulseTiles();

  /// Level 3, the demonstration, ends at once for a template that has nothing to show beyond the lit answer.
  void endDemoIfShown() {
    if (hintPictureOf(activity) == HintPicture.demonstration) controller.demoDone();
  }

  @override
  void onHint() {
    pulseTiles();
    endDemoIfShown();
  }

  /// The tiles light one after the other, the same for all: nothing is marked.
  void pulseTiles({int step = 450}) {
    for (int i = 0; i < options.length; i++) {
      later(Duration(milliseconds: step * i), () {
        litTile = i;
        notify();
      });
    }
    later(Duration(milliseconds: step * options.length), () {
      litTile = null;
      notify();
    });
  }

  /// The row of tiles of the choice, in the course's direction, with a speaker under each that has a clip when [speakers] is true.
  Widget choiceTiles(BuildContext context, ActivitySpec spec, {bool speakers = true}) => ListenableBuilder(
    listenable: this,
    builder: (BuildContext c, Widget? _) => ChoiceRow(
      options: options,
      assets: activity.assets,
      course: activity.course,
      tileFont: spec.tileFont,
      direction: rowDirection,
      chosenId: chosenId,
      chosenState: chosenState,
      correctId: correctId,
      answerShown: controller.answerShown,
      litIndex: litTile,
      onChoose: choose,
      onSpeak: speakers ? sayOption : null,
      stress: stress,
    ),
  );
}
