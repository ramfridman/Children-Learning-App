import 'dart:math' as math;
import 'dart:ui';

/// The layer table of the room backdrops (docs/design/m11-rooms.md section 3.2). The numbers are copied from `LAYERS` of
/// `tools/make_room_art.py`, which draws the art (a test compares them); the landmark is not a layer of the backdrop (it stands in its own
/// place on the board, see `LandmarkSlot`). Each layer keeps the aspect of its file and is cropped by the stage's
/// rounded clip, never stretched, so one set of files serves a phone, a tablet and the celebration's window.
abstract final class RoomLayout {
  static const double far = 0.66;
  static const double ground = 0.22;
  static const double top = 0.22;
  static const double corner = 0.52;
  static const double cornerMaxWidth = 0.30;
  static const double roomCorner = 0.64;
  static const double roomCornerMaxWidth = 0.32;

  /// The corner's gap from the stage's edge: from the side and from the bottom, in points.
  static const double insetX = 6;
  static const double insetY = 2;

  /// The sizes of the files, which give each layer its aspect.
  static const Size farFile = Size(1600, 200);
  static const Size groundFile = Size(2400, 100);
  static const Size topFile = Size(2400, 100);
  static const Size cornerFile = Size(240, 200);

  /// The band of far hills (or far wall): 0.66 of the stage's height, on the bottom, centred; wider than the stage on purpose.
  static Rect farBox(Size stage) => _band(stage, far, farFile, atBottom: true);

  static Rect groundBox(Size stage) => _band(stage, ground, groundFile, atBottom: true);

  static Rect topBox(Size stage) => _band(stage, top, topFile, atBottom: false);

  static Rect _band(Size stage, double share, Size file, {required bool atBottom}) {
    final double h = stage.height * share;
    final double w = h * file.width / file.height;
    return Rect.fromLTWH((stage.width - w) / 2, atBottom ? stage.height - h : 0, w, h);
  }

  /// The cluster in the stage's start (right) bottom corner.
  static Rect cornerBox(Size stage, {required bool course}) {
    final double h = math.min(
      stage.height * (course ? roomCorner : corner),
      stage.width * (course ? roomCornerMaxWidth : cornerMaxWidth) * cornerFile.height / cornerFile.width,
    );
    final double w = h * cornerFile.width / cornerFile.height;
    return Rect.fromLTWH(stage.width - w - insetX, stage.height - h - insetY, w, h);
  }
}
