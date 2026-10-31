// Rules from CLAUDE.md that are cheap to enforce by reading the source (M1: the app shell).
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

List<File> dartFiles(String dir) =>
    Directory(dir)
        .listSync(recursive: true)
        .whereType<File>()
        .where((File f) => f.path.endsWith('.dart'))
        .toList();

String slashed(File f) => f.path.replaceAll(r'\', '/');

final RegExp hebrew = RegExp('[֐-׿]');
final RegExp niqqud = RegExp('[ְ-ׇ]');

void main() {
  final List<File> lib = dartFiles('lib');

  group('child and parent areas stay apart', () {
    final List<File> child = dartFiles('lib/child');

    test('there is child code to check', () => expect(child.length, greaterThanOrEqualTo(4)));

    test('nothing in child/ imports parent/ or anything that can reach the network or the PIN', () {
      final RegExp forbidden = RegExp(r'''import\s+['"][^'"]*/(parent|security|net|auth|device)/''');
      for (final File f in child) {
        expect(forbidden.hasMatch(f.readAsStringSync()), isFalse, reason: slashed(f));
      }
    });

    test('the only way from the child space into the parent area is the gate', () {
      // The child space receives callbacks; it never builds a parent screen itself.
      for (final File f in child) {
        final String text = f.readAsStringSync();
        expect(text.contains('ParentArea'), isFalse, reason: slashed(f));
        expect(text.contains('ParentSession'), isFalse, reason: slashed(f));
      }
    });

    test('only the parent entry flow unlocks the session', () {
      final List<String> users = <String>[
        for (final File f in lib)
          if (f.readAsStringSync().contains('.unlock(')) slashed(f),
      ];
      expect(
        users.where(
          (String p) => !p.endsWith('parent/entry_flow.dart') && !p.endsWith('security/parent_session.dart'),
        ),
        isEmpty,
      );
    });
  });

  group('Hebrew text', () {
    test('every Hebrew string lives in lib/strings/he.dart', () {
      for (final File f in lib) {
        final String p = slashed(f);
        if (p.endsWith('strings/he.dart')) continue;
        // The matcher's word lists are language data for the recogniser, not text a child sees.
        if (p.startsWith('lib/speech/')) continue;
        for (final String line in f.readAsLinesSync()) {
          if (line.trimLeft().startsWith('//')) continue;
          expect(hebrew.hasMatch(line), isFalse, reason: '$p: $line');
        }
      }
    });

    test('child strings carry niqqud, adult strings do not, and nothing is marked approved', () {
      final String source = File('lib/strings/he.dart').readAsStringSync();
      final RegExp entry = RegExp(r"static const Str (\w+) = Str\(\s*'([^']*)'(,\s*nikud: true)?,?\s*\);");
      final List<RegExpMatch> all = entry.allMatches(source).toList();
      expect(all.length, greaterThan(60));
      for (final RegExpMatch m in all) {
        final String name = m.group(1)!;
        final String text = m.group(2)!;
        final bool nikud = m.group(3) != null;
        if (nikud) {
          expect(niqqud.hasMatch(text), isTrue, reason: '$name should be written with niqqud');
        } else {
          expect(niqqud.hasMatch(text), isFalse, reason: '$name is adult text and has no niqqud');
        }
      }
      expect(source.contains("'approved'"), isFalse);
      expect(source.contains("=> 'needs-editor'"), isTrue);
    });

    test('child-space text never reaches a child as adult text and vice versa', () {
      final String source = File('lib/strings/he.dart').readAsStringSync();
      final int childPart = source.indexOf('// ---- child space ----');
      final int parentPart = source.indexOf('// ---- parent gate and PIN');
      final String childBlock = source.substring(childPart, parentPart);
      // Everything a child sees is pointed, except short semantic labels read by a screen reader. The pattern also takes
      // an entry that the formatter spread over several lines (QA-23: those were skipped before).
      final List<RegExpMatch> entries = RegExp(
        r"static const Str (\w+) = Str\(\s*'([^']*)'(,\s*nikud: true)?,?\s*\)",
      ).allMatches(childBlock).toList();
      expect(entries, hasLength(RegExp(r'static const Str \w+ =').allMatches(childBlock).length));
      for (final RegExpMatch m in entries) {
        final String name = m.group(1)!;
        if (name.endsWith('Semantics') || name == 'homeParents') continue;
        expect(m.group(3), isNotNull, reason: '$name is shown to children and needs niqqud');
      }
    });

    // What this rule protects: the only thing a string may carry from the device is a short, known placeholder, and the one
    // that holds personal data (`child`, the first name) is the only one of its kind. The others are numbers, shapes and
    // words of the lesson itself. `land` is one more of the latter: the name of a land, filled on the device and only from
    // the `He.land*` constants (see the next test), never from the child, the pack or a server.
    test(
      'the placeholders in the child strings are the known ones, and the child name is the only personal one',
      () {
        final String source = File('lib/strings/he.dart').readAsStringSync();
        final Set<String?> names = RegExp(r'\{(\w+)\}')
            .allMatches(source)
            .map((RegExpMatch m) => m.group(1))
            .toSet();
        expect(names, <String?>{'child', 's', 'm', 't', 'n', 'a', 'b', 'how', 'title', 'w', 'land'});
      },
    );

    test('{land} is only ever filled from the land names of He.land*', () {
      // 1. Every place that fills `land` is in the adventure line and takes a name from the two functions of names.dart.
      final List<String> fills = <String>[];
      for (final File f in lib) {
        final String text = f.readAsStringSync();
        for (final RegExpMatch m in RegExp(r"'land':\s*([^,}]*)").allMatches(text)) {
          fills.add('${f.path.replaceAll(r'\', '/').split('lib/').last}: ${m.group(1)!.trim()}');
        }
      }
      expect(fills, <String>[
        'child/adventure_line.dart: landName(land).text',
        'child/adventure_line.dart: landSemanticsName(land).text',
      ]);
      // 2. Those functions return nothing but He.land* constants (one per land, and nothing else in the switch).
      final String names = File('lib/rewards/names.dart').readAsStringSync();
      for (final String fn in <String>['landName', 'landSemanticsName']) {
        final int start = names.indexOf('Str $fn(TrophyLand land) => switch');
        expect(start, isNonNegative, reason: fn);
        final String body = names.substring(start, names.indexOf('};', start));
        final List<String> arms = RegExp(r'TrophyLand\.\w+ => (.+),')
            .allMatches(body)
            .map((RegExpMatch m) => m.group(1)!)
            .toList();
        expect(arms, hasLength(6), reason: fn);
        for (final String arm in arms) {
          expect(arm, matches(RegExp(r'^He\.land[A-Za-z]+$')), reason: '$fn gives only He.land* constants');
        }
      }
    });
  });

  group('fonts', () {
    test('only Heebo and Secular One are declared and used', () {
      final String pubspec = File('pubspec.yaml').readAsStringSync();
      final Set<String> families = RegExp(r'- family: (\S+)')
          .allMatches(pubspec)
          .map((RegExpMatch m) => m.group(1)!)
          .toSet();
      expect(families, <String>{'Heebo', 'SecularOne'});
      for (final File f in lib) {
        final String text = f.readAsStringSync();
        for (final String banned in <String>[
          'Rubik',
          'Fredoka',
          'Roboto',
          'Arial',
          'Assistant',
          'NotoSans',
        ]) {
          expect(text.contains(banned), isFalse, reason: '${slashed(f)} mentions $banned');
        }
        for (final RegExpMatch m in RegExp(r'''fontFamily:\s*['"]([^'"]+)['"]''').allMatches(text)) {
          expect(
            <String>{'Heebo', 'SecularOne'}.contains(m.group(1)),
            isTrue,
            reason: '${slashed(f)}: ${m.group(0)}',
          );
        }
      }
    });

    test('no synthetic bold anywhere', () {
      for (final File f in lib) {
        final String text = f.readAsStringSync();
        expect(text.contains('FontWeight.bold'), isFalse, reason: slashed(f));
        expect(text.contains('fontWeight: FontWeight.w700'), isFalse, reason: slashed(f));
      }
    });

    test('no letter spacing on text styles (it breaks niqqud)', () {
      for (final File f in lib) {
        for (final RegExpMatch m in RegExp(r'letterSpacing:\s*([^,)\s]+)').allMatches(f.readAsStringSync())) {
          expect(m.group(1), '0', reason: slashed(f));
        }
      }
    });

    test('font files and their licences are bundled', () {
      for (final String name in <String>[
        'Heebo-Variable.ttf',
        'SecularOne-Regular.ttf',
        'OFL-Heebo.txt',
        'OFL-SecularOne.txt',
      ]) {
        expect(File('assets/fonts/$name').existsSync(), isTrue, reason: name);
      }
    });
  });

  group('the child space has no purchases, timers, streaks or guilt', () {
    test('no such words in the child code', () {
      final RegExp banned = RegExp(
        'streak|countdown|purchase|subscribe|price|ads?Banner|timer',
        caseSensitive: false,
      );
      for (final File f in dartFiles('lib/child')) {
        for (final String line in f.readAsLinesSync()) {
          if (line.trimLeft().startsWith('//') || line.trimLeft().startsWith('///')) continue;
          expect(banned.hasMatch(line), isFalse, reason: '${slashed(f)}: $line');
        }
      }
    });
  });
}
