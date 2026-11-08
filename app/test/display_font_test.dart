// A font for one item (HEB-A-10.6 and HEB-A-11.4, a transfer check of the same letters and names in Secular One): `font: display` on an activity of
// a Hebrew course, drawn by `CourseText` under a `DisplayFontScope`. English and Russian have their one teaching font and refuse it.
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nitznutz/content/models.dart';
import 'package:nitznutz/content/pack_verify.dart';
import 'package:nitznutz/content/schema.dart' show Problem;
import 'package:nitznutz/design/course_text.dart';
import 'package:nitznutz/design/target_text.dart';
import 'package:nitznutz/design/tokens.g.dart';

import '../tool/pack_builder_lib.dart';
import 'support/pack_fixtures.dart';

const String _languages = '../content/languages';

String? _familyOf(WidgetTester t, String text) {
  final Text w = t.widget<Text>(find.text(text));
  return w.style?.fontFamily;
}

void main() {
  group('the face of the text', () {
    testWidgets('Hebrew is Heebo, and Secular One inside the scope of an item that asks for it', (
      WidgetTester t,
    ) async {
      await t.pumpWidget(
        const Directionality(
          textDirection: TextDirection.rtl,
          child: Column(
            children: <Widget>[
              CourseText('נעה', course: 'heb', size: 40, bold: true),
              DisplayFontScope(display: true, child: CourseText('דני', course: 'heb', size: 40, bold: true)),
              DisplayFontScope(display: false, child: CourseText('גיל', course: 'heb', size: 40)),
            ],
          ),
        ),
      );
      expect(_familyOf(t, 'נעה'), TokenFonts.text);
      expect(_familyOf(t, 'דני'), TokenFonts.display);
      expect(_familyOf(t, 'גיל'), TokenFonts.text);
      // Secular One has one weight: a bold request is a plain one in it, never a smeared copy
      expect(t.widget<Text>(find.text('דני')).style?.fontWeight, FontWeight.w400);
      expect(t.widget<Text>(find.text('נעה')).style?.fontWeight, FontWeight.w700);
    });

    testWidgets('English and Russian keep their one teaching font, whatever the scope says', (
      WidgetTester t,
    ) async {
      await t.pumpWidget(
        const Directionality(
          textDirection: TextDirection.ltr,
          child: DisplayFontScope(
            display: true,
            child: Column(
              children: <Widget>[
                CourseText('cat', course: 'eng', size: 40),
                CourseText('кот', course: 'rus', size: 40),
              ],
            ),
          ),
        ),
      );
      expect(_familyOf(t, 'cat'), targetFontFamily);
      expect(_familyOf(t, 'кот'), targetFontFamily);
    });
  });

  group('the item in the pack', () {
    late PackContent heb;
    late PackKey key;

    setUpAll(() async {
      key = await newTestKey();
      heb = PackContent.fromPack(
        await verifyPack(
          (await buildPack(languageSource('heb', _languages), key)).bytes,
          publicKey: key.publicKey,
        ),
      );
    });

    test(
      'A-10.6 (a sort) and A-11.4 (a choice of names) ask for the display face, and no other activity does',
      () {
        final Set<String> asking = <String>{
          for (final Activity a in heb.activities.values)
            if (a.displayFont) a.id,
        };
        expect(asking, <String>{'heb.a10.s06', 'heb.a11.04'});
      },
    );

    test('the item names a letter group of the same letters as the item it checks, in the other face', () {
      expect(heb.activities['heb.a10.s06']!.purpose, 'check');
      expect(heb.activities['heb.a11.04']!.purpose, 'check');
    });

    test('a pack of another course refuses it, with the file named', () async {
      final Directory from = languageSource('eng', _languages);
      final Directory dir = Directory.systemTemp.createTempSync('nn_font_');
      addTearDown(() => dir.deleteSync(recursive: true));
      for (final FileSystemEntity e in from.listSync()) {
        if (e is File) e.copySync('${dir.path}${Platform.pathSeparator}${e.uri.pathSegments.last}');
      }
      final File f = File('${dir.path}${Platform.pathSeparator}activity.eng.a01.i01.json');
      final Map<String, Object?> doc = jsonDecode(f.readAsStringSync()) as Map<String, Object?>;
      doc['font'] = 'display';
      f.writeAsStringSync(jsonEncode(doc));
      try {
        await buildPack(dir, key);
        fail('the broken source was signed');
      } on BuildFailed catch (e) {
        expect(
          e.problems.map((Problem p) => '$p').join('\n'),
          allOf(
            contains('activity.eng.a01.i01.json'),
            contains('font'),
            contains('belongs to a Hebrew course'),
          ),
        );
      }
    });
  });
}
