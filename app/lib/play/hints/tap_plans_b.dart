part of 'tap_plans.dart';

// Band B of `tap_answer` (B-40 part 4): what each Band B skill draws at each hint level, in the same three steps as Band A (look
// here, another way, watch me with the answer last). A skill that the Band A families already serve (count on, take away, a pattern
// row, a sample colour) is not listed here: [bandB] gives null and the family's own plan runs.
//
// Where a Band B question has nothing on the stage (a number in words, a name of a colour or a day), level 1 lights each answer in
// turn, as in Band A, and the new picture at level 2 is drawn in the empty stage: a path of numbers, a ten-frame, bars of cubes.

/// A number sentence of the stage's row, by the places (cells) of its parts: `A sign B equals R` or `R equals A sign B`; [value] holds
/// the numbers, the unknown one filled in with the answer.
typedef _Sentence = ({int a, int b, int r, int sign, int equals, int unknown, Map<int, int> value});

extension _BandB on _Plans {
  /// The plan of a Band B skill that has pictures of its own, or null when the family's plan serves it.
  HintPlan? bandB(int level) => switch (a.skillId) {
    'COL-B-01' => _mix(level),
    'COL-B-02' => _shades(level),
    'NUM-B-08' => _teens(level),
    'NUM-B-10' => _barsOfOptions(level),
    'NUM-B-17' => _skipCount(level),
    'NUM-B-18' => _pairsUp(level),
    'MATH-B-10' || 'MATH-B-19' => _chart(level),
    'MATH-B-02' when a.group == null => _wholeParts(level),
    'MATH-B-03' || 'MATH-B-07' || 'MATH-B-08' || 'MATH-B-18' => _sentence(level),
    'NUM-B-16' when a.row.isNotEmpty => _sentence(level),
    'MATH-B-06' => _toTen(level),
    'MATH-B-14' => _week(level),
    'MATH-B-15' => _clockHour(level),
    'MATH-B-16' => _coins(level),
    'SHP-B-01' => _corners(level),
    'SHP-B-02' || 'SHP-B-04' => _sides(level),
    'SHP-B-03' => _sideSticks(level),
    'SHP-B-09' => _stamps(level),
    'LOG-B-06' => _common(level),
    'LOG-B-09' => _clues(level),
    _ => null,
  };

  static Rect _sq(Offset c, double side) => Rect.fromCenter(center: c, width: side, height: side);

  /// A hint that stays on the stage once it is shown: one step that is held, then rests.
  HintPlan _still(List<HintMark> marks, {int ms = 2800}) =>
      HintPlan(<HintFrame>[HintFrame(marks, hold: _ms(ms))], rest: marks);

  // ---- COL-B-01: mixing two colours ----

  /// What two paints make (the three mixes of the skill): the colour a pair of parents gives.
  static const Map<String, String> _mixes = <String, String>{
    'red+yellow': 'orange',
    'blue+yellow': 'green',
    'blue+red': 'purple',
  };

  static String? _mixOf(String x, String y) => _mixes[(<String>[x, y]..sort()).join('+')];

  /// Two paints and the colour they make, as [one] [two] -> [made]: one of the three places is empty (the question). With two paints
  /// on the stage the made colour is the answer; with one, the question names the colour made and the answer is the other paint.
  /// At level 3 the hand pours one into the other and what is missing appears in its place, last.
  HintPlan _mix(int level) {
    final String? first = colourOfSprite(a.group?.sprite);
    final String? second = colourOfSprite(a.group2?.sprite);
    final String? picked = colourOfSprite(_spriteOf(_right));
    if (first == null || picked == null) return generic(level);
    final bool findsMix = second != null;
    final String other = second ?? picked;
    final String? made = findsMix ? picked : _mixOf(first, picked);
    if (made == null) return generic(level);
    if (level == 1) return look();
    final Rect card = g.centre(math.min(g.w - 16, 250 * k), 88 * k);
    final double side = 52 * k;
    Rect at(double dx) => _sq(card.center + Offset(dx * k, 0), side);
    final Rect one = at(-88);
    final Rect two = at(-24);
    final Rect result = at(80);
    final Rect hole = findsMix ? result : two;
    final List<HintMark> frame = <HintMark>[
      CardMark(card, const SizedBox.shrink()),
      SwatchMark(one, first),
      if (findsMix) SwatchMark(two, other) else SwatchMark(result, made),
      ArrowMark(card.center + Offset(12 * k, 0), card.center + Offset(44 * k, 0)),
    ];
    final List<HintMark> empty = <HintMark>[...frame, GhostMark(hole, GhostKind.circle)];
    if (level == 2) return _still(empty);
    final List<HintMark> full = <HintMark>[...frame, SwatchMark(hole, findsMix ? made : other)];
    return _demo(<HintFrame>[
      HintFrame(<HintMark>[...empty, HandMark(one.center, press: true)], hold: _ms(750)),
      if (findsMix) HintFrame(<HintMark>[...empty, HandMark(two.center, press: true)], hold: _ms(750)),
      HintFrame(<HintMark>[...empty, HandMark(hole.center, press: true)], hold: _ms(750)),
      HintFrame(<HintMark>[...full, HandMark(hole.center)], hold: _ms(900)),
      _toAnswer(full),
    ]);
  }

  // ---- COL-B-02: from light to dark ----

  /// The shades of one colour in their order, an arrow from the lightest to the darkest. With a row on the stage (the shade in the
  /// middle) the row is the strip and the arrow lies under it.
  HintPlan _shades(int level) {
    final RegExpMatch? m = RegExp(r'^shade_([a-z]+)_(\d)$')
        .firstMatch((_spriteOf(_right) ?? '').replaceFirst('asset:', ''));
    if (m == null) return generic(level);
    if (level == 1) return look();
    if (a.row.isNotEmpty) {
      final List<Rect> cells = g.rowCells();
      final List<int> known = <int>[
        for (final String r in a.row)
          if (RegExp(r'_(\d)$').hasMatch(r)) int.parse(RegExp(r'_(\d)$').firstMatch(r)![1]!),
      ];
      if (known.length < 2) return generic(level);
      final double y = cells.first.bottom + 12 * k;
      final bool lightFirst = known.first < known.last;
      final double from = lightFirst ? cells.first.center.dx : cells.last.center.dx;
      final double to = lightFirst ? cells.last.center.dx : cells.first.center.dx;
      final List<HintMark> arrow = <HintMark>[ArrowMark(Offset(from, y), Offset(to, y))];
      if (level == 2) return _still(arrow);
      return _rowDemo(cells, a.row.indexOf('?'), base: arrow);
    }
    final List<String> strip = <String>[
      for (int i = 1; i <= 3; i++)
        if (_svg('asset:shade_${m[1]}_$i') != null) _svg('asset:shade_${m[1]}_$i')!,
    ];
    if (strip.length != 3) return generic(level);
    final double side = 52 * k;
    final List<Rect> at = <Rect>[
      for (int i = 0; i < 3; i++) _sq(Offset(g.w / 2 + (i - 1) * 70 * k, g.h * 0.42), side),
    ];
    final double y = at.first.bottom + 12 * k;
    final List<HintMark> copies = <HintMark>[for (int i = 0; i < 3; i++) CopyMark(at[i], strip[i])];
    final List<HintMark> shown = <HintMark>[
      ...copies,
      ArrowMark(Offset(at.first.center.dx, y), Offset(at.last.center.dx, y)),
    ];
    if (level == 2) {
      return HintPlan(<HintFrame>[
        for (int i = 1; i <= 3; i++) HintFrame(copies.sublist(0, i), hold: _ms(700)),
        HintFrame(shown, hold: _ms(1800)),
      ], rest: shown);
    }
    return _demo(<HintFrame>[
      for (int i = 0; i < 3; i++)
        HintFrame(<HintMark>[...shown, HandMark(at[i].center, press: true)], hold: _ms(700)),
      _toAnswer(shown),
    ]);
  }

  // ---- NUM-B-08: a number of ten and some ----

  /// A teen as a full ten-frame and the ones on another; level 3 builds it frame by frame and shows the numeral last. A number that
  /// is missing from a row is found on a path of numbers.
  HintPlan _teens(int level) {
    final int? n = _right.numeral;
    if (a.row.isNotEmpty) return sequence(level);
    if (n == null || n < 10 || n > 20) return generic(level);
    if (level == 1) return tilesInTurn();
    final int frames = n > 10 ? 2 : 1;
    // The cells are 24 across on a phone (the spec says 30, which two frames side by side do not leave room for) and grow with the
    // stage. A frame is five cells, its padding and its border wide; the card scales what it holds down if the stage is too narrow.
    final double cell = 24 * k;
    final double frameW = 5 * cell + 9;
    final Rect card = g.centre(math.min(g.w - 16, 300 * k), 84 * k);
    final double total = frames * frameW + (frames - 1) * 16;
    final double f = math.min(1, (card.width - 2 * (6 * k + 3)) / total);
    Offset frameAt(int i) => card.center + Offset((i - (frames - 1) / 2) * (frameW + 16) * f, 0);
    List<HintMark> built(int filled) => <HintMark>[
      CardMark(card, TenFrames(total: n, filled: filled, cell: cell)),
    ];
    if (level == 2) {
      return HintPlan(<HintFrame>[
        HintFrame(built(10), hold: _ms(1300)),
        if (n > 10) HintFrame(built(n), hold: _ms(1800)),
      ], rest: built(n));
    }
    final List<HintMark> numeral = <HintMark>[
      CardMark(card, Text('$n', style: AppText.fixed(size: 44, weight: 800, lineHeight: 1))),
    ];
    return _demo(<HintFrame>[
      HintFrame(built(0), hold: _ms(500)),
      HintFrame(<HintMark>[...built(10), HandMark(frameAt(0), press: true)], hold: _ms(900)),
      if (n > 10) HintFrame(<HintMark>[...built(n), HandMark(frameAt(1), press: true)], hold: _ms(900)),
      HintFrame(<HintMark>[...numeral, HandMark(card.center)], hold: _ms(900)),
      _toAnswer(numeral),
    ]);
  }

  // ---- NUM-B-17: counting by twos, by tens ----

  /// A path of the numbers that are counted by, the steps given drawn as hops and the next place empty. The numbers given and the
  /// step are read from the question; level 3 hops along them and lands in the place.
  HintPlan _skipCount(int level) {
    final int? c = _right.numeral;
    final List<int> said = numbersIn(a.promptLine.caption);
    if (c == null || said.length < 2) return generic(level);
    final int step = said[1] - said[0];
    if (step <= 0 || said.last + step != c) return generic(level);
    const int m = 10;
    int start = math.max(step, said.first - 2 * step);
    if (c > start + (m - 1) * step) start = c - (m - 1) * step;
    final Rect path = Rect.fromCenter(
      center: Offset(g.w / 2, g.h / 2 + 6 * k),
      width: math.min(g.w - 20, m * 30 * k),
      height: 36 * k,
    );
    Offset top(int n) => Offset(path.left + ((n - start) / step + 0.5) * path.width / m, path.top + 2 * k);
    PathMark strip({int? marker, int? gap}) =>
        PathMark(rect: path, count: m, gap: gap, marker: marker, from: start, step: step);
    List<HintMark> hops(int upTo) => <HintMark>[
      for (int i = 0; i < upTo - 1; i++) ArcMark(top(said[i]), top(said[i + 1])),
    ];
    if (level == 1) {
      // The numbers that were said in a row, and the empty place at the right end: the question again.
      final double side = 48 * k;
      final int slots = said.length + 1;
      final List<Rect> at = <Rect>[
        for (int i = 0; i < slots; i++)
          _sq(Offset(g.w / 2 + (i - (slots - 1) / 2) * (side + 8 * k), g.h / 2), side),
      ];
      return HintPlan(<HintFrame>[
        HintFrame(<HintMark>[
          VeilMark(at),
          for (int i = 0; i < said.length; i++)
            CardMark(at[i], Text('${said[i]}', style: AppText.fixed(size: 24, weight: 800, lineHeight: 1))),
          GhostMark(at.last, GhostKind.square),
        ], hold: _ms(2600)),
      ]);
    }
    final List<HintMark> shown = <HintMark>[strip(gap: c), ...hops(said.length)];
    if (level == 2) {
      return HintPlan(<HintFrame>[
        for (int i = 1; i <= said.length; i++)
          HintFrame(<HintMark>[strip(gap: c, marker: said[i - 1]), ...hops(i)], hold: _ms(750)),
      ], rest: shown);
    }
    return _demo(<HintFrame>[
      for (int i = 1; i <= said.length; i++)
        HintFrame(<HintMark>[
          strip(gap: c, marker: said[i - 1]),
          ...hops(i),
          HandMark(top(said[i - 1]), press: true),
        ], hold: _ms(750)),
      HintFrame(<HintMark>[
        strip(marker: c),
        ...hops(said.length),
        ArcMark(top(said.last), top(c)),
        HandMark(top(c), press: true),
      ], hold: _ms(1000)),
      _toAnswer(<HintMark>[strip(marker: c), ...hops(said.length), ArcMark(top(said.last), top(c))]),
    ]);
  }

  // ---- bars of cubes: NUM-B-10 (which number is bigger) and MATH-B-16 (which coin is worth more) ----

  /// A bar of cubes for each option, from one start line: the longer is the bigger number. Numerals only (the stage is empty).
  HintPlan _barsOfOptions(int level) {
    final List<int> values = <int>[for (final ChoiceOption o in a.options) o.numeral ?? -1];
    if (values.any((int v) => v < 0)) return generic(level);
    return _bars(level, <double>[for (final int v in values) v.toDouble()]);
  }

  /// The value of a coin from its picture (`coin_s5` is 5 shekels, `coin_a10` and `coin_h50` are agorot), in shekels.
  double? _coinValue(ChoiceOption o) {
    final RegExpMatch? m = RegExp(r'coin_([sah])(\d+)$').firstMatch(o.sprite ?? '');
    if (m == null) return null;
    final double n = double.parse(m[2]!);
    return m[1] == 's' ? n : n / 100;
  }

  /// Two coins of one size, each with a bar of cubes as long as its value: what a coin is worth, not how big it is (M-MONEY-SIZE).
  HintPlan _coins(int level) {
    final List<double?> values = <double?>[for (final ChoiceOption o in a.options) _coinValue(o)];
    if (values.any((double? v) => v == null) || a.options.any((ChoiceOption o) => _svg(o.sprite) == null)) {
      return generic(level);
    }
    return _bars(
      level,
      <double>[for (final double? v in values) v!],
      heads: <String>[for (final ChoiceOption o in a.options) _svg(o.sprite)!],
    );
  }

  HintPlan _bars(int level, List<double> values, {List<String>? heads}) {
    if (level == 1) return tilesInTurn();
    final int n = values.length;
    final double startX = (heads == null ? 34 : 62) * k;
    final double most = values.fold(1, (double m, double v) => math.max(m, v.ceilToDouble()));
    // As big as the stage lets them be (up to 24 on a phone), so that the child can count the cubes of each bar.
    final double cube = math.max(5 * k, math.min(24 * k, (g.w - startX - 26 * k) / most));
    double y(int i) => g.h * (n == 2 ? (i == 0 ? 0.3 : 0.7) : (0.2 + 0.3 * i));
    final HintMark line = LineMark(Offset(startX - 4 * k, 6 * k), Offset(startX - 4 * k, g.h - 6 * k));
    List<HintMark> bar(int i) {
      final List<HintMark> out = <HintMark>[
        if (heads != null) CopyMark(_sq(Offset(30 * k, y(i)), 40 * k), heads[i]),
      ];
      double left = startX;
      double remaining = values[i];
      while (remaining > 0) {
        final double part = math.min(1, remaining);
        out.add(BlockMark(Rect.fromLTWH(left, y(i) - cube / 2, cube * part - 1.5 * k, cube - 1.5 * k)));
        left += cube * part;
        remaining -= part;
      }
      return out;
    }

    Offset end(int i) => Offset(startX + values[i] * cube, y(i));
    final List<HintMark> all = <HintMark>[line, for (int i = 0; i < n; i++) ...bar(i)];
    if (level == 2) {
      return HintPlan(<HintFrame>[
        for (int i = 1; i <= n; i++)
          HintFrame(<HintMark>[line, for (int j = 0; j < i; j++) ...bar(j)], hold: _ms(1000)),
        HintFrame(all, hold: _ms(1800)),
      ], rest: all);
    }
    HintMark? count(int i) => values[i] >= 1 && values[i] == values[i].roundToDouble()
        ? BadgeMark(end(i) + Offset(14 * k, 13 * k), values[i].round())
        : null;
    List<HintMark> counted(int upTo) => <HintMark>[for (int j = 0; j < upTo; j++) ?count(j)];
    return _demo(<HintFrame>[
      HintFrame(all, hold: _ms(500)),
      for (int i = 0; i < n; i++)
        HintFrame(<HintMark>[...all, ...counted(i + 1), HandMark(end(i), press: true)], hold: _ms(900)),
      _toAnswer(<HintMark>[...all, ...counted(n)]),
    ]);
  }

  // ---- NUM-B-18: pairs of two ----

  /// The things of the stage in twos, a line for each pair; the one that has no partner is ringed (an odd number leaves one).
  HintPlan _pairsUp(int level) {
    if (a.group == null) return generic(level);
    final List<Rect> objs = _groupRects(g, 0);
    final int n = objs.length;
    if (n < 2) return generic(level);
    if (level == 1) return look();
    final int pairs = n ~/ 2;
    final List<Rect> lone = n.isOdd ? <Rect>[objs.last] : <Rect>[];
    List<(Offset, Offset)> lines(int upTo) => <(Offset, Offset)>[
      for (int i = 0; i < upTo; i++) (objs[2 * i].center, objs[2 * i + 1].center),
    ];
    final PairsMark all = PairsMark(lines: lines(pairs), unpaired: lone);
    if (level == 2) {
      return HintPlan(
        <HintFrame>[
          for (int i = 1; i <= pairs; i++) HintFrame(<HintMark>[PairsMark(lines: lines(i))], hold: _ms(600)),
          HintFrame(<HintMark>[all], hold: _ms(1800)),
        ],
        rest: <HintMark>[all],
      );
    }
    return _demo(<HintFrame>[
      for (int i = 1; i <= pairs; i++)
        HintFrame(<HintMark>[
          PairsMark(lines: lines(i)),
          HandMark((objs[2 * i - 2].center + objs[2 * i - 1].center) / 2, press: true),
        ], hold: _ms(750)),
      if (lone.isNotEmpty)
        HintFrame(<HintMark>[all, HandMark(lone.first.center, press: true)], hold: _ms(900)),
      _toAnswer(<HintMark>[all]),
    ]);
  }

  // ---- MATH-B-19 and MATH-B-10: a chart of columns ----

  /// The columns of the chart, each with how many it holds. Level 3 goes along the columns with a badge for each; for equal groups
  /// ([MATH-B-10]) the badge keeps a running total.
  HintPlan _chart(int level) {
    if (a.chart.isEmpty) return generic(level);
    final List<List<Rect>> cols = g.chartColumns();
    if (cols.any((List<Rect> c) => c.isEmpty)) return generic(level);
    final bool running = a.skillId == 'MATH-B-10';
    Rect column(int i) =>
        Rect.fromLTRB(cols[i].first.left, cols[i].last.top, cols[i].first.right, cols[i].first.bottom);
    Offset badgeAt(int i) => Offset(column(i).right + 14 * k, cols[i].last.center.dy);
    if (level == 1) {
      return HintPlan(<HintFrame>[
        HintFrame(<HintMark>[
          VeilMark(<Rect>[for (int i = 0; i < cols.length; i++) column(i)]),
        ], hold: _ms(2400)),
      ]);
    }
    int total(int upTo) =>
        <int>[for (int i = 0; i < upTo; i++) a.chart[i].count].fold(0, (int s, int c) => s + c);
    List<HintMark> counts(int upTo, {required bool total_}) => <HintMark>[
      for (int i = 0; i < upTo; i++) BadgeMark(badgeAt(i), total_ ? total(i + 1) : a.chart[i].count),
    ];
    if (level == 2) {
      final List<HintMark> every = counts(cols.length, total_: false);
      return HintPlan(<HintFrame>[
        for (int i = 1; i <= cols.length; i++) HintFrame(counts(i, total_: false), hold: _ms(800)),
        HintFrame(every, hold: _ms(1500)),
      ], rest: every);
    }
    return _demo(<HintFrame>[
      for (int i = 0; i < cols.length; i++)
        HintFrame(<HintMark>[
          ...counts(i + 1, total_: running),
          HandMark(cols[i].last.center, press: true),
        ], hold: _ms(850)),
      _toAnswer(counts(cols.length, total_: running)),
    ]);
  }

  // ---- MATH-B-03, 07, 08, 18: number sentences ----

  /// The cells of a number sentence of the stage's row: the cell of each number, of the sign and the equals sign, and which cell is
  /// the unknown one. `A op B = R` and `R = A op B` both read as (A, B, R).
  _Sentence? _readSentence() {
    final List<String> row = a.row;
    final int eq = row.indexOf('op:=');
    final int c = _right.numeral ?? -1;
    if (eq < 0 || c < 0) return null;
    final List<int> left = <int>[for (int i = 0; i < eq; i++) i];
    final List<int> right = <int>[for (int i = eq + 1; i < row.length; i++) i];
    final bool exprLeft = left.length == 3;
    final List<int> expr = exprLeft ? left : right;
    final List<int> single = exprLeft ? right : left;
    if ((exprLeft ? right.length : left.length) != 1 || expr.length != 3 || !row[expr[1]].startsWith('op:')) {
      return null;
    }
    final Map<int, int> value = <int, int>{};
    int? unknown;
    for (final int i in <int>[expr[0], expr[2], single.first]) {
      if (row[i] == '?') {
        unknown = i;
        value[i] = c;
      } else if (row[i].startsWith('n:')) {
        value[i] = int.tryParse(row[i].substring(2)) ?? -1;
      }
    }
    if (unknown == null || value.values.any((int v) => v < 0)) return null;
    return (
      a: expr[0],
      b: expr[2],
      r: single.first,
      sign: expr[1],
      equals: eq,
      unknown: unknown,
      value: value,
    );
  }

  /// [n] small cubes over the cell [cell], in rows of five from the bottom up; the first [filled] are cubes, the rest empty places.
  List<HintMark> _cubesAbove(Rect cell, int n, {int? filled}) {
    if (n <= 0) return <HintMark>[];
    final int rows = (n / 5).ceil();
    // The numeral of a cell may reach above its square: the cubes stand over the drawn cell's top.
    final double top = math.min(cell.top, g.rowTop);
    final double room = top - 8 * k;
    // A row of five may be a little wider than its cell (the cells beside a number are signs, with nothing over them).
    final double cube = math.max(
      4,
      math.min(math.min(15 * k, (cell.width + 24 * k) / math.min(n, 5) - 2), room / rows - 1),
    );
    final double bottom = top - 4 * k;
    final double rowWidth = math.min(n, 5) * (cube + 1);
    // A row wider than its cell stays inside the stage.
    final double left = (cell.center.dx - rowWidth / 2)
        .clamp(4 * k, math.max(4 * k, g.w - 4 * k - rowWidth))
        .toDouble();
    return <HintMark>[
      for (int i = 0; i < n; i++)
        BlockMark(
          Rect.fromLTWH(left + (i % 5) * (cube + 1), bottom - ((i ~/ 5) + 1) * (cube + 1), cube, cube),
          empty: i >= (filled ?? n),
        ),
    ];
  }

  /// Level 1 lights the signs; level 2 puts cubes over the numbers (for a missing part, over the whole: the known part cubes, the rest
  /// empty places to count); level 3 the hand goes over the numbers and the answer comes in the empty cell last.
  HintPlan _sentence(int level) {
    final _Sentence? s = _readSentence();
    if (s == null) return generic(level);
    final List<Rect> cells = g.rowCells();
    if (level == 1) {
      return HintPlan(<HintFrame>[
        HintFrame(<HintMark>[
          VeilMark(<Rect>[cells[s.sign], cells[s.equals]]),
        ], hold: _ms(2400)),
      ]);
    }
    final int av = s.value[s.a]!;
    final int bv = s.value[s.b]!;
    final int rv = s.value[s.r]!;
    final bool addition = a.row[s.sign] == 'op:+';
    if (s.unknown == s.r) {
      List<HintMark> cubes(int upTo) => <HintMark>[
        if (upTo >= 1) ..._cubesAbove(cells[s.a], av),
        if (upTo >= 2) ..._cubesAbove(cells[s.b], bv),
      ];
      if (level == 2) {
        return HintPlan(<HintFrame>[
          HintFrame(cubes(1), hold: _ms(1000)),
          HintFrame(cubes(2), hold: _ms(1800)),
        ], rest: cubes(2));
      }
      final Offset answerAt = cells[s.r].center + Offset(0, 24 * k);
      return _demo(<HintFrame>[
        HintFrame(<HintMark>[...cubes(1), HandMark(cells[s.a].center, press: true)], hold: _ms(800)),
        HintFrame(<HintMark>[...cubes(2), HandMark(cells[s.b].center, press: true)], hold: _ms(800)),
        HintFrame(<HintMark>[
          ...cubes(2),
          BadgeMark(answerAt, rv),
          HandMark(answerAt, press: true),
        ], hold: _ms(900)),
        _toAnswer(<HintMark>[...cubes(2), BadgeMark(answerAt, rv)]),
      ]);
    }
    // A part is missing: the whole is drawn as the known part (cubes) and the places that are left (empty), over the whole's cell.
    final int knownCell = s.unknown == s.a ? s.b : s.a;
    final int known = s.value[knownCell]!;
    final int whole = addition ? rv : av;
    if (!addition || whole < known) return generic(level);
    final List<HintMark> parts = <HintMark>[
      ..._cubesAbove(cells[knownCell], known),
      ..._cubesAbove(cells[s.r], whole, filled: known),
    ];
    final int left = whole - known;
    if (level == 2) {
      return HintPlan(<HintFrame>[
        HintFrame(_cubesAbove(cells[knownCell], known), hold: _ms(1000)),
        HintFrame(parts, hold: _ms(1800)),
      ], rest: parts);
    }
    // The empty places are counted one by one in the cell of the unknown: a badge with how many so far.
    final Offset counted = cells[s.unknown].center + Offset(0, 24 * k);
    final List<HintMark> places = _cubesAbove(cells[s.r], whole, filled: known);
    return _demo(<HintFrame>[
      HintFrame(<HintMark>[...parts, HandMark(cells[knownCell].center, press: true)], hold: _ms(800)),
      for (int j = 1; j <= left; j++)
        HintFrame(<HintMark>[
          ...parts,
          BadgeMark(counted, j),
          HandMark((places[known + j - 1] as BlockMark).rect.center, press: true),
        ], hold: _ms(650)),
      _toAnswer(<HintMark>[...parts, BadgeMark(counted, left)]),
    ]);
  }

  // ---- MATH-B-02: a whole and its parts, with no picture on the stage ----

  /// "Ten is three and how many?" and "two in the basket and five outside, how many in all?": a row of cubes, the known part drawn
  /// and the rest left empty (or both parts side by side). The numbers are read from the question.
  HintPlan _wholeParts(int level) {
    final List<int> said = numbersIn(a.promptLine.caption);
    final int? c = _right.numeral;
    if (said.length < 2 || c == null) return generic(level);
    final bool missing = c == said[0] - said[1];
    final bool sum = c == said[0] + said[1];
    if (!missing && !sum) return generic(level);
    if (level == 1) return tilesInTurn();
    final int cells = missing ? said[0] : said[0] + said[1];
    final Rect card = g.centre(math.min(g.w - 16, 284 * k), 76 * k);
    final double cube = math.min(30 * k, (card.width - 24 * k - (sum ? 12 * k : 0)) / cells - 3 * k);
    Rect at(int i) {
      final double gap = sum && i >= said[0] ? 12 * k : 0;
      final double width = cells * (cube + 3 * k) + (sum ? 12 * k : 0);
      return Rect.fromLTWH(
        card.center.dx - width / 2 + i * (cube + 3 * k) + gap,
        card.center.dy - cube / 2,
        cube,
        cube,
      );
    }

    final List<HintMark> row = <HintMark>[
      CardMark(card, const SizedBox.shrink()),
      for (int i = 0; i < cells; i++) BlockMark(at(i), empty: missing && i >= said[1]),
    ];
    if (level == 2) {
      return HintPlan(<HintFrame>[
        HintFrame(<HintMark>[
          CardMark(card, const SizedBox.shrink()),
          ...row.sublist(1, 1 + (missing ? said[1] : said[0])),
        ], hold: _ms(1200)),
        HintFrame(row, hold: _ms(1800)),
      ], rest: row);
    }
    final int from = missing ? said[1] : 0;
    return _demo(<HintFrame>[
      HintFrame(row, hold: _ms(500)),
      for (int j = from + 1; j <= cells; j++)
        HintFrame(<HintMark>[
          ...row,
          BadgeMark(at(j - 1).topCenter - Offset(0, 14 * k), missing ? j - from : j),
          HandMark(at(j - 1).center, press: true),
        ], hold: _ms(missing ? 650 : 480)),
      _toAnswer(<HintMark>[
        ...row,
        BadgeMark(at(cells - 1).topCenter - Offset(0, 14 * k), missing ? cells - from : cells),
      ]),
    ]);
  }

  // ---- MATH-B-06: how many more to make ten ----

  /// The cells of a ten-frame that are still empty are what is asked: lit one by one at level 2, counted at level 3. A group drawn
  /// in a ten-frame uses its own frame; any other group gets a frame in a card.
  HintPlan _toTen(int level) {
    final SpriteSet? set = a.group;
    if (set == null || _right.numeral != 10 - set.count || set.count >= 10) return generic(level);
    if (level == 1) return look();
    final int n = set.count;
    final int left = 10 - n;
    List<Rect> cells;
    List<HintMark> frame = <HintMark>[];
    final List<Rect> own = set.arrangement == 'ten_frame' ? g.groupObjects(0, count: 10) : <Rect>[];
    if (own.length == 10) {
      cells = own;
      // The stage draws only the pictures, so the places that are still empty are drawn as outlines.
      frame = <HintMark>[
        for (final Rect r in own.sublist(n)) BlockMark(r.deflate(r.width * 0.18), empty: true),
      ];
    } else {
      final Rect card = g.centre(math.min(g.w - 16, 190 * k), 84 * k);
      final double cube = math.min(26 * k, (card.width - 20 * k) / 5);
      cells = <Rect>[
        for (int i = 0; i < 10; i++)
          Rect.fromLTWH(
            card.center.dx - 2.5 * (cube + 2 * k) + (i % 5) * (cube + 2 * k),
            card.center.dy - (cube + 2 * k) + (i ~/ 5) * (cube + 2 * k),
            cube,
            cube,
          ),
      ];
      frame = <HintMark>[
        CardMark(card, const SizedBox.shrink()),
        for (int i = 0; i < 10; i++) BlockMark(cells[i], empty: i >= n),
      ];
    }
    final List<Rect> empties = cells.sublist(n);
    if (level == 2) {
      return HintPlan(
        _lightEach(empties, base: frame),
        rest: <HintMark>[...frame, for (final Rect r in empties) SeenMark(r)],
      );
    }
    final Offset badgeAt = Offset(g.w / 2, 18 * k);
    return _demo(<HintFrame>[
      HintFrame(frame, hold: _ms(500)),
      for (int j = 1; j <= left; j++)
        HintFrame(<HintMark>[
          ...frame,
          for (int q = 0; q < j - 1; q++) SeenMark(empties[q]),
          BadgeMark(badgeAt, j),
          HandMark(empties[j - 1].center, press: true),
        ], hold: _ms(700)),
      _toAnswer(<HintMark>[...frame, BadgeMark(badgeAt, left)]),
    ]);
  }

  // ---- MATH-B-14: the days of the week ----

  /// A strip of the seven day cards in their order, left to right, the day that was asked for left empty; the day given in the
  /// question is ringed. Level 3 walks along the strip from the first day, and the card comes into its place last.
  HintPlan _week(int level) {
    final RegExpMatch? m = RegExp(r'day_(\d)$').firstMatch(_spriteOf(_right) ?? '');
    final String q = a.promptLine.caption;
    final bool after = promptHasWord(q, 'axry') || promptHasWord(q, 'mxr');
    final bool before = promptHasWord(q, 'lpny') || promptHasWord(q, 'aTmvl');
    final List<String?> cards = <String?>[for (int i = 1; i <= 7; i++) _svg('asset:day_$i')];
    if (m == null || cards.contains(null) || after == before) return generic(level);
    if (level == 1) return tilesInTurn();
    final int day = int.parse(m[1]!);
    final int given = after ? (day == 1 ? 7 : day - 1) : (day == 7 ? 1 : day + 1);
    final double cellW = (g.w - 20) / 7;
    final double side = math.min(cellW - 4, 52 * k);
    Rect cell(int d) => _sq(Offset(10 + (d - 0.5) * cellW, g.h / 2), side);
    List<HintMark> strip({bool filled = false}) => <HintMark>[
      for (int d = 1; d <= 7; d++)
        if (d == day && !filled) GhostMark(cell(d), GhostKind.square) else CopyMark(cell(d), cards[d - 1]!),
    ];
    final List<HintMark> shown = <HintMark>[...strip(), RingMark(cell(given), round: false)];
    if (level == 2) {
      return HintPlan(<HintFrame>[
        HintFrame(strip(), hold: _ms(1200)),
        HintFrame(shown, hold: _ms(1800)),
      ], rest: shown);
    }
    final int last = math.max(given, day);
    return _demo(<HintFrame>[
      for (int d = 1; d <= last; d++)
        HintFrame(<HintMark>[
          ...strip(),
          HandMark(cell(d).topCenter + Offset(0, 6 * k), press: true),
        ], hold: _ms(550)),
      if (before)
        HintFrame(<HintMark>[
          ...strip(),
          HandMark(cell(day).topCenter + Offset(0, 6 * k), press: true),
        ], hold: _ms(700)),
      HintFrame(<HintMark>[
        ...strip(filled: true),
        HandMark(cell(day).topCenter + Offset(0, 6 * k)),
      ], hold: _ms(900)),
      _toAnswer(strip(filled: true)),
    ]);
  }

  // ---- MATH-B-15: what time is it ----

  /// The short hand is the one that tells the hour: lit at level 1, a dotted ray out to the edge of the dial at level 2 (the dial's
  /// top is marked 12). At level 3 the hand counts the hours round the dial from the 12 up to the short hand.
  HintPlan _clockHour(int level) {
    final RegExpMatch? m = RegExp(r'clock_(\d+)$').firstMatch(a.group?.sprite ?? '');
    final List<Rect> faces = a.group == null ? <Rect>[] : g.groupObjects(0);
    if (m == null || faces.length != 1) return generic(level);
    final int hour = int.parse(m[1]!);
    final Rect face = faces.first;
    final double u = face.width / 100;
    final Offset c = face.center;
    Offset tick(int h, double r) =>
        c + Offset(math.sin(h * math.pi / 6), -math.cos(h * math.pi / 6)) * (r * u);
    // The numbers stand a little outside the dial, far enough from each other that two neighbours never touch (a small dial on a
    // small phone has ticks that are closer than a badge is wide).
    Offset number(int h) => tick(h, math.max(44, 46 * k / u));
    if (level == 1) {
      return HintPlan(<HintFrame>[
        HintFrame(<HintMark>[
          VeilMark(<Rect>[Rect.fromPoints(c, tick(hour, 24)).inflate(4 * u)]),
        ], hold: _ms(2600)),
      ]);
    }
    final List<HintMark> twelve = <HintMark>[BadgeMark(number(12), 12)];
    final List<HintMark> ray = <HintMark>[
      LineMark(tick(hour, 27), tick(hour, 41)),
      RingMark(_sq(tick(hour, 41), 14 * u), round: true),
      ...twelve,
    ];
    if (level == 2) return _still(ray);
    List<HintMark> counted(int upTo) => <HintMark>[for (int j = 1; j <= upTo; j++) BadgeMark(number(j), j)];
    return _demo(<HintFrame>[
      HintFrame(<HintMark>[...ray, HandMark(c, press: true)], hold: _ms(700)),
      HintFrame(<HintMark>[...ray, HandMark(tick(hour, 24))], hold: _ms(700)),
      for (int j = 1; j <= hour; j++)
        HintFrame(<HintMark>[
          LineMark(tick(hour, 27), tick(hour, 41)),
          ...counted(j),
          HandMark(number(j), press: true),
        ], hold: _ms(420)),
      _toAnswer(<HintMark>[LineMark(tick(hour, 27), tick(hour, 41)), ...counted(hour)]),
    ]);
  }

  // ---- SHP-B-01, 02, 03, 04: corners and sides ----

  /// The shape the question names, its corners and sides: lit one after the other at level 2 (a dot for each corner reached) and
  /// counted at level 3.
  HintPlan _corners(int level) {
    final SpriteOutline? o = outlineOf(_svg(_spriteOf(_right)) ?? '');
    if (o == null) return generic(level);
    if (level == 1) return look();
    final Rect box = g.centre(math.min(96 * k, g.h - 20), math.min(96 * k, g.h - 20));
    return _walkSides(level, o, box, badges: true);
  }

  /// The shape of the stage (SHP-B-02 counts its sides, SHP-B-04 follows them round to see whether they close).
  HintPlan _sides(int level) {
    final List<Rect> shapes = a.group == null ? <Rect>[] : g.groupObjects(0);
    final SpriteOutline? o = outlineOf(_svg(a.group?.sprite) ?? '');
    if (o == null || shapes.length != 1) return generic(level);
    if (level == 1) return look();
    final double side = math.min(shapes.first.width, shapes.first.height);
    return _walkSides(level, o, _sq(shapes.first.center, side), badges: a.skillId == 'SHP-B-02');
  }

  /// Level 2: the sides of [o] in [box] lit in order from a start dot; level 3: the hand goes corner to corner, with a number for
  /// each side when [badges]; a curved shape (many short sides) is lit in six steps.
  HintPlan _walkSides(int level, SpriteOutline o, Rect box, {required bool badges}) {
    final List<Offset> pts = o.inBox(box);
    final int sides = o.sides;
    final int step = math.max(1, (sides / 6).ceil());
    final List<int> stops = <int>[for (int s = step; s < sides; s += step) s, sides];
    HintMark lit(int upTo) => OutlineMark(pts, closed: o.closed, upTo: upTo, faint: upTo == 0);
    Offset corner(int i) => pts[i % pts.length];
    Offset mid(int i) => (corner(i) + corner(i + 1)) / 2;
    final Offset centre = box.center;
    Offset outward(Offset p, double d) {
      final Offset v = p - centre;
      return v.distance < 1 ? p : p + v / v.distance * d;
    }

    if (level == 2) {
      return HintPlan(
        <HintFrame>[
          HintFrame(<HintMark>[lit(0)], hold: _ms(500)),
          for (final int s in stops) HintFrame(<HintMark>[lit(s)], hold: _ms(step == 1 ? 650 : 450)),
        ],
        rest: <HintMark>[lit(sides)],
      );
    }
    List<HintMark> numbered(int upTo) => <HintMark>[
      if (badges)
        for (int i = 0; i < upTo; i++) BadgeMark(outward(mid(i), 15 * k), i + 1),
    ];
    return _demo(<HintFrame>[
      HintFrame(<HintMark>[lit(0), HandMark(corner(0), press: true)], hold: _ms(600)),
      for (final int s in stops)
        HintFrame(<HintMark>[
          lit(s),
          ...numbered(s),
          HandMark(corner(s), press: true),
        ], hold: _ms(step == 1 ? 700 : 500)),
      _toAnswer(<HintMark>[lit(sides), ...numbered(sides)]),
    ]);
  }

  /// The options' shapes on the stage, side by side, and for each the lengths of its sides as short sticks one over the other: how
  /// long each side is, with no word and no mark on any one shape.
  HintPlan _sideSticks(int level) {
    final List<(String, SpriteOutline?)> shapes = <(String, SpriteOutline?)>[
      for (final ChoiceOption o in a.options)
        if (_svg(o.sprite) != null) (_svg(o.sprite)!, outlineOf(_svg(o.sprite)!)),
    ];
    if (shapes.length != a.options.length || shapes.every(((String, SpriteOutline?) s) => s.$2 == null)) {
      return generic(level);
    }
    if (level == 1) return look();
    final int n = shapes.length;
    final double cellW = (g.w - 20) / n;
    final double side = math.min(cellW - 14 * k, 54 * k);
    Rect box(int i) => Rect.fromLTWH(10 + (i + 0.5) * cellW - side / 2, 6 * k, side, side);
    List<HintMark> pictures(int upTo) => <HintMark>[
      for (int i = 0; i < upTo; i++) CopyMark(box(i), shapes[i].$1),
    ];
    List<HintMark> sticks(int i) {
      final SpriteOutline? o = shapes[i].$2;
      if (o == null) return <HintMark>[];
      final double top = box(i).bottom + 10 * k;
      return <HintMark>[
        for (int s = 0; s < o.sides; s++)
          BlockMark(
            Rect.fromLTWH(
              box(i).center.dx - o.sideLength(s) * side * 0.5,
              top + s * 9 * k,
              o.sideLength(s) * side,
              6 * k,
            ),
          ),
      ];
    }

    final List<HintMark> all = <HintMark>[...pictures(n), for (int i = 0; i < n; i++) ...sticks(i)];
    if (level == 2) {
      return HintPlan(<HintFrame>[
        HintFrame(pictures(n), hold: _ms(900)),
        for (int i = 1; i <= n; i++)
          HintFrame(<HintMark>[...pictures(n), for (int j = 0; j < i; j++) ...sticks(j)], hold: _ms(1000)),
      ], rest: all);
    }
    return _demo(<HintFrame>[
      for (int i = 0; i < n; i++)
        HintFrame(<HintMark>[...all, HandMark(box(i).center, press: true)], hold: _ms(800)),
      _toAnswer(all),
    ]);
  }

  // ---- SHP-B-09: what a solid leaves in the sand ----

  /// The solids of the options side by side, and under each the print it leaves when it is pressed down on its flat face: a round tin
  /// and a cone leave a circle, a box a square. Every option gets its print, none is marked.
  HintPlan _stamps(int level) {
    GhostKind? footprintOf(String? ref) => switch ((ref ?? '').replaceFirst('asset:solid_', '')) {
      'cylinder' || 'cone' || 'sphere' => GhostKind.circle,
      'box' || 'pyramid' => GhostKind.square,
      _ => null,
    };
    final List<GhostKind?> prints = <GhostKind?>[
      for (final ChoiceOption o in a.options) footprintOf(o.sprite),
    ];
    if (prints.contains(null) || a.options.any((ChoiceOption o) => _svg(o.sprite) == null)) {
      return generic(level);
    }
    if (level == 1) return tilesInTurn();
    final int n = a.options.length;
    final double cellW = (g.w - 20) / n;
    final double side = math.min(cellW - 20 * k, 50 * k);
    Rect solid(int i) => _sq(Offset(10 + (i + 0.5) * cellW, g.h * 0.32), side);
    Rect mark(int i) => _sq(Offset(10 + (i + 0.5) * cellW, g.h * 0.76), side * 0.95);
    List<HintMark> solids(int upTo) => <HintMark>[
      for (int i = 0; i < upTo; i++) CopyMark(solid(i), _svg(a.options[i].sprite)!),
    ];
    List<HintMark> printed(int upTo) => <HintMark>[
      for (int i = 0; i < upTo; i++) GhostMark(mark(i), prints[i]!),
    ];
    final List<HintMark> all = <HintMark>[...solids(n), ...printed(n)];
    if (level == 2) {
      return HintPlan(<HintFrame>[
        HintFrame(solids(n), hold: _ms(900)),
        for (int i = 1; i <= n; i++) HintFrame(<HintMark>[...solids(n), ...printed(i)], hold: _ms(1000)),
      ], rest: all);
    }
    return _demo(<HintFrame>[
      for (int i = 0; i < n; i++)
        HintFrame(<HintMark>[...all, HandMark(mark(i).center, press: true)], hold: _ms(800)),
      _toAnswer(all),
    ]);
  }

  // ---- LOG-B-06: what do they all share, LOG-B-09: two clues ----

  /// What the pictures of a row have in common: each linked to the next at level 2, and the hand along the row at level 3.
  HintPlan _common(int level) {
    if (a.row.length < 2) return generic(level);
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
    return _demo(<HintFrame>[
      for (int i = 0; i < cells.length; i++)
        HintFrame(<HintMark>[
          ...links(cells.length - 1),
          HandMark(cells[i].center, press: true),
        ], hold: _ms(700)),
      _toAnswer(links(cells.length - 1)),
    ]);
  }

  /// "Not red and not round": the options are drawn in a row on the stage. Level 2 puts the first clue to them (the one that is
  /// red fades), level 3 the second (the round one fades) and the one that is left is the answer.
  HintPlan _clues(int level) {
    final RegExp name = RegExp(r'shape_([a-z]+)_([a-z]+)$');
    final List<RegExpMatch?> parts = <RegExpMatch?>[
      for (final ChoiceOption o in a.options) name.firstMatch(o.sprite ?? ''),
    ];
    final List<String?> svgs = <String?>[for (final ChoiceOption o in a.options) _svg(o.sprite)];
    if (parts.contains(null) || svgs.contains(null) || a.options.length != 3) return generic(level);
    final RegExpMatch right = parts[_ci]!;
    int? byColour; // the one that has the right shape and another colour: it breaks the colour clue
    int? byShape; // the one that has the right colour and another shape
    for (int i = 0; i < 3; i++) {
      if (i == _ci) continue;
      if (parts[i]![1] == right[1] && parts[i]![2] != right[2]) byColour = i;
      if (parts[i]![2] == right[2] && parts[i]![1] != right[1]) byShape = i;
    }
    if (byColour == null || byShape == null) return generic(level);
    if (level == 1) return tilesInTurn();
    final double cellW = (g.w - 20) / 3;
    final double side = math.min(cellW - 14 * k, 60 * k);
    Rect cell(int i) => _sq(Offset(10 + (i + 0.5) * cellW, g.h / 2), side);
    List<HintMark> row({Set<int> faded = const <int>{}}) => <HintMark>[
      for (int i = 0; i < 3; i++) CopyMark(cell(i), svgs[i]!, opacity: faded.contains(i) ? 0.28 : 1),
    ];
    if (level == 2) {
      return HintPlan(<HintFrame>[
        HintFrame(row(), hold: _ms(900)),
        HintFrame(row(faded: <int>{byColour}), hold: _ms(1800)),
      ], rest: row(faded: <int>{byColour}));
    }
    final List<HintMark> done = <HintMark>[
      ...row(faded: <int>{byColour, byShape}),
      RingMark(cell(_ci), round: false),
    ];
    return _demo(<HintFrame>[
      HintFrame(row(), hold: _ms(600)),
      HintFrame(<HintMark>[
        ...row(faded: <int>{byColour}),
        HandMark(cell(byColour).center, press: true),
      ], hold: _ms(900)),
      HintFrame(<HintMark>[
        ...row(faded: <int>{byColour, byShape}),
        HandMark(cell(byShape).center, press: true),
      ], hold: _ms(900)),
      HintFrame(<HintMark>[...done, HandMark(cell(_ci).center)], hold: _ms(900)),
      _toAnswer(done),
    ]);
  }
}
