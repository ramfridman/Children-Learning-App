import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:nitznutz/security/pin_hasher.dart';
import 'package:nitznutz/security/pin_service.dart';

import 'support/fakes.dart';
import 'support/security_fakes.dart';

const String pin = '4831';
const String wrong = '1111';

void main() {
  late MemoryStore store;
  late ControlledClock clock;
  late FakePlatform phone;
  late List<String> events;

  PinService make({PinHasher hasher = const FastHasher()}) => PinService(
    store: store,
    clock: clock,
    platform: phone,
    hasher: hasher,
    onEvent: (String kind, String detail) async => events.add('$kind $detail'),
  );

  setUp(() {
    store = MemoryStore();
    clock = ControlledClock(1793000000000);
    phone = FakePlatform();
    events = <String>[];
  });

  group('setting a PIN', () {
    test('accepts 4 to 6 digits only', () async {
      final PinService s = make();
      for (final String bad in <String>['123', '1234567', '12a4', '', '١٢٣٤', '12 34']) {
        await expectLater(s.setPin(bad), throwsArgumentError, reason: bad);
      }
      for (final String good in <String>['1234', '12345', '123456']) {
        await s.setPin(good);
        expect(await s.isSet(), isTrue);
      }
    });

    test('keeps only a salted hash: the PIN is nowhere in storage', () async {
      final PinService s = make(hasher: const Argon2idHasher());
      await s.setPin(pin);
      final String raw = store.data[PinService.storeKey]!;
      expect(raw.contains(pin), isFalse);
      final Map<String, Object?> state = jsonDecode(raw) as Map<String, Object?>;
      expect(base64Decode(state['hash']! as String).length, 32);
      expect(base64Decode(state['salt']! as String).length, 16);
      expect(state['m'], 19456);
      expect(state['t'], 3);
    });

    test('two PINs set on the same PIN get different salts and hashes', () async {
      final PinService a = make();
      await a.setPin(pin);
      final String first = store.data[PinService.storeKey]!;
      await a.setPin(pin);
      expect(store.data[PinService.storeKey], isNot(first));
    });

    test('verify with no PIN set is a programming error, not a pass', () async {
      await expectLater(make().verify(pin), throwsStateError);
    });
  });

  group('the real Argon2id', () {
    test('accepts the right PIN, refuses a wrong one, and a check is well under 2 seconds', () async {
      final PinService s = make(hasher: const Argon2idHasher());
      await s.setPin(pin);
      final Stopwatch sw = Stopwatch()..start();
      expect(await s.verify(pin), isA<PinOk>());
      expect(sw.elapsedMilliseconds, lessThan(2000));
      expect(await s.verify(wrong), isA<PinWrong>());
    });

    test('matches a known Argon2id vector shape: the same inputs always give the same hash', () async {
      const Argon2idHasher h = Argon2idHasher();
      final Uint8List salt = Uint8List.fromList(List<int>.generate(16, (int i) => i));
      final Uint8List a = await h.hash('0000', salt, const ArgonParams());
      final Uint8List b = await h.hash('0000', salt, const ArgonParams());
      final Uint8List c = await h.hash('0001', salt, const ArgonParams());
      expect(a, b);
      expect(a, isNot(c));
      expect(a.length, 32);
    });
  });

  group('lock-outs', () {
    test('5th wrong try 30 s, 7th 2 min, 9th 10 min, 11th and later 1 h; nothing in between', () async {
      final PinService s = make();
      await s.setPin(pin);
      final Map<int, Duration> expected = <int, Duration>{
        5: const Duration(seconds: 30),
        7: const Duration(minutes: 2),
        9: const Duration(minutes: 10),
        11: const Duration(hours: 1),
        12: const Duration(hours: 1),
      };
      for (int n = 1; n <= 12; n++) {
        final PinResult r = await s.verify(wrong);
        expect(r, isA<PinWrong>(), reason: 'try $n');
        expect((r as PinWrong).failures, n);
        expect(r.lockedFor, expected[n], reason: 'try $n');
        final Duration? lock = expected[n];
        if (lock != null) {
          // Wait the lock out, so the next try is allowed.
          phone.advance(lock + const Duration(seconds: 1));
        }
      }
    });

    test('while locked, even the right PIN is refused, and the count does not move', () async {
      final PinService s = make();
      await s.setPin(pin);
      for (int i = 0; i < 5; i++) {
        await s.verify(wrong);
      }
      final PinResult locked = await s.verify(pin);
      expect(locked, isA<PinLocked>());
      expect((locked as PinLocked).remaining, lessThanOrEqualTo(const Duration(seconds: 30)));
      phone.advance(const Duration(seconds: 10));
      final PinResult later = await s.verify(wrong);
      expect(later, isA<PinLocked>());
      expect((later as PinLocked).remaining, const Duration(seconds: 20));
      expect(jsonDecode(store.data[PinService.storeKey]!)['fails'], 5);
    });

    test('the right PIN works again once the lock has run out, and resets the count', () async {
      final PinService s = make();
      await s.setPin(pin);
      for (int i = 0; i < 5; i++) {
        await s.verify(wrong);
      }
      phone.advance(const Duration(seconds: 31));
      expect(await s.verify(pin), isA<PinOk>());
      expect(jsonDecode(store.data[PinService.storeKey]!)['fails'], 0);
      // A fresh run of wrong tries starts from 1 again.
      expect(((await s.verify(wrong)) as PinWrong).failures, 1);
    });

    test('a correct PIN before the 5th try resets the count', () async {
      final PinService s = make();
      await s.setPin(pin);
      for (int i = 0; i < 4; i++) {
        await s.verify(wrong);
      }
      expect(await s.verify(pin), isA<PinOk>());
      for (int i = 0; i < 4; i++) {
        expect((await s.verify(wrong) as PinWrong).lockedFor, isNull);
      }
    });

    test('a badly formed PIN counts as a wrong try and is never hashed', () async {
      final PinService s = make(hasher: _ThrowingHasher(afterFirst: true));
      await s.setPin(pin);
      expect(await s.verify('12'), isA<PinWrong>());
      expect(await s.verify('abcd'), isA<PinWrong>());
    });
  });

  group('restarts', () {
    test('the count survives closing the app', () async {
      final PinService first = make();
      await first.setPin(pin);
      for (int i = 0; i < 4; i++) {
        await first.verify(wrong);
      }
      final PinService second = make();
      final PinResult r = await second.verify(wrong);
      expect((r as PinWrong).failures, 5);
      expect(r.lockedFor, const Duration(seconds: 30));
    });

    test('a lock survives closing the app', () async {
      final PinService first = make();
      await first.setPin(pin);
      for (int i = 0; i < 5; i++) {
        await first.verify(wrong);
      }
      expect(await make().lockRemaining(), isNotNull);
      expect(await make().verify(pin), isA<PinLocked>());
    });

    test('killing the app in the middle of a check still counts the try', () async {
      final PinService s = make(hasher: _ThrowingHasher(afterFirst: true));
      await s.setPin(pin);
      await expectLater(s.verify(pin), throwsStateError);
      expect(jsonDecode(store.data[PinService.storeKey]!)['fails'], 1);
    });
  });

  group('changing the phone\'s clock', () {
    Future<PinService> locked() async {
      final PinService s = make();
      await s.setPin(pin);
      for (int i = 0; i < 9; i++) {
        phone.advance(const Duration(hours: 2));
        clock.advance(const Duration(hours: 2));
        await s.verify(wrong);
      }
      return s; // locked for 10 minutes
    }

    test('setting the date back does not lengthen or shorten the lock', () async {
      final PinService s = await locked();
      final Duration before = (await s.lockRemaining())!;
      clock.now -= const Duration(days: 30).inMilliseconds;
      expect(await s.lockRemaining(), before);
    });

    test('setting the date forward does not end the lock', () async {
      final PinService s = await locked();
      clock.now += const Duration(days: 30).inMilliseconds;
      expect(await s.lockRemaining(), isNotNull);
      expect(await s.verify(pin), isA<PinLocked>());
    });

    test('the lock ends on time by the phone\'s own uptime', () async {
      final PinService s = await locked();
      phone.advance(const Duration(minutes: 10, seconds: 1));
      expect(await s.lockRemaining(), isNull);
    });

    test(
      'after a restart of the phone the wall clock is used, but never for longer than the lock itself',
      () async {
        final PinService s = await locked();
        phone
          ..bootId += 1
          ..elapsedMs = 5000;
        clock.now -= const Duration(days: 400).inMilliseconds;
        final Duration? remaining = await s.lockRemaining();
        expect(remaining, const Duration(minutes: 10));
        clock.now += const Duration(days: 401).inMilliseconds;
        expect(await s.lockRemaining(), isNull);
      },
    );
  });

  group('events', () {
    test('wrong tries, the alert on the 3rd, and each lock-out are recorded with fixed words only', () async {
      final PinService s = make();
      await s.setPin(pin);
      for (int i = 0; i < 5; i++) {
        await s.verify(wrong);
      }
      expect(events, <String>[
        'pin_wrong n=1',
        'pin_wrong n=2',
        'pin_wrong n=3',
        'pin_alert n=3',
        'pin_wrong n=4',
        'pin_wrong n=5',
        'pin_lockout s=30',
      ]);
      expect(events.any((String e) => e.contains(pin) || e.contains(wrong)), isFalse);
    });
  });

  test('two checks started at the same time are counted one after the other', () async {
    final PinService s = make();
    await s.setPin(pin);
    final List<PinResult> results = await Future.wait(<Future<PinResult>>[
      for (int i = 0; i < 5; i++) s.verify(wrong),
    ]);
    expect(<int>[for (final PinResult r in results) (r as PinWrong).failures], <int>[1, 2, 3, 4, 5]);
  });

  test('constantTimeEquals', () {
    expect(constantTimeEquals(<int>[1, 2, 3], <int>[1, 2, 3]), isTrue);
    expect(constantTimeEquals(<int>[1, 2, 3], <int>[1, 2, 4]), isFalse);
    expect(constantTimeEquals(<int>[1, 2], <int>[1, 2, 3]), isFalse);
  });
}

/// Hashes once (for setPin), then fails: simulates the app being killed during a check.
class _ThrowingHasher implements PinHasher {
  _ThrowingHasher({required this.afterFirst});

  final bool afterFirst;
  int calls = 0;

  @override
  Future<Uint8List> hash(String pin, Uint8List salt, ArgonParams params) async {
    calls++;
    if (afterFirst && calls > 1) throw StateError('killed');
    return Uint8List.fromList(<int>[...salt, ...pin.codeUnits]);
  }
}
