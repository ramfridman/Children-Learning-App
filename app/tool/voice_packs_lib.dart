// How the lines of one character are shared among its voice packs (B-45).
//
// A narrator says about 4,000 lines, two files each (the sound and its mouth cues): about 8,000 files and, at 44.1 kHz and
// 64 kbps, 100 to 240 MB. The app takes a pack whole into memory and refuses one over `ZipLimits` (64 MiB, 8,002 files), so
// the voice tool makes several packs, each well under both limits ([VoicePackLimits]).
//
// The share is a pure function of the voice ids, so the same lines always land in the same packs and nothing about it
// depends on which clips were made, or when:
//   1. [voiceGroupOf] gives every id a group: `core` (the shared lines every lesson uses: `core.*`, `fb.*`, `hint.*`,
//      `celebrate.*`, and any id this file does not know), `welcome` (the daily welcome, `welcome.*`), `skill` (the map card of a
//      skill, `core.skill.*`) or `<land>-<band>` (`num-b`: the number land, band B). A
//      land is the skill's domain (num, math, log, col, shp, cs) and a band is the letter in the skill id (`numb03` is band B).
//   2. [layoutVoicePacks] cuts a group of more than `maxLines` lines into parts, in the order of the ids, never inside a
//      unit (all the lines of one skill, or of one old lesson, stay together), so `num-b` becomes `num-b-1` and `num-b-2`.
// Why lands and bands: a child plays one band at a time, so a pack never mixes what only a younger or an older child
// needs, and a land is the natural unit when a band is too big. The group is only packaging: the app looks a line up in
// all the packs of a character, so a wrong guess about where an id belongs changes the size of a pack and nothing else.
import 'package:nitznutz/content/schemas.dart' show Patterns;
import 'package:nitznutz/voice/voice_pack_ids.dart';

import 'voice_text_lib.dart' show VoiceGenFailed;

/// What one voice pack may hold. The app's own limit (`ZipLimits`) is a guard against a pack that fills the memory; these
/// stay far under it, so a pack is small enough to download and to read whole.
abstract final class VoicePackLimits {
  /// The sum of a pack's file sizes (sound and cues), in bytes.
  static const int maxBytes = 40 * 1024 * 1024;

  /// Files in a pack, `manifest.json` and `manifest.sig` included.
  static const int maxEntries = 3000;

  /// The most lines the layout puts in one pack. At 60 KiB a clip this is 26 MiB, and a pack reaches the byte limit only
  /// when the clips average 93 KiB. The byte limit decides; this is the starting point.
  static const int maxLines = 450;

  /// The size of one clip that `plan` assumes (MP3, 44.1 kHz, 64 kbps, a line of about 40 characters) before any exists.
  static const int estimatedClipBytes = 60 * 1024;
}

/// Files a pack of [lines] lines holds: a sound and a cue file for each, and the manifest and its signature.
int voicePackEntries(int lines) => 2 * lines + 2;

const Set<String> _sharedPrefixes = <String>{'core', 'fb', 'hint', 'celebrate'};

/// B-45 job 4 (2026-11-02): two small groups of their own, so that `core` stays one pack with the plain id (it is 422 lines; 148 more
/// would cut it into core-1 and core-2) and a child who taps a map card, or opens the app for the day, does not pull a 25 MiB lesson
/// pack into memory for one short clip. `welcome.*` is the 48 daily-welcome lines (B-42); `core.skill.<skill id>` is the sentence of a
/// skill's map card (the `childLine`, 100 lines).
const String _welcomePrefix = 'welcome';
const String _mapCardSegment = 'skill';

/// The ids that carry a skill: `b.numb03.8.prompt`, `b15.numa13.1.h1`, `b36...`, `x.numb07...`.
const Set<String> _skillPrefixes = <String>{'b', 'b15', 'b36', 'x'};

final RegExp _skillToken = RegExp(r'^(num|math|log|col|shp|cs)([ab])\d{2}$');

/// The first lessons, whose ids start with the lesson (`col.find.1.prompt`) rather than with a skill: the land of each.
const Set<String> _oldLands = <String>{'col', 'log', 'math', 'shp', 'cs'};

/// The first number lessons (`count.apples.1.prompt`, `ordinal.first...`), all of the number land, band A.
const Set<String> _oldNumberLessons = <String>{
  'count',
  'give',
  'more',
  'fewer',
  'flash',
  'next',
  'ordinal',
  'nonzero',
  'zero',
  'numeral',
  'show',
  'same',
  'pick',
};

List<String> _segments(String voId) => (voId.startsWith('vo:') ? voId.substring(3) : voId).split('.');

/// The group of [voId] (with or without `vo:`): `core`, `welcome`, `skill`, or `<land>-<band>` such as `num-b` or `shp-a`. Any id this does not
/// recognise is in `core`.
String voiceGroupOf(String voId) {
  final List<String> s = _segments(voId);
  if (s.first == _welcomePrefix) return 'welcome';
  if (s.first == 'core' && s.length > 2 && s[1] == _mapCardSegment) return 'skill';
  if (_sharedPrefixes.contains(s.first)) return 'core';
  if (_skillPrefixes.contains(s.first) && s.length > 1) {
    final RegExpMatch? m = _skillToken.firstMatch(s[1]);
    if (m != null) return '${m.group(1)}-${m.group(2)}';
  }
  if (_oldLands.contains(s.first)) return '${s.first}-a';
  if (_oldNumberLessons.contains(s.first)) return 'num-a';
  return 'core';
}

/// The unit of [voId]: the lines that always stay in one pack. A skill (`numb03`), or else the first two parts of the id
/// (`col.find`, `celebrate.make_ten`).
String voiceUnitOf(String voId) {
  final List<String> s = _segments(voId);
  if (_skillPrefixes.contains(s.first) && s.length > 1 && _skillToken.hasMatch(s[1])) return s[1];
  return s.length > 1 ? '${s[0]}.${s[1]}' : s[0];
}

/// One voice pack to be built: its id, and the lines (`vo:` ids) it holds, in order.
class VoicePackGroup {
  const VoicePackGroup({required this.name, required this.packId, required this.voIds});

  /// `core`, `num-b`, `num-b-2` ...
  final String name;
  final String packId;
  final List<String> voIds;

  int get entries => voicePackEntries(voIds.length);
}

/// The packs of [characterId]'s voice for the lines [voIds] (with `vo:`), in a fixed order: `core` first, then by name.
///
/// [maxLines] is the most lines in a pack. With [onePack] (a friend, who says a handful of lines) everything is one pack,
/// whatever the ids. Throws [VoiceGenFailed] before anything is spent if a unit is too big to fit in a pack by the
/// file limit, or if a pack id would not be a valid pack id.
List<VoicePackGroup> layoutVoicePacks(
  String characterId,
  Iterable<String> voIds, {
  int maxLines = VoicePackLimits.maxLines,
  bool onePack = false,
}) {
  if (!hasPlainVoiceId(characterId)) {
    throw VoiceGenFailed(
      'the character id "$characterId" holds "-part-", which marks a part of a voice pack id',
    );
  }
  if (maxLines < 1) throw const VoiceGenFailed('a voice pack holds at least one line');
  final Set<String> ids = voIds.toSet();
  final Map<String, List<String>> byGroup = <String, List<String>>{};
  for (final String id in ids.toList()..sort()) {
    byGroup.putIfAbsent(onePack ? 'core' : voiceGroupOf(id), () => <String>[]).add(id);
  }
  final List<VoicePackGroup> out = <VoicePackGroup>[];
  for (final MapEntry<String, List<String>> g in byGroup.entries) {
    final List<List<String>> parts = onePack ? <List<String>>[g.value] : _parts(g.value, maxLines);
    for (int i = 0; i < parts.length; i++) {
      final String name = parts.length == 1 ? g.key : '${g.key}-${i + 1}';
      final VoicePackGroup pack = VoicePackGroup(
        name: name,
        packId: name == 'core' ? voicePackId(characterId) : voicePackId(characterId, name),
        voIds: parts[i],
      );
      if (!RegExp('^${Patterns.packId}\$').hasMatch(pack.packId) || pack.packId.length > 41) {
        throw VoiceGenFailed('"${pack.packId}" is not a pack id (3 to 41 letters, digits and hyphens)');
      }
      if (pack.entries > VoicePackLimits.maxEntries) {
        throw VoiceGenFailed(
          '${pack.packId} would hold ${pack.entries} files (at most ${VoicePackLimits.maxEntries}): '
          'a skill or lesson with ${pack.voIds.length} lines cannot be cut. Nothing was sent.',
        );
      }
      out.add(pack);
    }
  }
  int rank(VoicePackGroup p) => p.name == 'core' || p.name.startsWith('core-') ? 0 : 1;
  out.sort((VoicePackGroup a, VoicePackGroup b) {
    final int byRank = rank(a) - rank(b);
    return byRank != 0 ? byRank : a.name.compareTo(b.name);
  });
  return out;
}

/// [ids] (sorted, one group) cut into parts of at most [maxLines] lines, never inside a unit. A unit that is bigger than
/// [maxLines] is a part of its own.
List<List<String>> _parts(List<String> ids, int maxLines) {
  final Map<String, List<String>> units = <String, List<String>>{};
  for (final String id in ids) {
    units.putIfAbsent(voiceUnitOf(id), () => <String>[]).add(id);
  }
  final List<String> order = units.keys.toList()..sort();
  final List<List<String>> parts = <List<String>>[<String>[]];
  for (final String u in order) {
    final List<String> unit = units[u]!;
    if (parts.last.isNotEmpty && parts.last.length + unit.length > maxLines) parts.add(<String>[]);
    parts.last.addAll(unit);
  }
  return parts;
}

/// What `plan` prints for one character: each pack with its lines, the characters to say and the size at
/// [VoicePackLimits.estimatedClipBytes] a clip. [characters] is the length of each line's text by voice id.
String describeVoicePacks(
  String characterId,
  List<VoicePackGroup> packs,
  Map<String, int> characters, {
  String? version,
  required int maxLines,
}) {
  String mib(int bytes) => (bytes / (1024 * 1024)).toStringAsFixed(1);
  final int lines = packs.fold<int>(0, (int s, VoicePackGroup p) => s + p.voIds.length);
  final int chars = packs.fold<int>(
    0,
    (int s, VoicePackGroup p) => s + p.voIds.fold<int>(0, (int t, String id) => t + (characters[id] ?? 0)),
  );
  final StringBuffer b = StringBuffer()
    ..writeln(
      'Voice packs of $characterId${version == null ? '' : ', version $version'}: ${packs.length} pack${packs.length == 1 ? '' : 's'}, '
      '$lines lines, $chars characters (at most $maxLines lines, ${mib(VoicePackLimits.maxBytes)} MiB and '
      '${VoicePackLimits.maxEntries} files each; sizes are an estimate at '
      '${VoicePackLimits.estimatedClipBytes ~/ 1024} KiB a clip)',
    );
  for (final VoicePackGroup p in packs) {
    final int c = p.voIds.fold<int>(0, (int t, String id) => t + (characters[id] ?? 0));
    b.writeln(
      '  ${p.packId.padRight(30)} ${p.voIds.length.toString().padLeft(4)} lines '
      '${c.toString().padLeft(7)} characters  ~${mib(p.voIds.length * VoicePackLimits.estimatedClipBytes).padLeft(5)} MiB  '
      '${p.entries.toString().padLeft(4)} files',
    );
  }
  return b.toString();
}

/// Refuses the packs whose clips do not fit: [bytes] is the size of each pack's files by pack id. One message names every
/// pack that is too big and says how to make the packs again with fewer lines in each, which needs no new clip.
void checkVoicePackSizes(String characterId, List<VoicePackGroup> packs, Map<String, int> bytes) {
  final List<String> over = <String>[];
  int suggest = VoicePackLimits.maxLines;
  for (final VoicePackGroup p in packs) {
    final int size = bytes[p.packId] ?? 0;
    if (size <= VoicePackLimits.maxBytes && p.entries <= VoicePackLimits.maxEntries) continue;
    over.add(
      '${p.packId}: ${p.voIds.length} lines, ${(size / (1024 * 1024)).toStringAsFixed(1)} MiB in ${p.entries} files',
    );
    final int fits = (p.voIds.length * VoicePackLimits.maxBytes * 0.9 / (size == 0 ? 1 : size)).floor();
    if (fits < suggest) suggest = fits < 1 ? 1 : fits;
  }
  if (over.isEmpty) return;
  throw VoiceGenFailed(
    'a voice pack may hold at most ${VoicePackLimits.maxBytes ~/ (1024 * 1024)} MiB and ${VoicePackLimits.maxEntries} '
    'files, and these are over:\n  ${over.join('\n  ')}\n'
    'No pack was signed. The clips are all saved, and none needs to be paid for again: make the packs again with '
    'fewer lines in each, for example `dart run tool/voice_gen.dart pack $characterId --max-lines $suggest` (free).',
  );
}
