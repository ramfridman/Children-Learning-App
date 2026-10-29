// B-26 step 1: the child's home island is named after the child. The words and the shortening rule are the
// hebrew-text-editor's (docs/agents/b26-hebrew.md, sections 1 and 3); the sign widget picks the maximum length from
// its measured box (owner decision 5), so the editor's table is checked here at its own maximum of 10.
import 'dart:io';

import 'package:flutter/widgets.dart' show StringCharacters;
import 'package:flutter_test/flutter_test.dart';
import 'package:nitznutz/child/home_island_name.dart';
import 'package:nitznutz/strings/he.dart';

const String fsi = '\u2068';
const String pdi = '\u2069';
const String nbsp = '\u00A0';

String sign(String name) => 'הָאִי שֶׁל $fsi$name$pdi';
String title(String name) => 'הָאִי$nbspשֶׁל $fsi$name$pdi';

/// The editor's table (b26-hebrew.md 1.5): the name as typed, its clusters, the sign at the editor's maximum of 10
/// and the screen title (the sign and title columns without the isolate marks).
const List<(int, String, int, String, String)> editorTable = <(int, String, int, String, String)>[
  (1, 'דנה', 3, 'דנה', 'דנה'),
  (2, 'בן', 2, 'בן', 'בן'),
  (3, 'נועה', 4, 'נועה', 'נועה'),
  (4, 'יהונתן', 6, 'יהונתן', 'יהונתן'),
  (5, 'הדס', 3, 'הדס', 'הדס'),
  (6, 'ורד', 3, 'ורד', 'ורד'),
  (7, 'שירה', 4, 'שירה', 'שירה'),
  (8, 'מיכאל', 5, 'מיכאל', 'מיכאל'),
  (9, 'לביא', 4, 'לביא', 'לביא'),
  (10, 'כרמל', 4, 'כרמל', 'כרמל'),
  (11, 'אורי', 4, 'אורי', 'אורי'),
  (12, 'עדי', 3, 'עדי', 'עדי'),
  (13, 'נועם', 4, 'נועם', 'נועם'),
  (14, 'ג\'וליה', 6, 'ג\'וליה', 'ג\'וליה'),
  (15, 'צ׳רלי', 5, 'צ׳רלי', 'צ׳רלי'),
  (16, 'בת-אל', 5, 'בת-אל', 'בת-אל'),
  (17, 'שירה-לי', 7, 'שירה-לי', 'שירה-לי'),
  (18, 'נועה מאיה', 9, 'נועה מאיה', 'נועה מאיה'),
  (19, 'אֲבִיגַיִל', 6, 'אֲבִיגַיִל', 'אֲבִיגַיִל'),
  (20, 'Emma', 4, 'Emma', 'Emma'),
  (21, 'Alexander', 9, 'Alexander', 'Alexander'),
  (22, 'אלכסנדרה', 8, 'אלכסנדרה', 'אלכסנדרה'),
  (23, 'מקסימיליאן', 10, 'מקסימיליאן', 'מקסימיליאן'),
  (24, 'Massimiliano', 12, 'Massimili…', 'Massimiliano'),
  (25, 'Marie-Antoinette', 16, 'Marie…', 'Marie-Antoinette'),
  (26, 'אביגיל-רחל שושנה', 16, 'אביגיל…', 'אביגיל-רחל שושנה'),
  (27, 'אנהמריהלואיזה', 13, 'אנהמריהלו…', 'אנהמריהלואיזה'),
  (28, '  טל  ', 2, 'טל', 'טל'),
];

void main() {
  group('the editor\'s table at its maximum of 10', () {
    for (final (int row, String typed, int clusters, String shown, String whole) in editorTable) {
      test('row $row: "$typed"', () {
        final HomeIslandName island = homeIslandName(typed);
        expect(island.isNamed, isTrue);
        expect(island.name, whole);
        expect(island.name.characters.length, clusters);
        expect(island.sign, sign(whole));
        expect(island.signShortened(10), sign(shown));
        expect(island.title, title(whole));
        expect(island.semantics, 'האי של $whole');
      });
    }

    test('row 29: no name gives "my island" everywhere', () {
      for (final String? typed in <String?>[null, '', '   ', '\u200F', ' \u2066\u202B\u200B\uFEFF \t\n ']) {
        final HomeIslandName island = homeIslandName(typed);
        expect(island.isNamed, isFalse, reason: '$typed');
        expect(island.name, isEmpty);
        expect(island.sign, 'הָאִי שֶׁלִּי');
        expect(island.signShortened(10), 'הָאִי שֶׁלִּי');
        expect(island.title, 'הָאִי$nbspשֶׁלִּי');
        expect(island.semantics, 'האי שלי');
      }
    });
  });

  group('cleaning the typed name', () {
    test('a name with no letter at all gets the fallback', () {
      for (final String typed in <String>['123', '-', '\'', '…', ' - ']) {
        expect(homeIslandName(typed).isNamed, isFalse, reason: typed);
      }
    });

    test(
      'white space is trimmed and every run becomes one space, also tabs, new lines and no-break spaces',
      () {
        expect(homeIslandName(' נועה \t\n מאיה ').name, 'נועה מאיה');
        expect(homeIslandName('נועה\u00A0\u2003מאיה').name, 'נועה מאיה');
      },
    );

    test('direction marks, isolates, zero-width characters and controls are removed', () {
      expect(homeIslandName('\u202Eנועה\u202C').name, 'נועה');
      expect(homeIslandName('\u2067נו\u200Bעה\u2069').name, 'נועה');
      expect(homeIslandName('\u200Eנו\u200Dעה\u200F').name, 'נועה');
      expect(homeIslandName('נו\u0000ע\u0007ה\u007F\u0085').name, 'נועה');
      expect(homeIslandName('\uFEFFEmma\u061C').name, 'Emma');
      // A control between two spaces leaves one space, not two.
      expect(homeIslandName('נועה \u0000 מאיה').name, 'נועה מאיה');
    });

    test('geresh, maqaf and hyphen stay as typed', () {
      expect(homeIslandName('ז\'אן').name, 'ז\'אן');
      expect(homeIslandName('צ׳רלי').name, 'צ׳רלי');
      expect(homeIslandName('בת־אל').name, 'בת־אל');
      expect(homeIslandName('בת-אל').name, 'בת-אל');
    });

    test('the parent\'s nikud is kept and none is added', () {
      expect(homeIslandName('אֲבִיגַיִל').name, 'אֲבִיגַיִל');
      final String plain = homeIslandName('אביגיל').sign;
      final String name = plain.substring(plain.indexOf(fsi) + 1, plain.indexOf(pdi));
      expect(RegExp('[֑-ׇ]').hasMatch(name), isFalse);
    });
  });

  group('the isolate and the frame', () {
    test('a Latin name sits inside the isolate on the sign and the title, and plain in the semantics', () {
      final HomeIslandName island = homeIslandName('Alexander');
      expect(island.sign, endsWith('${fsi}Alexander$pdi'));
      expect(island.title, endsWith('${fsi}Alexander$pdi'));
      expect(island.semantics, isNot(contains(fsi)));
      expect(island.semantics, isNot(contains(pdi)));
      expect(island.signShortened(6), endsWith('${fsi}Alexa…$pdi'));
    });

    test('the title wraps only before the name: the frame words are joined by a no-break space', () {
      final String t = homeIslandName('נועה מאיה').title;
      final String frame = t.substring(0, t.indexOf(fsi));
      expect(frame, 'הָאִי$nbspשֶׁל ');
      expect(t.substring(t.indexOf(fsi)), '$fsiנועה מאיה$pdi');
    });

    test('{child} is always filled, and a name that looks like a placeholder is shown as typed', () {
      for (final (int _, String typed, int _, String _, String _) in editorTable) {
        final HomeIslandName island = homeIslandName(typed);
        for (final String text in <String>[
          island.sign,
          island.signShortened(10),
          island.title,
          island.semantics,
        ]) {
          expect(text.contains('{'), isFalse, reason: text);
        }
      }
      expect(homeIslandName('{child}').sign, sign('{child}'));
    });
  });

  group('shortenName', () {
    test('a name that fits is returned unchanged', () {
      expect(shortenName('אלכסנדרה', 8), 'אלכסנדרה');
      expect(shortenName('אלכסנדרה', 24), 'אלכסנדרה');
    });

    test('the result is never longer than the maximum, the ellipsis included', () {
      for (final (int _, String typed, int _, String _, String _) in editorTable) {
        final String name = homeIslandName(typed).name;
        for (int max = 3; max <= 12; max++) {
          final String short = shortenName(name, max);
          expect(short.characters.length, lessThanOrEqualTo(max), reason: '$name at $max: $short');
          expect(short == name || short.endsWith(ellipsis), isTrue, reason: '$name at $max: $short');
        }
      }
    });

    test('whole parts first, keeping the longest run that fits', () {
      expect(shortenName('אביגיל-רחל שושנה', 11), 'אביגיל-רחל…');
      expect(shortenName('אביגיל-רחל שושנה', 10), 'אביגיל…');
      expect(shortenName('נועה מאיה רחל', 10), 'נועה מאיה…');
      expect(shortenName('בת־אל אביגיל', 7), 'בת־אל…');
    });

    test('a first part needs two letters, otherwise letters are cut', () {
      expect(shortenName('א-ביגילרחל', 6), 'א-ביג…');
    });

    test('letters never leave a geresh behind: the letter before it goes too', () {
      expect(shortenName('אבגדהג\'וליה', 7), 'אבגדה…');
      expect(shortenName('אבגדהצ׳רלי', 7), 'אבגדה…');
      expect(shortenName('אבגדהג\u2019וליה', 7), 'אבגדה…');
      // When the geresh is kept with its letter, nothing else is dropped.
      expect(shortenName('אבגדג\'וליה', 7), 'אבגדג\'…');
    });

    test('a run of whole parts drops its trailing space or hyphen', () {
      expect(shortenName('אבגדה-וזחטי', 7), 'אבגדה…');
      expect(shortenName('אבגדהו זחטי', 8), 'אבגדהו…');
    });

    test('letters never end on a space or a hyphen before the ellipsis', () {
      expect(shortenName('א בגדהוזח', 3), 'א…');
      expect(shortenName('א-בגדהוזח', 3), 'א…');
      expect(shortenName('א ב גדהוזח', 4), 'א ב…');
    });

    test('a nikud mark is part of its letter, so a pointed name is never cut inside a letter', () {
      expect(shortenName('אֲבִיגַיִלְרָחֵל', 5), 'אֲבִיגַ…');
    });

    test('a maximum under 3 is refused', () {
      expect(() => shortenName('אלכסנדרה', 2), throwsRangeError);
    });
  });

  group('the title guard at 24', () {
    test('up to 24 clusters the title shows the whole name', () {
      const String name = 'אבגדהוזחטי אבגדהוזחטי אב'; // 24
      final HomeIslandName island = homeIslandName(name);
      expect(island.title, title(name));
      expect(island.semantics, 'האי של $name');
    });

    test(
      'over 24 the title is shortened by the same rule; the sign and the semantics keep the whole name',
      () {
        const String name = 'אבגדהוזחטי אבגדהוזחטי אבגדהוזחטי אבגדהוזח'; // 40, as the parent form allows
        final HomeIslandName island = homeIslandName(name);
        expect(island.title, title('אבגדהוזחטי אבגדהוזחטי…'));
        expect(island.sign, sign(name));
        expect(island.semantics, 'האי של $name');
      },
    );
  });

  group('the strings in he.dart', () {
    test('the editor\'s texts, child text pointed and screen-reader text plain', () {
      const Map<Str, (String, bool)> expected = <Str, (String, bool)>{
        He.homeIsland: ('הָאִי שֶׁל {child}', true),
        He.homeIslandMine: ('הָאִי שֶׁלִּי', true),
        He.homeIslandSemantics: ('האי של {child}', false),
        He.homeIslandMineSemantics: ('האי שלי', false),
        He.nitziHomeWelcome: ('שָׁלוֹם, {child}! בְּרוּכִים הַבָּאִים הַבַּיְתָה.', true),
        He.nitziHomeWelcomeNoName: ('שָׁלוֹם! בְּרוּכִים הַבָּאִים הַבַּיְתָה.', true),
        He.nitziHomeHi: ('זֶה הַבַּיִת שֶׁלִּי.', true),
        He.nitziHomeTreasures: ('פֹּה גָּרִים הַגְּבִיעִים, הַמֵּדַלְיוֹת וְהַמַּדְבֵּקוֹת.', true),
        He.nitziHomeBottle: ('בַּבַּקְבּוּק יֵשׁ הַרְפַּתְקָה. בּוֹאוּ נִפְתַּח אוֹתוֹ.', true),
        He.nitziHomeBottleDone: (
          'כְּבָר סִיַּמְנוּ אֶת הַהַרְפַּתְקָה שֶׁל הַיּוֹם. אֶפְשָׁר לְשַׂחֵק בָּאִיִּים.',
          true,
        ),
      };
      for (final MapEntry<Str, (String, bool)> e in expected.entries) {
        expect(e.key.text, e.value.$1);
        expect(e.key.nikud, e.value.$2, reason: e.value.$1);
        expect(e.key.review, 'needs-editor', reason: e.value.$1);
      }
    });

    test('each new entry is declared once in the child-space block, before the parent strings', () {
      final String source = File('lib/strings/he.dart').readAsStringSync();
      final int parentPart = source.indexOf('// ---- parent gate and PIN');
      for (final String name in <String>[
        'homeIsland',
        'homeIslandMine',
        'homeIslandSemantics',
        'homeIslandMineSemantics',
        'nitziHomeWelcome',
        'nitziHomeWelcomeNoName',
        'nitziHomeHi',
        'nitziHomeTreasures',
        'nitziHomeBottle',
        'nitziHomeBottleDone',
      ]) {
        final List<RegExpMatch> found = RegExp('static const Str $name = ').allMatches(source).toList();
        expect(found, hasLength(1), reason: name);
        expect(found.single.start, lessThan(parentPart), reason: name);
      }
    });

    test('no "back" label: the home uses the existing back pebble and its screen-reader text', () {
      final String source = File('lib/strings/he.dart').readAsStringSync();
      expect(source.contains('nitziHomeBack'), isFalse);
    });
  });
}
