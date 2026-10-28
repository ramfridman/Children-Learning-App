// The coins and notes of the shop, drawn as the app draws them: a contact sheet to look at (and a picture that must not change by accident).
//
// Regenerate after a deliberate change of the drawings:  flutter test --update-goldens test/coins_sheet_test.dart
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/golden_comparator.dart';

void main() {
  setUpAll(() => useTolerantGoldens(0.03));

  testWidgets('the coins and the notes', (WidgetTester tester) async {
    const List<String> coins = <String>['coin_a10', 'coin_h50', 'coin_s1', 'coin_s2', 'coin_s5', 'coin_s10'];
    const List<String> notes = <String>['note_20', 'note_50', 'note_100', 'note_200'];
    Widget pic(String name, double w) => Padding(
      padding: const EdgeInsets.all(8),
      child: SizedBox(
        width: w,
        child: SvgPicture.string(File('../content/starter/$name.svg').readAsStringSync()),
      ),
    );
    await tester.binding.setSurfaceSize(const Size(900, 520));
    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        home: ColoredBox(
          color: const Color(0xFFFFF4E6),
          child: Column(
            children: <Widget>[
              Wrap(children: <Widget>[for (final String c in coins) pic(c, 130)]),
              Wrap(children: <Widget>[for (final String n in notes) pic(n, 210)]),
              Wrap(
                children: <Widget>[
                  for (final String c in coins) pic(c, 48),
                  for (final String n in notes) pic(n, 76),
                ],
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await expectLater(find.byType(MaterialApp), matchesGoldenFile('goldens/coins_sheet.png'));
  });
}
