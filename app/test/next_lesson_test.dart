import 'package:flutter_test/flutter_test.dart';
import 'package:nitznutz/content/models.dart';
import 'package:nitznutz/world/next_lesson.dart';

import 'support/starter.dart';

void main() {
  late PackContent content;
  setUpAll(() async => content = await loadStarter());

  List<String> path() => <String>[
    for (final Lesson l in content.lessons.values)
      if (l.skillIds.any((String s) => content.skills[s]?.domain == 'numbers')) l.id,
  ]..sort((String a, String b) => content.lessons[a]!.sequence.compareTo(content.lessons[b]!.sequence));

  test('a child who has done nothing starts with the butterflies, the first adventure', () {
    expect(nextLessonId(content: content, domain: 'numbers', finished: const <String, int>{}), 'butterflies');
  });

  test('each finished lesson moves the island on to the next one on the path, in order', () {
    final Map<String, int> done = <String, int>{};
    final List<String> seen = <String>[];
    for (int i = 0; i < path().length; i++) {
      final String next = nextLessonId(content: content, domain: 'numbers', finished: done)!;
      seen.add(next);
      done[next] = 1;
    }
    expect(seen, path());
    expect(seen.toSet().length, seen.length, reason: 'no lesson is offered twice before all are done');
  });

  test('when everything is done the path goes round: the lesson finished fewest times comes next', () {
    final Map<String, int> done = <String, int>{for (final String id in path()) id: 2}..['giving'] = 1;
    expect(nextLessonId(content: content, domain: 'numbers', finished: done), 'giving');
  });

  test('the pack gives every lesson a different place on the path, and the path leaves nothing out', () {
    final List<int> places = <int>[for (final String id in path()) content.lessons[id]!.sequence];
    expect(places.toSet().length, places.length);
    expect(places, everyElement(lessThan(1000)));
    expect(path().length, content.lessons.values.where((Lesson l) => l.skillIds.any((String s) => content.skills[s]?.domain == 'numbers')).length);
  });

  test('a land with no lesson has no next lesson', () {
    expect(nextLessonId(content: content, domain: 'cs', finished: const <String, int>{}), isNull);
  });
}
