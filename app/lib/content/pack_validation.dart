import 'dart:math' as math;

import '../engine/course.dart';
import '../speech/answer_matcher.dart';
import '../speech/hebrew_text.dart';
import '../speech/lexicon.dart';
import '../speech/spoken_options.dart';
import '../speech/word_text.dart' show normalizeWords;
import 'block_geometry.dart';
import 'capabilities.dart' show compareTemplateVersion;
import 'hint_ladder.dart';
import 'language_checks.dart';
import 'ls01_checks.dart';
import 'l5_hint_checks.dart';
import 'ls02_checks.dart';
import 'ls03_checks.dart';
import 'ls04_checks.dart';
import 'ls05_checks.dart';
import 'row_width.dart';
import 'schema.dart';
import 'schemas.dart';
import 'scripts.dart';

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
  final String course = (manifest['course'] as String?) ?? Course.core;
  _packCourse(course, manifest['id']! as String, say);

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
  final Map<String, Map<String, Object?>> gates = <String, Map<String, Object?>>{};
  final Map<String, Map<String, Object?>> placements = <String, Map<String, Object?>>{};
  // Every id that has a file, even one that failed its schema; only valid documents are cross-checked.
  final Set<String> activityIds = <String>{};
  final Set<String> lessonIds = <String>{};
  final Set<String> skillIds = <String>{};
  final Set<String> tagIds = <String>{};
  final Set<String> gateIds = <String>{};
  final Set<String> placementIds = <String>{};
  final Map<String, Map<String, Object?>> characters = <String, Map<String, Object?>>{};
  final Set<String> characterIds = <String>{};
  final Map<String, Map<String, Object?>> cues = <String, Map<String, Object?>>{};
  final Set<String> cueIds = <String>{};
  final Map<String, Map<String, Object?>> strokeSets = <String, Map<String, Object?>>{};
  final Set<String> strokeIds = <String>{};

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
        final Object? version = doc['templateVersion'];
        final Schema? s = template is String
            ? activitySchemaFor(template, version: version is String ? version : null)
            : null;
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
      case 'gate':
        gateIds.add(middle);
        final List<Problem> found = validate(gateSchema, doc);
        for (final Problem p in found) {
          add(name, p);
        }
        if (doc['id'] != middle) say(name, 'id', 'must equal "$middle", the middle of the file name');
        if (found.isEmpty) gates[middle] = doc;
      case 'placement':
        placementIds.add(middle);
        final List<Problem> found = validate(placementSchema, doc);
        for (final Problem p in found) {
          add(name, p);
        }
        if (doc['id'] != middle) say(name, 'id', 'must equal "$middle", the middle of the file name');
        if (found.isEmpty) placements[middle] = doc;
      case 'character':
        characterIds.add(middle);
        final List<Problem> found = validate(characterSchema, doc);
        for (final Problem p in found) {
          add(name, p);
        }
        if (doc['id'] != middle) say(name, 'id', 'must equal "$middle", the middle of the file name');
        if (found.isEmpty) characters[middle] = doc;
      case 'strokes':
        strokeIds.add(middle);
        final List<Problem> found = validate(strokesSchema, doc);
        for (final Problem p in found) {
          add(name, p);
        }
        if (doc['set'] != middle) say(name, 'set', 'must equal "$middle", the middle of the file name');
        if (!Course.isLanguage(course)) {
          say(name, '', 'belongs to a language course: the lands have no stroke sets');
        } else if (found.isEmpty) {
          checkStrokeSet(name, doc, course: course, say: say);
        }
        if (found.isEmpty) strokeSets[middle] = doc;
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
  sameSet('gates', gateIds);
  sameSet('placements', placementIds);
  sameSet('characters', characterIds);
  sameSet('cues', cueIds);
  sameSet('strokes', strokeIds);

  // ---- the manifest must promise every template an activity uses ----
  final Map<String, Object?> templates = manifest['templates']! as Map<String, Object?>;
  activities.forEach((String id, Map<String, Object?> a) {
    final String t = a['template']! as String;
    final Object? promised = templates[t];
    if (promised == null) {
      say('manifest.json', 'templates', 'does not list "$t", which activity $id uses');
    } else if (promised is String && compareTemplateVersion('${a['templateVersion']}', promised) > 0) {
      // SEC-M10-5: an app that has the manifest's version must be able to play what the activity says it needs.
      say(
        'activity.$id.json',
        'templateVersion',
        'is ${a['templateVersion']}, above the $promised the manifest lists for "$t"',
      );
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
    // The first skill is the one the activity teaches; its band is the activity's band.
    final List<Map<String, Object?>> taught = _maps(a['skills']);
    final Object? taughtBand = taught.isEmpty ? null : skills[taught.first['id']]?['band'];
    if (taughtBand != null && taughtBand != a['band']) {
      say(file, 'band', 'is ${a['band']}, but its skill ${taught.first['id']} is in band $taughtBand');
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
    // The ladder (B-40): the first two hints must not be the worked example, level 3 must differ from level 2, and what the
    // template draws at each level must not mark the answer before level 3.
    for (final (int i, Map<String, Object?> h) in hints.indexed) {
      if (i < 2 && h['action'] == 'worked_example') {
        say(file, 'hints[$i].action', 'the worked example shows the answer, so it belongs at level 3 only');
      }
    }
    if (hints.length >= 3 && hints[2]['action'] == hints[1]['action']) {
      say(file, 'hints[2].action', 'level 3 must help in a different way than level 2');
    }
    final String? ladder = a['template'] == 'say_it'
        ? null
        : HintLadder.problemWith(
            a['template']! as String,
            share: a['template'] == 'sort_drag' && (a['answer'] as Map<String, Object?>?)?['mode'] == 'share',
          );
    if (ladder != null) say(file, 'hints', ladder);
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
        if (answer['type'] == 'number') {
          _numberAnswer(file, answer, say, checkTag);
        } else {
          _choiceAnswer(file, a, answer, say);
          _options(file, answer, say, checkTag, checkAsset: checkAsset);
        }
        _stagePictureOf(file, scene['picture'], say);
        _stagePictureOf(file, scene['picture2'], say, path: 'scene.picture2', blocksOnly: true);
        if (scene['picture2'] != null && (scene['picture'] as Map<String, Object?>?)?['kind'] != 'base_ten') {
          say(file, 'scene.picture2', 'a second picture needs a first, and both are blocks (base_ten)');
        }
        for (final (int i, Map<String, Object?> o) in _maps(answer['options']).indexed) {
          _stagePictureOf(file, o['picture'], say, path: 'answer.options[$i].picture', blocksOnly: true);
        }
        if (!blockLimitWaivers.contains(a['id'])) {
          for (final String problem in blockLimits(scene, answer)) {
            final int colon = problem.indexOf(': ');
            say(
              file,
              colon < 0 ? 'scene' : problem.substring(0, colon),
              colon < 0 ? problem : problem.substring(colon + 2),
            );
          }
        }
        _tapVersion(file, a, scene, answer, say);
        _tapBigNumbers(file, a, scene, answer, say);
        _tapRowWidth(file, scene, say);
        _promptMath(file, a, scene, say);
        for (final (int i, Object? r) in ((scene['row'] as List<Object?>?) ?? const <Object?>[]).indexed) {
          if (r is String && r.startsWith('asset:')) checkAsset(file, 'scene.row[$i]', r);
        }
        for (final (int i, Map<String, Object?> c) in _maps(scene['chart']).indexed) {
          checkAsset(file, 'scene.chart[$i].sprite', c['sprite']);
        }
        for (final String g in <String>['group', 'group2']) {
          final Object? group = scene[g];
          if (group is Map<String, Object?>) checkAsset(file, 'scene.$g.sprite', group['sprite']);
        }
        for (final (int i, Map<String, Object?> o) in _maps(answer['options']).indexed) {
          _optionKind(file, 'answer.options[$i]', o, say, language: Course.isLanguage(course));
          checkVo(file, 'answer.options[$i].clip', o['clip']);
          final Object? set = o['set'];
          if (set is Map<String, Object?>) checkAsset(file, 'answer.options[$i].set.sprite', set['sprite']);
        }
        // Two answers that look the same cannot be told apart by a child.
        final List<String> looks = <String>[
          for (final Map<String, Object?> o in _maps(answer['options'])) _look(o),
        ];
        // A tap-all repeats a card (three t's among other letters); ls01_checks.dart holds it to its own rule.
        if (answer['all'] != true && looks.toSet().length != looks.length) {
          say(file, 'answer.options', 'two options look the same');
        }
      case 'story':
        checkAsset(file, 'scene.background', scene['background']);
        _story(file, a, say, checkAsset: checkAsset, checkVo: checkVo, checkTag: checkTag);
      case 'listen_do':
        checkAsset(file, 'scene.background', scene['background']);
        _listenDo(file, a, say, checkAsset: checkAsset, checkVo: checkVo, checkTag: checkTag);
      case 'sing_along':
        checkAsset(file, 'scene.background', scene['background']);
        _singAlong(file, a, say, checkAsset: checkAsset, checkVo: checkVo, checkTag: checkTag);
      case 'puppet_talk':
        checkAsset(file, 'scene.background', scene['background']);
        _puppetTalk(file, a, say, checkAsset: checkAsset, checkVo: checkVo, checkTag: checkTag);
      case 'sound_boxes' when isBoxes(a):
        // LS03 boxes: the steps, the units and the keys of `classify` are `ls03_checks.dart`'s; here only what a file of the pack can point at.
        checkAsset(file, 'scene.background', scene['background']);
        final Map<String, Object?> boxWord = _mapOf(scene['word']);
        checkAsset(file, 'scene.word.sprite', boxWord['sprite']);
        checkVo(file, 'scene.word.clip', boxWord['clip']);
        checkVo(file, 'scene.word.slow', boxWord['slow']);
        checkVo(file, 'scene.tok', scene['tok']);
        for (final (int i, Map<String, Object?> u) in _maps(boxWord['units']).indexed) {
          checkVo(file, 'scene.word.units[$i].clip', u['clip']);
          checkAsset(file, 'scene.word.units[$i].mouth', u['mouth']);
        }
        for (final MapEntry<String, Object?> c in _mapOf(answer['classify']).entries) {
          checkTag(file, 'answer.classify.${c.key}', c.value);
        }
      case 'change_part':
        checkAsset(file, 'scene.background', scene['background']);
        for (final (int i, Map<String, Object?> p) in _maps(scene['parts']).indexed) {
          checkTag(file, 'scene.parts[$i].tag', p['tag']);
        }
        for (final (int i, Map<String, Object?> r) in _maps(scene['results']).indexed) {
          checkVo(file, 'scene.results[$i].clip', r['clip']);
          checkAsset(file, 'scene.results[$i].sprite', r['sprite']);
        }
        if (scene['mode'] == 'explore') _unscored(file, a, say, 'a teaching screen');
      case 'blend_slide':
        checkAsset(file, 'scene.background', scene['background']);
        final Map<String, Object?> blendWord = _mapOf(scene['word']);
        checkVo(file, 'scene.word.whole', blendWord['whole']);
        checkVo(file, 'scene.word.stretched', blendWord['stretched']);
        for (final (int i, Map<String, Object?> p) in _maps(blendWord['parts']).indexed) {
          checkVo(file, 'scene.word.parts[$i].clip', p['clip']);
          checkAsset(file, 'scene.word.parts[$i].mouth', p['mouth']);
        }
        _l4Options(file, answer, say, checkAsset, checkVo, checkTag, faceless: scene['mode'] == 'merge');
      case 'sound_boxes':
        checkAsset(file, 'scene.background', scene['background']);
        checkAsset(file, 'scene.picture', scene['picture']);
        for (final String k in <String>['word', 'slow']) {
          for (final (int i, Object? c) in ((scene[k] as List<Object?>?) ?? const <Object?>[]).indexed) {
            checkVo(file, 'scene.$k[$i]', c);
          }
        }
        checkVo(file, 'scene.drum', scene['drum']);
        for (final (int i, Map<String, Object?> c) in _maps(answer['classifiers']).indexed) {
          checkTag(file, 'answer.classifiers[$i].misconception', c['misconception']);
        }
        // A free response is evidence of one thing only: whether the child can count the parts. It is never the check of a skill alone.
        if (a['purpose'] == 'check') {
          say(file, 'purpose', 'a drum item is never a check: its answer is free, with no distractors');
        }
      case 'count_tap':
        checkAsset(file, 'scene.background', scene['background']);
        final Map<String, Object?> objects = scene['objects']! as Map<String, Object?>;
        checkAsset(file, 'scene.objects.sprite', objects['sprite']);
        checkAsset(file, 'scene.objects.litSprite', objects['litSprite']);
        checkAsset(file, 'scene.target.sprite', (scene['target']! as Map<String, Object?>)['sprite']);
        checkVo(file, 'answerPrompt.vo', (a['answerPrompt']! as Map<String, Object?>)['vo']);
        _options(file, answer, say, checkTag);
        for (final (int i, Map<String, Object?> o) in _maps(answer['options']).indexed) {
          checkVo(file, 'answer.options[$i].clip', o['clip']);
        }
        for (final (int i, Object? c)
            in ((objects['clips'] as List<Object?>?) ?? const <Object?>[]).indexed) {
          checkVo(file, 'scene.objects.clips[$i]', c);
        }
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
        if ((scene['tickStep'] != null || answer['tolerance'] != null) &&
            compareTemplateVersion('${a['templateVersion']}', '1.1') < 0) {
          say(
            file,
            'templateVersion',
            'is ${a['templateVersion']}, but a tick step or a tolerance needs number_line 1.1',
          );
        }
        final int step = (scene['tickStep'] as int?) ?? 1;
        if ((lineTo - lineFrom) % step != 0) {
          say(file, 'scene.tickStep', 'the line from $lineFrom to $lineTo does not end on a tick of $step');
        }
        final int tolerance = (answer['tolerance'] as int?) ?? 0;
        if (tolerance > 0 && answer['mode'] == 'jump') {
          say(file, 'answer.tolerance', 'only a place item has a tolerance');
        }
        if (tolerance >= lineTo - lineFrom) say(file, 'answer.tolerance', 'is as wide as the line');
        if (tolerance > 0 &&
            answer['mirrorMisconception'] != null &&
            (lineFrom + lineTo - target - target).abs() <= 2 * tolerance) {
          say(file, 'answer.mirrorMisconception', 'the mirror of the answer is inside the tolerance');
        }
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
        _spotVersion(file, a, scene, cells, say);
        _spotBigNumbers(file, a, cells, say);
      case 'match_pairs':
        checkAsset(file, 'scene.background', scene['background']);
        final List<Map<String, Object?>> leftFaces = _maps(scene['left']);
        final List<Map<String, Object?>> rightFaces = _maps(scene['right']);
        final Set<Object?> faceIds = <Object?>{};
        for (final (String side, List<Map<String, Object?>> faces) in <(String, List<Map<String, Object?>>)>[
          ('left', leftFaces),
          ('right', rightFaces),
        ]) {
          for (final (int i, Map<String, Object?> f) in faces.indexed) {
            if (!faceIds.add(f['id'])) say(file, 'scene.$side[$i].id', 'is used twice');
            // A face of a language course may also be a text, or only a sound (a sound card); the lands have neither (ls01_checks.dart).
            final int shown = <Object?>[
              f['sprite'],
              f['numeral'],
              f['coin'],
              f['text'],
            ].where((Object? x) => x != null).length;
            final bool soundCard = shown == 0 && f['clip'] != null && Course.isLanguage(course);
            if (shown > 1 || (shown == 0 && !soundCard)) {
              say(
                file,
                'scene.$side[$i]',
                Course.isLanguage(course)
                    ? 'needs exactly one of a picture, a numeral, a coin or a text, or only a clip (a sound card)'
                    : 'needs exactly one of a picture, a numeral or a coin',
              );
            }
            if (f['sprite'] != null) checkAsset(file, 'scene.$side[$i].sprite', f['sprite']);
            checkVo(file, 'scene.$side[$i].clip', f['clip']);
            checkTag(file, 'scene.$side[$i].misconception', f['misconception']);
          }
        }
        if (leftFaces.length != rightFaces.length) {
          say(file, 'scene.right', 'must have as many faces as the left');
        }
        final List<Map<String, Object?>> pairs = _maps(answer['pairs']);
        final Set<Object?> usedLeft = <Object?>{};
        final Set<Object?> usedRight = <Object?>{};
        for (final (int i, Map<String, Object?> p) in pairs.indexed) {
          if (!leftFaces.any((Map<String, Object?> f) => f['id'] == p['left'])) {
            say(file, 'answer.pairs[$i].left', 'is not a face of the top row');
          }
          if (!rightFaces.any((Map<String, Object?> f) => f['id'] == p['right'])) {
            say(file, 'answer.pairs[$i].right', 'is not a face of the bottom row');
          }
          if (!usedLeft.add(p['left']) || !usedRight.add(p['right'])) {
            say(file, 'answer.pairs[$i]', 'uses a face twice');
          }
        }
        if (pairs.length != leftFaces.length) say(file, 'answer.pairs', 'must pair every face');
        checkTag(file, 'answer.misconception', answer['misconception']);
      case 'shop_pay':
        checkAsset(file, 'scene.background', scene['background']);
        checkAsset(file, 'scene.itemSprite', scene['itemSprite']);
        Set<int> reach = <int>{0};
        for (final (int i, Map<String, Object?> p) in _maps(scene['purse']).indexed) {
          final String kind = p['kind']! as String;
          checkAsset(file, 'scene.purse[$i].kind', 'asset:${coinSprites[kind]}');
          final Set<int> next = <int>{...reach};
          for (int k = 1; k <= (p['count']! as int); k++) {
            for (final int r in reach) {
              next.add(r + k * coinValues[kind]!);
            }
          }
          reach = next;
        }
        if (!reach.contains(scene['price'])) {
          say(file, 'scene.price', 'cannot be paid exactly with the purse');
        }
        checkTag(file, 'answer.misconception', answer['misconception']);
        checkTag(file, 'answer.countMisconception', answer['countMisconception']);
      case 'clock_set':
        checkAsset(file, 'scene.background', scene['background']);
        final int minute = scene['minute']! as int;
        if (minute != 0 && minute != 30) say(file, 'scene.minute', 'must be 0 or 30');
        if (scene['startHour'] == scene['hour'] && (scene['startHalf'] == true) == (minute == 30)) {
          say(file, 'scene.startHour', 'the clock already shows the time to set');
        }
        checkTag(file, 'answer.misconception', answer['misconception']);
        checkTag(file, 'answer.handsMisconception', answer['handsMisconception']);
      case 'trace' when isLetterWrite(a):
        // LS02: the modes, forms and classifiers are `ls02_checks.dart`'s; here only what a file of the pack can point at.
        final Object? intro = scene['intro'];
        if (intro is Map<String, Object?>) {
          checkAsset(file, 'scene.intro.picture', intro['picture']);
          for (final String k in <String>['sound', 'keyword', 'name']) {
            checkVo(file, 'scene.intro.$k', intro[k]);
          }
        }
        final Map<String, Object?> classify = _mapOf(answer['classify']);
        for (final String k in <String>['start', 'direction', 'lines', 'mirror']) {
          checkTag(file, 'answer.classify.$k', classify[k]);
        }
        for (final MapEntry<String, Object?> p in _mapOf(classify['partners']).entries) {
          checkTag(file, 'answer.classify.partners.${p.key}', p.value);
        }
        if (scene['mode'] == 'intro') _unscored(file, a, say, 'an introduction');
      case 'trace':
        checkAsset(file, 'scene.background', scene['background']);
        for (final (int i, Object? stroke) in (scene['strokes']! as List<Object?>).indexed) {
          double length = 0;
          final List<Object?> pts = stroke! as List<Object?>;
          for (int k = 1; k < pts.length; k++) {
            final List<Object?> a0 = pts[k - 1]! as List<Object?>;
            final List<Object?> a1 = pts[k]! as List<Object?>;
            final double dx = ((a1[0]! as num) - (a0[0]! as num)).toDouble();
            final double dy = ((a1[1]! as num) - (a0[1]! as num)).toDouble();
            length += math.sqrt(dx * dx + dy * dy);
          }
          if (length < 25) say(file, 'scene.strokes[$i]', 'is too short to trace');
        }
        checkTag(file, 'answer.misconception', answer['misconception']);
        checkTag(file, 'answer.directionMisconception', answer['directionMisconception']);
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
        if (share && (bins.length < 2 || bins.length > 3 || items.length % bins.length != 0)) {
          say(
            file,
            'scene',
            'sharing is between two or three bins and needs a number of pictures that divides evenly',
          );
        }
        checkTag(file, 'answer.misconception', answer['misconception']);
      case 'build_pattern':
        checkAsset(file, 'scene.background', scene['background']);
        final List<Object?> palette = scene['palette']! as List<Object?>;
        // A tile of a language course may be a text (`txt:`) as well as a picture (`asset:`).
        void asset(String path, Object? ref) {
          if (ref is String && ref.startsWith('asset:')) checkAsset(file, path, ref);
        }

        for (final (int i, Object? p) in palette.indexed) {
          asset('scene.palette[$i]', p);
        }
        for (final (int i, Object? m) in ((scene['model'] as List<Object?>?) ?? const <Object?>[]).indexed) {
          asset('scene.model[$i]', m);
        }
        final List<Object?> sequence = (answer['sequence'] as List<Object?>?) ?? const <Object?>[];
        if (answer['order'] == null) {
          if (sequence.isEmpty) {
            say(
              file,
              'answer.sequence',
              'needs the pictures in their right order (`sequence`), or a story line (`order`)',
            );
          } else if (sequence.length != scene['slots']) {
            say(
              file,
              'answer.sequence',
              'must have exactly as many pictures as there are places (${scene['slots']})',
            );
          }
        } else if (sequence.isNotEmpty) {
          say(file, 'answer.sequence', 'a story line is given by `order`: it has no `sequence`');
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
      case 'say_it':
        if (!Course.isLanguage(course)) {
          say(file, 'template', 'say_it is the say-it of a language course; the lands have none');
        }
        checkAsset(file, 'scene.background', scene['background']);
        checkAsset(file, 'scene.picture.sprite', (scene['picture']! as Map<String, Object?>)['sprite']);
        final Map<String, Object?> speak = a['say']! as Map<String, Object?>;
        checkVo(file, 'say.clip', speak['clip']);
        checkVo(file, 'say.heard.vo', (speak['heard']! as Map<String, Object?>)['vo']);
        checkVo(file, 'say.together.vo', (speak['together']! as Map<String, Object?>)['vo']);
        _sayWords(file, a['course'] as String? ?? course, speak, say);
      case 'give_n':
        checkAsset(file, 'scene.background', scene['background']);
        final Map<String, Object?> source = scene['source']! as Map<String, Object?>;
        checkAsset(file, 'scene.source.sprite', source['sprite']);
        checkAsset(file, 'scene.target.sprite', (scene['target']! as Map<String, Object?>)['sprite']);
        if ((answer['n']! as int) > (source['count']! as int)) {
          say(file, 'answer.n', 'cannot be more than the ${source['count']} objects in the jar');
        }
        if (scene['frame'] == true && compareTemplateVersion('${a['templateVersion']}', '1.1') < 0) {
          say(file, 'templateVersion', 'is ${a['templateVersion']}, but a ten-frame target needs give_n 1.1');
        }
        for (final (int i, Map<String, Object?> c) in _maps(answer['classifiers']).indexed) {
          checkTag(file, 'answer.classifiers[$i].misconception', c['misconception']);
        }
    }
    _targetClips(file, a, checkVo);
    checkLs01(
      file,
      a,
      language: Course.isLanguage(course),
      say: say,
      checkAsset: checkAsset,
      checkVo: checkVo,
      checkTag: checkTag,
      familyOf: (String tag) => tags[tag]?['family'] as String?,
    );
    checkLs02Activity(
      file,
      a,
      language: Course.isLanguage(course),
      course: course,
      strokeSets: strokeSets,
      skills: skills,
      tags: <String, TagFacts>{
        for (final MapEntry<String, Map<String, Object?>> t in tags.entries)
          t.key: (family: t.value['family'] as String?, kind: t.value['kind'] as String?),
      },
      say: say,
    );
    checkLs03Activity(file, a, language: Course.isLanguage(course), course: course, skills: skills, say: say);
    checkLs04Activity(file, a, language: Course.isLanguage(course), course: course, say: say);
    checkLs05Activity(file, a, language: Course.isLanguage(course), course: course, say: say);
    checkBorrowedHints(
      file,
      a,
      language: Course.isLanguage(course),
      course: course,
      say: say,
      checkVo: checkVo,
    );
    _languageOnlyTemplate(file, a, say, language: Course.isLanguage(course));
    _hebrew(file, a, say, pointed: a['band'] != 'C');
    _voiceAnswer(file, a, say, starter: manifest['id'] == 'starter');
  });

  lessons.forEach((String id, Map<String, Object?> l) {
    final String file = 'lesson.$id.json';
    for (final (int i, Object? item) in (l['items']! as List<Object?>).indexed) {
      if (!activityIds.contains(item)) say(file, 'items[$i]', 'there is no activity "$item" in this pack');
    }
    for (final (int i, Object? s) in (l['skills']! as List<Object?>).indexed) {
      checkSkill(file, 'skills[$i]', s);
      final Object? band = skills[s]?['band'];
      if (band != null && band != l['band']) {
        say(file, 'skills[$i]', 'the skill $s is in band $band, but the lesson is in band ${l['band']}');
      }
    }
    final Map<String, Object?> cel = l['celebration']! as Map<String, Object?>;
    checkVo(file, 'celebration.vo', cel['vo']);
    final Object? demo = l['demo'];
    if (demo is Map<String, Object?>) {
      checkVo(file, 'demo.vo', demo['vo']);
      if (!(l['items']! as List<Object?>).any((Object? i) => _hasBlocks(activities[i]))) {
        say(
          file,
          'demo',
          'a lesson opens with the demonstration of blocks only when one of its items has blocks',
        );
      }
    }
    _targetClips(file, l, checkVo);
    _hebrew(file, l, say, pointed: l['band'] != 'C');
  });

  skills.forEach((String id, Map<String, Object?> s) {
    final String file = 'skill.$id.json';
    _skillId(file, id, s, say, course: course);
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

  // ---- the placement game of a language course (docs/languages/frame.md section 3.2) ----
  placements.forEach((String id, Map<String, Object?> p) {
    _placement(
      'placement.$id.json',
      id,
      p,
      course: course,
      activities: activities,
      skillIds: skillIds,
      say: say,
      checkVo: checkVo,
    );
    _hebrew('placement.$id.json', p, say, pointed: true);
  });

  // ---- courses never mix (docs/languages/frame.md section 1.5) ----
  _courseRules(
    course: course,
    activities: activities,
    lessons: lessons,
    skills: skills,
    tags: tags,
    skillIds: skillIds,
    gates: gates,
    say: say,
  );
  if (Course.isLanguage(course)) {
    checkLanguageContent(
      course: course,
      activities: activities,
      lessons: lessons,
      skills: skills,
      tags: tags,
      say: say,
    );
    checkLs02Pack(
      course: course,
      activities: activities,
      lessons: lessons,
      skills: skills,
      gates: gates,
      say: say,
    );
  }

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

/// Things in a pack that work but should be looked at: the builder prints them and still signs. Today one kind (board
/// B-24): a spoken answer whose number word starts another option's ("שמונה" and "שמונה עשרה"); the mic waits for the end
/// of the listen there, so a child who stops between the two words is heard as the shorter number.
List<Problem> packWarnings({required Map<String, Object?> docs}) {
  final List<Problem> out = <Problem>[];
  const AnswerMatcher matcher = AnswerMatcher();
  for (final MapEntry<String, Object?> d in docs.entries) {
    final Object? a = d.value;
    if (!d.key.startsWith('activity.') || a is! Map<String, Object?> || a['voiceAnswer'] != true) continue;
    final List<SpokenOption> options = spokenOptions(a);
    final List<Expected> heard = expectedFor(options, correctId: '');
    for (final (int i, Expected e) in heard.indexed) {
      for (final AcceptWord w in e.words) {
        if (isDigits(w.text) || !matcher.couldGoOn(w.text, heard, winnerId: e.id)) continue;
        out.add(
          Problem('${d.key} › answer.options[$i]', 'its spoken number begins the number of another option'),
        );
        break;
      }
    }
  }
  return out;
}

/// The words of a say-it item (`say.forms`, `say.foils`, `say.keyWords`): each is a word of the course's script, no foil is the target
/// or one of its forms once spelling is brought to its plain form (a foil that is the target could never be told from it), and a
/// key word is a word of one of the forms. These words are the hotword list of the recogniser, so they are signed content only.
void _sayWords(
  String file,
  String course,
  Map<String, Object?> speak,
  void Function(String, String, String) say,
) {
  List<String> plain(String key) => <String>[
    for (final Object? w in (speak[key] as List<Object?>? ?? const <Object?>[]))
      normalizeWords(course, w! as String),
  ];
  final List<String> forms = plain('forms');
  final List<String> foils = plain('foils');
  final List<String> keys = plain('keyWords');
  for (final (String key, List<String> words) in <(String, List<String>)>[
    ('forms', forms),
    ('foils', foils),
    ('keyWords', keys),
  ]) {
    for (final (int i, String w) in words.indexed) {
      if (w.isEmpty) {
        say(file, 'say.$key[$i]', 'has no letters of the course\'s script, so nothing could be heard as it');
      }
    }
  }
  for (final (int i, String f) in foils.indexed) {
    if (forms.contains(f)) {
      say(file, 'say.foils[$i]', 'is the target or one of its forms, which no foil may be');
    }
  }
  final Set<String> inForms = <String>{for (final String f in forms) ...f.split(' ')};
  for (final (int i, String k) in keys.indexed) {
    if (k.isNotEmpty && !k.split(' ').every(inForms.contains)) {
      say(file, 'say.keyWords[$i]', 'is not a word of any of the forms');
    }
  }
}

/// The templates whose answer a child can say (board B-24); every other template is answered by hand.
const Set<String> voiceTemplates = <String>{'tap_answer', 'count_tap', 'flash'};

/// The options of a choice as voice sees them (a count_tap option has a `value`, the others a `numeral` or a label).
List<SpokenOption> spokenOptions(Map<String, Object?> activity) => <SpokenOption>[
  for (final Map<String, Object?> o in _maps(_mapOf(activity['answer'])['options']))
    SpokenOption(
      o['id']! as String,
      number: (o['numeral'] ?? o['value']) as int?,
      label: (o['label'] as String?) ?? '',
      speech: <String>[
        for (final Object? s in (o['speech'] as List<Object?>?) ?? const <Object?>[]) s! as String,
      ],
    ),
];

Map<String, Object?> _mapOf(Object? v) => v is Map<String, Object?> ? v : const <String, Object?>{};

/// A spoken answer is offered only where the lesson can hear it (board B-24): a template with a choice, every option with
/// a word of its own, no two options that sound the same, and no yes or no (a "no" is heard as "not", so it is never
/// taken). In the starter pack every activity says whether it is spoken.
void _voiceAnswer(
  String file,
  Map<String, Object?> a,
  void Function(String, String, String) say, {
  required bool starter,
}) {
  final Object? flag = a['voiceAnswer'];
  if (flag == null) {
    if (starter) {
      say(file, 'voiceAnswer', 'every activity of the starter pack must say whether it is answered by voice');
    }
    return;
  }
  if (flag != true) return;
  if (Course.isLanguage((a['course'] as String?) ?? Course.core)) {
    say(
      file,
      'voiceAnswer',
      'a language item is not answered by voice; its speech is the say step of the say_it template, under the language\'s own switch',
    );
    return;
  }
  if (!voiceTemplates.contains(a['template'])) {
    say(
      file,
      'voiceAnswer',
      'a ${a['template']} is answered by hand; only a choice can be answered by voice',
    );
    return;
  }
  final List<SpokenOption> options = spokenOptions(a);
  final List<Expected> heard = expectedFor(options, correctId: _mapOf(a['answer'])['correct']! as String);
  final Set<String> yesNo = <String>{...intentPhrases(Intent.yes), ...intentPhrases(Intent.no)};
  for (final (int i, SpokenOption o) in options.indexed) {
    if (o.number != null) continue;
    if (o.allWords.contains(negationWord) ||
        <String>[o.label, ...o.speech].any((String s) => yesNo.contains(normalizeHebrew(s)))) {
      say(file, 'answer.options[$i]', 'is a yes or a no, which voice cannot take (a "no" is heard as "not")');
    } else if (heard[i].words.isEmpty) {
      say(
        file,
        'answer.options[$i]',
        'has nothing of its own to say: no number, and no word that only it has',
      );
    }
  }
  Set<String> sounds(Expected e) => <String>{
    for (final AcceptWord w in e.words)
      if (!isDigits(w.text)) phoneticKey(w.text),
  };
  for (int i = 0; i < heard.length; i++) {
    for (int j = i + 1; j < heard.length; j++) {
      final bool sameNumber = heard[i].number != null && heard[i].number == heard[j].number;
      if (sameNumber || sounds(heard[i]).intersection(sounds(heard[j])).isNotEmpty) {
        say(
          file,
          'answer.options[$j]',
          'sounds the same as option ${heard[i].id}, so voice cannot tell them apart',
        );
      }
    }
  }
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

/// A choice of a `tap_answer` has its options, the right one, and the two switches; a number answer's fields are not its own.
void _choiceAnswer(
  String file,
  Map<String, Object?> a,
  Map<String, Object?> answer,
  void Function(String, String, String) say,
) {
  for (final String f in <String>['options', 'correct', 'shuffle', 'unsureAllowed']) {
    if (answer[f] == null) say(file, 'answer.$f', 'a choice needs it');
  }
  for (final String f in <String>['value', 'expected', 'rules']) {
    if (answer[f] != null) say(file, 'answer.$f', 'belongs to a number answer, not to a choice');
  }
  // Up to five choices, only in Band C (curriculum: Band A and B keep their caps); a tap-all of a language course has up to five cards in
  // any band (ls01_checks.dart holds it to its own rule, and refuses it in the lands).
  if (_maps(answer['options']).length > 4 && a['band'] != 'C' && answer['all'] != true) {
    say(file, 'answer.options', 'more than four choices belong to Band C');
  }
}

/// A number answer (M10, X3): the child types the number. It has the number itself, and no options; every wrong number the author
/// expects is another number than the right one, listed once, and names a tag; a rule names a tag.
void _numberAnswer(
  String file,
  Map<String, Object?> answer,
  void Function(String, String, String) say,
  void Function(String, String, Object?) checkTag,
) {
  if (answer['value'] == null) say(file, 'answer.value', 'a number answer needs the number');
  for (final String f in <String>['options', 'correct', 'shuffle', 'unsureAllowed']) {
    if (answer[f] != null) {
      say(file, 'answer.$f', 'a number answer has no options: the child types it');
    }
  }
  final Set<Object?> seen = <Object?>{};
  for (final (int i, Map<String, Object?> e) in _maps(answer['expected']).indexed) {
    if (e['value'] == answer['value']) say(file, 'answer.expected[$i].value', 'is the right answer');
    if (!seen.add(e['value'])) say(file, 'answer.expected[$i].value', 'is listed twice');
    checkTag(file, 'answer.expected[$i].misconception', e['misconception']);
  }
  final Set<Object?> rules = <Object?>{};
  for (final (int i, Map<String, Object?> r) in _maps(answer['rules']).indexed) {
    if (!rules.add(r['when'])) say(file, 'answer.rules[$i].when', 'is listed twice');
    checkTag(file, 'answer.rules[$i].misconception', r['misconception']);
  }
}

/// What each kind of stage picture (`scene.picture`, X1) must say, and what belongs to no other kind.
const Map<String, ({Set<String> needs, Set<String> may})> _pictureFields =
    <String, ({Set<String> needs, Set<String> may})>{
      'base_ten': (
        needs: <String>{},
        may: <String>{'thousands', 'hundreds', 'tens', 'ones', 'litRods', 'crossedRods'},
      ),
      'array': (needs: <String>{'rows', 'columns'}, may: <String>{}),
      'hundred_chart': (needs: <String>{}, may: <String>{'lit', 'blank'}),
      'clock': (needs: <String>{'hour', 'minute'}, may: <String>{'digital'}),
      'ruler': (needs: <String>{'length'}, may: <String>{'from'}),
      'column': (needs: <String>{'op', 'top', 'bottom'}, may: <String>{'marks'}),
      'fraction': (needs: <String>{'parts', 'shaded'}, may: <String>{}),
    };

void _stagePictureOf(
  String file,
  Object? picture,
  void Function(String, String, String) say, {
  String path = 'scene.picture',
  bool blocksOnly = false,
}) {
  if (picture is! Map<String, Object?>) return;
  final ({Set<String> needs, Set<String> may})? fields = _pictureFields[picture['kind']];
  if (fields == null) return;
  final Object? kind = picture['kind'];
  final Set<String> given = picture.keys.toSet()..remove('kind');
  for (final String f in fields.needs.difference(given)) {
    say(file, '$path.$f', 'a $kind picture needs it');
  }
  for (final String f in given.difference(fields.needs).difference(fields.may)) {
    say(file, '$path.$f', 'does not belong to a $kind picture');
  }
  if (kind == 'base_ten' && given.isEmpty) {
    say(file, path, 'a base_ten picture needs at least one of thousands, hundreds, tens or ones');
  }
  if (blocksOnly && kind != 'base_ten') {
    say(file, '$path.kind', 'only a picture of blocks (base_ten) goes here');
  }
  if (kind == 'base_ten') {
    final Object? tens = picture['tens'];
    final Object? lit = picture['litRods'];
    final Object? crossed = picture['crossedRods'];
    final int rods = tens is int ? tens : 0;
    if (lit is int && lit > rods) say(file, '$path.litRods', 'is more than the tens rods');
    if (crossed is int && crossed > rods) say(file, '$path.crossedRods', 'is more than the tens rods');
    if (lit is int && crossed is int && lit + crossed > rods) {
      say(file, '$path.crossedRods', 'a rod is lit or crossed out, not both');
    }
  }
  if (kind == 'hundred_chart') {
    final Set<Object?> lit = <Object?>{...?(picture['lit'] as List<Object?>?)};
    final Set<Object?> blank = <Object?>{...?(picture['blank'] as List<Object?>?)};
    if (lit.intersection(blank).isNotEmpty) {
      say(file, '$path.blank', 'a cell is lit or blank, not both');
    }
  }
  // The fields a kind needs are reported above when missing, so a missing or odd one is skipped here (SEC-M10-2).
  final Object? parts = picture['parts'];
  final Object? shaded = picture['shaded'];
  if (kind == 'fraction' && parts is int && shaded is int && shaded > parts) {
    say(file, '$path.shaded', 'is more than the parts');
  }
  final Object? top = picture['top'];
  final Object? bottom = picture['bottom'];
  if (kind == 'column' && top is String && bottom is String && top.length < bottom.length) {
    say(file, '$path.bottom', 'a column sum has the longer number on top');
  }
}

/// Whether a tap-the-answer item shows base-ten blocks, on its stage or on its tiles.
bool _hasBlocks(Map<String, Object?>? a) {
  final Object? scene = a?['scene'];
  final Object? answer = a?['answer'];
  if (scene is! Map<String, Object?> || answer is! Map<String, Object?>) return false;
  return (scene['picture'] as Map<String, Object?>?)?['kind'] == 'base_ten' ||
      _maps(answer['options']).any((Map<String, Object?> o) => o['picture'] != null);
}

final RegExp _bigNumberCell = RegExp(r'^n:[0-9]{4,}$');
final RegExp _newSignCell = RegExp(r'^op:[<>()]$');

/// A `tap_answer` that uses a 1.4 feature (a stage picture, the number answer, five choices, the signs `<` `>` `(` `)`, a number of
/// four digits or more, a row of more than eight cells; in a language course a text stem, a cloze or a tap-all) says
/// `templateVersion` 1.4 or later.
void _tapVersion(
  String file,
  Map<String, Object?> a,
  Map<String, Object?> scene,
  Map<String, Object?> answer,
  void Function(String, String, String) say,
) {
  final List<Object?> row = (scene['row'] as List<Object?>?) ?? const <Object?>[];
  final String? feature =
      scene['picture'] != null ||
          scene['picture2'] != null ||
          _maps(answer['options']).any((Map<String, Object?> o) => o['picture'] != null)
      ? 'a stage picture'
      : answer['type'] == 'number'
      ? 'a number answer'
      : scene['stem'] != null
      ? 'a text stem'
      : scene['cloze'] != null
      ? 'a cloze'
      : answer['all'] == true
      ? 'a tap-all'
      : _maps(answer['options']).length > 4
      ? 'more than four choices'
      : row.length > 8
      ? 'a row of more than eight cells'
      : row.any((Object? c) => c is String && (_bigNumberCell.hasMatch(c) || _newSignCell.hasMatch(c)))
      ? 'a number of four digits or a sign `<` `>` `(` `)`'
      : ((scene['numeral'] as int?) ?? 0) > 100 ||
            _maps(answer['options']).any((Map<String, Object?> o) => ((o['numeral'] as int?) ?? 0) > 100)
      ? 'a number above 100'
      : null;
  if (feature != null && compareTemplateVersion('${a['templateVersion']}', '1.4') < 0) {
    say(file, 'templateVersion', 'is ${a['templateVersion']}, but $feature needs tap_answer 1.4');
  }
}

/// The number sentence of `prompt.math` (`tap_answer` 1.4): shown in the bubble under the line, so the stage has no row of its own for it
/// (the row already draws a sentence); it asks for one number at most; a number of four digits belongs to Band C; and it is no wider than the
/// bubble of the smallest phone holds.
void _promptMath(
  String file,
  Map<String, Object?> a,
  Map<String, Object?> scene,
  void Function(String, String, String) say,
) {
  final List<String>? run = ((a['prompt']! as Map<String, Object?>)['math'] as List<Object?>?)
      ?.whereType<String>()
      .toList();
  if (run == null) return;
  if (((scene['row'] as List<Object?>?) ?? const <Object?>[]).isNotEmpty) {
    say(file, 'prompt.math', 'the scene already draws the sentence in a row');
  }
  if (run.where((String c) => c == '?').length > 1) say(file, 'prompt.math', 'asks for more than one number');
  if (run.any((String c) => c.startsWith('n:') && c.length > 5)) {
    if (a['band'] != 'C') say(file, 'prompt.math', 'a number of four digits belongs to Band C');
  }
  if (rowEm(run) > maxPromptMathEm) say(file, 'prompt.math', 'is too wide for the bubble of a small phone');
  if (compareTemplateVersion('${a['templateVersion']}', '1.4') < 0) {
    say(
      file,
      'templateVersion',
      'is ${a['templateVersion']}, but a number sentence in the prompt needs tap_answer 1.4',
    );
  }
}

/// SEC-M10-3: a number above 100 (a numeral on the stage or on a tile) and a number of four digits or more in a row belong to Band C.
/// Band A and B items stay small, as their hint pictures are drawn one mark for each unit.
void _tapBigNumbers(
  String file,
  Map<String, Object?> a,
  Map<String, Object?> scene,
  Map<String, Object?> answer,
  void Function(String, String, String) say,
) {
  if (a['band'] == 'C') return;
  if (((scene['numeral'] as int?) ?? 0) > 100) {
    say(file, 'scene.numeral', 'a number above 100 belongs to Band C');
  }
  for (final (int i, Map<String, Object?> o) in _maps(answer['options']).indexed) {
    if (((o['numeral'] as int?) ?? 0) > 100) {
      say(file, 'answer.options[$i].numeral', 'a number above 100 belongs to Band C');
    }
  }
  for (final (int i, Object? c) in ((scene['row'] as List<Object?>?) ?? const <Object?>[]).indexed) {
    if (c is String && _bigNumberCell.hasMatch(c)) {
      say(file, 'scene.row[$i]', 'a number of four digits belongs to Band C');
    }
  }
}

/// A row the stage can show at a size a child can read: no wider than [maxRowEm] (see `row_width.dart`).
void _tapRowWidth(String file, Map<String, Object?> scene, void Function(String, String, String) say) {
  final List<String> row = <String>[
    for (final Object? c in (scene['row'] as List<Object?>?) ?? const <Object?>[])
      if (c is String) c,
  ];
  if (rowEm(row) > maxRowEm) {
    say(file, 'scene.row', 'is too wide to read on a small phone (shorten a number or drop a cell)');
  }
}

/// SEC-M10-3 for a `spot_error`: a number of four digits or more in a cell belongs to Band C.
void _spotBigNumbers(
  String file,
  Map<String, Object?> a,
  List<Object?> cells,
  void Function(String, String, String) say,
) {
  if (a['band'] == 'C') return;
  for (final (int i, Object? c) in cells.indexed) {
    if (c is String && _bigNumberCell.hasMatch(c)) {
      say(file, 'scene.cells[$i]', 'a number of four digits belongs to Band C');
    }
  }
}

/// A `spot_error` with a sign `<` `>` `(` `)`, a number of four digits or more, or (in a language course) a text cell or a model
/// picture says `templateVersion` 1.1 or later.
void _spotVersion(
  String file,
  Map<String, Object?> a,
  Map<String, Object?> scene,
  List<Object?> cells,
  void Function(String, String, String) say,
) {
  final bool uses =
      scene['model'] != null ||
      cells.any(
        (Object? c) =>
            c is String && (_bigNumberCell.hasMatch(c) || _newSignCell.hasMatch(c) || c.startsWith('txt:')),
      );
  if (uses && compareTemplateVersion('${a['templateVersion']}', '1.1') < 0) {
    say(file, 'templateVersion', 'is ${a['templateVersion']}, but these cells need spot_error 1.1');
  }
}

void _options(
  String file,
  Map<String, Object?> answer,
  void Function(String, String, String) say,
  void Function(String, String, Object?) checkTag, {
  void Function(String, String, Object?)? checkAsset,
}) {
  final Set<Object?> ids = <Object?>{for (final Map<String, Object?> o in _maps(answer['options'])) o['id']};
  final Object? correct = answer['correct'];
  // A tap-all has a list of right options (L5-1); every other choice has one.
  final List<Object?> right = correct is List<Object?> ? correct : <Object?>[correct];
  if (right.any((Object? r) => !ids.contains(r))) say(file, 'answer.correct', 'is not the id of any option');
  if (right.toSet().length != right.length) say(file, 'answer.correct', 'names an option twice');
  for (final (int i, Map<String, Object?> o) in _maps(answer['options']).indexed) {
    checkTag(file, 'answer.options[$i].misconception', o['misconception']);
    checkAsset?.call(file, 'answer.options[$i].sprite', o['sprite']);
    if (right.contains(o['id']) && o['misconception'] != null) {
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
  final Object? question = _mapOf(a['answer'])['question'];
  if (question is Map<String, Object?>) atMost('answer.question.caption', question['caption'], 14);
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
  // A sound button has no face, so its sound is all there is to tell it by.
  final Object? picture = o['picture'];
  final bool faceless =
      o['sprite'] == null && o['numeral'] == null && o['text'] == null && set == null && picture == null;
  final String blocks = picture is Map<String, Object?>
      ? picture.entries.map((e) => '${e.key}=${e.value}').join(',')
      : '';
  return '${o['sprite']}|${o['numeral']}|${o['text']}|${parts.join(',')}|$blocks${faceless ? '|${o['clip']}' : ''}';
}

/// What an option of a `tap_answer` is: exactly one of a sprite, a numeral or a set; in a language course also a text, or only a
/// sound (a sound button). A clip may go with any of them (a speaker on the tile); a revealed word goes under a picture.
void _optionKind(
  String file,
  String path,
  Map<String, Object?> o,
  void Function(String, String, String) say, {
  required bool language,
}) {
  final int faces = <String>['sprite', 'numeral', 'set', 'picture', 'text'].where(o.containsKey).length;
  if (!language) {
    if (faces - (o.containsKey('text') ? 1 : 0) != 1) {
      say(file, path, 'must be exactly one of a sprite, a numeral, a set or a picture of blocks');
    }
    return;
  }
  if (faces > 1 || (faces == 0 && !o.containsKey('clip'))) {
    say(
      file,
      path,
      'must be exactly one of a sprite, a numeral, a set or a text, or only a clip (a sound button)',
    );
  }
  if (o.containsKey('reveal') && !(o.containsKey('sprite') || o.containsKey('set'))) {
    say(file, '$path.reveal', 'is the word under a picture: the option needs a sprite or a set');
  }
}

/// The fields that only a language course has (text and sound on an option, a second clip and a word on show on a line, the
/// number clips of counting, the sides of a pair): a pack of the lands holds none of them.
void _languageFieldsInLands(String file, Map<String, Object?> a, void Function(String, String, String) say) {
  void walk(Object? node, String path) {
    if (node is Map<String, Object?>) {
      node.forEach((String k, Object? v) {
        final String here = path.isEmpty ? k : '$path.$k';
        final bool option = RegExp(r'^answer\.options\[\d+\]$').hasMatch(path);
        final bool own =
            const <String>{'show', 'clips', 'pole', 'pairWith'}.contains(k) ||
            (k == 'target' && v is String) ||
            (option && const <String>{'text', 'clip', 'reveal'}.contains(k));
        if (own) {
          say(file, here, 'belongs to a language course, not to the lands');
        } else {
          walk(v, here);
        }
      });
    } else if (node is List<Object?>) {
      for (final (int i, Object? e) in node.indexed) {
        walk(e, '$path[$i]');
      }
    }
  }

  walk(a, '');
}

/// The templates of the Band A wave of the language courses (L4) belong to a language course: a pack of the lands holds none.
const Set<String> languageTemplates = <String>{
  'story',
  'listen_do',
  'sing_along',
  'puppet_talk',
  'sound_boxes',
  'change_part',
  'blend_slide',
};

void _languageOnlyTemplate(
  String file,
  Map<String, Object?> a,
  void Function(String, String, String) say, {
  required bool language,
}) {
  if (!language && languageTemplates.contains(a['template'])) {
    say(file, 'template', '${a['template']} belongs to a language course, not to the lands');
  }
}

/// The options of a choice of a language template (a pause, a button, a bubble, a rhyme): between 2 and 3 of them, each a picture, a
/// text or only a sound, with a label, and a hotspot (`at`) that lies inside its picture.
void _l4Options(
  String file,
  Map<String, Object?> answer,
  void Function(String, String, String) say,
  void Function(String, String, Object?) checkAsset,
  void Function(String, String, Object?) checkVo,
  void Function(String, String, Object?) checkTag, {
  bool needCorrect = true,
  bool faceless = false,
}) {
  final List<Map<String, Object?>> options = _maps(answer['options']);
  if (needCorrect) _options(file, answer, say, checkTag, checkAsset: checkAsset);
  for (final (int i, Map<String, Object?> o) in options.indexed) {
    final String path = 'answer.options[$i]';
    checkAsset(file, '$path.sprite', o['sprite']);
    checkVo(file, '$path.clip', o['clip']);
    final int faces = <String>['sprite', 'numeral', 'text'].where(o.containsKey).length;
    if (faces > 1 || (faces == 0 && !o.containsKey('clip') && !faceless)) {
      say(
        file,
        path,
        'must be exactly one of a sprite, a numeral or a text, or only a clip (a sound button)',
      );
    }
    for (final _Place r in _shares(o['at'])) {
      if (r.right > 1.001 || r.bottom > 1.001) say(file, '$path.at', 'reaches outside the picture');
    }
  }
  // Parts of a picture are told apart by where they are (the overlap rule), not by a face of their own.
  final List<String> looks = <String>[for (final Map<String, Object?> o in options) _look(o)];
  if (!faceless && looks.toSet().length != looks.length) {
    say(file, 'answer.options', 'two options look the same');
  }
}

/// What an activity of a language template that is not scored must be: practice, with no options to choose and nothing right.
void _unscored(String file, Map<String, Object?> a, void Function(String, String, String) say, String what) {
  final Map<String, Object?> answer = _mapOf(a['answer']);
  if (a['purpose'] != 'practice') say(file, 'purpose', '$what is never scored: it is practice');
  if (answer['type'] != 'none') say(file, 'answer.type', '$what has no answer to choose: the type is "none"');
  // Nothing is wrong in it, so no repair can be aimed at it (the session builder serves a `contradicts` item to repair a tag).
  if (a.containsKey('contradicts')) say(file, 'contradicts', '$what is never a repair item');
  for (final String k in <String>['correct', 'pairWith', 'pole']) {
    if (answer.containsKey(k)) say(file, 'answer.$k', '$what has no right answer');
  }
}

/// A rectangle of the scene as shares of its picture (the validator is plain Dart, which the pack builder runs: no `dart:ui`).
typedef _Place = ({double left, double top, double right, double bottom});

_Place? _share(Object? o) {
  if (o is! Map<String, Object?>) return null;
  final double x = (o['x']! as num).toDouble();
  final double y = (o['y']! as num).toDouble();
  return (left: x, top: y, right: x + (o['w']! as num).toDouble(), bottom: y + (o['h']! as num).toDouble());
}

/// The places of an option: one rectangle or a list of them.
List<_Place> _shares(Object? o) => <_Place>[
  for (final Object? r in o is List<Object?> ? o : <Object?>[o])
    if (_share(r) case final _Place p) p,
];

/// Places that only touch edge to edge do not overlap: the shares are floating point (0.3594 + 0.2812 is not exactly 0.6406), so the
/// tolerance is a thousandth of the picture's side, as for "reaches outside" (QA-L4-12).
const double _touch = 0.001;

bool _overlap(_Place a, _Place b) =>
    a.left < b.right - _touch &&
    b.left < a.right - _touch &&
    a.top < b.bottom - _touch &&
    b.top < a.bottom - _touch;

/// Two places that overlap cannot be told apart by a touch: each part of the picture is one thing.
void _noOverlap(String file, List<(String, _Place?)> places, void Function(String, String, String) say) {
  for (int i = 0; i < places.length; i++) {
    for (int j = i + 1; j < places.length; j++) {
      final _Place? a = places[i].$2;
      final _Place? b = places[j].$2;
      if (a != null && b != null && _overlap(a, b)) {
        say(file, places[j].$1, 'overlaps ${places[i].$1}: a touch must mean one thing');
      }
    }
  }
}

/// The least share of a picture's side a touch area has in Band A (72 of 256 units, 65.5 pt on the scene of the smallest phone).
const double minBandAHotspot = 0.2812;

/// The templates a probe of the placement game may be: ordinary tap and drum items, never a story, a command, a song or a talk.
const Set<String> probeTemplates = <String>{'tap_answer', 'sound_boxes'};

/// LS13: the placement document of a language course. Its probes are ordinary items of the pack's own course with `purpose` probe (no
/// hints, one answer), of a template a probe may be, answered by touch (speech is never a probe), scored (a personal turn or a step the
/// child does is never one), and each in one place of one ladder.
void _placement(
  String file,
  String id,
  Map<String, Object?> p, {
  required String course,
  required Map<String, Map<String, Object?>> activities,
  required Set<String> skillIds,
  required void Function(String, String, String) say,
  required void Function(String, String, Object?) checkVo,
}) {
  if (!Course.isLanguage(course)) {
    say(
      file,
      '',
      'belongs to a language course: the lands have no placement document (their warm-up is made on the spot)',
    );
  } else {
    if (p['course'] != course) say(file, 'course', 'must be $course, the course of the pack');
    if (id != '$course.placement') say(file, 'id', 'must be "$course.placement"');
  }
  checkVo(file, 'thanks.vo', (p['thanks']! as Map<String, Object?>)['vo']);
  checkVo(file, 'celebration.vo', (p['celebration']! as Map<String, Object?>)['vo']);
  final Set<String> used = <String>{};
  for (final (int s, Map<String, Object?> strand) in _maps(p['strands']).indexed) {
    final List<Map<String, Object?>> levels = _maps(strand['levels']);
    final Object? offer = strand['offer'];
    if (offer is Map<String, Object?> && (offer.containsKey('answer') != offer.containsKey('equals'))) {
      say(
        file,
        'strands[$s].offer',
        'names a questionnaire question and the answer that offers the strand, both or neither',
      );
    }
    for (final (int r, Map<String, Object?> rule) in _maps(strand['start']).indexed) {
      if ((rule['level']! as int) >= levels.length) {
        say(file, 'strands[$s].start[$r].level', 'is not a level of the strand (0 to ${levels.length - 1})');
      }
    }
    for (final (int l, Map<String, Object?> level) in levels.indexed) {
      for (final (int i, Object? item) in ((level['items'] as List<Object?>?) ?? const <Object?>[]).indexed) {
        final String path = 'strands[$s].levels[$l].items[$i]';
        final Map<String, Object?>? a = item is String ? activities[item] : null;
        if (a == null) {
          say(file, path, 'there is no activity "$item" in this pack');
          continue;
        }
        final String probe = item! as String;
        if (!used.add(probe)) {
          say(file, path, '"$probe" is a probe of two places: each probe stands in one level of one strand');
        }
        if (a['purpose'] != 'probe') {
          say(file, path, '"$probe" must be a probe (purpose: probe): no hints, one answer');
        }
        if (!probeTemplates.contains(a['template'])) {
          say(file, path, '"$probe" is a ${a['template']}: a probe is a tap item or a drum item');
        }
        if (a['voiceAnswer'] == true) {
          say(file, path, '"$probe" is answered by voice: speech is never a probe');
        }
        if (_mapOf(a['answer'])['type'] == 'none') {
          say(file, path, '"$probe" is not scored, so it cannot be a probe');
        }
        if (Course.ofActivityId(probe) != course) {
          say(file, path, '"$probe" is not an item of the course $course');
        }
      }
      for (final (int i, Object? skill)
          in ((level['assumes'] as List<Object?>?) ?? const <Object?>[]).indexed) {
        final String path = 'strands[$s].levels[$l].assumes[$i]';
        if (skill is! String || !skillIds.contains(skill)) {
          say(file, path, 'the skill $skill is not in this pack');
        } else if (Course.ofSkillId(skill) != course) {
          say(file, path, '$skill is not a skill of the course $course');
        }
      }
    }
  }
}

/// LS10: a bubble turn is a scored choice; a personal turn is the four things of frame section 5.2 and nothing else, answered by
/// touch, never scored, never checked, with a pass.
void _puppetTalk(
  String file,
  Map<String, Object?> a,
  void Function(String, String, String) say, {
  required void Function(String, String, Object?) checkAsset,
  required void Function(String, String, Object?) checkVo,
  required void Function(String, String, Object?) checkTag,
}) {
  final Map<String, Object?> scene = a['scene']! as Map<String, Object?>;
  final Map<String, Object?> answer = a['answer']! as Map<String, Object?>;
  checkAsset(file, 'scene.picture', scene['picture']);
  final _Place? key = _share((scene['key'] as Map<String, Object?>?)?['at']);
  if (key != null && (key.right > 1.001 || key.bottom > 1.001)) {
    say(file, 'scene.key.at', 'reaches outside the picture');
  }
  final Object? pass = answer['pass'];
  if (pass is Map<String, Object?>) checkVo(file, 'answer.pass.vo', pass['vo']);
  final List<Map<String, Object?>> options = _maps(answer['options']);
  if (answer['mode'] == 'bubble') {
    for (final String k in <String>['topic', 'pass']) {
      if (answer.containsKey(k)) say(file, 'answer.$k', 'only a personal turn has a $k');
    }
    if (answer['type'] != 'choice') {
      say(file, 'answer.type', 'a bubble turn is a choice: the type is "choice"');
    }
    if (options.length < 2 || answer['correct'] == null) {
      say(file, 'answer.options', 'a bubble turn needs 2 or 3 answer bubbles and the right one');
      return;
    }
    if (options.length > 3) say(file, 'answer.options', 'Band A shows at most 3 bubbles');
    _l4Options(file, answer, say, checkAsset, checkVo, checkTag);
    return;
  }
  // personal (frame section 5.2): never scored, never checked, never kept
  _unscored(file, a, say, 'a personal turn');
  if (a['voiceAnswer'] == true) {
    say(
      file,
      'voiceAnswer',
      'a personal turn is answered by touch: nothing the child says is taken, checked or kept',
    );
  }
  if (answer['topic'] == null) {
    say(
      file,
      'answer.topic',
      'a personal turn says what it asks: the name, the age, the likes or the family',
    );
  }
  if (pass is! Map<String, Object?>) {
    say(file, 'answer.pass', 'a personal turn always has a pass, and the puppet\'s answer to it');
  }
  if (answer['topic'] != 'name' && options.length < 2) {
    say(file, 'answer.options', 'a personal turn about the ${answer['topic']} needs cards to touch (2 to 8)');
  }
  for (final (int i, Map<String, Object?> o) in options.indexed) {
    if (o.containsKey('misconception')) {
      say(
        file,
        'answer.options[$i].misconception',
        'nothing is wrong in a personal turn: no tag, no evidence',
      );
    }
  }
  _l4Options(file, answer, say, checkAsset, checkVo, checkTag, needCorrect: false);
}

/// LS12: the pictures, the lines and what each mode needs.
void _singAlong(
  String file,
  Map<String, Object?> a,
  void Function(String, String, String) say, {
  required void Function(String, String, Object?) checkAsset,
  required void Function(String, String, Object?) checkVo,
  required void Function(String, String, Object?) checkTag,
}) {
  final Map<String, Object?> scene = a['scene']! as Map<String, Object?>;
  final Map<String, Object?> answer = a['answer']! as Map<String, Object?>;
  final List<Map<String, Object?>> pictures = _maps(scene['pictures']);
  for (final (int i, Map<String, Object?> p) in pictures.indexed) {
    checkAsset(file, 'scene.pictures[$i].picture', p['picture']);
    checkVo(file, 'scene.pictures[$i].clip', p['clip']);
  }
  final List<Map<String, Object?>> lines = _maps(scene['lines']);
  for (final (int i, Map<String, Object?> l) in lines.indexed) {
    for (final (int k, Object? c) in ((l['clips'] as List<Object?>?) ?? const <Object?>[]).indexed) {
      checkVo(file, 'scene.lines[$i].clips[$k]', c);
    }
    for (final (int k, Object? n) in ((l['lights'] as List<Object?>?) ?? const <Object?>[]).indexed) {
      if (n is int && n >= pictures.length) {
        say(file, 'scene.lines[$i].lights[$k]', 'is not one of the ${pictures.length} pictures of the song');
      }
    }
  }
  final Map<String, Object?>? verse = scene['verse'] as Map<String, Object?>?;
  if (verse != null) {
    for (final String k in <String>['whole', 'open', 'full', 'cue']) {
      for (final (int i, Object? c) in ((verse[k] as List<Object?>?) ?? const <Object?>[]).indexed) {
        checkVo(file, 'scene.verse.$k[$i]', c);
      }
    }
  }
  final Object? question = answer['question'];
  if (question is Map<String, Object?>) checkVo(file, 'answer.question.vo', question['vo']);
  if (answer['mode'] == 'chant') {
    _unscored(file, a, say, 'a chant');
    if (lines.length < 2) say(file, 'scene.lines', 'a chant has at least two lines');
    for (final String k in <String>['options', 'question']) {
      if (answer.containsKey(k)) say(file, 'answer.$k', 'a chant has no gap and no question');
    }
    if (verse != null) say(file, 'scene.verse', 'a chant is its lines; a verse with a gap is a rhyme');
    return;
  }
  // rhyme
  if (answer['type'] != 'choice') say(file, 'answer.type', 'a rhyme asks a choice: the type is "choice"');
  if (verse == null) {
    say(
      file,
      'scene.verse',
      'a rhyme needs its verse: heard whole, up to the gap, whole again, and the end word of its first line',
    );
  }
  if (lines.isNotEmpty) say(file, 'scene.lines', 'a rhyme is its verse; the lines of a chant are not used');
  if (question is! Map<String, Object?>) say(file, 'answer.question', 'a rhyme asks which word fits the end');
  final List<Map<String, Object?>> options = _maps(answer['options']);
  if (options.length < 2 || answer['correct'] == null) {
    say(file, 'answer.options', 'a rhyme needs 2 or 3 picture options and the right one');
    return;
  }
  for (final (int i, Map<String, Object?> o) in options.indexed) {
    if (o['sprite'] == null) {
      say(file, 'answer.options[$i].sprite', 'a rhyme is completed by choosing a picture');
    }
  }
  _l4Options(file, answer, say, checkAsset, checkVo, checkTag);
}

/// A touch area of a Band A command is 64 points at least: of the 233 pt scene of the smallest phone that is 0.2747; the design's own floor
/// is 72 of 256 units (docs/design/languages-l4-layout.md section 2). It holds for a part to touch, a place, a thing to drag and the
/// target of a drag, the same for all (QA-L4-1, QA-L4-11).
void _floor(String file, String path, Iterable<_Place> places, void Function(String, String, String) say) {
  for (final _Place r in places) {
    if (r.right - r.left < minBandAHotspot - 0.001 || r.bottom - r.top < minBandAHotspot - 0.001) {
      say(
        file,
        path,
        'is smaller than $minBandAHotspot of the picture: a Band A touch is 64 points at least, and the smallest scene is 233',
      );
    }
  }
}

/// LS11: what each mode needs of its scene and its options.
void _listenDo(
  String file,
  Map<String, Object?> a,
  void Function(String, String, String) say, {
  required void Function(String, String, Object?) checkAsset,
  required void Function(String, String, Object?) checkVo,
  required void Function(String, String, Object?) checkTag,
}) {
  final Map<String, Object?> scene = a['scene']! as Map<String, Object?>;
  final Map<String, Object?> answer = a['answer']! as Map<String, Object?>;
  final String mode = answer['mode']! as String;
  checkAsset(file, 'scene.picture', scene['picture']);
  final Map<String, Object?>? target = scene['target'] as Map<String, Object?>?;
  final Map<String, Object?>? thing = scene['thing'] as Map<String, Object?>?;
  checkAsset(file, 'scene.target.sprite', target?['sprite']);
  checkAsset(file, 'scene.thing.sprite', thing?['sprite']);
  for (final (String path, Map<String, Object?>? m) in <(String, Map<String, Object?>?)>[
    ('scene.target.at', target),
    ('scene.thing.at', thing),
  ]) {
    final _Place? r = _share(m?['at']);
    if (r != null && (r.right > 1.001 || r.bottom > 1.001)) say(file, path, 'reaches outside the picture');
  }
  if (mode == 'embodied') {
    _unscored(file, a, say, 'a step the child does');
    if (a['representation'] != 'embodied') {
      say(
        file,
        'representation',
        'what the child does is the representation "embodied", never counted alone',
      );
    }
    if (answer.containsKey('options')) {
      say(file, 'answer.options', 'a step the child does has nothing to choose');
    }
    for (final String k in <String>['target', 'thing']) {
      if (scene.containsKey(k)) say(file, 'scene.$k', 'a step the child does moves nothing');
    }
    return;
  }
  if (answer['type'] != 'choice') {
    say(file, 'answer.type', 'a command that is scored is a choice: the type is "choice"');
  }
  final List<Map<String, Object?>> options = _maps(answer['options']);
  if (options.length < 2 || answer['correct'] == null) {
    say(file, 'answer.options', 'needs 2 or 3 options and the right one');
    return;
  }
  _l4Options(
    file,
    answer,
    say,
    checkAsset,
    checkVo,
    checkTag,
    faceless: mode == 'hotspots' || mode == 'place',
  );
  final List<(String, _Place?)> places = <(String, _Place?)>[
    for (final (int i, Map<String, Object?> o) in options.indexed)
      for (final _Place r in _shares(o['at'])) ('answer.options[$i].at', r),
  ];
  if (a['band'] == 'A' && mode != 'cards') {
    for (final (int i, Map<String, Object?> o) in options.indexed) {
      _floor(file, 'answer.options[$i].at', _shares(o['at']), say);
    }
    _floor(file, 'scene.target.at', _shares(target?['at']), say);
    _floor(file, 'scene.thing.at', _shares(thing?['at']), say);
  }
  if (mode != 'hotspots' && mode != 'cards') {
    for (final (int i, Map<String, Object?> o) in options.indexed) {
      if (_shares(o['at']).length > 1) {
        say(
          file,
          'answer.options[$i].at',
          'only a part of a picture (hotspots, or the card of one) has more than one place',
        );
      }
    }
  }
  switch (mode) {
    case 'hotspots':
    case 'place':
      for (final (int i, Map<String, Object?> o) in options.indexed) {
        if (o['at'] == null) {
          say(file, 'answer.options[$i].at', 'a $mode option is a place in the picture: it needs `at`');
        }
      }
      if (mode == 'place') {
        if (thing == null) say(file, 'scene.thing', 'a place mode moves one thing: the scene needs it');
        _noOverlap(file, <(String, _Place?)>[...places, ('scene.thing.at', _share(thing?['at']))], say);
      } else {
        _noOverlap(file, places, say);
      }
    case 'buttons':
    case 'cards':
      for (final (int i, Map<String, Object?> o) in options.indexed) {
        if (o['sprite'] == null) {
          say(file, 'answer.options[$i].sprite', 'a button is the picture of an action');
        }
      }
    case 'drag':
      for (final (int i, Map<String, Object?> o) in options.indexed) {
        if (o['sprite'] == null || o['at'] == null) {
          say(
            file,
            'answer.options[$i]',
            'a thing to drag is a picture with the place it starts at (`sprite` and `at`)',
          );
        }
      }
      if (target == null) say(file, 'scene.target', 'a drag mode needs the place the things are taken to');
      _noOverlap(file, <(String, _Place?)>[...places, ('scene.target.at', _share(target?['at']))], say);
  }
}

/// LS08: the pages, the hotspots, the clips, and what each mode needs.
void _story(
  String file,
  Map<String, Object?> a,
  void Function(String, String, String) say, {
  required void Function(String, String, Object?) checkAsset,
  required void Function(String, String, Object?) checkVo,
  required void Function(String, String, Object?) checkTag,
}) {
  final Map<String, Object?> scene = a['scene']! as Map<String, Object?>;
  final Map<String, Object?> answer = a['answer']! as Map<String, Object?>;
  final List<Map<String, Object?>> pages = _maps(scene['pages']);
  for (final (int i, Map<String, Object?> p) in pages.indexed) {
    final String path = 'scene.pages[$i]';
    checkAsset(file, '$path.picture', p['picture']);
    for (final (int k, Object? c) in ((p['clips'] as List<Object?>?) ?? const <Object?>[]).indexed) {
      checkVo(file, '$path.clips[$k]', c);
    }
    for (final (int k, Map<String, Object?> w) in _maps(p['words']).indexed) {
      checkVo(file, '$path.words[$k].clip', w['clip']);
      final Map<String, Object?> at = w['at']! as Map<String, Object?>;
      if ((at['x']! as num) + (at['w']! as num) > 1.001 || (at['y']! as num) + (at['h']! as num) > 1.001) {
        say(file, '$path.words[$k].at', 'reaches outside the picture');
      }
    }
  }
  if (answer['mode'] == 'listen') {
    _unscored(file, a, say, 'a story that is only heard');
    for (final String k in <String>['options', 'pauseAfter', 'question']) {
      if (answer.containsKey(k)) {
        say(file, 'answer.$k', 'a story that is only heard has no pause and no question');
      }
    }
    return;
  }
  // dialogic
  if (answer['type'] != 'choice') {
    say(file, 'answer.type', 'a dialogic story asks a choice: the type is "choice"');
  }
  final Object? pause = answer['pauseAfter'];
  if (pause is! int || pause >= pages.length) {
    say(
      file,
      'answer.pauseAfter',
      'must be a page of the story (0 to ${pages.length - 1}): the page after which it asks',
    );
  }
  final Object? question = answer['question'];
  if (question is! Map<String, Object?>) {
    say(file, 'answer.question', 'a dialogic story needs the question it asks at its pause');
  } else {
    checkVo(file, 'answer.question.vo', question['vo']);
  }
  if (_maps(answer['options']).length < 2 || answer['correct'] == null) {
    say(file, 'answer.options', 'a dialogic story needs 2 or 3 options and the right one');
    return;
  }
  _l4Options(file, answer, say, checkAsset, checkVo, checkTag);
}

/// The second clip of a spoken line (`target`) names a voice line of the pack, and only a language course has one.
void _targetClips(String file, Map<String, Object?> a, void Function(String, String, Object?) checkVo) {
  void walk(Object? node, String path) {
    if (node is Map<String, Object?>) {
      node.forEach((String k, Object? v) {
        final String here = path.isEmpty ? k : '$path.$k';
        if (k == 'target' && v is String) {
          checkVo(file, here, v);
        } else {
          walk(v, here);
        }
      });
    } else if (node is List<Object?>) {
      for (final (int i, Object? e) in node.indexed) {
        walk(e, '$path[$i]');
      }
    }
  }

  walk(a, '');
}

final RegExp _jsonName = RegExp(r'^([a-z]+)\.(.+)\.json$');

/// The code each domain's skill ids start with (NUM-A-01, MATH-B-07, COL-A-02, SHP-B-03, LOG-A-10, CS-B-04).
const Map<String, String> skillDomainCodes = <String, String>{
  'numbers': 'NUM',
  'math': 'MATH',
  'colors': 'COL',
  'shapes': 'SHP',
  'logic': 'LOG',
  'cs': 'CS',
};

final RegExp _skillIdPattern = RegExp(r'^([A-Z]+)-([ABC])-(\d{2})(?:\.[A-Z]\d{1,2})?$');

/// A skill id is `<DOMAIN>-<BAND>-<NN>`: the code of the skill's own domain, its own band letter and two digits
/// (board B-15); in a language course the code is the course in capitals (`ENG-A-01`), and a skill taught group by group
/// has a dotted id for each group (`ENG-B-19.G1`). The schema only asks for the shape; this checks that the id says what
/// the skill file says.
void _skillId(
  String file,
  String id,
  Map<String, Object?> s,
  void Function(String, String, String) say, {
  required String course,
}) {
  final RegExpMatch? m = _skillIdPattern.firstMatch(id);
  if (Course.isLanguage(course)) {
    if (m == null || m[1] != Course.skillPrefixOf(course)) {
      say(
        file,
        'id',
        '"$id" must be ${Course.skillPrefixOf(course)}-<BAND>-<NN>, the capitals of the course $course',
      );
    } else if (m[2] != s['band']) {
      say(file, 'id', '"$id" has the band letter ${m[2]}, but the skill is in band ${s['band']}');
    }
    return;
  }
  if (s['domain'] == languagesDomain) return; // `_courseRules` says that a core pack has no language skills
  final String? code = skillDomainCodes[s['domain']];
  if (m == null || !skillDomainCodes.containsValue(m[1])) {
    say(
      file,
      'id',
      '"$id" must be <DOMAIN>-<BAND>-<NN>, with a domain of ${skillDomainCodes.values.join(', ')}',
    );
    return;
  }
  if (m[1] != code) {
    say(file, 'id', '"$id" starts with ${m[1]}, but the skill is in the domain ${s['domain']} ($code)');
  }
  if (m[2] != s['band']) {
    say(file, 'id', '"$id" has the band letter ${m[2]}, but the skill is in band ${s['band']}');
  }
}

/// A pack of a language course is named `lang-<course>`, and no other pack is named `lang-` anything: one signed pack per
/// course (docs/languages/frame.md section 1.5), recognised by its id alone (the gateway does too).
void _packCourse(String course, String packId, void Function(String, String, String) say) {
  final String? named = Course.ofPackId(packId);
  if (named == null) {
    say('manifest.json', 'id', '"$packId" begins with lang- but names no language course');
  } else if (named != course) {
    final String? want = Course.packIdOf(course);
    say(
      'manifest.json',
      'id',
      want == null
          ? '"$packId" is the id of a language pack, but the pack says it is core'
          : 'a pack of the course $course must be named "$want"',
    );
  }
}

/// The invariants of docs/languages/frame.md section 1.5. Courses never mix: a pack holds one course, and inside it every
/// skill, prerequisite, activity, lesson and misconception tag belongs to that course. Evidence, repair and revisits can
/// therefore never cross, because nothing that could carry them across is allowed to exist.
void _courseRules({
  required String course,
  required Map<String, Map<String, Object?>> activities,
  required Map<String, Map<String, Object?>> lessons,
  required Map<String, Map<String, Object?>> skills,
  required Map<String, Map<String, Object?>> tags,
  required Set<String> skillIds,
  required Map<String, Map<String, Object?>> gates,
  required void Function(String, String, String) say,
}) {
  final bool language = Course.isLanguage(course);
  void sameCourse(String file, Map<String, Object?> doc) {
    final Object? own = doc['course'];
    if ((own ?? Course.core) != course) {
      say(file, 'course', 'is $own, but the pack is of the course $course (a pack holds one course)');
    }
  }

  void domain(String file, Map<String, Object?> doc) {
    if ((doc['domain'] == languagesDomain) != language) {
      say(
        file,
        'domain',
        language
            ? 'must be $languagesDomain in the language course $course'
            : '$languagesDomain belongs to a language course, not to core',
      );
    }
  }

  bool ownSkill(String id) => Course.ofSkillId(id) == course;

  // Activity and lesson ids carry their course: `eng.greet.i01`. Two packs can then never share an id, and an answer is evidence
  // for its own pack's item only (SEC-L0-1).
  void ownId(String file, String id) {
    if (Course.ofActivityId(id) != course) {
      say(
        file,
        'id',
        language
            ? '"$id" must begin with "$course." (an id of a language course carries its course)'
            : '"$id" begins with a language course; those ids belong to the language packs',
      );
    }
  }

  // Which skills are roll-ups: those that have dotted groups. A roll-up has no estimate of its own.
  final Set<String> rollUps = <String>{for (final String id in skillIds) ?SkillIds.parentOf(id)};

  skills.forEach((String id, Map<String, Object?> s) {
    final String file = 'skill.$id.json';
    sameCourse(file, s);
    domain(file, s);
    if (!ownSkill(id)) say(file, 'id', '"$id" is not a skill of the course $course');
    final String? parent = SkillIds.parentOf(id);
    if (parent != null && !skillIds.contains(parent)) {
      say(file, 'id', 'is a group of $parent, which is not in this pack (the roll-up skill is needed)');
    }
    for (final (int i, Map<String, Object?> p) in _maps(s['prerequisites']).indexed) {
      final Object? need = p['skill'];
      if (need is! String) continue;
      if (!ownSkill(need)) {
        say(
          file,
          'prerequisites[$i].skill',
          '$need is not a skill of the course $course (no prerequisite across courses)',
        );
      } else if (!skillIds.contains(need)) {
        say(file, 'prerequisites[$i].skill', 'the skill $need is not in this pack');
      }
      if (need == parent) {
        say(file, 'prerequisites[$i].skill', 'a group cannot need its own roll-up skill $need');
      }
    }
    if (rollUps.contains(id) && _maps(s['prerequisites']).isNotEmpty) {
      say(file, 'prerequisites', 'a roll-up has none of its own: put them on its groups');
    }
  });

  _bundlesAndGates(
    course: course,
    skills: skills,
    skillIds: skillIds,
    rollUps: rollUps,
    gates: gates,
    say: say,
  );

  tags.forEach((String id, Map<String, Object?> t) {
    final String file = 'misconception.$id.json';
    sameCourse(file, t);
    if (Course.ofTag(id) != course) say(file, 'id', '"$id" is not a misconception tag of the course $course');
    if (language && !id.startsWith('$course.')) say(file, 'id', 'must begin with "$course."');
    for (final (int i, Object? s) in (t['skills']! as List<Object?>).indexed) {
      if (s is String && !ownSkill(s)) say(file, 'skills[$i]', '$s is not a skill of the course $course');
    }
  });

  activities.forEach((String id, Map<String, Object?> a) {
    final String file = 'activity.$id.json';
    sameCourse(file, a);
    ownId(file, id);
    domain(file, a);
    for (final (int i, Map<String, Object?> s) in _maps(a['skills']).indexed) {
      final Object? skill = s['id'];
      if (skill is! String) continue;
      if (!ownSkill(skill)) {
        say(
          file,
          'skills[$i].id',
          '$skill is not a skill of the course $course (evidence never crosses courses)',
        );
      } else if (rollUps.contains(skill)) {
        say(file, 'skills[$i].id', '$skill is a roll-up with no estimate of its own: name one of its groups');
      }
    }
    if (!language) _languageFieldsInLands(file, a, say);
    final Object? tutor = a['tutor'];
    if (language && tutor is Map<String, Object?> && tutor['llmAllowed'] == true) {
      say(file, 'tutor.llmAllowed', 'must be false: the AI tutor is off in language lessons');
    }
  });

  lessons.forEach((String id, Map<String, Object?> l) {
    final String file = 'lesson.$id.json';
    sameCourse(file, l);
    ownId(file, id);
    if (!language) _languageFieldsInLands(file, l, say);
    for (final (int i, Object? s) in (l['skills']! as List<Object?>).indexed) {
      if (s is String && !ownSkill(s)) say(file, 'skills[$i]', '$s is not a skill of the course $course');
    }
  });
}

/// The rules for letter bundles and gates (docs/languages/frame.md sections 3.3.3 and 3.3.6).
void _bundlesAndGates({
  required String course,
  required Map<String, Map<String, Object?>> skills,
  required Set<String> skillIds,
  required Set<String> rollUps,
  required Map<String, Map<String, Object?>> gates,
  required void Function(String, String, String) say,
}) {
  final Map<String, List<String>> bundles = <String, List<String>>{};
  skills.forEach((String id, Map<String, Object?> s) {
    final Object? b = s['bundle'];
    if (b is! String) return;
    final String file = 'skill.$id.json';
    if (!b.startsWith('$course.')) say(file, 'bundle', '"$b" must begin with "$course."');
    if (rollUps.contains(id)) say(file, 'bundle', 'a roll-up has no estimate, so it is no facet of a bundle');
    (bundles[b] ??= <String>[]).add(id);
  });
  bundles.forEach((String bundle, List<String> members) {
    if (members.length < 2) {
      say('skill.${members.first}.json', 'bundle', 'a bundle has at least two facets; "$bundle" has one');
    }
    for (final String m in members) {
      final Set<String> below = skillsBelow(<String>[m], skills);
      for (final String other in members) {
        if (other != m && below.contains(other)) {
          say(
            'skill.$m.json',
            'prerequisites',
            'a facet of "$bundle" cannot need another facet of it ($other)',
          );
        }
      }
    }
  });

  gates.forEach((String id, Map<String, Object?> g) {
    final String file = 'gate.$id.json';
    // A gate of a language pack carries its course like every other document of it (it is never read as core by default).
    if ((Course.isLanguage(course) ? g['course'] : g['course'] ?? Course.core) != course) {
      say(
        file,
        'course',
        'is ${g['course']}, but the pack is of the course $course (a pack holds one course, and says it on every document)',
      );
    }
    if (!id.startsWith('$course.')) say(file, 'id', '"$id" must begin with "$course."');
    final Set<String> requires = <String>{
      for (final Object? s in g['requires']! as List<Object?>) s! as String,
    };
    final Set<String> holds = <String>{for (final Object? s in g['holds']! as List<Object?>) s! as String};
    final Set<String> named = <String>{...requires, ...holds};
    for (final Map<String, Object?> q in _maps(g['requireAtLeast'])) {
      final List<Object?> quota = q['skills']! as List<Object?>;
      named.addAll(<String>[for (final Object? s in quota) s! as String]);
      if ((q['count']! as int) > quota.length) {
        say(file, 'requireAtLeast', 'asks for ${q['count']} skills out of ${quota.length}');
      }
    }
    for (final String s in named) {
      if (Course.ofSkillId(s) != course) {
        say(
          file,
          'skills',
          '$s is not a skill of the course $course (a gate never reaches into another course)',
        );
      } else if (!skillIds.contains(s)) {
        say(file, 'skills', 'the skill $s is not in this pack');
      }
    }
    for (final String h in holds) {
      if (rollUps.contains(h)) say(file, 'holds', '$h is a roll-up: hold its groups');
      if (requires.contains(h)) {
        say(file, 'holds', '$h is both required and held, so the gate could never open');
      }
    }
    // A gate can never open if what it asks for needs something it holds back.
    final Set<String> asked = <String>{
      ...requires,
      for (final Map<String, Object?> q in _maps(g['requireAtLeast']))
        for (final Object? s in q['skills']! as List<Object?>) s! as String,
    };
    final Set<String> needed = <String>{...asked, ...skillsBelow(asked, skills)};
    for (final String h in holds) {
      if (needed.contains(h)) {
        say(file, 'holds', '$h is needed by what the gate asks for, so the gate could never open');
      }
    }
  });
}

String _range(int from, int to) => '${String.fromCharCode(from)}-${String.fromCharCode(to)}';

// Letters U+05D0 to U+05EA, points U+05B0 to U+05C7; geresh, gershayim and maqaf may sit inside a word.
// Built from code points so this file holds no Hebrew text (that lives in strings/he.dart).
final String _letters = _range(0x05D0, 0x05EA);
final String _points = _range(0x05B0, 0x05C7);
final RegExp _hebrewWord = RegExp(
  '[$_letters][$_points$_letters${String.fromCharCodes(<int>[0x05F3, 0x05F4, 0x05BE])}]*',
);
final RegExp _latin = RegExp('[A-Za-z]');
final RegExp _cyrillic = RegExp('[${_range(0x0400, 0x052F)}]');

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
  if (_cyrillic.hasMatch(text)) {
    say(file, path, 'contains Cyrillic letters; a Hebrew line holds no word of another language');
  }
  for (final String problem in hebrewLineProblems(text)) {
    say(file, path, problem);
  }
  if (text.contains('<') || text.contains('>')) {
    say(file, path, 'contains < or >, which turn over in right-to-left text; write maths as a token');
  }
  if (!_hebrewWord.hasMatch(text) && !allowNoHebrew) say(file, path, 'contains no Hebrew');
  if (!pointed) return;
  for (final String word in unpointedHebrewWords(text)) {
    say(file, path, 'the word "$word" has no niqqud (Bands A and B are fully pointed)');
  }
}
