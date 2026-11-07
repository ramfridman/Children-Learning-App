// The whole drawing is read once the target is whole (L5-2b, QA-L52-1 and QA-L52-4): a letter written the way the school model or another right
// build writes it is never taken for another letter, and the builds of the stroke data are each read as their own letter and no other.
import 'package:flutter_test/flutter_test.dart';
import 'package:nitznutz/content/strokes.dart';

import 'support/stroke_hands.dart';

void main() {
  group('a right letter is not taken for another letter', () {
    for (final MapEntry<String, StrokeSet> set in strokeSets.entries) {
      for (final (String who, StrokeHand hand) in <(String, StrokeHand)>[
        ('an adult', StrokeHand.adult),
        ('a child', StrokeHand.child),
      ]) {
        test('${set.key}: every form written by $who, and every other build of it, ten times each', () {
          final List<String> taken = <String>[];
          int tried = 0;
          for (final StrokeForm f in set.value.forms.values) {
            for (final (String name, List<StrokeModel> build) in <(String, List<StrokeModel>)>[
              ('model', f.strokes),
              for (final (int i, List<StrokeModel> b) in f.alternates.indexed) ('build ${i + 1}', b),
            ]) {
              for (int seed = 0; seed < 10; seed++) {
                tried++;
                if (!countedForTarget(f, set.value.forms.values, writeBuild(build, seed * 7 + 1, hand))) {
                  taken.add('${f.id} $name seed $seed');
                }
              }
            }
          }
          // An adult is never taken for another letter. The made-up child is deliberately extreme (a start up to 7 units off, a wander of 3, a
          // letter 8% off in size, all together): at most 1 letter in 200 of those may be, and what is refused is only a retry (nothing is
          // written against the child unless the other letter is one the item lists as a look-alike). The qa-engineer tunes this on real hands.
          final int allowed = identical(hand, StrokeHand.adult) ? 0 : (tried * 0.005).ceil();
          expect(
            taken.length,
            lessThanOrEqualTo(allowed),
            reason: '${taken.length} of $tried: ${taken.take(10).join('; ')}',
          );
        });
      }
    }
  });
}
