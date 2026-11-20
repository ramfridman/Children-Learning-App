// The floors of docs/design/m11/min-sizes.md (section 2, checklist 5, addenda 8.x) applied to what `min_sizes_measure.dart` read off a screen.
// A rule gives one finding per screen: the worst value and how many pieces were under the floor. Nothing is exempt but what the design says
// is not that kind of picture: the scene backdrop (BoxFit.cover), the companion, the hint hand, the bubble's own text (its caption has its own rule).
import 'dart:math' as math;

import 'package:flutter/painting.dart';
import 'package:nitznutz/design/stage_spec.dart';

import 'min_sizes_measure.dart';

/// One rule: its id, the severity of the design (S1 content too small to see, count or touch; S2 under a floor but usable, or text and
/// numerals under their rule; S3 wasted room), the design finding it belongs to, and what it measures.
class RuleInfo {
  const RuleInfo(this.sev, this.design, this.what);
  final String sev;
  final String design;
  final String what;
}

const Map<String, RuleInfo> rules = <String, RuleInfo>{
  'TILE_H': RuleInfo(
    'S1',
    'R4, A1/A2/B11',
    'answer tile height under the look\'s tile (96/88/80 phone, 112/104/96 tablet)',
  ),
  'TILE_HIT': RuleInfo(
    'S1',
    'R4, 6.1',
    'touch area of a tile or control under the look\'s minimum control (64 for P1/P2, 56 for P3/P4)',
  ),
  'DRAG': RuleInfo('S1', 'R4', 'draggable under the minimum control'),
  'PIC_ID': RuleInfo('S1', 'R1', 'picture to identify, ink under 40'),
  'PIC_DETAIL': RuleInfo(
    'S1',
    'R2',
    'detail in a composite (set, strip, balance pan, chart), ink under 24 (32 on tablets for pans, charts, sets on tiles)',
  ),
  'COUNT_OBJ': RuleInfo('S1', 'R3, A9', 'counted object touched one by one: drawn ink under 40'),
  'COUNT_TOUCH': RuleInfo('S1', 'R3, A9', 'counted object touch square under the minimum control'),
  'BIN_ITEM': RuleInfo('S1', 'R5, A2, 3.4', 'item box shown in a bin under 48 (44 SE, 64 tablet)'),
  'BIN_STRIP': RuleInfo(
    'S1',
    'R5, A1',
    'pattern card in a bin or in the tray under 68 high (100 on tablets)',
  ),
  'BIN_SAMPLE': RuleInfo('S1', 'R1, 5.2', 'bin sample picture box under 40 (56 on tablets)'),
  'BIN_INK': RuleInfo(
    'S1',
    'R1/R5, V10',
    'drawn ink of a bin sample or of an item shown in a bin under 40 (the box is not what the child sees)',
  ),
  'LABEL_SIZE': RuleInfo('S2', 'R6, A2', 'Hebrew label under 18 (20 on tablets)'),
  'LABEL_WEIGHT': RuleInfo('S2', 'R6', 'Hebrew label heavier than w500 under 24'),
  'LABEL_LINE': RuleInfo('S2', '9.4', 'pointed text with line height under 1.7'),
  'LATIN_SIZE': RuleInfo('S2', 'R6', 'Latin or Cyrillic text of the child under 18 (20 on tablets)'),
  'NUMERAL': RuleInfo('S2', 'R7, B1, V13', 'numeral the child reads under 20 (24 on tablets)'),
  'NUMLINE_LABEL': RuleInfo('S2', 'B1', 'number-line label under 20 (28 on tablets)'),
  'CAPTION': RuleInfo(
    'S2',
    'R8, V2',
    'bubble caption under the look\'s caption minus 2 (no look: 22 phone, 20 SE, 28 tablet)',
  ),
  'ICON': RuleInfo(
    'S2',
    'R9',
    'glyph on a control tile (keypad, undo, clock, balance) under 32 (40 on tablets)',
  ),
  'ICON_PROGRAM': RuleInfo('S2', 'R9, B2', 'arrow in the robot program strip under 28 (40 on tablets)'),
  'CLOCK_FACE': RuleInfo('S1', 'A3', 'clock face under 174 across (240 on tablets)'),
  'NUMLINE_TICKS': RuleInfo('S2', 'B1', 'number-line labels closer than 24 (32 on tablets) per unit'),
  'ROBOT_STRIP': RuleInfo('S2', 'B2', 'robot program strip under 44 high (56 on tablets)'),
  'COIN': RuleInfo('S2', 'B3', 'coin in the purse under 48 across (64 on tablets)'),
  'PRICE': RuleInfo('S2', 'B3', 'price numeral under 24 (32 on tablets)'),
  'TRACE_PAD': RuleInfo('S2', 'A10', 'trace pad under 220 high (360 on tablets)'),
  'GIVE_TRAY': RuleInfo('S2', 'B6', 'picture in the give tray under 32 (48 on tablets)'),
  'CHROME': RuleInfo(
    'S1',
    '6.1',
    'a control of the frame (lamp, replay, home, mic) under the minimum control',
  ),
  'STAGE_CARD': RuleInfo(
    'S3',
    'C1/C2, S2/S3',
    'tablet stage card narrower than 848 (landscape) or lower than 520 (portrait; 420 with two rows of tiles)',
  ),
  'EMPTY_BAND': RuleInfo('S3', 'C3, S4', 'empty band under the last content taller than 25% of the board'),
  'HAND_BUBBLE': RuleInfo(
    'S2',
    'V4',
    'the hint hand lies over the words of the bubble (the hand box, 150 square points or more of a paragraph)',
  ),
  'LAYOUT_ERROR': RuleInfo(
    'S1',
    '-',
    'the framework reported an error (an overflow) while the screen was laid out',
  ),
};

/// What a finding says.
class Finding {
  Finding(this.rule, this.value, this.threshold, this.count, this.detail);
  final String rule;

  /// The worst measured value (the smallest; for EMPTY_BAND, HAND_BUBBLE the largest).
  final double value;
  final double threshold;

  /// How many pieces of the screen were under the floor.
  final int count;
  final String detail;
}

/// What a screen is, for the rules.
class RuleCtx {
  const RuleCtx({
    this.template = '',
    this.hint = 0,
    this.show = false,
    this.language = false,
    this.numberLine,
  });
  final String template;

  /// The hint level shown (0: none).
  final int hint;
  final bool show;
  final bool language;

  /// The range (to - from) of a number line, when this is one.
  final num? numberLine;
}

const Set<String> _chrome = <String>{
  'lesson-hint',
  'lesson-replay',
  'activity-home',
  'lesson-mic',
  'lesson-show-me',
};
const Set<String> _companion = <String>{
  'activity-nitzi',
  'lesson-cameo',
  'lesson-celebration',
  'hint-hand',
  'room-pair',
  'bubble-body',
  'lesson-bubble',
  'lesson-speaker-bubble',
};
const Set<String> _controls = <String>{
  'clock-prev',
  'clock-next',
  'clock-ok',
  'robot-undo',
  'arrow-left',
  'arrow-right',
  'arrow-up',
  'arrow-down',
  'balance-plus',
  'balance-minus',
  'picker-add',
  'give-done',
  'pay',
  'say-done',
  'drum-done',
  'do-done',
  'box-done',
  'change-done',
  'robot-go',
  'confirm-yes',
  'confirm-again',
};

bool _isControl(List<String> keys) => keys.any((String k) => _controls.contains(k) || k.startsWith('key-'));

double _minControl(Screen s) {
  final StageSpec? l = s.look;
  if (l == null) return 56;
  return l.stage.index <= 1 ? 64 : 56;
}

/// Judges [s]. The findings are in a fixed order (by rule, then worst first), so a run prints the same lines every time.
List<Finding> judge(Screen s, RuleCtx c) {
  final List<Finding> out = <Finding>[];
  final bool tablet = s.tablet;
  final double minControl = _minControl(s);

  void low(String rule, Iterable<(double, String)> measured, double floor, {double tol = 0.5}) {
    final List<(double, String)> bad = <(double, String)>[
      for (final (double, String) m in measured)
        if (m.$1 < floor - tol) m,
    ];
    if (bad.isEmpty) return;
    bad.sort(((double, String) a, (double, String) b) => a.$1.compareTo(b.$1));
    out.add(Finding(rule, bad.first.$1, floor, bad.length, bad.first.$2));
  }

  String r1(Rect r) =>
      '${r.width.toStringAsFixed(0)}x${r.height.toStringAsFixed(0)}@${r.left.toStringAsFixed(0)},${r.top.toStringAsFixed(0)}';

  // --- answer tiles ---
  final double lookTile = s.look?.tile(s.sizeClass) ?? 96;
  low('TILE_H', <(double, String)>[
    for (final TilePiece t in s.tiles)
      if (!_isControl(t.keys)) (t.rect.height, 'tile ${r1(t.rect)}'),
  ], lookTile);
  low('TILE_HIT', <(double, String)>[
    for (final TilePiece t in s.tiles)
      (math.min(t.hit.width, t.hit.height), 'hit ${r1(t.hit)}${_isControl(t.keys) ? ' (control)' : ''}'),
  ], minControl);
  low('DRAG', <(double, String)>[
    for (final DragPiece d in s.drags)
      (
        math.min(d.rect.width, d.rect.height),
        'drag ${r1(d.rect)} ${d.keys.where((String k) => k.startsWith('item') || k.startsWith('piece') || k.startsWith('coin')).join(',')}',
      ),
  ], minControl);
  low('CHROME', <(double, String)>[
    for (final String k in _chrome)
      for (final Rect r in s.keyed[k] ?? const <Rect>[])
        if (k != 'lesson-replay') (math.min(r.width, r.height), '$k ${r1(r)}'),
  ], minControl);

  // --- pictures ---
  final List<PicturePiece> pics = <PicturePiece>[
    for (final PicturePiece p in s.pictures)
      if (p.fit != BoxFit.cover && !p.underAny(_companion)) p,
  ];
  // pictures per answer tile
  final Map<TilePiece, List<PicturePiece>> inTile = <TilePiece, List<PicturePiece>>{};
  final Set<PicturePiece> tiled = <PicturePiece>{};
  for (final TilePiece t in s.tiles) {
    for (final PicturePiece p in pics) {
      if (t.rect.inflate(1).contains(p.rect.center) && p.rect.width <= t.rect.width + 2) {
        inTile.putIfAbsent(t, () => <PicturePiece>[]).add(p);
        tiled.add(p);
      }
    }
  }
  final Map<String, int> bySvg = <String, int>{};
  for (final PicturePiece p in pics) {
    if (!tiled.contains(p)) bySvg[p.svg] = (bySvg[p.svg] ?? 0) + 1;
  }
  final double detailFloor = 24;
  final double detailTablet = tablet ? 32 : 24;
  final List<(double, String)> id = <(double, String)>[];
  final List<(double, String)> detail = <(double, String)>[];
  final List<(double, String)> countObj = <(double, String)>[];
  final List<(double, String)> countTouch = <(double, String)>[];
  final List<(double, String)> binItem = <(double, String)>[];
  final List<(double, String)> binStrip = <(double, String)>[];
  final List<(double, String)> sample = <(double, String)>[];
  final List<(double, String)> binInk = <(double, String)>[];
  final List<(double, String)> give = <(double, String)>[];
  final List<(double, String)> tabletDetail = <(double, String)>[];
  for (final PicturePiece p in pics) {
    final String what = 'picture ${p.toString().replaceFirst('picture ', '')}';
    final bool inBinCard = p.keys.any((String k) => k.startsWith('bin-card-'));
    final bool inTrayCard = p.keys.any((String k) => k.startsWith('tray-card-'));
    final String? obj = p.keys.cast<String?>().firstWhere(
      (String? k) => RegExp(r'^[a-z]+-\d+$').hasMatch(k!) && !k.startsWith('piece') && !k.startsWith('hint'),
      orElse: () => null,
    );
    if (p.under('count-stage') && obj != null) {
      countObj.add((p.ink, '$what $obj'));
      final Rect cell = s.keyed[obj]?.first ?? p.rect;
      countTouch.add((math.min(cell.width, cell.height), 'cell ${r1(cell)} $obj'));
    } else if (p.under('bin-sample')) {
      sample.add((math.min(p.rect.width, p.rect.height), what));
      binInk.add((p.ink, 'sample $what'));
    } else if (p.strip) {
      if (inBinCard || p.keys.any((String k) => k.startsWith('bin-'))) {
        binStrip.add((p.rect.height, 'bin card $what'));
      } else if (inTrayCard) {
        binStrip.add((p.rect.height, 'tray card $what'));
      }
      detail.add((p.detail, 'strip animal in $what'));
    } else if (p.keys.any(
          (String k) => k.startsWith('bin-') && k != 'bin-sample' && !k.startsWith('bin-label'),
        ) &&
        !p.under('bin-sample')) {
      binItem.add((math.min(p.rect.width, p.rect.height), what));
      binInk.add((p.ink, 'item $what'));
    } else if (p.under('give-tray')) {
      give.add((p.ink, what));
    } else if (tiled.contains(p)) {
      final TilePiece t = inTile.entries
          .firstWhere((MapEntry<TilePiece, List<PicturePiece>> e) => e.value.contains(p))
          .key;
      if (inTile[t]!.length > 1) {
        detail.add((p.detail, 'set on a tile $what'));
        if (tablet) tabletDetail.add((p.detail, 'set on a tile $what'));
      } else {
        id.add((p.ink, 'on a tile $what'));
      }
    } else if ((bySvg[p.svg] ?? 0) >= 2) {
      detail.add((p.detail, 'counted/composite $what'));
      if (tablet &&
          p.keys.any(
            (String k) => k == 'scale-stage' || k == 'stage-chart' || k == 'tap-chart' || k == 'tap-groups',
          )) {
        tabletDetail.add((p.detail, 'counted/composite $what'));
      }
    } else {
      id.add((p.ink, what));
    }
  }
  low('PIC_ID', id, 40, tol: 1);
  // one finding: the piece furthest under its own floor (24; 32 on a tablet for pans, charts and sets on tiles)
  final Set<String> bigFloor = <String>{for (final (double, String) d in tabletDetail) d.$2};
  (double, String, double)? worstDetail;
  int detailCount = 0;
  for (final (double, String) d in detail) {
    final double fl = bigFloor.contains(d.$2) ? detailTablet : detailFloor;
    if (d.$1 >= fl - 1) continue;
    detailCount++;
    if (worstDetail == null || d.$1 / fl < worstDetail.$1 / worstDetail.$3) worstDetail = (d.$1, d.$2, fl);
  }
  if (worstDetail != null) {
    out.add(Finding('PIC_DETAIL', worstDetail.$1, worstDetail.$3, detailCount, worstDetail.$2));
  }
  low('COUNT_OBJ', countObj, 40, tol: 1);
  low('COUNT_TOUCH', countTouch, minControl, tol: 0.5);
  low('BIN_ITEM', binItem, tablet ? 64 : (s.sizeClass.name == 'phoneSE' ? 44 : 48), tol: 1);
  low('BIN_STRIP', binStrip, tablet ? 100 : 68, tol: 1);
  low('BIN_SAMPLE', sample, tablet ? 56 : 40, tol: 1);
  low('BIN_INK', binInk, 40, tol: 1);
  low('GIVE_TRAY', give, tablet ? 48 : 32, tol: 1);

  // --- text ---
  final double labelFloor = tablet ? 20 : 18;
  final double numFloor = tablet ? 24 : 20;
  final List<TextPiece> texts = <TextPiece>[
    for (final TextPiece t in s.texts)
      if (!t.underAny(_companion)) t,
  ];
  low('LABEL_SIZE', <(double, String)>[
    for (final TextPiece t in texts)
      if (t.kind == TextKind.nikud || t.kind == TextKind.hebrew)
        (t.drawn, '"${t.text}" ${t.keys.where((String k) => !k.startsWith('lesson')).take(2).join('/')}'),
  ], labelFloor);
  final List<(double, String)> heavy = <(double, String)>[
    for (final TextPiece t in texts)
      if ((t.kind == TextKind.nikud || t.kind == TextKind.hebrew) && t.drawn < 24 && t.weight > 500)
        (t.weight.toDouble(), '"${t.text}" w${t.weight} ${t.drawn.toStringAsFixed(1)}pt'),
  ];
  if (heavy.isNotEmpty) {
    heavy.sort(((double, String) a, (double, String) b) => b.$1.compareTo(a.$1));
    out.add(Finding('LABEL_WEIGHT', heavy.first.$1, 500, heavy.length, heavy.first.$2));
  }
  final List<(double, String)> tight = <(double, String)>[
    for (final TextPiece t in texts)
      if (t.kind == TextKind.nikud && (t.height ?? 1.7) < 1.7 - 1e-9)
        (t.height ?? 0, '"${t.text}" h${t.height}'),
  ];
  low('LABEL_LINE', tight, 1.7, tol: 0.001);
  low('LATIN_SIZE', <(double, String)>[
    for (final TextPiece t in texts)
      if (t.kind == TextKind.latin)
        (t.drawn, '"${t.text}" ${t.keys.where((String k) => !k.startsWith('lesson')).take(2).join('/')}'),
  ], labelFloor);
  final bool nl = c.numberLine != null;
  low('NUMERAL', <(double, String)>[
    for (final TextPiece t in texts)
      if (t.kind == TextKind.numeral && !(nl && t.under('line-stage')) && !t.under('price'))
        (t.drawn, '"${t.text}" ${t.keys.where((String k) => !k.startsWith('lesson')).take(2).join('/')}'),
  ], numFloor);
  low('NUMLINE_LABEL', <(double, String)>[
    for (final TextPiece t in texts)
      if (t.kind == TextKind.numeral && t.under('line-stage')) (t.drawn, '"${t.text}"'),
  ], tablet ? 28 : 20);
  low('PRICE', <(double, String)>[
    for (final TextPiece t in texts)
      if (t.under('price')) (t.drawn, '"${t.text}"'),
  ], tablet ? 32 : 24);

  // the bubble's caption
  final StageSpec? look = s.look;
  final double capFloor = look != null
      ? look.captionFloor(s.sizeClass)
      : (tablet ? 28 : (s.sizeClass.name == 'phoneSE' ? 20 : 22));
  low('CAPTION', <(double, String)>[
    for (final TextPiece t in s.texts)
      if (t.under('bubble-body') && !t.under('bubble-math') && t.kind != TextKind.numeral)
        (t.drawn, '"${t.text}"'),
  ], capFloor);

  // --- icons ---
  low('ICON_PROGRAM', <(double, String)>[
    for (final IconPiece i in s.icons)
      if (i.under('robot-program')) (i.drawn, 'program arrow ${r1(i.rect)}'),
  ], tablet ? 40 : 28);
  low('ICON', <(double, String)>[
    for (final IconPiece i in s.icons)
      if (i.under('answer-tile') && !i.under('robot-program'))
        (
          i.drawn,
          'icon on a tile ${i.keys.where((String k) => k != 'answer-tile').take(1).join()} ${i.drawn.toStringAsFixed(1)}',
        ),
  ], tablet ? 40 : 32);

  // --- template keys ---
  final Rect? face = s.rectOf('clock-face');
  if (face != null) {
    low('CLOCK_FACE', <(double, String)>[
      (math.min(face.width, face.height), 'face ${r1(face)}'),
    ], tablet ? 240 : 174);
  }
  final Rect? strip = s.rectOf('robot-program');
  if (strip != null) {
    low('ROBOT_STRIP', <(double, String)>[(strip.height, 'strip ${r1(strip)}')], tablet ? 56 : 44);
  }
  low(
    'COIN',
    <(double, String)>[
      for (final PicturePiece p in pics)
        if (p.keys.any((String k) => k.startsWith('coin-')) && p.under('purse'))
          (p.rect.width, 'coin ${r1(p.rect)}'),
    ],
    tablet ? 64 : 48,
    tol: 0.5,
  );
  final Rect? pad = s.rectOf('trace-stage');
  if (pad != null) low('TRACE_PAD', <(double, String)>[(pad.height, 'pad ${r1(pad)}')], tablet ? 360 : 220);
  if (c.numberLine != null && c.numberLine! > 0 && c.numberLine! <= 20) {
    final List<TextPiece> labels = <TextPiece>[
      for (final TextPiece t in texts)
        if (t.kind == TextKind.numeral && t.under('line-stage') && int.tryParse(t.text.trim()) != null) t,
    ]..sort((TextPiece a, TextPiece b) => a.rect.center.dx.compareTo(b.rect.center.dx));
    if (labels.length >= 2) {
      double? best;
      for (int i = 1; i < labels.length; i++) {
        final int dv = (int.parse(labels[i].text.trim()) - int.parse(labels[i - 1].text.trim())).abs();
        if (dv == 0) continue;
        final double sp = (labels[i].rect.center.dx - labels[i - 1].rect.center.dx).abs() / dv;
        best = best == null ? sp : math.min(best, sp);
      }
      if (best != null) {
        low(
          'NUMLINE_TICKS',
          <(double, String)>[(best, 'unit spacing ${best.toStringAsFixed(1)}')],
          tablet ? 32 : 24,
          tol: 0.5,
        );
      }
    }
  }

  // --- the hint hand over the words of the bubble (V4); the hand's box is the proxy, 150 square points or more of a paragraph ---
  double worstHand = 0;
  String handWhere = '';
  for (final Rect h in s.hands) {
    for (final TextPiece t in s.texts) {
      if (!t.under('bubble-body')) continue;
      final Rect x = h.intersect(t.rect);
      if (x.width > 0 && x.height > 0 && x.width * x.height > worstHand) {
        worstHand = x.width * x.height;
        handWhere = 'hand ${r1(h)} over "${t.text}" ${r1(t.rect)}';
      }
    }
  }
  if (worstHand > 150) out.add(Finding('HAND_BUBBLE', worstHand, 150, 1, handWhere));

  // --- room ---
  final Rect? stage = s.rectOf('lesson-stage');
  if (tablet && stage != null) {
    final bool portrait = s.board.height > s.board.width;
    // `lesson-stage` is the inside of the card (the card has a 16 point rim all round)
    final Rect card = stage.inflate(16);
    final Set<int> rows = <int>{for (final TilePiece t in s.tiles) (t.rect.top / 20).round()};
    if (portrait) {
      final double want = rows.length >= 2 ? 420 : 520;
      if (card.height < want - 1) out.add(Finding('STAGE_CARD', card.height, want, 1, 'card ${r1(card)}'));
    } else if (card.width < 848 - 1) {
      out.add(Finding('STAGE_CARD', card.width, 848, 1, 'card ${r1(card)}'));
    }
  }
  double bottom = stage == null ? 0 : (tablet ? stage.inflate(16).bottom : stage.bottom);
  for (final TilePiece t in s.tiles) {
    bottom = math.max(bottom, t.rect.bottom);
  }
  for (final DragPiece d in s.drags) {
    bottom = math.max(bottom, d.rect.bottom);
  }
  for (final PicturePiece p in pics) {
    bottom = math.max(bottom, p.rect.bottom);
  }
  for (final TextPiece t in texts) {
    bottom = math.max(bottom, t.rect.bottom);
  }
  final double empty = s.board.height - bottom;
  final double limit = 0.25 * s.board.height;
  if (empty > limit + 1) {
    out.add(
      Finding(
        'EMPTY_BAND',
        empty,
        limit,
        1,
        'content ends at ${bottom.toStringAsFixed(0)} of ${s.board.height.toStringAsFixed(0)}',
      ),
    );
  }

  out.sort((Finding a, Finding b) => a.rule.compareTo(b.rule));
  return out;
}
