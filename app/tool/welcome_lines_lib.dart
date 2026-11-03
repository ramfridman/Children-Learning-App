// The lines of the daily welcome (B-42) as the app reads them: `assets/lines/welcome.json`, made from the two sources the
// rest of the team owns, so there is one source of truth and the app cannot drift from it.
//
//   content/lines/core.he.json          the `welcome.*` lines (the hebrew-text-editor): what the bubble shows
//   content/lines/welcome-topics.json   which skill goes with which topic line (the curriculum-expert)
//
// `welcome_lines_asset.dart` writes the file; `test/welcome_table_test.dart` fails when the file is not what this makes.
import 'dart:convert';
import 'dart:io';

import 'voice_text_lib.dart';

/// The schema name of the asset the app reads.
const String welcomeAssetSchema = 'welcome-lines/v1';

/// The `vo:` prefix of every welcome line.
const String welcomeVoicePrefix = 'vo:welcome.';

/// The asset's JSON text for [core] and [topics], two spaces of indentation and a final newline. Nothing from the topic
/// file's `note`, `checked` or `why` goes in (they are for the people who keep the table), and nothing is said to a child
/// that is not a line of the core file.
String welcomeAssetOf({required File core, required File topics}) {
  final Map<String, Object?> table = jsonDecode(topics.readAsStringSync()) as Map<String, Object?>;
  if (table['schema'] != 'welcome-topics/v1') {
    throw VoiceGenFailed('${topics.path}: the schema is not welcome-topics/v1');
  }
  final Map<String, String> lines = <String, String>{
    for (final SpokenLine l in coreLines(core))
      if (l.voId.startsWith(welcomeVoicePrefix)) l.voId: l.text,
  };
  final List<Object?> lands = <Object?>[
    for (final Object? entry in table['lands']! as List<Object?>) _landOf(entry! as Map<String, Object?>),
  ];
  final Map<String, Object?> out = <String, Object?>{
    'schema': welcomeAssetSchema,
    'note':
        'Made by tool/welcome_lines_asset.dart from content/lines/core.he.json and content/lines/welcome-topics.json. '
        'Do not edit.',
    'lines': lines,
    'lands': lands,
  };
  return '${const JsonEncoder.withIndent('  ').convert(out)}\n';
}

/// One land of the table without its reasons: where it is, its line, its topics and the skills it names by its land line.
Map<String, Object?> _landOf(Map<String, Object?> land) => <String, Object?>{
  'land': land['land'],
  'domain': land['domain'],
  'line': land['line'],
  'topics': <Object?>[
    for (final Object? topic in land['topics']! as List<Object?>) _topicOf(topic! as Map<String, Object?>),
  ],
  'landLine': land['landLine'],
};

Map<String, Object?> _topicOf(Map<String, Object?> topic) => <String, Object?>{
  'line': topic['line'],
  'skills': topic['skills'],
};
