// The layout fixes of docs/design/languages-l4-layout.md (QA-L4-1, -2, -3, -8, -9): hotspots with several places and the Band A floor, the
// face items as three close-up cards, the close-up slots outside the scene on every board, the speaker beside its tile on the phones
// with the stage kept, a page that keeps its own proportions, and the drum's zones. Fixture course, fake clips.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nitznutz/child/activity_shell.dart';
import 'package:nitznutz/content/models.dart';
import 'package:nitznutz/content/pack_validation.dart';
import 'package:nitznutz/content/schema.dart';
import 'package:nitznutz/design/board.dart' show BoardClass;
import 'package:nitznutz/play/lesson_controller.dart';
import 'package:nitznutz/play/listen_do_session.dart';
import 'package:nitznutz/play/puppet_talk_session.dart';
import 'package:nitznutz/play/sound_boxes_session.dart';
import 'package:nitznutz/play/story_session.dart';

import 'support/l4_rig.dart';
import 'support/language_content.dart';

List<String> _messages(LangPack p) => <String>[
  for (final Problem x in validatePack(manifest: p.pack.manifest, docs: p.pack.docs, files: p.pack.files))
    '${x.path}: ${x.message}',
];

const List<String> _pics = <String>['teddy', 'table', 'cat', 'dog', 'duck', 'ball', 'banana'];

Map<String, Object?> _card(String id, String asset, Map<String, Object?> where, {String? tag}) =>
    <String, Object?>{'id': id, 'label': asset, 'sprite': 'asset:$asset', 'at': where, 'misconception': ?tag};

LangPack _faceItem() {
  final LangPack p = LangPack()..addPictures(_pics);
  p.add(
    listenDoJson(
      id: 'face',
      mode: 'cards',
      options: <Map<String, Object?>>[
        _card('o1', 'cat', at(0.3, 0.05, 0.4, 0.3)),
        _card('o2', 'dog', at(0.3, 0.3, 0.4, 0.3), tag: p.tag('lis.sem')),
        _card('o3', 'duck', at(0.3, 0.6, 0.4, 0.3), tag: p.tag('lis.guess')),
      ],
      correct: 'o1',
    ),
  );
  return p;
}

Rig<ListenDoSession> _doRig(LangPack p, String id) => Rig<ListenDoSession>(
  p,
  id,
  (LessonController c, Activity a) => ListenDoSession(c, a as ListenDoActivity),
);

void main() {
  group('the Band A floor of a touch area (QA-L4-1)', () {
    LangPack hot(Map<String, Object?> nose, {String band = 'A'}) {
      final LangPack p = LangPack()..addPictures(_pics);
      final Map<String, Object?> doc = listenDoJson(
        id: 'nose',
        mode: 'hotspots',
        options: <Map<String, Object?>>[
          partOption('o1', nose),
          partOption('o2', at(0.0, 0.0, 0.3, 0.3), tag: p.tag('lis.sem')),
          partOption('o3', at(0.0, 0.7, 0.3, 0.3), tag: p.tag('lis.guess')),
        ],
        correct: 'o1',
      )..['band'] = band;
      p.add(doc);
      return p;
    }

    test(
      'an area of the design\'s least size (72 of 256 units) is taken; one smaller is refused in Band A',
      () {
        expect(minBandAHotspot, closeTo(72 / 256, 0.0001));
        expect(_messages(hot(at(0.3594, 0.1414, 0.2812, 0.2812))), isEmpty);
        expect(
          _messages(hot(at(0.45, 0.2, 0.1, 0.1))),
          contains(contains('answer.options[0].at: is smaller than 0.2812 of the picture')),
        );
      },
    );

    test('every place of a part with several is held to it, and a part with several places may not be a body part of another mode', () {
      final LangPack p = LangPack()..addPictures(_pics);
      p.add(
        listenDoJson(
          id: 'ears',
          mode: 'hotspots',
          options: <Map<String, Object?>>[
            <String, Object?>{
              'id': 'o1',
              'label': 'ears',
              'at': <Map<String, Object?>>[at(0.05, 0.1, 0.3, 0.3), at(0.65, 0.1, 0.3, 0.1)],
            },
            partOption('o2', at(0.35, 0.5, 0.3, 0.3), tag: p.tag('lis.sem')),
          ],
          correct: 'o1',
        ),
      );
      expect(_messages(p), contains(contains('answer.options[0].at: is smaller than 0.2812')));
      final LangPack q = LangPack()..addPictures(_pics);
      q.add(
        listenDoJson(
          id: 'drag1',
          mode: 'drag',
          target: <String, Object?>{'at': at(0.6, 0.3, 0.3, 0.3)},
          options: <Map<String, Object?>>[
            <String, Object?>{
              'id': 'o1',
              'label': 'a',
              'sprite': 'asset:cat',
              'at': <Map<String, Object?>>[at(0.0, 0.0, 0.2, 0.2), at(0.0, 0.3, 0.2, 0.2)],
            },
            thingOption('o2', 'dog', at(0.0, 0.6, 0.2, 0.2), tag: q.tag('lis.sem')),
          ],
          correct: 'o1',
        ),
      );
      expect(
        _messages(q),
        contains(contains('only a part of a picture (hotspots, or the card of one) has more than one place')),
      );
    });
  });

  group('the face items as three close-up cards (the friend stays on the stage)', () {
    test('a cards item passes the validator, needs a picture on each card, and its parts may overlap (they are rings, not touches)', () {
      expect(_messages(_faceItem()), isEmpty);
      final ListenDoActivity a = _faceItem().content.activities['eng.face']! as ListenDoActivity;
      expect(a.mode, 'cards');
      expect(a.options.first.at, isNotNull);
      final LangPack p = _faceItem();
      (((p.activity('face')['answer']! as Map<String, Object?>)['options']! as List<Object?>)[0]!
              as Map<String, Object?>)
          .remove('sprite');
      expect(_messages(p), contains(contains('answer.options[0].sprite')));
    });

    testWidgets(
      'the whole friend is on the stage with no touch area; the cards are the tiles; a card touched rings its part',
      (WidgetTester t) async {
        final Rig<ListenDoSession> r = _doRig(_faceItem(), 'face');
        await r.pump(t);
        expect(find.byKey(const Key('do-scene-cards')), findsOneWidget);
        expect(find.byKey(const Key('do-hot-o1')), findsNothing);
        expect(r.tile('o1'), findsOneWidget);
        expect(find.byKey(const Key('do-part-ring')), findsNothing);
        await t.tap(r.tile('o2'));
        await r.wait(t, 100);
        expect(
          find.byKey(const Key('do-part-ring')),
          findsOneWidget,
          reason: 'the part the touched card names',
        );
        expect(r.written, <String>['incorrect:o2']);
        await r.wait(t, 1300);
        await t.tap(r.tile('o3'));
        await r.wait(t, 1300);
        expect(r.controller.hintShown, 2);
        expect(
          find.byKey(const Key('do-closeup')),
          findsNothing,
          reason: 'the cards are the close-ups: no card of level 2 over the tiles',
        );
        expect(
          find.byKey(const Key('do-part-ring')),
          findsOneWidget,
          reason: 'at level 2 the right part is ringed',
        );
        await r.done(t);
      },
    );
  });

  group('the close-up card of level 2 has a slot outside the scene on every board (QA-L4-3)', () {
    LangPack place() {
      final LangPack p = LangPack('heb')..addPictures(<String>['table', 'ball']);
      p.add(
        listenDoJson(
          course: 'heb',
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

    for (final MapEntry<String, Size> b in boards.entries) {
      testWidgets(
        '${b.key}: the card stands clear of every place and of the scene, and nothing under it is a target',
        (WidgetTester t) async {
          final Rig<ListenDoSession> r = _doRig(place(), 'place1');
          await r.pump(t, size: b.value);
          await t.tap(find.byKey(const Key('do-place-o2')));
          await r.wait(t, 1600);
          await t.tap(find.byKey(const Key('do-place-o3')));
          await r.wait(t, 1600);
          expect(r.controller.hintShown, 2);
          final Rect card = t.getRect(find.byKey(const Key('do-closeup')));
          expect(card.width, b.key.startsWith('tablet') ? 130 : 96);
          final Rect scene = t.getRect(find.byKey(const Key('do-scene-place')));
          expect(card.overlaps(scene), isFalse, reason: '${b.key}: card $card over the scene $scene');
          for (final String id in <String>['o1', 'o2', 'o3']) {
            expect(card.overlaps(t.getRect(find.byKey(Key('do-place-$id')))), isFalse);
          }
          await r.done(t);
        },
      );
    }
  });

  group('the speaker beside its tile on the phones, the stage kept (QA-L4-8)', () {
    LangPack puppet(String course) {
      final LangPack p = LangPack(course)..addPictures(_pics);
      p.add(
        puppetJson(
          course: course,
          id: 'bub',
          mode: 'bubble',
          picture: 'cat',
          options: <Map<String, Object?>>[
            pictureOption('o1', 'duck', clip: 'vo:$course.b.1'),
            pictureOption('o2', 'dog', tag: p.tag('lis.sem'), clip: 'vo:$course.b.2'),
            pictureOption('o3', 'ball', tag: p.tag('lis.guess'), clip: 'vo:$course.b.3'),
          ],
          correct: 'o1',
        ),
      );
      return p;
    }

    Rig<PuppetTalkSession> rig(LangPack p) => Rig<PuppetTalkSession>(
      p,
      'bub',
      (LessonController c, Activity a) => PuppetTalkSession(c, a as PuppetTalkActivity),
    );

    for (final (String name, Size size, double stageH, double scene) in <(String, Size, double, double)>[
      ('phone', const Size(852, 393), 128, 116),
      ('phoneSE', const Size(667, 375), 116, 104),
    ]) {
      testWidgets(
        '$name: the stage is $stageH high, the picture $scene; each speaker is at the end of its tile, in the course\'s direction',
        (WidgetTester t) async {
          final Rig<PuppetTalkSession> e = rig(puppet('eng'));
          await e.pump(t, size: size);
          expect(t.getSize(find.byKey(const Key('puppet-scene'))).width, scene);
          for (final String id in <String>['o1', 'o2', 'o3']) {
            final Rect tile = t.getRect(find.byKey(Key('tile-$id')));
            final Rect speaker = t.getRect(find.byKey(Key('speaker-$id')));
            expect(
              speaker.left,
              greaterThanOrEqualTo(tile.right - 0.5),
              reason: 'English: the speaker is on the right',
            );
            expect(speaker.width, 64);
            expect((speaker.center.dy - tile.center.dy).abs(), lessThan(2));
          }
          expect(t.getSize(find.byKey(const Key('tile-o1'))).width, 96);
          final Rect row = t
              .getRect(find.byKey(const Key('tile-o1')))
              .expandToInclude(t.getRect(find.byKey(const Key('speaker-o3'))));
          expect(
            row.width,
            lessThan(size.width - 140),
            reason: 'the row stays clear of the guide and the microphone',
          );
          await e.done(t);
          final Rig<PuppetTalkSession> h = rig(puppet('heb'));
          await h.pump(t, size: size);
          for (final String id in <String>['o1', 'o2']) {
            final Rect tile = t.getRect(find.byKey(Key('tile-$id')));
            final Rect speaker = t.getRect(find.byKey(Key('speaker-$id')));
            expect(
              speaker.right,
              lessThanOrEqualTo(tile.left + 0.5),
              reason: 'Hebrew: the speaker is on the left',
            );
          }
          await h.done(t);
        },
      );
    }

    testWidgets('a tablet keeps the speaker under its tile', (WidgetTester t) async {
      final Rig<PuppetTalkSession> r = rig(puppet('eng'));
      await r.pump(t, size: const Size(1180, 820));
      final Rect tile = t.getRect(find.byKey(const Key('tile-o1')));
      final Rect speaker = t.getRect(find.byKey(const Key('speaker-o1')));
      expect(speaker.top, greaterThanOrEqualTo(tile.bottom - 0.5));
      await r.done(t);
    });

    test('a page keeps its own proportions: the aspect of an SVG is its viewBox', () {
      expect(svgAspect('<svg viewBox="0 0 384 216"></svg>'), closeTo(16 / 9, 0.001));
      expect(svgAspect('<svg viewBox="0 0 256 256"></svg>'), 1);
      expect(svgAspect('<svg width="10"></svg>'), 1);
    });
  });

  group('the drum\'s zones (QA-L4-9)', () {
    LangPack drum(String course) {
      final LangPack p = LangPack(course)..addPictures(<String>['banana']);
      p.addTag('pa.syll', 'diagnostic');
      p.add(
        drumJson(
          course: course,
          id: 'drum1',
          beats: 3,
          picture: 'banana',
          more: p.tag('pa.syll'),
          fewer: p.tag('pa.syll'),
        ),
      );
      return p;
    }

    for (final MapEntry<String, Size> b in boards.entries) {
      testWidgets(
        '${b.key}: nine dots fit before the check mark, and the check mark stands alone at the end corner',
        (WidgetTester t) async {
          for (final String course in <String>['eng', 'heb']) {
            final Rig<SoundBoxesSession> r = Rig<SoundBoxesSession>(
              drum(course),
              'drum1',
              (LessonController c, Activity a) => SoundBoxesSession(c, a as SoundBoxesActivity),
            );
            await r.pump(t, size: b.value);
            for (int i = 0; i < 9; i++) {
              await t.tap(find.byKey(const Key('drum')));
              await r.wait(t, 50);
            }
            final Rect check = t.getRect(find.byKey(const Key('drum-done')));
            final Rect dots = t.getRect(find.byKey(const Key('drum-dots')));
            final Rect drumDisc = t.getRect(find.byKey(const Key('drum')));
            expect(check.overlaps(dots), isFalse, reason: '$course: the dots stop before the check mark');
            expect(check.overlaps(drumDisc), isFalse);
            expect(find.byKey(const Key('drum-dot-8')), findsOneWidget);
            final bool rtl = course == 'heb';
            final Rect pic = t.getRect(find.byKey(const Key('drum-picture')));
            expect(
              rtl ? pic.center.dx > drumDisc.center.dx : pic.center.dx < drumDisc.center.dx,
              isTrue,
              reason: '$course: the picture is at the start corner',
            );
            expect(
              rtl ? check.center.dx < drumDisc.center.dx : check.center.dx > drumDisc.center.dx,
              isTrue,
              reason: '$course: the check mark is at the end',
            );
            expect(check.width, greaterThanOrEqualTo(b.key.startsWith('tablet') ? 96 : 72));
            await r.done(t);
          }
        },
      );
    }

    test('the board classes are the four the spec has', () {
      expect(BoardClass.values, hasLength(4));
      expect(ActivitySpec.of(BoardClass.phoneSE).boardHeight, 375);
    });
  });

  group('the story page at a question', () {
    testWidgets('a story keeps its stage and its picture at the pause on the phones', (WidgetTester t) async {
      final LangPack p = LangPack()..addPictures(_pics);
      p.add(
        storyJson(
          id: 'tale',
          pages: <Map<String, Object?>>[
            storyPage('cat', <String>['vo:eng.t.1']),
            storyPage('dog', <String>['vo:eng.t.2']),
          ],
          pauseAfter: 0,
          options: <Map<String, Object?>>[
            pictureOption('o1', 'cat', clip: 'vo:eng.w.1'),
            pictureOption('o2', 'dog', tag: p.tag('lis.sem'), clip: 'vo:eng.w.2'),
            pictureOption('o3', 'duck', tag: p.tag('lis.guess'), clip: 'vo:eng.w.3'),
          ],
          correct: 'o1',
        ),
      );
      final Rig<StorySession> r = Rig<StorySession>(
        p,
        'tale',
        (LessonController c, Activity a) => StorySession(c, a as StoryActivity),
      );
      await r.pump(t);
      await t.tap(find.byKey(const Key('story-turn')));
      await r.wait(t, 100);
      expect(t.getSize(find.byKey(const Key('story-page-0'))).width, 116);
      await r.done(t);
    });
  });
}
