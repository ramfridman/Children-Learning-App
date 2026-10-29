// QA, B-26 step 1: an independent, adversarial check of `homeIslandName` and `shortenName` beyond the developer's
// tests (docs/qa/b26-step1-verification.md). Open defects are skipped in a normal run so the suite stays green; run
//
//   flutter test --no-pub --dart-define=QA_OPEN=true test/qa_b26_home_island_name_test.dart
//
// When a defect is fixed, the owner of the fix removes `skip: _open` from its test.
import 'dart:math';

import 'package:flutter/widgets.dart' show StringCharacters;
import 'package:flutter_test/flutter_test.dart';
import 'package:nitznutz/child/home_island_name.dart';
import 'package:nitznutz/strings/he.dart';

const bool _runOpen = bool.fromEnvironment('QA_OPEN');
const bool _open = !_runOpen;

const String fsi = '\u2068';
const String pdi = '\u2069';
const Set<String> separators = <String>{' ', '-', '־'};
const Set<String> gereshes = <String>{'\'', '׳', '’'};
final RegExp format = RegExp(r'\p{Cf}', unicode: true);
final RegExp control = RegExp(r'\p{Cc}', unicode: true);
final RegExp mark = RegExp(r'^\p{M}', unicode: true);

/// The checks every shortened name must pass (the editor's rule, b26-hebrew.md 1.4, and owner decision 5).
void expectShortenedWell(String name, int max) {
  final String short = shortenName(name, max);
  final String why = '"$name" at $max: "$short"';
  final int clusters = short.characters.length;
  expect(clusters, lessThanOrEqualTo(max), reason: why);
  if (name.characters.length <= max) {
    expect(short, name, reason: why);
    return;
  }
  expect(short.endsWith(ellipsis), isTrue, reason: why);
  final String kept = short.substring(0, short.length - ellipsis.length);
  expect(kept, isNotEmpty, reason: why);
  // A prefix made of whole clusters: never a letter without its nikud.
  expect(name.startsWith(kept), isTrue, reason: why);
  final List<String> all = name.characters.toList();
  final List<String> head = kept.characters.toList();
  expect(all.sublist(0, head.length), head, reason: why);
  final String rest = name.substring(kept.length);
  expect(mark.hasMatch(rest), isFalse, reason: '$why: the first dropped code point is a combining mark');
  // Never ends on a separator before the ellipsis (unless a single cluster is all that is left).
  if (head.length > 1) expect(separators.contains(head.last), isFalse, reason: why);
  // A letter is never shown without its geresh: the first dropped cluster is not a geresh. Two gereshes in a row are
  // QA-22 (open), checked strictly in its own group.
  if (!hasDoubledGeresh(all)) {
    expect(gereshes.contains(rest.characters.first), isFalse, reason: '$why: a letter lost its geresh');
  }
}

bool hasDoubledGeresh(List<String> clusters) {
  for (int i = 1; i < clusters.length; i++) {
    if (gereshes.contains(clusters[i - 1]) && gereshes.contains(clusters[i])) return true;
  }
  return false;
}

void main() {
  group('long names', () {
    String repeat(String s, int n) => List<String>.filled(n, s).join();

    test('24 clusters: the title and the semantics show the whole name', () {
      final String name = repeat('א', 24);
      final HomeIslandName island = homeIslandName(name);
      expect(island.title, endsWith('$fsi$name$pdi'));
      expect(island.semantics, 'האי של $name');
      expect(island.sign, endsWith('$fsi$name$pdi'));
    });

    test(
      '25 clusters: the title is cut to 24 with the ellipsis; the sign and the semantics keep it whole',
      () {
        final String name = repeat('א', 25);
        final HomeIslandName island = homeIslandName(name);
        final String t = island.title;
        final String inIsolate = t.substring(t.indexOf(fsi) + 1, t.indexOf(pdi));
        expect(inIsolate, '${repeat('א', 23)}$ellipsis');
        expect(inIsolate.characters.length, 24);
        expect(island.semantics, 'האי של $name');
        expect(island.sign, endsWith('$fsi$name$pdi'));
      },
    );

    test('40 and 200 clusters, Hebrew with nikud, Latin and many parts: title at most 24, never throws', () {
      final List<String> names = <String>[
        repeat('אֲ', 40),
        '${repeat('Ab-', 13)}C', // 40
        repeat('דנה ', 50).trim(), // 199
        repeat('מ', 200),
        repeat('Zoe\u0308 ', 50).trim(),
      ];
      for (final String name in names) {
        final HomeIslandName island = homeIslandName(name);
        final String t = island.title;
        final String inIsolate = t.substring(t.indexOf(fsi) + 1, t.indexOf(pdi));
        expect(inIsolate.characters.length, lessThanOrEqualTo(titleMaxClusters), reason: name);
        expect(inIsolate, endsWith(ellipsis), reason: name);
        expect(island.semantics, 'האי של ${island.name}', reason: name);
        for (int max = 3; max <= 30; max++) {
          expectShortenedWell(island.name, max);
        }
      }
    });
  });

  group('odd names', () {
    test('only a geresh, a hyphen, a maqaf, digits, emoji or marks: the fallback', () {
      for (final String typed in <String>[
        '\'',
        '׳',
        '’’',
        '--',
        '־',
        '- ־ \'',
        '2018',
        '٣٤',
        '🦄',
        '👨\u200D👩\u200D👧',
        '🇮🇱',
        '\u05B8\u05B8', // nikud with no letter
        '.',
        '\u2800', // braille blank
      ]) {
        final HomeIslandName island = homeIslandName(typed);
        expect(island.isNamed, isFalse, reason: typed);
        expect(island.sign, He.homeIslandMine.text, reason: typed);
        expect(island.semantics, He.homeIslandMineSemantics.text, reason: typed);
      }
    });

    test('Latin with accents, precomposed and decomposed, counts one cluster per letter', () {
      expect(homeIslandName('Zoë').name.characters.length, 3);
      expect(homeIslandName('Zoe\u0308').name.characters.length, 3);
      expect(homeIslandName('José').sign, 'הָאִי שֶׁל ${fsi}José$pdi');
      for (int max = 3; max <= 14; max++) {
        expectShortenedWell('Rene\u0301e-E\u0301loi\u0308se', max);
        expectShortenedWell('Renée-Éloïse', max);
      }
      expect(shortenName('Rene\u0301e-E\u0301loi\u0308se', 8), 'Rene\u0301e…');
    });

    test(
      'emoji: kept as typed, one cluster each, a ZWJ family falls apart into its people (ZWJ is removed)',
      () {
        final HomeIslandName island = homeIslandName('נועה 👍🏽');
        expect(island.name, 'נועה 👍🏽');
        expect(island.name.characters.length, 6);
        expect(homeIslandName('דנה 👨\u200D👩\u200D👧').name, 'דנה 👨👩👧');
        for (int max = 3; max <= 8; max++) {
          expectShortenedWell('דנה🇮🇱🇮🇱🇮🇱👍🏽👍🏽', max);
        }
      },
    );

    test(
      'RTL and LTR marks and embeddings mixed into a name are all removed, the isolate is the only one',
      () {
        final HomeIslandName island = homeIslandName(
          '\u200Fדנה\u200E \u202AEmma\u202C\u2066\u2069\u2069 \u061C',
        );
        expect(island.name, 'דנה Emma');
        for (final String text in <String>[island.sign, island.title, island.signShortened(4)]) {
          expect(fsi.allMatches(text).length, 1, reason: text);
          expect(pdi.allMatches(text).length, 1, reason: text);
          expect(text.endsWith(pdi), isTrue, reason: text);
          expect(RegExp('[\u200E\u200F\u202A-\u202E\u2066\u2067]').hasMatch(text), isFalse, reason: text);
        }
        expect(format.hasMatch(island.semantics), isFalse);
        // A stray close-isolate typed by the parent cannot end the name's isolate early.
        expect(homeIslandName('Emma\u2069 x').sign, 'הָאִי שֶׁל ${fsi}Emma x$pdi');
      },
    );

    test('names with nikud are never cut inside a letter', () {
      for (final String name in <String>['אֲבִיגַיִל', 'יְהוֹנָתָן-שְׁמוּאֵל', 'שִׁירָה לִי', 'מִיכָאֵל']) {
        for (int max = 3; max <= 14; max++) {
          expectShortenedWell(name, max);
        }
      }
      expect(shortenName('יְהוֹנָתָן-שְׁמוּאֵל', 10), 'יְהוֹנָתָן…');
    });

    test('a combining mark after a separator: never split from it, never throws', () {
      // A space or hyphen with a mark on it is one cluster that is not a plain separator.
      for (final String name in <String>[
        'בת-\u05B8אלאלאל',
        'נועה \u05B8מאיה רחל',
        '\u05B8דנהדנהדנה',
        'ab- \u0301cdefgh',
      ]) {
        final HomeIslandName island = homeIslandName(name);
        expect(island.isNamed, isTrue, reason: name);
        for (int max = 3; max <= 12; max++) {
          expectShortenedWell(island.name, max);
        }
      }
    });

    test('"{child}" and other braces typed as a name are shown as typed, once, everywhere', () {
      for (final String typed in <String>['{child}', '{child}{child}', '{companion}', r'א $1 \0 {}']) {
        final HomeIslandName island = homeIslandName(typed);
        expect(island.sign, 'הָאִי שֶׁל $fsi$typed$pdi', reason: typed);
        expect(island.title, endsWith('$fsi$typed$pdi'), reason: typed);
        expect(island.semantics, 'האי של $typed', reason: typed);
      }
    });
  });

  group('the maximum', () {
    test('3, 4, 5 and large give the rule; below 3 is a RangeError and nothing else throws', () {
      const String name = 'אביגיל-רחל שושנה';
      expect(shortenName(name, 3), 'אב…');
      expect(shortenName(name, 4), 'אבי…');
      expect(shortenName(name, 5), 'אביג…');
      expect(shortenName(name, 7), 'אביגיל…');
      expect(shortenName(name, 16), name);
      expect(shortenName(name, 1000), name);
      expect(shortenName(name, 1 << 62), name);
      for (final int bad in <int>[2, 1, 0, -1, -(1 << 62)]) {
        expect(() => shortenName(name, bad), throwsRangeError, reason: '$bad');
        expect(() => shortenName('', bad), throwsRangeError, reason: 'empty at $bad');
      }
      expect(shortenName('', 3), '');
      expect(() => homeIslandName(name).signShortened(2), throwsRangeError);
      // The fallback has no name to shorten, so it does not check the maximum.
      expect(homeIslandName('').signShortened(2), He.homeIslandMine.text);
    });
  });

  group('random names', () {
    test('5,000 random names: homeIslandName never throws, every shortening keeps the rules', () {
      final Random random = Random(26);
      const List<String> alphabet = <String>[
        'א',
        'ב',
        'ג',
        'ש',
        'ל',
        'ם',
        'ן',
        'a',
        'Z',
        'é',
        'e\u0301',
        '\u05B8',
        '\u05BC',
        '\u05C1',
        '\u05B4',
        ' ',
        ' ',
        '-',
        '־',
        '\'',
        '׳',
        '’',
        '1',
        '7',
        '🦄',
        '👍🏽',
        '🇮🇱',
        '\u200D',
        '\u200F',
        '\u200E',
        '\u202E',
        '\u2066',
        '\u2069',
        '\uFEFF',
        '\u0000',
        '\t',
        '\n',
        '\u00A0',
        '\u0301',
        '{',
        '}',
        '…',
        '\u3164',
      ];
      for (int n = 0; n < 5000; n++) {
        final int length = random.nextInt(45);
        final String typed = List<String>.generate(
          length,
          (_) => alphabet[random.nextInt(alphabet.length)],
        ).join();
        final HomeIslandName island = homeIslandName(typed);
        expect(format.hasMatch(island.name), isFalse, reason: typed);
        expect(control.hasMatch(island.name), isFalse, reason: typed);
        expect(island.name, island.name.trim(), reason: typed);
        expect(island.name.contains('  '), isFalse, reason: typed);
        if (!island.isNamed) continue;
        final String t = island.title;
        final String inTitle = t.substring(t.indexOf(fsi) + 1, t.indexOf(pdi));
        expect(inTitle.characters.length, lessThanOrEqualTo(titleMaxClusters), reason: typed);
        for (final int max in <int>[3, 4, 5, 6, 8, 10, 13, 24]) {
          expectShortenedWell(island.name, max);
        }
      }
    });
  });

  group('QA-22 (open): a letter is never shown without its geresh', () {
    test('a doubled apostrophe after the cut still leaves the letter before it without its geresh', () {
      // clusters: א ב ג ד ה ' ' ו ל י ה; at 7 the cut lands on the second apostrophe, steps back one cluster to
      // the first apostrophe and keeps "אבגדה": ה is shown without its geresh. The rule (1.4 step 2) is that a letter
      // is never shown without its geresh: step back past every geresh, then one more letter.
      expect(shortenName('אבגדה\'\'וליה', 7), 'אבגד…');
      expect(shortenName('אבגדה׳׳וליה', 7), 'אבגד…');
    }, skip: _open);
  });
}
