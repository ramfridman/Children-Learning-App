// Board B-24: the pack says where a spoken answer makes sense (`voiceAnswer`), and the validator refuses a promise the
// lesson cannot keep. The rule: docs/knowledge/voice-answer-by-activity.md.
import 'package:flutter_test/flutter_test.dart';
import 'package:nitznutz/content/pack_validation.dart';
import 'package:nitznutz/content/schema.dart';

import 'support/sample_pack.dart';

Map<String, Object?> _m(Object? o) => o! as Map<String, Object?>;

List<Problem> _run(SamplePack p) => validatePack(manifest: p.manifest, docs: p.docs, files: p.files);

/// Replaces the options of the sample's tap activity, and sets its flag.
void _tapOptions(SamplePack p, List<Map<String, Object?>> options, {bool voice = true}) {
  final Map<String, Object?> tap = _m(p.docs[tapFile]);
  tap['voiceAnswer'] = voice;
  _m(tap['answer'])['options'] = <Object?>[
    for (final (int i, Map<String, Object?> o) in options.indexed) <String, Object?>{'id': 'o${i + 1}', ...o},
  ];
}

/// Picture options with these labels: the sample pack has two pictures, so every option after the second is a set.
List<Map<String, Object?>> _pictures(
  List<String> labels, {
  Map<int, List<String>> speech = const <int, List<String>>{},
}) => <Map<String, Object?>>[
  for (final (int i, String l) in labels.indexed)
    <String, Object?>{
      if (i == 0) 'sprite': 'asset:flower_red',
      if (i == 1) 'sprite': 'asset:flower_yellow',
      if (i >= 2) 'set': <String, Object?>{'sprite': 'asset:butterfly', 'count': i},
      'label': l,
      if (speech[i] != null) 'speech': speech[i],
    },
];

List<Map<String, Object?>> _numerals(List<int> values) => <Map<String, Object?>>[
  for (final int v in values) <String, Object?>{'numeral': v, 'label': '$v'},
];

Iterable<String> _messages(List<Problem> found, String path) =>
    found.where((Problem p) => p.path == path).map((Problem p) => p.message);

void main() {
  group('where the flag may be', () {
    test('a pack without the flag is valid: the app reads a missing flag as "no mic"', () {
      expect(_run(SamplePack()), isEmpty);
    });

    test('true on the three templates with a choice, and false anywhere, is valid', () {
      final SamplePack p = SamplePack();
      _m(p.docs[countFile])['voiceAnswer'] = true;
      _m(p.docs[tapFile])['voiceAnswer'] = true;
      _m(p.docs[giveFile])['voiceAnswer'] = false;
      expect(_run(p), isEmpty);
    });

    test('(a) true on a template answered by hand is refused', () {
      final SamplePack p = SamplePack();
      _m(p.docs[giveFile])['voiceAnswer'] = true;
      expect(_messages(_run(p), '$giveFile › voiceAnswer').single, contains('answered by hand'));
    });

    test('the flag is a true or a false, nothing else', () {
      final SamplePack p = SamplePack();
      _m(p.docs[tapFile])['voiceAnswer'] = 'yes';
      expect(_run(p).where((Problem x) => x.path == '$tapFile › voiceAnswer'), isNotEmpty);
    });

    test('(d) in the starter pack every activity must carry the flag', () {
      final SamplePack p = SamplePack();
      p.manifest['id'] = 'starter';
      final List<Problem> found = _run(p);
      for (final String f in <String>[countFile, tapFile, giveFile]) {
        expect(_messages(found, '$f › voiceAnswer').single, contains('starter pack'));
      }
      for (final String f in <String>[countFile, tapFile, giveFile]) {
        _m(p.docs[f])['voiceAnswer'] = f == countFile;
      }
      expect(_run(p), isEmpty);
    });
  });

  group('(b) every option can be said, and no two sound the same', () {
    test('a colour that tells the options apart is enough, and a word every option has is not needed', () {
      final SamplePack p = SamplePack();
      _tapOptions(p, _pictures(<String>['כַּדּוּר אָדֹם', 'כַּדּוּר כָּחֹל', 'כַּדּוּר צָהֹב']));
      expect(_run(p), isEmpty);
    });

    test('a day of the week: "יום" is in two options but "שבת" and the day names still tell them apart', () {
      final SamplePack p = SamplePack();
      _tapOptions(p, _pictures(<String>['שַׁבָּת', 'יוֹם רִאשׁוֹן', 'יוֹם שִׁשִּׁי']));
      expect(_run(p), isEmpty);
    });

    test('an option with no word of its own is refused', () {
      final SamplePack p = SamplePack();
      // "כדור" is in two options and "אדום" in two others: the first has nothing left to say.
      _tapOptions(p, _pictures(<String>['כַּדּוּר אָדֹם', 'כַּדּוּר כָּחֹל', 'בָּלוֹן אָדֹם']));
      expect(_messages(_run(p), '$tapFile › answer.options[0]').single, contains('nothing of its own'));
    });

    test('two options that are spelled differently but sound the same are refused', () {
      final SamplePack p = SamplePack();
      _tapOptions(p, _pictures(<String>['אָדֹם', 'אדום']));
      expect(
        _messages(_run(p), '$tapFile › answer.options[1]').single,
        contains('sounds the same as option o1'),
      );
    });

    test('an author\'s word given to two options is refused', () {
      final SamplePack p = SamplePack();
      _tapOptions(
        p,
        _pictures(
          <String>['פֶּרַח', 'עֵץ'],
          speech: <int, List<String>>{
            0: <String>['גִּנָּה'],
            1: <String>['גִּנָּה'],
          },
        ),
      );
      expect(_messages(_run(p), '$tapFile › answer.options[1]').single, contains('sounds the same'));
    });

    test('the same rule says nothing about an activity that is not spoken', () {
      final SamplePack p = SamplePack();
      _tapOptions(p, _pictures(<String>['כַּדּוּר אָדֹם', 'כַּדּוּר כָּחֹל', 'בָּלוֹן אָדֹם']), voice: false);
      expect(_run(p), isEmpty);
    });

    test('numerals are said as numbers, up to 100', () {
      final SamplePack p = SamplePack();
      _tapOptions(p, _numerals(<int>[29, 30, 31]));
      expect(_run(p), isEmpty);
    });
  });

  group('(c) no yes or no', () {
    test('a tick and a cross ("כן" and "לא") cannot be spoken: both are refused', () {
      final SamplePack p = SamplePack();
      _tapOptions(p, _pictures(<String>['כֵּן', 'לֹא']));
      final List<Problem> found = _run(p);
      expect(_messages(found, '$tapFile › answer.options[0]').single, contains('yes or a no'));
      expect(_messages(found, '$tapFile › answer.options[1]').single, contains('yes or a no'));
    });

    test('an option that holds the word "לא" is refused', () {
      final SamplePack p = SamplePack();
      _tapOptions(p, _pictures(<String>['אָדֹם', 'לֹא אָדֹם']));
      expect(_messages(_run(p), '$tapFile › answer.options[1]').single, contains('yes or a no'));
    });

    test('a yes or no question without a mic is fine', () {
      final SamplePack p = SamplePack();
      _tapOptions(p, _pictures(<String>['כֵּן', 'לֹא']), voice: false);
      expect(_run(p), isEmpty);
    });
  });

  group('the warning: a number whose word starts another option\'s number', () {
    List<Problem> warn(List<int> values, {bool voice = true}) {
      final SamplePack p = SamplePack();
      _tapOptions(p, _numerals(values), voice: voice);
      expect(_run(p), isEmpty, reason: 'a warning is not an error: the pack is still valid');
      return packWarnings(docs: p.docs);
    }

    test('8 and 18, 3 and 13, 2 and 12, 20 and 21 are each warned about on the shorter number', () {
      expect(warn(<int>[18, 8]).single.path, '$tapFile › answer.options[1]');
      expect(warn(<int>[3, 13, 4]).single.path, '$tapFile › answer.options[0]');
      expect(warn(<int>[1, 12, 2]).single.path, '$tapFile › answer.options[2]');
      expect(warn(<int>[20, 19, 21]).single.path, '$tapFile › answer.options[0]');
      expect(warn(<int>[30, 31, 29]).single.path, '$tapFile › answer.options[0]');
    });

    test('numbers that do not start one another, or an activity without a mic, are not', () {
      expect(warn(<int>[2, 3, 4]), isEmpty);
      expect(warn(<int>[3, 30, 4]), isEmpty, reason: '"שלושים" is one word, not "שלוש" and more');
      expect(warn(<int>[12, 13, 14]), isEmpty);
      expect(warn(<int>[18, 8], voice: false), isEmpty);
    });
  });
}
