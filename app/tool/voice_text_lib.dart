// Which lines a character says, and the words sent for each.
//
// The words come from the voice_text column of docs/review/hebrew-master.csv: the editor's spoken form of a line (plain
// full spelling, points only on a word with two readings, no "!"). Never from the screen caption, which is fully
// pointed, keeps its "!" and may still hold a form the editor has corrected (docs/agents/voice-pronunciation-audit.md).
// A line is voiced only when the owner approved every row it comes from (`owner-approved`, `voice-ready` or `voiced`).
// Every text also passes the pre-flight check at the end of this file before it can be sent.
import 'dart:convert';
import 'dart:io';

/// One line to be said: its voice id (`vo:...`) and the text sent for it.
class SpokenLine {
  const SpokenLine(this.voId, this.text);

  final String voId;
  final String text;

  String get fileId => voId.substring('vo:'.length);
}

class VoiceGenFailed implements Exception {
  const VoiceGenFailed(this.message);

  final String message;

  @override
  String toString() => message;
}

// ---- the captions (what the screen shows) ----

/// The pack documents that ask for voice lines, in a fixed order.
List<File> _lineDocuments(Directory folder) {
  final List<File> files = <File>[
    for (final FileSystemEntity e in folder.listSync())
      if (e is File && e.path.endsWith('.json')) e,
  ];
  bool asksForLines(File f) {
    final String name = f.uri.pathSegments.last;
    return name.startsWith('activity.') || name.startsWith('lesson.');
  }

  return files.where(asksForLines).toList()
    ..sort((File a, File b) => a.uri.pathSegments.last.compareTo(b.uri.pathSegments.last));
}

/// Calls [found] for every node of [doc] that asks for a voice line, with the path of its caption text
/// (`prompt.caption.0.v`, the id the master table uses).
void _walkLines(Object? doc, void Function(String voId, String captionPath, String caption) found) {
  void walk(Object? node, String path) {
    final String prefix = path.isEmpty ? '' : '$path.';
    if (node is Map<String, Object?>) {
      final Object? vo = node['vo'];
      final Object? caption = node['caption'];
      if (vo is String && vo.startsWith('vo:') && caption is List<Object?> && caption.isNotEmpty) {
        final Object? first = caption.first;
        if (first is Map<String, Object?> && first['v'] is String) {
          found(vo, '${prefix}caption.0.v', first['v']! as String);
        }
      }
      for (final MapEntry<String, Object?> e in node.entries) {
        walk(e.value, '$prefix${e.key}');
      }
    } else if (node is List<Object?>) {
      for (int i = 0; i < node.length; i++) {
        walk(node[i], '$prefix$i');
      }
    }
  }

  walk(doc, '');
}

/// Every line (voice id and screen caption) that a content pack's documents ask for. The captions are what the old
/// clips were made from; they are used now only to compare with them in an audition.
List<SpokenLine> linesOfContent(Directory folder) {
  final Map<String, String> found = <String, String>{};
  for (final File f in _lineDocuments(folder)) {
    _walkLines(
      jsonDecode(f.readAsStringSync()),
      (String vo, String path, String caption) => found[vo] = caption,
    );
  }
  return <SpokenLine>[for (final MapEntry<String, String> l in found.entries) SpokenLine(l.key, l.value)];
}

/// The core lines (greetings, encouragement ...) of `content/lines/core.he.json`, with their screen text.
List<SpokenLine> coreLines(File file) {
  final Map<String, Object?> doc = jsonDecode(file.readAsStringSync()) as Map<String, Object?>;
  return <SpokenLine>[
    for (final Object? l in doc['lines']! as List<Object?>)
      SpokenLine('vo:${(l! as Map<String, Object?>)['id']}', (l as Map<String, Object?>)['text']! as String),
  ];
}

// ---- the master table ----

/// The statuses whose voice_text may be sent to a voice: the owner approved the text (docs/agents/README.md › statuses;
/// the same words as `OWNER_STATUSES` in tools/hebrew_voice_review.py). `voiced` stays voiceable, so that a line made
/// before is made again when its request changes. Anything else waits: `text-ready` (the editor finished, the owner has
/// not approved yet), `proposed`, `unchanged`, empty.
const Set<String> voiceableStatuses = <String>{'owner-approved', 'voice-ready', 'voiced'};

/// The status [readMaster] gives a key that appears twice with a different voice_text or status.
const String duplicateStatus = 'duplicate';

/// The `source` of the core lines in the master table.
const String coreSource = 'content/lines/core.he.json';

/// The columns of a master-table row that the voice generator reads.
class MasterRow {
  const MasterRow({required this.text, required this.uiText, required this.voiceText, required this.status});

  /// The text the table was made from, and the editor's corrected screen text.
  final String text;
  final String uiText;
  final String voiceText;
  final String status;
}

/// The key of a row: its `source` (a pack file name, or [coreSource]) and its `id` (the caption path, or the core id).
String masterKey(String source, String id) => '$source › $id';

/// The rows of the master table (CSV, as the editor's tools write it) by [masterKey]. A key that appears twice with a
/// different voice_text or status gets the status [duplicateStatus], so its line waits: which row is right is the
/// editor's call, not the order of the file.
Map<String, MasterRow> readMaster(String csv) {
  final List<List<String>> rows = parseCsv(csv);
  if (rows.isEmpty) throw const VoiceGenFailed('the master table is empty');
  final List<String> head = rows.first;
  int column(String name) {
    final int i = head.indexOf(name);
    if (i < 0) throw VoiceGenFailed('the master table has no "$name" column');
    return i;
  }

  final int source = column('source');
  final int id = column('id');
  final int text = column('text');
  final int ui = column('ui_text');
  final int voice = column('voice_text');
  final int status = column('status');
  final int width = head.length;
  final Map<String, MasterRow> out = <String, MasterRow>{};
  for (final List<String> r in rows.skip(1)) {
    if (r.length < width) continue;
    final String key = masterKey(r[source], r[id]);
    final MasterRow row = MasterRow(text: r[text], uiText: r[ui], voiceText: r[voice], status: r[status]);
    final MasterRow? before = out[key];
    out[key] = before == null || (before.voiceText == row.voiceText && before.status == row.status)
        ? row
        : MasterRow(text: row.text, uiText: row.uiText, voiceText: row.voiceText, status: duplicateStatus);
  }
  return out;
}

/// RFC 4180 CSV: fields in double quotes may hold commas, line breaks and doubled quotes. A leading byte-order mark is
/// skipped. A plain loop over the characters: the table has about 10,000 rows, read once per run.
List<List<String>> parseCsv(String text) {
  final List<List<String>> rows = <List<String>>[];
  List<String> row = <String>[];
  final StringBuffer field = StringBuffer();
  bool quoted = false;
  int i = text.isNotEmpty && text.codeUnitAt(0) == 0xFEFF ? 1 : 0;
  void endField() {
    row.add(field.toString());
    field.clear();
  }

  void endRow() {
    endField();
    rows.add(row);
    row = <String>[];
  }

  while (i < text.length) {
    final String c = text[i];
    if (quoted) {
      if (c == '"' && i + 1 < text.length && text[i + 1] == '"') {
        field.write('"');
        i++;
      } else if (c == '"') {
        quoted = false;
      } else {
        field.write(c);
      }
    } else if (c == '"') {
      quoted = true;
    } else if (c == ',') {
      endField();
    } else if (c == '\n' || c == '\r') {
      if (c == '\r' && i + 1 < text.length && text[i + 1] == '\n') i++;
      endRow();
    } else {
      field.write(c);
    }
    i++;
  }
  if (field.isNotEmpty || row.isNotEmpty) endRow();
  return rows;
}

/// A line as the generator voices it: the voice_text of its rows in the master table, and why it cannot be voiced yet
/// ([problem] is null when it can).
class VoicedLine {
  const VoicedLine({required this.voId, required this.text, required this.rows, this.problem});

  final String voId;

  /// The voice_text ('' when the table has none).
  final String text;

  /// Where the line comes from: `source › id (status)` for each place that asks for it.
  final List<String> rows;
  final String? problem;
}

/// Every line the content asks for, with the words to send.
class VoiceTexts {
  const VoiceTexts(this.lines);

  final List<VoicedLine> lines;

  /// The lines that may be voiced.
  List<SpokenLine> get ready => <SpokenLine>[
    for (final VoicedLine l in lines)
      if (l.problem == null) SpokenLine(l.voId, l.text),
  ];

  /// The lines that wait: no row, a row not approved, no voice_text, or a caption changed after the table was made.
  List<VoicedLine> get blocked => <VoicedLine>[
    for (final VoicedLine l in lines)
      if (l.problem != null) l,
  ];

  /// Every line that has a voice_text, approved or not: for the free test voices only, which send nothing anywhere.
  List<SpokenLine> get forTestVoices => <SpokenLine>[
    for (final VoicedLine l in lines)
      if (l.text.isNotEmpty) SpokenLine(l.voId, l.text),
  ];

  /// The voice_text of every line by its voice id, approved or not (for an audition that compares forms).
  Map<String, String> get textById => <String, String>{for (final VoicedLine l in lines) l.voId: l.text};

  String describeBlocked() {
    final StringBuffer b = StringBuffer()
      ..writeln(
        '${blocked.length} lines cannot be voiced yet. Their rows in docs/review/hebrew-master.csv must be '
        '${voiceableStatuses.join(' or ')} with a voice_text:',
      );
    for (final VoicedLine l in blocked) {
      b.writeln('  ${l.voId}: ${l.problem}');
    }
    return b.toString();
  }
}

final RegExp _voIdPattern = RegExp(r'^vo:[a-z0-9_.]{1,80}$');

/// The voice texts of every line that [content] (the starter pack folder) and [core] ask for, from [master].
VoiceTexts voiceTextsOf({
  required Directory content,
  required File core,
  required Map<String, MasterRow> master,
}) {
  // Every place that asks for each voice id, in a fixed order: the pack documents by name, then the core lines.
  final Map<String, List<(String, String, String)>> places = <String, List<(String, String, String)>>{};
  void add(String vo, String source, String id, String caption) =>
      places.putIfAbsent(vo, () => <(String, String, String)>[]).add((source, id, caption));
  for (final File f in _lineDocuments(content)) {
    final String name = f.uri.pathSegments.last;
    _walkLines(
      jsonDecode(f.readAsStringSync()),
      (String vo, String path, String caption) => add(vo, name, path, caption),
    );
  }
  for (final SpokenLine l in coreLines(core)) {
    add(l.voId, coreSource, l.fileId, l.text);
  }

  final List<VoicedLine> out = <VoicedLine>[];
  for (final MapEntry<String, List<(String, String, String)>> e in places.entries) {
    final List<String> where = <String>[];
    final Set<String> problems = <String>{};
    final Set<String> texts = <String>{};
    // The id becomes a file name (vo.<id>.mp3): checked here too, not only by the content validator.
    if (!_voIdPattern.hasMatch(e.key) || e.key.contains('..')) {
      problems.add('the voice id is not a plain name');
    }
    for (final (String source, String id, String caption) in e.value) {
      final String at = masterKey(source, id);
      final MasterRow? row = master[at];
      if (row == null) {
        where.add(at);
        problems.add('no row in the master table for $at');
        continue;
      }
      where.add('$at (${row.status.isEmpty ? 'no status' : row.status})');
      if (caption != row.text && caption != row.uiText) {
        problems.add('the caption of $at changed after the master table was made');
      }
      if (row.status == duplicateStatus) {
        problems.add('$at appears twice in the master table with a different voice_text or status');
      } else if (!voiceableStatuses.contains(row.status)) {
        problems.add(
          '$at is ${row.status.isEmpty ? 'without a status' : row.status} '
          '(voiced only once the owner approved it: ${voiceableStatuses.join(', ')})',
        );
      }
      if (row.voiceText.trim().isEmpty) {
        problems.add('$at has no voice_text');
      } else {
        texts.add(row.voiceText);
      }
    }
    if (texts.length > 1) problems.add('its rows have ${texts.length} different voice texts');
    out.add(
      VoicedLine(
        voId: e.key,
        text: texts.isEmpty ? '' : texts.first,
        rows: where,
        problem: problems.isEmpty ? null : problems.join('; '),
      ),
    );
  }
  return VoiceTexts(out);
}

// ---- the pre-flight check ----

/// What one audition clip may carry beyond plain Hebrew, to hear its effect. Pack lines allow none of these.
enum Allowance {
  /// `!` (the cheer against the full stop, L4x). Only the plain ASCII sign; its look-alikes never pass.
  exclamation('exclamation'),

  /// U+05C7 qamats qatan and U+05B3 hataf qamats (today's captions, for comparison).
  rarePoints('rare-points'),

  /// One IPA word between slashes, `/ʃaˈve/`: IPA letters and stress and length marks only.
  ipa('ipa'),

  /// v4 audio tags from a closed list ([audioTags]) in square brackets, `[gently]`.
  audioTags('audio-tags'),

  /// Line breaks, for a clip that says several lines in one request (L10).
  lineBreaks('line-breaks');

  const Allowance(this.key);

  final String key;

  static Allowance parse(String key) => Allowance.values.firstWhere(
    (Allowance a) => a.key == key,
    orElse: () => throw VoiceGenFailed(
      '"$key" is not an allowance; use ${Allowance.values.map((Allowance a) => a.key).join(', ')}',
    ),
  );
}

/// The audio tags an audition clip may use (with [Allowance.audioTags]); the voice director extends the list here.
const Set<String> audioTags = <String>{
  'gently',
  'warmly',
  'softly',
  'cheerfully',
  'excited',
  'curious',
  'calm',
  'whispers',
  'laughs',
};

/// One character that a text may not carry to the voice.
class TextProblem {
  const TextProblem(this.id, this.char, this.why);

  /// The line or clip id.
  final String id;
  final String char;
  final String why;

  @override
  String toString() {
    if (char.isEmpty) return '$id: $why';
    final int r = char.runes.first;
    final String code = 'U+${r.toRadixString(16).toUpperCase().padLeft(4, '0')}';
    // An invisible character is named by its code only; a Hebrew point is shown on a dotted circle.
    if (_invisible.hasMatch(char)) return '$id: $code $why';
    final String shown = r >= 0x0591 && r <= 0x05C7 ? '${String.fromCharCode(0x25CC)}$char' : char;
    return '$id: "$shown" ($code) $why';
  }
}

/// Every character a voice text may carry: the 27 Hebrew letters, the vowel points, dagesh and the shin and sin dots,
/// maqaf, geresh and gershayim, the space, and the punctuation the voice texts use. An allowlist, so that a look-alike
/// in any Unicode form (a fullwidth sign, a compatibility digit, a letter of another script, an invisible control) is
/// refused without having to be named.
final Set<int> _allowed = <int>{
  0x20, 0x22, 0x27, 0x2C, 0x2D, 0x2E, 0x3A, 0x3B, 0x3F, // space " ' , - . : ; ?
  0x2013, 0x2014, 0x2026, // en dash, em dash, ellipsis
  for (int r = 0x05D0; r <= 0x05EA; r++) r, // the letters
  for (int r = 0x05B0; r <= 0x05BC; r++)
    if (r != 0x05B3) r, // the points (not hataf qamats) and dagesh
  0x05C1, 0x05C2, // shin and sin dots
  0x05BE, 0x05F3, 0x05F4, // maqaf, geresh, gershayim
};

/// The letters of one IPA word (with [Allowance.ipa]): a to z, the IPA extensions, the few Latin-1 and Greek letters
/// IPA uses, and the stress and length marks. No digit, bracket, sign or click letter.
final Set<int> _ipaLetters = <int>{
  for (int r = 0x61; r <= 0x7A; r++) r,
  0xE6, 0xE7, 0xF0, 0xF8, 0x0127, 0x014B, 0x0153, // æ ç ð ø ħ ŋ œ
  for (int r = 0x0250; r <= 0x02AF; r++) r,
  0x02C8, 0x02CC, 0x02D0, 0x02D1, // ˈ ˌ ː ˑ
  0x03B2, 0x03B8, 0x03C7, // β θ χ
};

/// The exclamation mark in its other forms: fullwidth, double, small, heavy, inverted, the click letter, and others.
const Set<int> _exclamations = <int>{
  0x01C3,
  0x00A1,
  0x203C,
  0x2048,
  0x2049,
  0x2755,
  0x2757,
  0xFE15,
  0xFE57,
  0xFF01,
};

final RegExp _number = RegExp(r'\p{N}', unicode: true);
final RegExp _letter = RegExp(r'\p{L}', unicode: true);
final RegExp _invisible = RegExp(r'[\p{Cc}\p{Cf}\p{Z}]', unicode: true);
final RegExp _bracket = RegExp(r'[\p{Ps}\p{Pe}]', unicode: true);

bool _isHebrewLetter(int r) => r >= 0x05D0 && r <= 0x05EA;

/// Why [r] may not be sent, or null.
String? _refusal(int r, Set<Allowance> allow) {
  if (r == 0x21) {
    return allow.contains(Allowance.exclamation)
        ? null
        : 'an exclamation mark is never sent: it makes the voice shout';
  }
  if (r == 0x0A && allow.contains(Allowance.lineBreaks)) return null;
  if (r == 0x05C7 || r == 0x05B3) {
    if (allow.contains(Allowance.rarePoints)) return null;
    return r == 0x05C7
        ? 'qamats qatan is never sent (the voice may say "kal"): write the plain word'
        : 'hataf qamats is never sent: write the plain word';
  }
  if (_allowed.contains(r)) return null;
  final String c = String.fromCharCode(r);
  if (_exclamations.contains(r)) {
    return 'an exclamation mark is never sent, in any form: it makes the voice shout';
  }
  if (_number.hasMatch(c)) return 'a digit or number sign is never sent: a number is written as a word';
  if (r == 0x7B || r == 0x7D || r == 0xFF5B || r == 0xFF5D) {
    return 'a placeholder is never sent: a {child} line is voiced per child with the parent-reviewed first name, '
        'and its voice_text leaves the name out';
  }
  if (r == 0x3C || r == 0x3E || r == 0xFF1C || r == 0xFF1E) return 'markup is never sent: v4 reads no SSML';
  if (_letter.hasMatch(c)) {
    return 'a letter that is not Hebrew is never sent (Latin only as one IPA word /…/ in an audition clip that '
        'allows it)';
  }
  if (_invisible.hasMatch(c)) return 'an invisible or control character is never sent';
  if (_bracket.hasMatch(c)) {
    return 'a bracket is never sent (an audio tag only in an audition clip that allows it)';
  }
  return 'is not a character the voice texts use';
}

/// The runes of [text] that belong to an allowed audio tag or IPA word, which the character check skips.
List<bool> _allowedSpans(List<int> runes, Set<Allowance> allow) {
  final List<bool> covered = List<bool>.filled(runes.length, false);
  void spans(int open, int close, bool Function(List<int> inner) ok) {
    for (int i = 0; i < runes.length; i++) {
      if (runes[i] != open || covered[i]) continue;
      final int end = runes.indexOf(close, i + 1);
      if (end < 0) return;
      if (end - i - 1 >= 1 && end - i - 1 <= 40 && ok(runes.sublist(i + 1, end))) {
        covered.fillRange(i, end + 1, true);
        i = end;
      }
    }
  }

  if (allow.contains(Allowance.audioTags)) {
    spans(0x5B, 0x5D, (List<int> inner) => audioTags.contains(String.fromCharCodes(inner)));
  }
  if (allow.contains(Allowance.ipa)) {
    spans(0x2F, 0x2F, (List<int> inner) => inner.every(_ipaLetters.contains));
  }
  return covered;
}

/// The characters of [text] that may not go to the voice, one problem for each distinct character, and a problem when
/// nothing in it can be said. [id] names the line in the report. Packs allow nothing extra; an audition clip may allow
/// what it sets out to test, and even then digits, placeholders, markup and look-alike signs never pass.
List<TextProblem> preflight(String id, String text, {Set<Allowance> allow = const <Allowance>{}}) {
  if (text.trim().isEmpty) return <TextProblem>[TextProblem(id, '', 'the text is empty')];
  final List<int> runes = text.runes.toList();
  final List<bool> covered = _allowedSpans(runes, allow);
  final Map<int, String> found = <int, String>{};
  bool speakable = false;
  for (int i = 0; i < runes.length; i++) {
    if (covered[i]) continue;
    final int r = runes[i];
    if (_isHebrewLetter(r)) speakable = true;
    if (found.containsKey(r)) continue;
    final String? why = _refusal(r, allow);
    if (why != null) found[r] = why;
  }
  return <TextProblem>[
    for (final MapEntry<int, String> f in found.entries) TextProblem(id, String.fromCharCode(f.key), f.value),
    if (!speakable) TextProblem(id, '', 'there is nothing to say: the text has no Hebrew letter'),
  ];
}
