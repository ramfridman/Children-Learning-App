// Voicing in batches. The whole release is more characters than the owner's plan allows in a month, so a run voices whole
// groups of lines and leaves the rest for after the allowance renews. The groups are the voice director's
// (`docs/audio/voicing-groups.json`, made by `tools/voicing_groups.py`: core, celebrate, then each land and band, in the
// order of the first tests), and the shell's lines as a last group of ours. Nothing here sends anything: it reads the
// manifest, chooses groups, prints what is left, and checks the clips that were made.
import 'dart:convert';
import 'dart:io';

import 'package:nitznutz/voice/voice_bank.dart' show lastVoicePart;

import 'voice_gen_lib.dart';

/// The voice director's groups: their names in the order of a run, and the group of each voice id.
class GroupManifest {
  const GroupManifest(this.names, this.groupOf);

  /// Reads the manifest file (schema `voicing-groups/v1`); a name used twice, or an id in two groups, is refused.
  factory GroupManifest.read(File file) {
    final Object? doc = file.existsSync() ? jsonDecode(file.readAsStringSync()) : null;
    if (doc is! Map<String, Object?> ||
        doc['schema'] != 'voicing-groups/v1' ||
        doc['groups'] is! List<Object?>) {
      throw VoiceGenFailed(
        '${file.path} is missing or is not a voicing-groups/v1 file (python tools/voicing_groups.py writes it)',
      );
    }
    final List<String> names = <String>[];
    final Map<String, String> groupOf = <String, String>{};
    for (final Object? g in doc['groups']! as List<Object?>) {
      final Map<String, Object?> group = g! as Map<String, Object?>;
      final String name = group['name']! as String;
      if (names.contains(name)) throw VoiceGenFailed('the group "$name" is listed twice in the manifest');
      names.add(name);
      for (final Object? id in group['ids']! as List<Object?>) {
        final String? other = groupOf[id! as String];
        if (other != null) throw VoiceGenFailed('$id is in the groups $other and $name of the manifest');
        groupOf[id as String] = name;
      }
    }
    return GroupManifest(names, groupOf);
  }

  final List<String> names;
  final Map<String, String> groupOf;

  /// Every group of a run in order: the manifest's, then the shell's lines.
  List<String> get order => <String>[...names, uiGroup];

  /// The names in [wanted] (comma separated) checked against the manifest, in run order.
  List<String> pick(String wanted) {
    final List<String> asked = wanted
        .split(',')
        .map((String s) => s.trim())
        .where((String s) => s.isNotEmpty)
        .toList();
    final List<String> unknown = <String>[
      for (final String g in asked)
        if (!order.contains(g)) g,
    ];
    if (asked.isEmpty || unknown.isNotEmpty) {
      throw VoiceGenFailed(
        '${unknown.isEmpty ? 'no group named' : 'not a group: ${unknown.join(', ')}'}; the groups are ${order.join(', ')}',
      );
    }
    return <String>[
      for (final String g in order)
        if (asked.contains(g)) g,
    ];
  }
}

/// The groups of one run and the groups left for the next.
class BatchChoice {
  const BatchChoice({
    required this.chosen,
    required this.left,
    required this.waiting,
    required this.total,
    required this.leftCharacters,
  });

  /// The groups to voice now, in run order. A group that costs nothing (all made) is among them.
  final List<String> chosen;

  /// The groups that are approved but come after the point where the budget stopped the run, in run order.
  final List<String> left;

  /// The groups that have a line the owner has not approved yet: they wait for him, not for the allowance.
  final List<String> waiting;

  /// The characters the run sends.
  final int total;

  /// What each group of [left] would cost on top of the run.
  final Map<String, int> leftCharacters;

  /// The characters still to be voiced after this run, over the groups of [left].
  int get leftTotal => leftCharacters.values.fold<int>(0, (int s, int c) => s + c);

  /// What the owner reads before the plan: the groups of this run, and what is left for next time.
  String describe({int? maxCharacters}) {
    final StringBuffer b = StringBuffer()
      ..writeln(
        'Groups in this run (${chosen.length}): ${chosen.isEmpty ? 'none' : chosen.join(', ')}; '
        '$total characters${maxCharacters == null ? '' : ' (limit $maxCharacters)'}',
      );
    if (left.isNotEmpty) {
      b.writeln(
        'Left for next time (${left.length} groups, $leftTotal characters; whole groups, none is split): '
        '${left.map((String g) => '$g ${leftCharacters[g]}').join(', ')}',
      );
      if (maxCharacters != null) {
        final List<String> tooBig = <String>[
          for (final String g in left)
            if (leftCharacters[g]! > maxCharacters) g,
        ];
        if (tooBig.isNotEmpty) {
          b.writeln('Larger than the limit on its own, so it needs a higher budget: ${tooBig.join(', ')}');
        }
      }
    }
    if (waiting.isNotEmpty) {
      b.writeln('Waiting for the owner to approve their rows (not counted above): ${waiting.join(', ')}');
    }
    return b.toString();
  }
}

/// Which part of a character's voice pack each group is in (`docs/audio/voicing-parts.json`). One pack may hold at most
/// [ZipLimits] bytes, and a narrator's whole voice is about 92 MiB, so the voice is several packs: `voice-<id>` for part 1,
/// `voice-<id>-N` for the others. The assignment is written down, whole groups in the order of the manifest, so that a rebuild
/// never moves a group because a clip changed its size.
class VoiceParts {
  const VoiceParts(this.groupsOfPart);

  /// Reads the file (schema `voicing-parts/v1`) and checks it against [manifest]: parts numbered 1, 2, 3 ... (at most
  /// [lastVoicePart]), every group of the manifest and the shell lines in exactly one part, no group that does not exist.
  factory VoiceParts.read(File file, GroupManifest manifest) {
    final Object? doc = file.existsSync() ? jsonDecode(file.readAsStringSync()) : null;
    if (doc is! Map<String, Object?> ||
        doc['schema'] != 'voicing-parts/v1' ||
        doc['parts'] is! List<Object?>) {
      throw VoiceGenFailed('${file.path} is missing or is not a voicing-parts/v1 file');
    }
    final List<Object?> parts = doc['parts']! as List<Object?>;
    if (parts.isEmpty || parts.length > lastVoicePart) {
      throw VoiceGenFailed('the voice is 1 to $lastVoicePart parts, not ${parts.length}');
    }
    final List<List<String>> groupsOfPart = <List<String>>[];
    final Set<String> seen = <String>{};
    for (final (int i, Object? p) in parts.indexed) {
      final Map<String, Object?> part = p! as Map<String, Object?>;
      if (part['part'] != i + 1) {
        throw VoiceGenFailed('the parts are numbered 1, 2, 3 ... in order; found ${part['part']}');
      }
      final List<String> groups = <String>[
        for (final Object? g in part['groups']! as List<Object?>) g! as String,
      ];
      for (final String g in groups) {
        if (!manifest.order.contains(g)) {
          throw VoiceGenFailed('part ${i + 1} names "$g", which is not a group');
        }
        if (!seen.add(g)) throw VoiceGenFailed('the group "$g" is in two parts');
      }
      groupsOfPart.add(groups);
    }
    final List<String> loose = <String>[
      for (final String g in manifest.order)
        if (!seen.contains(g)) g,
    ];
    if (loose.isNotEmpty) throw VoiceGenFailed('the groups ${loose.join(', ')} are in no part');
    return VoiceParts(groupsOfPart);
  }

  /// The groups of part 1, part 2 ...
  final List<List<String>> groupsOfPart;

  int get length => groupsOfPart.length;

  /// The part (1 to n) of [group].
  int partOfGroup(String group) => groupsOfPart.indexWhere((List<String> g) => g.contains(group)) + 1;

  /// The part of each voice id in [lines] that has a group (a line with none is left out of the map; a run that needs it
  /// stops before anything is sent).
  Map<String, int> partOfLines(Iterable<VoicedLine> lines) => <String, int>{
    for (final VoicedLine l in lines)
      if (l.group.isNotEmpty) l.voId: partOfGroup(l.group),
  };
}

/// Chooses whole groups for a run. [candidates] are the groups wanted, in run order; [waiting] those of them that have an
/// unapproved line (they cannot be voiced yet and are passed over). [costOf] gives the characters a run sends when it
/// voices exactly the groups it is given (the sounds that groups share are counted once, so the costs of groups do not
/// simply add up).
///
/// Taking the groups in order, a group goes into the run while the run with it still costs at most [maxCharacters] (no
/// limit when null). The run stops before the first group that would not fit, and every group after it is left, so the
/// groups already voiced are always an unbroken start of the order. A group never goes in in part.
BatchChoice chooseBatch({
  required List<String> candidates,
  required Set<String> waiting,
  required int Function(Set<String> groups) costOf,
  int? maxCharacters,
}) {
  final List<String> eligible = <String>[
    for (final String g in candidates)
      if (!waiting.contains(g)) g,
  ];
  final Set<String> chosen = <String>{};
  for (final String g in eligible) {
    if (maxCharacters != null && costOf(<String>{...chosen, g}) > maxCharacters) break;
    chosen.add(g);
  }
  final int total = costOf(chosen);
  final List<String> left = <String>[
    for (final String g in eligible)
      if (!chosen.contains(g)) g,
  ];
  return BatchChoice(
    chosen: <String>[
      for (final String g in eligible)
        if (chosen.contains(g)) g,
    ],
    left: left,
    waiting: <String>[
      for (final String g in candidates)
        if (waiting.contains(g)) g,
    ],
    total: total,
    leftCharacters: <String, int>{
      for (final String g in left) g: costOf(<String>{...chosen, g}) - total,
    },
  );
}

// ---- verify ----

/// Why a clip is not as it should be.
enum ClipFault {
  /// No sound or no mouth cues in the work folder.
  missing('missing'),

  /// The sound is smaller than any real clip (an error answer, a cut-off download).
  empty('too small for a voice clip'),

  /// The sound was made from another text, voice, model, settings or format than the line has now.
  changed('made from another text or setting');

  const ClipFault(this.why);

  final String why;
}

/// The result of checking the clips of some lines against the work folder.
class VerifyReport {
  const VerifyReport({required this.faults, required this.checked, required this.notApproved});

  /// The faulty lines by voice id, in the order of the lines.
  final Map<String, ClipFault> faults;

  /// The group of every line checked, by voice id.
  final Map<String, String> checked;

  /// Lines left out because the owner has not approved their rows (their clips cannot be right yet).
  final List<String> notApproved;

  bool get ok => faults.isEmpty;

  String describe() {
    final Map<String, List<String>> byGroup = <String, List<String>>{};
    for (final MapEntry<String, String> e in checked.entries) {
      (byGroup[e.value] ??= <String>[]).add(e.key);
    }
    final StringBuffer b = StringBuffer();
    for (final MapEntry<String, List<String>> g in byGroup.entries) {
      final List<String> bad = <String>[
        for (final String id in g.value)
          if (faults.containsKey(id)) id,
      ];
      b.writeln(
        '  ${g.key}: ${g.value.length - bad.length} of ${g.value.length} clips are as the text says'
        '${bad.isEmpty ? '' : '; ${bad.length} are not'}',
      );
    }
    for (final MapEntry<String, ClipFault> f in faults.entries.take(40)) {
      b.writeln('    ${f.key}: ${f.value.why}');
    }
    if (faults.length > 40) b.writeln('    ... and ${faults.length - 40} more');
    if (notApproved.isNotEmpty) {
      b.writeln('  ${notApproved.length} lines are not approved yet and were not checked');
    }
    b.writeln(
      ok
          ? 'All ${checked.length} clips are there and match their text.'
          : '${faults.length} clips need attention.',
    );
    return b.toString();
  }
}

/// The bytes of the distinct sounds of [lines] in [workDir], as the app counts them against `maxVoiceBytes`: lines with
/// the same request in the same part share one sound (one file in the pack); a line whose twin is in another part has its
/// own. [partOfLine] gives the part of each voice id (all in part 1 when null). A line with no clip counts nothing.
int distinctClipBytes({
  required Directory workDir,
  required VoiceProfile profile,
  required List<SpokenLine> lines,
  Map<String, int>? partOfLine,
}) {
  final Set<String> seen = <String>{};
  int bytes = 0;
  for (final SpokenLine line in lines) {
    final String key = '${partOfLine?[line.voId] ?? 1}|${profile.requestFor(line).hash}';
    if (!seen.add(key)) continue;
    final File? file = _audioFile(workDir, line.fileId);
    if (file != null) bytes += file.lengthSync();
  }
  return bytes;
}

File? _audioFile(Directory workDir, String id) {
  for (final String ext in <String>['mp3', 'wav']) {
    final File f = File('${workDir.path}${Platform.pathSeparator}vo.$id.$ext');
    if (f.existsSync()) return f;
  }
  return null;
}

/// A voice clip smaller than this is not a clip (the shortest real line is far longer than 2 KB at 64 kbps).
const int minClipBytes = 2048;

/// Checks that the clip of each of [lines] (voice id, group and text) is in [workDir], is not empty, and was made from the
/// request [profile] gives for its text now (the hash in the ledger), and is at least [minBytes]. [unapproved] are the
/// voice ids that are left out.
VerifyReport verifyClips({
  required Directory workDir,
  required VoiceProfile profile,
  required List<(SpokenLine, String)> lines,
  List<String> unapproved = const <String>[],
  int minBytes = minClipBytes,
}) {
  final Map<String, String> made = ClipLedger(workDir).hashes();
  final Map<String, ClipFault> faults = <String, ClipFault>{};
  final Map<String, String> checked = <String, String>{};
  for (final (SpokenLine line, String group) in lines) {
    checked[line.voId] = group;
    final ClipState state = clipState(workDir, line.fileId, profile.requestFor(line), made);
    if (state == ClipState.newLine) {
      faults[line.voId] = ClipFault.missing;
    } else if (audioBytesOf(workDir, line.fileId).length < minBytes) {
      faults[line.voId] = ClipFault.empty;
    } else if (state == ClipState.changed) {
      faults[line.voId] = ClipFault.changed;
    }
  }
  return VerifyReport(faults: faults, checked: checked, notApproved: unapproved);
}
