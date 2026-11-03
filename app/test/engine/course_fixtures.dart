import 'package:nitznutz/engine/course.dart';
import 'package:nitznutz/engine/course_rules.dart';
import 'package:nitznutz/engine/engine.dart';
import 'package:nitznutz/engine/types.dart';

import 'fixtures.dart';

/// The id prefix a fixture course gives its skills: the capitals of a language course, `SK` for `core`.
String skillPrefix(String course) => course == Course.core ? 'SK' : course.toUpperCase();

/// A misconception tag of a fixture course, in the form the course uses.
String tagOf(String course, String name) =>
    course == Course.core ? 'M-${name.toUpperCase()}' : '$course.ph.$name';

/// Three items for a skill, in three representations: `<id>.0` concrete, `<id>.1` pictorial (a transfer check), `<id>.2` an
/// open reverse check (symbolic). Two kinds of check, so even a core skill can reach fresh mastery. Each is a group of its
/// own, as a word would be.
List<ItemMeta> itemsOf(SkillNode s, {Set<String> tags = const <String>{}}) {
  const List<Representation> reps = <Representation>[
    Representation.concrete,
    Representation.pictorial,
    Representation.symbolic,
  ];
  return <ItemMeta>[
    for (final (int r, Representation rep) in reps.indexed)
      ItemMeta(
        id: '${s.id}.$r',
        course: s.course,
        skills: <String, double>{s.id: 1},
        representation: rep,
        checkType: switch (r) {
          1 => CheckType.transfer,
          2 => CheckType.reverse,
          _ => CheckType.practice,
        },
        variantGroup: '${s.id}.g$r',
        difficulty: 0.3 + 0.2 * r,
        optionCount: r == 2 ? 0 : 3,
        tags: tags,
      ),
  ];
}

/// A small course that is not real content: three skills in a line (`P-A-01`, `P-A-02`, `P-B-01`), three items for each,
/// one tag for the first skill and a repair activity for it.
({List<SkillNode> skills, List<ItemMeta> items, List<TagInfo> tags}) miniCourse(String course) {
  final String p = skillPrefix(course);
  final String tag = tagOf(course, 'dir');
  final List<String> ids = <String>['$p-A-01', '$p-A-02', '$p-B-01'];
  final List<SkillNode> skills = <SkillNode>[
    for (final (int i, String id) in ids.indexed)
      SkillNode(
        id: id,
        course: course,
        prerequisites: i == 0 ? const <String, double>{} : <String, double>{ids[i - 1]: 1},
        tags: i == 0 ? <String>{tag} : const <String>{},
      ),
  ];
  final List<ItemMeta> items = <ItemMeta>[
    for (final (int i, SkillNode s) in skills.indexed)
      ...itemsOf(s, tags: i == 0 ? <String>{tag} : const <String>{}),
  ];
  return (
    skills: skills,
    items: items,
    tags: <TagInfo>[
      TagInfo(
        id: tag,
        course: course,
        skills: <String>[ids.first],
        repairActivities: <String>[items.first.id],
      ),
    ],
  );
}

/// The catalogue of one fixture course.
Catalog miniCatalog(String course) {
  final ({List<SkillNode> skills, List<ItemMeta> items, List<TagInfo> tags}) c = miniCourse(course);
  return Catalog(skills: c.skills, items: c.items, tags: c.tags);
}

/// `core` and the three languages together, as the app holds them for a child who plays everything.
Catalog allCourses() => mergeCatalogs(<Catalog>[for (final String c in Course.all) miniCatalog(c)]);

/// A catalogue of the given skills, each with the three items of [itemsOf] (language skills carry their own course).
Catalog catalogOf(List<SkillNode> skills, {List<ItemMeta> extraItems = const <ItemMeta>[]}) => Catalog(
  skills: skills,
  items: <ItemMeta>[for (final SkillNode s in skills) ...itemsOf(s), ...extraItems],
);

/// Brings a skill to fresh mastery with the three items of [itemsOf]: right answers on one day, then the reverse check on the
/// next (in [session], if one is given). The story's clock moves on by a day.
void master(Story s, String skillId, {int? session}) {
  for (final int r in <int>[0, 1, 0, 1]) {
    s.right('$skillId.$r', session: session);
  }
  s.days(1);
  s.right('$skillId.2', session: session);
  s.right('$skillId.1', session: session);
}

/// Fresh mastery of [skillId] has been reached in [engine].
bool isFresh(Engine engine, String skillId) => engine.state.skills[skillId]?.freshAt != null;
