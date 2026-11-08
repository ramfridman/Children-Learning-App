// QA-BA-9 (2026-11-07): the arrow that turns a story page is never drawn over the page's picture.
import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nitznutz/play/story_session.dart';

Rect _rect(Size box, ({Size size, Alignment align}) p) => p.align.inscribe(p.size, Offset.zero & box);

Rect _arrow(Size box, double side, {required bool rtl}) {
  const double inset = storyArrowInset - 6;
  return Rect.fromLTWH(rtl ? inset : box.width - inset - side, box.height - inset - side, side, side);
}

void main() {
  // The phone's tall story stage less its padding of 6, and the SE's.
  const Map<String, Size> boxes = <String, Size>{'phone': Size(318, 241), 'phoneSE': Size(250, 233)};
  for (final MapEntry<String, Size> b in boxes.entries) {
    for (final double aspect in <double>[16 / 9, 1, 4 / 3]) {
      for (final bool rtl in <bool>[false, true]) {
        test(
          '${b.key}, a page of $aspect, ${rtl ? 'right to left' : 'left to right'}: the arrow is off the page',
          () {
            final ({Size size, Alignment align}) p = storyPagePlace(b.value, aspect, arrow: 72, rtl: rtl);
            final Rect page = _rect(b.value, p);
            expect(
              page.overlaps(_arrow(b.value, 72, rtl: rtl).inflate(storyArrowGap - 0.01)),
              isFalse,
              reason: 'a gap, not a touch',
            );
            expect(
              p.size.width / p.size.height,
              closeTo(aspect, 0.001),
              reason: 'the page keeps its proportions',
            );
            expect(page.left >= -0.01 && page.right <= b.value.width + 0.01, isTrue);
            expect(page.top >= -0.01 && page.bottom <= b.value.height + 0.01, isTrue);
          },
        );
      }
    }
  }

  test('with no arrow (a question) the page is as large as the box allows, centred', () {
    final ({Size size, Alignment align}) p = storyPagePlace(
      const Size(318, 241),
      16 / 9,
      arrow: 0,
      rtl: false,
    );
    expect(p.size.width, closeTo(318, 0.01));
    expect(p.align, Alignment.center);
  });

  test("the phone's 16:9 page stands above the arrow with a gap, 275 by 155", () {
    final ({Size size, Alignment align}) p = storyPagePlace(
      const Size(318, 241),
      16 / 9,
      arrow: 72,
      rtl: false,
    );
    expect(p.align, Alignment.topCenter);
    expect(p.size.height, closeTo(241 - 72 - 6 - storyArrowGap, 0.01));
  });
}
