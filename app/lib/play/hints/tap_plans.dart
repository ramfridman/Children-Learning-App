import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../content/hint_ladder.dart';
import '../../content/models.dart';
import '../../design/app_text.dart';
import '../count_tap_session.dart' show Dots;
import '../hint_hand.dart';
import '../hint_widgets.dart';
import 'hint_marks.dart';
import 'hint_pictures.dart' show hintScale;
import 'tap_geometry.dart';

// What each family of `tap_answer` draws at each hint level (B-40 part 2; the plan is docs/curriculum/b40-visual-hint-ladder.md
// section 5.1, the pictures are docs/design/b40-visual-hints.md section 5). Each level is a [HintPlan]: steps shown one after the
// other, on the stage, over the group, the row or the numeral of the question.
//
//   level 1, look here:      a sky glow on the parts of the question (or, where the stage has none, each option in turn);
//   level 2, another way:    a new picture (a hand, a path, a swatch, an outline, pair lines, brackets, numbered slots);
//   level 3, watch me:       the sky hand does the whole thing, and the answer is the last step.
//
// Level 1 and level 2 never mark the right option. What a plan needs (a colour, a shape, the number given) it reads from the
// activity as it is: the sprite names and counts of its options and groups, and for a number sequence the word "after" or
// "before" of its question. A plan that cannot find what it needs falls back to the generic one, so a hint is never empty.

/// The plan of [a] at [level] (1 to 3), or null when the activity's family has no pictures yet.
HintPlan? tapHintPlan(TapAnswerActivity a, TapGeometry g, int level) {
  final TapFamily? family = tapFamilyOf(a.skillId, numeralOnStage: a.stageNumeral != null);
  if (family == null || !HintLadder.tapFamiliesBuilt.contains(family)) return null;
  final _Plans p = _Plans(a, g);
  final int l = level.clamp(1, 3);
  return switch (family) {
    TapFamily.colour => p.colour(l),
    TapFamily.shapes => p.shapes(l),
    TapFamily.compare => p.compare(l),
    TapFamily.count => p.count(l),
    TapFamily.sequence => p.sequence(l),
    TapFamily.pattern => p.pattern(l),
    TapFamily.time => p.time(l),
    TapFamily.same => p.same(l),
    TapFamily.add => p.add(l),
    TapFamily.numerals => p.numerals(l),
    TapFamily.measure => p.measure(l),
  };
}

/// The colour a sprite name ends in (`ball_red`, `shape_circle_yellow`), or null.
String? colourOfSprite(String? ref) {
  if (ref == null) return null;
  final String last = ref.split('_').last;
  return hintColours.containsKey(last) ? last : null;
}

/// The words of a number question that say which way the sequence goes, written as code points (every Hebrew string of the app
/// lives in `strings/he.dart`; these two are read, never shown): "before" and "after".
final String _before = String.fromCharCodes(<int>[0x5DC, 0x5E4, 0x5E0, 0x5D9]);
final String _after = String.fromCharCodes(<int>[0x5D0, 0x5D7, 0x5E8, 0x5D9]);

/// The Hebrew text of a prompt without its vowel marks, to look for one word.
String _plain(String s) => s.replaceAll(_vowelMarks, '');

final RegExp _vowelMarks = RegExp('[${String.fromCharCode(0x591)}-${String.fromCharCode(0x5C7)}]');

/// The smallest unit that repeats through the known cells of [row], or null when none does (the unit is at most half the row).
int? periodOf(List<String> row) {
  for (int p = 1; p <= row.length ~/ 2; p++) {
    bool fits = true;
    for (int i = 0; i < row.length && fits; i++) {
      for (int j = i + p; j < row.length; j += p) {
        if (row[i] != '?' && row[j] != '?' && row[i] != row[j]) {
          fits = false;
          break;
        }
      }
    }
    if (fits) return p;
  }
  return null;
}

class _Plans {
  _Plans(this.a, this.g) : k = hintScale(g.size);

  final TapAnswerActivity a;
  final TapGeometry g;
  final double k;

  // ---- small helpers ----

  static Duration _ms(int ms) => Duration(milliseconds: ms);

  int get _n => a.options.length;
  int get _ci => g.correctIndex;
  ChoiceOption get _right => a.options[_ci];

  String? _svg(String? ref) => ref == null ? null : a.assets.svgOrNull(ref);

  /// The picture of an option (a sprite, or the sprite of its set).
  String? _spriteOf(ChoiceOption o) => o.sprite ?? o.set?.sprite;

  /// A plan that ends with the answer: its last step hands the turn back, and the answer gets its halo.
  HintPlan _demo(List<HintFrame> frames) => HintPlan(frames, endsDemo: true);

  /// The last step of a demonstration: the hand on the right tile (or the right picture on the stage), with [base] still shown.
  HintFrame _toAnswer(List<HintMark> base, {double reserve = 0}) => HintFrame(
    <HintMark>[...base, HandMark(g.optionTip(_ci), press: true)],
    hold: _ms(1300),
    reserve: reserve,
  );

  /// The hand goes along the options (tiles) one after the other and ends on the right one: the demonstration of a question
  /// that has nothing else to do.
  HintPlan _walkOptions({List<HintMark> base = const <HintMark>[], int? to, double reserve = 0}) {
    final int last = to ?? _n - 1;
    return _demo(<HintFrame>[
      for (int i = 0; i <= last; i++)
        HintFrame(
          <HintMark>[...base, HandMark(g.optionTip(i), press: true)],
          hold: _ms(i == last && last == _ci ? 1300 : 850),
          reserve: reserve,
        ),
      if (last != _ci) _toAnswer(base, reserve: reserve),
    ]);
  }

  /// Level 1 of a question with a group, a row or a numeral on the stage: the parts of the question stand out. With nothing on the
  /// stage, the options are lit one after the other (each the same, none staying lit).
  HintPlan look() {
    final List<Rect> holes = _questionParts();
    if (holes.isEmpty) return tilesInTurn();
    return HintPlan(<HintFrame>[
      HintFrame(<HintMark>[VeilMark(holes)], hold: _ms(2400)),
    ]);
  }

  HintPlan tilesInTurn() =>
      HintPlan(<HintFrame>[for (int i = 0; i < _n; i++) HintFrame(const <HintMark>[], litOption: i)]);

  List<Rect> _questionParts() => <Rect>[
    if (a.group != null) ...(_groupRects(g, 0).isEmpty ? <Rect>[g.groupCell(0)] : _groupRects(g, 0)),
    if (a.group2 != null) ..._groupRects(g, 1),
    if (a.row.isNotEmpty) ...g.rowCells(),
    if (a.stageNumeral != null) g.stageNumeral,
  ];

  List<Rect> _groupRects(TapGeometry geo, int which) => geo.inReadingOrder(geo.groupObjects(which));

  /// The card for a second picture at the stage's end side, and the part of the stage it takes.
  Rect get _card => g.endCard;
  double get _reserve => g.endCard.right + 6;

  /// Level 1 of a count: the things are lit one after the other, left to right, a dot staying on each; nothing is said or counted.
  List<HintFrame> _lightEach(
    List<Rect> rs, {
    bool round = true,
    List<HintMark> base = const <HintMark>[],
    double reserve = 0,
  }) => <HintFrame>[
    for (int i = 0; i < rs.length; i++)
      HintFrame(
        <HintMark>[...base, for (int j = 0; j < i; j++) SeenMark(rs[j]), RingMark(rs[i], round: round)],
        hold: _ms(950),
        reserve: reserve,
      ),
  ];

  // ---- a sample the child compares the options with (TA-6 colour, TA-7 shapes, TA-9 same) ----

  /// Level 2 shows the sample (a swatch, an outline, a copy of the model) in a sky card; level 3 glides it over each option in
  /// turn, and it stops on the one that matches. [make] draws the sample in a given box.
  HintPlan _sample(int level, HintMark Function(Rect box) make) {
    if (level == 1) return look();
    final bool beside = _questionParts().isNotEmpty;
    final Rect card = beside ? _card : g.centre(110 * k, 100 * k);
    final double side = math.min(66 * k, card.width - 16 * k);
    final Rect home = Rect.fromCenter(center: card.center, width: side, height: side);
    final double reserve = beside ? _reserve : 0;
    final List<HintMark> shown = <HintMark>[CardMark(card, const SizedBox.shrink()), make(home)];
    if (level == 2) {
      return HintPlan(
        <HintFrame>[HintFrame(shown, hold: _ms(2600), reserve: reserve)],
        rest: shown,
        restReserve: reserve,
      );
    }
    Rect above(int i) =>
        Rect.fromCenter(center: g.optionTip(i) - Offset(26 * k, 22 * k), width: 38 * k, height: 38 * k);
    return _demo(<HintFrame>[
      HintFrame(<HintMark>[make(home)], hold: _ms(700), reserve: reserve),
      for (int i = 0; i < _n; i++) HintFrame(<HintMark>[make(above(i))], hold: _ms(800), reserve: reserve),
      HintFrame(
        <HintMark>[make(above(_ci)), HandMark(g.optionTip(_ci), press: true)],
        hold: _ms(1300),
        reserve: reserve,
      ),
    ]);
  }

  /// A plan nothing in the activity can feed: look, a question mark card, and the hand along the options.
  HintPlan generic(int level) => switch (level) {
    1 => look(),
    2 => HintPlan(<HintFrame>[HintFrame(_questionCard, hold: _ms(2400))], rest: _questionCard),
    _ => _walkOptions(),
  };

  List<HintMark> get _questionCard => <HintMark>[
    CardMark(g.centre(80 * k, 80 * k), Text('?', style: AppText.fixed(size: 40, weight: 800, lineHeight: 1))),
  ];

  // ---- TA-6 colour ----

  HintPlan colour(int level) {
    final String? c = colourOfSprite(_spriteOf(_right)) ?? colourOfSprite(a.group?.sprite);
    if (c == null) return generic(level);
    return _sample(level, (Rect box) => SwatchMark(box, c));
  }

  // ---- TA-7 shapes ----

  HintPlan shapes(int level) {
    if (level == 1) return look();
    switch (a.skillId) {
      case 'SHP-A-07':
        return _rolls(level);
      case 'SHP-A-08':
        return _position(level);
      default:
        final GhostKind? kind = _shapeKind();
        if (kind == null) return generic(level);
        return _sample(level, (Rect box) => GhostMark(box, kind, turn: a.skillId == 'SHP-A-03'));
    }
  }

  /// The shape the question asks for, read from the right option (`shape_circle_red`, a plate, `line_curved`).
  GhostKind? _shapeKind() {
    final String name = (_spriteOf(_right) ?? '').replaceFirst('asset:', '');
    if (a.skillId == 'SHP-A-10') {
      if (name.contains('curved') || name.contains('circle')) return GhostKind.curved;
      return GhostKind.straight;
    }
    if (name.contains('circle') || name == 'plate') return GhostKind.circle;
    if (name.contains('square')) return GhostKind.square;
    if (name.contains('rect') || name == 'window') return GhostKind.rect;
    if (name.contains('triangle') || name == 'sign') return GhostKind.triangle;
    return null;
  }

  /// SHP-A-07: the ball rolls away and the box stays where it is (the question's own two things, no new ones).
  HintPlan _rolls(int level) {
    final ChoiceOption? ball = _first((String s) => s.contains('sphere') || s.contains('ball'));
    final ChoiceOption? box = _first((String s) => s.contains('box'));
    final String? ballSvg = _svg(ball?.sprite);
    final String? boxSvg = _svg(box?.sprite);
    if (ballSvg == null || boxSvg == null) return generic(level);
    final double side = 46 * k;
    final Rect ballAt = Rect.fromCenter(center: Offset(g.w * 0.22, g.h / 2), width: side, height: side);
    final Rect ballFar = Rect.fromCenter(center: Offset(g.w * 0.52, g.h / 2), width: side, height: side);
    final Rect boxAt = Rect.fromCenter(center: Offset(g.w * 0.8, g.h / 2), width: side, height: side);
    List<HintMark> scene(Rect b, {double turns = 0, bool trail = false}) => <HintMark>[
      CopyMark(boxAt, boxSvg),
      CopyMark(b, ballSvg, turns: turns),
      if (trail)
        LineMark(
          Offset(ballAt.center.dx, ballAt.bottom + 6 * k),
          Offset(ballFar.center.dx, ballFar.bottom + 6 * k),
        ),
    ];
    if (level == 2) {
      final List<HintMark> end = scene(ballFar, turns: 0.5, trail: true);
      return HintPlan(<HintFrame>[
        HintFrame(scene(ballAt), hold: _ms(900)),
        HintFrame(end, hold: _ms(2000)),
      ], rest: end);
    }
    return _walkOptions();
  }

  ChoiceOption? _first(bool Function(String sprite) test) {
    for (final ChoiceOption o in a.options) {
      if (o.sprite != null && test(o.sprite!)) return o;
    }
    return null;
  }

  /// SHP-A-08: the position of the question's word acted out with a box and a ball, in a sky card.
  HintPlan _position(int level) {
    final String where = (_right.sprite ?? '').replaceFirst('asset:pos_', '');
    final String? boxSvg = _svg('asset:solid_box');
    final String? ballSvg = _svg('asset:ball_red') ?? _svg('asset:solid_sphere');
    if (boxSvg == null ||
        ballSvg == null ||
        !<String>{'above', 'on', 'next', 'under', 'in'}.contains(where)) {
      return generic(level);
    }
    if (level == 3) return _walkOptions();
    final Rect card = g.centre(150 * k, 112 * k);
    final double b = 44 * k;
    final double d = 24 * k;
    final Offset c = card.center;
    final (Rect, Rect) place = switch (where) {
      'above' => (
        Rect.fromCenter(center: c + Offset(0, 24 * k), width: b, height: b),
        Rect.fromCenter(center: c + Offset(0, -40 * k), width: d, height: d),
      ),
      'on' => (
        Rect.fromCenter(center: c + Offset(0, 18 * k), width: b, height: b),
        Rect.fromCenter(center: c + Offset(0, -16 * k), width: d, height: d),
      ),
      'next' => (
        Rect.fromCenter(center: c + Offset(-26 * k, 10 * k), width: b, height: b),
        Rect.fromCenter(center: c + Offset(30 * k, 22 * k), width: d, height: d),
      ),
      'under' => (
        Rect.fromCenter(center: c + Offset(0, -22 * k), width: b, height: b),
        Rect.fromCenter(center: c + Offset(0, 36 * k), width: d, height: d),
      ),
      _ => (
        Rect.fromCenter(center: c + Offset(0, 8 * k), width: b * 1.3, height: b * 1.3),
        Rect.fromCenter(center: c + Offset(0, 14 * k), width: d * 0.8, height: d * 0.8),
      ),
    };
    final List<HintMark> scene = <HintMark>[
      CardMark(card, const SizedBox.shrink()),
      CopyMark(place.$1, boxSvg),
      CopyMark(place.$2, ballSvg),
    ];
    return HintPlan(<HintFrame>[HintFrame(scene, hold: _ms(2600))], rest: scene);
  }

  // ---- TA-4 compare ----

  /// The two groups to compare: the sets of the two options (drawn on the tiles) or the two groups of the stage.
  HintPlan compare(int level) {
    final bool onStage = a.group != null && a.group2 != null;
    final List<(String, int)> sets = <(String, int)>[
      if (!onStage)
        for (final ChoiceOption o in a.options)
          if (o.set != null && _svg(o.set!.sprite) != null) (_svg(o.set!.sprite)!, o.set!.count),
    ];
    if (!onStage && sets.length != 2) return generic(level);

    List<Rect> top;
    List<Rect> bottom;
    List<HintMark> copies = <HintMark>[];
    if (onStage) {
      top = _groupRects(g, 0);
      bottom = _groupRects(g, 1);
      // The groups already stand side by side: the pairs are drawn between them.
    } else {
      // Equal size and equal spacing in two rows from the start line: the size and the crowding of the tiles are gone (P8).
      final int most = math.max(sets[0].$2, sets[1].$2);
      final double d = math.min(math.min(36 * k, (g.w - 70 * k) / math.max(most, 1)), g.h * 0.32);
      final double step = d * 1.25;
      List<Rect> row(int count, double y) => <Rect>[
        for (int i = 0; i < count; i++)
          Rect.fromCenter(center: Offset(40 * k + i * step, y), width: d, height: d),
      ];
      top = row(sets[0].$2, g.h * 0.3);
      bottom = row(sets[1].$2, g.h * 0.72);
      copies = <HintMark>[
        for (final Rect r in top) CopyMark(r, sets[0].$1),
        for (final Rect r in bottom) CopyMark(r, sets[1].$1),
        LineMark(Offset(24 * k, 6 * k), Offset(24 * k, g.h - 6 * k)),
      ];
    }
    final int pairs = math.min(top.length, bottom.length);
    final List<Rect> left = top.length > bottom.length ? top.sublist(pairs) : <Rect>[];
    final List<Rect> leftB = bottom.length > top.length ? bottom.sublist(pairs) : <Rect>[];
    final List<Rect> leftover = <Rect>[...left, ...leftB];
    List<(Offset, Offset)> lines(int upTo) => <(Offset, Offset)>[
      for (int i = 0; i < upTo; i++) (top[i].center, bottom[i].center),
    ];
    if (level == 1) {
      if (onStage) return look();
      return HintPlan(<HintFrame>[HintFrame(copies, hold: _ms(2600))], rest: copies);
    }
    if (level == 2) {
      final List<HintFrame> frames = <HintFrame>[
        for (int i = 1; i <= pairs; i++)
          HintFrame(<HintMark>[...copies, PairsMark(lines: lines(i))], hold: _ms(550)),
        HintFrame(<HintMark>[...copies, PairsMark(lines: lines(pairs), unpaired: leftover)], hold: _ms(1800)),
      ];
      return HintPlan(
        frames,
        rest: <HintMark>[
          ...copies,
          PairsMark(lines: lines(pairs), unpaired: leftover),
        ],
      );
    }
    return _demo(<HintFrame>[
      HintFrame(copies, hold: _ms(600)),
      for (int i = 1; i <= pairs; i++)
        HintFrame(<HintMark>[
          ...copies,
          PairsMark(lines: lines(i)),
          HandMark((top[i - 1].center + bottom[i - 1].center) / 2, press: true),
        ], hold: _ms(700)),
      for (int j = 1; j <= leftover.length; j++)
        HintFrame(<HintMark>[
          ...copies,
          PairsMark(lines: lines(pairs), unpaired: leftover),
          for (int q = 1; q <= j; q++) BadgeMark(leftover[q - 1].topRight, q),
          HandMark(leftover[j - 1].center, press: true),
        ], hold: _ms(800)),
      _toAnswer(<HintMark>[...copies, PairsMark(lines: lines(pairs), unpaired: leftover)]),
    ]);
  }

  // ---- TA-1 count a group ----

  HintPlan count(int level) {
    if (a.row.isNotEmpty) return _steps(level);
    if (a.group == null) return generic(level);
    if (_right.numeral == 0) return _zero(level);
    final TapGeometry g2 = g.withReserve(_reserve);
    final List<Rect> objs = _groupRects(level == 1 ? g : g2, 0);
    final int n = objs.length;
    if (n == 0) return generic(level);
    if (level == 1) {
      return HintPlan(_lightEach(objs), rest: <HintMark>[for (final Rect r in objs) SeenMark(r)]);
    }
    Widget hands(int raised) => raised <= 5
        ? HintHand(fingers: raised, side: HandSide.left, height: 84)
        : CountingHands(raised: raised);
    final Offset fingerTop = Offset(_card.center.dx, _card.top + 20 * k);
    if (level == 2) {
      final List<HintFrame> frames = <HintFrame>[
        HintFrame(<HintMark>[CardMark(_card, hands(0))], hold: _ms(500), reserve: _reserve),
        for (int i = 0; i < n; i++)
          HintFrame(
            <HintMark>[
              CardMark(_card, hands(i + 1)),
              for (int j = 0; j < i; j++) SeenMark(objs[j]),
              RingMark(objs[i]),
              LineMark(objs[i].center, fingerTop),
            ],
            hold: _ms(950),
            reserve: _reserve,
          ),
      ];
      return HintPlan(
        frames,
        rest: <HintMark>[CardMark(_card, hands(n)), for (final Rect r in objs) SeenMark(r)],
        restReserve: _reserve,
      );
    }
    List<HintMark> badges(int upTo) => <HintMark>[
      for (int j = 0; j < upTo; j++) BadgeMark(objs[j].topRight, j + 1),
    ];
    final List<HintMark> counted = <HintMark>[...badges(n), BadgeMark(_card.center, n, big: true)];
    return _demo(<HintFrame>[
      HintFrame(const <HintMark>[], hold: _ms(500), reserve: _reserve),
      for (int i = 0; i < n; i++)
        HintFrame(
          <HintMark>[...badges(i + 1), HandMark(objs[i].center, press: true)],
          hold: _ms(850),
          reserve: _reserve,
        ),
      HintFrame(<HintMark>[...counted, HandMark(objs[n - 1].center)], hold: _ms(900), reserve: _reserve),
      _toAnswer(counted, reserve: _reserve),
    ]);
  }

  /// Zero (NUM-A-14): nothing is there, so the hand runs over an empty ten-frame and finds nothing to count.
  HintPlan _zero(int level) {
    if (level == 1) {
      final List<Rect> objs = _groupRects(g, 0);
      return HintPlan(<HintFrame>[
        HintFrame(<HintMark>[
          VeilMark(objs.isEmpty ? <Rect>[g.groupCell(0)] : objs),
        ], hold: _ms(2400)),
      ]);
    }
    final Rect card = g.centre(170 * k, 92 * k);
    final List<HintMark> frame = <HintMark>[CardMark(card, const TenFrames(total: 10, filled: 0))];
    if (level == 2) return HintPlan(<HintFrame>[HintFrame(frame, hold: _ms(2600))], rest: frame);
    final List<Offset> cells = <Offset>[
      card.center + Offset(-44 * k, -10 * k),
      card.center + Offset(44 * k, -10 * k),
      card.center + Offset(-44 * k, 14 * k),
      card.center + Offset(44 * k, 14 * k),
    ];
    return _demo(<HintFrame>[
      for (final Offset c in cells) HintFrame(<HintMark>[...frame, HandMark(c, press: true)], hold: _ms(700)),
      _toAnswer(<HintMark>[...frame, BadgeMark(card.center + Offset(0, -2 * k), 0, big: true)]),
    ]);
  }

  /// CS-A-04: the steps from the robot to the flag are the hops between the squares of the row.
  HintPlan _steps(int level) {
    final List<Rect> cells = g.rowCells();
    final int hops = cells.length - 1;
    Offset top(int i) => Offset(cells[i].center.dx, cells[i].top + 4 * k);
    if (level == 1) {
      return HintPlan(<HintFrame>[
        HintFrame(<HintMark>[
          VeilMark(<Rect>[cells.first, cells.last]),
        ], hold: _ms(2400)),
      ]);
    }
    List<HintMark> arcs(int upTo) => <HintMark>[for (int i = 0; i < upTo; i++) ArcMark(top(i), top(i + 1))];
    if (level == 2) {
      return HintPlan(<HintFrame>[
        for (int i = 1; i <= hops; i++) HintFrame(arcs(i), hold: _ms(800)),
      ], rest: arcs(hops));
    }
    return _demo(<HintFrame>[
      for (int i = 1; i <= hops; i++)
        HintFrame(<HintMark>[
          ...arcs(i),
          for (int j = 1; j <= i; j++) BadgeMark(top(j) + Offset(0, -10 * k), j),
          HandMark(top(i), press: true),
        ], hold: _ms(800)),
      _toAnswer(<HintMark>[
        ...arcs(hops),
        for (int j = 1; j <= hops; j++) BadgeMark(top(j) + Offset(0, -10 * k), j),
      ]),
    ]);
  }

  // ---- TA-3 sequence ----

  HintPlan sequence(int level) {
    if (a.skillId == 'NUM-A-13') return _ordinal(level);
    final int? c = _right.numeral;
    final String q = _plain(a.promptLine.caption);
    final bool before = q.contains(_before);
    final bool after = q.contains(_after);
    if (c == null || (!before && !after)) return generic(level);
    final int given = before ? c + 1 : c - 1;
    final int m = given <= 5 && c <= 5 && a.options.every((ChoiceOption o) => (o.numeral ?? 0) <= 5) ? 5 : 10;
    final Rect path = Rect.fromCenter(
      center: Offset(g.w / 2, g.h / 2 + 6 * k),
      width: math.min(g.w - 20, m * 30 * k),
      height: 36 * k,
    );
    Offset squareTop(int j) => Offset(path.left + (j - 0.5) * path.width / m, path.top + 2 * k);
    if (level == 1) {
      // The number we are given and an empty place next to it, left to right: the gap is where to look (the question, no answer).
      final double s = 52 * k;
      final Rect givenAt = Rect.fromCenter(
        center: Offset(g.w / 2 + (before ? 34 : -34) * k, g.h / 2),
        width: s,
        height: s,
      );
      final Rect gapAt = Rect.fromCenter(
        center: Offset(g.w / 2 + (before ? -34 : 34) * k, g.h / 2),
        width: s,
        height: s,
      );
      return HintPlan(<HintFrame>[
        HintFrame(<HintMark>[
          VeilMark(<Rect>[givenAt, gapAt]),
          CardMark(givenAt, Text('$given', style: AppText.fixed(size: 30, weight: 800, lineHeight: 1))),
          GhostMark(gapAt, GhostKind.square),
        ], hold: _ms(2600)),
      ]);
    }
    PathMark strip({int? marker, int? gap, int? ring}) =>
        PathMark(rect: path, count: m, gap: gap, ring: ring, marker: marker);
    if (level == 2) {
      final List<HintMark> shown = <HintMark>[strip(gap: c, ring: given)];
      return HintPlan(<HintFrame>[HintFrame(shown, hold: _ms(2800))], rest: shown);
    }
    return _demo(<HintFrame>[
      for (int j = 1; j <= c; j++)
        HintFrame(<HintMark>[strip(gap: c, marker: j), HandMark(squareTop(j), press: true)], hold: _ms(620)),
      _toAnswer(<HintMark>[strip(marker: c)]),
    ]);
  }

  /// NUM-A-13: first, second, third, last. The tiles are the line, and the row of tiles starts at the right, so the numbered
  /// strip starts at the right too (the one place a strip of the stage is turned, to run the way the tiles run).
  HintPlan _ordinal(int level) {
    if (level == 1) return tilesInTurn();
    final Rect path = Rect.fromCenter(
      center: Offset(g.w / 2, g.h / 2),
      width: math.min(g.w - 20, _n * 44 * k),
      height: 40 * k,
    );
    if (level == 2) {
      final List<HintMark> shown = <HintMark>[PathMark(rect: path, count: _n, ring: _ci + 1, reverse: true)];
      return HintPlan(<HintFrame>[HintFrame(shown, hold: _ms(2800))], rest: shown);
    }
    Offset squareTop(int j) => Offset(path.right - (j - 0.5) * path.width / _n, path.top + 2 * k);
    return _demo(<HintFrame>[
      for (int j = 1; j <= _ci + 1; j++)
        HintFrame(<HintMark>[
          PathMark(rect: path, count: _n, marker: j, reverse: true),
          HandMark(squareTop(j), press: true),
        ], hold: _ms(800)),
      _toAnswer(<HintMark>[PathMark(rect: path, count: _n, ring: _ci + 1, reverse: true)]),
    ]);
  }

  // ---- TA-8 pattern rows, TA-10 order in time ----

  HintPlan pattern(int level) {
    if (a.row.isEmpty) return generic(level);
    final List<Rect> cells = g.rowCells();
    final int gap = a.row.indexOf('?');
    final List<HintMark> seen = <HintMark>[
      for (int i = 0; i < cells.length; i++)
        if (i != gap) SeenMark(cells[i]),
    ];
    if (level == 1) return HintPlan(_lightEach(cells, round: false), rest: seen);
    final bool yesNo = a.options.every(
      (ChoiceOption o) => o.sprite == 'asset:tick' || o.sprite == 'asset:cross',
    );
    final int? p = periodOf(a.row);
    final double y = cells.first.bottom + 8 * k;
    List<HintMark> brackets(int upTo) {
      final int size = p ?? (yesNo ? cells.length ~/ 2 : 0);
      if (size == 0) return <HintMark>[];
      final List<HintMark> out = <HintMark>[];
      for (int b = 0; b < upTo; b++) {
        final int from = b * size;
        final int to = math.min(cells.length, from + size) - 1;
        if (from > to) break;
        out.add(BracketMark(Offset(cells[from].left + 2 * k, y), Offset(cells[to].right - 2 * k, y)));
      }
      return out;
    }

    final int blocks = p == null && !yesNo ? 0 : (cells.length / (p ?? cells.length ~/ 2)).ceil();
    if (level == 2) {
      if (blocks == 0) {
        // A row that grows (seriation): one floor under every cell, and the neighbours are linked.
        final List<HintMark> floor = <HintMark>[
          LineMark(Offset(cells.first.left, y), Offset(cells.last.right, y)),
          for (int i = 0; i + 1 < cells.length; i++)
            ArcMark(
              Offset(cells[i].center.dx, cells[i].top),
              Offset(cells[i + 1].center.dx, cells[i + 1].top),
            ),
        ];
        return HintPlan(<HintFrame>[HintFrame(floor, hold: _ms(2800))], rest: floor);
      }
      return HintPlan(<HintFrame>[
        for (int b = 1; b <= blocks; b++) HintFrame(brackets(b), hold: _ms(900)),
      ], rest: brackets(blocks));
    }
    return _rowDemo(cells, gap);
  }

  /// The hand reads the row from the left, and where there is a gap the right picture appears in it last.
  HintPlan _rowDemo(List<Rect> cells, int gap, {List<HintMark> base = const <HintMark>[]}) {
    final String? answerSvg = gap >= 0 ? _svg(_spriteOf(_right)) : null;
    final List<HintMark> filled = <HintMark>[
      ...base,
      if (answerSvg != null) CopyMark(cells[gap].deflate(3 * k), answerSvg),
    ];
    return _demo(<HintFrame>[
      for (int i = 0; i < cells.length; i++)
        HintFrame(<HintMark>[...base, HandMark(cells[i].center, press: true)], hold: _ms(620)),
      HintFrame(<HintMark>[...filled, if (gap >= 0) HandMark(cells[gap].center)], hold: _ms(900)),
      _toAnswer(filled),
    ]);
  }

  HintPlan time(int level) {
    if (a.row.isNotEmpty) {
      final List<Rect> cells = g.rowCells();
      final int gap = a.row.indexOf('?');
      if (level == 1) {
        return HintPlan(<HintFrame>[
          HintFrame(<HintMark>[
            VeilMark(<Rect>[cells.first]),
          ], hold: _ms(2400)),
        ]);
      }
      final List<HintMark> numbers = <HintMark>[
        for (int i = 0; i < cells.length; i++)
          BadgeMark(Offset(cells[i].center.dx, cells[i].bottom + 12 * k), i + 1),
      ];
      if (level == 2) {
        return HintPlan(<HintFrame>[
          for (int i = 1; i <= cells.length; i++) HintFrame(numbers.sublist(0, i), hold: _ms(800)),
        ], rest: numbers);
      }
      return _rowDemo(cells, gap, base: numbers);
    }
    if (level == 1) return tilesInTurn();
    // The steps of the story are numbered places in a row, left to right.
    final Rect slots = Rect.fromCenter(
      center: Offset(g.w / 2, g.h / 2),
      width: math.min(g.w - 20, _n * 56 * k),
      height: 52 * k,
    );
    final List<HintMark> shown = <HintMark>[PathMark(rect: slots, count: _n)];
    if (level == 2) return HintPlan(<HintFrame>[HintFrame(shown, hold: _ms(2800))], rest: shown);
    Offset slotTop(int j) => Offset(slots.left + (j - 0.5) * slots.width / _n, slots.top + 2 * k);
    return _demo(<HintFrame>[
      for (int j = 1; j <= _n; j++)
        HintFrame(<HintMark>[
          PathMark(rect: slots, count: _n, marker: j),
          HandMark(slotTop(j), press: true),
        ], hold: _ms(800)),
      _toAnswer(shown),
    ]);
  }

  // ---- TA-9 same, odd one out ----

  HintPlan same(int level) {
    if (a.row.isNotEmpty) return _oddOne(level);
    final String? model = _svg(a.group?.sprite);
    if (model == null) return generic(level);
    return _sample(level, (Rect box) => CopyMark(box, model));
  }

  /// LOG-A-02: four in a row, one is different. Level 2 links each to the next, level 3 walks along and stops on the odd one.
  HintPlan _oddOne(int level) {
    final List<Rect> cells = g.rowCells();
    if (level == 1) {
      return HintPlan(<HintFrame>[
        HintFrame(<HintMark>[VeilMark(cells)], hold: _ms(2400)),
      ]);
    }
    List<HintMark> links(int upTo) => <HintMark>[
      for (int i = 0; i < upTo; i++)
        ArcMark(Offset(cells[i].center.dx, cells[i].top), Offset(cells[i + 1].center.dx, cells[i + 1].top)),
    ];
    if (level == 2) {
      return HintPlan(<HintFrame>[
        for (int i = 1; i < cells.length; i++) HintFrame(links(i), hold: _ms(800)),
      ], rest: links(cells.length - 1));
    }
    // The odd one is the cell whose picture is not the commonest.
    final Map<String, int> seen = <String, int>{};
    for (final String r in a.row) {
      seen[r] = (seen[r] ?? 0) + 1;
    }
    final int odd = a.row.indexWhere((String r) => seen[r] == 1);
    final int stop = odd < 0 ? cells.length - 1 : odd;
    return _demo(<HintFrame>[
      for (int i = 0; i <= stop; i++)
        HintFrame(<HintMark>[HandMark(cells[i].center, press: true)], hold: _ms(700)),
      HintFrame(<HintMark>[
        RingMark(cells[stop], round: false),
        HandMark(cells[stop].center),
      ], hold: _ms(900)),
      _toAnswer(<HintMark>[RingMark(cells[stop], round: false)]),
    ]);
  }

  // ---- TA-5 add, take away ----

  HintPlan add(int level) {
    if (a.group == null) return generic(level);
    final TapGeometry g2 = g.withReserve(_reserve);
    final List<Rect> first = _groupRects(level == 1 ? g : g2, 0);
    final List<Rect> second = a.group2 != null ? _groupRects(level == 1 ? g : g2, 1) : <Rect>[];
    final bool adds = a.group2 != null;
    final int total = _right.numeral ?? first.length;
    final int start = first.length;
    if (level == 1) {
      return HintPlan(<HintFrame>[
        HintFrame(<HintMark>[VeilMark(first)], hold: _ms(1500)),
        if (adds) HintFrame(<HintMark>[VeilMark(second)], hold: _ms(1500)),
      ]);
    }
    Widget hands(int raised) => raised <= 5
        ? HintHand(fingers: math.max(0, raised), side: HandSide.left, height: 84)
        : CountingHands(raised: raised);
    if (adds) {
      // Count on: the hand shows the first group, and the second group is counted one by one on top of it.
      final int more = second.length;
      List<HintMark> done(int j) => <HintMark>[
        for (final Rect r in first) SeenMark(r),
        for (int i = 0; i < j; i++) SeenMark(second[i]),
      ];
      if (level == 2) {
        final List<HintFrame> frames = <HintFrame>[
          HintFrame(<HintMark>[CardMark(_card, hands(start)), ...done(0)], hold: _ms(900), reserve: _reserve),
          for (int j = 0; j < more; j++)
            HintFrame(
              <HintMark>[CardMark(_card, hands(start)), ...done(j), RingMark(second[j])],
              hold: _ms(900),
              reserve: _reserve,
            ),
        ];
        return HintPlan(
          frames,
          rest: <HintMark>[CardMark(_card, hands(start)), ...done(more)],
          restReserve: _reserve,
        );
      }
      return _demo(<HintFrame>[
        HintFrame(<HintMark>[CardMark(_card, hands(start)), ...done(0)], hold: _ms(800), reserve: _reserve),
        for (int j = 1; j <= more; j++)
          HintFrame(
            <HintMark>[
              CardMark(_card, hands(start + j)),
              ...done(j),
              BadgeMark(second[j - 1].topRight, start + j),
              HandMark(second[j - 1].center, press: true),
            ],
            hold: _ms(900),
            reserve: _reserve,
          ),
        _toAnswer(<HintMark>[
          CardMark(_card, hands(total)),
          ...done(more),
          BadgeMark(_card.center, total, big: true),
        ], reserve: _reserve),
      ]);
    }
    // Take away: the hand shows the group, and the things taken away fold a finger each.
    final int taken = math.max(0, first.length - total);
    final List<Rect> gone = first.length >= taken ? first.sublist(first.length - taken) : <Rect>[];
    if (level == 2) {
      final List<HintFrame> frames = <HintFrame>[
        HintFrame(<HintMark>[CardMark(_card, hands(start))], hold: _ms(900), reserve: _reserve),
        for (int j = 0; j < gone.length; j++)
          HintFrame(
            <HintMark>[CardMark(_card, hands(start)), RingMark(gone[gone.length - 1 - j])],
            hold: _ms(900),
            reserve: _reserve,
          ),
      ];
      return HintPlan(frames, rest: <HintMark>[CardMark(_card, hands(start))], restReserve: _reserve);
    }
    return _demo(<HintFrame>[
      HintFrame(<HintMark>[CardMark(_card, hands(start))], hold: _ms(800), reserve: _reserve),
      for (int j = 1; j <= gone.length; j++)
        HintFrame(
          <HintMark>[CardMark(_card, hands(start - j)), HandMark(gone[gone.length - j].center, press: true)],
          hold: _ms(900),
          reserve: _reserve,
        ),
      _toAnswer(<HintMark>[
        CardMark(_card, hands(total)),
        BadgeMark(_card.center, total, big: true),
      ], reserve: _reserve),
    ]);
  }

  // ---- TA-2 numerals ----

  HintPlan numerals(int level) {
    final int? n = a.stageNumeral ?? _right.numeral;
    if (n == null || n < 1) return generic(level);
    final Rect path = Rect.fromCenter(
      center: Offset(g.w / 2, g.h / 2 + 6 * k),
      width: math.min(g.w - 20, 5 * 40 * k),
      height: 40 * k,
    );
    Offset squareTop(int j) => Offset(path.left + (j - 0.5) * path.width / 5, path.top + 2 * k);
    final String? sprite = _svg(_spriteOf(_right));
    if (level == 1) {
      if (a.stageNumeral == null) return tilesInTurn();
      final Rect dots = Rect.fromCenter(
        center: Offset(g.w / 2 + g.h * 0.55 + 20 * k, g.h / 2),
        width: math.min(g.w * 0.25, (n * 12 + 16) * k),
        height: 30 * k,
      );
      return HintPlan(<HintFrame>[
        HintFrame(<HintMark>[
          VeilMark(<Rect>[g.stageNumeral, dots]),
          CardMark(dots, Dots(n)),
        ], hold: _ms(2600)),
      ]);
    }
    // Over the numeral of the stage (when there is one) a sky card holds the number path: 1 to 5, a marker walking to the number.
    final Rect cover = Rect.fromCenter(
      center: path.center.translate(0, -6 * k),
      width: path.width + 14 * k,
      height: g.h * 0.8,
    );
    List<HintMark> strip({int? marker}) => <HintMark>[
      if (a.stageNumeral != null) CardMark(cover, const SizedBox.shrink()),
      PathMark(rect: path, count: 5, ring: marker == n ? n : null, marker: marker),
    ];
    if (level == 2) {
      return HintPlan(<HintFrame>[
        for (int j = 1; j <= n; j++) HintFrame(strip(marker: j), hold: _ms(700)),
      ], rest: strip(marker: n));
    }
    if (a.stageNumeral == null || sprite == null) {
      return _demo(<HintFrame>[
        for (int j = 1; j <= n; j++)
          HintFrame(<HintMark>[...strip(marker: j), HandMark(squareTop(j), press: true)], hold: _ms(700)),
        _toAnswer(strip(marker: n)),
      ]);
    }
    // The quantity is built on the stage, one by one, and then the hand goes to the set that matches.
    final double d = math.min(38 * k, (g.w - 50) / n);
    Rect at(int i) =>
        Rect.fromCenter(center: Offset(g.w / 2 + (i - (n - 1) / 2) * d * 1.2, g.h / 2), width: d, height: d);
    List<HintMark> built(int upTo) => <HintMark>[
      CardMark(g.centre(math.min(g.w - 20, (n * 1.2 + 0.6) * d), g.h * 0.8), const SizedBox.shrink()),
      for (int i = 0; i < upTo; i++) ...<HintMark>[CopyMark(at(i), sprite), BadgeMark(at(i).topRight, i + 1)],
    ];
    return _demo(<HintFrame>[
      for (int i = 1; i <= n; i++)
        HintFrame(<HintMark>[...built(i), HandMark(at(i - 1).center, press: true)], hold: _ms(800)),
      _toAnswer(built(n)),
    ]);
  }

  // ---- TA-11 measure ----

  HintPlan measure(int level) {
    final List<(String, double)> things = <(String, double)>[
      for (final ChoiceOption o in a.options)
        if (_svg(_spriteOf(o)) != null) (_svg(_spriteOf(o))!, o.set?.scale ?? 1),
    ];
    if (things.length != 2) return generic(level);
    final double most = things.map(((String, double) t) => t.$2).reduce(math.max);
    final double base = math.min(54 * k, g.h * 0.34) / math.max(1.0, most);
    final List<Rect> rows = <Rect>[
      for (int i = 0; i < 2; i++)
        Rect.fromCenter(
          center: Offset(46 * k + base * things[i].$2 / 2, g.h * (i == 0 ? 0.27 : 0.66)),
          width: base * things[i].$2,
          height: base * things[i].$2,
        ),
    ];
    final List<HintMark> aligned = <HintMark>[
      LineMark(Offset(30 * k, 6 * k), Offset(30 * k, g.h - 6 * k)),
      for (int i = 0; i < 2; i++) CopyMark(rows[i], things[i].$1),
    ];
    if (level == 1) return HintPlan(<HintFrame>[HintFrame(aligned, hold: _ms(2600))], rest: aligned);
    if (level == 2) {
      // A stick of cubes along each: the longer has more.
      final double cube = 11 * k;
      final List<HintMark> cubes = <HintMark>[
        for (final Rect r in rows)
          for (int c = 0; c < math.max(1, (r.width / cube).floor()); c++)
            BlockMark(Rect.fromLTWH(r.left + c * cube, r.bottom + 2 * k, cube - 1.5, cube - 1.5)),
      ];
      return HintPlan(
        <HintFrame>[
          HintFrame(<HintMark>[...aligned, ...cubes], hold: _ms(2800)),
        ],
        rest: <HintMark>[...aligned, ...cubes],
      );
    }
    return _walkOptions(base: aligned);
  }
}
