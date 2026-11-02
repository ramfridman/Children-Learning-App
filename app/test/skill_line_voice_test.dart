// B-45: the narrator says the map-card line (`childLine`) of a skill. The id of the recording comes from one function
// (skillLineVoiceId); every skill of the starter pack that has a line maps to an id, and that id has a line in
// content/lines/core.he.json whose text is the skill's own.
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:nitznutz/content/models.dart';
import 'package:nitznutz/voice/voice_lines.dart';

import 'support/starter.dart';

/// The ids the hebrew-text-editor proposed, from the file she made for the owner's decision.
Map<String, String> proposedIds() {
  final List<String> rows = File('../docs/review/b45-childline-proposed.tsv').readAsLinesSync();
  final Map<String, String> bySkill = <String, String>{};
  for (final String row in rows.skip(1)) {
    if (row.trim().isEmpty) continue;
    final List<String> cells = row.split('\t');
    final String source = cells[3]; // skill.COL-A-01.json > childLine.0.v
    bySkill[source.split('.json').first.substring('skill.'.length)] = cells[0];
  }
  return bySkill;
}

void main() {
  group('skillLineVoiceId', () {
    test('lower case, hyphens to underscores, under core.skill', () {
      expect(skillLineVoiceId('COL-A-01'), 'vo:core.skill.col_a_01');
      expect(skillLineVoiceId('NUM-B-14'), 'vo:core.skill.num_b_14');
      expect(skillLineVoiceId('LOG-A-05'), 'vo:core.skill.log_a_05');
    });

    test('an id that cannot make a voice id gives none', () {
      for (final String bad in <String>[
        '',
        '-',
        'COL--A',
        'COL-A-',
        'col a',
        'COL.A',
        'COL/A',
        'ABC_1',
        'עברית',
      ]) {
        expect(skillLineVoiceId(bad), isNull, reason: bad);
      }
    });

    test('the result fits the voice id pattern of the packs', () {
      final RegExp shape = RegExp(r'^vo:[a-z0-9_.]{1,80}$');
      expect(shape.hasMatch(skillLineVoiceId('SHP-C-12')!), isTrue);
    });
  });

  group('the skills of the starter pack', () {
    late PackContent content;
    late Map<String, String> proposed;

    setUpAll(() async {
      content = await loadStarter();
      proposed = proposedIds();
    });

    test('every skill with a childLine maps to an id, and the ids are all different', () {
      final List<SkillDoc> withLine = content.skills.values
          .where((SkillDoc s) => s.childLine != null)
          .toList();
      expect(withLine, isNotEmpty);
      final Set<String> ids = <String>{};
      for (final SkillDoc s in withLine) {
        final String? id = skillLineVoiceId(s.id);
        expect(id, isNotNull, reason: s.id);
        expect(ids.add(id!), isTrue, reason: 'two skills share $id');
      }
    });

    test('the ids the editor proposed are the ones the app asks for', () {
      expect(proposed, isNotEmpty);
      for (final MapEntry<String, String> p in proposed.entries) {
        expect(skillLineVoiceId(p.key), p.value, reason: p.key);
      }
      for (final SkillDoc s in content.skills.values.where((SkillDoc s) => s.childLine != null)) {
        expect(proposed.containsKey(s.id), isTrue, reason: '${s.id} has a line but no proposed recording');
      }
    });

    test('each core line of a skill says the same as the skill shows', () {
      final Map<String, Object?> core =
          jsonDecode(File('../content/lines/core.he.json').readAsStringSync()) as Map<String, Object?>;
      final Map<String, String> lines = <String, String>{
        for (final Object? l in core['lines']! as List<Object?>)
          (l! as Map<String, Object?>)['id']! as String: (l as Map<String, Object?>)['text']! as String,
      };
      final List<String> have = lines.keys.where((String id) => id.startsWith('core.skill.')).toList();
      expect(have, isNotEmpty, reason: 'content/lines/core.he.json must hold the core.skill.* lines');
      for (final SkillDoc s in content.skills.values.where((SkillDoc s) => s.childLine != null)) {
        final String id = skillLineVoiceId(s.id)!.substring('vo:'.length);
        expect(lines[id], s.childLine, reason: '$id must equal the childLine of ${s.id}');
      }
    });
  });
}
