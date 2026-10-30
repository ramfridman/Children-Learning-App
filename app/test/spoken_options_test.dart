import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:nitznutz/speech/answer_matcher.dart';
import 'package:nitznutz/speech/lexicon.dart';
import 'package:nitznutz/speech/spoken_options.dart';

const AnswerMatcher matcher = AnswerMatcher();

MatchResult heard(String text, List<Expected> options) =>
    matcher.decide(<Hypothesis>[Hypothesis(text, 0.9)], options);

/// The options of SHP-B-08 "אֵיפֹה הַתֵּבָה?" (activity.b.shpb08.5).
List<Expected> solids({String correct = 'box'}) => expectedFor(<SpokenOption>[
  const SpokenOption('cone', label: 'חָרוּט'),
  const SpokenOption('box', label: 'תֵּבָה'),
  const SpokenOption('sphere', label: 'כַּדּוּר'),
], correctId: correct);

void main() {
  group('the box word (hebrew-notes D6, owner Q7)', () {
    test('a child who says the everyday word "קופסה" (or "קופסא") for "תֵּבָה" is right', () {
      for (final String said in <String>['קופסה', 'קופסא', 'הקופסה', 'תיבה', 'תבה', 'התיבה']) {
        final MatchResult r = heard(said, solids());
        expect(r.decision, Decision.accept, reason: said);
        expect(r.optionId, 'box', reason: said);
      }
    });

    test('the everyday word answers only the box, never another solid', () {
      final MatchResult r = heard('קופסה', solids(correct: 'cone'));
      expect(r.optionId, 'box');
      expect(r.decision, isNot(Decision.accept)); // a wrong option is only confirmed, never counted
      expect(labelSynonyms('חרוט'), isEmpty);
    });

    test(
      'the lesson says the new word back after the child\'s word: the correct line names "הַתֵּבָה" first',
      () {
        int found = 0;
        for (final File f in Directory('../content/starter').listSync().whereType<File>()) {
          if (!f.path.contains('activity.') || !f.path.endsWith('.json')) continue;
          final Map<String, Object?> d = jsonDecode(f.readAsStringSync()) as Map<String, Object?>;
          final Map<String, Object?> answer = d['answer']! as Map<String, Object?>;
          if (answer['type'] != 'choice') continue;
          final Map<String, Object?> right = (answer['options']! as List<Object?>)
              .cast<Map<String, Object?>>()
              .firstWhere((Map<String, Object?> o) => o['id'] == answer['correct']);
          if (right['label'] != 'תֵּבָה') continue;
          final Map<String, Object?> correct =
              (d['feedback']! as Map<String, Object?>)['correct']! as Map<String, Object?>;
          final String said =
              (correct['caption']! as List<Object?>).cast<Map<String, Object?>>().first['v']! as String;
          expect(said, startsWith('כֵּן! זוֹ הַתֵּבָה'), reason: f.path);
          found++;
        }
        expect(found, greaterThan(0));
      },
    );
  });
}
