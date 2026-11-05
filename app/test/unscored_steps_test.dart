// SEC-L4-1: a step that is never scored (a story only heard, a chant, the embodied "done", a personal turn) writes no attempt of any kind,
// "show me" (`unsure`) included, and offers no lamp and no eye. Fixture course, no widgets.
import 'package:flutter_test/flutter_test.dart';
import 'package:nitznutz/content/models.dart';
import 'package:nitznutz/play/lesson_controller.dart';

import 'support/fakes.dart';
import 'support/language_content.dart';

const List<String> _pictures = <String>['cat', 'dog', 'teddy'];

LangPack _pack() {
  final LangPack p = LangPack()..addPictures(_pictures);
  p.add(
    storyJson(
      id: 'tale',
      pages: <Map<String, Object?>>[
        storyPage('cat', <String>['vo:eng.t.1']),
        storyPage('dog', <String>['vo:eng.t.2']),
      ],
    ),
  );
  p.add(
    singJson(
      id: 'chant',
      pictures: <Map<String, Object?>>[songPicture('cat')],
      lines: <Map<String, Object?>>[
        <String, Object?>{
          'clips': <String>['vo:eng.c.1'],
          'lights': <int>[0],
        },
        <String, Object?>{
          'clips': <String>['vo:eng.c.2'],
          'lights': <int>[0],
        },
      ],
    ),
  );
  p.add(listenDoJson(id: 'doit', mode: 'embodied'));
  p.add(puppetJson(id: 'mine', mode: 'personal', topic: 'name'));
  return p;
}

void main() {
  for (final String id in <String>['tale', 'chant', 'doit', 'mine']) {
    test('$id: "show me" and the lamp do nothing and write nothing', () async {
      final LangPack p = _pack();
      final PackContent content = p.content;
      final List<AttemptRecord> written = <AttemptRecord>[];
      final LessonController c = LessonController(
        content: content,
        lesson: Lesson.mission(
          id: 'one',
          itemIds: <String>['eng.$id'],
          skillIds: <String>['ENG-A-02'],
          celebration: const Spoken(vo: 'vo:x.celebrate', caption: 'x'),
        ),
        profileId: 'p-1',
        clock: FixedClock(1793000000000),
        record: (AttemptRecord r) async => written.add(r),
      );
      expect(c.current.unscored, isTrue);
      expect(c.noHelp, isTrue, reason: 'the frame draws neither the lamp nor the eye');
      final int nonce = c.voiceNonce;
      await c.unsure();
      c.showHint();
      expect(written, isEmpty, reason: 'not even an "unsure"');
      expect(c.hintShown, 0);
      expect(c.voiceNonce, nonce);
    });
  }

  test('a scored item is not unscored: a dialogic story, a rhyme and a bubble keep their help', () {
    final LangPack p = LangPack()..addPictures(_pictures);
    p.add(
      storyJson(
        id: 'ask',
        pages: <Map<String, Object?>>[
          storyPage('cat', <String>['vo:eng.t.1']),
          storyPage('dog', <String>['vo:eng.t.2']),
        ],
        pauseAfter: 0,
        options: <Map<String, Object?>>[
          pictureOption('o1', 'cat'),
          pictureOption('o2', 'dog', tag: p.tag('lis.sem')),
        ],
        correct: 'o1',
      ),
    );
    expect(p.content.activities['eng.ask']!.unscored, isFalse);
  });
}
