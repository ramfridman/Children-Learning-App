import 'package:flutter/material.dart';

import '../design/app_text.dart';
import '../design/tokens.g.dart';
import '../strings/he.dart';

/// Domain name and colour for the progress view.
({String name, Color color}) domainLook(String domain) => switch (domain) {
  'numbers' => (name: He.domainNumbers.text, color: TokenColors.domainNumbersDeep),
  'colors' => (name: He.domainColors.text, color: TokenColors.domainColorsDeep),
  'shapes' => (name: He.domainShapes.text, color: TokenColors.domainShapesDeep),
  'logic' => (name: He.domainLogic.text, color: TokenColors.domainLogicDeep),
  'cs' => (name: He.domainCs.text, color: TokenColors.domainCsDeep),
  'math' => (name: He.domainMath.text, color: TokenColors.domainMathDeep),
  _ => (name: domain, color: TokenColors.inkSoft),
};

/// The Hebrew letter of a weekday (Sunday is alef).
String dayLetter(DateTime d) => He.dayLetters.text.split(' ')[d.weekday % 7];

/// Minutes of play for each of the last seven days, as bars with their values written above them. Time runs from
/// right to left, as the week does for a Hebrew reader.
class MinutesBars extends StatelessWidget {
  const MinutesBars({super.key, required this.data});

  final List<({DateTime day, int minutes})> data;

  @override
  Widget build(BuildContext context) => Semantics(
    container: true,
    label: <String>[for (final ({DateTime day, int minutes}) d in data) '${dayLetter(d.day)}: ${d.minutes}']
        .join(', '),
    child: ExcludeSemantics(
      child: SizedBox(
        height: 160,
        width: double.infinity,
        child: CustomPaint(painter: _BarsPainter(data)),
      ),
    ),
  );
}

class _BarsPainter extends CustomPainter {
  _BarsPainter(this.data);

  final List<({DateTime day, int minutes})> data;

  @override
  void paint(Canvas canvas, Size size) {
    const double labelRoom = 22;
    final double top = 20;
    final double base = size.height - labelRoom;
    final int most = data.fold<int>(
      10,
      (int m, ({DateTime day, int minutes}) d) => d.minutes > m ? d.minutes : m,
    );
    final double slot = size.width / data.length;
    final Paint bar = Paint()..color = TokenColors.night;
    final Paint rule = Paint()
      ..color = TokenColors.hairline
      ..strokeWidth = 1;
    canvas.drawLine(Offset(0, base), Offset(size.width, base), rule);
    for (int i = 0; i < data.length; i++) {
      final ({DateTime day, int minutes}) d = data[i];
      // The oldest day is at the right edge.
      final double cx = size.width - slot * (i + 0.5);
      final double h = (base - top) * d.minutes / most;
      if (d.minutes > 0) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(center: Offset(cx, base - h / 2), width: slot * 0.5, height: h),
            const Radius.circular(6),
          ),
          bar,
        );
        _text(canvas, '${d.minutes}', Offset(cx, base - h - 10), AppText.parent(TokenType.parentSmall));
      }
      _text(
        canvas,
        dayLetter(d.day),
        Offset(cx, base + 11),
        AppText.parent(TokenType.parentSmall, color: TokenColors.inkSoft),
      );
    }
  }

  @override
  bool shouldRepaint(_BarsPainter old) => old.data != data;
}

void _text(Canvas canvas, String s, Offset center, TextStyle style) {
  final TextPainter p = TextPainter(
    text: TextSpan(text: s, style: style),
    textDirection: TextDirection.rtl,
  )..layout();
  p.paint(canvas, center - Offset(p.width / 2, p.height / 2));
}

/// Understanding over the last eight weeks: one line per domain, from 0 to 100 percent, oldest week at the right. A
/// week in which the child had not started a domain leaves a gap in its line. The latest value of each line is
/// written under the chart.
class GrowthLines extends StatelessWidget {
  const GrowthLines({super.key, required this.weeks, required this.domains});

  /// One map per week, oldest first: domain to understanding (0 to 1), null when not started yet.
  final List<Map<String, double?>> weeks;
  final List<String> domains;

  /// The latest known value of a domain, in percent, or null.
  static int? latest(List<Map<String, double?>> weeks, String domain) {
    for (int i = weeks.length - 1; i >= 0; i--) {
      final double? v = weeks[i][domain];
      if (v != null) return (v * 100).round();
    }
    return null;
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: <Widget>[
      Semantics(
        container: true,
        label: <String>[
          for (final String d in domains) '${domainLook(d).name}: ${latest(weeks, d)?.toString() ?? '-'}',
        ].join(', '),
        child: ExcludeSemantics(
          child: SizedBox(
            height: 160,
            width: double.infinity,
            child: CustomPaint(painter: _LinesPainter(weeks, domains)),
          ),
        ),
      ),
      const SizedBox(height: 8),
      Wrap(
        spacing: 16,
        runSpacing: 4,
        children: <Widget>[
          for (final String d in domains)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(color: domainLook(d).color, shape: BoxShape.circle),
                ),
                const SizedBox(width: 6),
                Text(
                  '${domainLook(d).name} ${latest(weeks, d) == null ? '-' : '${latest(weeks, d)}%'}',
                  style: AppText.parent(TokenType.parentSmall),
                ),
              ],
            ),
        ],
      ),
    ],
  );
}

class _LinesPainter extends CustomPainter {
  _LinesPainter(this.weeks, this.domains);

  final List<Map<String, double?>> weeks;
  final List<String> domains;

  @override
  void paint(Canvas canvas, Size size) {
    const double pad = 12;
    final double w = size.width - 2 * pad;
    final double h = size.height - 2 * pad;
    final Paint rule = Paint()
      ..color = TokenColors.hairline
      ..strokeWidth = 1;
    for (final double f in <double>[0, 0.5, 1]) {
      final double y = pad + h * (1 - f);
      canvas.drawLine(Offset(pad, y), Offset(size.width - pad, y), rule);
    }
    for (final String d in domains) {
      final Paint line = Paint()
        ..color = domainLook(d).color
        ..strokeWidth = 3
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;
      Path? run;
      for (int i = 0; i < weeks.length; i++) {
        final double? v = weeks[i][d];
        // The oldest week is at the right edge.
        final double x = pad + w * (weeks.length == 1 ? 0.5 : 1 - i / (weeks.length - 1));
        if (v == null) {
          if (run != null) canvas.drawPath(run, line);
          run = null;
          continue;
        }
        final Offset p = Offset(x, pad + h * (1 - v));
        canvas.drawCircle(p, 4, Paint()..color = domainLook(d).color);
        if (run == null) {
          run = Path()..moveTo(p.dx, p.dy);
        } else {
          run.lineTo(p.dx, p.dy);
        }
      }
      if (run != null) canvas.drawPath(run, line);
    }
  }

  @override
  bool shouldRepaint(_LinesPainter old) => old.weeks != weeks || old.domains != domains;
}
