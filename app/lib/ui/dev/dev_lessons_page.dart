import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../app/state.dart';
import '../../content/models.dart';
import '../../data/app_database.dart';
import '../../play/lesson_screen.dart';
import 'dev_strings.dart';

/// Dev flavour only (QA-10): every lesson of the pack, to open any one for a child without walking the path to it, so that
/// the newest templates can be checked on a phone. The answers given here are written for that child like any others.
/// In the prod flavour the page shows nothing (it is also never linked there).
class DevLessonsPage extends ConsumerStatefulWidget {
  const DevLessonsPage({super.key});

  @override
  ConsumerState<DevLessonsPage> createState() => _DevLessonsPageState();
}

class _DevLessonsPageState extends ConsumerState<DevLessonsPage> {
  String? _childId;
  String _template = _all;

  static const String _all = 'all templates';

  @override
  Widget build(BuildContext context) {
    if (!ref.watch(configProvider).isDev) {
      return const Scaffold(body: Center(child: Text(DevStrings.prodPlaceholder)));
    }
    final List<Profile> children = ref.watch(appStateProvider).value?.profiles ?? const <Profile>[];
    final PackContent? content = ref.watch(contentProvider).value;
    final String? child = _childId ?? children.firstOrNull?.id;
    return Scaffold(
      appBar: AppBar(title: const Text(DevStrings.lessonsTitle)),
      body: SafeArea(
        child: content == null
            ? const Center(child: CircularProgressIndicator())
            : _list(content, children, child),
      ),
    );
  }

  Widget _list(PackContent content, List<Profile> children, String? child) {
    final List<DevLessonRow> rows = devLessonRows(content);
    final List<String> templates = <String>{for (final DevLessonRow r in rows) ...r.templates}.toList()
      ..sort();
    final List<DevLessonRow> shown = <DevLessonRow>[
      for (final DevLessonRow r in rows)
        if (_template == _all || r.templates.contains(_template)) r,
    ];
    return ListView(
      padding: const EdgeInsets.all(16),
      children: <Widget>[
        const Text(DevStrings.lessonsNote),
        if (children.isEmpty) const Text(DevStrings.lessonsNoChild),
        if (children.isNotEmpty)
          DropdownButton<String>(
            key: const Key('dev-lessons-child'),
            value: child,
            items: <DropdownMenuItem<String>>[
              for (final Profile p in children) DropdownMenuItem<String>(value: p.id, child: Text(p.name)),
            ],
            onChanged: (String? id) => setState(() => _childId = id),
          ),
        DropdownButton<String>(
          key: const Key('dev-lessons-template'),
          value: _template,
          items: <DropdownMenuItem<String>>[
            for (final String t in <String>[_all, ...templates])
              DropdownMenuItem<String>(value: t, child: Text(t)),
          ],
          onChanged: (String? t) => setState(() => _template = t ?? _all),
        ),
        for (final DevLessonRow r in shown)
          ListTile(
            key: Key('dev-lesson-${r.lesson.id}'),
            dense: true,
            title: Text(r.lesson.id),
            subtitle: Text('${r.land} ${r.band} #${r.lesson.sequence} · ${r.templates.join(', ')}'),
            enabled: child != null,
            onTap: child == null
                ? null
                : () => Navigator.of(context).push(
                    MaterialPageRoute<bool>(
                      builder: (BuildContext c) => LessonScreen(profileId: child, lessonId: r.lesson.id),
                    ),
                  ),
          ),
      ],
    );
  }
}

/// One lesson as the dev list shows it: its land and band (from its first skill) and the templates it plays.
class DevLessonRow {
  const DevLessonRow(this.lesson, this.land, this.band, this.templates);

  final Lesson lesson;
  final String land;
  final String band;
  final List<String> templates;
}

/// Every lesson of [content], by land, then band, then its place in the path.
List<DevLessonRow> devLessonRows(PackContent content) {
  final List<DevLessonRow> rows = <DevLessonRow>[
    for (final Lesson l in content.lessons.values)
      DevLessonRow(
        l,
        content.skills[l.skillIds.firstOrNull]?.domain ?? '-',
        // A skill id is LAND-band-number, as NUM-A-07.
        l.skillIds.firstOrNull?.split('-').elementAtOrNull(1) ?? '-',
        <String>{for (final String id in l.itemIds) ?content.activities[id]?.template}.toList()..sort(),
      ),
  ];
  rows.sort(
    (DevLessonRow a, DevLessonRow b) => a.land != b.land
        ? a.land.compareTo(b.land)
        : (a.band != b.band ? a.band.compareTo(b.band) : a.lesson.sequence.compareTo(b.lesson.sequence)),
  );
  return rows;
}
