// The app opened on a language course's home over the fixture packs, with a real in-memory database, for the tests that play a visit
// from the home (L-course).
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nitznutz/child/course_home.dart';
import 'package:nitznutz/child/home_screen.dart';
import 'package:nitznutz/parent/language_settings.dart';
import 'package:nitznutz/parent/parent_rules.dart';
import 'package:nitznutz/tutor/tutor.dart';

import 'app_harness.dart';
import 'course_history.dart';
import 'course_packs.dart';
import 'l4_golden.dart' show voRefsOf, waitFor;
import 'language_voice.dart';
import 'voice_fixtures.dart';

/// The app with the fixture packs of [on] installed and on for the child, [history] written first (before the app reads anything), and
/// the map open. Returns the rig; the child is chosen.
Future<AppRig> courseApp(
  WidgetTester tester,
  List<String> on, {
  Size size = const Size(852, 393),
  Future<void> Function(AppRig rig)? history,
  Map<String, LanguageSwitches>? switches,
  ParentRules? rules,
  TutorClient? tutor,
  int? clockMs,
}) async {
  final Set<String> refs = <String>{for (final String c in on) ...voRefsOf(courseFixture(c))};
  final AppRig rig = AppRig(
    characters: await languageVoiceSource(refs),
    player: FakePlayer()..endsAfter = const Duration(milliseconds: 150),
    rules: rules,
    tutor: tutor,
    clockMs: clockMs,
  )..languagePacks = fixturePacks(on);
  await rig.seedFinishedSetup(id: courseKid);
  if (history != null) await history(rig);
  FamilyLanguages f = const FamilyLanguages();
  for (final String c in on) {
    f = f.withSwitches(courseKid, c, switches?[c] ?? const LanguageSwitches(on: true))!;
  }
  await rig.db.putSetting(languagesSettingKey, f.encode());
  await rig.pump(tester, size: size);
  await tester.tap(find.text('נועה'));
  await tester.pumpAndSettle();
  expect(find.byType(HomeScreen), findsOneWidget);
  return rig;
}

/// From the map to the home of [course] (through the doors when several languages are on).
Future<void> openCourse(WidgetTester tester, String course, {bool doors = false}) async {
  final Finder tap = find.byKey(const Key('land-tap-languages'));
  await tester.ensureVisible(tap);
  await tester.pumpAndSettle();
  await tester.tap(tap);
  await tester.pumpAndSettle();
  if (doors) {
    await tester.tap(find.byKey(Key('door-$course')));
    await tester.pump(const Duration(milliseconds: 700));
    await tester.pumpAndSettle();
  }
  expect(find.byType(CourseHomeScreen), findsOneWidget);
}

/// Lets the visit settle: time passes in steps, as lessons with a companion cannot use `pumpAndSettle`.
Future<void> settle(WidgetTester tester, {int ms = 3000}) => waitFor(tester, ms);

/// Touches the right (`o1`) or a wrong (`o2`) answer of the activity on screen and lets the lesson move on.
Future<void> answer(WidgetTester tester, {bool right = true}) async {
  await tester.tap(find.byKey(Key(right ? 'option-o1' : 'option-o2')));
  await settle(tester, ms: 3000);
}
