import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import '../core/clock.dart';
import '../core/platform_service.dart';
import '../device/secure_store.dart';
import 'pin_hasher.dart';

sealed class PinResult {
  const PinResult();
}

class PinOk extends PinResult {
  const PinOk();
}

/// A wrong PIN. [lockedFor] is set when this try started a lock-out.
class PinWrong extends PinResult {
  const PinWrong({required this.failures, this.lockedFor});

  final int failures;
  final Duration? lockedFor;
}

/// The PIN was not even checked, because a lock-out is running.
class PinLocked extends PinResult {
  const PinLocked(this.remaining);

  final Duration remaining;
}

/// The parent PIN: 4 to 6 digits, kept only as an Argon2id hash with a random salt.
///
/// Wrong tries are counted and persisted in secure storage **before** the PIN is checked, so closing
/// the app mid-check cannot save a try. Lock-outs follow the plan: the 5th wrong try locks for 30 s,
/// the 7th for 2 min, the 9th for 10 min, and the 11th and every later one for 1 h. A correct PIN
/// resets the count. While locked, the PIN is not checked at all, so a lock-out gives no hints.
///
/// A lock is timed with the phone's monotonic clock (which changing the date cannot move) within
/// one boot, and with the wall clock, limited to the lock's own length, after a restart.
class PinService {
  PinService({
    required SecureStore store,
    required Clock clock,
    required PlatformService platform,
    PinHasher hasher = const Argon2idHasher(),
    ArgonParams params = const ArgonParams(),
    Random? random,
    this.onEvent,
  }) : _store = store,
       _clock = clock,
       _platform = platform,
       _hasher = hasher,
       _params = params,
       _random = random ?? Random.secure();

  static const String storeKey = 'parent_pin_v1';
  static const int minLength = 4;
  static const int maxLength = 6;

  /// The lock that the n-th consecutive wrong try starts, or null.
  static Duration? lockFor(int failures) {
    if (failures >= 11) return const Duration(hours: 1);
    return switch (failures) {
      5 => const Duration(seconds: 30),
      7 => const Duration(minutes: 2),
      9 => const Duration(minutes: 10),
      _ => null,
    };
  }

  final SecureStore _store;
  final Clock _clock;
  final PlatformService _platform;
  final PinHasher _hasher;
  final ArgonParams _params;
  final Random _random;

  /// Called with a short event name and fixed words only (never the PIN): `pin_wrong`,
  /// `pin_alert` (the 3rd wrong try in a row) and `pin_lockout`.
  final Future<void> Function(String kind, String detail)? onEvent;

  Future<void> _tail = Future<void>.value();

  Future<T> _serial<T>(Future<T> Function() action) {
    final Completer<T> done = Completer<T>();
    _tail = _tail.then((_) async {
      try {
        done.complete(await action());
      } catch (e, s) {
        done.completeError(e, s);
      }
    });
    return done.future;
  }

  static bool isValidFormat(String pin) => RegExp('^[0-9]{$minLength,$maxLength}\$').hasMatch(pin);

  Future<Map<String, Object?>?> _load() async {
    final String? raw = await _store.read(storeKey);
    if (raw == null) return null;
    try {
      final Object? v = jsonDecode(raw);
      return v is Map<String, Object?> && v['v'] == 1 ? v : null;
    } on FormatException {
      return null;
    }
  }

  Future<void> _save(Map<String, Object?> state) => _store.write(storeKey, jsonEncode(state));

  Future<bool> isSet() async => (await _load()) != null;

  /// Sets or replaces the PIN. The caller has already checked the old PIN when changing one.
  Future<void> setPin(String pin) => _serial(() async {
    if (!isValidFormat(pin)) throw ArgumentError('A PIN is 4 to 6 digits');
    final Uint8List salt = Uint8List.fromList(<int>[for (int i = 0; i < 16; i++) _random.nextInt(256)]);
    final Uint8List hash = await _hasher.hash(pin, salt, _params);
    await _save(<String, Object?>{
      'v': 1,
      'salt': base64Encode(salt),
      'hash': base64Encode(hash),
      'm': _params.memoryKiB,
      't': _params.iterations,
      'p': _params.parallelism,
      'fails': 0,
      'lockMs': 0,
      'lockWallEnd': 0,
      'lockElapsed': 0,
      'lockBoot': 0,
    });
  });

  Future<void> clear() => _serial(() => _store.delete(storeKey));

  /// How long a running lock-out has left, or null.
  Future<Duration?> lockRemaining() => _serial(() async {
    final Map<String, Object?>? s = await _load();
    return s == null ? null : await _remaining(s);
  });

  Future<Duration?> _remaining(Map<String, Object?> s) async {
    final int lockMs = (s['lockMs']! as num).toInt();
    if (lockMs <= 0) return null;
    final MonotonicReading now = await _platform.monotonic();
    final int startElapsed = (s['lockElapsed']! as num).toInt();
    final bool sameBoot = now.bootId == (s['lockBoot']! as num).toInt() && now.elapsedMs >= startElapsed;
    final int remainingMs = sameBoot
        ? lockMs - (now.elapsedMs - startElapsed)
        : ((s['lockWallEnd']! as num).toInt() - _clock.nowMs()).clamp(0, lockMs);
    return remainingMs > 0 ? Duration(milliseconds: remainingMs) : null;
  }

  Future<PinResult> verify(String pin) => _serial(() async {
    final Map<String, Object?>? s = await _load();
    if (s == null) throw StateError('No PIN is set');
    final Duration? locked = await _remaining(s);
    if (locked != null) return PinLocked(locked);

    // Count the try first. A correct PIN resets it below.
    final int failures = (s['fails']! as num).toInt() + 1;
    s['fails'] = failures;
    s['lockMs'] = 0;
    await _save(s);

    final Uint8List expected = base64Decode(s['hash']! as String);
    final Uint8List actual = isValidFormat(pin)
        ? await _hasher.hash(
            pin,
            base64Decode(s['salt']! as String),
            ArgonParams(
              memoryKiB: (s['m']! as num).toInt(),
              iterations: (s['t']! as num).toInt(),
              parallelism: (s['p']! as num).toInt(),
            ),
          )
        : Uint8List(0);
    if (constantTimeEquals(expected, actual)) {
      s['fails'] = 0;
      await _save(s);
      return const PinOk();
    }

    await onEvent?.call('pin_wrong', 'n=$failures');
    if (failures == 3) await onEvent?.call('pin_alert', 'n=3');
    final Duration? lock = lockFor(failures);
    if (lock != null) {
      final MonotonicReading now = await _platform.monotonic();
      s['lockMs'] = lock.inMilliseconds;
      s['lockWallEnd'] = _clock.nowMs() + lock.inMilliseconds;
      s['lockElapsed'] = now.elapsedMs;
      s['lockBoot'] = now.bootId;
      await _save(s);
      await onEvent?.call('pin_lockout', 's=${lock.inSeconds}');
    }
    return PinWrong(failures: failures, lockedFor: lock);
  });
}
