import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../child/activity_shell.dart';
import '../content/models.dart';
import '../design/app_text.dart';
import '../design/components.dart';
import '../design/tokens.g.dart';
import 'template_session.dart';

/// The clock template (T18): set the hands of an analog clock to a time. The short thick hand is the hour hand: the child drags
/// it round, or touches the arrows, and it snaps to the hours. For a half hour a button swaps the long hand to the six (and the
/// short hand then stands between two numbers, as it does on a real clock). A tick checks the time.
///
/// A whole hour set to twelve is the child who read the long hand as the hour: it carries M-CLOCK-HANDS. After three mistakes the
/// help shows where the short hand belongs, and only the right time is taken.
class ClockSetSession extends TemplateSession {
  ClockSetSession(super.controller, this.activity) : hour = activity.startHour, half = activity.startHalf;

  final ClockSetActivity activity;

  /// 1 to 12.
  int hour;
  bool half;
  bool ghost = false;
  AnswerState ring = AnswerState.idle;
  bool _busy = false;

  /// Does this activity use the half-hour button at all?
  bool get allowHalf => activity.half || activity.startHalf;

  void next() => _set(hour % 12 + 1);
  void previous() => _set((hour + 10) % 12 + 1);

  void _set(int h) {
    if (_busy || ring == AnswerState.correct) return;
    hour = h;
    ghost = false;
    notify();
  }

  void toggleHalf() {
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
    if (_busy || ring == AnswerState.correct) return;
    final bool right = hour == activity.hour && half == activity.half;
    if (controller.guided && !right) {
      ghost = true;
      notify();
      return;
    }
    _busy = true;
    String tag = '';
    if (!right) {
      final bool handsSwapped = !activity.half && activity.hour != 12 && hour == 12 && !half;
      tag = (handsSwapped && activity.handsTag != null) ? activity.handsTag! : (activity.wrongTag ?? '');
    }
    await controller.submitPlacement(right: right, tag: tag, response: '$hour${half ? ':30' : ':00'}');
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
      ghost = controller.guided;
      notify();
    });
  }

  @override
  void onReset() {
    hour = activity.startHour;
    half = activity.startHalf;
    ghost = false;
    ring = AnswerState.idle;
    _busy = false;
    notify();
  }

  @override
  void onReplay() {
    ghost = false;
    notify();
  }

  @override
  void onHint() {
    ghost = true;
    notify();
  }

  // ---- drawing ----

  @override
  Widget buildStage(BuildContext context, Size size, ActivitySpec spec) => ListenableBuilder(
    listenable: this,
    builder: (BuildContext c, Widget? _) {
      final double side = math.min(size.width, size.height) - 8;
      return Semantics(
        container: true,
        label: activity.altText,
        child: Center(
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
    if (s.ghost) {
      hand((a.hour % 12) * 30.0 + (a.half ? 15 : 0), r * 0.5, 9, TokenColors.hintHalo, alpha: 0.55);
      hand(a.half ? 180 : 0, r * 0.78, 5, TokenColors.hintHalo, alpha: 0.55);
    }
    hand(s.half ? 180 : 0, r * 0.78, 4, const Color(0xFF4DA3FF));
    hand((s.hour % 12) * 30.0 + (s.half ? 15 : 0), r * 0.5, 8, const Color(0xFFE5484D));
    canvas.drawCircle(c, 5, Paint()..color = TokenColors.ink);
  }

  @override
  bool shouldRepaint(_ClockPainter old) => true;
}
