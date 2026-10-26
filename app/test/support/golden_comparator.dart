import 'dart:typed_data';

import 'package:flutter/foundation.dart' show FlutterError;

import 'package:flutter_test/flutter_test.dart';

/// Compares golden images but forgives a small share of different pixels. Text is anti-aliased a
/// little differently on Windows and Linux, so a strict comparison would fail on CI for no real reason.
class TolerantGoldenComparator extends LocalFileComparator {
  TolerantGoldenComparator(super.testFile, this.tolerance);

  /// The largest share of differing pixels that still passes (0.03 is 3 percent).
  final double tolerance;

  @override
  Future<bool> compare(Uint8List imageBytes, Uri golden) async {
    final ComparisonResult result = await GoldenFileComparator.compareLists(
      imageBytes,
      await getGoldenBytes(golden),
    );
    if (!result.passed && result.diffPercent > tolerance) {
      final String error = await generateFailureOutput(result, golden, basedir);
      throw FlutterError(error);
    }
    if (!result.passed) {
      result.dispose();
    }
    return true;
  }
}

/// Makes this test file's golden comparisons tolerant. Call from `setUpAll`.
void useTolerantGoldens(double tolerance) {
  final LocalFileComparator current = goldenFileComparator as LocalFileComparator;
  goldenFileComparator = TolerantGoldenComparator(
    current.basedir.resolve('golden_screens_test.dart'),
    tolerance,
  );
}
