// Writes app/assets/lines/welcome.json from the welcome lines and the topic table (see welcome_lines_lib.dart). Run from
// app/:
//
//   dart run tool/welcome_lines_asset.dart          writes the file
//   dart run tool/welcome_lines_asset.dart --check  says whether the file is up to date (exit 1 when it is not)
//
// It reads two files of this repository and writes one; it needs no key and no network.
import 'dart:io';

import 'voice_text_lib.dart' show VoiceGenFailed;
import 'welcome_lines_lib.dart';

void main(List<String> args) {
  final File out = File('assets/lines/welcome.json');
  try {
    final String made = welcomeAssetOf(
      core: File('../content/lines/core.he.json'),
      topics: File('../content/lines/welcome-topics.json'),
    );
    if (args.contains('--check')) {
      final bool same = out.existsSync() && out.readAsStringSync() == made;
      stdout.writeln(
        same ? 'assets/lines/welcome.json is up to date' : 'assets/lines/welcome.json is out of date',
      );
      exit(same ? 0 : 1);
    }
    out.parent.createSync(recursive: true);
    out.writeAsStringSync(made);
    stdout.writeln('wrote ${out.path}: ${made.length} characters');
  } on VoiceGenFailed catch (e) {
    stderr.writeln('FAILED: $e');
    exit(1);
  }
}
