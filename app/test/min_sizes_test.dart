// The minimum sizes of the child's space (the owner's rule of 2026-11-16: "not too small to see or read in any of the devices"), automated from
// docs/design/m11/min-sizes.md (section 2 floors, checklist 5, addenda 8.x). How it works, what it covers and what it cannot measure is in
// docs/agents/qa-min-sizes-2026-11-17.md.
//
// This file is the quick part (no screen is drawn): the floors the test uses are the design's numbers, the layout groups used for the language screens
// cover every template and every activity of the pack, the hint families cover every template, and the one map of known failures
// (support/min_sizes_known.dart) is well formed and names things that exist. It also prints the summary table of the map.
//
// The screens themselves are drawn by min_sizes_phone_test.dart, min_sizes_phone_se_test.dart, min_sizes_tablet_l_test.dart and
// min_sizes_tablet_p_test.dart (one file per board so that the CI shards can take them apart; each asserts the map for its board exactly).
// Every activity of the pack that is not a Show is opened on every board at text size 1.0 and 1.3; the hints, the Shows and the language screens
// are opened by family (the layout groups of support/min_sizes_catalogue.dart choose the language screens; the hint families are listed in the suite).
import 'package:flutter_test/flutter_test.dart';
import 'package:nitznutz/content/models.dart';
import 'package:nitznutz/design/token_types.dart';
import 'package:nitznutz/design/tokens.g.dart';

import 'support/c1_screens.dart' show boards, loadSourcePack;
import 'support/harness.dart';
import 'support/l7_rig.dart' show buildCourse;
import 'support/min_sizes_catalogue.dart';
import 'support/min_sizes_known.dart';
import 'support/min_sizes_rules.dart';
import 'support/min_sizes_suite.dart' show hintFamilies, languageCourses, showLessons;

void main() {
  late PackContent content;
  setUpAll(() async {
    await loadAppFonts();
    content = await loadSourcePack();
  });

  test(
    'the floors are the design numbers: tiles 96/88/80 and 112/104/96, controls 64/56, a picture at least 40',
    () {
      expect(TokenStage.all.map((StageToken s) => s.tilePhone), <double>[96, 96, 88, 80]);
      expect(TokenStage.all.map((StageToken s) => s.tileTablet), <double>[112, 112, 104, 96]);
      expect(TokenTouch.band[Band.a]!.minControl, 64);
      expect(TokenTouch.band[Band.b]!.minControl, 56);
      expect(TokenTouch.band[Band.c]!.minControl, 56);
      expect(TokenComponent.stagePictureMin, 40);
      expect(TokenStage.all.map((StageToken s) => s.captionPhone), <double>[26, 26, 24, 22]);
      expect(TokenStage.all.map((StageToken s) => s.captionFloorDrop), everyElement(2));
    },
  );

  test('the four boards are the design boards', () {
    expect(<String>[for (final b in boards) b.$1], <String>['phone', 'phoneSE', 'tabletL', 'tabletP']);
  });

  test(
    'every activity is in exactly one layout, and every template, in every band it is used in, has one',
    () {
      final List<LayoutGroup> groups = layoutGroups(content);
      final Set<String> seen = <String>{};
      for (final LayoutGroup g in groups) {
        for (final String id in g.ids) {
          expect(seen.add(id), isTrue, reason: '$id is in two layouts');
        }
        expect(g.rep, g.ids.first);
      }
      expect(seen, content.activities.keys.toSet());
      final Set<String> templatesAndBands = <String>{
        for (final Activity a in content.activities.values) '${a.template}/${a.band}/${a.isShow}',
      };
      // each (template, band, show) has at least one group
      for (final String tb in templatesAndBands) {
        final List<String> p = tb.split('/');
        final bool found = groups.any((LayoutGroup g) {
          final List<String> f = g.fingerprint.split('/');
          return f[0] == p[0] && f[2] == p[1] && f[3] == (p[2] == 'true' ? 'show' : 'item');
        });
        expect(found, isTrue, reason: 'no layout group for $tb');
      }
      // the pack still has the 15 templates the design lists
      expect(content.activities.values.map((Activity a) => a.template).toSet().length, 15);
      // ignore: avoid_print
      print(
        'MINSIZES-COVERAGE ${groups.length} layouts for ${content.activities.length} activities '
        '(${groups.where((LayoutGroup g) => !g.fingerprint.contains('/show/')).length} of items, '
        '${groups.where((LayoutGroup g) => g.fingerprint.contains('/show/')).length} of Shows)',
      );
    },
  );

  test('the hint families exist and reach every template; every kind of Show has a lesson', () {
    final List<Activity> found = <Activity>[
      for (final String id in hintFamilies)
        if (content.activities[id] != null) content.activities[id]!,
    ];
    expect(
      found.length,
      greaterThanOrEqualTo(hintFamilies.length - 2),
      reason: 'a hint family names an activity the pack no longer has',
    );
    final Set<String> templates = <String>{
      for (final Activity a in content.activities.values)
        if (a.hints.isNotEmpty && !a.isShow) a.template,
    };
    expect(
      found.map((Activity a) => a.template).toSet(),
      templates,
      reason: 'a template with hints has no hint family',
    );
    final Set<String> showTemplates = <String>{
      for (final Activity a in content.activities.values)
        if (a.isShow) a.template,
    };
    final Set<String> lessonTemplates = showLessons(content).keys
        .map((String k) => k.split('/').first)
        .toSet();
    expect(lessonTemplates, showTemplates, reason: 'a Show template with no lesson that plays it');
  });

  test('the map of known failures is well formed and names what exists', () async {
    final Map<String, PackContent> courses = <String, PackContent>{
      for (final String c in languageCourses) c: await buildCourse(c),
    };
    const Set<String> looks = <String>{'P1', 'P3', 'P4'};
    final RegExp langLook = RegExp(r'^B[012]-(eng|heb|rus)$');
    const Set<String> kinds = <String>{
      'item',
      'sorted',
      'hint1',
      'hint2',
      'hint3',
      'show-host',
      'show-turn',
      'lang',
      'lang-lesson',
    };
    for (final MapEntry<String, Known> e in knownFailures.entries) {
      final List<String> p = e.key.split('|');
      expect(p.length, 6, reason: e.key);
      expect(<String>['phone', 'phoneSE', 'tabletL', 'tabletP'], contains(p[0]), reason: e.key);
      expect(looks.contains(p[1]) || langLook.hasMatch(p[1]), isTrue, reason: e.key);
      expect(<String>['1.0', '1.3'], contains(p[2]), reason: e.key);
      expect(kinds, contains(p[3]), reason: e.key);
      expect(p[5], e.value.rule, reason: e.key);
      expect(rules.containsKey(e.value.rule), isTrue, reason: e.key);
      final bool high =
          e.value.rule == 'EMPTY_BAND' || e.value.rule == 'HAND_BUBBLE' || e.value.rule == 'LABEL_WEIGHT';
      if (e.value.rule != 'LAYOUT_ERROR') {
        expect(
          high ? e.value.value > e.value.threshold : e.value.value < e.value.threshold,
          isTrue,
          reason: '${e.key} is not a failure',
        );
      }
      expect(e.value.count, greaterThan(0), reason: e.key);
      final PackContent pack = langLook.hasMatch(p[1]) ? courses[p[1].split('-').last]! : content;
      final bool lesson = p[3] == 'lang-lesson' || p[3].startsWith('show');
      expect(
        lesson ? pack.lessons.containsKey(p[4]) : pack.activities.containsKey(p[4]),
        isTrue,
        reason: '${e.key}: ${p[4]} is not in the pack',
      );
    }
  });

  test('summary of the known failures, by board and severity', () {
    final Map<String, Map<String, int>> by = <String, Map<String, int>>{};
    final Map<String, int> byRule = <String, int>{};
    for (final MapEntry<String, Known> e in knownFailures.entries) {
      final String board = e.key.split('|').first;
      final String sev = rules[e.value.rule]!.sev;
      by.putIfAbsent(board, () => <String, int>{'S1': 0, 'S2': 0, 'S3': 0})[sev] = by[board]![sev]! + 1;
      byRule[e.value.rule] = (byRule[e.value.rule] ?? 0) + 1;
    }
    // ignore: avoid_print
    print('MINSIZES-SUMMARY board      S1    S2    S3   total');
    int total = 0;
    for (final String b in <String>['phone', 'phoneSE', 'tabletL', 'tabletP']) {
      final Map<String, int> m = by[b] ?? <String, int>{'S1': 0, 'S2': 0, 'S3': 0};
      final int t = m['S1']! + m['S2']! + m['S3']!;
      total += t;
      // ignore: avoid_print
      print(
        'MINSIZES-SUMMARY ${b.padRight(9)} ${m['S1'].toString().padLeft(5)} ${m['S2'].toString().padLeft(5)} ${m['S3'].toString().padLeft(5)} ${t.toString().padLeft(7)}',
      );
    }
    // ignore: avoid_print
    print(
      'MINSIZES-SUMMARY all: $total failing measurements; by rule ${(byRule.entries.toList()..sort((MapEntry<String, int> a, MapEntry<String, int> b) => b.value.compareTo(a.value))).map((MapEntry<String, int> e) => '${e.key} ${e.value}').join(', ')}',
    );
  });
}
