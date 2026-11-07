// Fixture content for LS02, write a letter (L5-2b): a fixture language pack with the real stroke set of its script, the skills of one letter
// group in the shape of docs/languages/writing-mastery.md section 2 (the knowledge facet, the trace node of its bundle, the writing node after
// it), and activities of the four modes. JSON of the pack's files; not content: the clips are pending and the words only give the text something
// to be. The stroke sets are the teacher-checked files of `content/languages/strokes` (run from the `app` folder, as `flutter test` does).

import 'dart:convert';
import 'dart:io';

import 'package:nitznutz/engine/course.dart' show SkillIds;

import 'language_content.dart';

/// The script of each course's print letters.
const Map<String, String> strokeSetOf = <String, String>{
  'eng': 'latin',
  'heb': 'hebrew-print',
  'rus': 'cyrillic',
};

/// The real stroke document of [set] (`latin`, `cyrillic`, `hebrew-print`, `hebrew-script`), as the pack carries it.
Map<String, Object?> strokeSetDoc(String set) =>
    jsonDecode(File('../content/languages/strokes/$set.json').readAsStringSync())! as Map<String, Object?>;

/// The ids of the skills of one letter group: the knowledge facets (one or two skills of the bundle), the trace node and the writing node.
/// The roll-up of each dotted id is added by [Ls02Pack].
class GroupSkills {
  const GroupSkills(
    this.course, {
    String? facet,
    String? trace,
    String? write,
    this.moreFacets = const <String>[],
  }) : _facet = facet,
       _trace = trace,
       _write = write;

  final String course;
  final String? _facet;
  final String? _trace;
  final String? _write;

  /// A second facet of the bundle (heb B-15 beside B-14).
  final List<String> moreFacets;

  String get up => course.toUpperCase();
  String get facet => _facet ?? '$up-B-16';
  String get trace => _trace ?? '$up-B-23.G1';
  String get write => _write ?? '$up-B-19.G1';
  String get traceRollUp => trace.substring(0, trace.indexOf('.'));
  String get writeRollUp => write.substring(0, write.indexOf('.'));
  String get bundle => '$course.g1';
}

Map<String, Object?> skillJson(
  String course,
  String id, {
  String? writing,
  String? bundle,
  String strand = 'wri',
  List<String> needs = const <String>[],
  bool setCoverage = false,
  Map<String, Object?>? masteryRequires,
  List<String> tags = const <String>[],
}) => <String, Object?>{
  'schema': 'skill/v1',
  'id': id,
  'course': course,
  'domain': 'languages',
  'band': 'B',
  'title': he('כּוֹתְבִים אוֹת'),
  'strand': strand,
  'prerequisites': <Object?>[
    for (final String n in needs) <String, Object?>{'skill': n, 'weight': 0.8},
  ],
  'representations': <Object?>['embodied'],
  'misconceptions': tags,
  'retention': <String, Object?>{'targetRetention': 0.9, 'initialStabilityDays': 1},
  'writing': ?writing,
  'bundle': ?bundle,
  'setCoverage': ?(setCoverage ? true : null),
  'masteryRequires': ?masteryRequires,
};

/// An LS02 activity (`trace` 2.0) of [course]: its id is `<course>.<id>`. [mode] is `intro`, `trace`, `copy` or `memory`; [forms] the letters.
Map<String, Object?> letterJson({
  String course = 'eng',
  required String id,
  required String skill,
  required String mode,
  required List<String> forms,
  String? guide,
  String? model,
  String? cue,
  String? cueClip,
  bool word = false,
  String? source,
  bool? practice,
  Map<String, Object?>? intro,
  Map<String, Object?>? classify,
  String purpose = 'practice',
  String checkType = 'practice',
  String band = 'B',
  String? variantGroup,
}) {
  final bool isIntro = mode == 'intro';
  final Map<String, Object?> doc = commonJson(course, id, skill, 'trace', '2.0', purpose, band, 'embodied');
  doc['checkType'] = checkType;
  doc['variantGroup'] = variantGroup ?? (word ? id.replaceAll('_', '-') : forms.first);
  doc.addAll(linesJson('$course.$id', target: cueClip, promptText: 'כִּתְבוּ אֶת הָאוֹת.'));
  if (isIntro) {
    doc['hints'] = <Object?>[];
    doc['answer'] = <String, Object?>{'type': 'none'};
  } else {
    doc['answer'] = <String, Object?>{'type': 'trace', 'classify': classify ?? const <String, Object?>{}};
  }
  doc['scene'] = <String, Object?>{
    'mode': mode,
    'canvas': word ? 'word' : 'letter',
    'forms': forms,
    'source': ?source,
    'guide': ?(mode == 'trace' ? (guide ?? 'start') : null),
    'model': ?(mode == 'copy' ? (model ?? 'beside') : null),
    'cue': ?(mode == 'memory' ? (cue ?? 'sound') : null),
    'intro': ?intro,
    'practice': ?practice,
  };
  doc['a11y'] = <String, Object?>{'altText': 'כּוֹתְבִים אוֹת'};
  return doc;
}

/// The worked example of a letter: its sound and name clips, a key word and its picture (an asset id of the fixture, `ball_red`).
Map<String, Object?> introData(String course, String x, {String? name, String? picture = 'ball_red'}) =>
    <String, Object?>{
      'sound': 'vo:$course.snd.$x',
      'keyword': 'vo:$course.kw.$x',
      'name': name ?? 'vo:$course.name.$x',
      'picture': ?(picture == null ? null : 'asset:$picture'),
    };

/// A fixture pack with the stroke set of [course], the tags of writing, and the skills of one letter group. [letters] are
/// (form id, short name) of the group; the activities are added by the test.
class Ls02Pack {
  Ls02Pack(this.course, {GroupSkills? skills, bool writingTags = true})
    : pack = LangPack(course),
      skills = skills ?? GroupSkills(course) {
    final String set = strokeSetOf[course]!;
    pack.addPictures(<String>['ball_red']);
    pack.pack.addDocument('strokes.$set.json', 'strokes', set, strokeSetDoc(set));
    if (writingTags) {
      pack.addTag('wri.stroke', 'diagnostic', family: 'STROKE');
      pack.addTag('wri.lines', 'diagnostic', family: 'STROKE');
      pack.addTag('wri.shape', 'diagnostic', family: 'SHAPE');
      pack.addTag('wri.mirror', 'diagnostic', family: 'SHAPE');
      pack.addTag('wri.homophone', 'on_the_way', family: 'CODE');
      pack.addTag('wri.name', 'diagnostic', family: 'NAME');
    }
    final GroupSkills g = this.skills;
    void skill(Map<String, Object?> s) =>
        pack.pack.addDocument('skill.${s['id']}.json', 'skills', s['id']! as String, s);
    final Set<String> added = <String>{};
    void once(String id, Map<String, Object?> Function() make) {
      if (added.add(id)) skill(make());
    }

    // A dotted skill needs its roll-up in the pack.
    for (final String id in <String>[g.facet, ...g.moreFacets, g.trace, g.write]) {
      final String? parent = SkillIds.parentOf(id);
      if (parent != null) {
        once(parent, () => skillJson(course, parent, strand: id == g.trace || id == g.write ? 'wri' : 'ph'));
      }
    }
    for (final String id in <String>[g.facet, ...g.moreFacets]) {
      once(id, () => skillJson(course, id, bundle: g.bundle, strand: 'ph'));
    }
    once(g.trace, () => skillJson(course, g.trace, writing: 'practised', bundle: g.bundle, strand: 'wri'));
    once(
      g.write,
      () => skillJson(
        course,
        g.write,
        writing: 'memory',
        setCoverage: true,
        strand: 'wri',
        needs: <String>[g.trace, g.facet, ...g.moreFacets],
      ),
    );
  }

  final String course;
  final LangPack pack;
  final GroupSkills skills;

  String tag(String slug) => '$course.wri.$slug';

  /// The classifiers of an item (the tags of this fixture): start and direction to the stroke tag, lines, mirror.
  Map<String, Object?> classify({
    Map<String, String> partners = const <String, String>{},
    bool mirror = true,
  }) => <String, Object?>{
    'start': tag('stroke'),
    'direction': tag('stroke'),
    'lines': tag('lines'),
    if (mirror) 'mirror': tag('mirror'),
    if (partners.isNotEmpty) 'partners': partners,
  };

  void add(Map<String, Object?> a) => pack.add(a);

  /// A tag of the frame's catalogue under its engine id (`eng.wr.stroke_rtl`), of its [kind] and [family].
  void addCatalogueTag(String id, String kind, String family) =>
      pack.pack.addDocument('misconception.$id.json', 'misconceptions', id, <String, Object?>{
        'schema': 'misconception/v1',
        'id': id,
        'course': course,
        'kind': kind,
        'family': family,
        'skills': <Object?>[skills.facet],
        'parentText': 'The child is still learning this letter.',
        'repairActivities': <Object?>[],
        'preferredRepresentations': <Object?>['embodied'],
      });

  /// Adds a lesson of [items] (short ids) at place [sequence] on the path, naming [skillIds].
  void addLesson(String id, List<String> items, List<String> skillIds, int sequence) {
    pack.pack.addDocument('lesson.$course.$id.json', 'lessons', '$course.$id', <String, Object?>{
      'schema': 'lesson/v1',
      'id': '$course.$id',
      'course': course,
      'revision': 1,
      'band': 'B',
      'title': he('אוֹת חֲדָשָׁה'),
      'skills': skillIds,
      'items': <Object?>[for (final String i in items) '$course.$i'],
      'estimatedMinutes': 5,
      'celebration': line('vo:$course.$id.done', 'כָּל הַכָּבוֹד!'),
      'sequence': sequence,
    });
    (pack.pack.manifest['voPending']! as List<Object?>).add('vo:$course.$id.done');
  }

  /// The id of the stroke form of letter [x] in this course's set.
  String form(String x, {bool cap = false}) => switch (course) {
    'eng' => 'latin.$x',
    'heb' => 'hebrew-print.$x',
    _ => cap ? 'cyrillic.$x.cap' : 'cyrillic.$x',
  };
}
