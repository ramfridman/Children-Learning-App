import 'course.dart';
import 'types.dart';

// The invariants of docs/languages/frame.md section 1.5, as they hold for the engine's catalogue. The pack validator
// (content/pack_validation.dart) refuses a pack that breaks them; this is the same check on what the engine actually holds,
// so a catalogue made from several packs (the lands and the language courses together) cannot let one course reach into
// another. Pure: it reads a catalogue and returns the problems, one sentence each.

/// What is wrong with [catalog] with respect to courses; empty when courses never mix in it.
List<String> courseProblems(Catalog catalog) {
  final List<String> out = <String>[];
  final Set<String> rollUps = <String>{for (final String id in catalog.skills.keys) ?SkillIds.parentOf(id)};

  for (final SkillNode s in catalog.skills.values) {
    if (!Course.isKnown(s.course)) out.add('${s.id} is of the unknown course ${s.course}');
    if (Course.ofSkillId(s.id) != s.course) {
      out.add('${s.id} is in the course ${s.course}, but its id belongs to ${Course.ofSkillId(s.id)}');
    }
    for (final String p in s.prerequisites.keys) {
      final SkillNode? need = catalog.skills[p];
      if (need == null) {
        out.add('${s.id} needs a skill that does not exist: $p');
      } else if (need.course != s.course) {
        out.add('${s.id} (${s.course}) needs $p (${need.course}): no prerequisite across courses');
      }
    }
  }

  for (final ItemMeta i in catalog.items.values) {
    for (final String id in i.skills.keys) {
      final SkillNode? s = catalog.skills[id];
      if (s == null) continue;
      if (s.course != i.course) {
        out.add('${i.id} (${i.course}) gives evidence for $id (${s.course}): evidence never crosses courses');
      }
      if (rollUps.contains(id)) out.add('${i.id} names $id, a roll-up with no estimate of its own');
    }
    for (final String t in <String>{...i.tags, ?i.contradicts}) {
      final String tagCourse = catalog.tags[t]?.course ?? Course.ofTag(t);
      if (tagCourse != i.course) out.add('${i.id} (${i.course}) names the misconception $t ($tagCourse)');
    }
  }

  for (final TagInfo t in catalog.tags.values) {
    if (Course.ofTag(t.id) != t.course) {
      out.add('${t.id} is in the course ${t.course}, but its id belongs to ${Course.ofTag(t.id)}');
    }
    for (final String id in t.skills) {
      final SkillNode? s = catalog.skills[id];
      if (s != null && s.course != t.course) {
        out.add('${t.id} (${t.course}) traces back to $id (${s.course})');
      }
    }
    for (final String id in t.repairActivities) {
      final ItemMeta? i = catalog.items[id];
      if (i != null && i.course != t.course) {
        out.add('${t.id} (${t.course}) is repaired by $id (${i.course}): a repair never mixes courses');
      }
    }
  }
  return out;
}

/// The catalogues of several packs as one, which the engine can hold for a child who plays more than one course. Throws a
/// [StateError] naming the problem if an id is used twice or if courses mix: a merged catalogue is never trusted blindly.
Catalog mergeCatalogs(Iterable<Catalog> parts) {
  final List<SkillNode> skills = <SkillNode>[];
  final List<ItemMeta> items = <ItemMeta>[];
  final List<TagInfo> tags = <TagInfo>[];
  final Set<String> seen = <String>{};
  void once(String kind, String id) {
    if (!seen.add('$kind:$id')) throw StateError('the $kind $id is in more than one pack');
  }

  for (final Catalog c in parts) {
    for (final SkillNode s in c.skills.values) {
      once('skill', s.id);
      skills.add(s);
    }
    for (final ItemMeta i in c.items.values) {
      once('item', i.id);
      items.add(i);
    }
    for (final TagInfo t in c.tags.values) {
      once('tag', t.id);
      tags.add(t);
    }
  }
  final Catalog merged = Catalog(skills: skills, items: items, tags: tags);
  final List<String> problems = courseProblems(merged);
  if (problems.isNotEmpty) throw StateError('courses mix: ${problems.first}');
  return merged;
}
