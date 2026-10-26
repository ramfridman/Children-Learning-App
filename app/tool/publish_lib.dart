// Builds the item index of a verified pack for the gateway's `content-publish` and sends it. PC only.
//
// What goes up is text the prompt is built from: the author's goal, the Hebrew question, the answer forms, the
// numbers and object ids of the item, the allowed hint actions and the hint threshold. No audio, no pictures.
// The publish secret comes from the environment and is sent in one header; it is never printed or written.
import 'dart:convert';
import 'dart:io';

import 'package:nitznutz/content/pack_verify.dart';

class PublishFailed implements Exception {
  const PublishFailed(this.message);

  final String message;

  @override
  String toString() => message;
}

List<Map<String, Object?>> _maps(Object? v) => <Map<String, Object?>>[
  if (v is List<Object?>)
    for (final Object? e in v)
      if (e is Map<String, Object?>) e,
];

String _hebrewCaption(Object? caption) {
  for (final Map<String, Object?> c in _maps(caption)) {
    if (c['t'] == 'he') return c['v']! as String;
  }
  throw const PublishFailed('an activity has no Hebrew caption');
}

/// The index entry of one activity document.
Map<String, Object?> itemOf(Map<String, Object?> a) {
  final Map<String, Object?> answer = (a['answer'] as Map<String, Object?>?) ?? <String, Object?>{};
  final Map<String, Object?> tutor = (a['tutor'] as Map<String, Object?>?) ?? <String, Object?>{};
  final Map<String, Object?> scene = (a['scene'] as Map<String, Object?>?) ?? <String, Object?>{};
  final List<Map<String, Object?>> answers = <Map<String, Object?>>[];
  final Set<int> numbers = <int>{};
  final List<String> objects = <String>[];

  if (answer['type'] == 'give') {
    // "Give N": the right answer is the number; each way of going wrong is a class with its misconception.
    final int n = answer['n']! as int;
    numbers.add(n);
    answers.add(<String, Object?>{'id': 'give-n', 'value': n, 'correct': true});
    for (final Map<String, Object?> c in _maps(answer['classifiers'])) {
      answers.add(<String, Object?>{
        'id': (c['when']! as String).replaceAll('_', '').toLowerCase(),
        'misconception': c['misconception'],
        'correct': false,
      });
    }
    final Map<String, Object?>? src = scene['source'] as Map<String, Object?>?;
    final Object? count = src?['count'];
    if (count is int) {
      numbers.add(count);
      objects.addAll(<String>[for (int i = 0; i < count; i++) 'obj-$i']);
    }
  } else {
    final String correct = answer['correct']! as String;
    for (final Map<String, Object?> o in _maps(answer['options'])) {
      final String id = o['id']! as String;
      answers.add(<String, Object?>{
        'id': id,
        if (o['value'] is int) 'value': o['value'],
        if (o['label'] is String) 'label': o['label'],
        if (o['misconception'] is String) 'misconception': o['misconception'],
        'correct': id == correct,
      });
      if (o['value'] is int) numbers.add(o['value']! as int);
      objects.add(id);
    }
    final Map<String, Object?>? objs = scene['objects'] as Map<String, Object?>?;
    final Object? count = objs?['count'];
    if (count is int) {
      numbers.add(count);
      objects.addAll(<String>[for (int i = 0; i < count; i++) 'obj-$i']);
    }
  }
  final Set<String> actions = <String>{
    for (final Map<String, Object?> h in _maps(a['hints'])) h['action']! as String,
  };
  return <String, Object?>{
    'item_id': a['id'],
    'revision': a['revision'],
    'template': a['template'],
    'band': a['band'],
    'skill_ids': <String>[for (final Map<String, Object?> s in _maps(a['skills'])) s['id']! as String],
    'llm_allowed': tutor['llmAllowed'] == true,
    'goal': (tutor['goal'] as String?) ?? 'answer the question',
    'prompt_text': _hebrewCaption((a['prompt']! as Map<String, Object?>)['caption']),
    'answers': answers,
    'number_set': (numbers.toList()..sort()),
    'allowed_actions': (actions.toList()..sort()),
    'hint_threshold': ((tutor['mustNotRevealBeforeHint'] as int?) ?? 3).clamp(1, 3),
    'object_ids': objects.toSet().toList(),
  };
}

/// The body of `content-publish` for a verified pack. A character pack gives one character (and no items); a
/// content pack gives its activities and misconceptions. [voices] maps a character id to its ElevenLabs voice id.
Map<String, Object?> indexOf(VerifiedPack pack, {Map<String, String> voices = const <String, String>{}}) {
  final List<Map<String, Object?>> items = <Map<String, Object?>>[];
  final List<Map<String, Object?>> misconceptions = <Map<String, Object?>>[];
  final List<Map<String, Object?>> characters = <Map<String, Object?>>[];
  for (final MapEntry<String, Object?> e in pack.docs.entries) {
    final Object? doc = e.value;
    if (doc is! Map<String, Object?>) continue;
    if (e.key.startsWith('activity.')) {
      items.add(itemOf(doc));
    } else if (e.key.startsWith('misconception.')) {
      misconceptions.add(<String, Object?>{
        'tag': doc['id'],
        'skill_ids': doc['skills'],
        'description': doc['parentText'],
      });
    } else if (e.key.startsWith('character.')) {
      final Map<String, Object?> name = doc['name']! as Map<String, Object?>;
      // A family character's name may carry the child's name; the server never knows it, so only the rest is sent.
      final String he = (name['he']! as String).replaceAll('{name}', '').trim();
      if (he.isEmpty) continue;
      final String id = doc['id']! as String;
      characters.add(<String, Object?>{
        'character_id': id,
        'name_he': he,
        'gender': name['gender'],
        'personal': doc['personalUseOnly'] == true,
        if (voices[id] != null && voices[id]!.isNotEmpty) 'voice_id': voices[id],
      });
    }
  }
  return <String, Object?>{
    'pack_id': pack.id,
    'pack_version': pack.version,
    'manifest_sha256': pack.manifestSha256,
    'items': items,
    'misconceptions': misconceptions,
    'characters': characters,
  };
}

/// Voice ids from `content/voices.json` (empty ones are left out).
Map<String, String> readVoices(File f) {
  final Map<String, Object?> doc = jsonDecode(f.readAsStringSync()) as Map<String, Object?>;
  final Map<String, Object?> voices = (doc['voices'] ?? <String, Object?>{}) as Map<String, Object?>;
  return <String, String>{
    for (final MapEntry<String, Object?> e in voices.entries)
      if (e.value is Map<String, Object?> && ((e.value! as Map<String, Object?>)['voiceId'] ?? '') != '')
        e.key: (e.value! as Map<String, Object?>)['voiceId']! as String,
  };
}

/// Sends the index. [baseUrl] is the project URL (changed only by tests, to a local fake). Returns the server's answer.
Future<Map<String, Object?>> publish(
  Map<String, Object?> body, {
  required String baseUrl,
  required String secret,
  String? publishableKey,
}) async {
  final HttpClient client = HttpClient();
  try {
    final HttpClientRequest req = await client.postUrl(Uri.parse('$baseUrl/functions/v1/content-publish'));
    req.headers
      ..set('content-type', 'application/json')
      ..set('x-publish-secret', secret)
      ..set('x-region', 'eu-central-1');
    if (publishableKey != null) req.headers.set('apikey', publishableKey);
    req.add(utf8.encode(jsonEncode(body)));
    final HttpClientResponse res = await req.close();
    final String text = await utf8.decodeStream(res);
    if (res.statusCode != 200) {
      // The server's answer is a short code only; never echo the request.
      String code = 'error';
      try {
        code = ((jsonDecode(text) as Map<String, Object?>)['error'] ?? 'error').toString();
      } on FormatException {
        // keep the generic word
      }
      throw PublishFailed('the server refused: ${res.statusCode} $code');
    }
    return jsonDecode(text) as Map<String, Object?>;
  } finally {
    client.close();
  }
}
