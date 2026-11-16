import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:nitznutz/content/models.dart';
import 'package:nitznutz/engine/age.dart';
import 'package:nitznutz/play/lesson_controller.dart';
import 'package:nitznutz/play/shape_builder_session.dart';
import 'package:nitznutz/play/sort_drag_session.dart';
import 'package:nitznutz/play/template_session.dart';

import 'support/arc.dart';
import 'support/fakes.dart';
import 'support/harness.dart';
import 'support/starter.dart';

/// The QA pass of the Stage 2 pilot (Shape Forest), the QA report of 2026-11-16: what the developer's own tests leave open. Each test names
/// the acceptance criterion of docs/milestones/M11-stage2.md section 7.3 it proves.
void main() {
  late PackContent content;
  setUpAll(() async {
    await loadAppFonts();
    content = await loadSourcePack();
  });

  final List<AttemptRecord> written = <AttemptRecord>[];
  setUp(written.clear);

  /// The raw source of an activity of the starter sources (the expected tags are read from here, not from the model under test).
  Map<String, Object?> raw(String id) =>
      jsonDecode(File('../content/starter/activity.$id.json').readAsStringSync()) as Map<String, Object?>;

  Lesson one(Activity a) => Lesson.mission(
    id: 'qa',
    itemIds: <String>[a.id],
    skillIds: <String>[a.skillId],
    celebration: const Spoken(vo: 'vo:x', caption: 'x'),
  );

  LessonController alone(Activity a) => LessonController(
    content: content,
    lesson: one(a),
    profileId: 'p-1',
    clock: FixedClock(1793000000000),
    record: (AttemptRecord r) async => written.add(r),
  );

  final List<Activity> shapeItems = <Activity>[];
  setUp(() {
    shapeItems
      ..clear()
      ..addAll(
        content.activities.values.where(
          (Activity a) =>
              !a.isShow && content.skills[a.skillId]?.domain == 'shapes' && a.template != 'listen_do',
        ),
      );
  });

  // Criterion 9 (tags): a wrong move in a sort records the tag the source gives the dropped card, else the activity's own, in every sort of the land.
  testWidgets('every wrong drop in every Shape Forest sort records the tag its source names', (
    WidgetTester tester,
  ) async {
    int moves = 0;
    final List<String> untagged = <String>[];
    for (final SortDragActivity a in shapeItems.whereType<SortDragActivity>()) {
      if (a.share) continue;
      final Map<String, Object?> src = raw(a.id);
      final Map<String, Object?> scene = src['scene']! as Map<String, Object?>;
      final String? own = (src['answer']! as Map<String, Object?>)['misconception'] as String?;
      for (final Map<String, Object?> item
          in (scene['items']! as List<Object?>).cast<Map<String, Object?>>()) {
        final String wrongBin = a.bins.firstWhere((SortBin b) => b.id != item['bin']).id;
        written.clear();
        final LessonController c = alone(a);
        c.endGreeting();
        final SortDragSession s = SortDragSession(c, a);
        await s.drop(item['id']! as String, wrongBin);
        await tester.pump(const Duration(seconds: 2));
        expect(written, hasLength(1), reason: '${a.id} ${item['id']}');
        final String expected = (item['misconception'] as String?) ?? own ?? '';
        expect(written.single.result, 'incorrect', reason: a.id);
        expect(written.single.misconceptionTag, expected, reason: '${a.id} ${item['id']}');
        if (expected.isEmpty) untagged.add('${a.id}/${item['id']}');
        moves++;
        s.dispose();
      }
    }
    // the diagnosis holes are named, not hidden: wrong moves that record no tag at all
    // ignore: avoid_print
    print('QA sorts: $moves wrong drops checked, ${untagged.length} record no tag: ${untagged.take(12)}');
    expect(moves, greaterThan(150));
  });

  // Criterion 9 for the shape builder, and the rocket: a piece of the same shape fits any place of that shape.
  testWidgets(
    'every wrong piece in every Shape Forest builder records the tag its source names; equal pieces fit',
    (WidgetTester tester) async {
      int moves = 0;
      final List<String> untagged = <String>[];
      for (final ShapeBuilderActivity a in shapeItems.whereType<ShapeBuilderActivity>()) {
        final Map<String, Object?> ans = raw(a.id)['answer']! as Map<String, Object?>;
        final String? own = ans['misconception'] as String?;
        final List<Map<String, Object?>> tags = ((ans['pieceTags'] as List<Object?>?) ?? const <Object?>[])
            .cast<Map<String, Object?>>();
        final LessonController probe = alone(a);
        final ShapeBuilderSession ps = ShapeBuilderSession(probe, a);
        final List<String> pieces = ps.pieces;
        ps.dispose();
        for (int p = 0; p < pieces.length; p++) {
          for (final ShapeSlot slot in a.slots) {
            if (ShapeBuilderActivity.fits(pieces[p], slot)) {
              // a piece that fits must be the same shape class as the place (colour never makes another shape)
              expect(
                ShapeBuilderActivity.shapeClassOf(pieces[p]),
                ShapeBuilderActivity.shapeClassOf(slot.sprite),
                reason: '${a.id}: ${pieces[p]} fits ${slot.sprite}',
              );
              continue;
            }
            written.clear();
            final LessonController c = alone(a);
            c.endGreeting();
            final ShapeBuilderSession s = ShapeBuilderSession(c, a);
            await s.drop(p, slot.id);
            await tester.pump(const Duration(seconds: 2));
            expect(written, hasLength(1), reason: '${a.id} piece $p slot ${slot.id}');
            String expected = own ?? '';
            String? anywhere;
            for (final Map<String, Object?> t in tags) {
              if (t['piece'] != pieces[p]) continue;
              if (t['slot'] == slot.sprite) {
                expected = t['misconception']! as String;
                anywhere = null;
                break;
              }
              if (t['slot'] == null) anywhere ??= t['misconception'] as String?;
            }
            if (anywhere != null) expected = anywhere;
            expect(
              written.single.misconceptionTag,
              expected,
              reason: '${a.id} ${pieces[p]} in ${slot.sprite}',
            );
            if (expected.isEmpty) untagged.add('${a.id}:${pieces[p]}->${slot.sprite}');
            moves++;
            s.dispose();
          }
        }
      }
      // ignore: avoid_print
      print(
        'QA builders: $moves wrong pieces checked, ${untagged.length} record no tag: ${untagged.take(12)}',
      );
      expect(moves, greaterThan(20));
    },
  );

  // Criterion 12 (nothing else moves) and "rooms off": a lesson of another land has no parts, and an activity of the lands that is a Show is never in a
  // lesson's own list of items (which is what a visit with the rooms off plays).
  test('only the lessons of the lands are in parts; no flat list holds a Show; a Show is never an item of the engine', () {
    for (final Lesson l in content.lessons.values) {
      // the six lands of the rooms (shapes, numbers, math, colours, logic, robots); a lesson of a language course is never in parts
      final bool land = l.skillIds.every((String s) => RegExp(r'^(SHP|NUM|MATH|COL|LOG|CS)-').hasMatch(s));
      if (!land) expect(l.parts, isNull, reason: '${l.id} is not of a land and must stay as it was');
      for (final String id in l.itemIds) {
        expect(content.activities[id]!.isShow, isFalse, reason: '${l.id} lists a Show among its items');
      }
    }
    expect(content.activities.values.where((Activity a) => a.isShow).length, greaterThanOrEqualTo(16));
  });

  // Criterion 4 and the evidence rule: a touch skips a reminder Show; nothing is written; the child's step is left.
  testWidgets(
    'a touch skips a reminder Show; the host cards are in their bins, nothing is written, the child can finish',
    (WidgetTester tester) async {
      final LessonController c = arcController(
        content,
        'any-shape',
        planOf(content, 'any-shape', PresentationStage.p4, learningChild),
        written,
      );
      final SortDragSession s = SortDragSession(c, c.current as SortDragActivity);
      await hostSession(tester, s);
      s.startHost();
      await passTime(tester, 1500);
      expect(s.hosting, isTrue);
      s.onScreenTouch();
      expect(s.hosting, isFalse);
      expect(s.placed.length, s.activity.show!.hostSteps.length);
      final ShowStep child = s.activity.show!.childStep;
      await s.drop(child.item!, child.bin!);
      expect(c.solved, isTrue);
      expect(written, isEmpty);
      await passTime(tester, 3000);
      s.dispose();
    },
  );

  // Criterion 1, every lesson in parts: a child new to the skills meets a Show first. A lesson whose Alone pool is empty has no plan and is played flat (QA-2: the validator refuses such a lesson, so none is left).
  test('every lesson of Shape Forest in parts has a plan for a new child, so that a Show comes first (V1 at the visit)', () {
    final List<String> flat = <String>[];
    for (final Lesson l in content.lessons.values) {
      if (l.parts == null) continue;
      for (final PresentationStage st in PresentationStage.values) {
        if (planOrNull(content, l.id, st, newChild) == null) flat.add('${l.id}@${st.name}');
      }
    }
    expect(flat, isEmpty, reason: 'played flat, with no Show: $flat');
  });

  // Robustness (QA-3): a clip that never reports its end (a player that fails to fire its completion) must not freeze a full Show, which has no skip:
  // every wait for the voice has a ceiling, and once the host has done its part the child may move on.
  testWidgets('a clip that never ends does not freeze a full Show; the child may move on', (
    WidgetTester tester,
  ) async {
    final LessonController c = arcController(
      content,
      'any-shape',
      planOf(content, 'any-shape', PresentationStage.p4, newChild),
      written,
    );
    final SortDragSession s = SortDragSession(c, c.current as SortDragActivity);
    s.untilQuiet = () => Completer<void>().future;
    await hostSession(tester, s);
    expect(s.canMoveOn.value, isFalse, reason: 'no "next" before the host has done its part');
    s.startHost();
    await passTime(tester, 90000);
    expect(s.hosting, isFalse, reason: 'the host waits for ever for a line that never ends');
    expect(s.canMoveOn.value, isTrue);
    final int shows = c.index;
    c.skipShow();
    expect(c.index, shows + 1, reason: 'moving on from a Show goes to the next screen');
    expect(written, isEmpty, reason: 'a Show writes nothing, however it is left');
    s.dispose();
  });

  test('the ceiling of a line grows with its length and never passes its maximum', () {
    const Duration least = TemplateSession.hostLinePause;
    final Duration short = TemplateSession.lineCeiling('אבג', least);
    final Duration long = TemplateSession.lineCeiling('א' * 90, least);
    expect(short, greaterThan(least));
    expect(long, greaterThan(short));
    expect(TemplateSession.lineCeiling('א' * 5000, least), TemplateSession.lineCeilingMax);
  });
}
