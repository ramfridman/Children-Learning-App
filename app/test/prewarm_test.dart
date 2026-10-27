// The pre-warm tool: it shows the count and cost first, refuses without the typed count, stays under its ceiling,
// and never prints the secret.
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../tool/prewarm_lib.dart';

const PrewarmRequest _request = PrewarmRequest(
  packId: 'starter',
  packVersion: '0.2.0',
  characters: <String>['nitzi'],
);

/// A fake server that has [total] lines to make, [cached] of them already made, at [microEach] per line.
class FakeGateway {
  FakeGateway({this.total = 40, this.cached = 0, this.microEach = 1000});

  final int total;
  int cached;
  final int microEach;
  final List<Map<String, Object?>> asked = <Map<String, Object?>>[];

  Future<Map<String, Object?>> send(Map<String, Object?> body) async {
    asked.add(body);
    switch (body['mode']) {
      case 'plan':
        final int todo = total - cached;
        return <String, Object?>{
          'lines': total,
          'cached': cached,
          'to_make': todo,
          'est_micro_usd': todo * microEach,
          'est_voice_chars': todo * 45,
          'est_eval_micro_usd': total * 400,
        };
      case 'make':
        final int offset = body['offset']! as int;
        final int limit = body['limit']! as int;
        final int end = (offset + limit).clamp(0, total);
        final int count = end - offset;
        return <String, Object?>{
          'made': count,
          'cached': 0,
          'failed': <String, Object?>{},
          'spent_micro_usd': count * microEach,
          'next_offset': end,
          'done': end >= total,
          'total': total,
        };
      case 'evaluate':
        final int from = body['offset']! as int;
        final int to = (from + (body['limit']! as int)).clamp(0, total);
        return <String, Object?>{
          'rows': <Object?>[
            for (int i = from; i < to; i++)
              <String, Object?>{
                'item': 'count.butterflies.3',
                'attempts': i.isEven ? 1 : 2,
                'firstTry': i.isEven,
                'passed': i % 5 != 0,
                'checks': i.isEven ? <Object?>[] : <Object?>['vocabulary'],
                'unknown': i.isEven ? <Object?>[] : <Object?>['נספור'],
                'say': 'x',
              },
          ],
          'spent_micro_usd': (to - from) * 300,
          'next_offset': to,
          'done': to >= total,
          'total': total,
        };
      default:
        return <String, Object?>{
          'runs': <Object?>[
            <String, Object?>{'server_ms': 900, 'model_ms': 500, 'voice_ms': 300},
            <String, Object?>{'server_ms': 700, 'model_ms': 400, 'voice_ms': 250},
            <String, Object?>{'server_ms': 1100, 'model_ms': 600, 'voice_ms': 350},
            <String, Object?>{
              'rule': 'model_failed',
              'detail': 'model status HTTP 404 not_found_error',
              'model_ms': 2100,
              'server_ms': 2100,
            },
          ],
          'spent_micro_usd': 4000,
        };
    }
  }
}

void main() {
  test(
    'the plan says how many lines, how many characters and what it costs, and calls nothing else',
    () async {
      final FakeGateway g = FakeGateway(total: 40, cached: 10, microEach: 2000);
      final PrewarmPlan p = await plan(g.send, _request);
      expect(p.toMake, 30);
      expect(p.voiceChars, 1350);
      expect(p.describe(), contains('30 to make'));
      expect(p.describe(), contains('0.06 USD'));
      expect(g.asked.map((Map<String, Object?> b) => b['mode']), <Object?>['plan']);
    },
  );

  test('without the typed number, or with the wrong one, nothing is made', () async {
    final FakeGateway g = FakeGateway();
    await expectLater(make(g.send, _request, confirmLines: null), throwsA(isA<PrewarmFailed>()));
    await expectLater(make(g.send, _request, confirmLines: 39), throwsA(isA<PrewarmFailed>()));
    expect(g.asked.map((Map<String, Object?> b) => b['mode']).toSet(), <Object?>{'plan'});
  });

  test('with the right number it makes every line in batches and reports what was spent', () async {
    final FakeGateway g = FakeGateway(total: 60);
    final List<String> said = <String>[];
    final PrewarmOutcome o = await make(g.send, _request, confirmLines: 60, say: said.add);
    expect(o.made, 60);
    expect(o.spentMicro, 60000);
    final Iterable<Map<String, Object?>> makes = g.asked.where(
      (Map<String, Object?> b) => b['mode'] == 'make',
    );
    expect(makes.map((Map<String, Object?> b) => b['offset']), <Object?>[0, 25, 50]);
    expect(said.first, contains('60 to make'), reason: 'the count and the cost are shown first');
  });

  test('nothing to make means no call to make', () async {
    final FakeGateway g = FakeGateway(total: 10, cached: 10);
    final PrewarmOutcome o = await make(g.send, _request, confirmLines: 0);
    expect(o.made, 0);
    expect(g.asked.length, 1);
  });

  test('the ceiling given to the server is one and a half times the estimate, less what was spent', () async {
    final FakeGateway g = FakeGateway(total: 50, microEach: 1000);
    await make(g.send, _request, confirmLines: 50);
    final List<Object?> ceilings = g.asked
        .where((Map<String, Object?> b) => b['mode'] == 'make')
        .map((Map<String, Object?> b) => b['max_micro_usd'])
        .toList();
    expect(ceilings.first, 75001);
    expect(ceilings.last, 75001 - 25000);
  });

  test('a server that stops making progress ends the run instead of looping', () async {
    int calls = 0;
    Future<Map<String, Object?>> stuck(Map<String, Object?> body) async {
      if (body['mode'] == 'plan') {
        return <String, Object?>{
          'lines': 5,
          'cached': 0,
          'to_make': 5,
          'est_micro_usd': 5000,
          'est_voice_chars': 225,
        };
      }
      calls++;
      return <String, Object?>{
        'made': 0,
        'cached': 0,
        'failed': <String, Object?>{'model_failed': 1},
        'spent_micro_usd': 0,
        'next_offset': 0,
        'done': false,
        'total': 5,
      };
    }

    await expectLater(make(stuck, _request, confirmLines: 5), throwsA(isA<PrewarmFailed>()));
    expect(calls, 1);
  });

  test('a measurement gives medians, and lines that fell back are counted apart', () async {
    final Measurement m = await measure(FakeGateway().send, _request);
    expect(m.medianServer, 900);
    expect(m.medianModel, 500);
    expect(m.medianVoice, 300);
    expect(m.rules, <String>['model_failed']);
    expect(m.describe(), contains('fell back to the authored line 1 times'));
    expect(m.describe(), contains('HTTP 404 not_found_error'), reason: 'the reason it gave up is shown');
  });

  test(
    'over http the secret goes in one header, and a refusal shows the short code and never the secret',
    () async {
      final HttpServer server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      addTearDown(() => server.close(force: true));
      final List<HttpRequest> seen = <HttpRequest>[];
      final List<String> bodies = <String>[];
      server.listen((HttpRequest req) async {
        seen.add(req);
        bodies.add(await utf8.decodeStream(req));
        if (req.headers.value('x-publish-secret') == 'right-secret-right-secret-right') {
          req.response
            ..statusCode = 200
            ..write(jsonEncode(<String, Object?>{'ok': true}));
        } else {
          req.response
            ..statusCode = 401
            ..write(jsonEncode(<String, Object?>{'error': 'unauthorized'}));
        }
        await req.response.close();
      });
      final String base = 'http://127.0.0.1:${server.port}';
      final Map<String, Object?> ok = await httpSend(
        baseUrl: base,
        secret: 'right-secret-right-secret-right',
      )(_request.body('plan'));
      expect(ok['ok'], isTrue);
      expect(seen.single.uri.path, '/functions/v1/tutor-prewarm');
      expect(
        bodies.single,
        isNot(contains('right-secret')),
        reason: 'the secret is a header, not part of the body',
      );

      Object? error;
      try {
        await httpSend(baseUrl: base, secret: 'wrong-secret-wrong-secret-wrong')(_request.body('plan'));
      } on PrewarmFailed catch (e) {
        error = e;
      }
      expect(error.toString(), 'the server refused: 401 unauthorized');
      expect(error.toString(), isNot(contains('wrong-secret')));
    },
  );

  test('evaluate shows the cost first, refuses without the typed count, then reports the pass rate and the lacking words', () async {
    final FakeGateway g = FakeGateway(total: 40);
    await expectLater(
      evaluate(g.send, _request, confirmLines: null),
      throwsA(
        isA<PrewarmFailed>().having(
          (PrewarmFailed e) => e.message,
          'message',
          contains('--confirm-lines 40'),
        ),
      ),
    );
    expect(
      g.asked.every((Map<String, Object?> b) => b['mode'] == 'plan'),
      isTrue,
      reason: 'nothing was asked',
    );
    final List<String> said = <String>[];
    final LineEvaluation e = await evaluate(g.send, _request, confirmLines: 40, say: said.add);
    expect(said.first, contains('0.02 USD'));
    expect(e.lines, 40);
    expect(e.firstTry, 20);
    expect(e.passed, 32);
    expect(e.refusedBy, <String, int>{'vocabulary': 20});
    expect(e.unknownWords.first.value, 20);
    expect(e.spentMicro, 40 * 300);
    expect(e.describe(), contains('32 passed the ten checks (80%)'));
  });
}
