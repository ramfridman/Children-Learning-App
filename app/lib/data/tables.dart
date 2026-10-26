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
