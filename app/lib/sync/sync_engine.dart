import 'package:drift/drift.dart' show Value;

import 'dart:convert';

import 'package:uuid/uuid.dart';

import '../core/errors.dart';
import '../core/log.dart';
import '../data/app_database.dart';
import '../data/child_name.dart';
import '../parent/parent_rules.dart';
import '../play/response_code.dart';
import '../rewards/ribbons.dart';

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

/// What one `sync-push` (or the one-by-one retry of a refused batch) did: events taken or already there, events the server
/// refused by id (a child it does not know), and events it would not take at all ([rejected], by event id). [mismatch]:
/// the server took none of them, so it does not know this app's format; nothing is marked and the round stops.
class _Sent {
  const _Sent({this.pushed = 0, this.refused = 0, this.rejected = const <String>{}, this.mismatch = false});

  _Sent.of(Map<String, Object?> answer)
    : pushed = (answer['accepted'] as int? ?? 0) + (answer['duplicates'] as int? ?? 0),
      refused = (answer['refused'] as List<Object?>? ?? const <Object?>[]).length,
      rejected = const <String>{},
      mismatch = false;

  final int pushed;
  final int refused;
  final Set<String> rejected;
  final bool mismatch;
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

  /// The engine version the rows refused by the server were last reset under (SEC-12).
  static const String _refusedResetKey = 'sync_refused_reset_version';

  /// `sync-push`'s own limits for values the device makes (`testvectors/wire-patterns.json`, tested equal).
  static const String lessonIdPattern = r'^[a-z0-9._-]{0,40}$';
  static const int maxDurationMs = 3600000;
  static final RegExp _lessonId = RegExp(lessonIdPattern);

  /// The lesson id as `sync-push` takes it. A revisit mission of an older version was named with its skill's capitals
  /// (`mission-NUM-A-03`); it goes as the name a mission has now (`mission-num-a-03`). Anything else outside the pattern
  /// goes empty: the answer itself still counts.
  static String wireLessonId(String id) {
    final String lower = id.toLowerCase();
    return _lessonId.hasMatch(lower) ? lower : '';
  }

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
    int alertsOut = 0;
    int alertsIn = 0;
    bool rules = false;
    try {
      alertsOut = await _pushAlerts();
    } on Object {
      // Left "not sent": they go next time.
    }
    try {
      final ({int pulled, int applied, int added, int deleted}) r = await _pull();
      pulled = r.pulled;
      applied = r.applied;
      added = r.added;
      deleted = r.deleted;
    } on Object {
      // Same: the cursor was not moved past anything that was not applied.
    }
    try {
      if (isParent) alertsIn = await _pullAlerts();
    } on Object {
      // The parent sees them next time.
    }
    try {
      rules = await _syncSettings();
    } on Object {
      // The rules stay as they are here until the server can be reached.
    }
    return SyncReport(
      pushedAlerts: alertsOut,
      pulledAlerts: alertsIn,
      rulesApplied: rules,
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
      final String fingerprint =
          '${p.name}|${p.avatar}|${p.addressForm}|${p.ageBand}|${p.companionId ?? ''}|${p.outfitId ?? ''}';
      if (await db.setting('profile_pushed_${p.id}') == fingerprint) continue;
      // A name saved before B-28 could be longer than the server takes, or hold a character it refuses: it goes cut to
      // fit. One with nothing left would only be refused, so it is not sent (its answers are then refused like those of
      // any child the server does not have).
      final String nickname = fitChildNameForServer(p.name);
      if (nickname.isEmpty) continue;
      try {
        await call('child-put', <String, Object?>{
          'child_id': p.id,
          'nickname': nickname,
          'avatar_id': p.avatar,
          'companion_id': ?p.companionId,
          'outfit_id': ?p.outfitId,
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
      'lesson_id': wireLessonId(a.lessonId),
      'template': a.template,
      'template_version': a.templateVersion,
      'skill_id': a.skillId,
      'result': a.result,
      'attempt_no': a.attemptNo,
      'hint_level': a.hintLevel,
      'misconception_tag': a.misconceptionTag,
      // A code an older version wrote outside the server's pattern (SEC-1) goes without it: the answer itself still counts.
      'response': ResponseCode.fits(a.response) ? a.response : '',
      // A question left open longer than the server takes counts as that long.
      'duration_ms': a.durationMs.clamp(0, maxDurationMs),
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

  Map<String, Object?> _rewardEvent(Reward r) => <String, Object?>{
    'id': eventIdOf(deviceId, 'reward', r.id),
    'child_id': r.profileId,
    'at': r.at.millisecondsSinceEpoch,
    'engine': engineVersion,
    'type': 'reward',
    'data': <String, Object?>{'kind': r.kind, 'key': r.awardKey},
  };

  /// Once per engine version, rows the server refused under an older one are made "not sent" again, so this version sends
  /// them once more (a fixed format, or a server that has learnt the field, takes them now).
  Future<void> _resendRefusedOncePerVersion() async {
    if (await db.setting(_refusedResetKey) == '$engineVersion') return;
    await db.unmarkRefusedBySync();
    await db.putSetting(_refusedResetKey, '$engineVersion');
  }

  Future<({int pushed, int refused})> _pushEvents() async {
    int pushed = 0;
    int refused = 0;
    await _resendRefusedOncePerVersion();
    final Set<String> gone = await _tombstoned();
    // True once the server took a call of this round: it knows this app's format, so an event it refuses alone is bad.
    bool understood = false;
    while (true) {
      final List<Session> sessions = await db.unsyncedSessions(limit: batch);
      final List<Attempt> attempts = await db.unsyncedAttempts(limit: batch);
      final List<Reward> rewards = await db.unsyncedRewards(limit: batch);
      if (sessions.isEmpty && attempts.isEmpty && rewards.isEmpty) break;
      // Answers go before the visit they belong to is not needed: the server keeps the order it received.
      final List<Attempt> a = attempts.where((Attempt x) => !gone.contains(x.profileId)).toList();
      final List<Session> s = sessions.where((Session x) => !gone.contains(x.profileId)).toList();
      // Rows of a deleted child are never sent; they are marked so they stop coming back.
      final List<Attempt> dropA = attempts.where((Attempt x) => gone.contains(x.profileId)).toList();
      final List<Session> dropS = sessions.where((Session x) => gone.contains(x.profileId)).toList();
      final List<Reward> w = rewards.where((Reward x) => !gone.contains(x.profileId)).toList();
      final List<Reward> dropW = rewards.where((Reward x) => gone.contains(x.profileId)).toList();
      final List<Map<String, Object?>> events = <Map<String, Object?>>[
        for (final Attempt x in a) _attemptEvent(x),
        for (final Session x in s) _sessionEvent(x),
        for (final Reward x in w) _rewardEvent(x),
      ].take(batch).toList();
      final _Sent sent = events.isEmpty ? const _Sent() : await _send(events, understood: understood);
      understood = understood || (events.isNotEmpty && !sent.mismatch);
      pushed += sent.pushed;
      refused += sent.refused + sent.rejected.length;
      // Sent, or refused (the server does not know the child, or would not take the row): either way not sent again.
      // After a format mismatch none of them is either: they all wait for the next round.
      final Set<String> inThisCall = <String>{
        if (!sent.mismatch)
          for (final Map<String, Object?> e in events) e['id']! as String,
      };
      List<int> went(String kind, Iterable<int> ids, {bool rejected = false}) => <int>[
        for (final int id in ids)
          if (inThisCall.contains(eventIdOf(deviceId, kind, id)) &&
              sent.rejected.contains(eventIdOf(deviceId, kind, id)) == rejected)
            id,
      ];
      final DateTime at = _now;
      final Iterable<int> aIds = a.map((Attempt x) => x.id);
      final Iterable<int> sIds = s.map((Session x) => x.id);
      final Iterable<int> wIds = w.map((Reward x) => x.id);
      await db.markAttemptsSynced(<int>[...went('attempt', aIds), ...dropA.map((Attempt x) => x.id)], at);
      await db.markSessionsSynced(<int>[...went('session', sIds), ...dropS.map((Session x) => x.id)], at);
      await db.markRewardsSynced(<int>[...went('reward', wIds), ...dropW.map((Reward x) => x.id)], at);
      if (sent.rejected.isNotEmpty) {
        final DateTime never = AppDatabase.refusedBySync;
        await db.markAttemptsSynced(went('attempt', aIds, rejected: true), never);
        await db.markSessionsSynced(went('session', sIds, rejected: true), never);
        await db.markRewardsSynced(went('reward', wIds, rejected: true), never);
      }
      if (sent.mismatch) break;
      if (events.isEmpty && dropA.isEmpty && dropS.isEmpty && dropW.isEmpty) break;
    }
    return (pushed: pushed, refused: refused);
  }

  /// Sends [events] in one call. When the server refuses the call as a whole (`bad_request`: one event it will not take
  /// refuses the batch), they are sent again one by one, so that the good ones get in and the one it will not take is known
  /// by its id. Any other failure (no network, the server down) is thrown: everything stays for the next round.
  ///
  /// When the server takes none of them alone, and there were two or more, or there was one and the server has taken
  /// nothing this round ([understood] false), it is not a bad row but a server that does not know this app's format (a
  /// gateway deployed out of order, SEC-12): the answer is a [_Sent.mismatch] and no event is marked refused.
  Future<_Sent> _send(List<Map<String, Object?>> events, {required bool understood}) async {
    try {
      return _Sent.of(await call('sync-push', <String, Object?>{'events': events}));
    } on GatewayException catch (e) {
      if (e.code != 'bad_request') rethrow;
    }
    int pushed = 0;
    int refused = 0;
    final Set<String> rejected = <String>{};
    for (final Map<String, Object?> e in events) {
      try {
        final _Sent one = _Sent.of(
          await call('sync-push', <String, Object?>{
            'events': <Map<String, Object?>>[e],
          }),
        );
        pushed += one.pushed;
        refused += one.refused;
      } on GatewayException catch (x) {
        if (x.code != 'bad_request') rethrow;
        rejected.add(e['id']! as String);
      }
    }
    if (rejected.length == events.length && (events.length > 1 || !understood)) {
      Log.d('sync: format mismatch, ${events.length} events kept for the next round');
      return const _Sent(mismatch: true);
    }
    if (rejected.isNotEmpty) {
      Log.d('sync: ${rejected.length} of ${events.length} events refused by the server');
    }
    return _Sent(pushed: pushed, refused: refused, rejected: rejected);
  }

  // ---- alerts and the family's rules ----

  /// Sends the alerts found on this device that the family has not been told about. Returns how many were sent.
  Future<int> _pushAlerts() async {
    int sent = 0;
    final Set<String> gone = await _tombstoned();
    while (true) {
      final List<Alert> rows = await db.unsyncedAlerts(limit: batch);
      if (rows.isEmpty) break;
      final List<int> done = <int>[];
      for (final Alert a in rows) {
        if (a.profileId != null && gone.contains(a.profileId)) {
          done.add(a.id);
          continue;
        }
        final Map<String, Object?> answer = await call('alert-create', <String, Object?>{
          'child_id': ?a.profileId,
          'category': a.category,
          'severity': a.severity,
          'count': a.count,
          if (a.detail.isNotEmpty) 'detail': a.detail,
          if (a.words.isNotEmpty) 'words': a.words,
          'key': a.dedupeKey,
          'at': a.at.millisecondsSinceEpoch,
        });
        // New, a duplicate, or refused (the server does not know the child): the alert is not sent again.
        done.add(a.id);
        if (answer['status'] == 'new') sent++;
      }
      await db.markAlertsSynced(done, _now);
      if (rows.length < batch) break;
    }
    return sent;
  }

  /// A parent device takes in the alerts the family's other devices raised. Returns how many were new here.
  Future<int> _pullAlerts() async {
    final Map<String, Object?> answer = await call('alert-list', const <String, Object?>{});
    final Set<String> gone = await _tombstoned();
    int added = 0;
    for (final Object? raw in (answer['alerts'] as List<Object?>? ?? const <Object?>[])) {
      final Map<String, Object?> a = raw! as Map<String, Object?>;
      final String? child = a['child_id'] as String?;
      if (child != null && gone.contains(child)) continue;
      final bool fresh = await db.addAlert(
        AlertsCompanion.insert(
          at: DateTime.fromMillisecondsSinceEpoch(a['at']! as int, isUtc: true),
          profileId: Value<String?>(child),
          category: a['category']! as String,
          severity: a['severity']! as String,
          count: Value<int>(a['count'] as int? ?? 0),
          detail: Value<String>(a['detail'] as String? ?? ''),
          words: Value<String>(a['words'] as String? ?? ''),
          dedupeKey: a['key']! as String,
          // Raised elsewhere: never sent back.
          syncedAt: Value<DateTime?>(_now),
        ),
      );
      if (fresh) added++;
    }
    return added;
  }

  static const String _versionKey = 'settings_version';
  static const String _fingerprintKey = 'settings_fingerprint';

  /// The family's rules as this device holds them: the time rules, whether the child's words are kept, and the AI helper.
  Future<Map<String, Object?>> _localRules() async => <String, Object?>{
    ...ParentRules.decode(await db.setting('parent_rules')).toJson(),
    'keepWords': await db.setting('keep_words') != 'off',
    'aiHelper': await db.setting('ai_helper') == 'on',
    'ceremonies': await db.setting('ceremonies') != 'off',
    'ribbons': decodeRibbons(await db.setting('ribbons')),
  };

  /// Keeps the family's rules the same on every device, the last write by the server's count winning. A parent device
  /// that changed the rules since it last synced sends them; any other device (and a parent device that has never
  /// synced) takes the server's rules if they are newer. A new phone therefore takes the family's rules instead of
  /// sending its defaults over them. Returns true if the rules here were replaced.
  Future<bool> _syncSettings() async {
    final String? lastFingerprint = await db.setting(_fingerprintKey);
    final String local = jsonEncode(await _localRules());
    int version = int.tryParse(await db.setting(_versionKey) ?? '') ?? 0;
    if (isParent && lastFingerprint != null && lastFingerprint != local) {
      final Map<String, Object?> put = await call('settings-put', <String, Object?>{'rules_json': local});
      version = put['version']! as int;
      await db.putSetting(_versionKey, '$version');
      await db.putSetting(_fingerprintKey, local);
      return false;
    }
    final Map<String, Object?> got = await call('settings-get', const <String, Object?>{});
    final int serverVersion = got['version'] as int? ?? 0;
    final Object? rules = got['rules'];
    if (serverVersion > version && rules is Map<String, Object?>) {
      await db.putSetting('parent_rules', ParentRules.fromJson(rules).encode());
      await db.putSetting('keep_words', rules['keepWords'] == false ? 'off' : 'on');
      await db.putSetting('ai_helper', rules['aiHelper'] == true ? 'on' : 'off');
      await db.putSetting('ceremonies', rules['ceremonies'] == false ? 'off' : 'on');
      // The promises are taken as the server has them, each one checked again here.
      final Object? ribbons = rules['ribbons'];
      await db.putSetting(
        'ribbons',
        encodeRibbons(decodeRibbons(ribbons == null ? null : jsonEncode(ribbons))),
      );
      await db.putSetting(_versionKey, '$serverVersion');
      await db.putSetting(_fingerprintKey, jsonEncode(await _localRules()));
      return true;
    }
    if (isParent && lastFingerprint == null) {
      // Never synced and the server has nothing: these are the family's first rules.
      final Map<String, Object?> put = await call('settings-put', <String, Object?>{'rules_json': local});
      await db.putSetting(_versionKey, '${put['version']}');
    }
    await db.putSetting(_fingerprintKey, local);
    return false;
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
      final Map<String, Profile> mine = <String, Profile>{
        for (final Profile p in await db.allProfiles()) p.id: p,
      };
      for (final Object? c in (page['children'] as List<Object?>? ?? const <Object?>[])) {
        final Map<String, Object?> m = c! as Map<String, Object?>;
        final String id = m['id']! as String;
        if (gone.contains(id)) continue;
        final Profile? here = mine[id];
        final String nickname = m['nickname']! as String;
        // A name longer than the server takes went cut (B-28): the server's copy is this phone's name, kept whole here.
        final String name = here != null && fitChildNameForServer(here.name) == nickname
            ? here.name
            : nickname;
        final ProfilesCompanion row = ProfilesCompanion(
          id: Value<String>(id),
          name: Value<String>(name),
          avatar: Value<String>(m['avatar_id']! as String),
          addressForm: Value<String>(m['address_form']! as String),
          ageBand: Value<int>(m['age_band']! as int),
          companionId: Value<String?>(m['companion_id'] as String?),
          // A prize the server does not know about yet never wipes the one chosen here.
          outfitId: m['outfit_id'] is String
              ? Value<String?>(m['outfit_id']! as String)
              : const Value<String?>.absent(),
          createdAt: Value<DateTime>(_now),
        );
        final bool known = here != null;
        if (!known) added++;
        await db.upsertProfileFromFamily(row, isNew: !known);
        // What the server has is now what this device has: no need to push it back.
        await db.putSetting(
          'profile_pushed_$id',
          '$name|${m['avatar_id']}|${m['address_form']}|${m['age_band']}|${m['companion_id'] ?? ''}|${m['outfit_id'] ?? ''}',
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
    if (e['type'] == 'reward') {
      final String key = d['key']! as String;
      return db.addRemoteReward(
        RewardsCompanion.insert(
          profileId: e['child_id']! as String,
          awardKey: key,
          kind: d['kind']! as String,
          at: at,
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
