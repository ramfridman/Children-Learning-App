// The fixture packs of the course screens are valid packs of their course: they pass the validator that the real packs pass, and their
// path, probes and placement are what the screens and the tests rely on.
import 'package:flutter_test/flutter_test.dart';
import 'package:nitznutz/content/models.dart';
import 'package:nitznutz/content/pack_validation.dart';
import 'package:nitznutz/content/schema.dart' show Problem;
import 'package:nitznutz/world/language_placement.dart';
import 'package:nitznutz/world/placement.dart' show landPath;

import 'support/course_packs.dart';

void main() {
  for (final String course in <String>['eng', 'heb', 'rus']) {
    group('the fixture pack of $course', () {
      test('passes the validator of a language pack', () {
        final p = courseFixture(course).pack;
        final List<Problem> problems = validatePack(manifest: p.manifest, docs: p.docs, files: p.files);
        expect(<String>[for (final Problem x in problems) '${x.path}: ${x.message}'], isEmpty);
      });

      test('has a path of lessons, in order, and a placement game whose probes are in no lesson', () {
        final PackContent c = courseContent(course);
        final List<Lesson> path = landPath(c, 'languages');
        expect(path.length, inInclusiveRange(5, 7));
        expect(<int>[
          for (final Lesson l in path) l.sequence,
        ], orderedEquals(<int>[for (int i = 1; i <= path.length; i++) i]));
        expect(c.course, course);
        expect(c.packId, 'lang-$course');
        final Set<String> inLessons = <String>{for (final Lesson l in path) ...l.itemIds};
        final game = placementGameOf(c)!;
        for (final s in c.placement!.strands) {
          for (final level in s.levels) {
            for (final String id in level.items) {
              expect(inLessons, isNot(contains(id)), reason: '$id is a probe, not a lesson item');
              expect(c.activities[id]!.isLanguage, isTrue);
            }
          }
        }
        expect(game.next(), isNotNull);
      });
    });
  }
}
