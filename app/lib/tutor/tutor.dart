import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import '../net/gateway_client.dart';

/// Everything the app tells the tutor service: ids, numbers and enums. Never a name, never text, never audio.
class TutorAttempt {
  const TutorAttempt(this.option, this.result, {this.misconception});

  /// The id of the option chosen (`o2`), or `n=4` for a count given.
  final String option;

  /// `incorrect` or `unsure`.
  final String result;
  final String? misconception;

  Map<String, Object?> toJson() => <String, Object?>{
    'option': option,
    'result': result,
    'misconception': ?misconception,
  };
}

class TutorAsk {
  const TutorAsk({
    required this.childRef,
    required this.sessionRef,
    required this.packId,
    required this.packVersion,
    required this.itemId,
    required this.characterId,
    required this.band,
    required this.addressForm,
    required this.hintLevel,
    required this.mistakes,
    this.attempts = const <TutorAttempt>[],
    this.prefetch = false,
  });

  final String childRef;
  final String sessionRef;
  final String packId;
  final String packVersion;
  final String itemId;
  final String characterId;

  /// `A`, `B` or `C`.
  final String band;

  /// `f`, `m` or `n`.
  final String addressForm;
  final int hintLevel;

  /// Misconception tags, or `default` for a wrong answer that has none.
  final List<String> mistakes;
  final List<TutorAttempt> attempts;
  final bool prefetch;

  Map<String, Object?> toJson() => <String, Object?>{
    'child_ref': childRef,
    'session_ref': sessionRef,
    'pack_id': packId,
    'pack_version': packVersion,
    'item_id': itemId,
    'character_id': characterId,
    'band': band,
    'address_form': addressForm,
    'hint_level': hintLevel,
    'mode': prefetch ? 'prefetch' : 'turn',
    'mistakes': mistakes,
    'attempts': <Object?>[for (final TutorAttempt a in attempts.take(3)) a.toJson()],
  };

  String keyFor(String mistake) => '$itemId|$mistake|$hintLevel';
}

/// One line the service made: what to say, in the guide's voice, and what to do with it.
class TutorLine {
  const TutorLine({
    required this.mistake,
    required this.source,
    required this.line,
    required this.caption,
    required this.next,
    required this.highlight,
    required this.misconception,
    required this.audio,
  });

  factory TutorLine.fromJson(Map<String, Object?> j) => TutorLine(
    mistake: j['mistake']! as String,
    source: j['source']! as String,
    line: j['line']! as String,
    caption: j['caption'] as String?,
    next: j['next']! as String,
    highlight: <String>[
      for (final Object? h in (j['highlight'] as List<Object?>? ?? const <Object?>[])) h! as String,
    ],
    misconception: j['misconception'] as String?,
    audio: j['audio'] is String ? base64Decode(j['audio']! as String) : null,
  );

  final String mistake;

  /// `live`, `cache` or `prefetch`.
  final String source;

  /// The vocalised line (for a caption in Bands B and C).
  final String line;
  final String? caption;
  final String next;
  final List<String> highlight;
  final String? misconception;
  final Uint8List? audio;
}

/// The answer for one mistake: a line, or the reason to use the authored line (RuleTutor).
class TutorResult {
  const TutorResult.line(TutorLine this.line) : mistake = '', rule = null;

  const TutorResult.rule(this.mistake, String this.rule) : line = null;

  final String mistake;
  final TutorLine? line;
  final String? rule;
}

abstract interface class TutorClient {
  /// Never throws: any failure is a result with a rule reason.
  Future<List<TutorResult>> ask(TutorAsk ask);
}

/// The real client: `tutor-turn` through the signed gateway.
class GatewayTutorClient implements TutorClient {
  GatewayTutorClient({required this.gateway, required this.deviceId, required this.accessToken});

  final GatewayClient gateway;
  final Future<String?> Function() deviceId;
  final Future<String?> Function() accessToken;

  @override
  Future<List<TutorResult>> ask(TutorAsk ask) async {
    List<TutorResult> failed(String why) => <TutorResult>[
      for (final String m in ask.mistakes) TutorResult.rule(m, why),
    ];
    try {
      final String? id = await deviceId();
      final String? token = await accessToken();
      if (id == null || token == null) return failed('unavailable');
      final Map<String, Object?> answer = await gateway.call(
        'tutor-turn',
        ask.toJson(),
        deviceId: id,
        accessToken: token,
      );
      final List<Object?> results = answer['results'] as List<Object?>? ?? const <Object?>[];
      return <TutorResult>[
        for (final Object? r in results)
          if (r is Map<String, Object?> && r['rule'] is String)
            TutorResult.rule(r['mistake']! as String, r['rule']! as String)
          else if (r is Map<String, Object?>)
            TutorResult.line(TutorLine.fromJson(r)),
      ];
    } on Object {
      return failed('unavailable');
    }
  }
}

/// The tutor for one lesson: keeps the lines made ahead, counts failures, and turns AI off for the rest of the
/// lesson after three (the circuit breaker) or when the service says it is off, capped or not configured.
class TutorSession {
  TutorSession({required this.client, this.failuresToStop = 3});

  final TutorClient client;
  final int failuresToStop;
  final Map<String, TutorLine> _ready = <String, TutorLine>{};
  int failures = 0;
  bool _blocked = false;
  bool _prefetchOff = false;

  /// Reasons that mean "not now, and not for the rest of this lesson", and are not a fault.
  static const Set<String> _stops = <String>{
    'kill_switch',
    'not_configured',
    'item_not_allowed',
    'cost_cap',
    'day_cap',
    'session_cap',
  };

  bool get available => !_blocked && failures < failuresToStop;

  /// A line made earlier for this mistake, if any.
  TutorLine? ready(TutorAsk ask) => _ready[ask.keyFor(ask.mistakes.first)];

  void _note(TutorAsk ask, List<TutorResult> results) {
    for (final TutorResult r in results) {
      final TutorLine? line = r.line;
      if (line != null) {
        _ready[ask.keyFor(line.mistake)] = line;
        continue;
      }
      final String why = r.rule ?? 'unavailable';
      if (_stops.contains(why)) {
        _blocked = true;
      } else if (why == 'prefetch_cap') {
        _prefetchOff = true;
      } else {
        failures++;
      }
    }
  }

  /// Asks ahead for the lines of likely mistakes. Quiet: nothing here can break a lesson.
  Future<void> prefetch(TutorAsk ask) async {
    if (!available || _prefetchOff) return;
    _note(ask, await client.ask(ask));
  }

  /// The line for a mistake now: from memory at once if it was made ahead, else asked for, with a recorded "hmm"
  /// at [slowAfter] and the authored line (null) at [giveUp].
  Future<TutorLine?> lineFor(
    TutorAsk ask, {
    Duration slowAfter = const Duration(milliseconds: 1500),
    Duration giveUp = const Duration(seconds: 3),
    void Function()? onSlow,
  }) async {
    final TutorLine? have = ready(ask);
    if (have != null) return have;
    if (!available) return null;
    final Timer slow = Timer(slowAfter, () => onSlow?.call());
    try {
      final List<TutorResult> results = await client
          .ask(ask)
          .timeout(giveUp, onTimeout: () => <TutorResult>[TutorResult.rule(ask.mistakes.first, 'timeout')]);
      _note(ask, results);
      return ready(ask);
    } finally {
      slow.cancel();
    }
  }
}
