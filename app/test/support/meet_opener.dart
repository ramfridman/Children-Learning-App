// The opener of a Meet set (what the guide says before the first new word of a lesson, `teach.opener` of a course) for the tests that open a
// lesson and want the screen where the first word is being said. The beats are paced by the fake clock, so a test never counts the opener's
// milliseconds: it waits until the speaking badge lights, which only the word's beats raise (the opener has none).
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nitznutz/content/models.dart';
import 'package:nitznutz/play/speaking_badge.dart';

/// The badge of a picture that is saying its word now (the badge is always in the tree, and lit only while a word is said).
final Finder badgeLit = find.byWidgetPredicate((Widget w) => w is SpeakingBadge && w.on);

/// The Meet screen a new learner meets first in lesson [lessonId], when that screen says an opener; null when the lesson starts with
/// anything else (a story, an item, a screen of the old kind).
SayItActivity? openerScreenOf(PackContent pack, String lessonId) {
  final List<Activity> items = pack.itemsFor(pack.lessons[lessonId]!, route: 'new');
  if (items.isEmpty || items.first is! SayItActivity) return null;
  final SayItActivity first = items.first as SayItActivity;
  return first.meet?.opener == null ? null : first;
}

/// Lets the opener be said: pumps (100 ms steps, at most [maxMs]) until the guide is saying the word and its badge is lit.
Future<void> untilWordBeat(WidgetTester t, {int maxMs = 12000}) async {
  for (int spent = 0; spent < maxMs && badgeLit.evaluate().isEmpty; spent += 100) {
    await t.pump(const Duration(milliseconds: 100));
  }
  expect(badgeLit, findsWidgets, reason: 'the opener was said and the word begins');
}
