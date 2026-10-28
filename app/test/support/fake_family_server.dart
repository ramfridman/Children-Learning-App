// A fake of the gateway's sync functions that behaves like the real ones (the Deno tests prove the real ones): one
// family, a log numbered by the server, profiles with nicknames, tombstones, duplicates ignored, unknown or deleted
// children refused. Devices call it through [callFor], which can be made to fail or to lose its answer.
import 'dart:convert';
import 'dart:io';

import 'package:nitznutz/core/errors.dart';

/// The text fields of an answer as `sync-push` takes them (`testvectors/wire-patterns.json`, tested equal to the server).
final Map<String, ({RegExp pattern, int max})> _attemptFields = () {
  final Map<String, Object?> v =
      jsonDecode(File('../testvectors/wire-patterns.json').readAsStringSync()) as Map<String, Object?>;
  return <String, ({RegExp pattern, int max})>{
    for (final MapEntry<String, Object?> e in (v['attempt_fields']! as Map<String, Object?>).entries)
      e.key: (
        pattern: RegExp((e.value! as Map<String, Object?>)['pattern']! as String),
        max: (e.value! as Map<String, Object?>)['max']! as int,
      ),
  };
}();

class FakeFamilyServer {
  FakeFamilyServer({this.checksAnswers = false});

  /// Refuses a whole `sync-push` with `bad_request` when one answer has a text field the real server would not take, as
  /// the real one does.
  final bool checksAnswers;

  final List<Map<String, Object?>> log = <Map<String, Object?>>[];
  final Map<String, Map<String, Object?>> children = <String, Map<String, Object?>>{};
  final List<String> tombstones = <String>[];
  final List<String> calls = <String>[];
  final List<Map<String, Object?>> alerts = <Map<String, Object?>>[];
  Map<String, Object?>? rules;
  int rulesVersion = 0;
  int _seq = 0;

  /// While true every call fails (the phone is offline).
  bool offline = false;

  /// The next call that names this function does its work and then fails, as if the answer was lost on the way.
  String? loseAnswerOf;

  /// Fails the Nth `sync-pull` call from now on (1 for the next one), to test that a half-done pull resumes.
  int failPullNumber = 0;
  int _pulls = 0;

  Future<Map<String, Object?>> Function(String, Map<String, Object?>) callFor(
    String deviceId, {
    bool parent = true,
  }) {
    return (String name, Map<String, Object?> body) async {
      calls.add('$deviceId:$name');
      if (name == 'sync-pull') _pulls++;
      if (offline) throw StateError('offline');
      final Map<String, Object?> answer = _handle(deviceId, name, body, parent);
      if (loseAnswerOf == name) {
        loseAnswerOf = null;
        throw StateError('the answer was lost');
      }
      return answer;
    };
  }

  Map<String, Object?> _handle(String deviceId, String name, Map<String, Object?> body, bool parent) {
    switch (name) {
      case 'child-put':
        if (!parent) throw StateError('forbidden');
        final String id = body['child_id']! as String;
        if (tombstones.contains(id)) throw StateError('child_deleted');
        children[id] = <String, Object?>{
          'id': id,
          'nickname': body['nickname'],
          'avatar_id': body['avatar_id'],
          'companion_id': body['companion_id'],
          'outfit_id': body['outfit_id'],
          'address_form': body['address_form'],
          'age_band': body['age_band'],
        };
        return <String, Object?>{'ok': true};
      case 'child-delete':
        if (!parent) throw StateError('forbidden');
        final String id = body['child_id']! as String;
        children.remove(id);
        log.removeWhere((Map<String, Object?> e) => e['child_id'] == id);
        alerts.removeWhere((Map<String, Object?> a) => a['child_id'] == id);
        if (!tombstones.contains(id)) tombstones.add(id);
        return <String, Object?>{'ok': true};
      case 'sync-push':
        if (checksAnswers) _checkAnswers(body['events']! as List<Object?>);
        int accepted = 0;
        int duplicates = 0;
        final List<String> refused = <String>[];
        for (final Object? raw in body['events']! as List<Object?>) {
          final Map<String, Object?> e = raw! as Map<String, Object?>;
          if (!children.containsKey(e['child_id'])) {
            refused.add(e['id']! as String);
          } else if (log.any((Map<String, Object?> x) => x['id'] == e['id'])) {
            duplicates++;
          } else {
            log.add(<String, Object?>{...e, 'seq': ++_seq, 'device_id': deviceId});
            accepted++;
          }
        }
        return <String, Object?>{'accepted': accepted, 'duplicates': duplicates, 'refused': refused};
      case 'sync-pull':
        if (failPullNumber != 0 && _pulls == failPullNumber) throw StateError('pull failed');
        final int after = body['after']! as int;
        final int limit = body['limit']! as int;
        final List<Map<String, Object?>> later =
            log.where((Map<String, Object?> e) => (e['seq']! as int) > after).toList()
              ..sort((a, b) => (a['seq']! as int).compareTo(b['seq']! as int));
        final List<Map<String, Object?>> page = later.take(limit).toList();
        return <String, Object?>{
          'events': page,
          'more': later.length > limit,
          'next': page.isEmpty ? after : page.last['seq'],
          'children': children.values.toList(),
          'tombstones': List<String>.of(tombstones),
        };
      case 'alert-create':
        final String? child = body['child_id'] as String?;
        if (child != null && !children.containsKey(child)) return <String, Object?>{'status': 'refused'};
        if (alerts.any((Map<String, Object?> a) => a['key'] == body['key'])) {
          return <String, Object?>{'status': 'duplicate'};
        }
        alerts.add(<String, Object?>{...body, 'child_id': child, 'id': 'a${alerts.length}', 'read_at': null});
        return <String, Object?>{'status': 'new'};
      case 'alert-list':
        if (!parent) throw StateError('forbidden');
        return <String, Object?>{'alerts': List<Map<String, Object?>>.of(alerts)};
      case 'settings-put':
        if (!parent) throw StateError('forbidden');
        rules = jsonDecode(body['rules_json']! as String) as Map<String, Object?>;
        return <String, Object?>{'version': ++rulesVersion};
      case 'settings-get':
        return <String, Object?>{'rules': rules, 'version': rulesVersion};
    }
    throw StateError('unknown function $name');
  }

  void _checkAnswers(List<Object?> events) {
    for (final Object? raw in events) {
      final Map<String, Object?> e = raw! as Map<String, Object?>;
      if (e['type'] != 'attempt') continue;
      final Map<String, Object?> d = e['data']! as Map<String, Object?>;
      for (final MapEntry<String, ({RegExp pattern, int max})> f in _attemptFields.entries) {
        final Object? v = d[f.key];
        if (v == null) continue;
        if (v is! String || v.length > f.value.max || !f.value.pattern.hasMatch(v)) {
          throw const GatewayException('bad_request', status: 400);
        }
      }
    }
  }
}
