// Makes tutor lines ahead of time on the gateway, so the first lesson already meets lines that were made, checked and
// voiced. Run from the app/ folder:
//
//   dart run tool/tutor_prewarm.dart plan    <pack file> --characters nitzi,bumbi [--bands A,B,C] [--forms f,m,n]
//   dart run tool/tutor_prewarm.dart make    <pack file> --characters ... --confirm-lines <N>
//   dart run tool/tutor_prewarm.dart measure <pack file> --characters ... [--count 5]
//   dart run tool/tutor_prewarm.dart evaluate <pack file> --characters ... --confirm-lines <N> [--report <file>]
//   dart run tool/tutor_prewarm.dart voice    <pack file> --characters ... --lines <file> --confirm-lines <N>
//   dart run tool/tutor_prewarm.dart carry    <new pack file> --from <older version>
//
// `plan` makes nothing and spends nothing: it prints how many lines, how many voice characters and the estimated cost.
// `make` refuses to start unless --confirm-lines equals the number `plan` printed as "to make". `measure` makes a few
// fresh lines (kept nowhere) and prints how long the model and the voice took, so the speed is a number, not a guess.
// `evaluate` asks the model (no voice, nothing kept) for every line of the grid and reports how often the ten checks
// pass, which ones refuse, and the words the lexicon lacks; every sentence goes to the report file for reading.
// `voice` speaks exactly the sentences a person approved (a report with lines struck out): the ten checks run again,
// no model is asked, and the lines are kept as reviewed lines that a later prompt change never touches.
//
// `carry` copies the reviewed lines of an older version of the pack to the new one, for the items whose revision did not
// change, so a pack that changes only its notes keeps its voiced lines. It uses no model and no voice and costs nothing.
//
// The publish secret is read from NITZNUTZ_PUBLISH_SECRET only. The project url comes from --url or
// config/dev.local.json. No key of a vendor is ever on this computer's side of the call: the gateway holds them.
import 'dart:convert';
import 'dart:io';

import 'package:nitznutz/content/pack_verify.dart';

import 'prewarm_lib.dart';
import 'prewarm_voice.dart';

const String _publicKeyAsset = 'assets/pack_signing_public_key.txt';

Future<void> main(List<String> args) async {
  if (args.length < 2) {
    stderr.writeln(
      'usage: dart run tool/tutor_prewarm.dart plan|make|measure|evaluate|voice <pack file> --characters a,b '
      '[--bands A,B,C] [--forms f,m,n] [--confirm-lines N] [--count N] [--url <project url>]\n'
      '       dart run tool/tutor_prewarm.dart carry <new pack file> --from <older version> [--url <project url>]',
    );
    exit(2);
  }
  try {
    await _run(args);
  } on PrewarmFailed catch (e) {
    stderr.writeln(e.message);
    exit(1);
  }
}

String? _option(List<String> args, String name) {
  final int i = args.indexOf(name);
  return i >= 0 && i + 1 < args.length ? args[i + 1] : null;
}

List<String> _list(String? v, List<String> fallback) => v == null
    ? fallback
    : v.split(',').map((String s) => s.trim()).where((String s) => s.isNotEmpty).toList();

Future<void> _run(List<String> args) async {
  final String command = args[0];
  final File packFile = File(args[1]);
  if (!packFile.existsSync()) throw PrewarmFailed('no such pack file: ${args[1]}');
  final VerifiedPack pack = await verifyPack(
    packFile.readAsBytesSync(),
    publicKey: unhex(File(_publicKeyAsset).readAsStringSync()),
  );
  final List<String> characters = _list(_option(args, '--characters'), <String>[]);
  if (characters.isEmpty && command != 'carry') {
    throw const PrewarmFailed('say which characters with --characters a,b');
  }
  final PrewarmRequest request = PrewarmRequest(
    packId: pack.id,
    packVersion: pack.version,
    characters: characters,
    bands: _list(_option(args, '--bands'), <String>['A', 'B', 'C']),
    forms: _list(_option(args, '--forms'), <String>['f', 'm', 'n']),
  );

  String? url = _option(args, '--url');
  String? publishable;
  final File cfg = File('config/dev.local.json');
  if (cfg.existsSync()) {
    final Map<String, Object?> j = jsonDecode(cfg.readAsStringSync()) as Map<String, Object?>;
    url ??= j['SUPABASE_URL'] as String?;
    publishable = j['SUPABASE_PUBLISHABLE_KEY'] as String?;
  }
  final String secret = Platform.environment['NITZNUTZ_PUBLISH_SECRET'] ?? '';
  if (url == null || secret.length < 24) {
    throw const PrewarmFailed(
      'set NITZNUTZ_PUBLISH_SECRET (24 characters or more) and a project url (--url or config/dev.local.json)',
    );
  }
  final PrewarmSend send = httpSend(baseUrl: url, secret: secret, publishableKey: publishable);

  switch (command) {
    case 'carry':
      final String? from = _option(args, '--from');
      if (from == null) throw const PrewarmFailed('say which older version with --from 0.2.0');
      final int copied = await carry(send, request, fromVersion: from);
      stdout.writeln(
        'carried $copied reviewed lines from $from to ${request.packVersion}; nothing was spent',
      );
    case 'plan':
      stdout.writeln((await plan(send, request)).describe());
    case 'make':
      final PrewarmOutcome o = await make(
        send,
        request,
        confirmLines: int.tryParse(_option(args, '--confirm-lines') ?? ''),
        say: stdout.writeln,
      );
      stdout.writeln(
        'made ${o.made}, already there ${o.cached}, spent ${dollars(o.spentMicro)} USD'
        '${o.failed.isEmpty ? '' : ', could not make: ${o.failed}'}',
      );
    case 'measure':
      final Measurement m = await measure(
        send,
        request,
        count: int.tryParse(_option(args, '--count') ?? '') ?? 5,
      );
      stdout.writeln(m.describe());
    case 'evaluate':
      final LineEvaluation e = await evaluate(
        send,
        request,
        confirmLines: int.tryParse(_option(args, '--confirm-lines') ?? ''),
        say: stdout.writeln,
      );
      stdout.writeln(e.describe());
      final File report = File(_option(args, '--report') ?? '../out/tutor-eval.json');
      report.parent.createSync(recursive: true);
      report.writeAsStringSync(const JsonEncoder.withIndent('  ').convert(e.rows));
      stdout.writeln('every sentence is in ${report.path}');
    case 'voice':
      final String? file = _option(args, '--lines');
      if (file == null || !File(file).existsSync()) {
        throw const PrewarmFailed('say the approved lines with --lines <file>');
      }
      final VoiceOutcome v = await voiceLines(
        send,
        request,
        readApproved(File(file).readAsStringSync(), characters: characters),
        confirmLines: int.tryParse(_option(args, '--confirm-lines') ?? ''),
        say: stdout.writeln,
      );
      stdout.writeln(
        'voiced ${v.made} lines, spent ${dollars(v.spentMicro)} USD, ${v.failed.length} refused',
      );
      for (final String f in v.failed) {
        stdout.writeln('  refused: $f');
      }
    default:
      throw PrewarmFailed('unknown command: $command');
  }
}
