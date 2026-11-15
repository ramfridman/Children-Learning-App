// QA of L7 (2026-11-15), criterion 2 of docs/milestones/L7.md section 6: the headless playthrough of the FIRST lesson of each real course as
// a complete beginner of 3, 5 and 7 (the age decides the look and the cap on the answer options, nothing else). Nothing is played by ear: the
// lesson's activities are read in the order the child meets them and the rules are checked on them.
//
//  - the parts come as Recall (at most 2 scored items before the first Meet screen, and only words the child may know), Meet, Find, Use;
//  - no scored item asks a word that was not met first, and no picture option on a scored screen is a word not met (Hebrew: unless the
//    course marks the word `everyday`);
//  - each new word's first Find has 2 choices (before and after the age's cap);
//  - each new word is heard at least 8 times in its lesson (counted below, the conservative way);
//  - in English and Russian the Hebrew meaning is said exactly once per new word (on its Meet screen) and never in a prompt of the lesson.
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:nitznutz/content/models.dart';
import 'package:nitznutz/content/pack_verify.dart';
import 'package:nitznutz/engine/course.dart';
import 'package:nitznutz/play/choice_cap.dart';
import 'package:nitznutz/play/first_meeting.dart';

import '../tool/pack_builder_lib.dart';
import 'support/pack_fixtures.dart';

const String _languages = '../content/languages';

/// The age's cap on answer options (P1 and P2 three, P3 four, P4 five).
const Map<int, int> _capOfAge = <int, int>{3: 3, 5: 4, 7: 5};

/// The Hebrew words a child of 3 already knows (`everyday` of the course): the only words a Hebrew scored picture may show without a Meet page.
Set<String> _everyday(String course) {
  final Object? doc = jsonDecode(File('$_languages/$course/course.json').readAsStringSync());
  final List<Object?> words =
      ((doc! as Map<String, Object?>)['everyday'] as List<Object?>?) ?? const <Object?>[];
  return <String>{for (final Object? w in words) 'vo:$course.${(w! as String).replaceAll('-', '_')}'};
}

/// What an item asks: the word of its prompt, or of its right answer (a puppet's bubble is the puppet's line and asks the word it is answered by).
Set<String> _asked(Activity a) => a is PuppetTalkActivity
    ? <String>{
        ?(a as ChoiceActivity).options.where((ChoiceOption o) => o.id == a.correctId).firstOrNull?.clip,
      }
    : askedWords(a);

void main() {
  for (final String course in Course.languages) {
    test('$course, lesson 1 as a complete beginner of 3, 5 and 7: taught before asked', () async {
      final PackKey key = await newTestKey();
      final PackContent content = PackContent.fromPack(
        await verifyPack(
          (await buildPack(languageSource(course, _languages), key)).bytes,
          publicKey: key.publicKey,
        ),
      );
      final Lesson first = content.lessons.values.reduce(
        (Lesson a, Lesson b) => b.sequence < a.sequence ? b : a,
      );
      final List<String> problems = <String>[];
      for (final int age in _capOfAge.keys) {
        final int cap = _capOfAge[age]!;
        final List<Activity> items = <Activity>[
          for (final Activity a in content.itemsFor(first, route: course == 'rus' ? 'new' : null))
            capChoices(a, cap),
        ];
        final String who = '$course ${first.id} age $age';
        final List<SayItActivity> meets = <SayItActivity>[
          for (final Activity a in items)
            if (a is SayItActivity && a.meetScreen) a,
        ];
        if (meets.isEmpty) problems.add('$who: no Meet screen at all');
        if (meets.length > 3) problems.add('$who: a Meet of ${meets.length} words');

        // The order: recall (at most 2 scored items) before the first Meet screen, then every Meet screen together, then the rest.
        final int firstMeet = items.indexWhere((Activity a) => a is SayItActivity && a.meetScreen);
        final int lastMeet = items.lastIndexWhere((Activity a) => a is SayItActivity && a.meetScreen);
        final int scoredBefore = items
            .take(firstMeet < 0 ? 0 : firstMeet)
            .where((Activity a) => !a.unscored)
            .length;
        if (scoredBefore > 2) {
          problems.add('$who: $scoredBefore scored items before the first Meet screen (recall is 1 to 2)');
        }
        for (int i = firstMeet; i <= lastMeet && firstMeet >= 0; i++) {
          final Activity a = items[i];
          if (!(a is SayItActivity && a.meetScreen)) problems.add('$who: ${a.id} stands inside the Meet set');
        }
        final List<Activity> after = items.skip(lastMeet + 1).toList();
        if (after.where((Activity a) => !a.unscored).length < 3) {
          problems.add('$who: fewer than 3 scored items after the Meet');
        }

        // Taught before asked.
        final Set<String> met = <String>{};
        final Set<String> everyday = course == 'heb' ? _everyday(course) : <String>{};
        final Map<String, int> firstFindOptions = <String, int>{};
        final Map<String, int> hearings = <String, int>{};
        void hear(String? clip, [int n = 1]) {
          if (clip != null) hearings[clip] = (hearings[clip] ?? 0) + n;
        }

        for (final (int i, Activity a) in items.indexed) {
          if (a is SayItActivity && a.meetScreen) {
            met.add(a.wordClip);
            // The beats that say the word (design M1, M3, M4 and M5: the carrier then the word, the word again, "together" and the word, the
            // word again at the child's turn). A child who taps "I said it" at once skips the last, so a lesson that reaches 8 only with it is
            // reported.
            hear(a.wordClip, 4);
            continue;
          }
          if (a.unscored && a is! SayItActivity) continue;
          final Set<String> asked = _asked(a);
          for (final String w in asked) {
            if (!met.contains(w) && !everyday.contains(w)) {
              problems.add('$who: item ${a.id} [$i] asks $w, which no Meet screen taught');
            }
          }
          if (a is ChoiceActivity) {
            final ChoiceActivity ch = a as ChoiceActivity;
            for (final ChoiceOption o in ch.options) {
              if (o.clip != null && !met.contains(o.clip) && !everyday.contains(o.clip)) {
                problems.add('$who: item ${a.id} [$i] shows a picture of ${o.clip}, not met before');
              }
            }
            if (!a.unscored && ch.options.isNotEmpty) {
              final String? word = asked.isEmpty ? null : asked.first;
              if (word != null && !firstFindOptions.containsKey(word)) {
                firstFindOptions[word] = ch.options.length;
              }
            }
            // The prompt says the word once; the right picture says it when tapped.
            hear(a.promptLine.target);
            final ChoiceOption right = ch.options.firstWhere((ChoiceOption o) => o.id == ch.correctId);
            hear(right.clip);
          } else if (a is SayItActivity) {
            hear(
              a.wordClip,
              2,
            ); // the model, then the child's own turn is not counted: the echo says it once more at the close
          } else {
            hear(a.promptLine.target);
          }
        }
        // Each new word: its first Find has 2 choices.
        for (final SayItActivity m in meets) {
          final int? n = firstFindOptions[m.wordClip];
          if (n == null) {
            problems.add('$who: the word ${m.wordClip} is never found (no scored choice asks it)');
          } else if (n != 2) {
            problems.add('$who: the first Find of ${m.wordClip} has $n choices (want 2)');
          }
          final int heard = hearings[m.wordClip] ?? 0;
          if (heard < 8 && course != 'heb') {
            problems.add('$who: the word ${m.wordClip} is heard $heard times (want at least 8)');
          }
        }
        // The Hebrew meaning: once per Meet screen, and nowhere else in the lesson.
        if (course != 'heb') {
          final Set<String> glosses = <String>{};
          for (final SayItActivity m in meets) {
            final Spoken? meaning = m.meet?.meaning;
            if (meaning?.target == null) {
              problems.add('$who: the Meet screen of ${m.wordClip} has no Hebrew meaning');
            } else if (!glosses.add(meaning!.target!)) {
              problems.add('$who: the meaning ${meaning.target} is said on two Meet screens');
            }
          }
          for (final Activity a in items) {
            if (a is SayItActivity && a.meetScreen) continue;
            for (final String? t in <String?>[a.promptLine.target, a.promptLine.target2]) {
              if (t != null && glosses.contains(t)) {
                problems.add('$who: ${a.id} says the Hebrew meaning $t again');
              }
            }
          }
        }
        // ignore: avoid_print
        print(
          'QA-L7 $who order: ${<String>[for (final Activity a in items) '${a.template}${a.unscored ? "*" : ""}:${a.id.split(".").last}']}',
        );
        // ignore: avoid_print
        print(
          'QA-L7 $who: ${items.length} activities, ${meets.length} Meet screens, first-Find options $firstFindOptions, heard $hearings',
        );
      }
      for (final String p in problems) {
        // ignore: avoid_print
        print('QA-L7-PROBLEM $p');
      }
      expect(problems, isEmpty);
    });
  }
}
