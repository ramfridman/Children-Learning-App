// Two-clip lines and the clip hook on the lesson screen (docs/languages/frame.md, F3 as far as LS01 needs it): a Hebrew frame clip
// and then the target clip, the replay, the word on show in its chip, the speaker and the sound buttons through the voice
// director, and the director's `sayClips` on its own. Fake clips (each a file that names its line), no real voice.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nitznutz/content/models.dart';
import 'package:nitznutz/play/lesson_screen.dart';
import 'package:nitznutz/voice/voice_bank.dart';
import 'package:nitznutz/voice/voice_director.dart';

import 'support/app_harness.dart';
import 'support/harness.dart';
import 'support/language_content.dart';
import 'support/language_voice.dart';
import 'support/voice_fixtures.dart';

/// Every `vo:` reference in the pack's documents, except [without].
Set<String> _refs(LangPack p, {Set<String> without = const <String>{}}) {
  final Set<String> out = <String>{};
  void scan(Object? n) {
    if (n is String && n.startsWith('vo:') && !without.contains(n)) out.add(n);
    if (n is Map<String, Object?>) n.values.forEach(scan);
    if (n is List<Object?>) n.forEach(scan);
  }

  scan(p.pack.docs);
  return out;
}

Future<void> _wait(WidgetTester t, int ms) async {
  for (int spent = 0; spent < ms; spent += 100) {
    await t.pump(const Duration(milliseconds: 100));
  }
  await t.pump(const Duration(milliseconds: 50));
}

/// The app with the pack [p] and a voice that has its lines; the lesson of [id] is on the screen.
Future<AppRig> _open(WidgetTester t, LangPack p, String id, {Set<String> without = const <String>{}}) async {
  final PackContent content = p.content;
  final AppRig rig = AppRig(
    content: content,
    characters: await languageVoiceSource(_refs(p, without: without)),
    player: FakePlayer()..endsAfter = const Duration(milliseconds: 200),
  );
  await rig.seedFinishedSetup(name: 'נֹעָה');
  await rig.pump(t);
  await t.tap(find.text('נֹעָה'));
  await t.pumpAndSettle();
  final Activity a = content.activities['${p.course}.$id']!;
  t
      .state<NavigatorState>(find.byType(Navigator).first)
      .push(
        MaterialPageRoute<void>(
          builder: (BuildContext c) => LessonScreen(
            profileId: 'p-1',
            mission: Lesson.mission(
              id: 'one',
              itemIds: <String>[a.id],
              skillIds: <String>[a.skillId],
              celebration: const Spoken(vo: 'vo:x.celebrate', caption: 'x'),
            ),
          ),
        ),
      );
  await t.pump(const Duration(milliseconds: 600));
  await _wait(t, 2500);
  return rig;
}

LangPack _words() {
  final LangPack p = LangPack();
  final Map<String, Object?> a = tapJson(
    id: 'words',
    options: <Map<String, Object?>>[
      textOption('o1', 'cat', clip: 'vo:eng.words.a'),
      textOption('o2', 'dog', tag: p.tag('lis.sem'), clip: 'vo:eng.words.b'),
      textOption('o3', 'sun', tag: p.tag('lis.guess'), clip: 'vo:eng.words.c'),
    ],
    correct: 'o1',
    target: 'vo:eng.words.word',
  );
  ((a['feedback']! as Map<String, Object?>)['correct']! as Map<String, Object?>)['target'] =
      'vo:eng.words.rightword';
  ((a['hints']! as List<Object?>)[1]! as Map<String, Object?>)['show'] = 'cat';
  ((a['hints']! as List<Object?>)[1]! as Map<String, Object?>)['target'] = 'vo:eng.words.h2word';
  p.add(a);
  return p;
}

void main() {
  setUpAll(loadAppFonts);

  group('a line of two clips', () {
    testWidgets('the prompt is the Hebrew frame clip and then the target clip', (WidgetTester t) async {
      final AppRig rig = await _open(t, _words(), 'words');
      expect(playedLines(rig.player.played), <String>['eng.words.prompt', 'eng.words.word']);
    });

    testWidgets('the replay says both again, in the same order', (WidgetTester t) async {
      final AppRig rig = await _open(t, _words(), 'words');
      await t.tap(find.byKey(const Key('lesson-replay')));
      await _wait(t, 1500);
      expect(playedLines(rig.player.played), <String>[
        'eng.words.prompt',
        'eng.words.word',
        'eng.words.prompt',
        'eng.words.word',
      ]);
    });

    testWidgets('a target clip that has no recording leaves the frame clip, which plays all the same', (
      WidgetTester t,
    ) async {
      final AppRig rig = await _open(t, _words(), 'words', without: <String>{'vo:eng.words.word'});
      expect(playedLines(rig.player.played), <String>['eng.words.prompt']);
    });

    testWidgets('a line with no second clip is one clip, as every line of the lands is', (
      WidgetTester t,
    ) async {
      final LangPack p = LangPack();
      p.add(
        tapJson(
          id: 'one',
          options: <Map<String, Object?>>[
            textOption('o1', 'cat'),
            textOption('o2', 'dog', tag: p.tag('lis.sem')),
            textOption('o3', 'sun', tag: p.tag('lis.guess')),
          ],
          correct: 'o1',
        ),
      );
      final AppRig rig = await _open(t, p, 'one');
      expect(playedLines(rig.player.played), <String>['eng.one.prompt']);
    });

    testWidgets('the right answer is praised in two clips, after the answer', (WidgetTester t) async {
      final AppRig rig = await _open(t, _words(), 'words');
      await t.tap(find.byKey(const Key('tile-o1')));
      await _wait(t, 1500);
      expect(playedLines(rig.player.played), <String>[
        'eng.words.prompt',
        'eng.words.word',
        'eng.words.right',
        'eng.words.rightword',
      ]);
    });

    testWidgets('a hint puts its word in a chip under the line, and says its target clip after it', (
      WidgetTester t,
    ) async {
      final AppRig rig = await _open(t, _words(), 'words');
      expect(find.byKey(const Key('target-chip')), findsNothing);
      await t.tap(find.byKey(const Key('lesson-hint')));
      await _wait(t, 400);
      await t.tap(find.byKey(const Key('lesson-hint')));
      await _wait(t, 2500);
      final Finder chip = find.byKey(const Key('target-chip'));
      expect(chip, findsOneWidget);
      expect(t.widget<Text>(find.descendant(of: chip, matching: find.byType(Text))).data, 'cat');
      expect(
        t.getRect(chip).top,
        greaterThanOrEqualTo(
          t
              .getRect(
                find.descendant(of: find.byKey(const Key('bubble-body')), matching: find.byType(Text)).first,
              )
              .bottom,
        ),
        reason: 'under the Hebrew line, not inside it',
      );
      expect(playedLines(rig.player.played).sublist(playedLines(rig.player.played).length - 2), <String>[
        'eng.words.h2',
        'eng.words.h2word',
      ]);
      await _wait(t, 400);
    });

    testWidgets(
      'no Latin letter ever stands in the Hebrew caption: the bubble\'s line is Hebrew and the word is the chip\'s',
      (WidgetTester t) async {
        await _open(t, _words(), 'words');
        await t.tap(find.byKey(const Key('lesson-hint')));
        await _wait(t, 400);
        await t.tap(find.byKey(const Key('lesson-hint')));
        await _wait(t, 800);
        final Iterable<String> lines = t
            .widgetList<Text>(
              find.descendant(of: find.byKey(const Key('bubble-body')), matching: find.byType(Text)),
            )
            .map((Text w) => w.data!)
            .where((String s) => s != 'cat');
        for (final String l in lines) {
          expect(RegExp('[A-Za-z]').hasMatch(l), isFalse, reason: l);
        }
        await _wait(t, 2500);
      },
    );
  });

  group('the clip hook on the lesson screen', () {
    testWidgets('a speaker plays its tile\'s clip and does not answer', (WidgetTester t) async {
      final AppRig rig = await _open(t, _words(), 'words');
      await t.tap(find.byKey(const Key('speaker-o2')));
      await _wait(t, 600);
      expect(playedLines(rig.player.played).last, 'eng.words.b');
      expect(find.byKey(const Key('tile-o2')), findsOneWidget);
      expect(find.text('x'), findsNothing, reason: 'the lesson has not ended: a listen is not an answer');
    });

    testWidgets('a sound button says its clip as it answers, and the line about it waits for the clip', (
      WidgetTester t,
    ) async {
      final LangPack p = LangPack();
      p.add(
        tapJson(
          id: 'snd',
          options: <Map<String, Object?>>[
            soundOption('o1', 'vo:eng.snd.a'),
            soundOption('o2', 'vo:eng.snd.b', tag: p.tag('lis.numword')),
            soundOption('o3', 'vo:eng.snd.c', tag: p.tag('lis.numword')),
          ],
          correct: 'o1',
        ),
      );
      final AppRig rig = await _open(t, p, 'snd');
      await t.tap(find.byKey(const Key('tile-o2')));
      await _wait(t, 4000);
      // The word of the button, then the line about the mistake, then (the hint after a mistake) every button again.
      expect(playedLines(rig.player.played).sublist(1), <String>[
        'eng.snd.b',
        'eng.snd.again',
        'eng.snd.a',
        'eng.snd.b',
        'eng.snd.c',
      ]);
    });
  });

  group('sayClips on the voice director', () {
    Future<(VoiceDirector, FakePlayer)> director(Set<String> ids) async {
      final FakePlayer player = FakePlayer()..endsAfter = const Duration(milliseconds: 100);
      final VoiceDirector d = VoiceDirector(player: player, poll: const Duration(seconds: 100));
      d.useBank(await bankOf(ids));
      addTearDown(d.dispose);
      return (d, player);
    }

    Future<void> later(int ms) => Future<void>.delayed(Duration(milliseconds: ms));

    test('the clips play one after the other, in order', () async {
      final (VoiceDirector d, FakePlayer player) = await director(<String>{'vo:a', 'vo:b', 'vo:c'});
      await d.sayClips(<String?>['vo:a', 'vo:b', 'vo:c']);
      await later(600);
      expect(playedLines(player.played), <String>['a', 'b', 'c']);
    });

    test('all four sound buttons play in turn (a line of four clips keeps all of them)', () async {
      final (VoiceDirector d, FakePlayer player) = await director(<String>{'vo:a', 'vo:b', 'vo:c', 'vo:d'});
      await d.sayClips(<String?>['vo:a', 'vo:b', 'vo:c', 'vo:d']);
      await later(800);
      expect(playedLines(player.played), <String>['a', 'b', 'c', 'd']);
    });

    test('a clip with no recording, or no id, is skipped and the others still play', () async {
      final (VoiceDirector d, FakePlayer player) = await director(<String>{'vo:a', 'vo:c'});
      await d.sayClips(<String?>['vo:a', 'vo:b', null, 'vo:c']);
      await later(600);
      expect(playedLines(player.played), <String>['a', 'c']);
    });

    test('without replace the clips wait for the line that plays; with it the first cuts in', () async {
      final (VoiceDirector d, FakePlayer player) = await director(<String>{'vo:a', 'vo:b', 'vo:c', 'vo:d'});
      await d.say('vo:a');
      await d.sayClips(<String?>['vo:b', 'vo:c']);
      await later(30);
      expect(playedLines(player.played), <String>['a'], reason: 'b and c wait for a');
      await later(600);
      expect(playedLines(player.played), <String>['a', 'b', 'c']);
      await d.sayClips(<String?>['vo:d'], replace: true);
      await later(30);
      expect(playedLines(player.played).last, 'd');
      await later(300);
    });

    test('a line of one clip is exactly what sayNext does', () async {
      final (VoiceDirector d, FakePlayer player) = await director(<String>{'vo:a'});
      await d.sayClips(<String?>['vo:a', null]);
      await later(300);
      expect(playedLines(player.played), <String>['a']);
    });
  });

  group('the voice bank of the fixtures', () {
    test('a line is a file that names its character and its line', () async {
      final VoiceBank bank = await bankOf(<String>['vo:eng.x.a']);
      expect(bank.has('vo:eng.x.a'), isTrue);
      expect(lineOf(bank.clip('vo:eng.x.a')!.mp3), 'eng.x.a');
    });
  });
}
