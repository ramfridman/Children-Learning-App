// QA of Languages Band A (2026-11-07): the headless playthrough of the three real course packs (the model is playthrough_test.dart,
// which does the starter pack). For every lesson of each course, on each route a course serves, and every activity the lesson plays
// (its teach and hearing screens included): each wrong move gives the line of its tag, the help climbs a ladder of three and ends with
// only the right move left, "not sure" is welcome and not a mistake, the right move is taken, and the lesson reaches its celebration.
import 'package:flutter_test/flutter_test.dart';
import 'package:nitznutz/content/models.dart';
import 'package:nitznutz/content/pack_verify.dart';
import 'package:nitznutz/engine/course.dart';
import 'package:nitznutz/play/lesson_controller.dart';

import '../tool/pack_builder_lib.dart';
import 'support/fakes.dart';
import 'support/pack_fixtures.dart';

const String _languages = '../content/languages';

void main() {
  for (final String course in Course.languages) {
    test('$course: every lesson, every activity, every route: wrong, help, unsure, right, celebration', () async {
      final PackKey key = await newTestKey();
      final PackContent content = PackContent.fromPack(
        await verifyPack(
          (await buildPack(languageSource(course, _languages), key)).bytes,
          publicKey: key.publicKey,
        ),
      );
      final List<String> problems = <String>[];
      final List<AttemptRecord> written = <AttemptRecord>[];
      final Set<String> reachedTags = <String>{}, templates = <String>{}, actions = <String>{};
      int played = 0;
      final List<String?> routes = course == 'rus' ? <String?>['new', 'heritage'] : <String?>[null];

      LessonController start(Lesson lesson, String? route, int index) {
        final LessonController c = LessonController(
          content: content,
          lesson: lesson,
          profileId: 'p-1',
          route: route,
          clock: FixedClock(1793000000000),
          record: (AttemptRecord r) async => written.add(r),
        );
        for (int i = 0; i < index; i++) {
          c.next();
        }
        return c;
      }

      Future<bool> right(LessonController c) async {
        final Activity a = c.current;
        if (a.unscored && a is! SayItActivity) return true;
        if (a is SayItActivity) {
          if (a.hear) {
            c.hearDone();
          } else {
            await c.sayItDone();
          }
          return c.solved;
        }
        if (a is TapAnswerActivity && a.all) return (await c.chooseSet(a.correctIds)).correct;
        if (a is ChoiceActivity) {
          await c.chooseOption((a as ChoiceActivity).correctId);
          return true;
        }
        return (await c.submitPlacement(right: true)).correct;
      }

      List<Future<Outcome> Function(LessonController)> wrongMoves(Activity a) {
        if (a is TapAnswerActivity && a.all) {
          return <Future<Outcome> Function(LessonController)>[
            for (final ChoiceOption o in a.options)
              if (!a.correctIds.contains(o.id))
                (LessonController c) => c.chooseSet(<String>[...a.correctIds.take(1), o.id]),
          ];
        }
        if (a is ChoiceActivity) {
          final ChoiceActivity ch = a as ChoiceActivity;
          return <Future<Outcome> Function(LessonController)>[
            for (final ChoiceOption o in ch.options)
              if (o.id != ch.correctId) (LessonController c) => c.chooseOption(o.id),
          ];
        }
        if (a is SayItActivity) return const <Future<Outcome> Function(LessonController)>[];
        final Set<String> tags = a.engineTags;
        return <Future<Outcome> Function(LessonController)>[
          if (tags.isEmpty) (LessonController c) => c.submitPlacement(right: false),
          for (final String t in tags) (LessonController c) => c.submitPlacement(right: false, tag: t),
        ];
      }

      for (final Lesson lesson in content.lessons.values) {
        for (final String? route in routes) {
          final LessonController probe = start(lesson, route, 0);
          final int n = probe.items.length;
          if (n == 0) problems.add('${lesson.id}/$route: no activity');
          for (int i = 0; i < n; i++) {
            final Activity a = probe.items[i];
            final String where = '${lesson.id}/$route[$i] ${a.id} (${a.template})';
            templates.add(a.template);
            played++;
            try {
              if (a.unscored || a is SayItActivity) {
                final LessonController c = start(lesson, route, i);
                if (!await right(c)) problems.add('$where: the step cannot be ended');
                continue;
              }
              final bool isProbe = a.purpose == 'probe';
              final List<Future<Outcome> Function(LessonController)> wrong = wrongMoves(a);
              if (wrong.isEmpty) problems.add('$where: no wrong move to try');
              for (final Future<Outcome> Function(LessonController) move in wrong) {
                final LessonController c = start(lesson, route, i);
                final Outcome o = await move(c);
                if (o.correct) problems.add('$where: a wrong move was right');
                if (isProbe) continue;
                if (c.feedback != FeedbackKind.notYet) {
                  problems.add('$where: first wrong is not "not yet": ${c.feedback}');
                }
                final String exp = a.feedback.forIncorrect(o.tag.isEmpty ? null : o.tag).caption.toString();
                if (c.bubble.toString() != exp) problems.add('$where: line of tag "${o.tag}" not shown');
                if (o.tag.isNotEmpty) {
                  reachedTags.add(o.tag);
                  if (!content.tags.containsKey(o.tag)) {
                    problems.add('$where: tag ${o.tag} is not in the course catalogue');
                  }
                }
                if (c.finished) problems.add('$where: finished after one wrong move');
              }
              if (isProbe) {
                final LessonController c = start(lesson, route, i);
                await c.unsure();
                continue;
              }
              if (wrong.isNotEmpty) {
                final LessonController ladder = start(lesson, route, i);
                final int attempts = a.optionCount == 2 ? 2 : a.maxAttempts;
                for (int k = 0; k < attempts; k++) {
                  await wrong[k % wrong.length](ladder);
                }
                if (ladder.errors != attempts) problems.add('$where: errors ${ladder.errors} != $attempts');
                if (!ladder.guided) problems.add('$where: not guided after $attempts mistakes');
                if (a.hints.length != 3) problems.add('$where: ${a.hints.length} hints');
                if (a.hints.isNotEmpty && ladder.hintLevel != a.hints.length) {
                  problems.add('$where: ladder top not reached (${ladder.hintLevel})');
                }
                if (ladder.hintAction != null) actions.add(ladder.hintAction!.name);
                if (!await right(ladder)) problems.add('$where: a guided child cannot answer');
              }
              final LessonController lamp = start(lesson, route, i);
              for (int h = 1; h <= a.hints.length + 1; h++) {
                lamp.showHint();
                final int want = h <= a.hints.length ? h : a.hints.length;
                if (lamp.hintLevel != want || lamp.hintShown != lamp.hintLevel) {
                  problems.add('$where: lamp level $h gives ${lamp.hintLevel}');
                }
                if (lamp.hintAction != null) actions.add(lamp.hintAction!.name);
              }
              final LessonController unsure = start(lesson, route, i);
              final int before = written.length;
              await unsure.unsure();
              if (written.length != before + 1 || written.last.result != 'unsure') {
                problems.add('$where: not sure writes ${written.length - before} rows');
              }
              if (unsure.errors != 0) problems.add('$where: not sure counted as a mistake');
            } catch (e, st) {
              problems.add('$where: THREW $e ${st.toString().split("\n").take(3).join(" | ")}');
            }
          }
          final LessonController through = start(lesson, route, 0);
          for (int i = 0; i < n; i++) {
            try {
              if (!await right(through)) {
                problems.add('${lesson.id}/$route[$i]: the right move did not solve it');
              }
            } catch (e) {
              problems.add(
                '${lesson.id}/$route[$i] ${through.current.id} (${through.current.template}) THREW in the final walk: $e',
              );
            }
            through.next();
          }
          if (!through.finished) problems.add('${lesson.id}/$route: not finished after the last item');
        }
      }
      final Set<String> authored = <String>{
        for (final Activity a in content.activities.values) ...a.engineTags,
      };
      final Set<String> unreached = authored.difference(reachedTags);
      // ignore: avoid_print
      print(
        'QA-PLAY $course: ${content.lessons.length} lessons, $played activity visits, templates $templates, '
        'tags ${reachedTags.length}/${authored.length}, help $actions, unreached $unreached, problems ${problems.length}',
      );
      for (final String p in problems.take(60)) {
        // ignore: avoid_print
        print('QA-PLAY-PROBLEM $course $p');
      }
      expect(problems, isEmpty);
    });
  }
}
