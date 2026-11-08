// QA's defects on the L5-3, L5-4 and L5-5 templates (QA-1 to QA-8). Each test was written failing and is the proof of its fix; all are fixed and run in the
// normal suite.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nitznutz/content/models.dart';
import 'package:nitznutz/content/pack_validation.dart';
import 'package:nitznutz/content/schema.dart';
import 'package:nitznutz/play/blend_layer.dart';
import 'package:nitznutz/play/blend_slide_session.dart';
import 'package:nitznutz/play/boxes_layer.dart';
import 'package:nitznutz/play/boxes_session.dart';
import 'package:nitznutz/play/change_part_session.dart';
import 'package:nitznutz/play/lesson_controller.dart';
import 'package:nitznutz/play/lesson_screen.dart';

import 'support/app_harness.dart';
import 'support/golden_comparator.dart';
import 'support/harness.dart';
import 'support/l4_golden.dart';
import 'support/l5_content.dart';
import 'support/l5_wheel.dart';
import 'support/language_content.dart';
import 'support/language_screens.dart' show langKid;
import 'support/l4_rig.dart' show Rig;
import 'support/language_voice.dart';
import 'support/voice_fixtures.dart';

const List<String> _pictures = <String>['sun', 'pot', 'top', 'pig', 'cat', 'whale', 'fish', 'banana'];

LangPack _sun() {
  final LangPack p = LangPack('eng')..addPictures(_pictures);
  p.addTag('pa.add_vowel', 'diagnostic');
  p.add(
    boxesJson(
      course: 'eng',
      id: 'box1',
      kinds: <String>['c', 'vowel', 'c'],
      steps: <String>['count'],
      classify: <String, String>{'count=more': p.tag('pa.add_vowel')},
    ),
  );
  return p;
}

LangPack _pot() {
  final LangPack p = LangPack('eng')..addPictures(_pictures);
  p.addTag('rea.reversed', 'diagnostic');
  p.add(
    blendJson(
      course: 'eng',
      id: 'sl1',
      text: 'pot',
      parts: <({String text, String? clip, bool stretch})>[
        bpart('p', clip: 'vo:eng.snd.p', stretch: false),
        bpart('o', clip: 'vo:eng.snd.o'),
        bpart('t', clip: 'vo:eng.snd.t', stretch: false),
      ],
      whole: 'vo:eng.pot',
      options: <Map<String, Object?>>[
        slideOption('o1', picture: 'pot'),
        slideOption('o2', picture: 'top', tag: p.tag('rea.reversed')),
      ],
      correct: 'o1',
    ),
  );
  return p;
}

void main() {
  setUpAll(() async {
    await loadAppFonts();
    useTolerantGoldens(0.03);
  });

  // QA-1: L5 section 7 and L4 D-5 say a template that waits for a clip waits a fixed pause when the clip is pending. In the app the lesson screen's player
  // always returns a Future that is already complete for a pending clip, so `sayAndWait` never takes its `without` pause and every guided sequence (the places
  // that light one by one, the slide, the friend's hands) runs in one tick. This opens the real lesson screen with an empty voice bank.
  testWidgets('QA-1 boxes: with every clip pending the places still light one after another', (
    WidgetTester t,
  ) async {
    final LangPack p = _sun();
    await openLessonPending(t, p, 'box1', const Size(852, 393));
    final BoxesSession s = t.widget<BoxesLayer>(find.byType(BoxesLayer)).session;
    for (int i = 0; i < 3; i++) {
      await t.tap(find.byKey(const Key('box-bowl')));
      await waitFor(t, 200);
    }
    await t.tap(find.byKey(const Key('box-done')));
    final Set<int> seen = <int>{};
    for (int i = 0; i < 40; i++) {
      await t.pump(const Duration(milliseconds: 100));
      seen.addAll(s.heard);
    }
    expect(seen, <int>{
      0,
      1,
      2,
    }, reason: 'each unit lights for a fixed pause (500 ms) when its clip is pending');
  });

  // The control of QA-1: with the clips in the bank the same moves light every place in turn, so the failure above is the pending case and not the test.
  testWidgets('control: with the clips in the voice bank the places light one after another', (
    WidgetTester t,
  ) async {
    final LangPack p = _sun();
    await openLesson(t, p, 'box1', const Size(852, 393));
    final BoxesSession s = t.widget<BoxesLayer>(find.byType(BoxesLayer)).session;
    for (int i = 0; i < 3; i++) {
      await t.tap(find.byKey(const Key('box-bowl')));
      await waitFor(t, 200);
    }
    await t.tap(find.byKey(const Key('box-done')));
    final Set<int> seen = <int>{};
    for (int i = 0; i < 40; i++) {
      await t.pump(const Duration(milliseconds: 100));
      seen.addAll(s.heard);
    }
    expect(seen, <int>{0, 1, 2});
  });

  testWidgets('QA-1 blend: with every clip pending the tap-slide still lights the parts one after another', (
    WidgetTester t,
  ) async {
    final LangPack p = _pot();
    await openLessonPending(t, p, 'sl1', const Size(852, 393));
    final BlendSlideSession s = t.widget<BlendLayer>(find.byType(BlendLayer)).session;
    await t.tap(find.byKey(const Key('slide-knob')));
    final Set<int> seen = <int>{};
    for (int i = 0; i < 40; i++) {
      await t.pump(const Duration(milliseconds: 100));
      final int? lit = s.litPart;
      if (lit != null) seen.add(lit);
    }
    expect(seen, <int>{
      0,
      1,
      2,
    }, reason: 'each part lights for the slow pace (700 ms) when its clip is pending');
    await t.pumpWidget(const SizedBox());
  });

  // QA-4 (coverage, not a defect): L5 section 5.5 says a slide's graphemes are taught by the skill or below it (F5). The check runs on the new faces
  // (`language_checks.dart`), but no test of the L5 suites shows it for LS04 or LS05; this one does.
  List<String> messages(LangPack p) => <String>[
    for (final Problem x in validatePack(manifest: p.pack.manifest, docs: p.pack.docs, files: p.pack.files))
      '${x.path}: ${x.message}',
  ];

  test('F5 on LS04: a slide word with a letter that no skill up to its own teaches is refused', () {
    LangPack slide(String text, List<String> parts) {
      final LangPack p = LangPack('eng')..addPictures(_pictures);
      p.addTag('rea.reversed', 'diagnostic');
      p.addTag('rea.first_guess', 'diagnostic');
      p.pack.doc('skill.ENG-A-01.json')['graphemes'] = <Object?>['a', 'm', 's'];
      p.pack.doc('skill.ENG-A-02.json')['letters'] = true;
      p.pack.doc('skill.ENG-A-02.json')['graphemes'] = <Object?>['t', 'o', 'p'];
      p.add(
        blendJson(
          course: 'eng',
          id: 'sl1',
          text: text,
          parts: <({String text, String? clip, bool stretch})>[
            for (final String x in parts) bpart(x, clip: 'vo:eng.snd.$x'),
          ],
          whole: 'vo:eng.$text',
          options: <Map<String, Object?>>[
            slideOption('o1', picture: 'pot'),
            slideOption('o2', picture: 'top', tag: p.tag('rea.reversed')),
            slideOption('o3', picture: 'pig', tag: p.tag('rea.first_guess')),
          ],
          correct: 'o1',
        ),
      );
      return p;
    }

    expect(messages(slide('top', <String>['t', 'o', 'p'])), isEmpty);
    expect(
      messages(slide('dog', <String>['d', 'o', 'g'])).where((String m) => m.contains('cannot be read yet')),
      isNotEmpty,
    );
  });

  // QA-5: L5 section 5.4 allows a result with no clip in `explore` ("a stop letter with no vowel: the hub shakes and plays nothing"). The session shakes the
  // hub only when there is no result row at all; a row written with no clip plays nothing and does not shake.
  for (final bool row in <bool>[false, true]) {
    testWidgets(
      '${row ? 'QA-5' : 'control'}: a unit with no sound shakes the hub (${row ? 'a result row with no clip' : 'no result row'})',
      (WidgetTester t) async {
        final LangPack p = LangPack('heb')..addPictures(_pictures);
        final Map<String, Object?> doc = s1Explore(id: 'whl0');
        if (row) {
          // The alef (p5) with no sign (p10): written as a result with no clip, which the validator allows in explore.
          ((doc['scene']! as Map<String, Object?>)['results']! as List<Object?>).add(<String, Object?>{
            'parts': <String>['p5', 'p10'],
            'text': 'א',
          });
        }
        p.add(doc);
        final Rig<ChangePartSession> r = Rig<ChangePartSession>(
          p,
          'whl0',
          (LessonController c, Activity a) => ChangePartSession(c, a as ChangePartActivity),
        );
        await r.pump(t);
        await t.tap(find.byKey(const Key('wheel-bead-4')));
        await r.wait(t, 400);
        await t.tap(find.byKey(const Key('wheel-sign-2')));
        await t.pump();
        expect(r.session.madeText, 'א');
        expect(r.session.hubShake, isTrue);
        await r.done(t);
      },
    );
  }

  // QA-6: a wheel with fewer than 7 letters (every `make` item: 2 letters) only shifts its beads (`ringOffset`), but `_turnTo` turns the short way round
  // modulo the part count, so `turn` leaves the range 0 to n - 1: the picked letter stands off the top (the ring at the top is empty, as in the golden
  // ls05_wheel_made_heb_phone.png) and after a few picks the beads are off the dial and gone.
  testWidgets(
    'QA-6 wheel make, two letters: the letter she picks is the one at the top, however many times she changes her mind',
    (WidgetTester t) async {
      final LangPack p = LangPack('heb')..addPictures(_pictures);
      p.addTag('dec.letter_mix', 'diagnostic');
      p.addTag('dec.vowel_skip', 'diagnostic');
      p.add(s1Make(p, id: 'whl1'));
      final Rig<ChangePartSession> r = Rig<ChangePartSession>(
        p,
        'whl1',
        (LessonController c, Activity a) => ChangePartSession(c, a as ChangePartActivity),
      );
      await r.pump(t);
      for (final int k in <int>[0, 1, 0, 1, 0]) {
        await t.tap(find.byKey(Key('wheel-bead-$k')), warnIfMissed: false);
        await r.wait(t, 600);
        expect(
          find.byKey(Key('wheel-bead-$k')),
          findsOneWidget,
          reason: 'the bead of letter $k is still on the dial',
        );
        expect(r.session.turn, k.toDouble(), reason: 'the dial stands with letter $k at the top');
      }
      await r.done(t);
    },
  );

  // QA-7: the validator allows 6 parts in a strip's `explore` (the Russian pilot's B-21 has 6 vowels), but the "go on" check stands at A's start and covers the
  // first tile on every board (judged from a render of а я о ё у ю; spec section 4.3 says the strip never hides a vowel).
  for (final MapEntry<String, Size> b in boards.entries) {
    testWidgets(
      'QA-7 strip explore with six vowels on ${b.key}: no tile is covered by the "go on" check or the picture',
      (WidgetTester t) async {
        final LangPack p = LangPack('rus')..addPictures(_pictures);
        final List<String> v = <String>['а', 'я', 'о', 'ё', 'у', 'ю'];
        p.add(
          changeJson(
            course: 'rus',
            id: 'str0',
            mode: 'explore',
            frame: 'м_',
            parts: <PartSpec>[for (int i = 0; i < 6; i++) part('p${i + 1}', 0, v[i])],
            results: <ResultSpec>[
              for (int i = 0; i < 6; i++)
                made(<String>['p${i + 1}'], 'м${v[i]}', sprite: i.isEven ? 'cat' : 'whale'),
            ],
          ),
        );
        await openLesson(t, p, 'str0', b.value, band: 1);
        await t.tap(find.byKey(const Key('strip-tile-1')));
        await waitFor(t, 400);
        final List<Rect> tiles = <Rect>[
          for (int i = 0; i < 6; i++) t.getRect(find.byKey(Key('strip-tile-$i'))),
        ];
        final Rect done = t.getRect(find.byKey(const Key('change-done')));
        for (final Rect tile in tiles) {
          expect(tile.overlaps(done), isFalse, reason: 'tile $tile under the check $done');
        }
        final Finder picture = find.byKey(const Key('strip-picture'));
        if (picture.evaluate().isNotEmpty) {
          for (final Rect tile in tiles) {
            expect(tile.overlaps(t.getRect(picture)), isFalse, reason: 'tile $tile under the picture');
          }
        }
      },
    );
  }

  // QA-8: the validator allows a wheel of 7 letters and 4 signs (S3 and later: qamats, patah, hiriq, shva), but the sign row's end beads overlap the two
  // lowest letter beads on the phone and the phone SE (a row of 3 signs, the S1 golden, does not).
  for (final MapEntry<String, Size> b in boards.entries) {
    testWidgets('QA-8 wheel with 7 letters and 4 signs on ${b.key}: no sign bead overlaps a letter bead', (
      WidgetTester t,
    ) async {
      final LangPack p = LangPack('heb');
      final List<String> letters = <String>['מ', 'ל', 'שׁ', 'ר', 'א', 'בּ', 'ת'];
      final List<String> signs = <String>[qamats, patah, hiriq, shva];
      p.add(
        changeJson(
          id: 'whl0',
          mode: 'explore',
          frame: '__',
          parts: <PartSpec>[
            for (int i = 0; i < 7; i++) part('p${i + 1}', 0, letters[i]),
            for (int j = 0; j < 4; j++) part('p${8 + j}', 1, signs[j]),
          ],
          results: <ResultSpec>[
            for (int i = 0; i < 7; i++)
              for (int j = 0; j < 4; j++)
                made(<String>['p${i + 1}', 'p${8 + j}'], letters[i] + signs[j], clip: 'vo:heb.u.$i$j'),
          ],
        ),
      );
      await openLesson(t, p, 'whl0', b.value, band: 1);
      final List<Rect> beads = <Rect>[
        for (int k = 0; k < 7; k++)
          if (find.byKey(Key('wheel-bead-$k')).evaluate().isNotEmpty)
            t.getRect(find.byKey(Key('wheel-bead-$k'))),
      ];
      for (int j = 0; j < 4; j++) {
        final Rect sign = t.getRect(find.byKey(Key('wheel-sign-$j')));
        for (final Rect bead in beads) {
          final Rect x = sign.intersect(bead);
          expect(x.width > 1 && x.height > 1, isFalse, reason: 'sign $j $sign over bead $bead');
        }
      }
    });
  }

  // QA-2: the hint-2 key-word card of the Hebrew wheel (phone, phone SE) stands over the bubble and hides its second line (judged from the golden
  // ls05_wheel_hint2_heb_phone.png).
  for (final MapEntry<String, Size> b in boards.entries.where(
    (MapEntry<String, Size> e) => e.key.startsWith('phone'),
  )) {
    testWidgets('QA-2 wheel hint 2 on ${b.key}: the key-word card does not cover the bubble', (
      WidgetTester t,
    ) async {
      final LangPack p = LangPack('heb')..addPictures(_pictures);
      p.addTag('dec.letter_mix', 'diagnostic');
      p.addTag('dec.vowel_skip', 'diagnostic');
      p.add(s1Make(p, id: 'whl1'));
      await openLesson(t, p, 'whl1', b.value);
      for (int i = 0; i < 2; i++) {
        await t.tap(find.byKey(const Key('change-done')));
        await waitFor(t, 1300);
      }
      final Rect card = t.getRect(find.byKey(const Key('change-key-card')));
      final Rect bubble = t.getRect(find.byKey(const Key('bubble-body')));
      expect(card.overlaps(bubble), isFalse, reason: 'card $card over bubble $bubble');
    });
  }

  // QA-3: a 3-line bubble on the phone SE reaches the 30-degree bead of the Hebrew wheel (design spec section 4.1 says the line "must stay at 2 lines"; nothing
  // holds it to that).
  testWidgets('QA-3 wheel on the phone SE: a three-line bubble stays clear of the dial', (
    WidgetTester t,
  ) async {
    final LangPack p = LangPack('heb')..addPictures(_pictures);
    final Map<String, Object?> a = s1Explore(id: 'whl0');
    (a['prompt']! as Map<String, Object?>)['caption'] = he(
      'הַקְשִׁיבוּ לַמִּלָּה, וְסוֹבְבוּ אֶת הַגַּלְגַּל עַד שֶׁתִּשְׁמְעוּ אֶת אוֹתָהּ מִלָּה.',
    );
    p.add(a);
    await openLesson(t, p, 'whl0', boards['phoneSE']!);
    final Rect bubble = t.getRect(find.byKey(const Key('bubble-body')));
    final List<Rect> beads = <Rect>[
      for (final Element e
          in find.byWidgetPredicate((Widget w) => w.key.toString().startsWith("[<'wheel-bead-")).evaluate())
        t.getRect(find.byElementPredicate((Element x) => x == e)),
    ];
    for (final Rect bead in beads) {
      expect(bubble.overlaps(bead), isFalse, reason: 'bubble $bubble over bead $bead');
    }
  });
}

/// [openLesson] (test/support/l4_golden.dart) with no clip in the voice bank at all: every clip pending, as the app is today (L5 section 7).
Future<AppRig> openLessonPending(WidgetTester t, LangPack p, String id, Size size) async {
  final AppRig rig = AppRig(
    content: p.content,
    characters: await languageVoiceSource(const <String>{'vo:x.unused'}),
    player: FakePlayer()..endsAfter = const Duration(milliseconds: 150),
  );
  await rig.seedFinishedSetup(name: 'נֹעָה', id: langKid);
  await rig.pump(t, size: size);
  await t.tap(find.text('נֹעָה'));
  await t.pumpAndSettle();
  final Activity a = p.content.activities['${p.course}.$id']!;
  t
      .state<NavigatorState>(find.byType(Navigator).first)
      .push(
        MaterialPageRoute<void>(
          builder: (BuildContext c) => LessonScreen(
            profileId: langKid,
            mission: Lesson.mission(
              id: 'shot',
              itemIds: <String>[a.id],
              skillIds: <String>[a.skillId],
              celebration: const Spoken(vo: 'vo:x.celebrate', caption: 'x'),
            ),
          ),
        ),
      );
  await t.pump(const Duration(milliseconds: 600));
  await waitFor(t, 2500);
  return rig;
}
