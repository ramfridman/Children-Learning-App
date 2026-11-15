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
    this.solved = false,
  });

  final RoomSpec room;

  /// The host, drawn in the pose of the moment (a `HostView`).
  final Widget hostView;

  /// The host's mouth in the pose it is drawn in, as a share of its box: the place the bubble's tail points at in a host beat.
  final Offset hostMouth;

  /// The host stands in front and speaks; the companion stands back in `listen`.
  final bool hostBeat;

  /// The item is solved: the landmark reacts (see `StageReaction`).
  final bool solved;
}
