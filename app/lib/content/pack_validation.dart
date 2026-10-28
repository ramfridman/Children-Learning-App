import 'schema.dart';
import 'schemas.dart';

/// Checks that need more than one file: every reference points at something that exists, ids are
/// unique, the manifest lists exactly what the pack holds, tags come from the catalogue, and the
/// Hebrew follows the house rules. The single-file rules are the schemas in `schemas.dart`.
///
/// [docs] holds each JSON file of the pack (by file name) already decoded; [files] is every file
/// name in the pack. The same function runs in the pack builder and in the app's installer.
List<Problem> validatePack({
  required Map<String, Object?> manifest,
  required Map<String, Object?> docs,
  required Set<String> files,
}) {
  final List<Problem> out = <Problem>[];
  void add(String file, Problem p) =>
      out.add(Problem(p.path.isEmpty ? file : '$file › ${p.path}', p.message));
  void say(String file, String path, String message) =>
      out.add(Problem(path.isEmpty ? file : '$file › $path', message));

  // ---- the manifest itself ----
  for (final Problem p in validate(manifestSchema, manifest)) {
    add('manifest.json', p);
  }
  if (out.isNotEmpty) return out; // the rest relies on the manifest's shape

  final List<Map<String, Object?>> listed = _maps(manifest['files']);
  final Set<String> listedNames = <String>{for (final Map<String, Object?> f in listed) f['name']! as String};
  for (final String n in files.difference(listedNames)) {
    say(n, '', 'is in the pack but not in the manifest');
  }
  for (final String n in listedNames.difference(files)) {
    say('manifest.json', 'files', '"$n" is listed but missing from the pack');
  }

  // ---- which file is which ----
  final Map<String, String> assetFiles = <String, String>{
    for (final Map<String, Object?> a in _maps(manifest['assets'])) a['id']! as String: a['file']! as String,
  };
  final Map<String, String> voFiles = <String, String>{
    for (final Map<String, Object?> a in _maps(manifest['vo'])) a['id']! as String: a['file']! as String,
  };
  final Set<String> referencedFiles = <String>{...assetFiles.values, ...voFiles.values};
  for (final String f in referencedFiles) {
    if (!listedNames.contains(f)) say('manifest.json', 'assets', '"$f" is not in the file list');
  }
  final Set<String> voPending = <String>{
    for (final Object? v in manifest['voPending']! as List<Object?>) v! as String,
  };
  for (final String id in voFiles.keys) {
    if (voPending.contains('vo:$id')) {
      say('manifest.json', 'voPending', 'vo:$id is both recorded and pending');
    }
  }

  final Map<String, Map<String, Object?>> activities = <String, Map<String, Object?>>{};
  final Map<String, Map<String, Object?>> lessons = <String, Map<String, Object?>>{};
  final Map<String, Map<String, Object?>> skills = <String, Map<String, Object?>>{};
  final Map<String, Map<String, Object?>> tags = <String, Map<String, Object?>>{};
  // Every id that has a file, even one that failed its schema; only valid documents are cross-checked.
  final Set<String> activityIds = <String>{};
  final Set<String> lessonIds = <String>{};
  final Set<String> skillIds = <String>{};
  final Set<String> tagIds = <String>{};
  final Map<String, Map<String, Object?>> characters = <String, Map<String, Object?>>{};
  final Set<String> characterIds = <String>{};
  final Map<String, Map<String, Object?>> cues = <String, Map<String, Object?>>{};
  final Set<String> cueIds = <String>{};

  for (final String name in listedNames.intersection(files)) {
    final bool isJson = name.endsWith('.json');
    if (!isJson) {
      if (!referencedFiles.contains(name)) {
        say(name, '', 'is not used by any asset or voice line of the manifest');
      }
      continue;
    }
    if (referencedFiles.contains(name)) {
      say(name, '', 'is a JSON file but is listed as an asset');
      continue;
    }
    final Object? doc = docs[name];
    if (doc is! Map<String, Object?>) {
      say(name, '', 'is not a JSON object');
      continue;
    }
    final RegExpMatch? named = _jsonName.firstMatch(name);
    if (named == null) {
      say(name, '', 'is a JSON file whose name is not <kind>.<id>.json');
      continue;
    }
    final String kind = named.group(1)!;
    final String middle = named.group(2)!;
    switch (kind) {
      case 'activity':
        final Object? template = doc['template'];
        final Schema? s = template is String ? activitySchemaFor(template) : null;
        activityIds.add(middle);
        if (s == null) {
          say(name, 'template', 'is not a template this version of the app can play');
          continue;
        }
        final List<Problem> found = validate(s, doc);
        for (final Problem p in found) {
          add(name, p);
        }
        if (doc['id'] != middle) say(name, 'id', 'must equal "$middle", the middle of the file name');
        if (found.isEmpty) activities[middle] = doc;
      case 'lesson':
        lessonIds.add(middle);
        final List<Problem> found = validate(lessonSchema, doc);
        for (final Problem p in found) {
          add(name, p);
        }
        if (doc['id'] != middle) say(name, 'id', 'must equal "$middle", the middle of the file name');
        if (found.isEmpty) lessons[middle] = doc;
      case 'skill':
        skillIds.add(middle);
        final List<Problem> found = validate(skillSchema, doc);
        for (final Problem p in found) {
          add(name, p);
        }
        if (doc['id'] != middle) say(name, 'id', 'must equal "$middle", the middle of the file name');
        if (found.isEmpty) skills[middle] = doc;
      case 'misconception':
        tagIds.add(middle);
        final List<Problem> found = validate(misconceptionSchema, doc);
        for (final Problem p in found) {
          add(name, p);
        }
        if (doc['id'] != middle) say(name, 'id', 'must equal "$middle", the middle of the file name');
        if (found.isEmpty) tags[middle] = doc;
      case 'character':
        characterIds.add(middle);
        final List<Problem> found = validate(characterSchema, doc);
        for (final Problem p in found) {
          add(name, p);
        }
        if (doc['id'] != middle) say(name, 'id', 'must equal "$middle", the middle of the file name');
        if (found.isEmpty) characters[middle] = doc;
      case 'cue':
        cueIds.add(middle);
        final List<Problem> found = validate(cueSchema, doc);
        for (final Problem p in found) {
          add(name, p);
        }
        if (doc['id'] != middle) say(name, 'id', 'must equal "$middle", the middle of the file name');
        if (found.isEmpty) cues[middle] = doc;
      default:
        say(name, '', 'is a JSON file of an unknown kind "$kind"');
    }
  }

  // ---- the manifest's own lists must match what is in the pack ----
  final Map<String, Object?> entries = manifest['entries']! as Map<String, Object?>;
  void sameSet(String field, Set<String> found) {
    final Set<String> declared = <String>{
      for (final Object? e in (entries[field] as List<Object?>?) ?? const <Object?>[]) e! as String,
    };
    for (final String d in declared.difference(found)) {
      say('manifest.json', 'entries.$field', '"$d" is declared but there is no such file');
    }
    for (final String f in found.difference(declared)) {
      say('manifest.json', 'entries.$field', '"$f" is in the pack but not declared');
    }
  }

  sameSet('activities', activityIds);
  sameSet('lessons', lessonIds);
  sameSet('skills', skillIds);
  sameSet('misconceptions', tagIds);
  sameSet('characters', characterIds);
  sameSet('cues', cueIds);

  // ---- the manifest must promise every template an activity uses ----
  final Map<String, Object?> templates = manifest['templates']! as Map<String, Object?>;
  activities.forEach((String id, Map<String, Object?> a) {
    final String t = a['template']! as String;
    if (!templates.containsKey(t)) {
      say('manifest.json', 'templates', 'does not list "$t", which activity $id uses');
    }
  });

  // ---- references ----
  bool hasAsset(String ref) => assetFiles.containsKey(ref.substring('asset:'.length));
  bool hasVo(String ref) => voFiles.containsKey(ref.substring('vo:'.length)) || voPending.contains(ref);

  void checkAsset(String file, String path, Object? ref) {
    if (ref is String && !hasAsset(ref)) say(file, path, '$ref is not in the manifest assets');
  }

  void checkVo(String file, String path, Object? ref) {
    if (ref is String && !hasVo(ref)) say(file, path, '$ref is neither recorded nor listed in voPending');
  }

  void checkTag(String file, String path, Object? tag) {
    if (tag is String && !tagIds.contains(tag)) {
      say(file, path, 'the tag $tag is not in the misconception catalogue of this pack');
    }
  }

  void checkSkill(String file, String path, Object? id) {
    if (id is String && !skillIds.contains(id)) say(file, path, 'the skill $id is not in this pack');
  }

  activities.forEach((String id, Map<String, Object?> a) {
    final String file = 'activity.$id.json';
    for (final (int i, Map<String, Object?> s) in _maps(a['skills']).indexed) {
      checkSkill(file, 'skills[$i].id', s['id']);
    }
    final Map<String, Object?> prompt = a['prompt']! as Map<String, Object?>;
    checkVo(file, 'prompt.vo', prompt['vo']);
    checkTag(file, 'contradicts', a['contradicts']);
    final Map<String, Object?> fb = a['feedback']! as Map<String, Object?>;
    checkVo(file, 'feedback.correct.vo', (fb['correct']! as Map<String, Object?>)['vo']);
    checkVo(file, 'feedback.unsure.vo', (fb['unsure']! as Map<String, Object?>)['vo']);
    bool hasDefault = false;
    for (final (int i, Map<String, Object?> r) in _maps(fb['incorrect']).indexed) {
      checkVo(file, 'feedback.incorrect[$i].vo', r['vo']);
      final String when = r['when']! as String;
      if (when == 'default') {
        hasDefault = true;
      } else {
        checkTag(file, 'feedback.incorrect[$i].when', when.substring('misconception:'.length));
      }
    }
    if (!hasDefault) say(file, 'feedback.incorrect', 'needs a rule with "when": "default"');
    final List<Map<String, Object?>> hints = _maps(a['hints']);
    for (final (int i, Map<String, Object?> h) in hints.indexed) {
      checkVo(file, 'hints[$i].vo', h['vo']);
      if (h['level'] != i + 1) say(file, 'hints[$i].level', 'hints must be numbered 1, 2, 3 in order');
    }
    // The ladder must change something: a second hint that does the same as the first helps nobody (M9 content rules).
    if (hints.length >= 2 && hints[1]['action'] == hints[0]['action']) {
      say(
        file,
        'hints[1].action',
        'level 2 must help in a different way than level 1 (change the representation)',
      );
    }
    _lengths(file, a, say);
    final List<Object?> credit =
        (a['scoring']! as Map<String, Object?>)['creditByHintLevel']! as List<Object?>;
    for (int i = 1; i < credit.length; i++) {
      if ((credit[i]! as num) > (credit[i - 1]! as num)) {
        say(file, 'scoring.creditByHintLevel', 'credit must not grow as more hints are used');
      }
    }

    final Map<String, Object?> scene = a['scene']! as Map<String, Object?>;
    final Map<String, Object?> answer = a['answer']! as Map<String, Object?>;
    switch (a['template']) {
      case 'tap_answer':
        checkAsset(file, 'scene.background', scene['background']);
        _options(file, answer, say, checkTag, checkAsset: checkAsset);
        for (final (int i, Object? r) in ((scene['row'] as List<Object?>?) ?? const <Object?>[]).indexed) {
          if (r is String && r.startsWith('asset:')) checkAsset(file, 'scene.row[$i]', r);
        }
        for (final String g in <String>['group', 'group2']) {
          final Object? group = scene[g];
          if (group is Map<String, Object?>) checkAsset(file, 'scene.$g.sprite', group['sprite']);
        }
        for (final (int i, Map<String, Object?> o) in _maps(answer['options']).indexed) {
          final int kinds = <String>['sprite', 'numeral', 'set'].where(o.containsKey).length;
          if (kinds != 1) {
            say(file, 'answer.options[$i]', 'must be exactly one of a sprite, a numeral or a set');
          }
          final Object? set = o['set'];
          if (set is Map<String, Object?>) checkAsset(file, 'answer.options[$i].set.sprite', set['sprite']);
        }
        // Two answers that look the same cannot be told apart by a child.
        final List<String> looks = <String>[
          for (final Map<String, Object?> o in _maps(answer['options'])) _look(o),
        ];
        if (looks.toSet().length != looks.length) say(file, 'answer.options', 'two options look the same');
      case 'count_tap':
        checkAsset(file, 'scene.background', scene['background']);
        final Map<String, Object?> objects = scene['objects']! as Map<String, Object?>;
        checkAsset(file, 'scene.objects.sprite', objects['sprite']);
        checkAsset(file, 'scene.objects.litSprite', objects['litSprite']);
        checkAsset(file, 'scene.target.sprite', (scene['target']! as Map<String, Object?>)['sprite']);
        checkVo(file, 'answerPrompt.vo', (a['answerPrompt']! as Map<String, Object?>)['vo']);
        _options(file, answer, say, checkTag);
        final Map<String, Object?>? right = _correctOption(answer);
        if (right != null && right['value'] != objects['count']) {
          say(
            file,
            'answer.correct',
            'the correct option must show the number of objects (${objects['count']})',
          );
        }
        final Set<Object?> values = <Object?>{
          for (final Map<String, Object?> o in _maps(answer['options'])) o['value'],
        };
        if (values.length != _maps(answer['options']).length) {
          say(file, 'answer.options', 'two options show the same number');
        }
        for (final (int i, Map<String, Object?> c) in _maps(a['traceClassifiers']).indexed) {
          checkTag(file, 'traceClassifiers[$i].misconception', c['misconception']);
        }
        // Counting is where the misconceptions show: a wrong answer that is nothing in particular teaches nothing.
        if (!_maps(answer['options']).any((Map<String, Object?> o) => o['misconception'] != null)) {
          say(file, 'answer.options', 'at least one wrong answer must name the misconception it shows');
        }
      case 'number_line':
        checkAsset(file, 'scene.background', scene['background']);
        checkAsset(file, 'scene.markerSprite', scene['markerSprite']);
        final int lineFrom = scene['from']! as int;
        final int lineTo = scene['to']! as int;
        if (lineFrom >= lineTo) say(file, 'scene.to', 'must be larger than from');
        bool onLine(int n) => n >= lineFrom && n <= lineTo;
        final int target = answer['target']! as int;
        if (!onLine(target)) say(file, 'answer.target', 'is not on the line');
        for (final (int i, Object? l) in (scene['labels']! as List<Object?>).indexed) {
          if (!onLine(l! as int)) say(file, 'scene.labels[$i]', 'is not on the line');
        }
        if (answer['mode'] == 'jump') {
          final int? from = scene['start'] as int?;
          final List<Object?> hops = (scene['hops'] as List<Object?>?) ?? const <Object?>[];
          if (from == null || hops.isEmpty || !onLine(from)) {
            say(file, 'scene.start', 'a jump needs a start on the line and at least one hop');
          } else {
            int at = from;
            for (final Object? h in hops) {
              at += h! as int;
              if (!onLine(at)) {
                say(file, 'scene.hops', 'the marker leaves the line');
                break;
              }
            }
            if (at != target) say(file, 'answer.target', 'is not where the hops end ($at)');
          }
        }
        checkTag(file, 'answer.misconception', answer['misconception']);
        checkTag(file, 'answer.mirrorMisconception', answer['mirrorMisconception']);
      case 'balance':
        checkAsset(file, 'scene.background', scene['background']);
        checkAsset(file, 'scene.blockSprite', scene['blockSprite']);
        int panWeight(Object? pan, String path) {
          int total = 0;
          for (final (int i, Map<String, Object?> g) in _maps(
            (pan! as Map<String, Object?>)['groups'],
          ).indexed) {
            checkAsset(file, '$path.groups[$i].sprite', g['sprite']);
            total += (g['count']! as int) * ((g['weight'] as int?) ?? 1);
          }
          return total;
        }
        final int wl = panWeight(scene['left'], 'scene.left');
        final int wr = panWeight(scene['right'], 'scene.right');
        final String result = answer['result']! as String;
        if (answer['mode'] == 'balance') {
          if (scene['blockSprite'] == null) {
            say(file, 'scene.blockSprite', 'a balance task needs the picture of the blocks');
          }
          if (result != '${wl - wr}' || wl - wr < 1) {
            say(
              file,
              'answer.result',
              'must be the number of blocks that make it level (${wl - wr}, at least 1)',
            );
          }
        } else {
          final String truth = wl == wr ? 'same' : (wl > wr ? 'left' : 'right');
          if (result != truth) say(file, 'answer.result', 'is not what the pans weigh ($truth)');
        }
        checkTag(file, 'answer.misconception', answer['misconception']);
      case 'spot_error':
        checkAsset(file, 'scene.background', scene['background']);
        final List<Object?> cells = scene['cells']! as List<Object?>;
        for (final (int i, Object? c) in cells.indexed) {
          if (c is String && c.startsWith('asset:')) checkAsset(file, 'scene.cells[$i]', c);
        }
        if ((answer['wrong']! as int) >= cells.length) say(file, 'answer.wrong', 'is not a cell of the row');
        checkTag(file, 'answer.misconception', answer['misconception']);
      case 'shape_builder':
        checkAsset(file, 'scene.background', scene['background']);
        final List<Map<String, Object?>> slots = _maps(scene['slots']);
        final Set<Object?> slotSprites = <Object?>{for (final Map<String, Object?> s in slots) s['sprite']};
        for (final (int i, Map<String, Object?> s) in slots.indexed) {
          checkAsset(file, 'scene.slots[$i].sprite', s['sprite']);
          final double x = (s['x']! as num).toDouble();
          final double y = (s['y']! as num).toDouble();
          if (x + (s['w']! as num) > 1.001 || y + (s['h']! as num) > 1.001) {
            say(file, 'scene.slots[$i]', 'reaches outside the picture');
          }
        }
        for (final (int i, Object? d) in ((scene['decoys'] as List<Object?>?) ?? const <Object?>[]).indexed) {
          checkAsset(file, 'scene.decoys[$i]', d);
          if (slotSprites.contains(d)) {
            say(file, 'scene.decoys[$i]', 'is a shape that belongs in the picture');
          }
        }
        checkTag(file, 'answer.misconception', answer['misconception']);
      case 'robot_path':
        checkAsset(file, 'scene.background', scene['background']);
        checkAsset(file, 'scene.robotSprite', scene['robotSprite']);
        checkAsset(file, 'scene.goalSprite', scene['goalSprite']);
        final int cols = scene['cols']! as int;
        final int rows = scene['rows']! as int;
        final Map<String, Object?> robot = scene['robot']! as Map<String, Object?>;
        final Map<String, Object?> goal = scene['goal']! as Map<String, Object?>;
        bool inside(int c, int r) => c >= 0 && c < cols && r >= 0 && r < rows;
        if (!inside(robot['col']! as int, robot['row']! as int)) {
          say(file, 'scene.robot', 'is outside the grid');
        }
        if (!inside(goal['col']! as int, goal['row']! as int)) say(file, 'scene.goal', 'is outside the grid');
        int c = robot['col']! as int;
        int r = robot['row']! as int;
        final List<Object?> way = answer['solution']! as List<Object?>;
        for (final Object? step in way) {
          switch (step) {
            case 'up':
              r--;
            case 'down':
              r++;
            case 'left':
              c--;
            case 'right':
              c++;
          }
          if (!inside(c, r)) {
            say(file, 'answer.solution', 'walks the robot off the grid');
            break;
          }
        }
        if (c != goal['col'] || r != goal['row']) say(file, 'answer.solution', 'does not end at the flag');
        if (way.length > (answer['maxSteps']! as int)) {
          say(file, 'answer.solution', 'is longer than maxSteps');
        }
        checkTag(file, 'answer.misconception', answer['misconception']);
      case 'sort_drag':
        checkAsset(file, 'scene.background', scene['background']);
        final List<Map<String, Object?>> bins = _maps(scene['bins']);
        final Set<Object?> binIds = <Object?>{for (final Map<String, Object?> b in bins) b['id']};
        for (final (int i, Map<String, Object?> b) in bins.indexed) {
          checkAsset(file, 'scene.bins[$i].sprite', b['sprite']);
        }
        final bool share = answer['mode'] == 'share';
        final List<Map<String, Object?>> items = _maps(scene['items']);
        for (final (int i, Map<String, Object?> it) in items.indexed) {
          checkAsset(file, 'scene.items[$i].sprite', it['sprite']);
          if (!share && !binIds.contains(it['bin'])) {
            say(file, 'scene.items[$i].bin', 'must be the id of a bin');
          }
        }
        if (share && (bins.length != 2 || items.length.isOdd)) {
          say(file, 'scene', 'sharing is between two bins and needs an even number of pictures');
        }
        checkTag(file, 'answer.misconception', answer['misconception']);
      case 'build_pattern':
        checkAsset(file, 'scene.background', scene['background']);
        final List<Object?> palette = scene['palette']! as List<Object?>;
        for (final (int i, Object? p) in palette.indexed) {
          checkAsset(file, 'scene.palette[$i]', p);
        }
        for (final (int i, Object? m) in ((scene['model'] as List<Object?>?) ?? const <Object?>[]).indexed) {
          checkAsset(file, 'scene.model[$i]', m);
        }
        final List<Object?> sequence = answer['sequence']! as List<Object?>;
        if (sequence.length != scene['slots']) {
          say(
            file,
            'answer.sequence',
            'must have exactly as many pictures as there are places (${scene['slots']})',
          );
        }
        for (final (int i, Object? p) in sequence.indexed) {
          if (!palette.contains(p)) say(file, 'answer.sequence[$i]', 'is not in the palette');
        }
        checkTag(file, 'answer.misconception', answer['misconception']);
      case 'flash':
        checkAsset(file, 'scene.background', scene['background']);
        final Map<String, Object?> group = scene['group']! as Map<String, Object?>;
        checkAsset(file, 'scene.group.sprite', group['sprite']);
        _options(file, answer, say, checkTag);
        if (_correctOption(answer)?['numeral'] != group['count']) {
          say(
            file,
            'answer.correct',
            'the correct option must show the number of things flashed (${group['count']})',
          );
        }
        final List<Object?> numerals = <Object?>[
          for (final Map<String, Object?> o in _maps(answer['options'])) o['numeral'],
        ];
        if (numerals.toSet().length != numerals.length) {
          say(file, 'answer.options', 'two options show the same number');
        }
      case 'give_n':
        checkAsset(file, 'scene.background', scene['background']);
        final Map<String, Object?> source = scene['source']! as Map<String, Object?>;
        checkAsset(file, 'scene.source.sprite', source['sprite']);
        checkAsset(file, 'scene.target.sprite', (scene['target']! as Map<String, Object?>)['sprite']);
        if ((answer['n']! as int) > (source['count']! as int)) {
          say(file, 'answer.n', 'cannot be more than the ${source['count']} objects in the jar');
        }
        for (final (int i, Map<String, Object?> c) in _maps(answer['classifiers']).indexed) {
          checkTag(file, 'answer.classifiers[$i].misconception', c['misconception']);
        }
    }
    _hebrew(file, a, say, pointed: a['band'] != 'C');
  });

  lessons.forEach((String id, Map<String, Object?> l) {
    final String file = 'lesson.$id.json';
    for (final (int i, Object? item) in (l['items']! as List<Object?>).indexed) {
      if (!activityIds.contains(item)) say(file, 'items[$i]', 'there is no activity "$item" in this pack');
    }
    for (final (int i, Object? s) in (l['skills']! as List<Object?>).indexed) {
      checkSkill(file, 'skills[$i]', s);
    }
    final Map<String, Object?> cel = l['celebration']! as Map<String, Object?>;
    checkVo(file, 'celebration.vo', cel['vo']);
    _hebrew(file, l, say, pointed: l['band'] != 'C');
  });

  skills.forEach((String id, Map<String, Object?> s) {
    final String file = 'skill.$id.json';
    for (final (int i, Map<String, Object?> p) in _maps(s['prerequisites']).indexed) {
      if (p['skill'] == id) say(file, 'prerequisites[$i].skill', 'a skill cannot need itself');
    }
    for (final (int i, Object? t) in (s['misconceptions']! as List<Object?>).indexed) {
      checkTag(file, 'misconceptions[$i]', t);
    }
  });

  tags.forEach((String id, Map<String, Object?> t) {
    final String file = 'misconception.$id.json';
    for (final (int i, Object? s) in (t['skills']! as List<Object?>).indexed) {
      checkSkill(file, 'skills[$i]', s);
    }
    for (final (int i, Object? r) in (t['repairActivities']! as List<Object?>).indexed) {
      if (!activityIds.contains(r)) {
        say(file, 'repairActivities[$i]', 'there is no activity "$r" in this pack');
      }
    }
  });

  // ---- characters ----
  characters.forEach((String id, Map<String, Object?> c) {
    final String file = 'character.$id.json';
    final Map<String, Object?> images = c['images']! as Map<String, Object?>;
    for (final MapEntry<String, Object?> i in images.entries) {
      checkAsset(file, 'images.${i.key}', i.value);
    }
    final bool personal = c['distribution'] == 'personal';
    if (c['personalUseOnly'] != personal) {
      say(file, 'personalUseOnly', 'must be true exactly when distribution is "personal"');
    }
    final Map<String, Object?> name = c['name']! as Map<String, Object?>;
    _line(
      (name['he']! as String).replaceAll('{name}', ''),
      'name.he',
      say,
      file,
      true,
      allowNoHebrew: (name['he']! as String).replaceAll('{name}', '').trim().isEmpty,
    );
  });

  // ---- mouth cues ----
  cues.forEach((String id, Map<String, Object?> c) {
    final String file = 'cue.$id.json';
    if (!voFiles.containsKey(id)) say(file, 'id', 'there is no recorded voice line "$id" in the manifest');
    int last = -1;
    for (final (int i, Map<String, Object?> q) in _maps(c['cues']).indexed) {
      final int t = q['t']! as int;
      if (t <= last) say(file, 'cues[$i].t', 'times must increase');
      last = t;
    }
  });
  if (voFiles.isNotEmpty) {
    for (final String id in voFiles.keys) {
      if (!cueIds.contains(id)) {
        say('manifest.json', 'vo', 'the voice line "$id" has no mouth-cue file cue.$id.json');
      }
    }
  }

  return out;
}

List<Map<String, Object?>> _maps(Object? v) => <Map<String, Object?>>[
  for (final Object? e in (v as List<Object?>? ?? const <Object?>[])) e! as Map<String, Object?>,
];

Map<String, Object?>? _correctOption(Map<String, Object?> answer) {
  for (final Map<String, Object?> o in _maps(answer['options'])) {
    if (o['id'] == answer['correct']) return o;
  }
  return null;
}

void _options(
  String file,
  Map<String, Object?> answer,
  void Function(String, String, String) say,
  void Function(String, String, Object?) checkTag, {
  void Function(String, String, Object?)? checkAsset,
}) {
  if (_correctOption(answer) == null) say(file, 'answer.correct', 'is not the id of any option');
  for (final (int i, Map<String, Object?> o) in _maps(answer['options']).indexed) {
    checkTag(file, 'answer.options[$i].misconception', o['misconception']);
    checkAsset?.call(file, 'answer.options[$i].sprite', o['sprite']);
    if (o['id'] == answer['correct'] && o['misconception'] != null) {
      say(file, 'answer.options[$i].misconception', 'the correct option cannot carry a misconception');
    }
  }
}

/// How much a child can be asked to hear at once: a question of at most 14 words, any other line of at most 24, and no
/// markup characters in a caption (maths is written as tokens, never as `<` or `>`).
void _lengths(String file, Map<String, Object?> a, void Function(String, String, String) say) {
  int words(Object? caption) {
    final List<Map<String, Object?>> c = _maps(caption);
    return c.isEmpty
        ? 0
        : (c.first['v']! as String).split(RegExp(r'\s+')).where((String w) => w.isNotEmpty).length;
  }

  void atMost(String path, Object? caption, int limit) {
    final int n = words(caption);
    if (n > limit) say(file, path, 'has $n words; a line the child hears is at most $limit words');
  }

  final Map<String, Object?> prompt = a['prompt']! as Map<String, Object?>;
  atMost('prompt.caption', prompt['caption'], 14);
  final Object? answerPrompt = a['answerPrompt'];
  if (answerPrompt is Map<String, Object?>) atMost('answerPrompt.caption', answerPrompt['caption'], 14);
  final Map<String, Object?> fb = a['feedback']! as Map<String, Object?>;
  atMost('feedback.correct.caption', (fb['correct']! as Map<String, Object?>)['caption'], 24);
  for (final (int i, Map<String, Object?> r) in _maps(fb['incorrect']).indexed) {
    atMost('feedback.incorrect[$i].caption', r['caption'], 24);
  }
  for (final (int i, Map<String, Object?> h) in _maps(a['hints']).indexed) {
    atMost('hints[$i].caption', h['caption'], 24);
  }
}

/// What an option looks like, as text, to find two that are the same.
String _look(Map<String, Object?> o) {
  final Object? set = o['set'];
  final List<String> parts = <String>[
    if (set is Map<String, Object?>)
      for (final MapEntry<String, Object?> e in set.entries) '${e.key}=${e.value}',
  ]..sort();
  return '${o['sprite']}|${o['numeral']}|${parts.join(',')}';
}

final RegExp _jsonName = RegExp(r'^([a-z]+)\.(.+)\.json$');
String _range(int from, int to) => '${String.fromCharCode(from)}-${String.fromCharCode(to)}';

// Letters U+05D0 to U+05EA, points U+05B0 to U+05C7; geresh, gershayim and maqaf may sit inside a word.
// Built from code points so this file holds no Hebrew text (that lives in strings/he.dart).
final String _letters = _range(0x05D0, 0x05EA);
final String _points = _range(0x05B0, 0x05C7);
final RegExp _hebrewWord = RegExp(
  '[$_letters][$_points$_letters${String.fromCharCodes(<int>[0x05F3, 0x05F4, 0x05BE])}]*',
);
final RegExp _niqqud = RegExp('[$_points]');
final RegExp _latin = RegExp('[A-Za-z]');

/// The house rules for child-facing Hebrew: Hebrew only, no Latin letters, and in Bands A and B
/// every word of two letters or more carries niqqud.
void _hebrew(
  String file,
  Map<String, Object?> doc,
  void Function(String, String, String) say, {
  required bool pointed,
}) {
  void walk(Object? node, String path) {
    if (node is Map<String, Object?>) {
      node.forEach((String k, Object? v) {
        if (k == 'caption' || k == 'title') {
          for (final (int i, Map<String, Object?> c) in _maps(v).indexed) {
            _line(c['v'], '$path$k[$i].v', say, file, pointed);
          }
        } else {
          walk(v, '$path$k.');
        }
      });
    } else if (node is List<Object?>) {
      for (final (int i, Object? e) in node.indexed) {
        walk(e, '${path.substring(0, path.isEmpty ? 0 : path.length - 1)}[$i].');
      }
    }
  }

  walk(doc, '');
}

void _line(
  Object? text,
  String path,
  void Function(String, String, String) say,
  String file,
  bool pointed, {
  bool allowNoHebrew = false,
}) {
  if (text is! String) return;
  if (_latin.hasMatch(text)) say(file, path, 'contains Latin letters; the child space is Hebrew only');
  if (text.contains('<') || text.contains('>')) {
    say(file, path, 'contains < or >, which turn over in right-to-left text; write maths as a token');
  }
  if (!_hebrewWord.hasMatch(text) && !allowNoHebrew) say(file, path, 'contains no Hebrew');
  if (!pointed) return;
  for (final RegExpMatch m in _hebrewWord.allMatches(text)) {
    final String word = m.group(0)!;
    final int letters = word.runes.where((int r) => r >= 0x05D0 && r <= 0x05EA).length;
    if (letters >= 2 && !_niqqud.hasMatch(word)) {
      say(file, path, 'the word "$word" has no niqqud (Bands A and B are fully pointed)');
    }
  }
}
