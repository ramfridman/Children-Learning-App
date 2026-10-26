import 'dart:typed_data';

import 'package:nitznutz/core/clock.dart';
import 'package:nitznutz/core/platform_service.dart';
import 'package:nitznutz/security/pin_hasher.dart';

/// A hasher that is instant: the "hash" is the salt followed by the PIN's digits. Only the real
/// Argon2id test uses the real hasher.
class FastHasher implements PinHasher {
  const FastHasher();

  @override
  Future<Uint8List> hash(String pin, Uint8List salt, ArgonParams params) async =>
      Uint8List.fromList(<int>[...salt, ...pin.codeUnits]);
}

class ControlledClock implements Clock {
  ControlledClock(this.now);

  int now;

  @override
  int nowMs() => now;

  void advance(Duration d) => now += d.inMilliseconds;
}

/// A phone whose uptime and boot number tests can set. [secure] records what the parent area asked for.
class FakePlatform implements PlatformService {
  int elapsedMs = 1000000;
  int bootId = 7;
  bool secure = false;
  final List<bool> secureCalls = <bool>[];

  void advance(Duration d) => elapsedMs += d.inMilliseconds;

  @override
  Future<MonotonicReading> monotonic() async => MonotonicReading(elapsedMs: elapsedMs, bootId: bootId);

  @override
  Future<String> noBackupDir() async => 'unused';

  @override
  Future<void> setSecure({required bool secure}) async {
    this.secure = secure;
    secureCalls.add(secure);
  }
}
