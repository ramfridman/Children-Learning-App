// B-42 part (b): the welcome's lines and topic table. The app reads `assets/lines/welcome.json`, which is made from the
// editor's lines and the curriculum-expert's table; these tests keep the file equal to its sources, and every skill of
// the installed pack resolved to a topic line or to its land's line.
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:nitznutz/content/models.dart';
import 'package:nitznutz/rewards/award.dart';
import 'package:nitznutz/world/welcome_table.dart';

import '../tool/voice_text_lib.dart' show coreLines, SpokenLine;
import '../tool/welcome_lines_lib.dart';
import 'support/starter.dart';

void main() {
  final File asset = File('assets/lines/welcome.json');
  final File core = File('../content/lines/core.he.json');
  final File topics = File('../content/lines/welcome-topics.json');

  test('the asset is what the tool makes from the editor\'s lines and the topic table', () {
    expect(
      asset.readAsStringSync(),
      welcomeAssetOf(core: core, topics: topics),
      reason: 'run: dart run tool/welcome_lines_asset.dart',
    );
  });

  test('the asset holds the 48 lines of the core file, word for word, and nothing else', () {
    final WelcomeTable table = WelcomeTable.parse(asset.readAsStringSync());
    final Map<String, String> fromCore = <String, String>{
      for (final SpokenLine l in coreLines(core))
        if (l.voId.startsWith('vo:welcome.')) l.voId: l.text,
    };
    expect(fromCore, hasLength(48));
    expect(<String>{...table.lineIds}, fromCore.keys.toSet());
    for (final MapEntry<String, String> e in fromCore.entries) {
      expect(table.text(e.key), e.value, reason: e.key);
    }
  });

  test(
    'every line is used: each topic line has a skill, each land has its line, and the greetings are there',
    () {
      final WelcomeTable table = WelcomeTable.parse(asset.readAsStringSync());
      final Set<String> used = <String>{
        ...table.topicLines,
        for (final TrophyLand l in TrophyLand.values) table.landLine(l),
        'vo:welcome.hello.1',
        'vo:welcome.hello.2',
        'vo:welcome.hello.3',
        'vo:welcome.hello.first',
        'vo:welcome.close',
      };
      expect(used, table.lineIds.toSet(), reason: 'no voiced line is unused');
    },
  );

  test('the asset names no reason and no note about a skill: only what the app needs', () {
    final Map<String, Object?> doc = jsonDecode(asset.readAsStringSync()) as Map<String, Object?>;
    expect(doc.keys, <String>['schema', 'note', 'lines', 'lands']);
  });

  test('every skill of the installed pack is placed in the land of its domain; the ones that are not are listed', () async {
    final PackContent content = await loadStarter();
    final WelcomeTable table = WelcomeTable.parse(asset.readAsStringSync());
    final List<String> unmapped = <String>[];
    final List<String> wrongLand = <String>[];
    for (final SkillDoc skill in content.skills.values) {
      if (!table.places(skill.id)) {
        unmapped.add(skill.id);
      } else if (table.landOf(skill.id) != TrophyLand.ofDomain(skill.domain)) {
        wrongLand.add('${skill.id} (${skill.domain}) is placed in ${table.landOf(skill.id)?.name}');
      }
    }
    if (unmapped.isNotEmpty) {
      // ignore: avoid_print
      print(
        'Skills with no row in content/lines/welcome-topics.json (they would hear their land line): $unmapped',
      );
    }
    expect(unmapped, isEmpty, reason: 'ask the curriculum-expert to place them');
    expect(wrongLand, isEmpty);
    expect(content.skills, hasLength(100));
  });

  test('every skill the table names is a skill of the installed pack', () async {
    final PackContent content = await loadStarter();
    final WelcomeTable table = WelcomeTable.parse(asset.readAsStringSync());
    final Map<String, Object?> doc = jsonDecode(asset.readAsStringSync()) as Map<String, Object?>;
    final List<String> named = <String>[];
    for (final Object? entry in doc['lands']! as List<Object?>) {
      final Map<String, Object?> land = entry! as Map<String, Object?>;
      for (final Object? topic in land['topics']! as List<Object?>) {
        named.addAll(((topic! as Map<String, Object?>)['skills']! as List<Object?>).cast<String>());
      }
      named.addAll((land['landLine']! as List<Object?>).cast<String>());
    }
    expect(named.where((String s) => !content.skills.containsKey(s)), isEmpty);
    expect(named.toSet(), hasLength(named.length), reason: 'each skill once');
    expect(named.every(table.places), isTrue);
  });
}
