import 'package:drift/drift.dart' show Value;
import 'package:uuid/uuid.dart';

import '../data/app_database.dart';

/// One call to a gateway function, already signed and with the device's own id and token filled in.
typedef SyncCall = Future<Map<String, Object?>> Function(String name, Map<String, Object?> body);

/// What one round of syncing did, for tests and the dev page.
class SyncReport {
  const SyncReport({
    this.pushedEvents = 0,
    this.refusedEvents = 0,
    this.pulledEvents = 0,
    this.appliedEvents = 0,
    this.childrenAdded = 0,
    this.childrenDeleted = 0,
    this.pushedAlerts = 0,
    this.pulledAlerts = 0,
    this.rulesApplied = false,
  });

  final int pushedEvents;
  final int refusedEvents;
  final int pulledEvents;
  final int appliedEvents;
  final int childrenAdded;
  final int childrenDeleted;
  final int pushedAlerts;
  final int pulledAlerts;
  final bool rulesApplied;
}

/// Keeps this device and the family's other devices in step (PLAN: Sync rules).
///
/// What leaves the device: the children's profiles (parent devices only), the answers and finished visits not sent yet,
/// and alerts not sent yet. What comes in: everything the server numbered after the last event seen, the family's
/// children, and the children that were deleted. The server's own sequence number is the cursor; no device clock ever
/// decides what is sent or taken. An event is the same event however often it is sent (its id comes from the device
/// and the row), so a retry after a lost answer changes nothing. Nothing here ever throws to the caller's UI: a failed
/// round simply leaves everything for the next one.
class SyncEngine {
  SyncEngine({
    required this.db,
    required this.call,
    required this.deviceId,
    required this.isParent,
    required this.nowMs,
    this.engineVersion = 1,
    this.pageSize = 100,
    this.batch = 40,
  });

  final AppDatabase db;
  final SyncCall call;
  final String deviceId;
  final bool isParent;
  final int Function() nowMs;
  final int engineVersion;
  final int pageSize;
  final int batch;

  static const String cursorKey = 'sync_cursor';
  static final String _namespace = Namespace.url.value;

  /// The id of an event made on this device: the same row always gives the same id.
  static String eventIdOf(String deviceId, String kind, int localId) =>
      const Uuid().v5(_namespace, 'nitznutz/$deviceId/$kind/$localId');

  DateTime get _now => DateTime.fromMillisecondsSinceEpoch(nowMs(), isUtc: true);

  /// One full round. Safe to call as often as wanted, and from two places at once (the second waits for the first).
  Future<SyncReport> syncOnce() =>
      _chain = _chain.then((_) => _run()).catchError((Object _) => const SyncReport());

  Future<SyncReport> _chain = Future<SyncReport>.value(const SyncReport());

  Future<SyncReport> _run() async {
    int pushed = 0;
    int refused = 0;
    try {
      if (isParent) await _retryDeletes();
      if (isParent) await _pushProfiles();
      final ({int pushed, int refused}) p = await _pushEvents();
      pushed = p.pushed;
      refused = p.refused;
    } on Object {
      // The server is out of reach or refused: the rows stay marked "not sent" and go next time.
    }
    int pulled = 0;
    int applied = 0;
    int added = 0;
    int deleted = 0;
    try {
      final ({int pulled, int applied, int added, int deleted}) r = await _pull();
      pulled = r.pulled;
      applied = r.applied;
      added = r.added;
      deleted = r.deleted;
    } on Object {
      // Same: the cursor was not moved past anything that was not applied.
    }
    return SyncReport(
      pushedEvents: pushed,
      refusedEvents: refused,
      pulledEvents: pulled,
      appliedEvents: applied,
      childrenAdded: added,
      childrenDeleted: deleted,
    );
  }

  // ---- deleting a child ----

  static const String _pendingKey = 'sync_pending_deletes';

  Future<Set<String>> _pending() async {
    final String? raw = await db.setting(_pendingKey);
    return raw == null || raw.isEmpty ? <String>{} : raw.split(',').toSet();
  }

  /// Deletes a child here at once, and on the server (and so on every device) as soon as it can: the child is
  /// remembered as deleted, so nothing about them is ever sent again, and the deletion is retried until it is made.
  Future<void> deleteChild(String childId) async {
    await db.deleteChildData(childId);
    final Set<String> gone = await _tombstoned()
      ..add(childId);
    await _rememberTombstones(gone);
    await db.putSetting(
      _pendingKey,
      (await _pending()
            ..add(childId))
          .join(','),
    );
    await syncOnce();
  }

  Future<void> _retryDeletes() async {
    final Set<String> pending = await _pending();
    for (final String id in pending.toList()) {
      try {
        await call('child-delete', <String, Object?>{'child_id': id});
        pending.remove(id);
      } on Object {
        // Still out of reach: it stays in the list.
      }
    }
    await db.putSetting(_pendingKey, pending.join(','));
  }

  // ---- out ----

  Future<void> _pushProfiles() async {
    final Set<String> gone = await _tombstoned();
    for (final Profile p in await db.allProfiles()) {
      if (gone.contains(p.id)) continue;
      final String fingerprint = '${p.name}|${p.avatar}|${p.addressForm}|${p.ageBand}|${p.companionId ?? ''}';
      if (await db.setting('profile_pushed_${p.id}') == fingerprint) continue;
      try {
        await call('child-put', <String, Object?>{
          'child_id': p.id,
          'nickname': p.name,
          'avatar_id': p.avatar,
          'companion_id': ?p.companionId,
          'address_form': p.addressForm,
          'age_band': p.ageBand,
        });
      } on Object {
        // One child that cannot be saved (a deleted one, a bad value) must not stop the others or the answers.
        continue;
      }
      await db.putSetting('profile_pushed_${p.id}', fingerprint);
    }
  }

  Map<String, Object?> _attemptEvent(Attempt a) => <String, Object?>{
    'id': eventIdOf(deviceId, 'attempt', a.id),
    'child_id': a.profileId,
    'at': a.at.millisecondsSinceEpoch,
    'engine': engineVersion,
    'type': 'attempt',
    'data': <String, Object?>{
      'activity_id': a.activityId,
      'activity_revision': a.activityRevision,
      'pack_id': a.packId,
      'pack_version': a.packVersion,
      'lesson_id': a.lessonId,
      'template': a.template,
      'template_version': a.templateVersion,
      'skill_id': a.skillId,
      'result': a.result,
      'attempt_no': a.attemptNo,
      'hint_level': a.hintLevel,
      'misconception_tag': a.misconceptionTag,
      'response': a.response,
      'duration_ms': a.durationMs,
      'input': a.input,
      'session_local': ?a.sessionId,
    },
  };

  Map<String, Object?> _sessionEvent(Session s) => <String, Object?>{
    'id': eventIdOf(deviceId, 'session', s.id),
    'child_id': s.profileId,
    'at': s.startedAt.millisecondsSinceEpoch,
    'engine': engineVersion,
    'type': 'session',
    'data': <String, Object?>{
      'plan': s.plan,
      'started_at': s.startedAt.millisecondsSinceEpoch,
      'ended_at': s.endedAt!.millisecondsSinceEpoch,
      'end_reason': s.endReason,
      'session_local': s.id,
    },
  };

  Future<({int pushed, int refused})> _pushEvents() async {
    int pushed = 0;
    int refused = 0;
    final Set<String> gone = await _tombstoned();
    while (true) {
      final List<Session> sessions = await db.unsyncedSessions(limit: batch);
      final List<Attempt> attempts = await db.unsyncedAttempts(limit: batch);
      if (sessions.isEmpty && attempts.isEmpty) break;
      // Answers go before the visit they belong to is not needed: the server keeps the order it received.
      final List<Attempt> a = attempts.where((Attempt x) => !gone.contains(x.profileId)).toList();
      final List<Session> s = sessions.where((Session x) => !gone.contains(x.profileId)).toList();
      // Rows of a deleted child are never sent; they are marked so they stop coming back.
      final List<Attempt> dropA = attempts.where((Attempt x) => gone.contains(x.profileId)).toList();
      final List<Session> dropS = sessions.where((Session x) => gone.contains(x.profileId)).toList();
      final List<Map<String, Object?>> events = <Map<String, Object?>>[
        for (final Attempt x in a) _attemptEvent(x),
        for (final Session x in s) _sessionEvent(x),
      ].take(batch).toList();
      if (events.isNotEmpty) {
        final Map<String, Object?> answer = await call('sync-push', <String, Object?>{'events': events});
        refused += (answer['refused'] as List<Object?>? ?? const <Object?>[]).length;
        pushed += (answer['accepted'] as int? ?? 0) + (answer['duplicates'] as int? ?? 0);
      }
      // Sent, or refused (the server does not know the child): either way not sent again.
      final Set<String> inThisCall = <String>{
        for (final Map<String, Object?> e in events) e['id']! as String,
      };
      final DateTime at = _now;
      await db.markAttemptsSynced(<int>[
        ...a
            .where((Attempt x) => inThisCall.contains(eventIdOf(deviceId, 'attempt', x.id)))
            .map((Attempt x) => x.id),
        ...dropA.map((Attempt x) => x.id),
      ], at);
      await db.markSessionsSynced(<int>[
        ...s
            .where((Session x) => inThisCall.contains(eventIdOf(deviceId, 'session', x.id)))
            .map((Session x) => x.id),
        ...dropS.map((Session x) => x.id),
      ], at);
      if (events.isEmpty && dropA.isEmpty && dropS.isEmpty) break;
    }
    return (pushed: pushed, refused: refused);
  }

  // ---- in ----

  Future<Set<String>> _tombstoned() async {
    final String? raw = await db.setting('sync_tombstones');
    return raw == null || raw.isEmpty ? <String>{} : raw.split(',').toSet();
  }

  Future<void> _rememberTombstones(Set<String> ids) => db.putSetting('sync_tombstones', ids.join(','));

  Future<({int pulled, int applied, int added, int deleted})> _pull() async {
    int pulled = 0;
    int applied = 0;
    int added = 0;
    int deleted = 0;
    int cursor = int.tryParse(await db.setting(cursorKey) ?? '') ?? 0;
    while (true) {
      final Map<String, Object?> page = await call('sync-pull', <String, Object?>{
        'after': cursor,
        'limit': pageSize,
      });

      // The family: forget the children that were deleted, take on the ones this device has not met.
      final Set<String> gone = await _tombstoned();
      final List<String> tombs = <String>[
        for (final Object? t in (page['tombstones'] as List<Object?>? ?? const <Object?>[])) t! as String,
      ];
      for (final String id in tombs) {
        if (gone.add(id)) {
          await db.deleteChildData(id);
          deleted++;
        } else if ((await db.allProfiles()).any((Profile p) => p.id == id)) {
          await db.deleteChildData(id);
          deleted++;
        }
      }
      await _rememberTombstones(gone);
      final List<Profile> mine = await db.allProfiles();
      for (final Object? c in (page['children'] as List<Object?>? ?? const <Object?>[])) {
        final Map<String, Object?> m = c! as Map<String, Object?>;
        final String id = m['id']! as String;
        if (gone.contains(id)) continue;
        final ProfilesCompanion row = ProfilesCompanion(
          id: Value<String>(id),
          name: Value<String>(m['nickname']! as String),
          avatar: Value<String>(m['avatar_id']! as String),
          addressForm: Value<String>(m['address_form']! as String),
          ageBand: Value<int>(m['age_band']! as int),
          companionId: Value<String?>(m['companion_id'] as String?),
          createdAt: Value<DateTime>(_now),
        );
        final bool known = mine.any((Profile p) => p.id == id);
        if (!known) added++;
        await db.upsertProfileFromFamily(row, isNew: !known);
        // What the server has is now what this device has: no need to push it back.
        await db.putSetting(
          'profile_pushed_$id',
          '${m['nickname']}|${m['avatar_id']}|${m['address_form']}|${m['age_band']}|${m['companion_id'] ?? ''}',
        );
      }

      final Set<String> known = <String>{for (final Profile p in await db.allProfiles()) p.id};
      final List<Map<String, Object?>> events = <Map<String, Object?>>[
        for (final Object? e in (page['events'] as List<Object?>? ?? const <Object?>[]))
          e! as Map<String, Object?>,
      ];
      for (final Map<String, Object?> e in events) {
        pulled++;
        if (e['device_id'] == deviceId) continue; // made here
        if (!known.contains(e['child_id'])) continue;
        if (await _apply(e)) applied++;
      }
      final int next = page['next'] as int? ?? cursor;
      cursor = next;
      await db.putSetting(cursorKey, '$cursor');
      if (page['more'] != true || events.isEmpty) break;
    }
    return (pulled: pulled, applied: applied, added: added, deleted: deleted);
  }

  /// Takes one event from another device into the local tables. False if it was already here.
  Future<bool> _apply(Map<String, Object?> e) async {
    final Map<String, Object?> d = e['data']! as Map<String, Object?>;
    final String id = e['id']! as String;
    final String from = e['device_id']! as String;
    final DateTime at = DateTime.fromMillisecondsSinceEpoch(e['at']! as int, isUtc: true);
    if (e['type'] == 'attempt') {
      final Object? local = d['session_local'];
      final String? key = local is int ? '$from:$local' : null;
      final int? sessionId = key == null ? null : await db.sessionIdForRemoteKey(key);
      return db.addRemoteAttempt(
        AttemptsCompanion.insert(
          at: at,
          profileId: e['child_id']! as String,
          packId: d['pack_id']! as String,
          packVersion: d['pack_version']! as String,
          lessonId: Value<String>(d['lesson_id'] as String? ?? ''),
          activityId: d['activity_id']! as String,
          activityRevision: d['activity_revision']! as int,
          template: d['template']! as String,
          templateVersion: d['template_version']! as String,
          skillId: d['skill_id']! as String,
          result: d['result']! as String,
          attemptNo: d['attempt_no']! as int,
          hintLevel: d['hint_level'] as int? ?? 0,
          misconceptionTag: Value<String>(d['misconception_tag'] as String? ?? ''),
          response: Value<String>(d['response'] as String? ?? ''),
          durationMs: Value<int>(d['duration_ms'] as int? ?? 0),
          sessionId: Value<int?>(sessionId),
          input: Value<String>(d['input'] as String? ?? 'tap'),
          remoteSession: Value<String?>(sessionId == null ? key : null),
        ),
        eventId: id,
        at: _now,
      );
    }
    final int? made = await db.addRemoteSession(
      SessionsCompanion.insert(
        profileId: e['child_id']! as String,
        startedAt: DateTime.fromMillisecondsSinceEpoch(d['started_at']! as int, isUtc: true),
        endedAt: Value<DateTime?>(
          d['ended_at'] is int
              ? DateTime.fromMillisecondsSinceEpoch(d['ended_at']! as int, isUtc: true)
              : null,
        ),
        plan: Value<String>(d['plan'] as String? ?? ''),
        endReason: Value<String>(d['end_reason'] as String? ?? ''),
      ),
      eventId: id,
      remoteKey: '$from:${d['session_local']}',
      at: _now,
    );
    return made != null;
  }
}
