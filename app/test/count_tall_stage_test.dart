// Counts of 5 to 10 on the phones (docs/design/languages-band-a-qa.md section 3): while the objects are counted the stage is the tall one, so
// that each object has a cell of 58 points or more (64 on the phone), and at the question the stage is the usual board again. The real
// Russian pack (RUS-A-11: six to ten objects counted in place) on the phone and the smallest phone.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nitznutz/content/models.dart';
import 'package:nitznutz/content/pack_verify.dart';
import 'package:nitznutz/parent/language_settings.dart';
import 'package:nitznutz/play/hint_widgets.dart' show CountingAid;
import 'package:nitznutz/play/lesson_screen.dart';

import '../tool/pack_builder_lib.dart';
import 'support/app_harness.dart';
import 'support/harness.dart' show loadAppFonts;
import 'support/l4_golden.dart' show boards, waitFor;
import 'support/language_screens.dart' show langKid;
import 'support/pack_fixtures.dart';
import 'support/voice_fixtures.dart';

const String _languages = '../content/languages';

void main() {
  setUpAll(loadAppFonts);

  Future<PackContent> russian() async {
    final PackKey key = await newTestKey();
    return PackContent.fromPack(
      await verifyPack(
        (await buildPack(languageSource('rus', _languages), key)).bytes,
        publicKey: key.publicKey,
      ),
    );
  }

  Future<void> open(WidgetTester t, PackContent content, Size size, String id) async {
    final AppRig rig = AppRig(
      content: content,
      player: FakePlayer()..endsAfter = const Duration(milliseconds: 150),
    )..languagePacks = <String, PackContent>{'rus': content};
    await rig.seedFinishedSetup(name: 'נֹעָה', id: langKid);
    await rig.db.putSetting(
      languagesSettingKey,
      const FamilyLanguages().withSwitches(langKid, 'rus', const LanguageSwitches(on: true))!.encode(),
    );
    await rig.pump(t, size: size);
    await t.tap(find.text('נֹעָה').first);
    await t.pumpAndSettle();
    final Activity a = content.activities[id]!;
    t
        .state<NavigatorState>(find.byType(Navigator).first)
        .push(
          MaterialPageRoute<void>(
            builder: (BuildContext c) => LessonScreen(
              profileId: langKid,
              course: 'rus',
              lessonId: 'shot',
              mission: Lesson.mission(
                id: 'shot',
                itemIds: <String>[a.id],
                skillIds: <String>[a.skillId],
                celebration: const Spoken(vo: 'vo:x.celebrate', caption: 'x'),
              ),
            ),
          ),
        );
    await t.pump(const Duration(milliseconds: 600));
    await waitFor(t, 2500);
  }

  for (final MapEntry<String, Size> b in boards.entries.where(
    (MapEntry<String, Size> e) => e.key == 'phone' || e.key == 'phoneSE',
  )) {
    testWidgets('${b.key}: ten objects are counted in cells of 58 or more, on the tall stage', (
      WidgetTester t,
    ) async {
      final PackContent content = await russian();
      await open(t, content, b.value, 'rus.a11.05');
      final Finder stage = find.byKey(const Key('count-stage'));
      final double tall = t.getSize(stage).height;
      final List<Rect> cells = <Rect>[
        for (int i = 0; i < 10; i++) t.getRect(find.byKey(Key('butterfly-$i'))),
      ];
      final double smallest = cells
          .map((Rect r) => r.shortestSide)
          .reduce((double a, double c) => a < c ? a : c);
      expect(
        smallest,
        greaterThanOrEqualTo(b.key == 'phone' ? 64 : 58),
        reason: 'the touch square of each object',
      );
      for (int i = 0; i < cells.length; i++) {
        for (int j = i + 1; j < cells.length; j++) {
          expect(
            cells[i].overlaps(cells[j].deflate(0.5)),
            isFalse,
            reason: 'objects $i and $j share a touch',
          );
        }
      }
      for (int i = 0; i < 10; i++) {
        await t.tap(find.byKey(Key('butterfly-$i')));
        await waitFor(t, 800);
      }
      await waitFor(t, 800);
      final double usual = t.getSize(stage).height;
      expect(usual, lessThan(tall), reason: 'at the question the stage gives the room back to the answers');
      expect(find.byKey(const Key('tile-o1')), findsOneWidget);
      expect(t.takeException(), isNull);
      await t.pumpWidget(const SizedBox());
    });

    testWidgets('${b.key}: hint 2 opens its card outside the tall stage, in the close-up slot', (
      WidgetTester t,
    ) async {
      final PackContent content = await russian();
      await open(t, content, b.value, 'rus.a11.05');
      final Rect stage = t.getRect(find.byKey(const Key('count-stage')));
      await t.tap(find.byKey(const Key('butterfly-0')));
      await waitFor(t, 400);
      for (int level = 0; level < 2; level++) {
        await t.tap(find.byKey(const Key('lesson-hint')));
        await waitFor(t, 2500);
      }
      expect(t.takeException(), isNull);
      final Finder card = find.byType(CountingAid);
      expect(card, findsOneWidget, reason: 'hint 2 shows the same number counted another way');
      final Rect at = t.getRect(card);
      expect(at.overlaps(stage), isFalse, reason: 'the card is outside the stage: it covers no object');
      expect(at.shortestSide, greaterThanOrEqualTo(90));
      await t.pumpWidget(const SizedBox());
    });
  }
}
