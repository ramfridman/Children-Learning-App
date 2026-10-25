import 'package:flutter_test/flutter_test.dart';
import 'package:nitznutz/core/log.dart';

void main() {
  test('tokens, keys, emails and codes never survive scrubbing', () {
    const String jwt = 'eyJhbGciOiJFUzI1NiJ9.eyJzdWIiOiIxMjMifQ.c2lnbmF0dXJl';
    final String publishable = <String>['sb', 'publishable', 'AbCdEf123'].join('_');
    const String long = 'AAECAwQFBgcICQoLDA0ODxAREhMUFRYXGBkaGxwdHh8gISIj';
    final String out = Log.scrub(
      'Authorization: Bearer abc.def.ghi jwt $jwt publishable $publishable '
      'mail=parent@example.test hash=$long code 123456 ok',
    );
    for (final String secret in <String>[
      'abc.def.ghi',
      jwt,
      publishable,
      'parent@example.test',
      long,
      '123456',
    ]) {
      expect(out, isNot(contains(secret)), reason: secret);
    }
    expect(out, contains('ok'));
  });

  test('ordinary text and ids pass through', () {
    const String text = 'device b6f0ed2e-0d4e-4dec-957b-0c0513f36096 role parent level tee';
    expect(Log.scrub(text), text);
  });

  test('a seven digit number is not a code', () {
    expect(Log.scrub('count 1234567'), 'count 1234567');
  });
}
