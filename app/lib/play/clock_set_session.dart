import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../child/activity_shell.dart';
import '../content/hint_ladder.dart';
import '../content/models.dart';
import '../design/app_text.dart';
import '../design/components.dart';
import '../design/tokens.g.dart';
import 'hint_widgets.dart';
import 'hints/hint_marks.dart';
import 'hints/hint_player.dart';
import 'hints/pointer_plans.dart';
import 'hints/tile_points.dart';
import 'response_code.dart';
import 'template_session.dart';

/// The clock template (T18): set the hands of an analog clock to a time. The short thick hand is the hour hand: the child drags
/// it round, or touches the arrows, and it snaps to the hours. For a half hour a button swaps the long hand to the six (and the
/// short hand then stands between two numbers, as it does on a real clock). A tick checks the time.
///
/// A whole hour set to twelve is the child who read the long hand as the hour: it carries M-CLOCK-HANDS. After three mistakes the
/// guide first moves the short hand from the start to the right hour, hour by hour, as a worked example, and then a faint hand
/// stays where it belongs; only the right time is taken. The guide's pointing hand presses the plus tile for each hour, and the hour
/// it has reached is numbered on the dial. The clock never mirrors: the numbers run round it clockwise, whatever the language.
class ClockSetSession extends TemplateSession {
  ClockSetSession(super.controller, this.activity) : hour = activity.startHour, half = activity.startHalf;

  final ClockSetActivity activity;

  /// 1 to 12.
  int hour;
  bool half;

  /// The faint hands where the time belongs: shown only at the end of the worked example, and afterwards.
  bool ghost = false;

  /// Hint 1 lights the short hand (and fades the long one) and shows the hour of the question on a card; hint 2 rings that numeral
  /// on the dial; the worked example moves the short hand through [demoHour].
  bool lightHand = false;
  bool numeralRing = false;
  int? demoHour;
  int _run = 0;

  /// The dotted link, the numbers and the pointing hand of the hints, and the places they are drawn by (see [HintPlayer]).
  late final HintPlayer _hint = HintPlayer(this);
  Size _size = Size.zero;
  ActivitySpec _spec = ActivitySpec.phone;
  AnswerState ring = AnswerState.idle;
  bool _busy = false;

  /// The hour the short hand shows: the guide's while it demonstrates, the child's otherwise.
  int get shownHour => demoHour ?? hour;

  bool get demoRunning => demoHour != null;

  /// Does this activity use the half-hour button at all?
  bool get allowHalf => activity.half || activity.startHalf;

  void next() => _set(hour % 12 + 1);
  void previous() => _set((hour + 10) % 12 + 1);

  /// A touch of the child ends the guide's demonstration at once and the child's move is taken.
  void _endDemo() {
    if (!demoRunning) return;
    _run++;
    _hint.clear();
    demoHour = null;
    controller.demoDone();
  }

  void _set(int h) {
    _endDemo();
    if (_busy || ring == AnswerState.correct) return;
    hour = h;
    ghost = false;
    notify();
  }

  void toggleHalf() {
    _endDemo();
    if (_busy || ring == AnswerState.correct || !allowHalf) return;
    half = !half;
    ghost = false;
    notify();
  }

  /// A touch or a drag at [local] on a clock of [side] points: the short hand follows to the nearest hour.
  void dragTo(Offset local, double side) {
    final Offset d = local - Offset(side / 2, side / 2);
    if (d.distance < side * 0.08) return;
    double deg = math.atan2(d.dx, -d.dy) * 180 / math.pi;
    if (deg < 0) deg += 360;
    final int h = ((deg - (half ? 15 : 0)) / 30).round() % 12;
    _set(h == 0 ? 12 : h);
  }

  Future<void> check() async {
    _endDemo();
    if (_busy || ring == AnswerState.correct) return;
    final bool right = hour == activity.hour && half == activity.half;
    if (controller.guided && !right) {
      if (controller.answerShown) ghost = true;
      notify();
      return;
    }
    _busy = true;
    String tag = '';
    if (!right) {
      final bool handsSwapped = !activity.half && activity.hour != 12 && hour == 12 && !half;
      tag = (handsSwapped && activity.handsTag != null) ? activity.handsTag! : (activity.wrongTag ?? '');
    }
    await controller.submitPlacement(
      right: right,
      tag: tag,
      response: ResponseCode.clock(hour, half: half),
    );
    if (disposed) return;
    if (right) {
      ring = AnswerState.correct;
      notify();
      later(TemplateSession.praisePause, controller.next);
      return;
    }
    ring = AnswerState.notYet;
    notify();
    later(TemplateSession.notYetPause, () {
      ring = AnswerState.idle;
      _busy = false;
      hour = activity.startHour;
      half = activity.startHalf;
      ghost = controller.answerShown;
      notify();
    });
  }

  @override
  void onReset() {
    _run++;
    _hint.clear();
    hour = activity.startHour;
    half = activity.startHalf;
    ghost = false;
    lightHand = false;
    numeralRing = false;
    demoHour = null;
    ring = AnswerState.idle;
    _busy = false;
    notify();
  }

  @override
  void onReplay() {
    _run++;
    _hint.clear();
    ghost = false;
    lightHand = false;
    numeralRing = false;
    demoHour = null;
    notify();
  }

  @override
  void onHint() {
    if (demoRunning) return;
    switch (hintPictureOf(activity)) {
      case HintPicture.handAndHour:
        lightHand = true;
        numeralRing = false;
        _hint.clear();
        notify();
      case HintPicture.numeralOnDial:
        lightHand = true;
        numeralRing = true;
        _hint.play(_linkPlan());
        notify();
      default:
        _workedExample();
    }
  }

  // ---- the places of the stage, as the stage draws them ----

  double get _side => math.min(_size.width, _size.height) - 8;

  Offset get _centre => Offset(_size.width / 2, _size.height / 2);

  /// Where the numeral [h] stands on the dial: the stage's clock has its numerals at 0.7 of the radius.
  Offset _numeralAt(int h) {
    final double r = _side / 2 - 3;
    final double a = h * math.pi / 6;
    return _centre + Offset(math.sin(a), -math.cos(a)) * (r * 0.7);
  }

  /// The card with the hour of the question: at the stage's left, as wide as its numeral.
  Rect get _card {
    final TextPainter text = TextPainter(
      text: TextSpan(
        text: activity.half ? '${activity.hour}\u00bd' : '${activity.hour}',
        style: AppText.fixed(size: 36, weight: 800, lineHeight: 1),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    final double w = text.width + 26;
    final double h = text.height + 26;
    return Rect.fromLTWH(6, _size.height / 2 - h / 2, w, h);
  }

  /// Level 2: the card and the numeral of the dial are lit with the same sky ring ("find the same number on the clock"). A line
  /// from one to the other would run across the dial and over its hands, so the two rings are the link.
  HintPlan _linkPlan() {
    final List<HintMark> same = <HintMark>[RingMark(_card, round: false)];
    return HintPlan(<HintFrame>[HintFrame(same, hold: const Duration(milliseconds: 2600))], rest: same);
  }

  /// The worked example: the short hand steps from where it stands to the hour of the question, one hour at a time, and then goes
  /// back; a faint hand is left where the time belongs. Then it is the child's turn.
  void _workedExample() {
    _run++;
    final int run = _run;
    lightHand = true;
    numeralRing = true;
    ghost = false;
    final int steps = (activity.hour - hour + 12) % 12;
    demoHour = hour;
    // The hand presses the plus tile once for each hour, and the hour it has reached is numbered on the dial.
    final Offset plus = _spec.tileTip(allowHalf ? 4 : 3, 1, slot: 96, slop: 12, rtl: false);
    List<HintMark> reached(int k) => <HintMark>[
      for (int j = 1; j <= k; j++) BadgeMark(_numeralAt((hour + j - 1) % 12 + 1), (hour + j - 1) % 12 + 1),
    ];
    _hint.play(
      handTourPlan(<HandStop>[
        for (int k = 0; k <= steps; k++) HandStop(plus, 800, marks: reached(k)),
        HandStop(plus, 1400, marks: reached(steps)),
      ]),
    );
    for (int k = 1; k <= steps; k++) {
      later(Duration(milliseconds: 800 * k), () {
        if (run != _run) return;
        demoHour = (hour + k - 1) % 12 + 1;
        notify();
      });
    }
    later(Duration(milliseconds: 800 * steps + 1400), () {
      if (run != _run) return;
      demoHour = null;
      ghost = true;
      notify();
      controller.demoDone();
    });
    notify();
  }

  // ---- drawing ----

  @override
  Widget buildStage(BuildContext context, Size size, ActivitySpec spec) {
    _size = size;
    _spec = spec;
    return Stack(
      fit: StackFit.expand,
      clipBehavior: Clip.none,
      children: <Widget>[_stage(size), _hint.body(size)],
    );
  }

  @override
  Widget? buildHands(BuildContext context, Size size, ActivitySpec spec) => _hint.hands(size, spec);

  Widget _stage(Size size) => ListenableBuilder(
    listenable: this,
    builder: (BuildContext c, Widget? _) {
      final double side = math.min(size.width, size.height) - 8;
      return Semantics(
        container: true,
        label: activity.altText,
        child: Stack(
          children: <Widget>[
            Center(
              child: SizedBox(
                width: side,
                height: side,
                child: GestureDetector(
                  key: const Key('clock-face'),
                  behavior: HitTestBehavior.opaque,
                  onPanStart: (DragStartDetails d) => dragTo(d.localPosition, side),
                  onPanUpdate: (DragUpdateDetails d) => dragTo(d.localPosition, side),
                  onTapUp: (TapUpDetails d) => dragTo(d.localPosition, side),
                  child: CustomPaint(painter: _ClockPainter(this)),
                ),
              ),
            ),
            // The question again, as a card: the hour the short hand is to show (and a half for the half hour).
            if (lightHand)
              Positioned(
                left: 6,
                top: 0,
                bottom: 0,
                child: Center(
                  child: IgnorePointer(
                    child: HintCard(
                      child: Text(
                        activity.half ? '${activity.hour}\u00bd' : '${activity.hour}',
                        key: const Key('clock-hour-card'),
                        style: AppText.fixed(size: 36, weight: 800, lineHeight: 1),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      );
    },
  );

  @override
  Widget? buildTiles(BuildContext context, ActivitySpec spec) => ListenableBuilder(
    listenable: this,
    builder: (BuildContext c, Widget? _) => Directionality(
      textDirection: TextDirection.ltr,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          AnswerTile(
            key: const Key('clock-prev'),
            semanticLabel: 'back an hour',
            size: 72,
            onPressed: previous,
            child: const Icon(Icons.remove_rounded, size: 40, color: TokenColors.ink),
          ),
          AnswerTile(
            key: const Key('clock-next'),
            semanticLabel: 'forward an hour',
            size: 72,
            onPressed: next,
            child: const Icon(Icons.add_rounded, size: 44, color: TokenColors.ink),
          ),
          if (allowHalf)
            AnswerTile(
              key: const Key('clock-half'),
              semanticLabel: 'half past',
              size: 72,
              state: half ? AnswerState.selected : AnswerState.idle,
              onPressed: toggleHalf,
              child: Text('½', style: AppText.fixed(size: 40, weight: 800, lineHeight: 1)),
            ),
          AnswerTile(
            key: const Key('clock-ok'),
            semanticLabel: 'check',
            size: 72,
            state: ring == AnswerState.notYet
                ? AnswerState.notYet
                : (ring == AnswerState.correct ? AnswerState.correct : AnswerState.idle),
            onPressed: check,
            child: const Icon(Icons.check_rounded, size: 44, color: TokenColors.ink),
          ),
        ],
      ),
    ),
  );
}

class _ClockPainter extends CustomPainter {
  _ClockPainter(this.s) : super(repaint: s);

  final ClockSetSession s;

  @override
  void paint(Canvas canvas, Size size) {
    final Offset c = Offset(size.width / 2, size.height / 2);
    final double r = size.width / 2 - 3;
    canvas.drawCircle(c, r, Paint()..color = Colors.white);
    final Color edge = s.ring == AnswerState.correct
        ? TokenColors.correctGlow
        : (s.ring == AnswerState.notYet ? TokenColors.notYetRing : TokenColors.ink);
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..color = edge
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5,
    );
    final Paint tick = Paint()
      ..color = TokenColors.ink
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;
    for (int i = 0; i < 12; i++) {
      final double a = i * math.pi / 6;
      canvas.drawLine(
        c + Offset(math.sin(a), -math.cos(a)) * (r * 0.86),
        c + Offset(math.sin(a), -math.cos(a)) * (r * 0.94),
        tick,
      );
    }
    for (int i = 1; i <= 12; i++) {
      final double a = i * math.pi / 6;
      final TextPainter tp = TextPainter(
        text: TextSpan(
          text: '$i',
          style: AppText.fixed(size: r * 0.23, weight: 800, lineHeight: 1).copyWith(color: TokenColors.ink),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(
        canvas,
        c + Offset(math.sin(a), -math.cos(a)) * (r * 0.7) - Offset(tp.width / 2, tp.height / 2),
      );
    }
    void hand(double deg, double length, double width, Color colour, {double alpha = 1}) {
      final double a = deg * math.pi / 180;
      canvas.drawLine(
        c,
        c + Offset(math.sin(a), -math.cos(a)) * length,
        Paint()
          ..color = colour.withValues(alpha: alpha)
          ..strokeWidth = width
          ..strokeCap = StrokeCap.round,
      );
    }

    final ClockSetActivity a = s.activity;
    final int shown = s.shownHour;
    if (s.numeralRing) {
      final double ang = a.hour * math.pi / 6;
      canvas.drawCircle(
        c + Offset(math.sin(ang), -math.cos(ang)) * (r * 0.7),
        r * 0.16,
        Paint()
          ..color = TokenColors.hintHalo
          ..style = PaintingStyle.stroke
          ..strokeWidth = 4,
      );
    }
    if (s.lightHand) {
      // The short hand is lit from behind with a sky stroke, and the long hand fades back.
      hand((shown % 12) * 30.0 + (s.half ? 15 : 0), r * 0.5, 18, TokenColors.hintHalo, alpha: 0.7);
    }
    if (s.ghost) {
      hand((a.hour % 12) * 30.0 + (a.half ? 15 : 0), r * 0.5, 9, TokenColors.hintHalo, alpha: 0.55);
      hand(a.half ? 180 : 0, r * 0.78, 5, TokenColors.hintHalo, alpha: 0.55);
    }
    hand(s.half ? 180 : 0, r * 0.78, 4, const Color(0xFF4DA3FF), alpha: s.lightHand ? 0.35 : 1);
    hand((shown % 12) * 30.0 + (s.half ? 15 : 0), r * 0.5, 8, const Color(0xFFE5484D));
    canvas.drawCircle(c, 5, Paint()..color = TokenColors.ink);
  }

  @override
  bool shouldRepaint(_ClockPainter old) => true;
}
