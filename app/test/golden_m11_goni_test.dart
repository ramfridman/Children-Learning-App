// M11 Stage 1, Goni's colours as pictures (docs/design/m11-rooms.md section 5.2): the host beat in his resting mint, the frame after a right
// answer with Goni in the colour the child found, and the lesson's card with him in mint, in a lesson colour, white, black and the rainbow
// ripple (at its hold, and as the still frame of "reduce motion").
//
// Regenerate after a deliberate visual change:  flutter test --update-goldens test/golden_m11_goni_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nitznutz/child/activity_shell.dart';
import 'package:nitznutz/design/board.dart';
import 'package:nitznutz/design/layout.dart';
import 'package:nitznutz/design/token_types.dart' show Band;
import 'package:nitznutz/play/activity_frame.dart';
import 'package:nitznutz/rooms/goni_skin.dart';
import 'package:nitznutz/rooms/host_view.dart';
import 'package:nitznutz/rooms/room_scene.dart';
import 'package:nitznutz/rooms/room_spec.dart';
import 'package:nitznutz/strings/he.dart' show HostHe;

import 'support/golden_comparator.dart';
import 'support/harness.dart';
import 'support/l4_golden.dart' show waitFor;

const Size _phone = Size(852, 393);

Future<void> _shot(WidgetTester tester, String name) =>
    expectLater(find.byType(MaterialApp), matchesGoldenFile('goldens/$name.png'));

/// Colour Bay on the phone: the frame of a host beat or, with [card], the lesson's card on top of the plain frame.
Future<void> _open(
  WidgetTester t, {
  required HostPose pose,
  GoniSkin? skin,
  bool solved = false,
  bool card = false,
  bool reduced = false,
  String bubble = 'כָּל הַכָּבוֹד!',
}) async {
  await t.pumpWidget(const SizedBox.shrink());
  t.view.physicalSize = _phone;
  t.view.devicePixelRatio = 1;
  addTearDown(t.view.reset);
  if (reduced) {
    t.platformDispatcher.accessibilityFeaturesTestValue = const FakeAccessibilityFeatures(
      disableAnimations: true,
    );
  }
  addTearDown(t.platformDispatcher.clearAccessibilityFeaturesTestValue);
  final HostView host = HostView(host: HostSpec.goni, pose: pose, skin: skin);
  const Widget companion = SizedBox.expand(child: _Companion());
  await t.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      locale: const Locale('he'),
      home: Directionality(
        textDirection: TextDirection.rtl,
        child: LayoutScope(
          band: Band.b,
          child: ActivityFrame(
            spec: ActivitySpec.of(BoardClass.phone),
            scene: RoomScene(
              room: RoomSpec.colors,
              hostView: host,
              hostMouth: HostSpec.goni.mouthShare(pose),
              hostBeat: !card,
              solved: solved,
            ),
            bubbleText: bubble,
            guide: companion,
            stage: (Size r) => const SizedBox.shrink(),
            trailTotal: 4,
            trailDone: card ? 4 : 2,
            onHome: () {},
            overlay: card
                ? LessonCelebration(
                    text: 'כָּל הַכָּבוֹד!',
                    onDone: () {},
                    room: RoomSpec.colors,
                    host: host,
                    cheer: HostHe.cheers['goni']!.text,
                    cameo: companion,
                  )
                : null,
          ),
        ),
      ),
    ),
  );
  // The pictures are parsed off the main thread: they are given time to arrive, and the host its moment to take the skin.
  await waitFor(t, 600);
}

/// The companion, as a still picture (the live character breathes for ever, which a golden cannot wait for).
class _Companion extends StatelessWidget {
  const _Companion();

  @override
  Widget build(BuildContext context) => SvgPicture.asset('assets/art/ui/nitzi_sit.svg', fit: BoxFit.contain);
}

void main() {
  setUpAll(() async {
    await loadAppFonts();
    useTolerantGoldens(0.03);
  });

  testWidgets('the host beat: Goni in his resting mint', (WidgetTester t) async {
    await _open(t, pose: HostPose.talk, bubble: HostHe.greetings['goni']!.text);
    await _shot(t, 'm11_goni_beat_mint_phone');
  });

  testWidgets('after a right answer: Goni in the colour the child found, the stage\'s landmark reacted', (
    WidgetTester t,
  ) async {
    await _open(t, pose: HostPose.celebrate, skin: GoniSkin.of('red'), solved: true);
    await _shot(t, 'm11_goni_after_answer_red_phone');
  });

  for (final ({String name, GoniSkin? skin, bool reduced}) c
      in <({String name, GoniSkin? skin, bool reduced})>[
        (name: 'mint', skin: null, reduced: false),
        (name: 'red', skin: GoniSkin.of('red'), reduced: false),
        (name: 'white', skin: GoniSkin.of('white'), reduced: false),
        (name: 'black', skin: GoniSkin.of('black'), reduced: false),
        (name: 'ripple', skin: GoniSkin.ripple, reduced: false),
        (name: 'ripple_reduce_motion', skin: GoniSkin.ripple, reduced: true),
      ]) {
    testWidgets('the lesson\'s card with Goni in ${c.name}', (WidgetTester t) async {
      await _open(t, pose: HostPose.celebrate, skin: c.skin, card: true, reduced: c.reduced);
      // The ripple holds its last step through the praise; the card is taken there.
      if (c.skin != null && c.skin!.isRipple) await waitFor(t, 1600);
      await _shot(t, 'm11_goni_card_${c.name}_phone');
    });
  }
}
