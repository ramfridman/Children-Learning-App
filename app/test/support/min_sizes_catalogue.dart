// Which activities the minimum-sizes test opens (docs/agents/qa-min-sizes-2026-11-17.md): the pack has 1,328 activities but only a few hundred
// ways to lay one out. An activity's layout fingerprint is its template and band, plus the parts of its scene that decide what is drawn and how
// big: how many options, how many things in a set (exact to 10), the arrangement, the mode, how many bins and items, the range of a number
// line, and for each picture the class of its drawing (wide strip, tall, square; how much of its box is ink). Text, ids, vo clips, hints
// and feedback are not in it, so two activities with the same fingerprint draw the same boxes. The first activity (by id) of each fingerprint
// is its representative; the test opens the representative and the report says how many activities each one stands for.
import 'package:nitznutz/content/models.dart';
import 'package:nitznutz/play/hints/tap_plans.dart' show inkBoxOf;

const Set<String> _ignoreKeys = <String>{
  'schema',
  'id',
  'revision',
  'review',
  'vo',
  'caption',
  'feedback',
  'hints',
  'a11y',
  'scoring',
  'difficulty',
  'prompt',
  'tutor',
  'skills',
  'checkType',
  'representation',
  'variantGroup',
  'purpose',
  'contradicts',
  'asks',
  'voiceAnswer',
  'seed',
  'x',
  'y',
  'w',
  'h',
  'rot',
  'aspect',
  'scale',
  'weight',
  'flashMs',
  'tolerance',
  'cell',
  'strokes',
  'labels',
  'background',
  'robot',
  'goal',
  'col',
  'row',
  'bin',
  'item',
  'left',
  'right',
  'slot',
  'coin',
  'arrow',
  'pan',
  'domain',
  'misconception',
  'when',
  'say',
  'handOver',
  'by',
  'role',
  'correct',
  'wrong',
  'target',
  'solution',
  'result',
  'text',
  'teaches',
  'templateVersion',
  'template',
  'band',
  'shuffle',
  'unsureAllowed',
  'replayButton',
  'show',
};

/// Keys whose string value is an enum that changes the layout.
const Set<String> _enumKeys = <String>{
  'arrangement',
  'mode',
  'kind',
  'motion',
  'guide',
  'type',
  'detail',
  'put',
};

String _bucket(num n) {
  final int i = n.round();
  if (i <= 10) return '$i';
  if (i <= 20) return 'm';
  if (i <= 100) return 'h';
  return 'k';
}

String _assetClass(PackAssets assets, String ref) {
  final String? svg = assets.svgOrNull(ref);
  if (svg == null) return 'A?';
  final RegExpMatch? vb = RegExp(r'viewBox="\s*[-\d.]+[\s,]+[-\d.]+[\s,]+([\d.]+)[\s,]+([\d.]+)')
      .firstMatch(svg);
  String aspect = 'sq';
  if (vb != null) {
    final double w = double.tryParse(vb[1]!) ?? 1, h = double.tryParse(vb[2]!) ?? 1;
    final double r = w / h;
    aspect = (r - 2.5).abs() < 0.05
        ? 'strip'
        : r > 1.3
        ? 'wide'
        : r < 0.77
        ? 'tall'
        : 'sq';
  }
  final double area = _inkArea(svg);
  final String ink = area < 0.4 ? 'small' : 'full';
  return 'A.$aspect.$ink';
}

double _inkArea(String svg) {
  final r = inkBoxOf(svg);
  return r.width * r.height;
}

String _shape(Object? v, String? key, PackAssets assets) {
  if (v is Map<String, Object?>) {
    final List<String> parts = <String>[];
    for (final String k in (v.keys.toList()..sort())) {
      if (_ignoreKeys.contains(k)) continue;
      if (k == 'label' && v[k] is String) {
        final int n = (v[k]! as String).length;
        parts.add('label:${n <= 14 ? 's' : 'l'}');
        continue;
      }
      parts.add('$k:${_shape(v[k], k, assets)}');
    }
    return '{${parts.join(',')}}';
  }
  if (v is List<Object?>) {
    if (v.isEmpty) return '[]';
    if (key == 'options' && v.every((Object? x) => x is Map<String, Object?>)) {
      // the options of a choice: how many, and what they show (pictures of which kind, the widest numeral, the longest label)
      final Set<String> feat = <String>{};
      int digits = 0;
      bool long = false;
      for (final Map<String, Object?> o in v.cast<Map<String, Object?>>()) {
        final Object? sp = o['sprite'];
        if (sp is String) feat.add(_assetClass(assets, sp));
        final Object? nu = o['numeral'];
        if (nu is num) {
          final int n = nu.abs().round().toString().length;
          digits = digits < n ? n : digits;
        }
        final Object? lb = o['label'];
        if (lb is String && lb.length > 14) long = true;
        for (final String k in o.keys) {
          if (k == 'set' || k == 'blocks' || k == 'coin' || k == 'face' || k == 'clock') feat.add(k);
        }
      }
      final List<String> f = feat.toList()..sort();
      return '[${v.length}:${f.join('|')}${digits > 0 ? '|${digits}d' : ''}${long ? '|long' : ''}]';
    }
    final Set<String> shapes = <String>{
      for (final Object? x in v)
        if (x is Map<String, Object?>)
          _shape(x, key, assets)
        else if (x is String && x.startsWith('asset:'))
          _assetClass(assets, x)
        else
          x is num ? 'n' : 's',
    };
    final List<String> s = shapes.toList()..sort();
    return '[${_bucket(v.length)}:${s.take(4).join('|')}]';
  }
  if (v is bool) return v ? 'T' : 'F';
  if (v is num) {
    if (const <String>{
      'count',
      'n',
      'cols',
      'rows',
      'itemCount',
      'tens',
      'ones',
      'hops',
      'prefilled',
      'blank',
      'lit',
    }.contains(key)) {
      return _bucket(v);
    }
    if (key == 'maxSteps') return v > 6 ? 'long' : 'short';
    if (key == 'numeral' ||
        key == 'from' ||
        key == 'to' ||
        key == 'start' ||
        key == 'value' ||
        key == 'price') {
      return '${v.abs().round().toString().length}d';
    }
    return '#';
  }
  if (v is String) {
    if (v.startsWith('asset:')) return _assetClass(assets, v);
    if (_enumKeys.contains(key) && v.length < 24) return v;
    return 's';
  }
  return '-';
}

/// The layout fingerprint of [a].
String fingerprintOf(Activity a) =>
    '${a.template}/${a.templateVersion}/${a.band}/${a.isShow ? 'show' : 'item'}/'
    '${_shape(a.json['scene'], 'scene', a.assets)}/${_shape(a.json['answer'], 'answer', a.assets)}';

/// A group of activities with one layout.
class LayoutGroup {
  LayoutGroup(this.fingerprint, this.ids);
  final String fingerprint;
  final List<String> ids;
  String get rep => ids.first;
  String get template => fingerprint.split('/').first;
}

/// Every layout of the activities of [pack] that [keep] allows, the representative first in each, in id order.
List<LayoutGroup> layoutGroups(PackContent pack, {bool Function(Activity a)? keep}) {
  final Map<String, List<String>> by = <String, List<String>>{};
  final List<String> ids = pack.activities.keys.toList()..sort();
  for (final String id in ids) {
    final Activity a = pack.activities[id]!;
    if (keep != null && !keep(a)) continue;
    by.putIfAbsent(fingerprintOf(a), () => <String>[]).add(id);
  }
  return <LayoutGroup>[
    for (final MapEntry<String, List<String>> e in by.entries) LayoutGroup(e.key, e.value),
  ];
}
