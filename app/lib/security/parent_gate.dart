import 'dart:convert';
import 'dart:math';

import '../core/clock.dart';
import '../device/secure_store.dart';
import '../strings/he.dart';

/// One question of the parent gate: a multiplication above what a Band C child does, written in
/// Hebrew words, answered on a shuffled keypad. The keypad is shuffled again for every question.
class GateQuestion {
  const GateQuestion({required this.a, required this.b, required this.keypad});

  final int a;
  final int b;

  /// The digits 0 to 9 in the order the keypad shows them.
  final List<int> keypad;

  int get answer => a * b;

  /// The question in words, for example "how much is fourteen times six?" (× is read out as "times").
  String get hebrew =>
      He.gateQuestion.fill(<String, String>{'a': He.gateNumbers[a]!.text, 'b': He.gateNumbers[b]!.text});
}

sealed class GateOutcome {
  const GateOutcome();
}

class GateOk extends GateOutcome {
  const GateOk();
}

class GateWrong extends GateOutcome {
  const GateWrong(this.failuresInARow);

  final int failuresInARow;
}

/// No question is accepted for now: a calm 30 second cool-down ([long] false) after 3 wrong
/// answers in a row, or a 10 minute lock ([long] true) after 5 wrong answers within 2 minutes.
class GateWait extends GateOutcome {
  const GateWait(this.remaining, {required this.long});

  final Duration remaining;
  final bool long;
}

/// The arithmetic parent gate. It is a speed bump in front of the PIN, not security on its own (the
/// design spec says so), and it keeps no secret. Its failure state is kept in secure storage so that
/// closing the app does not clear a cool-down.
class ParentGate {
  ParentGate({required SecureStore store, required Clock clock, Random? random, this.onEvent})
    : _store = store,
      _clock = clock,
      _random = random ?? Random.secure();

  static const String storeKey = 'parent_gate_v1';
  static const Duration coolDown = Duration(seconds: 30);
  static const Duration longLock = Duration(minutes: 10);
  static const Duration window = Duration(minutes: 2);
  static const int streakForCoolDown = 3;
  static const int failuresForLock = 5;

  final SecureStore _store;
  final Clock _clock;
  final Random _random;

  /// `gate_alert` (3 wrong in a row) and `gate_lock` (5 within 2 minutes). Fixed words only.
  final Future<void> Function(String kind, String detail)? onEvent;

  GateQuestion newQuestion() {
    const List<int> as = <int>[12, 13, 14, 15, 16, 17, 18, 19];
    const List<int> bs = <int>[3, 4, 5, 6, 7, 8, 9];
    final List<int> keypad = <int>[for (int d = 0; d < 10; d++) d]..shuffle(_random);
    return GateQuestion(a: as[_random.nextInt(as.length)], b: bs[_random.nextInt(bs.length)], keypad: keypad);
  }

  Future<Map<String, Object?>> _load() async {
    final String? raw = await _store.read(storeKey);
    if (raw != null) {
      try {
        final Object? v = jsonDecode(raw);
        if (v is Map<String, Object?>) return v;
      } on FormatException {
        // fall through to a fresh state
      }
    }
    return <String, Object?>{'streak': 0, 'recent': <int>[], 'until': 0, 'long': false};
  }

  Future<GateWait?> waiting() async {
    final Map<String, Object?> s = await _load();
    final int left = (s['until']! as num).toInt() - _clock.nowMs();
    return left > 0 ? GateWait(Duration(milliseconds: left), long: s['long'] == true) : null;
  }

  Future<GateOutcome> submit(GateQuestion question, String entered) async {
    final GateWait? wait = await waiting();
    if (wait != null) return wait;

    final Map<String, Object?> s = await _load();
    if (entered == '${question.answer}') {
      await _store.write(
        storeKey,
        jsonEncode(<String, Object?>{'streak': 0, 'recent': <int>[], 'until': 0, 'long': false}),
      );
      return const GateOk();
    }

    final int now = _clock.nowMs();
    final int streak = (s['streak']! as num).toInt() + 1;
    final List<int> recent = <int>[
      for (final Object? t in s['recent']! as List<Object?>)
        if (now - (t! as num).toInt() < window.inMilliseconds) (t as num).toInt(),
      now,
    ];
    s['streak'] = streak;
    s['recent'] = recent;
    s['until'] = 0;
    s['long'] = false;
    GateWait? result;
    if (recent.length >= failuresForLock) {
      s['until'] = now + longLock.inMilliseconds;
      s['long'] = true;
      s['recent'] = <int>[];
      s['streak'] = 0;
      result = const GateWait(longLock, long: true);
      await onEvent?.call('gate_lock', 'min=10');
    } else if (streak >= streakForCoolDown) {
      s['until'] = now + coolDown.inMilliseconds;
      result = const GateWait(coolDown, long: false);
      if (streak == streakForCoolDown) await onEvent?.call('gate_alert', 'n=3');
    }
    await _store.write(storeKey, jsonEncode(s));
    return result ?? GateWrong(streak);
  }
}
