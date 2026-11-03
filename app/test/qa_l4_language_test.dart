// QA of milestone L4 (the Band A templates), by the QA engineer, independent of the builder's own tests.
//
// 1. The real items of the three Band A batches (`docs/languages/{english,hebrew,russian}/band-a-content.md`) built as fixture items
//    (their ids, their options, their tags from the frame's catalogue, the real pictures, the real hotspot map) and played through the
//    sessions on the frame of the lesson screen, or through `LessonScreen` with the real database.
// 2. The acceptance items of `docs/milestones/L4.md` section 3, one by one: unscored steps write nothing, the ladders, the distractors,
//    the drum classifier, the placement rules of frame 3.2, the personal turns, the page-turn arrows, the child-space source rules.
//
// The defects found are in `qa_l4_open_defects_test.dart`. Fake clips; no real voice.
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nitznutz/content/models.dart';
import 'package:nitznutz/content/pack_validation.dart';
import 'package:nitznutz/content/schema.dart' show Problem;
import 'package:nitznutz/data/app_database.dart';
import 'package:nitznutz/design/components.dart' show AnswerState;
import 'package:nitznutz/engine/staircase.dart';
import 'package:nitznutz/play/lesson_controller.dart';
import 'package:nitznutz/play/listen_do_session.dart';
import 'package:nitznutz/play/puppet_talk_session.dart';
import 'package:nitznutz/play/sing_along_session.dart';
import 'package:nitznutz/play/sound_boxes_session.dart';
import 'package:nitznutz/play/story_session.dart';
import 'package:nitznutz/play/tap_answer_session.dart';
import 'package:nitznutz/world/language_placement.dart';

import 'support/golden_comparator.dart';
import 'support/harness.dart';
import 'support/l4_golden.dart';
import 'support/l4_rig.dart';
import 'support/language_content.dart';
import 'support/language_screens.dart' show langKid;

// ---- the real material ----------------------------------------------------------------------------------------------------------

/// The tags the Band A batches use, with their engine ids from `docs/languages/frame.md` 4.2 (all diagnostic).
const Map<String, List<String>> _realTags = <String, List<String>>{
  'eng': <String>['lis.l1_guess', 'lis.story_recall', 'pa.syll', 'pa.weak_syll'],
  'heb': <String>[
    // `ol.sem` (M-HEB-SEM) clashes with the fixture pack's own `lis.sem`, so `heb.lis.sem` stands in for it
    'ol.story_seen',
    'ol.story_world',
    'ol.story_role',
    'ol.prep',
    'pa.syll',
    'pa.allit',
  ],
  'rus': <String>['lis.sem', 'voc.sound', 'pho.syll'],
};

LangPack _course(String course, Iterable<String> pictures) {
  final LangPack p = LangPack(course)..addPictures(pictures);
  for (final String slug in _realTags[course]!) {
    // `LangPack` already holds `lis.sem` of every course.
    if (slug == 'lis.sem') continue;
    p.addTag(slug, 'diagnostic');
  }
  return p;
}

List<String> _messages(LangPack p) => <String>[
  for (final Problem x in validatePack(manifest: p.pack.manifest, docs: p.pack.docs, files: p.pack.files))
    '${x.path}: ${x.message}',
];

/// The areas of the design-director's hotspot map of `mika-body` (256 by 256), as shares of the picture. A part with two places
/// (ears, hands) gives its first; a circle gives its bounding square.
Map<String, Map<String, Object?>> _bodyAreas() {
  final Map<String, Object?> json = jsonDecode(
    File('../content/languages/pictures/mika-body.hotspots.json').readAsStringSync(),
  ) as Map<String, Object?>;
  final Map<String, Object?> areas = json['areas']! as Map<String, Object?>;
  Map<String, Object?> share(double x, double y, double w, double h) =>
      at(x / 256, y / 256, w / 256, h / 256);
  final Map<String, Map<String, Object?>> out = <String, Map<String, Object?>>{};
  for (final MapEntry<String, Object?> e in areas.entries) {
    Object? a = e.value;
    if (a is List<Object?>) a = a.first;
    final Map<String, Object?> m = a! as Map<String, Object?>;
    if (m['rect'] != null) {
      final List<Object?> r = m['rect']! as List<Object?>;
      out[e.key] = share(
        (r[0]! as num).toDouble(),
        (r[1]! as num).toDouble(),
        (r[2]! as num).toDouble(),
        (r[3]! as num).toDouble(),
      );
    } else {
      final List<Object?> c = m['circle']! as List<Object?>;
      final double cx = (c[0]! as num).toDouble(),
          cy = (c[1]! as num).toDouble(),
          r = (c[2]! as num).toDouble();
      out[e.key] = share(cx - r, cy - r, 2 * r, 2 * r);
    }
  }
  return out;
}

// ---- LS08: the stories -------------------------------------------------------------------------------------------------------------

/// ENG-A-15 "Bounce, Ball!": six pages, the repeated line, a word to touch on each page; d01 pauses on page 3 (the duck is on the
/// screen, its "Hello, duck!" is the recast) with the options of the batch.
Map<String, Object?> _bounce(LangPack p, {required bool dialogic}) {
  const List<String> things = <String>['ball_red', 'cat', 'duck', 'frog', 'dog', 'dog'];
  return storyJson(
    course: 'eng',
    id: 'bounce',
    pages: <Map<String, Object?>>[
      for (int i = 0; i < 6; i++)
        storyPage(
          'story_bounce_${i + 1}',
          <String>['vo:eng.st.bounce.${i + 1}'],
          words: <Map<String, Object?>>[hotWord('vo:eng.w.${things[i]}')],
        ),
    ],
    pauseAfter: dialogic ? 2 : null,
    question: 'מִי זֶה?',
    options: dialogic
        ? <Map<String, Object?>>[
            pictureOption('o1', 'duck', clip: 'vo:eng.w.duck'),
            pictureOption('o2', 'cat', tag: 'eng.lis.story_recall', clip: 'vo:eng.w.cat'),
            pictureOption('o3', 'frog', tag: 'eng.lis.sem', clip: 'vo:eng.w.frog'),
          ]
        : null,
    correct: dialogic ? 'o1' : null,
  );
}

/// HEB story 1 (the rabbit's ball), five pages; the first pause after page 3 (s1-q1): bush right, tree on the page, window not in it.
Map<String, Object?> _rabbit(LangPack p, {int pauseAfter = 2}) => storyJson(
  course: 'heb',
  id: 'rabbit',
  pages: <Map<String, Object?>>[
    for (int i = 1; i <= 5; i++) storyPage('s1_p$i', <String>['vo:heb.s1.p$i']),
  ],
  pauseAfter: pauseAfter,
  question: 'לְאָן נָפַל הַכַּדּוּר?',
  options: <Map<String, Object?>>[
    pictureOption('o1', 'bush', clip: 'vo:heb.w.bush'),
    pictureOption('o2', 'tree', tag: 'heb.ol.story_seen', clip: 'vo:heb.w.tree'),
    pictureOption('o3', 'window', tag: 'heb.ol.story_world', clip: 'vo:heb.w.window'),
  ],
  correct: 'o1',
);

// ---- LS11: the commands ------------------------------------------------------------------------------------------------------------

Map<String, Object?> _bodyItem(LangPack p, String id, String right, String near, String far) {
  final Map<String, Map<String, Object?>> a = _bodyAreas();
  return listenDoJson(
    course: p.course,
    id: id,
    mode: 'hotspots',
    picture: 'mika_body',
    options: <Map<String, Object?>>[
      partOption('o1', a[right]!, label: right),
      partOption('o2', a[near]!, tag: '${p.course}.lis.sem', label: near),
      partOption('o3', a[far]!, tag: p.course == 'eng' ? 'eng.lis.l1_guess' : 'rus.voc.sound', label: far),
    ],
    correct: 'o1',
  );
}

// ---- the rigs ----------------------------------------------------------------------------------------------------------------------

Rig<StorySession> _storyRig(LangPack p, String id) =>
    Rig<StorySession>(p, id, (LessonController c, Activity a) => StorySession(c, a as StoryActivity));
Rig<ListenDoSession> _doRig(LangPack p, String id) => Rig<ListenDoSession>(
  p,
  id,
  (LessonController c, Activity a) => ListenDoSession(c, a as ListenDoActivity),
);
Rig<SingAlongSession> _singRig(LangPack p, String id) => Rig<SingAlongSession>(
  p,
  id,
  (LessonController c, Activity a) => SingAlongSession(c, a as SingAlongActivity),
);
Rig<PuppetTalkSession> _puppetRig(LangPack p, String id, {bool allowed = true}) => Rig<PuppetTalkSession>(
  p,
  id,
  (LessonController c, Activity a) => PuppetTalkSession(c, a as PuppetTalkActivity, personalAllowed: allowed),
);
Rig<SoundBoxesSession> _drumRig(LangPack p, String id) => Rig<SoundBoxesSession>(
  p,
  id,
  (LessonController c, Activity a) => SoundBoxesSession(c, a as SoundBoxesActivity),
);

Map<String, Object?> _drum(
  String course,
  String id,
  String picture,
  int beats, {
  String? more,
  String? fewer,
  String purpose = 'learn',
}) => drumJson(
  course: course,
  id: id,
  picture: picture,
  beats: beats,
  more: more ?? '$course.pa.syll',
  fewer: fewer ?? (course == 'eng' ? 'eng.pa.weak_syll' : '$course.pa.syll'),
  purpose: purpose,
);

Future<void> _drumTaps(WidgetTester t, Rig<SoundBoxesSession> r, int n) async {
  for (int i = 0; i < n; i++) {
    await t.tap(find.byKey(const Key('drum')));
    await r.wait(t, 100);
  }
}

Future<void> _turn(WidgetTester t, Rig<StorySession> r, [int times = 1]) async {
  for (int i = 0; i < times; i++) {
    await t.tap(find.byKey(const Key('story-turn')));
    await r.wait(t, 100);
  }
}

void main() {
  setUpAll(() async {
    await loadAppFonts();
    useTolerantGoldens(0.03);
  });

  // ===============================================================================================================================
  group('real items: LS08 story', () {
    testWidgets(
      'ENG-A-15 s01, six pages, listen: every page narrated in order, a word touched, nothing written',
      (WidgetTester t) async {
        final LangPack p = _course('eng', <String>[
          for (int i = 1; i <= 6; i++) 'story_bounce_$i',
          'ball_red',
          'cat',
          'duck',
          'frog',
          'dog',
        ]);
        p.add(_bounce(p, dialogic: false));
        expect(_messages(p), isEmpty);
        final Rig<StorySession> r = _storyRig(p, 'bounce');
        await r.pump(t);
        await r.wait(t, 200);
        await t.tap(find.byKey(const Key('story-word-0')));
        await r.wait(t, 100);
        expect(r.heard.calls.last, 'now vo:eng.w.ball_red');
        await _turn(t, r, 5);
        expect(r.session.page, 5);
        expect(r.heard.clips.where((String c) => c.startsWith('vo:eng.st')).toList(), <String>[
          for (int i = 1; i <= 6; i++) 'vo:eng.st.bounce.$i',
        ]);
        await _turn(t, r);
        await r.wait(t, 1800);
        expect(r.controller.finished, isTrue);
        expect(r.attempts, isEmpty);
        await r.done(t);
      },
    );

    testWidgets(
      'ENG-A-15 d01: pause on the duck page, wrong cat and frog give their tags, the recast, the rest of the story',
      (WidgetTester t) async {
        final LangPack p = _course('eng', <String>[
          for (int i = 1; i <= 6; i++) 'story_bounce_$i',
          'ball_red',
          'cat',
          'duck',
          'frog',
          'dog',
        ]);
        p.add(_bounce(p, dialogic: true));
        expect(_messages(p), isEmpty);
        final Rig<StorySession> r = _storyRig(p, 'bounce');
        await r.pump(t);
        await _turn(t, r, 3);
        expect(r.session.asking, isTrue);
        expect(r.session.page, 2);
        await t.tap(r.tile('o2'));
        await r.wait(t, 1600);
        await t.tap(r.tile('o3'));
        await r.wait(t, 1600);
        await t.tap(r.tile('o1'));
        await r.wait(t, 100);
        expect(
          r.attempts.map((AttemptRecord a) => '${a.result}:${a.response}:${a.misconceptionTag}').toList(),
          <String>['incorrect:o2:eng.lis.story_recall', 'incorrect:o3:eng.lis.sem', 'correct:o1:'],
        );
        await r.wait(t, 1800);
        expect(r.session.page, 3);
        await _turn(t, r, 3);
        expect(r.controller.finished, isTrue);
        expect(r.attempts, hasLength(3), reason: 'the rest of the story writes nothing');
        await r.done(t);
      },
    );

    testWidgets(
      'HEB story 1, both pauses as two items of the same pages: the arrow points left, the tags are the story tags',
      (WidgetTester t) async {
        final LangPack p = _course('heb', <String>[
          's1_p1',
          's1_p2',
          's1_p3',
          's1_p4',
          's1_p5',
          'bush',
          'tree',
          'window',
        ]);
        p.add(_rabbit(p));
        expect(_messages(p), isEmpty);
        final Rig<StorySession> r = _storyRig(p, 'rabbit');
        await r.pump(t);
        expect(find.byIcon(Icons.arrow_back_rounded), findsOneWidget);
        await _turn(t, r, 3);
        expect(r.session.asking, isTrue);
        // the options are in a right-to-left row
        expect(t.getCenter(r.tile('o1')).dx, greaterThan(t.getCenter(r.tile('o2')).dx));
        await t.tap(r.tile('o3'));
        await r.wait(t, 1600);
        await t.tap(r.tile('o1'));
        await r.wait(t, 100);
        expect(r.attempts.map((AttemptRecord a) => a.misconceptionTag).toList(), <String>[
          'heb.ol.story_world',
          '',
        ]);
        await r.done(t);
      },
    );

    test('a pause on a page that is not there, and a pause that comes after the last page, are refused or accepted as the plan says', () {
      final LangPack p = _course('heb', <String>[
        's1_p1',
        's1_p2',
        's1_p3',
        's1_p4',
        's1_p5',
        'bush',
        'tree',
        'window',
      ]);
      p.add(_rabbit(p, pauseAfter: 3));
      expect(_messages(p), isEmpty, reason: 's1-q2 pauses after page 4');
      final LangPack q = _course('heb', <String>[
        's1_p1',
        's1_p2',
        's1_p3',
        's1_p4',
        's1_p5',
        'bush',
        'tree',
        'window',
      ]);
      q.add(_rabbit(q, pauseAfter: 5));
      expect(_messages(q), contains(contains('must be a page')));
    });
  });

  // ===============================================================================================================================
  group('real items: LS11 listen and do', () {
    testWidgets(
      'ENG-A-06 i01, i02, i03 on the real hotspot map: each wrong part gives its tag, the right one ends the item',
      (WidgetTester t) async {
        for (final (String id, String right, String near, String far) in <(String, String, String, String)>[
          ('i01', 'head', 'tummy', 'feet'),
          ('i02', 'eyes', 'ears', 'mouth'),
          ('i03', 'ears', 'eyes', 'mouth'),
        ]) {
          final LangPack p = _course('eng', <String>['mika_body']);
          p.add(_bodyItem(p, id, right, near, far));
          expect(_messages(p), isEmpty, reason: '$id: ${_messages(p)}');
          final Rig<ListenDoSession> r = _doRig(p, id);
          await r.pump(t);
          await t.tap(find.byKey(const Key('do-hot-o2')), warnIfMissed: false);
          await r.wait(t, 1600);
          await t.tap(find.byKey(const Key('do-hot-o1')), warnIfMissed: false);
          await r.wait(t, 100);
          expect(r.written, <String>['incorrect:o2', 'correct:o1'], reason: id);
          expect(r.attempts.first.misconceptionTag, 'eng.lis.sem', reason: id);
          await r.done(t);
        }
      },
    );

    testWidgets(
      'ENG-A-02 i09 buttons (jump, stop, listen): the friend shows the chosen action; i10 clap; e01 embodied writes nothing',
      (WidgetTester t) async {
        final LangPack p = _course('eng', <String>['mika_body', 'act_jump', 'act_stop', 'act_listen']);
        p.add(
          listenDoJson(
            course: 'eng',
            id: 'a2i09',
            mode: 'buttons',
            picture: 'mika_body',
            options: <Map<String, Object?>>[
              pictureOption('o1', 'act_jump'),
              pictureOption('o2', 'act_stop', tag: 'eng.lis.sem'),
              pictureOption('o3', 'act_listen', tag: 'eng.lis.l1_guess'),
            ],
            correct: 'o1',
          ),
        );
        p.add(listenDoJson(course: 'eng', id: 'a2e01', mode: 'embodied', picture: 'mika_body'));
        expect(_messages(p), isEmpty);
        final Rig<ListenDoSession> r = _doRig(p, 'a2i09');
        await r.pump(t);
        await t.tap(r.tile('o3'));
        await r.wait(t, 100);
        expect(r.session.reaction, 'asset:act_listen', reason: 'the friend does the chosen action');
        expect(r.attempts.single.misconceptionTag, 'eng.lis.l1_guess');
        await r.wait(t, 1600);
        await t.tap(r.tile('o1'));
        await r.wait(t, 100);
        expect(r.attempts.last.result, 'correct');
        await r.done(t);

        final Rig<ListenDoSession> e = _doRig(p, 'a2e01');
        await e.pump(t);
        await t.tap(find.byKey(const Key('do-done')));
        await e.wait(t, 2000);
        expect(e.attempts, isEmpty, reason: 'embodied: self-report, never counted');
        expect(e.controller.finished, isTrue);
        await e.done(t);
      },
    );

    testWidgets(
      'HEB-A-04.1 place the ball: on the chair, under, next to; both wrong places are the preposition tag',
      (WidgetTester t) async {
        final LangPack p = _course('heb', <String>['scene_room', 'ball', 'chair']);
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
        expect(_messages(p), isEmpty);
        final Rig<ListenDoSession> r = _doRig(p, 'place1');
        await r.pump(t);
        await t.tap(find.byKey(const Key('do-place-o2')));
        await r.wait(t, 1600);
        await t.tap(find.byKey(const Key('do-place-o1')));
        await r.wait(t, 100);
        expect(r.attempts.map((AttemptRecord a) => a.misconceptionTag).toList(), <String>['heb.ol.prep', '']);
        // the other wrong place is the same tag (both "next to" and "under" are the preposition)
        expect(p.content.activities['heb.place1']!.engineTags, <String>{'heb.ol.prep'});
        await r.done(t);
      },
    );

    testWidgets(
      'RUS a07.22 picnic: touch the juice, then the friend\'s plate; a soup is the sound-alike tag, water the neighbour',
      (WidgetTester t) async {
        final LangPack p = _course('rus', <String>['scene_picnic', 'juice', 'soup', 'water', 'plate']);
        p.add(
          listenDoJson(
            course: 'rus',
            id: 'a0722',
            mode: 'drag',
            picture: 'scene_picnic',
            target: <String, Object?>{'at': at(0.58, 0.3, 0.38, 0.38), 'sprite': 'asset:plate'},
            options: <Map<String, Object?>>[
              thingOption('o1', 'juice', at(0.02, 0.05, 0.26, 0.26)),
              thingOption('o2', 'soup', at(0.02, 0.37, 0.26, 0.26), tag: 'rus.voc.sound'),
              thingOption('o3', 'water', at(0.02, 0.69, 0.26, 0.26), tag: 'rus.lis.sem'),
            ],
            correct: 'o1',
          ),
        );
        expect(_messages(p), isEmpty);
        final Rig<ListenDoSession> r = _doRig(p, 'a0722');
        await r.pump(t);
        await t.tap(find.byKey(const Key('do-piece-o2')));
        await t.tap(find.byKey(const Key('do-target')));
        await r.wait(t, 100);
        expect(r.attempts.single.misconceptionTag, 'rus.voc.sound');
        expect(r.session.chosenState, AnswerState.notYet);
        await r.wait(t, 1600);
        await t.tap(find.byKey(const Key('do-piece-o1')));
        await t.tap(find.byKey(const Key('do-target')));
        await r.wait(t, 100);
        expect(r.attempts.last.result, 'correct');
        await r.done(t);
      },
    );
  });

  // ===============================================================================================================================
  group('real items: LS12 sing along', () {
    testWidgets('ENG-A-13 c01 the hello chant: four lines in order, lights follow, nothing is written', (
      WidgetTester t,
    ) async {
      final LangPack p = _course('eng', <String>['act_wave', 'act_clap']);
      p.add(
        singJson(
          course: 'eng',
          id: 'hello',
          pictures: <Map<String, Object?>>[
            songPicture('act_wave', clip: 'vo:eng.w.wave'),
            songPicture('act_clap', clip: 'vo:eng.w.clap'),
          ],
          lines: <Map<String, Object?>>[
            <String, Object?>{
              'clips': <String>['vo:eng.ch.hello.1'],
              'lights': <int>[0],
            },
            <String, Object?>{
              'clips': <String>['vo:eng.ch.hello.2'],
              'lights': <int>[],
            },
            <String, Object?>{
              'clips': <String>['vo:eng.ch.hello.3'],
              'lights': <int>[1],
            },
            <String, Object?>{
              'clips': <String>['vo:eng.ch.hello.4'],
              'lights': <int>[],
            },
          ],
        ),
      );
      expect(_messages(p), isEmpty);
      final Rig<SingAlongSession> r = _singRig(p, 'hello');
      await r.pump(t);
      await r.wait(t, 5000);
      expect(r.heard.clips, <String>[for (int i = 1; i <= 4; i++) 'vo:eng.ch.hello.$i']);
      expect(r.controller.solved || r.controller.finished, isTrue);
      expect(r.attempts, isEmpty);
      await r.wait(t, 2000);
      expect(r.controller.finished, isTrue);
      await r.done(t);
    });

    testWidgets(
      'HEB-A-06.2 the clock verse: whole, up to the gap, then the pictures; sem and allit tags; the whole verse after',
      (WidgetTester t) async {
        final LangPack p = _course('heb', <String>['window', 'sun', 'basket', 'cat']);
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
        expect(_messages(p), isEmpty);
        final Rig<SingAlongSession> r = _singRig(p, 'verse2');
        await r.pump(t);
        await r.wait(t, 2000);
        expect(r.heard.calls, <String>['after vo:heb.v2.whole', 'after vo:heb.v2.open']);
        expect(r.session.asking, isTrue);
        await t.tap(r.tile('o2'));
        await r.wait(t, 1600);
        await t.tap(r.tile('o3'));
        await r.wait(t, 1600);
        await t.tap(r.tile('o1'));
        await r.wait(t, 2500);
        expect(r.attempts.map((AttemptRecord a) => a.misconceptionTag).toList(), <String>[
          'heb.pa.allit',
          'heb.lis.sem',
          '',
        ]);
        expect(r.heard.calls.last, 'after vo:heb.v2.full');
        expect(r.controller.finished, isTrue);
        await r.done(t);
      },
    );
  });

  // ===============================================================================================================================
  group('real items: LS10 puppet talk', () {
    testWidgets(
      'ENG-A-17 i05 (Pip asks Mika; the child picks "I\'m sad"): the sem and the guess tags, the puppet answers',
      (WidgetTester t) async {
        final LangPack p = _course('eng', <String>['mika_icecream', 'mika_sad', 'mika_happy', 'pip_leave']);
        p.add(
          puppetJson(
            course: 'eng',
            id: 'a17i05',
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
        expect(_messages(p), isEmpty);
        final Rig<PuppetTalkSession> r = _puppetRig(p, 'a17i05');
        await r.pump(t);
        await r.wait(t, 200);
        await t.tap(r.tile('o3'));
        await r.wait(t, 1600);
        await t.tap(r.tile('o1'));
        await r.wait(t, 100);
        expect(r.written, <String>['incorrect:o3', 'correct:o1']);
        expect(r.attempts.first.misconceptionTag, 'eng.lis.l1_guess');
        await r.done(t);
      },
    );

    testWidgets(
      'the personal turns of ENG-A-01, A-04, A-08: the pass and a card write nothing, whatever the topic',
      (WidgetTester t) async {
        final LangPack p = _course('eng', <String>['apple', 'banana', 'cat', 'pip_happy']);
        Map<String, Object?> card(String id, {String? asset, int? numeral}) => <String, Object?>{
          'id': id,
          'label': id,
          'sprite': ?(asset == null ? null : 'asset:$asset'),
          'numeral': ?numeral,
          'clip': 'vo:eng.card.$id',
        };
        p.add(puppetJson(course: 'eng', id: 'pers1', mode: 'personal', topic: 'name', picture: 'pip_happy'));
        p.add(
          puppetJson(
            course: 'eng',
            id: 'pers4',
            mode: 'personal',
            topic: 'age',
            picture: 'pip_happy',
            options: <Map<String, Object?>>[for (int n = 3; n <= 9; n++) card('o${n - 2}', numeral: n)],
          ),
        );
        p.add(
          puppetJson(
            course: 'eng',
            id: 'pers8',
            mode: 'personal',
            topic: 'likes',
            picture: 'pip_happy',
            options: <Map<String, Object?>>[
              card('o1', asset: 'apple'),
              card('o2', asset: 'banana'),
            ],
          ),
        );
        expect(_messages(p), isEmpty, reason: 'age cards 3 to 9 are seven cards');
        for (final (String id, String touch) in <(String, String)>[
          ('pers1', 'personal-said'),
          ('pers4', 'card-o3'),
          ('pers8', 'card-o2'),
          ('pers8', 'personal-pass'),
        ]) {
          final Rig<PuppetTalkSession> r = _puppetRig(p, id);
          await r.pump(t);
          expect(find.byKey(const Key('personal-pass')), findsOneWidget, reason: '$id: the pass is in reach');
          await t.tap(find.byKey(Key(touch)));
          await r.wait(t, 2000);
          expect(r.attempts, isEmpty, reason: '$id $touch');
          expect(r.controller.finished, isTrue, reason: '$id $touch');
          await r.done(t);
        }
      },
    );
  });

  // ===============================================================================================================================
  group('real items: LS03 drum', () {
    testWidgets(
      'ENG-A-14 cat (1), apple (2), banana (3): the right count is right, one more and one fewer give the course tags',
      (WidgetTester t) async {
        final LangPack p = _course('eng', <String>['cat', 'apple', 'banana']);
        p.add(_drum('eng', 'cat', 'cat', 1));
        p.add(_drum('eng', 'apple', 'apple', 2));
        p.add(_drum('eng', 'banana', 'banana', 3));
        expect(_messages(p), isEmpty);
        for (final (String id, int beats, int more, int fewer) in <(String, int, int, int)>[
          ('cat', 1, 2, 0),
          ('apple', 2, 3, 1),
          ('banana', 3, 4, 2),
        ]) {
          final Rig<SoundBoxesSession> r = _drumRig(p, id);
          await r.pump(t);
          await _drumTaps(t, r, more);
          await t.tap(find.byKey(const Key('drum-done')));
          await r.wait(t, 100);
          expect(r.attempts.last.misconceptionTag, 'eng.pa.syll', reason: '$id one more');
          expect(r.attempts.last.response, 'n=$more');
          await r.wait(t, 1400);
          if (fewer > 0) {
            await _drumTaps(t, r, fewer);
            await t.tap(find.byKey(const Key('drum-done')));
            await r.wait(t, 100);
            expect(r.attempts.last.misconceptionTag, 'eng.pa.weak_syll', reason: '$id one fewer');
            await r.wait(t, 1400);
          }
          await _drumTaps(t, r, beats);
          await t.tap(find.byKey(const Key('drum-done')));
          await r.wait(t, 100);
          expect(r.attempts.last.result, 'correct', reason: id);
          expect(r.attempts.last.response, 'n=$beats');
          await r.done(t);
        }
      },
    );

    testWidgets('HEB-A-08 duvi (2) and banana (3): one more and one fewer are the same tag', (
      WidgetTester t,
    ) async {
      final LangPack p = _course('heb', <String>['teddy', 'banana']);
      p.add(_drum('heb', 'duvi', 'teddy', 2));
      p.add(_drum('heb', 'banana', 'banana', 3));
      expect(_messages(p), isEmpty);
      final Rig<SoundBoxesSession> r = _drumRig(p, 'banana');
      await r.pump(t);
      for (final int n in <int>[2, 4]) {
        await _drumTaps(t, r, n);
        await t.tap(find.byKey(const Key('drum-done')));
        await r.wait(t, 1500);
      }
      expect(r.attempts.map((AttemptRecord a) => a.misconceptionTag).toList(), <String>[
        'heb.pa.syll',
        'heb.pa.syll',
      ]);
      await r.done(t);
    });
  });

  // ===============================================================================================================================
  group('acceptance: unscored steps write nothing, on the lesson screen with the real database', () {
    testWidgets(
      'a lesson of a chant, a heard story, an embodied step and a personal pass leaves no attempt, no event, no alert',
      (WidgetTester t) async {
        final LangPack p = _course('eng', <String>[
          'act_wave',
          'mika_body',
          'pip_happy',
          'story_bounce_1',
          'story_bounce_2',
          'ball_red',
          'cat',
        ]);
        p.add(
          singJson(
            course: 'eng',
            id: 'hello',
            pictures: <Map<String, Object?>>[songPicture('act_wave', clip: 'vo:eng.w.wave')],
            lines: <Map<String, Object?>>[
              <String, Object?>{
                'clips': <String>['vo:eng.ch.1'],
                'lights': <int>[0],
              },
            ],
          ),
        );
        p.add(listenDoJson(course: 'eng', id: 'emb', mode: 'embodied', picture: 'mika_body'));
        p.add(puppetJson(course: 'eng', id: 'who', mode: 'personal', topic: 'name', picture: 'pip_happy'));
        p.add(
          storyJson(
            course: 'eng',
            id: 'tale',
            pages: <Map<String, Object?>>[
              storyPage('story_bounce_1', <String>['vo:eng.t.1']),
              storyPage('story_bounce_2', <String>['vo:eng.t.2']),
            ],
          ),
        );
        final rig = await openLesson(
          t,
          p,
          'hello',
          const Size(852, 393),
          itemIds: <String>['eng.hello', 'eng.emb', 'eng.who', 'eng.tale'],
        );
        await waitFor(t, 4000);
        await t.tap(find.byKey(const Key('do-done')));
        await waitFor(t, 2500);
        await t.tap(find.byKey(const Key('personal-pass')));
        await waitFor(t, 2500);
        await t.tap(find.byKey(const Key('story-turn')));
        await waitFor(t, 300);
        await t.tap(find.byKey(const Key('story-turn')));
        await waitFor(t, 2500);
        final AppDatabase db = rig.db;
        expect(await db.attemptsOf(langKid), isEmpty);
        expect(await db.unreadAlertCount(), 0);
        expect(await db.attemptsOf(langKid), isEmpty);
      },
    );
  });

  // ===============================================================================================================================
  group('acceptance: the hint ladders change the representation at level 2', () {
    testWidgets(
      'story: level 1 the answering page again, level 2 the pages in a row, level 3 the answer is shown',
      (WidgetTester t) async {
        final LangPack p = _course('eng', <String>[
          for (int i = 1; i <= 6; i++) 'story_bounce_$i',
          'ball_red',
          'cat',
          'duck',
          'frog',
          'dog',
        ]);
        p.add(_bounce(p, dialogic: true));
        final Rig<StorySession> r = _storyRig(p, 'bounce');
        await r.pump(t);
        await _turn(t, r, 3);
        r.heard.clear();
        await t.tap(find.byKey(const Key('lesson-hint')));
        await r.wait(t, 300);
        expect(r.controller.hintShown, 1);
        expect(find.byKey(const Key('story-row')), findsNothing);
        expect(r.heard.clips, contains('vo:eng.st.bounce.3'));
        await t.tap(find.byKey(const Key('lesson-hint')));
        await r.wait(t, 300);
        expect(r.controller.hintShown, 2);
        expect(
          find.byKey(const Key('story-row')),
          findsOneWidget,
          reason: 'level 2: the pages so far, as a sequence',
        );
        await r.wait(t, 3000);
        await t.tap(find.byKey(const Key('lesson-hint')));
        await r.wait(t, 2500);
        expect(r.controller.hintShown, 3);
        expect(
          r.attempts.where((AttemptRecord a) => a.result == 'incorrect'),
          isEmpty,
          reason: 'the lamp is not a mistake',
        );
        await r.done(t);
      },
    );

    testWidgets(
      'listen_do: level 2 is a close-up of what the command names, level 3 the right move shown; for all five modes',
      (WidgetTester t) async {
        final LangPack p = _course('eng', <String>[
          'mika_body',
          'act_jump',
          'act_stop',
          'act_listen',
          'plate',
          'apple',
          'banana',
          'bread',
          'ball',
        ]);
        p.add(_bodyItem(p, 'hot', 'head', 'tummy', 'feet'));
        p.add(
          listenDoJson(
            course: 'eng',
            id: 'btn',
            mode: 'buttons',
            picture: 'mika_body',
            options: <Map<String, Object?>>[
              pictureOption('o1', 'act_jump'),
              pictureOption('o2', 'act_stop', tag: 'eng.lis.sem'),
              pictureOption('o3', 'act_listen', tag: 'eng.lis.l1_guess'),
            ],
            correct: 'o1',
          ),
        );
        p.add(
          listenDoJson(
            course: 'eng',
            id: 'drg',
            mode: 'drag',
            picture: 'mika_body',
            target: <String, Object?>{'at': at(0.58, 0.3, 0.38, 0.38), 'sprite': 'asset:plate'},
            options: <Map<String, Object?>>[
              thingOption('o1', 'apple', at(0.02, 0.05, 0.26, 0.26)),
              thingOption('o2', 'banana', at(0.02, 0.37, 0.26, 0.26), tag: 'eng.lis.sem'),
              thingOption('o3', 'bread', at(0.02, 0.69, 0.26, 0.26), tag: 'eng.lis.l1_guess'),
            ],
            correct: 'o1',
          ),
        );
        p.add(
          listenDoJson(
            course: 'eng',
            id: 'plc',
            mode: 'place',
            picture: 'mika_body',
            thing: <String, Object?>{'sprite': 'asset:ball', 'at': at(0.04, 0.4, 0.22, 0.22)},
            options: <Map<String, Object?>>[
              partOption('o1', at(0.4, 0.04, 0.5, 0.26), label: 'on'),
              partOption('o2', at(0.4, 0.7, 0.5, 0.26), tag: 'eng.lis.sem', label: 'under'),
              partOption('o3', at(0.72, 0.36, 0.25, 0.26), tag: 'eng.lis.l1_guess', label: 'next to'),
            ],
            correct: 'o1',
          ),
        );
        for (final String id in <String>['hot', 'btn', 'drg', 'plc']) {
          final Rig<ListenDoSession> r = _doRig(p, id);
          await r.pump(t);
          await t.tap(find.byKey(const Key('lesson-hint')));
          await r.wait(t, 200);
          expect(r.controller.hintShown, 1, reason: id);
          expect(find.byKey(const Key('do-closeup')), findsNothing, reason: '$id level 1 is only a light');
          await t.tap(find.byKey(const Key('lesson-hint')));
          await r.wait(t, 200);
          expect(r.controller.hintShown, 2, reason: id);
          expect(
            find.byKey(const Key('do-closeup')),
            findsOneWidget,
            reason: '$id level 2 changes the representation',
          );
          await t.tap(find.byKey(const Key('lesson-hint')));
          await r.wait(t, 1500);
          expect(r.controller.hintShown, 3, reason: id);
          expect(r.session.demoMove, isTrue, reason: '$id level 3 shows it done');
          await r.done(t);
        }
      },
    );

    testWidgets(
      'sing_along rhyme: level 1 the end word, level 2 the end word beside each option (the ends alone), level 3 the verse with the answer',
      (WidgetTester t) async {
        final LangPack p = _course('heb', <String>['window', 'sun', 'basket', 'cat']);
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
        final Rig<SingAlongSession> r = _singRig(p, 'verse2');
        await r.pump(t);
        await r.wait(t, 2000);
        r.heard.clear();
        await t.tap(find.byKey(const Key('lesson-hint')));
        await r.wait(t, 200);
        expect(r.heard.clips, <String>[
          'vo:heb.v2.e',
        ], reason: 'level 1: the end word of the first line again');
        r.heard.clear();
        await t.tap(find.byKey(const Key('lesson-hint')));
        await r.wait(t, 3000);
        expect(r.controller.hintShown, 2);
        expect(r.heard.clips, <String>[
          'vo:heb.v2.e',
          'vo:heb.w.window',
          'vo:heb.v2.e',
          'vo:heb.w.sun',
          'vo:heb.v2.e',
          'vo:heb.w.basket',
        ], reason: 'level 2: each pair, the ends alone');
        await t.tap(find.byKey(const Key('lesson-hint')));
        await r.wait(t, 1500);
        expect(r.controller.hintShown, 3);
        await r.done(t);
      },
    );

    testWidgets(
      'puppet bubble: level 1 the line then each bubble slowly, level 2 the key picture glows, level 3 the right bubble is shown',
      (WidgetTester t) async {
        final LangPack p = _course('eng', <String>['mika_icecream', 'mika_sad', 'mika_happy', 'pip_leave']);
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
        final Rig<PuppetTalkSession> r = _puppetRig(p, 'bub');
        await r.pump(t);
        await r.wait(t, 200);
        r.heard.clear();
        await t.tap(find.byKey(const Key('lesson-hint')));
        await r.wait(t, 4000);
        expect(r.heard.clips, <String>[
          'vo:eng.bub.prompt',
          'vo:eng.bub.puppet',
          'vo:eng.im.sad',
          'vo:eng.im.happy',
          'vo:eng.goodbye',
        ]);
        expect(find.byKey(const Key('puppet-key')), findsNothing);
        await t.tap(find.byKey(const Key('lesson-hint')));
        await r.wait(t, 200);
        expect(find.byKey(const Key('puppet-key')), findsOneWidget);
        await t.tap(find.byKey(const Key('lesson-hint')));
        await r.wait(t, 1500);
        await r.done(t);
      },
    );

    testWidgets(
      'drum: level 1 the word slowly, level 2 hands clap once per beat, level 3 the friend drums and the count lights',
      (WidgetTester t) async {
        final LangPack p = _course('eng', <String>['banana']);
        p.add(_drum('eng', 'banana', 'banana', 3));
        final Rig<SoundBoxesSession> r = _drumRig(p, 'banana');
        await r.pump(t);
        await r.wait(t, 300);
        r.heard.clear();
        await t.tap(find.byKey(const Key('lesson-hint')));
        await r.wait(t, 200);
        expect(r.heard.clips, <String>['vo:eng.banana.slow']);
        await t.tap(find.byKey(const Key('lesson-hint')));
        await r.wait(t, 2500);
        expect(r.session.hands, 3);
        expect(find.byIcon(Icons.back_hand_rounded), findsNWidgets(3));
        await t.tap(find.byKey(const Key('lesson-hint')));
        await r.wait(t, 4000);
        expect(r.controller.hintShown, 3);
        expect(
          r.controller.guided,
          isFalse,
          reason: 'the lamp does not make the help guided; only mistakes or "show me" do',
        );
        await r.done(t);
      },
    );
  });

  // ===============================================================================================================================
  group('acceptance: every distractor is tagged (frame 2.3), in every template that has a choice', () {
    test('a story pause, a hotspot command, a button, a rhyme gap and a bubble each refuse an untagged distractor', () {
      final LangPack p = _course('eng', <String>[
        for (int i = 1; i <= 6; i++) 'story_bounce_$i',
        'ball_red',
        'cat',
        'duck',
        'frog',
        'dog',
        'mika_body',
        'act_jump',
        'act_stop',
        'act_listen',
        'mika_icecream',
        'mika_sad',
        'mika_happy',
        'pip_leave',
        'window',
        'sun',
        'basket',
      ]);
      p.add(_bounce(p, dialogic: true));
      p.add(_bodyItem(p, 'hot', 'head', 'tummy', 'feet'));
      p.add(
        listenDoJson(
          course: 'eng',
          id: 'btn',
          mode: 'buttons',
          options: <Map<String, Object?>>[
            pictureOption('o1', 'act_jump'),
            pictureOption('o2', 'act_stop', tag: 'eng.lis.sem'),
            pictureOption('o3', 'act_listen', tag: 'eng.lis.l1_guess'),
          ],
          correct: 'o1',
          picture: 'mika_body',
        ),
      );
      p.add(
        singJson(
          course: 'eng',
          id: 'rhyme',
          pictures: <Map<String, Object?>>[songPicture('cat')],
          verse: <String, Object?>{
            'whole': <String>['vo:eng.v.w'],
            'open': <String>['vo:eng.v.o'],
            'full': <String>['vo:eng.v.f'],
            'cue': <String>['vo:eng.v.e'],
          },
          options: <Map<String, Object?>>[
            pictureOption('o1', 'window', clip: 'vo:eng.w.window'),
            pictureOption('o2', 'sun', tag: 'eng.lis.sem', clip: 'vo:eng.w.sun'),
            pictureOption('o3', 'basket', tag: 'eng.lis.l1_guess', clip: 'vo:eng.w.basket'),
          ],
          correct: 'o1',
        ),
      );
      p.add(
        puppetJson(
          course: 'eng',
          id: 'bub',
          mode: 'bubble',
          picture: 'mika_icecream',
          options: <Map<String, Object?>>[
            pictureOption('o1', 'mika_sad', clip: 'vo:eng.im.sad'),
            pictureOption('o2', 'mika_happy', tag: 'eng.lis.sem', clip: 'vo:eng.im.happy'),
            pictureOption('o3', 'pip_leave', tag: 'eng.lis.l1_guess', clip: 'vo:eng.goodbye'),
          ],
          correct: 'o1',
        ),
      );
      expect(_messages(p), isEmpty);
      for (final String id in <String>['bounce', 'hot', 'btn', 'rhyme', 'bub']) {
        final LangPack q = _course('eng', <String>[]);
        // the same pack again, with the second distractor of one item stripped of its tag
        final Map<String, Object?> doc = Map<String, Object?>.of(
          p.pack.docs['activity.eng.$id.json']! as Map<String, Object?>,
        );
        final Map<String, Object?> answer = Map<String, Object?>.of(doc['answer']! as Map<String, Object?>);
        final List<Object?> options = <Object?>[
          for (final Object? o in answer['options']! as List<Object?>)
            Map<String, Object?>.of(o! as Map<String, Object?>),
        ];
        (options[2]! as Map<String, Object?>).remove('misconception');
        answer['options'] = options;
        doc['answer'] = answer;
        final Object? saved = p.pack.docs['activity.eng.$id.json'];
        p.pack.docs['activity.eng.$id.json'] = doc;
        expect(
          _messages(p),
          contains(contains('answer.options[2].misconception: a distractor carries the misconception')),
          reason: id,
        );
        p.pack.docs['activity.eng.$id.json'] = saved;
        expect(q, isNotNull);
      }
    });

    test('an accent tag is never a distractor tag in any of them (frame 2.3)', () {
      final LangPack p = _course('eng', <String>['mika_icecream', 'mika_sad', 'mika_happy', 'pip_leave']);
      p.add(
        puppetJson(
          course: 'eng',
          id: 'bub',
          mode: 'bubble',
          picture: 'mika_icecream',
          options: <Map<String, Object?>>[
            pictureOption('o1', 'mika_sad', clip: 'vo:eng.im.sad'),
            pictureOption('o2', 'mika_happy', tag: 'eng.spk.accent', clip: 'vo:eng.im.happy'),
            pictureOption('o3', 'pip_leave', tag: 'eng.lis.l1_guess', clip: 'vo:eng.goodbye'),
          ],
          correct: 'o1',
        ),
      );
      expect(_messages(p), contains(contains('accent')));
    });
  });

  // ===============================================================================================================================
  group('acceptance: the drum', () {
    testWidgets(
      'English banana: every count from 1 to 9 maps as the plan says; more than nine taps are not counted',
      (WidgetTester t) async {
        final LangPack p = _course('eng', <String>['banana']);
        p.add(_drum('eng', 'banana', 'banana', 3));
        for (final int n in <int>[1, 2, 4, 5, 6, 7, 8, 9, 12]) {
          final Rig<SoundBoxesSession> r = _drumRig(p, 'banana');
          await r.pump(t);
          await _drumTaps(t, r, n);
          expect(r.session.taps, n > 9 ? 9 : n);
          await t.tap(find.byKey(const Key('drum-done')));
          await r.wait(t, 100);
          final AttemptRecord a = r.attempts.single;
          expect(a.response, 'n=${n > 9 ? 9 : n}');
          expect(a.result, 'incorrect');
          expect(
            a.misconceptionTag,
            n == 4 ? 'eng.pa.syll' : (n == 2 ? 'eng.pa.weak_syll' : ''),
            reason: 'count $n',
          );
          await r.done(t);
        }
      },
    );

    testWidgets('the dots are the child\'s own count: dots, never a number, in the course direction', (
      WidgetTester t,
    ) async {
      final LangPack p = _course('heb', <String>['banana']);
      p.add(_drum('heb', 'banana', 'banana', 3));
      final Rig<SoundBoxesSession> r = _drumRig(p, 'banana');
      await r.pump(t);
      await _drumTaps(t, r, 3);
      expect(find.textContaining(RegExp(r'[0-9]')), findsNothing);
      expect(
        t.getCenter(find.byKey(const Key('drum-dot-0'))).dx,
        greaterThan(t.getCenter(find.byKey(const Key('drum-dot-2'))).dx),
      );
      await r.done(t);
    });
  });

  // ===============================================================================================================================
  group('acceptance: the placement staircase follows frame 3.2', () {
    // A reference written from the text of frame 3.2, not from the code: two right go up, one wrong goes down; 2 reversals or 8
    // items; the highest level with at least 2/3 right, minus one; two misses at the floor stop it; no more than 8 per visit.
    ({int entry, int asked}) reference(List<List<String>> levels, List<bool> answers) {
      int level = 0, run = 0, reversals = 0, last = 0, floorMiss = 0, asked = 0;
      final Map<int, List<bool>> at = <int, List<bool>>{};
      for (final bool right in answers) {
        if (asked >= 8 || reversals >= 2 || floorMiss >= 2) break;
        asked++;
        (at[level] ??= <bool>[]).add(right);
        void move(int d) {
          if (last != 0 && last != d) reversals++;
          last = d;
          level += d;
        }

        if (right) {
          floorMiss = 0;
          if (++run == 2) {
            run = 0;
            if (level < levels.length - 1) move(1);
          }
        } else {
          run = 0;
          if (level == 0) {
            floorMiss++;
          } else {
            move(-1);
          }
        }
      }
      int? best;
      for (final MapEntry<int, List<bool>> e in at.entries.toList()..sort((a, b) => a.key.compareTo(b.key))) {
        if (e.value.where((bool b) => b).length * 3 >= e.value.length * 2) best = e.key;
      }
      return (entry: floorMiss >= 2 || best == null ? 0 : (best - 1 < 0 ? 0 : best - 1), asked: asked);
    }

    test('the staircase agrees with a reference of the frame text on 4000 random answer sequences', () {
      final List<List<String>> levels = <List<String>>[
        for (int l = 0; l < 4; l++) <String>['a$l', 'b$l', 'c$l', 'd$l', 'e$l', 'f$l', 'g$l', 'h$l'],
      ];
      int seed = 7;
      bool coin(int pct) {
        seed = (seed * 1103515245 + 12345) & 0x7fffffff;
        return (seed >> 8) % 100 < pct;
      }

      for (int n = 0; n < 4000; n++) {
        final int skill = n % 5 * 20 + 10;
        final List<bool> answers = <bool>[for (int i = 0; i < 12; i++) coin(skill)];
        final Staircase s = Staircase(StrandPlan(id: 'o', levels: levels));
        int given = 0;
        for (final bool right in answers) {
          final String? next = s.next;
          if (next == null) break;
          s.record(next, right: right);
          given++;
        }
        final ({int entry, int asked}) ref = reference(levels, answers);
        expect(s.result.entry, ref.entry, reason: '$answers');
        expect(given, ref.asked, reason: '$answers');
        expect(given, lessThanOrEqualTo(8));
      }
    });

    test('two probes missed at the floor stop the strand at once, placed at the floor; a questionnaire start never decides the end', () {
      final List<List<String>> levels = <List<String>>[
        <String>['a0', 'b0', 'c0'],
        <String>['a1', 'b1', 'c1'],
        <String>['a2', 'b2', 'c2'],
      ];
      final Staircase s = Staircase(StrandPlan(id: 'o', levels: levels));
      s.record(s.next!, right: false);
      expect(s.stopped, isFalse);
      s.record(s.next!, right: false);
      expect(s.stopped, isTrue);
      expect(s.result.entry, 0);
      expect(s.asked, 2);

      // a questionnaire start at level 2: a child who misses goes down, and the end is where the answers put it
      final Staircase high = Staircase(StrandPlan(id: 'o', levels: levels).startingAt(2));
      expect(high.level, 2);
      high.record(high.next!, right: false);
      high.record(high.next!, right: false);
      expect(high.level, 0, reason: 'a start above the floor is not a promise');
      high.record(high.next!, right: false);
      high.record(high.next!, right: false);
      expect(high.stopped, isTrue);
      expect(high.result.entry, 0);
    });

    test('a visit holds at most perVisit probes, the strands run in order, oral first, and a speech probe is refused', () {
      final PlacementGame g = PlacementGame(
        strands: <StrandPlan>[
          StrandPlan(
            id: 'o',
            levels: <List<String>>[
              for (int l = 0; l < 3; l++) <String>['o${l}a', 'o${l}b', 'o${l}c'],
            ],
          ),
          StrandPlan(
            id: 'l',
            levels: <List<String>>[
              for (int l = 0; l < 3; l++) <String>['l${l}a', 'l${l}b', 'l${l}c'],
            ],
          ),
        ],
      );
      expect(g.next(), 'o0a');
      expect(g.next(doneThisVisit: 8), isNull);
      expect(g.next(doneThisVisit: 7), isNotNull);
      for (final String id in <String>['o0a', 'o0b']) {
        g.record(id, right: true);
      }
      expect(g.stairs('o')!.level, 1);
      expect(g.whereIs('l1b')!.strand, 'l');

      final LangPack p = _course('eng', <String>['cat', 'dog', 'duck']);
      p.addProbe('probe1');
      p.addProbe('probe2');
      p.activity('probe1')['voiceAnswer'] = true;
      p.addPlacement(
        placementJson('eng', <Map<String, Object?>>[
          strandJson('o', 'eng', <List<String>>[
            <String>['probe1'],
            <String>['probe2'],
          ]),
        ]),
      );
      expect(_messages(p), contains(contains('speech is never a probe')));
    });
  });

  // ===============================================================================================================================
  group('acceptance: a probe shows no result to the child', () {
    PlacementFlow flowOf(LangPack p) => PlacementFlow(placementGameOf(p.content)!, p.content.placement!);

    LangPack placement() {
      final LangPack p = _course('eng', <String>['cat', 'dog', 'duck', 'banana']);
      final List<List<String>> levels = <List<String>>[
        <String>['p_0_1', 'p_0_2', 'p_0_3'],
        <String>['p_1_1', 'p_1_2', 'p_1_3'],
      ];
      for (final List<String> l in levels) {
        l.forEach(p.addProbe);
      }
      p.add(_drum('eng', 'dprobe', 'banana', 3, purpose: 'probe'));
      p.addPlacement(placementJson('eng', <Map<String, Object?>>[strandJson('o', 'eng', levels)]));
      return p;
    }

    testWidgets('the lesson screen has no lamp and no "show me" on a probe', (WidgetTester t) async {
      final LangPack p = placement();
      await openLesson(t, p, 'p_0_1', const Size(852, 393), flow: flowOf(p));
      expect(find.byKey(const Key('lesson-hint')), findsNothing);
      expect(find.byKey(const Key('lesson-show-me')), findsNothing);
      expect(find.byKey(const Key('lesson-replay')), findsOneWidget, reason: 'the replay button stays');
    });

    testWidgets(
      'a tap probe: the line, the voice, the feedback kind and the tile state are the same for a right and a wrong answer',
      (WidgetTester t) async {
        final List<String> seen = <String>[];
        for (final String tile in <String>['o1', 'o2']) {
          final LangPack p = placement();
          final Rig<TapAnswerSession> r = Rig<TapAnswerSession>(
            p,
            'p_0_1',
            (LessonController c, Activity a) => TapAnswerSession(c, a as TapAnswerActivity),
            flow: flowOf(p),
          );
          await r.pump(t);
          expect(r.controller.noHelp, isTrue);
          await t.tap(
            find.byKey(Key('option-$tile')).evaluate().isEmpty
                ? r.tile(tile)
                : find.byKey(Key('option-$tile')),
          );
          await r.wait(t, 200);
          seen.add(
            '${r.controller.bubble}|${r.controller.voice}|${r.controller.feedback}|${r.controller.solved}|${r.session.chosenState}|${r.controller.hintShown}|${r.controller.errors}',
          );
          expect(r.attempts, hasLength(1));
          expect(r.attempts.single.result, tile == 'o1' ? 'correct' : 'incorrect');
          await r.done(t);
        }
        expect(seen[0], seen[1], reason: 'nothing a child could read a result from');
        expect(seen[0], contains('vo:eng.placement.thanks'));
      },
    );

    testWidgets('a drum probe: the same, whatever the count; the lesson goes on after one answer', (
      WidgetTester t,
    ) async {
      final List<String> seen = <String>[];
      for (final int n in <int>[3, 2, 6]) {
        final LangPack p = placement();
        final Rig<SoundBoxesSession> r = _drumRig(p, 'dprobe');
        await r.pump(t);
        await _drumTaps(t, r, n);
        await t.tap(find.byKey(const Key('drum-done')));
        await r.wait(t, 200);
        seen.add(
          '${r.controller.bubble}|${r.controller.voice}|${r.controller.feedback}|${r.controller.solved}|${r.session.state}|${r.controller.hintShown}',
        );
        await r.wait(t, 1800);
        expect(r.controller.finished, isTrue, reason: 'n=$n: one answer ends a probe');
        expect(r.attempts, hasLength(1));
        await r.done(t);
      }
      expect(seen.toSet(), hasLength(1), reason: '$seen');
    });
  });

  // ===============================================================================================================================
  group('acceptance: the page-turn arrow points the reading direction, never mirrored', () {
    testWidgets(
      'an English story turns toward the right, a Hebrew one toward the left, a Russian one toward the right',
      (WidgetTester t) async {
        for (final (String course, IconData icon, IconData other) in <(String, IconData, IconData)>[
          ('eng', Icons.arrow_forward_rounded, Icons.arrow_back_rounded),
          ('heb', Icons.arrow_back_rounded, Icons.arrow_forward_rounded),
          ('rus', Icons.arrow_forward_rounded, Icons.arrow_back_rounded),
        ]) {
          final LangPack p = _course(course, <String>['story_bounce_1', 'story_bounce_2']);
          p.add(
            storyJson(
              course: course,
              id: 'tale',
              pages: <Map<String, Object?>>[
                storyPage('story_bounce_1', <String>['vo:$course.t.1']),
                storyPage('story_bounce_2', <String>['vo:$course.t.2']),
              ],
            ),
          );
          final Rig<StorySession> r = _storyRig(p, 'tale');
          await r.pump(t);
          expect(find.byIcon(icon), findsOneWidget, reason: course);
          expect(find.byIcon(other), findsNothing, reason: course);
          // never mirrored by the UI's own direction: the icon is painted with an explicit left-to-right text direction
          final Icon w = t.widget<Icon>(find.byIcon(icon));
          expect(w.textDirection, TextDirection.ltr, reason: course);
          // and it stands at the end of the reading direction
          final double x = t.getCenter(find.byKey(const Key('story-turn'))).dx;
          final double mid = t.getCenter(find.byKey(const Key('story-stage'))).dx;
          expect(
            course == 'heb' ? x < mid : x > mid,
            isTrue,
            reason: '$course: the arrow is at the end corner',
          );
          await r.done(t);
        }
      },
    );
  });

  // ===============================================================================================================================
  group('acceptance: no red, no "wrong", no timer word in the child-space source of L4', () {
    const List<String> files = <String>[
      'lib/play/story_session.dart',
      'lib/play/listen_do_session.dart',
      'lib/play/sing_along_session.dart',
      'lib/play/puppet_talk_session.dart',
      'lib/play/sound_boxes_session.dart',
      'lib/play/choice_session.dart',
      'lib/play/choice_row.dart',
      'lib/world/language_placement.dart',
      'lib/engine/staircase.dart',
    ];

    test('no timer, countdown, streak or stopwatch word in the code of the new files (comments aside)', () {
      final RegExp banned = RegExp('timer|countdown|streak|stopwatch|seconds? left', caseSensitive: false);
      for (final String f in files) {
        for (final String line in File(f).readAsLinesSync()) {
          if (line.trimLeft().startsWith('//')) continue;
          expect(banned.hasMatch(line), isFalse, reason: '$f: $line');
        }
      }
    });

    test('no red anywhere: no Colors.red and no red-looking colour literal in the new files', () {
      final RegExp red = RegExp(r'Colors\.(red|redAccent|deepOrange)');
      for (final String f in files) {
        for (final String line in File(f).readAsLinesSync()) {
          expect(red.hasMatch(line), isFalse, reason: '$f: $line');
        }
      }
    });

    test('the child never reads "wrong": no string of the new files says it', () {
      final RegExp wrong = RegExp('טעות|שגוי|לא נכון|wrong', caseSensitive: false);
      for (final String f in files) {
        for (final String line in File(f).readAsLinesSync()) {
          if (line.trimLeft().startsWith('//')) continue;
          // a string literal only (`onWrong` is the name of a method; the child never reads a name)
          for (final RegExpMatch m in RegExp(r"'[^']*'").allMatches(line)) {
            expect(wrong.hasMatch(m[0]!), isFalse, reason: '$f: $line');
          }
        }
      }
      final String he = File('lib/strings/he.dart').readAsStringSync();
      final int from = he.indexOf('L4: screen-reader labels');
      final List<String> l4 = LineSplitter.split(he.substring(from)).take(10).toList();
      expect(l4.where((String l) => l.contains('Semantics') && !l.contains('coin')), hasLength(7));
      expect(wrong.hasMatch(l4.join(' ')), isFalse);
    });

    test('the not-yet colour is a soft violet, and no colour the new files use is a red', () {
      final String tokens = File('lib/design/tokens.g.dart').readAsStringSync();
      for (final String name in <String>['notYetRing', 'correctGlow', 'hintHalo']) {
        final RegExpMatch m = RegExp('$name = Color\\(0xFF([0-9A-F]{6})\\)').firstMatch(tokens)!;
        final int rgb = int.parse(m[1]!, radix: 16);
        final int r = rgb >> 16, g = (rgb >> 8) & 255, b = rgb & 255;
        expect(r > 170 && g < 110 && b < 110, isFalse, reason: '$name is red-ish: #${m[1]}');
      }
    });
  });
  // ===============================================================================================================================
  group('acceptance: the parent switch for personal turns, both ways, on the lesson screen with the real database', () {
    LangPack lesson() {
      final LangPack p = _course('eng', <String>['pip_happy', 'cat', 'duck', 'frog']);
      p.add(puppetJson(course: 'eng', id: 'pers1', mode: 'personal', topic: 'name', picture: 'pip_happy'));
      p.add(
        tapJson(
          course: 'eng',
          id: 'after',
          options: <Map<String, Object?>>[
            pictureOption('o1', 'cat'),
            pictureOption('o2', 'duck', tag: 'eng.lis.sem'),
            pictureOption('o3', 'frog', tag: 'eng.lis.l1_guess'),
          ],
          correct: 'o1',
        ),
      );
      return p;
    }

    testWidgets(
      'switch on: the turn is asked, the pass is there, and passing leaves nothing; the lesson goes on',
      (WidgetTester t) async {
        final rig = await openLesson(
          t,
          lesson(),
          'pers1',
          const Size(852, 393),
          itemIds: <String>['eng.pers1', 'eng.after'],
        );
        expect(find.byKey(const Key('personal-pass')), findsOneWidget);
        expect(find.byKey(const Key('personal-said')), findsOneWidget);
        await t.tap(find.byKey(const Key('personal-pass')));
        await waitFor(t, 3000);
        expect(find.byKey(const Key('personal-pass')), findsNothing);
        expect(await rig.db.attemptsOf(langKid), isEmpty);
      },
    );

    testWidgets(
      'switch off: nothing is asked, no card and no pass, the puppet answers itself and the lesson goes on alone',
      (WidgetTester t) async {
        final rig = await openLesson(
          t,
          lesson(),
          'pers1',
          const Size(852, 393),
          itemIds: <String>['eng.pers1', 'eng.after'],
          personal: false,
        );
        expect(find.byKey(const Key('personal-pass')), findsNothing);
        expect(find.byKey(const Key('personal-said')), findsNothing);
        await waitFor(t, 3500);
        expect(find.byKey(const Key('personal-pass')), findsNothing);
        expect(await rig.db.attemptsOf(langKid), isEmpty);
      },
    );
  });

  // ===============================================================================================================================
  group('acceptance: the English strand O of the batch (section 5) as a placement document', () {
    test('the nine tap probes of the batch fit a four-level strand; the one hotspot probe (A-06 i04) is refused', () {
      final LangPack p = _course('eng', <String>['cat', 'dog', 'duck', 'mika_body']);
      const List<List<String>> levels = <List<String>>[
        <String>['a01i01', 'a03i01'],
        <String>['a05i05', 'a08i02', 'a09i08'],
        <String>['a02i04', 'a04i08'],
        <String>['a11i05', 'a16i04'],
      ];
      for (final List<String> l in levels) {
        l.forEach(p.addProbe);
      }
      p.addPlacement(placementJson('eng', <Map<String, Object?>>[strandJson('o', 'eng', levels)]));
      expect(_messages(p), isEmpty, reason: 'nine tap probes make a valid strand');
      final PlacementGame g = placementGameOf(p.content)!;
      expect(g.strands.single.levels.expand((List<String> l) => l), hasLength(9));

      // the tenth probe of the batch is a hotspot command (an LS11 item): the validator refuses it as a probe
      final LangPack q = _course('eng', <String>['cat', 'dog', 'duck', 'mika_body']);
      for (final List<String> l in levels) {
        l.forEach(q.addProbe);
      }
      q.add(_bodyItem(q, 'a06i04', 'head', 'tummy', 'feet'));
      q.activity('a06i04')['purpose'] = 'probe';
      final List<List<String>> withHotspot = <List<String>>[
        ...levels.take(2),
        <String>['a02i04', 'a04i08', 'a06i04'],
        levels[3],
      ];
      q.addPlacement(placementJson('eng', <Map<String, Object?>>[strandJson('o', 'eng', withHotspot)]));
      expect(_messages(q), contains(contains('is a listen_do: a probe is a tap item or a drum item')));
    });
  });
}
