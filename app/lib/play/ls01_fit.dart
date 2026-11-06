import 'dart:math' as math;

import '../child/activity_shell.dart';
import '../content/models.dart';
import '../content/scripts.dart' show isSingleLetter;
import '../design/token_types.dart';
import '../engine/course.dart';
import 'choice_row.dart';
import 'ls01_metrics.dart';

// The fit check of the text faces of LS01 (docs/design/languages-l5-ls01.md section 4): every text of every language item must fit the
// phone SE, the binding board, at the reading size of each band the course allows. A text that does not fit is a content error, found here
// before a pack is built, so that no device ever meets one: the screen never shrinks a text below its reading size. The test
// `test/text_fit_test.dart` runs this over the language packs; the numbers are the ones the screens use (`Ls01Metrics`, `withLs01Zones`).

/// The bands whose reading sizes the course's text must fit: English and Russian show no text under Band A (frame section 3.1), Hebrew does.
List<Band> fitBandsOf(String course) => course == Course.heb ? Band.values : const <Band>[Band.b, Band.c];

/// What is wrong with the text faces of [a] on the phone SE at each of [bands] (the course's by default), one sentence for each: the item, the
/// text, how wide it is and how wide it may be. Empty when every text fits.
List<String> ls01FitProblems(Activity a, {Iterable<Band>? bands}) {
  final List<String> out = <String>[];
  for (final Band band in bands ?? fitBandsOf(a.course)) {
    final ActivitySpec zones = withLs01Zones(
      ActivitySpec.phoneSE,
      band,
      wide: a is BuildPatternActivity && a.isSequence,
    );
    final Ls01Metrics m = Ls01Metrics.of(band: band, spec: zones, course: a.course);
    final _Fit fit = _Fit(a.id, band, m, zones, out);
    switch (a) {
      case TapAnswerActivity():
        fit.tap(a);
      case SortDragActivity() when a.isLanguage:
        fit.sort(a);
      case MatchPairsActivity() when a.isLanguage:
        fit.pairs(a);
      case SpotErrorActivity() when a.isLanguage:
        fit.spot(a);
      case BuildPatternActivity() when a.isLanguage:
        a.isSequence ? fit.sequence(a) : fit.order(a);
      default:
    }
  }
  return out;
}

String _txt(String cell) => cell.startsWith('txt:') ? cell.substring(4) : cell;

class _Fit {
  _Fit(this.id, this.band, this.m, this.zones, this.out);

  final String id;
  final Band band;
  final Ls01Metrics m;
  final ActivitySpec zones;
  final List<String> out;

  String get _where => '$id at Band ${band.name.toUpperCase()} on the phone SE';

  void _say(String message) => out.add('$_where: $message');

  double _w(String text, FaceKind kind) => m.textWidth(text, kind);

  /// A row of equal tiles for [texts] in the answer zone: the widest text decides the width and the row must hold [count] tiles.
  void _row(String what, List<String> texts, FaceKind kind, {int? count, double reserve = 0}) {
    if (texts.isEmpty) return;
    final RowPlan p = m.row(texts, kind, zones.tilesWidth - reserve, count: count);
    if (p.fits) return;
    final String widest = texts.reduce((String x, String y) => _w(x, kind) >= _w(y, kind) ? x : y);
    _say(
      '$what: "$widest" is ${p.widest.toStringAsFixed(0)} points wide at the reading size, '
      'and the limit for ${p.count} tiles in the row is ${p.textLimit.toStringAsFixed(0)}',
    );
  }

  FaceKind _kindOf(Iterable<String> texts) =>
      texts.isNotEmpty && texts.every(isSingleLetter) ? FaceKind.letter : FaceKind.word;

  // ---- tap_answer: the plain tap, the stem, the cloze, the tap-all ----

  void tap(TapAnswerActivity a) {
    final List<String> texts = <String>[
      for (final ChoiceOption o in a.options)
        if (o.text != null) o.text!,
    ];
    final FaceKind kind = a.letterFace ? FaceKind.letter : FaceKind.word;
    if (a.all) {
      _tapAllCapacity(a, texts, kind);
    } else {
      _row('the options', texts, kind, count: a.options.length);
    }
    final ({String text, String? clip})? stem = a.stem;
    if (stem != null) _stem(stem.text);
    final ({String text, String? picture})? cloze = a.cloze;
    if (cloze != null) _cloze(cloze, texts);
  }

  /// A tap-all: the cards stand in the answer zone as many as fit and the rest at the stage's end side, beside the speaker of the target.
  void _tapAllCapacity(TapAnswerActivity a, List<String> texts, FaceKind kind) {
    final int n = a.options.length;
    final RowPlan one = m.row(texts, kind, zones.tilesWidth, count: 1);
    if (one.tileWidth + one.gap > zones.tilesWidth) {
      _say(
        'the cards: a card is ${one.tileWidth.toStringAsFixed(0)} points wide and the row has ${zones.tilesWidth.toStringAsFixed(0)}',
      );
      return;
    }
    final int inA = (zones.tilesWidth / one.cell).floor();
    final double stageRoom = zones.stage.width - 64 - 8;
    final int inS = math.max(0, (stageRoom / one.cell).floor());
    if (n > inA + inS) {
      _say(
        'the cards: $n cards, but the row holds $inA and the stage $inS beside the speaker: a tap-all of ${inA + inS} at most',
      );
    }
  }

  /// A stem on the page of the stage: one word at the stem size on one line, a phrase at the line size in at most two lines.
  void _stem(String text) {
    final double column = zones.stage.width - 48;
    final bool oneWord = !text.contains(' ');
    final FaceKind kind = oneWord ? FaceKind.stem : FaceKind.line;
    final ({int lines, double widestWord}) l = m.lines(text, kind, column);
    if (l.widestWord > column) {
      _say(
        'the stem "$text": the word is ${l.widestWord.toStringAsFixed(0)} points wide and the page has ${column.toStringAsFixed(0)}',
      );
    } else if (l.lines > (oneWord ? 1 : 2)) {
      _say(
        'the stem "$text" takes ${l.lines} lines in a column of ${column.toStringAsFixed(0)} (at most ${oneWord ? 1 : 2})',
      );
    }
  }

  /// A cloze: the sentence in the column the picture leaves (64 wide and 32 apart on the SE), the gap as one unbreakable piece as wide as
  /// the widest option and 16 more; at most 3 lines in English and Russian and 2 in Hebrew; its three word tiles in a row.
  void _cloze(({String text, String? picture}) cloze, List<String> options) {
    final double column = zones.stage.width - (cloze.picture == null ? 0 : 64 + 32);
    final double gapWidth = options.map((String o) => _w(o, FaceKind.line)).fold<double>(0, math.max) + 16;
    // The pieces of the sentence: its words, and the gap (with the punctuation that stuck to it) as one piece as wide as the gap.
    final List<double> pieces = <double>[
      for (final String w in cloze.text.split(' '))
        if (w.isNotEmpty)
          if (w.contains('_'))
            _w(w.substring(0, w.indexOf('_')), FaceKind.line) +
                gapWidth +
                _w(w.substring(w.indexOf('_') + 1), FaceKind.line)
          else
            _w(w, FaceKind.line),
    ];
    final ({int lines, double widestWord}) l = (
      lines: Ls01Metrics.wrapLines(pieces, column, m.size(FaceKind.line) * 0.3),
      widestWord: pieces.fold<double>(0, math.max),
    );
    final int most = m.hebrew ? 2 : 3;
    if (l.widestWord > column) {
      _say(
        'the cloze "${cloze.text}": its widest piece is ${l.widestWord.toStringAsFixed(0)} points and the column ${column.toStringAsFixed(0)}',
      );
    } else if (l.lines > most) {
      _say(
        'the cloze "${cloze.text}" takes ${l.lines} lines in a column of ${column.toStringAsFixed(0)} (at most $most)',
      );
    }
  }

  // ---- sort ----

  void sort(SortDragActivity a) {
    final int n = a.bins.length;
    final double binWidth = (zones.stage.width - 12 - (n - 1) * 8) / n;
    for (final SortBin b in a.bins) {
      final String? t = b.text;
      if (t == null) continue;
      final double w = _w(t, isSingleLetter(t) ? FaceKind.letter : FaceKind.word);
      if (w > binWidth - 12 - 12) {
        _say(
          'the sign "$t" of ${b.id} is ${w.toStringAsFixed(0)} points wide and the bin has ${(binWidth - 24).toStringAsFixed(0)} for it',
        );
      }
    }
    final List<String> cards = <String>[
      for (final SortItem i in a.items)
        if (i.text != null) i.text!,
    ];
    _row('the cards', cards, _kindOf(cards), count: 1, reserve: 56);
    for (final String c in cards) {
      final double chip = _w(c, FaceKind.kept) + 16;
      if (chip > binWidth - 12) {
        _say(
          'the kept chip "$c" is ${chip.toStringAsFixed(0)} points wide and the bin has ${(binWidth - 12).toStringAsFixed(0)}',
        );
      }
    }
  }

  // ---- pairs ----

  void pairs(MatchPairsActivity a) {
    final List<String> partners = <String>[
      for (final MatchFace f in a.right)
        if (f.text != null) f.text!,
    ];
    _row('the partners', partners, _kindOf(partners), count: a.right.length);
    for (final MatchFace f in a.left) {
      final String? t = f.text;
      if (t == null) continue;
      final bool letter = isSingleLetter(t);
      final double w = _w(t, letter ? FaceKind.letter : FaceKind.word) * (letter ? 1.25 : 1);
      if (w > 120 - 16) {
        _say('the item now "$t" is ${w.toStringAsFixed(0)} points wide and its square has 104');
      }
    }
  }

  // ---- spot, order, sequence ----

  void spot(SpotErrorActivity a) {
    final List<String> cells = <String>[
      for (final String c in a.cells)
        if (c.startsWith('txt:')) _txt(c),
    ];
    _row('the cells', cells, _kindOf(cells), count: a.cells.length);
  }

  void order(BuildPatternActivity a) {
    final List<String> tiles = <String>[
      for (final String c in a.palette)
        if (c.startsWith('txt:')) _txt(c),
    ];
    _row('the tiles', tiles, _kindOf(tiles), count: a.palette.length);
    // The row of the stage: cells of 52 points, 8 apart; the phone SE holds 4 of them (the model and the places).
    final int cells = a.model.length + a.slots;
    final double room = zones.stage.width - 12;
    if (cells * 60 > room) {
      _say('the row has $cells cells (the model and the places) and the stage holds ${(room / 60).floor()}');
    }
    for (final String c in <String>[...a.model, ...a.palette]) {
      if (!c.startsWith('txt:')) continue;
      final double w = _w(_txt(c), FaceKind.letter);
      if (w > 52 - 8) _say('the cell "${_txt(c)}" is ${w.toStringAsFixed(0)} points wide and a cell has 44');
    }
  }

  void sequence(BuildPatternActivity a) {
    final int n = a.palette.length;
    final double w = (zones.tilesWidth - (n - 1) * 16) / n;
    for (final String c in a.palette) {
      if (!c.startsWith('txt:')) continue;
      final double tw = _w(_txt(c), FaceKind.letter);
      if (tw > w - 12) {
        _say(
          'the place "${_txt(c)}" is ${tw.toStringAsFixed(0)} points wide and a place has ${(w - 12).toStringAsFixed(0)}',
        );
      }
    }
  }
}
