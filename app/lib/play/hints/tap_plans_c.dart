part of 'tap_plans.dart';

// Band C of `tap_answer` (M10, section 7.2): what each skill of the numbers to 100 and the facts draws at each hint level, in the same
// three steps as Bands A and B (look here, another way, watch me with the answer last). The pictures come from the plan's table:
//
//   facts (MATH-B-04, C-01, C-02, NUM-B-09)   cubes over the numbers of the sentence, or the count on of two groups
//   place value (NUM-C-02, C-03, MATH-C-03)   base-ten blocks of the number, in a card; a stage picture of blocks gets its digits
//   a numeral and its quantity (NUM-B-06)     the number as a ten-frame
//   counting on (NUM-C-01)                    a path of numbers around the one given; on a chart, the row that is counted along
//   compare (NUM-C-04)                        a tower of blocks for each number
//   the hundred chart (NUM-C-09)              the column that a ten-rod is laid down
//
// A number answer (the keypad) has the same plans: its last steps are the hand typing the number (see `_answerSteps`).

extension _BandC on _Plans {
  /// The plan of a Band C skill, or null when the skill is not one of these (the family's plan serves it).
  HintPlan? bandC(int level) => switch (a.skillId) {
    'MATH-B-04' || 'MATH-C-01' || 'MATH-C-02' || 'NUM-B-09' => _facts(level),
    'MATH-C-03' || 'NUM-C-02' || 'NUM-C-03' => _placeValue(level),
    'NUM-B-06' => _numeralDots(level),
    'NUM-C-01' => TapGeometry.stagePictureOf(a) == 'hundred_chart' ? _hundredChart(level) : sequence(level),
    'NUM-C-04' => _towers(level),
    'NUM-C-09' => _hundredChart(level),
    _ => null,
  };

  // ---- facts: the cubes of Band B, and count on from the first of two groups ----

  HintPlan _facts(int level) {
    if (a.group != null && a.group2 != null) return add(level);
    if (a.group != null && a.row.isEmpty) return _toTen(level);
    if (a.row.isNotEmpty) return _sentence(level);
    return generic(level);
  }

  // ---- the shared pieces of the blocks ----

  /// The card the blocks of a sentence or of a number in words stand in: the middle of the stage, as high as it lets it be.
  Rect get _blocksCard => g.centre(math.min(g.w - 16, 300 * k), g.h * 0.88);

  /// Level 1 of a sentence: the signs are lit, as in Band B.
  HintPlan _signsLit(_Sentence s) => HintPlan(<HintFrame>[
    HintFrame(<HintMark>[
      VeilMark(<Rect>[g.rowCells()[s.sign], g.rowCells()[s.equals]]),
    ], hold: _ms(2400)),
  ]);

  /// The marks of the blocks of [n] over the places of [cell], with only the first [filled] worth of them on show when it is given
  /// (the rest are empty places).
  List<HintMark> _blockUnits(Rect cell, int n, {int? filled}) => <HintMark>[
    BlocksMark(
      cell,
      BaseTen.of(n),
      shown: filled == null ? null : BaseTen.of(filled),
      places: filled != null,
    ),
  ];

  /// Where the blocks of [whole] that [known] does not have stand when they are drawn in [cell].
  List<Rect> _blockPlaces(Rect cell, int whole, int known) {
    final BaseTen w = BaseTen.of(whole);
    final BaseTen kn = BaseTen.of(known);
    final BaseTenLayout l = BaseTenLayout.forBox(w, cell.size);
    return <Rect>[
      for (final Rect r in <Rect>[
        ...l.thousands.skip(kn.thousands),
        ...l.hundreds.skip(kn.hundreds),
        ...l.tens.skip(kn.tens),
        ...l.ones.skip(kn.ones),
      ])
        r.shift(cell.topLeft),
    ];
  }

  /// The steps of counting the blocks of [n] laid out by [l] (in the box at [origin]): each flat is a hundred more, each rod ten, each
  /// cube one; when that is more than eight steps the cubes, and then the rods, are counted in one step each. Each step is the block
  /// the hand is on, the number counted so far and the blocks on show.
  List<(Rect, int, BaseTen)> _countSteps(BaseTenLayout l, Offset origin, BaseTen n) {
    List<(Rect, int, BaseTen)> build(bool eachCube, bool eachRod) {
      final List<(Rect, int, BaseTen)> out = <(Rect, int, BaseTen)>[];
      int total = 0;
      for (int i = 0; i < l.thousands.length; i++) {
        total += 1000;
        out.add((l.thousands[i].shift(origin), total, BaseTen(thousands: i + 1)));
      }
      for (int i = 0; i < l.hundreds.length; i++) {
        total += 100;
        out.add((l.hundreds[i].shift(origin), total, BaseTen(thousands: n.thousands, hundreds: i + 1)));
      }
      final int before = total;
      if (l.tens.isNotEmpty) {
        if (eachRod) {
          for (int i = 0; i < l.tens.length; i++) {
            total += 10;
            out.add((
              l.tens[i].shift(origin),
              total,
              BaseTen(thousands: n.thousands, hundreds: n.hundreds, tens: i + 1),
            ));
          }
        } else {
          total = before + n.tens * 10;
          out.add((
            l.tensBox!.shift(origin),
            total,
            BaseTen(thousands: n.thousands, hundreds: n.hundreds, tens: n.tens),
          ));
        }
      }
      if (l.ones.isNotEmpty) {
        if (eachCube) {
          for (int i = 0; i < l.ones.length; i++) {
            total += 1;
            out.add((
              l.ones[i].shift(origin),
              total,
              BaseTen(thousands: n.thousands, hundreds: n.hundreds, tens: n.tens, ones: i + 1),
            ));
          }
        } else {
          total += n.ones;
          out.add((l.onesBox!.shift(origin), total, n));
        }
      }
      return out;
    }

    List<(Rect, int, BaseTen)> steps = build(true, true);
    if (steps.length > 8) steps = build(false, true);
    if (steps.length > 8) steps = build(false, false);
    return steps;
  }

  /// How long each of [steps] counting steps is held: a quicker count when there is much to count, so that a demonstration is over in ten
  /// seconds.
  Duration _stepHold(int steps) => _ms((6000 / math.max(1, steps)).clamp(350, 800).round());

  // ---- place value (NUM-C-02, NUM-C-03, MATH-C-03) ----

  HintPlan _placeValue(int level) {
    if (g.blocks != null) return _pictureBlocks(level);
    if (a.group != null) return _money(level);
    final int? v = _answerValue;
    if (v == null || v > 9999) return generic(level);
    if (a.row.isNotEmpty) return _sentenceBlocks(level);
    return _cardBlocks(level, v);
  }

  /// A number said in words (or its tens and ones said): level 2 builds its blocks in a card, the tens and then the ones; level 3 counts
  /// them, a hundred, ten or one more for each block, and the number is the last thing said.
  HintPlan _cardBlocks(int level, int v) {
    if (level == 1) return look();
    final BaseTen n = BaseTen.of(v);
    final Rect card = _blocksCard;
    final Rect inner = card.deflate(8 * k);
    final BaseTenLayout l = BaseTenLayout.forBox(n, inner.size);
    List<HintMark> built(BaseTen shown, {bool places = false}) => <HintMark>[
      CardMark(card, const SizedBox.shrink()),
      BlocksMark(inner, n, shown: shown, places: places),
    ];
    if (level == 2) {
      final List<HintMark> all = built(n);
      return HintPlan(<HintFrame>[
        if (n.ones > 0 && n.value >= 10)
          HintFrame(
            built(BaseTen(thousands: n.thousands, hundreds: n.hundreds, tens: n.tens)),
            hold: _ms(1300),
          ),
        HintFrame(all, hold: _ms(1900)),
      ], rest: all);
    }
    final List<(Rect, int, BaseTen)> steps = _countSteps(l, inner.topLeft, n);
    final Duration hold = _stepHold(steps.length);
    final HintMark total = BadgeMark(card.topCenter + Offset(0, 12 * k), v);
    return _demo(<HintFrame>[
      HintFrame(built(const BaseTen(), places: true), hold: _ms(500)),
      for (final (Rect at, int counted, BaseTen shown) in steps)
        HintFrame(<HintMark>[
          ...built(shown, places: true),
          BadgeMark(at.topRight, counted),
          HandMark(at.center, press: true),
        ], hold: hold),
      ..._answerSteps(<HintMark>[...built(n), total]),
    ]);
  }

  /// A sentence of place value (`30 + 4 = ?`, `34 = ? + 4`, `40 + 30 = ?`): the blocks of each number stand in a card, left and right,
  /// and the missing part is counted in tens or in ones.
  HintPlan _sentenceBlocks(int level) {
    final _Sentence? s = _readSentence();
    if (s == null || s.value.values.any((int v) => v > 9999)) return generic(level);
    if (level == 1) return _signsLit(s);
    final int unknown = s.value[s.unknown]!;
    return _sentenceWith(
      level,
      s,
      _blockUnits,
      card: _blocksCard,
      emptyOf: _blockPlaces,
      perPlace: unknown >= 10 && unknown % 10 == 0 ? 10 : 1,
    );
  }

  /// A stage picture of blocks (how many cubes are here? which number was built?): level 1 lights the rods and the cubes, level 2 puts the
  /// digit of each kind under it, level 3 counts the blocks, ten for each rod, one for each cube.
  HintPlan _pictureBlocks(int level) {
    final BaseTenLayout l = g.blocks!;
    final Offset o = g.pictureArea.topLeft;
    final BaseTen n = BaseTen.fromScene(a.picture!);
    final int? v = _answerValue;
    if (level == 1) return look();
    if (level == 2) {
      // The digit of each kind under its blocks: what the rods count and what the cubes count, not the number they make.
      final List<HintMark> digits = <HintMark>[
        if (l.tensBox != null) BadgeMark(l.tensBox!.shift(o).bottomCenter + Offset(0, 4 * k), n.tens),
        if (l.onesBox != null) BadgeMark(l.onesBox!.shift(o).bottomCenter + Offset(0, 4 * k), n.ones),
      ];
      return HintPlan(<HintFrame>[HintFrame(digits, hold: _ms(2800))], rest: digits);
    }
    final List<(Rect, int, BaseTen)> steps = _countSteps(l, o, n);
    final Duration hold = _stepHold(steps.length);
    final Offset totalAt = g.pictureArea.topCenter + Offset(0, 10 * k);
    return _demo(<HintFrame>[
      for (final (Rect at, int counted, BaseTen _) in steps)
        HintFrame(<HintMark>[BadgeMark(at.topRight, counted), HandMark(at.center, press: true)], hold: hold),
      ..._answerSteps(<HintMark>[if (v != null) BadgeMark(totalAt, v)]),
    ]);
  }

  /// The worth of one coin of [sprite] in shekels (`coin_s10`: 10), or null for anything that is not a coin of shekels.
  int? _shekels(String sprite) {
    final RegExpMatch? m = RegExp(r'coin_s(\d+)$').firstMatch(sprite);
    return m == null ? null : int.parse(m[1]!);
  }

  /// Coins of tens and of ones on the stage (how many shekels are here?): level 1 lights each group, level 2 shows the blocks of the
  /// whole sum beside them, level 3 counts the coins, ten for each note, one for each coin.
  HintPlan _money(int level) {
    final List<SpriteSet> sets = <SpriteSet>[a.group!, ?a.group2];
    final List<int?> worth = <int?>[for (final SpriteSet s in sets) _shekels(s.sprite)];
    if (worth.any((int? w) => w == null)) return generic(level);
    final int sum = <int>[for (int i = 0; i < sets.length; i++) sets[i].count * worth[i]!]
        .fold(0, (int s, int x) => s + x);
    final int total = _answerValue ?? sum;
    if (level == 1) {
      return HintPlan(<HintFrame>[
        for (int i = 0; i < sets.length; i++)
          HintFrame(<HintMark>[VeilMark(_groupRects(g, i))], hold: _ms(1500)),
      ]);
    }
    final TapGeometry g2 = g.withReserve(_reserve);
    final Rect card = _card;
    final Rect inner = card.deflate(8 * k);
    final BaseTen n = BaseTen.of(total);
    List<HintMark> blocks(BaseTen shown) => <HintMark>[
      CardMark(card, const SizedBox.shrink()),
      BlocksMark(inner, n, shown: shown),
    ];
    if (level == 2) {
      final List<HintMark> all = blocks(n);
      return HintPlan(
        <HintFrame>[
          HintFrame(
            blocks(BaseTen(tens: n.tens)),
            hold: _ms(1300),
            reserve: _reserve,
          ),
          HintFrame(all, hold: _ms(1900), reserve: _reserve),
        ],
        rest: all,
        restReserve: _reserve,
      );
    }
    final List<(Rect, int)> coins = <(Rect, int)>[];
    int counted = 0;
    final int pieces = sets.fold(0, (int s, SpriteSet x) => s + x.count);
    for (int i = 0; i < sets.length; i++) {
      final List<Rect> rects = g2.inReadingOrder(g2.groupObjects(i));
      if (pieces <= 9) {
        for (final Rect r in rects) {
          counted += worth[i]!;
          coins.add((r, counted));
        }
      } else if (rects.isNotEmpty) {
        counted += sets[i].count * worth[i]!;
        coins.add((rects.first.expandToInclude(rects.last), counted));
      }
    }
    final Duration hold = _stepHold(coins.length);
    final HintMark whole = BadgeMark(card.center, total, big: true);
    return _demo(<HintFrame>[
      for (final (Rect at, int n) in coins)
        HintFrame(
          <HintMark>[BadgeMark(at.topRight, n), HandMark(at.center, press: true)],
          hold: hold,
          reserve: _reserve,
        ),
      ..._answerSteps(<HintMark>[whole], reserve: _reserve),
    ]);
  }

  // ---- NUM-B-06: a numeral and its quantity ----

  /// The number as a ten-frame (or two): level 1 lights the numeral on the stage, or each answer in turn; level 2 shows the frames filled;
  /// level 3 counts the counters and the number is the last thing said.
  HintPlan _numeralDots(int level) {
    final int? n = a.stageNumeral ?? _answerValue;
    if (n == null || n < 1 || n > 20) return generic(level);
    if (level == 1) return look();
    final bool beside = a.stageNumeral != null;
    final int frames = n > 10 ? 2 : 1;
    final double cell = 24 * k;
    final double frameW = 5 * cell + 9;
    final double frameH = 2 * cell + 9;
    final Rect card = beside ? _card : g.centre(math.min(g.w - 16, 300 * k), 84 * k);
    final double total = frames * frameW + (frames - 1) * 16;
    final Rect inner = card.deflate(6 * k + 3);
    final double f = math.min(1, math.min(inner.width / total, inner.height / frameH));
    final Offset origin = inner.center - Offset(total * f / 2, frameH * f / 2);
    Offset counter(int i) {
      final int j = i % 10;
      return origin +
          Offset(
            ((i ~/ 10) * (frameW + 16) + 4.5 + (j % 5) * cell + cell / 2) * f,
            (4.5 + (j ~/ 5) * cell + cell / 2) * f,
          );
    }

    List<HintMark> built(int filled) => <HintMark>[
      CardMark(card, TenFrames(total: n, filled: filled, cell: cell)),
    ];
    if (level == 2) return HintPlan(<HintFrame>[HintFrame(built(n), hold: _ms(2600))], rest: built(n));
    final Duration hold = _stepHold(n);
    final HintMark whole = BadgeMark(card.topCenter + Offset(0, 4 * k), n);
    return _demo(<HintFrame>[
      HintFrame(built(0), hold: _ms(500)),
      for (int i = 0; i < n; i++)
        HintFrame(<HintMark>[
          ...built(i + 1),
          BadgeMark(counter(i) + Offset(cell * f * 0.5, -cell * f * 0.7), i + 1),
          HandMark(counter(i), press: true),
        ], hold: hold),
      ..._answerSteps(<HintMark>[...built(n), whole]),
    ]);
  }

  // ---- NUM-C-04: which number is bigger, a tower of blocks for each ----

  /// A tower of blocks for each number, in the order of the tiles: the one with more rods is the bigger. Level 1 lights the numbers of
  /// the sentence (or each answer in turn); level 2 builds the towers one after the other; level 3 goes along them with the hand.
  HintPlan _towers(int level) {
    final List<int> values = <int>[for (final ChoiceOption o in a.options) o.numeral ?? -1];
    if (a.numberAnswer != null || values.isEmpty || values.any((int v) => v < 0 || v > 999)) {
      return generic(level);
    }
    if (level == 1) {
      if (a.row.isEmpty) return tilesInTurn();
      final List<Rect> cells = g.rowCells();
      return HintPlan(<HintFrame>[
        HintFrame(<HintMark>[
          VeilMark(<Rect>[
            for (int i = 0; i < a.row.length; i++)
              if (a.row[i].startsWith('n:')) cells[i],
          ]),
        ], hold: _ms(2400)),
      ]);
    }
    // The number the sentence gives stands first, then the answers in the order the tiles are in on the screen.
    final List<int> order = List<int>.generate(values.length, (int i) => i)
      ..sort((int p, int q) => g.optionTip(p).dx.compareTo(g.optionTip(q).dx));
    final int? given = a.row.isEmpty
        ? null
        : a.row
              .map((String c) => c.startsWith('n:') ? int.tryParse(c.substring(2)) : null)
              .whereType<int>()
              .firstOrNull;
    final List<int> towerValues = <int>[?given, for (final int i in order) values[i]];
    final Rect card = g.centre(g.w - 12 * k, g.h - 8 * k);
    final Rect inner = card.deflate(8 * k);
    final double slotW = inner.width / towerValues.length;
    // One unit for all the towers, so that a bigger number is a wider tower and nothing else: the least any of them is given.
    double unit = double.infinity;
    for (final int v in towerValues) {
      unit = math.min(unit, BaseTenLayout.forBox(BaseTen.of(v), Size(slotW - 6 * k, inner.height)).unit);
    }
    final List<Rect> boxes = <Rect>[
      for (final (int i, int v) in towerValues.indexed)
        () {
          final Size e = BaseTenLayout.extentOf(BaseTen.of(v));
          final double w = e.width * unit;
          final double h = e.height * unit;
          return Rect.fromLTWH(inner.left + slotW * i + (slotW - w) / 2, inner.bottom - h, w, h);
        }(),
    ];
    List<HintMark> towers(int upTo) => <HintMark>[
      CardMark(card, const SizedBox.shrink()),
      for (int i = 0; i < upTo; i++) BlocksMark(boxes[i], BaseTen.of(towerValues[i])),
    ];
    if (level == 2) {
      return HintPlan(<HintFrame>[
        for (int i = 1; i < towerValues.length; i++) HintFrame(towers(i), hold: _ms(900)),
        HintFrame(towers(towerValues.length), hold: _ms(1800)),
      ], rest: towers(towerValues.length));
    }
    final List<HintMark> all = towers(towerValues.length);
    return _demo(<HintFrame>[
      for (final Rect b in boxes)
        HintFrame(<HintMark>[...all, HandMark(b.topCenter + Offset(0, 4 * k), press: true)], hold: _ms(850)),
      ..._answerSteps(all),
    ]);
  }

  // ---- NUM-C-09: the hundred chart, a ten more is a row down ----

  /// The cells the chart is made of in the question, and where it is drawn: the chart of the stage, or one in a card for a question with
  /// a row (`34 + 10 = ?`, a column of numbers).
  ({ChartSpec spec, Rect box, int target, Rect Function(int n) cell})? _chartOf() {
    final int? target = _answerValue;
    if (target == null || target < 1 || target > 100) return null;
    final ChartLayout? own = g.chart;
    if (own != null) {
      final ChartSpec spec = own.spec;
      final int blank = spec.blank.isEmpty ? target : spec.blank.first;
      final Offset o = g.pictureArea.topLeft;
      return (
        spec: spec,
        box: g.pictureArea,
        target: blank,
        cell: (int n) => (own.cellOf(n) ?? own.box).shift(o),
      );
    }
    // A question with a row: the first number of `34 + 10` is lit, or all the numbers of a column.
    final bool sum = a.row.any((String c) => c.startsWith('op:'));
    final List<int> nums = <int>[
      for (final String c in a.row)
        if (c.startsWith('n:')) ?int.tryParse(c.substring(2)),
    ];
    if (nums.isEmpty) return null;
    final Set<int> lit = sum ? <int>{nums.first} : nums.toSet();
    final ChartSpec rows = ChartSpec.around(<int>{...lit, target}, const <int>{});
    final ChartSpec spec = ChartSpec(firstRow: rows.firstRow, lastRow: rows.lastRow, lit: lit);
    final Rect card = g.centre(math.min(g.w - 16, 300 * k), g.h * 0.9);
    final Rect inner = card.deflate(6 * k + 3);
    final ChartLayout l = ChartLayout.forBox(spec, inner.size);
    return (
      spec: spec,
      box: card,
      target: target,
      cell: (int n) => (l.cellOf(n) ?? l.box).shift(inner.topLeft),
    );
  }

  /// Level 1 lights the number the count starts from (the lit cells); level 2 lays a ten-rod down its column (the column is shaded; a
  /// count along a row, the row); level 3 moves the hand from the nearest lit cell to the empty one, and the number is the last thing.
  HintPlan _hundredChart(int level) {
    final ({ChartSpec spec, Rect box, int target, Rect Function(int n) cell})? c = _chartOf();
    if (c == null) return generic(level);
    final bool own = g.chart != null;
    if (level == 1) {
      if (own) return look();
      return HintPlan(<HintFrame>[
        HintFrame(<HintMark>[
          VeilMark(<Rect>[for (final int n in c.spec.lit) c.cell(n)]),
        ], hold: _ms(2400)),
      ]);
    }
    final Rect inner = own ? c.box : c.box.deflate(6 * k + 3);
    final ChartSpec shaded = c.spec.shaded(c.target);
    final List<HintMark> card = <HintMark>[if (!own) CardMark(c.box, const SizedBox.shrink())];
    final List<HintMark> shown = <HintMark>[...card, ChartMark(inner, shaded)];
    if (level == 2) return HintPlan(<HintFrame>[HintFrame(shown, hold: _ms(2800))], rest: shown);
    // From the lit cell nearest to the empty one: ten more is the cell under it, ten less the one above it, the next is the one that follows.
    final int from = c.spec.lit.reduce(
      (int p, int q) => (p - c.target).abs() <= (q - c.target).abs() ? p : q,
    );
    final Rect start = c.cell(from);
    final Rect end = c.cell(c.target);
    final bool column = (from - c.target) % 10 == 0;
    final List<HintMark> filled = <HintMark>[...card, ChartMark(inner, shaded.withLit(c.target))];
    return _demo(<HintFrame>[
      HintFrame(<HintMark>[...shown, HandMark(start.center, press: true)], hold: _ms(900)),
      HintFrame(<HintMark>[
        ...shown,
        ArcMark(start.center, end.center),
        if (column)
          BadgeMark(
            Offset((start.center.dx + end.center.dx) / 2 + 14 * k, (start.center.dy + end.center.dy) / 2),
            10,
          ),
        HandMark(end.center, press: true),
      ], hold: _ms(1000)),
      ..._answerSteps(filled),
    ]);
  }
}
