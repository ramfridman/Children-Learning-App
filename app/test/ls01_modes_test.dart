// LS01, the rest (L5-1): sort with text, picture and sound faces; pairs played one at a time; spot with text cells; order tiles; the story line.
// The document (the model and the validator's rules, with a broken file for each rule), the play (what is written, the tags, the hints) and
// the board (the zones, the directions). Fixture course and fake clips, not content.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nitznutz/content/ls01_checks.dart';
import 'package:nitznutz/content/models.dart';
import 'package:nitznutz/content/pack_validation.dart';
import 'package:nitznutz/content/schema.dart';
import 'package:nitznutz/play/lesson_controller.dart';
import 'package:nitznutz/play/listen_do_session.dart';
import 'package:nitznutz/play/ls01_order_session.dart';
import 'package:nitznutz/play/ls01_pairs_session.dart';
import 'package:nitznutz/play/ls01_sequence_session.dart';
import 'package:nitznutz/play/ls01_sort_session.dart';
import 'package:nitznutz/play/template_session.dart';
import 'package:nitznutz/play/ls01_spot_session.dart';

import 'support/l4_rig.dart';
import 'support/language_content.dart';
import 'support/ls01_content.dart';
import 'support/sample_pack.dart';

List<Problem> _run(SamplePack p) => validatePack(manifest: p.manifest, docs: p.docs, files: p.files);

List<String> _messages(LangPack p) => <String>[
  for (final Problem x in _run(p.pack)) '${x.path}: ${x.message}',
];

const List<String> _pictures = <String>['cat', 'dog', 'duck', 'apple', 'banana', 'bread', 'book'];

LangPack _base() => LangPack()..addPictures(_pictures);

// ---- the fixtures ----

LangPack _sortPack({String id = 'sort', int cards = 4}) {
  final LangPack p = _base();
  final String sem = p.tag('lis.sem');
  final String guess = p.tag('lis.guess');
  const List<(String, String)> words = <(String, String)>[
    ('pan', 'b1'),
    ('pin', 'b2'),
    ('nap', 'b1'),
    ('sit', 'b2'),
    ('tap', 'b1'),
    ('tin', 'b2'),
  ];
  p.add(
    sortJson(
      id: id,
      bins: <Map<String, Object?>>[
        sortFace('b1', text: 'a', clip: 'vo:eng.b.a'),
        sortFace('b2', text: 'i'),
      ],
      items: <Map<String, Object?>>[
        for (final (int k, (String, String) w) in words.take(cards).indexed)
          sortFace('i${k + 1}', text: w.$1, bin: w.$2, tag: k.isEven ? sem : guess),
      ],
    ),
  );
  return p;
}

LangPack _soundSortPack() {
  final LangPack p = _base();
  p.add(
    sortJson(
      id: 'sounds',
      bins: <Map<String, Object?>>[
        sortFace('b1', picture: 'cat'),
        sortFace('b2', picture: 'dog'),
      ],
      items: <Map<String, Object?>>[
        sortFace('i1', clip: 'vo:eng.s.one', bin: 'b1'),
        sortFace('i2', clip: 'vo:eng.s.many', bin: 'b2'),
        sortFace('i3', clip: 'vo:eng.s.two', bin: 'b1'),
      ],
      tag: p.tag('lis.sem'),
    ),
  );
  return p;
}

LangPack _pairsPack({int n = 3}) {
  final LangPack p = _base();
  final String sem = p.tag('lis.sem');
  p.add(
    pairsJson(
      id: 'pairs',
      left: <Map<String, Object?>>[
        for (int i = 0; i < n; i++) pairFace('l${i + 1}', text: 'stpn'[i], clip: 'vo:eng.l.${i + 1}'),
      ],
      right: <Map<String, Object?>>[
        for (int i = 0; i < n; i++)
          pairFace('r${i + 1}', clip: 'vo:eng.n.${i + 1}', tag: i == 0 ? sem : null),
      ],
      pairs: <String, String>{for (int i = 0; i < n; i++) 'l${i + 1}': 'r${i + 1}'},
      tag: sem,
    ),
  );
  return p;
}

LangPack _spotPack() {
  final LangPack p = _base();
  p.add(
    spotJson(
      id: 'spot',
      cells: <String>['txt:c', 'txt:a', 'txt:p'],
      wrong: 2,
      model: 'cat',
      modelClip: 'vo:eng.cat',
      tag: p.tag('lis.sem'),
    ),
  );
  final Map<String, Object?> scene =
      (p.pack.docs['activity.eng.spot.json']! as Map<String, Object?>)['scene']! as Map<String, Object?>;
  (scene['model']! as Map<String, Object?>)['spelling'] = <String>['txt:c', 'txt:a', 'txt:t'];
  return p;
}

LangPack _orderPack() {
  final LangPack p = _base();
  p.add(
    orderJson(
      id: 'order',
      model: <String>['txt:s', 'txt:a'],
      palette: <String>['txt:p', 'txt:t', 'txt:n'],
      sequence: <String>['txt:t', 'txt:p'],
      tag: p.tag('lis.sem'),
    ),
  );
  return p;
}

LangPack _sequencePack({String course = 'eng'}) {
  final LangPack p = LangPack(course)..addPictures(_pictures);
  p.add(
    sequenceJson(
      course: course,
      id: 'story',
      palette: <String>['asset:cat', 'asset:dog', 'asset:duck'],
      order: <int>[1, 2, 0],
      tag: p.tag('lis.sem'),
    ),
  );
  final Map<String, Object?> scene =
      (p.pack.docs['activity.$course.story.json']! as Map<String, Object?>)['scene']! as Map<String, Object?>;
  final List<String> clips = <String>['vo:$course.q.third', 'vo:$course.q.first', 'vo:$course.q.second'];
  scene['clips'] = clips;
  (p.pack.manifest['voPending']! as List<Object?>).addAll(clips);
  return p;
}

Rig<S> _rig<S extends TemplateSession>(LangPack p, String id, S Function(LessonController, Activity) make) =>
    Rig<S>(p, id, make);

Rig<Ls01SortSession> _sort(LangPack p, String id) => _rig<Ls01SortSession>(
  p,
  id,
  (LessonController c, Activity a) => Ls01SortSession(c, a as SortDragActivity),
);

void main() {
  group('the document', () {
    test('every mode passes the validator and reads as its model', () {
      for (final LangPack p in <LangPack>[
        _sortPack(),
        _soundSortPack(),
        _pairsPack(),
        _spotPack(),
        _orderPack(),
        _sequencePack(),
        _sequencePack(course: 'heb'),
      ]) {
        expect(_messages(p), isEmpty, reason: p.course);
      }
      final SortDragActivity s = _sortPack().content.activities['eng.sort']! as SortDragActivity;
      expect(s.bins.first.text, 'a');
      expect(s.bins.first.clip, 'vo:eng.b.a');
      expect(s.items.first.misconception, 'eng.lis.sem');
      expect(s.engineTags, <String>{'eng.lis.sem', 'eng.lis.guess'});
      final SortDragActivity sound = _soundSortPack().content.activities['eng.sounds']! as SortDragActivity;
      expect(sound.items.first.text, isNull);
      expect(sound.items.first.clip, 'vo:eng.s.one');
      final MatchPairsActivity m = _pairsPack().content.activities['eng.pairs']! as MatchPairsActivity;
      expect(m.left.first.text, 's');
      expect(m.right.first.clip, 'vo:eng.n.1');
      expect(m.engineTags, contains('eng.lis.sem'));
      final SpotErrorActivity spot = _spotPack().content.activities['eng.spot']! as SpotErrorActivity;
      expect(spot.model!.spelling, <String>['txt:c', 'txt:a', 'txt:t']);
      final BuildPatternActivity o = _orderPack().content.activities['eng.order']! as BuildPatternActivity;
      expect(o.isSequence, isFalse);
      final BuildPatternActivity q = _sequencePack().content.activities['eng.story']! as BuildPatternActivity;
      expect(q.isSequence, isTrue);
      expect(q.order, <int>[1, 2, 0]);
      expect(q.clips, hasLength(3));
    });

    test('the broken sorts', () {
      LangPack p = _sortPack();
      Map<String, Object?> doc() => p.pack.docs['activity.eng.sort.json']! as Map<String, Object?>;
      Map<String, Object?> scene() => doc()['scene']! as Map<String, Object?>;
      List<Map<String, Object?>> items() => <Map<String, Object?>>[
        for (final Object? i in scene()['items']! as List<Object?>) i! as Map<String, Object?>,
      ];
      // A card with a text and a picture; a card with no tag; a bin that no card belongs in; two cards alike in two bins.
      items().first['sprite'] = 'asset:cat';
      expect(_messages(p), contains(contains('must be exactly one of a picture or a text, or only a clip')));
      p = _sortPack();
      items().first.remove('misconception');
      expect(
        _messages(p),
        contains(contains('carries the misconception that putting it in a wrong bin shows')),
      );
      p = _sortPack();
      for (final Map<String, Object?> i in items()) {
        i['bin'] = 'b1';
      }
      expect(_messages(p), contains(contains('has no card that belongs in it')));
      p = _sortPack();
      items()[1]['text'] = 'pan';
      expect(_messages(p), contains(contains('looks like a card that belongs in another bin')));
      // Share mode is the lands'; seven cards are too many for the tray and its pile.
      p = _sortPack();
      (doc()['answer']! as Map<String, Object?>)['mode'] = 'share';
      expect(_messages(p), contains(contains('sharing between friends is a land')));
      p = _sortPack();
      final List<Object?> many = scene()['items']! as List<Object?>;
      for (int k = 0; k < 3; k++) {
        many.add(<String, Object?>{
          'id': 'i${many.length + 1}',
          'label': 'x',
          'text': 'cat$k',
          'bin': 'b1',
          'misconception': 'eng.lis.sem',
        });
      }
      expect(_messages(p), contains(contains('a sort has at most 6 cards')));
      // An accent tag is never on a card.
      p = _sortPack();
      items().first['misconception'] = 'eng.spk.accent';
      expect(_messages(p), contains(contains('is an accent tag')));
    });

    test('the broken pairs, spots and orders', () {
      LangPack p = _pairsPack(n: 4);
      expect(
        _messages(p),
        contains(contains('4 pairs: played one at a time, an item has at most 3 in this band')),
      );
      p = _pairsPack();
      final Map<String, Object?> pd = p.pack.docs['activity.eng.pairs.json']! as Map<String, Object?>;
      (pd['answer']! as Map<String, Object?>).remove('misconception');
      expect(_messages(p), contains(contains('a partner carries the misconception')));
      p = _spotPack();
      Map<String, Object?> sd() => p.pack.docs['activity.eng.spot.json']! as Map<String, Object?>;
      ((sd()['scene']! as Map<String, Object?>)['cells']! as List<Object?>)[1] = 'n:4';
      expect(_messages(p), contains(contains('is all text')));
      p = _spotPack();
      (sd()['answer']! as Map<String, Object?>).remove('misconception');
      expect(_messages(p), contains(contains('a cell touched by mistake shows a misconception')));
      p = _spotPack();
      (((sd()['scene']! as Map<String, Object?>)['model']! as Map<String, Object?>)['spelling']!
              as List<Object?>)[2] =
          'txt:p';
      expect(_messages(p), contains(contains('is the wrong cell as it stands')));
      p = _orderPack();
      Map<String, Object?> od() => p.pack.docs['activity.eng.order.json']! as Map<String, Object?>;
      (od()['answer']! as Map<String, Object?>).remove('misconception');
      expect(_messages(p), contains(contains('a tile put in a wrong place shows a misconception')));
    });

    test('the broken story lines', () {
      LangPack p = _sequencePack();
      Map<String, Object?> doc() => p.pack.docs['activity.eng.story.json']! as Map<String, Object?>;
      Map<String, Object?> answer() => doc()['answer']! as Map<String, Object?>;
      Map<String, Object?> scene() => doc()['scene']! as Map<String, Object?>;
      answer()['order'] = <int>[0, 1, 2];
      expect(_messages(p), contains(contains('the line starts shuffled')));
      p = _sequencePack();
      answer()['order'] = <int>[1, 1, 0];
      expect(_messages(p), contains(contains('must name every picture once')));
      p = _sequencePack();
      scene()['palette'] = <String>['asset:cat', 'asset:dog', 'asset:duck', 'asset:book'];
      scene()['slots'] = 4;
      answer()['order'] = <int>[1, 2, 3, 0];
      scene().remove('clips');
      expect(_messages(p), contains(contains('a scored story line has at most 3 in this band')));
      p = _sequencePack();
      scene()['palette'] = <String>['asset:cat', 'asset:cat', 'asset:duck'];
      expect(_messages(p), contains(contains('has two pictures that are the same')));
      p = _sequencePack();
      scene()['model'] = <String>['asset:cat'];
      expect(_messages(p), contains(contains('a story line has no model')));
      p = _sequencePack();
      (scene()['clips']! as List<Object?>).removeLast();
      expect(_messages(p), contains(contains('one line for each')));
      p = _sequencePack();
      answer()['sequence'] = <String>['asset:cat', 'asset:dog'];
      expect(_messages(p), contains(contains('it has no `sequence`')));
    });

    test('the lands refuse every one of these modes', () {
      final List<String> said = <String>[];
      void say(String f, String path, String m) => said.add('$path: $m');
      void nothing(String f, String p, Object? r) {}
      for (final Map<String, Object?> a in <Map<String, Object?>>[
        _sortPack().activityOf('sort'),
        _pairsPack().activityOf('pairs'),
        _spotPack().activityOf('spot'),
        _orderPack().activityOf('order'),
        _sequencePack().activityOf('story'),
      ]) {
        said.clear();
        checkLs01(
          'f',
          a,
          language: false,
          say: say,
          checkAsset: nothing,
          checkVo: nothing,
          checkTag: nothing,
        );
        expect(said, isNotEmpty, reason: a['template'] as String);
        expect(
          said.every((String m) => m.contains('belongs to a language course') || m.contains('is missing')),
          isTrue,
        );
      }
    });
  });

  group('sort', () {
    testWidgets('a card is touched and then its bin; the last one checks the sort', (WidgetTester t) async {
      final Rig<Ls01SortSession> r = _sort(_sortPack(), 'sort');
      await r.pump(t);
      expect(find.byKey(const Key('sign-b1')), findsOneWidget);
      for (final (String card, String bin) in <(String, String)>[
        ('i1', 'b1'),
        ('i2', 'b2'),
        ('i3', 'b1'),
        ('i4', 'b2'),
      ]) {
        await t.tap(r.tile(card));
        await r.wait(t, 100);
        expect(r.session.selected, card);
        await t.tap(find.byKey(Key('bin-$bin')));
        await r.wait(t, 100);
      }
      expect(r.written, <String>['correct:sorted']);
      expect(find.byKey(const Key('chip-i1')), findsOneWidget);
      await r.done(t);
    });

    testWidgets('a card dragged to a bin goes in', (WidgetTester t) async {
      final Rig<Ls01SortSession> r = _sort(_sortPack(), 'sort');
      await r.pump(t);
      final Offset from = t.getCenter(r.tile('i1'));
      final Offset to = t.getCenter(find.byKey(const Key('bin-b1')));
      final TestGesture g = await t.startGesture(from);
      await g.moveTo(from + const Offset(0, -20));
      await t.pump(const Duration(milliseconds: 50));
      await g.moveTo(to);
      await t.pump(const Duration(milliseconds: 50));
      await g.up();
      await r.wait(t, 100);
      expect(r.session.placed, <String, String>{'i1': 'b1'});
      await r.done(t);
    });

    testWidgets(
      'a wrong sort: the wrong cards wobble and fly back, the right ones stay, the tag is the card\'s',
      (WidgetTester t) async {
        final Rig<Ls01SortSession> r = _sort(_sortPack(), 'sort');
        await r.pump(t);
        for (final String card in <String>['i1', 'i2', 'i3', 'i4']) {
          await t.tap(r.tile(card));
          await t.tap(find.byKey(const Key('bin-b1')));
          await r.wait(t, 100);
        }
        expect(r.written, <String>['incorrect:b1=0123-b2=']);
        expect(
          r.attempts.single.misconceptionTag,
          'eng.lis.guess',
          reason: 'the first wrong card is i2, whose tag is guess',
        );
        expect(r.session.wobbling, <String>{'i2', 'i4'});
        await r.wait(t, 1300);
        expect(r.session.placed.keys, unorderedEquals(<String>['i1', 'i3']));
        expect(r.session.wobbling, isEmpty);
        await r.done(t);
      },
    );

    testWidgets('after three tries only the right bin takes a card', (WidgetTester t) async {
      final Rig<Ls01SortSession> r = _sort(_sortPack(), 'sort');
      await r.pump(t);
      for (int k = 0; k < 3; k++) {
        for (final String card in <String>[for (final SortItem i in r.session.tray) i.id]) {
          await t.tap(r.tile(card));
          await t.tap(find.byKey(const Key('bin-b1')));
          await r.wait(t, 50);
        }
        await r.wait(t, 1500);
      }
      expect(r.controller.guided, isTrue);
      await r.wait(t, 5000);
      expect(r.session.placed.keys, unorderedEquals(<String>['i1', 'i3']));
      await t.tap(r.tile('i2'));
      await t.tap(find.byKey(const Key('bin-b1')));
      expect(r.session.placed.containsKey('i2'), isFalse);
      await t.tap(find.byKey(const Key('bin-b2')));
      expect(r.session.placed['i2'], 'b2');
      await r.done(t);
    });

    testWidgets(
      'a sound card plays when it is touched and shows its waves afterwards; a bin\'s speaker plays its sign',
      (WidgetTester t) async {
        final Rig<Ls01SortSession> r = _sort(_soundSortPack(), 'sounds');
        await r.pump(t);
        expect(
          find.byIcon(Icons.volume_mute_rounded),
          findsNWidgets(3),
          reason: 'nothing has been heard yet: no waves',
        );
        await t.tap(r.tile('i1'));
        await r.wait(t, 100);
        expect(r.heard.calls.last, 'now vo:eng.s.one');
        expect(find.byIcon(Icons.volume_up_rounded), findsOneWidget);
        // A second touch on the chosen sound card plays it again and keeps it chosen.
        await t.tap(r.tile('i1'));
        await r.wait(t, 100);
        expect(r.heard.calls.last, 'now vo:eng.s.one');
        expect(r.session.selected, 'i1');
        await t.tap(find.byKey(const Key('bin-b1')));
        await r.wait(t, 100);
        expect(r.session.placed, <String, String>{'i1': 'b1'});
        await r.done(t);
      },
    );

    testWidgets('the ladder: the signs light, the card goes past them, the hand takes a card to its bin', (
      WidgetTester t,
    ) async {
      final Rig<Ls01SortSession> r = _sort(_sortPack(), 'sort');
      await r.pump(t);
      r.controller.showHint();
      await r.wait(t, 200);
      expect(find.byKey(const Key('bin-glow')), findsOneWidget);
      expect(find.byKey(const Key('hint-tile-glow')), findsNothing, reason: 'no card is lit at level 1');
      expect(r.heard.clips, contains('vo:eng.b.a'));
      await r.wait(t, 2000);
      r.controller.showHint();
      await r.wait(t, 400);
      expect(find.byKey(const Key('sort-ghost')), findsOneWidget);
      await r.wait(t, 2000);
      r.controller.showHint();
      await r.wait(t, 1800);
      expect(r.session.handTip, isNotNull);
      await r.wait(t, 3000);
      expect(r.session.handTip, isNull);
      expect(r.session.placed, isEmpty, reason: 'the card goes back: the child does it');
      await r.done(t);
    });

    testWidgets('six word cards on the phone SE: the tray shows as many as fit and the rest wait in a pile', (
      WidgetTester t,
    ) async {
      final Rig<Ls01SortSession> r = _sort(_sortPack(cards: 6), 'sort');
      await r.pump(t, size: const Size(667, 375));
      expect(find.byKey(const Key('sort-pile')), findsOneWidget);
      final int shown = find.byKey(const Key('sort-tray')).evaluate().isEmpty ? 0 : r.session.tray.length;
      expect(shown, 6);
      final Rect tray = t.getRect(find.byKey(const Key('sort-tray')));
      final Rect pile = t.getRect(find.byKey(const Key('sort-pile')));
      expect(tray.width + pile.width, lessThanOrEqualTo(484.5));
      await r.done(t);
    });
  });

  group('pairs', () {
    Rig<Ls01PairsSession> rigOf(LangPack p) => _rig<Ls01PairsSession>(
      p,
      'pairs',
      (LessonController c, Activity a) => Ls01PairsSession(c, a as MatchPairsActivity),
    );

    testWidgets('one item at a time; the pairs fly to the end side; the last pair makes itself', (
      WidgetTester t,
    ) async {
      final Rig<Ls01PairsSession> r = rigOf(_pairsPack());
      await r.pump(t);
      expect(r.session.current, 0);
      await t.tap(r.tile('r2'));
      await r.wait(t, 100);
      expect(r.written, <String>['incorrect:t0-b1']);
      expect(r.session.current, 0, reason: 'the item now stays');
      await r.wait(t, 1300);
      await t.tap(r.tile('r1'));
      await r.wait(t, 100);
      expect(r.session.current, 1);
      expect(find.byKey(const Key('pair-chip-0-0')), findsOneWidget);
      await t.tap(r.tile('r2'));
      await r.wait(t, 100);
      // The last pair makes itself: the item was written once, as correct, with every pair.
      expect(r.written.last, 'correct:t0-b0.t1-b1.t2-b2');
      expect(find.byKey(const Key('pair-chip-2-2')), findsOneWidget);
      await r.done(t);
    });

    testWidgets('a wrong partner carries its own tag; the item\'s tag is the fallback', (
      WidgetTester t,
    ) async {
      final Rig<Ls01PairsSession> r = rigOf(_pairsPack());
      await r.pump(t);
      await t.tap(r.tile('r1'));
      await r.wait(t, 100);
      await t.tap(r.tile('r3'));
      await r.wait(t, 100);
      expect(r.attempts.single.misconceptionTag, 'eng.lis.sem');
      await r.done(t);
    });

    testWidgets('the ladder: the item lights and plays; the hand brings the partner', (WidgetTester t) async {
      final Rig<Ls01PairsSession> r = rigOf(_pairsPack());
      await r.pump(t);
      r.controller.showHint();
      await r.wait(t, 200);
      expect(find.byKey(const Key('pairs-item-glow')), findsOneWidget);
      expect(r.heard.clips, contains('vo:eng.l.1'));
      expect(find.byKey(const Key('hint-tile-glow')), findsNothing);
      r.controller.showHint();
      await r.wait(t, 200);
      r.controller.showHint();
      await r.wait(t, 700);
      expect(r.session.handTip, isNotNull);
      await r.wait(t, 1500);
      expect(r.session.handTip, isNull);
      await r.done(t);
    });
  });

  group('spot', () {
    Rig<Ls01SpotSession> rigOf() => _rig<Ls01SpotSession>(
      _spotPack(),
      'spot',
      (LessonController c, Activity a) => Ls01SpotSession(c, a as SpotErrorActivity),
    );

    testWidgets(
      'a touch on the cell that does not match is right; another is not yet, with the item\'s tag',
      (WidgetTester t) async {
        final Rig<Ls01SpotSession> r = rigOf();
        await r.pump(t);
        await t.tap(r.tile('c0'));
        await r.wait(t, 100);
        expect(r.written, <String>['incorrect:0']);
        expect(r.attempts.single.misconceptionTag, 'eng.lis.sem');
        await r.wait(t, 1300);
        await t.tap(r.tile('c2'));
        await r.wait(t, 100);
        expect(r.written.last, 'correct:2');
        await r.done(t);
      },
    );

    testWidgets('the model is heard on a touch', (WidgetTester t) async {
      final Rig<Ls01SpotSession> r = rigOf();
      await r.pump(t);
      await t.tap(find.byKey(const Key('spot-model')));
      expect(r.heard.calls.last, 'now vo:eng.cat');
      await r.done(t);
    });

    testWidgets('the ladder: a bead over each cell, the model\'s spelling, the hand and the right letter', (
      WidgetTester t,
    ) async {
      final Rig<Ls01SpotSession> r = rigOf();
      await r.pump(t);
      r.controller.showHint();
      await r.wait(t, 200);
      expect(find.byKey(const Key('spot-bead')), findsOneWidget);
      expect(
        find.byKey(const Key('hint-tile-glow')),
        findsNothing,
        reason: 'the cells themselves do not light',
      );
      await r.wait(t, 2500);
      r.controller.showHint();
      await r.wait(t, 200);
      expect(find.byKey(const Key('spot-spelling')), findsOneWidget);
      r.controller.showHint();
      await r.wait(t, 1800);
      expect(r.session.handTip, isNotNull);
      expect(r.session.fixedShown, isTrue, reason: 'the right letter appears in the cell');
      await r.done(t);
    });
  });

  group('order tiles', () {
    Rig<Ls01OrderSession> rigOf() => _rig<Ls01OrderSession>(
      _orderPack(),
      'order',
      (LessonController c, Activity a) => Ls01OrderSession(c, a as BuildPatternActivity),
    );

    testWidgets(
      'tiles go to the next empty place, a place gives its tile back, and the row is checked when full',
      (WidgetTester t) async {
        final Rig<Ls01OrderSession> r = rigOf();
        await r.pump(t);
        await t.tap(r.tile('p0'));
        await r.wait(t, 100);
        expect(r.session.filled, <int?>[0, null]);
        await t.tap(find.byKey(const Key('order-slot-0')));
        await r.wait(t, 100);
        expect(r.session.filled, <int?>[null, null]);
        // The wrong order first: p, then t.
        await t.tap(r.tile('p0'));
        await t.tap(r.tile('p1'));
        await r.wait(t, 200);
        expect(r.written, <String>['incorrect:01']);
        expect(r.attempts.single.misconceptionTag, 'eng.lis.sem');
        await r.wait(t, 1300);
        expect(r.session.filled, <int?>[null, null]);
        await t.tap(r.tile('p1'));
        await t.tap(r.tile('p0'));
        await r.wait(t, 200);
        expect(r.written.last, 'correct:10');
        await r.done(t);
      },
    );

    testWidgets('the ladder: the row lights in rhythm, the bridge, the hand on the right tile', (
      WidgetTester t,
    ) async {
      final Rig<Ls01OrderSession> r = rigOf();
      await r.pump(t);
      r.controller.showHint();
      await r.wait(t, 700);
      expect(find.byKey(const Key('order-glow')), findsOneWidget);
      expect(find.byKey(const Key('hint-tile-glow')), findsNothing);
      await r.wait(t, 2000);
      r.controller.showHint();
      await r.wait(t, 200);
      expect(find.byKey(const Key('order-glow')), findsOneWidget);
      expect(find.byKey(const Key('order-slot-glow')), findsOneWidget);
      r.controller.showHint();
      await r.wait(t, 700);
      expect(r.session.handTip, isNotNull);
      await r.done(t);
    });
  });

  group('the story line', () {
    Rig<Ls01SequenceSession> rigOf(LangPack p) => _rig<Ls01SequenceSession>(
      p,
      'story',
      (LessonController c, Activity a) => Ls01SequenceSession(c, a as BuildPatternActivity),
    );

    testWidgets(
      'a touch sets a picture in the first place not set; the last place sets itself and the order is checked',
      (WidgetTester t) async {
        final Rig<Ls01SequenceSession> r = rigOf(_sequencePack());
        await r.pump(t);
        expect(r.session.arrangement, <int>[0, 1, 2]);
        // The story is dog (1), duck (2), cat (0). The dog is in place 1: it swaps with the cat in place 0.
        await t.tap(find.byKey(const Key('place-1')));
        await r.wait(t, 100);
        expect(r.session.arrangement, <int>[1, 0, 2]);
        expect(r.session.setCount, 1);
        await t.tap(find.byKey(const Key('place-2')));
        await r.wait(t, 200);
        // One place was left: it set itself, and the order [1, 2, 0] was checked.
        expect(r.written, <String>['correct:120']);
        await r.wait(t, 2500);
        await r.done(t);
      },
    );

    testWidgets(
      'a set picture un-sets itself and the places after it; a wrong order wobbles the line and un-sets all',
      (WidgetTester t) async {
        final Rig<Ls01SequenceSession> r = rigOf(_sequencePack());
        await r.pump(t);
        await t.tap(find.byKey(const Key('place-0')));
        await r.wait(t, 100);
        expect(r.session.setCount, 1);
        await t.tap(find.byKey(const Key('place-0')));
        await r.wait(t, 100);
        expect(r.session.setCount, 0, reason: 'a touch on a set picture un-sets it');
        // The cat, the dog, the duck as they stand is the wrong order.
        await t.tap(find.byKey(const Key('place-0')));
        await t.tap(find.byKey(const Key('place-1')));
        await r.wait(t, 200);
        expect(r.written, <String>['incorrect:012']);
        expect(r.attempts.single.misconceptionTag, 'eng.lis.sem');
        expect(r.session.wobbling, isTrue);
        await r.wait(t, 1300);
        expect(r.session.setCount, 0);
        expect(r.session.arrangement, <int>[0, 1, 2], reason: 'the pictures stay where they are');
        await r.done(t);
      },
    );

    testWidgets('the Hebrew course\'s line starts at the right, English at the left', (WidgetTester t) async {
      final Rig<Ls01SequenceSession> en = rigOf(_sequencePack());
      await en.pump(t);
      final double enFirst = t.getCenter(find.byKey(const Key('place-0'))).dx;
      final double enLast = t.getCenter(find.byKey(const Key('place-2'))).dx;
      expect(enFirst, lessThan(enLast));
      expect(t.getCenter(find.byKey(const Key('sequence-flag'))).dx, lessThan(enFirst));
      await en.done(t);
      final Rig<Ls01SequenceSession> he = rigOf(_sequencePack(course: 'heb'));
      await he.pump(t);
      final double heFirst = t.getCenter(find.byKey(const Key('place-0'))).dx;
      final double heLast = t.getCenter(find.byKey(const Key('place-2'))).dx;
      expect(heFirst, greaterThan(heLast));
      expect(t.getCenter(find.byKey(const Key('sequence-flag'))).dx, greaterThan(heFirst));
      await he.done(t);
    });

    testWidgets(
      'the ladder: each picture lights with its line, the card of first-then-at-the-end, the hand taps the order',
      (WidgetTester t) async {
        final Rig<Ls01SequenceSession> r = rigOf(_sequencePack());
        await r.pump(t);
        r.controller.showHint();
        await r.wait(t, 200);
        expect(find.byKey(const Key('place-glow')), findsOneWidget);
        expect(r.heard.clips, contains('vo:eng.q.first'));
        await r.wait(t, 3000);
        r.controller.showHint();
        await r.wait(t, 800);
        expect(find.byKey(const Key('sequence-card')), findsOneWidget);
        r.controller.showHint();
        await r.wait(t, 700);
        expect(r.session.handTip, isNotNull);
        await r.wait(t, 4500);
        expect(r.session.handTip, isNull);
        await r.done(t);
      },
    );
  });

  group('LS11 place with letter stones (a text face on a target)', () {
    LangPack stones() {
      final LangPack p = LangPack()..addPictures(_pictures);
      p.pack.doc('skill.ENG-A-02.json')['letters'] = true;
      p.pack.doc('skill.ENG-A-02.json')['graphemes'] = <Object?>['n'];
      Map<String, Object?> stone(String id, String letter, double x, {String? tag}) => <String, Object?>{
        'id': id,
        'text': letter,
        'label': 'stone $letter',
        'at': at(x, 0.55, 0.3, 0.3),
        'misconception': ?tag,
      };
      final Map<String, Object?> doc = listenDoJson(
        id: 'stones',
        mode: 'place',
        picture: 'cat',
        thing: <String, Object?>{'at': at(0.36, 0.05, 0.3, 0.3), 'sprite': 'asset:dog'},
        options: <Map<String, Object?>>[
          stone('o1', 'n', 0.04),
          stone('o2', 'h', 0.36, tag: p.tag('lis.lookalike')),
          stone('o3', 'm', 0.68, tag: p.tag('lis.lookalike')),
        ],
        correct: 'o1',
      );
      (doc['answer']! as Map<String, Object?>)['face'] = 'letter';
      p.add(doc);
      return p;
    }

    test('a place with a text passes the validator (an untaught look-alike letter included)', () {
      expect(_messages(stones()), isEmpty);
      final ListenDoActivity a = stones().content.activities['eng.stones']! as ListenDoActivity;
      expect(a.options.first.text, 'n');
    });

    test(
      'a letter stone is read: a letter of no taught group is refused unless it is a SHAPE look-alike',
      () {
        final LangPack p = stones();
        final List<Object?> opts =
            (p.activity('stones')['answer']! as Map<String, Object?>)['options']! as List<Object?>;
        (opts.first! as Map<String, Object?>)['text'] = 'q';
        expect(_messages(p), contains(contains('the word "q" cannot be read yet')));
      },
    );

    testWidgets(
      'each stone shows its letter at the reading size of the band, and the child can still move Pip there',
      (WidgetTester t) async {
        final Rig<ListenDoSession> r = _rig<ListenDoSession>(
          stones(),
          'stones',
          (LessonController c, Activity a) => ListenDoSession(c, a as ListenDoActivity),
        );
        await r.pump(t, size: const Size(667, 375));
        for (final String id in <String>['o1', 'o2', 'o3']) {
          expect(find.byKey(Key('do-place-text-$id')), findsOneWidget);
        }
        final Text n = t.widget<Text>(
          find.descendant(of: find.byKey(const Key('do-place-text-o1')), matching: find.byType(Text)),
        );
        expect(n.style!.fontSize, 48, reason: 'a letter in Band B on a phone');
        await t.tap(find.byKey(const Key('do-place-o2')));
        await r.wait(t, 100);
        expect(r.heard.calls, isEmpty, reason: 'a letter stone says nothing when it is touched');
        await r.done(t);
      },
    );
  });

  group('the zones', () {
    testWidgets('on every board the tiles stay inside the answer zone and the stage inside its zone', (
      WidgetTester t,
    ) async {
      for (final Size size in <Size>[
        const Size(852, 393),
        const Size(667, 375),
        const Size(1180, 820),
        const Size(820, 1180),
      ]) {
        final Rig<Ls01SortSession> r = _sort(_sortPack(), 'sort');
        await r.pump(t, size: size);
        final Rect row = t.getRect(find.byKey(const Key('sort-tray')));
        final Rect stage = t.getRect(find.byKey(const Key('lesson-stage')));
        expect(stage.bottom, lessThanOrEqualTo(row.top), reason: '$size');
        await r.done(t);
      }
    });
  });
}

extension on LangPack {
  Map<String, Object?> activityOf(String id) => activity(id);
}
