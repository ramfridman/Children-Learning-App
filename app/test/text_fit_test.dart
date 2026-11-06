// The fit check of LS01 (docs/design/languages-l5-ls01.md section 4): every text face of every language item must fit the phone SE, the
// binding board, at the reading size of each band the course allows. A text that does not fit is a content error, found here with the real
// fonts before a pack is built, so that no device ever meets one. Fixture packs, not content; the pilot slices of the three courses are
// checked by the same function when their generators write packs.
import 'package:flutter_test/flutter_test.dart';
import 'package:nitznutz/content/models.dart';
import 'package:nitznutz/design/token_types.dart';
import 'package:nitznutz/play/ls01_fit.dart';
import 'package:nitznutz/play/ls01_metrics.dart';

import 'support/course_packs.dart';
import 'support/harness.dart';
import 'support/language_content.dart';
import 'support/ls01_content.dart';

const List<String> _pictures = <String>['cat', 'dog', 'duck', 'apple', 'banana', 'bread', 'book'];

Activity _item(Map<String, Object?> json, {String course = 'eng', LangPack? into}) {
  final LangPack p = into ?? (LangPack(course)..addPictures(_pictures));
  p.add(json);
  return p.content.activities[json['id']]!;
}

List<String> _problems(Activity a, {Iterable<Band>? bands}) => ls01FitProblems(a, bands: bands);

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await loadAppFonts();
  });

  group('the measure is the design-director\'s', () {
    test('the words of the fit table are as wide as it says, in em of the word size', () {
      final Ls01Metrics en = Ls01Metrics(band: Band.b, tablet: false, course: 'eng');
      final Ls01Metrics he = Ls01Metrics(band: Band.b, tablet: false, course: 'heb');
      // docs/design/languages-l5-ls01.md section 4.2, measured with the real fonts (Medium).
      expect(en.textWidth('cat', FaceKind.word) / en.size(FaceKind.word), closeTo(1.49, 0.06));
      expect(en.textWidth('rabbit', FaceKind.word) / en.size(FaceKind.word), closeTo(2.88, 0.1));
      expect(en.textWidth('elephant', FaceKind.word) / en.size(FaceKind.word), closeTo(4.11, 0.12));
      expect(he.textWidth('כֶּלֶב', FaceKind.word) / he.size(FaceKind.word), closeTo(1.60, 0.1));
    });

    test('the reading sizes are the spec\'s, per band, script and board', () {
      expect(Ls01Metrics(band: Band.b, tablet: false, course: 'eng').size(FaceKind.word), 38);
      expect(Ls01Metrics(band: Band.b, tablet: false, course: 'heb').size(FaceKind.word), 34);
      expect(Ls01Metrics(band: Band.b, tablet: true, course: 'rus').size(FaceKind.word), 44);
      expect(Ls01Metrics(band: Band.b, tablet: false, course: 'eng').size(FaceKind.letter), 48);
      expect(Ls01Metrics(band: Band.a, tablet: true, course: 'heb').size(FaceKind.stem), 56);
      expect(Ls01Metrics(band: Band.c, tablet: false, course: 'rus').size(FaceKind.kept), 26);
      expect(Ls01Metrics(band: Band.b, tablet: false, course: 'eng').tileHeight, 88);
      expect(Ls01Metrics(band: Band.b, tablet: true, course: 'eng').tileHeight, 104);
      expect(Ls01Metrics(band: Band.b, tablet: false, course: 'eng').squareGap, 24);
      expect(Ls01Metrics(band: Band.b, tablet: false, course: 'eng').wideGap, 16);
    });

    test(
      'the limit of a row on the phone SE is the spec\'s: 198 points for 2 options, 117 for 3, 77 for 4',
      () {
        final Ls01Metrics m = Ls01Metrics(band: Band.b, tablet: false, course: 'eng');
        expect(m.row(<String>['cat', 'map'], FaceKind.word, 484).textLimit, closeTo(198, 1));
        expect(m.row(<String>['cat', 'map', 'dog'], FaceKind.word, 484).textLimit, closeTo(117, 1));
        expect(m.row(<String>['cat', 'map', 'dog', 'pig'], FaceKind.word, 484).textLimit, closeTo(77, 1));
      },
    );
  });

  group('the fixture courses', () {
    for (final String course in <String>['eng', 'heb', 'rus']) {
      test('every language item of the $course fixture pack fits', () {
        final PackContent c = courseContent(course);
        final List<String> all = <String>[for (final Activity a in c.activities.values) ..._problems(a)];
        expect(all, isEmpty, reason: all.join('\n'));
        expect(c.activities, isNotEmpty);
      });
    }
  });

  group('each mode', () {
    Map<String, Object?> tapOf(List<String> words, {String? id, String course = 'eng', String? face}) {
      final LangPack p = LangPack(course);
      return tapJson(
        course: course,
        id: id ?? 'row',
        band: 'B',
        options: <Map<String, Object?>>[
          for (final (int i, String w) in words.indexed)
            textOption('o${i + 1}', w, tag: i == 0 ? null : p.tag('lis.sem')),
        ],
        correct: 'o1',
        answer: <String, Object?>{'face': ?face},
      );
    }

    test('words in a row of options: 4 short ones fit, "elephant" in 4 does not, in 2 it does', () {
      expect(_problems(_item(tapOf(<String>['cat', 'map', 'pig', 'dog']))), isEmpty);
      final List<String> long4 = _problems(
        _item(tapOf(<String>['cat', 'elephant', 'pig', 'dog'], id: 'long4')),
      );
      expect(long4, isNotEmpty);
      expect(long4.first, contains('"elephant"'));
      expect(long4.first, contains('the limit for 4 tiles in the row is'));
      expect(long4.first, contains('Band B on the phone SE'));
      expect(_problems(_item(tapOf(<String>['cat', 'elephant'], id: 'long2'))), isEmpty);
    });

    test(
      'a Hebrew word in Band A is bigger than in Band B: it is checked at each band the course allows',
      () {
        final Map<String, Object?> j = tapOf(<String>['כֶּלֶב', 'חָתוּל', 'דָּג'], course: 'heb', id: 'heb3');
        expect(_problems(_item(j, course: 'heb')), isEmpty);
        final List<String> bands = <String>[
          for (final String m in _problems(
            _item(
              tapOf(<String>['מִטְרִיָּה', 'אֲבַטִּיחַ', 'פַּרְפַּר', 'דָּג'], course: 'heb', id: 'heb4'),
              course: 'heb',
            ),
          ))
            m,
        ];
        // Three-syllable words in four options are too wide at the larger sizes of the younger bands.
        expect(bands, isNotEmpty);
      },
    );

    test('a stem: one word on one line, a phrase in two lines at most', () {
      final LangPack p = LangPack()..addPictures(_pictures);
      Map<String, Object?> stem(String id, String text) => stemJson(
        id: id,
        band: 'B',
        stem: text,
        options: <Map<String, Object?>>[
          pictureOption('o1', 'cat'),
          pictureOption('o2', 'dog', tag: p.tag('lis.sem')),
          pictureOption('o3', 'duck', tag: p.tag('lis.guess')),
        ],
        correct: 'o1',
      );
      expect(_problems(_item(stem('s1', 'cat'), into: p)), isEmpty);
      expect(_problems(_item(stem('s2', 'a cat is on the bed'), into: p)), isEmpty);
      final List<String> three = _problems(
        _item(stem('s3', 'the little cat is sitting on the big red bed'), into: p),
      );
      expect(three.first, contains('lines in a column of 214'));
      final List<String> wide = _problems(_item(stem('s4', 'extraordinarilylongword'), into: p));
      expect(wide.first, contains('the word is'));
    });

    test('a cloze: the column the picture leaves holds 3 lines in English, 2 in Hebrew', () {
      final LangPack p = LangPack()..addPictures(_pictures);
      Map<String, Object?> cloze(String id, String text) => clozeJson(
        id: id,
        band: 'B',
        text: text,
        picture: 'cat',
        options: <Map<String, Object?>>[
          textOption('o1', 'on'),
          textOption('o2', 'in', tag: p.tag('lis.sem')),
          textOption('o3', 'at', tag: p.tag('lis.guess')),
        ],
        correct: 'o1',
      );
      expect(_problems(_item(cloze('c1', 'The dog is _ the chair.'), into: p)), isEmpty);
      final List<String> long = _problems(
        _item(cloze('c2', 'The little brown dog is sitting _ the very big red chair by the door.'), into: p),
      );
      expect(long.first, contains('lines in a column of 166'));
    });

    test('a tap-all of 6 does not fit the phone SE at Band B: the row holds 4 and the stage 1 beside the speaker', () {
      final LangPack p = LangPack()..addPictures(_pictures);
      Map<String, Object?> all(String id, int n) => tapAllJson(
        id: id,
        band: 'B',
        face: 'letter',
        options: <Map<String, Object?>>[
          for (int i = 0; i < n; i++)
            textOption('o${i + 1}', 'tifln'[i % 5], tag: i < 2 ? null : p.tag('lis.sem')),
        ],
        correct: <String>['o1', 'o2'],
      );
      expect(_problems(_item(all('a5', 5), into: p)), isEmpty);
      expect(_problems(_item(all('a6', 6), into: p)).first, contains('a tap-all of 5 at most'));
    });

    test('a sort: the sign must fit its bin, the cards the tray, and a kept chip the bin', () {
      final LangPack p = LangPack()..addPictures(_pictures);
      Map<String, Object?> sort(String id, String sign, String card) => sortJson(
        id: id,
        band: 'B',
        bins: <Map<String, Object?>>[
          sortFace('b1', text: sign),
          sortFace('b2', text: 'i'),
          sortFace('b3', text: 'o'),
        ],
        items: <Map<String, Object?>>[
          sortFace('i1', text: card, bin: 'b1', tag: p.tag('lis.sem')),
          sortFace('i2', text: 'pin', bin: 'b2', tag: p.tag('lis.sem')),
          sortFace('i3', text: 'dot', bin: 'b3', tag: p.tag('lis.sem')),
        ],
      );
      expect(_problems(_item(sort('so1', 'a', 'pan'), into: p)), isEmpty);
      final List<String> wide = _problems(_item(sort('so2', 'aeiou', 'pan'), into: p));
      expect(wide.first, contains('the sign "aeiou"'));
      final List<String> card = _problems(_item(sort('so3', 'a', 'elephant'), into: p));
      expect(card, isNotEmpty);
    });

    test('order tiles: the row of the stage holds 4 cells on the phone SE', () {
      final LangPack p = LangPack()..addPictures(_pictures);
      Map<String, Object?> order(String id, List<String> model, List<String> seq) => orderJson(
        id: id,
        band: 'B',
        model: model,
        palette: <String>[...seq, 'txt:n'],
        sequence: seq,
        tag: p.tag('lis.sem'),
      );
      expect(
        _problems(_item(order('or1', <String>['txt:s', 'txt:a'], <String>['txt:t', 'txt:p']), into: p)),
        isEmpty,
      );
      final List<String> five = _problems(
        _item(order('or2', <String>['txt:s', 'txt:a', 'txt:t'], <String>['txt:p', 'txt:i']), into: p),
      );
      expect(five.first, contains('the row has 5 cells'));
    });

    test('pairs and spot rows fit like any row', () {
      final LangPack p = LangPack()..addPictures(_pictures);
      final Activity spot = _item(
        spotJson(
          id: 'sp1',
          band: 'B',
          cells: <String>['txt:cat', 'txt:cot', 'txt:cut', 'txt:cup'],
          wrong: 1,
          tag: p.tag('lis.sem'),
        ),
        into: p,
      );
      expect(_problems(spot), isEmpty);
      final Activity wide = _item(
        spotJson(
          id: 'sp2',
          band: 'B',
          cells: <String>['txt:elephant', 'txt:giraffe', 'txt:cut', 'txt:cup'],
          wrong: 1,
          tag: p.tag('lis.sem'),
        ),
        into: p,
      );
      expect(_problems(wide), isNotEmpty);
    });
  });
}
