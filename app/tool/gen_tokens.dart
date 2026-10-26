// Turns `design/tokens.json` (the single source of truth) into `lib/design/tokens.g.dart`.
//
//   dart run tool/gen_tokens.dart            (from the app/ folder) writes the file
//   dart run tool/gen_tokens.dart --check    exits 1 if the committed file is out of date
//
// `test/design_tokens_test.dart` runs the same check, so changing the JSON without regenerating
// fails CI.
import 'dart:convert';
import 'dart:io';

const String _tokensPath = '../design/tokens.json';
const String _outPath = 'lib/design/tokens.g.dart';

Future<void> main(List<String> args) async {
  final Map<String, Object?> json =
      jsonDecode(await File(_tokensPath).readAsString()) as Map<String, Object?>;
  final String generated = generateTokens(json);
  if (args.contains('--check')) {
    final String current = await File(_outPath).readAsString();
    if (current != generated) {
      stderr.writeln('$_outPath is out of date: run `dart run tool/gen_tokens.dart`.');
      exit(1);
    }
    stdout.writeln('$_outPath is up to date.');
    return;
  }
  await File(_outPath).writeAsString(generated);
  stdout.writeln('Wrote $_outPath');
}

String _camel(String key) {
  final List<String> parts = key.split(RegExp(r'[^A-Za-z0-9]+')).where((String p) => p.isNotEmpty).toList();
  final StringBuffer b = StringBuffer(parts.first[0].toLowerCase() + parts.first.substring(1));
  for (final String p in parts.skip(1)) {
    b.write(p[0].toUpperCase() + p.substring(1));
  }
  final String name = b.toString();
  return RegExp(r'^[0-9]').hasMatch(name) ? 's$name' : name;
}

String _color(String value) {
  final RegExpMatch? hex = RegExp(r'^#([0-9A-Fa-f]{6})$').firstMatch(value);
  if (hex != null) return 'Color(0xFF${hex.group(1)!.toUpperCase()})';
  final RegExpMatch? rgba = RegExp(r'^rgba\((\d+),\s*(\d+),\s*(\d+),\s*([0-9.]+)\)$').firstMatch(value);
  if (rgba != null) {
    return 'Color.fromRGBO(${rgba.group(1)}, ${rgba.group(2)}, ${rgba.group(3)}, ${rgba.group(4)})';
  }
  throw FormatException('Unsupported colour: $value');
}

String _num(Object? v) {
  final num n = v! as num;
  return n == n.truncate() ? '${n.truncate()}.0' : '$n';
}

Map<String, Object?> _map(Object? v) => v! as Map<String, Object?>;

String generateTokens(Map<String, Object?> t) {
  final StringBuffer o = StringBuffer()
    ..writeln(
      '// GENERATED FILE. Do not edit: run `dart run tool/gen_tokens.dart` after changing design/tokens.json.',
    )
    ..writeln('// dart format off')
    ..writeln('// ignore_for_file: type=lint')
    ..writeln("import 'dart:ui' show Color;")
    ..writeln()
    ..writeln("import 'token_types.dart';")
    ..writeln();

  // ---- colours ----
  o.writeln('/// Colours from tokens.json (all sRGB).');
  o.writeln('abstract final class TokenColors {');
  final Map<String, Object?> color = _map(t['color']);
  for (final String group in <String>['core', 'brand', 'feedback']) {
    for (final MapEntry<String, Object?> e in _map(color[group]).entries) {
      if (e.key.startsWith(r'$')) continue;
      o.writeln('  static const Color ${_camel(e.key)} = ${_color(_map(e.value)['value']! as String)};');
    }
  }
  for (final MapEntry<String, Object?> d in _map(color['domain']).entries) {
    if (d.key.startsWith(r'$')) continue;
    for (final String part in <String>['fill', 'deep', 'tint']) {
      o.writeln(
        '  static const Color ${_camel('domain_${d.key}_$part')} = ${_color(_map(d.value)[part]! as String)};',
      );
    }
  }
  for (final MapEntry<String, Object?> e in _map(color['teach']).entries) {
    if (e.key.startsWith(r'$')) continue;
    final Map<String, Object?> c = _map(e.value);
    o.writeln('  static const Color ${_camel('teach_${e.key}')} = ${_color(c['value']! as String)};');
    o.writeln('  static const Color ${_camel('teach_${e.key}_lip')} = ${_color(c['lip']! as String)};');
  }
  for (final MapEntry<String, Object?> e in _map(color['world']).entries) {
    if (e.key.startsWith(r'$')) continue;
    o.writeln(
      '  static const Color ${_camel('world_${e.key}')} = ${_color(_map(e.value)['value']! as String)};',
    );
  }
  o.writeln('}');
  o.writeln();

  // ---- font ----
  final Map<String, Object?> font = _map(t['font']);
  o.writeln('/// Font families bundled in assets/fonts (names as declared in pubspec.yaml).');
  o.writeln('abstract final class TokenFonts {');
  o.writeln("  static const String display = 'SecularOne';");
  o.writeln("  static const String text = 'Heebo';");
  o.writeln(
    '  static const double niqqudMinLineHeight = ${_num(_map(font['niqqudRules'])['minLineHeight'])};',
  );
  o.writeln('  static const int maxWeightBelow24pt = ${_map(font['niqqudRules'])['maxWeightBelow24pt']};');
  o.writeln('}');
  o.writeln();

  // ---- type ----
  final Map<String, Object?> type = _map(t['type']);
  String typeToken(Map<String, Object?> s, {String? sizeKey}) {
    final Map<String, Object?> sizes = _map(s['size']);
    return 'TypeToken(family: \'${s['family']}\', weight: ${s['weight']}, lineHeight: ${_num(s['lineHeight'])}, '
        'phoneSize: ${_num(sizes['phone'])}, tabletSize: ${_num(sizes['tablet'])})';
  }

  o.writeln('/// Child-space type styles, per age band where the design has one.');
  o.writeln('abstract final class TokenType {');
  final Map<String, Object?> kid = _map(type['kid']);
  for (final MapEntry<String, Object?> e in kid.entries) {
    if (e.key.startsWith(r'$')) continue;
    final Map<String, Object?> s = _map(e.value);
    if (s.containsKey('A')) {
      o.writeln('  static const Map<Band, TypeToken> ${_camel(e.key)} = <Band, TypeToken>{');
      for (final String band in <String>['A', 'B', 'C']) {
        o.writeln('    Band.${band.toLowerCase()}: ${typeToken(_map(s[band]))},');
      }
      o.writeln('  };');
    } else {
      o.writeln('  static const TypeToken ${_camel(e.key)} = ${typeToken(s)};');
    }
  }
  for (final MapEntry<String, Object?> e in _map(type['parent']).entries) {
    if (e.key.startsWith(r'$')) continue;
    final Map<String, Object?> s = _map(e.value);
    o.writeln(
      '  static const ParentTypeToken ${_camel('parent_${e.key}')} = ParentTypeToken('
      'weight: ${s['weight']}, size: ${_num(s['size'])}, lineHeight: ${_num(s['lineHeight'])});',
    );
  }
  o.writeln('}');
  o.writeln();

  // ---- space, radius, border ----
  void doubles(String cls, String doc, Map<String, Object?> m) {
    o.writeln('/// $doc');
    o.writeln('abstract final class $cls {');
    for (final MapEntry<String, Object?> e in m.entries) {
      if (e.key.startsWith(r'$')) continue;
      o.writeln('  static const double ${_camel(e.key)} = ${_num(e.value)};');
    }
    o.writeln('}');
    o.writeln();
  }

  doubles('TokenSpace', 'Spacing scale in logical points (s4 = 16).', _map(t['space']));
  doubles('TokenRadius', 'Corner radii.', _map(t['radius']));
  doubles('TokenBorder', 'Border widths.', _map(t['border']));

  // ---- touch ----
  final Map<String, Object?> touch = _map(t['touch']);
  o.writeln('/// Touch sizes per age band, and the edge bands that hold no drag targets.');
  o.writeln('abstract final class TokenTouch {');
  o.writeln('  static const Map<Band, BandTouch> band = <Band, BandTouch>{');
  for (final String b in <String>['A', 'B', 'C']) {
    final Map<String, Object?> s = _map(touch[b]);
    final Map<String, Object?> ans = _map(s['answer']);
    final Map<String, Object?> gap = _map(s['gap']);
    o.writeln(
      '    Band.${b.toLowerCase()}: BandTouch(minControl: ${_num(s['minControl'])}, '
      'answerPhone: ${_num(ans['phone'])}, answerTablet: ${_num(ans['tablet'])}, '
      'gapPhone: ${_num(gap['phone'])}, gapTablet: ${_num(gap['tablet'])}, '
      'hitSlop: ${_num(s['hitSlop'])}, maxChoices: ${s['maxChoices']}),',
    );
  }
  o.writeln('  };');
  o.writeln('  static const double edgeNoDrag = ${_num(touch['edgeNoDrag'])};');
  o.writeln('  static const double bottomNoHotspot = ${_num(touch['bottomNoHotspot'])};');
  o.writeln('}');
  o.writeln();

  // ---- layout ----
  final Map<String, Object?> layout = _map(t['layout']);
  final Map<String, Object?> devices = _map(layout['devices']);
  o.writeln('/// Reference devices of the boards and the layout numbers per size class.');
  o.writeln('abstract final class TokenLayout {');
  for (final MapEntry<String, Object?> e in devices.entries) {
    final Map<String, Object?> d = _map(e.value);
    final Map<String, Object?> s = _map(d['safe']);
    o.writeln(
      '  static const DeviceToken ${_camel('device_${e.key}')} = DeviceToken(width: ${_num(d['w'])}, '
      'height: ${_num(d['h'])}, safeStart: ${_num(s['start'])}, safeEnd: ${_num(s['end'])}, '
      'safeTop: ${_num(s['top'])}, safeBottom: ${_num(s['bottom'])});',
    );
  }
  for (final String cls in <String>['phone', 'phoneSE', 'tablet']) {
    final Map<String, Object?> s = _map(layout[cls]);
    final Map<String, Object?> bar = _map(s['topBar']);
    final Map<String, Object?> rail = _map(s['guideRail']);
    o.writeln(
      '  static const LayoutClass ${_camel('class_$cls')} = LayoutClass(contentMargin: ${_num(s['contentMargin'])}, '
      'topBarHeight: ${_num(bar['height'])}, topBarControlTop: ${_num(bar['controlTop'])}, '
      'guideRailWidth: ${_num(rail['width'])});',
    );
  }
  o.writeln('}');
  o.writeln();

  // ---- motion ----
  final Map<String, Object?> motion = _map(t['motion']);
  o.writeln('/// Durations in milliseconds and a few motion values.');
  o.writeln('abstract final class TokenMotion {');
  for (final MapEntry<String, Object?> e in _map(motion['duration']).entries) {
    o.writeln('  static const Duration ${_camel('d_${e.key}')} = Duration(milliseconds: ${e.value});');
  }
  final Map<String, Object?> values = _map(motion['values']);
  o.writeln('  static const double pressScale = ${_num(values['pressScale'])};');
  o.writeln('  static const double maxFlashHz = ${_num(values['maxFlashHz'])};');
  o.writeln('}');
  o.writeln();

  // ---- components ----
  final Map<String, Object?> comp = _map(t['component']);
  final Map<String, Object?> pebble = _map(comp['pebbleButton']);
  final Map<String, Object?> pebbleSize = _map(pebble['size']);
  final Map<String, Object?> trail = _map(comp['progressTrail']);
  final Map<String, Object?> caption = _map(comp['caption']);
  o.writeln('/// Component measurements from board 05.');
  o.writeln('abstract final class TokenComponent {');
  o.writeln(
    '  static const Map<Band, double> pebbleSize = <Band, double>{Band.a: ${_num(pebbleSize['A'])}, '
    'Band.b: ${_num(pebbleSize['B'])}, Band.c: ${_num(pebbleSize['C'])}};',
  );
  o.writeln('  static const double clayLip = ${_num(pebble['lip'])};');
  o.writeln('  static const double clayLipPressed = ${_num(_map(_map(t['elevation'])['lip'])['pressed'])};');
  o.writeln('  static const double trailSocket = ${_num(trail['socket'])};');
  o.writeln('  static const double trailGap = ${_num(trail['gap'])};');
  o.writeln('  static const double trailHeight = ${_num(trail['height'])};');
  o.writeln('  static const double captionPaddingX = ${_num(caption['paddingX'])};');
  o.writeln('  static const double captionPaddingY = ${_num(caption['paddingY'])};');
  o.writeln('  static const double parentButtonHeight = ${_num(_map(comp['parentButton'])['height'])};');
  o.writeln('}');
  return o.toString();
}
