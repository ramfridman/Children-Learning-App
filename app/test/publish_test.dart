import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:nitznutz/content/pack_verify.dart';

import '../tool/publish_lib.dart';

Future<VerifiedPack> _load(String path) async => verifyPack(
  File(path).readAsBytesSync(),
  publicKey: unhex(File('assets/pack_signing_public_key.txt').readAsStringSync()),
);

const String _vectors = '../testvectors/publish-starter.json';

void main() {
  late Map<String, Object?> starter;
  setUpAll(() async => starter = indexOf(await _load('assets/packs/starter-0.2.0.nnpack')));

  test(
    'the starter pack gives its five activities and four misconceptions, with the facts the prompt needs',
    () {
      final List<Object?> items = starter['items']! as List<Object?>;
      expect(items.length, 5);
      expect((starter['misconceptions']! as List<Object?>).length, 4);
      final Map<String, Object?> count = items.cast<Map<String, Object?>>().firstWhere(
        (Map<String, Object?> i) => i['item_id'] == 'count.butterflies.3',
      );
      expect(count['template'], 'count_tap');
      expect(count['band'], 'A');
      expect(count['skill_ids'], <String>['NUM-A-03', 'NUM-A-04']);
      expect(count['llm_allowed'], isTrue);
      expect(count['hint_threshold'], 3);
      expect(count['number_set'], <int>[2, 3, 4]);
      expect(count['allowed_actions'], containsAll(<String>['replay_prompt_slow', 'show_fingers']));
      expect(count['object_ids'], containsAll(<String>['o1', 'o2', 'obj-0', 'obj-2']));
      final List<Map<String, Object?>> answers = (count['answers']! as List<Object?>)
          .cast<Map<String, Object?>>();
      expect(answers.where((Map<String, Object?> a) => a['correct'] == true).single['value'], 3);
      expect(answers.any((Map<String, Object?> a) => a['misconception'] == 'M-CNT-DOUBLE'), isTrue);
      expect(count['prompt_text'], contains('פַּרְפָּרִים'));
    },
  );

  test('"give N" and "tap the answer" activities are indexed too, with one right answer each', () {
    final List<Map<String, Object?>> items = (starter['items']! as List<Object?>)
        .cast<Map<String, Object?>>();
    for (final Map<String, Object?> i in items) {
      final List<Map<String, Object?>> a = (i['answers']! as List<Object?>).cast<Map<String, Object?>>();
      expect(a.where((Map<String, Object?> x) => x['correct'] == true).length, 1, reason: '${i['item_id']}');
      expect(i['hint_threshold'], inInclusiveRange(1, 3));
    }
    final Map<String, Object?> give = items.firstWhere((Map<String, Object?> i) => i['template'] == 'give_n');
    expect((give['answers']! as List<Object?>).cast<Map<String, Object?>>().first['value'], 4);
    final Map<String, Object?> flower = items.firstWhere(
      (Map<String, Object?> i) => i['item_id'] == 'pick.red.flower',
    );
    expect(flower['llm_allowed'], isFalse);
  });

  test('nothing but text for the prompt goes up: no audio, no pictures, no ids of a device or a child', () {
    final String json = jsonEncode(starter);
    expect(json, isNot(contains('.svg')));
    expect(json, isNot(contains('.mp3')));
    expect(json, isNot(contains('vo:')));
    expect(RegExp(r'[0-9a-f]{8}-[0-9a-f]{4}-4').hasMatch(json), isFalse);
  });

  test('the index of the starter pack equals the shared vector the gateway test publishes', () {
    final String now = const JsonEncoder.withIndent('  ').convert(starter);
    if (Platform.environment['NN_UPDATE_VECTORS'] == '1') {
      File(_vectors).writeAsStringSync('$now\n');
    }
    expect(File(_vectors).readAsStringSync().replaceAll('\r\n', '\n').trim(), now.trim());
  });

  test(
    'a character pack gives its character; a family name keeps only what follows the child\'s name',
    () async {
      final Map<String, Object?> nitzi = indexOf(await _load('assets/characters/char-nitzi-1.0.0.nnpack'));
      final Map<String, Object?> c = (nitzi['characters']! as List<Object?>)
          .cast<Map<String, Object?>>()
          .single;
      expect(c['character_id'], 'nitzi');
      expect(c['gender'], 'f');
      expect(c['personal'], isFalse);
      expect(c.containsKey('voice_id'), isFalse, reason: 'no voice chosen yet');
      expect(nitzi['items'], isEmpty);
      final Map<String, Object?> withVoice = indexOf(
        await _load('assets/characters/char-nitzi-1.0.0.nnpack'),
        voices: <String, String>{'nitzi': 'abcDEF0123456789'},
      );
      expect(
        ((withVoice['characters']! as List<Object?>).single! as Map<String, Object?>)['voice_id'],
        'abcDEF0123456789',
      );
    },
  );

  group('sending', () {
    late HttpServer server;
    late List<Map<String, Object?>> seen;
    int status = 200;

    setUp(() async {
      seen = <Map<String, Object?>>[];
      status = 200;
      server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      unawaited(
        server.forEach((HttpRequest r) async {
          seen.add(<String, Object?>{
            'path': r.uri.path,
            'secret': r.headers.value('x-publish-secret'),
            'region': r.headers.value('x-region'),
            'body': jsonDecode(await utf8.decodeStream(r)),
          });
          r.response.statusCode = status;
          r.response.write(status == 200 ? '{"result":"published"}' : '{"error":"unauthorized"}');
          await r.response.close();
        }),
      );
    });
    tearDown(() => server.close(force: true));

    test('posts the index to content-publish with the secret in one header', () async {
      final Map<String, Object?> answer = await publish(
        starter,
        baseUrl: 'http://127.0.0.1:${server.port}',
        secret: 'a-long-enough-test-value-0123456789',
      );
      expect(answer['result'], 'published');
      expect(seen.single['path'], '/functions/v1/content-publish');
      expect(seen.single['secret'], 'a-long-enough-test-value-0123456789');
      expect(seen.single['region'], 'eu-central-1');
      expect((seen.single['body']! as Map<String, Object?>)['pack_id'], 'starter');
    });

    test('a refusal is reported by its code only', () async {
      status = 401;
      await expectLater(
        publish(
          starter,
          baseUrl: 'http://127.0.0.1:${server.port}',
          secret: 'a-long-enough-test-value-0123456789',
        ),
        throwsA(
          isA<PublishFailed>().having(
            (PublishFailed e) => e.message,
            'message',
            allOf(contains('401'), contains('unauthorized'), isNot(contains('a-long-enough'))),
          ),
        ),
      );
    });
  });

  test('the secret is never printed or written by the publish code', () {
    for (final String f in <String>['tool/publish_lib.dart', 'tool/pack_builder.dart']) {
      final String src = File(f).readAsStringSync();
      expect(
        RegExp(r'(print|stdout\.write\w*|stderr\.write\w*)\([^;]*secret', caseSensitive: false).hasMatch(src),
        isFalse,
        reason: f,
      );
      expect(src, isNot(contains('writeAsString(secret')));
    }
  });
}
