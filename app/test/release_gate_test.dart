// The release gate of a language's say-it (frame section 5.1): at most 1 in 20 of the readings that should not be confident, and most
// of the correct readings. Too few readings is never a pass.
import 'package:flutter_test/flutter_test.dart';
import 'package:nitznutz/speech/release_gate.dart';

GateCounts counts(int correct, int correctYes, int neg, int negYes) => GateCounts(
  correctReadings: correct,
  correctConfident: correctYes,
  negativeReadings: neg,
  negativeConfident: negYes,
);

void main() {
  test('enough readings, no confident foil, most correct heard: pass', () {
    final GateResult r = releaseGate(counts(100, 80, 100, 0));
    expect(r.verdict, GateVerdict.pass);
    expect(r.recall, 0.8);
    expect(r.upperBound, closeTo(0.03, 1e-9), reason: 'the rule of three: 3 / 100');
    expect(r.meetsStricterBar, isTrue);
  });

  test('60 foil readings with none confident show at most 5% and pass, but not the stricter 3%', () {
    final GateResult r = releaseGate(counts(30, 20, 60, 0));
    expect(r.verdict, GateVerdict.pass);
    expect(r.upperBound, closeTo(0.05, 1e-9));
    expect(r.meetsStricterBar, isFalse);
  });

  test('too few foil readings is not a pass, however good they were', () {
    final GateResult r = releaseGate(counts(100, 100, 59, 0));
    expect(r.verdict, GateVerdict.notEnough);
    expect(r.reasons.single, contains('59'));
  });

  test('too few correct readings is not a pass either', () {
    expect(releaseGate(counts(19, 19, 100, 0)).verdict, GateVerdict.notEnough);
  });

  test('more than 1 in 20 foils confident fails, even with few readings', () {
    expect(releaseGate(counts(100, 90, 100, 6)).verdict, GateVerdict.fail);
    expect(releaseGate(counts(100, 90, 20, 3)).verdict, GateVerdict.fail);
  });

  test('a single confident foil among few readings is not enough to say anything', () {
    expect(releaseGate(counts(100, 90, 10, 1)).verdict, GateVerdict.notEnough);
  });

  test('5 in 100 confident is the edge: the rate is at the bar, but the upper bound is above it', () {
    final GateResult r = releaseGate(counts(100, 90, 100, 5));
    expect(r.falseConfident, 0.05);
    expect(r.verdict, GateVerdict.notEnough, reason: 'the 95% bound of 5 in 100 is above 5%');
  });

  test('half or fewer of the correct readings confident fails: the language ships in echo mode', () {
    final GateResult r = releaseGate(counts(100, 50, 100, 0));
    expect(r.verdict, GateVerdict.fail);
    expect(r.reasons.single, contains('50%'));
  });

  test('a language passes only when every age band does; a missing band is not enough', () {
    final GateCounts good = counts(100, 80, 100, 0);
    expect(languageVerdict(<String, GateCounts>{'A': good, 'B': good, 'C': good}), GateVerdict.pass);
    expect(
      languageVerdict(<String, GateCounts>{'A': good, 'B': counts(10, 9, 10, 0)}),
      GateVerdict.notEnough,
    );
    expect(languageVerdict(<String, GateCounts>{'A': good, 'B': counts(100, 90, 100, 9)}), GateVerdict.fail);
    expect(languageVerdict(const <String, GateCounts>{}), GateVerdict.notEnough);
    expect(
      languageVerdict(<String, GateCounts>{'adult': good}),
      GateVerdict.notEnough,
      reason: 'adults alone cannot pass a language for children',
    );
    expect(
      languageVerdict(<String, GateCounts>{
        'A': good,
        'B': good,
        'C': good,
        'adult': counts(100, 90, 100, 9),
      }),
      GateVerdict.fail,
    );
  });

  test('counts add up', () {
    final GateCounts s = counts(1, 1, 2, 0) + counts(3, 2, 4, 1);
    expect(
      <int>[s.correctReadings, s.correctConfident, s.negativeReadings, s.negativeConfident],
      <int>[4, 3, 6, 1],
    );
  });
}
