// QA's defects of milestone L1 (docs/qa/l1-languages-verification.md): QA-L1-1 to QA-L1-4. Each test was the failing proof of its
// defect, skipped until the fix; the fixes are in, and the proofs now run in every build.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nitznutz/child/activity_shell.dart';
import 'package:nitznutz/content/models.dart';
import 'package:nitznutz/content/scripts.dart';
import 'package:nitznutz/design/board.dart' show boardClassFor;
import 'package:nitznutz/design/token_types.dart' show Band;
import 'package:nitznutz/design/tokens.g.dart';
import 'package:nitznutz/play/activity_frame.dart';
import 'package:nitznutz/play/lesson_controller.dart';
import 'package:nitznutz/play/tap_answer_session.dart';

import 'support/fakes.dart';
import 'support/harness.dart';
import 'support/language_content.dart';

const Map<String, Size> boards = <String, Size>{
  'phone': Size(852, 393),
  'phoneSE': Size(667, 375),
  'tabletLandscape': Size(1180, 820),
  'tabletPortrait': Size(820, 1180),
};

String _cp(int r) => String.fromCharCode(r);

/// A session of the one item of [p], on a screen of [size] in the band [band].
class _Rig {
  _Rig(LangPack p, {String id = 'words'}) {
    final PackContent content = p.content;
    activity = content.activities['${p.course}.$id']! as TapAnswerActivity;
    controller = LessonController(
      content: content,
      lesson: Lesson.mission(
        id: 'one',
        itemIds: <String>[activity.id],
        skillIds: <String>[activity.skillId],
        celebration: const Spoken(vo: 'vo:x.celebrate', caption: 'x'),
      ),
      profileId: 'p-1',
      clock: FixedClock(1793000000000),
      record: (AttemptRecord r) async {},
    );
    session = TapAnswerSession(controller, activity)
      ..playClips = (List<String> ids, {bool replace = false}) {};
  }

  late final TapAnswerActivity activity;
  late final LessonController controller;
  late final TapAnswerSession session;

  Future<void> pump(WidgetTester t, {Size size = const Size(852, 393), Band band = Band.a}) async {
    addTearDown(() {
      if (!session.disposed) session.dispose();
    });
    await pumpScreen(
      t,
      Builder(
        builder: (BuildContext c) {
          final ActivitySpec spec = ActivitySpec.of(boardClassFor(size));
          return ActivityFrame(
            bubbleText: 'x',
            stage: (Size room) => session.buildStage(c, room, spec),
            tiles: session.buildTiles(c, spec),
            trailTotal: 3,
            trailDone: 1,
            onHome: () {},
          );
        },
      ),
      size: size,
      band: band,
    );
  }

  Future<void> done(WidgetTester t) async {
    await t.pumpWidget(const SizedBox());
    session.dispose();
  }

  Text textIn(WidgetTester t, String id) =>
      t.widget<Text>(find.descendant(of: find.byKey(Key('tile-$id')), matching: find.byType(Text)));
}

LangPack _words(String course, List<String> w) {
  final LangPack p = LangPack(course);
  p.add(
    tapJson(
      course: course,
      id: 'words',
      options: <Map<String, Object?>>[
        for (final (int i, String word) in w.indexed)
          textOption(
            'o${i + 1}',
            word,
            tag: i == 0 ? null : p.tag(i.isOdd ? 'lis.sem' : 'lis.guess'),
            clip: 'vo:$course.words.${'abcd'[i]}',
          ),
      ],
      correct: 'o1',
    ),
  );
  return p;
}

void main() {
  setUpAll(loadAppFonts);

  // QA-L1-1 (major, owner: app-developer, with the design-director for the look). `isSingleLetter` counts the letters of a
  // tile's own text, so a word of one or two letters ("on", "up", "да", "ёж", the Hebrew "דָּג", "גַּן", and the own-name
  // tiles "בן", "טל", "דן" of HEB-A-11) is set as a letter: bold, at the full tile font (56), while its neighbours are Medium at
  // 0.55 of it. In an item that mixes lengths one tile stands out. In HEB-A-11 ("recognise your own written name") it is
  // the child's own name when that name is short, which gives the answer away by its look alone. The choice between the
  // "letter" face and the "word" face has to be made once for the whole item (all options are letters, or none is), not
  // for each tile by counting.
  // Spec: frame 2.3 LS01 (a) text faces; HEB-A-11 distractors "never a name equal to the child's", names of 2 to 5 letters.
  for (final (String, String, List<String>) c in <(String, String, List<String>)>[
    ('English', 'eng', <String>['on', 'cat', 'sun']),
    ('Russian', 'rus', <String>['да', 'нет', 'мама']),
    ('Hebrew names (HEB-A-11)', 'heb', <String>['דָּן', 'נוֹעָה', 'יַעַל']),
  ]) {
    testWidgets(
      'QA-L1-1: ${c.$1}: a word of two letters is set like the words beside it, not like a letter',
      (WidgetTester t) async {
        final _Rig r = _Rig(_words(c.$2, c.$3));
        await r.pump(t);
        final Text short = r.textIn(t, 'o1');
        for (final String id in <String>['o2', 'o3']) {
          final Text other = r.textIn(t, id);
          expect(
            short.style!.fontSize,
            other.style!.fontSize,
            reason: '${c.$3.first} against ${c.$3[int.parse(id.substring(1)) - 1]}',
          );
          expect(short.style!.fontWeight, other.style!.fontWeight);
        }
        await r.done(t);
      },
    );
  }

  // QA-L1-2 (major, owner: design-director for the size, app-developer for the code). The speaker on a text tile is a child
  // control, and design-spec 6.1 sets its engineering floor at 64 pt in Band A and 56 pt in Bands B and C. `SpeakerMark` is
  // 48 pt to touch (a 36 pt disc), in every band. A child who aims at the speaker and lands beside it answers the tile.
  for (final (String, Band) b in <(String, Band)>[
    ('Band A', Band.a),
    ('Band B', Band.b),
    ('Band C', Band.c),
  ]) {
    testWidgets('QA-L1-2: the speaker on a tile is at least the ${b.$1} floor to touch', (
      WidgetTester t,
    ) async {
      final _Rig r = _Rig(_words('eng', <String>['cat', 'dog', 'sun']));
      await r.pump(t, band: b.$2);
      final Size speaker = t.getSize(find.byKey(const Key('speaker-o1')));
      final double floor = TokenTouch.band[b.$2]!.minControl;
      expect(
        speaker.width,
        greaterThanOrEqualTo(floor),
        reason: '${speaker.width} wide, the floor is $floor',
      );
      expect(
        speaker.height,
        greaterThanOrEqualTo(floor),
        reason: '${speaker.height} high, the floor is $floor',
      );
      await r.done(t);
    });
  }

  // QA-L1-3 (minor, owner: app-developer). The decodable check compares the code points of a word with the taught graphemes as
  // they were typed. Hebrew marks on one letter have a canonical order (a vowel, then the dagesh, then a shin or sin dot),
  // but an editor may type the dagesh first, and a tool may reorder. A grapheme "בָּ" typed one way does not read a word
  // typed the other way: the word is refused with "its letters are taught, but not in this order", which sends an author
  // looking for an order problem that is not there. The words and graphemes are to be compared after putting the marks in
  // canonical order (and the same for `unpointedHebrewWords`).
  test(
    'QA-L1-3: a grapheme and a word with the same Hebrew marks in another order are the same grapheme',
    () {
      final String canonical = '${_cp(0x5D3)}${_cp(0x5B8)}${_cp(0x5BC)}';
      final String typed = '${_cp(0x5D3)}${_cp(0x5BC)}${_cp(0x5B8)}';
      final String gimel = _cp(0x5D2);
      expect(
        decodes('$canonical$gimel', <String>{typed, gimel}),
        isTrue,
        reason: 'the word in canonical order',
      );
      expect(decodes('$typed$gimel', <String>{canonical, gimel}), isTrue, reason: 'the word as typed');
    },
  );

  // QA-L1-4 (minor, owner: design-director). On the phone SE a Hebrew line of nine words with a word in its chip (the Band A
  // prompts `he-ins-how-many`, "כַּמָּה יֵשׁ? הַקְשִׁיבוּ לַכַּפְתּוֹרִים, וּגְעוּ בַּמִּסְפָּר הַנָּכוֹן.", and the Hebrew welcome line)
  // makes the bubble's body end 11 pt under the top edge of the first row of tiles, and the border of the chip 3 pt under
  // it: the tile (painted above the bubble) cuts the chip and the lip of the bubble. Nothing is lost for the child, but the
  // bubble "sits on" the tiles. The font is already at its floor (14), so the line cannot shrink; the bubble needs
  // another place (wider, or the chip beside a short line), or the line has to be shorter (hebrew-text-editor).
  testWidgets('QA-L1-4: phone SE: a nine-word line with a word in its chip stays clear of the tiles', (
    WidgetTester t,
  ) async {
    const String line = 'כַּמָּה יֵשׁ? הַקְשִׁיבוּ לַכַּפְתּוֹרִים, וּגְעוּ בַּמִּסְפָּר הַנָּכוֹן.';
    final ActivitySpec spec = ActivitySpec.of(boardClassFor(boards['phoneSE']!));
    await pumpScreen(
      t,
      ActivityFrame(
        bubbleText: line,
        bubbleTarget: (text: 'elephant', course: 'eng'),
        stage: (Size room) => const SizedBox.expand(),
        tiles: const SizedBox(height: 96),
        trailTotal: 3,
        trailDone: 1,
        onHome: () {},
      ),
      size: boards['phoneSE']!,
      band: Band.a,
    );
    await t.pump(const Duration(seconds: 2));
    expect(t.getRect(find.byKey(const Key('target-chip'))).bottom, lessThanOrEqualTo(spec.tilesTop));
    expect(t.getRect(find.byKey(const Key('bubble-body'))).bottom, lessThanOrEqualTo(spec.tilesTop));
  });
}
