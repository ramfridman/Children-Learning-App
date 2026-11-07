// M10 step 0.4: the schema bumps for the new modes of Band C. `tap_answer` 1.4 (X1 stage pictures, X2 signs and numbers to 10,000,
// X3 the number answer, five choices in Band C) and `spot_error` 1.1 (X2). The schema takes the shapes, the validator checks what the
// shapes mean, and an item that uses a new feature must say it needs the new version, so that an older app keeps the pack hidden.
import 'package:flutter_test/flutter_test.dart';
import 'package:nitznutz/content/capabilities.dart';
import 'package:nitznutz/content/models.dart';
import 'package:nitznutz/content/pack_validation.dart';
import 'package:nitznutz/content/schema.dart';
import 'package:nitznutz/content/schemas.dart';

import 'support/sample_pack.dart';

Map<String, Object?> _m(Object? v) => v! as Map<String, Object?>;

/// A copy of the sample's `tap_answer` item, edited by [edit]. The item is Band C (the numbers above 100 and of four digits belong
/// there, SEC-M10-3) and the manifest promises tap_answer 1.4 (an item may not ask for more than it, SEC-M10-5).
SamplePack _tap(void Function(Map<String, Object?> doc) edit, {String version = '1.4'}) {
  final SamplePack p = SamplePack();
  final Map<String, Object?> doc = _m(p.docs[tapFile]);
  doc['templateVersion'] = version;
  doc['band'] = 'C';
  _m(p.manifest['templates'])['tap_answer'] = '1.4';
  edit(doc);
  return p;
}

/// The problems of one document. The sample's skill is in Band A, so "the item is Band C but its skill is not" is left out: these
/// tests are about the rules of the new modes.
List<String> _problems(SamplePack p, {String file = tapFile}) => <String>[
  for (final Problem x in validatePack(manifest: p.manifest, docs: p.docs, files: p.files))
    if (x.path.startsWith(file) && !x.toString().contains('but its skill')) x.toString(),
];

List<String> _schema(SamplePack p, {String template = 'tap_answer', String file = tapFile}) => <String>[
  for (final Problem x in validate(activitySchemaFor(template)!, p.doc(file))) x.toString(),
];

/// The number answer of 12 ÷ 3 style items: the number, the wrong ones the author expects, the rules.
Map<String, Object?> _numberAnswer() => <String, Object?>{
  'type': 'number',
  'value': 35,
  'expected': <Object?>[
    <String, Object?>{'value': 25, 'misconception': 'M-CNT-DOUBLE'},
    <String, Object?>{'value': 85, 'misconception': 'M-CNT-SKIP'},
  ],
  'rules': <Object?>[
    <String, Object?>{'when': 'smaller_from_larger', 'misconception': 'M-CNT-SKIP'},
  ],
};

void _numberItem(Map<String, Object?> doc) {
  doc['scene'] = <String, Object?>{
    'background': 'asset:meadow',
    'row': <Object?>['n:52', 'op:-', 'n:27', 'op:=', '?'],
  };
  doc['answer'] = _numberAnswer();
}

void main() {
  group('the versions', () {
    test('the app plays tap_answer 1.4 and spot_error 1.1', () {
      expect(supportedTemplates['tap_answer'], '1.4');
      expect(supportedTemplates['spot_error'], '1.1');
      expect(compareTemplateVersion('1.4', supportedTemplates['tap_answer']!), 0);
      expect(compareTemplateVersion('1.5', supportedTemplates['tap_answer']!), greaterThan(0));
    });

    test('a pack that asks for tap_answer 1.4 is hidden by an app that has 1.3', () {
      final AppCapabilities old = AppCapabilities(
        appVersion: '9.9.9',
        templates: <String, String>{...supportedTemplates, 'tap_answer': '1.3'},
      );
      final SamplePack p = SamplePack();
      _m(p.manifest['templates'])['tap_answer'] = '1.4';
      expect(old.incompatibility(p.manifest), contains('tap_answer 1.4'));
      expect(AppCapabilities.current.incompatibility(p.manifest), isNull);
    });
  });

  group('X2: signs and numbers to 10,000 in a row', () {
    test('the signs < > ( ) and numbers of up to five digits are taken, and a row of eleven', () {
      final SamplePack p = _tap(
        (Map<String, Object?> d) => _m(d['scene'])['row'] = <Object?>[
          'op:(',
          'n:10000',
          'op:+',
          'n:2500',
          'op:)',
          'op:x',
          'n:3',
          'op:<',
          'n:9999',
          'op:=',
          '?',
        ],
      );
      expect(_schema(p), isEmpty);
      expect(_problems(p), isEmpty);
      for (final String sign in <String>['<', '>', '(', ')', ':', '-', 'x']) {
        final SamplePack one = _tap(
          (Map<String, Object?> d) => _m(d['scene'])['row'] = <Object?>['n:1', 'op:$sign'],
        );
        expect(_schema(one), isEmpty, reason: sign);
      }
    });

    test('a number of six digits, a sign that is not one, and twelve cells are not', () {
      expect(
        _schema(_tap((Map<String, Object?> d) => _m(d['scene'])['row'] = <Object?>['n:100000', 'op:+'])),
        isNotEmpty,
      );
      expect(
        _schema(_tap((Map<String, Object?> d) => _m(d['scene'])['row'] = <Object?>['n:1', 'op:%'])),
        isNotEmpty,
      );
      expect(
        _schema(
          _tap(
            (Map<String, Object?> d) => _m(d['scene'])['row'] = <Object?>[for (int i = 0; i < 12; i++) 'n:1'],
          ),
        ),
        isNotEmpty,
      );
    });

    test('numerals on tiles and on the stage go to 10,000, and no further', () {
      final SamplePack ok = _tap((Map<String, Object?> d) {
        _m(d['scene'])['numeral'] = 10000;
        final List<Object?> options = _m(d['answer'])['options']! as List<Object?>;
        _m(options[0]).remove('sprite');
        _m(options[0])['numeral'] = 10000;
        _m(options[1]).remove('sprite');
        _m(options[1])['numeral'] = 4050;
      });
      expect(_schema(ok), isEmpty);
      expect(
        _schema(_tap((Map<String, Object?> d) => _m(d['scene'])['numeral'] = 10001)),
        contains(contains('scene.numeral')),
      );
    });

    test('an item that uses them says tap_answer 1.4', () {
      for (final void Function(Map<String, Object?>) use in <void Function(Map<String, Object?>)>[
        (Map<String, Object?> d) => _m(d['scene'])['row'] = <Object?>['n:1', 'op:<', 'n:2'],
        (Map<String, Object?> d) => _m(d['scene'])['row'] = <Object?>['n:1000', 'op:+', 'n:2'],
        (Map<String, Object?> d) => _m(d['scene'])['row'] = <Object?>[for (int i = 0; i < 9; i++) 'n:1'],
        (Map<String, Object?> d) => _m(d['scene'])['numeral'] = 500,
      ]) {
        final SamplePack old = _tap(use, version: '1.1');
        expect(_problems(old), contains(contains('needs tap_answer 1.4')));
        expect(_problems(_tap(use)), isEmpty);
      }
    });

    test('prompt.math, the number sentence of the bubble: the shape, the version, and what it may sit beside', () {
      const List<Object?> run = <Object?>['n:40', 'op:+', 'n:30', 'op:=', '?'];
      void say(Map<String, Object?> d) => _m(d['prompt'])['math'] = run;
      expect(_schema(_tap(say)), isEmpty);
      expect(_problems(_tap(say)), isEmpty);
      // Too short, too long, a picture, a number out of range, a sign that is no sign: refused by the schema.
      for (final List<Object?> bad in <List<Object?>>[
        <Object?>['n:4', 'op:+'],
        <Object?>[for (int i = 0; i < 10; i++) 'n:1'],
        <Object?>['n:4', 'op:+', 'asset:cube'],
        <Object?>['n:10001', 'op:+', 'n:1'],
        <Object?>['n:4', 'op:%', 'n:1'],
        <Object?>['n:04', 'op:+', 'n:1'],
      ]) {
        expect(
          _schema(_tap((Map<String, Object?> d) => _m(d['prompt'])['math'] = bad)),
          contains(contains('prompt.math')),
          reason: '$bad',
        );
      }
      // Only a tap_answer has one.
      final SamplePack other = SamplePack();
      final Map<String, Object?> story = _m(other.docs[tapFile]);
      expect(
        validate(activitySchemaFor('count_tap')!, <String, Object?>{
          ...story,
          'template': 'count_tap',
          'prompt': <String, Object?>{..._m(story['prompt']), 'math': run},
        }),
        isNotEmpty,
      );
      // An old template version, a row beside it, two gaps, four digits outside Band C, a run too wide for the bubble.
      expect(_problems(_tap(say, version: '1.1')), contains(contains('needs tap_answer 1.4')));
      expect(
        _problems(
          _tap((Map<String, Object?> d) {
            say(d);
            _m(d['scene'])['row'] = <Object?>['n:1', 'op:+', 'n:2', 'op:=', '?'];
          }),
        ),
        contains(contains('already draws the sentence')),
      );
      expect(
        _problems(_tap((Map<String, Object?> d) => _m(d['prompt'])['math'] = <Object?>['?', 'op:+', '?'])),
        contains(contains('more than one number')),
      );
      expect(
        _problems(
          _tap((Map<String, Object?> d) {
            say(d);
            d['band'] = 'A';
            _m(d['prompt'])['math'] = <Object?>['n:1000', 'op:+', 'n:1', 'op:=', '?'];
          }),
        ),
        contains(contains('four digits')),
      );
      expect(
        _problems(
          _tap(
            (Map<String, Object?> d) => _m(d['prompt'])['math'] = <Object?>[
              'n:9999',
              'op:+',
              'n:9999',
              'op:=',
              'n:9999',
              'op:+',
              'n:1',
            ],
          ),
        ),
        contains(contains('too wide')),
      );
    });

    test('spot_error 1.1 takes the new signs and big numbers, and an item that uses them says so', () {
      SamplePack spot(String version, List<Object?> cells) {
        final SamplePack p = SamplePack();
        final Map<String, Object?> doc = Map<String, Object?>.of(_m(p.docs[tapFile]))
          ..['id'] = 'spot.one'
          ..['template'] = 'spot_error'
          ..['templateVersion'] = version
          ..['band'] = 'C'
          ..['scene'] = <String, Object?>{'background': 'asset:meadow', 'cells': cells}
          ..['answer'] = <String, Object?>{'type': 'spot', 'wrong': 1};
        p.addDocument('activity.spot.one.json', 'activities', 'spot.one', doc);
        (p.manifest['templates']! as Map<String, Object?>)['spot_error'] = version;
        return p;
      }

      const String file = 'activity.spot.one.json';
      final List<Object?> cells = <Object?>['n:4050', 'op:<', 'n:4500'];
      expect(_schema(spot('1.1', cells), template: 'spot_error', file: file), isEmpty);
      expect(_problems(spot('1.1', cells), file: file), isEmpty);
      expect(_problems(spot('1.0', cells), file: file), contains(contains('need spot_error 1.1')));
      expect(_problems(spot('1.0', <Object?>['n:4', 'op:+', 'n:5']), file: file), isEmpty);
      expect(
        _schema(spot('1.1', <Object?>['n:100000', 'op:+', 'n:5']), template: 'spot_error', file: file),
        isNotEmpty,
      );
    });
  });

  group('five choices in Band C', () {
    SamplePack five({String band = 'C'}) => _tap((Map<String, Object?> d) {
      d['band'] = band;
      final List<Object?> options = _m(d['answer'])['options']! as List<Object?>;
      for (int i = 3; i <= 5; i++) {
        options.add(<String, Object?>{'id': 'o$i', 'sprite': 'asset:flower_red', 'label': 'red $i'});
      }
    });

    test('the schema takes five and refuses six', () {
      expect(_schema(five()), isEmpty);
      final SamplePack six = five();
      ((_m(six.docs[tapFile])['answer']! as Map<String, Object?>)['options']! as List<Object?>).add(
        <String, Object?>{'id': 'o6', 'sprite': 'asset:flower_red', 'label': 'x'},
      );
      expect(_schema(six), isNotEmpty);
    });

    test('the validator allows more than four only in Band C, and the item says 1.4', () {
      expect(_problems(five(band: 'A')), contains(contains('more than four choices belong to Band C')));
      expect(_problems(five()), isNot(contains(contains('more than four choices'))));
      expect(_problems(five(band: 'B')), contains(contains('more than four choices belong to Band C')));
    });
  });

  group('X1: the stage pictures', () {
    SamplePack pic(Map<String, Object?> picture, {String version = '1.4'}) =>
        _tap((Map<String, Object?> d) => _m(d['scene'])['picture'] = picture, version: version);

    final List<Map<String, Object?>> good = <Map<String, Object?>>[
      <String, Object?>{'kind': 'base_ten', 'thousands': 1, 'hundreds': 3, 'tens': 0, 'ones': 5},
      <String, Object?>{'kind': 'base_ten', 'tens': 4},
      <String, Object?>{'kind': 'array', 'rows': 3, 'columns': 4},
      <String, Object?>{
        'kind': 'hundred_chart',
        'lit': <Object?>[34, 44],
        'blank': <Object?>[54],
      },
      <String, Object?>{'kind': 'hundred_chart'},
      <String, Object?>{'kind': 'clock', 'hour': 2, 'minute': 30, 'digital': true},
      <String, Object?>{'kind': 'ruler', 'length': 7, 'from': 1},
      <String, Object?>{
        'kind': 'column',
        'op': '-',
        'top': '52',
        'bottom': '27',
        'marks': <Object?>[
          <String, Object?>{'place': 1, 'kind': 'borrow'},
        ],
      },
      <String, Object?>{'kind': 'fraction', 'parts': 4, 'shaded': 1},
    ];

    test('every kind is taken, by the schema and by the validator', () {
      for (final Map<String, Object?> picture in good) {
        expect(_schema(pic(picture)), isEmpty, reason: '$picture');
        expect(_problems(pic(picture)), isEmpty, reason: '$picture');
      }
      expect(good.map((Map<String, Object?> p) => p['kind']).toSet(), stagePictureKinds.toSet());
    });

    test('a kind that is not one, a place count out of range and a field of no kind are refused', () {
      expect(_schema(pic(<String, Object?>{'kind': 'pie'})), isNotEmpty);
      expect(_schema(pic(<String, Object?>{'kind': 'base_ten', 'hundreds': 10})), isNotEmpty);
      expect(
        _schema(pic(<String, Object?>{'kind': 'array', 'rows': 3, 'columns': 4, 'colour': 'red'})),
        isNotEmpty,
      );
      expect(_schema(pic(<String, Object?>{'kind': 'clock', 'hour': 13, 'minute': 0})), isNotEmpty);
      expect(
        _schema(pic(<String, Object?>{'kind': 'column', 'op': '*', 'top': '52', 'bottom': '27'})),
        isNotEmpty,
      );
    });

    test('a picture says what its kind needs, and nothing of another kind', () {
      expect(
        _problems(pic(<String, Object?>{'kind': 'array', 'rows': 3})),
        contains(contains('scene.picture.columns')),
      );
      expect(
        _problems(pic(<String, Object?>{'kind': 'clock', 'hour': 2})),
        contains(contains('scene.picture.minute')),
      );
      expect(
        _problems(pic(<String, Object?>{'kind': 'array', 'rows': 3, 'columns': 4, 'hour': 2})),
        contains(contains('scene.picture.hour: does not belong to a array picture')),
      );
      expect(
        _problems(pic(<String, Object?>{'kind': 'base_ten'})),
        contains(contains('needs at least one of')),
      );
      expect(
        _problems(pic(<String, Object?>{'kind': 'fraction', 'parts': 3, 'shaded': 4})),
        contains(contains('scene.picture.shaded')),
      );
      expect(
        _problems(
          pic(<String, Object?>{
            'kind': 'hundred_chart',
            'lit': <Object?>[5],
            'blank': <Object?>[5],
          }),
        ),
        contains(contains('scene.picture.blank')),
      );
      expect(
        _problems(pic(<String, Object?>{'kind': 'column', 'op': '+', 'top': '5', 'bottom': '25'})),
        contains(contains('the longer number on top')),
      );
    });

    test('a picture needs tap_answer 1.4', () {
      expect(
        _problems(pic(<String, Object?>{'kind': 'array', 'rows': 3, 'columns': 4}, version: '1.3')),
        contains(contains('a stage picture needs tap_answer 1.4')),
      );
    });
  });

  group('X3: the number answer', () {
    test('a number answer with its expected wrong numbers and rules is taken', () {
      final SamplePack p = _tap(_numberItem);
      expect(_schema(p), isEmpty);
      expect(_problems(p), isEmpty);
    });

    test('it needs the number, has no options, and its wrong numbers are other numbers, once each, with a tag of the catalogue', () {
      List<String> broken(void Function(Map<String, Object?> a) edit) => _problems(
        _tap((Map<String, Object?> d) {
          _numberItem(d);
          edit(_m(d['answer']));
        }),
      );
      expect(
        broken((Map<String, Object?> a) => a.remove('value')),
        contains(contains('answer.value: a number answer needs')),
      );
      expect(
        broken(
          (Map<String, Object?> a) => a['options'] = <Object?>[
            <String, Object?>{'id': 'o1', 'numeral': 1, 'label': 'one'},
            <String, Object?>{'id': 'o2', 'numeral': 2, 'label': 'two'},
          ],
        ),
        contains(contains('answer.options: a number answer has no options')),
      );
      expect(
        broken(
          (Map<String, Object?> a) => (a['expected']! as List<Object?>)[0] = <String, Object?>{
            'value': 35,
            'misconception': 'M-CNT-SKIP',
          },
        ),
        contains(contains('answer.expected[0].value: is the right answer')),
      );
      expect(
        broken(
          (Map<String, Object?> a) => (a['expected']! as List<Object?>)[1] = <String, Object?>{
            'value': 25,
            'misconception': 'M-CNT-SKIP',
          },
        ),
        contains(contains('answer.expected[1].value: is listed twice')),
      );
      expect(
        broken(
          (Map<String, Object?> a) => (a['expected']! as List<Object?>)[0] = <String, Object?>{
            'value': 25,
            'misconception': 'M-NOT-HERE',
          },
        ),
        contains(contains('answer.expected[0].misconception')),
      );
      expect(
        broken(
          (Map<String, Object?> a) => (a['rules']! as List<Object?>)[0] = <String, Object?>{
            'when': 'smaller_from_larger',
            'misconception': 'M-NOT-HERE',
          },
        ),
        contains(contains('answer.rules[0].misconception')),
      );
    });

    test('the schema limits the number to 10,000, the rules to the five of the plan, and the wrong numbers to eight', () {
      List<String> schema(void Function(Map<String, Object?> a) edit) => _schema(
        _tap((Map<String, Object?> d) {
          _numberItem(d);
          edit(_m(d['answer']));
        }),
      );
      expect(schema((Map<String, Object?> a) => a['value'] = 10000), isEmpty);
      expect(schema((Map<String, Object?> a) => a['value'] = 10001), isNotEmpty);
      expect(schema((Map<String, Object?> a) => a['value'] = -1), isNotEmpty);
      for (final String rule in numberRules) {
        expect(
          schema(
            (Map<String, Object?> a) => a['rules'] = <Object?>[
              <String, Object?>{'when': rule, 'misconception': 'M-CNT-SKIP'},
            ],
          ),
          isEmpty,
          reason: rule,
        );
      }
      expect(numberRules, <String>[
        'smaller_from_larger',
        'forgot_the_ten',
        'added_instead',
        'off_by_ten',
        'face_value',
      ]);
      expect(
        schema(
          (Map<String, Object?> a) => a['rules'] = <Object?>[
            <String, Object?>{'when': 'guessed', 'misconception': 'M-CNT-SKIP'},
          ],
        ),
        isNotEmpty,
      );
      expect(
        schema(
          (Map<String, Object?> a) => a['expected'] = <Object?>[
            for (int i = 0; i < 9; i++) <String, Object?>{'value': 100 + i, 'misconception': 'M-CNT-SKIP'},
          ],
        ),
        isNotEmpty,
      );
    });

    test('a choice still needs its options, its right answer and its switches, and no number fields', () {
      expect(
        _problems(_tap((Map<String, Object?> d) => _m(d['answer']).remove('correct'))),
        contains(contains('answer.correct: a choice needs it')),
      );
      expect(
        _problems(_tap((Map<String, Object?> d) => _m(d['answer']).remove('shuffle'))),
        contains(contains('answer.shuffle: a choice needs it')),
      );
      expect(
        _problems(_tap((Map<String, Object?> d) => _m(d['answer'])['value'] = 3)),
        contains(contains('belongs to a number answer')),
      );
    });

    test('a number answer needs tap_answer 1.4', () {
      expect(
        _problems(_tap(_numberItem, version: '1.3')),
        contains(contains('a number answer needs tap_answer 1.4')),
      );
    });
  });

  group('the model', () {
    test('a number item reads as a number answer with no options; a stage picture is kept', () {
      final SamplePack p = _tap((Map<String, Object?> d) {
        _numberItem(d);
        _m(d['scene'])['picture'] = <String, Object?>{'kind': 'array', 'rows': 3, 'columns': 4};
      });
      // The pack content hides such an item until a session draws it (SEC-M10-1), so the model is read from the document.
      final PackAssets assets = PackContent.fromPack(p.verified()).assets;
      final TapAnswerActivity a = Activity.fromJson(_m(p.docs[tapFile]), assets) as TapAnswerActivity;
      expect(a.options, isEmpty);
      expect(a.optionCount, 0);
      expect(a.correctId, '');
      expect(a.numberAnswer!.value, 35);
      expect(a.numberAnswer!.expected, <int, String>{25: 'M-CNT-DOUBLE', 85: 'M-CNT-SKIP'});
      expect(a.numberAnswer!.rules, <String, String>{'smaller_from_larger': 'M-CNT-SKIP'});
      expect(a.engineTags, <String>{'M-CNT-DOUBLE', 'M-CNT-SKIP'});
      expect(a.picture, <String, Object?>{'kind': 'array', 'rows': 3, 'columns': 4});
      expect(a.row, <String>['n:52', 'op:-', 'n:27', 'op:=', '?']);
    });

    test('a choice has no number answer and no picture', () {
      final TapAnswerActivity a =
          PackContent.fromPack(SamplePack().verified()).activities['pick.red.flower']! as TapAnswerActivity;
      expect(a.numberAnswer, isNull);
      expect(a.picture, isNull);
      expect(a.correctId, 'o1');
    });
  });
}
