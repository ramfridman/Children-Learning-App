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
  'ls01_heb_words_phone.png',
  'ls01_eng_letters_phone.png',
  'hint_pattern_l2_phone.png',
  'hint_pattern_l3_phone.png',
  'hint_qa_sequence_l3_phone_se.png',
  'hint_qa_colour_l3_phone_se.png',
  'hint_tap_colour_model_l1_phone.png',
  'hint_tap_sequence_l3_phone.png',
  'hint_tap_measure_l1_phone.png',
  'hint_tap_measure_l3_phone.png',
  'hint_tapb_mix_l1_phone.png',
  'hint_tapb_sentence_part_l2_phone.png',
  'lesson_5_give_two_phone.png',
  'logic_size_row_and_tiles_phone_se.png',
  'hint_spot_rainbow_l2_phone.png',
  'progress_view.png',
  'robot_plan_5x4_l2_phone_se.png',
  'unit_logic_size_phone.png',
  'unit_math_shop_tablet_landscape.png',
};

/// Makes this test file's golden comparisons tolerant. Call from `setUpAll`.
void useTolerantGoldens(double tolerance) {
  final LocalFileComparator current = goldenFileComparator as LocalFileComparator;
  goldenFileComparator = TolerantGoldenComparator(
    current.basedir.resolve('golden_screens_test.dart'),
    tolerance,
  );
}
