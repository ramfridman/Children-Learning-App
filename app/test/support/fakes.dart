import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:nitznutz/core/clock.dart';
import 'package:nitznutz/core/config.dart';
import 'package:nitznutz/core/hosts.dart';
import 'package:nitznutz/device/device_key_service.dart';
import 'package:nitznutz/device/secure_store.dart';

const String testHost = 'example-project.supabase.co';
const String testKey = 'sb_publishable_test_only';

NetworkHosts testHosts() =>
    NetworkHosts.parse('{"hosts":[{"name":"t","host":"$testHost","scheme":"https","roles":["parent"]}]}');

AppConfig testConfig({bool dev = false}) =>
    AppConfig.parse(url: 'https://$testHost', key: testKey, flavor: dev ? 'dev' : 'prod', hosts: testHosts());

class FixedClock implements Clock {
  FixedClock(this.now);
  int now;

  @override
  int nowMs() => now;
}

/// A key service that signs nothing real: it returns a fixed "signature" and remembers what it
/// was asked to sign, so tests can compare it with the request headers.
class FakeKeys implements DeviceKeyService {
  final List<Uint8List> signed = <Uint8List>[];
  final List<Uint8List> challenges = <Uint8List>[];
  bool deleted = false;
  bool present = false;

  @override
  Future<DeviceKeyMaterial> createKey(Uint8List challenge) async {
    challenges.add(challenge);
    present = true;
    return DeviceKeyMaterial(
      publicKey: Uint8List.fromList(List<int>.generate(91, (int i) => i)),
      chain: <Uint8List>[
        Uint8List.fromList(List<int>.filled(120, 1)),
        Uint8List.fromList(List<int>.filled(120, 2)),
      ],
    );
  }

  @override
  Future<Uint8List> sign(Uint8List message) async {
    signed.add(message);
    return Uint8List.fromList(<int>[0x30, 0x06, 0x02, 0x01, 0x01, 0x02, 0x01, 0x01]);
  }

  @override
  Future<bool> hasKey() async => present;

  @override
  Future<void> deleteKey() async {
    deleted = true;
    present = false;
  }
}

class MemoryStore implements SecureStore {
  final Map<String, String> data = <String, String>{};

  @override
  Future<String?> read(String key) async => data[key];

  @override
  Future<void> write(String key, String value) async => data[key] = value;

  @override
  Future<void> delete(String key) async => data.remove(key);

  @override
  Future<void> clear() async => data.clear();
}

/// Records every request and answers from [handler].
class Recorder {
  Recorder(this.handler);

  final http.Response Function(http.Request request) handler;
  final List<http.Request> requests = <http.Request>[];

  MockClient get client => MockClient((http.Request request) async {
    requests.add(request);
    return handler(request);
  });
}

http.Response jsonReply(Object body, {int status = 200}) => http.Response.bytes(
  utf8.encode(jsonEncode(body)),
  status,
  headers: <String, String>{'content-type': 'application/json; charset=utf-8'},
);
