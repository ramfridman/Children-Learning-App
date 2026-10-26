// Plays invented children with planted gaps against the real learning engine and prints how often the
// engine finds the gap within 1, 2 and 3 probes. Run from the app/ folder:
//
//   dart run tool/simulate.dart [--children 1000] [--seed 20261026]
import 'dart:io';

import 'package:nitznutz/engine/simulator.dart';

void main(List<String> args) {
  int option(String name, int fallback) {
    final int i = args.indexOf(name);
    return i >= 0 && i + 1 < args.length ? int.parse(args[i + 1]) : fallback;
  }

  final int children = option('--children', 1000);
  final int seed = option('--seed', 20261026);
  stdout.writeln('Invented children against the engine (seed $seed, $children children per row).');
  stdout.writeln(
    '"within N" = the planted gap was named exactly after at most N probes; "wrong" = a gap that was not planted.',
  );
  stdout.writeln('');
  final List<GapReport> rows = <GapReport>[
    gapReport(label: 'one gap, history on 0% of skills', children: children, seed: seed, coverage: 0.0),
    gapReport(label: 'one gap, history on 50% of skills', children: children, seed: seed, coverage: 0.5),
    gapReport(label: 'one gap, history on 80% of skills', children: children, seed: seed, coverage: 0.8),
    gapReport(
      label: 'two gaps, history on 50% of skills',
      children: children,
      seed: seed,
      gaps: 2,
      coverage: 0.5,
    ),
    falseGapReport(children: children, seed: seed),
  ];
  rows.forEach(stdout.writeln);
}
