import 'dart:typed_data';

import 'package:nitznutz/content/zip_store.dart' show ZipEntry, ZipException, ZipLimits;

// The zip reader, writer, CRC-32 and name rule exactly as they were before they were made faster (board
// item B-12, commit e6971fb), kept only as the oracle the tests compare the production code with: the
// same input must give the same bytes, the same entries or the same refusal reason. Do not change this
// file to make a test pass; it is the definition of "behaves as before".

const int _localSig = 0x04034b50;
const int _centralSig = 0x02014b50;
const int _endSig = 0x06054b50;
const int _localHeader = 30;
const int _centralHeader = 46;
const int _endRecord = 22;
const int _version = 20;
const int _dosTime = 0;
const int _dosDate = 0x0021;

final RegExp _plainName = RegExp(r'^[A-Za-z0-9][A-Za-z0-9._-]{0,100}$');
const Set<String> _deviceNames = <String>{
  'con', 'prn', 'aux', 'nul', //
  'com1', 'com2', 'com3', 'com4', 'com5', 'com6', 'com7', 'com8', 'com9',
  'lpt1', 'lpt2', 'lpt3', 'lpt4', 'lpt5', 'lpt6', 'lpt7', 'lpt8', 'lpt9',
};

String? referenceUnsafeNameReason(String name) {
  if (!_plainName.hasMatch(name)) return 'the name "$name" is not a plain file name';
  if (name.contains('..')) return 'the name "$name" contains ".."';
  if (name.endsWith('.')) return 'the name "$name" ends with a dot';
  if (_deviceNames.contains(name.split('.').first.toLowerCase())) {
    return 'the name "$name" is reserved on Windows';
  }
  return null;
}

final Uint32List _crcTable = () {
  final Uint32List t = Uint32List(256);
  for (int n = 0; n < 256; n++) {
    int c = n;
    for (int k = 0; k < 8; k++) {
      c = (c & 1) != 0 ? 0xEDB88320 ^ (c >> 1) : c >> 1;
    }
    t[n] = c;
  }
  return t;
}();

/// The bytewise CRC-32.
int referenceCrc32(Uint8List data) {
  int c = 0xFFFFFFFF;
  for (final int b in data) {
    c = _crcTable[(c ^ b) & 0xFF] ^ (c >> 8);
  }
  return (c ^ 0xFFFFFFFF) & 0xFFFFFFFF;
}

int _compareNames(String a, String b) {
  final int n = a.length < b.length ? a.length : b.length;
  for (int i = 0; i < n; i++) {
    final int d = a.codeUnitAt(i) - b.codeUnitAt(i);
    if (d != 0) return d;
  }
  return a.length - b.length;
}

Uint8List referenceWriteStoredZip(List<ZipEntry> entries) {
  final List<ZipEntry> sorted = List<ZipEntry>.of(entries)
    ..sort((ZipEntry a, ZipEntry b) => _compareNames(a.name, b.name));
  final Set<String> seen = <String>{};
  int total = _endRecord;
  for (final ZipEntry e in sorted) {
    final String? why = referenceUnsafeNameReason(e.name);
    if (why != null) throw ArgumentError(why);
    if (!seen.add(e.name.toLowerCase())) throw ArgumentError('the name "${e.name}" is used twice');
    total += _localHeader + _centralHeader + 2 * e.name.length + e.data.length;
  }
  final Uint8List out = Uint8List(total);
  final ByteData v = ByteData.sublistView(out);
  int pos = 0;
  final List<int> offsets = <int>[];
  for (final ZipEntry e in sorted) {
    offsets.add(pos);
    v.setUint32(pos, _localSig, Endian.little);
    v.setUint16(pos + 4, _version, Endian.little);
    v.setUint16(pos + 6, 0, Endian.little);
    v.setUint16(pos + 8, 0, Endian.little);
    v.setUint16(pos + 10, _dosTime, Endian.little);
    v.setUint16(pos + 12, _dosDate, Endian.little);
    v.setUint32(pos + 14, referenceCrc32(e.data), Endian.little);
    v.setUint32(pos + 18, e.data.length, Endian.little);
    v.setUint32(pos + 22, e.data.length, Endian.little);
    v.setUint16(pos + 26, e.name.length, Endian.little);
    v.setUint16(pos + 28, 0, Endian.little);
    out.setRange(pos + _localHeader, pos + _localHeader + e.name.length, e.name.codeUnits);
    pos += _localHeader + e.name.length;
    out.setRange(pos, pos + e.data.length, e.data);
    pos += e.data.length;
  }
  final int directoryStart = pos;
  for (final (int i, ZipEntry e) in sorted.indexed) {
    v.setUint32(pos, _centralSig, Endian.little);
    v.setUint16(pos + 4, _version, Endian.little);
    v.setUint16(pos + 6, _version, Endian.little);
    v.setUint16(pos + 8, 0, Endian.little);
    v.setUint16(pos + 10, 0, Endian.little);
    v.setUint16(pos + 12, _dosTime, Endian.little);
    v.setUint16(pos + 14, _dosDate, Endian.little);
    v.setUint32(pos + 16, referenceCrc32(e.data), Endian.little);
    v.setUint32(pos + 20, e.data.length, Endian.little);
    v.setUint32(pos + 24, e.data.length, Endian.little);
    v.setUint16(pos + 28, e.name.length, Endian.little);
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

List<ZipEntry> referenceReadStoredZip(Uint8List bytes) {
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

  final List<ZipEntry> entries = <ZipEntry>[];
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
    final String? why = referenceUnsafeNameReason(name);
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
    if (referenceCrc32(data) != crc) throw ZipException('the file "$name" is damaged (checksum)');
    entries.add(ZipEntry(name, data));

    expectedOffset = dataStart + size;
    at += _centralHeader + nameLength;
  }
  if (expectedOffset != directoryStart) {
    throw const ZipException('there are bytes between the files and the directory');
  }
  if (at != end) throw const ZipException('there are bytes after the directory');

  final Uint8List again = referenceWriteStoredZip(entries);
  if (again.length != bytes.length) throw const ZipException('the zip is not in canonical form');
  for (int i = 0; i < again.length; i++) {
    if (again[i] != bytes[i]) throw const ZipException('the zip is not in canonical form');
  }
  return entries;
}

String _asciiName(Uint8List bytes, int start, int length) {
  for (int i = start; i < start + length; i++) {
    if (bytes[i] < 0x21 || bytes[i] > 0x7E) {
      throw const ZipException('a file name has characters that are not allowed');
    }
  }
  return String.fromCharCodes(bytes, start, start + length);
}
