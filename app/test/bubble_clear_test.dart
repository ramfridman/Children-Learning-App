// QA-C1d-1: the speech bubble never covers an answer tile, whatever the line, the board and the text size. The frame shrinks the line to
// the room between the progress trail and the tiles; when it is still too tall at the smallest size (14 points as drawn) the bubble
// widens to the left (a phone leaves its stage 150 points), and only a line longer than that goes below 14, to 11 at the least.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nitznutz/child/activity_shell.dart';
import 'package:nitznutz/play/activity_frame.dart';

import 'support/harness.dart';

const String _hint =
    'אַחַת, שְׁתַּיִם, שָׁלוֹשׁ, אַרְבַּע, חָמֵשׁ, שֵׁשׁ, שֶׁבַע, שְׁמוֹנֶה. הִכְנַסְנוּ חָמֵשׁ, אָז נִשְׁאֲרוּ שָׁלוֹשׁ. עַכְשָׁו תּוֹרְכֶם — לִלְחֹץ עַל שָׁלוֹשׁ.';
const String _hintLong =
    'תֵּשַׁע… וּמַמְשִׁיכִים: עֶשֶׂר, אַחַת עֶשְׂרֵה, שְׁתֵּים עֶשְׂרֵה, שְׁלֹשׁ עֶשְׂרֵה, אַרְבַּע עֶשְׂרֵה, חֲמֵשׁ עֶשְׂרֵה. הֵרַמְנוּ שֵׁשׁ אֶצְבָּעוֹת. עַכְשָׁו תּוֹרְכֶם — לִלְחֹץ עַל שֵׁשׁ.';

const List<(String, ActivitySpec, Size)> _boards = <(String, ActivitySpec, Size)>[
  ('phone', ActivitySpec.phone, Size(852, 393)),
  ('phoneSE', ActivitySpec.phoneSE, Size(667, 375)),
  ('tabletL', ActivitySpec.tabletLandscape, Size(1180, 820)),
  ('tabletP', ActivitySpec.tabletPortrait, Size(820, 1180)),
];

void main() {
  setUpAll(loadAppFonts);

  group('fitBubble', () {
    test('a line that fits at the board width keeps the width and its font', () {
      final ({double font, double height, double width}) fit = ActivityFrame.fitBubble(
        'כַּמָּה זֶה?',
        ActivitySpec.phoneSE,
      );
      expect(fit.width, ActivitySpec.phoneSE.bubbleMaxWidth);
      expect(fit.font, ActivitySpec.phoneSE.bubbleFont);
    });

    test(
      'a line too tall at 14 widens to the left, by the least that makes it fit, before the font goes lower',
      () {
        final ActivitySpec s = ActivitySpec.phoneSE;
        const double room = 136;
        expect(
          ActivityFrame.bubbleHeight(_hint, 14, s.bubbleMaxWidth),
          greaterThan(room),
          reason: 'the defect: it did not fit',
        );
        final ({double font, double height, double width}) fit = ActivityFrame.fitBubble(
          _hint,
          s,
          maxHeight: room,
          widest: 310,
        );
        expect(fit.font, 14);
        expect(fit.width, greaterThan(s.bubbleMaxWidth));
        expect(fit.width, lessThanOrEqualTo(310));
        expect(fit.height, lessThanOrEqualTo(room));
        expect(
          ActivityFrame.bubbleHeight(_hint, 14, fit.width - 4),
          greaterThan(room),
          reason: 'a narrower bubble would not have fitted',
        );
      },
    );

    test(
      'without room to widen the width stays; a line that still does not fit goes below 14, never below 11',
      () {
        final ActivitySpec s = ActivitySpec.phoneSE;
        final String huge = List<String>.filled(6, _hint).join(' ');
        final ({double font, double height, double width}) fit = ActivityFrame.fitBubble(
          huge,
          s,
          maxHeight: 136,
          widest: 310,
        );
        expect(fit.width, 310);
        expect(fit.font, lessThan(14));
        expect(fit.font, greaterThanOrEqualTo(ActivityFrame.hardMinFont));
        final ({double font, double height, double width}) none = ActivityFrame.fitBubble(
          _hint,
          s,
          maxHeight: 136,
        );
        expect(none.width, s.bubbleMaxWidth, reason: 'no room to widen was given');
      },
    );
  });

  for (final (String name, ActivitySpec spec, Size size) in _boards) {
    for (final double scale in <double>[1.0, 1.3]) {
      testWidgets(
        'on the $name board at text size $scale a bubble of any line ends ${ActivityFrame.tileClear} above the tiles',
        (WidgetTester t) async {
          t.platformDispatcher.textScaleFactorTestValue = scale;
          addTearDown(t.platformDispatcher.clearAllTestValues);
          final String twice = '$_hint $_hintLong';
          for (final String text in <String>['כַּמָּה זֶה?', _hint, _hintLong, twice]) {
            await pumpScreen(
              t,
              ActivityFrame(
                bubbleText: text,
                stage: (Size room) => const SizedBox(),
                tiles: Container(key: const Key('tiles'), height: 96, color: Colors.white),
                trailTotal: 3,
                trailDone: 0,
                onHome: () {},
              ),
              size: size,
            );
            final Rect bubble = t.getRect(find.byKey(const Key('bubble-body')));
            final String why = '${text.length} letters: $bubble';
            expect(
              bubble.bottom,
              lessThanOrEqualTo(spec.tilesTop - ActivityFrame.tileClear + 0.5),
              reason: why,
            );
            expect(bubble.top, greaterThanOrEqualTo(spec.trailTop + 36), reason: why);
            if (spec.bubbleLeft != null) {
              expect(
                bubble.right,
                lessThanOrEqualTo(spec.bubbleLeft! + spec.bubbleMaxWidth + 0.5),
                reason: why,
              );
              expect(
                bubble.left,
                greaterThanOrEqualTo(spec.stage.left + ActivityFrame.minStageRoom - 0.5),
                reason: why,
              );
            }
            expect(t.takeException(), isNull, reason: why);
          }
        },
      );
    }
  }
}
