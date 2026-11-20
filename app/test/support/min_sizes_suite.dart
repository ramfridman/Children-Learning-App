// The tests of the minimum-sizes suite for one board (see min_sizes_run.dart): the layouts of the pack's activities by look and text size, the
// sorted state of the sorts.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nitznutz/characters/character_source.dart' show FixedCharacterSource;
import 'package:nitznutz/content/models.dart';
import 'package:nitznutz/parent/age_settings.dart';
import 'package:nitznutz/parent/language_settings.dart';
import 'package:nitznutz/play/lesson_screen.dart';
import 'package:nitznutz/play/show_stage.dart' show ShowArt;

import 'bubble_audit.dart' show AuditLook, auditLooks;
import 'c1_screens.dart';
import 'app_harness.dart';
import 'harness.dart';
import 'language_screens.dart' show langKid;
import 'language_voice.dart';
import 'l7_rig.dart';
import 'meet_opener.dart';
import 'voice_fixtures.dart';
import 'min_sizes_catalogue.dart';
import 'min_sizes_measure.dart' show readScreen;
import 'min_sizes_rules.dart';
import 'min_sizes_run.dart';

const List<String> _lookNames = <String>['P1', 'P3', 'P4'];
const Map<int, String> _bandOfLook = <int, String>{0: 'A', 1: 'B', 2: 'C'};

num? _range(Activity a) {
  final Map<Object?, Object?> sc = a.json['scene']! as Map<Object?, Object?>;
  final Object? from = sc['from'], to = sc['to'];
  return from is num && to is num ? to - from : null;
}

Future<void> _sortTwo(WidgetTester t, SortDragActivity a) async {
  int done = 0;
  for (int round = 0; round < 6 && done < 3; round++) {
    SortItem? next;
    for (final SortItem i in a.items) {
      if (find.byKey(Key('item-${i.id}')).evaluate().isNotEmpty) {
        next = i;
        break;
      }
    }
    if (next == null) break;
    final String bin = next.bin ?? a.bins.first.id;
    final Finder from = find.byKey(Key('item-${next.id}'));
    final Finder to = find.byKey(Key('bin-$bin'));
    if (to.evaluate().isEmpty) break;
    final Offset start = t.getCenter(from);
    await t.dragFrom(start, t.getCenter(to) - start);
    await t.pump(const Duration(milliseconds: 500));
    done++;
  }
  await t.pump(const Duration(milliseconds: 600));
}

/// The activities whose hints are measured: one of each hint family of the goldens (hint_golden, hint_tap, hint_tap_b, hint_part5, hint_qa,
/// hint_hand_below, hint_seesaw), the template families of the Band C hints, and every template of the pack at least once.
const List<String> hintFamilies = <String>[
  'count.apples.7',
  'b.numb04.3',
  'give.butterflies.4',
  'flash.dice.3',
  'x.shpa02.1',
  'b.numb13.13',
  'b.numb13.19',
  'b.numb13.7',
  'x.mathb15.1',
  'b.numb11.1',
  'b15.cola02.5',
  'cs.robot.plan.2',
  'log.sortdrag.colour',
  'math.share.apples',
  'log.copy.three',
  'x.numa07.1',
  'x.mathb16.1',
  'x.shpb09.1',
  'shp.build.house',
  'b15.numa01.4',
  'b15.loga04.1',
  'b.colb01.1',
  'b.colb02.1',
  'b.colb03.1',
  'b.numb02.2',
  'b.numb17.8',
  'b.numb08.1',
  'b.numb10.1',
  'b.numb18.10',
  'x.mathb19.1',
  'x.mathb19.7',
  'b.mathb03.1',
  'b.mathb14.1',
  'x.mathb16.8',
  'b.shpb01.6',
  'b.shpb02.1',
  'b.shpb04.2',
  'b.shpb03.1',
  'b.shpb08.1',
  'x.shpb09.5',
  'b.logb04.1',
  'b.logb06.1',
  'b.logb09.1',
  'shp.name.triangle',
  'col.name.red.ball',
  'more.apples.2v4',
  'numeral.bugs.5',
  'next.after.4',
  'log.next.colours',
  'log.story.plant.mid',
  'log.same.cat',
  'math.add.stars',
  'show.birds.4',
  'math.size.long',
  'shp.where.above',
  'ordinal.second.of4',
  'zero.basket',
  'x.mathb17.6',
  'b.mathb09.5',
  'b.mathb13.5',
  'b.mathb13.7',
  'b.mathb03.9',
  'b.logb02.1',
  'b.csb04.1',
  'b.logb11.4',
  'b.colb06.5',
  'b.colb04.6',
  'c.mathc01.1',
  'c.mathc01.12',
  'c.mathc02.1',
  'c.numb06.2',
  'c.numc01.5',
  'c.numc02.4',
  'c.numc03.3',
  'c.numc03.5',
  'c.numc03.9',
  'c.numc03.18',
  'c.numc02.1',
];

/// The lesson that plays each kind of Show (the Show of its first skill), by the Show's template and band: the first lesson by id.
Map<String, String> showLessons(PackContent c) {
  final Map<String, String> out = <String, String>{};
  final List<String> ids = c.lessons.keys.toList()..sort();
  for (final String id in ids) {
    final LessonParts? p = c.lessons[id]!.parts;
    if (p == null) continue;
    final Activity? a = c.activities[p.show];
    if (a == null) continue;
    out.putIfAbsent('${a.template}/${a.band}', () => id);
  }
  return out;
}

Future<void> _startRooms(WidgetTester t, PackContent content, Size board, AuditLook look) async {
  await t.runAsync(() => ShowArt.load());
  final AppRig rig = AppRig(
    content: content,
    rooms: true,
    player: FakePlayer()..endsAfter = const Duration(milliseconds: 1200),
  );
  await rig.seedFinishedSetup(name: 'נֹעָה', ageBand: look.school.band);
  await rig.db.confirmStage('p-1', look.school, DateTime(2026, 10, 26));
  await rig.db.setBirth('p-1', look.birth);
  if (look.captions != null) await rig.db.putSetting(readingKey('p-1'), look.captions!);
  await rig.pump(t, size: board);
  await t.tap(find.text('נֹעָה'));
  await t.pump(const Duration(milliseconds: 500));
}

/// The lessons of a course whose first screen is opened: the first lesson of each layout of its first item, and every fifth lesson.
List<String> languageLessonReps(PackContent pack) {
  final List<String> ids = pack.lessons.keys.toList()..sort();
  final Set<String> seen = <String>{};
  final List<String> out = <String>[];
  for (int i = 0; i < ids.length; i++) {
    final List<Activity> items = pack.itemsFor(pack.lessons[ids[i]]!, route: 'new');
    if (items.isEmpty) continue;
    final bool fresh = seen.add(fingerprintOf(items.first));
    if (fresh || i % 5 == 0) out.add(ids[i]);
  }
  return out;
}

const List<String> languageCourses = <String>['eng', 'heb', 'rus'];

/// The language activities opened: the first of each layout, the heaviest (most text) of each layout, and every tenth by id.
List<String> languageReps(PackContent pack) {
  final List<LayoutGroup> groups = layoutGroups(pack);
  final Set<String> out = <String>{};
  for (final LayoutGroup g in groups) {
    out.add(g.rep);
    final List<String> byWeight = <String>[...g.ids]
      ..sort(
        (String a, String b) =>
            pack.activities[b]!.json.toString().length.compareTo(pack.activities[a]!.json.toString().length),
      );
    out.add(byWeight.first);
  }
  final List<String> ids = pack.activities.keys.toList()..sort();
  for (int i = 0; i < ids.length; i += 10) {
    out.add(ids[i]);
  }
  return out.toList()..sort();
}

void minSizesBoard(String boardName) {
  final (String, Size) board = boards.firstWhere(((String, Size) b) => b.$1 == boardName);
  late PackContent content;
  final Map<String, PackContent> courses = <String, PackContent>{};
  final Map<String, FixedCharacterSource> voices = <String, FixedCharacterSource>{};
  setUpAll(() async {
    await loadAppFonts();
    content = await loadSourcePack();
    for (final String c in languageCourses) {
      courses[c] = await buildCourse(c);
      voices[c] = await languageVoiceSource(courseRefs(c));
    }
  });

  // the language course screens: every layout of each real course (Meet, Find, Use and the sessions of ls01 to ls13), by the parent's band
  for (final (int, double) pass in <(int, double)>[(0, 1.0), (2, 1.0), (2, 1.3)]) {
    for (final String course in languageCourses) {
      testWidgets('${board.$1}: the $course course screens, band ${pass.$1}, at text size ${pass.$2}', (
        WidgetTester t,
      ) async {
        await setScale(t, pass.$2);
        await warm(t);
        final PackContent pack = courses[course]!;
        final AppRig rig = AppRig(
          content: pack,
          characters: voices[course],
          player: FakePlayer()..endsAfter = const Duration(milliseconds: 150),
        );
        await rig.seedFinishedSetup(name: 'נֹעָה', id: langKid);
        await rig.db.putSetting(
          languagesSettingKey,
          const FamilyLanguages()
              .withSwitches(langKid, course, LanguageSwitches(on: true, band: pass.$1))!
              .encode(),
        );
        await rig.pump(t, size: board.$2);
        await t.tap(find.text('נֹעָה'));
        await t.pumpAndSettle();
        final Slice slice = Slice(board.$1, board.$2, 'B${pass.$1}-$course', pass.$2, 'lang');
        await collectErrors((List<FlutterErrorDetails> sink) async {
          for (final String id in languageReps(pack)) {
            final Activity a = pack.activities[id]!;
            if (a is SayItActivity) {
              continue; // opened inside its lesson below: a Meet item needs the set around it
            }
            final NavigatorState nav = t.state<NavigatorState>(find.byType(Navigator).first);
            nav.push(
              MaterialPageRoute<void>(
                builder: (BuildContext c) => LessonScreen(
                  profileId: langKid,
                  mission: Lesson.mission(
                    id: 'shot',
                    itemIds: <String>[a.id],
                    skillIds: <String>[a.skillId],
                    celebration: const Spoken(vo: 'vo:x.celebrate', caption: 'x'),
                  ),
                ),
              ),
            );
            await t.pump(const Duration(milliseconds: 500));
            await waitSteps(t, 1400);
            measure(t, slice, id, a.template, RuleCtx(template: a.template, language: true), sink);
            nav.pop();
            await t.pump(const Duration(milliseconds: 400));
            sink.clear();
          }
        });
        // the first screen of the lessons (the Meet screen, the first Find, the first Use): the opener said, the first word at its first beat
        final Slice first = Slice(board.$1, board.$2, 'B${pass.$1}-$course', pass.$2, 'lang-lesson');
        await collectErrors((List<FlutterErrorDetails> sink) async {
          for (final String lesson in languageLessonReps(pack)) {
            final NavigatorState nav = t.state<NavigatorState>(find.byType(Navigator).first);
            nav.push(
              MaterialPageRoute<void>(
                builder: (BuildContext c) => LessonScreen(profileId: langKid, lessonId: lesson),
              ),
            );
            await t.pump(const Duration(milliseconds: 600));
            if (openerScreenOf(pack, lesson) != null) {
              for (int spent = 0; spent < 12000 && badgeLit.evaluate().isEmpty; spent += 100) {
                await t.pump(const Duration(milliseconds: 100));
              }
              await t.pump(const Duration(milliseconds: 600));
            } else {
              await waitSteps(t, 1400);
            }
            final Activity firstItem = pack.itemsFor(pack.lessons[lesson]!, route: 'new').first;
            measure(
              t,
              first,
              lesson,
              firstItem.template,
              RuleCtx(template: firstItem.template, language: true),
              sink,
            );
            nav.pop();
            await t.pump(const Duration(milliseconds: 400));
            sink.clear();
          }
        });
        report(slice);
        report(first);
      }, timeout: const Timeout(Duration(minutes: 6)));
    }
  }

  for (final double scale in textScales) {
    for (int look = 0; look < 3; look++) {
      testWidgets(
        '${board.$1}: the Show of every kind of lesson of band ${_bandOfLook[look]} at text size $scale (look ${_lookNames[look]})',
        (WidgetTester t) async {
          await setScale(t, scale);
          await warm(t);
          final Map<String, String> lessons = <String, String>{
            for (final MapEntry<String, String> e in showLessons(content).entries)
              if (e.key.endsWith('/${_bandOfLook[look]}')) e.key: e.value,
          };
          await _startRooms(t, content, board.$2, auditLooks[look]);
          final Slice at = Slice(board.$1, board.$2, _lookNames[look], scale, 'show-host');
          final Slice turn = Slice(board.$1, board.$2, _lookNames[look], scale, 'show-turn');
          await collectErrors((List<FlutterErrorDetails> sink) async {
            for (final MapEntry<String, String> e in lessons.entries) {
              final NavigatorState nav = t.state<NavigatorState>(find.byType(Navigator).first);
              nav.push(
                MaterialPageRoute<void>(
                  builder: (BuildContext c) => LessonScreen(profileId: 'p-1', lessonId: e.value),
                ),
              );
              for (int i = 0; i < 12; i++) {
                await t.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 100)));
                await t.pump(const Duration(milliseconds: 100));
              }
              await waitSteps(t, 9500);
              final String template = e.key.split('/').first;
              measure(t, at, e.value, template, RuleCtx(template: template, show: true), sink);
              await waitSteps(t, 11500);
              measure(t, turn, e.value, template, RuleCtx(template: template, show: true), sink);
              nav.pop();
              await t.pump(const Duration(milliseconds: 600));
              sink.clear();
            }
          });
          report(at);
          report(turn);
        },
        timeout: const Timeout(Duration(minutes: 6)),
      );
    }
  }

  for (int look = 0; look < 3; look++) {
    testWidgets(
      '${board.$1}: the hint player at level 1, 2 and 3 for every hint family of band ${_bandOfLook[look]} (look ${_lookNames[look]})',
      (WidgetTester t) async {
        await setScale(t, 1.0);
        await warm(t);
        final List<String> ids = <String>[
          for (final String id in hintFamilies)
            if (content.activities[id] != null && lookOfBand[content.activities[id]!.band] == look) id,
        ];
        await startOn(t, content, board.$2, look: auditLooks[look]);
        final List<Slice> levels = <Slice>[
          for (int l = 1; l <= 3; l++) Slice(board.$1, board.$2, _lookNames[look], 1.0, 'hint$l'),
        ];
        await collectErrors((List<FlutterErrorDetails> sink) async {
          for (final String id in ids) {
            final Activity a = content.activities[id]!;
            await openFast(t, content, a);
            final Map<String, Finding> base = <String, Finding>{
              for (final Finding f in judge(
                readScreen(t, board.$2, 1.0),
                RuleCtx(template: a.template, numberLine: a is NumberLineActivity ? _range(a) : null),
              ))
                f.rule: f,
            };
            for (int level = 1; level <= 3; level++) {
              await t.tap(find.byKey(const Key('lesson-hint')), warnIfMissed: false);
              await waitSteps(t, level == 1 ? 1200 : 1800);
              measure(
                t,
                levels[level - 1],
                id,
                a.template,
                RuleCtx(
                  template: a.template,
                  hint: level,
                  numberLine: a is NumberLineActivity ? _range(a) : null,
                ),
                sink,
                inherited: base,
              );
            }
            await closeOne(t);
            sink.clear();
          }
        });
        levels.forEach(report);
      },
      timeout: const Timeout(Duration(minutes: 6)),
    );
  }

  for (final double scale in textScales) {
    for (int look = 0; look < 3; look++) {
      testWidgets(
        '${board.$1}: every band-${_bandOfLook[look]} activity at text size $scale (look ${_lookNames[look]})',
        (WidgetTester t) async {
          await setScale(t, scale);
          await warm(t);
          await startOn(t, content, board.$2, look: auditLooks[look]);
          final Slice item = Slice(board.$1, board.$2, _lookNames[look], scale, 'item');
          final Slice sorted = Slice(board.$1, board.$2, _lookNames[look], scale, 'sorted');
          // every activity of the band that is not a Show: the layouts have the same boxes but not the same pictures or words, and a sweep of the
          // whole pack showed that one activity of each layout missed 9 to 15 in 100 of the others' failures (docs/agents/qa-min-sizes-2026-11-17.md)
          final List<String> todo = <String>[
            for (final String id in (content.activities.keys.toList()..sort()))
              if (!content.activities[id]!.isShow && content.activities[id]!.band == _bandOfLook[look]) id,
          ];
          await collectErrors((List<FlutterErrorDetails> sink) async {
            for (final String id in todo) {
              final Activity a = content.activities[id]!;
              await openFast(t, content, a);
              measure(
                t,
                item,
                a.id,
                a.template,
                RuleCtx(template: a.template, numberLine: a is NumberLineActivity ? _range(a) : null),
                sink,
              );
              if (a is SortDragActivity) {
                await _sortTwo(t, a);
                measure(t, sorted, a.id, a.template, RuleCtx(template: a.template), sink);
              }
              await closeOne(t);
              sink.clear();
            }
          });
          report(item);
          report(sorted);
        },
        timeout: const Timeout(Duration(minutes: 6)),
      );
    }
  }
}
