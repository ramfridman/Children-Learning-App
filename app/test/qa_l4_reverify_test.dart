// ignore_for_file: curly_braces_in_flow_control_structures
// QA's re-verification of L4 after the fixes of QA-L4-1 to -10 (docs/qa/l4-languages-verification.md section 10). The developer's own proofs
// (`qa_l4_open_defects_test.dart`, `l4_layout_test.dart`) play fixture items; these play every item of the design-director's real body map
// (`content/languages/pictures/mika-body.hotspots.json`), measure every place and every board, and check the layout spec's numbers
// (docs/design/languages-l4-layout.md) one by one. A test with `skip: _open` is an open defect (run with `--dart-define=QA_OPEN=true`).
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nitznutz/content/models.dart';
import 'package:nitznutz/content/pack_validation.dart';
import 'package:nitznutz/content/schema.dart' show Problem;
import 'package:nitznutz/play/lesson_controller.dart';
import 'package:nitznutz/play/listen_do_session.dart';
import 'package:nitznutz/play/puppet_talk_session.dart';
import 'package:nitznutz/play/sound_boxes_session.dart';
import 'package:nitznutz/play/story_session.dart';

import 'support/golden_comparator.dart';
import 'support/harness.dart';
import 'support/l4_rig.dart';
import 'support/language_content.dart';

const bool _runOpen = bool.fromEnvironment('QA_OPEN');
const bool _open = !_runOpen;

List<String> _messages(LangPack p) => <String>[
  for (final Problem x in validatePack(manifest: p.pack.manifest, docs: p.pack.docs, files: p.pack.files))
    '${x.path}: ${x.message}',
];

Rig<ListenDoSession> _doRig(LangPack p, String id) => Rig<ListenDoSession>(
  p,
  id,
  (LessonController c, Activity a) => ListenDoSession(c, a as ListenDoActivity),
);

Rig<SoundBoxesSession> _drumRig(LangPack p, String id) => Rig<SoundBoxesSession>(
  p,
  id,
  (LessonController c, Activity a) => SoundBoxesSession(c, a as SoundBoxesActivity),
);

// ---- the real map ----------------------------------------------------------------------------------------------------------------------

Map<String, Object?> _json() =>
    jsonDecode(File('../content/languages/pictures/mika-body.hotspots.json').readAsStringSync())
        as Map<String, Object?>;

double _n(Object? o) => (o! as num).toDouble();

/// The places of [part] as shares: one rectangle or several.
List<Map<String, Object?>> _places(String part) => <Map<String, Object?>>[
  for (final List<Object?> r
      in ((_json()['parts']! as Map<String, Object?>)[part]! as List<Object?>).cast<List<Object?>>())
    at(_n(r[0]), _n(r[1]), _n(r[2]), _n(r[3])),
];

String _asset(String picture) => picture.replaceAll('-', '_');

/// One item of the map as an activity of its course, built the way the design says: touch areas on the body (`show: body`) or three
/// close-up cards in the answer row (`show: cards`).
LangPack _mapItem(String key, Map<String, Object?> item) {
  final String course = key.startsWith('rus') ? 'rus' : 'eng';
  final List<String> parts = (item['parts']! as List<Object?>).cast<String>();
  final bool cards = item['show'] == 'cards';
  final Map<String, Object?> cardOf = _json()['cards']! as Map<String, Object?>;
  final LangPack p = LangPack(course)..addPictures(<String>['mika_body']);
  if (cards) p.addPictures(<String>[for (final String part in parts) _asset(cardOf[part]! as String)]);
  final List<String?> tags = <String?>[null, p.tag('lis.sem'), p.tag('lis.guess')];
  final List<Map<String, Object?>> options = <Map<String, Object?>>[
    for (int i = 0; i < 3; i++)
      <String, Object?>{
        'id': 'o${i + 1}',
        'label': parts[i],
        if (cards) 'sprite': 'asset:${_asset(cardOf[parts[i]]! as String)}',
        'at': _places(parts[i]),
        'misconception': ?tags[i],
      },
  ];
  p.add(
    listenDoJson(
      course: course,
      id: 'item',
      mode: cards ? 'cards' : 'hotspots',
      picture: 'mika_body',
      options: options,
      correct: 'o1',
    ),
  );
  return p;
}

bool _overlaps(Rect a, Rect b) => a.deflate(0.5).overlaps(b.deflate(0.5));

void main() {
  setUpAll(() async {
    await loadAppFonts();
    useTolerantGoldens(0.03);
  });

  // ---------------------------------------------------------------------------------------------------------------------------------
  group('QA-L4-1 and -2, re-verified on the real map: every item of ENG-A-06 and RUS-A-03', () {
    final Map<String, Object?> items = _json()['items']! as Map<String, Object?>;

    test('the map has the 8 English and the 14 Russian items (rus.a03.12 is a dress-up scene), and every part is a list of 1 or 2 areas of at least 72/256', () {
      expect(items.keys.where((String k) => k.startsWith('ENG')), hasLength(8));
      expect(items.keys.where((String k) => k.startsWith('rus')), hasLength(14));
      final Map<String, Object?> parts = _json()['parts']! as Map<String, Object?>;
      for (final MapEntry<String, Object?> e in parts.entries) {
        final List<Object?> rs = e.value! as List<Object?>;
        expect(rs.length, inInclusiveRange(1, 2), reason: e.key);
        for (final List<Object?> r in rs.cast<List<Object?>>()) {
          expect(_n(r[2]), greaterThanOrEqualTo(72 / 256 - 0.0001), reason: '${e.key} width');
          expect(_n(r[3]), greaterThanOrEqualTo(72 / 256 - 0.0001), reason: '${e.key} height');
          expect(_n(r[0]) + _n(r[2]), lessThanOrEqualTo(1.0005), reason: '${e.key} inside the picture');
          expect(_n(r[1]) + _n(r[3]), lessThanOrEqualTo(1.0005), reason: '${e.key} inside the picture');
        }
      }
      for (final String two in <String>['ears', 'arms', 'hands', 'fingers']) {
        expect((parts[two]! as List<Object?>), hasLength(2), reason: '$two has two places');
      }
    });

    // rus.a03.06, .10 and .14: the nose (or the belly) and the right arm abut exactly (0.3594 + 0.2812 = 0.6406) and the validator reads the
    // float sum as an overlap (QA-L4-12).
    const Set<String> abutting = <String>{'rus.a03.06', 'rus.a03.10', 'rus.a03.14'};

    test('every item but three passes the pack validator as the design says it is shown (nose and two-place parts included)', () {
      final List<String> bad = <String>[];
      for (final MapEntry<String, Object?> e in items.entries) {
        if (abutting.contains(e.key)) continue;
        final List<String> m = _messages(_mapItem(e.key, e.value! as Map<String, Object?>));
        if (m.isNotEmpty) bad.add('${e.key}: $m');
      }
      expect(bad, isEmpty);
    });

    test('QA-L4-12 (open): RUS-A-03 items 06, 10 and 14 (areas that only touch) pass the pack validator', () {
      final List<String> bad = <String>[];
      for (final String k in abutting) {
        final List<String> m = _messages(_mapItem(k, items[k]! as Map<String, Object?>));
        if (m.isNotEmpty) bad.add('$k: $m');
      }
      expect(
        bad,
        isEmpty,
        reason: 'the areas touch edge to edge and the float sum of the validator calls it an overlap',
      );
    }, skip: _open ? 'QA-L4-12 open: `_overlap` has no tolerance' : false);

    test('every card of a cards item has its close-up picture in the set (body-<part>.svg)', () {
      final Map<String, Object?> cardOf = _json()['cards']! as Map<String, Object?>;
      final List<String> missing = <String>[];
      for (final MapEntry<String, Object?> e in items.entries) {
        final Map<String, Object?> item = e.value! as Map<String, Object?>;
        if (item['show'] != 'cards') continue;
        for (final String part in (item['parts']! as List<Object?>).cast<String>()) {
          final String file = '../content/languages/pictures/${cardOf[part]}.svg';
          if (!File(file).existsSync()) missing.add('${e.key} $part $file');
        }
        expect((item['cards']! as List<Object?>).length, 3, reason: e.key);
      }
      expect(missing, isEmpty);
    });

    test('items shown on the body keep their three parts apart (no overlap, by the map\'s own numbers rounded to 4 places)', () {
      for (final MapEntry<String, Object?> e in items.entries) {
        final Map<String, Object?> item = e.value! as Map<String, Object?>;
        if (item['show'] != 'body') continue;
        final List<String> parts = (item['parts']! as List<Object?>).cast<String>();
        final List<(String, Rect)> rs = <(String, Rect)>[
          for (final String part in parts)
            for (final Map<String, Object?> a in _places(part))
              (
                part,
                Rect.fromLTWH(
                  double.parse(_n(a['x']).toStringAsFixed(4)),
                  double.parse(_n(a['y']).toStringAsFixed(4)),
                  double.parse(_n(a['w']).toStringAsFixed(4)),
                  double.parse(_n(a['h']).toStringAsFixed(4)),
                ),
              ),
        ];
        for (int i = 0; i < rs.length; i++) {
          for (int j = i + 1; j < rs.length; j++) {
            if (rs[i].$1 != rs[j].$1) {
              expect(_overlaps(rs[i].$2, rs[j].$2), isFalse, reason: '${e.key}: ${rs[i].$1} and ${rs[j].$1}');
            }
          }
        }
      }
    });

    for (final MapEntry<String, Size> b in boards.entries) {
      testWidgets(
        '${b.key}: every body item has every place at least 64 pt each way and apart, a touch on any place of the right part answers; a cards item has 96 or 112 pt tiles',
        (WidgetTester t) async {
          final List<String> small = <String>[];
          final bool tablet = b.key.startsWith('tablet');
          for (final MapEntry<String, Object?> e in items.entries) {
            final Map<String, Object?> item = e.value! as Map<String, Object?>;
            final LangPack p = _mapItem(e.key, item);
            if (item['show'] == 'cards') {
              final Rig<ListenDoSession> r = _doRig(p, 'item');
              await r.pump(t, size: b.value);
              expect(find.byKey(const Key('do-scene-cards')), findsOneWidget, reason: e.key);
              expect(find.byKey(const Key('do-hot-o1')), findsNothing, reason: e.key);
              for (final String id in <String>['o1', 'o2', 'o3']) {
                final Size s = t.getSize(r.tile(id));
                if (s.width < (tablet ? 112 : 96) - 0.5 || s.height < (tablet ? 112 : 96) - 0.5) {
                  small.add('${e.key} ${b.key} tile $id ${s.width.round()}x${s.height.round()}');
                }
              }
              await t.tap(r.tile('o1'));
              await r.wait(t, 300);
              expect(r.written, <String>['correct:o1'], reason: '${e.key} ${b.key}');
              await r.done(t);
              continue;
            }
            // body: every place of every option
            final int placesOfRight = _places((item['parts']! as List<Object?>).cast<String>().first).length;
            for (int k = 0; k < placesOfRight; k++) {
              final Rig<ListenDoSession> r = _doRig(p, 'item');
              await r.pump(t, size: b.value);
              final List<Rect> all = <Rect>[];
              for (int i = 1; i <= 3; i++) {
                for (int j = 0; j < 2; j++) {
                  final Finder f = find.byKey(Key(j == 0 ? 'do-hot-o$i' : 'do-hot-o$i-$j'));
                  if (f.evaluate().isEmpty) continue;
                  final Rect rect = t.getRect(f);
                  all.add(rect);
                  if (rect.width < 64 - 0.5 || rect.height < 64 - 0.5) {
                    small.add('${e.key} ${b.key} o$i place $j ${rect.width.round()}x${rect.height.round()}');
                  }
                }
              }
              for (int a = 0; a < all.length; a++) {
                for (int c = a + 1; c < all.length; c++) {
                  if (_overlaps(all[a], all[c]))
                    small.add('${e.key} ${b.key}: touch areas overlap ${all[a]} ${all[c]}');
                }
              }
              final Finder target = find.byKey(Key(k == 0 ? 'do-hot-o1' : 'do-hot-o1-$k'));
              expect(target, findsOneWidget, reason: '${e.key} ${b.key} place $k of the right part');
              await t.tap(target);
              await r.wait(t, 300);
              expect(r.written, <String>['correct:o1'], reason: '${e.key} ${b.key} place $k');
              await r.done(t);
            }
          }
          expect(small, isEmpty, reason: '$small');
        },
      );
    }
  });

  // ---------------------------------------------------------------------------------------------------------------------------------
  group('QA-L4-3, re-verified: the close-up card of level 2 stands clear of everything the child can touch or read, on every board', () {
    LangPack drag(String course) {
      final LangPack p = LangPack(course)..addPictures(<String>['table', 'apple', 'banana', 'cat']);
      p.add(
        listenDoJson(
          course: course,
          id: 'drag1',
          mode: 'drag',
          picture: 'table',
          target: <String, Object?>{'at': at(0.6, 0.3, 0.3, 0.3)},
          options: <Map<String, Object?>>[
            thingOption('o1', 'apple', at(0.02, 0.02, 0.22, 0.22)),
            thingOption('o2', 'banana', at(0.02, 0.4, 0.22, 0.22), tag: p.tag('lis.sem')),
            thingOption('o3', 'cat', at(0.02, 0.72, 0.22, 0.22), tag: p.tag('lis.guess')),
          ],
          correct: 'o1',
        ),
      );
      return p;
    }

    LangPack place(String course) {
      final LangPack p = LangPack(course)..addPictures(<String>['table', 'ball']);
      p.add(
        listenDoJson(
          course: course,
          id: 'place1',
          mode: 'place',
          picture: 'table',
          thing: <String, Object?>{'sprite': 'asset:ball', 'at': at(0.04, 0.4, 0.22, 0.22)},
          options: <Map<String, Object?>>[
            partOption('o1', at(0.4, 0.04, 0.5, 0.26), label: 'on'),
            partOption('o2', at(0.4, 0.7, 0.5, 0.26), tag: p.tag('lis.sem'), label: 'under'),
            partOption('o3', at(0.72, 0.36, 0.25, 0.26), tag: p.tag('lis.guess'), label: 'next to'),
          ],
          correct: 'o1',
        ),
      );
      return p;
    }

    Future<void> twoMistakes(WidgetTester t, Rig<ListenDoSession> r, String mode) async {
      if (mode == 'drag') {
        for (final String id in <String>['o2', 'o3']) {
          await t.tap(find.byKey(Key('do-piece-$id')));
          await r.wait(t, 200);
          await t.tap(find.byKey(const Key('do-target')));
          await r.wait(t, 1700);
        }
      } else if (mode == 'place') {
        for (final String id in <String>['o2', 'o3']) {
          await t.tap(find.byKey(Key('do-place-$id')));
          await r.wait(t, 1700);
        }
      } else {
        for (final String id in <String>['o2', 'o3']) {
          await t.tap(find.byKey(Key('do-hot-$id')));
          await r.wait(t, 1700);
        }
      }
    }

    for (final MapEntry<String, Size> b in boards.entries) {
      for (final String course in <String>['eng', 'heb']) {
        testWidgets(
          '${b.key} $course: the card is on the board, outside the scene, clear of the bubble, the lamp, the eye and every target',
          (WidgetTester t) async {
            for (final String mode in <String>['hotspots', 'place', 'drag']) {
              final LangPack p = mode == 'drag'
                  ? drag(course)
                  : mode == 'place'
                  ? place(course)
                  : _mapItem(
                      'ENG-A-06 i01',
                      (_json()['items']! as Map<String, Object?>)['ENG-A-06 i01']! as Map<String, Object?>,
                    );
              final String id = mode == 'drag'
                  ? 'drag1'
                  : mode == 'place'
                  ? 'place1'
                  : 'item';
              final Rig<ListenDoSession> r = _doRig(p, id);
              await r.pump(t, size: b.value);
              await twoMistakes(t, r, mode);
              expect(r.controller.hintShown, 2, reason: '$mode: level 2');
              final Finder cardF = find.byKey(const Key('do-closeup'));
              expect(cardF, findsOneWidget, reason: '$mode: the card is shown at level 2');
              final Rect card = t.getRect(cardF);
              final Rect board = Offset.zero & b.value;
              expect(
                board.contains(card.topLeft) && board.contains(card.bottomRight),
                isTrue,
                reason: '$mode: on the board $card',
              );
              final List<(String, Finder)> others = <(String, Finder)>[
                ('scene', find.byKey(Key('do-scene-$mode'))),
                ('lamp', find.byKey(const Key('lesson-hint'))),
                ('eye', find.byKey(const Key('lesson-show-me'))),
                ('bubble', find.byKey(const Key('lesson-bubble'))),
                ('target', find.byKey(const Key('do-target'))),
                for (final String o in <String>['o1', 'o2', 'o3']) ...<(String, Finder)>[
                  ('place $o', find.byKey(Key('do-place-$o'))),
                  ('piece $o', find.byKey(Key('do-piece-$o'))),
                ],
              ];
              for (final (String name, Finder f) in others) {
                if (f.evaluate().isEmpty) continue;
                expect(
                  _overlaps(card, t.getRect(f)),
                  isFalse,
                  reason: '${b.key} $course $mode: the card $card lies over the $name ${t.getRect(f)}',
                );
              }
              await r.done(t);
            }
          },
        );
      }
    }
  });

  // ---------------------------------------------------------------------------------------------------------------------------------
  group(
    'QA-L4-4, re-verified in every choice template the plan names: the lamp three times shows the answer',
    () {
      testWidgets(
        'place, drag, buttons and cards (listen_do): level 3 asked with the lamp marks the right one',
        (WidgetTester t) async {
          final LangPack p = LangPack('eng')
            ..addPictures(<String>[
              'table',
              'ball',
              'apple',
              'banana',
              'cat',
              'dog',
              'duck',
              'teddy',
              'mika_body',
            ]);
          p.add(
            listenDoJson(
              id: 'place1',
              mode: 'place',
              picture: 'table',
              thing: <String, Object?>{'sprite': 'asset:ball', 'at': at(0.04, 0.4, 0.22, 0.22)},
              options: <Map<String, Object?>>[
                partOption('o1', at(0.4, 0.04, 0.5, 0.26), label: 'on'),
                partOption('o2', at(0.4, 0.7, 0.5, 0.26), tag: p.tag('lis.sem'), label: 'under'),
              ],
              correct: 'o1',
            ),
          );
          p.add(
            listenDoJson(
              id: 'btn1',
              mode: 'buttons',
              options: <Map<String, Object?>>[
                pictureOption('o1', 'cat'),
                pictureOption('o2', 'dog', tag: p.tag('lis.sem')),
                pictureOption('o3', 'duck', tag: p.tag('lis.guess')),
              ],
              correct: 'o1',
            ),
          );
          for (final String id in <String>['place1', 'btn1']) {
            final Rig<ListenDoSession> r = _doRig(p, id);
            await r.pump(t);
            for (int i = 0; i < 3; i++) {
              await t.tap(find.byKey(const Key('lesson-hint')));
              await r.wait(t, 3500);
            }
            expect(r.controller.hintShown, 3, reason: id);
            expect(r.controller.answerShown, isTrue, reason: '$id: level 3 shows the answer');
            await r.done(t);
          }
          final LangPack cards = _mapItem(
            'ENG-A-06 i03',
            (_json()['items']! as Map<String, Object?>)['ENG-A-06 i03']! as Map<String, Object?>,
          );
          final Rig<ListenDoSession> c = _doRig(cards, 'item');
          await c.pump(t);
          for (int i = 0; i < 3; i++) {
            await t.tap(find.byKey(const Key('lesson-hint')));
            await c.wait(t, 3500);
          }
          expect(c.controller.hintShown, 3, reason: 'cards');
          expect(c.controller.answerShown, isTrue, reason: 'cards: level 3 shows the answer');
          await c.done(t);
        },
      );
    },
  );

  // ---------------------------------------------------------------------------------------------------------------------------------
  group('the cards mode: a card rings the part it names, both ears for "ears"', () {
    testWidgets(
      'ENG-A-06 i03 (ears, eyes, nose): a wrong card rings its own part; at level 2 the right card rings both ears',
      (WidgetTester t) async {
        final LangPack p = _mapItem(
          'ENG-A-06 i03',
          (_json()['items']! as Map<String, Object?>)['ENG-A-06 i03']! as Map<String, Object?>,
        );
        final Rig<ListenDoSession> r = _doRig(p, 'item');
        await r.pump(t);
        await t.tap(r.tile('o2'));
        await r.wait(t, 100);
        expect(
          find.byKey(const Key('do-part-ring')),
          findsNWidgets(1),
          reason: 'the eyes card: one ring on the eyes',
        );
        await r.wait(t, 1600);
        await t.tap(r.tile('o3'));
        await r.wait(t, 1800);
        expect(r.controller.hintShown, 2);
        expect(
          find.byKey(const Key('do-part-ring')),
          findsNWidgets(2),
          reason: 'level 2: both ears are ringed',
        );
        await r.done(t);
      },
    );
  });

  // ---------------------------------------------------------------------------------------------------------------------------------
  group('the decision: at level 2 of `buttons` the friend does the right action on the stage (no card)', () {
    LangPack buttons() {
      final LangPack p = LangPack('eng')..addPictures(<String>['teddy', 'cat', 'dog', 'duck']);
      p.add(
        listenDoJson(
          id: 'btn1',
          mode: 'buttons',
          options: <Map<String, Object?>>[
            pictureOption('o1', 'cat'),
            pictureOption('o2', 'dog', tag: p.tag('lis.sem')),
            pictureOption('o3', 'duck', tag: p.tag('lis.guess')),
          ],
          correct: 'o1',
        ),
      );
      return p;
    }

    testWidgets(
      'nothing at level 0 and 1; at level 2 the right action; a touched button is what the friend then does; no close-up card',
      (WidgetTester t) async {
        final Rig<ListenDoSession> r = _doRig(buttons(), 'btn1');
        await r.pump(t);
        expect(r.session.reaction, isNull, reason: 'level 0: the friend stands');
        await t.tap(find.byKey(const Key('lesson-hint')));
        await r.wait(t, 3500);
        expect(r.controller.hintShown, 1);
        expect(r.session.reaction, isNull, reason: 'level 1: the command again, the friend still stands');
        await t.tap(r.tile('o2'));
        await r.wait(t, 1700);
        await t.tap(r.tile('o3'));
        await r.wait(t, 1700);
        expect(r.controller.hintShown, 2);
        expect(r.session.reaction, 'asset:cat', reason: 'level 2: the friend does the right action');
        expect(find.byKey(const Key('do-closeup')), findsNothing, reason: 'no card for buttons');
        // the wrong tries were written as they should be, the shown action is not an attempt
        expect(r.written, <String>['incorrect:o2', 'incorrect:o3']);
        await t.tap(r.tile('o1'));
        await r.wait(t, 300);
        expect(r.written.last, 'correct:o1');
        await r.done(t);
      },
    );
  });

  // ---------------------------------------------------------------------------------------------------------------------------------
  group('QA-L4-6, re-verified: a count that is not one of the word\'s writes nothing and costs nothing; one off by one keeps its tag', () {
    LangPack banana() {
      final LangPack p = LangPack('eng')..addPictures(<String>['banana']);
      p.addTag('pa.syll', 'diagnostic');
      p.addTag('pa.weak_syll', 'diagnostic');
      p.add(
        drumJson(
          course: 'eng',
          id: 'banana',
          picture: 'banana',
          beats: 3,
          more: 'eng.pa.syll',
          fewer: 'eng.pa.weak_syll',
        ),
      );
      return p;
    }

    testWidgets(
      'a retry (5 taps) and then the right count: one attempt, correct, no help step, the dots clear in between',
      (WidgetTester t) async {
        final Rig<SoundBoxesSession> r = _drumRig(banana(), 'banana');
        await r.pump(t);
        for (int i = 0; i < 5; i++) {
          await t.tap(find.byKey(const Key('drum')));
          await r.wait(t, 100);
        }
        await t.tap(find.byKey(const Key('drum-done')));
        await r.wait(t, 1600);
        expect(r.attempts, isEmpty);
        expect(r.session.taps, 0);
        for (int i = 0; i < 3; i++) {
          await t.tap(find.byKey(const Key('drum')));
          await r.wait(t, 100);
        }
        await t.tap(find.byKey(const Key('drum-done')));
        await r.wait(t, 1600);
        expect(r.written, hasLength(1));
        expect(r.written.single, startsWith('correct'));
        expect(r.controller.hintShown, 0);
        await r.done(t);
      },
    );

    testWidgets(
      'one more (4) and one fewer (2) keep their misconception tags; a retry is never counted toward the three mistakes',
      (WidgetTester t) async {
        for (final (int n, String tag) in <(int, String)>[(4, 'eng.pa.syll'), (2, 'eng.pa.weak_syll')]) {
          final Rig<SoundBoxesSession> r = _drumRig(banana(), 'banana');
          await r.pump(t);
          for (int i = 0; i < n; i++) {
            await t.tap(find.byKey(const Key('drum')));
            await r.wait(t, 100);
          }
          await t.tap(find.byKey(const Key('drum-done')));
          await r.wait(t, 1600);
          expect(r.attempts.single.misconceptionTag, tag, reason: 'n=$n');
          await r.done(t);
        }
        // five retries in a row: nothing is written and the help does not move
        final Rig<SoundBoxesSession> r = _drumRig(banana(), 'banana');
        await r.pump(t);
        for (int round = 0; round < 5; round++) {
          for (int i = 0; i < 6; i++) {
            await t.tap(find.byKey(const Key('drum')));
            await r.wait(t, 100);
          }
          await t.tap(find.byKey(const Key('drum-done')));
          await r.wait(t, 1600);
        }
        expect(r.attempts, isEmpty);
        expect(r.controller.hintShown, 0);
        expect(r.controller.finished, isFalse);
        await r.done(t);
      },
    );
  });

  // ---------------------------------------------------------------------------------------------------------------------------------
  group('QA-L4-9, re-verified against the numbers of docs/design/languages-l4-layout.md section 5 (stage points; Hebrew mirrors x)', () {
    // board, stage w x h, picture (x, y, side), drum (x, y, side), hands (y, h), dots (y, dot, gap), check (x, y, side)
    const List<
      (
        String,
        Size,
        (double, double, double),
        (double, double, double),
        (double, double),
        (double, double, double),
        (double, double, double),
      )
    >
    spec =
        <
          (
            String,
            Size,
            (double, double, double),
            (double, double, double),
            (double, double),
            (double, double, double),
            (double, double, double),
          )
        >[
          ('phone', Size(330, 253), (8, 8, 96), (159, 8, 116), (132, 34), (182, 18, 8), (246, 169, 72)),
          ('phoneSE', Size(270, 245), (8, 8, 80), (129, 8, 100), (116, 30), (158, 14, 4), (186, 161, 72)),
          (
            'tabletLandscape',
            Size(584, 546),
            (12, 12, 150),
            (253, 16, 240),
            (280, 44),
            (350, 32, 12),
            (476, 438, 96),
          ),
          (
            'tabletPortrait',
            Size(772, 764),
            (12, 12, 180),
            (332, 16, 300),
            (340, 50),
            (420, 36, 12),
            (664, 656, 96),
          ),
        ];
    for (final (
          String board,
          Size stage,
          (double, double, double) pic,
          (double, double, double) drum,
          (double, double) hands,
          (double, double, double) dots,
          (double, double, double) check,
        )
        in spec) {
      testWidgets('$board: the zones are where the design put them', (WidgetTester t) async {
        final List<String> off = <String>[];
        for (final String course in <String>['eng', 'heb']) {
          final LangPack p = LangPack(course)..addPictures(<String>['banana']);
          p.addTag('pa.syll', 'diagnostic');
          p.add(
            drumJson(
              course: course,
              id: 'banana',
              picture: 'banana',
              beats: 3,
              more: p.tag('pa.syll'),
              fewer: p.tag('pa.syll'),
            ),
          );
          final Rig<SoundBoxesSession> r = _drumRig(p, 'banana');
          await r.pump(t, size: boards[board]!);
          // level 2 shows the hands: two lamp touches
          await t.tap(find.byKey(const Key('lesson-hint')));
          await r.wait(t, 300);
          await t.tap(find.byKey(const Key('lesson-hint')));
          await r.wait(t, 3000);
          for (int i = 0; i < 3; i++) {
            await t.tap(find.byKey(const Key('drum')));
            await r.wait(t, 100);
          }
          final Rect st = t.getRect(find.byKey(const Key('drum-stage')));
          // the keyed box is the stage less its padding (0 on the phones, 16 on the tablets): the spec's points are inside the padding
          final Offset pad = Offset((stage.width - st.width) / 2, (stage.height - st.height) / 2);
          if (pad.dx != pad.dy || pad.dx < 0 || pad.dx > 16) {
            off.add('$course stage ${st.size} is not the spec stage less a padding');
          }
          final bool rtl = course == 'heb';
          Rect local(Finder f) => t.getRect(f).shift(-st.topLeft + pad);
          double lx(double x, double w) => rtl ? stage.width - x - w : x;
          void expectRect(String what, Rect got, double x, double y, double w, double h, {double tol = 2.5}) {
            final Rect want = Rect.fromLTWH(lx(x, w), y, w, h);
            if ((got.left - want.left).abs() > tol ||
                (got.top - want.top).abs() > tol ||
                (got.width - want.width).abs() > tol ||
                (got.height - want.height).abs() > tol) {
              off.add('$course $what: $got, the spec says $want');
            }
          }

          expectRect('picture', local(find.byKey(const Key('drum-picture'))), pic.$1, pic.$2, pic.$3, pic.$3);
          expectRect('drum', local(find.byKey(const Key('drum'))), drum.$1, drum.$2, drum.$3, drum.$3);
          expectRect(
            'check',
            local(find.byKey(const Key('drum-done'))),
            check.$1,
            check.$2,
            check.$3,
            check.$3,
          );
          final Rect h = local(find.byKey(const Key('drum-hands')));
          if ((h.top - hands.$1).abs() > 3 || (h.height - hands.$2).abs() > 3)
            off.add('$course hands $h, the spec says y ${hands.$1} h ${hands.$2}');
          final Rect d = local(find.byKey(const Key('drum-dot-0')));
          if ((d.top - dots.$1).abs() > 3 || (d.width - dots.$2).abs() > 2)
            off.add('$course dot $d, the spec says y ${dots.$1} size ${dots.$2}');
          await r.done(t);
        }
        expect(off, isEmpty, reason: '$off');
      });
    }
  });

  // ---------------------------------------------------------------------------------------------------------------------------------
  group('QA-L4-8, re-verified against section 4: a 16:9 page keeps its proportions at a question', () {
    testWidgets(
      'the page is 206 x 116 on the phone and 185 x 104 on the SE (a page of 384 x 216), and 16:9 on the tablets',
      (WidgetTester t) async {
        final LangPack p = LangPack(
          'eng',
        )..addPictures(<String>['story_bounce_1', 'story_bounce_2', 'story_bounce_3', 'cat', 'duck', 'frog']);
        p.add(
          storyJson(
            id: 'tale',
            pages: <Map<String, Object?>>[
              for (int i = 1; i <= 3; i++) storyPage('story_bounce_$i', <String>['vo:eng.t.$i']),
            ],
            pauseAfter: 1,
            options: <Map<String, Object?>>[
              pictureOption('o1', 'duck', clip: 'vo:eng.w.duck'),
              pictureOption('o2', 'cat', tag: p.tag('lis.sem'), clip: 'vo:eng.w.cat'),
              pictureOption('o3', 'frog', tag: p.tag('lis.guess'), clip: 'vo:eng.w.frog'),
            ],
            correct: 'o1',
          ),
        );
        final List<String> off = <String>[];
        for (final MapEntry<String, (double, double)?> b in <String, (double, double)?>{
          'phone': (206, 116),
          'phoneSE': (185, 104),
          'tabletLandscape': null,
          'tabletPortrait': null,
        }.entries) {
          final Rig<StorySession> r = Rig<StorySession>(
            p,
            'tale',
            (LessonController c, Activity a) => StorySession(c, a as StoryActivity),
          );
          await r.pump(t, size: boards[b.key]!);
          for (int i = 0; i < 2; i++) {
            await t.tap(find.byKey(const Key('story-turn')));
            await r.wait(t, 100);
          }
          final Size s = t.getSize(find.byKey(const Key('story-page-1')));
          if ((s.width / s.height - 16 / 9).abs() > 0.03)
            off.add('${b.key}: ${s.width} x ${s.height} is not 16:9');
          if (b.value case final (double, double) want) {
            if ((s.width - want.$1).abs() > 2 || (s.height - want.$2).abs() > 2)
              off.add('${b.key}: ${s.width} x ${s.height}, the spec says $want');
          } else if (s.width < 256) {
            off.add('${b.key}: ${s.width} wide, the tablets show 256 or more');
          }
          // the three options with their speakers stand inside the board, left of the guide on the phones
          final Rect last = t.getRect(find.byKey(const Key('speaker-o3')));
          if (last.right > boards[b.key]!.width - 130 && !b.key.startsWith('tablet'))
            off.add('${b.key}: the last speaker ${last.right} reaches the guide');
          await r.done(t);
        }
        expect(off, isEmpty, reason: '$off');
      },
    );
  });

  // ---------------------------------------------------------------------------------------------------------------------------------
  group('the answer tiles of the choice templates are the band primary target (design-spec 6.1: 96 pt on a phone, 112 on a tablet)', () {
    testWidgets('a story pause and a puppet bubble: every tile on every board', (WidgetTester t) async {
      final LangPack p = LangPack('eng')..addPictures(<String>['cat', 'duck', 'frog', 'dog', 'ball']);
      p.add(
        storyJson(
          id: 'tale',
          pages: <Map<String, Object?>>[
            storyPage('cat', <String>['vo:eng.t.1']),
            storyPage('dog', <String>['vo:eng.t.2']),
          ],
          pauseAfter: 0,
          options: <Map<String, Object?>>[
            pictureOption('o1', 'duck', clip: 'vo:eng.w.1'),
            pictureOption('o2', 'cat', tag: p.tag('lis.sem'), clip: 'vo:eng.w.2'),
            pictureOption('o3', 'frog', tag: p.tag('lis.guess'), clip: 'vo:eng.w.3'),
          ],
          correct: 'o1',
        ),
      );
      p.add(
        puppetJson(
          id: 'bub',
          mode: 'bubble',
          picture: 'cat',
          options: <Map<String, Object?>>[
            pictureOption('o1', 'duck', clip: 'vo:eng.b.1'),
            pictureOption('o2', 'dog', tag: p.tag('lis.sem'), clip: 'vo:eng.b.2'),
            pictureOption('o3', 'ball', tag: p.tag('lis.guess'), clip: 'vo:eng.b.3'),
          ],
          correct: 'o1',
        ),
      );
      final List<String> small = <String>[];
      for (final MapEntry<String, Size> b in boards.entries) {
        final double floor = b.key.startsWith('tablet') ? 112 : 96;
        final Rig<StorySession> s = Rig<StorySession>(
          p,
          'tale',
          (LessonController c, Activity a) => StorySession(c, a as StoryActivity),
        );
        await s.pump(t, size: b.value);
        await t.tap(find.byKey(const Key('story-turn')));
        await s.wait(t, 100);
        for (final String id in <String>['o1', 'o2', 'o3']) {
          final Size z = t.getSize(s.tile(id));
          if (z.width < floor - 0.5 || z.height < floor - 0.5)
            small.add('story ${b.key} $id ${z.width} x ${z.height}, the band wants $floor');
        }
        await s.done(t);
        final Rig<PuppetTalkSession> r = Rig<PuppetTalkSession>(
          p,
          'bub',
          (LessonController c, Activity a) => PuppetTalkSession(c, a as PuppetTalkActivity),
        );
        await r.pump(t, size: b.value);
        for (final String id in <String>['o1', 'o2', 'o3']) {
          final Size z = t.getSize(r.tile(id));
          if (z.width < floor - 0.5 || z.height < floor - 0.5)
            small.add('puppet ${b.key} $id ${z.width} x ${z.height}, the band wants $floor');
        }
        await r.done(t);
      }
      expect(small, isEmpty, reason: '$small');
    });
  });

  // ---------------------------------------------------------------------------------------------------------------------------------
  group('the personal turn\'s cards and pass are a touch of at least 64 pt on every board', () {
    testWidgets('ages 3 to 9 (seven cards) and the family (eight): each card and the pass', (
      WidgetTester t,
    ) async {
      Map<String, Object?> card(String id, int n) => <String, Object?>{
        'id': id,
        'label': '$n',
        'numeral': n,
        'clip': 'vo:eng.card.$id',
      };
      final LangPack p = LangPack('eng')..addPictures(<String>['pip_happy']);
      p.add(
        puppetJson(
          course: 'eng',
          id: 'age',
          mode: 'personal',
          topic: 'age',
          picture: 'pip_happy',
          options: <Map<String, Object?>>[for (int n = 3; n <= 9; n++) card('o${n - 2}', n)],
        ),
      );
      final List<String> small = <String>[];
      for (final MapEntry<String, Size> b in boards.entries) {
        final Rig<PuppetTalkSession> r = Rig<PuppetTalkSession>(
          p,
          'age',
          (LessonController c, Activity a) => PuppetTalkSession(c, a as PuppetTalkActivity),
        );
        await r.pump(t, size: b.value);
        for (final String id in <String>['card-o1', 'card-o2', 'card-o3', 'personal-pass']) {
          final Size s = t.getSize(find.byKey(Key(id)));
          if (s.width < 63.5 || s.height < 63.5) small.add('${b.key} $id ${s.width} x ${s.height}');
        }
        await r.done(t);
      }
      expect(small, isEmpty, reason: '$small');
    });
  });

  // ---------------------------------------------------------------------------------------------------------------------------------
  group('QA-L4-11 (open): a Band A place or drag area is held to the 64 pt floor as a hotspot is', () {
    test('a `place` option of 0.1 of the picture (23 pt on the smallest phone) is refused in Band A', () {
      final LangPack p = LangPack('heb')..addPictures(<String>['table', 'ball']);
      p.add(
        listenDoJson(
          course: 'heb',
          id: 'place1',
          mode: 'place',
          picture: 'table',
          thing: <String, Object?>{'sprite': 'asset:ball', 'at': at(0.04, 0.4, 0.3, 0.3)},
          options: <Map<String, Object?>>[
            partOption('o1', at(0.5, 0.04, 0.1, 0.1), label: 'on'),
            partOption('o2', at(0.5, 0.4, 0.3, 0.25), tag: p.tag('lis.sem'), label: 'under'),
            partOption('o3', at(0.5, 0.7, 0.3, 0.25), tag: p.tag('lis.guess'), label: 'next to'),
          ],
          correct: 'o1',
        ),
      );
      expect(
        _messages(p),
        contains(contains('answer.options[0].at')),
        reason: 'a 23 pt target in Band A passes the validator',
      );
    }, skip: _open ? 'QA-L4-11 open: only `hotspots` has the floor' : false);
  });
}
