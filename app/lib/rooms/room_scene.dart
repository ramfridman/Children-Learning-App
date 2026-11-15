import 'package:flutter/widgets.dart';

import 'room_spec.dart';

/// What the activity frame needs to draw a lesson in a room (docs/design/m11-rooms.md sections 2 and 3): the room, the host's picture, whether
/// this is a host beat (the host in front with the bubble's tail at its mouth) and whether the stage reacts now. A frame given none draws the
/// default: the cream screen, the meadow, round sockets and the guide alone.
class RoomScene {
  const RoomScene({
    required this.room,
    required this.hostView,
    required this.hostMouth,
    this.hostBeat = false,
    this.companionSpeaks = false,
    this.hostStays = false,
    this.solved = false,
  });

  final RoomSpec room;

  /// The host, drawn in the pose of the moment (a `HostView`).
  final Widget hostView;

  /// The host's mouth in the pose it is drawn in, as a share of its box: the place the bubble's tail points at in a host beat.
  final Offset hostMouth;

  /// The host stands in front and speaks; the companion stands back in `listen`.
  final bool hostBeat;

  /// Inside a host beat the companion has a line of its own (the microphone's "I heard you" on a Meet screen): the bubble's tail moves to the
  /// companion in the back place, and nobody moves (docs/design/m11-rooms.md section 2.1, rule 3).
  final bool companionSpeaks;

  /// The host is already in front when this frame is first drawn (it greeted the child a moment ago): it does not walk in again.
  final bool hostStays;

  /// The item is solved: the landmark reacts (see `StageReaction`).
  final bool solved;
}
