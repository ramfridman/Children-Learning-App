import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:nitznutz/core/config.dart';
import 'package:nitznutz/core/hosts.dart';

import 'support/fakes.dart';

String fakeJwt(Map<String, Object?> payload) {
  String part(Object value) => base64Url.encode(utf8.encode(jsonEncode(value))).replaceAll('=', '');
  return '${part(<String, Object?>{'alg': 'none'})}.${part(payload)}.sig';
}

void main() {
  group('NetworkHosts', () {
    final NetworkHosts hosts = testHosts();

    test('allows the listed host over https', () {
      expect(hosts.allows(Uri.parse('https://$testHost/functions/v1/x')), isTrue);
      expect(hosts.allows(Uri.parse('https://${testHost.toUpperCase()}/x')), isTrue);
    });

    test('refuses everything else', () {
      expect(hosts.allows(Uri.parse('http://$testHost/x')), isFalse);
      expect(hosts.allows(Uri.parse('https://evil.example/x')), isFalse);
      expect(hosts.allows(Uri.parse('https://$testHost:8443/x')), isFalse);
      expect(hosts.allows(Uri.parse('https://user@$testHost/x')), isFalse);
      expect(hosts.allows(Uri.parse('https://sub.$testHost/x')), isFalse);
      expect(hosts.allows(Uri.parse('https://$testHost.evil.example/x')), isFalse);
    });

    test('the real hosts file parses and lists only https hosts', () {
      final NetworkHosts real = NetworkHosts.parse(File('network_hosts.json').readAsStringSync());
      expect(real.allows(Uri.parse('https://ungkvkabqxssggttajfs.supabase.co/auth/v1/otp')), isTrue);
      expect(real.allows(Uri.parse('https://example.com/')), isFalse);
    });

    test('a hosts file with an http entry is rejected', () {
      expect(
        () => NetworkHosts.parse('{"hosts":[{"name":"x","host":"a.example","scheme":"http"}]}'),
        throwsFormatException,
      );
      expect(() => NetworkHosts.parse('{"hosts":[]}'), throwsFormatException);
    });
  });

  group('AppConfig', () {
    AppConfig parse({String url = 'https://$testHost', String key = testKey, String flavor = 'dev'}) =>
        AppConfig.parse(url: url, key: key, flavor: flavor, hosts: testHosts());

    test('accepts a publishable key', () {
      final AppConfig c = parse();
      expect(c.isDev, isTrue);
      expect(c.supabaseUrl.toString(), 'https://$testHost');
    });

    test('refuses a missing or unlisted URL', () {
      expect(() => parse(url: ''), throwsA(isA<ConfigException>()));
      expect(() => parse(url: 'https://other.example'), throwsA(isA<ConfigException>()));
      expect(() => parse(url: 'http://$testHost'), throwsA(isA<ConfigException>()));
    });

    test('refuses an empty or placeholder key', () {
      expect(() => parse(key: ''), throwsA(isA<ConfigException>()));
      expect(() => parse(key: 'paste the key here'), throwsA(isA<ConfigException>()));
    });

    test('refuses secret keys', () {
      expect(() => parse(key: 'sb_secret_abcdefghijklmnop'), throwsA(isA<ConfigException>()));
      expect(() => parse(key: fakeJwt(<String, Object?>{'role': 'service_role'})), throwsA(isA<ConfigException>()));
      expect(parse(key: fakeJwt(<String, Object?>{'role': 'anon'})).publishableKey, isNotEmpty);
    });

    test('refuses an unknown flavour', () {
      expect(() => parse(flavor: 'staging'), throwsA(isA<ConfigException>()));
    });
  });
}
