import 'package:flutter_test/flutter_test.dart';
import 'package:nitznutz/engine/simulator.dart';

/// The acceptance test of M3: invented children with planted gaps play against the real engine.
/// `dart run tool/simulate.dart` prints the whole table.
void main() {
  const int seed = 20261026;

  test('the engine finds the planted gap within 3 probes in at least 90% of 1,000 children (history on 80% of skills)', () {
    final GapReport r = gapReport(label: 'one gap, 80% history', children: 1000, seed: seed, coverage: 0.8);
    // ignore: avoid_print
    print(r);
    expect(r.rateWithin3, greaterThanOrEqualTo(0.90));
    expect(r.wrong / r.total, lessThan(0.06), reason: 'gaps that were not planted');
  });

  test('with less history the engine does worse but never invents gaps in bulk, and finds most within 3 probes at 50%', () {
    final GapReport half = gapReport(label: 'one gap, 50% history', children: 500, seed: seed, coverage: 0.5);
    // ignore: avoid_print
    print(half);
    expect(half.rateWithin3, greaterThanOrEqualTo(0.88));
    expect(half.wrong / half.total, lessThan(0.10));
    final GapReport two = gapReport(
      label: 'two gaps, 50% history',
      children: 500,
      seed: seed,
      gaps: 2,
      coverage: 0.5,
    );
    // ignore: avoid_print
    print(two);
    expect(two.rateWithin3, greaterThanOrEqualTo(0.88));
  });

  test('with no history at all the engine is half blind: it finds about half and is wrong about a quarter (a bound, not a goal)', () {
    final GapReport none = gapReport(label: 'one gap, no history', children: 500, seed: seed, coverage: 0.0);
    // ignore: avoid_print
    print(none);
    expect(none.wrong / none.total, lessThan(0.30));
    expect(none.rateWithin3, greaterThan(0.45));
  });

  test('a child who knows everything but slips twice is not given a gap (under 5%)', () {
    final GapReport r = falseGapReport(children: 1000, seed: seed);
    // ignore: avoid_print
    print(r);
    expect(r.wrong / r.total, lessThan(0.05));
  });

  test('the same seed gives the same table (the simulation is reproducible)', () {
    final GapReport a = gapReport(label: 'a', children: 60, seed: 7, coverage: 0.8);
    final GapReport b = gapReport(label: 'a', children: 60, seed: 7, coverage: 0.8);
    expect(a.toString(), b.toString());
  });
}
