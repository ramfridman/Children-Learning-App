// QA's own check of board B-24 (docs/qa/b23-b24-verification.md), separate from the developer's tests: over EVERY activity
// of the bundled starter pack, the `voiceAnswer` flag agrees with the rule of docs/knowledge/voice-answer-by-activity.md,
// worked out here from the activity itself (its template, its prompt and its options), never from its id or from the
// developer's tables; and every spoken activity can really be answered by voice in the lesson: the session the lesson
// builds (the real TapAnswerSession, CountTapSession or FlashSession) gives every option words of its own, and saying
// those words is heard as that option and no other.
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter_test/flutter_test.dart';
import 'package:nitznutz/content/models.dart';
import 'package:nitznutz/play/count_tap_session.dart';
import 'package:nitznutz/play/flash_session.dart';
import 'package:nitznutz/play/lesson_controller.dart';
import 'package:nitznutz/play/tap_answer_session.dart';
import 'package:nitznutz/play/template_session.dart';
import 'package:nitznutz/speech/answer_matcher.dart';
import 'package:nitznutz/speech/hebrew_text.dart';
import 'package:nitznutz/speech/lexicon.dart';

import 'support/fakes.dart';
import 'support/starter.dart';

/// The templates that hold a choice the child can say; every other template is answered by hand.
const Set<String> _choiceTemplates = <String>{'tap_answer', 'count_tap', 'flash'};

/// The words that name an attribute a child can say: a colour, a shape, a day, a time of day (normalised, both spellings).
final Set<String> _sayable = <String>{
  for (final String w
      in ('אדום אדם כחול כחל צהוב צהב ירוק ירק כתום כתם סגול סגל ורוד ורד חום שחור לבן '
              'עיגול עגול ריבוע רבוע משולש משלש מלבן '
              'ראשון שני שלישי רביעי חמישי שישי ששי שבת '
              'בוקר בקר צהריים צהרים ערב לילה')
          .split(' '))
    normalizeHebrew(w),
};

/// Prompts that name the answer or ask for a match, not a word: "where is…", "choose the numeral", "the same as…".
final List<String> _notSaid = <String>[
  'איפה',
  'בוחרים',
  'אותו',
  'אותה',
  'איזו תמונה',
].map(normalizeHebrew).toList();

/// The groups the owner may switch on later (the decision's "for the owner" list): off today.
const Set<String> _ownerMaySwitchOn = <String>{'LOG-A-06', 'LOG-A-07', 'LOG-B-01', 'LOG-B-06'};

/// Skills whose tapped numeral answers are, on purpose, not said (B-15 part 2): "ten and four, which number?" (NUM-B-16,
/// spec §4: `voiceAnswer` stays false, the answer is made of the numbers of the question) and "3 coins, one coin for each
/// apple, how many apples?" (MATH-A-06: the answer is the number of the question).
const Set<String> _echoSkills = <String>{'NUM-B-16', 'MATH-A-06'};

String _caption(Object? spoken) => <String>[
  for (final Object? c
      in ((spoken as Map<String, Object?>?)?['caption'] as List<Object?>?) ?? const <Object?>[])
    (c! as Map<String, Object?>)['v']! as String,
].join(' ');

List<Map<String, Object?>> _options(Activity a) => <Map<String, Object?>>[
  for (final Object? o
      in ((a.json['answer']! as Map<String, Object?>)['options'] as List<Object?>?) ?? const <Object?>[])
    o! as Map<String, Object?>,
];

/// The rule, from the activity itself: should the child be able to say this answer?
bool _shouldSpeak(Activity a) {
  if (a.template == 'count_tap' || a.template == 'flash') return true;
  if (a.template != 'tap_answer') return false;
  if (_ownerMaySwitchOn.contains(a.skillId) || _echoSkills.contains(a.skillId)) return false;
  final String prompt = normalizeHebrew(_caption(a.json['prompt']));
  if (_notSaid.any(prompt.contains)) return false;
  final List<Map<String, Object?>> options = _options(a);
  if (options.every((Map<String, Object?> o) => o['numeral'] != null)) {
    // Amendment QA-21: an answer that is a part of the number word the question asks about is an echo, not an answer.
    // "שְׁלֹשׁ עֶשְׂרֵה is ten and how many?" names the teen whose first word is the answer (the teen is answer + 10).
    final Map<String, Object?> right = options.firstWhere(
      (Map<String, Object?> o) => o['id'] == (a.json['answer']! as Map<String, Object?>)['correct'],
    );
    final int n = right['numeral']! as int;
    return !(n >= 1 && n <= 9 && _names(prompt, n + 10));
  }
  // Word options: the prompt asks for a word ("איזה צבע", "איזו צורה", "מה בא", "מה חסר", "מה היה", "מה יהיה"), and once
  // the words another option also has are set aside ("כדור", "יום"), each option is exactly one sayable word ("כתום",
  // "רביעי", "שבת"), and the right one is not in the prompt already.
  if (!_asksForAWord.any(prompt.contains)) return false;
  final List<Set<String>> own = _ownWords(options);
  final int right = options.indexWhere(
    (Map<String, Object?> o) => o['id'] == (a.json['answer']! as Map<String, Object?>)['correct'],
  );
  if (own[right].any(tokensOf(prompt).contains)) return false;
  return own.every((Set<String> w) => w.length == 1 && _sayable.contains(w.single));
}

/// Whether the (normalised) prompt names the number [n] in words, compared by sound ("שלש" meets "שלוש").
bool _names(String prompt, int n) {
  final String text = ' ${tokensOf(prompt).map(phoneticKey).join(' ')} ';
  return numberWords(n).any(
    (AcceptWord w) => !isDigits(w.text) && text.contains(' ${tokensOf(w.text).map(phoneticKey).join(' ')} '),
  );
}

final List<String> _asksForAWord = <String>[
  'צבע',
  'צורה',
  'מה בא',
  'מה חסר',
  'מה היה',
  'מה יהיה',
].map(normalizeHebrew).toList();

/// The words of each option's label that no other option's label has.
List<Set<String>> _ownWords(List<Map<String, Object?>> options) {
  final List<Set<String>> words = <Set<String>>[
    for (final Map<String, Object?> o in options)
      tokensOf(normalizeHebrew((o['label'] as String?) ?? '')).toSet(),
  ];
  return <Set<String>>[
    for (final (int i, Set<String> w) in words.indexed)
      w
          .where((String x) => !words.indexed.any(((int, Set<String>) o) => o.$1 != i && o.$2.contains(x)))
          .toSet(),
  ];
}

void main() {
  late PackContent pack;
  setUpAll(() async => pack = await loadStarter());

  /// The real session the lesson builds for [a], and what it says it can hear.
  List<Expected> heardBy(Activity a) {
    final LessonController c = LessonController(
      content: pack,
      lesson: Lesson.mission(
        id: 'qa',
        itemIds: <String>[a.id],
        skillIds: <String>[for (final Skill s in a.skills) s.id],
        celebration: pack.lessons['butterflies']!.celebration,
      ),
      profileId: 'p-1',
      clock: FixedClock(1793000000000),
      record: (AttemptRecord r) async {},
    );
    final TemplateSession s = switch (a) {
      TapAnswerActivity() => TapAnswerSession(c, a),
      CountTapActivity() => CountTapSession(c, a),
      FlashActivity() => FlashSession(c, a),
      _ => throw StateError('${a.id}: ${a.template} has no spoken answer'),
    };
    final List<Expected> e = s.voiceExpected();
    s.dispose();
    c.dispose();
    return e;
  }

  test('all 967 activities: the flag agrees with the rule worked out from the activity itself', () {
    expect(pack.activities.length, 967);
    final List<String> wrong = <String>[
      for (final Activity a in pack.activities.values)
        if (a.voiceAnswer != _shouldSpeak(a)) '${a.id} (${a.template}, ${a.skillId}): flag ${a.voiceAnswer}',
    ];
    expect(wrong, isEmpty, reason: wrong.join('\n'));
    final int spoken = pack.activities.values.where((Activity a) => a.voiceAnswer).length;
    // 267 and 500 before the QA-21 amendment turned the nine NUM-B-16 activities off.
    expect(spoken, 310);
    expect(pack.activities.length - spoken, 657);
  });

  test('the flag is a real boolean in every activity file, and true only on a template with a choice', () {
    for (final Activity a in pack.activities.values) {
      expect(a.json['voiceAnswer'], isA<bool>(), reason: a.id);
      if (a.voiceAnswer) expect(_choiceTemplates, contains(a.template), reason: a.id);
      if (a.template == 'count_tap' || a.template == 'flash') expect(a.voiceAnswer, isTrue, reason: a.id);
    }
  });

  test('every spoken activity: each option has words of its own, and no two options share a word', () {
    final List<String> found = <String>[];
    for (final Activity a in pack.activities.values.where((Activity a) => a.voiceAnswer)) {
      final List<Expected> heard = heardBy(a);
      final List<Map<String, Object?>> options = _options(a);
      expect(heard.length, options.length, reason: a.id);
      expect(heard.length, greaterThanOrEqualTo(2), reason: a.id);
      for (int i = 0; i < heard.length; i++) {
        final Set<String> mine = <String>{for (final AcceptWord w in heard[i].words) w.text};
        if (mine.isEmpty) found.add('${a.id} option ${heard[i].id}: nothing to say');
        for (final String w in mine) {
          if (tokensOf(w).contains(negationWord) || intentPhrases(Intent.yes).contains(w)) {
            found.add('${a.id} option ${heard[i].id}: "$w" is a yes or a no');
          }
        }
        for (int j = i + 1; j < heard.length; j++) {
          final Set<String> theirs = <String>{for (final AcceptWord w in heard[j].words) w.text};
          final Set<String> both = mine.intersection(theirs);
          if (both.isNotEmpty) found.add('${a.id}: ${heard[i].id} and ${heard[j].id} share $both');
          final Set<String> sounds =
              <String>{
                for (final String w in mine)
                  if (!isDigits(w)) phoneticKey(w),
              }.intersection(<String>{
                for (final String w in theirs)
                  if (!isDigits(w)) phoneticKey(w),
              });
          if (sounds.isNotEmpty) found.add('${a.id}: ${heard[i].id} and ${heard[j].id} sound alike $sounds');
        }
      }
      // A label option answers to a word of its own label (the author's `speech` list may add more).
      for (final (int i, Map<String, Object?> o) in options.indexed) {
        if (o['numeral'] != null || o['value'] != null) {
          expect(heard[i].number, (o['numeral'] ?? o['value'])! as int, reason: '${a.id} ${o['id']}');
        } else {
          final Set<String> label = tokensOf(normalizeHebrew((o['label'] as String?) ?? '')).toSet();
          expect(
            heard[i].words.any((AcceptWord w) => label.contains(w.text)),
            isTrue,
            reason: '${a.id} ${o['id']}: answers to a word of its label',
          );
        }
      }
    }
    expect(found, isEmpty, reason: found.join('\n'));
  });

  test(
    'every spoken activity: saying an option (its label, or its number word) is heard as that option only',
    () {
      const AnswerMatcher matcher = AnswerMatcher();
      final List<String> found = <String>[];
      int said = 0;
      for (final Activity a in pack.activities.values.where((Activity a) => a.voiceAnswer)) {
        final List<Expected> heard = heardBy(a);
        final List<Map<String, Object?>> options = _options(a);
        for (final (int i, Expected e) in heard.indexed) {
          final List<String> utterances = <String>[
            if (e.number != null) ...<String>[
              '${e.number}',
              for (final AcceptWord w in e.words)
                if (!isDigits(w.text)) w.text,
            ] else ...<String>[
              normalizeHebrew((options[i]['label'] as String?) ?? ''),
              for (final AcceptWord w in e.words) w.text,
            ],
          ];
          for (final String u in utterances) {
            said++;
            final MatchResult r = matcher.decide(<Hypothesis>[Hypothesis(u, 0.95)], heard);
            final Decision want = e.correct ? Decision.accept : Decision.confirm;
            if (r.optionId != e.id || r.decision != want) {
              found.add('${a.id}: "$u" for ${e.id} (${e.correct ? 'right' : 'wrong'}) gave $r');
            }
          }
        }
      }
      debugPrint('QA B-24: $said spoken forms tried');
      expect(found, isEmpty, reason: found.take(40).join('\n'));
    },
  );

  test('the spoken answer is not already in the prompt, except where the sum keeps a number the same (reviewed list)', () {
    // A number question whose answer is one of the numbers of the prompt: n + 0, n - 0, 0 + 0 (the zero property),
    // 5 + 5 = 10 (one of the two numbers) and "what comes before 21?" (20 is the first word of 21). These are sums and
    // sequences, not "where is the number…?": the child works the number out, and the curriculum-expert kept them
    // (docs/knowledge/voice-answer-by-activity.md, amendment QA-21; "13 is ten and how many?", an echo, was turned off).
    // A new one fails here until someone looks at it.
    const Set<String> reviewed = <String>{
      'b.mathb06.1',
      'b.mathb07.1',
      'b.mathb07.2',
      'b.mathb07.3',
      'b.mathb07.6',
      'b.numb02.6',
    };
    final Set<String> named = <String>{};
    for (final Activity a in pack.activities.values.where((Activity a) => a.voiceAnswer)) {
      final List<String> prompt = tokensOf(
        normalizeHebrew('${_caption(a.json['prompt'])} ${_caption(a.json['answerPrompt'])}'),
      );
      final Map<String, Object?> right = _options(a).firstWhere(
        (Map<String, Object?> o) => o['id'] == (a.json['answer']! as Map<String, Object?>)['correct'],
      );
      final int? n = (right['numeral'] ?? right['value']) as int?;
      // Compared by sound, so that the spellings of the prompt ("שלש", "חמשה") meet the lexicon's ("שלוש", "חמישה").
      final String text = ' ${prompt.map(phoneticKey).join(' ')} ';
      final bool inPrompt;
      if (n != null) {
        // The number's word (one or two words) is in the prompt: "שתים עשרה" holds 12, and also holds 2.
        inPrompt =
            numberWords(n).any(
              (AcceptWord w) =>
                  !isDigits(w.text) && text.contains(' ${tokensOf(w.text).map(phoneticKey).join(' ')} '),
            ) ||
            prompt.contains('$n');
      } else {
        final List<Map<String, Object?>> options = _options(a);
        // Words by spelling: by sound, "צבע" (colour) and "צהוב" (yellow) have the same skeleton.
        inPrompt = _ownWords(options)[options.indexOf(right)].any(prompt.contains);
      }
      if (inPrompt) named.add(a.id);
    }
    expect(named, reviewed);
  });
}
