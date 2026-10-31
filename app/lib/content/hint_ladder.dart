// The hint ladder (B-40): what each template draws at each hint level, in one table that the templates, the validator and the
// tests all read. The rule (PLAN.md, curriculum plan section 1): level 1 lights a part of the question, level 2 shows the same
// problem another way or does one step, level 3 is a demonstration whose last step is the answer. Level 1 and level 2 never
// mark the answer.

/// One picture a hint can draw. Part 1 of B-40 builds the first ten of the sets the templates need; the shared pictures of the
/// design spec (P1 to P12) replace some of them later.
enum HintPicture {
  /// The things of the question are lit one after the other, left to right (count, rows); a dot stays on each one visited.
  lightEach('light_each'),

  /// The goal as a numeral with its dots (give N), and the target place lit.
  goalCard('goal_card'),

  /// The same number as two hands (up to ten) or as one or two ten-frames (above ten).
  countingAid('counting_aid'),

  /// The group is shown again, longer (flash).
  lookAgain('look_again'),

  /// Only the first part of the path: where to start and which way (trace).
  firstStroke('first_stroke'),

  /// The whole path, walked by a dot that leaves a trail (trace).
  wholeStroke('whole_stroke'),

  /// Each bin or plate is lit in turn; none stays lit (sort and share).
  eachPlace('each_place'),

  /// The next picture is lit, and the bins are compared one after the other; no bin is chosen (sort).
  nextPicture('next_picture'),

  /// The guide deals one round, one for each friend, and stops (share).
  firstRound('first_round'),

  /// The row, the model or the program is lit in order, ending on the next empty place (patterns, spot the mistake, programs).
  walkTheRow('walk_the_row'),

  /// The same walk, with a step arc between each two neighbours; no cell is picked out (spot the mistake).
  stepArcs('step_arcs'),

  /// The model cell above the next empty place is lit: one to one copying (build a pattern).
  modelCell('model_cell'),

  /// The faces or outlines of the question are lit in turn; none is paired (match, build a shape).
  eachFace('each_face'),

  /// The next empty outline is lit: where to build next, not which piece goes there (build a shape).
  nextOutline('next_outline'),

  /// The first card that is not paired yet is lit: start with this one (match).
  firstFace('first_face'),

  /// The start of the line, its landmarks and the hop size (number line).
  startAndLandmarks('start_and_landmarks'),

  /// The marker hops one unit and stops (number line).
  firstHop('first_hop'),

  /// The robot and the flag are lit (robot).
  robotAndGoal('robot_and_goal'),

  /// The next arrow is lit and a ghost robot takes the one step (robot).
  firstArrow('first_arrow'),

  /// The price and the counter where coins go are lit (shop).
  priceAndCounter('price_and_counter'),

  /// The biggest coin that fits goes on the counter, and the guide stops (shop).
  firstCoin('first_coin'),

  /// The short hand is lit and the long hand fades; a card shows the hour of the question (clock).
  handAndHour('hand_and_hour'),

  /// A dotted link from the card to the same numeral on the dial (clock).
  numeralOnDial('numeral_on_dial'),

  /// Each pan is lit in turn (balance).
  eachPan('each_pan'),

  /// Both pans together, with a level line across the beam (balance).
  levelLine('level_line'),

  /// The parts of the question are lit (and where the stage has none, the options one after the other, none staying lit): look
  /// at them (tap the answer, the families of part 2 of B-40).
  lookHere('look_here'),

  /// The question shown another way, by its family: hands, a number path, a swatch, an outline, pair lines, brackets, numbered
  /// slots. No option is marked (tap the answer).
  anotherWay('another_way'),

  /// The worked example: the guide does the whole thing and the answer is marked as its last step. Level 3 only.
  demonstration('demonstration', marksAnswer: true);

  const HintPicture(this.id, {this.marksAnswer = false});

  /// The name in tests and logs.
  final String id;

  /// The picture picks out the answer (an option, bin, coin, cell or hand) while it is on screen.
  final bool marksAnswer;
}

/// The picture families of `tap_answer` (curriculum plan section 5.1, TA-1 to TA-11), by what the skill asks.
enum TapFamily {
  count,
  numerals,
  sequence,
  compare,
  add,
  colour,
  shapes,
  pattern,
  same,
  time,
  measure,
  clockMoney,
}

/// The family of each skill that uses `tap_answer`: Band A first, then Band B (curriculum plan section 5.1).
const Map<String, TapFamily> _tapFamilyOfSkill = <String, TapFamily>{
  'NUM-A-03': TapFamily.count,
  'NUM-A-04': TapFamily.count,
  'NUM-A-07': TapFamily
      .count, // numeral to set items (a numeral on the stage) belong to TapFamily.numerals, see tapFamilyOf
  'NUM-A-14': TapFamily.count,
  'MATH-A-06': TapFamily.count,
  'CS-A-04': TapFamily.count,
  'NUM-A-08': TapFamily.numerals,
  'NUM-A-01': TapFamily.sequence,
  'NUM-A-02': TapFamily.sequence,
  'NUM-A-13': TapFamily.sequence,
  'NUM-A-11': TapFamily.compare,
  'NUM-A-12': TapFamily.compare,
  'MATH-A-07': TapFamily.compare,
  'MATH-A-01': TapFamily.add,
  'MATH-A-02': TapFamily.add,
  'COL-A-01': TapFamily.colour,
  'COL-A-02': TapFamily.colour,
  'COL-A-03': TapFamily.colour,
  'COL-A-04': TapFamily.colour,
  'COL-A-05': TapFamily.colour,
  'COL-A-06': TapFamily.colour,
  'COL-A-07': TapFamily.colour,
  'SHP-A-01': TapFamily.shapes,
  'SHP-A-02': TapFamily.shapes,
  'SHP-A-03': TapFamily.shapes,
  'SHP-A-04': TapFamily.shapes,
  'SHP-A-05': TapFamily.shapes,
  'SHP-A-07': TapFamily.shapes,
  'SHP-A-08': TapFamily.shapes,
  'SHP-A-10': TapFamily.shapes,
  'LOG-A-04': TapFamily.pattern,
  'LOG-A-06': TapFamily.pattern,
  'LOG-A-07': TapFamily.pattern,
  'LOG-A-10': TapFamily.pattern,
  'LOG-A-01': TapFamily.same,
  'LOG-A-02': TapFamily.same,
  'LOG-A-03': TapFamily.same,
  'LOG-A-09': TapFamily.same,
  'CS-A-01': TapFamily.time,
  'CS-A-05': TapFamily.time,
  'LOG-A-08': TapFamily.time,
  'MATH-A-05': TapFamily.time,
  'MATH-A-04': TapFamily.measure,
  'CS-B-01': TapFamily.count,
  'SHP-B-02': TapFamily.count,
  'NUM-B-08': TapFamily.numerals,
  'NUM-B-01': TapFamily.sequence,
  'NUM-B-02': TapFamily.sequence,
  'NUM-B-03': TapFamily.sequence,
  'NUM-B-11': TapFamily.sequence,
  'NUM-B-17': TapFamily.sequence,
  'NUM-B-10': TapFamily.compare,
  'NUM-B-18': TapFamily.compare,
  'MATH-B-19': TapFamily.compare,
  'MATH-B-01': TapFamily.add,
  'MATH-B-02': TapFamily.add,
  'MATH-B-03': TapFamily.add,
  'MATH-B-06': TapFamily.add,
  'MATH-B-07': TapFamily.add,
  'MATH-B-08': TapFamily.add,
  'MATH-B-10': TapFamily.add,
  'MATH-B-18': TapFamily.add,
  'NUM-B-14': TapFamily.add,
  'NUM-B-16': TapFamily.add,
  'COL-B-01': TapFamily.colour,
  'COL-B-02': TapFamily.colour,
  'COL-B-03': TapFamily.colour,
  'SHP-B-01': TapFamily.shapes,
  'SHP-B-03': TapFamily.shapes,
  'SHP-B-04': TapFamily.shapes,
  'SHP-B-08': TapFamily.shapes,
  'SHP-B-09': TapFamily.shapes,
  'LOG-B-01': TapFamily.pattern,
  'LOG-B-04': TapFamily.pattern,
  'LOG-B-06': TapFamily.same,
  'LOG-B-09': TapFamily.same,
  'MATH-B-14': TapFamily.time,
  'MATH-B-15': TapFamily.clockMoney,
  'MATH-B-16': TapFamily.clockMoney,
};

/// The family of a `tap_answer` activity with skill [skillId] whose stage shows a numeral ([numeralOnStage]) or not: null for a
/// skill that is not in the table.
TapFamily? tapFamilyOf(String skillId, {bool numeralOnStage = false}) {
  if (skillId == 'NUM-A-07' && numeralOnStage) return TapFamily.numerals;
  return _tapFamilyOfSkill[skillId];
}

/// What a template draws at levels 1, 2 and 3.
class HintLadder {
  const HintLadder._(this.pictures);

  final List<HintPicture> pictures;

  /// The picture for [level] (1 to 3); a level beyond the last uses the last.
  HintPicture at(int level) => pictures[(level - 1).clamp(0, pictures.length - 1)];

  static const HintLadder _count = HintLadder._(<HintPicture>[
    HintPicture.lightEach,
    HintPicture.countingAid,
    HintPicture.demonstration,
  ]);

  static const Map<String, HintLadder> _byTemplate = <String, HintLadder>{
    'count_tap': _count,
    'give_n': HintLadder._(<HintPicture>[
      HintPicture.goalCard,
      HintPicture.countingAid,
      HintPicture.demonstration,
    ]),
    'flash': HintLadder._(<HintPicture>[
      HintPicture.lookAgain,
      HintPicture.countingAid,
      HintPicture.demonstration,
    ]),
    'trace': HintLadder._(<HintPicture>[
      HintPicture.firstStroke,
      HintPicture.wholeStroke,
      HintPicture.demonstration,
    ]),
    'sort_drag': HintLadder._(<HintPicture>[
      HintPicture.eachPlace,
      HintPicture.nextPicture,
      HintPicture.demonstration,
    ]),
    'build_pattern': HintLadder._(<HintPicture>[
      HintPicture.walkTheRow,
      HintPicture.modelCell,
      HintPicture.demonstration,
    ]),
    'match_pairs': HintLadder._(<HintPicture>[
      HintPicture.eachFace,
      HintPicture.firstFace,
      HintPicture.demonstration,
    ]),
    'shape_builder': HintLadder._(<HintPicture>[
      HintPicture.eachFace,
      HintPicture.nextOutline,
      HintPicture.demonstration,
    ]),
    'number_line': HintLadder._(<HintPicture>[
      HintPicture.startAndLandmarks,
      HintPicture.firstHop,
      HintPicture.demonstration,
    ]),
    'robot_path': HintLadder._(<HintPicture>[
      HintPicture.robotAndGoal,
      HintPicture.firstArrow,
      HintPicture.demonstration,
    ]),
    'shop_pay': HintLadder._(<HintPicture>[
      HintPicture.priceAndCounter,
      HintPicture.firstCoin,
      HintPicture.demonstration,
    ]),
    'clock_set': HintLadder._(<HintPicture>[
      HintPicture.handAndHour,
      HintPicture.numeralOnDial,
      HintPicture.demonstration,
    ]),
    'balance': HintLadder._(<HintPicture>[
      HintPicture.eachPan,
      HintPicture.levelLine,
      HintPicture.demonstration,
    ]),
    'spot_error': HintLadder._(<HintPicture>[
      HintPicture.walkTheRow,
      HintPicture.stepArcs,
      HintPicture.demonstration,
    ]),
    'tap_answer': _tapFamily,
  };

  /// The share mode of sort and drag deals pictures, so it has its own ladder.
  static const HintLadder _share = HintLadder._(<HintPicture>[
    HintPicture.eachPlace,
    HintPicture.firstRound,
    HintPicture.demonstration,
  ]);

  /// What every family of `tap_answer` draws (B-40 parts 2 and 4): look at the parts of the question, see it another way, watch
  /// the demonstration.
  static const HintLadder _tapFamily = HintLadder._(<HintPicture>[
    HintPicture.lookHere,
    HintPicture.anotherWay,
    HintPicture.demonstration,
  ]);

  /// Every template that has a ladder.
  static Iterable<String> get templates => _byTemplate.keys;

  /// The ladder of [template]; [share] is true for a sort and drag activity in share mode.
  static HintLadder? of(String template, {bool share = false}) =>
      share && template == 'sort_drag' ? _share : _byTemplate[template];

  /// What is wrong with a ladder, or null: level 1 and 2 must not mark the answer, level 3 must be the demonstration, and no level
  /// draws what the level below draws.
  static String? problemWith(String template, {bool share = false}) {
    final HintLadder? l = of(template, share: share);
    if (l == null) return 'the template $template has no hint ladder';
    if (l.pictures.length != 3) return 'the hint ladder of $template needs three levels';
    for (int i = 0; i < 2; i++) {
      if (l.pictures[i].marksAnswer) return 'level ${i + 1} of $template shows the answer';
    }
    if (l.pictures[2] != HintPicture.demonstration) return 'level 3 of $template must be the demonstration';
    for (int i = 1; i < 3; i++) {
      if (l.pictures[i] == l.pictures[i - 1]) return 'level ${i + 1} of $template draws what level $i draws';
    }
    return null;
  }
}
