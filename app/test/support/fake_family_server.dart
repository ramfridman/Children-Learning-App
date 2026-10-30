// A fake of the gateway's sync functions that behaves like the real ones (the Deno tests prove the real ones): one
// family, a log numbered by the server, profiles with nicknames, tombstones, duplicates ignored, unknown or deleted
// children refused. Devices call it through [callFor], which can be made to fail or to lose its answer.
import 'dart:convert';
import 'dart:io';

import 'package:nitznutz/core/errors.dart';

/// One key of an event as `sync-push` takes it: is [value] of the right type, in its pattern, range or values?
typedef _Check = bool Function(Object? value);

_Check _checkOf(Map<String, Object?> f) {
  final RegExp? pattern = f['pattern'] == null ? null : RegExp(f['pattern']! as String);
  return switch (f['t']) {
    'uuid' => (Object? v) => v is String && pattern!.hasMatch(v),
    'string' => (
      Object? v,
    ) => v is String && v.length <= (f['max']! as int) && (pattern?.hasMatch(v) ?? true),
    'int' => (Object? v) => v is int && v >= (f['min']! as int) && v <= (f['max']! as int),
    'enum' => (Object? v) => v is String && (f['values']! as List<Object?>).contains(v),
    'object' => (Object? v) => v is Map<String, Object?>,
    _ => throw StateError('wire-patterns.json: unknown type ${f['t']}'),
  };
}

/// Everything `sync-push` takes in an event (`testvectors/wire-patterns.json`, tested equal to the server).
final ({
  int maxEvents,
  Map<String, _Check> event,
  Map<String, _Check> data,
  Map<String, List<String>> required,
  Map<String, _Check> alert,
  Set<String> wordCategories,
})
_wire = () {
  final Map<String, Object?> v =
      jsonDecode(File('../testvectors/wire-patterns.json').readAsStringSync()) as Map<String, Object?>;
  Map<String, _Check> checks(String key) => <String, _Check>{
    for (final MapEntry<String, Object?> e in (v[key]! as Map<String, Object?>).entries)
      e.key: _checkOf(e.value! as Map<String, Object?>),
  };
  return (
    maxEvents: v['max_events']! as int,
    event: checks('event_fields'),
    data: checks('data_fields'),
    required: <String, List<String>>{
      for (final MapEntry<String, Object?> e in (v['required']! as Map<String, Object?>).entries)
        e.key: <String>[for (final Object? k in e.value! as List<Object?>) k! as String],
    },
    alert: checks('alert_create'),
    wordCategories: <String>{
      for (final Object? c in v['alert_word_categories']! as List<Object?>) c! as String,
    },
  );
}();

class FakeFamilyServer {
  FakeFamilyServer({this.checksFormat = false});

  /// Refuses a whole `sync-push` with `bad_request` when one event is not in the format the real server takes (an unknown
  /// key, a missing one, a value outside its pattern, range or values, too many events), as the real one does.
  final bool checksFormat;

  /// Keys of an event's data this server does not know (with [checksFormat]): a gateway older than the app, or one
  /// deployed with a field removed. An event that carries one is refused.
  Set<String> forgets = <String>{};

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
        if (checksFormat) _checkEvents(body['events']! as List<Object?>);
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
        _checkAlert(body);
        final String? child = body['child_id'] as String?;
        if (child != null && !children.containsKey(child)) return <String, Object?>{'status': 'refused'};
        final Map<String, Object?>? have = alerts
            .where((Map<String, Object?> a) => a['key'] == body['key'])
            .firstOrNull;
        if (have != null) {
          // As the server: only a word alert said again keeps the higher count (QA-43).
          if (_wire.wordCategories.contains(have['category']) &&
              have['category'] == body['category'] &&
              (body['count']! as int) > (have['count'] as int? ?? 0)) {
            have['count'] = body['count'];
          }
          return <String, Object?>{'status': 'duplicate'};
        }
        // As the server: the words are dropped when the family does not keep them (SEC-28).
        alerts.add(<String, Object?>{
          ...body,
          'child_id': child,
          'id': 'a${alerts.length}',
          'read_at': null,
          if (!keepsWords) 'words': '',
        });
        return <String, Object?>{'status': 'new'};
      case 'alert-list':
        if (!parent) throw StateError('forbidden');
        return <String, Object?>{
          'alerts': <Map<String, Object?>>[
            for (final Map<String, Object?> a in alerts)
              <String, Object?>{...a, if (!keepsWords) 'words': ''},
          ],
        };
      case 'settings-put':
        if (!parent) throw StateError('forbidden');
        rules = jsonDecode(body['rules_json']! as String) as Map<String, Object?>;
        // As the server: turning "keep the words" off empties the words of every alert (SEC-28).
        if (!keepsWords) {
          for (final Map<String, Object?> a in alerts) {
            a['words'] = '';
          }
        }
        return <String, Object?>{'version': ++rulesVersion};
      case 'settings-get':
        return <String, Object?>{'rules': rules, 'version': rulesVersion};
    }
    throw StateError('unknown function $name');
  }

  /// Whether the family keeps the child's words (the default until a parent says no).
  bool get keepsWords => rules?['keepWords'] != false;

  /// The schema check of the real `alert-create` (testvectors/wire-patterns.json): a known key with a value it takes,
  /// the keys it needs, a child unless the alert is about the gate, and words only on a word alert.
  void _checkAlert(Map<String, Object?> body) {
    bool fits() {
      for (final MapEntry<String, Object?> e in body.entries) {
        final _Check? check = _wire.alert[e.key];
        if (check == null || !check(e.value)) return false;
      }
      if (!<String>['category', 'severity', 'count', 'key', 'at'].every(body.containsKey)) return false;
      if (body['category'] != 'gateAttempts' && body['child_id'] == null) return false;
      final String words = body['words'] as String? ?? '';
      return words.isEmpty || _wire.wordCategories.contains(body['category']);
    }

    if (!fits()) throw const GatewayException('bad_request', status: 400);
  }

  /// The schema check of the real `sync-push`, then its check of the keys each type must carry.
  void _checkEvents(List<Object?> events) {
    bool fits(
      Map<String, _Check> shape,
      Object? raw, {
      required bool allOptional,
      Set<String> unknown = const <String>{},
    }) {
      if (raw is! Map<String, Object?>) return false;
      if (raw.keys.any((String k) => !shape.containsKey(k) || unknown.contains(k))) return false;
      for (final MapEntry<String, _Check> f in shape.entries) {
        if (!raw.containsKey(f.key)) {
          if (allOptional) continue;
          return false;
        }
        if (!f.value(raw[f.key])) return false;
      }
      return true;
    }

    final bool ok =
        events.length <= _wire.maxEvents &&
        events.every((Object? raw) {
          if (!fits(_wire.event, raw, allOptional: false)) return false;
          final Map<String, Object?> e = raw! as Map<String, Object?>;
          final Map<String, Object?> data = e['data']! as Map<String, Object?>;
          return fits(_wire.data, data, allOptional: true, unknown: forgets) &&
              _wire.required[e['type']]!.every(data.containsKey);
        });
    if (!ok) throw const GatewayException('bad_request', status: 400);
  }
}
