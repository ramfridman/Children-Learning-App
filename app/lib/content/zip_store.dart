import 'dart:typed_data';

// A deliberately narrow zip, written and read by us so no unpacking library is needed.
//
// What is allowed: stored files only (no compression, no encryption, no zip64, no data descriptors,
// no extra fields, no comments, no directory entries), flat plain names, entries sorted by name, one
// fixed timestamp. That is exactly what `writeStoredZip` produces.
//
// What the reader guarantees: after it has parsed a file it writes the same entries again and
// compares the result with the input byte for byte. Because the format is canonical, a zip that
// differs in even one byte from what the writer would produce is refused, so no byte of the
// container can be changed without being noticed (the contents are covered by the CRC here and by
// the signature and hashes in `pack_verify.dart`). It never trusts a length it has not checked.
//
// This file is pure Dart so the pack builder (a command-line tool) and the app share it.

class ZipEntry {
  const ZipEntry(this.name, this.data);

  final String name;
  final Uint8List data;
}

class ZipException implements Exception {
  const ZipException(this.reason);

  final String reason;

  @override
  String toString() => 'ZipException: $reason';
}

abstract final class ZipLimits {
  /// 8,000 files of content plus `manifest.json` and `manifest.sig` (a pack of lessons or of one friend's voice: a line is
  /// two files, its sound and its mouth cues).
  static const int maxEntries = 8002;

  /// The sum of all file sizes.
  static const int maxTotalBytes = 64 * 1024 * 1024;

  static const int maxNameLength = 101;

  /// The largest zip file the reader looks at: the contents plus room for the headers.
  static const int maxZipBytes = maxTotalBytes + 256 * 1024;
}

const int _localSig = 0x04034b50;
const int _centralSig = 0x02014b50;
const int _endSig = 0x06054b50;
const int _localHeader = 30;
const int _centralHeader = 46;
const int _endRecord = 22;

/// Version 2.0 (stored files), the fixed DOS time 00:00:00 and the fixed DOS date 1980-01-01.
const int _version = 20;
const int _dosTime = 0;
const int _dosDate = 0x0021;

const Set<String> _deviceNames = <String>{
  'con',
  'prn',
  'aux',
  'nul',
  'com1',
  'com2',
  'com3',
  'com4',
  'com5',
  'com6',
  'com7',
  'com8',
  'com9',
  'lpt1',
  'lpt2',
  'lpt3',
  'lpt4',
  'lpt5',
  'lpt6',
  'lpt7',
  'lpt8',
  'lpt9',
};

/// True if [name] matches `^[A-Za-z0-9][A-Za-z0-9._-]{0,100}$` (`Patterns.fileName`): 1 to 101 ASCII
/// letters, digits, dots, underscores and hyphens, the first a letter or a digit. A loop rather than the
/// pattern because the reader runs it for every entry of every pack it reads, and the pattern alone took
/// three times as long as all of [unsafeNameReason] does now (zip_store_test.dart checks the two agree).
bool _isPlainName(String name) {
  if (name.isEmpty || name.length > ZipLimits.maxNameLength) return false;
  for (int i = 0; i < name.length; i++) {
    final int c = name.codeUnitAt(i);
    final bool letterOrDigit =
        (c >= 0x30 && c <= 0x39) || (c >= 0x41 && c <= 0x5A) || (c >= 0x61 && c <= 0x7A);
    if (letterOrDigit) continue;
    if (i == 0 || (c != 0x2E && c != 0x5F && c != 0x2D)) return false;
  }
  return true;
}

/// Null if [name] is a safe flat file name, otherwise why not. The same rule runs when writing and
/// reading, and the manifest's file names use the same pattern.
String? unsafeNameReason(String name) {
  if (!_isPlainName(name)) return 'the name "$name" is not a plain file name';
  if (name.contains('..')) return 'the name "$name" contains ".."';
  if (name.endsWith('.')) return 'the name "$name" ends with a dot';
  final int dot = name.indexOf('.');
  if (_deviceNames.contains((dot < 0 ? name : name.substring(0, dot)).toLowerCase())) {
    return 'the name "$name" is reserved on Windows';
  }
  return null;
}

// ---- CRC-32 (the zip one) ----

// Slice-by-8: eight tables of 256 entries. Table 0 is the usual bytewise table; table k gives the CRC
// change of a byte followed by k zero bytes, so eight bytes are folded in with eight independent
// lookups instead of eight dependent steps. The result is exactly the bytewise one (zip_store_test.dart
// checks both against each other); it is about 3.6 times faster, and every pack check runs it over every file.
final Uint32List _crcTables = () {
  final Uint32List t = Uint32List(8 * 256);
  for (int n = 0; n < 256; n++) {
    int c = n;
    for (int k = 0; k < 8; k++) {
      c = (c & 1) != 0 ? 0xEDB88320 ^ (c >> 1) : c >> 1;
    }
    t[n] = c;
  }
  for (int i = 256; i < t.length; i++) {
    final int previous = t[i - 256];
    t[i] = (previous >> 8) ^ t[previous & 0xFF];
  }
  return t;
}();

int crc32(Uint8List data) {
  final Uint32List t = _crcTables;
  final ByteData v = ByteData.sublistView(data);
  final int n = data.length;
  final int whole = n - n % 8;
  int c = 0xFFFFFFFF;
  int i = 0;
  for (; i < whole; i += 8) {
    final int low = c ^ v.getUint32(i, Endian.little);
    final int high = v.getUint32(i + 4, Endian.little);
    c =
        t[0x700 + (low & 0xFF)] ^
        t[0x600 + ((low >> 8) & 0xFF)] ^
        t[0x500 + ((low >> 16) & 0xFF)] ^
        t[0x400 + (low >> 24)] ^
        t[0x300 + (high & 0xFF)] ^
        t[0x200 + ((high >> 8) & 0xFF)] ^
        t[0x100 + ((high >> 16) & 0xFF)] ^
        t[high >> 24];
  }
  for (; i < n; i++) {
    c = t[(c ^ data[i]) & 0xFF] ^ (c >> 8);
  }
  return c ^ 0xFFFFFFFF;
}

// ---- writing ----

int _compareNames(String a, String b) {
  final int n = a.length < b.length ? a.length : b.length;
  for (int i = 0; i < n; i++) {
    final int d = a.codeUnitAt(i) - b.codeUnitAt(i);
    if (d != 0) return d;
  }
  return a.length - b.length;
}

/// The canonical zip of [entries]: sorted by name, stored, fixed times. The same entries always give
/// the same bytes. Throws [ArgumentError] for a name that is not safe or used twice.
Uint8List writeStoredZip(List<ZipEntry> entries) {
  final List<ZipEntry> sorted = List<ZipEntry>.of(entries)
    ..sort((ZipEntry a, ZipEntry b) => _compareNames(a.name, b.name));
  final Set<String> seen = <String>{};
  for (final ZipEntry e in sorted) {
    final String? why = unsafeNameReason(e.name);
    if (why != null) throw ArgumentError(why);
    if (!seen.add(e.name.toLowerCase())) throw ArgumentError('the name "${e.name}" is used twice');
  }
  return _layOut(<_Stored>[for (final ZipEntry e in sorted) (entry: e, crc: crc32(e.data))]);
}

/// An entry with the CRC-32 of its data.
typedef _Stored = ({ZipEntry entry, int crc});

/// The bytes of the zip of [sorted]: entries already sorted by name with safe, distinct names, each with
/// the CRC-32 of its data.
Uint8List _layOut(List<_Stored> sorted) {
  int total = _endRecord;
  for (final _Stored s in sorted) {
    total += _localHeader + _centralHeader + 2 * s.entry.name.length + s.entry.data.length;
  }
  final Uint8List out = Uint8List(total);
  final ByteData v = ByteData.sublistView(out);
  int pos = 0;
  final List<int> offsets = <int>[];
  for (final (entry: ZipEntry e, :int crc) in sorted) {
    offsets.add(pos);
    v.setUint32(pos, _localSig, Endian.little);
    v.setUint16(pos + 4, _version, Endian.little);
    v.setUint16(pos + 6, 0, Endian.little); // flags
    v.setUint16(pos + 8, 0, Endian.little); // method: stored
    v.setUint16(pos + 10, _dosTime, Endian.little);
    v.setUint16(pos + 12, _dosDate, Endian.little);
    v.setUint32(pos + 14, crc, Endian.little);
    v.setUint32(pos + 18, e.data.length, Endian.little);
    v.setUint32(pos + 22, e.data.length, Endian.little);
    v.setUint16(pos + 26, e.name.length, Endian.little);
    v.setUint16(pos + 28, 0, Endian.little); // extra field length
    out.setRange(pos + _localHeader, pos + _localHeader + e.name.length, e.name.codeUnits);
    pos += _localHeader + e.name.length;
    out.setRange(pos, pos + e.data.length, e.data);
    pos += e.data.length;
  }
  final int directoryStart = pos;
  for (final (int i, (entry: ZipEntry e, :int crc)) in sorted.indexed) {
    v.setUint32(pos, _centralSig, Endian.little);
    v.setUint16(pos + 4, _version, Endian.little); // made by
    v.setUint16(pos + 6, _version, Endian.little); // needed to extract
    v.setUint16(pos + 8, 0, Endian.little);
    v.setUint16(pos + 10, 0, Endian.little);
    v.setUint16(pos + 12, _dosTime, Endian.little);
    v.setUint16(pos + 14, _dosDate, Endian.little);
    v.setUint32(pos + 16, crc, Endian.little);
    v.setUint32(pos + 20, e.data.length, Endian.little);
    v.setUint32(pos + 24, e.data.length, Endian.little);
    v.setUint16(pos + 28, e.name.length, Endian.little);
    // extra length, comment length, disk number, internal and external attributes: all zero.
    v.setUint32(pos + 42, offsets[i], Endian.little);
    out.setRange(pos + _centralHeader, pos + _centralHeader + e.name.length, e.name.codeUnits);
    pos += _centralHeader + e.name.length;
  }
  v.setUint32(pos, _endSig, Endian.little);
  v.setUint16(pos + 8, sorted.length, Endian.little);
  v.setUint16(pos + 10, sorted.length, Endian.little);
  v.setUint32(pos + 12, pos - directoryStart, Endian.little);
  v.setUint32(pos + 16, directoryStart, Endian.little);
  return out;
}

// ---- reading ----

/// Reads a zip made by [writeStoredZip] and nothing else. Throws [ZipException] with the reason.
List<ZipEntry> readStoredZip(Uint8List bytes) {
  if (bytes.length > ZipLimits.maxZipBytes) throw const ZipException('the file is too large');
  if (bytes.length < _endRecord) throw const ZipException('the file is too short to be a pack');
  final ByteData v = ByteData.sublistView(bytes);
  int u16(int at) => v.getUint16(at, Endian.little);
  int u32(int at) => v.getUint32(at, Endian.little);

  final int end = bytes.length - _endRecord;
  if (u32(end) != _endSig) throw const ZipException('the end of the zip is not where it should be');
  if (u16(end + 4) != 0 || u16(end + 6) != 0) throw const ZipException('multi-disk zips are not allowed');
  final int count = u16(end + 8);
  if (u16(end + 10) != count) throw const ZipException('the entry counts disagree');
  if (u16(end + 20) != 0) throw const ZipException('a zip comment is not allowed');
  if (count < 1 || count > ZipLimits.maxEntries) throw ZipException('$count entries is not allowed');
  final int directorySize = u32(end + 12);
  final int directoryStart = u32(end + 16);
  if (directoryStart + directorySize != end) {
    throw const ZipException('the directory is not where it should be');
  }

  final List<_Stored> checked = <_Stored>[];
  final Set<String> seen = <String>{};
  int at = directoryStart;
  int expectedOffset = 0;
  int total = 0;
  for (int i = 0; i < count; i++) {
    if (at + _centralHeader > end) throw const ZipException('the directory ends too early');
    if (u32(at) != _centralSig) throw const ZipException('a directory entry is damaged');
    final int nameLength = u16(at + 28);
    if (nameLength < 1 || nameLength > ZipLimits.maxNameLength) {
      throw const ZipException('a file name has a bad length');
    }
    if (u16(at + 30) != 0 || u16(at + 32) != 0) {
      throw const ZipException('extra fields and comments are not allowed');
    }
    if (u16(at + 8) != 0) {
      throw const ZipException('zip flags (encryption, data descriptors) are not allowed');
    }
    if (u16(at + 10) != 0) throw const ZipException('only stored files are allowed');
    final int size = u32(at + 24);
    if (u32(at + 20) != size) throw const ZipException('a file is compressed');
    if (size > ZipLimits.maxTotalBytes) throw const ZipException('a file is too large');
    total += size;
    if (total > ZipLimits.maxTotalBytes) throw const ZipException('the files are too large together');
    if (u32(at + 42) != expectedOffset) throw const ZipException('the files are not stored in order');
    if (at + _centralHeader + nameLength > end) throw const ZipException('the directory ends too early');
    final String name = _asciiName(bytes, at + _centralHeader, nameLength);
    final String? why = unsafeNameReason(name);
    if (why != null) throw ZipException(why);
    if (!seen.add(name.toLowerCase())) throw ZipException('the name "$name" is used twice');

    final int crc = u32(at + 16);
    final int local = expectedOffset;
    if (local + _localHeader + nameLength + size > directoryStart) {
      throw const ZipException('a file runs past the end');
    }
    if (u32(local) != _localSig) throw const ZipException('a file header is damaged');
    if (u16(local + 26) != nameLength || u16(local + 28) != 0) {
      throw const ZipException('a file header disagrees with the directory');
    }
    if (u32(local + 14) != crc || u32(local + 18) != size || u32(local + 22) != size) {
      throw const ZipException('a file header disagrees with the directory');
    }
    final int dataStart = local + _localHeader + nameLength;
    final Uint8List data = Uint8List.sublistView(bytes, dataStart, dataStart + size);
    if (crc32(data) != crc) throw ZipException('the file "$name" is damaged (checksum)');
    checked.add((entry: ZipEntry(name, data), crc: crc));

    expectedOffset = dataStart + size;
    at += _centralHeader + nameLength;
  }
  if (expectedOffset != directoryStart) {
    throw const ZipException('there are bytes between the files and the directory');
  }
  if (at != end) throw const ZipException('there are bytes after the directory');

  // Everything above is checked field by field; this is the net under it: the zip must be exactly the
  // one the writer would make, so a change to any byte (timestamps, version fields, attributes ...) fails.
  // These are the bytes `writeStoredZip` gives for the same entries: the names passed the same rules
  // above, and each CRC is the one just computed from the data, so it is not computed twice more.
  final Uint8List again = _layOut(
    List<_Stored>.of(checked)..sort((_Stored a, _Stored b) => _compareNames(a.entry.name, b.entry.name)),
  );
  if (!_sameBytes(again, bytes)) throw const ZipException('the zip is not in canonical form');
  return <ZipEntry>[for (final _Stored s in checked) s.entry];
}

/// True if [a] and [b] hold the same bytes; compared four at a time (1.7 ms instead of 3 ms for a 3.5 MB
/// pack, and every pack read compares the whole file).
bool _sameBytes(Uint8List a, Uint8List b) {
  if (a.length != b.length) return false;
  final ByteData x = ByteData.sublistView(a);
  final ByteData y = ByteData.sublistView(b);
  final int whole = a.length - a.length % 4;
  for (int i = 0; i < whole; i += 4) {
    if (x.getUint32(i, Endian.little) != y.getUint32(i, Endian.little)) return false;
  }
  for (int i = whole; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}

String _asciiName(Uint8List bytes, int start, int length) {
  for (int i = start; i < start + length; i++) {
    if (bytes[i] < 0x21 || bytes[i] > 0x7E) {
      throw const ZipException('a file name has characters that are not allowed');
    }
  }
  return String.fromCharCodes(bytes, start, start + length);
}
