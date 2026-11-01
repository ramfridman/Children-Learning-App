part of 'tap_plans.dart';

// The second ways of showing a skill (B-36 part D, curriculum plan docs/curriculum/b36-second-representations.md): items whose
// stage or answers are drawn another way than the skill's first items, so the plans of their family read something else. A plate to
// pick out of a pile, a zero, a numeral written on a tile, a pile counted in twos, a chart of coins, the part that hides behind a
// stone. Each is the same three steps as everywhere (look here, another way, watch me with the answer last), built from the same
// marks; a plan that cannot find what it needs falls back to the generic one.

extension _SecondWay on _Plans {
  /// The fingers of a number: one hand up to five, two hands up to ten, the numeral above ten.
  Widget _fingers(int raised) => raised > 10
      ? Text('$raised', style: AppText.fixed(size: 44, weight: 800, lineHeight: 1))
      : (raised <= 5
            ? HintHand(fingers: raised, side: HandSide.left, height: 84)
            : CountingHands(raised: raised));

  // ---- NUM-A-06: a plate out of a pile ----

  /// "Here are seven fish, the cat asked for three, which plate is right?": the answer is a plate with the asked number, and the pile
  /// on the stage is more than that, so counting the pile would count the wrong number. Level 1 lights the plates in turn; level 2
  /// shows the asked number on fingers beside the pile; at level 3 the fingers go up one at a time with the count, and the hand picks
  /// the plate last.
  HintPlan _plate(int level) {
    final int n = _right.set!.count;
    if (n < 1 || n > 10) return generic(level);
    if (level == 1) return tilesInTurn();
    List<HintMark> asked(int raised) => <HintMark>[CardMark(_card, _fingers(raised))];
    if (level == 2) {
      return HintPlan(
        <HintFrame>[HintFrame(asked(n), hold: _ms(2600), reserve: _reserve)],
        rest: asked(n),
        restReserve: _reserve,
      );
    }
    return _demo(<HintFrame>[
      HintFrame(asked(0), hold: _ms(600), reserve: _reserve),
      for (int j = 1; j <= n; j++)
        HintFrame(
          <HintMark>[...asked(j), HandMark(_fingerIn(_card, j - 1, n), press: true)],
          hold: _ms(800),
          reserve: _reserve,
        ),
      _toAnswer(asked(n), reserve: _reserve),
    ]);
  }

  // ---- NUM-A-14: zero ----

  /// Zero on the stage: level 1 lights the numeral; levels 2 and 3 are the empty ten-frame of the zero plan.
  HintPlan _zeroOnStage(int level) {
    if (level > 1) return _zero(level);
    return HintPlan(<HintFrame>[
      HintFrame(<HintMark>[
        VeilMark(<Rect>[g.stageNumeral]),
      ], hold: _ms(2400)),
    ]);
  }

  // ---- NUM-B-07: a numeral written the right way ----

  /// "Where is the three written the right way?": the answers are drawn numerals (`glyph_3`, `glyph_3_rev`, `glyph_8`), so the
  /// number is in the picture's name. Level 2 shows the numeral on its own, in the app's type, in a card; at level 3 it glides over
  /// each tile and stops on the one that is written the same way. The right glyph itself is never the sample.
  HintPlan _writtenNumeral(int level) {
    final RegExpMatch? m = RegExp(r'glyph_(\d)').firstMatch(_spriteOf(_right) ?? '');
    if (m == null) return generic(level);
    final int n = int.parse(m[1]!);
    return _sample(level, (Rect box) => BadgeMark(box.center, n, big: true));
  }

  // ---- NUM-B-17: counting a pile in twos ----

  /// "Count the socks in twos": the pile is in a ten-frame whose columns are pairs (other piles go two by two in reading order).
  /// Level 2 rings the pairs one at a time with the count so far, 2, 4, 6; at level 3 the hand goes pair by pair and the total
  /// comes last.
  HintPlan _inTwos(int level) {
    final List<Rect> objs = _groupRects(g, 0);
    final int n = objs.length;
    if (n < 2 || n.isOdd) return generic(level);
    if (level == 1) return look();
    final int pairs = n ~/ 2;
    final bool columns = a.group!.arrangement == 'ten_frame' && n == 10;
    final List<Rect> at = <Rect>[
      for (int i = 0; i < pairs; i++)
        columns ? objs[i].expandToInclude(objs[i + 5]) : objs[2 * i].expandToInclude(objs[2 * i + 1]),
    ];
    List<HintMark> counted(int upTo) => <HintMark>[
      for (int i = 0; i < upTo; i++) ...<HintMark>[
        RingMark(at[i].inflate(2 * k), round: false),
        BadgeMark(at[i].topRight, 2 * (i + 1)),
      ],
    ];
    if (level == 2) {
      return HintPlan(<HintFrame>[
        for (int i = 1; i <= pairs; i++) HintFrame(counted(i), hold: _ms(800)),
      ], rest: counted(pairs));
    }
    return _demo(<HintFrame>[
      for (int i = 1; i <= pairs; i++)
        HintFrame(<HintMark>[...counted(i), HandMark(at[i - 1].center, press: true)], hold: _ms(800)),
      _toAnswer(<HintMark>[...counted(pairs), BadgeMark(Offset(g.w / 2, 18 * k), n, big: true)]),
    ]);
  }

  // ---- MATH-B-17: what the coins are worth ----

  /// The value of the coin a chart column draws (`coin_s5` is 5 shekels), or null for a picture that is not a whole-shekel coin.
  int? _shekelsOf(String sprite) {
    final RegExpMatch? m = RegExp(r'coin_s(\d+)$').firstMatch(sprite);
    return m == null ? null : int.parse(m[1]!);
  }

  /// "How much money is there?": the coins stand in columns on the stage. Level 2 puts each coin's value beside it, column by column;
  /// at level 3 the hand goes along the columns with the sum so far, and the total comes last.
  HintPlan money(int level) {
    final List<int?> value = <int?>[
      for (final ({String sprite, int count}) c in a.chart) _shekelsOf(c.sprite),
    ];
    final List<List<Rect>> cols = a.chart.isEmpty ? <List<Rect>>[] : g.chartColumns();
    if (a.chart.isEmpty || value.contains(null) || cols.any((List<Rect> c) => c.isEmpty)) {
      return generic(level);
    }
    Rect column(int i) =>
        Rect.fromLTRB(cols[i].first.left, cols[i].last.top, cols[i].first.right, cols[i].first.bottom);
    if (level == 1) {
      return HintPlan(<HintFrame>[
        HintFrame(<HintMark>[
          VeilMark(<Rect>[for (int i = 0; i < cols.length; i++) column(i)]),
        ], hold: _ms(2400)),
      ]);
    }
    List<HintMark> values(int upTo) => <HintMark>[
      for (int i = 0; i < upTo; i++)
        for (final Rect coin in cols[i]) BadgeMark(Offset(coin.right + 14 * k, coin.center.dy), value[i]!),
    ];
    if (level == 2) {
      return HintPlan(<HintFrame>[
        for (int i = 1; i <= cols.length; i++) HintFrame(values(i), hold: _ms(900)),
      ], rest: values(cols.length));
    }
    int sum(int upTo) =>
        <int>[for (int i = 0; i < upTo; i++) value[i]! * a.chart[i].count].fold(0, (int s, int v) => s + v);
    Offset sumAt(int i) => Offset(column(i).right + 14 * k, cols[i].last.center.dy);
    List<HintMark> running(int upTo) => <HintMark>[
      for (int i = 0; i < upTo; i++) BadgeMark(sumAt(i), sum(i + 1)),
    ];
    return _demo(<HintFrame>[
      for (int i = 0; i < cols.length; i++)
        HintFrame(<HintMark>[...running(i + 1), HandMark(cols[i].last.center, press: true)], hold: _ms(900)),
      _toAnswer(running(cols.length)),
    ]);
  }

  // ---- MATH-B-18: the part that hides ----

  /// "Seven fish in all, we see three, the others hide behind the stone": the whole is the seen and the hidden together. Level 2
  /// draws the whole as a frame with the seen filled, the empty places lit one by one; at level 3 the hand counts the empty places and
  /// the number of them comes last. The whole is read from the question, and must be the seen and the hidden together.
  HintPlan _hiddenPart(int level) {
    final int? seen = a.group?.count;
    final int? hidden = _right.numeral;
    if (seen == null || hidden == null || hidden < 1 || seen + hidden > 10) return generic(level);
    if (!numbersIn(a.promptLine.caption).contains(seen + hidden)) return generic(level);
    if (level == 1) return look();
    final int whole = seen + hidden;
    final Rect card = g.centre(math.min(g.w - 16, 190 * k), 84 * k);
    final double cube = math.min(26 * k, (card.width - 20 * k) / 5);
    final List<Rect> cells = <Rect>[
      for (int i = 0; i < whole; i++)
        Rect.fromLTWH(
          card.center.dx - 2.5 * (cube + 2 * k) + (i % 5) * (cube + 2 * k),
          card.center.dy - (cube + 2 * k) + (i ~/ 5) * (cube + 2 * k),
          cube,
          cube,
        ),
    ];
    final List<HintMark> frame = <HintMark>[
      CardMark(card, const SizedBox.shrink()),
      for (int i = 0; i < whole; i++) BlockMark(cells[i], empty: i >= seen),
    ];
    final List<Rect> empties = cells.sublist(seen);
    if (level == 2) {
      return HintPlan(
        _lightEach(empties, base: frame),
        rest: <HintMark>[...frame, for (final Rect r in empties) SeenMark(r)],
      );
    }
    final Offset badgeAt = Offset(g.w / 2, 18 * k);
    return _demo(<HintFrame>[
      HintFrame(frame, hold: _ms(500)),
      for (int j = 1; j <= hidden; j++)
        HintFrame(<HintMark>[
          ...frame,
          for (int q = 0; q < j - 1; q++) SeenMark(empties[q]),
          BadgeMark(badgeAt, j),
          HandMark(empties[j - 1].center, press: true),
        ], hold: _ms(700)),
      _toAnswer(<HintMark>[...frame, BadgeMark(badgeAt, hidden)]),
    ]);
  }
}
