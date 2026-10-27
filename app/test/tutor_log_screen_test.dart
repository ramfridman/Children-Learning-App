// What the helper said, in the parent area: the lines with the child they were said to, the usual message when a line
// was not used, and calm sentences when there is nothing or the server cannot be reached.
import 'package:flutter/material.dart' show Key, Scrollable, SizedBox;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:nitznutz/app/tutor_log_provider.dart';
import 'package:nitznutz/parent/tutor_log_screen.dart';
import 'package:nitznutz/strings/he.dart';

import 'support/app_harness.dart';
import 'support/harness.dart';

Future<AppRig> open(WidgetTester tester, List<TutorLogLine>? lines) async {
  final AppRig rig = AppRig(
    extraOverrides: <Override>[tutorLogProvider.overrideWith((Ref ref) async => lines)],
  );
  await rig.seedFinishedSetup();
  await rig.pump(tester);
  await tester.tap(find.text('נועה'));
  await tester.pumpAndSettle();
  await tester.tap(find.text(He.homeParents.text));
  await tester.pumpAndSettle();
  await tapDigits(tester, '${rig.gateQuestion.answer}');
  await tester.tap(find.text(He.pinOk.text));
  await tester.pumpAndSettle();
  await tapDigits(tester, testPin);
  await tester.tap(find.text(He.pinOk.text));
  await tester.pumpAndSettle();
  final Finder button = find.byKey(const Key('open-tutor-log'));
  await tester.scrollUntilVisible(button, 200, scrollable: find.byType(Scrollable).first);
  await tester.tap(button);
  await tester.pumpAndSettle();
  expect(find.byType(TutorLogScreen), findsOneWidget);
  return rig;
}

void main() {
  setUpAll(loadAppFonts);

  testWidgets(
    'it lists what was said with the child it was said to, and the usual message when no line was used',
    (WidgetTester tester) async {
      await open(tester, <TutorLogLine>[
        TutorLogLine(
          at: DateTime(2026, 11, 20, 10, 30),
          childId: 'p-1',
          source: 'cache',
          outcome: 'ok',
          line: 'בּוֹאוּ נִסְפֹּר יַחַד',
        ),
        TutorLogLine(
          at: DateTime(2026, 11, 20, 10, 20),
          childId: 'p-1',
          source: 'rule',
          outcome: 'timeout',
          line: null,
        ),
      ]);
      expect(find.text('בּוֹאוּ נִסְפֹּר יַחַד'), findsOneWidget);
      expect(find.text(He.tutorLogRule.text), findsOneWidget);
      expect(find.text('נועה'), findsWidgets, reason: 'the nickname of the child');
      expect(find.text(He.tutorLogHelp.text), findsOneWidget);
    },
  );

  testWidgets('with nothing said it says so, and when the server cannot be reached it says that', (
    WidgetTester tester,
  ) async {
    await open(tester, const <TutorLogLine>[]);
    expect(find.byKey(const Key('log-empty')), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('an unreachable server gives one calm sentence, not an error', (WidgetTester tester) async {
    await open(tester, null);
    expect(find.byKey(const Key('log-offline')), findsOneWidget);
    expect(find.text(He.tutorLogOffline.text), findsOneWidget);
  });
}
