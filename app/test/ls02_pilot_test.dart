// The LS02 items of the three group-1 pilot slices (docs/languages/*/band-b-pilot.md) must validate: each is read from its markdown file, made into
// the activity file a pack would carry, and put through the real pack validator with the real stroke set of its script. The tags are the engine
// ids of the frame's catalogue (docs/languages/frame.md section 4.2).
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:nitznutz/content/ls02_checks.dart';
import 'package:nitznutz/content/pack_validation.dart';
import 'package:nitznutz/content/schema.dart';

import 'support/ls02_content.dart';

String _read(String path) => File('../$path').readAsStringSync().replaceAll('\r\n', '\n');

/// The catalogue of frame section 4.2: a tag as the teachers write it to (engine id, kind, family).
Map<String, ({String id, String kind, String family})> _catalogue() {
  final Map<String, ({String id, String kind, String family})> out =
      <String, ({String id, String kind, String family})>{};
  final RegExp row = RegExp(
    r'^\| (M-[A-Z]+-[A-Z0-9-]+) \| `([a-z]{3}\.[a-z]{2,4}\.[a-z0-9_]+)` \| ([^|]+) \| ([A-Z]+) \|',
    multiLine: true,
  );
  for (final RegExpMatch m in row.allMatches(_read('docs/languages/frame.md'))) {
    out[m.group(1)!] = (
      id: m.group(2)!,
      kind: m.group(3)!.trim().startsWith('on-the-way') ? 'on_the_way' : 'diagnostic',
      family: m.group(4)!,
    );
  }
  return out;
}

/// The cells of the markdown table rows of the section that begins with [heading] (up to the next heading).
List<List<String>> _rows(String text, String heading) {
  final int at = text.indexOf(heading);
  expect(at, isNonNegative, reason: 'no section "$heading"');
  final int end = text.indexOf(RegExp(r'^#{2,3} ', multiLine: true), at + heading.length);
  final String body = text.substring(at, end < 0 ? text.length : end);
  return <List<String>>[
    for (final String line in body.split('\n'))
      if (line.startsWith('| ') && !line.startsWith('| ---') && !line.startsWith('|---'))
        <String>[for (final String c in line.substring(1, line.length - 1).split(' | ')) c.trim()],
  ];
}

/// The backticked tokens of a cell, in order.
List<String> _ticks(String cell) => <String>[
  for (final RegExpMatch m in RegExp(r'`([^`]+)`').allMatches(cell)) m.group(1)!,
];

String _vo(String id) => 'vo:${id.toLowerCase().replaceAll('-', '_')}';

class _Item {
  _Item(
    this.id,
    this.skill,
    this.mode, {
    required this.forms,
    this.guide,
    this.model,
    this.cue,
    this.cueClip,
    this.check = false,
    this.word = false,
    this.intro,
    this.classify = const <String, String>{},
    this.partners = const <String, String>{},
  });

  final String id;
  final String skill;
  final String mode;
  final List<String> forms;
  final String? guide;
  final String? model;
  final String? cue;
  final String? cueClip;
  final bool check;
  final bool word;
  final Map<String, Object?>? intro;

  /// start, direction, lines, mirror: the catalogue name of the tag.
  final Map<String, String> classify;

  /// form id to the catalogue name of its tag.
  final Map<String, String> partners;
}

// ---- English: the activity data is in the file as JSON ----

List<_Item> _english() {
  final String text = _read('docs/languages/english/band-b-pilot.md');
  final List<_Item> out = <_Item>[];
  final RegExp data = RegExp(r'^([a-z]\d{2}): (\{.*"type": "trace".*\})$', multiLine: true);
  // The skill of each item is the section it is in; a check is marked **C** in its table row.
  final Set<String> checks = <String>{
    for (final RegExpMatch m in RegExp(
      r'^\| ([a-z]\d{2}) \*\*C\*\* \| LS02',
      multiLine: true,
    ).allMatches(text))
      m.group(1)!,
  };
  for (final RegExpMatch m in data.allMatches(text)) {
    final String id = m.group(1)!;
    final Map<String, Object?> j = _json(m.group(2)!);
    final String mode = j['mode']! as String;
    final Map<String, Object?> prompt = j['prompt']! as Map<String, Object?>;
    final Map<String, Object?> classify =
        (j['classify'] as Map<String, Object?>?) ?? const <String, Object?>{};
    final String skill = mode == 'copy' || mode == 'memory' ? 'ENG-B-19.G1' : 'ENG-B-23.G1';
    out.add(
      _Item(
        id,
        skill,
        mode,
        forms: <String>[for (final Object? f in j['forms']! as List<Object?>) f! as String],
        guide: j['guide'] as String?,
        model: j['model'] as String?,
        cue: j['cue'] as String?,
        cueClip: prompt['target'] == null ? null : _vo((prompt['target']! as String).substring(3)),
        check: checks.contains(id),
        intro: mode == 'intro'
            ? <String, Object?>{
                'sound': _vo((prompt['sound']! as String).substring(3)),
                'keyword': _vo((prompt['keyword']! as String).substring(3)),
                'name': _vo((prompt['name']! as String).substring(3)),
              }
            : null,
        classify: <String, String>{
          for (final String k in <String>['start', 'direction', 'lines', 'mirror'])
            if (classify[k] != null) k: classify[k]! as String,
        },
        partners: <String, String>{
          for (final MapEntry<String, Object?> p
              in ((classify['partners'] as Map<String, Object?>?) ?? const <String, Object?>{}).entries)
            p.key: p.value! as String,
        },
      ),
    );
  }
  return out;
}

Map<String, Object?> _json(String text) => jsonDecode(text)! as Map<String, Object?>;

Map<String, Object?> _copy(Map<String, Object?> m) => jsonDecode(jsonEncode(m))! as Map<String, Object?>;

// ---- Hebrew: the items are table rows ----

List<_Item> _hebrew() {
  final String text = _read('docs/languages/hebrew/band-b-pilot.md');
  final List<_Item> out = <_Item>[];
  // The name clip of each letter is the second clip of the prompt of its trace; the sound clip is in the intro table.
  final Map<String, String> name = <String, String>{};
  for (final List<String> r in _rows(text, '### 5.4 HEB-B-24.S1')) {
    if (!r[0].startsWith('B-24.')) continue;
    final List<String> t = _ticks(r[2]);
    if (_ticks(r[3]).isEmpty) throw StateError('row $r');
    name[_ticks(r[3]).first] = t.last;
  }
  for (final List<String> r in _rows(text, '### 5.1 The letter introductions')) {
    if (!r[0].startsWith('B-24.i')) continue;
    final String form = _ticks(r[1]).single;
    out.add(
      _Item(
        'b24_${r[0].substring(5)}',
        'HEB-B-24.S1',
        'intro',
        forms: <String>[form],
        intro: <String, Object?>{
          'sound': _vo(_ticks(r[3]).first),
          if (_ticks(r[4]).isNotEmpty) 'keyword': _vo(_ticks(r[4]).first),
          'name': _vo(name[form]!),
        },
      ),
    );
  }
  Map<String, String> partnersOf(String cell) => <String, String>{
    for (final RegExpMatch m in RegExp(r'`([a-z-]+\.[a-z-]+)` \[([A-Z-]+)\]').allMatches(cell))
      m.group(1)!: 'M-HEB-${m.group(2)}',
  };
  final Map<String, Map<String, String>> byRow = <String, Map<String, String>>{};
  for (final List<String> r in _rows(text, '### 5.4 HEB-B-24.S1')) {
    if (!r[0].startsWith('B-24.')) continue;
    final String n = r[0].split(' ').first;
    final bool word = r[1].contains('canvas: word');
    final List<String> forms = _ticks(r[3]).where((String f) => f.startsWith('hebrew-print.')).toList();
    final Map<String, String> partners = word
        ? <String, String>{
            for (final String k in <String>['B-24.3', 'B-24.6', 'B-24.7']) ...?byRow[k],
          }
        : partnersOf(r[4]);
    byRow[n] = partners;
    out.add(
      _Item(
        'b24_${n.substring(5)}',
        'HEB-B-24.S1',
        'trace',
        forms: forms,
        guide: 'start',
        word: word,
        classify: <String, String>{
          'start': 'M-HEB-STROKE',
          'direction': 'M-HEB-STROKE',
          if (!r[1].contains('`mirror` off')) 'mirror': 'M-HEB-MIRROR',
        },
        partners: partners,
      ),
    );
  }
  for (final List<String> r in _rows(text, '### 5.6 HEB-B-26.S1')) {
    if (!r[0].startsWith('B-26.')) continue;
    final String n = r[0].split(' ').first;
    final List<String> mode = _ticks(r[1]);
    final bool copy = r[1].startsWith('copy');
    final String form = _ticks(r[3]).single;
    out.add(
      _Item(
        'b26_${n.substring(5)}',
        'HEB-B-26.S1',
        copy ? 'copy' : 'memory',
        forms: <String>[form],
        model: copy ? mode.first.split(': ').last : null,
        cue: copy ? null : mode.first.split(': ').last,
        cueClip: copy ? null : _vo(_ticks(r[2]).last),
        check: r[0].contains(' C'),
        classify: <String, String>{
          'start': 'M-HEB-STROKE',
          'direction': 'M-HEB-STROKE',
          if (form != 'hebrew-print.mem-final') 'mirror': 'M-HEB-MIRROR',
        },
        partners: partnersOf(r[4]),
      ),
    );
  }
  return out;
}

// ---- Russian: the items are table rows ----

List<_Item> _russian() {
  final String text = _read('docs/languages/russian/band-b-pilot.md');
  final List<_Item> out = <_Item>[];
  for (final List<String> r in _rows(text, '### `RUS-B-24.G1`')) {
    final String id = _ticks(r[0]).isEmpty ? '' : _ticks(r[0]).first;
    if (!id.startsWith('rus.b24g1.')) continue;
    final String short = id.substring('rus.'.length).replaceAll('.', '_');
    if (r[1].contains('intro')) {
      out.add(
        _Item(
          short,
          'RUS-B-24.G1',
          'intro',
          forms: <String>[_ticks(r[2]).single],
          intro: <String, Object?>{
            'sound': _vo(_ticks(r[3]).single),
            'keyword': _vo(_ticks(r[4]).first),
            'name': _vo(_ticks(r[5]).first),
          },
        ),
      );
    } else {
      out.add(
        _Item(
          short,
          'RUS-B-24.G1',
          'trace',
          forms: <String>[_ticks(r[2]).single],
          guide: _ticks(r[3]).isEmpty ? r[3] : _ticks(r[3]).first,
        ),
      );
    }
  }
  for (final List<String> r in _rows(text, '### `RUS-B-26.G1`')) {
    final List<String> id = _ticks(r[0]);
    if (id.isEmpty || !id.first.startsWith('rus.b26g1.')) continue;
    final bool copy = r[1].contains('copy');
    final String cue = r[3].startsWith('name') ? 'name' : 'sound';
    out.add(
      _Item(
        id.first.substring('rus.'.length).replaceAll('.', '_'),
        'RUS-B-26.G1',
        copy ? 'copy' : 'memory',
        forms: <String>[_ticks(r[2]).single],
        model: copy ? 'beside' : null,
        cue: copy ? null : cue,
        cueClip: copy ? null : _vo(_ticks(r[4]).last),
        check: r[0].contains('` C'),
        classify: <String, String>{
          'start': 'M-RUS-STROKE',
          'direction': 'M-RUS-STROKE',
          'lines': 'M-RUS-STROKE',
          'mirror': 'M-RUS-STROKE',
        },
        partners: <String, String>{
          for (final RegExpMatch m in RegExp(r'`(cyrillic\.[a-z.-]+)` \((M-RUS-[A-Z]+)\)').allMatches(r[5]))
            m.group(1)!: m.group(2)!,
        },
      ),
    );
  }
  return out;
}

/// A pack of the pilot items of [course], and the problems the validator finds in it.
({Ls02Pack pack, List<Problem> problems, List<_Item> items}) _validated(
  String course,
  List<_Item> items,
  GroupSkills skills,
) {
  final Ls02Pack p = Ls02Pack(course, skills: skills, writingTags: false);
  final Map<String, ({String id, String kind, String family})> catalogue = _catalogue();
  final Set<String> tagged = <String>{};
  String tagId(String name) {
    final ({String id, String kind, String family}) t =
        catalogue[name] ?? (throw StateError('"$name" is not in the catalogue of frame 4.2'));
    if (tagged.add(t.id)) p.addCatalogueTag(t.id, t.kind, t.family);
    return t.id;
  }

  for (final _Item i in items) {
    final Map<String, Object?> classify = <String, Object?>{
      for (final MapEntry<String, String> c in i.classify.entries) c.key: tagId(c.value),
      if (i.partners.isNotEmpty)
        'partners': <String, Object?>{
          for (final MapEntry<String, String> e in i.partners.entries) e.key: tagId(e.value),
        },
    };
    p.add(
      letterJson(
        course: course,
        id: i.id,
        skill: i.skill,
        mode: i.mode,
        forms: i.forms,
        guide: i.guide == 'full' ? 'full' : 'start',
        model: i.model,
        cue: i.cue,
        cueClip: i.cueClip,
        word: i.word,
        intro: i.intro,
        classify: i.mode == 'intro' ? null : classify,
        purpose: i.check ? 'check' : 'practice',
        checkType: i.check ? 'transfer' : 'practice',
      ),
    );
  }
  final Map<String, Object?> docs = _copy(p.pack.pack.docs);
  final Map<String, Object?> manifest = _copy(p.pack.pack.manifest);
  return (
    pack: p,
    problems: validatePack(manifest: manifest, docs: docs, files: p.pack.pack.files),
    items: items,
  );
}

void main() {
  const GroupSkills engSkills = GroupSkills(
    'eng',
    facet: 'ENG-B-16',
    trace: 'ENG-B-23.G1',
    write: 'ENG-B-19.G1',
  );
  const GroupSkills hebSkills = GroupSkills(
    'heb',
    facet: 'HEB-B-14.S1',
    moreFacets: <String>['HEB-B-15.S1'],
    trace: 'HEB-B-24.S1',
    write: 'HEB-B-26.S1',
  );
  const GroupSkills rusSkills = GroupSkills(
    'rus',
    facet: 'RUS-B-18',
    trace: 'RUS-B-24.G1',
    write: 'RUS-B-26.G1',
  );

  group('the pilot items of LS02 validate', () {
    test('English group 1 (s a t p i n): 6 intros, 7 traces, copy and memory items', () {
      final items = _english();
      expect(items.where((_Item i) => i.mode == 'intro'), hasLength(6));
      expect(items.where((_Item i) => i.mode == 'trace'), hasLength(7));
      expect(items.where((_Item i) => i.mode == 'memory').length, greaterThanOrEqualTo(12));
      final r = _validated('eng', items, engSkills);
      // The pilot lists no check for the trace node, and every letter has a memory item with each cue.
      expect(r.problems, isEmpty, reason: r.problems.join('\n'));
    });

    test('Hebrew S1 (מ ל שׁ ר א בּ ת ם): 8 intros, 9 traces with the word, copy and memory items', () {
      final items = _hebrew();
      expect(items.where((_Item i) => i.mode == 'intro'), hasLength(8));
      expect(items.where((_Item i) => i.mode == 'trace'), hasLength(9));
      expect(items.where((_Item i) => i.word), hasLength(1));
      expect(items.where((_Item i) => i.mode == 'copy'), hasLength(3));
      expect(items.where((_Item i) => i.mode == 'memory'), hasLength(5));
      final r = _validated('heb', items, hebSkills);
      // The one thing the validator finds is a gap the slice owns up to (hebrew/band-b-pilot.md section 5.6: "HEB-2b adds ... the items for
      // א, בּ and ם"): בּ has a copy item (B-26.2) and no memory item, so B-26.S1 could not be mastered from the slice alone (writing-mastery
      // section 8 rule 4). It goes to the curriculum-expert; when HEB-2b adds the memory items this expectation becomes isEmpty.
      expect(r.problems.map((Problem p) => p.toString()), <String>[
        'skill.HEB-B-26.S1.json › writing: the letter hebrew-print.bet has no memory item: each letter must be written once from memory',
      ]);
    });

    test('Russian group 1 (А У О М, capital and small): 4 intros, 8 traces, copy and memory items', () {
      final items = _russian();
      expect(items.where((_Item i) => i.mode == 'intro'), hasLength(4));
      expect(items.where((_Item i) => i.mode == 'trace'), hasLength(8));
      expect(items.where((_Item i) => i.mode == 'copy'), hasLength(4));
      expect(items.where((_Item i) => i.mode == 'memory'), hasLength(8));
      final r = _validated('rus', items, rusSkills);
      expect(r.problems, isEmpty, reason: r.problems.join('\n'));
    });
  });

  group('the visits of the pilots keep E-2', () {
    // Each visit's table row, and how many letters it introduces.
    test('English: at most 3 new letters a visit (n01 to n06)', () {
      final String text = _read('docs/languages/english/band-b-pilot.md');
      for (final List<String> r in _rows(text, '## 6. Lessons (visits)')) {
        if (!RegExp(r'^V\d$').hasMatch(r[0])) continue;
        expect(
          RegExp(r'\bn0\d\b').allMatches(r[2]).length,
          lessThanOrEqualTo(newLettersPerVisit('eng')),
          reason: r[0],
        );
      }
    });

    test('Hebrew: at most 2 new letters a visit (B-24.i1 to i8)', () {
      final String text = _read('docs/languages/hebrew/band-b-pilot.md');
      int seen = 0;
      for (final List<String> r in _rows(text, '## 7. Lessons (visits) for the pilot')) {
        if (!RegExp(r'^V\d$').hasMatch(r[0])) continue;
        final int n = RegExp(r'B-24\.i\d').allMatches(r[1]).length;
        expect(n, lessThanOrEqualTo(newLettersPerVisit('heb')), reason: r[0]);
        seen += n;
      }
      expect(seen, 8);
    });

    test('Russian: at most 3 new letters a visit (i01 to i04)', () {
      final String text = _read('docs/languages/russian/band-b-pilot.md');
      int seen = 0;
      for (final List<String> r in _rows(text, '## 5. Lessons (proposed')) {
        if (!RegExp(r'^G1-\d$').hasMatch(r[0])) continue;
        final int n = RegExp(r'\bi0\d\b').allMatches(r[1]).length;
        expect(n, lessThanOrEqualTo(newLettersPerVisit('rus')), reason: r[0]);
        seen += n;
      }
      expect(seen, 4);
    });
  });
}
