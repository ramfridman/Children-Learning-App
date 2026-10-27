import 'package:drift/drift.dart';

/// A child profile. The first name is stored here, on the device, and nowhere else in M1. It is
/// the parent-reviewed spelling; it never goes to the AI vendor (placeholders only, CLAUDE.md).
class Profiles extends Table {
  TextColumn get id => text()();

  TextColumn get name => text().withLength(min: 1, max: 40)();

  /// An id from the avatar set, for example `avatar-noa`.
  TextColumn get avatar => text()();

  /// How the app addresses the child in Hebrew: `f` (feminine), `m` (masculine) or `n` (neutral).
  TextColumn get addressForm => text().withLength(min: 1, max: 1)();

  /// 0, 1 or 2 for age bands A (3 to 4), B (5 to 6) and C (7 to 8).
  // The self-reference is how Drift writes a column check; it is not a real recursion.
  // ignore: recursive_getters
  IntColumn get ageBand => integer().check(ageBand.isBetweenValues(0, 2))();

  DateTimeColumn get createdAt => dateTime()();

  /// The id of the character the child chose as a companion (for example `hero-son`), or null for the house
  /// character, Nitzi. It names a character pack by id only; the pictures and the voice live in packs.
  TextColumn get companionId => text().nullable()();

  @override
  Set<Column<Object>> get primaryKey => <Column<Object>>{id};
}

/// Small settings that belong to this device (not to a child), as text key and value.
class AppSettings extends Table {
  TextColumn get key => text()();

  TextColumn get value => text()();

  @override
  Set<Column<Object>> get primaryKey => <Column<Object>>{key};
}

/// A short local record of security events (wrong PIN, gate failures, lock-outs). Alerts to the
/// parent's phone arrive in M7; this is the on-device record they will be built from.
class LocalEvents extends Table {
  IntColumn get id => integer().autoIncrement()();

  DateTimeColumn get at => dateTime()();

  TextColumn get kind => text()();

  /// Short, fixed words only. Never a PIN, a name or free text.
  TextColumn get detail => text().withDefault(const Constant<String>(''))();
}

/// A content pack that is installed on this device. One row per pack id: installing a newer version
/// replaces the row. The files live in the no-backup folder, under `packs/<id>/<version>/`.
class InstalledPacks extends Table {
  TextColumn get id => text().withLength(min: 3, max: 41)();

  TextColumn get version => text().withLength(min: 5, max: 11)();

  /// SHA-256 (hex) of the pack's manifest.json, which lists the hash of every other file: it names
  /// these exact contents. The same version with another hash is refused.
  TextColumn get manifestSha256 => text().withLength(min: 64, max: 64)();

  DateTimeColumn get installedAt => dateTime()();

  /// True if this app cannot play the pack yet (it needs a newer app or template); never offered.
  BoolColumn get hidden => boolean().withDefault(const Constant<bool>(false))();

  /// Why it is hidden, in a short English sentence for the developer log; empty when not hidden.
  TextColumn get hiddenReason => text().withDefault(const Constant<String>(''))();

  @override
  Set<Column<Object>> get primaryKey => <Column<Object>>{id};
}

/// One answer a child gave, as the engine of M3 will read it. It holds ids, numbers and fixed words
/// only: never a name, never free text, never audio.
class Attempts extends Table {
  IntColumn get id => integer().autoIncrement()();

  DateTimeColumn get at => dateTime()();

  TextColumn get profileId => text()();

  TextColumn get packId => text()();

  TextColumn get packVersion => text()();

  /// The lesson being played, or empty for a single activity.
  TextColumn get lessonId => text().withDefault(const Constant<String>(''))();

  TextColumn get activityId => text()();

  /// The `revision` of the activity file, so a changed activity is never mixed up with the old one.
  IntColumn get activityRevision => integer()();

  TextColumn get template => text()();

  TextColumn get templateVersion => text()();

  /// The first skill of the activity (for example `NUM-A-03`).
  TextColumn get skillId => text()();

  /// `correct`, `incorrect` or `unsure`. Unsure is never wrong.
  TextColumn get result => text()();

  /// Which try this was for the activity, from 1.
  IntColumn get attemptNo => integer()();

  /// The highest hint level shown before this answer (0 for none, up to 3).
  IntColumn get hintLevel => integer()();

  /// A misconception tag such as `M-CNT-DOUBLE`, or empty.
  TextColumn get misconceptionTag => text().withDefault(const Constant<String>(''))();

  /// What was chosen, as a fixed code: an option id (`o2`), a number (`n=4`) or a classifier word.
  TextColumn get response => text().withDefault(const Constant<String>(''))();

  IntColumn get durationMs => integer().withDefault(const Constant<int>(0))();

  /// The session this answer belongs to (a visit with a start and an end), or null for answers from before sessions.
  IntColumn get sessionId => integer().nullable()();

  /// How the answer was given: `tap`, or `voice` (a spoken answer that was clear, or that the child confirmed).
  TextColumn get input => text().withDefault(const Constant<String>('tap'))();

  /// Sync (M7b). An answer made here is sent once: [syncedAt] says when. An answer that came from another device
  /// carries that device's event id in [eventId] (so it is never added twice) and is never sent back.
  TextColumn get eventId => text().nullable()();

  DateTimeColumn get syncedAt => dateTime().nullable()();

  /// For an answer from another device: which visit of that device it belongs to (`deviceId:number`), until the visit's
  /// own event has arrived and [sessionId] can be set.
  TextColumn get remoteSession => text().nullable()();
}

/// One visit: a lesson or a session the engine planned. It holds no names and no text.
class Sessions extends Table {
  IntColumn get id => integer().autoIncrement()();

  TextColumn get profileId => text()();

  DateTimeColumn get startedAt => dateTime()();

  DateTimeColumn get endedAt => dateTime().nullable()();

  /// What was played, for example `lesson:butterflies` or `session:A`.
  TextColumn get plan => text().withDefault(const Constant<String>(''))();

  /// A fixed word: `finished`, `home` (the child left), `limit` (the parent's time was up) or empty while it runs.
  TextColumn get endReason => text().withDefault(const Constant<String>(''))();

  /// Sync (M7b): when the visit was sent (only once it has ended), or the id of the event it came from, and for a visit
  /// from another device its name there (`deviceId:number`).
  TextColumn get eventId => text().nullable()();

  DateTimeColumn get syncedAt => dateTime().nullable()();

  TextColumn get remoteKey => text().nullable()();
}

/// One time the child tapped the mic, and how it went, as a fixed word. It holds no audio, no words and no text:
/// only what is needed to see whether voice works for this child (and to stop inviting it when it does not).
class VoiceListens extends Table {
  IntColumn get id => integer().autoIncrement()();

  DateTimeColumn get at => dateTime()();

  TextColumn get profileId => text()();

  /// What kind of answer was expected: `number`, `colour` or `word`.
  TextColumn get answerType => text()();

  /// `accepted`, `confirmed`, `declined`, `unclear`, `silent`, `intent` or `failed`.
  TextColumn get outcome => text()();
}

/// What the parent is told about (M7): a category, a severity, a number and fixed words. The child's own words are in
/// [words] only while "keep the words" is on (default on, never longer than 30 days); otherwise it is empty.
class Alerts extends Table {
  IntColumn get id => integer().autoIncrement()();

  DateTimeColumn get at => dateTime()();

  /// The child the alert is about, or null for one that concerns the device (someone at the parent gate).
  TextColumn get profileId => text().nullable()();

  /// An `AlertCategory` name and an `AlertSeverity` name.
  TextColumn get category => text()();

  TextColumn get severity => text()();

  /// Minutes, attempts or days, depending on the category.
  IntColumn get count => integer().withDefault(const Constant<int>(0))();

  /// Fixed words only (an activity id).
  TextColumn get detail => text().withDefault(const Constant<String>(''))();

  /// The words the recogniser heard, kept only when the parent allows it.
  TextColumn get words => text().withDefault(const Constant<String>(''))();

  /// What makes this alert the same alert next time (one a day, one a session, one an event), so a scan never repeats it.
  TextColumn get dedupeKey => text().unique()();

  DateTimeColumn get readAt => dateTime().nullable()();

  /// When the alert was sent to the family's other devices (an alert from another device is never sent back).
  DateTimeColumn get syncedAt => dateTime().nullable()();
}

/// What a child has been given (M8): stickers, golden stars and trophies. A row is never changed except to say that the
/// child has seen it, and never deleted except with the child: a replay or a late event from another phone cannot take an
/// award away. It holds a key, a kind and a time, and no text.
class Rewards extends Table {
  IntColumn get id => integer().autoIncrement()();

  TextColumn get profileId => text()();

  /// The award's key, for example `trophy:counting:silver`; the same on every device.
  TextColumn get awardKey => text()();

  /// An `AwardKind` name.
  TextColumn get kind => text()();

  /// When it was earned (the answer or the lesson that made it so), not when this phone found out.
  DateTimeColumn get at => dateTime()();

  /// When the child was shown it (a sticker revealed, a ceremony played). Null while it waits to be shown; an award from
  /// another phone or from before this feature is marked seen at once.
  DateTimeColumn get seenAt => dateTime().nullable()();

  /// Sync: when it was sent, or the id of the event it came from.
  TextColumn get eventId => text().nullable()();

  DateTimeColumn get syncedAt => dateTime().nullable()();

  @override
  List<Set<Column<Object>>> get uniqueKeys => <Set<Column<Object>>>[
    <Column<Object>>{profileId, awardKey},
  ];
}
