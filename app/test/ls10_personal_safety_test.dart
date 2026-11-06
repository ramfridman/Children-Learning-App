// The safeguards of the scripted personal turns (docs/languages/frame.md section 5.2; L4), proved on the lesson screen with its real
// database: a child touches a card (or passes) and nothing is stored, logged or queued to be sent, whatever was touched; the parent's
// switch for personal questions is read from the family's settings; and no personal turn can be scored or placed.
import 'package:flutter/foundation.dart';

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:nitznutz/app/language_providers.dart';
import 'package:nitznutz/parent/language_settings.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nitznutz/content/pack_validation.dart';
import 'package:nitznutz/data/app_database.dart';

import 'support/golden_comparator.dart';
import 'support/harness.dart';
import 'support/l4_golden.dart';
import 'support/language_content.dart';
import 'support/language_screens.dart' show langKid;

const List<String> _pictures = <String>['apple', 'banana', 'cat'];

LangPack _pack() {
  final LangPack p = LangPack()..addPictures(_pictures);
  p.add(
    puppetJson(
      id: 'mine',
      mode: 'personal',
      topic: 'likes',
      options: <Map<String, Object?>>[
        <String, Object?>{'id': 'o1', 'label': 'apple', 'sprite': 'asset:apple', 'clip': 'vo:eng.f.apple'},
        <String, Object?>{'id': 'o2', 'label': 'banana', 'sprite': 'asset:banana', 'clip': 'vo:eng.f.banana'},
      ],
    ),
  );
  return p;
}

void main() {
  setUpAll(() async {
    await loadAppFonts();
    useTolerantGoldens(0.03);
  });

  for (final String how in <String>['a card', 'the pass']) {
    testWidgets('$how: nothing is written, logged or queued', (WidgetTester t) async {
      final List<String> logged = <String>[];
      final DebugPrintCallback old = debugPrint;
      debugPrint = (String? m, {int? wrapWidth}) => logged.add(m ?? '');
      final rig = await openLesson(t, _pack(), 'mine', const Size(852, 393));
      await t.tap(find.byKey(Key(how == 'a card' ? 'card-o2' : 'personal-pass')));
      await waitFor(t, 2500);
      debugPrint = old;

      final AppDatabase db = rig.db;
      expect(
        await db.attemptsOf(langKid),
        isEmpty,
        reason: 'no attempt row: no response, no tag, no evidence',
      );
      expect(await db.unreadAlertCount(), 0);
      final List<LocalEvent> events = await db.recentEvents(limit: 200);
      expect(
        events.where(
          (LocalEvent e) => '${e.kind} ${e.detail}'.contains('mine') || e.detail.contains('banana'),
        ),
        isEmpty,
      );
      expect(
        logged.where((String l) => l.contains('banana') || l.contains('card-o2') || l.contains('o2')),
        isEmpty,
      );
      expect(
        logged.where((String l) => l.contains('mistake')),
        isEmpty,
        reason: 'the turn is not a mistake, nor a move',
      );
    });
  }

  testWidgets('with the parent\'s switch off the cards never appear and nothing is asked', (
    WidgetTester t,
  ) async {
    final rig = await openLesson(t, _pack(), 'mine', const Size(852, 393), personal: false);
    expect(find.byKey(const Key('card-o1')), findsNothing);
    expect(find.byKey(const Key('personal-pass')), findsNothing);
    await waitFor(t, 2500);
    expect(await rig.db.attemptsOf(langKid), isEmpty);
  });

  testWidgets('"show me" before any card writes nothing: a personal turn offers no lamp and no eye at all', (
    WidgetTester t,
  ) async {
    final rig = await openLesson(t, _pack(), 'mine', const Size(852, 393));
    expect(find.byKey(const Key('lesson-show-me')), findsNothing);
    expect(find.byKey(const Key('lesson-hint')), findsNothing);
    final Finder eye = find.byKey(const Key('lesson-show-me'));
    if (eye.evaluate().isNotEmpty) {
      await t.tap(eye);
      await waitFor(t, 500);
    }
    expect(
      await rig.db.attemptsOf(langKid),
      isEmpty,
      reason: 'a personal turn leaves no attempt row, "unsure" included',
    );
  });

  testWidgets('with the switch off there is no eye during the wait either, and nothing is written', (
    WidgetTester t,
  ) async {
    final rig = await openLesson(t, _pack(), 'mine', const Size(852, 393), personal: false, settle: 300);
    expect(find.byKey(const Key('lesson-show-me')), findsNothing);
    await waitFor(t, 2500);
    expect(await rig.db.attemptsOf(langKid), isEmpty);
  });

  testWidgets('the switch fails closed: while the family settings are loading, no card is asked', (
    WidgetTester t,
  ) async {
    await openLesson(
      t,
      _pack(),
      'mine',
      const Size(852, 393),
      overrides: <Override>[languagesProvider.overrideWith(_NeverLoaded.new)],
    );
    expect(find.byKey(const Key('card-o1')), findsNothing);
    expect(find.byKey(const Key('personal-pass')), findsNothing);
  });

  test('a personal turn can be neither scored nor placed: the validator refuses a probe that is one', () {
    final LangPack p = _pack();
    p.activity('mine')['purpose'] = 'probe';
    final List<String> m = <String>[
      for (final x in validatePack(manifest: p.pack.manifest, docs: p.pack.docs, files: p.pack.files))
        '${x.path}: ${x.message}',
    ];
    expect(m, contains(contains('purpose: a personal turn is never scored')));
  });
}

/// The family's language settings, never read: the provider stays loading.
class _NeverLoaded extends LanguagesNotifier {
  @override
  Future<FamilyLanguages> build() => Completer<FamilyLanguages>().future;
}
