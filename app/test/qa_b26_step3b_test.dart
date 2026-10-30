// QA, B-26 step 3b: the name in the map bubble sits in an isolate, so a shortened Latin name keeps its "…" on its right;
// the nameless bubble says He.homeBubbleNoName (docs/qa/b26-step3b-verification.md). The real app on four boards at text
// scale 1.0 and 1.3, Latin, Hebrew and mixed names; what the screen reader gets from the sign and the bubble.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nitznutz/app/state.dart';
import 'package:nitznutz/child/home_island_name.dart';
import 'package:nitznutz/child/home_screen.dart';
import 'package:nitznutz/child/profile_picker.dart';
import 'package:nitznutz/strings/he.dart';

import 'support/app_harness.dart';
import 'support/harness.dart';

const Map<String, Size> boards = <String, Size>{
  'phone': Size(852, 393),
  'phoneSE': Size(667, 375),
  'tabletLandscape': Size(1180, 820),
  'tabletPortrait': Size(820, 1180),
};

/// Latin (short, long, very long), Hebrew, mixed in both orders, and no usable name.
const Map<String, String> names = <String, String>{
  'massimiliano': 'Massimiliano',
  'massimiliano_2': 'Massimiliano Bartholomew',
  'latin_40': 'Massimiliano Bartholomew Alessandro Wolf',
  'hebrew': 'אלכסנדרה',
  'mixed_he_first': 'נועה Noa',
  'mixed_latin_first': 'Noa נועה',
  'none': '   ',
};

/// Format and control characters a screen reader might speak or stumble on.
final RegExp invisible = RegExp(r'[\p{Cf}\p{Cc}]', unicode: true);

Future<void> openMap(WidgetTester tester, Size size, String name) async {
  final AppRig rig = AppRig();
  await rig.seedFinishedSetup(name: name);
  await rig.pump(tester, size: size);
  tester.takeException(); // QA-19: the picker's cards at 1.3 (open, older)
  final ProviderContainer c = ProviderScope.containerOf(tester.element(find.byType(ProfilePicker)));
  c.read(activeProfileProvider.notifier).choose((await c.read(appStateProvider.future)).profiles.single);
  await tester.pumpAndSettle();
  expect(find.byType(HomeScreen), findsOneWidget);
}

void main() {
  setUpAll(loadAppFonts);

  for (final MapEntry<String, Size> b in boards.entries) {
    for (final double scale in <double>[1.0, 1.3]) {
      for (final MapEntry<String, String> n in names.entries) {
        testWidgets('${b.key} x$scale ${n.key}', (WidgetTester tester) async {
          tester.platformDispatcher.textScaleFactorTestValue = scale;
          addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
          final SemanticsHandle sem = tester.ensureSemantics();
          await openMap(tester, b.value, n.value);
          final Object? late = tester.takeException();
          if (late != null) expect('$late', contains('RenderFlex overflowed'), reason: 'QA-19 only');

          final HomeIslandName island = homeIslandName(n.value);
          final Finder body = find.byKey(const Key('bubble-body'));
          final String text = tester
              .widget<Text>(find.descendant(of: body, matching: find.byType(Text)))
              .data!;
          final RenderParagraph para = tester.renderObject<RenderParagraph>(
            find.descendant(of: body, matching: find.byType(RichText)),
          );
          final Rect r = tester.getRect(body);
          final bool tablet = b.key.startsWith('tablet');
          final double font = tablet ? 24 : (b.key == 'phone' ? 18 : 17);
          final int lines = (para.size.height / (font * scale * 1.7)).round();
          final String bubbleLabel = tester
              .getSemantics(find.descendant(of: body, matching: find.byType(Text)))
              .label;
          debugPrint(
            'QA3B|${b.key}|$scale|${n.key}|${text.replaceAll('\u2068', '').replaceAll('\u2069', '').replaceAll('\n', ' / ')}'
            '|${r.width.toStringAsFixed(1)}|$lines|${r.left.toStringAsFixed(1)}'
            '|bubble label marks: ${invisible.allMatches(bubbleLabel).map((Match m) => 'U+${m.group(0)!.codeUnitAt(0).toRadixString(16).toUpperCase()}').join(' ')}',
          );
          debugPrint(
            'QA3B-label|${b.key}|$scale|${n.key}|${bubbleLabel.runes.map((int c) => c < 0x80 || (c >= 0x5D0 && c <= 0x5EA) ? String.fromCharCode(c) : "<U+${c.toRadixString(16)}>").join()}',
          );

          if (!island.isNamed) {
            expect(text, He.homeBubbleNoName.text);
          } else {
            // Exactly one isolate, around the name (whole or shortened), closed before the comma.
            expect('\u2068'.allMatches(text).length, 1, reason: text);
            expect('\u2069'.allMatches(text).length, 1, reason: text);
            final int open = text.indexOf('\u2068');
            final int close = text.indexOf('\u2069');
            expect(open, 0, reason: text);
            expect(text.substring(close + 1), startsWith(','), reason: text);
            final String inner = text.substring(open + 1, close);
            expect(island.name.startsWith(inner.replaceAll(ellipsis, '')), isTrue, reason: text);
            // A shortened name: the "…" is drawn after its last letter in the name's own direction.
            final int dots = text.indexOf(ellipsis);
            if (dots > 0) {
              TextBox boxAt(int i) =>
                  para.getBoxesForSelection(TextSelection(baseOffset: i, extentOffset: i + 1)).first;
              final TextBox letter = boxAt(dots - 1);
              final TextBox dotsBox = boxAt(dots);
              final bool latinEnd = RegExp('[A-Za-z]').hasMatch(text[dots - 1]);
              if (latinEnd) {
                expect(
                  dotsBox.left,
                  greaterThanOrEqualTo(letter.right - 0.5),
                  reason: '"…" right of the Latin',
                );
              } else {
                expect(dotsBox.right, lessThanOrEqualTo(letter.left + 0.5), reason: '"…" left of the Hebrew');
              }
            }
          }
          // Lines and width as in step 3 (B-34: every board): at most two lines, 210 wide (190 on the SE).
          expect(lines, lessThanOrEqualTo(2), reason: text);
          expect(r.width, lessThanOrEqualTo(b.key == 'phoneSE' ? 190.01 : 210.01));

          // What the screen reader gets: the sign and its tap area carry the plain whole name, no invisible marks.
          final List<String> signLabels = <String>[
            tester.getSemantics(find.byKey(const Key('land-tap-nitzi'))).label,
            tester.getSemantics(find.byKey(const Key('sign-nitzi'))).label,
          ];
          for (final String l in signLabels) {
            expect(invisible.hasMatch(l), isFalse, reason: 'a mark in "$l"');
            expect(l, island.semantics);
          }
          sem.dispose();
        });
      }
    }
  }

  test('the nameless bubble takes its own reviewed line, never one cut out of homeBubble', () {
    // Today both give the same words, so only the source tells them apart: a rewording of homeBubble must not change
    // what a child with no name sees (docs/agents/b26-hebrew.md 7.1).
    final String src = File('lib/child/home_screen.dart').readAsStringSync();
    expect(src, contains('He.homeBubbleNoName.text'));
    expect(src.contains(RegExp(r"homeBubble\.text\.replaceFirst\('\{child\}, ', ''\)")), isFalse);
  });
}
