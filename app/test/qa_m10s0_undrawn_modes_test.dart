// QA of M10 step 0 (2026-11-06), item 4 of the brief: schema 1.4 of tap_answer takes stage pictures (`scene.picture`, X1) and the number
// answer (`answer.type: number`, X3). A pack that used a mode that **no session draws** would show the child an empty stage or an answer
// that cannot be given. This test fails the build if any activity in `content/` (and in the bundled starter pack) uses one. Batch C1
// (2026-11-07) built the blocks (`base_ten`), the hundred chart (`hundred_chart`) and the keypad (`number`) and took them off the list;
// the other picture kinds (array, clock, ruler, column, fraction) stay on it until the batch that needs each draws it.
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:nitznutz/content/pack_verify.dart';

/// The stage pictures a session draws today (`drawnStagePictureKinds` of the model).
const Set<String> _drawn = <String>{'base_ten', 'hundred_chart'};

/// What a document uses that no session draws yet: one line per use, empty for a document that is fine.
List<String> undrawnUses(String where, Object? doc) {
  if (doc is! Map<String, Object?>) return const <String>[];
  final List<String> found = <String>[];
  final Object? scene = doc['scene'];
  if (scene is Map<String, Object?> && scene.containsKey('picture')) {
    final Object? picture = scene['picture'];
    final Object? kind = picture is Map<String, Object?> ? picture['kind'] : null;
    if (!_drawn.contains(kind)) {
      found.add('$where: scene.picture of kind $kind (X1) is not drawn by any session yet');
    }
  }
  return found;
}

void main() {
  test('the detector finds a picture of a kind no session draws, and nothing else', () {
    expect(
      undrawnUses('a', <String, Object?>{
        'scene': <String, Object?>{
          'picture': <String, Object?>{'kind': 'clock'},
        },
      }),
      hasLength(1),
    );
    for (final String kind in <String>['base_ten', 'hundred_chart']) {
      expect(
        undrawnUses('drawn', <String, Object?>{
          'scene': <String, Object?>{
            'picture': <String, Object?>{'kind': kind},
          },
        }),
        isEmpty,
        reason: kind,
      );
    }
    expect(
      undrawnUses('b', <String, Object?>{
        'answer': <String, Object?>{'type': 'number', 'value': 12},
      }),
      isEmpty,
      reason: 'the keypad draws a number answer',
    );
    expect(
      undrawnUses('c', <String, Object?>{
        'scene': <String, Object?>{
          'row': <Object?>['n:1'],
          'group': <String, Object?>{},
        },
        'answer': <String, Object?>{'type': 'choice'},
      }),
      isEmpty,
    );
    expect(undrawnUses('d', <Object?>[1, 2]), isEmpty);
    expect(
      undrawnUses('e', <String, Object?>{
        'scene': <String, Object?>{'picture': 1},
        'answer': <String, Object?>{'type': 'number'},
      }),
      hasLength(1),
    );
  });

  test('no JSON document under content/ uses a stage picture that no session draws', () {
    final Directory root = Directory('../content');
    expect(root.existsSync(), isTrue, reason: 'run from app/');
    final List<String> found = <String>[];
    int read = 0;
    for (final File f in root.listSync(recursive: true).whereType<File>()) {
      final String path = f.path.replaceAll('\\', '/');
      // The schemas describe the modes; they are not packs.
      if (!path.endsWith('.json') || path.contains('/content/schemas/')) continue;
      Object? doc;
      try {
        doc = jsonDecode(f.readAsStringSync(encoding: utf8));
      } on FormatException {
        continue;
      }
      read++;
      found.addAll(undrawnUses(path, doc));
    }
    expect(read, greaterThan(500), reason: 'the walk really read the sources');
    expect(found, isEmpty, reason: found.join('\n'));
  });

  test('the bundled starter pack (what the app really loads) uses none', () async {
    final VerifiedPack pack = await verifyPack(
      File('assets/packs/starter-0.10.0.nnpack').readAsBytesSync(),
      publicKey: unhex(File('assets/pack_signing_public_key.txt').readAsStringSync()),
    );
    final List<String> found = <String>[];
    int activities = 0;
    for (final MapEntry<String, Object?> e in pack.docs.entries) {
      if (!e.key.startsWith('activity.')) continue;
      activities++;
      found.addAll(undrawnUses(e.key, e.value));
    }
    expect(activities, greaterThan(500));
    expect(found, isEmpty, reason: found.join('\n'));
  });
}
