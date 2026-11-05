// QA's open defects of milestone L4 (docs/qa/l4-languages-verification.md): QA-L4-1 to QA-L4-10. Each test FAILS until its defect is
// fixed; it is the proof of the fix. All are fixed now (2026-11-05), so every one runs in every build.
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
import 'package:nitznutz/play/sing_along_session.dart';
import 'package:nitznutz/play/sound_boxes_session.dart';
import 'package:nitznutz/play/story_session.dart';

import 'support/golden_comparator.dart';
import 'support/harness.dart';
import 'support/l4_rig.dart';
import 'support/language_content.dart';

/// The floor of a child's touch in Band A (docs/design-spec.md 6.1: "any child control, minimum, engineering floor").
const double _bandAFloor = 64;

List<String> _messages(LangPack p) => <String>[
  for (final Problem x in validatePack(manifest: p.pack.manifest, docs: p.pack.docs, files: p.pack.files))
    '${x.path}: ${x.message}',
];

/// The design-director's tap areas of `mika-body` (`content/languages/pictures/mika-body.hotspots.json`, version 2): for each part, one
/// place or several (either ear), each `[x, y, w, h]` as shares of the picture's side.
Map<String, List<Map<String, Object?>>> _bodyMap() {
  final Map<String, Object?> json = jsonDecode(
    File('../content/languages/pictures/mika-body.hotspots.json').readAsStringSync(),
  ) as Map<String, Object?>;
  final Map<String, Object?> parts = json['parts']! as Map<String, Object?>;
  double n(Object? o) => (o! as num).toDouble();
  return <String, List<Map<String, Object?>>>{
    for (final MapEntry<String, Object?> e in parts.entries)
      e.key: <Map<String, Object?>>[
        for (final List<Object?> r in (e.value! as List<Object?>).cast<List<Object?>>())
          at(n(r[0]), n(r[1]), n(r[2]), n(r[3])),
      ],
  };
}

LangPack _eng(Iterable<String> pictures) {
  final LangPack p = LangPack('eng')
    ..addPictures(pictures)
    ..addPictures(<String>['body_ears', 'body_eyes', 'body_nose', 'body_mouth', 'body_head']);
  p.addTag('lis.l1_guess', 'diagnostic');
  return p;
}

/// ENG-A-06 style: the part [right] is the answer, [near] and [far] the distractors, taken from the real map (first place of each).
Map<String, Object?> _body(String id, String right, String near, String far) {
  final Map<String, List<Map<String, Object?>>> m = _bodyMap();
  return listenDoJson(
    course: 'eng',
    id: id,
    mode: 'hotspots',
    picture: 'mika_body',
    options: <Map<String, Object?>>[
      partOption('o1', m[right]!.first, label: right),
      partOption('o2', m[near]!.first, tag: 'eng.lis.sem', label: near),
      partOption('o3', m[far]!.first, tag: 'eng.lis.l1_guess', label: far),
    ],
    correct: 'o1',
  );
}

/// The item of the design-director's map for the three parts: as touch areas on the body when they can be 64 pt apart there, and as
/// three close-up cards (the friend stays on the stage) when two or more are parts of the face (`show: cards`).
Map<String, Object?> _bodyItem(String id, String right, String near, String far) {
  final Map<String, Object?> items =
      (jsonDecode(File('../content/languages/pictures/mika-body.hotspots.json').readAsStringSync())
              as Map<String, Object?>)['items']!
          as Map<String, Object?>;
  final Map<String, Object?> entry = items.values.cast<Map<String, Object?>>().firstWhere(
    (Map<String, Object?> e) => (e['parts']! as List<Object?>).join(',') == '$right,$near,$far',
  );
  if (entry['show'] != 'cards') return _body(id, right, near, far);
  final Map<String, List<Map<String, Object?>>> m = _bodyMap();
  Map<String, Object?> card(String optionId, String part, {String? tag}) => <String, Object?>{
    'id': optionId,
    'label': part,
    'sprite': 'asset:body_$part',
    'at': m[part],
    'misconception': ?tag,
  };
  return listenDoJson(
    course: 'eng',
    id: id,
    mode: 'cards',
    picture: 'mika_body',
    options: <Map<String, Object?>>[
      card('o1', right),
      card('o2', near, tag: 'eng.lis.sem'),
      card('o3', far, tag: 'eng.lis.l1_guess'),
    ],
    correct: 'o1',
  );
}

Rig<ListenDoSession> _doRig(LangPack p, String id) => Rig<ListenDoSession>(
  p,
  id,
  (LessonController c, Activity a) => ListenDoSession(c, a as ListenDoActivity),
);

void main() {
  setUpAll(() async {
    await loadAppFonts();
    useTolerantGoldens(0.03);
  });

  // ---------------------------------------------------------------------------------------------------------------------------------
  group('QA-L4-1 (major): the hotspots of the real body map are under the Band A touch floor, and the nose is refused', () {
    test('the nose area of the design-director\'s map (ENG-A-06 i03 and i04, the placement probe) passes the validator', () {
      final LangPack p = _eng(<String>['mika_body']);
      p.add(_bodyItem('i04', 'nose', 'mouth', 'ears'));
      expect(_messages(p), isEmpty);
    });

    testWidgets(
      'every part of ENG-A-06 is at least 64 points each way on a phone and a tablet (the stage is 241 pt on the phone)',
      (WidgetTester t) async {
        final List<String> small = <String>[];
        for (final MapEntry<String, Size> b in boards.entries) {
          for (final String part in <String>['head', 'eyes', 'mouth', 'hands', 'feet', 'tummy']) {
            final LangPack p = _eng(<String>['mika_body']);
            final String near = part == 'head' ? 'tummy' : 'head';
            final String far = (part == 'feet' || part == 'tummy') ? 'eyes' : 'feet';
            p.add(_body('i01', part, near, far));
            final Rig<ListenDoSession> r = _doRig(p, 'i01');
            await r.pump(t, size: b.value);
            final Size s = t.getSize(find.byKey(const Key('do-hot-o1')));
            if (s.width < _bandAFloor || s.height < _bandAFloor) {
              small.add('${b.key} $part ${s.width.round()}x${s.height.round()}');
            }
            await r.done(t);
          }
        }
        expect(small, isEmpty, reason: 'targets under 64 pt: $small');
      },
    );
  });

  // ---------------------------------------------------------------------------------------------------------------------------------
  group('QA-L4-2 (major): a body part with two places (ears, hands, arms, fingers) cannot be one option', () {
    test('an option whose `at` is two rectangles (both ears) passes the validator', () {
      final LangPack p = _eng(<String>['mika_body']);
      final Map<String, List<Map<String, Object?>>> m = _bodyMap();
      expect(m['ears']!, hasLength(2), reason: 'the map itself has two places for the ears');
      p.add(
        listenDoJson(
          course: 'eng',
          id: 'ears',
          mode: 'hotspots',
          picture: 'mika_body',
          options: <Map<String, Object?>>[
            <String, Object?>{'id': 'o1', 'label': 'ears', 'at': m['ears']},
            // the other two parts stand clear of both ears (the map's own areas of parts that never meet in one item overlap)
            partOption('o2', at(0.35, 0.41, 0.3, 0.29), tag: 'eng.lis.sem', label: 'eyes'),
            partOption('o3', at(0.35, 0.71, 0.3, 0.29), tag: 'eng.lis.l1_guess', label: 'mouth'),
          ],
          correct: 'o1',
        ),
      );
      expect(_messages(p), isEmpty);
    });
  });

  // ---------------------------------------------------------------------------------------------------------------------------------
  group('QA-L4-3 (major): the level 2 close-up card of a command covers the place the child must touch', () {
    testWidgets(
      'after two mistakes the right place (HEB-A-04.1, "on the chair": the top right of the scene) can still be touched',
      (WidgetTester t) async {
        final LangPack p = LangPack('heb')..addPictures(<String>['scene_room', 'ball']);
        p.addTag('ol.prep', 'diagnostic');
        p.add(
          listenDoJson(
            course: 'heb',
            id: 'place1',
            mode: 'place',
            picture: 'scene_room',
            thing: <String, Object?>{'sprite': 'asset:ball', 'at': at(0.04, 0.4, 0.22, 0.22)},
            options: <Map<String, Object?>>[
              partOption('o1', at(0.4, 0.04, 0.5, 0.26), label: 'on'),
              partOption('o2', at(0.4, 0.7, 0.5, 0.26), tag: 'heb.ol.prep', label: 'under'),
              partOption('o3', at(0.72, 0.36, 0.25, 0.26), tag: 'heb.ol.prep', label: 'next to'),
            ],
            correct: 'o1',
          ),
        );
        final Rig<ListenDoSession> r = _doRig(p, 'place1');
        await r.pump(t);
        await t.tap(find.byKey(const Key('do-place-o2')));
        await r.wait(t, 1600);
        await t.tap(find.byKey(const Key('do-place-o3')));
        await r.wait(t, 1600);
        expect(r.controller.hintShown, 2);
        expect(find.byKey(const Key('do-closeup')), findsOneWidget);
        final Rect card = t.getRect(find.byKey(const Key('do-closeup')));
        final Offset centre = t.getCenter(find.byKey(const Key('do-place-o1')));
        expect(
          card.contains(centre),
          isFalse,
          reason:
              'the card $card lies over the centre $centre of the right place: a touch there goes to the card',
        );
        await r.done(t);
      },
    );
  });

  // ---------------------------------------------------------------------------------------------------------------------------------
  group('QA-L4-4 (major): level 3 asked for with the lamp marks no answer in the choice templates', () {
    testWidgets(
      'a bubble of the puppet: the lamp three times, and the right bubble is shown (halo, the others dimmed)',
      (WidgetTester t) async {
        final LangPack p = _eng(<String>['mika_icecream', 'mika_sad', 'mika_happy', 'pip_leave']);
        p.add(
          puppetJson(
            course: 'eng',
            id: 'bub',
            mode: 'bubble',
            picture: 'mika_icecream',
            key: <String, Object?>{'at': at(0.3, 0.1, 0.4, 0.4)},
            options: <Map<String, Object?>>[
              pictureOption('o1', 'mika_sad', clip: 'vo:eng.im.sad'),
              pictureOption('o2', 'mika_happy', tag: 'eng.lis.sem', clip: 'vo:eng.im.happy'),
              pictureOption('o3', 'pip_leave', tag: 'eng.lis.l1_guess', clip: 'vo:eng.goodbye'),
            ],
            correct: 'o1',
          ),
        );
        final Rig<PuppetTalkSession> r = Rig<PuppetTalkSession>(
          p,
          'bub',
          (LessonController c, Activity a) => PuppetTalkSession(c, a as PuppetTalkActivity),
        );
        await r.pump(t);
        for (int i = 0; i < 3; i++) {
          await t.tap(find.byKey(const Key('lesson-hint')));
          await r.wait(t, 4500);
        }
        expect(r.controller.hintShown, 3);
        expect(r.controller.answerShown, isTrue, reason: 'level 3 is "show me": the answer is shown');
        await r.done(t);
      },
    );

    testWidgets('a dialogic story and a hotspot command: the lamp three times shows the answer', (
      WidgetTester t,
    ) async {
      final LangPack p = _eng(<String>[
        'mika_body',
        for (int i = 1; i <= 3; i++) 'story_bounce_$i',
        'cat',
        'duck',
        'frog',
      ]);
      p.add(
        storyJson(
          course: 'eng',
          id: 'tale',
          pages: <Map<String, Object?>>[
            for (int i = 1; i <= 3; i++) storyPage('story_bounce_$i', <String>['vo:eng.t.$i']),
          ],
          pauseAfter: 1,
          options: <Map<String, Object?>>[
            pictureOption('o1', 'duck', clip: 'vo:eng.w.duck'),
            pictureOption('o2', 'cat', tag: 'eng.lis.story_recall', clip: 'vo:eng.w.cat'),
            pictureOption('o3', 'frog', tag: 'eng.lis.sem', clip: 'vo:eng.w.frog'),
          ],
          correct: 'o1',
        ),
      );
      // the tag `story_recall` is the catalogue's; the fixture pack holds `lis.sem` and `lis.l1_guess`
      p.addTag('lis.story_recall', 'diagnostic');
      final Rig<StorySession> s = Rig<StorySession>(
        p,
        'tale',
        (LessonController c, Activity a) => StorySession(c, a as StoryActivity),
      );
      await s.pump(t);
      for (int i = 0; i < 2; i++) {
        await t.tap(find.byKey(const Key('story-turn')));
        await s.wait(t, 100);
      }
      for (int i = 0; i < 3; i++) {
        await t.tap(find.byKey(const Key('lesson-hint')));
        await s.wait(t, 4000);
      }
      expect(s.controller.hintShown, 3);
      expect(s.controller.answerShown, isTrue, reason: 'story: level 3 shows the answer');
      await s.done(t);

      final LangPack q = _eng(<String>['mika_body']);
      q.add(_body('i01', 'head', 'tummy', 'feet'));
      final Rig<ListenDoSession> h = _doRig(q, 'i01');
      await h.pump(t);
      for (int i = 0; i < 3; i++) {
        await t.tap(find.byKey(const Key('lesson-hint')));
        await h.wait(t, 2500);
      }
      expect(h.controller.hintShown, 3);
      expect(h.controller.answerShown, isTrue, reason: 'hotspots: level 3 shows the part');
      await h.done(t);
    });
  });

  // ---------------------------------------------------------------------------------------------------------------------------------
  group('QA-L4-5 (minor): the rhyme ladder\'s level 3 does not play the whole verse', () {
    testWidgets(
      'after three mistakes the whole verse is heard with the right picture lit (the acceptance of LS12.3 and HEB-A-06)',
      (WidgetTester t) async {
        final LangPack p = LangPack('heb')..addPictures(<String>['window', 'sun', 'basket', 'cat']);
        p.addTag('pa.allit', 'diagnostic');
        p.add(
          singJson(
            course: 'heb',
            id: 'verse2',
            pictures: <Map<String, Object?>>[songPicture('cat')],
            verse: <String, Object?>{
              'whole': <String>['vo:heb.v2.whole'],
              'open': <String>['vo:heb.v2.open'],
              'full': <String>['vo:heb.v2.full'],
              'cue': <String>['vo:heb.v2.e'],
            },
            options: <Map<String, Object?>>[
              pictureOption('o1', 'window', clip: 'vo:heb.w.window'),
              pictureOption('o2', 'sun', tag: 'heb.pa.allit', clip: 'vo:heb.w.sun'),
              pictureOption('o3', 'basket', tag: 'heb.lis.sem', clip: 'vo:heb.w.basket'),
            ],
            correct: 'o1',
          ),
        );
        final Rig<SingAlongSession> r = Rig<SingAlongSession>(
          p,
          'verse2',
          (LessonController c, Activity a) => SingAlongSession(c, a as SingAlongActivity),
        );
        await r.pump(t);
        await r.wait(t, 2000);
        await t.tap(r.tile('o2'));
        await r.wait(t, 1600);
        await t.tap(r.tile('o3'));
        await r.wait(t, 1600);
        r.heard.clear();
        await t.tap(r.tile('o2'));
        await r.wait(t, 4000);
        expect(r.controller.hintShown, 3);
        expect(
          r.heard.clips,
          contains('vo:heb.v2.full'),
          reason: 'level 3: the whole verse, the right picture lit',
        );
        await r.done(t);
      },
    );
  });

  // ---------------------------------------------------------------------------------------------------------------------------------
  group('QA-L4-6 (major): a drum count that is off by two or more writes an incorrect attempt', () {
    testWidgets(
      'banana (3 beats) drummed 5 times and "that\'s all": a retry with no tag and no evidence, so no attempt, no hint step',
      (WidgetTester t) async {
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
        for (final int n in <int>[1, 5, 9]) {
          final Rig<SoundBoxesSession> r = Rig<SoundBoxesSession>(
            p,
            'banana',
            (LessonController c, Activity a) => SoundBoxesSession(c, a as SoundBoxesActivity),
          );
          await r.pump(t);
          for (int i = 0; i < n; i++) {
            await t.tap(find.byKey(const Key('drum')));
            await r.wait(t, 100);
          }
          await t.tap(find.byKey(const Key('drum-done')));
          await r.wait(t, 1600);
          expect(r.attempts, isEmpty, reason: 'n=$n: nothing is written for a retry');
          expect(r.controller.hintShown, 0, reason: 'n=$n: no help is escalated by a retry');
          expect(r.session.taps, 0, reason: 'n=$n: the child may drum it again');
          await r.done(t);
        }
      },
    );
  });

  // ---------------------------------------------------------------------------------------------------------------------------------
  group(
    'QA-L4-7 (major, content): the English batch names a placement probe that the validator must refuse',
    () {
      test('every probe (P) of the English batch is an LS01, LS03 or LS06 item (frame 2.3, LS13): ENG-A-06 i04 is an LS11 hotspot', () {
        final List<String> rows = File('../docs/languages/english/band-a-content.md')
            .readAsLinesSync()
            .where((String l) => RegExp(r'^\| [a-z]\d+ \*\*P\*\* \|').hasMatch(l))
            .toList();
        expect(rows, hasLength(10), reason: 'ten probes are marked');
        final List<String> bad = <String>[
          for (final String l in rows)
            if (!RegExp(r'^\| \S+ \*\*P\*\* \| LS0[136]\b').hasMatch(l)) l.split('|').take(3).join('|'),
        ];
        expect(bad, isEmpty, reason: 'a probe the placement document cannot hold: $bad');
      });
    },
  );
  // ---------------------------------------------------------------------------------------------------------------------------------
  group('QA-L4-8 (major): on a phone the picture a question is about is a thumbnail', () {
    testWidgets(
      'a story\'s pause and a puppet\'s bubble show their picture at least 96 points wide on every board',
      (WidgetTester t) async {
        final LangPack p = _eng(<String>['cat', 'duck', 'frog']);
        p.add(
          storyJson(
            course: 'eng',
            id: 'tale',
            pages: <Map<String, Object?>>[
              storyPage('cat', <String>['vo:eng.t.1']),
              storyPage('duck', <String>['vo:eng.t.2']),
              storyPage('frog', <String>['vo:eng.t.3']),
            ],
            pauseAfter: 1,
            options: <Map<String, Object?>>[
              pictureOption('o1', 'duck', clip: 'vo:eng.w.duck'),
              pictureOption('o2', 'cat', tag: 'eng.lis.sem'),
              pictureOption('o3', 'frog', tag: 'eng.lis.l1_guess'),
            ],
            correct: 'o1',
          ),
        );
        p.add(
          puppetJson(
            course: 'eng',
            id: 'bub',
            mode: 'bubble',
            picture: 'cat',
            options: <Map<String, Object?>>[
              pictureOption('o1', 'duck', clip: 'vo:eng.w.duck'),
              pictureOption('o2', 'cat', tag: 'eng.lis.sem', clip: 'vo:eng.x'),
              pictureOption('o3', 'frog', tag: 'eng.lis.l1_guess', clip: 'vo:eng.y'),
            ],
            correct: 'o1',
          ),
        );
        final List<String> small = <String>[];
        for (final MapEntry<String, Size> b in boards.entries) {
          final Rig<StorySession> s = Rig<StorySession>(
            p,
            'tale',
            (LessonController c, Activity a) => StorySession(c, a as StoryActivity),
          );
          await s.pump(t, size: b.value);
          for (int i = 0; i < 2; i++) {
            await t.tap(find.byKey(const Key('story-turn')));
            await s.wait(t, 100);
          }
          final double w = t.getSize(find.byKey(const Key('story-page-1'))).width;
          if (w < 96) small.add('story ${b.key} ${w.round()}');
          await s.done(t);
          final Rig<PuppetTalkSession> r = Rig<PuppetTalkSession>(
            p,
            'bub',
            (LessonController c, Activity a) => PuppetTalkSession(c, a as PuppetTalkActivity),
          );
          await r.pump(t, size: b.value);
          final double v = t.getSize(find.byKey(const Key('puppet-scene'))).width;
          if (v < 96) small.add('puppet ${b.key} ${v.round()}');
          await r.done(t);
        }
        expect(small, isEmpty, reason: 'thumbnails (the tablets show 256 pt): $small');
      },
    );
  });

  // ---------------------------------------------------------------------------------------------------------------------------------
  group('QA-L4-9 (major): on the phones the "that\'s all" check mark sits on the drum, and over the third clapping hand', () {
    testWidgets('the check mark does not overlap the drum\'s tap area, nor the hands of the second hint', (
      WidgetTester t,
    ) async {
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
      final List<String> clashes = <String>[];
      for (final MapEntry<String, Size> b in boards.entries) {
        final Rig<SoundBoxesSession> r = Rig<SoundBoxesSession>(
          p,
          'banana',
          (LessonController c, Activity a) => SoundBoxesSession(c, a as SoundBoxesActivity),
        );
        await r.pump(t, size: b.value);
        for (int i = 0; i < 3; i++) {
          await t.tap(find.byKey(const Key('drum')));
          await r.wait(t, 100);
        }
        final Rect drum = t.getRect(find.byKey(const Key('drum')));
        final Rect done = t.getRect(find.byKey(const Key('drum-done')));
        if (drum.overlaps(done)) {
          clashes.add('${b.key}: the check mark overlaps the drum by ${drum.intersect(done)}');
        }
        await r.done(t);

        final Rig<SoundBoxesSession> h = Rig<SoundBoxesSession>(
          p,
          'banana',
          (LessonController c, Activity a) => SoundBoxesSession(c, a as SoundBoxesActivity),
        );
        await h.pump(t, size: b.value);
        await t.tap(find.byKey(const Key('lesson-hint')));
        await h.wait(t, 300);
        await t.tap(find.byKey(const Key('lesson-hint')));
        await h.wait(t, 3000);
        final Rect check = t.getRect(find.byKey(const Key('drum-done')));
        for (final Element e in find.byIcon(Icons.back_hand_rounded).evaluate()) {
          final Rect hand = t.getRect(find.byElementPredicate((Element x) => x == e));
          if (hand.overlaps(check)) clashes.add('${b.key}: a clapping hand is under the check mark ($hand)');
        }
        await h.done(t);
      }
      expect(clashes, isEmpty, reason: '$clashes');
    });
  });
  // ---------------------------------------------------------------------------------------------------------------------------------
  group(
    'QA-L4-10 (minor, content or template): the English family turn has ten cards, the template takes eight',
    () {
      test('the cards of ENG-A-07 p01 (the family) fit the schema\'s limit of eight, or the validator takes the ten', () {
        final String row = File('../docs/languages/english/band-a-content.md')
            .readAsLinesSync()
            .firstWhere((String l) => l.startsWith('| p01 *not scored* | LS10 personal (family)'));
        final String cards = row
            .split('cards (any number, each plays its word): ')
            .last
            .split('; pass')
            .first
            .replaceAll(RegExp(r'\([^)]*\)'), '');
        final List<String> words = cards
            .split(',')
            .map((String w) => w.trim())
            .where((String w) => w.isNotEmpty)
            .toList();
        expect(
          words,
          hasLength(8),
          reason:
              'mom, dad, baby, brother, sister, grandma, grandpa, someone else (cousin and pet go under it)',
        );
        // `activity.eng.fam.json › answer.options: 10 items is outside 0 to 8` (pack_validation, checked by hand on 2026-11-04)
        expect(words.length, lessThanOrEqualTo(8), reason: 'a personal turn holds at most 8 cards');
      });
    },
  );
}
