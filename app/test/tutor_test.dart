import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:nitznutz/tutor/tutor.dart';

import 'support/fake_tutor.dart';

TutorAsk ask({
  List<String> mistakes = const <String>['M-CNT-DOUBLE'],
  int hint = 2,
  bool prefetch = false,
  String item = 'count.butterflies.3',
}) => TutorAsk(
  childRef: 'child-0000-0001',
  sessionRef: 'session-0000-0001',
  packId: 'starter',
  packVersion: '0.2.0',
  itemId: item,
  characterId: 'nitzi',
  band: 'A',
  addressForm: 'n',
  hintLevel: hint,
  mistakes: mistakes,
  attempts: const <TutorAttempt>[TutorAttempt('o3', 'incorrect', misconception: 'M-CNT-DOUBLE')],
  prefetch: prefetch,
);

void main() {
  group('what the app sends', () {
    test('ids, numbers and enums only: a fixed set of keys, nothing a child typed or said', () {
      final Map<String, Object?> j = ask().toJson();
      expect(j.keys.toSet(), <String>{
        'child_ref',
        'session_ref',
        'pack_id',
        'pack_version',
        'item_id',
        'character_id',
        'band',
        'address_form',
        'hint_level',
        'mode',
        'mistakes',
        'attempts',
      });
      expect(j['mode'], 'turn');
      expect(ask(prefetch: true).toJson()['mode'], 'prefetch');
      final String all = jsonEncode(j);
      expect(RegExp(r'[֐-׿]').hasMatch(all), isFalse, reason: 'no Hebrew text goes up at all');
      expect((j['attempts']! as List<Object?>).single, <String, Object?>{
        'option': 'o3',
        'result': 'incorrect',
        'misconception': 'M-CNT-DOUBLE',
      });
    });

    test('at most three attempts are sent', () {
      final TutorAsk many = TutorAsk(
        childRef: 'child-0000-0001',
        sessionRef: 'session-0000-0001',
        packId: 'starter',
        packVersion: '0.2.0',
        itemId: 'x',
        characterId: 'nitzi',
        band: 'A',
        addressForm: 'n',
        hintLevel: 0,
        mistakes: const <String>['default'],
        attempts: List<TutorAttempt>.generate(6, (int i) => TutorAttempt('o$i', 'incorrect')),
      );
      expect((many.toJson()['attempts']! as List<Object?>).length, 3);
    });
  });

  group('the real client over a gateway call', () {
    test('sends tutor-turn with the device id and token, and reads the lines and the audio', () async {
      String? name;
      Map<String, Object?>? body;
      String? id;
      String? token;
      final GatewayTutorClient c = GatewayTutorClient(
        call: (String n, Map<String, Object?> b, {String? deviceId, String? accessToken}) async {
          name = n;
          body = b;
          id = deviceId;
          token = accessToken;
          return <String, Object?>{
            'results': <Object?>[
              <String, Object?>{
                'mistake': 'M-CNT-DOUBLE',
                'source': 'cache',
                'line': 'x',
                'caption': null,
                'next': 'show_fingers',
                'highlight': <String>['o1'],
                'misconception': 'M-CNT-DOUBLE',
                'audio': base64Encode(<int>[1, 2, 3]),
                'audio_mime': 'audio/mpeg',
              },
              <String, Object?>{'mistake': 'default', 'rule': 'validator_failed'},
            ],
          };
        },
        deviceId: () async => 'device-1',
        accessToken: () async => 'token-1',
      );
      final List<TutorResult> r = await c.ask(ask(mistakes: <String>['M-CNT-DOUBLE', 'default']));
      expect(name, 'tutor-turn');
      expect(id, 'device-1');
      expect(token, 'token-1');
      expect(body!['item_id'], 'count.butterflies.3');
      expect(r[0].line!.audio, Uint8List.fromList(<int>[1, 2, 3]));
      expect(r[0].line!.highlight, <String>['o1']);
      expect(r[1].rule, 'validator_failed');
    });

    test('never throws: a failing call, no device or no sign-in is a RuleTutor answer', () async {
      final GatewayTutorClient boom = GatewayTutorClient(
        call: (String n, Map<String, Object?> b, {String? deviceId, String? accessToken}) async =>
            throw StateError('x'),
        deviceId: () async => 'device-1',
        accessToken: () async => 'token-1',
      );
      expect((await boom.ask(ask())).single.rule, 'unavailable');
      final GatewayTutorClient noDevice = GatewayTutorClient(
        call: (String n, Map<String, Object?> b, {String? deviceId, String? accessToken}) async =>
            <String, Object?>{},
        deviceId: () async => null,
        accessToken: () async => 'token-1',
      );
      expect((await noDevice.ask(ask())).single.rule, 'unavailable');
    });
  });

  group('the tutor of a lesson', () {
    late FakeTutorClient client;
    late TutorSession session;
    setUp(() {
      client = FakeTutorClient();
      session = TutorSession(client: client);
    });

    test('a line made ahead is there at once: no second question to the service', () async {
      await session.prefetch(ask(prefetch: true, mistakes: <String>['M-CNT-DOUBLE', 'M-CNT-SKIP']));
      expect(client.asked.length, 1);
      final TutorLine? line = await session.lineFor(ask());
      expect(line!.mistake, 'M-CNT-DOUBLE');
      expect(client.asked.length, 1, reason: 'served from memory');
    });

    test('a line that was not made ahead is asked for', () async {
      final TutorLine? line = await session.lineFor(ask());
      expect(line, isNotNull);
      expect(client.asked.single.prefetch, isFalse);
    });

    test(
      'a slow answer: the "hmm" fires at the slow mark, and the authored line (null) at the give-up mark',
      () async {
        client.delay = const Duration(milliseconds: 400);
        int slow = 0;
        final TutorLine? line = await session.lineFor(
          ask(),
          slowAfter: const Duration(milliseconds: 100),
          giveUp: const Duration(milliseconds: 250),
          onSlow: () => slow++,
        );
        expect(slow, 1);
        expect(line, isNull, reason: 'the child never waits past the give-up mark');
        expect(session.failures, 1);
      },
    );

    test('a quick answer does not trigger the "hmm"', () async {
      int slow = 0;
      await session.lineFor(ask(), slowAfter: const Duration(milliseconds: 200), onSlow: () => slow++);
      await Future<void>.delayed(const Duration(milliseconds: 300));
      expect(slow, 0);
    });

    test('three failures turn the helper off for the rest of the lesson (the circuit breaker)', () async {
      client.rule = 'model_failed';
      for (int i = 0; i < 3; i++) {
        expect(await session.lineFor(ask(item: 'i$i')), isNull);
      }
      expect(session.available, isFalse);
      final int asked = client.asked.length;
      expect(await session.lineFor(ask(item: 'later')), isNull);
      await session.prefetch(ask(prefetch: true, item: 'later'));
      expect(client.asked.length, asked, reason: 'nothing more is asked');
    });

    test('a switch, a cap or a missing key stops the helper at once, without counting as a fault', () async {
      for (final String why in <String>[
        'kill_switch',
        'not_configured',
        'item_not_allowed',
        'cost_cap',
        'day_cap',
        'session_cap',
      ]) {
        final FakeTutorClient c = FakeTutorClient()..rule = why;
        final TutorSession s = TutorSession(client: c);
        expect(await s.lineFor(ask()), isNull, reason: why);
        expect(s.available, isFalse, reason: why);
        expect(s.failures, 0, reason: why);
      }
    });

    test('a full prefetch allowance only stops prefetching, not the helper', () async {
      client.rule = 'prefetch_cap';
      await session.prefetch(ask(prefetch: true));
      expect(session.available, isTrue);
      final int asked = client.asked.length;
      await session.prefetch(ask(prefetch: true, item: 'other'));
      expect(client.asked.length, asked);
    });

    test('a refused line (validator) counts as a fault, one at a time', () async {
      client.rule = 'validator_failed';
      await session.lineFor(ask());
      expect(session.failures, 1);
      expect(session.available, isTrue);
    });
  });
}
