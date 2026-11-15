import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'room_layout.dart';
import 'room_spec.dart';

/// The backdrop of a room's stage: a sky or wall gradient and five layers of art (far, ground, top, corner and the landmark), built in the
/// stage's own size, each layer in its own aspect and cropped by the stage's rounded clip. It is static, so it is drawn once behind a
/// repaint boundary. Nothing on it moves, and nothing on it is a row of small repeated things a child could count.
class RoomBackdrop extends StatelessWidget {
  const RoomBackdrop({
    super.key,
    required this.room,
    required this.size,
    this.radius = 24,
    this.landmark = true,
  });

  final RoomSpec room;
  final Size size;

  /// The radius of the stage's clip: the phone's stage 24, a tablet card's inner stage 16, the celebration's window 20.
  final double radius;

  /// The landmark is part of the backdrop (a land's on the phones and the portrait tablet, a course's window everywhere). Off for the
  /// celebration's window, which draws it larger with its new piece, and for a land whose landmark stands outside the card.
  final bool landmark;

  static Widget _layer(String asset, Rect box) => Positioned.fromRect(
    rect: box,
    child: SvgPicture.asset(asset, fit: BoxFit.fill, excludeFromSemantics: true),
  );

  @override
  Widget build(BuildContext context) => RepaintBoundary(
    child: ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: SizedBox(
        key: Key('room-backdrop-${room.name}'),
        width: size.width,
        height: size.height,
        child: Stack(
          clipBehavior: Clip.none,
          children: <Widget>[
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: <Color>[room.skyTop, room.skyBottom],
                  ),
                ),
              ),
            ),
            _layer(room.art('far'), RoomLayout.farBox(size)),
            _layer(room.art('ground'), RoomLayout.groundBox(size)),
            _layer(room.art('top'), RoomLayout.topBox(size)),
            _layer(room.art('corner'), RoomLayout.cornerBox(size, course: room.isCourse)),
            if (landmark) _layer(room.art('landmark'), RoomLayout.landmarkBox(room, size)),
          ],
        ),
      ),
    ),
  );
}
