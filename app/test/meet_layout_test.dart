// The places of the Meet screen's card and strip, and of the pictures of a Find on a phone, as docs/design/l7-meet-find.md sections 4.1 and 6.4
// give them, and the rule for the written word (section 3.2). Pure geometry: no widget.
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:nitznutz/design/token_types.dart' show Band;
import 'package:nitznutz/play/find_stage.dart';
import 'package:nitznutz/play/meet_layout.dart';
import 'package:nitznutz/play/meet_rules.dart';

void main() {
  const double square = 1;
  const double wide = 16 / 9;

  MeetLayout layout(
    Size stage, {
    double aspect = square,
    int earlier = 1,
    bool tablet = false,
    bool lookA = true,
  }) => MeetLayout(stage: stage, aspect: aspect, earlier: earlier, tablet: tablet, lookA: lookA);

  group('the picture card', () {
    test('phone: 260 square in the stage of 377 by 260, the strip column at its left', () {
      final MeetLayout l = layout(const Size(377, 260));
      expect(l.card.size, const Size(260, 260));
      expect(
        l.card.center.dx,
        closeTo(76 + (377 - 76) / 2, 0.01),
        reason: 'centred in the picture area, right of the 64 wide column and its gap of 12',
      );
      expect(l.strip.single.size, const Size(64, 64));
    });

    test('phone SE: 192 square for the youngest look, 200 for the others (their strip is narrower)', () {
      expect(layout(const Size(264, 256)).card.size, const Size(192, 192));
      expect(layout(const Size(264, 256), lookA: false).card.size, const Size(200, 200));
      expect(layout(const Size(264, 256), lookA: false).strip.single.size, const Size(56, 56));
    });

    test(
      'tablets: 268 on the landscape card and 388 on the portrait card, each 16 inside the white card',
      () {
        expect(layout(const Size(584 - 32, 300 - 32), tablet: true).card.size, const Size(268, 268));
        expect(layout(const Size(772 - 32, 420 - 32), tablet: true).card.size, const Size(388, 388));
        expect(layout(const Size(772 - 32, 420 - 32), tablet: true).strip.single.width, 88);
      },
    );

    test('a wide picture on a phone has no strip: the card takes the whole stage width', () {
      final MeetLayout l = layout(const Size(377, 260), aspect: wide);
      expect(l.strip, isEmpty);
      expect(l.card.width, closeTo(377, 0.01));
      expect(l.card.height, closeTo(223, 1));
      expect(layout(const Size(264, 256), aspect: wide).card.height, closeTo(160, 1));
    });

    test('a wide picture on a tablet keeps its strip', () {
      expect(layout(const Size(584 - 32, 300 - 32), aspect: wide, tablet: true).strip, hasLength(1));
    });

    test(
      'the strip column is kept when it is empty, so the card does not jump between the screens of a set',
      () {
        final MeetLayout first = layout(const Size(377, 260), earlier: 0);
        final MeetLayout second = layout(const Size(377, 260));
        expect(first.strip, isEmpty);
        expect(first.card, second.card);
      },
    );

    test('two earlier words stand one above the other, centred, 12 apart', () {
      final MeetLayout l = layout(const Size(377, 260), earlier: 2);
      expect(l.strip, hasLength(2));
      expect(l.strip[1].top - l.strip[0].bottom, 12);
      expect((l.strip[0].top + l.strip[1].bottom) / 2, closeTo(130, 0.01));
    });
  });

  group('the pictures of a Find on a phone', () {
    const Size phone = Size(377, 253);
    const Size se = Size(264, 245);

    test('two choices are 166 wide on the phone and 110 on the small phone, 32 apart', () {
      final List<Rect> p = FindStage.cells(stage: phone, n: 2, lookA: true, firstAtRight: false);
      expect(p[0].width, closeTo(166, 0.01));
      expect(p[1].left - p[0].right, closeTo(32, 0.01));
      expect(FindStage.cells(stage: se, n: 2, lookA: true, firstAtRight: false)[0].width, closeTo(110, 0.5));
    });

    test('three choices are about 100 on the phone, 105 for the older looks', () {
      expect(
        FindStage.cells(stage: phone, n: 3, lookA: true, firstAtRight: false)[0].width,
        closeTo(100, 0.01),
      );
      expect(
        FindStage.cells(stage: phone, n: 3, lookA: false, firstAtRight: false)[0].width,
        closeTo(105.3, 0.1),
      );
    });

    test('three choices on the small phone stand in two rows, two then one centred under them', () {
      final List<Rect> c = FindStage.cells(stage: se, n: 3, lookA: true, firstAtRight: false);
      expect(c[0].top, c[1].top);
      expect(c[2].top, greaterThan(c[0].bottom));
      expect(c[2].center.dx, closeTo(se.width / 2, 0.01));
      expect(c[0].width, closeTo(106.5, 0.5));
      expect(c.every((Rect r) => r.bottom <= se.height && r.top >= 0), isTrue);
    });

    test("the row keeps the course's direction: English and Russian first at the left, Hebrew first at the right", () {
      final List<Rect> ltr = FindStage.cells(stage: phone, n: 2, lookA: true, firstAtRight: false);
      final List<Rect> rtl = FindStage.cells(stage: phone, n: 2, lookA: true, firstAtRight: true);
      expect(ltr[0].left, lessThan(ltr[1].left));
      expect(rtl[0].left, greaterThan(rtl[1].left));
    });
  });

  group('the written word on a Meet screen (section 3.2)', () {
    test('look A never shows it, whatever the letters gate says', () {
      expect(meetShowsWord(look: Band.a, lettersOpen: true), isFalse);
      expect(meetShowsWord(look: Band.a, lettersOpen: false), isFalse);
    });

    test('looks B and C show it only once the child\'s letters are open', () {
      for (final Band look in <Band>[Band.b, Band.c]) {
        expect(meetShowsWord(look: look, lettersOpen: true), isTrue);
        expect(meetShowsWord(look: look, lettersOpen: false), isFalse);
      }
    });
  });
}
