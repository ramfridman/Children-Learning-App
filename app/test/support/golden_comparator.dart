import 'dart:typed_data';

import 'package:flutter/foundation.dart' show FlutterError;

import 'package:flutter_test/flutter_test.dart';

/// Compares golden images but forgives a small share of different pixels. Text is anti-aliased a
/// little differently on Windows and Linux, so a strict comparison would fail on CI for no real reason.
class TolerantGoldenComparator extends LocalFileComparator {
  TolerantGoldenComparator(super.testFile, this.tolerance);

  /// The largest share of differing pixels that still passes (0.03 is 3 percent).
  final double tolerance;

  /// The tolerance for [golden]: the file's own, or [windowsMadeTolerance] for a named shot of
  /// [windowsMadeShots] (never lower than the file's).
  double toleranceFor(Uri golden) {
    final String name = golden.pathSegments.isEmpty ? '' : golden.pathSegments.last;
    if (windowsMadeShots.contains(name) && windowsMadeTolerance > tolerance) {
      return windowsMadeTolerance;
    }
    return tolerance;
  }

  @override
  Future<bool> compare(Uint8List imageBytes, Uri golden) async {
    final ComparisonResult result = await GoldenFileComparator.compareLists(
      imageBytes,
      await getGoldenBytes(golden),
    );
    if (!result.passed && result.diffPercent > toleranceFor(golden)) {
      final String error = await generateFailureOutput(result, golden, basedir);
      throw FlutterError(error);
    }
    if (!result.passed) {
      result.dispose();
    }
    return true;
  }
}

/// The tolerance of the shots in [windowsMadeShots]: 4 percent. The global 3 percent is untouched.
const double windowsMadeTolerance = 0.04;

/// Named shots (file names under `goldens/`) that get [windowsMadeTolerance]. Windows-made golden;
/// Linux CI differs by 3.0 to 3.4%. A shot goes on this list only when CI measured a diff between 3 and 4
/// percent; a bigger diff is a real difference and is never put here.
const Set<String> windowsMadeShots = <String>{
  'c1_keypad_row_l2_phone.png',
  'c1_keypad_row_l3_phone.png',
  'c1_keypad_words_l3_phone.png',
  'hint_give_l3_tablet_landscape.png',
  'hint_pattern_l2_phone.png',
  'hint_pattern_l3_phone.png',
  'hint_qa_count_l2_phone_se.png',
  'hint_qa_sequence_l2_phone_se.png',
  'hint_robot_l1_phone.png',
  'hint_tap_measure_l1_phone.png',
  'hint_tapb_sentence_l3_tablet_landscape.png',
  'home_phoneSE_lang.png',
  'logic_size_row_and_tiles_phone_se.png',
};

/// Makes this test file's golden comparisons tolerant. Call from `setUpAll`.
void useTolerantGoldens(double tolerance) {
  final LocalFileComparator current = goldenFileComparator as LocalFileComparator;
  goldenFileComparator = TolerantGoldenComparator(
    current.basedir.resolve('golden_screens_test.dart'),
    tolerance,
  );
}
