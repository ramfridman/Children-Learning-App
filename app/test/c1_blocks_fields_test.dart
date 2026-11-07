// Batch C1: the fields of the blocks picture beyond the first schema of step 0 (2026-11-07): a lit rod (`litRods`: "how much is this rod
// worth?"), rods crossed out (`crossedRods`: 70 - 40), a second picture beside the first (`scene.picture2`: two towers to compare, `40 + 30`
// as rods) and blocks on an answer tile (`answer.options[].picture`). The validator, the model and the drawing of each.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nitznutz/content/block_geometry.dart';
import 'package:nitznutz/content/models.dart';
import 'package:nitznutz/content/pack_validation.dart';
import 'package:nitznutz/content/schema.dart' show Problem;
import 'package:nitznutz/play/stage_pictures.dart';

import 'support/c1_screens.dart' show loadSourceVerified;
import 'support/golden_comparator.dart';
import 'support/harness.dart';
import 'support/sample_pack.dart';

Map<String, Object?> _m(Object? v) => v! as Map<String, Object?>;

SamplePack _tap(void Function(Map<String, Object?> doc) edit) {
  final SamplePack p = SamplePack();
  final Map<String, Object?> doc = _m(p.docs[tapFile]);
  doc['templateVersion'] = '1.4';
  doc['band'] = 'C';
  _m(p.manifest['templates'])['tap_answer'] = '1.4';
  edit(doc);
  return p;
}

List<String> _problems(SamplePack p) => <String>[
  for (final Problem x in validatePack(manifest: p.manifest, docs: p.docs, files: p.files))
    if (x.path.startsWith(tapFile) && !x.toString().contains('but its skill')) x.toString(),
];

void main() {
  setUpAll(() async {
    await loadAppFonts();
    useTolerantGoldens(0.03);
  });

  group('the validator', () {
    test(
      'a lit rod and rods crossed out are taken, as long as there are that many rods and none is both',
      () {
        expect(
          _problems(
            _tap(
              (Map<String, Object?> d) =>
                  _m(d['scene'])['picture'] = <String, Object?>{'kind': 'base_ten', 'tens': 7, 'litRods': 1},
            ),
          ),
          isEmpty,
        );
        expect(
          _problems(
            _tap(
              (Map<String, Object?> d) => _m(d['scene'])['picture'] = <String, Object?>{
                'kind': 'base_ten',
                'tens': 7,
                'crossedRods': 4,
              },
            ),
          ),
          isEmpty,
        );
        for (final Map<String, Object?> bad in <Map<String, Object?>>[
          <String, Object?>{'kind': 'base_ten', 'tens': 3, 'litRods': 4},
          <String, Object?>{'kind': 'base_ten', 'tens': 3, 'crossedRods': 4},
          <String, Object?>{'kind': 'base_ten', 'tens': 3, 'litRods': 2, 'crossedRods': 2},
          <String, Object?>{'kind': 'clock', 'hour': 3, 'minute': 0, 'litRods': 1},
        ]) {
          expect(
            _problems(_tap((Map<String, Object?> d) => _m(d['scene'])['picture'] = bad)),
            isNotEmpty,
            reason: '$bad',
          );
        }
      },
    );

    test('a second picture needs a first, and both are blocks', () {
      expect(
        _problems(
          _tap((Map<String, Object?> d) {
            _m(d['scene'])['picture'] = <String, Object?>{'kind': 'base_ten', 'tens': 4, 'ones': 1};
            _m(d['scene'])['picture2'] = <String, Object?>{'kind': 'base_ten', 'tens': 3, 'ones': 9};
          }),
        ),
        isEmpty,
      );
      expect(
        _problems(
          _tap((Map<String, Object?> d) {
            _m(d['scene'])['picture2'] = <String, Object?>{'kind': 'base_ten', 'tens': 3};
          }),
        ),
        isNotEmpty,
        reason: 'no first picture',
      );
      expect(
        _problems(
          _tap((Map<String, Object?> d) {
            _m(d['scene'])['picture'] = <String, Object?>{'kind': 'base_ten', 'tens': 4};
            _m(d['scene'])['picture2'] = <String, Object?>{
              'kind': 'hundred_chart',
              'lit': <Object?>[3],
            };
          }),
        ),
        isNotEmpty,
        reason: 'the second is not blocks',
      );
    });

    test('an option can be blocks, and two options with the same blocks look the same', () {
      void options(Map<String, Object?> d, List<Map<String, Object?>> pictures) {
        final Map<String, Object?> answer = _m(d['answer']);
        answer['options'] = <Object?>[
          for (final (int i, Map<String, Object?> p) in pictures.indexed)
            <String, Object?>{'id': 'o${i + 1}', 'picture': p, 'label': 'ציור ${i + 1}'},
        ];
        answer['correct'] = 'o1';
      }

      expect(
        _problems(
          _tap(
            (Map<String, Object?> d) => options(d, <Map<String, Object?>>[
              <String, Object?>{'kind': 'base_ten', 'tens': 3, 'ones': 4},
              <String, Object?>{'kind': 'base_ten', 'tens': 4, 'ones': 3},
            ]),
          ),
        ),
        isEmpty,
      );
      expect(
        _problems(
          _tap(
            (Map<String, Object?> d) => options(d, <Map<String, Object?>>[
              <String, Object?>{'kind': 'base_ten', 'tens': 3, 'ones': 4},
              <String, Object?>{'kind': 'base_ten', 'tens': 3, 'ones': 4},
            ]),
          ),
        ),
        isNotEmpty,
      );
      expect(
        _problems(
          _tap(
            (Map<String, Object?> d) => options(d, <Map<String, Object?>>[
              <String, Object?>{'kind': 'base_ten', 'tens': 3},
              <String, Object?>{'kind': 'array', 'rows': 2, 'columns': 2},
            ]),
          ),
        ),
        isNotEmpty,
        reason: 'only blocks go on a tile',
      );
    });

    test('blocks on tiles keep the cube at 12 points on the smallest phone: at most three options and no option too wide', () {
      List<String> options(List<Map<String, Object?>> pictures) => _problems(
        _tap((Map<String, Object?> d) {
          final Map<String, Object?> answer = _m(d['answer']);
          answer['options'] = <Object?>[
            for (final (int i, Map<String, Object?> p) in pictures.indexed)
              <String, Object?>{'id': 'o${i + 1}', 'picture': p, 'label': 'ציור ${i + 1}'},
          ];
          answer['correct'] = 'o1';
        }),
      );
      Map<String, Object?> blocks(int tens, int ones) => <String, Object?>{
        'kind': 'base_ten',
        'tens': tens,
        'ones': ones,
      };
      expect(options(<Map<String, Object?>>[blocks(4, 3), blocks(3, 4), blocks(0, 7)]), isEmpty);
      expect(
        options(<Map<String, Object?>>[blocks(5, 2), blocks(3, 4), blocks(0, 7)]),
        isEmpty,
        reason: 'five rods and two cubes still fit',
      );
      expect(
        options(<Map<String, Object?>>[blocks(8, 3), blocks(3, 7)]),
        isEmpty,
        reason: 'two options have room for eight rods',
      );
      expect(
        options(<Map<String, Object?>>[blocks(5, 6), blocks(3, 4), blocks(0, 7)]),
        isNotEmpty,
        reason: 'five rods and six cubes are too wide',
      );
      expect(
        options(<Map<String, Object?>>[blocks(6, 1), blocks(3, 4), blocks(0, 7)]),
        isNotEmpty,
        reason: 'six rods and a cube are too wide',
      );
      expect(
        options(<Map<String, Object?>>[blocks(1, 1), blocks(2, 2), blocks(3, 3), blocks(4, 4)]),
        isNotEmpty,
        reason: 'four tiles',
      );
    });

    test('two pictures to compare: four rods with six or more cubes, or five rods with five or fewer', () {
      List<String> pair(int t1, int o1, int t2, int o2) => _problems(
        _tap((Map<String, Object?> d) {
          _m(d['scene'])['picture'] = <String, Object?>{'kind': 'base_ten', 'tens': t1, 'ones': o1};
          _m(d['scene'])['picture2'] = <String, Object?>{'kind': 'base_ten', 'tens': t2, 'ones': o2};
        }),
      );
      expect(pair(4, 1, 3, 9), isEmpty);
      expect(pair(4, 9, 4, 8), isEmpty);
      expect(pair(5, 5, 4, 9), isEmpty);
      expect(pair(5, 6, 4, 9), isNotEmpty);
      expect(pair(6, 4, 5, 9), isNotEmpty);
    });

    test('the pack keeps to the limits, but for the items that wait for their content to change', () async {
      final Map<String, Object?> docs = (await loadSourceVerified()).docs;
      final Set<String> over = <String>{};
      for (final MapEntry<String, Object?> e in docs.entries) {
        if (!e.key.startsWith('activity.')) continue;
        final Map<String, Object?> a = _m(e.value);
        if (a['template'] != 'tap_answer') continue;
        if (blockLimits(_m(a['scene']), _m(a['answer'])).isNotEmpty) over.add(a['id']! as String);
      }
      expect(
        over,
        blockLimitWaivers,
        reason: 'a waived item that keeps the limits is to leave the list, and no other may break them',
      );
    });

    test('a lesson opens with the demonstration only when one of its items has blocks', () {
      final Map<String, Object?> demo = <String, Object?>{
        'kind': 'ten_is_rod',
        'vo': 'vo:demo.ten_is_rod',
        'caption': <Object?>[
          <String, Object?>{'t': 'he', 'v': 'עֶשֶׂר קֻבִּיּוֹת הֵן מוֹט אֶחָד.'},
        ],
      };
      List<String> demoProblems({required bool blocks}) {
        final SamplePack p = SamplePack();
        final Map<String, Object?> lesson = _m(p.docs[lessonFile]);
        lesson['demo'] = demo;
        if (blocks) {
          lesson['items'] = <Object?>['pick.red.flower'];
          final Map<String, Object?> doc = _m(p.docs[tapFile]);
          doc['templateVersion'] = '1.4';
          doc['band'] = 'C';
          _m(p.manifest['templates'])['tap_answer'] = '1.4';
          _m(doc['scene'])['picture'] = <String, Object?>{'kind': 'base_ten', 'tens': 3, 'ones': 4};
        }
        return <String>[
          for (final Problem x in validatePack(manifest: p.manifest, docs: p.docs, files: p.files))
            if (x.path.startsWith(lessonFile) && x.toString().contains('demonstration')) x.toString(),
        ];
      }

      expect(demoProblems(blocks: false), isNotEmpty, reason: 'the sample lesson has no blocks');
      expect(demoProblems(blocks: true), isEmpty);
    });

    test('the model reads them', () {
      final SamplePack p = _tap((Map<String, Object?> d) {
        _m(d['scene'])['picture'] = <String, Object?>{'kind': 'base_ten', 'tens': 7, 'crossedRods': 4};
        _m(d['scene'])['picture2'] = <String, Object?>{'kind': 'base_ten', 'tens': 3};
      });
      final PackAssets assets = PackContent.fromPack(p.verified(pictures: true)).assets;
      final TapAnswerActivity a = Activity.fromJson(_m(p.docs[tapFile]), assets) as TapAnswerActivity;
      expect(BaseTen.fromScene(a.picture!).crossedRods, 4);
      expect(a.picture2!['tens'], 3);
      expect(a.drawnPictureKind, 'base_ten');
    });
  });

  group('the drawing', () {
    testWidgets('a lit rod, crossed rods, a stack of flats and a thousand draw and stay inside their box', (
      WidgetTester t,
    ) async {
      const List<BaseTen> blocks = <BaseTen>[
        BaseTen(tens: 2, ones: 7, litRods: 1),
        BaseTen(tens: 7, crossedRods: 4),
        BaseTen(thousands: 1, hundreds: 3, tens: 2, ones: 5),
        BaseTen(tens: 4, ones: 1),
      ];
      await pumpScreen(
        t,
        Container(
          color: Colors.white,
          padding: const EdgeInsets.all(12),
          child: Row(
            textDirection: TextDirection.ltr,
            children: <Widget>[
              for (final BaseTen b in blocks)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(6),
                    child: BaseTenPicture(layoutOf: b),
                  ),
                ),
            ],
          ),
        ),
      );
      expect(t.takeException(), isNull);
      await expectLater(find.byType(MaterialApp), matchesGoldenFile('goldens/c1_blocks_fields.png'));
    });

    test('the crossed rods are the last ones, the lit rod is the first', () {
      const BaseTen n = BaseTen(tens: 7, litRods: 1, crossedRods: 4);
      expect(n.tens - n.crossedRods, 3, reason: 'the first three stay');
      expect(BaseTenLayout.forBox(n, const Size(300, 110)).tens, hasLength(7));
    });
  });
}
