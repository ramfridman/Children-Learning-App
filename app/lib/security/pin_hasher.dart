import 'dart:isolate';
import 'dart:typed_data';

import 'package:hashlib/hashlib.dart' as hashlib;

/// Argon2id settings, stored next to every hash so they can be raised later without breaking
/// old PINs. The numbers follow the OWASP minimum for Argon2id (19 MiB, 2 passes, 1 lane) with
/// one more pass; a check takes a few hundred milliseconds on a phone.
class ArgonParams {
  const ArgonParams({this.memoryKiB = 19456, this.iterations = 3, this.parallelism = 1});

  final int memoryKiB;
  final int iterations;
  final int parallelism;
}

abstract interface class PinHasher {
  /// A 32-byte Argon2id hash of [pin] with [salt].
  Future<Uint8List> hash(String pin, Uint8List salt, ArgonParams params);
}

/// Pure Dart Argon2id (`hashlib`), run in a separate isolate so the screen does not stutter.
class Argon2idHasher implements PinHasher {
  const Argon2idHasher();

  @override
  Future<Uint8List> hash(String pin, Uint8List salt, ArgonParams params) => Isolate.run(() {
    final hashlib.Argon2 argon = hashlib.Argon2(
      salt: salt,
      type: hashlib.Argon2Type.argon2id,
      hashLength: 32,
      iterations: params.iterations,
      memorySizeKB: params.memoryKiB,
      parallelism: params.parallelism,
    );
    return Uint8List.fromList(argon.convert(pin.codeUnits).bytes);
  });
}

/// Compares two byte lists without stopping at the first difference.
bool constantTimeEquals(List<int> a, List<int> b) {
  if (a.length != b.length) return false;
  int diff = 0;
  for (int i = 0; i < a.length; i++) {
    diff |= a[i] ^ b[i];
  }
  return diff == 0;
}
