// The runner of the minimum-sizes test (docs/agents/qa-min-sizes-2026-11-17.md): opens each layout of the pack on one board, reads what the
// screen drew, judges it by `min_sizes_rules.dart`, prints the table of what is under its floor and compares it with the one map of known
// failures (`min_sizes_known.dart`): a failure that is not in the map is a regression, an entry whose failure is gone (or whose measured value
// changed) must be taken out of (or updated in) the map. Every file of the test runs one board.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nitznutz/content/models.dart';
import 'package:nitznutz/design/stage_spec.dart';
import 'package:nitznutz/play/hint_hand.dart' show warmHintHands;
import 'package:nitznutz/play/lesson_screen.dart';

import 'bubble_audit.dart' show AuditLook, auditLooks;
import 'c1_screens.dart';
import 'min_sizes_known.dart';
import 'min_sizes_measure.dart';
import 'min_sizes_rules.dart';

/// One failed measurement: where (slice, screen), which rule, the worst value against its floor, and how many pieces were under it.
class Fail {
  Fail(this.id, this.rule, this.value, this.threshold, this.count, this.detail, this.template);
  final String id;
  final String rule;
  final double value;
  final double threshold;
  final int count;
  final String detail;
  final String template;
}

/// The look the child of an activity of each band is given: the one with the biggest tiles and caption of the band's own range.
const Map<String, int> lookOfBand = <String, int>{'A': 0, 'B': 1, 'C': 2};

const List<double> textScales = <double>[1.0, 1.3];

String _f(double v) => v.toStringAsFixed(1);

/// Rounds like the map does.
double r1(double v) => (v * 10).round() / 10;

class Slice {
  Slice(this.board, this.size, this.look, this.scale, this.kind);
  final String board;
  final Size size;
  final String look;
  final double scale;
  final String kind;
  String get prefix => '$board|$look|$scale|$kind|';
  int screens = 0;
  final List<Fail> rows = <Fail>[];
}

/// Opens [a] on the lesson screen like `openOne`, with the waits cut to what the layout needs.
Future<void> openFast(WidgetTester t, PackContent content, Activity a, {int settleMs = 900}) async {
  final NavigatorState nav = t.state<NavigatorState>(find.byType(Navigator).first);
  final Lesson one = Lesson.mission(
    id: 'shot',
    itemIds: <String>[a.id],
    skillIds: a.skills.map((Skill s) => s.id).toList(),
    celebration: content.lessons['butterflies']!.celebration,
  );
  nav.push(
    MaterialPageRoute<void>(
      builder: (BuildContext c) => LessonScreen(profileId: 'p-1', mission: one),
    ),
  );
  await t.pump(const Duration(milliseconds: 500));
  await waitSteps(t, settleMs);
}

/// Reads and judges the screen the tester shows, adding the failures to [slice] under [name].
/// [inherited] are the findings of the activity's own screen: a hint slice lists only what the hint adds or makes worse.
void measure(
  WidgetTester t,
  Slice slice,
  String name,
  String template,
  RuleCtx ctx,
  List<FlutterErrorDetails> errors, {
  Map<String, Finding> inherited = const <String, Finding>{},
}) {
  final Screen s = readScreen(t, slice.size, slice.scale);
  slice.screens++;
  if (Platform.environment['MIN_SIZES_DEBUG'] != null) {
    // ignore: avoid_print
    print(
      'SCREEN ${slice.prefix}$name texts ${s.texts.length} pictures ${s.pictures.length} tiles ${s.tiles.length} drags ${s.drags.length} keys ${s.keyed.keys.where((String k) => k.endsWith('stage')).join(',')}',
    );
  }
  final List<Finding> found = judge(s, ctx);
  expect(
    found.map((Finding f) => f.rule).toSet().length,
    found.length,
    reason: 'a rule reported twice for one screen: $name',
  );
  if (errors.isNotEmpty) {
    found.add(
      Finding('LAYOUT_ERROR', 0, 1, errors.length, errors.first.exceptionAsString().split('\n').first),
    );
    errors.clear();
  }
  for (final Finding f in found) {
    final Finding? same = inherited[f.rule];
    if (same != null && (same.value - f.value).abs() < 0.15 && same.count == f.count) continue;
    slice.rows.add(
      Fail('${slice.prefix}$name|${f.rule}', f.rule, r1(f.value), f.threshold, f.count, f.detail, template),
    );
  }
}

/// Prints the table of a slice and asserts it against the known failures.
void report(Slice slice) {
  final Map<String, int> by = <String, int>{};
  for (final Fail r in slice.rows) {
    by[r.rule] = (by[r.rule] ?? 0) + 1;
  }
  final Map<String, int> sev = <String, int>{'S1': 0, 'S2': 0, 'S3': 0};
  for (final Fail r in slice.rows) {
    final String s = rules[r.rule]!.sev;
    sev[s] = sev[s]! + 1;
  }
  // ignore: avoid_print
  print(
    'MINSIZES ${slice.board} look ${slice.look} text ${slice.scale} ${slice.kind}: ${slice.screens} screens, '
    '${slice.rows.length} failing measurements (S1 ${sev['S1']}, S2 ${sev['S2']}, S3 ${sev['S3']}); '
    '${(by.entries.toList()..sort((MapEntry<String, int> a, MapEntry<String, int> b) => b.value.compareTo(a.value))).map((MapEntry<String, int> e) => '${e.key} ${e.value}').join(', ')}',
  );
  final String? out = Platform.environment['MIN_SIZES_OUT'];
  if (out != null) {
    File('$out/${slice.board}.txt').writeAsStringSync(
      slice.rows
              .map(
                (Fail r) =>
                    "  '${r.id}': Known('${r.rule}', ${_f(r.value)}, ${_f(r.threshold)}, ${r.count}),",
              )
              .join('\n') +
          (slice.rows.isEmpty ? '' : '\n'),
      mode: FileMode.append,
    );
    File('$out/${slice.board}_detail.txt').writeAsStringSync(
      slice.rows
              .map((Fail r) => '${r.id}\t${r.template}\t${r.value}\t${r.threshold}\t${r.count}\t${r.detail}')
              .join('\n') +
          (slice.rows.isEmpty ? '' : '\n'),
      mode: FileMode.append,
    );
    return;
  }
  final Map<String, Known> known = <String, Known>{
    for (final MapEntry<String, Known> e in knownFailures.entries)
      if (e.key.startsWith(slice.prefix)) e.key: e.value,
  };
  final Map<String, Fail> got = <String, Fail>{for (final Fail r in slice.rows) r.id: r};
  final List<String> problems = <String>[];
  for (final Fail r in got.values) {
    final Known? k = known[r.id];
    if (k == null) {
      problems.add(
        'NEW   ${r.id}: ${r.rule} measured ${_f(r.value)} against ${_f(r.threshold)} (${r.count}x) ${r.detail}',
      );
    } else if ((k.value - r.value).abs() > 0.5 || k.count != r.count) {
      problems.add(
        'MOVED ${r.id}: the map says ${_f(k.value)} (${k.count}x), now ${_f(r.value)} (${r.count}x): update the entry (or remove it if it is above ${_f(r.threshold)})',
      );
    }
  }
  for (final String id in known.keys) {
    if (!got.containsKey(id)) problems.add('FIXED $id: no longer failing, remove it from knownFailures');
  }
  expect(
    problems,
    isEmpty,
    reason: '${problems.length} differences from the map of known failures:\n${problems.take(40).join('\n')}',
  );
}

/// The looks of the audit by index.
AuditLook lookAt(int i) => auditLooks[i];

Future<void> setScale(WidgetTester t, double scale) async {
  t.platformDispatcher.textScaleFactorTestValue = scale;
  addTearDown(t.platformDispatcher.clearAllTestValues);
}

Future<void> warm(WidgetTester t) => t.runAsync(warmHintHands);

/// The `StageSpec` of the child on screen (for the name of the look).
StageSpec? lookOnScreen(WidgetTester t) {
  final Finder f = find.byType(StageScope);
  return f.evaluate().isEmpty ? null : (f.evaluate().first.widget as StageScope).stage;
}
