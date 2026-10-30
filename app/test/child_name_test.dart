// Board B-28: one rule for a child's first name on the phone and on the server (testvectors/child-name.json, which the
// gateway is tested against too: supabase/functions/child_name_vectors_test.ts). 1 to 24 UTF-16 code units, the way the
// server's pattern counts, never graphemes; no angle brackets, controls or invisible direction marks.
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nitznutz/data/app_database.dart';
import 'package:nitznutz/data/child_name.dart';
import 'package:nitznutz/design/components.dart';
import 'package:nitznutz/parent/child_form.dart';
import 'package:nitznutz/parent/parent_area.dart';
import 'package:nitznutz/strings/he.dart';

import 'support/app_harness.dart';
import 'support/harness.dart';

typedef _Vector = ({String name, String value, int units, ChildNameProblem? reason, bool appOnly});

final Map<String, Object?> _file =
    jsonDecode(File('../testvectors/child-name.json').readAsStringSync()) as Map<String, Object?>;

List<_Vector> _vectors(String key) => <_Vector>[
  for (final Map<String, Object?> v in (_file[key]! as List<Object?>).cast<Map<String, Object?>>())
    (
      name: v['name']! as String,
      value: v['value']! as String,
      units: v['units']! as int,
      reason: v['reason'] == null ? null : ChildNameProblem.values.byName(v['reason']! as String),
      appOnly: v['appOnly'] == true,
    ),
];

final RegExp _server = RegExp(_file['server_pattern']! as String);

const String _letters30 = 'abcdefghijklmnopqrstuvwxyzabcd';
const String _flower = '\u{1F338}';

Future<AppRig> _openArea(WidgetTester tester, {String name = 'נועה'}) async {
  final AppRig rig = AppRig();
  await rig.seedFinishedSetup(name: name);
  await rig.pump(tester);
  await tester.tap(find.text(name));
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
  return rig;
}

Future<void> _openForm(WidgetTester tester) async {
  final Finder add = find.text(He.areaAddChild.text);
  await tester.scrollUntilVisible(add, 200, scrollable: find.byType(Scrollable).first);
  await tester.tap(add);
  await tester.pumpAndSettle();
  expect(find.byType(ChildFormScreen), findsOneWidget);
}

bool _canSave(WidgetTester tester) =>
    tester.widget<ParentButton>(find.widgetWithText(ParentButton, He.setupSave.text)).onPressed != null;

TextEditingValue _typed(String text) => TextEditingValue(
  text: text,
  selection: TextSelection.collapsed(offset: text.length),
);

void main() {
  group('the shared vectors (testvectors/child-name.json)', () {
    test('the app\'s limit is the server\'s, and every vector is as long as it says in UTF-16 units', () {
      expect(childNameMaxLength, _file['max_utf16_units']);
      for (final _Vector v in <_Vector>[
        ..._vectors('accept'),
        ..._vectors('reject'),
        ..._vectors('clientOnly'),
      ]) {
        expect(v.value.length, v.units, reason: v.name);
      }
    });

    test('every accepted name is ok, and goes to the server as it is', () {
      final List<_Vector> accept = _vectors('accept');
      expect(accept.length, greaterThanOrEqualTo(7));
      for (final _Vector v in accept) {
        expect(validateChildName(v.value), ChildNameProblem.ok, reason: v.name);
        expect(fitChildNameForServer(v.value), v.value, reason: v.name);
        expect(_server.hasMatch(v.value), isTrue, reason: v.name);
      }
    });

    test('every rejected name has its reason, and the server refuses the ones that are not app-only', () {
      final List<_Vector> reject = _vectors('reject');
      expect(reject.where((_Vector v) => v.appOnly).length, greaterThanOrEqualTo(4));
      for (final _Vector v in reject) {
        expect(validateChildName(v.value), v.reason, reason: v.name);
        expect(
          _server.hasMatch(v.value),
          v.appOnly,
          reason: '${v.name}: appOnly means the server takes it today',
        );
      }
      for (final _Vector v in _vectors('clientOnly')) {
        expect(validateChildName(v.value), v.reason, reason: v.name);
      }
    });

    test('whatever a name holds, what is sent is empty or a nickname the server takes', () {
      for (final _Vector v in <_Vector>[
        ..._vectors('accept'),
        ..._vectors('reject'),
        ..._vectors('clientOnly'),
      ]) {
        final String sent = fitChildNameForServer(v.value);
        if (sent.isEmpty) continue;
        expect(_server.hasMatch(sent), isTrue, reason: v.name);
        expect(validateChildName(sent), ChildNameProblem.ok, reason: v.name);
      }
    });
  });

  group('validateChildName', () {
    test('trims first: spaces around a name do not count, spaces alone are empty', () {
      expect(validateChildName('  נועה  '), ChildNameProblem.ok);
      expect(validateChildName('${'a' * 24}  '), ChildNameProblem.ok);
      expect(validateChildName(' \n '), ChildNameProblem.empty);
    });

    test('counts UTF-16 units, not letters: an emoji is two', () {
      expect(validateChildName('${'a' * 22}$_flower'), ChildNameProblem.ok);
      expect(validateChildName('${'a' * 23}$_flower'), ChildNameProblem.tooLong);
    });
  });

  group('fitChildNameForServer (names saved before B-28 could be 40 long)', () {
    test('cuts to 24 units', () => expect(fitChildNameForServer(_letters30), _letters30.substring(0, 24)));

    test('never splits a surrogate pair', () {
      expect(fitChildNameForServer('${'a' * 23}${_flower}bc'), 'a' * 23);
      expect(fitChildNameForServer('${'a' * 22}${_flower}bc'), '${'a' * 22}$_flower');
    });

    test('drops the refused characters and trims, also after the cut', () {
      expect(fitChildNameForServer('  נועה <3>  '), 'נועה 3');
      expect(fitChildNameForServer('נו\u202eעה\u0085'), 'נועה');
      expect(fitChildNameForServer('${'a' * 23} bbbb'), 'a' * 23);
    });

    test('nothing left is empty', () {
      expect(fitChildNameForServer('<<>>'), '');
      expect(fitChildNameForServer('   '), '');
    });
  });

  group('the length formatter of the form', () {
    const ChildNameLengthFormatter f = ChildNameLengthFormatter();

    test('a 25th unit typed at the end is not taken', () {
      final TextEditingValue full = _typed('a' * 24);
      expect(f.formatEditUpdate(full, _typed('${'a' * 24}b')), full);
    });

    test('a long paste is cut to 24 units, the cursor kept inside the text', () {
      final TextEditingValue out = f.formatEditUpdate(TextEditingValue.empty, _typed(_letters30));
      expect(out.text, _letters30.substring(0, 24));
      expect(out.selection, const TextSelection.collapsed(offset: 24));
    });

    test('a paste cut inside a surrogate pair drops the whole pair', () {
      final TextEditingValue out = f.formatEditUpdate(
        TextEditingValue.empty,
        _typed('${'a' * 23}${_flower}c'),
      );
      expect(out.text, 'a' * 23);
    });

    test('a name within the limit passes untouched', () {
      final TextEditingValue v = _typed('נועה');
      expect(identical(f.formatEditUpdate(TextEditingValue.empty, v), v), isTrue);
    });
  });

  group('the child form', () {
    setUpAll(loadAppFonts);

    testWidgets('25 letters typed: 24 get in, the counter says 24/24, the limit is said, and 24 are saved', (
      WidgetTester tester,
    ) async {
      final AppRig rig = await _openArea(tester);
      await _openForm(tester);
      expect(find.text('0/24'), findsOneWidget, reason: 'the counter counts UTF-16 units');
      expect(find.text(He.setupNameTooLong.text), findsNothing);
      expect(_canSave(tester), isFalse, reason: 'an empty name cannot be saved');

      await tester.enterText(find.byType(TextField), '${'a' * 24}b');
      await tester.pump();
      expect(tester.widget<TextField>(find.byType(TextField)).controller!.text, 'a' * 24);
      expect(find.text('24/24'), findsOneWidget);
      expect(find.text(He.setupNameTooLong.text), findsOneWidget);
      expect(_canSave(tester), isTrue);

      await tester.tap(find.text(He.setupSave.text));
      await tester.pumpAndSettle();
      expect((await rig.db.allProfiles()).map((Profile p) => p.name), contains('a' * 24));
    });

    testWidgets('a name of 25 units can never be saved, however it got into the field', (
      WidgetTester tester,
    ) async {
      await _openArea(tester);
      await _openForm(tester);
      tester.widget<TextField>(find.byType(TextField)).controller!.text = 'a' * 25;
      await tester.pump();
      expect(find.text('25/24'), findsOneWidget);
      expect(find.text(He.setupNameTooLong.text), findsOneWidget);
      expect(_canSave(tester), isFalse);
    });

    testWidgets('an emoji that would end at unit 25 is not let in by halves', (WidgetTester tester) async {
      await _openArea(tester);
      await _openForm(tester);
      await tester.enterText(find.byType(TextField), '${'a' * 23}$_flower');
      await tester.pump();
      expect(tester.widget<TextField>(find.byType(TextField)).controller!.text, 'a' * 23);
      expect(find.text('23/24'), findsOneWidget);
      expect(_canSave(tester), isTrue);
    });

    testWidgets('an angle bracket or an invisible mark says why, and the name cannot be saved', (
      WidgetTester tester,
    ) async {
      await _openArea(tester);
      await _openForm(tester);
      for (final String bad in <String>['נו<עה', 'נועה>', 'נו\u202eעה', 'נו\u200fעה']) {
        await tester.enterText(find.byType(TextField), bad);
        await tester.pump();
        expect(find.text(He.setupNameBadChars.text), findsOneWidget, reason: bad);
        expect(find.text(He.setupNameTooLong.text), findsNothing, reason: bad);
        expect(_canSave(tester), isFalse, reason: bad);
      }
      await tester.enterText(find.byType(TextField), 'נועה');
      await tester.pump();
      expect(find.text(He.setupNameBadChars.text), findsNothing);
      expect(_canSave(tester), isTrue);
    });

    testWidgets('spaces alone cannot be saved, and nothing is said about them', (WidgetTester tester) async {
      await _openArea(tester);
      await _openForm(tester);
      await tester.enterText(find.byType(TextField), '   ');
      await tester.pump();
      expect(_canSave(tester), isFalse);
      expect(find.text(He.setupNameBadChars.text), findsNothing);
      expect(find.text(He.setupNameTooLong.text), findsNothing);
    });
  });

  group('the parent area\'s list of children', () {
    setUpAll(loadAppFonts);

    testWidgets('a child saved before B-28 with a name over 24 units is told the family account has 24', (
      WidgetTester tester,
    ) async {
      await _openArea(tester, name: _letters30);
      final Finder note = find.text(He.setupNameLegacyShortened.text);
      await tester.scrollUntilVisible(note, 200, scrollable: find.byType(Scrollable).first);
      expect(note, findsOneWidget);
      expect(find.text(_letters30), findsWidgets, reason: 'the name on this phone is untouched');
      await tester.tap(find.byTooltip(He.areaLockNow.text));
      await tester.pumpAndSettle();
    });

    testWidgets('a name within the limit has no such line', (WidgetTester tester) async {
      await _openArea(tester);
      await tester.scrollUntilVisible(
        find.text(He.areaAddChild.text),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text(He.setupNameLegacyShortened.text), findsNothing);
      await tester.tap(find.byTooltip(He.areaLockNow.text));
      await tester.pumpAndSettle();
    });
  });
}
