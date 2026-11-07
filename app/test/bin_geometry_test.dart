// The speaker of a sort bin (docs/design/languages-band-a-qa.md section 4.2): 64 points in Band A in every bin; in a narrow bin (the phone SE's two
// of 121) it stands in the end corner under the sign, which has the whole row, and the chips keep out of the corner. Bands B and C keep a
// 52 speaker beside the sign there, and a word as a card keeps the old layout (a word is wider than the room a corner speaker leaves).
import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nitznutz/play/ls01_chips.dart';

void main() {
  // The stage of the sort on the phone SE (262 by 136), on the phone (377 by 148) and on a tablet landscape.
  const Size se = Size(262, 136);
  const Size phone = Size(377, 148);

  BinGeometry geo(Size room, {int bins = 2, bool tablet = false, bool big = true}) =>
      BinGeometry(room: room, tablet: tablet, bins: bins, bigSpeakers: big);

  test('Band A: the speaker is 64 in every bin of every board', () {
    expect(geo(se).speakerTouch, 64);
    expect(geo(phone).speakerTouch, 64);
    expect(geo(const Size(900, 500), tablet: true).speakerTouch, 64);
    expect(geo(phone, bins: 3).speakerTouch, 64);
  });

  test('in a bin narrower than 150 the speaker is in the corner, and the sign has the whole row', () {
    final BinGeometry g = geo(se);
    expect(g.binWidth, 121);
    expect(g.cornerSpeaker, isTrue);
    expect(
      g.signLimit(speaker: true),
      g.signLimit(speaker: false),
      reason: 'the speaker takes nothing from the sign',
    );
    expect(g.signLimit(speaker: true), greaterThanOrEqualTo(121 - 24 - 1));
    expect(
      g.chipRoomFor(speaker: true).width,
      g.chipRoom.width - 70,
      reason: 'the chips keep out of the 64 corner and its margin',
    );
    expect(g.chipRoomFor(speaker: false), g.chipRoom, reason: 'a bin with no sound has no corner');
    expect(geo(phone, bins: 3).cornerSpeaker, isTrue, reason: 'three bins are narrow too');
  });

  test('in a bin of 150 or more, and on a tablet, the speaker stays beside the sign', () {
    expect(geo(phone).binWidth, greaterThanOrEqualTo(150));
    expect(geo(phone).cornerSpeaker, isFalse);
    expect(geo(const Size(900, 500), tablet: true).cornerSpeaker, isFalse);
    expect(geo(phone).signLimit(speaker: true), lessThan(geo(phone).signLimit(speaker: false)));
  });

  test(
    'Bands B and C, and a sort whose cards are words, keep the 52 speaker beside the sign in a narrow bin',
    () {
      final BinGeometry g = geo(se, big: false);
      expect(g.speakerTouch, 52);
      expect(g.cornerSpeaker, isFalse);
      expect(g.chipRoomFor(speaker: true), g.chipRoom);
      expect(
        BinGeometry.bigSpeakersFor(bandA: true, cardTexts: <String?>[null, 'ב', 'א']),
        isTrue,
        reason: 'pictures and letters',
      );
      expect(BinGeometry.bigSpeakersFor(bandA: true, cardTexts: <String?>['מַפָּה']), isFalse);
      expect(BinGeometry.bigSpeakersFor(bandA: false, cardTexts: <String?>[null]), isFalse);
    },
  );

  test('the corner is 6 from the inner edges: 70 for the speaker and its margin', () {
    expect(BinGeometry.cornerMargin, 6);
    expect(geo(se).cornerRoom, 70);
  });
}
