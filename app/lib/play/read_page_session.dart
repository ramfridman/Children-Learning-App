import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../child/activity_shell.dart';
import '../content/hint_ladder.dart';
import '../content/models.dart';
import '../design/app_text.dart';
import '../design/layout.dart';
import '../design/token_types.dart' show Band;
import '../design/tokens.g.dart';
import 'choice_row.dart' show withLs01Zones, withTallStage;
import 'choice_session.dart';
import 'hint_hand.dart';
import 'lesson_controller.dart' show LessonController;
import 'story_session.dart' show svgAspect;
import 'template_session.dart' show PackSvg;

/// A page that shows its text (LS08 `zones` and `follow`, Hebrew Band A, HEB-A-12: print runs from the right to the left and carries the
/// words the voice reads; the child reads nothing). The page is a picture and its lines of print.
///
/// **zones**: "where do we start reading?". The child touches the end of a line the reading starts at (the right end), the other end of a
/// line or the picture. **follow**: the voice reads a word and waits; the child touches that word, and the voice reads the next, right to
/// left. A touch on another word or on the picture is the mistake it shows (`M-HEB-ORDER`, `M-HEB-PRINT-PICTURE`) and the voice reads
/// the word again; only the last right touch is the answer the lesson scores, so a mistake on the way is what the item records.
///
/// Nothing is drawn on the page at rest: the zones are places of the print, not buttons (a hint or the child's own touch lights them). The
/// hints: level 1 the reading arrow over the first line, from its start to its end; level 2 the page is read while a finger moves under its
/// words from the right to the left; level 3 the finger stops on the place to touch.
class ReadPageSession extends ChoiceSession {
  ReadPageSession(LessonController controller, StoryActivity activity, {super.stress})
    : story = activity,
      super(controller, activity, activity) {
    controller.replayQuiet = true;
    // The first word is read after the question has been asked (it waits its turn), never over it.
    if (follow) later(const Duration(milliseconds: 900), () => _sayDue(replace: false));
  }

  final StoryActivity story;

  bool get follow => story.mode == 'follow';
  StoryPage get page => story.pages.first;

  /// The words of the page in reading order, with the line each is in.
  late final List<({String text, String clip, int line})> words = <({String text, String clip, int line})>[
    for (final (int l, List<({String text, String? clip})> line) in page.lines.indexed)
      for (final ({String text, String? clip}) w in line) (text: w.text, clip: w.clip ?? '', line: l),
  ];

  /// The word that is due (follow): the child has touched the ones before it.
  int due = 0;

  /// The word that is lit now (the voice is reading it, or the child touched it).
  int? litWord;

  /// The reading arrow over the first line is showing (hint level 1).
  bool arrowShown = false;

  /// How far the finger has moved under the first line, from its start (0) to its end (1); null when it is not moving (hint level 2).
  double? reading;

  /// The finger rests on the place to touch (hint level 3).
  bool get pointing => controller.answerShown;

  ChoiceOption? optionAt(String zone) => options.where((ChoiceOption o) => o.zone == zone).firstOrNull;

  /// The place the finger rests on at level 3, as a zone name.
  String get rightZone => follow ? 'word' : 'line1-start';

  void _sayDue({bool replace = true}) {
    if (disposed || !follow || due >= words.length) return;
    litWord = due;
    notify();
    playClips?.call(<String>[words[due].clip], replace: replace);
    later(const Duration(milliseconds: 900), () {
      if (litWord == due) {
        litWord = null;
        notify();
      }
    });
  }

  /// A touch on the word [i] (follow): the due word goes on to the next; any other word is the mistake of the other-word zone.
  Future<void> touchWord(int i) async {
    if (busy || !follow) return;
    if (i == due) {
      if (due == words.length - 1) {
        litWord = i;
        await choose(optionAt('word')!.id);
        return;
      }
      due++;
      litWord = i;
      notify();
      later(const Duration(milliseconds: 500), _sayDue);
    } else {
      final ChoiceOption? other = optionAt('other');
      if (other != null) await choose(other.id);
      later(const Duration(milliseconds: 1500), _sayDue);
    }
  }

  /// A touch on a zone of the text (in the mode `zones`) or on the picture.
  Future<void> touchZone(String zone) async {
    final ChoiceOption? o = optionAt(zone);
    if (o != null) await choose(o.id);
  }

  // ---- hints ----

  @override
  void onReset() {
    super.onReset();
    due = 0;
    litWord = null;
    arrowShown = false;
    reading = null;
    notify();
    if (follow) later(const Duration(milliseconds: 600), _sayDue);
  }

  @override
  void onReplay() {
    if (follow) {
      _sayDue();
    } else {
      playClips?.call(page.clips, replace: true);
    }
  }

  @override
  void onHint() {
    switch (hintPictureOf(activity)) {
      case HintPicture.replayPart:
        arrowShown = true;
        notify();
        later(const Duration(milliseconds: 3200), () {
          arrowShown = false;
          notify();
        });
      case HintPicture.pagesInRow:
        _readAloud();
      default:
        arrowShown = false;
        if (follow) {
          litWord = due;
          notify();
        }
        endDemoIfShown();
    }
  }

  /// The page is read while a finger moves under the words from the right to the left.
  Future<void> _readAloud() async {
    arrowShown = false;
    if (follow) {
      for (final (int i, ({String text, String clip, int line}) w) in words.indexed) {
        litWord = i;
        notify();
        await sayAndWait(<String>[w.clip], replace: i == 0);
        if (disposed) return;
      }
      litWord = null;
      notify();
      return;
    }
    reading = 0;
    notify();
    final Future<void> played = sayAndWait(page.clips, replace: true, atMost: const Duration(seconds: 6));
    later(const Duration(milliseconds: 60), () {
      reading = 1;
      notify();
    });
    await played;
    if (disposed) return;
    reading = null;
    notify();
  }

  // ---- layout ----

  /// On the phones the picture is the stage and the print stands in the answer zone under it, one sentence to a line (docs/design/
  /// languages-band-a-qa.md section 5.2): the stage of a card is as wide as a phone's tall stage is not, and a five-word sentence wrapped
  /// into it and scaled down was a narrow column. The tablets keep the tall stage with both.
  bool zoned = false;

  @override
  ActivitySpec layoutFor(ActivitySpec base) {
    zoned = !base.stageIsCard;
    return zoned ? withLs01Zones(base, Band.a) : withTallStage(base);
  }

  @override
  Widget buildStage(BuildContext context, Size size, ActivitySpec spec) =>
      ListenableBuilder(listenable: this, builder: (BuildContext c, Widget? _) => _ReadStage(this, size));

  @override
  Widget? buildTiles(BuildContext context, ActivitySpec spec) {
    if (!zoned) return null;
    // The answer zone's height, to the edge where no touch place may be: two lines of print are scaled down to it, never cut.
    final double room = spec.boardHeight - TokenTouch.bottomNoHotspot - (spec.tilesTop - 12);
    return ListenableBuilder(
      listenable: this,
      builder: (BuildContext c, Widget? _) => ConstrainedBox(
        constraints: BoxConstraints(maxWidth: spec.tilesWidth, maxHeight: room),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          alignment: AlignmentDirectional.topStart,
          child: SizedBox(width: spec.tilesWidth, child: _ReadPrint(this, zoned: true)),
        ),
      ),
    );
  }
}

/// The print of a page is large: a size for the words that the stage holds in two or three lines.
const double _printSize = 34;

class _ReadStage extends StatelessWidget {
  const _ReadStage(this.s, this.size);

  final ReadPageSession s;
  final Size size;

  @override
  Widget build(BuildContext context) {
    final StoryActivity a = s.story;
    final StoryPage p = s.page;
    return Semantics(
      container: true,
      label: p.alt,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(TokenRadius.lg),
        child: Stack(
          key: const Key('read-stage'),
          children: <Widget>[
            if (a.background != null)
              Positioned.fill(child: PackSvg(a.assets.svg(a.background!), fit: BoxFit.cover)),
            Padding(
              padding: const EdgeInsets.all(8),
              child: s.zoned
                  ? _picture(a, p)
                  : Column(
                      children: <Widget>[
                        Expanded(flex: 5, child: _picture(a, p)),
                        const SizedBox(height: 6),
                        Expanded(flex: 4, child: _ReadPrint(s, zoned: false)),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  /// The picture of the page. A touch on it is the `picture` zone: nothing is drawn on it, whatever the hint.
  Widget _picture(StoryActivity a, StoryPage p) {
    final bool lit = s.optionAt('picture') != null && s.chosenId == s.optionAt('picture')!.id;
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints box) {
        final double aspect = svgAspect(a.assets.svg(p.picture));
        final double width = math.min(box.maxWidth, box.maxHeight * aspect);
        // The picture stands at the start of the page (the right) as the print does: the page is one column.
        return Align(
          alignment: AlignmentDirectional.centerStart,
          child: GestureDetector(
            key: const Key('read-picture'),
            behavior: HitTestBehavior.opaque,
            onTap: () => s.touchZone('picture'),
            child: SizedBox(
              width: width,
              height: width / aspect,
              child: DecoratedBox(
                position: DecorationPosition.foreground,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(TokenRadius.lg),
                  border: lit ? Border.all(color: TokenColors.notYetRing, width: 4) : null,
                ),
                child: PackSvg(a.assets.svg(p.picture)),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// The lines of print, one under the other, each starting at the right (the reading direction of Hebrew). In the stage of a card the words
/// wrap to its width and a page of more rows than the stage holds is scaled down, never cut; [zoned] (a phone's answer zone) sets each line
/// of the page in one row, which is shrunk only when it is wider than the zone.
class _ReadPrint extends StatelessWidget {
  const _ReadPrint(this.s, {required this.zoned});

  final ReadPageSession s;
  final bool zoned;

  @override
  Widget build(BuildContext context) {
    final double touch = AppLayout.of(context).touch.minControl;
    final StoryPage p = s.page;
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Column(
        key: const Key('read-print'),
        mainAxisSize: zoned ? MainAxisSize.min : MainAxisSize.max,
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          for (final (int l, List<({String text, String? clip})> line) in p.lines.indexed)
            if (zoned)
              SizedBox(
                height: touch,
                child: s.follow
                    ? FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: AlignmentDirectional.centerStart,
                        child: _FollowLine(s, l, line, touch, oneRow: true),
                      )
                    : _ZoneLine(s, l, line.map((w) => w.text).join(' '), touch),
              )
            else
              Flexible(
                child: s.follow
                    ? LayoutBuilder(
                        builder: (BuildContext context, BoxConstraints box) => FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: AlignmentDirectional.centerStart,
                          child: ConstrainedBox(
                            constraints: BoxConstraints(maxWidth: box.maxWidth),
                            child: _FollowLine(s, l, line, touch),
                          ),
                        ),
                      )
                    : _ZoneLine(s, l, line.map((w) => w.text).join(' '), touch),
              ),
        ],
      ),
    );
  }
}

/// A line of print with its two ends as zones (`zones`): the text is set at one size, right-aligned, and the start and the end of what is
/// written are the touch places, each a third of the line and never narrower than a touch. Nothing is drawn on them at rest.
class _ZoneLine extends StatelessWidget {
  const _ZoneLine(this.s, this.index, this.text, this.touch);

  final ReadPageSession s;
  final int index;
  final String text;
  final double touch;

  @override
  Widget build(BuildContext context) {
    final TextStyle style = AppText.fixed(size: _printSize, weight: 500, lineHeight: 1.7);
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints box) {
        final TextPainter painter = TextPainter(
          text: TextSpan(text: text, style: style),
          textDirection: TextDirection.rtl,
          locale: const Locale('he'),
        )..layout();
        final double scale = math.min(1, box.maxWidth / painter.width);
        final double width = painter.width * scale;
        final double zone = math.max(touch, width / 3);
        final double height = math.max(box.maxHeight, touch);
        // In a right-to-left line the start of the reading is the right edge: `start` is the right, and the text is set against it.
        Widget place(String name, {required bool atStart}) {
          final ChoiceOption? o = s.optionAt(name);
          final bool chosen = o != null && s.chosenId == o.id;
          final bool lit =
              o != null &&
              (chosen || (s.pointing && name == s.rightZone) || s.litTile == s.options.indexOf(o));
          return PositionedDirectional(
            start: atStart ? 0 : math.max(0, width - zone),
            top: 0,
            width: zone,
            height: height,
            child: Semantics(
              button: o != null,
              label: o?.label,
              child: GestureDetector(
                key: Key('read-zone-$name'),
                behavior: HitTestBehavior.opaque,
                onTap: () => s.touchZone(name),
                child: lit
                    ? DecoratedBox(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(TokenRadius.lg),
                          border: Border.all(
                            color: chosen ? TokenColors.notYetRing : TokenColors.hintHalo,
                            width: 5,
                          ),
                        ),
                      )
                    : null,
              ),
            ),
          );
        }

        return SizedBox(
          height: height,
          child: Stack(
            clipBehavior: Clip.none,
            children: <Widget>[
              Positioned.fill(
                child: Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      text,
                      key: Key('read-line-$index'),
                      style: style,
                      textDirection: TextDirection.rtl,
                      locale: const Locale('he'),
                    ),
                  ),
                ),
              ),
              place('line${index + 1}-start', atStart: true),
              place('line${index + 1}-end', atStart: false),
              if (index == 0 && (s.arrowShown || s.reading != null || s.pointing))
                _guide(context, width, height),
            ],
          ),
        );
      },
    );
  }

  /// What the hints draw over the first line: the reading arrow (level 1), the finger moving under the words (level 2) and the finger resting
  /// on the start (level 3). The arrow points the way the print is read, to the left, and never mirrors.
  Widget _guide(BuildContext context, double width, double height) {
    final double handHeight = math.min(72, height);
    return Positioned.fill(
      child: IgnorePointer(
        child: Stack(
          clipBehavior: Clip.none,
          children: <Widget>[
            if (s.arrowShown)
              PositionedDirectional(
                start: 0,
                width: width,
                bottom: -6,
                height: 18,
                child: CustomPaint(
                  key: const Key('read-arrow'),
                  painter: _ArrowPainter(TokenColors.hintHalo),
                ),
              ),
            // The finger resting on the start (level 3) comes from the guide's side, the upper right, as every pointing hand does: its
            // tip touches the top of the first letter and the hand lies above the line, so no letter of the first word is covered
            // (QA-BA-10). It ends 6 past the line's start, inside the stage's padding of 8.
            if (s.pointing && s.reading == null)
              PositionedDirectional(
                key: const Key('read-finger'),
                start: -6,
                top: 4 - PointingHand.tipAt(handHeight).dy,
                child: PointingHand(height: handHeight),
              )
            else if (s.reading != null || s.pointing)
              AnimatedPositionedDirectional(
                key: const Key('read-finger'),
                duration: s.reading == null || MediaQuery.disableAnimationsOf(context)
                    ? Duration.zero
                    : const Duration(seconds: 3),
                curve: Curves.easeInOut,
                start: (s.reading ?? 0) * (width - PointingHand.widthAt(handHeight)),
                bottom: -handHeight * 0.45,
                child: PointingHand(height: handHeight),
              ),
          ],
        ),
      ),
    );
  }
}

/// A line of print whose words are touched one after the other (`follow`): the voice reads the word that is due and waits for a touch on it.
class _FollowLine extends StatelessWidget {
  const _FollowLine(this.s, this.index, this.line, this.touch, {this.oneRow = false});

  final ReadPageSession s;
  final int index;
  final List<({String text, String? clip})> line;
  final double touch;

  /// The whole line is one row of words (the phone's answer zone); otherwise the words wrap onto as many rows as the width needs.
  final bool oneRow;

  @override
  Widget build(BuildContext context) {
    final int first = <int>[for (int l = 0; l < index; l++) s.page.lines[l].length]
        .fold(0, (int a, int b) => a + b);
    // The words wrap onto as many rows as the width needs, so that the print stays large; the first word is at the right.
    final List<Widget> words = <Widget>[
      for (final (int k, ({String text, String? clip}) w) in line.indexed)
        Padding(padding: const EdgeInsets.symmetric(horizontal: 4), child: _word(context, first + k, w.text)),
    ];
    if (oneRow) {
      return Row(textDirection: TextDirection.rtl, mainAxisSize: MainAxisSize.min, children: words);
    }
    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: Wrap(textDirection: TextDirection.rtl, runSpacing: 2, children: words),
    );
  }

  Widget _word(BuildContext context, int i, String text) {
    final bool lit = s.litWord == i || (s.pointing && i == s.due);
    final bool read = i < s.due;
    return GestureDetector(
      key: Key('read-word-$i'),
      behavior: HitTestBehavior.opaque,
      onTap: () => s.touchWord(i),
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.bottomCenter,
        children: <Widget>[
          Container(
            constraints: BoxConstraints(minHeight: touch, minWidth: touch),
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(TokenRadius.lg),
              border: lit ? Border.all(color: TokenColors.hintHalo, width: 5) : null,
            ),
            child: Text(
              text,
              style: AppText.fixed(
                size: _printSize,
                weight: 500,
                lineHeight: 1.7,
                color: read ? TokenColors.ink : TokenColors.ink,
              ),
              textDirection: TextDirection.rtl,
              locale: const Locale('he'),
            ),
          ),
          if (s.pointing && i == s.due)
            Positioned(
              bottom: -PointingHand.tipAt(60).dy,
              child: IgnorePointer(child: PointingHand(key: const Key('read-finger'), height: 60)),
            ),
        ],
      ),
    );
  }
}

/// The reading arrow: a line along the print from its start (the right) to its end (the left), with the head on the left.
class _ArrowPainter extends CustomPainter {
  const _ArrowPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final Paint p = Paint()
      ..color = color
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final double y = size.height / 2;
    canvas.drawLine(Offset(size.width, y), Offset(8, y), p);
    canvas.drawLine(Offset(8, y), Offset(22, y - 9), p);
    canvas.drawLine(Offset(8, y), Offset(22, y + 9), p);
  }

  @override
  bool shouldRepaint(_ArrowPainter old) => old.color != color;
}
