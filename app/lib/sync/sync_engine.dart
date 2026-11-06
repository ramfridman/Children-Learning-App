import 'package:drift/drift.dart' show Value;

import 'dart:convert';
import 'dart:math' as math;

import 'package:uuid/uuid.dart';

import '../core/errors.dart';
import '../core/log.dart';
import '../data/app_database.dart';
import '../data/child_name.dart';
import '../engine/age.dart' show SchoolStage;
import '../engine/course.dart';
import '../parent/language_settings.dart';
import '../parent/look_settings.dart';
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
/// refused by id (a child it does not know), and events it would not take at all ([rejected], by event id).
class _Sent {
  const _Sent({this.pushed = 0, this.refused = 0, this.rejected = const <String>{}});

  _Sent.of(Map<String, Object?> answer)
    : pushed = (answer['accepted'] as int? ?? 0) + (answer['duplicates'] as int? ?? 0),
      refused = (answer['refused'] as List<Object?>? ?? const <Object?>[]).length,
      rejected = const <String>{};

  final int pushed;
  final int refused;
  final Set<String> rejected;
}

/// What one round of sending events knows so far, for each kind of event (`attempt`, `session`, `reward`; the names are
/// those of the event ids and of the wire's `type`). The server's format is judged per kind: an answer carries keys a
/// visit does not, so a server that has taken a visit has not shown that it takes answers (QA-17).
class _Round {
  /// [waiting] are the kinds still in the wait after a stalled round: they are not read in this round.
  _Round({Set<String> waiting = const <String>{}}) : givenUp = <String>{...waiting} {
    for (final String k in SyncEngine._kinds) {
      understood[k] = false;
      suspects[k] = <int>{};
      after[k] = 0;
    }
  }

  /// True once the server answered for an event of the kind in this round (took it, had it, or refused its child): it knows
  /// the format, so an event of the kind it refuses on its own is a bad row.
  final Map<String, bool> understood = <String, bool>{};

  /// The rows (local ids) the server refused on their own before it showed that it knows the format: bad rows, or a server
  /// that does not know the format. The verdict comes with the first event of the kind that the server takes (QA-18).
  final Map<String, Set<int>> suspects = <String, Set<int>>{};

  /// Rows numbered this or lower are left out of the next batches: they wait in [suspects].
  final Map<String, int> after = <String, int>{};

  /// How many batches (of any kind) had suspects in them, one budget for the whole round (SEC-B20-4); [newSuspects] says
  /// the batch just settled added some.
  int suspectBatches = 0;
  bool newSuspects = false;

  /// The kinds not read any more in this round: waiting, or given up after the budget and the probe.
  final Set<String> givenUp;

  /// The kinds whose probe (the newest unsent row) was refused too.
  final Set<String> probeFailed = <String>{};

  /// The kinds that end the round without a verdict: they hold suspects, or their probe was refused. A round with any is
  /// a stall.
  Set<String> get stalled => <String>{
    for (final String k in SyncEngine._kinds)
      if (suspects[k]!.isNotEmpty || probeFailed.contains(k)) k,
  };
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
    int Function()? serverNowMs,
    this.engineVersion = 1,
    this.wireFormat = currentWireFormat,
    this.pageSize = 100,
    this.batch = 40,
  }) : _serverNowMs = serverNowMs;

  final AppDatabase db;
  final SyncCall call;
  final String deviceId;
  final bool isParent;
  final int Function() nowMs;

  /// The server's time as the gateway client knows it: an alert's time is never sent later than this (a phone whose
  /// clock runs fast). The gateway stores the earlier of the two anyway (SEC-30); one older than that refused a time
  /// more than two minutes ahead of its own.
  late final int Function() serverNowMs = _serverNowMs ?? nowMs;
  final int Function()? _serverNowMs;
  final int engineVersion;

  /// The format of the events as the server takes them. It goes up when `testvectors/wire-patterns.json` changes (a pin test
  /// holds the two together); the rows the server refused under an older one are then sent once more (R2). The events' own
  /// `engine` number is another thing and is never raised for this.
  final int wireFormat;
  final int pageSize;
  final int batch;

  static const String cursorKey = 'sync_cursor';
  static final String _namespace = Namespace.url.value;

  /// The wire format of this build (see [wireFormat]).
  static const int currentWireFormat = 2;

  /// The wire format the rows refused by the server were last reset under (SEC-12). Not the key of the engine version that
  /// came before it (`sync_refused_reset_version`): the first start of the build that brought this resets once more, which
  /// sends again the answers that QA-17 marked refused by mistake.
  static const String _refusedResetKey = 'sync_refused_reset_format';
  static const String _stallKey = 'sync_stall';

  /// `sync-push`'s own limits for values the device makes (`testvectors/wire-patterns.json`, tested equal).
  static const int minClientMs = AppDatabase.serverTimeFloorMs;
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

  /// A time of an event as `sync-push` takes it (SEC-B20-1): never earlier than [minClientMs] and never later than the
  /// server's time. One from a clock that was wrong (before the floor) keeps its place in time by the phone's offset from
  /// the server's time now, then is held inside the range; a row is re-timed, never dropped, and the time kept on the
  /// phone is not touched.
  int _wireTime(int t) {
    final int server = serverNowMs();
    final int shifted = t < minClientMs ? t + (server - nowMs()) : t;
    return shifted.clamp(minClientMs, math.max(server, minClientMs));
  }

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
    try {
      // The family's "keep the words" may have just changed, and 30 days may have passed (SEC-28).
      await db.tidyAlerts(_now);
    } on Object {
      // Next round.
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
      final String fingerprint = _profileFingerprint(
        p.name,
        p.avatar,
        p.addressForm,
        p.ageBand,
        p.companionId,
        p.outfitId,
        SchoolStage.fromWire(p.schoolStage),
      );
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
          // The school stage a parent confirmed, as its word. Nothing else about the child's age is ever sent: the month and
          // year of birth stay on this device (B-29).
          if (SchoolStage.fromWire(p.schoolStage) case final SchoolStage stage) 'school_stage': stage.wire,
        });
      } on Object {
        // One child that cannot be saved (a deleted one, a bad value) must not stop the others or the answers.
        continue;
      }
      await db.putSetting('profile_pushed_${p.id}', fingerprint);
    }
  }

  /// What was last saved on the server for a child, as one string. The school stage is in it, so confirming one sends the child
  /// again; the month and year of birth are not, because they are not sent.
  static String _profileFingerprint(
    String name,
    String avatar,
    String addressForm,
    int ageBand,
    String? companionId,
    String? outfitId,
    SchoolStage? stage,
  ) => '$name|$avatar|$addressForm|$ageBand|${companionId ?? ''}|${outfitId ?? ''}|${stage?.wire ?? ''}';

  /// The children whose rows wait (B-32): on a parent device, the ones this device has not yet saved on the server (no
  /// `profile_pushed_<id>` key; a failed `child-put` leaves none). The server refuses the rows of a child it does not
  /// know, and a refused row is never sent again, so the answers, visits, awards and alerts of such a child stay "not
  /// sent" and go in the round after the first successful `child-put`. A device that is not a parent never pushes
  /// children: the ones it has came from the server, so nothing waits there. A deleted child is not held (its rows are
  /// dropped).
  Future<Set<String>> _childrenNotOnServer() async {
    if (!isParent) return const <String>{};
    final Set<String> gone = await _tombstoned();
    return <String>{
      for (final Profile p in await db.allProfiles())
        if (!gone.contains(p.id) && await db.setting('profile_pushed_${p.id}') == null) p.id,
    };
  }

  Map<String, Object?> _attemptEvent(Attempt a) => <String, Object?>{
    'id': eventIdOf(deviceId, 'attempt', a.id),
    'child_id': a.profileId,
    'at': _wireTime(a.at.millisecondsSinceEpoch),
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
      // The course of a language answer (the lands send none, and none means `core`).
      if (Course.ofSkillId(a.skillId) != Course.core) 'course': Course.ofSkillId(a.skillId),
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

  Map<String, Object?> _sessionEvent(Session s) {
    final int start = _wireTime(s.startedAt.millisecondsSinceEpoch);
    // The two times move together; the end never comes before the start.
    final int end = math.max(start, _wireTime(s.endedAt!.millisecondsSinceEpoch));
    return <String, Object?>{
      'id': eventIdOf(deviceId, 'session', s.id),
      'child_id': s.profileId,
      'at': start,
      'engine': engineVersion,
      'type': 'session',
      'data': <String, Object?>{
        'plan': s.plan,
        'started_at': start,
        'ended_at': end,
        'end_reason': s.endReason,
        'session_local': s.id,
      },
    };
  }

  Map<String, Object?> _rewardEvent(Reward r) => <String, Object?>{
    'id': eventIdOf(deviceId, 'reward', r.id),
    'child_id': r.profileId,
    'at': _wireTime(r.at.millisecondsSinceEpoch),
    'engine': engineVersion,
    'type': 'reward',
    'data': <String, Object?>{'kind': r.kind, 'key': r.awardKey},
  };

  /// The kinds of event, in the order they are read (and the names of the event ids).
  static const List<String> _kinds = <String>['attempt', 'session', 'reward'];

  /// Batches (of any kind, one budget for the round) that the server refuses event by event before it has shown that it
  /// takes the kind: each costs a call for the batch and one for each of its events. When they are used up, every kind
  /// still without a verdict gets one probe, the newest unsent row of the kind, and is given up if that is refused too. A
  /// round that gives a kind up is a stall (see [stallWait]).
  static const int maxSuspectBatches = 2;

  /// Once per wire format, rows the server refused under an older one are made "not sent" again, so this version sends
  /// them once more (a fixed format, or a server that has learnt the field, takes them now). A stall is forgotten too: a
  /// new format may be the one the server was waiting for.
  Future<void> _resendRefusedOncePerFormat() async {
    if (await db.setting(_refusedResetKey) == '$wireFormat') return;
    await db.unmarkRefusedBySync();
    await db.putSetting(_stallKey, '');
    await db.putSetting(_refusedResetKey, '$wireFormat');
  }

  // ---- a stall: backing off ----

  /// How long a round that stalled (the server took no event of a kind, so it may not know this app's format) is followed by
  /// no event call for the kinds that stalled: the first time [stallBase], then twice as long each time, at most
  /// [stallCap]. The other kinds go on as usual (SEC-B20-3). Without it every round of every five minutes would spend a
  /// call per event on rows the server will not take (41 per batch), against `sync-push`'s 600 calls an hour. Setting
  /// `sync_stall`: the number of stalled rounds in a row, when the last one was, and the kinds that stalled (`1,<ms>,reward`
  /// or `2,<ms>,attempt+session`).
  static const Duration stallBase = Duration(minutes: 5);
  static const Duration stallCap = Duration(hours: 1);

  /// The wait after the [count]th stalled round in a row.
  static Duration stallWait(int count) {
    final Duration wait = stallBase * (1 << math.min(math.max(count - 1, 0), 10));
    return wait > stallCap ? stallCap : wait;
  }

  /// The stalled rounds in a row, the time (the device's clock) of the last one and the kinds that stalled; null when the
  /// last round did not stall, or the setting is not one this engine wrote.
  Future<({int count, int at, Set<String> kinds})?> _stall() async {
    final List<String> parts = (await db.setting(_stallKey) ?? '').split(',');
    if (parts.length != 3) return null;
    final int? count = int.tryParse(parts[0]);
    final int? at = int.tryParse(parts[1]);
    final Set<String> kinds = parts[2].split('+').where(_kinds.contains).toSet();
    return count == null || count < 1 || at == null || kinds.isEmpty
        ? null
        : (count: count, at: at, kinds: kinds);
  }

  /// The kinds that are still in the wait after a stalled round; none when it is over. A clock that went back does not hold
  /// the sync for ever.
  Future<Set<String>> _waitingKinds() async {
    final ({int count, int at, Set<String> kinds})? stall = await _stall();
    if (stall == null) return const <String>{};
    final int since = nowMs() - stall.at;
    return since >= 0 && since < stallWait(stall.count).inMilliseconds ? stall.kinds : const <String>{};
  }

  /// Records how the round ended: [stalled] kinds start (or lengthen) a wait, in which the [skipped] ones, still waiting
  /// from before, stay; a round that stalled nothing and skipped nothing ends the wait. A round that only skipped changes
  /// nothing.
  Future<void> _noteStall({required Set<String> stalled, required Set<String> skipped}) async {
    final ({int count, int at, Set<String> kinds})? before = await _stall();
    if (stalled.isEmpty) {
      if (before != null && skipped.isEmpty) await db.putSetting(_stallKey, '');
      return;
    }
    final String kinds = (<String>{...stalled, ...skipped}.toList()..sort()).join('+');
    await db.putSetting(_stallKey, '${(before?.count ?? 0) + 1},${nowMs()},$kinds');
  }

  // ---- sending events ----

  Future<({int pushed, int refused})> _pushEvents() async {
    int pushed = 0;
    int refused = 0;
    await _resendRefusedOncePerFormat();
    final Set<String> waiting = await _waitingKinds();
    final Set<String> gone = await _tombstoned();
    final _Round round = _Round(waiting: waiting);
    while (true) {
      // Read again for each batch: a child made during a long round is held at once.
      final Set<String> held = await _childrenNotOnServer();
      // Rows already refused alone in this round wait for their verdict and are left out; a kind given up on is not read.
      final List<Session> sessions = round.givenUp.contains('session')
          ? const <Session>[]
          : await db.unsyncedSessions(limit: batch, except: held, after: round.after['session']!);
      final List<Attempt> attempts = round.givenUp.contains('attempt')
          ? const <Attempt>[]
          : await db.unsyncedAttempts(limit: batch, except: held, after: round.after['attempt']!);
      final List<Reward> rewards = round.givenUp.contains('reward')
          ? const <Reward>[]
          : await db.unsyncedRewards(limit: batch, except: held, after: round.after['reward']!);
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
      final _Sent sent = events.isEmpty ? const _Sent() : await _send(events);
      pushed += sent.pushed;
      refused += sent.refused;
      final Set<String> inCall = <String>{for (final Map<String, Object?> e in events) e['id']! as String};
      final DateTime at = _now;
      final Map<String, (List<int>, List<int>)> rows = <String, (List<int>, List<int>)>{
        'attempt': (a.map((Attempt x) => x.id).toList(), dropA.map((Attempt x) => x.id).toList()),
        'session': (s.map((Session x) => x.id).toList(), dropS.map((Session x) => x.id).toList()),
        'reward': (w.map((Reward x) => x.id).toList(), dropW.map((Reward x) => x.id).toList()),
      };
      for (final MapEntry<String, (List<int>, List<int>)> kind in rows.entries) {
        refused += await _settle(
          round,
          kind.key,
          ids: kind.value.$1,
          dropped: kind.value.$2,
          inCall: inCall,
          rejected: sent.rejected,
          at: at,
        );
      }
      if (round.newSuspects) round.suspectBatches++;
      round.newSuspects = false;
      if (round.suspectBatches >= maxSuspectBatches) {
        // The budget is used up: one probe for each kind without a verdict, then the rest of the round, or no more of it.
        for (final String kind in _kinds) {
          if (round.understood[kind]! || round.givenUp.contains(kind)) continue;
          final ({int pushed, int refused}) probed = await _probe(round, kind, gone);
          pushed += probed.pushed;
          refused += probed.refused;
          if (!round.understood[kind]!) round.givenUp.add(kind);
        }
      }
      if (events.isEmpty && dropA.isEmpty && dropS.isEmpty && dropW.isEmpty) break;
    }
    final Set<String> stalled = round.stalled;
    if (stalled.isNotEmpty) {
      final int kept = round.suspects.values.fold(0, (int n, Set<int> ids) => n + ids.length);
      Log.d('sync: format mismatch, $kept events kept for the next round');
    }
    await _noteStall(stalled: stalled, skipped: waiting);
    return (pushed: pushed, refused: refused);
  }

  /// One last try for a [kind] the round is about to give up on: its newest unsent row (not one of the suspects), sent
  /// alone. If the server takes it the kind is understood, every suspect is a bad row and the round goes on with the rows
  /// after them; if it is refused too the kind stalls (SEC-B20-1). Without it 80 bad rows at the head of the queue would
  /// stop the good rows behind them for ever, since every round starts from the oldest.
  Future<({int pushed, int refused})> _probe(_Round round, String kind, Set<String> gone) async {
    final Set<String> skip = <String>{...await _childrenNotOnServer(), ...gone};
    final int after = round.after[kind]!;
    final (int, Map<String, Object?>)? row = switch (kind) {
      'attempt' => <(int, Map<String, Object?>)>[
        for (final Attempt x in await db.unsyncedAttempts(
          limit: 1,
          except: skip,
          after: after,
          newestFirst: true,
        ))
          (x.id, _attemptEvent(x)),
      ].firstOrNull,
      'session' => <(int, Map<String, Object?>)>[
        for (final Session x in await db.unsyncedSessions(
          limit: 1,
          except: skip,
          after: after,
          newestFirst: true,
        ))
          (x.id, _sessionEvent(x)),
      ].firstOrNull,
      _ => <(int, Map<String, Object?>)>[
        for (final Reward x in await db.unsyncedRewards(
          limit: 1,
          except: skip,
          after: after,
          newestFirst: true,
        ))
          (x.id, _rewardEvent(x)),
      ].firstOrNull,
    };
    if (row == null) return (pushed: 0, refused: 0);
    final _Sent sent = await _send(<Map<String, Object?>>[row.$2]);
    if (sent.rejected.isNotEmpty) {
      round.probeFailed.add(kind);
      return (pushed: 0, refused: 0);
    }
    final int marked = await _settle(
      round,
      kind,
      ids: <int>[row.$1],
      dropped: const <int>[],
      inCall: <String>{row.$2['id']! as String},
      rejected: sent.rejected,
      at: _now,
    );
    return (pushed: sent.pushed, refused: sent.refused + marked);
  }

  /// Marks what became of the rows of one [kind] in one call: those the server took (or had, or refused by id) and those of
  /// a deleted child are done; a row it would not take on its own is a bad row (marked refused, never sent again) once the
  /// server has shown that it takes the kind in this round, and a suspect until then (marked nothing, left out of the next
  /// batches of the round, so that the rows after it still go: QA-18). The first event of the kind the server takes gives
  /// the verdict on every suspect: bad rows. A round that ends with suspects left is a stall; they all wait for the next
  /// round. Whether a kind is given up is for [_pushEvents] to say (the budget of suspect batches, then [_probe]). Returns
  /// how many rows were marked refused.
  Future<int> _settle(
    _Round round,
    String kind, {
    required List<int> ids,
    required List<int> dropped,
    required Set<String> inCall,
    required Set<String> rejected,
    required DateTime at,
  }) async {
    final List<int> sent = <int>[
      for (final int id in ids)
        if (inCall.contains(eventIdOf(deviceId, kind, id))) id,
    ];
    final List<int> bad = <int>[
      for (final int id in sent)
        if (rejected.contains(eventIdOf(deviceId, kind, id))) id,
    ];
    final List<int> taken = <int>[
      for (final int id in sent)
        if (!bad.contains(id)) id,
    ];
    await _mark(kind, <int>[...taken, ...dropped], at);
    if (taken.isNotEmpty) round.understood[kind] = true;
    final Set<int> suspects = round.suspects[kind]!;
    if (round.understood[kind]!) {
      final List<int> never = <int>[...bad, ...suspects];
      suspects.clear();
      await _mark(kind, never, AppDatabase.refusedBySync);
      return never.length;
    }
    if (bad.isNotEmpty) {
      suspects.addAll(bad);
      round.after[kind] = bad.reduce(math.max);
      round.newSuspects = true;
    }
    return 0;
  }

  Future<void> _mark(String kind, List<int> ids, DateTime at) => switch (kind) {
    'attempt' => db.markAttemptsSynced(ids, at),
    'session' => db.markSessionsSynced(ids, at),
    _ => db.markRewardsSynced(ids, at),
  };

  /// The one answer that says a row is bad on its own: our gateway's `bad_request`, with the status 400. The same word from
  /// anything else (another status) is a failure that leaves the rows as they are (SEC-B20-7).
  static bool _isBadRequest(GatewayException e) => e.code == 'bad_request' && e.status == 400;

  /// Sends [events] in one call. When the server refuses the call as a whole (`bad_request`: one event it will not take
  /// refuses the batch), they are sent again one by one, so that the good ones get in and the ones it will not take are known
  /// by their ids ([_Sent.rejected]). Any other failure (no network, the server down) is thrown: everything stays for the
  /// next round. Whether a rejected event is a bad row or the sign of a server that does not know this app's format (a
  /// gateway deployed out of order, SEC-12) is for [_settle] to say.
  Future<_Sent> _send(List<Map<String, Object?>> events) async {
    try {
      return _Sent.of(await call('sync-push', <String, Object?>{'events': events}));
    } on GatewayException catch (e) {
      if (!_isBadRequest(e)) rethrow;
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
        if (!_isBadRequest(x)) rethrow;
        rejected.add(e['id']! as String);
      }
    }
    if (rejected.isNotEmpty) {
      Log.d('sync: ${rejected.length} of ${events.length} events refused by the server');
    }
    return _Sent(pushed: pushed, refused: refused, rejected: rejected);
  }

  // ---- alerts and the family's rules ----

  /// Sends the alerts found on this device that the family has not been told about. Returns how many were sent.
  ///
  /// Each alert is marked as soon as it is answered. One the gateway will not take (`bad_request`: words or a value it
  /// refuses, or a category it does not know yet) never holds up the ones after it (SEC-25): it is sent once more without
  /// its words (the alert arrives, the words are lost, the private side), and if that is refused too it is kept aside as
  /// [AppDatabase.refusedBySync] and sent again once by the next version of the app. Any other failure (no network, the
  /// server down, a limit) stops the round and leaves the rest for the next one.
  Future<int> _pushAlerts() async {
    int sent = 0;
    final Set<String> gone = await _tombstoned();
    while (true) {
      final Set<String> held = await _childrenNotOnServer();
      final List<Alert> rows = await db.unsyncedAlerts(limit: batch, except: held);
      if (rows.isEmpty) break;
      for (final Alert a in rows) {
        if (a.profileId != null && gone.contains(a.profileId)) {
          await db.markAlertsSynced(<int>[a.id], _now);
          continue;
        }
        final Map<String, Object?>? answer = await _sendAlert(a);
        // New, a duplicate, or refused (the server does not know the child): the alert is not sent again.
        await db.markAlertsSynced(<int>[a.id], answer == null ? AppDatabase.refusedBySync : _now);
        if (answer?['status'] == 'new') sent++;
      }
      if (rows.length < batch) break;
    }
    return sent;
  }

  /// One alert to `alert-create`: the server's answer, or null when it refused the alert.
  ///
  /// At most two calls, however the clock or the server behaves (SEC-30), and the time is worked out once for each, not
  /// in a loop. The first call of a session may be the one that teaches the gateway client the server's time
  /// (`clock_skew`), and a gateway older than SEC-30 refused a time ahead of its own. So when the first call is refused
  /// and the time has changed since, the clock was the likely cause: the second call has the corrected time and the same
  /// words, and a phone whose clock runs fast neither loses its act nor its words (QA-45). When the time is the same,
  /// the second call is without the words (the alert arrives, the words are lost, the private side).
  Future<Map<String, Object?>?> _sendAlert(Alert a) async {
    final Map<String, Object?> body = <String, Object?>{
      'child_id': ?a.profileId,
      'category': a.category,
      'severity': a.severity,
      'count': a.count,
      if (a.detail.isNotEmpty) 'detail': a.detail,
      'key': a.dedupeKey,
    };
    Future<Map<String, Object?>?> send(int at, bool withWords) async {
      try {
        return await call('alert-create', <String, Object?>{
          ...body,
          'at': at,
          if (withWords) 'words': a.words,
        });
      } on GatewayException catch (e) {
        if (!_isBadRequest(e)) rethrow;
        return null;
      }
    }

    final bool hasWords = a.words.isNotEmpty;
    final int first = _alertTime(a);
    final Map<String, Object?>? answer = await send(first, hasWords);
    if (answer != null) return answer;
    final int again = _alertTime(a);
    final bool timeChanged = again != first;
    if (timeChanged || hasWords) {
      final Map<String, Object?>? second = await send(again, hasWords && timeChanged);
      if (second != null) return second;
    }
    Log.d('sync: an alert refused by the server, kept aside');
    return null;
  }

  /// The time an alert is sent with: its own, but never ahead of the server's, and the server's own when its time is before
  /// what the gateway takes (a wrong clock: the server lists and deletes alerts by this time, so the floor would not do;
  /// SEC-B20-2).
  int _alertTime(Alert a) {
    final int at = a.at.millisecondsSinceEpoch;
    final int server = serverNowMs();
    return at < minClientMs ? server : math.min(at, server);
  }

  /// A parent device takes in the alerts the family's other devices raised. Returns how many were new here.
  Future<int> _pullAlerts() async {
    final Map<String, Object?> answer = await call('alert-list', const <String, Object?>{});
    final Set<String> gone = await _tombstoned();
    // The words come in only when this phone keeps them (SEC-28).
    final bool keepWords = await db.setting('keep_words') != 'off';
    int added = 0;
    for (final Object? raw in (answer['alerts'] as List<Object?>? ?? const <Object?>[])) {
      final Map<String, Object?> a = raw! as Map<String, Object?>;
      final String? child = a['child_id'] as String?;
      if (child != null && gone.contains(child)) continue;
      final bool fresh = await db.takeRemoteAlert(
        AlertsCompanion.insert(
          at: DateTime.fromMillisecondsSinceEpoch(a['at']! as int, isUtc: true),
          profileId: Value<String?>(child),
          category: a['category']! as String,
          severity: a['severity']! as String,
          count: Value<int>(a['count'] as int? ?? 0),
          detail: Value<String>(a['detail'] as String? ?? ''),
          words: Value<String>(keepWords ? a['words'] as String? ?? '' : ''),
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

  /// The family's rules as this device holds them: the time rules, whether the child's words are kept, the AI helper, and
  /// (only when a parent has turned a language on or changed one) the language settings of each child, and (only for a child
  /// whose parent chose one) the look as a letter. A family that touches neither syncs exactly the document it did before.
  Future<Map<String, Object?>> _localRules() async {
    final FamilyLanguages languages = FamilyLanguages.decode(await db.setting(languagesSettingKey));
    final FamilyLooks looks = FamilyLooks.decode(await db.setting(looksSettingKey));
    return <String, Object?>{
      ...ParentRules.decode(await db.setting('parent_rules')).toJson(),
      'keepWords': await db.setting('keep_words') != 'off',
      'aiHelper': await db.setting('ai_helper') == 'on',
      'ceremonies': await db.setting('ceremonies') != 'off',
      'ribbons': decodeRibbons(await db.setting('ribbons')),
      if (!languages.isEmpty) 'languages': languages.toJson(),
      // The look a parent chose for a child, one letter each (B-29).
      if (!looks.isEmpty) 'looks': looks.toJson(),
    };
  }

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
      // The language settings are taken as the server has them, each value checked again here.
      await db.putSetting(languagesSettingKey, FamilyLanguages.fromJson(rules['languages']).encode());
      // So are the looks: a letter for a child, or nothing.
      await db.putSetting(looksSettingKey, FamilyLooks.fromJson(rules['looks']).encode());
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
        // The server's copy is untrusted like any input (B-32): cleaned like a typed name. A new child whose name has
        // nothing left is not taken on; one this phone has keeps its own name.
        final String nickname = safeChildName(m['nickname']! as String);
        if (nickname.isEmpty && here == null) continue;
        // A name longer than the server takes went cut (B-28): the server's copy is this phone's name, kept whole here.
        final String name = here != null && (nickname.isEmpty || fitChildNameForServer(here.name) == nickname)
            ? here.name
            : nickname;
        // The school stage is untrusted like the rest: one of the six words, and the band that goes with it; anything else is
        // ignored (the stage here stays as it was). A server older than B-29 sends none, and that never wipes the one chosen here.
        final SchoolStage? stage = SchoolStage.fromWire(m['school_stage']);
        final bool stageFits = stage != null && stage.band == m['age_band'];
        // A stage kept here for another band than the server's is wrong for the child now (another phone saved a new band,
        // SEC-B29-1): it is cleared, so this phone never pushes a stage against the band, which the server refuses for ever.
        final SchoolStage? local = SchoolStage.fromWire(here?.schoolStage);
        final bool localFits = local != null && local.band == m['age_band'];
        final bool clearLocal = !stageFits && local != null && !localFits;
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
          schoolStage: stageFits
              ? Value<String?>(stage.wire)
              : clearLocal
              ? const Value<String?>(null)
              : const Value<String?>.absent(),
          createdAt: Value<DateTime>(_now),
        );
        final bool known = here != null;
        if (!known) added++;
        await db.upsertProfileFromFamily(row, isNew: !known);
        // What the server has is now what this device has: no need to push it back.
        await db.putSetting(
          'profile_pushed_$id',
          _profileFingerprint(
            name,
            m['avatar_id']! as String,
            m['address_form']! as String,
            m['age_band']! as int,
            m['companion_id'] as String?,
            m['outfit_id'] as String?,
            // What this phone holds after the pull: the server's stage when it fits, else the one already here if it fits.
            stageFits ? stage : (localFits ? local : null),
          ),
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
      // Evidence never crosses courses (docs/languages/frame.md section 1.5): an answer whose skill, pack, tag and course do
      // not say the same course is not taken in.
      final String? course = Course.ofAnswer(
        skillId: d['skill_id']! as String,
        packId: d['pack_id']! as String,
        activityId: d['activity_id']! as String,
        lessonId: d['lesson_id'] as String? ?? '',
        tag: d['misconception_tag'] as String? ?? '',
        course: d['course'] as String?,
      );
      if (course == null) return false;
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
