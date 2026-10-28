// The world (M8): which drawing a skill owns, how far each object has grown, when it calls for help, and the short
// revisit mission a bell flag opens. All pure, from the engine's own state.
import 'package:flutter_test/flutter_test.dart';
import 'package:nitznutz/engine/engine.dart';
import 'package:nitznutz/engine/types.dart';
import 'package:nitznutz/parent/progress.dart' show SkillInfo;
import 'package:nitznutz/rewards/award.dart';
import 'package:nitznutz/world/world_state.dart';

import 'engine/fixtures.dart';

const WorldCatalog catalog = WorldCatalog(
  skills: <String, String>{'SK-A-01': 'pool'},
  domains: <String, String>{'numbers': 'stair', 'shapes': 'cone-tree'},
  fallback: 'sprout',
);

Map<String, SkillInfo> infos() => <String, SkillInfo>{
  'SK-A-01': const SkillInfo(title: 'a', domain: 'numbers'),
  'SK-B-01': const SkillInfo(title: 'b', domain: 'numbers'),
  'SK-C-01': const SkillInfo(title: 'c', domain: 'numbers'),
  'SK-D-01': const SkillInfo(title: 'd', domain: 'logic'),
};

/// A catalogue with a spare item for each skill, so a delayed check can be passed.
Catalog withSpare() {
  final Catalog c = smallCatalog();
  return Catalog(
    skills: c.skills.values,
    items: <ItemMeta>[
      ...c.items.values,
      for (final String l in <String>['A', 'B', 'C', 'D'])
        ItemMeta(
          id: '$l.4',
          skills: <String, double>{'SK-$l-01': 1},
          representation: Representation.story,
          variantGroup: '$l-g4',
          optionCount: 3,
        ),
    ],
    tags: c.tags.values,
  );
}

void freshly(Story t, String l) {
  for (final String i in <String>['$l.1', '$l.2', '$l.1', '$l.2']) {
    t.right(i);
  }
  t.days(1);
  t.right('$l.3');
  t.right('$l.1');
}

void main() {
  test('a skill owns its own drawing, else its domain\'s, else the plant', () {
    expect(catalog.objectFor('SK-A-01', 'numbers'), 'pool');
    expect(catalog.objectFor('SK-B-01', 'numbers'), 'stair');
    expect(catalog.objectFor('SK-D-01', 'cs'), 'sprout');
    expect(
      WorldCatalog.parse('{"skills":{"X":"stall"},"domains":{},"fallback":"sprout"}').objectFor('X', 'math'),
      'stall',
    );
  });

  group('growth', () {
    test('a sketch while practising, colour at fresh mastery, fruit and a star at lasting understanding', () {
      final Engine e = engineOf(withSpare());
      final Story t = Story(e);
      freshly(t, 'A');
      t.days(8);
      t.right('A.4'); // lasting
      freshly(Story(e, start: t.at.add(const Duration(days: 1))), 'B'); // fresh only
      Story(e, start: t.at.add(const Duration(days: 1))).right('C.1'); // started
      final Map<TrophyLand, List<WorldObject>> world = buildWorld(
        engine: e,
        skills: infos(),
        starredSkills: const <String>{},
        catalog: catalog,
        now: t.at.add(const Duration(days: 2)),
      );
      final Map<String, WorldObject> byId = <String, WorldObject>{
        for (final WorldObject o in world[TrophyLand.counting]!) o.skillId: o,
      };
      expect(byId['SK-A-01']!.stage, GrowthStage.fruit);
      expect(byId['SK-A-01']!.star, isTrue);
      expect(byId['SK-A-01']!.objectId, 'pool');
      expect(byId['SK-B-01']!.stage, GrowthStage.colour);
      expect(byId['SK-B-01']!.objectId, 'stair');
      expect(byId['SK-C-01']!.stage, GrowthStage.sketch);
      expect(world.containsKey(TrophyLand.logic), isTrue, reason: 'every land with skills');
      expect(world.containsKey(TrophyLand.colors), isFalse);
    });

    test('a star the child was given stays on the map even when the engine no longer finds it', () {
      final Engine e = engineOf(withSpare()); // no history at all
      final Map<TrophyLand, List<WorldObject>> world = buildWorld(
        engine: e,
        skills: infos(),
        starredSkills: const <String>{'SK-B-01'},
        catalog: catalog,
        now: day0,
      );
      final WorldObject b = world[TrophyLand.counting]!.firstWhere((WorldObject o) => o.skillId == 'SK-B-01');
      expect(b.stage, GrowthStage.fruit);
      expect(
        world[TrophyLand.counting]!.firstWhere((WorldObject o) => o.skillId == 'SK-A-01').stage,
        GrowthStage.sketch,
      );
    });

    test(
      'a skill whose check is due keeps its colour and star and shows a bell flag; nothing is removed',
      () {
        final Engine e = engineOf(withSpare());
        final Story t = Story(e);
        freshly(t, 'A');
        t.days(8);
        t.right('A.4');
        Map<String, WorldObject> at(DateTime now) => <String, WorldObject>{
          for (final WorldObject o in buildWorld(
            engine: e,
            skills: infos(),
            starredSkills: const <String>{},
            catalog: catalog,
            now: now,
          )[TrophyLand.counting]!)
            o.skillId: o,
        };
        expect(at(t.at.add(const Duration(minutes: 1)))['SK-A-01']!.bell, isFalse);
        final WorldObject later = at(t.at.add(const Duration(days: 400)))['SK-A-01']!;
        expect(later.bell, isTrue, reason: 'long unseen: its check is due');
        expect(later.stage, GrowthStage.fruit, reason: 'it keeps its fruit and star');
        // A failed check makes it need a revisit at once.
        final Story failed = Story(e, start: t.at.add(const Duration(days: 10)))..wrong('A.2');
        expect(at(failed.at)['SK-A-01']!.bell, isTrue);
      },
    );
  });

  group('the revisit mission', () {
    test('three to five different ways of asking, never a probe, deterministic', () {
      final Engine e = engineOf(withSpare());
      final Story t = Story(e);
      freshly(t, 'A');
      final List<String> ids = missionItemIds(e, 'SK-A-01');
      expect(ids.length, inInclusiveRange(3, 5));
      expect(ids.toSet().length, ids.length);
      expect(ids.any((String i) => i.contains('.p')), isFalse, reason: 'probes are for searching for gaps');
      expect(missionItemIds(e, 'SK-A-01'), ids);
    });

    test('after a failed check it starts with another way of explaining than the one last used', () {
      final Engine e = engineOf(withSpare());
      final Story t = Story(e);
      freshly(t, 'A');
      t.days(3);
      t.wrong('A.1'); // concrete, failed
      final ItemMeta first = e.catalog.items[missionItemIds(e, 'SK-A-01').first]!;
      expect(first.representation, isNot(e.state.skills['SK-A-01']!.lastRepresentation));
    });

    test('a skill with nothing to ask has no mission', () {
      expect(missionItemIds(engineOf(withSpare()), 'SK-Z-99'), isEmpty);
    });
  });
}
