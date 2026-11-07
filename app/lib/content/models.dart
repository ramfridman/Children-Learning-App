import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' show Offset, Rect;

import '../engine/course.dart';
import '../engine/types.dart' show WritingCue, WritingRule;
import 'pack_verify.dart';
import 'schemas.dart' show coinValues;
import 'strokes.dart';

// Typed views of the documents of a pack that has passed `verifyPack`. The documents were checked
// against the schemas and the cross-file rules, so these classes read them without defending against
// a wrong shape; they are never built from anything that has not been verified.

Map<String, Object?> _map(Object? o) => o! as Map<String, Object?>;

/// A part of a document that may be absent: an empty map when it is.
Map<String, Object?> _maybe(Object? o) => o == null ? const <String, Object?>{} : _map(o);
List<Map<String, Object?>> _maps(Object? o) => <Map<String, Object?>>[
  for (final Object? e in (o as List<Object?>? ?? const <Object?>[])) _map(e),
];

/// The Hebrew of a caption list (exactly one element, `t` is always `he`).
String _caption(Object? o) => _map((o! as List<Object?>).single)['v']! as String;

/// A line to be voiced and shown: the voice id (`vo:…`) and its caption. In a language course a line may also carry a second
/// clip, the target-language clip that follows the Hebrew frame clip ([target]), and a target word to show in a chip under the
/// caption ([show]); never inside it.
class Spoken {
  const Spoken({required this.vo, required this.caption, this.target, this.target2, this.show});

  factory Spoken.fromJson(Object? json) {
    final Map<String, Object?> m = _map(json);
    return Spoken(
      vo: m['vo']! as String,
      caption: _caption(m['caption']),
      target: m['target'] as String?,
      target2: m['target2'] as String?,
      show: m['show'] as String?,
    );
  }

  final String vo;
  final String caption;

  /// A language course: the clip that follows [vo], and a second one after it (a question and its answer, two sounds to compare).
  final String? target;
  final String? target2;
  final String? show;
}

enum HintAction { replayPromptSlow, highlightObjectsSequentially, showFingers, workedExample }

HintAction _hintAction(String s) => switch (s) {
  'replay_prompt_slow' => HintAction.replayPromptSlow,
  'highlight_objects_sequentially' => HintAction.highlightObjectsSequentially,
  'show_fingers' => HintAction.showFingers,
  _ => HintAction.workedExample,
};

class Hint {
  const Hint({required this.level, required this.action, required this.say});

  final int level;
  final HintAction action;
  final Spoken say;
}

/// A rule of `feedback.incorrect`: `when` is `default` or `misconception:<tag>`.
class IncorrectRule {
  const IncorrectRule({required this.tag, required this.say});

  /// Null for the default rule.
  final String? tag;
  final Spoken say;
}

class ActivityFeedback {
  const ActivityFeedback({required this.correct, required this.incorrect, required this.unsure});

  final Spoken correct;
  final List<IncorrectRule> incorrect;
  final Spoken unsure;

  /// The line for a wrong answer carrying [tag] (or none): the rule for that tag, else the default.
  Spoken forIncorrect(String? tag) {
    IncorrectRule? fallback;
    for (final IncorrectRule r in incorrect) {
      if (r.tag == null) {
        fallback = r;
      } else if (r.tag == tag) {
        return r.say;
      }
    }
    return fallback!.say;
  }
}

class Skill {
  const Skill({required this.id, required this.weight});

  final String id;
  final double weight;
}

/// What every activity has, whatever its template.
sealed class Activity {
  Activity._(this.json, this.assets)
    : id = json['id']! as String,
      revision = json['revision']! as int,
      template = json['template']! as String,
      templateVersion = json['templateVersion']! as String,
      course = (json['course'] as String?) ?? Course.core,
      skills = <Skill>[
        for (final Map<String, Object?> s in _maps(json['skills']))
          Skill(id: s['id']! as String, weight: (s['weight']! as num).toDouble()),
      ],
      purpose = json['purpose']! as String,
      checkType = json['checkType']! as String,
      representation = json['representation']! as String,
      variantGroup = json['variantGroup']! as String,
      difficulty = (_map(json['difficulty'])['authored']! as num).toDouble(),
      contradicts = json['contradicts'] as String?,
      voiceAnswer = json['voiceAnswer'] == true,
      promptLine = Spoken.fromJson(json['prompt']),
      feedback = ActivityFeedback(
        correct: Spoken.fromJson(_map(json['feedback'])['correct']),
        incorrect: <IncorrectRule>[
          for (final Map<String, Object?> r in _maps(_map(json['feedback'])['incorrect']))
            IncorrectRule(
              tag: (r['when']! as String) == 'default'
                  ? null
                  : (r['when']! as String).substring('misconception:'.length),
              say: Spoken.fromJson(r),
            ),
        ],
        unsure: Spoken.fromJson(_map(json['feedback'])['unsure']),
      ),
      hints = <Hint>[
        for (final Map<String, Object?> h in _maps(json['hints']))
          Hint(
            level: h['level']! as int,
            action: _hintAction(h['action']! as String),
            say: Spoken.fromJson(h),
          ),
      ],
      maxAttempts = _map(json['scoring'])['maxAttempts']! as int,
      altText = _map(json['a11y'])['altText']! as String;

  factory Activity.fromJson(Map<String, Object?> json, PackAssets assets) => switch (json['template']) {
    'count_tap' => CountTapActivity._(json, assets),
    'tap_answer' => TapAnswerActivity._(json, assets),
    'story' => StoryActivity._(json, assets),
    'listen_do' => ListenDoActivity._(json, assets),
    'sing_along' => SingAlongActivity._(json, assets),
    'puppet_talk' => PuppetTalkActivity._(json, assets),
    'sound_boxes' => SoundBoxesActivity._(json, assets),
    'flash' => FlashActivity._(json, assets),
    'sort_drag' => SortDragActivity._(json, assets),
    'build_pattern' => BuildPatternActivity._(json, assets),
    'robot_path' => RobotPathActivity._(json, assets),
    'shape_builder' => ShapeBuilderActivity._(json, assets),
    'number_line' => NumberLineActivity._(json, assets),
    'balance' => BalanceActivity._(json, assets),
    'spot_error' => SpotErrorActivity._(json, assets),
    'match_pairs' => MatchPairsActivity._(json, assets),
    'shop_pay' => ShopPayActivity._(json, assets),
    'clock_set' => ClockSetActivity._(json, assets),
    'trace' when (json['templateVersion']! as String).startsWith('2.') => LetterWriteActivity._(json, assets),
    'trace' => TraceActivity._(json, assets),
    'say_it' => SayItActivity._(json, assets),
    _ => GiveNActivity._(json, assets),
  };

  final Map<String, Object?> json;
  final PackAssets assets;

  /// May the AI tutor speak in this activity (the author's choice)? Never in a language course: its lines are authored,
  /// and model text in a target language cannot be checked (docs/languages/frame.md section 1.6).
  bool get llmAllowed => course == Course.core && _map(json['tutor'])['llmAllowed'] == true;

  /// The item's text is set in the display face (Secular One) and not in the course's usual one: a transfer check of the same letters in
  /// another face (docs/languages/hebrew/band-a-content.md, A-10.6 and A-11.4). Hebrew only.
  bool get displayFont => json['font'] == 'display';

  /// The activity that forms a balanced pair with this one (a yes and a no: `answer.pairWith`), or null.
  String? get pairWith => _map(json['answer'])['pairWith'] as String?;

  /// A teach screen: shown before a lesson to a route that needs the words, never an item of the engine's catalogue.
  bool get teachScreen => false;

  /// A step that is never scored (a story only heard, a chant, the embodied "done", a personal turn): it writes no attempt of any
  /// kind, not even an "unsure", and the child is offered no help in it (docs/languages/frame.md section 3.3.8 and 5.2).
  bool get unscored => false;

  /// The misconception tags this activity's wrong answers can carry (what the tutor may be asked about).
  List<String> get misconceptionTags => <String>{
    for (final Map<String, Object?> o in _maps(_map(json['answer'])['options']))
      if (o['misconception'] is String) o['misconception']! as String,
    if (_map(json['answer'])['misconception'] is String) _map(json['answer'])['misconception']! as String,
    for (final Map<String, Object?> c in _maps(_map(json['answer'])['classifiers']))
      if (c['misconception'] is String) c['misconception']! as String,
    // The look-alike pairs of the own-name answer: the tag a touch on the look-alike of the child's first letter carries.
    for (final Map<String, Object?> p in _maps(_map(json['answer'])['pairs']))
      if (p['misconception'] is String) p['misconception']! as String,
  }.toList();

  /// What the learning engine needs to know about the activity.
  final String purpose;
  final String checkType;
  final String representation;
  final String variantGroup;
  final double difficulty;
  final String? contradicts;

  /// The child may say the answer (the author's choice, board B-24); without it there is no mic at all.
  final bool voiceAnswer;
  final String id;
  final int revision;
  final String template;
  final String templateVersion;

  /// `core` for every activity that exists today; a language pack's activities carry their language's course.
  final String course;
  bool get isLanguage => Course.isLanguage(course);
  final List<Skill> skills;
  final Spoken promptLine;
  final ActivityFeedback feedback;
  final List<Hint> hints;
  final int maxAttempts;
  final String altText;

  String get skillId => skills.first.id;

  /// How many choices the child has (0 for an open task), and the misconceptions the wrong answers can show.
  int get optionCount;
  Set<String> get engineTags;

  /// The asset reference (`asset:butterfly`) of the scene background, if any.
  String? get background => _map(json['scene'])['background'] as String?;
}

/// Some of a thing, to draw as a group: the set to count in a scene, or an answer that is a set (tap_answer 1.1).
class SpriteSet {
  const SpriteSet({
    required this.sprite,
    required this.count,
    this.arrangement = 'line',
    this.seed = 0,
    this.scale = 1,
  });

  factory SpriteSet.fromJson(Object? json) {
    final Map<String, Object?> m = _map(json);
    return SpriteSet(
      sprite: m['sprite']! as String,
      count: m['count']! as int,
      arrangement: (m['arrangement'] as String?) ?? 'line',
      seed: (m['seed'] as int?) ?? 0,
      scale: ((m['scale'] as num?) ?? 1).toDouble(),
    );
  }

  final String sprite;
  final int count;
  final String arrangement;
  final int seed;
  final double scale;
}

class ChoiceOption {
  const ChoiceOption({
    required this.id,
    this.value,
    this.numeral,
    this.set,
    this.sprite,
    this.label,
    this.misconception,
    this.speech = const <String>[],
    this.text,
    this.clip,
    this.reveal,
    this.zone,
    this.ats = const <Rect>[],
  });

  final String id;

  /// The number a count option shows (`count_tap`).
  final int? value;

  /// A `tap_answer` option that is a numeral (drawn as a number tile), or a set (some of a thing).
  final int? numeral;
  final SpriteSet? set;

  /// The picture of a `tap_answer` option (an `asset:` reference).
  final String? sprite;
  final String? label;
  final String? misconception;

  /// Extra words a child may say for this option (see the `speech` list of the activity file).
  final List<String> speech;

  /// A language course: the text of the tile (in the course's language), the option's own sound (a `vo:` reference), and the
  /// word shown under the picture once the answer is accepted.
  final String? text;
  final String? clip;
  final String? reveal;

  /// Where a touch is this option on a page that shows its text (`picture`, `line1-start`, `word`, `other` ...); null for any other option.
  final String? zone;

  /// Where the option is in the picture of the scene, as shares of its width and height (a part of a body, a thing in a room, a
  /// place to put something): LS11. Several for a part that has more than one place (both ears). Empty for an option that is a tile.
  final List<Rect> ats;

  /// The first place of the option, or null when it has none.
  Rect? get at => ats.isEmpty ? null : ats.first;

  /// A sound button: nothing to see on it, only a sound to hear (LS01 c).
  bool get soundOnly => clip != null && text == null && sprite == null && numeral == null && set == null;
}

List<ChoiceOption> _options(Object? answer) => <ChoiceOption>[
  for (final Map<String, Object?> o in _maps(_map(answer)['options']))
    ChoiceOption(
      id: o['id']! as String,
      value: o['value'] as int?,
      numeral: o['numeral'] as int?,
      set: o['set'] == null ? null : SpriteSet.fromJson(o['set']),
      sprite: o['sprite'] as String?,
      label: o['label'] as String?,
      misconception: o['misconception'] as String?,
      speech: <String>[
        for (final Object? w in (o['speech'] as List<Object?>? ?? const <Object?>[])) w! as String,
      ],
      text: o['text'] as String?,
      clip: o['clip'] as String?,
      reveal: o['reveal'] as String?,
      zone: o['zone'] as String?,
      ats: _rects(o['at']),
    ),
];

/// The places of an option in the picture: one rectangle or a list of them; none when it has none.
List<Rect> _rects(Object? o) {
  if (o == null) return const <Rect>[];
  return <Rect>[
    for (final Object? r in o is List<Object?> ? o : <Object?>[o]) _rect(r)!,
  ];
}

/// A rectangle written `{x, y, w, h}` as shares of the picture it is in, or null when there is none.
Rect? _rect(Object? o) {
  if (o == null) return null;
  final Map<String, Object?> m = _map(o);
  return Rect.fromLTWH(
    (m['x']! as num).toDouble(),
    (m['y']! as num).toDouble(),
    (m['w']! as num).toDouble(),
    (m['h']! as num).toDouble(),
  );
}

/// An activity whose answer is a choice among options, one of them right (`tap_answer`, `count_tap`, `flash` and every template of
/// a language course whose answer is a choice): the lesson controller scores it by option id.
abstract interface class ChoiceActivity {
  List<ChoiceOption> get options;
  String get correctId;
}

/// The modes of LS01 that `tap_answer` 1.4 adds to the plain tap of L1 (docs/design/languages-l5-ls01.md sections 7.7 to 7.9).
enum Ls01TapMode { stem, cloze, tapAll }

/// The answer of a number-entry item (`tap_answer` 1.4, M10 X3): the number, the wrong numbers the author expects with the tag each
/// shows, and the rules that classify any other wrong number (`smaller_from_larger`, `forgot_the_ten`, ...) with their tags.
class NumberAnswer {
  const NumberAnswer({required this.value, required this.expected, required this.rules});

  factory NumberAnswer.fromJson(Map<String, Object?> answer) => NumberAnswer(
    value: answer['value']! as int,
    expected: <int, String>{
      for (final Map<String, Object?> e in _maps(answer['expected']))
        e['value']! as int: e['misconception']! as String,
    },
    rules: <String, String>{
      for (final Map<String, Object?> r in _maps(answer['rules']))
        r['when']! as String: r['misconception']! as String,
    },
  );

  final int value;

  /// A wrong number the author expects, to the tag it shows.
  final Map<int, String> expected;

  /// A rule (`when`) to the tag it is evidence for.
  final Map<String, String> rules;
}

class TapAnswerActivity extends Activity implements ChoiceActivity {
  TapAnswerActivity._(super.json, super.assets)
    : options = _options(json['answer']),
      correctIds = _correctIds(_map(json['answer'])['correct']),
      correctId = _correctIds(_map(json['answer'])['correct']).firstOrNull ?? '',
      all = _map(json['answer'])['all'] == true,
      numberAnswer = _map(json['answer'])['type'] == 'number'
          ? NumberAnswer.fromJson(_map(json['answer']))
          : null,
      picture = _map(json['scene'])['picture'] as Map<String, Object?>?,
      stem = _map(json['scene'])['stem'] == null
          ? null
          : (
              text: _map(_map(json['scene'])['stem'])['text']! as String,
              clip: _map(_map(json['scene'])['stem'])['clip'] as String?,
            ),
      cloze = _map(json['scene'])['cloze'] == null
          ? null
          : (
              text: _map(_map(json['scene'])['cloze'])['text']! as String,
              picture: _map(_map(json['scene'])['cloze'])['picture'] as String?,
            ),
      group = _map(json['scene'])['group'] == null ? null : SpriteSet.fromJson(_map(json['scene'])['group']),
      group2 = _map(json['scene'])['group2'] == null
          ? null
          : SpriteSet.fromJson(_map(json['scene'])['group2']),
      stageNumeral = _map(json['scene'])['numeral'] as int?,
      _tilesFlag = _map(json['scene'])['optionsOnTiles'] == true,
      row = <String>[
        for (final Object? r in (_map(json['scene'])['row'] as List<Object?>? ?? const <Object?>[]))
          r! as String,
      ],
      chart = <({String sprite, int count})>[
        for (final Map<String, Object?> c in _maps(_map(json['scene'])['chart']))
          (sprite: c['sprite']! as String, count: c['count']! as int),
      ],
      super._();

  /// The columns of a chart to read (1.2): each a picture and how many of it; empty when the scene has none.
  final List<({String sprite, int count})> chart;

  @override
  final List<ChoiceOption> options;

  /// The right answer (the first of [correctIds] in a tap-all, whose right answer is a set); empty for a number answer, which has no
  /// options.
  @override
  final String correctId;

  /// Every right option: one, or the set of a tap-all; none for a number answer.
  final List<String> correctIds;

  /// Tap-all (LS01, L5-1): several right cards in one row, each tapped; the item checks itself once as many cards are picked as there are right
  /// ones, and is right when they are exactly the right ones.
  final bool all;

  /// The number the child types (1.4), or null for a choice. The session that draws the keypad comes with the first batch that uses it.
  final NumberAnswer? numberAnswer;

  /// A picture of a number or a measure for the stage (1.4): its `kind` and the fields of that kind (see `stagePictureKinds`), or
  /// null. The sessions draw each kind as the batch that needs it lands.
  final Map<String, Object?>? picture;

  /// A text stem (LS01 d): a written word, unit or letter on the stage, and the clip that "read it to me" plays; null when the item has none.
  final ({String text, String? clip})? stem;

  /// A cloze (LS01 e): a sentence with one gap (`_`), and an optional picture beside it; null when the item has none.
  final ({String text, String? picture})? cloze;

  /// The own-name answer of Hebrew Band A (`answer.type` `name`): the options are not in the pack, they are made on the device from the
  /// child's first name when the lesson opens (`play/name_options.dart`). Until then the item has no face to draw.
  bool get ownName => _map(this.json['answer'])['type'] == 'name';

  /// The LS01 mode this item plays in, or null for the plain tap of L1 (pictures, texts or sounds on tiles).
  Ls01TapMode? get ls01Mode => all
      ? Ls01TapMode.tapAll
      : cloze != null
      ? Ls01TapMode.cloze
      : stem != null
      ? Ls01TapMode.stem
      : null;

  /// The right ids of an `answer.correct`: a string, a list of them (tap-all), or nothing (a number answer).
  static List<String> _correctIds(Object? correct) => correct is List<Object?>
      ? <String>[for (final Object? c in correct) c! as String]
      : <String>[?(correct as String?)];

  /// The item's text tiles are letters (`answer.face` is `letter`): square, large and bold, all alike. Any other item shows its
  /// texts as words, all alike, whatever their length.
  bool get letterFace => _map(this.json['answer'])['face'] == 'letter';

  /// The thing to count or compare, shown above the answers (1.1), and a second one beside it for a comparison.
  final SpriteSet? group;
  final SpriteSet? group2;

  /// A row of pictures (asset references) with `?` for the gap to fill (1.1); empty when the scene has none.
  final List<String> row;

  /// A numeral drawn large on the stage (1.1), or null.
  final int? stageNumeral;

  /// Numerals and sets are answered on tiles below the stage (it is too small for them); pictures stay on the stage. In a language
  /// course a picture the question stands on (a group: the dog of "is it a cat?", the family, the box) has the whole stage and the
  /// pictures that answer are tiles under it (QA-BA-6): sharing the phone's 128-point stage made both a thumbnail.
  bool get optionsInTiles =>
      _tilesFlag ||
      options.any((ChoiceOption o) => o.sprite == null) ||
      (group != null && Course.isLanguage(course));
  final bool _tilesFlag;

  /// The word that appears under the right picture once the answer is accepted (LS01 g), or null when there is none.
  String? get revealedWord {
    for (final ChoiceOption o in options) {
      if (o.id == correctId) return o.reveal;
    }
    return null;
  }

  @override
  int get optionCount => options.length;

  @override
  Set<String> get engineTags => <String>{
    for (final ChoiceOption o in options)
      if (o.misconception != null) o.misconception!,
    ...?numberAnswer?.expected.values,
    ...?numberAnswer?.rules.values,
    for (final Map<String, Object?> p in _maps(_map(this.json['answer'])['pairs']))
      if (p['misconception'] is String) p['misconception']! as String,
  };
}

/// One page of a story: its picture, the clips of its narration, what a screen reader says, and the things in it that say their word
/// when touched.
class StoryPage {
  const StoryPage({
    required this.picture,
    required this.clips,
    required this.alt,
    required this.words,
    this.lines = const <List<({String text, String? clip})>>[],
  });

  final String picture;
  final List<String> clips;
  final String alt;
  final List<({Rect at, String clip})> words;

  /// The text of the page, shown, line by line and word by word, each word with the clip of the voice saying it alone when the story is a
  /// `follow`. Empty for a page that shows only its picture.
  final List<List<({String text, String? clip})>> lines;
}

/// The story template (LS08, docs/languages/frame.md section 2.3): a picture book. In `listen` mode it is heard to its end and is
/// never scored. In `dialogic` mode it stops after the page [pauseAfter] and asks [question], a choice that is scored (the item's
/// `feedback.correct` is the recast), and then goes on to the last page.
class StoryActivity extends Activity implements ChoiceActivity {
  StoryActivity._(super.json, super.assets)
    : pages = <StoryPage>[
        for (final Map<String, Object?> p in _maps(_map(json['scene'])['pages']))
          StoryPage(
            picture: p['picture']! as String,
            clips: <String>[for (final Object? c in p['clips']! as List<Object?>) c! as String],
            alt: p['alt']! as String,
            words: <({Rect at, String clip})>[
              for (final Map<String, Object?> w in _maps(p['words']))
                (at: _rect(w['at'])!, clip: w['clip']! as String),
            ],
            lines: <List<({String text, String? clip})>>[
              for (final Object? line in (p['lines'] as List<Object?>? ?? const <Object?>[]))
                <({String text, String? clip})>[
                  for (final Map<String, Object?> w in _maps(line))
                    (text: w['text']! as String, clip: w['clip'] as String?),
                ],
            ],
          ),
      ],
      mode = _map(json['answer'])['mode'] as String,
      pauseAfter = _map(json['answer'])['pauseAfter'] as int?,
      question = _map(json['answer'])['question'] == null
          ? null
          : Spoken.fromJson(_map(json['answer'])['question']),
      options = _options(json['answer']),
      correctId = (_map(json['answer'])['correct'] as String?) ?? '',
      super._();

  final List<StoryPage> pages;

  /// The page (from 0) after which a dialogic story stops to ask; null for a story that is only heard.
  final int? pauseAfter;

  /// What a dialogic story asks at its pause.
  final Spoken? question;
  @override
  final List<ChoiceOption> options;
  @override
  final String correctId;

  /// `listen`, `dialogic`, or one of the two print-direction modes: `zones` (where does reading start?) and `follow` (touch each word as the
  /// voice reads it), which show the page's text.
  final String mode;

  bool get dialogic => question != null;

  /// A page that shows its text and asks where to touch it (Hebrew Band A, HEB-A-12).
  bool get reads => mode == 'zones' || mode == 'follow';

  @override
  bool get unscored => mode == 'listen';

  @override
  int get optionCount => options.length;

  @override
  Set<String> get engineTags => <String>{
    for (final ChoiceOption o in options)
      if (o.misconception != null) o.misconception!,
  };
}

/// The listen-and-do template (LS11, docs/languages/frame.md section 2.3): the child carries out a command in a scene. In `hotspots`
/// mode the options are the glowing parts of the picture ([ChoiceOption.at]); in `buttons` they are action pictures and the friend
/// does the one chosen; in `drag` they are things that go to [targetAt]; in `place` they are places for [thingAt]'s one thing; in
/// `embodied` mode there is nothing to choose: the child does it and touches "done", and nothing is scored.
class ListenDoActivity extends Activity implements ChoiceActivity {
  ListenDoActivity._(super.json, super.assets)
    : mode = _map(json['answer'])['mode']! as String,
      picture = _map(json['scene'])['picture']! as String,
      targetAt = _rect(_maybe(_map(json['scene'])['target'])['at']),
      targetSprite = _maybe(_map(json['scene'])['target'])['sprite'] as String?,
      thingAt = _rect(_maybe(_map(json['scene'])['thing'])['at']),
      thingSprite = _maybe(_map(json['scene'])['thing'])['sprite'] as String?,
      options = _options(json['answer']),
      correctId = (_map(json['answer'])['correct'] as String?) ?? '',
      super._();

  /// `hotspots`, `buttons`, `drag`, `place` or `embodied`.
  final String mode;

  /// The scene's picture (an `asset:` reference).
  final String picture;

  /// Where a dragged thing is dropped, and its picture if it has one (`drag`).
  final Rect? targetAt;
  final String? targetSprite;

  /// The one thing that is moved, and where it starts (`place`).
  final Rect? thingAt;
  final String? thingSprite;
  @override
  final List<ChoiceOption> options;
  @override
  final String correctId;

  bool get embodied => mode == 'embodied';

  @override
  bool get unscored => embodied;

  @override
  int get optionCount => options.length;

  @override
  Set<String> get engineTags => <String>{
    for (final ChoiceOption o in options)
      if (o.misconception != null) o.misconception!,
  };
}

/// The sing-along template (LS12, docs/languages/frame.md section 2.3): a chant, or a rhyme with a gap. In `chant` mode the [lines] are
/// said one after another and the [pictures] of a line light while it is said; it is practice and writes nothing. In `rhyme` mode the
/// [verse] is heard, stops before its last word, and the child chooses the picture that ends it (scored); then the verse is heard whole.
class SingAlongActivity extends Activity implements ChoiceActivity {
  SingAlongActivity._(super.json, super.assets)
    : mode = _map(json['answer'])['mode']! as String,
      pictures = <({String picture, String label, String? clip})>[
        for (final Map<String, Object?> p in _maps(_map(json['scene'])['pictures']))
          (picture: p['picture']! as String, label: p['label']! as String, clip: p['clip'] as String?),
      ],
      lines = <({List<String> clips, List<int> lights})>[
        for (final Map<String, Object?> l in _maps(_map(json['scene'])['lines']))
          (
            clips: <String>[for (final Object? c in l['clips']! as List<Object?>) c! as String],
            lights: <int>[for (final Object? i in l['lights']! as List<Object?>) i! as int],
          ),
      ],
      verse = _verse(_maybe(_map(json['scene'])['verse'])),
      question = _map(json['answer'])['question'] == null
          ? null
          : Spoken.fromJson(_map(json['answer'])['question']),
      options = _options(json['answer']),
      correctId = (_map(json['answer'])['correct'] as String?) ?? '',
      super._();

  static ({List<String> whole, List<String> open, List<String> full, List<String> cue}) _verse(
    Map<String, Object?> v,
  ) {
    List<String> clips(String k) => <String>[
      for (final Object? c in (v[k] as List<Object?>?) ?? const <Object?>[]) c! as String,
    ];
    return (whole: clips('whole'), open: clips('open'), full: clips('full'), cue: clips('cue'));
  }

  /// `chant` or `rhyme`.
  final String mode;
  final List<({String picture, String label, String? clip})> pictures;
  final List<({List<String> clips, List<int> lights})> lines;
  final ({List<String> whole, List<String> open, List<String> full, List<String> cue}) verse;
  final Spoken? question;
  @override
  final List<ChoiceOption> options;
  @override
  final String correctId;

  bool get rhyme => mode == 'rhyme';

  @override
  bool get unscored => !rhyme;

  @override
  int get optionCount => options.length;

  @override
  Set<String> get engineTags => <String>{
    for (final ChoiceOption o in options)
      if (o.misconception != null) o.misconception!,
  };
}

/// The puppet-talk template (LS10, docs/languages/frame.md section 2.3 and 5.2): a puppet speaks one turn and the child answers. In
/// `bubble` mode the options are answer bubbles, one fits the scene (scored). In `personal` mode there is nothing right: the [topic]
/// (the name, the age, the likes or the family) is answered by touching a card, or [pass] is touched; nothing is written.
class PuppetTalkActivity extends Activity implements ChoiceActivity {
  PuppetTalkActivity._(super.json, super.assets)
    : mode = _map(json['answer'])['mode']! as String,
      picture = _map(json['scene'])['picture']! as String,
      keyAt = _rect(_maybe(_map(json['scene'])['key'])['at']),
      topic = _map(json['answer'])['topic'] as String?,
      pass = _map(json['answer'])['pass'] == null ? null : Spoken.fromJson(_map(json['answer'])['pass']),
      options = _options(json['answer']),
      correctId = (_map(json['answer'])['correct'] as String?) ?? '',
      super._();

  /// `bubble` or `personal`.
  final String mode;

  /// The scene's picture (an `asset:` reference), and the place in it that glows at the second hint.
  final String picture;
  final Rect? keyAt;

  /// The thing a personal turn asks (`name`, `age`, `likes` or `family`), and what the puppet says to a pass.
  final String? topic;
  final Spoken? pass;
  @override
  final List<ChoiceOption> options;
  @override
  final String correctId;

  bool get personal => mode == 'personal';

  @override
  bool get unscored => personal;

  @override
  int get optionCount => personal ? 0 : options.length;

  @override
  Set<String> get engineTags => <String>{
    if (!personal)
      for (final ChoiceOption o in options)
        if (o.misconception != null) o.misconception!,
  };
}

/// The sound-boxes template in drum mode (LS03, docs/languages/frame.md section 2.3): a word is heard with its picture and the child taps
/// a drum once for each part. A free response: a count of [beats] is right; one more and one fewer map to a tag ([moreTag],
/// [fewerTag]); any other count is a retry with no tag.
class SoundBoxesActivity extends Activity {
  SoundBoxesActivity._(super.json, super.assets)
    : picture = _map(json['scene'])['picture']! as String,
      word = <String>[for (final Object? c in _map(json['scene'])['word']! as List<Object?>) c! as String],
      slow = <String>[
        for (final Object? c in (_map(json['scene'])['slow'] as List<Object?>?) ?? const <Object?>[])
          c! as String,
      ],
      drumClip = _map(json['scene'])['drum'] as String?,
      beats = _map(json['answer'])['beats']! as int,
      moreTag = _classified(json, 'one_more'),
      fewerTag = _classified(json, 'one_fewer'),
      super._();

  static String? _classified(Map<String, Object?> json, String when) {
    for (final Map<String, Object?> c in _maps(_map(json['answer'])['classifiers'])) {
      if (c['when'] == when) return c['misconception']! as String;
    }
    return null;
  }

  /// The word's picture (an `asset:` reference), the clips of the word, the same slowly, and the sound of a tap on the drum.
  final String picture;
  final List<String> word;
  final List<String> slow;
  final String? drumClip;

  /// How many parts the word has.
  final int beats;
  final String? moreTag;
  final String? fewerTag;

  /// The tag for a count of [taps], or empty: one more and one fewer are named, any other count is not.
  String tagFor(int taps) =>
      taps == beats + 1 ? (moreTag ?? '') : (taps == beats - 1 ? (fewerTag ?? '') : '');

  @override
  int get optionCount => 0;

  @override
  Set<String> get engineTags => <String>{?moreTag, ?fewerTag};
}

/// A bin of the sort-and-drag template: a picture (or a set of them) that shows the rule, and its name.
class SortBin {
  const SortBin({
    required this.id,
    this.sprite,
    this.text,
    this.clip,
    this.alt,
    required this.count,
    required this.label,
  });

  final String id;

  /// A picture beside the sign at hint level 2 (the other form of the sign), or null.
  final String? alt;

  /// The sign of the bin: a picture (the lands), or in a language course a picture, a text (a letter, a unit, a word), or a sound.
  final String? sprite;
  final String? text;
  final String? clip;

  /// How many of the picture to draw in the bin (a bin that shows its rule with three of them), at least 1.
  final int count;
  final String label;
}

/// A picture to be sorted, and the bin it belongs in (null in share mode, where any bin may be right).
class SortItem {
  const SortItem({
    required this.id,
    this.sprite,
    this.text,
    this.clip,
    this.misconception,
    required this.bin,
    this.label = '',
  });

  final String id;

  /// A picture (the lands), or in a language course a picture, a text, or only a sound (a sound card).
  final String? sprite;
  final String? text;
  final String? clip;

  /// The tag of the misconception that putting this card in a wrong bin shows (a language course; the item's own tag otherwise).
  final String? misconception;
  final String? bin;
  final String label;
}

/// The sort-and-drag template (T03): pictures go into bins by touch or by drag; in `share` mode they are dealt between
/// two friends until both have the same.
class SortDragActivity extends Activity {
  SortDragActivity._(super.json, super.assets)
    : bins = <SortBin>[
        for (final Map<String, Object?> b in _maps(_map(json['scene'])['bins']))
          SortBin(
            id: b['id']! as String,
            sprite: b['sprite'] as String?,
            text: b['text'] as String?,
            clip: b['clip'] as String?,
            alt: b['alt'] as String?,
            count: (b['count'] as int?) ?? 1,
            label: b['label']! as String,
          ),
      ],
      items = <SortItem>[
        for (final Map<String, Object?> i in _maps(_map(json['scene'])['items']))
          SortItem(
            id: i['id']! as String,
            sprite: i['sprite'] as String?,
            text: i['text'] as String?,
            clip: i['clip'] as String?,
            misconception: i['misconception'] as String?,
            bin: i['bin'] as String?,
            label: (i['label'] as String?) ?? '',
          ),
      ],
      share = _map(json['answer'])['mode'] == 'share',
      wrongTag = _map(json['answer'])['misconception'] as String?,
      super._();

  final List<SortBin> bins;
  final List<SortItem> items;

  /// Share mode: the answer is right when every bin holds the same number.
  final bool share;
  final String? wrongTag;

  @override
  int get optionCount => 0;

  @override
  Set<String> get engineTags => <String>{?wrongTag, for (final SortItem i in items) ?i.misconception};
}

/// The build-a-pattern template (T05): fill the places from a palette.
class BuildPatternActivity extends Activity {
  BuildPatternActivity._(super.json, super.assets)
    : model = <String>[
        for (final Object? m in (_map(json['scene'])['model'] as List<Object?>? ?? const <Object?>[]))
          m! as String,
      ],
      slots = _map(json['scene'])['slots']! as int,
      palette = <String>[
        for (final Object? p in _map(json['scene'])['palette']! as List<Object?>) p! as String,
      ],
      sequence = <String>[
        for (final Object? s in (_map(json['answer'])['sequence'] as List<Object?>? ?? const <Object?>[]))
          s! as String,
      ],
      order = <int>[
        for (final Object? o in (_map(json['answer'])['order'] as List<Object?>? ?? const <Object?>[]))
          o! as int,
      ],
      clips = <String>[
        for (final Object? c in (_map(json['scene'])['clips'] as List<Object?>? ?? const <Object?>[]))
          c! as String,
      ],
      wrongTag = _map(json['answer'])['misconception'] as String?,
      super._();

  /// The pattern to copy (may be empty), the number of places, the pictures to choose from and the right order.
  /// A face is `asset:id` (a picture) or, in a language course, `txt:` and a letter, a unit or a word (LS01 order tiles).
  final List<String> model;
  final int slots;
  final List<String> palette;
  final List<String> sequence;

  /// A sequence (LS01 f, the story line of a language course): the picture indexes of [palette], which stands in a shuffled order, in the
  /// right order of the story. Empty for every other item.
  final List<int> order;
  bool get isSequence => order.isNotEmpty;

  /// A story line: the line of each picture as a clip, in the order of [palette] (hint level 1 plays them as it lights the pictures).
  final List<String> clips;
  final String? wrongTag;

  @override
  int get optionCount => 0;

  @override
  Set<String> get engineTags => <String>{?wrongTag};
}

/// The number-line template (T09): put a marker on a number, or say where it lands after its hops.
class NumberLineActivity extends Activity {
  NumberLineActivity._(super.json, super.assets)
    : from = _map(json['scene'])['from']! as int,
      to = _map(json['scene'])['to']! as int,
      markerSprite = _map(json['scene'])['markerSprite']! as String,
      start = _map(json['scene'])['start'] as int?,
      hops = <int>[
        for (final Object? h in (_map(json['scene'])['hops'] as List<Object?>? ?? const <Object?>[]))
          h! as int,
      ],
      labels = <int>[for (final Object? l in _map(json['scene'])['labels']! as List<Object?>) l! as int],
      jump = _map(json['answer'])['mode'] == 'jump',
      target = _map(json['answer'])['target']! as int,
      wrongTag = _map(json['answer'])['misconception'] as String?,
      mirrorTag = _map(json['answer'])['mirrorMisconception'] as String?,
      super._();

  final int from;
  final int to;
  final String markerSprite;

  /// Where the marker starts (a jump), or null (the marker is put on the line by the child).
  final int? start;

  /// By how much each hop goes (negative: to the left).
  final List<int> hops;

  /// The numbers that have a written numeral under their tick.
  final List<int> labels;
  final bool jump;
  final int target;
  final String? wrongTag;

  /// The tag for the mirror of the right answer: the child who runs the line from right to left.
  final String? mirrorTag;

  @override
  int get optionCount => 0;

  @override
  Set<String> get engineTags => <String>{?wrongTag, ?mirrorTag};
}

/// One kind of thing on a pan of a balance, how many there are and what one weighs (in blocks).
class PanGroup {
  const PanGroup({required this.sprite, required this.count, required this.weight});

  final String sprite;
  final int count;
  final int weight;
}

/// The balance template (T08): compare two pans (which is heavier, or are they the same), or add blocks until it is level.
class BalanceActivity extends Activity {
  BalanceActivity._(super.json, super.assets)
    : left = _pan(_map(json['scene'])['left']),
      right = _pan(_map(json['scene'])['right']),
      blockSprite = _map(json['scene'])['blockSprite'] as String?,
      hideTilt = _map(json['scene'])['hideTilt'] == true,
      weigh = _map(json['answer'])['mode'] == 'balance',
      result = _map(json['answer'])['result']! as String,
      wrongTag = _map(json['answer'])['misconception'] as String?,
      super._();

  static List<PanGroup> _pan(Object? pan) => <PanGroup>[
    for (final Map<String, Object?> g in _maps(_map(pan)['groups']))
      PanGroup(sprite: g['sprite']! as String, count: g['count']! as int, weight: (g['weight'] as int?) ?? 1),
  ];

  final List<PanGroup> left;
  final List<PanGroup> right;
  final String? blockSprite;
  final bool hideTilt;

  /// `balance` mode: add blocks to the right pan until the scale is level.
  final bool weigh;

  /// `left`, `right` or `same` (compare), or the number of blocks to add (balance).
  final String result;
  final String? wrongTag;

  static int weightOf(List<PanGroup> pan) =>
      pan.fold<int>(0, (int sum, PanGroup g) => sum + g.count * g.weight);

  @override
  int get optionCount => 0;

  @override
  Set<String> get engineTags => <String>{?wrongTag};
}

/// The spot-the-mistake template (T21): a row made by a friend with one mistake in it; the child touches the mistake.
class SpotErrorActivity extends Activity {
  SpotErrorActivity._(super.json, super.assets)
    : cells = <String>[for (final Object? c in _map(json['scene'])['cells']! as List<Object?>) c! as String],
      model = _map(json['scene'])['model'] == null
          ? null
          : (
              sprite: _map(_map(json['scene'])['model'])['sprite']! as String,
              clip: _map(_map(json['scene'])['model'])['clip'] as String?,
              spelling: <String>[
                for (final Object? c
                    in (_map(_map(json['scene'])['model'])['spelling'] as List<Object?>?) ??
                        const <Object?>[])
                  c! as String,
              ],
            ),
      wrong = _map(json['answer'])['wrong']! as int,
      wrongTag = _map(json['answer'])['misconception'] as String?,
      super._();

  /// Each cell is `asset:id`, `n:7`, `dir:up`, `op:+` or, in a language course, `txt:` and a letter, a unit or a word.
  final List<String> cells;

  /// A language course: the picture (and its word, heard on a touch) the cells are to match; null in the lands.
  final ({String sprite, String? clip, List<String> spelling})? model;

  /// The index of the cell that is wrong.
  final int wrong;
  final String? wrongTag;

  @override
  int get optionCount => 0;

  @override
  Set<String> get engineTags => <String>{?wrongTag};
}

/// A face on the matching template: a picture (a set, when [count] is more than one) or a numeral.
class MatchFace {
  const MatchFace({
    required this.id,
    required this.label,
    this.sprite,
    this.count = 1,
    this.numeral,
    this.coin,
    this.text,
    this.clip,
    this.alt,
    this.misconception,
  });

  factory MatchFace.fromJson(Map<String, Object?> m) => MatchFace(
    id: m['id']! as String,
    label: m['label']! as String,
    sprite: m['sprite'] as String?,
    count: (m['count'] as int?) ?? 1,
    numeral: m['numeral'] as int?,
    coin: m['coin'] as String?,
    text: m['text'] as String?,
    clip: m['clip'] as String?,
    alt: m['alt'] as String?,
    misconception: m['misconception'] as String?,
  );

  final String id;
  final String label;

  /// A picture beside the face at hint level 2 (the other form of the face), or null.
  final String? alt;

  /// A language course: a face may be a text (a letter, a unit, a word), or only a sound (a sound card), as well as a picture.
  final String? text;
  final String? clip;

  /// The tag of the misconception that choosing this face as a partner of a wrong one shows (a face of the bottom row).
  final String? misconception;
  final String? sprite;
  final int count;
  final int? numeral;

  /// A coin or note kind of the shop (`s2`, `n20`), drawn with its value.
  final String? coin;
}

/// The matching template (T16): pairs of faces, one row above and one below; the child joins each pair.
class MatchPairsActivity extends Activity {
  MatchPairsActivity._(super.json, super.assets)
    : left = <MatchFace>[
        for (final Map<String, Object?> f in _maps(_map(json['scene'])['left'])) MatchFace.fromJson(f),
      ],
      right = <MatchFace>[
        for (final Map<String, Object?> f in _maps(_map(json['scene'])['right'])) MatchFace.fromJson(f),
      ],
      pairs = <String, String>{
        for (final Map<String, Object?> p in _maps(_map(json['answer'])['pairs']))
          p['left']! as String: p['right']! as String,
      },
      wrongTag = _map(json['answer'])['misconception'] as String?,
      super._();

  final List<MatchFace> left;
  final List<MatchFace> right;

  /// Left face id -> the right face id that goes with it.
  final Map<String, String> pairs;
  final String? wrongTag;

  @override
  int get optionCount => 0;

  @override
  Set<String> get engineTags => <String>{?wrongTag, for (final MatchFace f in right) ?f.misconception};
}

/// A kind of coin or note in the purse and how many of it there are.
class PurseItem {
  const PurseItem(this.kind, this.count);

  final String kind;
  final int count;
  int get value => coinValues[kind]!;
}

/// The shop template (T17): pay a price with the coins of the purse.
class ShopPayActivity extends Activity {
  ShopPayActivity._(super.json, super.assets)
    : itemSprite = _map(json['scene'])['itemSprite']! as String,
      itemCount = _map(json['scene'])['itemCount']! as int,
      price = _map(json['scene'])['price']! as int,
      purse = <PurseItem>[
        for (final Map<String, Object?> p in _maps(_map(json['scene'])['purse']))
          PurseItem(p['kind']! as String, p['count']! as int),
      ],
      wrongTag = _map(json['answer'])['misconception'] as String?,
      countTag = _map(json['answer'])['countMisconception'] as String?,
      super._();

  final String itemSprite;
  final int itemCount;

  /// The price in agorot.
  final int price;
  final List<PurseItem> purse;
  final String? wrongTag;
  final String? countTag;

  @override
  int get optionCount => 0;

  @override
  Set<String> get engineTags => <String>{?wrongTag, ?countTag};
}

/// The clock template (T18): set the hands to a time.
class ClockSetActivity extends Activity {
  ClockSetActivity._(super.json, super.assets)
    : hour = _map(json['scene'])['hour']! as int,
      minute = _map(json['scene'])['minute']! as int,
      startHour = _map(json['scene'])['startHour']! as int,
      startHalf = _map(json['scene'])['startHalf'] == true,
      wrongTag = _map(json['answer'])['misconception'] as String?,
      handsTag = _map(json['answer'])['handsMisconception'] as String?,
      super._();

  final int hour;

  /// 0 for a whole hour, 30 for half past.
  final int minute;
  final int startHour;
  final bool startHalf;
  final String? wrongTag;
  final String? handsTag;

  bool get half => minute == 30;

  @override
  int get optionCount => 0;

  @override
  Set<String> get engineTags => <String>{?wrongTag, ?handsTag};
}

/// The tracing template (T04): follow a path with a finger.
class TraceActivity extends Activity {
  TraceActivity._(super.json, super.assets)
    : strokes = <List<Offset>>[
        for (final Object? s in _map(json['scene'])['strokes']! as List<Object?>)
          <Offset>[
            for (final Object? p in s! as List<Object?>)
              Offset(
                ((p! as List<Object?>)[0]! as num).toDouble(),
                ((p as List<Object?>)[1]! as num).toDouble(),
              ),
          ],
      ],
      fullGuide = _map(json['scene'])['guide'] == 'full',
      tolerance = (_map(json['scene'])['tolerance']! as num).toDouble(),
      wrongTag = _map(json['answer'])['misconception'] as String?,
      directionTag = _map(json['answer'])['directionMisconception'] as String?,
      super._();

  /// Each stroke is a list of points in a 100 by 100 box, from where it starts to where it ends.
  final List<List<Offset>> strokes;

  /// The whole dotted path is drawn (otherwise only the starting dot and the first direction).
  final bool fullGuide;

  /// How far from the path a finger may be, in the same 100 by 100 units.
  final double tolerance;
  final String? wrongTag;
  final String? directionTag;

  @override
  int get optionCount => 0;

  @override
  Set<String> get engineTags => <String>{?wrongTag, ?directionTag};
}

/// The modes of LS02, write a letter (docs/languages/writing-mastery.md section 3).
enum LetterMode { intro, trace, copy, memory }

LetterMode _letterMode(String s) => switch (s) {
  'intro' => LetterMode.intro,
  'copy' => LetterMode.copy,
  'memory' => LetterMode.memory,
  _ => LetterMode.trace,
};

/// The worked example of a letter (the `intro` mode): its sound, shown with a key word and a picture, and its name as a separate fact.
class LetterIntro {
  const LetterIntro({required this.sound, required this.name, this.keyword, this.picture});

  factory LetterIntro.fromJson(Map<String, Object?> json) => LetterIntro(
    sound: json['sound']! as String,
    name: json['name']! as String,
    keyword: json['keyword'] as String?,
    picture: json['picture'] as String?,
  );

  final String sound;
  final String name;
  final String? keyword;

  /// An `asset:` reference.
  final String? picture;
}

/// LS02 write a letter (`trace` 2.0, docs/milestones/L5.md section 5.2): the worked example of a letter, then trace it, copy it, and write
/// it from memory, on a canvas of one letter or of a word. The letters are forms of the stroke set of the course's script; their strokes
/// are read from the pack's stroke document, never from the activity. Free response: nothing is a fixed option, and an error the
/// free-stroke check can name maps to a tag of [classify], while any other miss is a retry that writes nothing.
class LetterWriteActivity extends Activity {
  LetterWriteActivity._(super.json, super.assets)
    : mode = _letterMode(_map(json['scene'])['mode']! as String),
      word = _map(json['scene'])['canvas'] == 'word',
      forms = _strings(_map(json['scene'])['forms']),
      ownName = _map(json['scene'])['source'] == 'own_name',
      fullGuide = _map(json['scene'])['guide'] == 'full',
      modelHidden = _map(json['scene'])['model'] == 'hide',
      cue = switch (_map(json['scene'])['cue']) {
        'sound' => WritingCue.sound,
        'name' => WritingCue.name,
        _ => null,
      },
      intro = _map(json['scene'])['intro'] == null
          ? null
          : LetterIntro.fromJson(_map(_map(json['scene'])['intro'])),
      practiceOnly = _map(json['scene'])['practice'] == true,
      classify = <String, String>{
        for (final String k in const <String>['start', 'direction', 'lines', 'mirror'])
          if (_maybe(_map(json['answer'])['classify'])[k] is String)
            k: _maybe(_map(json['answer'])['classify'])[k]! as String,
      },
      partners = <String, String>{
        for (final MapEntry<String, Object?> p in _maybe(
          _maybe(_map(json['answer'])['classify'])['partners'],
        ).entries)
          p.key: p.value! as String,
      },
      super._();

  final LetterMode mode;

  /// A canvas of a word: a row of boxes in the course's direction. Otherwise one box with one letter.
  final bool word;

  /// The form ids to write: one for a letter canvas, two to six for a word.
  final List<String> forms;

  /// The letters come from the child's own name (heb B-27); [forms] is the fallback word when no name is set.
  final bool ownName;

  /// trace: the whole dotted path (otherwise only the start dot and the first direction).
  final bool fullGuide;

  /// copy: the model is shown and then covered (otherwise it stays beside the box).
  final bool modelHidden;

  /// memory: what the voice says (its clip is the prompt's target).
  final WritingCue? cue;

  /// intro: the sound, the key word and the name to say.
  final LetterIntro? intro;

  /// A handwriting step that is only practice, whatever skill it names.
  final bool practiceOnly;

  /// The tag of each error the free-stroke check can name: `start`, `direction`, `lines`, `mirror`.
  final Map<String, String> classify;

  /// A look-alike form the child may write instead (form id) and the tag of that mix-up.
  final Map<String, String> partners;

  /// The tracing of a letter with only its start dot: a success there marks the letter as practised (E-1).
  bool get startGuide => mode == LetterMode.trace && !fullGuide && !word;

  @override
  bool get unscored => mode == LetterMode.intro;

  @override
  int get optionCount => 0;

  @override
  Set<String> get engineTags => <String>{...classify.values, ...partners.values};
}

/// A place of the shape builder: the shape that belongs there, where it stands in the picture (shares of its width and height)
/// and how it is turned.
class ShapeSlot {
  const ShapeSlot({
    required this.id,
    required this.sprite,
    required this.x,
    required this.y,
    required this.w,
    required this.h,
    required this.rot,
  });

  final String id;
  final String sprite;
  final double x;
  final double y;
  final double w;
  final double h;

  /// Degrees, clockwise.
  final int rot;
}

/// The shape-builder template (T10): a picture made of shapes, shown as silhouettes, to be filled with the shapes.
class ShapeBuilderActivity extends Activity {
  ShapeBuilderActivity._(super.json, super.assets)
    : aspect = (_map(json['scene'])['aspect']! as num).toDouble(),
      slots = <ShapeSlot>[
        for (final Map<String, Object?> s in _maps(_map(json['scene'])['slots']))
          ShapeSlot(
            id: s['id']! as String,
            sprite: s['sprite']! as String,
            x: (s['x']! as num).toDouble(),
            y: (s['y']! as num).toDouble(),
            w: (s['w']! as num).toDouble(),
            h: (s['h']! as num).toDouble(),
            rot: (s['rot'] as int?) ?? 0,
          ),
      ],
      decoys = <String>[
        for (final Object? d in (_map(json['scene'])['decoys'] as List<Object?>? ?? const <Object?>[]))
          d! as String,
      ],
      wrongTag = _map(json['answer'])['misconception'] as String?,
      super._();

  final double aspect;
  final List<ShapeSlot> slots;
  final List<String> decoys;
  final String? wrongTag;

  /// The shapes in the tray, as asset references: one for each place and the decoys, in a fixed mixed order.
  List<String> get pieces {
    final List<String> all = <String>[for (final ShapeSlot s in slots) s.sprite, ...decoys];
    final List<int> order = List<int>.generate(all.length, (int i) => i)
      ..sort((int a, int b) => ((a * 5 + 2) % all.length).compareTo((b * 5 + 2) % all.length));
    return <String>[for (final int i in order) all[i]];
  }

  @override
  int get optionCount => 0;

  @override
  Set<String> get engineTags => <String>{?wrongTag};
}

/// The robot-path template (T07): move a robot to the flag with arrows, directly or by planning the steps first.
class RobotPathActivity extends Activity {
  RobotPathActivity._(super.json, super.assets)
    : cols = _map(json['scene'])['cols']! as int,
      rows = _map(json['scene'])['rows']! as int,
      robotAt = (
        _map(_map(json['scene'])['robot'])['col']! as int,
        _map(_map(json['scene'])['robot'])['row']! as int,
      ),
      goalAt = (
        _map(_map(json['scene'])['goal'])['col']! as int,
        _map(_map(json['scene'])['goal'])['row']! as int,
      ),
      robotSprite = _map(json['scene'])['robotSprite']! as String,
      goalSprite = _map(json['scene'])['goalSprite']! as String,
      plan = _map(json['answer'])['mode'] == 'plan',
      maxSteps = _map(json['answer'])['maxSteps']! as int,
      solution = <String>[
        for (final Object? s in _map(json['answer'])['solution']! as List<Object?>) s! as String,
      ],
      wrongTag = _map(json['answer'])['misconception'] as String?,
      super._();

  final int cols;
  final int rows;

  /// Start and goal as (column, row), counted from the top left of the screen.
  final (int, int) robotAt;
  final (int, int) goalAt;
  final String robotSprite;
  final String goalSprite;

  /// Plan mode: the steps are planned, then run with the go button. Direct mode: every arrow moves the robot at once.
  final bool plan;
  final int maxSteps;

  /// One shortest way, as `up`, `down`, `left`, `right`, for the help.
  final List<String> solution;
  final String? wrongTag;

  @override
  int get optionCount => 0;

  @override
  Set<String> get engineTags => <String>{?wrongTag};
}

/// The flash template (T14): a group is shown for [flashMs] and covered, and the child picks how many.
class FlashActivity extends Activity implements ChoiceActivity {
  FlashActivity._(super.json, super.assets)
    : options = _options(json['answer']),
      correctId = _map(json['answer'])['correct']! as String,
      group = SpriteSet.fromJson(_map(json['scene'])['group']),
      flashMs = _map(json['scene'])['flashMs']! as int,
      super._();

  @override
  final List<ChoiceOption> options;
  @override
  final String correctId;
  final SpriteSet group;
  final int flashMs;

  @override
  int get optionCount => options.length;

  @override
  Set<String> get engineTags => <String>{
    for (final ChoiceOption o in options)
      if (o.misconception != null) o.misconception!,
  };
}

/// LS09 say it with me (docs/languages/frame.md section 2.3): a picture and a word. The voice says the word; the child may say it
/// (a say step, the per-word matcher answers confident or unsure); a tap on the picture goes on, and counts as a listening answer
/// when [scored]. There is nothing to get wrong, so there are no options.
class SayItActivity extends Activity {
  SayItActivity._(super.json, super.assets)
    : picture = _map(_map(json['scene'])['picture'])['sprite']! as String,
      forms = _strings(_map(json['say'])['forms']),
      foils = _strings(_map(json['say'])['foils']),
      keyWords = _strings(_map(json['say'])['keyWords']),
      wordClip = _map(json['say'])['clip']! as String,
      heard = Spoken.fromJson(_map(json['say'])['heard']),
      together = Spoken.fromJson(_map(json['say'])['together']),
      scored = _map(json['answer'])['scored'] == true,
      teach = _map(json['answer'])['teach'] == true,
      hear = _map(json['answer'])['hear'] == true,
      order = <String, String>{
        for (final MapEntry<String, Object?> e in _maybe(_map(json['say'])['order']).entries)
          e.key: e.value! as String,
      },
      pictureFirstLine = _map(json['say'])['pictureFirst'] == null
          ? null
          : Spoken.fromJson(_map(json['say'])['pictureFirst']),
      super._();

  /// A teach screen (`answer.teach`): the word is shown and said twice, the child may say it with the voice. It is never scored, writes no
  /// attempt, has no microphone and no help (nothing can be got wrong), and the engine does not see it.
  final bool teach;

  /// A hearing screen (`answer.hear`, always a teach screen too): the line and the word once, no microphone, no "I said it", the word again
  /// whenever the child touches the replay button; the picture shows once the word has been said. It writes nothing either.
  final bool hear;

  /// The order the step is played in on each route (`echo`: the model first, then the child; `picture`: the question first, the model after
  /// a pause), by route name; empty for a step that has no routes (a course that has none, a teach or hearing screen).
  final Map<String, String> order;

  /// The line that asks the child to say the word before it is heard (no clip after it), or null.
  final Spoken? pictureFirstLine;

  /// Whether the child is asked for the word before it is heard on [route] (a route not set counts as a new learner). [echoOnly] is the
  /// visit's quiet fallback (too many unsure turns): the rest of the visit is echo, silently. A teach or hearing screen is always echo.
  bool picturesFirst(String? route, {bool echoOnly = false}) =>
      !teach && !echoOnly && pictureFirstLine != null && order[route ?? 'new'] == 'picture';

  /// The picture (an `asset:` reference).
  final String picture;

  /// The target and the forms its teacher lists; the foils; for a chunk the key words that must each be heard.
  final List<String> forms;
  final List<String> foils;
  final List<String> keyWords;

  /// The voice line of the word itself.
  final String wordClip;

  /// "I heard:" and "let's say it together"; the word follows each as its own target clip.
  final Spoken heard;
  final Spoken together;

  /// The tap on the picture is a scored listening answer.
  final bool scored;

  @override
  bool get unscored => teach;

  @override
  bool get teachScreen => teach;

  @override
  int get optionCount => 0;

  @override
  Set<String> get engineTags => const <String>{};
}

List<String> _strings(Object? o) => <String>[
  for (final Object? e in (o as List<Object?>? ?? const <Object?>[])) e! as String,
];

class CountTapActivity extends Activity implements ChoiceActivity {
  CountTapActivity._(super.json, super.assets)
    : options = _options(json['answer']),
      correctId = _map(json['answer'])['correct']! as String,
      count = _map(_map(_map(json['scene'])['objects']))['count']! as int,
      arrangement = _map(_map(json['scene'])['objects'])['arrangement']! as String,
      onTap = _map(_map(json['scene'])['objects'])['onTap']! as String,
      seed = _map(_map(json['scene'])['objects'])['seed']! as int,
      sprite = _map(_map(json['scene'])['objects'])['sprite']! as String,
      litSprite = _map(_map(json['scene'])['objects'])['litSprite']! as String,
      clips = <String>[
        for (final Object? c
            in (_map(_map(json['scene'])['objects'])['clips'] as List<Object?>? ?? const <Object?>[]))
          c! as String,
      ],
      targetSprite = _map(_map(json['scene'])['target'])['sprite']! as String,
      answerPrompt = Spoken.fromJson(json['answerPrompt']),
      traceTags = <String, String>{
        for (final Map<String, Object?> c in _maps(json['traceClassifiers']))
          c['when']! as String: c['misconception']! as String,
      },
      super._();

  @override
  final List<ChoiceOption> options;
  @override
  final String correctId;
  final int count;

  /// `line` or `scatter`.
  final String arrangement;

  /// `fly_to_target` or `glow`.
  final String onTap;
  final int seed;
  final String sprite;
  final String litSprite;
  final String targetSprite;

  /// A language course: the number word each counting tap plays, in counting order (practice, never scored).
  final List<String> clips;

  /// Asked once every object has been counted: "how many?".
  final Spoken answerPrompt;

  /// `same_object_tapped_twice` and `object_never_tapped` to the tag each one is evidence for.
  final Map<String, String> traceTags;

  @override
  int get optionCount => options.length;

  @override
  Set<String> get engineTags => <String>{
    for (final ChoiceOption o in options)
      if (o.misconception != null) o.misconception!,
    ...traceTags.values,
  };
}

class GiveNActivity extends Activity {
  GiveNActivity._(super.json, super.assets)
    : n = _map(json['answer'])['n']! as int,
      sourceCount = _map(_map(_map(json['scene'])['source']))['count']! as int,
      sourceSprite = _map(_map(json['scene'])['source'])['sprite']! as String,
      targetSprite = _map(_map(json['scene'])['target'])['sprite']! as String,
      classifiers = <String, String>{
        for (final Map<String, Object?> c in _maps(_map(json['answer'])['classifiers']))
          c['when']! as String: c['misconception']! as String,
      },
      super._();

  /// How many the child must give.
  final int n;
  final int sourceCount;
  final String sourceSprite;
  final String targetSprite;

  /// `took_all`, `took_more` or `took_fewer` to the tag each one is evidence for.
  final Map<String, String> classifiers;

  @override
  int get optionCount => 0;

  @override
  Set<String> get engineTags => classifiers.values.toSet();
}

class Lesson {
  Lesson._(Map<String, Object?> json)
    : id = json['id']! as String,
      revision = json['revision']! as int,
      course = (json['course'] as String?) ?? Course.core,
      title = _caption(json['title']),
      itemIds = <String>[for (final Object? i in json['items']! as List<Object?>) i! as String],
      skillIds = <String>[for (final Object? s in json['skills']! as List<Object?>) s! as String],
      sequence = (json['sequence'] as int?) ?? 1000,
      teach = <TeachSet>[
        for (final Map<String, Object?> t in _maps(json['teach']))
          TeachSet(
            itemIds: <String>[for (final Object? i in t['items']! as List<Object?>) i! as String],
            routes: <String>{for (final Object? r in t['routes']! as List<Object?>) r! as String},
            hear: t['mode'] == 'hear',
          ),
      ],
      stopAfterStruggles = 0,
      celebration = Spoken.fromJson(json['celebration']);

  /// A short lesson made on the spot for one skill's revisit (M8): the bell flag on the map. It is not in any pack.
  Lesson.mission({
    required this.id,
    required this.itemIds,
    required this.skillIds,
    required this.celebration,
    this.stopAfterStruggles = 0,
  }) : revision = 1,
       sequence = 1000,
       teach = const <TeachSet>[],
       course = skillIds.isEmpty ? Course.core : Course.ofSkillId(skillIds.first),
       title = '';

  final String id;
  final int revision;
  final String course;
  final String title;
  final List<String> itemIds;
  final List<String> skillIds;

  /// Where the lesson sits on the path of its land (smaller comes first); 1000 for a lesson that has no place.
  final int sequence;

  /// The teach screens that come before the lesson's items, each set for the routes that are shown it (see [PackContent.itemsFor]).
  final List<TeachSet> teach;

  /// A lesson that ends gently, with its celebration, once the child has needed the full help on this many activities in a
  /// row (the placement warm-up: it must never become a string of failures). 0 means it never stops early.
  final int stopAfterStruggles;
  final Spoken celebration;
}

/// A set of screens to be shown before a lesson asks its words, in order, and the routes of a language course that are shown them: the
/// teach screens of new words (LS09, echo) for a new learner, or, when [hear], the hearing screens of words a heritage speaker is to hear
/// once before they are asked. A heritage speaker already knows the words and is never shown a teach screen.
class TeachSet {
  const TeachSet({required this.itemIds, required this.routes, this.hear = false});

  final List<String> itemIds;
  final Set<String> routes;

  /// A set of hearing screens (`mode` `hear`), not of teach screens.
  final bool hear;
}

/// A skill of the pack, for the learning engine.
class SkillDoc {
  SkillDoc._(Map<String, Object?> json)
    : id = json['id']! as String,
      course = (json['course'] as String?) ?? Course.core,
      domain = json['domain']! as String,
      title = _caption(json['title']),
      prerequisites = <String, double>{
        for (final Map<String, Object?> p in _maps(json['prerequisites']))
          p['skill']! as String: (p['weight']! as num).toDouble(),
      },
      representations = <String>[
        for (final Object? r in json['representations']! as List<Object?>) r! as String,
      ],
      misconceptions = <String>[
        for (final Object? t in json['misconceptions']! as List<Object?>) t! as String,
      ],
      worldObject = json['worldObject'] as String?,
      childLine = json['childLine'] == null ? null : _caption(json['childLine']),
      core = (json['core'] as bool?) ?? false,
      bundle = json['bundle'] as String?,
      setCoverage = (json['setCoverage'] as bool?) ?? false,
      soundRight = (json['soundRight'] as String?) ?? 'teaches',
      letters = (json['letters'] as bool?) ?? false,
      writing = switch (json['writing']) {
        'memory' => WritingRule.memory,
        'practised' => WritingRule.practised,
        _ => null,
      },
      strand = json['strand'] as String?,
      readerAs = (json['readerAs'] as String?) ?? 'oral',
      masteryRequires = (json['masteryRequires'] as Map<String, Object?>?) ?? const <String, Object?>{},
      initialStabilityDays = (_map(json['retention'])['initialStabilityDays']! as num).toDouble(),
      targetRetention = (_map(json['retention'])['targetRetention']! as num).toDouble();

  final String id;
  final String course;

  /// One of the domains (`numbers`, `colors`, ...), and the skill as a plain sentence of what the child can do.
  final String domain;
  final String title;
  final Map<String, double> prerequisites;
  final List<String> representations;
  final List<String> misconceptions;

  /// Which drawing grows for this skill (an id of the app's world art), or null: the app's own catalog then decides.
  final String? worldObject;

  /// One line for the child, with niqqud, of what they can do; or null.
  final String? childLine;
  final bool core;

  /// Language courses: the letter bundle, whether the skill is a set of words or letters, what a spelling that is right by
  /// sound counts as (`accepts` or `teaches`), and whether the skill is letter work.
  final String? bundle;
  final bool setCoverage;
  final String soundRight;
  final bool letters;

  /// Letter writing (E-1): a writing node (memory) or a trace node (practised); null for every other skill.
  final WritingRule? writing;

  /// The strand of the course (`lis`, `ph`, `rea` ...) the progress view groups the skill under; null in the lands.
  final String? strand;

  /// How a child whose route is `reader` is served in this skill: `oral` (the default: as strand 1 of the placement says) or `heritage`
  /// (see `servedRoute`). Only the Russian course says anything else.
  final String readerAs;
  final Map<String, Object?> masteryRequires;
  final double initialStabilityDays;
  final double targetRetention;
}

/// A gate of a language course (docs/languages/frame.md section 3.3.6): what must be mastered, what it holds back, and what
/// the parent's switch and the child's age and route do to it.
class GateDoc {
  GateDoc._(Map<String, Object?> json)
    : id = json['id']! as String,
      course = (json['course'] as String?) ?? Course.core,
      requires = <String>{for (final Object? s in json['requires']! as List<Object?>) s! as String},
      requireAtLeast = <({Set<String> skills, int count})>[
        for (final Map<String, Object?> q in _maps(json['requireAtLeast']))
          (
            skills: <String>{for (final Object? s in q['skills']! as List<Object?>) s! as String},
            count: q['count']! as int,
          ),
      ],
      holds = <String>{for (final Object? s in json['holds']! as List<Object?>) s! as String},
      minAge = json['minAge'] as int?,
      neverUnderBand = json['neverUnderBand'] as int?,
      durableBelowBand = json['durableBelowBand'] as int?,
      switchName = (json['parentSwitch'] as Map<String, Object?>?)?['name'] as String?,
      switchEffect = (json['parentSwitch'] as Map<String, Object?>?)?['effect'] as String?,
      routeBypass = <String>{
        for (final Object? r in (json['routeBypass'] as List<Object?>?) ?? const <Object?>[]) r! as String,
      };

  final String id;
  final String course;
  final Set<String> requires;
  final List<({Set<String> skills, int count})> requireAtLeast;
  final Set<String> holds;
  final int? minAge;
  final int? neverUnderBand;
  final int? durableBelowBand;
  final String? switchName;
  final String? switchEffect;
  final Set<String> routeBypass;
}

/// One strand of a course's placement game: a ladder of levels of probe items, where a questionnaire answer starts it, and when it is
/// offered at all.
class PlacementStrandDoc {
  PlacementStrandDoc._(Map<String, Object?> json)
    : id = json['id']! as String,
      offerAnswer = _maybe(json['offer'])['answer'] as String?,
      offerEquals = _maybe(json['offer'])['equals'] as String?,
      offerMinBand = (_maybe(json['offer'])['minBand'] as int?) ?? 0,
      start = <({String answer, String equals, int level})>[
        for (final Map<String, Object?> s in _maps(json['start']))
          (answer: s['answer']! as String, equals: s['equals']! as String, level: s['level']! as int),
      ],
      levels = <({List<String> items, List<String> assumes})>[
        for (final Map<String, Object?> l in _maps(json['levels']))
          (
            items: <String>[for (final Object? i in l['items']! as List<Object?>) i! as String],
            assumes: <String>[
              for (final Object? i in (l['assumes'] as List<Object?>?) ?? const <Object?>[]) i! as String,
            ],
          ),
      ];

  final String id;

  /// The strand is offered only when the questionnaire answered [offerAnswer] with [offerEquals] (both null: always) and the child's
  /// presentation band is at least [offerMinBand].
  final String? offerAnswer;
  final String? offerEquals;
  final int offerMinBand;
  final List<({String answer, String equals, int level})> start;
  final List<({List<String> items, List<String> assumes})> levels;
}

/// The placement game of a language course (docs/languages/frame.md section 3.2, LS13): its strands, the one warm line after each probe,
/// the line that ends a visit, and how many probes one visit may hold.
class PlacementDoc {
  PlacementDoc._(Map<String, Object?> json)
    : id = json['id']! as String,
      course = (json['course'] as String?) ?? Course.core,
      thanks = Spoken.fromJson(json['thanks']),
      celebration = Spoken.fromJson(json['celebration']),
      perVisit = json['perVisit']! as int,
      strands = <PlacementStrandDoc>[
        for (final Map<String, Object?> s in _maps(json['strands'])) PlacementStrandDoc._(s),
      ];

  final String id;
  final String course;
  final Spoken thanks;
  final Spoken celebration;
  final int perVisit;
  final List<PlacementStrandDoc> strands;
}

/// A misconception of the pack.
class TagDoc {
  TagDoc._(Map<String, Object?> json)
    : id = json['id']! as String,
      course = (json['course'] as String?) ?? Course.core,
      parentText = json['parentText']! as String,
      kind = json['kind'] as String?,
      homeActivity = json['homeActivity'] == null ? null : _caption(json['homeActivity']),
      skills = <String>[for (final Object? s in json['skills']! as List<Object?>) s! as String],
      repairActivities = <String>[
        for (final Object? a in json['repairActivities']! as List<Object?>) a! as String,
      ],
      preferredRepresentations = <String>[
        for (final Object? r in json['preferredRepresentations']! as List<Object?>) r! as String,
      ];

  final String id;
  final String course;

  /// What a parent reads about this misunderstanding, in plain Hebrew.
  final String parentText;

  /// `diagnostic`, `on_the_way`, `accent` or `practice` in a language course (frame section 4.1); null in the lands.
  final String? kind;

  /// Something a parent can do at home in about five minutes, or null.
  final String? homeActivity;
  final List<String> skills;
  final List<String> repairActivities;
  final List<String> preferredRepresentations;
}

/// The pictures of a pack, by asset id, as SVG text. Nothing else is ever drawn from a pack.
class PackAssets {
  PackAssets(Map<String, String> svg) : _svg = svg;

  factory PackAssets.fromPack(VerifiedPack pack) {
    final Map<String, String> svg = <String, String>{};
    for (final Map<String, Object?> a in _maps(pack.manifest['assets'])) {
      final Uint8List? bytes = pack.files[a['file']! as String];
      if (bytes != null) svg[a['id']! as String] = utf8.decode(bytes);
    }
    return PackAssets(svg);
  }

  final Map<String, String> _svg;

  /// The SVG text of an `asset:<id>` reference.
  String svg(String ref) => _svg[ref.substring('asset:'.length)]!;

  /// The same, or null when the pack has no such picture (a hint that draws a picture of its own asks this way).
  String? svgOrNull(String ref) => _svg[ref.startsWith('asset:') ? ref.substring('asset:'.length) : ref];
}

/// A verified pack, ready to be played.
class PackContent {
  PackContent._({
    required this.packId,
    required this.packVersion,
    required this.course,
    required this.lessons,
    required this.activities,
    required this.assets,
    required this.skills,
    required this.tags,
    required this.gates,
    this.strokeSets = const <String, StrokeSet>{},
    this.placement,
  });

  factory PackContent.fromPack(VerifiedPack pack) {
    final PackAssets assets = PackAssets.fromPack(pack);
    final Map<String, Lesson> lessons = <String, Lesson>{};
    final Map<String, Activity> activities = <String, Activity>{};
    final Map<String, SkillDoc> skills = <String, SkillDoc>{};
    final Map<String, TagDoc> tags = <String, TagDoc>{};
    final Map<String, GateDoc> gates = <String, GateDoc>{};
    final Map<String, StrokeSet> strokeSets = <String, StrokeSet>{};
    PlacementDoc? placement;
    for (final MapEntry<String, Object?> d in pack.docs.entries) {
      final Map<String, Object?> doc = _map(d.value);
      if (d.key.startsWith('lesson.')) {
        final Lesson l = Lesson._(doc);
        lessons[l.id] = l;
      } else if (d.key.startsWith('skill.')) {
        final SkillDoc s = SkillDoc._(doc);
        skills[s.id] = s;
      } else if (d.key.startsWith('gate.')) {
        final GateDoc g = GateDoc._(doc);
        gates[g.id] = g;
      } else if (d.key.startsWith('strokes.')) {
        final StrokeSet set = StrokeSet.fromJson(doc);
        strokeSets[set.name] = set;
      } else if (d.key.startsWith('placement.')) {
        placement = PlacementDoc._(doc);
      } else if (d.key.startsWith('misconception.')) {
        final TagDoc t = TagDoc._(doc);
        tags[t.id] = t;
      } else if (d.key.startsWith('activity.')) {
        final Activity a = Activity.fromJson(doc, assets);
        // SEC-M10-1: the build claims `tap_answer` 1.4, but no session draws a number answer or a stage picture yet (the first batch
        // that does removes this line for what it draws). Until then such an item is hidden, as a pack of a newer version is.
        if (a is TapAnswerActivity && (a.numberAnswer != null || a.picture != null)) continue;
        activities[a.id] = a;
      }
    }
    return PackContent._(
      packId: pack.id,
      packVersion: pack.version,
      course: (pack.manifest['course'] as String?) ?? Course.core,
      lessons: lessons,
      activities: activities,
      assets: assets,
      skills: skills,
      tags: tags,
      gates: gates,
      strokeSets: strokeSets,
      placement: placement,
    );
  }

  final String packId;
  final String packVersion;

  /// The course every document of the pack belongs to (the validator makes them agree).
  final String course;
  final Map<String, Lesson> lessons;
  final Map<String, Activity> activities;
  final PackAssets assets;
  final Map<String, SkillDoc> skills;
  final Map<String, TagDoc> tags;

  /// The gates of the course (none in the lands that exist today).
  final Map<String, GateDoc> gates;

  /// The stroke sets of the course's scripts by name (`latin`, `hebrew-print` ...); none in the lands.
  final Map<String, StrokeSet> strokeSets;

  /// The placement game of the course (LS13), or null: the lands have none, and a language pack may not have one yet.
  final PlacementDoc? placement;

  /// The activities of a lesson, in order. An item that is hidden (see [PackContent.fromPack]) is left out, and so is a teach screen: the
  /// validator refuses one among the items, and a teach screen is only ever played from a `teach` set, which [itemsFor] filters by route.
  List<Activity> itemsOf(Lesson lesson) => <Activity>[
    for (final String id in lesson.itemIds)
      if (activities[id] case final Activity a when !a.teachScreen) a,
  ];

  /// What a child served on [route] (`new` or `heritage`: [servedRoute] has resolved a reader) plays in [lesson]: the screens of the sets
  /// that route is shown, then the lesson's items, the same for every route. A route that is not set yet counts as a new learner. A
  /// heritage speaker is never shown a teach screen (a `teach` set may not name that route) and is shown a hearing screen only from a
  /// `hear` set, a new learner never; a pack that says otherwise is refused here as well. Any other route (a reader nobody resolved) is
  /// served as a new learner, the side that shows more. A route never removes, adds or reorders a lesson's items.
  List<Activity> itemsFor(Lesson lesson, {String? route}) {
    final bool heritage = route == 'heritage';
    return <Activity>[
      for (final TeachSet set in lesson.teach)
        if (set.routes.contains(heritage ? 'heritage' : 'new') && set.hear == heritage)
          for (final String id in set.itemIds) ?activities[id],
      ...itemsOf(lesson),
    ];
  }
}
