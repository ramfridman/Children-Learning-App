// M10 (NUM-B-09, concrete): a give-N item whose target is a ten-frame (`scene.frame`): the objects the child gives sit in the cells of one
// frame (two above ten), row by row from the left. The model, the validator, the layout and a give that fills the frame.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nitznutz/child/activity_shell.dart';
import 'package:nitznutz/content/models.dart';
import 'package:nitznutz/content/pack_validation.dart';
import 'package:nitznutz/content/pack_verify.dart';
import 'package:nitznutz/content/schema.dart' show Problem;
import 'package:nitznutz/play/give_n_session.dart';

import 'support/c1_screens.dart';
import 'support/harness.dart';

Map<String, Object?> _m(Object? v) => v! as Map<String, Object?>;

const String _id = 'b.numb05.1';

/// Item b.numb05.1 (give 13 of 20) with a ten-frame as the target.
void _frame(Map<String, Object?> docs, {int source = 20, int n = 13}) {
  final Map<String, Object?> d = _m(docs['activity.$_id.json']);
  d['templateVersion'] = '1.1';
  _m(d['scene'])['frame'] = true;
  _m(_m(d['scene'])['source'])['count'] = source;
  _m(d['answer'])['n'] = n;
}

void main() {
  late PackContent content;
  setUpAll(() async {
    await loadAppFonts();
    content = await loadSourcePack(edit: _frame);
  });

  test('the model reads the frame', () {
    expect((content.activities[_id]! as GiveNActivity).frame, isTrue);
    expect((content.activities['b.numb05.2']! as GiveNActivity).frame, isFalse);
  });

  test('the validator wants give_n 1.1 for a frame', () async {
    final VerifiedPack pack = await loadSourceVerified();
    _frame(pack.docs);
    _m(pack.manifest['templates'])['give_n'] = '1.1';
    List<String> problems() => <String>[
      for (final Problem x in validatePack(
        manifest: pack.manifest,
        docs: pack.docs,
        files: pack.files.keys.toSet(),
      ))
        if (x.path.startsWith('activity.$_id.json')) x.toString(),
    ];
    expect(problems(), isEmpty);
    _m(pack.docs['activity.$_id.json'])['templateVersion'] = '1.0';
    expect(problems(), isNotEmpty);
  });

  test('the cells are the places: row by row from the left, a second frame under the first, inside the stage, no two alike', () {
    final GiveNActivity a = content.activities[_id]! as GiveNActivity;
    for (final ActivitySpec spec in <ActivitySpec>[
      ActivitySpec.phone,
      ActivitySpec.phoneSE,
      ActivitySpec.tabletLandscape,
      ActivitySpec.tabletPortrait,
    ]) {
      final Size stage = spec.stageIsCard
          ? Size(spec.stage.width - 32, spec.stage.height - 32)
          : spec.stage.size;
      final GiveLayout l = GiveLayout(stage, a);
      expect(l.slots, hasLength(20));
      expect(l.slots[1].dx, greaterThan(l.slots[0].dx), reason: 'left to right');
      expect(l.slots[5].dy, greaterThan(l.slots[0].dy), reason: 'the second row');
      expect(l.slots[5].dx, closeTo(l.slots[0].dx, 0.01));
      expect(l.slots[10].dy, greaterThan(l.slots[9].dy), reason: 'the second frame is under the first');
      expect(l.slotSize, greaterThanOrEqualTo(12), reason: 'a counter you can count on ${spec.stage}');
      for (final Offset o in l.slots) {
        expect(Rect.fromLTWH(0, 0, stage.width, stage.height).contains(o), isTrue, reason: '$o in $stage');
      }
      expect(l.slots.toSet(), hasLength(20));
    }
  });

  for (final (String name, Size size) in boards) {
    testWidgets('on the $name board the frame is drawn, and giving 13 fills it', (WidgetTester t) async {
      await startOn(t, content, size);
      await openOne(t, content, content.activities[_id]!);
      expect(find.byKey(const Key('give-frame')), findsOneWidget);
      expect(find.byKey(const Key('give-flower')), findsNothing);
      expect(t.takeException(), isNull);
      for (int i = 0; i < 13; i++) {
        await t.tap(find.byKey(Key('give-butterfly-$i')), warnIfMissed: false);
        await t.pump(const Duration(milliseconds: 80));
        await t.tap(find.byKey(const Key('give-frame')), warnIfMissed: false);
        await t.pump(const Duration(milliseconds: 80));
      }
      expect(find.byKey(const Key('give-counter')), findsOneWidget);
      expect(t.takeException(), isNull);
    });
  }
}
