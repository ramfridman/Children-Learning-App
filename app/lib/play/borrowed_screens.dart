import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../content/ls05_checks.dart' show composeFrame, isWheelSign;
import '../content/models.dart';
import '../design/board.dart' show BoardClass;
import '../design/course_text.dart';
import '../engine/course.dart';
import 'ls05_widgets.dart';

// The screens a hint borrows from another template (docs/milestones/L5.md section 5.9, docs/design/l5-templates.md sections 4.2 and 5.3): the small wheel
// (Hebrew level 2: the letters turn under a fixed sign, or the signs turn under a fixed letter), the compact strip (Russian level 2: the friend slides
// along the vowels under the consonant) and the slide (level 3: the friend slides through the word). A plan says what the friend does, step by step and with
// the clip of each step; the host session walks it on its own clock; `BorrowedPanel` draws the step it is on. The data come from the hint's `screen`, or, when
// it gives none, are worked out from the item's own stem and from the unit the child chose.

/// What the friend does in a borrowed screen.
sealed class BorrowedPlan {
  const BorrowedPlan();

  /// How many steps the friend takes, and the clip each one plays (null: it lights in silence).
  int get steps;
  String? clipAt(int step);

  /// The plan for the hint of a text stem (a decoding item): [show] is the hint's `screen`, [chosen] the text of the option the child chose last, if it had
  /// a text. Null when nothing can be shown (a screen the item gave no data for and the stem cannot supply).
  static BorrowedPlan? forStem(TapAnswerActivity a, HintShow show, {String? chosen}) {
    final String stem = a.stem?.text ?? '';
    if (stem.isEmpty) return null;
    if (show.template == 'blend_slide') {
      final BlendWord word =
          show.word ?? BlendWord(text: stem, parts: splitUnits(stem, a.course), whole: a.stem?.clip);
      return SlidePlan(parts: word.parts, whole: word.whole ?? a.stem?.clip, text: word.text);
    }
    if (show.frame != null && show.parts != null) return _fromData(a.course, show, stem, chosen);
    if (a.course == Course.heb) return _hebrewUnit(stem, chosen, a.stem?.clip);
    return null;
  }

  /// The plan for the second hint of a blend slide that names a screen.
  static BorrowedPlan? forBlend(BlendSlideActivity a, HintShow show) {
    final String text = a.word.text;
    if (show.template == 'blend_slide') {
      final BlendWord word = show.word ?? a.word;
      return SlidePlan(parts: word.parts, whole: word.whole ?? a.word.whole, text: word.text);
    }
    if (show.frame != null && show.parts != null) return _fromData(a.course, show, text, null);
    if (a.course == Course.heb) return _hebrewUnit(text, null, a.word.whole);
    return null;
  }

  /// A plan from the hint's own frame, parts and results (one place that changes).
  static BorrowedPlan? _fromData(String course, HintShow show, String target, String? chosen) {
    final ChangeFrame frame = show.frame!;
    final List<ChangePart> parts = show.parts!;
    if (frame.slots != 1) return null;
    String made(ChangePart p) {
      for (final ChangeResult r in show.results ?? const <ChangeResult>[]) {
        if (r.parts.length == 1 && r.parts.first == p.id) return r.text;
      }
      return composeFrame(frame.text, <String>[p.text]);
    }

    String? clip(ChangePart p) {
      for (final ChangeResult r in show.results ?? const <ChangeResult>[]) {
        if (r.parts.length == 1 && r.parts.first == p.id) return r.clip;
      }
      return null;
    }

    final List<String> texts = <String>[for (final ChangePart p in parts) made(p)];
    final int targetAt = math.max(0, texts.indexWhere((String t) => _same(t, target)));
    final int start = chosen == null ? 0 : math.max(0, texts.indexWhere((String t) => _same(t, chosen)));
    if (course == Course.heb) {
      return WheelPlan(
        ring: <String>[for (final ChangePart p in parts) p.text],
        ringIsSigns: parts.every((ChangePart p) => isWheelSign(p.text)),
        units: texts,
        clips: <String?>[for (final ChangePart p in parts) clip(p)],
        start: start,
        target: targetAt,
      );
    }
    return StripPlan(
      frame: frame.text,
      vowels: <String>[for (final ChangePart p in parts) p.text],
      words: texts,
      clips: <String?>[for (final ChangePart p in parts) clip(p)],
      start: start,
      target: targetAt,
    );
  }

  /// The wheel of a Hebrew unit worked out from the stem: when the letters differ the letters turn under the target's sign, otherwise the signs turn under the
  /// target's letter (and with nothing chosen, "no sign" against the sign: the reader who skips a vowel).
  static BorrowedPlan? _hebrewUnit(String stem, String? chosen, String? clip) {
    final ({String letter, String sign})? target = splitUnit(firstUnit(stem));
    if (target == null) return null;
    final ({String letter, String sign})? other = chosen == null ? null : splitUnit(firstUnit(chosen));
    if (other != null && other.letter != target.letter) {
      return WheelPlan(
        ring: <String>[other.letter, target.letter],
        ringIsSigns: false,
        units: <String>[other.letter + target.sign, target.letter + target.sign],
        clips: <String?>[null, clip],
        start: 0,
        target: 1,
      );
    }
    final String skipped = other != null && other.sign != target.sign ? other.sign : '';
    return WheelPlan(
      ring: <String>[skipped, target.sign],
      ringIsSigns: true,
      units: <String>[target.letter + skipped, target.letter + target.sign],
      clips: <String?>[null, clip],
      start: 0,
      target: 1,
    );
  }

  static bool _same(String a, String b) => _canon(a) == _canon(b);

  static String _canon(String t) {
    final List<int> r = t.runes.toList()..sort();
    return String.fromCharCodes(r);
  }
}

/// The wheel: the ring's parts and what each makes, and the two positions the friend turns between.
class WheelPlan extends BorrowedPlan {
  const WheelPlan({
    required this.ring,
    required this.ringIsSigns,
    required this.units,
    required this.clips,
    required this.start,
    required this.target,
  });

  final List<String> ring;
  final bool ringIsSigns;

  /// What each ring part makes in the hub, and its clip.
  final List<String> units;
  final List<String?> clips;
  final int start;
  final int target;

  /// The friend turns from the child's unit to the target.
  List<int> get path => start == target ? <int>[target] : <int>[start, target];

  @override
  int get steps => path.length;

  @override
  String? clipAt(int step) => clips[path[step]];
}

/// The strip: the frame, the vowels along it and the word each makes; the friend slides from the first to the target.
class StripPlan extends BorrowedPlan {
  const StripPlan({
    required this.frame,
    required this.vowels,
    required this.words,
    required this.clips,
    required this.start,
    required this.target,
  });

  final String frame;
  final List<String> vowels;
  final List<String> words;
  final List<String?> clips;
  final int start;
  final int target;

  /// Every vowel from the first to the target, each heard (the friend slides a, o, u under m and each is heard).
  List<int> get path => <int>[for (int i = 0; i <= math.max(start, target); i++) i];

  @override
  int get steps => path.length;

  @override
  String? clipAt(int step) => clips[path[step]];
}

/// The slide: the parts the friend slides through, and the whole that plays at the end.
class SlidePlan extends BorrowedPlan {
  const SlidePlan({required this.parts, required this.whole, required this.text});

  final List<BlendPart> parts;
  final String? whole;
  final String text;

  @override
  int get steps => parts.length;

  @override
  String? clipAt(int step) => parts[step].clip;
}

// ---- Hebrew units ----

bool _isMarkRune(int r) => (r >= 0x05B0 && r <= 0x05C7) && r != 0x05BE && r != 0x05C0 && r != 0x05C3;

/// The first unit of a text: its first letter with every mark that follows it.
String firstUnit(String text) {
  final StringBuffer b = StringBuffer();
  bool started = false;
  for (final int r in text.runes) {
    if (!started) {
      b.writeCharCode(r);
      started = true;
    } else if (_isMarkRune(r)) {
      b.writeCharCode(r);
    } else {
      break;
    }
  }
  return b.toString();
}

/// A unit as its letter (with its dagesh or shin dot) and its vowel sign, or null when it does not begin with a letter.
({String letter, String sign})? splitUnit(String unit) {
  final List<int> runes = unit.runes.toList();
  if (runes.isEmpty || !(runes.first >= 0x05D0 && runes.first <= 0x05EA)) return null;
  final StringBuffer letter = StringBuffer()..writeCharCode(runes.first);
  final StringBuffer sign = StringBuffer();
  for (final int r in runes.skip(1)) {
    if (r == 0x05BC || r == 0x05C1 || r == 0x05C2) {
      letter.writeCharCode(r);
    } else {
      sign.writeCharCode(r);
    }
  }
  return (letter: letter.toString(), sign: sign.toString());
}

/// The parts of a word to slide through when the item gives none: Hebrew a unit at a time (a letter with its marks; a final he after a qamats is one unit with
/// it), English and Russian a letter at a time (a digraph is one part).
List<BlendPart> splitUnits(String text, String course) {
  final List<String> parts = <String>[];
  if (course == Course.heb) {
    final List<int> runes = text.runes.toList();
    int i = 0;
    while (i < runes.length) {
      final StringBuffer b = StringBuffer()..writeCharCode(runes[i]);
      i++;
      while (i < runes.length && _isMarkRune(runes[i])) {
        b.writeCharCode(runes[i]);
        i++;
      }
      parts.add(b.toString());
    }
    // The final he of a word that ends in a qamats and a he is one unit with the letter before it.
    if (parts.length >= 2 &&
        parts.last == String.fromCharCode(0x05D4) &&
        parts[parts.length - 2].contains(String.fromCharCode(0x05B8))) {
      final String he = parts.removeLast();
      parts[parts.length - 1] = parts.last + he;
    }
  } else {
    const List<String> digraphs = <String>['sh', 'ch', 'th', 'ck', 'ng', 'wh'];
    final String lower = text.toLowerCase();
    int i = 0;
    while (i < text.length) {
      if (course == Course.eng && i + 1 < text.length && digraphs.contains(lower.substring(i, i + 2))) {
        parts.add(text.substring(i, i + 2));
        i += 2;
      } else {
        parts.add(text[i]);
        i++;
      }
    }
  }
  return <BlendPart>[for (final String p in parts) BlendPart(text: p)];
}

// ---- drawing ----

/// A borrowed screen at one step of its plan, in the room of the card it stands in.
class BorrowedPanel extends StatelessWidget {
  const BorrowedPanel({
    super.key,
    required this.plan,
    required this.step,
    required this.board,
    required this.course,
    required this.assets,
  });

  final BorrowedPlan plan;
  final int step;
  final BoardClass board;
  final String course;
  final PackAssets assets;

  @override
  Widget build(BuildContext context) => switch (plan) {
    final WheelPlan p => _wheel(p),
    final StripPlan p => _strip(p),
    final SlidePlan p => _slide(p),
  };

  Widget _wheel(WheelPlan p) {
    final int at = p.path[math.min(step, p.steps - 1)];
    return LayoutBuilder(
      builder: (BuildContext c, BoxConstraints box) {
        final WheelSpec probe = WheelSpec.mini(board, Offset.zero);
        final double radius = probe.ring + probe.bead / 2 + 8;
        final double group = 2 * radius + 14 + probe.hub.width;
        final double left = (box.maxWidth - group) / 2;
        // The wheel at the start side (the right), the unit it makes after it (the left).
        final Offset centre = Offset(
          left + group - radius,
          (box.maxHeight + probe.ring + probe.bead / 2) / 2 - 4,
        );
        final WheelSpec w = WheelSpec.mini(board, centre);
        return Stack(
          clipBehavior: Clip.none,
          children: <Widget>[
            Positioned.fill(
              child: TweenAnimationBuilder<double>(
                tween: Tween<double>(end: at.toDouble()),
                duration: MediaQuery.disableAnimationsOf(c)
                    ? Duration.zero
                    : const Duration(milliseconds: 350),
                builder: (BuildContext c, double turn, Widget? _) => WheelView(
                  key: const Key('mini-wheel'),
                  spec: w,
                  ring: p.ring,
                  ringIsSigns: p.ringIsSigns,
                  turn: turn,
                  hubText: p.units[at],
                  hubSide: HubSide.left,
                  onRing: (int _) {},
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _strip(StripPlan p) {
    final StripSpec s = StripSpec.compact(board);
    final int at = p.path[math.min(step, p.steps - 1)];
    final List<String> vowels = p.vowels;
    return Center(
      child: Column(
        key: const Key('mini-strip'),
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          FrameCard(course: course, frame: p.frame, window: vowels[at], spec: s),
          const SizedBox(height: 12),
          VowelStrip(texts: vowels, course: course, spec: s, current: at, onPick: (int _) {}),
        ],
      ),
    );
  }

  Widget _slide(SlidePlan p) {
    // The slide's own picture is drawn by the stem's stage (the page becomes the slide page); here the parts are lit in turn as tokens.
    return Row(
      mainAxisSize: MainAxisSize.min,
      textDirection: directionOfCourse(course),
      children: <Widget>[
        for (final (int i, BlendPart part) in p.parts.indexed)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: i == step ? const Color(0xFFE3F4FC) : null,
              ),
              child: Padding(
                padding: const EdgeInsets.all(6),
                child: CourseText(part.text, course: course, size: 40),
              ),
            ),
          ),
      ],
    );
  }
}
