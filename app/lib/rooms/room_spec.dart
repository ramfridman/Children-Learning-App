import 'dart:ui' show Color;

import '../content/models.dart' show SkillDoc;
import '../design/tokens.g.dart';
import '../engine/course.dart';
import '../design/trail_shape.dart';

/// The nine rooms of M11 (docs/design/m11-rooms.md section 3): six lands and three language courses. The names are the art's file prefixes.
enum RoomId { numbers, colors, shapes, logic, cs, math, eng, heb, rus }

/// What makes one room look and feel its own: its screen colour, the rim of its stage, the sky of its backdrop, the shape of its trail's
/// sockets and the host who teaches in it. Looked up once for a lesson (see [RoomSpec.of]); the art is `assets/art/rooms/<id>_*.svg` and
/// the hosts' pictures are described by `HostSpec`.
///
/// A room is told apart by shape first (backdrop, landmark, trail); its colour is the third cue and never carries an answer, except in
/// Colour Bay, which is neutral on purpose so that nothing competes with the colours being taught.
class RoomSpec {
  const RoomSpec._({
    required this.id,
    required this.screen,
    required this.rim,
    required this.lip,
    required this.skyTop,
    required this.skyBottom,
    required this.trail,
    required this.hostId,
  });

  final RoomId id;

  /// The colour of the screen behind the frame (the domain tint; Colour Bay keeps the cream).
  final Color screen;

  /// The 4 point rim of the stage, and the lip under the tablet's card.
  final Color rim;
  final Color lip;

  /// The sky or wall gradient of the backdrop, drawn in code (layer 1 of the backdrop).
  final Color skyTop;
  final Color skyBottom;
  final TrailShape trail;

  /// The id of the host (`HostSpec.byId`): the teacher of this room.
  final String hostId;

  /// A language course's room: its landmark is a window on the wall, and the stage's end-bottom corner stays free.
  bool get isCourse => id == RoomId.eng || id == RoomId.heb || id == RoomId.rus;

  /// The prefix of the room's art files: `assets/art/rooms/<name>_far.svg` and the others.
  String get name => id.name;

  String art(String part) => 'assets/art/rooms/${name}_$part.svg';

  static const RoomSpec numbers = RoomSpec._(
    id: RoomId.numbers,
    screen: TokenColors.domainNumbersTint,
    rim: TokenColors.domainNumbersFill,
    lip: TokenColors.domainNumbersDeep,
    skyTop: Color(0xFFCDEFFF),
    skyBottom: Color(0xFFFFF1D6),
    trail: TrailShape.stair,
    hostId: 'nekudi',
  );

  static const RoomSpec colors = RoomSpec._(
    id: RoomId.colors,
    screen: TokenColors.cream,
    rim: TokenColors.sketch,
    lip: TokenColors.cardLip,
    skyTop: Color(0xFFFFFFFF),
    skyBottom: Color(0xFFF5F2F8),
    trail: TrailShape.drop,
    hostId: 'goni',
  );

  static const RoomSpec shapes = RoomSpec._(
    id: RoomId.shapes,
    screen: TokenColors.domainShapesTint,
    rim: TokenColors.domainShapesFill,
    lip: TokenColors.domainShapesDeep,
    skyTop: Color(0xFFCDEFFF),
    skyBottom: Color(0xFFEAF7EE),
    trail: TrailShape.tree,
    hostId: 'kubi',
  );

  static const RoomSpec logic = RoomSpec._(
    id: RoomId.logic,
    screen: TokenColors.domainLogicTint,
    rim: TokenColors.domainLogicFill,
    lip: TokenColors.domainLogicDeep,
    skyTop: Color(0xFFF7F3FF),
    skyBottom: Color(0xFFECE3FE),
    trail: TrailShape.puzzle,
    hostId: 'timi',
  );

  static const RoomSpec cs = RoomSpec._(
    id: RoomId.cs,
    screen: TokenColors.domainCsTint,
    rim: TokenColors.domainCsFill,
    lip: TokenColors.domainCsDeep,
    skyTop: Color(0xFFCDEFFF),
    skyBottom: Color(0xFFEEF6FD),
    trail: TrailShape.nut,
    hostId: 'tzaadon',
  );

  static const RoomSpec math = RoomSpec._(
    id: RoomId.math,
    screen: TokenColors.domainMathTint,
    rim: TokenColors.domainMathFill,
    lip: TokenColors.domainMathDeep,
    skyTop: Color(0xFFFFF8EC),
    skyBottom: Color(0xFFFEEFD6),
    trail: TrailShape.orange,
    hostId: 'pnina',
  );

  static const RoomSpec eng = RoomSpec._(
    id: RoomId.eng,
    screen: TokenColors.courseEngTint,
    rim: TokenColors.courseEngFill,
    lip: TokenColors.courseEngDeep,
    skyTop: Color(0xFFF4F8FD),
    skyBottom: Color(0xFFE1ECF8),
    trail: TrailShape.porthole,
    hostId: 'host_eng',
  );

  static const RoomSpec heb = RoomSpec._(
    id: RoomId.heb,
    screen: TokenColors.courseHebTint,
    rim: TokenColors.courseHebFill,
    lip: TokenColors.courseHebDeep,
    skyTop: Color(0xFFFEF6F3),
    skyBottom: Color(0xFFFBE4DF),
    trail: TrailShape.arch,
    hostId: 'host_heb',
  );

  static const RoomSpec rus = RoomSpec._(
    id: RoomId.rus,
    screen: TokenColors.courseRusTint,
    rim: TokenColors.courseRusFill,
    lip: TokenColors.courseRusDeep,
    skyTop: Color(0xFFF8F4FD),
    skyBottom: Color(0xFFEBE3F7),
    trail: TrailShape.square,
    hostId: 'host_rus',
  );

  static const List<RoomSpec> all = <RoomSpec>[numbers, colors, shapes, logic, cs, math, eng, heb, rus];

  static final Map<RoomId, RoomSpec> _byId = <RoomId, RoomSpec>{for (final RoomSpec r in all) r.id: r};

  static RoomSpec byId(RoomId id) => _byId[id]!;

  /// The room of a lesson whose skill is [skill]: a language course's own room, or the land of the skill's domain. Null where no room
  /// applies (a skill that is not known, a domain with no room): the screen then keeps the default frame, the meadow and the guide alone.
  static RoomSpec? of(SkillDoc? skill) {
    if (skill == null) return null;
    return switch (skill.course) {
      Course.eng => eng,
      Course.heb => heb,
      Course.rus => rus,
      _ => switch (skill.domain) {
        'numbers' => numbers,
        'colors' => colors,
        'shapes' => shapes,
        'logic' => logic,
        'cs' => cs,
        'math' => math,
        _ => null,
      },
    };
  }
}
