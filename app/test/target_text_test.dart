// The teaching font of English and Russian lesson text (docs/languages/fonts.md sections 6 and 8.5): upright only, never the
// stylistic set that gives the one-storey Cyrillic a, a language tag on every run, left to right whatever the screen, and the
// files clean of the name of the font they were made from.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nitznutz/design/target_text.dart';

import 'support/harness.dart';

List<File> dartFiles(String dir) =>
    Directory(dir)
        .listSync(recursive: true)
        .whereType<File>()
        .where((File f) => f.path.endsWith('.dart'))
        .toList();

void main() {
  setUpAll(loadAppFonts);

  group('the style', () {
    test('Medium for words, Bold for a letter, upright, no spacing, no features', () {
      final TextStyle word = targetStyle(size: 26);
      final TextStyle letter = targetStyle(size: 64, bold: true);
      expect(word.fontFamily, 'NitznutzLetters');
      expect(word.fontWeight, FontWeight.w500);
      expect(letter.fontWeight, FontWeight.w700);
      for (final TextStyle s in <TextStyle>[word, letter]) {
        expect(s.fontStyle, FontStyle.normal);
        expect(s.letterSpacing, 0);
        expect(s.fontFeatures, isNull, reason: 'ss01 (or any feature) is never switched on');
        expect(s.fontVariations, isNull);
      }
    });

    test('the languages are English and Russian with their own tags, never sr, mk or bg', () {
      expect(TargetLanguage.english.locale, const Locale('en'));
      expect(TargetLanguage.russian.locale, const Locale('ru'));
      expect(TargetLanguage.values.map((TargetLanguage l) => l.tag), <String>['en', 'ru']);
    });
  });

  group('the widget', () {
    testWidgets(
      'Russian text carries the ru tag, English the en tag, both left to right inside a right to left screen',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            locale: Locale('he'),
            home: Directionality(
              textDirection: TextDirection.rtl,
              child: Column(
                children: <Widget>[
                  TargetText('Привет', language: TargetLanguage.russian, size: 26),
                  TargetText('Hello', language: TargetLanguage.english, size: 26),
                ],
              ),
            ),
          ),
        );
        final Text ru = tester.widget<Text>(find.text('Привет'));
        final Text en = tester.widget<Text>(find.text('Hello'));
        expect(ru.locale, const Locale('ru'));
        expect(en.locale, const Locale('en'));
        expect(ru.textDirection, TextDirection.ltr);
        expect(en.textDirection, TextDirection.ltr);
        expect(ru.style!.fontStyle, FontStyle.normal);
        expect(ru.style!.fontFeatures, isNull);
      },
    );
  });

  group('the source', () {
    test('no italic, no font feature and no stylistic set anywhere near the family', () {
      final String text = File('lib/design/target_text.dart').readAsStringSync();
      expect(text.contains('FontStyle.italic'), isFalse);
      expect(text.contains('FontFeature'), isFalse);
      expect(text.toLowerCase().contains('ss01'), isFalse);
    });

    test('no italic is declared for the family in the pubspec, and no italic is asked for in the app', () {
      final String pubspec = File('pubspec.yaml').readAsStringSync();
      final int start = pubspec.indexOf('- family: NitznutzLetters');
      expect(start, isNonNegative);
      final String block = pubspec.substring(
        start,
        pubspec.indexOf('\n    - family', start + 1) < 0
            ? pubspec.length
            : pubspec.indexOf('\n    - family', start + 1),
      );
      expect(block.contains('style: italic'), isFalse);
      expect(RegExp(r'weight: (\d+)').allMatches(block).map((RegExpMatch m) => m.group(1)).toList(), <String>[
        '500',
        '700',
      ]);
      for (final File f in dartFiles('lib')) {
        final String path = f.path.replaceAll(r'\', '/');
        if (path.endsWith('target_text.dart')) continue;
        expect(f.readAsStringSync().contains('ss01'), isFalse, reason: path);
      }
    });

    test('every Russian string in a widget is tagged: Cyrillic text is set only through TargetText', () {
      final RegExp cyrillic = RegExp('[Ѐ-ӿ]');
      for (final File f in dartFiles('lib')) {
        final String path = f.path.replaceAll(r'\', '/');
        final String text = f.readAsStringSync();
        if (!cyrillic.hasMatch(text)) continue;
        // A file with Cyrillic in it must hand it to TargetText with the Russian language.
        expect(text.contains('TargetLanguage.russian'), isTrue, reason: path);
      }
    });
  });

  group('the font files', () {
    final List<String> files = <String>[
      'assets/fonts/NitznutzLetters-Medium.ttf',
      'assets/fonts/NitznutzLetters-Bold.ttf',
    ];

    test('no trace of the name of the font they were made from, in ASCII or in UTF-16', () {
      for (final String path in files) {
        final List<int> bytes = File(path).readAsBytesSync();
        for (final String word in <String>['Andika', 'SIL International']) {
          final List<int> ascii = word.codeUnits;
          final List<int> wide = <int>[
            for (final int c in word.codeUnits) ...<int>[0, c],
          ];
          for (final List<int> needle in <List<int>>[ascii, wide]) {
            expect(_contains(bytes, needle), isFalse, reason: '$path holds "$word"');
          }
        }
        expect(
          _contains(bytes, 'Nitznutz Letters'.codeUnits) || _contains(bytes, _wide('Nitznutz Letters')),
          isTrue,
        );
      }
    });

    test('the sizes are those of the build (a changed file is a deliberate change)', () {
      expect(File(files[0]).lengthSync(), 59808);
      expect(File(files[1]).lengthSync(), 60048);
    });
  });
}

List<int> _wide(String s) => <int>[
  for (final int c in s.codeUnits) ...<int>[0, c],
];

bool _contains(List<int> haystack, List<int> needle) {
  outer:
  for (int i = 0; i + needle.length <= haystack.length; i++) {
    for (int j = 0; j < needle.length; j++) {
      if (haystack[i + j] != needle[j]) continue outer;
    }
    return true;
  }
  return false;
}
