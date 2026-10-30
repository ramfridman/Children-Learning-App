// QA's adversarial checks of board B-28 (the child's first name: one limit of 24 UTF-16 units on the phone and on the
// server). Verdicts of the server side were derived independently from supabase/functions/child-put/handler.ts (the
// pattern /^[^\u0000-\u001f\u007f<>]{1,24}$/ without the u flag) by running it in Deno on every string used here.
//
// The groups "regression" pass today. The group "QA-B28 (open)" holds the defects: each test FAILS until the defect is
// fixed and is skipped in a normal run (the convention of qa_open_defects_test.dart); run them with
//
//   flutter test --no-pub --dart-define=QA_OPEN=true test/qa_b28_test.dart
//
// When a defect is fixed, the owner of the fix removes `skip: _open` from its test. Record: docs/qa/b28-verification.md.
import 'package:drift/drift.dart' show Value, driftRuntimeOptions;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nitznutz/data/app_database.dart';
import 'package:nitznutz/data/child_name.dart';
import 'package:nitznutz/parent/child_form.dart';
import 'package:nitznutz/parent/parent_area.dart';
import 'package:nitznutz/strings/he.dart';

import 'support/app_harness.dart';
import 'support/fake_family_server.dart';
import 'support/harness.dart';
import 'sync_engine_test.dart' show Phone, dev1, dev2, kid;

const bool _open = !bool.fromEnvironment('QA_OPEN');

const String _flower = '\u{1F338}';
const String _long30 = 'abcdefghijklmnopqrstuvwxyzabcd';
const String _cut24 = 'abcdefghijklmnopqrstuvwx';

TextEditingValue _at(String text, int offset) => TextEditingValue(
  text: text,
  selection: TextSelection.collapsed(offset: offset),
);

Future<void> _rename(Phone p, String id, String name) => (p.db.update(
  p.db.profiles,
)..where(($ProfilesTable t) => t.id.equals(id))).write(ProfilesCompanion(name: Value<String>(name)));

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  group('regression: the rule against strings the vectors do not hold', () {
    test('a name with nikud that is exactly 24 units is ok, 25 is too long, whatever the grapheme count', () {
      final String n24 = 'אָבָגָדָהָוָזָחָטָיָכָלָ'; // 12 letters, 12 marks
      expect(n24.length, 24);
      expect(validateChildName(n24), ChildNameProblem.ok);
      expect(validateChildName('${n24}x'), ChildNameProblem.tooLong);
      expect(fitChildNameForServer(n24), n24);
    });

    test(
      'NBSP and the ideographic space at the ends are trimmed, as saving trims; U+00A0 alone is empty',
      () {
        expect(validateChildName(' נועה '), ChildNameProblem.ok);
        expect(validateChildName('　נועה　'), ChildNameProblem.ok);
        expect(validateChildName('${'a' * 24} '), ChildNameProblem.ok);
        expect(validateChildName(' 　 '), ChildNameProblem.empty);
        expect(fitChildNameForServer(' נועה　'), 'נועה');
      },
    );

    test('only spaces and brackets: refused as bad characters, and nothing is sent', () {
      expect(validateChildName('  <  '), ChildNameProblem.badChars);
      expect(validateChildName(' > '), ChildNameProblem.badChars);
      expect(fitChildNameForServer('  <  '), '');
    });

    test('a name longer than 24 that also holds a refused character is still told apart from "too long"', () {
      expect(validateChildName('${'a' * 30}<'), ChildNameProblem.badChars);
    });

    test(
      'fit never gives the server more than 24 units, nor half an emoji, for 0 to 40 units of mixed text',
      () {
        final RegExp server = RegExp(r'^[^\u0000-\u001f\u007f<>]{1,24}$');
        const List<String> pieces = <String>['a', 'ב', 'ָ', _flower, ' ', '<', '‏'];
        for (int shift = 0; shift < pieces.length; shift++) {
          final StringBuffer b = StringBuffer();
          for (int i = 0; i < 40; i++) {
            b.write(pieces[(i + shift) % pieces.length]);
            final String sent = fitChildNameForServer(b.toString());
            if (sent.isEmpty) continue;
            expect(server.hasMatch(sent), isTrue, reason: 'shift $shift, ${b.length} units: "$sent"');
            expect(sent, sent.trim());
            for (int u = 0; u < sent.length; u++) {
              final int c = sent.codeUnitAt(u);
              final bool high = c >= 0xD800 && c <= 0xDBFF;
              final bool low = c >= 0xDC00 && c <= 0xDFFF;
              if (high) expect(u + 1 < sent.length && sent.codeUnitAt(u + 1) >= 0xDC00, isTrue);
              if (low) expect(u > 0 && sent.codeUnitAt(u - 1) <= 0xDBFF, isTrue);
            }
          }
        }
      },
    );

    test('the formatter: a paste of an emoji over the limit is dropped whole, never as a lone half', () {
      const ChildNameLengthFormatter f = ChildNameLengthFormatter();
      for (int have = 20; have < 24; have++) {
        final String old = 'a' * have;
        final TextEditingValue out = f.formatEditUpdate(
          _at(old, have),
          _at('$old$_flower$_flower', have + 4),
        );
        expect(out.text.length, lessThanOrEqualTo(24), reason: 'have $have');
        final String tail = out.text.substring(have);
        expect(tail == '' || tail == _flower || tail == '$_flower$_flower', isTrue, reason: 'have $have');
        expect(out.selection.baseOffset, lessThanOrEqualTo(out.text.length));
      }
    });

    test('the formatter: replacing a selection at the limit with a longer paste is cut to 24', () {
      const ChildNameLengthFormatter f = ChildNameLengthFormatter();
      final TextEditingValue old = TextEditingValue(
        text: 'a' * 24,
        selection: const TextSelection(baseOffset: 0, extentOffset: 24),
      );
      final TextEditingValue out = f.formatEditUpdate(old, _at(_long30, 30));
      expect(out.text, _cut24);
      expect(out.selection.extentOffset, 24);
    });

    test('the formatter: a paste in the middle keeps the text at 24 and the cursor inside it', () {
      const ChildNameLengthFormatter f = ChildNameLengthFormatter();
      final TextEditingValue out = f.formatEditUpdate(_at('abcdefghij', 3), _at('abc${'X' * 30}defghij', 33));
      expect(out.text.length, 24);
      expect(out.selection.baseOffset, lessThanOrEqualTo(24));
      expect(out.selection.baseOffset, greaterThanOrEqualTo(0));
    });
  });

  group('regression: sync of names saved before the limit', () {
    late FakeFamilyServer server;
    late Phone p1;
    late Phone p2;

    setUp(() {
      server = FakeFamilyServer();
      p1 = Phone(dev1, server);
      p2 = Phone(dev2, server);
    });

    tearDown(() async {
      await p1.db.close();
      await p2.db.close();
    });

    int puts() => server.calls.where((String c) => c == '$dev1:child-put').length;

    test('three sync rounds in a row send the child once, and the name stays whole on this phone', () async {
      await p1.addChild(name: _long30);
      await p1.engine.syncOnce();
      await p1.engine.syncOnce();
      await p1.engine.syncOnce();
      expect(puts(), 1);
      expect((await p1.db.allProfiles()).single.name, _long30);
      expect(server.children[kid]?['nickname'], _cut24);
    });

    test(
      'a rename on another device while this phone holds the long name: the pull takes the new name',
      () async {
        await p1.addChild(name: _long30);
        await p1.engine.syncOnce();
        // Another parent phone renamed the child (the app has no rename today; the server accepts it from child-put).
        server.children[kid]!['nickname'] = 'דנה';
        await p1.engine.syncOnce();
        expect((await p1.db.allProfiles()).single.name, 'דנה');
        server.calls.clear();
        await p1.engine.syncOnce();
        expect(
          server.calls,
          isNot(contains('$dev1:child-put')),
          reason: 'the pulled name is not pushed back',
        );
      },
    );

    test(
      'the long name changes on this phone after it was cut: the new cut goes once, the phone keeps it whole',
      () async {
        await p1.addChild(name: _long30);
        await p1.engine.syncOnce();
        const String other = 'zyxwvutsrqponmlkjihgfedcbazyxw';
        await _rename(p1, kid, other);
        await p1.engine.syncOnce();
        expect(server.children[kid]?['nickname'], other.substring(0, 24));
        expect((await p1.db.allProfiles()).single.name, other);
        server.calls.clear();
        await p1.engine.syncOnce();
        expect(server.calls, isNot(contains('$dev1:child-put')));
        expect(server.children[kid]?['nickname'], other.substring(0, 24));
      },
    );

    test(
      'a long name changed to a short one on this phone is pushed, and the pull keeps the short one',
      () async {
        await p1.addChild(name: _long30);
        await p1.engine.syncOnce();
        await _rename(p1, kid, 'דנה');
        await p1.engine.syncOnce();
        expect(server.children[kid]?['nickname'], 'דנה');
        expect((await p1.db.allProfiles()).single.name, 'דנה');
      },
    );

    test('two children with 30-letter names that share their first 24 each keep their own name', () async {
      const String other = '${_cut24}ZZZZZZ';
      await p1.addChild(name: _long30);
      await p1.db.addProfile(
        ProfilesCompanion.insert(
          id: 'child-bbbb-0002',
          name: other,
          avatar: 'avatar-noa',
          addressForm: 'f',
          ageBand: 1,
          createdAt: DateTime.utc(2026, 11, 1),
        ),
      );
      await p1.engine.syncOnce();
      await p1.engine.syncOnce();
      final Map<String, String> names = <String, String>{
        for (final Profile p in await p1.db.allProfiles()) p.id: p.name,
      };
      expect(names[kid], _long30);
      expect(names['child-bbbb-0002'], other);
      expect(puts(), 2, reason: 'one child-put for each child, none again');
      await p2.engine.syncOnce();
      expect((await p2.db.allProfiles()).map((Profile p) => p.name), <String>[_cut24, _cut24]);
    });

    test(
      'a long name with an emoji over the cut: the server holds 23 units and the phone keeps the whole',
      () async {
        final String name = '${'a' * 23}${_flower}bc';
        await p1.addChild(name: name);
        await p1.engine.syncOnce();
        await p1.engine.syncOnce();
        expect(server.children[kid]?['nickname'], 'a' * 23);
        expect((await p1.db.allProfiles()).single.name, name);
        expect(puts(), 1);
      },
    );

    test('the server being offline at first: nothing is lost, the cut goes once when it is back', () async {
      await p1.addChild(name: _long30);
      server.offline = true;
      try {
        await p1.engine.syncOnce();
      } on Object {
        // offline: the round may report or throw; either way nothing is lost
      }
      server.offline = false;
      await p1.engine.syncOnce();
      await p1.engine.syncOnce();
      expect(server.children[kid]?['nickname'], _cut24);
      expect((await p1.db.allProfiles()).single.name, _long30);
    });

    test('a second phone that pulls the cut name never pushes it back or changes it', () async {
      await p1.addChild(name: _long30);
      await p1.engine.syncOnce();
      await p2.engine.syncOnce();
      await p2.engine.syncOnce();
      expect(server.calls.where((String c) => c == '$dev2:child-put'), isEmpty);
      expect((await p2.db.allProfiles()).single.name, _cut24);
    });
  });

  group('QA-B28 (open)', () {
    // QA-B28-1 (minor): the rule refuses the direction marks and controls, but a name made only of characters that draw
    // nothing is "ok", so a parent can save a child with a blank name that the family list and the child's picker
    // show as empty. U+200B is not white space for Dart's trim(); U+061C is the Arabic letter mark, a direction mark
    // the library comment ("the invisible direction marks") says is refused.
    test('QA-B28-1a: a name of invisible characters only is not ok', () {
      for (final String blank in <String>['​', '​​⁠', '⠀', 'ㅤ', '­']) {
        expect(
          validateChildName(blank),
          isNot(ChildNameProblem.ok),
          reason: 'U+${blank.codeUnitAt(0).toRadixString(16)}',
        );
        expect(fitChildNameForServer(blank), isEmpty, reason: 'nothing visible is left to send');
      }
    }, skip: _open);

    test('QA-B28-1b: the Arabic letter mark U+061C (a direction mark) is refused like U+200F', () {
      expect(validateChildName('נו؜עה'), ChildNameProblem.badChars);
    }, skip: _open);

    // QA-B28-2 (minor): a lone surrogate is not text. Dart's jsonEncode sends it as an escape, the gateway's pattern
    // takes it (no u flag), and the database driver turns it into U+FFFD, so the server holds a different name than the
    // phone and the next pull overwrites the phone's name with the replacement character.
    // QA-B28-3 (minor, design-director + app-developer): in the parent list the name and the legacy line share a row with
    // the "progress" and "remove" buttons, so on a 360-point phone the line gets a column of 86 points (65 at a text
    // scale of 1.3: 300 points tall, words cut in the middle: המשפח/ה, הראשוני/ם) and a 40-unit name is cut into columns of
    // four letters. Evidence: docs/qa/b28-verification.md (the list PNGs).
    testWidgets('QA-B28-3: the legacy line has room to be read on a phone', (WidgetTester tester) async {
      await loadAppFonts();
      final AppRig rig = AppRig();
      await rig.seedFinishedSetup(name: ('אָ' * 20));
      await rig.pump(tester, size: const Size(360, 740));
      await tester.tap(find.text(('אָ' * 20)));
      await tester.pumpAndSettle();
      await tester.tap(find.text(He.homeParents.text));
      await tester.pumpAndSettle();
      await tapDigits(tester, '${rig.gateQuestion.answer}');
      await tester.tap(find.text(He.pinOk.text));
      await tester.pumpAndSettle();
      await tapDigits(tester, testPin);
      await tester.tap(find.text(He.pinOk.text));
      await tester.pumpAndSettle();
      expect(find.byType(ParentArea), findsOneWidget);
      final Finder note = find.text(He.setupNameLegacyShortened.text);
      await tester.scrollUntilVisible(note, 100, scrollable: find.byType(Scrollable).first);
      expect(
        tester.getSize(note).width,
        greaterThanOrEqualTo(160),
        reason: 'a column of 86 points is 7 lines',
      );
    }, skip: _open);

    test('QA-B28-2: a lone surrogate is refused', () {
      expect(validateChildName('ab\uD800'), isNot(ChildNameProblem.ok));
      expect(validateChildName('ab\uDC00cd'), isNot(ChildNameProblem.ok));
      expect(fitChildNameForServer('ab\uD800'), 'ab');
    }, skip: _open);
  });
}
