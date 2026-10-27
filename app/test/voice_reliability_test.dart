import 'package:flutter_test/flutter_test.dart';
import 'package:nitznutz/speech/reliability.dart';

List<VoiceListenRow> rows(List<String> outcomes, DateTime at) => <VoiceListenRow>[
  for (final String o in outcomes) VoiceListenRow(at, o),
];

void main() {
  final DateTime now = DateTime.utc(2026, 11, 10, 9);

  test('voice is offered until there is enough to judge by', () {
    expect(voiceWorks(const <VoiceListenRow>[], now: now), isTrue);
    expect(voiceWorks(rows(<String>['unclear', 'unclear', 'silent'], now), now: now), isTrue);
  });

  test('a child whom recognition keeps failing is quietly not invited any more', () {
    expect(
      voiceWorks(rows(<String>['unclear', 'silent', 'failed', 'unclear', 'accepted'], now), now: now),
      isFalse,
    );
  });

  test('a child it works for stays invited, even after a few misses', () {
    expect(
      voiceWorks(
        rows(<String>['accepted', 'unclear', 'confirmed', 'accepted', 'silent', 'accepted'], now),
        now: now,
      ),
      isTrue,
    );
  });

  test('"no, that is not what I said" counts against it, and a heard intent does not', () {
    expect(
      voiceWorks(rows(<String>['declined', 'declined', 'declined', 'declined', 'accepted'], now), now: now),
      isFalse,
    );
    expect(voiceWorks(rows(<String>['intent', 'intent', 'accepted', 'confirmed'], now), now: now), isTrue);
  });

  test('it is tried again after a week', () {
    final List<String> bad = <String>['unclear', 'silent', 'unclear', 'unclear', 'silent'];
    expect(voiceWorks(rows(bad, now.subtract(const Duration(days: 3))), now: now), isFalse);
    expect(voiceWorks(rows(bad, now.subtract(const Duration(days: 8))), now: now), isTrue);
  });
}
