import 'package:nitznutz/engine/course.dart';
import 'package:nitznutz/engine/course_rules.dart';
import 'package:nitznutz/engine/types.dart';

/// The id prefix a fixture course gives its skills: the capitals of a language course, `SK` for `core`.
String skillPrefix(String course) => course == Course.core ? 'SK' : course.toUpperCase();

/// A misconception tag of a fixture course, in the form the course uses.
String tagOf(String course, String name) =>
    course == Course.core ? 'M-${name.toUpperCase()}' : '$course.ph.$name';

/// A small course that is not real content: three skills in a line (`P-A-01`, `P-A-02`, `P-B-01`), three items for each in
/// three representations, one tag for the first skill and a repair activity for it.
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
  final List<ItemMeta> items = <ItemMeta>[];
  const List<Representation> reps = <Representation>[
    Representation.concrete,
    Representation.pictorial,
    Representation.symbolic,
  ];
  for (final String id in ids) {
    for (final (int r, Representation rep) in reps.indexed) {
      items.add(
        ItemMeta(
          id: '$course.${id.toLowerCase()}.$r',
          course: course,
          skills: <String, double>{id: 1},
          representation: rep,
          variantGroup: '$course.$id.g$r',
          difficulty: 0.3 + 0.2 * r,
          optionCount: 3,
          tags: id == ids.first ? <String>{tag} : const <String>{},
        ),
      );
    }
  }
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
