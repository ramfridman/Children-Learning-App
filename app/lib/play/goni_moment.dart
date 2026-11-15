import '../content/models.dart';
import '../rooms/goni_skin.dart';
import '../rooms/room_spec.dart';
import 'lesson_controller.dart';

/// The skin Goni wears now in a lesson (docs/design/m11-rooms.md section 5.2), or null for his resting mint.
///
/// He takes the colour the child just found only after a right answer to a scored item has been accepted, and keeps it for as long as the
/// praise lasts (the controller's `solved`); when the next item begins, `solved` is false again and he is mint before its question is shown.
/// So he is mint before and during every question, on every wrong answer and in every hint, and in every room but Colour Bay.
GoniSkin? goniSkinFor(LessonController c, RoomSpec? room) {
  if (room?.id != RoomId.colors || c.finished || !c.solved || c.feedback != FeedbackKind.correct) return null;
  return answeredByChild(c.current) ? skinForAnswer(c.current) : null;
}

/// The item is one the child answers and that is scored: not a step that is only heard or done, and not a probe of the placement game (whose
/// answer is welcomed the same whatever it was).
bool answeredByChild(Activity a) => !a.unscored && a.purpose != 'probe';

/// The items of a lesson that the child answers, in order.
List<Activity> askedItems(Iterable<Activity> items) => <Activity>[
  for (final Activity a in items)
    if (answeredByChild(a)) a,
];

/// The skin on the lesson's card, where he cheers: the colour every scored item asked for, else the ripple. Mint in any other room, and when
/// the lesson ended for rest (nothing was found).
GoniSkin? goniCardSkin(LessonController c, RoomSpec? room) =>
    room?.id != RoomId.colors || c.endedForRest ? null : skinForLesson(askedItems(c.items));
