// QA, B-42 (docs/milestones/B42.md section 8 row 7), the welcome inside the real app, second part: never on top of a land or
// the phone's home button, the warm-up deciding the middle sentence for a Band B child, and the pause between two clips by
// band. The real app, the real pack, a fake player.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nitznutz/child/land_screen.dart';
import 'package:nitznutz/strings/he.dart';
import 'package:nitznutz/world/welcome_table.dart';

import 'support/app_harness.dart';
import 'support/companion_fixtures.dart';
import 'support/harness.dart';
import 'support/voice_fixtures.dart';

late WelcomeTable table;

Future<void> _start(WidgetTester tester) async {
  for (int i = 0; i < 20; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

String _bubble(WidgetTester tester) => tester
    .widget<Text>(find.descendant(of: find.byKey(const Key('bubble-body')), matching: find.byType(Text)))
    .data!
    .replaceAll(RegExp(r'[\u2066-\u2069\u200E\u200F]'), '');

bool _isOwn(WidgetTester tester) => _bubble(tester).endsWith(He.homeBubbleNoName.text);

Future<void> _toMap(WidgetTester tester, AppRig rig) async {
  await rig.pump(tester, reduceMotion: true);
  await tester.tap(find.text('נועה'));
  await tester.pump();
}

/// What the bubble says, one sentence after the other, until it is its own again.
Future<List<String>> _readWelcome(WidgetTester tester) async {
  final List<String> said = <String>[];
  String last = '';
  for (int ms = 0; ms < 12000; ms += 100) {
    if (find.byKey(const Key('bubble-body')).evaluate().isEmpty) break;
    final String now = _bubble(tester);
    if (now != last) {
      last = now;
      said.add(now);
    }
    await tester.pump(const Duration(milliseconds: 100));
  }
  return said;
}

void main() {
  setUpAll(() async {
    await loadAppFonts();
    table = WelcomeTable.parse(File('assets/lines/welcome.json').readAsStringSync());
  });

  List<String> welcomeIds() => <String>[for (final String id in table.lineIds) id.substring('vo:'.length)];

  group('never on top of something else, and back on the map it comes (B42.md 2.1)', () {
    testWidgets(
      'the app leaves the front (the home button, a call): the welcome stops, does not start again, and the day stays used',
      (WidgetTester tester) async {
        final AppRig rig = AppRig(welcome: true);
        await rig.seedFinishedSetup();
        await _toMap(tester, rig);
        await _start(tester);
        expect(_isOwn(tester), isFalse, reason: 'the welcome is on');
        tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
        await tester.pump();
        tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
        await tester.pump();
        expect(_isOwn(tester), isTrue);
        await tester.pump(const Duration(seconds: 12));
        expect(_isOwn(tester), isTrue, reason: 'it does not start again');
        expect(await rig.db.welcomeDayOf('p-1'), isNotNull);
      },
    );

    testWidgets(
      'a welcome that could not come (the rest hours) comes the next time the map is shown, once the time is over',
      (WidgetTester tester) async {
        final AppRig rig = AppRig(welcome: true, clockMs: DateTime(2026, 10, 28, 22).millisecondsSinceEpoch);
        await rig.seedFinishedSetup();
        await _toMap(tester, rig);
        await _start(tester);
        expect(_isOwn(tester), isTrue, reason: 'in the rest hours the map is the ordinary map');
        expect(await rig.db.welcomeDayOf('p-1'), isNull, reason: 'and the day is not used up');
        rig.clock.advance(const Duration(hours: 12));
        final Finder tap = find.byKey(const Key('land-tap-counting'));
        await tester.ensureVisible(tap);
        await tester.pump();
        await tester.tap(tap);
        await tester.pumpAndSettle();
        expect(find.byType(LandScreen), findsOneWidget);
        tester.state<NavigatorState>(find.byType(Navigator).first).pop();
        await tester.pumpAndSettle();
        await _start(tester);
        expect(
          await rig.db.welcomeDayOf('p-1'),
          isNotNull,
          reason: 'back on the map the welcome of the day is given',
        );
      },
    );
  });

  group('the band decides the pace and the warm-up decides the sentence (B42.md 2.2, 2.5)', () {
    testWidgets(
      'a Band A child on the first day hears the topic of the stop; a Band B child whose warm-up is due hears the land',
      (WidgetTester tester) async {
        final Map<int, String> middle = <int, String>{};
        for (final int band in <int>[0, 1]) {
          final AppRig rig = AppRig(welcome: true);
          await rig.seedFinishedSetup(ageBand: band, warmUp: true);
          await _toMap(tester, rig);
          await _start(tester);
          final List<String> said = await _readWelcome(tester);
          expect(said, hasLength(4), reason: 'band $band: $said');
          middle[band] = said[1];
          await tester.pumpWidget(const SizedBox());
          await tester.pump();
        }
        expect(
          middle[0],
          table.text('vo:welcome.topic.counting.count'),
          reason: 'Band A: no warm-up, the topic of NUM-A-01',
        );
        expect(
          middle[1],
          table.text('vo:welcome.land.counting'),
          reason: 'Band B with the warm-up due: where we start',
        );
      },
    );

    testWidgets('the pause between two clips is about 500 ms for Band A and 300 ms for Band C', (
      WidgetTester tester,
    ) async {
      final Map<int, int> gap = <int, int>{};
      for (final int band in <int>[0, 2]) {
        final FakePlayer player = FakePlayer()..endsAfter = const Duration(milliseconds: 700);
        final AppRig rig = AppRig(
          welcome: true,
          player: player,
          characters: await sourceWithLines(welcomeIds()),
        );
        await rig.seedFinishedSetup(ageBand: band);
        await _toMap(tester, rig);
        int firstAt = -1;
        int secondAt = -1;
        for (int ms = 0; ms < 8000 && secondAt < 0; ms += 10) {
          await tester.pump(const Duration(milliseconds: 10));
          if (player.plays >= 1 && firstAt < 0) firstAt = ms;
          if (player.plays >= 2 && secondAt < 0) secondAt = ms;
        }
        expect(firstAt, greaterThanOrEqualTo(0), reason: 'band $band: the first clip played');
        expect(secondAt, greaterThan(firstAt), reason: 'band $band: the second clip played');
        gap[band] = secondAt - firstAt - 700;
        await tester.pumpWidget(const SizedBox());
        await tester.pump(const Duration(seconds: 12));
      }
      expect(gap[0]!, inInclusiveRange(450, 560), reason: 'Band A: about 500 ms, was ${gap[0]}');
      expect(gap[2]!, inInclusiveRange(250, 360), reason: 'Band C: about 300 ms, was ${gap[2]}');
    });
  });
}
