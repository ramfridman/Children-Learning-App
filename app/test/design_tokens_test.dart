import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:nitznutz/design/token_types.dart';
import 'package:nitznutz/design/tokens.g.dart';

import '../tool/gen_tokens.dart';

void main() {
  test('tokens.g.dart is up to date with design/tokens.json', () {
    final Map<String, Object?> json =
        jsonDecode(File('../design/tokens.json').readAsStringSync()) as Map<String, Object?>;
    final String committed = File('lib/design/tokens.g.dart').readAsStringSync();
    expect(committed, generateTokens(json), reason: 'run `dart run tool/gen_tokens.dart` in app/');
  });

  test('values the boards rely on come through', () {
    expect(TokenColors.cream.toARGB32(), 0xFFFFF6E8);
    expect(TokenColors.ink.toARGB32(), 0xFF2B2350);
    expect(TokenColors.spark.toARGB32(), 0xFFFFC83D);
    expect(TokenColors.sunset.toARGB32(), 0xFFFF8A3D);
    expect(TokenColors.parentBg.toARGB32(), 0xFFF6F1FA);
    expect(TokenRadius.xl, 28);
    expect(TokenSpace.s4, 16);
    expect(TokenLayout.deviceTabletL.width, 1180);
    expect(TokenLayout.devicePhone.safeStart, 59);
  });

  test('touch sizes: controls never below 64 for band A and 56 for B and C, gaps at least 12', () {
    expect(TokenTouch.band[Band.a]!.minControl, greaterThanOrEqualTo(64));
    expect(TokenTouch.band[Band.b]!.minControl, greaterThanOrEqualTo(56));
    expect(TokenTouch.band[Band.c]!.minControl, greaterThanOrEqualTo(56));
    for (final BandTouch t in TokenTouch.band.values) {
      expect(t.gapPhone, greaterThanOrEqualTo(12));
      expect(t.answerPhone, greaterThanOrEqualTo(t.minControl));
    }
    expect(TokenComponent.pebbleSize[Band.a], 64);
  });

  test('pointed (niqqud) text: line height 1.7 or more, in every band', () {
    expect(TokenFonts.niqqudMinLineHeight, 1.7);
    for (final Band b in Band.values) {
      expect(TokenType.caption[b]!.lineHeight, greaterThanOrEqualTo(1.7));
      expect(TokenType.caption[b]!.weight, lessThanOrEqualTo(TokenFonts.maxWeightBelow24pt));
    }
    expect(TokenType.label.lineHeight, greaterThanOrEqualTo(1.7));
  });

  test('the generator refuses an unknown colour format', () {
    final Map<String, Object?> json =
        jsonDecode(File('../design/tokens.json').readAsStringSync()) as Map<String, Object?>;
    final Map<String, Object?> bad = jsonDecode(jsonEncode(json)) as Map<String, Object?>;
    ((bad['color']! as Map<String, Object?>)['core']! as Map<String, Object?>)['cream'] = <String, Object?>{
      'value': 'hotpink',
    };
    expect(() => generateTokens(bad), throwsFormatException);
  });
}
