// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $ProfilesTable extends Profiles with TableInfo<$ProfilesTable, Profile> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ProfilesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(minTextLength: 1, maxTextLength: 40),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _avatarMeta = const VerificationMeta('avatar');
  @override
  late final GeneratedColumn<String> avatar = GeneratedColumn<String>(
    'avatar',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _addressFormMeta = const VerificationMeta('addressForm');
  @override
  late final GeneratedColumn<String> addressForm = GeneratedColumn<String>(
    'address_form',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(minTextLength: 1, maxTextLength: 1),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _ageBandMeta = const VerificationMeta('ageBand');
  @override
  late final GeneratedColumn<int> ageBand = GeneratedColumn<int>(
    'age_band',
    aliasedName,
    false,
    check: () => ComparableExpr(ageBand).isBetweenValues(0, 2),
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _companionIdMeta = const VerificationMeta('companionId');
  @override
  late final GeneratedColumn<String> companionId = GeneratedColumn<String>(
    'companion_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [id, name, avatar, addressForm, ageBand, createdAt, companionId];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'profiles';
  @override
  VerificationContext validateIntegrity(Insertable<Profile> instance, {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(_nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('avatar')) {
      context.handle(_avatarMeta, avatar.isAcceptableOrUnknown(data['avatar']!, _avatarMeta));
    } else if (isInserting) {
      context.missing(_avatarMeta);
    }
    if (data.containsKey('address_form')) {
      context.handle(
        _addressFormMeta,
        addressForm.isAcceptableOrUnknown(data['address_form']!, _addressFormMeta),
      );
    } else if (isInserting) {
      context.missing(_addressFormMeta);
    }
    if (data.containsKey('age_band')) {
      context.handle(_ageBandMeta, ageBand.isAcceptableOrUnknown(data['age_band']!, _ageBandMeta));
    } else if (isInserting) {
      context.missing(_ageBandMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta, createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('companion_id')) {
      context.handle(
        _companionIdMeta,
        companionId.isAcceptableOrUnknown(data['companion_id']!, _companionIdMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Profile map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Profile(
      id: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      name: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      avatar: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}avatar'])!,
      addressForm: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}address_form'],
      )!,
      ageBand: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}age_band'])!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      companionId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}companion_id'],
      ),
    );
  }

  @override
  $ProfilesTable createAlias(String alias) {
    return $ProfilesTable(attachedDatabase, alias);
  }
}

class Profile extends DataClass implements Insertable<Profile> {
  final String id;
  final String name;

  /// An id from the avatar set, for example `avatar-noa`.
  final String avatar;

  /// How the app addresses the child in Hebrew: `f` (feminine), `m` (masculine) or `n` (neutral).
  final String addressForm;

  /// 0, 1 or 2 for age bands A (3 to 4), B (5 to 6) and C (7 to 8).
  final int ageBand;
  final DateTime createdAt;

  /// The id of the character the child chose as a companion (for example `hero-son`), or null for the house
  /// character, Nitzi. It names a character pack by id only; the pictures and the voice live in packs.
  final String? companionId;
  const Profile({
    required this.id,
    required this.name,
    required this.avatar,
    required this.addressForm,
    required this.ageBand,
    required this.createdAt,
    this.companionId,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['avatar'] = Variable<String>(avatar);
    map['address_form'] = Variable<String>(addressForm);
    map['age_band'] = Variable<int>(ageBand);
    map['created_at'] = Variable<DateTime>(createdAt);
    if (!nullToAbsent || companionId != null) {
      map['companion_id'] = Variable<String>(companionId);
    }
    return map;
  }

  ProfilesCompanion toCompanion(bool nullToAbsent) {
    return ProfilesCompanion(
      id: Value(id),
      name: Value(name),
      avatar: Value(avatar),
      addressForm: Value(addressForm),
      ageBand: Value(ageBand),
      createdAt: Value(createdAt),
      companionId: companionId == null && nullToAbsent ? const Value.absent() : Value(companionId),
    );
  }

  factory Profile.fromJson(Map<String, dynamic> json, {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Profile(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      avatar: serializer.fromJson<String>(json['avatar']),
      addressForm: serializer.fromJson<String>(json['addressForm']),
      ageBand: serializer.fromJson<int>(json['ageBand']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      companionId: serializer.fromJson<String?>(json['companionId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'avatar': serializer.toJson<String>(avatar),
      'addressForm': serializer.toJson<String>(addressForm),
      'ageBand': serializer.toJson<int>(ageBand),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'companionId': serializer.toJson<String?>(companionId),
    };
  }

  Profile copyWith({
    String? id,
    String? name,
    String? avatar,
    String? addressForm,
    int? ageBand,
    DateTime? createdAt,
    Value<String?> companionId = const Value.absent(),
  }) => Profile(
    id: id ?? this.id,
    name: name ?? this.name,
    avatar: avatar ?? this.avatar,
    addressForm: addressForm ?? this.addressForm,
    ageBand: ageBand ?? this.ageBand,
    createdAt: createdAt ?? this.createdAt,
    companionId: companionId.present ? companionId.value : this.companionId,
  );
  Profile copyWithCompanion(ProfilesCompanion data) {
    return Profile(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      avatar: data.avatar.present ? data.avatar.value : this.avatar,
      addressForm: data.addressForm.present ? data.addressForm.value : this.addressForm,
      ageBand: data.ageBand.present ? data.ageBand.value : this.ageBand,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      companionId: data.companionId.present ? data.companionId.value : this.companionId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Profile(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('avatar: $avatar, ')
          ..write('addressForm: $addressForm, ')
          ..write('ageBand: $ageBand, ')
          ..write('createdAt: $createdAt, ')
          ..write('companionId: $companionId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, avatar, addressForm, ageBand, createdAt, companionId);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Profile &&
          other.id == this.id &&
          other.name == this.name &&
          other.avatar == this.avatar &&
          other.addressForm == this.addressForm &&
          other.ageBand == this.ageBand &&
          other.createdAt == this.createdAt &&
          other.companionId == this.companionId);
}

class ProfilesCompanion extends UpdateCompanion<Profile> {
  final Value<String> id;
  final Value<String> name;
  final Value<String> avatar;
  final Value<String> addressForm;
  final Value<int> ageBand;
  final Value<DateTime> createdAt;
  final Value<String?> companionId;
  final Value<int> rowid;
  const ProfilesCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.avatar = const Value.absent(),
    this.addressForm = const Value.absent(),
    this.ageBand = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.companionId = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ProfilesCompanion.insert({
    required String id,
    required String name,
    required String avatar,
    required String addressForm,
    required int ageBand,
    required DateTime createdAt,
    this.companionId = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       avatar = Value(avatar),
       addressForm = Value(addressForm),
       ageBand = Value(ageBand),
       createdAt = Value(createdAt);
  static Insertable<Profile> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? avatar,
    Expression<String>? addressForm,
    Expression<int>? ageBand,
    Expression<DateTime>? createdAt,
    Expression<String>? companionId,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (avatar != null) 'avatar': avatar,
      if (addressForm != null) 'address_form': addressForm,
      if (ageBand != null) 'age_band': ageBand,
      if (createdAt != null) 'created_at': createdAt,
      if (companionId != null) 'companion_id': companionId,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ProfilesCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<String>? avatar,
    Value<String>? addressForm,
    Value<int>? ageBand,
    Value<DateTime>? createdAt,
    Value<String?>? companionId,
    Value<int>? rowid,
  }) {
    return ProfilesCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      avatar: avatar ?? this.avatar,
      addressForm: addressForm ?? this.addressForm,
      ageBand: ageBand ?? this.ageBand,
      createdAt: createdAt ?? this.createdAt,
      companionId: companionId ?? this.companionId,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (avatar.present) {
      map['avatar'] = Variable<String>(avatar.value);
    }
    if (addressForm.present) {
      map['address_form'] = Variable<String>(addressForm.value);
    }
    if (ageBand.present) {
      map['age_band'] = Variable<int>(ageBand.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (companionId.present) {
      map['companion_id'] = Variable<String>(companionId.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ProfilesCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('avatar: $avatar, ')
          ..write('addressForm: $addressForm, ')
          ..write('ageBand: $ageBand, ')
          ..write('createdAt: $createdAt, ')
          ..write('companionId: $companionId, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $AppSettingsTable extends AppSettings with TableInfo<$AppSettingsTable, AppSetting> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AppSettingsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
    'key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<String> value = GeneratedColumn<String>(
    'value',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [key, value];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'app_settings';
  @override
  VerificationContext validateIntegrity(Insertable<AppSetting> instance, {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('key')) {
      context.handle(_keyMeta, key.isAcceptableOrUnknown(data['key']!, _keyMeta));
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('value')) {
      context.handle(_valueMeta, value.isAcceptableOrUnknown(data['value']!, _valueMeta));
    } else if (isInserting) {
      context.missing(_valueMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {key};
  @override
  AppSetting map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AppSetting(
      key: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}key'])!,
      value: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}value'])!,
    );
  }

  @override
  $AppSettingsTable createAlias(String alias) {
    return $AppSettingsTable(attachedDatabase, alias);
  }
}

class AppSetting extends DataClass implements Insertable<AppSetting> {
  final String key;
  final String value;
  const AppSetting({required this.key, required this.value});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    map['value'] = Variable<String>(value);
    return map;
  }

  AppSettingsCompanion toCompanion(bool nullToAbsent) {
    return AppSettingsCompanion(key: Value(key), value: Value(value));
  }

  factory AppSetting.fromJson(Map<String, dynamic> json, {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AppSetting(
      key: serializer.fromJson<String>(json['key']),
      value: serializer.fromJson<String>(json['value']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'key': serializer.toJson<String>(key),
      'value': serializer.toJson<String>(value),
    };
  }

  AppSetting copyWith({String? key, String? value}) =>
      AppSetting(key: key ?? this.key, value: value ?? this.value);
  AppSetting copyWithCompanion(AppSettingsCompanion data) {
    return AppSetting(
      key: data.key.present ? data.key.value : this.key,
      value: data.value.present ? data.value.value : this.value,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AppSetting(')
          ..write('key: $key, ')
          ..write('value: $value')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(key, value);
  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is AppSetting && other.key == this.key && other.value == this.value);
}

class AppSettingsCompanion extends UpdateCompanion<AppSetting> {
  final Value<String> key;
  final Value<String> value;
  final Value<int> rowid;
  const AppSettingsCompanion({
    this.key = const Value.absent(),
    this.value = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AppSettingsCompanion.insert({required String key, required String value, this.rowid = const Value.absent()})
    : key = Value(key),
      value = Value(value);
  static Insertable<AppSetting> custom({
    Expression<String>? key,
    Expression<String>? value,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (key != null) 'key': key,
      if (value != null) 'value': value,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AppSettingsCompanion copyWith({Value<String>? key, Value<String>? value, Value<int>? rowid}) {
    return AppSettingsCompanion(key: key ?? this.key, value: value ?? this.value, rowid: rowid ?? this.rowid);
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (value.present) {
      map['value'] = Variable<String>(value.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AppSettingsCompanion(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LocalEventsTable extends LocalEvents with TableInfo<$LocalEventsTable, LocalEvent> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalEventsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'),
  );
  static const VerificationMeta _atMeta = const VerificationMeta('at');
  @override
  late final GeneratedColumn<DateTime> at = GeneratedColumn<DateTime>(
    'at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _kindMeta = const VerificationMeta('kind');
  @override
  late final GeneratedColumn<String> kind = GeneratedColumn<String>(
    'kind',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _detailMeta = const VerificationMeta('detail');
  @override
  late final GeneratedColumn<String> detail = GeneratedColumn<String>(
    'detail',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant<String>(''),
  );
  @override
  List<GeneratedColumn> get $columns => [id, at, kind, detail];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_events';
  @override
  VerificationContext validateIntegrity(Insertable<LocalEvent> instance, {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('at')) {
      context.handle(_atMeta, at.isAcceptableOrUnknown(data['at']!, _atMeta));
    } else if (isInserting) {
      context.missing(_atMeta);
    }
    if (data.containsKey('kind')) {
      context.handle(_kindMeta, kind.isAcceptableOrUnknown(data['kind']!, _kindMeta));
    } else if (isInserting) {
      context.missing(_kindMeta);
    }
    if (data.containsKey('detail')) {
      context.handle(_detailMeta, detail.isAcceptableOrUnknown(data['detail']!, _detailMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LocalEvent map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalEvent(
      id: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      at: attachedDatabase.typeMapping.read(DriftSqlType.dateTime, data['${effectivePrefix}at'])!,
      kind: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}kind'])!,
      detail: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}detail'])!,
    );
  }

  @override
  $LocalEventsTable createAlias(String alias) {
    return $LocalEventsTable(attachedDatabase, alias);
  }
}

class LocalEvent extends DataClass implements Insertable<LocalEvent> {
  final int id;
  final DateTime at;
  final String kind;

  /// Short, fixed words only. Never a PIN, a name or free text.
  final String detail;
  const LocalEvent({required this.id, required this.at, required this.kind, required this.detail});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['at'] = Variable<DateTime>(at);
    map['kind'] = Variable<String>(kind);
    map['detail'] = Variable<String>(detail);
    return map;
  }

  LocalEventsCompanion toCompanion(bool nullToAbsent) {
    return LocalEventsCompanion(id: Value(id), at: Value(at), kind: Value(kind), detail: Value(detail));
  }

  factory LocalEvent.fromJson(Map<String, dynamic> json, {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalEvent(
      id: serializer.fromJson<int>(json['id']),
      at: serializer.fromJson<DateTime>(json['at']),
      kind: serializer.fromJson<String>(json['kind']),
      detail: serializer.fromJson<String>(json['detail']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'at': serializer.toJson<DateTime>(at),
      'kind': serializer.toJson<String>(kind),
      'detail': serializer.toJson<String>(detail),
    };
  }

  LocalEvent copyWith({int? id, DateTime? at, String? kind, String? detail}) => LocalEvent(
    id: id ?? this.id,
    at: at ?? this.at,
    kind: kind ?? this.kind,
    detail: detail ?? this.detail,
  );
  LocalEvent copyWithCompanion(LocalEventsCompanion data) {
    return LocalEvent(
      id: data.id.present ? data.id.value : this.id,
      at: data.at.present ? data.at.value : this.at,
      kind: data.kind.present ? data.kind.value : this.kind,
      detail: data.detail.present ? data.detail.value : this.detail,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalEvent(')
          ..write('id: $id, ')
          ..write('at: $at, ')
          ..write('kind: $kind, ')
          ..write('detail: $detail')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, at, kind, detail);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalEvent &&
          other.id == this.id &&
          other.at == this.at &&
          other.kind == this.kind &&
          other.detail == this.detail);
}

class LocalEventsCompanion extends UpdateCompanion<LocalEvent> {
  final Value<int> id;
  final Value<DateTime> at;
  final Value<String> kind;
  final Value<String> detail;
  const LocalEventsCompanion({
    this.id = const Value.absent(),
    this.at = const Value.absent(),
    this.kind = const Value.absent(),
    this.detail = const Value.absent(),
  });
  LocalEventsCompanion.insert({
    this.id = const Value.absent(),
    required DateTime at,
    required String kind,
    this.detail = const Value.absent(),
  }) : at = Value(at),
       kind = Value(kind);
  static Insertable<LocalEvent> custom({
    Expression<int>? id,
    Expression<DateTime>? at,
    Expression<String>? kind,
    Expression<String>? detail,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (at != null) 'at': at,
      if (kind != null) 'kind': kind,
      if (detail != null) 'detail': detail,
    });
  }

  LocalEventsCompanion copyWith({
    Value<int>? id,
    Value<DateTime>? at,
    Value<String>? kind,
    Value<String>? detail,
  }) {
    return LocalEventsCompanion(
      id: id ?? this.id,
      at: at ?? this.at,
      kind: kind ?? this.kind,
      detail: detail ?? this.detail,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (at.present) {
      map['at'] = Variable<DateTime>(at.value);
    }
    if (kind.present) {
      map['kind'] = Variable<String>(kind.value);
    }
    if (detail.present) {
      map['detail'] = Variable<String>(detail.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalEventsCompanion(')
          ..write('id: $id, ')
          ..write('at: $at, ')
          ..write('kind: $kind, ')
          ..write('detail: $detail')
          ..write(')'))
        .toString();
  }
}

class $InstalledPacksTable extends InstalledPacks with TableInfo<$InstalledPacksTable, InstalledPack> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $InstalledPacksTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(minTextLength: 3, maxTextLength: 41),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _versionMeta = const VerificationMeta('version');
  @override
  late final GeneratedColumn<String> version = GeneratedColumn<String>(
    'version',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(minTextLength: 5, maxTextLength: 11),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _manifestSha256Meta = const VerificationMeta('manifestSha256');
  @override
  late final GeneratedColumn<String> manifestSha256 = GeneratedColumn<String>(
    'manifest_sha256',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(minTextLength: 64, maxTextLength: 64),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _installedAtMeta = const VerificationMeta('installedAt');
  @override
  late final GeneratedColumn<DateTime> installedAt = GeneratedColumn<DateTime>(
    'installed_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _hiddenMeta = const VerificationMeta('hidden');
  @override
  late final GeneratedColumn<bool> hidden = GeneratedColumn<bool>(
    'hidden',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways('CHECK ("hidden" IN (0, 1))'),
    defaultValue: const Constant<bool>(false),
  );
  static const VerificationMeta _hiddenReasonMeta = const VerificationMeta('hiddenReason');
  @override
  late final GeneratedColumn<String> hiddenReason = GeneratedColumn<String>(
    'hidden_reason',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant<String>(''),
  );
  @override
  List<GeneratedColumn> get $columns => [id, version, manifestSha256, installedAt, hidden, hiddenReason];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'installed_packs';
  @override
  VerificationContext validateIntegrity(Insertable<InstalledPack> instance, {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('version')) {
      context.handle(_versionMeta, version.isAcceptableOrUnknown(data['version']!, _versionMeta));
    } else if (isInserting) {
      context.missing(_versionMeta);
    }
    if (data.containsKey('manifest_sha256')) {
      context.handle(
        _manifestSha256Meta,
        manifestSha256.isAcceptableOrUnknown(data['manifest_sha256']!, _manifestSha256Meta),
      );
    } else if (isInserting) {
      context.missing(_manifestSha256Meta);
    }
    if (data.containsKey('installed_at')) {
      context.handle(
        _installedAtMeta,
        installedAt.isAcceptableOrUnknown(data['installed_at']!, _installedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_installedAtMeta);
    }
    if (data.containsKey('hidden')) {
      context.handle(_hiddenMeta, hidden.isAcceptableOrUnknown(data['hidden']!, _hiddenMeta));
    }
    if (data.containsKey('hidden_reason')) {
      context.handle(
        _hiddenReasonMeta,
        hiddenReason.isAcceptableOrUnknown(data['hidden_reason']!, _hiddenReasonMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  InstalledPack map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return InstalledPack(
      id: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      version: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}version'])!,
      manifestSha256: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}manifest_sha256'],
      )!,
      installedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}installed_at'],
      )!,
      hidden: attachedDatabase.typeMapping.read(DriftSqlType.bool, data['${effectivePrefix}hidden'])!,
      hiddenReason: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}hidden_reason'],
      )!,
    );
  }

  @override
  $InstalledPacksTable createAlias(String alias) {
    return $InstalledPacksTable(attachedDatabase, alias);
  }
}

class InstalledPack extends DataClass implements Insertable<InstalledPack> {
  final String id;
  final String version;

  /// SHA-256 (hex) of the pack's manifest.json, which lists the hash of every other file: it names
  /// these exact contents. The same version with another hash is refused.
  final String manifestSha256;
  final DateTime installedAt;

  /// True if this app cannot play the pack yet (it needs a newer app or template); never offered.
  final bool hidden;

  /// Why it is hidden, in a short English sentence for the developer log; empty when not hidden.
  final String hiddenReason;
  const InstalledPack({
    required this.id,
    required this.version,
    required this.manifestSha256,
    required this.installedAt,
    required this.hidden,
    required this.hiddenReason,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['version'] = Variable<String>(version);
    map['manifest_sha256'] = Variable<String>(manifestSha256);
    map['installed_at'] = Variable<DateTime>(installedAt);
    map['hidden'] = Variable<bool>(hidden);
    map['hidden_reason'] = Variable<String>(hiddenReason);
    return map;
  }

  InstalledPacksCompanion toCompanion(bool nullToAbsent) {
    return InstalledPacksCompanion(
      id: Value(id),
      version: Value(version),
      manifestSha256: Value(manifestSha256),
      installedAt: Value(installedAt),
      hidden: Value(hidden),
      hiddenReason: Value(hiddenReason),
    );
  }

  factory InstalledPack.fromJson(Map<String, dynamic> json, {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return InstalledPack(
      id: serializer.fromJson<String>(json['id']),
      version: serializer.fromJson<String>(json['version']),
      manifestSha256: serializer.fromJson<String>(json['manifestSha256']),
      installedAt: serializer.fromJson<DateTime>(json['installedAt']),
      hidden: serializer.fromJson<bool>(json['hidden']),
      hiddenReason: serializer.fromJson<String>(json['hiddenReason']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'version': serializer.toJson<String>(version),
      'manifestSha256': serializer.toJson<String>(manifestSha256),
      'installedAt': serializer.toJson<DateTime>(installedAt),
      'hidden': serializer.toJson<bool>(hidden),
      'hiddenReason': serializer.toJson<String>(hiddenReason),
    };
  }

  InstalledPack copyWith({
    String? id,
    String? version,
    String? manifestSha256,
    DateTime? installedAt,
    bool? hidden,
    String? hiddenReason,
  }) => InstalledPack(
    id: id ?? this.id,
    version: version ?? this.version,
    manifestSha256: manifestSha256 ?? this.manifestSha256,
    installedAt: installedAt ?? this.installedAt,
    hidden: hidden ?? this.hidden,
    hiddenReason: hiddenReason ?? this.hiddenReason,
  );
  InstalledPack copyWithCompanion(InstalledPacksCompanion data) {
    return InstalledPack(
      id: data.id.present ? data.id.value : this.id,
      version: data.version.present ? data.version.value : this.version,
      manifestSha256: data.manifestSha256.present ? data.manifestSha256.value : this.manifestSha256,
      installedAt: data.installedAt.present ? data.installedAt.value : this.installedAt,
      hidden: data.hidden.present ? data.hidden.value : this.hidden,
      hiddenReason: data.hiddenReason.present ? data.hiddenReason.value : this.hiddenReason,
    );
  }

  @override
  String toString() {
    return (StringBuffer('InstalledPack(')
          ..write('id: $id, ')
          ..write('version: $version, ')
          ..write('manifestSha256: $manifestSha256, ')
          ..write('installedAt: $installedAt, ')
          ..write('hidden: $hidden, ')
          ..write('hiddenReason: $hiddenReason')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, version, manifestSha256, installedAt, hidden, hiddenReason);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is InstalledPack &&
          other.id == this.id &&
          other.version == this.version &&
          other.manifestSha256 == this.manifestSha256 &&
          other.installedAt == this.installedAt &&
          other.hidden == this.hidden &&
          other.hiddenReason == this.hiddenReason);
}

class InstalledPacksCompanion extends UpdateCompanion<InstalledPack> {
  final Value<String> id;
  final Value<String> version;
  final Value<String> manifestSha256;
  final Value<DateTime> installedAt;
  final Value<bool> hidden;
  final Value<String> hiddenReason;
  final Value<int> rowid;
  const InstalledPacksCompanion({
    this.id = const Value.absent(),
    this.version = const Value.absent(),
    this.manifestSha256 = const Value.absent(),
    this.installedAt = const Value.absent(),
    this.hidden = const Value.absent(),
    this.hiddenReason = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  InstalledPacksCompanion.insert({
    required String id,
    required String version,
    required String manifestSha256,
    required DateTime installedAt,
    this.hidden = const Value.absent(),
    this.hiddenReason = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       version = Value(version),
       manifestSha256 = Value(manifestSha256),
       installedAt = Value(installedAt);
  static Insertable<InstalledPack> custom({
    Expression<String>? id,
    Expression<String>? version,
    Expression<String>? manifestSha256,
    Expression<DateTime>? installedAt,
    Expression<bool>? hidden,
    Expression<String>? hiddenReason,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (version != null) 'version': version,
      if (manifestSha256 != null) 'manifest_sha256': manifestSha256,
      if (installedAt != null) 'installed_at': installedAt,
      if (hidden != null) 'hidden': hidden,
      if (hiddenReason != null) 'hidden_reason': hiddenReason,
      if (rowid != null) 'rowid': rowid,
    });
  }

  InstalledPacksCompanion copyWith({
    Value<String>? id,
    Value<String>? version,
    Value<String>? manifestSha256,
    Value<DateTime>? installedAt,
    Value<bool>? hidden,
    Value<String>? hiddenReason,
    Value<int>? rowid,
  }) {
    return InstalledPacksCompanion(
      id: id ?? this.id,
      version: version ?? this.version,
      manifestSha256: manifestSha256 ?? this.manifestSha256,
      installedAt: installedAt ?? this.installedAt,
      hidden: hidden ?? this.hidden,
      hiddenReason: hiddenReason ?? this.hiddenReason,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (version.present) {
      map['version'] = Variable<String>(version.value);
    }
    if (manifestSha256.present) {
      map['manifest_sha256'] = Variable<String>(manifestSha256.value);
    }
    if (installedAt.present) {
      map['installed_at'] = Variable<DateTime>(installedAt.value);
    }
    if (hidden.present) {
      map['hidden'] = Variable<bool>(hidden.value);
    }
    if (hiddenReason.present) {
      map['hidden_reason'] = Variable<String>(hiddenReason.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('InstalledPacksCompanion(')
          ..write('id: $id, ')
          ..write('version: $version, ')
          ..write('manifestSha256: $manifestSha256, ')
          ..write('installedAt: $installedAt, ')
          ..write('hidden: $hidden, ')
          ..write('hiddenReason: $hiddenReason, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $AttemptsTable extends Attempts with TableInfo<$AttemptsTable, Attempt> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AttemptsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'),
  );
  static const VerificationMeta _atMeta = const VerificationMeta('at');
  @override
  late final GeneratedColumn<DateTime> at = GeneratedColumn<DateTime>(
    'at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _profileIdMeta = const VerificationMeta('profileId');
  @override
  late final GeneratedColumn<String> profileId = GeneratedColumn<String>(
    'profile_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _packIdMeta = const VerificationMeta('packId');
  @override
  late final GeneratedColumn<String> packId = GeneratedColumn<String>(
    'pack_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _packVersionMeta = const VerificationMeta('packVersion');
  @override
  late final GeneratedColumn<String> packVersion = GeneratedColumn<String>(
    'pack_version',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _lessonIdMeta = const VerificationMeta('lessonId');
  @override
  late final GeneratedColumn<String> lessonId = GeneratedColumn<String>(
    'lesson_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant<String>(''),
  );
  static const VerificationMeta _activityIdMeta = const VerificationMeta('activityId');
  @override
  late final GeneratedColumn<String> activityId = GeneratedColumn<String>(
    'activity_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _activityRevisionMeta = const VerificationMeta('activityRevision');
  @override
  late final GeneratedColumn<int> activityRevision = GeneratedColumn<int>(
    'activity_revision',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _templateMeta = const VerificationMeta('template');
  @override
  late final GeneratedColumn<String> template = GeneratedColumn<String>(
    'template',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _templateVersionMeta = const VerificationMeta('templateVersion');
  @override
  late final GeneratedColumn<String> templateVersion = GeneratedColumn<String>(
    'template_version',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _skillIdMeta = const VerificationMeta('skillId');
  @override
  late final GeneratedColumn<String> skillId = GeneratedColumn<String>(
    'skill_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _resultMeta = const VerificationMeta('result');
  @override
  late final GeneratedColumn<String> result = GeneratedColumn<String>(
    'result',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _attemptNoMeta = const VerificationMeta('attemptNo');
  @override
  late final GeneratedColumn<int> attemptNo = GeneratedColumn<int>(
    'attempt_no',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _hintLevelMeta = const VerificationMeta('hintLevel');
  @override
  late final GeneratedColumn<int> hintLevel = GeneratedColumn<int>(
    'hint_level',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _misconceptionTagMeta = const VerificationMeta('misconceptionTag');
  @override
  late final GeneratedColumn<String> misconceptionTag = GeneratedColumn<String>(
    'misconception_tag',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant<String>(''),
  );
  static const VerificationMeta _responseMeta = const VerificationMeta('response');
  @override
  late final GeneratedColumn<String> response = GeneratedColumn<String>(
    'response',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant<String>(''),
  );
  static const VerificationMeta _durationMsMeta = const VerificationMeta('durationMs');
  @override
  late final GeneratedColumn<int> durationMs = GeneratedColumn<int>(
    'duration_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant<int>(0),
  );
  static const VerificationMeta _sessionIdMeta = const VerificationMeta('sessionId');
  @override
  late final GeneratedColumn<int> sessionId = GeneratedColumn<int>(
    'session_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _inputMeta = const VerificationMeta('input');
  @override
  late final GeneratedColumn<String> input = GeneratedColumn<String>(
    'input',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant<String>('tap'),
  );
  static const VerificationMeta _eventIdMeta = const VerificationMeta('eventId');
  @override
  late final GeneratedColumn<String> eventId = GeneratedColumn<String>(
    'event_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _syncedAtMeta = const VerificationMeta('syncedAt');
  @override
  late final GeneratedColumn<DateTime> syncedAt = GeneratedColumn<DateTime>(
    'synced_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _remoteSessionMeta = const VerificationMeta('remoteSession');
  @override
  late final GeneratedColumn<String> remoteSession = GeneratedColumn<String>(
    'remote_session',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    at,
    profileId,
    packId,
    packVersion,
    lessonId,
    activityId,
    activityRevision,
    template,
    templateVersion,
    skillId,
    result,
    attemptNo,
    hintLevel,
    misconceptionTag,
    response,
    durationMs,
    sessionId,
    input,
    eventId,
    syncedAt,
    remoteSession,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'attempts';
  @override
  VerificationContext validateIntegrity(Insertable<Attempt> instance, {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('at')) {
      context.handle(_atMeta, at.isAcceptableOrUnknown(data['at']!, _atMeta));
    } else if (isInserting) {
      context.missing(_atMeta);
    }
    if (data.containsKey('profile_id')) {
      context.handle(_profileIdMeta, profileId.isAcceptableOrUnknown(data['profile_id']!, _profileIdMeta));
    } else if (isInserting) {
      context.missing(_profileIdMeta);
    }
    if (data.containsKey('pack_id')) {
      context.handle(_packIdMeta, packId.isAcceptableOrUnknown(data['pack_id']!, _packIdMeta));
    } else if (isInserting) {
      context.missing(_packIdMeta);
    }
    if (data.containsKey('pack_version')) {
      context.handle(
        _packVersionMeta,
        packVersion.isAcceptableOrUnknown(data['pack_version']!, _packVersionMeta),
      );
    } else if (isInserting) {
      context.missing(_packVersionMeta);
    }
    if (data.containsKey('lesson_id')) {
      context.handle(_lessonIdMeta, lessonId.isAcceptableOrUnknown(data['lesson_id']!, _lessonIdMeta));
    }
    if (data.containsKey('activity_id')) {
      context.handle(
        _activityIdMeta,
        activityId.isAcceptableOrUnknown(data['activity_id']!, _activityIdMeta),
      );
    } else if (isInserting) {
      context.missing(_activityIdMeta);
    }
    if (data.containsKey('activity_revision')) {
      context.handle(
        _activityRevisionMeta,
        activityRevision.isAcceptableOrUnknown(data['activity_revision']!, _activityRevisionMeta),
      );
    } else if (isInserting) {
      context.missing(_activityRevisionMeta);
    }
    if (data.containsKey('template')) {
      context.handle(_templateMeta, template.isAcceptableOrUnknown(data['template']!, _templateMeta));
    } else if (isInserting) {
      context.missing(_templateMeta);
    }
    if (data.containsKey('template_version')) {
      context.handle(
        _templateVersionMeta,
        templateVersion.isAcceptableOrUnknown(data['template_version']!, _templateVersionMeta),
      );
    } else if (isInserting) {
      context.missing(_templateVersionMeta);
    }
    if (data.containsKey('skill_id')) {
      context.handle(_skillIdMeta, skillId.isAcceptableOrUnknown(data['skill_id']!, _skillIdMeta));
    } else if (isInserting) {
      context.missing(_skillIdMeta);
    }
    if (data.containsKey('result')) {
      context.handle(_resultMeta, result.isAcceptableOrUnknown(data['result']!, _resultMeta));
    } else if (isInserting) {
      context.missing(_resultMeta);
    }
    if (data.containsKey('attempt_no')) {
      context.handle(_attemptNoMeta, attemptNo.isAcceptableOrUnknown(data['attempt_no']!, _attemptNoMeta));
    } else if (isInserting) {
      context.missing(_attemptNoMeta);
    }
    if (data.containsKey('hint_level')) {
      context.handle(_hintLevelMeta, hintLevel.isAcceptableOrUnknown(data['hint_level']!, _hintLevelMeta));
    } else if (isInserting) {
      context.missing(_hintLevelMeta);
    }
    if (data.containsKey('misconception_tag')) {
      context.handle(
        _misconceptionTagMeta,
        misconceptionTag.isAcceptableOrUnknown(data['misconception_tag']!, _misconceptionTagMeta),
      );
    }
    if (data.containsKey('response')) {
      context.handle(_responseMeta, response.isAcceptableOrUnknown(data['response']!, _responseMeta));
    }
    if (data.containsKey('duration_ms')) {
      context.handle(
        _durationMsMeta,
        durationMs.isAcceptableOrUnknown(data['duration_ms']!, _durationMsMeta),
      );
    }
    if (data.containsKey('session_id')) {
      context.handle(_sessionIdMeta, sessionId.isAcceptableOrUnknown(data['session_id']!, _sessionIdMeta));
    }
    if (data.containsKey('input')) {
      context.handle(_inputMeta, input.isAcceptableOrUnknown(data['input']!, _inputMeta));
    }
    if (data.containsKey('event_id')) {
      context.handle(_eventIdMeta, eventId.isAcceptableOrUnknown(data['event_id']!, _eventIdMeta));
    }
    if (data.containsKey('synced_at')) {
      context.handle(_syncedAtMeta, syncedAt.isAcceptableOrUnknown(data['synced_at']!, _syncedAtMeta));
    }
    if (data.containsKey('remote_session')) {
      context.handle(
        _remoteSessionMeta,
        remoteSession.isAcceptableOrUnknown(data['remote_session']!, _remoteSessionMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Attempt map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Attempt(
      id: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      at: attachedDatabase.typeMapping.read(DriftSqlType.dateTime, data['${effectivePrefix}at'])!,
      profileId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}profile_id'],
      )!,
      packId: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}pack_id'])!,
      packVersion: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}pack_version'],
      )!,
      lessonId: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}lesson_id'])!,
      activityId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}activity_id'],
      )!,
      activityRevision: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}activity_revision'],
      )!,
      template: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}template'])!,
      templateVersion: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}template_version'],
      )!,
      skillId: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}skill_id'])!,
      result: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}result'])!,
      attemptNo: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}attempt_no'])!,
      hintLevel: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}hint_level'])!,
      misconceptionTag: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}misconception_tag'],
      )!,
      response: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}response'])!,
      durationMs: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}duration_ms'])!,
      sessionId: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}session_id']),
      input: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}input'])!,
      eventId: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}event_id']),
      syncedAt: attachedDatabase.typeMapping.read(DriftSqlType.dateTime, data['${effectivePrefix}synced_at']),
      remoteSession: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}remote_session'],
      ),
    );
  }

  @override
  $AttemptsTable createAlias(String alias) {
    return $AttemptsTable(attachedDatabase, alias);
  }
}

class Attempt extends DataClass implements Insertable<Attempt> {
  final int id;
  final DateTime at;
  final String profileId;
  final String packId;
  final String packVersion;

  /// The lesson being played, or empty for a single activity.
  final String lessonId;
  final String activityId;

  /// The `revision` of the activity file, so a changed activity is never mixed up with the old one.
  final int activityRevision;
  final String template;
  final String templateVersion;

  /// The first skill of the activity (for example `NUM-A-03`).
  final String skillId;

  /// `correct`, `incorrect` or `unsure`. Unsure is never wrong.
  final String result;

  /// Which try this was for the activity, from 1.
  final int attemptNo;

  /// The highest hint level shown before this answer (0 for none, up to 3).
  final int hintLevel;

  /// A misconception tag such as `M-CNT-DOUBLE`, or empty.
  final String misconceptionTag;

  /// What was chosen, as a fixed code: an option id (`o2`), a number (`n=4`) or a classifier word.
  final String response;
  final int durationMs;

  /// The session this answer belongs to (a visit with a start and an end), or null for answers from before sessions.
  final int? sessionId;

  /// How the answer was given: `tap`, or `voice` (a spoken answer that was clear, or that the child confirmed).
  final String input;

  /// Sync (M7b). An answer made here is sent once: [syncedAt] says when. An answer that came from another device
  /// carries that device's event id in [eventId] (so it is never added twice) and is never sent back.
  final String? eventId;
  final DateTime? syncedAt;

  /// For an answer from another device: which visit of that device it belongs to (`deviceId:number`), until the visit's
  /// own event has arrived and [sessionId] can be set.
  final String? remoteSession;
  const Attempt({
    required this.id,
    required this.at,
    required this.profileId,
    required this.packId,
    required this.packVersion,
    required this.lessonId,
    required this.activityId,
    required this.activityRevision,
    required this.template,
    required this.templateVersion,
    required this.skillId,
    required this.result,
    required this.attemptNo,
    required this.hintLevel,
    required this.misconceptionTag,
    required this.response,
    required this.durationMs,
    this.sessionId,
    required this.input,
    this.eventId,
    this.syncedAt,
    this.remoteSession,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['at'] = Variable<DateTime>(at);
    map['profile_id'] = Variable<String>(profileId);
    map['pack_id'] = Variable<String>(packId);
    map['pack_version'] = Variable<String>(packVersion);
    map['lesson_id'] = Variable<String>(lessonId);
    map['activity_id'] = Variable<String>(activityId);
    map['activity_revision'] = Variable<int>(activityRevision);
    map['template'] = Variable<String>(template);
    map['template_version'] = Variable<String>(templateVersion);
    map['skill_id'] = Variable<String>(skillId);
    map['result'] = Variable<String>(result);
    map['attempt_no'] = Variable<int>(attemptNo);
    map['hint_level'] = Variable<int>(hintLevel);
    map['misconception_tag'] = Variable<String>(misconceptionTag);
    map['response'] = Variable<String>(response);
    map['duration_ms'] = Variable<int>(durationMs);
    if (!nullToAbsent || sessionId != null) {
      map['session_id'] = Variable<int>(sessionId);
    }
    map['input'] = Variable<String>(input);
    if (!nullToAbsent || eventId != null) {
      map['event_id'] = Variable<String>(eventId);
    }
    if (!nullToAbsent || syncedAt != null) {
      map['synced_at'] = Variable<DateTime>(syncedAt);
    }
    if (!nullToAbsent || remoteSession != null) {
      map['remote_session'] = Variable<String>(remoteSession);
    }
    return map;
  }

  AttemptsCompanion toCompanion(bool nullToAbsent) {
    return AttemptsCompanion(
      id: Value(id),
      at: Value(at),
      profileId: Value(profileId),
      packId: Value(packId),
      packVersion: Value(packVersion),
      lessonId: Value(lessonId),
      activityId: Value(activityId),
      activityRevision: Value(activityRevision),
      template: Value(template),
      templateVersion: Value(templateVersion),
      skillId: Value(skillId),
      result: Value(result),
      attemptNo: Value(attemptNo),
      hintLevel: Value(hintLevel),
      misconceptionTag: Value(misconceptionTag),
      response: Value(response),
      durationMs: Value(durationMs),
      sessionId: sessionId == null && nullToAbsent ? const Value.absent() : Value(sessionId),
      input: Value(input),
      eventId: eventId == null && nullToAbsent ? const Value.absent() : Value(eventId),
      syncedAt: syncedAt == null && nullToAbsent ? const Value.absent() : Value(syncedAt),
      remoteSession: remoteSession == null && nullToAbsent ? const Value.absent() : Value(remoteSession),
    );
  }

  factory Attempt.fromJson(Map<String, dynamic> json, {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Attempt(
      id: serializer.fromJson<int>(json['id']),
      at: serializer.fromJson<DateTime>(json['at']),
      profileId: serializer.fromJson<String>(json['profileId']),
      packId: serializer.fromJson<String>(json['packId']),
      packVersion: serializer.fromJson<String>(json['packVersion']),
      lessonId: serializer.fromJson<String>(json['lessonId']),
      activityId: serializer.fromJson<String>(json['activityId']),
      activityRevision: serializer.fromJson<int>(json['activityRevision']),
      template: serializer.fromJson<String>(json['template']),
      templateVersion: serializer.fromJson<String>(json['templateVersion']),
      skillId: serializer.fromJson<String>(json['skillId']),
      result: serializer.fromJson<String>(json['result']),
      attemptNo: serializer.fromJson<int>(json['attemptNo']),
      hintLevel: serializer.fromJson<int>(json['hintLevel']),
      misconceptionTag: serializer.fromJson<String>(json['misconceptionTag']),
      response: serializer.fromJson<String>(json['response']),
      durationMs: serializer.fromJson<int>(json['durationMs']),
      sessionId: serializer.fromJson<int?>(json['sessionId']),
      input: serializer.fromJson<String>(json['input']),
      eventId: serializer.fromJson<String?>(json['eventId']),
      syncedAt: serializer.fromJson<DateTime?>(json['syncedAt']),
      remoteSession: serializer.fromJson<String?>(json['remoteSession']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'at': serializer.toJson<DateTime>(at),
      'profileId': serializer.toJson<String>(profileId),
      'packId': serializer.toJson<String>(packId),
      'packVersion': serializer.toJson<String>(packVersion),
      'lessonId': serializer.toJson<String>(lessonId),
      'activityId': serializer.toJson<String>(activityId),
      'activityRevision': serializer.toJson<int>(activityRevision),
      'template': serializer.toJson<String>(template),
      'templateVersion': serializer.toJson<String>(templateVersion),
      'skillId': serializer.toJson<String>(skillId),
      'result': serializer.toJson<String>(result),
      'attemptNo': serializer.toJson<int>(attemptNo),
      'hintLevel': serializer.toJson<int>(hintLevel),
      'misconceptionTag': serializer.toJson<String>(misconceptionTag),
      'response': serializer.toJson<String>(response),
      'durationMs': serializer.toJson<int>(durationMs),
      'sessionId': serializer.toJson<int?>(sessionId),
      'input': serializer.toJson<String>(input),
      'eventId': serializer.toJson<String?>(eventId),
      'syncedAt': serializer.toJson<DateTime?>(syncedAt),
      'remoteSession': serializer.toJson<String?>(remoteSession),
    };
  }

  Attempt copyWith({
    int? id,
    DateTime? at,
    String? profileId,
    String? packId,
    String? packVersion,
    String? lessonId,
    String? activityId,
    int? activityRevision,
    String? template,
    String? templateVersion,
    String? skillId,
    String? result,
    int? attemptNo,
    int? hintLevel,
    String? misconceptionTag,
    String? response,
    int? durationMs,
    Value<int?> sessionId = const Value.absent(),
    String? input,
    Value<String?> eventId = const Value.absent(),
    Value<DateTime?> syncedAt = const Value.absent(),
    Value<String?> remoteSession = const Value.absent(),
  }) => Attempt(
    id: id ?? this.id,
    at: at ?? this.at,
    profileId: profileId ?? this.profileId,
    packId: packId ?? this.packId,
    packVersion: packVersion ?? this.packVersion,
    lessonId: lessonId ?? this.lessonId,
    activityId: activityId ?? this.activityId,
    activityRevision: activityRevision ?? this.activityRevision,
    template: template ?? this.template,
    templateVersion: templateVersion ?? this.templateVersion,
    skillId: skillId ?? this.skillId,
    result: result ?? this.result,
    attemptNo: attemptNo ?? this.attemptNo,
    hintLevel: hintLevel ?? this.hintLevel,
    misconceptionTag: misconceptionTag ?? this.misconceptionTag,
    response: response ?? this.response,
    durationMs: durationMs ?? this.durationMs,
    sessionId: sessionId.present ? sessionId.value : this.sessionId,
    input: input ?? this.input,
    eventId: eventId.present ? eventId.value : this.eventId,
    syncedAt: syncedAt.present ? syncedAt.value : this.syncedAt,
    remoteSession: remoteSession.present ? remoteSession.value : this.remoteSession,
  );
  Attempt copyWithCompanion(AttemptsCompanion data) {
    return Attempt(
      id: data.id.present ? data.id.value : this.id,
      at: data.at.present ? data.at.value : this.at,
      profileId: data.profileId.present ? data.profileId.value : this.profileId,
      packId: data.packId.present ? data.packId.value : this.packId,
      packVersion: data.packVersion.present ? data.packVersion.value : this.packVersion,
      lessonId: data.lessonId.present ? data.lessonId.value : this.lessonId,
      activityId: data.activityId.present ? data.activityId.value : this.activityId,
      activityRevision: data.activityRevision.present ? data.activityRevision.value : this.activityRevision,
      template: data.template.present ? data.template.value : this.template,
      templateVersion: data.templateVersion.present ? data.templateVersion.value : this.templateVersion,
      skillId: data.skillId.present ? data.skillId.value : this.skillId,
      result: data.result.present ? data.result.value : this.result,
      attemptNo: data.attemptNo.present ? data.attemptNo.value : this.attemptNo,
      hintLevel: data.hintLevel.present ? data.hintLevel.value : this.hintLevel,
      misconceptionTag: data.misconceptionTag.present ? data.misconceptionTag.value : this.misconceptionTag,
      response: data.response.present ? data.response.value : this.response,
      durationMs: data.durationMs.present ? data.durationMs.value : this.durationMs,
      sessionId: data.sessionId.present ? data.sessionId.value : this.sessionId,
      input: data.input.present ? data.input.value : this.input,
      eventId: data.eventId.present ? data.eventId.value : this.eventId,
      syncedAt: data.syncedAt.present ? data.syncedAt.value : this.syncedAt,
      remoteSession: data.remoteSession.present ? data.remoteSession.value : this.remoteSession,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Attempt(')
          ..write('id: $id, ')
          ..write('at: $at, ')
          ..write('profileId: $profileId, ')
          ..write('packId: $packId, ')
          ..write('packVersion: $packVersion, ')
          ..write('lessonId: $lessonId, ')
          ..write('activityId: $activityId, ')
          ..write('activityRevision: $activityRevision, ')
          ..write('template: $template, ')
          ..write('templateVersion: $templateVersion, ')
          ..write('skillId: $skillId, ')
          ..write('result: $result, ')
          ..write('attemptNo: $attemptNo, ')
          ..write('hintLevel: $hintLevel, ')
          ..write('misconceptionTag: $misconceptionTag, ')
          ..write('response: $response, ')
          ..write('durationMs: $durationMs, ')
          ..write('sessionId: $sessionId, ')
          ..write('input: $input, ')
          ..write('eventId: $eventId, ')
          ..write('syncedAt: $syncedAt, ')
          ..write('remoteSession: $remoteSession')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
    id,
    at,
    profileId,
    packId,
    packVersion,
    lessonId,
    activityId,
    activityRevision,
    template,
    templateVersion,
    skillId,
    result,
    attemptNo,
    hintLevel,
    misconceptionTag,
    response,
    durationMs,
    sessionId,
    input,
    eventId,
    syncedAt,
    remoteSession,
  ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Attempt &&
          other.id == this.id &&
          other.at == this.at &&
          other.profileId == this.profileId &&
          other.packId == this.packId &&
          other.packVersion == this.packVersion &&
          other.lessonId == this.lessonId &&
          other.activityId == this.activityId &&
          other.activityRevision == this.activityRevision &&
          other.template == this.template &&
          other.templateVersion == this.templateVersion &&
          other.skillId == this.skillId &&
          other.result == this.result &&
          other.attemptNo == this.attemptNo &&
          other.hintLevel == this.hintLevel &&
          other.misconceptionTag == this.misconceptionTag &&
          other.response == this.response &&
          other.durationMs == this.durationMs &&
          other.sessionId == this.sessionId &&
          other.input == this.input &&
          other.eventId == this.eventId &&
          other.syncedAt == this.syncedAt &&
          other.remoteSession == this.remoteSession);
}

class AttemptsCompanion extends UpdateCompanion<Attempt> {
  final Value<int> id;
  final Value<DateTime> at;
  final Value<String> profileId;
  final Value<String> packId;
  final Value<String> packVersion;
  final Value<String> lessonId;
  final Value<String> activityId;
  final Value<int> activityRevision;
  final Value<String> template;
  final Value<String> templateVersion;
  final Value<String> skillId;
  final Value<String> result;
  final Value<int> attemptNo;
  final Value<int> hintLevel;
  final Value<String> misconceptionTag;
  final Value<String> response;
  final Value<int> durationMs;
  final Value<int?> sessionId;
  final Value<String> input;
  final Value<String?> eventId;
  final Value<DateTime?> syncedAt;
  final Value<String?> remoteSession;
  const AttemptsCompanion({
    this.id = const Value.absent(),
    this.at = const Value.absent(),
    this.profileId = const Value.absent(),
    this.packId = const Value.absent(),
    this.packVersion = const Value.absent(),
    this.lessonId = const Value.absent(),
    this.activityId = const Value.absent(),
    this.activityRevision = const Value.absent(),
    this.template = const Value.absent(),
    this.templateVersion = const Value.absent(),
    this.skillId = const Value.absent(),
    this.result = const Value.absent(),
    this.attemptNo = const Value.absent(),
    this.hintLevel = const Value.absent(),
    this.misconceptionTag = const Value.absent(),
    this.response = const Value.absent(),
    this.durationMs = const Value.absent(),
    this.sessionId = const Value.absent(),
    this.input = const Value.absent(),
    this.eventId = const Value.absent(),
    this.syncedAt = const Value.absent(),
    this.remoteSession = const Value.absent(),
  });
  AttemptsCompanion.insert({
    this.id = const Value.absent(),
    required DateTime at,
    required String profileId,
    required String packId,
    required String packVersion,
    this.lessonId = const Value.absent(),
    required String activityId,
    required int activityRevision,
    required String template,
    required String templateVersion,
    required String skillId,
    required String result,
    required int attemptNo,
    required int hintLevel,
    this.misconceptionTag = const Value.absent(),
    this.response = const Value.absent(),
    this.durationMs = const Value.absent(),
    this.sessionId = const Value.absent(),
    this.input = const Value.absent(),
    this.eventId = const Value.absent(),
    this.syncedAt = const Value.absent(),
    this.remoteSession = const Value.absent(),
  }) : at = Value(at),
       profileId = Value(profileId),
       packId = Value(packId),
       packVersion = Value(packVersion),
       activityId = Value(activityId),
       activityRevision = Value(activityRevision),
       template = Value(template),
       templateVersion = Value(templateVersion),
       skillId = Value(skillId),
       result = Value(result),
       attemptNo = Value(attemptNo),
       hintLevel = Value(hintLevel);
  static Insertable<Attempt> custom({
    Expression<int>? id,
    Expression<DateTime>? at,
    Expression<String>? profileId,
    Expression<String>? packId,
    Expression<String>? packVersion,
    Expression<String>? lessonId,
    Expression<String>? activityId,
    Expression<int>? activityRevision,
    Expression<String>? template,
    Expression<String>? templateVersion,
    Expression<String>? skillId,
    Expression<String>? result,
    Expression<int>? attemptNo,
    Expression<int>? hintLevel,
    Expression<String>? misconceptionTag,
    Expression<String>? response,
    Expression<int>? durationMs,
    Expression<int>? sessionId,
    Expression<String>? input,
    Expression<String>? eventId,
    Expression<DateTime>? syncedAt,
    Expression<String>? remoteSession,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (at != null) 'at': at,
      if (profileId != null) 'profile_id': profileId,
      if (packId != null) 'pack_id': packId,
      if (packVersion != null) 'pack_version': packVersion,
      if (lessonId != null) 'lesson_id': lessonId,
      if (activityId != null) 'activity_id': activityId,
      if (activityRevision != null) 'activity_revision': activityRevision,
      if (template != null) 'template': template,
      if (templateVersion != null) 'template_version': templateVersion,
      if (skillId != null) 'skill_id': skillId,
      if (result != null) 'result': result,
      if (attemptNo != null) 'attempt_no': attemptNo,
      if (hintLevel != null) 'hint_level': hintLevel,
      if (misconceptionTag != null) 'misconception_tag': misconceptionTag,
      if (response != null) 'response': response,
      if (durationMs != null) 'duration_ms': durationMs,
      if (sessionId != null) 'session_id': sessionId,
      if (input != null) 'input': input,
      if (eventId != null) 'event_id': eventId,
      if (syncedAt != null) 'synced_at': syncedAt,
      if (remoteSession != null) 'remote_session': remoteSession,
    });
  }

  AttemptsCompanion copyWith({
    Value<int>? id,
    Value<DateTime>? at,
    Value<String>? profileId,
    Value<String>? packId,
    Value<String>? packVersion,
    Value<String>? lessonId,
    Value<String>? activityId,
    Value<int>? activityRevision,
    Value<String>? template,
    Value<String>? templateVersion,
    Value<String>? skillId,
    Value<String>? result,
    Value<int>? attemptNo,
    Value<int>? hintLevel,
    Value<String>? misconceptionTag,
    Value<String>? response,
    Value<int>? durationMs,
    Value<int?>? sessionId,
    Value<String>? input,
    Value<String?>? eventId,
    Value<DateTime?>? syncedAt,
    Value<String?>? remoteSession,
  }) {
    return AttemptsCompanion(
      id: id ?? this.id,
      at: at ?? this.at,
      profileId: profileId ?? this.profileId,
      packId: packId ?? this.packId,
      packVersion: packVersion ?? this.packVersion,
      lessonId: lessonId ?? this.lessonId,
      activityId: activityId ?? this.activityId,
      activityRevision: activityRevision ?? this.activityRevision,
      template: template ?? this.template,
      templateVersion: templateVersion ?? this.templateVersion,
      skillId: skillId ?? this.skillId,
      result: result ?? this.result,
      attemptNo: attemptNo ?? this.attemptNo,
      hintLevel: hintLevel ?? this.hintLevel,
      misconceptionTag: misconceptionTag ?? this.misconceptionTag,
      response: response ?? this.response,
      durationMs: durationMs ?? this.durationMs,
      sessionId: sessionId ?? this.sessionId,
      input: input ?? this.input,
      eventId: eventId ?? this.eventId,
      syncedAt: syncedAt ?? this.syncedAt,
      remoteSession: remoteSession ?? this.remoteSession,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (at.present) {
      map['at'] = Variable<DateTime>(at.value);
    }
    if (profileId.present) {
      map['profile_id'] = Variable<String>(profileId.value);
    }
    if (packId.present) {
      map['pack_id'] = Variable<String>(packId.value);
    }
    if (packVersion.present) {
      map['pack_version'] = Variable<String>(packVersion.value);
    }
    if (lessonId.present) {
      map['lesson_id'] = Variable<String>(lessonId.value);
    }
    if (activityId.present) {
      map['activity_id'] = Variable<String>(activityId.value);
    }
    if (activityRevision.present) {
      map['activity_revision'] = Variable<int>(activityRevision.value);
    }
    if (template.present) {
      map['template'] = Variable<String>(template.value);
    }
    if (templateVersion.present) {
      map['template_version'] = Variable<String>(templateVersion.value);
    }
    if (skillId.present) {
      map['skill_id'] = Variable<String>(skillId.value);
    }
    if (result.present) {
      map['result'] = Variable<String>(result.value);
    }
    if (attemptNo.present) {
      map['attempt_no'] = Variable<int>(attemptNo.value);
    }
    if (hintLevel.present) {
      map['hint_level'] = Variable<int>(hintLevel.value);
    }
    if (misconceptionTag.present) {
      map['misconception_tag'] = Variable<String>(misconceptionTag.value);
    }
    if (response.present) {
      map['response'] = Variable<String>(response.value);
    }
    if (durationMs.present) {
      map['duration_ms'] = Variable<int>(durationMs.value);
    }
    if (sessionId.present) {
      map['session_id'] = Variable<int>(sessionId.value);
    }
    if (input.present) {
      map['input'] = Variable<String>(input.value);
    }
    if (eventId.present) {
      map['event_id'] = Variable<String>(eventId.value);
    }
    if (syncedAt.present) {
      map['synced_at'] = Variable<DateTime>(syncedAt.value);
    }
    if (remoteSession.present) {
      map['remote_session'] = Variable<String>(remoteSession.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AttemptsCompanion(')
          ..write('id: $id, ')
          ..write('at: $at, ')
          ..write('profileId: $profileId, ')
          ..write('packId: $packId, ')
          ..write('packVersion: $packVersion, ')
          ..write('lessonId: $lessonId, ')
          ..write('activityId: $activityId, ')
          ..write('activityRevision: $activityRevision, ')
          ..write('template: $template, ')
          ..write('templateVersion: $templateVersion, ')
          ..write('skillId: $skillId, ')
          ..write('result: $result, ')
          ..write('attemptNo: $attemptNo, ')
          ..write('hintLevel: $hintLevel, ')
          ..write('misconceptionTag: $misconceptionTag, ')
          ..write('response: $response, ')
          ..write('durationMs: $durationMs, ')
          ..write('sessionId: $sessionId, ')
          ..write('input: $input, ')
          ..write('eventId: $eventId, ')
          ..write('syncedAt: $syncedAt, ')
          ..write('remoteSession: $remoteSession')
          ..write(')'))
        .toString();
  }
}

class $SessionsTable extends Sessions with TableInfo<$SessionsTable, Session> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SessionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'),
  );
  static const VerificationMeta _profileIdMeta = const VerificationMeta('profileId');
  @override
  late final GeneratedColumn<String> profileId = GeneratedColumn<String>(
    'profile_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _startedAtMeta = const VerificationMeta('startedAt');
  @override
  late final GeneratedColumn<DateTime> startedAt = GeneratedColumn<DateTime>(
    'started_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _endedAtMeta = const VerificationMeta('endedAt');
  @override
  late final GeneratedColumn<DateTime> endedAt = GeneratedColumn<DateTime>(
    'ended_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _planMeta = const VerificationMeta('plan');
  @override
  late final GeneratedColumn<String> plan = GeneratedColumn<String>(
    'plan',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant<String>(''),
  );
  static const VerificationMeta _endReasonMeta = const VerificationMeta('endReason');
  @override
  late final GeneratedColumn<String> endReason = GeneratedColumn<String>(
    'end_reason',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant<String>(''),
  );
  static const VerificationMeta _eventIdMeta = const VerificationMeta('eventId');
  @override
  late final GeneratedColumn<String> eventId = GeneratedColumn<String>(
    'event_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _syncedAtMeta = const VerificationMeta('syncedAt');
  @override
  late final GeneratedColumn<DateTime> syncedAt = GeneratedColumn<DateTime>(
    'synced_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _remoteKeyMeta = const VerificationMeta('remoteKey');
  @override
  late final GeneratedColumn<String> remoteKey = GeneratedColumn<String>(
    'remote_key',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    profileId,
    startedAt,
    endedAt,
    plan,
    endReason,
    eventId,
    syncedAt,
    remoteKey,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sessions';
  @override
  VerificationContext validateIntegrity(Insertable<Session> instance, {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('profile_id')) {
      context.handle(_profileIdMeta, profileId.isAcceptableOrUnknown(data['profile_id']!, _profileIdMeta));
    } else if (isInserting) {
      context.missing(_profileIdMeta);
    }
    if (data.containsKey('started_at')) {
      context.handle(_startedAtMeta, startedAt.isAcceptableOrUnknown(data['started_at']!, _startedAtMeta));
    } else if (isInserting) {
      context.missing(_startedAtMeta);
    }
    if (data.containsKey('ended_at')) {
      context.handle(_endedAtMeta, endedAt.isAcceptableOrUnknown(data['ended_at']!, _endedAtMeta));
    }
    if (data.containsKey('plan')) {
      context.handle(_planMeta, plan.isAcceptableOrUnknown(data['plan']!, _planMeta));
    }
    if (data.containsKey('end_reason')) {
      context.handle(_endReasonMeta, endReason.isAcceptableOrUnknown(data['end_reason']!, _endReasonMeta));
    }
    if (data.containsKey('event_id')) {
      context.handle(_eventIdMeta, eventId.isAcceptableOrUnknown(data['event_id']!, _eventIdMeta));
    }
    if (data.containsKey('synced_at')) {
      context.handle(_syncedAtMeta, syncedAt.isAcceptableOrUnknown(data['synced_at']!, _syncedAtMeta));
    }
    if (data.containsKey('remote_key')) {
      context.handle(_remoteKeyMeta, remoteKey.isAcceptableOrUnknown(data['remote_key']!, _remoteKeyMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Session map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Session(
      id: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      profileId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}profile_id'],
      )!,
      startedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}started_at'],
      )!,
      endedAt: attachedDatabase.typeMapping.read(DriftSqlType.dateTime, data['${effectivePrefix}ended_at']),
      plan: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}plan'])!,
      endReason: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}end_reason'],
      )!,
      eventId: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}event_id']),
      syncedAt: attachedDatabase.typeMapping.read(DriftSqlType.dateTime, data['${effectivePrefix}synced_at']),
      remoteKey: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}remote_key']),
    );
  }

  @override
  $SessionsTable createAlias(String alias) {
    return $SessionsTable(attachedDatabase, alias);
  }
}

class Session extends DataClass implements Insertable<Session> {
  final int id;
  final String profileId;
  final DateTime startedAt;
  final DateTime? endedAt;

  /// What was played, for example `lesson:butterflies` or `session:A`.
  final String plan;

  /// A fixed word: `finished`, `home` (the child left), `limit` (the parent's time was up) or empty while it runs.
  final String endReason;

  /// Sync (M7b): when the visit was sent (only once it has ended), or the id of the event it came from, and for a visit
  /// from another device its name there (`deviceId:number`).
  final String? eventId;
  final DateTime? syncedAt;
  final String? remoteKey;
  const Session({
    required this.id,
    required this.profileId,
    required this.startedAt,
    this.endedAt,
    required this.plan,
    required this.endReason,
    this.eventId,
    this.syncedAt,
    this.remoteKey,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['profile_id'] = Variable<String>(profileId);
    map['started_at'] = Variable<DateTime>(startedAt);
    if (!nullToAbsent || endedAt != null) {
      map['ended_at'] = Variable<DateTime>(endedAt);
    }
    map['plan'] = Variable<String>(plan);
    map['end_reason'] = Variable<String>(endReason);
    if (!nullToAbsent || eventId != null) {
      map['event_id'] = Variable<String>(eventId);
    }
    if (!nullToAbsent || syncedAt != null) {
      map['synced_at'] = Variable<DateTime>(syncedAt);
    }
    if (!nullToAbsent || remoteKey != null) {
      map['remote_key'] = Variable<String>(remoteKey);
    }
    return map;
  }

  SessionsCompanion toCompanion(bool nullToAbsent) {
    return SessionsCompanion(
      id: Value(id),
      profileId: Value(profileId),
      startedAt: Value(startedAt),
      endedAt: endedAt == null && nullToAbsent ? const Value.absent() : Value(endedAt),
      plan: Value(plan),
      endReason: Value(endReason),
      eventId: eventId == null && nullToAbsent ? const Value.absent() : Value(eventId),
      syncedAt: syncedAt == null && nullToAbsent ? const Value.absent() : Value(syncedAt),
      remoteKey: remoteKey == null && nullToAbsent ? const Value.absent() : Value(remoteKey),
    );
  }

  factory Session.fromJson(Map<String, dynamic> json, {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Session(
      id: serializer.fromJson<int>(json['id']),
      profileId: serializer.fromJson<String>(json['profileId']),
      startedAt: serializer.fromJson<DateTime>(json['startedAt']),
      endedAt: serializer.fromJson<DateTime?>(json['endedAt']),
      plan: serializer.fromJson<String>(json['plan']),
      endReason: serializer.fromJson<String>(json['endReason']),
      eventId: serializer.fromJson<String?>(json['eventId']),
      syncedAt: serializer.fromJson<DateTime?>(json['syncedAt']),
      remoteKey: serializer.fromJson<String?>(json['remoteKey']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'profileId': serializer.toJson<String>(profileId),
      'startedAt': serializer.toJson<DateTime>(startedAt),
      'endedAt': serializer.toJson<DateTime?>(endedAt),
      'plan': serializer.toJson<String>(plan),
      'endReason': serializer.toJson<String>(endReason),
      'eventId': serializer.toJson<String?>(eventId),
      'syncedAt': serializer.toJson<DateTime?>(syncedAt),
      'remoteKey': serializer.toJson<String?>(remoteKey),
    };
  }

  Session copyWith({
    int? id,
    String? profileId,
    DateTime? startedAt,
    Value<DateTime?> endedAt = const Value.absent(),
    String? plan,
    String? endReason,
    Value<String?> eventId = const Value.absent(),
    Value<DateTime?> syncedAt = const Value.absent(),
    Value<String?> remoteKey = const Value.absent(),
  }) => Session(
    id: id ?? this.id,
    profileId: profileId ?? this.profileId,
    startedAt: startedAt ?? this.startedAt,
    endedAt: endedAt.present ? endedAt.value : this.endedAt,
    plan: plan ?? this.plan,
    endReason: endReason ?? this.endReason,
    eventId: eventId.present ? eventId.value : this.eventId,
    syncedAt: syncedAt.present ? syncedAt.value : this.syncedAt,
    remoteKey: remoteKey.present ? remoteKey.value : this.remoteKey,
  );
  Session copyWithCompanion(SessionsCompanion data) {
    return Session(
      id: data.id.present ? data.id.value : this.id,
      profileId: data.profileId.present ? data.profileId.value : this.profileId,
      startedAt: data.startedAt.present ? data.startedAt.value : this.startedAt,
      endedAt: data.endedAt.present ? data.endedAt.value : this.endedAt,
      plan: data.plan.present ? data.plan.value : this.plan,
      endReason: data.endReason.present ? data.endReason.value : this.endReason,
      eventId: data.eventId.present ? data.eventId.value : this.eventId,
      syncedAt: data.syncedAt.present ? data.syncedAt.value : this.syncedAt,
      remoteKey: data.remoteKey.present ? data.remoteKey.value : this.remoteKey,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Session(')
          ..write('id: $id, ')
          ..write('profileId: $profileId, ')
          ..write('startedAt: $startedAt, ')
          ..write('endedAt: $endedAt, ')
          ..write('plan: $plan, ')
          ..write('endReason: $endReason, ')
          ..write('eventId: $eventId, ')
          ..write('syncedAt: $syncedAt, ')
          ..write('remoteKey: $remoteKey')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, profileId, startedAt, endedAt, plan, endReason, eventId, syncedAt, remoteKey);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Session &&
          other.id == this.id &&
          other.profileId == this.profileId &&
          other.startedAt == this.startedAt &&
          other.endedAt == this.endedAt &&
          other.plan == this.plan &&
          other.endReason == this.endReason &&
          other.eventId == this.eventId &&
          other.syncedAt == this.syncedAt &&
          other.remoteKey == this.remoteKey);
}

class SessionsCompanion extends UpdateCompanion<Session> {
  final Value<int> id;
  final Value<String> profileId;
  final Value<DateTime> startedAt;
  final Value<DateTime?> endedAt;
  final Value<String> plan;
  final Value<String> endReason;
  final Value<String?> eventId;
  final Value<DateTime?> syncedAt;
  final Value<String?> remoteKey;
  const SessionsCompanion({
    this.id = const Value.absent(),
    this.profileId = const Value.absent(),
    this.startedAt = const Value.absent(),
    this.endedAt = const Value.absent(),
    this.plan = const Value.absent(),
    this.endReason = const Value.absent(),
    this.eventId = const Value.absent(),
    this.syncedAt = const Value.absent(),
    this.remoteKey = const Value.absent(),
  });
  SessionsCompanion.insert({
    this.id = const Value.absent(),
    required String profileId,
    required DateTime startedAt,
    this.endedAt = const Value.absent(),
    this.plan = const Value.absent(),
    this.endReason = const Value.absent(),
    this.eventId = const Value.absent(),
    this.syncedAt = const Value.absent(),
    this.remoteKey = const Value.absent(),
  }) : profileId = Value(profileId),
       startedAt = Value(startedAt);
  static Insertable<Session> custom({
    Expression<int>? id,
    Expression<String>? profileId,
    Expression<DateTime>? startedAt,
    Expression<DateTime>? endedAt,
    Expression<String>? plan,
    Expression<String>? endReason,
    Expression<String>? eventId,
    Expression<DateTime>? syncedAt,
    Expression<String>? remoteKey,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (profileId != null) 'profile_id': profileId,
      if (startedAt != null) 'started_at': startedAt,
      if (endedAt != null) 'ended_at': endedAt,
      if (plan != null) 'plan': plan,
      if (endReason != null) 'end_reason': endReason,
      if (eventId != null) 'event_id': eventId,
      if (syncedAt != null) 'synced_at': syncedAt,
      if (remoteKey != null) 'remote_key': remoteKey,
    });
  }

  SessionsCompanion copyWith({
    Value<int>? id,
    Value<String>? profileId,
    Value<DateTime>? startedAt,
    Value<DateTime?>? endedAt,
    Value<String>? plan,
    Value<String>? endReason,
    Value<String?>? eventId,
    Value<DateTime?>? syncedAt,
    Value<String?>? remoteKey,
  }) {
    return SessionsCompanion(
      id: id ?? this.id,
      profileId: profileId ?? this.profileId,
      startedAt: startedAt ?? this.startedAt,
      endedAt: endedAt ?? this.endedAt,
      plan: plan ?? this.plan,
      endReason: endReason ?? this.endReason,
      eventId: eventId ?? this.eventId,
      syncedAt: syncedAt ?? this.syncedAt,
      remoteKey: remoteKey ?? this.remoteKey,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (profileId.present) {
      map['profile_id'] = Variable<String>(profileId.value);
    }
    if (startedAt.present) {
      map['started_at'] = Variable<DateTime>(startedAt.value);
    }
    if (endedAt.present) {
      map['ended_at'] = Variable<DateTime>(endedAt.value);
    }
    if (plan.present) {
      map['plan'] = Variable<String>(plan.value);
    }
    if (endReason.present) {
      map['end_reason'] = Variable<String>(endReason.value);
    }
    if (eventId.present) {
      map['event_id'] = Variable<String>(eventId.value);
    }
    if (syncedAt.present) {
      map['synced_at'] = Variable<DateTime>(syncedAt.value);
    }
    if (remoteKey.present) {
      map['remote_key'] = Variable<String>(remoteKey.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SessionsCompanion(')
          ..write('id: $id, ')
          ..write('profileId: $profileId, ')
          ..write('startedAt: $startedAt, ')
          ..write('endedAt: $endedAt, ')
          ..write('plan: $plan, ')
          ..write('endReason: $endReason, ')
          ..write('eventId: $eventId, ')
          ..write('syncedAt: $syncedAt, ')
          ..write('remoteKey: $remoteKey')
          ..write(')'))
        .toString();
  }
}

class $VoiceListensTable extends VoiceListens with TableInfo<$VoiceListensTable, VoiceListen> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $VoiceListensTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'),
  );
  static const VerificationMeta _atMeta = const VerificationMeta('at');
  @override
  late final GeneratedColumn<DateTime> at = GeneratedColumn<DateTime>(
    'at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _profileIdMeta = const VerificationMeta('profileId');
  @override
  late final GeneratedColumn<String> profileId = GeneratedColumn<String>(
    'profile_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _answerTypeMeta = const VerificationMeta('answerType');
  @override
  late final GeneratedColumn<String> answerType = GeneratedColumn<String>(
    'answer_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _outcomeMeta = const VerificationMeta('outcome');
  @override
  late final GeneratedColumn<String> outcome = GeneratedColumn<String>(
    'outcome',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, at, profileId, answerType, outcome];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'voice_listens';
  @override
  VerificationContext validateIntegrity(Insertable<VoiceListen> instance, {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('at')) {
      context.handle(_atMeta, at.isAcceptableOrUnknown(data['at']!, _atMeta));
    } else if (isInserting) {
      context.missing(_atMeta);
    }
    if (data.containsKey('profile_id')) {
      context.handle(_profileIdMeta, profileId.isAcceptableOrUnknown(data['profile_id']!, _profileIdMeta));
    } else if (isInserting) {
      context.missing(_profileIdMeta);
    }
    if (data.containsKey('answer_type')) {
      context.handle(
        _answerTypeMeta,
        answerType.isAcceptableOrUnknown(data['answer_type']!, _answerTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_answerTypeMeta);
    }
    if (data.containsKey('outcome')) {
      context.handle(_outcomeMeta, outcome.isAcceptableOrUnknown(data['outcome']!, _outcomeMeta));
    } else if (isInserting) {
      context.missing(_outcomeMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  VoiceListen map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return VoiceListen(
      id: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      at: attachedDatabase.typeMapping.read(DriftSqlType.dateTime, data['${effectivePrefix}at'])!,
      profileId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}profile_id'],
      )!,
      answerType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}answer_type'],
      )!,
      outcome: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}outcome'])!,
    );
  }

  @override
  $VoiceListensTable createAlias(String alias) {
    return $VoiceListensTable(attachedDatabase, alias);
  }
}

class VoiceListen extends DataClass implements Insertable<VoiceListen> {
  final int id;
  final DateTime at;
  final String profileId;

  /// What kind of answer was expected: `number`, `colour` or `word`.
  final String answerType;

  /// `accepted`, `confirmed`, `declined`, `unclear`, `silent`, `intent` or `failed`.
  final String outcome;
  const VoiceListen({
    required this.id,
    required this.at,
    required this.profileId,
    required this.answerType,
    required this.outcome,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['at'] = Variable<DateTime>(at);
    map['profile_id'] = Variable<String>(profileId);
    map['answer_type'] = Variable<String>(answerType);
    map['outcome'] = Variable<String>(outcome);
    return map;
  }

  VoiceListensCompanion toCompanion(bool nullToAbsent) {
    return VoiceListensCompanion(
      id: Value(id),
      at: Value(at),
      profileId: Value(profileId),
      answerType: Value(answerType),
      outcome: Value(outcome),
    );
  }

  factory VoiceListen.fromJson(Map<String, dynamic> json, {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return VoiceListen(
      id: serializer.fromJson<int>(json['id']),
      at: serializer.fromJson<DateTime>(json['at']),
      profileId: serializer.fromJson<String>(json['profileId']),
      answerType: serializer.fromJson<String>(json['answerType']),
      outcome: serializer.fromJson<String>(json['outcome']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'at': serializer.toJson<DateTime>(at),
      'profileId': serializer.toJson<String>(profileId),
      'answerType': serializer.toJson<String>(answerType),
      'outcome': serializer.toJson<String>(outcome),
    };
  }

  VoiceListen copyWith({int? id, DateTime? at, String? profileId, String? answerType, String? outcome}) =>
      VoiceListen(
        id: id ?? this.id,
        at: at ?? this.at,
        profileId: profileId ?? this.profileId,
        answerType: answerType ?? this.answerType,
        outcome: outcome ?? this.outcome,
      );
  VoiceListen copyWithCompanion(VoiceListensCompanion data) {
    return VoiceListen(
      id: data.id.present ? data.id.value : this.id,
      at: data.at.present ? data.at.value : this.at,
      profileId: data.profileId.present ? data.profileId.value : this.profileId,
      answerType: data.answerType.present ? data.answerType.value : this.answerType,
      outcome: data.outcome.present ? data.outcome.value : this.outcome,
    );
  }

  @override
  String toString() {
    return (StringBuffer('VoiceListen(')
          ..write('id: $id, ')
          ..write('at: $at, ')
          ..write('profileId: $profileId, ')
          ..write('answerType: $answerType, ')
          ..write('outcome: $outcome')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, at, profileId, answerType, outcome);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is VoiceListen &&
          other.id == this.id &&
          other.at == this.at &&
          other.profileId == this.profileId &&
          other.answerType == this.answerType &&
          other.outcome == this.outcome);
}

class VoiceListensCompanion extends UpdateCompanion<VoiceListen> {
  final Value<int> id;
  final Value<DateTime> at;
  final Value<String> profileId;
  final Value<String> answerType;
  final Value<String> outcome;
  const VoiceListensCompanion({
    this.id = const Value.absent(),
    this.at = const Value.absent(),
    this.profileId = const Value.absent(),
    this.answerType = const Value.absent(),
    this.outcome = const Value.absent(),
  });
  VoiceListensCompanion.insert({
    this.id = const Value.absent(),
    required DateTime at,
    required String profileId,
    required String answerType,
    required String outcome,
  }) : at = Value(at),
       profileId = Value(profileId),
       answerType = Value(answerType),
       outcome = Value(outcome);
  static Insertable<VoiceListen> custom({
    Expression<int>? id,
    Expression<DateTime>? at,
    Expression<String>? profileId,
    Expression<String>? answerType,
    Expression<String>? outcome,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (at != null) 'at': at,
      if (profileId != null) 'profile_id': profileId,
      if (answerType != null) 'answer_type': answerType,
      if (outcome != null) 'outcome': outcome,
    });
  }

  VoiceListensCompanion copyWith({
    Value<int>? id,
    Value<DateTime>? at,
    Value<String>? profileId,
    Value<String>? answerType,
    Value<String>? outcome,
  }) {
    return VoiceListensCompanion(
      id: id ?? this.id,
      at: at ?? this.at,
      profileId: profileId ?? this.profileId,
      answerType: answerType ?? this.answerType,
      outcome: outcome ?? this.outcome,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (at.present) {
      map['at'] = Variable<DateTime>(at.value);
    }
    if (profileId.present) {
      map['profile_id'] = Variable<String>(profileId.value);
    }
    if (answerType.present) {
      map['answer_type'] = Variable<String>(answerType.value);
    }
    if (outcome.present) {
      map['outcome'] = Variable<String>(outcome.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('VoiceListensCompanion(')
          ..write('id: $id, ')
          ..write('at: $at, ')
          ..write('profileId: $profileId, ')
          ..write('answerType: $answerType, ')
          ..write('outcome: $outcome')
          ..write(')'))
        .toString();
  }
}

class $AlertsTable extends Alerts with TableInfo<$AlertsTable, Alert> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AlertsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'),
  );
  static const VerificationMeta _atMeta = const VerificationMeta('at');
  @override
  late final GeneratedColumn<DateTime> at = GeneratedColumn<DateTime>(
    'at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _profileIdMeta = const VerificationMeta('profileId');
  @override
  late final GeneratedColumn<String> profileId = GeneratedColumn<String>(
    'profile_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _categoryMeta = const VerificationMeta('category');
  @override
  late final GeneratedColumn<String> category = GeneratedColumn<String>(
    'category',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _severityMeta = const VerificationMeta('severity');
  @override
  late final GeneratedColumn<String> severity = GeneratedColumn<String>(
    'severity',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _countMeta = const VerificationMeta('count');
  @override
  late final GeneratedColumn<int> count = GeneratedColumn<int>(
    'count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant<int>(0),
  );
  static const VerificationMeta _detailMeta = const VerificationMeta('detail');
  @override
  late final GeneratedColumn<String> detail = GeneratedColumn<String>(
    'detail',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant<String>(''),
  );
  static const VerificationMeta _wordsMeta = const VerificationMeta('words');
  @override
  late final GeneratedColumn<String> words = GeneratedColumn<String>(
    'words',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant<String>(''),
  );
  static const VerificationMeta _dedupeKeyMeta = const VerificationMeta('dedupeKey');
  @override
  late final GeneratedColumn<String> dedupeKey = GeneratedColumn<String>(
    'dedupe_key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _readAtMeta = const VerificationMeta('readAt');
  @override
  late final GeneratedColumn<DateTime> readAt = GeneratedColumn<DateTime>(
    'read_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _syncedAtMeta = const VerificationMeta('syncedAt');
  @override
  late final GeneratedColumn<DateTime> syncedAt = GeneratedColumn<DateTime>(
    'synced_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    at,
    profileId,
    category,
    severity,
    count,
    detail,
    words,
    dedupeKey,
    readAt,
    syncedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'alerts';
  @override
  VerificationContext validateIntegrity(Insertable<Alert> instance, {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('at')) {
      context.handle(_atMeta, at.isAcceptableOrUnknown(data['at']!, _atMeta));
    } else if (isInserting) {
      context.missing(_atMeta);
    }
    if (data.containsKey('profile_id')) {
      context.handle(_profileIdMeta, profileId.isAcceptableOrUnknown(data['profile_id']!, _profileIdMeta));
    }
    if (data.containsKey('category')) {
      context.handle(_categoryMeta, category.isAcceptableOrUnknown(data['category']!, _categoryMeta));
    } else if (isInserting) {
      context.missing(_categoryMeta);
    }
    if (data.containsKey('severity')) {
      context.handle(_severityMeta, severity.isAcceptableOrUnknown(data['severity']!, _severityMeta));
    } else if (isInserting) {
      context.missing(_severityMeta);
    }
    if (data.containsKey('count')) {
      context.handle(_countMeta, count.isAcceptableOrUnknown(data['count']!, _countMeta));
    }
    if (data.containsKey('detail')) {
      context.handle(_detailMeta, detail.isAcceptableOrUnknown(data['detail']!, _detailMeta));
    }
    if (data.containsKey('words')) {
      context.handle(_wordsMeta, words.isAcceptableOrUnknown(data['words']!, _wordsMeta));
    }
    if (data.containsKey('dedupe_key')) {
      context.handle(_dedupeKeyMeta, dedupeKey.isAcceptableOrUnknown(data['dedupe_key']!, _dedupeKeyMeta));
    } else if (isInserting) {
      context.missing(_dedupeKeyMeta);
    }
    if (data.containsKey('read_at')) {
      context.handle(_readAtMeta, readAt.isAcceptableOrUnknown(data['read_at']!, _readAtMeta));
    }
    if (data.containsKey('synced_at')) {
      context.handle(_syncedAtMeta, syncedAt.isAcceptableOrUnknown(data['synced_at']!, _syncedAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Alert map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Alert(
      id: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      at: attachedDatabase.typeMapping.read(DriftSqlType.dateTime, data['${effectivePrefix}at'])!,
      profileId: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}profile_id']),
      category: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}category'])!,
      severity: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}severity'])!,
      count: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}count'])!,
      detail: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}detail'])!,
      words: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}words'])!,
      dedupeKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}dedupe_key'],
      )!,
      readAt: attachedDatabase.typeMapping.read(DriftSqlType.dateTime, data['${effectivePrefix}read_at']),
      syncedAt: attachedDatabase.typeMapping.read(DriftSqlType.dateTime, data['${effectivePrefix}synced_at']),
    );
  }

  @override
  $AlertsTable createAlias(String alias) {
    return $AlertsTable(attachedDatabase, alias);
  }
}

class Alert extends DataClass implements Insertable<Alert> {
  final int id;
  final DateTime at;

  /// The child the alert is about, or null for one that concerns the device (someone at the parent gate).
  final String? profileId;

  /// An `AlertCategory` name and an `AlertSeverity` name.
  final String category;
  final String severity;

  /// Minutes, attempts or days, depending on the category.
  final int count;

  /// Fixed words only (an activity id).
  final String detail;

  /// The words the recogniser heard, kept only when the parent allows it.
  final String words;

  /// What makes this alert the same alert next time (one a day, one a session, one an event), so a scan never repeats it.
  final String dedupeKey;
  final DateTime? readAt;

  /// When the alert was sent to the family's other devices (an alert from another device is never sent back).
  final DateTime? syncedAt;
  const Alert({
    required this.id,
    required this.at,
    this.profileId,
    required this.category,
    required this.severity,
    required this.count,
    required this.detail,
    required this.words,
    required this.dedupeKey,
    this.readAt,
    this.syncedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['at'] = Variable<DateTime>(at);
    if (!nullToAbsent || profileId != null) {
      map['profile_id'] = Variable<String>(profileId);
    }
    map['category'] = Variable<String>(category);
    map['severity'] = Variable<String>(severity);
    map['count'] = Variable<int>(count);
    map['detail'] = Variable<String>(detail);
    map['words'] = Variable<String>(words);
    map['dedupe_key'] = Variable<String>(dedupeKey);
    if (!nullToAbsent || readAt != null) {
      map['read_at'] = Variable<DateTime>(readAt);
    }
    if (!nullToAbsent || syncedAt != null) {
      map['synced_at'] = Variable<DateTime>(syncedAt);
    }
    return map;
  }

  AlertsCompanion toCompanion(bool nullToAbsent) {
    return AlertsCompanion(
      id: Value(id),
      at: Value(at),
      profileId: profileId == null && nullToAbsent ? const Value.absent() : Value(profileId),
      category: Value(category),
      severity: Value(severity),
      count: Value(count),
      detail: Value(detail),
      words: Value(words),
      dedupeKey: Value(dedupeKey),
      readAt: readAt == null && nullToAbsent ? const Value.absent() : Value(readAt),
      syncedAt: syncedAt == null && nullToAbsent ? const Value.absent() : Value(syncedAt),
    );
  }

  factory Alert.fromJson(Map<String, dynamic> json, {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Alert(
      id: serializer.fromJson<int>(json['id']),
      at: serializer.fromJson<DateTime>(json['at']),
      profileId: serializer.fromJson<String?>(json['profileId']),
      category: serializer.fromJson<String>(json['category']),
      severity: serializer.fromJson<String>(json['severity']),
      count: serializer.fromJson<int>(json['count']),
      detail: serializer.fromJson<String>(json['detail']),
      words: serializer.fromJson<String>(json['words']),
      dedupeKey: serializer.fromJson<String>(json['dedupeKey']),
      readAt: serializer.fromJson<DateTime?>(json['readAt']),
      syncedAt: serializer.fromJson<DateTime?>(json['syncedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'at': serializer.toJson<DateTime>(at),
      'profileId': serializer.toJson<String?>(profileId),
      'category': serializer.toJson<String>(category),
      'severity': serializer.toJson<String>(severity),
      'count': serializer.toJson<int>(count),
      'detail': serializer.toJson<String>(detail),
      'words': serializer.toJson<String>(words),
      'dedupeKey': serializer.toJson<String>(dedupeKey),
      'readAt': serializer.toJson<DateTime?>(readAt),
      'syncedAt': serializer.toJson<DateTime?>(syncedAt),
    };
  }

  Alert copyWith({
    int? id,
    DateTime? at,
    Value<String?> profileId = const Value.absent(),
    String? category,
    String? severity,
    int? count,
    String? detail,
    String? words,
    String? dedupeKey,
    Value<DateTime?> readAt = const Value.absent(),
    Value<DateTime?> syncedAt = const Value.absent(),
  }) => Alert(
    id: id ?? this.id,
    at: at ?? this.at,
    profileId: profileId.present ? profileId.value : this.profileId,
    category: category ?? this.category,
    severity: severity ?? this.severity,
    count: count ?? this.count,
    detail: detail ?? this.detail,
    words: words ?? this.words,
    dedupeKey: dedupeKey ?? this.dedupeKey,
    readAt: readAt.present ? readAt.value : this.readAt,
    syncedAt: syncedAt.present ? syncedAt.value : this.syncedAt,
  );
  Alert copyWithCompanion(AlertsCompanion data) {
    return Alert(
      id: data.id.present ? data.id.value : this.id,
      at: data.at.present ? data.at.value : this.at,
      profileId: data.profileId.present ? data.profileId.value : this.profileId,
      category: data.category.present ? data.category.value : this.category,
      severity: data.severity.present ? data.severity.value : this.severity,
      count: data.count.present ? data.count.value : this.count,
      detail: data.detail.present ? data.detail.value : this.detail,
      words: data.words.present ? data.words.value : this.words,
      dedupeKey: data.dedupeKey.present ? data.dedupeKey.value : this.dedupeKey,
      readAt: data.readAt.present ? data.readAt.value : this.readAt,
      syncedAt: data.syncedAt.present ? data.syncedAt.value : this.syncedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Alert(')
          ..write('id: $id, ')
          ..write('at: $at, ')
          ..write('profileId: $profileId, ')
          ..write('category: $category, ')
          ..write('severity: $severity, ')
          ..write('count: $count, ')
          ..write('detail: $detail, ')
          ..write('words: $words, ')
          ..write('dedupeKey: $dedupeKey, ')
          ..write('readAt: $readAt, ')
          ..write('syncedAt: $syncedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, at, profileId, category, severity, count, detail, words, dedupeKey, readAt, syncedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Alert &&
          other.id == this.id &&
          other.at == this.at &&
          other.profileId == this.profileId &&
          other.category == this.category &&
          other.severity == this.severity &&
          other.count == this.count &&
          other.detail == this.detail &&
          other.words == this.words &&
          other.dedupeKey == this.dedupeKey &&
          other.readAt == this.readAt &&
          other.syncedAt == this.syncedAt);
}

class AlertsCompanion extends UpdateCompanion<Alert> {
  final Value<int> id;
  final Value<DateTime> at;
  final Value<String?> profileId;
  final Value<String> category;
  final Value<String> severity;
  final Value<int> count;
  final Value<String> detail;
  final Value<String> words;
  final Value<String> dedupeKey;
  final Value<DateTime?> readAt;
  final Value<DateTime?> syncedAt;
  const AlertsCompanion({
    this.id = const Value.absent(),
    this.at = const Value.absent(),
    this.profileId = const Value.absent(),
    this.category = const Value.absent(),
    this.severity = const Value.absent(),
    this.count = const Value.absent(),
    this.detail = const Value.absent(),
    this.words = const Value.absent(),
    this.dedupeKey = const Value.absent(),
    this.readAt = const Value.absent(),
    this.syncedAt = const Value.absent(),
  });
  AlertsCompanion.insert({
    this.id = const Value.absent(),
    required DateTime at,
    this.profileId = const Value.absent(),
    required String category,
    required String severity,
    this.count = const Value.absent(),
    this.detail = const Value.absent(),
    this.words = const Value.absent(),
    required String dedupeKey,
    this.readAt = const Value.absent(),
    this.syncedAt = const Value.absent(),
  }) : at = Value(at),
       category = Value(category),
       severity = Value(severity),
       dedupeKey = Value(dedupeKey);
  static Insertable<Alert> custom({
    Expression<int>? id,
    Expression<DateTime>? at,
    Expression<String>? profileId,
    Expression<String>? category,
    Expression<String>? severity,
    Expression<int>? count,
    Expression<String>? detail,
    Expression<String>? words,
    Expression<String>? dedupeKey,
    Expression<DateTime>? readAt,
    Expression<DateTime>? syncedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (at != null) 'at': at,
      if (profileId != null) 'profile_id': profileId,
      if (category != null) 'category': category,
      if (severity != null) 'severity': severity,
      if (count != null) 'count': count,
      if (detail != null) 'detail': detail,
      if (words != null) 'words': words,
      if (dedupeKey != null) 'dedupe_key': dedupeKey,
      if (readAt != null) 'read_at': readAt,
      if (syncedAt != null) 'synced_at': syncedAt,
    });
  }

  AlertsCompanion copyWith({
    Value<int>? id,
    Value<DateTime>? at,
    Value<String?>? profileId,
    Value<String>? category,
    Value<String>? severity,
    Value<int>? count,
    Value<String>? detail,
    Value<String>? words,
    Value<String>? dedupeKey,
    Value<DateTime?>? readAt,
    Value<DateTime?>? syncedAt,
  }) {
    return AlertsCompanion(
      id: id ?? this.id,
      at: at ?? this.at,
      profileId: profileId ?? this.profileId,
      category: category ?? this.category,
      severity: severity ?? this.severity,
      count: count ?? this.count,
      detail: detail ?? this.detail,
      words: words ?? this.words,
      dedupeKey: dedupeKey ?? this.dedupeKey,
      readAt: readAt ?? this.readAt,
      syncedAt: syncedAt ?? this.syncedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (at.present) {
      map['at'] = Variable<DateTime>(at.value);
    }
    if (profileId.present) {
      map['profile_id'] = Variable<String>(profileId.value);
    }
    if (category.present) {
      map['category'] = Variable<String>(category.value);
    }
    if (severity.present) {
      map['severity'] = Variable<String>(severity.value);
    }
    if (count.present) {
      map['count'] = Variable<int>(count.value);
    }
    if (detail.present) {
      map['detail'] = Variable<String>(detail.value);
    }
    if (words.present) {
      map['words'] = Variable<String>(words.value);
    }
    if (dedupeKey.present) {
      map['dedupe_key'] = Variable<String>(dedupeKey.value);
    }
    if (readAt.present) {
      map['read_at'] = Variable<DateTime>(readAt.value);
    }
    if (syncedAt.present) {
      map['synced_at'] = Variable<DateTime>(syncedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AlertsCompanion(')
          ..write('id: $id, ')
          ..write('at: $at, ')
          ..write('profileId: $profileId, ')
          ..write('category: $category, ')
          ..write('severity: $severity, ')
          ..write('count: $count, ')
          ..write('detail: $detail, ')
          ..write('words: $words, ')
          ..write('dedupeKey: $dedupeKey, ')
          ..write('readAt: $readAt, ')
          ..write('syncedAt: $syncedAt')
          ..write(')'))
        .toString();
  }
}

class $RewardsTable extends Rewards with TableInfo<$RewardsTable, Reward> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RewardsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'),
  );
  static const VerificationMeta _profileIdMeta = const VerificationMeta('profileId');
  @override
  late final GeneratedColumn<String> profileId = GeneratedColumn<String>(
    'profile_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _awardKeyMeta = const VerificationMeta('awardKey');
  @override
  late final GeneratedColumn<String> awardKey = GeneratedColumn<String>(
    'award_key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _kindMeta = const VerificationMeta('kind');
  @override
  late final GeneratedColumn<String> kind = GeneratedColumn<String>(
    'kind',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _atMeta = const VerificationMeta('at');
  @override
  late final GeneratedColumn<DateTime> at = GeneratedColumn<DateTime>(
    'at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _seenAtMeta = const VerificationMeta('seenAt');
  @override
  late final GeneratedColumn<DateTime> seenAt = GeneratedColumn<DateTime>(
    'seen_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _eventIdMeta = const VerificationMeta('eventId');
  @override
  late final GeneratedColumn<String> eventId = GeneratedColumn<String>(
    'event_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _syncedAtMeta = const VerificationMeta('syncedAt');
  @override
  late final GeneratedColumn<DateTime> syncedAt = GeneratedColumn<DateTime>(
    'synced_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [id, profileId, awardKey, kind, at, seenAt, eventId, syncedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'rewards';
  @override
  VerificationContext validateIntegrity(Insertable<Reward> instance, {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('profile_id')) {
      context.handle(_profileIdMeta, profileId.isAcceptableOrUnknown(data['profile_id']!, _profileIdMeta));
    } else if (isInserting) {
      context.missing(_profileIdMeta);
    }
    if (data.containsKey('award_key')) {
      context.handle(_awardKeyMeta, awardKey.isAcceptableOrUnknown(data['award_key']!, _awardKeyMeta));
    } else if (isInserting) {
      context.missing(_awardKeyMeta);
    }
    if (data.containsKey('kind')) {
      context.handle(_kindMeta, kind.isAcceptableOrUnknown(data['kind']!, _kindMeta));
    } else if (isInserting) {
      context.missing(_kindMeta);
    }
    if (data.containsKey('at')) {
      context.handle(_atMeta, at.isAcceptableOrUnknown(data['at']!, _atMeta));
    } else if (isInserting) {
      context.missing(_atMeta);
    }
    if (data.containsKey('seen_at')) {
      context.handle(_seenAtMeta, seenAt.isAcceptableOrUnknown(data['seen_at']!, _seenAtMeta));
    }
    if (data.containsKey('event_id')) {
      context.handle(_eventIdMeta, eventId.isAcceptableOrUnknown(data['event_id']!, _eventIdMeta));
    }
    if (data.containsKey('synced_at')) {
      context.handle(_syncedAtMeta, syncedAt.isAcceptableOrUnknown(data['synced_at']!, _syncedAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {profileId, awardKey},
  ];
  @override
  Reward map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Reward(
      id: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      profileId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}profile_id'],
      )!,
      awardKey: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}award_key'])!,
      kind: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}kind'])!,
      at: attachedDatabase.typeMapping.read(DriftSqlType.dateTime, data['${effectivePrefix}at'])!,
      seenAt: attachedDatabase.typeMapping.read(DriftSqlType.dateTime, data['${effectivePrefix}seen_at']),
      eventId: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}event_id']),
      syncedAt: attachedDatabase.typeMapping.read(DriftSqlType.dateTime, data['${effectivePrefix}synced_at']),
    );
  }

  @override
  $RewardsTable createAlias(String alias) {
    return $RewardsTable(attachedDatabase, alias);
  }
}

class Reward extends DataClass implements Insertable<Reward> {
  final int id;
  final String profileId;

  /// The award's key, for example `trophy:counting:silver`; the same on every device.
  final String awardKey;

  /// An `AwardKind` name.
  final String kind;

  /// When it was earned (the answer or the lesson that made it so), not when this phone found out.
  final DateTime at;

  /// When the child was shown it (a sticker revealed, a ceremony played). Null while it waits to be shown; an award from
  /// another phone or from before this feature is marked seen at once.
  final DateTime? seenAt;

  /// Sync: when it was sent, or the id of the event it came from.
  final String? eventId;
  final DateTime? syncedAt;
  const Reward({
    required this.id,
    required this.profileId,
    required this.awardKey,
    required this.kind,
    required this.at,
    this.seenAt,
    this.eventId,
    this.syncedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['profile_id'] = Variable<String>(profileId);
    map['award_key'] = Variable<String>(awardKey);
    map['kind'] = Variable<String>(kind);
    map['at'] = Variable<DateTime>(at);
    if (!nullToAbsent || seenAt != null) {
      map['seen_at'] = Variable<DateTime>(seenAt);
    }
    if (!nullToAbsent || eventId != null) {
      map['event_id'] = Variable<String>(eventId);
    }
    if (!nullToAbsent || syncedAt != null) {
      map['synced_at'] = Variable<DateTime>(syncedAt);
    }
    return map;
  }

  RewardsCompanion toCompanion(bool nullToAbsent) {
    return RewardsCompanion(
      id: Value(id),
      profileId: Value(profileId),
      awardKey: Value(awardKey),
      kind: Value(kind),
      at: Value(at),
      seenAt: seenAt == null && nullToAbsent ? const Value.absent() : Value(seenAt),
      eventId: eventId == null && nullToAbsent ? const Value.absent() : Value(eventId),
      syncedAt: syncedAt == null && nullToAbsent ? const Value.absent() : Value(syncedAt),
    );
  }

  factory Reward.fromJson(Map<String, dynamic> json, {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Reward(
      id: serializer.fromJson<int>(json['id']),
      profileId: serializer.fromJson<String>(json['profileId']),
      awardKey: serializer.fromJson<String>(json['awardKey']),
      kind: serializer.fromJson<String>(json['kind']),
      at: serializer.fromJson<DateTime>(json['at']),
      seenAt: serializer.fromJson<DateTime?>(json['seenAt']),
      eventId: serializer.fromJson<String?>(json['eventId']),
      syncedAt: serializer.fromJson<DateTime?>(json['syncedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'profileId': serializer.toJson<String>(profileId),
      'awardKey': serializer.toJson<String>(awardKey),
      'kind': serializer.toJson<String>(kind),
      'at': serializer.toJson<DateTime>(at),
      'seenAt': serializer.toJson<DateTime?>(seenAt),
      'eventId': serializer.toJson<String?>(eventId),
      'syncedAt': serializer.toJson<DateTime?>(syncedAt),
    };
  }

  Reward copyWith({
    int? id,
    String? profileId,
    String? awardKey,
    String? kind,
    DateTime? at,
    Value<DateTime?> seenAt = const Value.absent(),
    Value<String?> eventId = const Value.absent(),
    Value<DateTime?> syncedAt = const Value.absent(),
  }) => Reward(
    id: id ?? this.id,
    profileId: profileId ?? this.profileId,
    awardKey: awardKey ?? this.awardKey,
    kind: kind ?? this.kind,
    at: at ?? this.at,
    seenAt: seenAt.present ? seenAt.value : this.seenAt,
    eventId: eventId.present ? eventId.value : this.eventId,
    syncedAt: syncedAt.present ? syncedAt.value : this.syncedAt,
  );
  Reward copyWithCompanion(RewardsCompanion data) {
    return Reward(
      id: data.id.present ? data.id.value : this.id,
      profileId: data.profileId.present ? data.profileId.value : this.profileId,
      awardKey: data.awardKey.present ? data.awardKey.value : this.awardKey,
      kind: data.kind.present ? data.kind.value : this.kind,
      at: data.at.present ? data.at.value : this.at,
      seenAt: data.seenAt.present ? data.seenAt.value : this.seenAt,
      eventId: data.eventId.present ? data.eventId.value : this.eventId,
      syncedAt: data.syncedAt.present ? data.syncedAt.value : this.syncedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Reward(')
          ..write('id: $id, ')
          ..write('profileId: $profileId, ')
          ..write('awardKey: $awardKey, ')
          ..write('kind: $kind, ')
          ..write('at: $at, ')
          ..write('seenAt: $seenAt, ')
          ..write('eventId: $eventId, ')
          ..write('syncedAt: $syncedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, profileId, awardKey, kind, at, seenAt, eventId, syncedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Reward &&
          other.id == this.id &&
          other.profileId == this.profileId &&
          other.awardKey == this.awardKey &&
          other.kind == this.kind &&
          other.at == this.at &&
          other.seenAt == this.seenAt &&
          other.eventId == this.eventId &&
          other.syncedAt == this.syncedAt);
}

class RewardsCompanion extends UpdateCompanion<Reward> {
  final Value<int> id;
  final Value<String> profileId;
  final Value<String> awardKey;
  final Value<String> kind;
  final Value<DateTime> at;
  final Value<DateTime?> seenAt;
  final Value<String?> eventId;
  final Value<DateTime?> syncedAt;
  const RewardsCompanion({
    this.id = const Value.absent(),
    this.profileId = const Value.absent(),
    this.awardKey = const Value.absent(),
    this.kind = const Value.absent(),
    this.at = const Value.absent(),
    this.seenAt = const Value.absent(),
    this.eventId = const Value.absent(),
    this.syncedAt = const Value.absent(),
  });
  RewardsCompanion.insert({
    this.id = const Value.absent(),
    required String profileId,
    required String awardKey,
    required String kind,
    required DateTime at,
    this.seenAt = const Value.absent(),
    this.eventId = const Value.absent(),
    this.syncedAt = const Value.absent(),
  }) : profileId = Value(profileId),
       awardKey = Value(awardKey),
       kind = Value(kind),
       at = Value(at);
  static Insertable<Reward> custom({
    Expression<int>? id,
    Expression<String>? profileId,
    Expression<String>? awardKey,
    Expression<String>? kind,
    Expression<DateTime>? at,
    Expression<DateTime>? seenAt,
    Expression<String>? eventId,
    Expression<DateTime>? syncedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (profileId != null) 'profile_id': profileId,
      if (awardKey != null) 'award_key': awardKey,
      if (kind != null) 'kind': kind,
      if (at != null) 'at': at,
      if (seenAt != null) 'seen_at': seenAt,
      if (eventId != null) 'event_id': eventId,
      if (syncedAt != null) 'synced_at': syncedAt,
    });
  }

  RewardsCompanion copyWith({
    Value<int>? id,
    Value<String>? profileId,
    Value<String>? awardKey,
    Value<String>? kind,
    Value<DateTime>? at,
    Value<DateTime?>? seenAt,
    Value<String?>? eventId,
    Value<DateTime?>? syncedAt,
  }) {
    return RewardsCompanion(
      id: id ?? this.id,
      profileId: profileId ?? this.profileId,
      awardKey: awardKey ?? this.awardKey,
      kind: kind ?? this.kind,
      at: at ?? this.at,
      seenAt: seenAt ?? this.seenAt,
      eventId: eventId ?? this.eventId,
      syncedAt: syncedAt ?? this.syncedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (profileId.present) {
      map['profile_id'] = Variable<String>(profileId.value);
    }
    if (awardKey.present) {
      map['award_key'] = Variable<String>(awardKey.value);
    }
    if (kind.present) {
      map['kind'] = Variable<String>(kind.value);
    }
    if (at.present) {
      map['at'] = Variable<DateTime>(at.value);
    }
    if (seenAt.present) {
      map['seen_at'] = Variable<DateTime>(seenAt.value);
    }
    if (eventId.present) {
      map['event_id'] = Variable<String>(eventId.value);
    }
    if (syncedAt.present) {
      map['synced_at'] = Variable<DateTime>(syncedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RewardsCompanion(')
          ..write('id: $id, ')
          ..write('profileId: $profileId, ')
          ..write('awardKey: $awardKey, ')
          ..write('kind: $kind, ')
          ..write('at: $at, ')
          ..write('seenAt: $seenAt, ')
          ..write('eventId: $eventId, ')
          ..write('syncedAt: $syncedAt')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $ProfilesTable profiles = $ProfilesTable(this);
  late final $AppSettingsTable appSettings = $AppSettingsTable(this);
  late final $LocalEventsTable localEvents = $LocalEventsTable(this);
  late final $InstalledPacksTable installedPacks = $InstalledPacksTable(this);
  late final $AttemptsTable attempts = $AttemptsTable(this);
  late final $SessionsTable sessions = $SessionsTable(this);
  late final $VoiceListensTable voiceListens = $VoiceListensTable(this);
  late final $AlertsTable alerts = $AlertsTable(this);
  late final $RewardsTable rewards = $RewardsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    profiles,
    appSettings,
    localEvents,
    installedPacks,
    attempts,
    sessions,
    voiceListens,
    alerts,
    rewards,
  ];
}

typedef $$ProfilesTableCreateCompanionBuilder = ProfilesCompanion Function({
  required String id,
  required String name,
  required String avatar,
  required String addressForm,
  required int ageBand,
  required DateTime createdAt,
  Value<String?> companionId,
  Value<int> rowid,
});
typedef $$ProfilesTableUpdateCompanionBuilder = ProfilesCompanion Function({
  Value<String> id,
  Value<String> name,
  Value<String> avatar,
  Value<String> addressForm,
  Value<int> ageBand,
  Value<DateTime> createdAt,
  Value<String?> companionId,
  Value<int> rowid,
});

class $$ProfilesTableFilterComposer extends Composer<_$AppDatabase, $ProfilesTable> {
  $$ProfilesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get avatar =>
      $composableBuilder(column: $table.avatar, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get addressForm =>
      $composableBuilder(column: $table.addressForm, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get ageBand =>
      $composableBuilder(column: $table.ageBand, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get companionId =>
      $composableBuilder(column: $table.companionId, builder: (column) => ColumnFilters(column));
}

class $$ProfilesTableOrderingComposer extends Composer<_$AppDatabase, $ProfilesTable> {
  $$ProfilesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get avatar =>
      $composableBuilder(column: $table.avatar, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get addressForm =>
      $composableBuilder(column: $table.addressForm, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get ageBand =>
      $composableBuilder(column: $table.ageBand, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get companionId =>
      $composableBuilder(column: $table.companionId, builder: (column) => ColumnOrderings(column));
}

class $$ProfilesTableAnnotationComposer extends Composer<_$AppDatabase, $ProfilesTable> {
  $$ProfilesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id => $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name => $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get avatar =>
      $composableBuilder(column: $table.avatar, builder: (column) => column);

  GeneratedColumn<String> get addressForm =>
      $composableBuilder(column: $table.addressForm, builder: (column) => column);

  GeneratedColumn<int> get ageBand => $composableBuilder(column: $table.ageBand, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<String> get companionId =>
      $composableBuilder(column: $table.companionId, builder: (column) => column);
}

class $$ProfilesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ProfilesTable,
          Profile,
          $$ProfilesTableFilterComposer,
          $$ProfilesTableOrderingComposer,
          $$ProfilesTableAnnotationComposer,
          $$ProfilesTableCreateCompanionBuilder,
          $$ProfilesTableUpdateCompanionBuilder,
          (Profile, BaseReferences<_$AppDatabase, $ProfilesTable, Profile>),
          Profile,
          PrefetchHooks Function()
        > {
  $$ProfilesTableTableManager(_$AppDatabase db, $ProfilesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () => $$ProfilesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () => $$ProfilesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () => $$ProfilesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> avatar = const Value.absent(),
                Value<String> addressForm = const Value.absent(),
                Value<int> ageBand = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<String?> companionId = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ProfilesCompanion(
                id: id,
                name: name,
                avatar: avatar,
                addressForm: addressForm,
                ageBand: ageBand,
                createdAt: createdAt,
                companionId: companionId,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                required String avatar,
                required String addressForm,
                required int ageBand,
                required DateTime createdAt,
                Value<String?> companionId = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ProfilesCompanion.insert(
                id: id,
                name: name,
                avatar: avatar,
                addressForm: addressForm,
                ageBand: ageBand,
                createdAt: createdAt,
                companionId: companionId,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ProfilesTable, Profile>(table),
                  BaseReferences<_$AppDatabase, $ProfilesTable, Profile>(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ProfilesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ProfilesTable,
      Profile,
      $$ProfilesTableFilterComposer,
      $$ProfilesTableOrderingComposer,
      $$ProfilesTableAnnotationComposer,
      $$ProfilesTableCreateCompanionBuilder,
      $$ProfilesTableUpdateCompanionBuilder,
      (Profile, BaseReferences<_$AppDatabase, $ProfilesTable, Profile>),
      Profile,
      PrefetchHooks Function()
    >;
typedef $$AppSettingsTableCreateCompanionBuilder = AppSettingsCompanion Function({
  required String key,
  required String value,
  Value<int> rowid,
});
typedef $$AppSettingsTableUpdateCompanionBuilder = AppSettingsCompanion Function({
  Value<String> key,
  Value<String> value,
  Value<int> rowid,
});

class $$AppSettingsTableFilterComposer extends Composer<_$AppDatabase, $AppSettingsTable> {
  $$AppSettingsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get value =>
      $composableBuilder(column: $table.value, builder: (column) => ColumnFilters(column));
}

class $$AppSettingsTableOrderingComposer extends Composer<_$AppDatabase, $AppSettingsTable> {
  $$AppSettingsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get value =>
      $composableBuilder(column: $table.value, builder: (column) => ColumnOrderings(column));
}

class $$AppSettingsTableAnnotationComposer extends Composer<_$AppDatabase, $AppSettingsTable> {
  $$AppSettingsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get key => $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<String> get value => $composableBuilder(column: $table.value, builder: (column) => column);
}

class $$AppSettingsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AppSettingsTable,
          AppSetting,
          $$AppSettingsTableFilterComposer,
          $$AppSettingsTableOrderingComposer,
          $$AppSettingsTableAnnotationComposer,
          $$AppSettingsTableCreateCompanionBuilder,
          $$AppSettingsTableUpdateCompanionBuilder,
          (AppSetting, BaseReferences<_$AppDatabase, $AppSettingsTable, AppSetting>),
          AppSetting,
          PrefetchHooks Function()
        > {
  $$AppSettingsTableTableManager(_$AppDatabase db, $AppSettingsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () => $$AppSettingsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () => $$AppSettingsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () => $$AppSettingsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> key = const Value.absent(),
            Value<String> value = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) => AppSettingsCompanion(key: key, value: value, rowid: rowid),
          createCompanionCallback: ({
            required String key,
            required String value,
            Value<int> rowid = const Value.absent(),
          }) => AppSettingsCompanion.insert(key: key, value: value, rowid: rowid),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$AppSettingsTable, AppSetting>(table),
                  BaseReferences<_$AppDatabase, $AppSettingsTable, AppSetting>(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$AppSettingsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AppSettingsTable,
      AppSetting,
      $$AppSettingsTableFilterComposer,
      $$AppSettingsTableOrderingComposer,
      $$AppSettingsTableAnnotationComposer,
      $$AppSettingsTableCreateCompanionBuilder,
      $$AppSettingsTableUpdateCompanionBuilder,
      (AppSetting, BaseReferences<_$AppDatabase, $AppSettingsTable, AppSetting>),
      AppSetting,
      PrefetchHooks Function()
    >;
typedef $$LocalEventsTableCreateCompanionBuilder = LocalEventsCompanion Function({
  Value<int> id,
  required DateTime at,
  required String kind,
  Value<String> detail,
});
typedef $$LocalEventsTableUpdateCompanionBuilder = LocalEventsCompanion Function({
  Value<int> id,
  Value<DateTime> at,
  Value<String> kind,
  Value<String> detail,
});

class $$LocalEventsTableFilterComposer extends Composer<_$AppDatabase, $LocalEventsTable> {
  $$LocalEventsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get at =>
      $composableBuilder(column: $table.at, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get detail =>
      $composableBuilder(column: $table.detail, builder: (column) => ColumnFilters(column));
}

class $$LocalEventsTableOrderingComposer extends Composer<_$AppDatabase, $LocalEventsTable> {
  $$LocalEventsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get at =>
      $composableBuilder(column: $table.at, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get detail =>
      $composableBuilder(column: $table.detail, builder: (column) => ColumnOrderings(column));
}

class $$LocalEventsTableAnnotationComposer extends Composer<_$AppDatabase, $LocalEventsTable> {
  $$LocalEventsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id => $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get at => $composableBuilder(column: $table.at, builder: (column) => column);

  GeneratedColumn<String> get kind => $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<String> get detail =>
      $composableBuilder(column: $table.detail, builder: (column) => column);
}

class $$LocalEventsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LocalEventsTable,
          LocalEvent,
          $$LocalEventsTableFilterComposer,
          $$LocalEventsTableOrderingComposer,
          $$LocalEventsTableAnnotationComposer,
          $$LocalEventsTableCreateCompanionBuilder,
          $$LocalEventsTableUpdateCompanionBuilder,
          (LocalEvent, BaseReferences<_$AppDatabase, $LocalEventsTable, LocalEvent>),
          LocalEvent,
          PrefetchHooks Function()
        > {
  $$LocalEventsTableTableManager(_$AppDatabase db, $LocalEventsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () => $$LocalEventsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () => $$LocalEventsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () => $$LocalEventsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<DateTime> at = const Value.absent(),
            Value<String> kind = const Value.absent(),
            Value<String> detail = const Value.absent(),
          }) => LocalEventsCompanion(id: id, at: at, kind: kind, detail: detail),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required DateTime at,
            required String kind,
            Value<String> detail = const Value.absent(),
          }) => LocalEventsCompanion.insert(id: id, at: at, kind: kind, detail: detail),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$LocalEventsTable, LocalEvent>(table),
                  BaseReferences<_$AppDatabase, $LocalEventsTable, LocalEvent>(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$LocalEventsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LocalEventsTable,
      LocalEvent,
      $$LocalEventsTableFilterComposer,
      $$LocalEventsTableOrderingComposer,
      $$LocalEventsTableAnnotationComposer,
      $$LocalEventsTableCreateCompanionBuilder,
      $$LocalEventsTableUpdateCompanionBuilder,
      (LocalEvent, BaseReferences<_$AppDatabase, $LocalEventsTable, LocalEvent>),
      LocalEvent,
      PrefetchHooks Function()
    >;
typedef $$InstalledPacksTableCreateCompanionBuilder = InstalledPacksCompanion Function({
  required String id,
  required String version,
  required String manifestSha256,
  required DateTime installedAt,
  Value<bool> hidden,
  Value<String> hiddenReason,
  Value<int> rowid,
});
typedef $$InstalledPacksTableUpdateCompanionBuilder = InstalledPacksCompanion Function({
  Value<String> id,
  Value<String> version,
  Value<String> manifestSha256,
  Value<DateTime> installedAt,
  Value<bool> hidden,
  Value<String> hiddenReason,
  Value<int> rowid,
});

class $$InstalledPacksTableFilterComposer extends Composer<_$AppDatabase, $InstalledPacksTable> {
  $$InstalledPacksTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get version =>
      $composableBuilder(column: $table.version, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get manifestSha256 =>
      $composableBuilder(column: $table.manifestSha256, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get installedAt =>
      $composableBuilder(column: $table.installedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get hidden =>
      $composableBuilder(column: $table.hidden, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get hiddenReason =>
      $composableBuilder(column: $table.hiddenReason, builder: (column) => ColumnFilters(column));
}

class $$InstalledPacksTableOrderingComposer extends Composer<_$AppDatabase, $InstalledPacksTable> {
  $$InstalledPacksTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get version =>
      $composableBuilder(column: $table.version, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get manifestSha256 =>
      $composableBuilder(column: $table.manifestSha256, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get installedAt =>
      $composableBuilder(column: $table.installedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get hidden =>
      $composableBuilder(column: $table.hidden, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get hiddenReason =>
      $composableBuilder(column: $table.hiddenReason, builder: (column) => ColumnOrderings(column));
}

class $$InstalledPacksTableAnnotationComposer extends Composer<_$AppDatabase, $InstalledPacksTable> {
  $$InstalledPacksTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id => $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get version =>
      $composableBuilder(column: $table.version, builder: (column) => column);

  GeneratedColumn<String> get manifestSha256 =>
      $composableBuilder(column: $table.manifestSha256, builder: (column) => column);

  GeneratedColumn<DateTime> get installedAt =>
      $composableBuilder(column: $table.installedAt, builder: (column) => column);

  GeneratedColumn<bool> get hidden => $composableBuilder(column: $table.hidden, builder: (column) => column);

  GeneratedColumn<String> get hiddenReason =>
      $composableBuilder(column: $table.hiddenReason, builder: (column) => column);
}

class $$InstalledPacksTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $InstalledPacksTable,
          InstalledPack,
          $$InstalledPacksTableFilterComposer,
          $$InstalledPacksTableOrderingComposer,
          $$InstalledPacksTableAnnotationComposer,
          $$InstalledPacksTableCreateCompanionBuilder,
          $$InstalledPacksTableUpdateCompanionBuilder,
          (InstalledPack, BaseReferences<_$AppDatabase, $InstalledPacksTable, InstalledPack>),
          InstalledPack,
          PrefetchHooks Function()
        > {
  $$InstalledPacksTableTableManager(_$AppDatabase db, $InstalledPacksTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () => $$InstalledPacksTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () => $$InstalledPacksTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () => $$InstalledPacksTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> version = const Value.absent(),
                Value<String> manifestSha256 = const Value.absent(),
                Value<DateTime> installedAt = const Value.absent(),
                Value<bool> hidden = const Value.absent(),
                Value<String> hiddenReason = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => InstalledPacksCompanion(
                id: id,
                version: version,
                manifestSha256: manifestSha256,
                installedAt: installedAt,
                hidden: hidden,
                hiddenReason: hiddenReason,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String version,
                required String manifestSha256,
                required DateTime installedAt,
                Value<bool> hidden = const Value.absent(),
                Value<String> hiddenReason = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => InstalledPacksCompanion.insert(
                id: id,
                version: version,
                manifestSha256: manifestSha256,
                installedAt: installedAt,
                hidden: hidden,
                hiddenReason: hiddenReason,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$InstalledPacksTable, InstalledPack>(table),
                  BaseReferences<_$AppDatabase, $InstalledPacksTable, InstalledPack>(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$InstalledPacksTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $InstalledPacksTable,
      InstalledPack,
      $$InstalledPacksTableFilterComposer,
      $$InstalledPacksTableOrderingComposer,
      $$InstalledPacksTableAnnotationComposer,
      $$InstalledPacksTableCreateCompanionBuilder,
      $$InstalledPacksTableUpdateCompanionBuilder,
      (InstalledPack, BaseReferences<_$AppDatabase, $InstalledPacksTable, InstalledPack>),
      InstalledPack,
      PrefetchHooks Function()
    >;
typedef $$AttemptsTableCreateCompanionBuilder = AttemptsCompanion Function({
  Value<int> id,
  required DateTime at,
  required String profileId,
  required String packId,
  required String packVersion,
  Value<String> lessonId,
  required String activityId,
  required int activityRevision,
  required String template,
  required String templateVersion,
  required String skillId,
  required String result,
  required int attemptNo,
  required int hintLevel,
  Value<String> misconceptionTag,
  Value<String> response,
  Value<int> durationMs,
  Value<int?> sessionId,
  Value<String> input,
  Value<String?> eventId,
  Value<DateTime?> syncedAt,
  Value<String?> remoteSession,
});
typedef $$AttemptsTableUpdateCompanionBuilder = AttemptsCompanion Function({
  Value<int> id,
  Value<DateTime> at,
  Value<String> profileId,
  Value<String> packId,
  Value<String> packVersion,
  Value<String> lessonId,
  Value<String> activityId,
  Value<int> activityRevision,
  Value<String> template,
  Value<String> templateVersion,
  Value<String> skillId,
  Value<String> result,
  Value<int> attemptNo,
  Value<int> hintLevel,
  Value<String> misconceptionTag,
  Value<String> response,
  Value<int> durationMs,
  Value<int?> sessionId,
  Value<String> input,
  Value<String?> eventId,
  Value<DateTime?> syncedAt,
  Value<String?> remoteSession,
});

class $$AttemptsTableFilterComposer extends Composer<_$AppDatabase, $AttemptsTable> {
  $$AttemptsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get at =>
      $composableBuilder(column: $table.at, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get profileId =>
      $composableBuilder(column: $table.profileId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get packId =>
      $composableBuilder(column: $table.packId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get packVersion =>
      $composableBuilder(column: $table.packVersion, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get lessonId =>
      $composableBuilder(column: $table.lessonId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get activityId =>
      $composableBuilder(column: $table.activityId, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get activityRevision =>
      $composableBuilder(column: $table.activityRevision, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get template =>
      $composableBuilder(column: $table.template, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get templateVersion =>
      $composableBuilder(column: $table.templateVersion, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get skillId =>
      $composableBuilder(column: $table.skillId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get result =>
      $composableBuilder(column: $table.result, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get attemptNo =>
      $composableBuilder(column: $table.attemptNo, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get hintLevel =>
      $composableBuilder(column: $table.hintLevel, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get misconceptionTag =>
      $composableBuilder(column: $table.misconceptionTag, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get response =>
      $composableBuilder(column: $table.response, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get durationMs =>
      $composableBuilder(column: $table.durationMs, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get sessionId =>
      $composableBuilder(column: $table.sessionId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get input =>
      $composableBuilder(column: $table.input, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get eventId =>
      $composableBuilder(column: $table.eventId, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get syncedAt =>
      $composableBuilder(column: $table.syncedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get remoteSession =>
      $composableBuilder(column: $table.remoteSession, builder: (column) => ColumnFilters(column));
}

class $$AttemptsTableOrderingComposer extends Composer<_$AppDatabase, $AttemptsTable> {
  $$AttemptsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get at =>
      $composableBuilder(column: $table.at, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get profileId =>
      $composableBuilder(column: $table.profileId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get packId =>
      $composableBuilder(column: $table.packId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get packVersion =>
      $composableBuilder(column: $table.packVersion, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get lessonId =>
      $composableBuilder(column: $table.lessonId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get activityId =>
      $composableBuilder(column: $table.activityId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get activityRevision =>
      $composableBuilder(column: $table.activityRevision, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get template =>
      $composableBuilder(column: $table.template, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get templateVersion =>
      $composableBuilder(column: $table.templateVersion, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get skillId =>
      $composableBuilder(column: $table.skillId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get result =>
      $composableBuilder(column: $table.result, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get attemptNo =>
      $composableBuilder(column: $table.attemptNo, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get hintLevel =>
      $composableBuilder(column: $table.hintLevel, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get misconceptionTag =>
      $composableBuilder(column: $table.misconceptionTag, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get response =>
      $composableBuilder(column: $table.response, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get durationMs =>
      $composableBuilder(column: $table.durationMs, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get sessionId =>
      $composableBuilder(column: $table.sessionId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get input =>
      $composableBuilder(column: $table.input, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get eventId =>
      $composableBuilder(column: $table.eventId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get syncedAt =>
      $composableBuilder(column: $table.syncedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get remoteSession =>
      $composableBuilder(column: $table.remoteSession, builder: (column) => ColumnOrderings(column));
}

class $$AttemptsTableAnnotationComposer extends Composer<_$AppDatabase, $AttemptsTable> {
  $$AttemptsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id => $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get at => $composableBuilder(column: $table.at, builder: (column) => column);

  GeneratedColumn<String> get profileId =>
      $composableBuilder(column: $table.profileId, builder: (column) => column);

  GeneratedColumn<String> get packId =>
      $composableBuilder(column: $table.packId, builder: (column) => column);

  GeneratedColumn<String> get packVersion =>
      $composableBuilder(column: $table.packVersion, builder: (column) => column);

  GeneratedColumn<String> get lessonId =>
      $composableBuilder(column: $table.lessonId, builder: (column) => column);

  GeneratedColumn<String> get activityId =>
      $composableBuilder(column: $table.activityId, builder: (column) => column);

  GeneratedColumn<int> get activityRevision =>
      $composableBuilder(column: $table.activityRevision, builder: (column) => column);

  GeneratedColumn<String> get template =>
      $composableBuilder(column: $table.template, builder: (column) => column);

  GeneratedColumn<String> get templateVersion =>
      $composableBuilder(column: $table.templateVersion, builder: (column) => column);

  GeneratedColumn<String> get skillId =>
      $composableBuilder(column: $table.skillId, builder: (column) => column);

  GeneratedColumn<String> get result =>
      $composableBuilder(column: $table.result, builder: (column) => column);

  GeneratedColumn<int> get attemptNo =>
      $composableBuilder(column: $table.attemptNo, builder: (column) => column);

  GeneratedColumn<int> get hintLevel =>
      $composableBuilder(column: $table.hintLevel, builder: (column) => column);

  GeneratedColumn<String> get misconceptionTag =>
      $composableBuilder(column: $table.misconceptionTag, builder: (column) => column);

  GeneratedColumn<String> get response =>
      $composableBuilder(column: $table.response, builder: (column) => column);

  GeneratedColumn<int> get durationMs =>
      $composableBuilder(column: $table.durationMs, builder: (column) => column);

  GeneratedColumn<int> get sessionId =>
      $composableBuilder(column: $table.sessionId, builder: (column) => column);

  GeneratedColumn<String> get input => $composableBuilder(column: $table.input, builder: (column) => column);

  GeneratedColumn<String> get eventId =>
      $composableBuilder(column: $table.eventId, builder: (column) => column);

  GeneratedColumn<DateTime> get syncedAt =>
      $composableBuilder(column: $table.syncedAt, builder: (column) => column);

  GeneratedColumn<String> get remoteSession =>
      $composableBuilder(column: $table.remoteSession, builder: (column) => column);
}

class $$AttemptsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AttemptsTable,
          Attempt,
          $$AttemptsTableFilterComposer,
          $$AttemptsTableOrderingComposer,
          $$AttemptsTableAnnotationComposer,
          $$AttemptsTableCreateCompanionBuilder,
          $$AttemptsTableUpdateCompanionBuilder,
          (Attempt, BaseReferences<_$AppDatabase, $AttemptsTable, Attempt>),
          Attempt,
          PrefetchHooks Function()
        > {
  $$AttemptsTableTableManager(_$AppDatabase db, $AttemptsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () => $$AttemptsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () => $$AttemptsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () => $$AttemptsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<DateTime> at = const Value.absent(),
                Value<String> profileId = const Value.absent(),
                Value<String> packId = const Value.absent(),
                Value<String> packVersion = const Value.absent(),
                Value<String> lessonId = const Value.absent(),
                Value<String> activityId = const Value.absent(),
                Value<int> activityRevision = const Value.absent(),
                Value<String> template = const Value.absent(),
                Value<String> templateVersion = const Value.absent(),
                Value<String> skillId = const Value.absent(),
                Value<String> result = const Value.absent(),
                Value<int> attemptNo = const Value.absent(),
                Value<int> hintLevel = const Value.absent(),
                Value<String> misconceptionTag = const Value.absent(),
                Value<String> response = const Value.absent(),
                Value<int> durationMs = const Value.absent(),
                Value<int?> sessionId = const Value.absent(),
                Value<String> input = const Value.absent(),
                Value<String?> eventId = const Value.absent(),
                Value<DateTime?> syncedAt = const Value.absent(),
                Value<String?> remoteSession = const Value.absent(),
              }) => AttemptsCompanion(
                id: id,
                at: at,
                profileId: profileId,
                packId: packId,
                packVersion: packVersion,
                lessonId: lessonId,
                activityId: activityId,
                activityRevision: activityRevision,
                template: template,
                templateVersion: templateVersion,
                skillId: skillId,
                result: result,
                attemptNo: attemptNo,
                hintLevel: hintLevel,
                misconceptionTag: misconceptionTag,
                response: response,
                durationMs: durationMs,
                sessionId: sessionId,
                input: input,
                eventId: eventId,
                syncedAt: syncedAt,
                remoteSession: remoteSession,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required DateTime at,
                required String profileId,
                required String packId,
                required String packVersion,
                Value<String> lessonId = const Value.absent(),
                required String activityId,
                required int activityRevision,
                required String template,
                required String templateVersion,
                required String skillId,
                required String result,
                required int attemptNo,
                required int hintLevel,
                Value<String> misconceptionTag = const Value.absent(),
                Value<String> response = const Value.absent(),
                Value<int> durationMs = const Value.absent(),
                Value<int?> sessionId = const Value.absent(),
                Value<String> input = const Value.absent(),
                Value<String?> eventId = const Value.absent(),
                Value<DateTime?> syncedAt = const Value.absent(),
                Value<String?> remoteSession = const Value.absent(),
              }) => AttemptsCompanion.insert(
                id: id,
                at: at,
                profileId: profileId,
                packId: packId,
                packVersion: packVersion,
                lessonId: lessonId,
                activityId: activityId,
                activityRevision: activityRevision,
                template: template,
                templateVersion: templateVersion,
                skillId: skillId,
                result: result,
                attemptNo: attemptNo,
                hintLevel: hintLevel,
                misconceptionTag: misconceptionTag,
                response: response,
                durationMs: durationMs,
                sessionId: sessionId,
                input: input,
                eventId: eventId,
                syncedAt: syncedAt,
                remoteSession: remoteSession,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$AttemptsTable, Attempt>(table),
                  BaseReferences<_$AppDatabase, $AttemptsTable, Attempt>(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$AttemptsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AttemptsTable,
      Attempt,
      $$AttemptsTableFilterComposer,
      $$AttemptsTableOrderingComposer,
      $$AttemptsTableAnnotationComposer,
      $$AttemptsTableCreateCompanionBuilder,
      $$AttemptsTableUpdateCompanionBuilder,
      (Attempt, BaseReferences<_$AppDatabase, $AttemptsTable, Attempt>),
      Attempt,
      PrefetchHooks Function()
    >;
typedef $$SessionsTableCreateCompanionBuilder = SessionsCompanion Function({
  Value<int> id,
  required String profileId,
  required DateTime startedAt,
  Value<DateTime?> endedAt,
  Value<String> plan,
  Value<String> endReason,
  Value<String?> eventId,
  Value<DateTime?> syncedAt,
  Value<String?> remoteKey,
});
typedef $$SessionsTableUpdateCompanionBuilder = SessionsCompanion Function({
  Value<int> id,
  Value<String> profileId,
  Value<DateTime> startedAt,
  Value<DateTime?> endedAt,
  Value<String> plan,
  Value<String> endReason,
  Value<String?> eventId,
  Value<DateTime?> syncedAt,
  Value<String?> remoteKey,
});

class $$SessionsTableFilterComposer extends Composer<_$AppDatabase, $SessionsTable> {
  $$SessionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get profileId =>
      $composableBuilder(column: $table.profileId, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get startedAt =>
      $composableBuilder(column: $table.startedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get endedAt =>
      $composableBuilder(column: $table.endedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get plan =>
      $composableBuilder(column: $table.plan, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get endReason =>
      $composableBuilder(column: $table.endReason, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get eventId =>
      $composableBuilder(column: $table.eventId, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get syncedAt =>
      $composableBuilder(column: $table.syncedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get remoteKey =>
      $composableBuilder(column: $table.remoteKey, builder: (column) => ColumnFilters(column));
}

class $$SessionsTableOrderingComposer extends Composer<_$AppDatabase, $SessionsTable> {
  $$SessionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get profileId =>
      $composableBuilder(column: $table.profileId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get startedAt =>
      $composableBuilder(column: $table.startedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get endedAt =>
      $composableBuilder(column: $table.endedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get plan =>
      $composableBuilder(column: $table.plan, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get endReason =>
      $composableBuilder(column: $table.endReason, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get eventId =>
      $composableBuilder(column: $table.eventId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get syncedAt =>
      $composableBuilder(column: $table.syncedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get remoteKey =>
      $composableBuilder(column: $table.remoteKey, builder: (column) => ColumnOrderings(column));
}

class $$SessionsTableAnnotationComposer extends Composer<_$AppDatabase, $SessionsTable> {
  $$SessionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id => $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get profileId =>
      $composableBuilder(column: $table.profileId, builder: (column) => column);

  GeneratedColumn<DateTime> get startedAt =>
      $composableBuilder(column: $table.startedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get endedAt =>
      $composableBuilder(column: $table.endedAt, builder: (column) => column);

  GeneratedColumn<String> get plan => $composableBuilder(column: $table.plan, builder: (column) => column);

  GeneratedColumn<String> get endReason =>
      $composableBuilder(column: $table.endReason, builder: (column) => column);

  GeneratedColumn<String> get eventId =>
      $composableBuilder(column: $table.eventId, builder: (column) => column);

  GeneratedColumn<DateTime> get syncedAt =>
      $composableBuilder(column: $table.syncedAt, builder: (column) => column);

  GeneratedColumn<String> get remoteKey =>
      $composableBuilder(column: $table.remoteKey, builder: (column) => column);
}

class $$SessionsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SessionsTable,
          Session,
          $$SessionsTableFilterComposer,
          $$SessionsTableOrderingComposer,
          $$SessionsTableAnnotationComposer,
          $$SessionsTableCreateCompanionBuilder,
          $$SessionsTableUpdateCompanionBuilder,
          (Session, BaseReferences<_$AppDatabase, $SessionsTable, Session>),
          Session,
          PrefetchHooks Function()
        > {
  $$SessionsTableTableManager(_$AppDatabase db, $SessionsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () => $$SessionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () => $$SessionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () => $$SessionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> profileId = const Value.absent(),
                Value<DateTime> startedAt = const Value.absent(),
                Value<DateTime?> endedAt = const Value.absent(),
                Value<String> plan = const Value.absent(),
                Value<String> endReason = const Value.absent(),
                Value<String?> eventId = const Value.absent(),
                Value<DateTime?> syncedAt = const Value.absent(),
                Value<String?> remoteKey = const Value.absent(),
              }) => SessionsCompanion(
                id: id,
                profileId: profileId,
                startedAt: startedAt,
                endedAt: endedAt,
                plan: plan,
                endReason: endReason,
                eventId: eventId,
                syncedAt: syncedAt,
                remoteKey: remoteKey,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String profileId,
                required DateTime startedAt,
                Value<DateTime?> endedAt = const Value.absent(),
                Value<String> plan = const Value.absent(),
                Value<String> endReason = const Value.absent(),
                Value<String?> eventId = const Value.absent(),
                Value<DateTime?> syncedAt = const Value.absent(),
                Value<String?> remoteKey = const Value.absent(),
              }) => SessionsCompanion.insert(
                id: id,
                profileId: profileId,
                startedAt: startedAt,
                endedAt: endedAt,
                plan: plan,
                endReason: endReason,
                eventId: eventId,
                syncedAt: syncedAt,
                remoteKey: remoteKey,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$SessionsTable, Session>(table),
                  BaseReferences<_$AppDatabase, $SessionsTable, Session>(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SessionsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SessionsTable,
      Session,
      $$SessionsTableFilterComposer,
      $$SessionsTableOrderingComposer,
      $$SessionsTableAnnotationComposer,
      $$SessionsTableCreateCompanionBuilder,
      $$SessionsTableUpdateCompanionBuilder,
      (Session, BaseReferences<_$AppDatabase, $SessionsTable, Session>),
      Session,
      PrefetchHooks Function()
    >;
typedef $$VoiceListensTableCreateCompanionBuilder = VoiceListensCompanion Function({
  Value<int> id,
  required DateTime at,
  required String profileId,
  required String answerType,
  required String outcome,
});
typedef $$VoiceListensTableUpdateCompanionBuilder = VoiceListensCompanion Function({
  Value<int> id,
  Value<DateTime> at,
  Value<String> profileId,
  Value<String> answerType,
  Value<String> outcome,
});

class $$VoiceListensTableFilterComposer extends Composer<_$AppDatabase, $VoiceListensTable> {
  $$VoiceListensTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get at =>
      $composableBuilder(column: $table.at, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get profileId =>
      $composableBuilder(column: $table.profileId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get answerType =>
      $composableBuilder(column: $table.answerType, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get outcome =>
      $composableBuilder(column: $table.outcome, builder: (column) => ColumnFilters(column));
}

class $$VoiceListensTableOrderingComposer extends Composer<_$AppDatabase, $VoiceListensTable> {
  $$VoiceListensTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get at =>
      $composableBuilder(column: $table.at, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get profileId =>
      $composableBuilder(column: $table.profileId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get answerType =>
      $composableBuilder(column: $table.answerType, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get outcome =>
      $composableBuilder(column: $table.outcome, builder: (column) => ColumnOrderings(column));
}

class $$VoiceListensTableAnnotationComposer extends Composer<_$AppDatabase, $VoiceListensTable> {
  $$VoiceListensTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id => $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get at => $composableBuilder(column: $table.at, builder: (column) => column);

  GeneratedColumn<String> get profileId =>
      $composableBuilder(column: $table.profileId, builder: (column) => column);

  GeneratedColumn<String> get answerType =>
      $composableBuilder(column: $table.answerType, builder: (column) => column);

  GeneratedColumn<String> get outcome =>
      $composableBuilder(column: $table.outcome, builder: (column) => column);
}

class $$VoiceListensTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $VoiceListensTable,
          VoiceListen,
          $$VoiceListensTableFilterComposer,
          $$VoiceListensTableOrderingComposer,
          $$VoiceListensTableAnnotationComposer,
          $$VoiceListensTableCreateCompanionBuilder,
          $$VoiceListensTableUpdateCompanionBuilder,
          (VoiceListen, BaseReferences<_$AppDatabase, $VoiceListensTable, VoiceListen>),
          VoiceListen,
          PrefetchHooks Function()
        > {
  $$VoiceListensTableTableManager(_$AppDatabase db, $VoiceListensTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () => $$VoiceListensTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () => $$VoiceListensTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () => $$VoiceListensTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<DateTime> at = const Value.absent(),
                Value<String> profileId = const Value.absent(),
                Value<String> answerType = const Value.absent(),
                Value<String> outcome = const Value.absent(),
              }) => VoiceListensCompanion(
                id: id,
                at: at,
                profileId: profileId,
                answerType: answerType,
                outcome: outcome,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required DateTime at,
                required String profileId,
                required String answerType,
                required String outcome,
              }) => VoiceListensCompanion.insert(
                id: id,
                at: at,
                profileId: profileId,
                answerType: answerType,
                outcome: outcome,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$VoiceListensTable, VoiceListen>(table),
                  BaseReferences<_$AppDatabase, $VoiceListensTable, VoiceListen>(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$VoiceListensTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $VoiceListensTable,
      VoiceListen,
      $$VoiceListensTableFilterComposer,
      $$VoiceListensTableOrderingComposer,
      $$VoiceListensTableAnnotationComposer,
      $$VoiceListensTableCreateCompanionBuilder,
      $$VoiceListensTableUpdateCompanionBuilder,
      (VoiceListen, BaseReferences<_$AppDatabase, $VoiceListensTable, VoiceListen>),
      VoiceListen,
      PrefetchHooks Function()
    >;
typedef $$AlertsTableCreateCompanionBuilder = AlertsCompanion Function({
  Value<int> id,
  required DateTime at,
  Value<String?> profileId,
  required String category,
  required String severity,
  Value<int> count,
  Value<String> detail,
  Value<String> words,
  required String dedupeKey,
  Value<DateTime?> readAt,
  Value<DateTime?> syncedAt,
});
typedef $$AlertsTableUpdateCompanionBuilder = AlertsCompanion Function({
  Value<int> id,
  Value<DateTime> at,
  Value<String?> profileId,
  Value<String> category,
  Value<String> severity,
  Value<int> count,
  Value<String> detail,
  Value<String> words,
  Value<String> dedupeKey,
  Value<DateTime?> readAt,
  Value<DateTime?> syncedAt,
});

class $$AlertsTableFilterComposer extends Composer<_$AppDatabase, $AlertsTable> {
  $$AlertsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get at =>
      $composableBuilder(column: $table.at, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get profileId =>
      $composableBuilder(column: $table.profileId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get category =>
      $composableBuilder(column: $table.category, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get severity =>
      $composableBuilder(column: $table.severity, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get count =>
      $composableBuilder(column: $table.count, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get detail =>
      $composableBuilder(column: $table.detail, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get words =>
      $composableBuilder(column: $table.words, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get dedupeKey =>
      $composableBuilder(column: $table.dedupeKey, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get readAt =>
      $composableBuilder(column: $table.readAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get syncedAt =>
      $composableBuilder(column: $table.syncedAt, builder: (column) => ColumnFilters(column));
}

class $$AlertsTableOrderingComposer extends Composer<_$AppDatabase, $AlertsTable> {
  $$AlertsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get at =>
      $composableBuilder(column: $table.at, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get profileId =>
      $composableBuilder(column: $table.profileId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get category =>
      $composableBuilder(column: $table.category, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get severity =>
      $composableBuilder(column: $table.severity, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get count =>
      $composableBuilder(column: $table.count, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get detail =>
      $composableBuilder(column: $table.detail, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get words =>
      $composableBuilder(column: $table.words, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get dedupeKey =>
      $composableBuilder(column: $table.dedupeKey, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get readAt =>
      $composableBuilder(column: $table.readAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get syncedAt =>
      $composableBuilder(column: $table.syncedAt, builder: (column) => ColumnOrderings(column));
}

class $$AlertsTableAnnotationComposer extends Composer<_$AppDatabase, $AlertsTable> {
  $$AlertsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id => $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get at => $composableBuilder(column: $table.at, builder: (column) => column);

  GeneratedColumn<String> get profileId =>
      $composableBuilder(column: $table.profileId, builder: (column) => column);

  GeneratedColumn<String> get category =>
      $composableBuilder(column: $table.category, builder: (column) => column);

  GeneratedColumn<String> get severity =>
      $composableBuilder(column: $table.severity, builder: (column) => column);

  GeneratedColumn<int> get count => $composableBuilder(column: $table.count, builder: (column) => column);

  GeneratedColumn<String> get detail =>
      $composableBuilder(column: $table.detail, builder: (column) => column);

  GeneratedColumn<String> get words => $composableBuilder(column: $table.words, builder: (column) => column);

  GeneratedColumn<String> get dedupeKey =>
      $composableBuilder(column: $table.dedupeKey, builder: (column) => column);

  GeneratedColumn<DateTime> get readAt =>
      $composableBuilder(column: $table.readAt, builder: (column) => column);

  GeneratedColumn<DateTime> get syncedAt =>
      $composableBuilder(column: $table.syncedAt, builder: (column) => column);
}

class $$AlertsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AlertsTable,
          Alert,
          $$AlertsTableFilterComposer,
          $$AlertsTableOrderingComposer,
          $$AlertsTableAnnotationComposer,
          $$AlertsTableCreateCompanionBuilder,
          $$AlertsTableUpdateCompanionBuilder,
          (Alert, BaseReferences<_$AppDatabase, $AlertsTable, Alert>),
          Alert,
          PrefetchHooks Function()
        > {
  $$AlertsTableTableManager(_$AppDatabase db, $AlertsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () => $$AlertsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () => $$AlertsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () => $$AlertsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<DateTime> at = const Value.absent(),
                Value<String?> profileId = const Value.absent(),
                Value<String> category = const Value.absent(),
                Value<String> severity = const Value.absent(),
                Value<int> count = const Value.absent(),
                Value<String> detail = const Value.absent(),
                Value<String> words = const Value.absent(),
                Value<String> dedupeKey = const Value.absent(),
                Value<DateTime?> readAt = const Value.absent(),
                Value<DateTime?> syncedAt = const Value.absent(),
              }) => AlertsCompanion(
                id: id,
                at: at,
                profileId: profileId,
                category: category,
                severity: severity,
                count: count,
                detail: detail,
                words: words,
                dedupeKey: dedupeKey,
                readAt: readAt,
                syncedAt: syncedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required DateTime at,
                Value<String?> profileId = const Value.absent(),
                required String category,
                required String severity,
                Value<int> count = const Value.absent(),
                Value<String> detail = const Value.absent(),
                Value<String> words = const Value.absent(),
                required String dedupeKey,
                Value<DateTime?> readAt = const Value.absent(),
                Value<DateTime?> syncedAt = const Value.absent(),
              }) => AlertsCompanion.insert(
                id: id,
                at: at,
                profileId: profileId,
                category: category,
                severity: severity,
                count: count,
                detail: detail,
                words: words,
                dedupeKey: dedupeKey,
                readAt: readAt,
                syncedAt: syncedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$AlertsTable, Alert>(table),
                  BaseReferences<_$AppDatabase, $AlertsTable, Alert>(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$AlertsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AlertsTable,
      Alert,
      $$AlertsTableFilterComposer,
      $$AlertsTableOrderingComposer,
      $$AlertsTableAnnotationComposer,
      $$AlertsTableCreateCompanionBuilder,
      $$AlertsTableUpdateCompanionBuilder,
      (Alert, BaseReferences<_$AppDatabase, $AlertsTable, Alert>),
      Alert,
      PrefetchHooks Function()
    >;
typedef $$RewardsTableCreateCompanionBuilder = RewardsCompanion Function({
  Value<int> id,
  required String profileId,
  required String awardKey,
  required String kind,
  required DateTime at,
  Value<DateTime?> seenAt,
  Value<String?> eventId,
  Value<DateTime?> syncedAt,
});
typedef $$RewardsTableUpdateCompanionBuilder = RewardsCompanion Function({
  Value<int> id,
  Value<String> profileId,
  Value<String> awardKey,
  Value<String> kind,
  Value<DateTime> at,
  Value<DateTime?> seenAt,
  Value<String?> eventId,
  Value<DateTime?> syncedAt,
});

class $$RewardsTableFilterComposer extends Composer<_$AppDatabase, $RewardsTable> {
  $$RewardsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get profileId =>
      $composableBuilder(column: $table.profileId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get awardKey =>
      $composableBuilder(column: $table.awardKey, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get at =>
      $composableBuilder(column: $table.at, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get seenAt =>
      $composableBuilder(column: $table.seenAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get eventId =>
      $composableBuilder(column: $table.eventId, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get syncedAt =>
      $composableBuilder(column: $table.syncedAt, builder: (column) => ColumnFilters(column));
}

class $$RewardsTableOrderingComposer extends Composer<_$AppDatabase, $RewardsTable> {
  $$RewardsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get profileId =>
      $composableBuilder(column: $table.profileId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get awardKey =>
      $composableBuilder(column: $table.awardKey, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get at =>
      $composableBuilder(column: $table.at, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get seenAt =>
      $composableBuilder(column: $table.seenAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get eventId =>
      $composableBuilder(column: $table.eventId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get syncedAt =>
      $composableBuilder(column: $table.syncedAt, builder: (column) => ColumnOrderings(column));
}

class $$RewardsTableAnnotationComposer extends Composer<_$AppDatabase, $RewardsTable> {
  $$RewardsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id => $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get profileId =>
      $composableBuilder(column: $table.profileId, builder: (column) => column);

  GeneratedColumn<String> get awardKey =>
      $composableBuilder(column: $table.awardKey, builder: (column) => column);

  GeneratedColumn<String> get kind => $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<DateTime> get at => $composableBuilder(column: $table.at, builder: (column) => column);

  GeneratedColumn<DateTime> get seenAt =>
      $composableBuilder(column: $table.seenAt, builder: (column) => column);

  GeneratedColumn<String> get eventId =>
      $composableBuilder(column: $table.eventId, builder: (column) => column);

  GeneratedColumn<DateTime> get syncedAt =>
      $composableBuilder(column: $table.syncedAt, builder: (column) => column);
}

class $$RewardsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $RewardsTable,
          Reward,
          $$RewardsTableFilterComposer,
          $$RewardsTableOrderingComposer,
          $$RewardsTableAnnotationComposer,
          $$RewardsTableCreateCompanionBuilder,
          $$RewardsTableUpdateCompanionBuilder,
          (Reward, BaseReferences<_$AppDatabase, $RewardsTable, Reward>),
          Reward,
          PrefetchHooks Function()
        > {
  $$RewardsTableTableManager(_$AppDatabase db, $RewardsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () => $$RewardsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () => $$RewardsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () => $$RewardsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> profileId = const Value.absent(),
                Value<String> awardKey = const Value.absent(),
                Value<String> kind = const Value.absent(),
                Value<DateTime> at = const Value.absent(),
                Value<DateTime?> seenAt = const Value.absent(),
                Value<String?> eventId = const Value.absent(),
                Value<DateTime?> syncedAt = const Value.absent(),
              }) => RewardsCompanion(
                id: id,
                profileId: profileId,
                awardKey: awardKey,
                kind: kind,
                at: at,
                seenAt: seenAt,
                eventId: eventId,
                syncedAt: syncedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String profileId,
                required String awardKey,
                required String kind,
                required DateTime at,
                Value<DateTime?> seenAt = const Value.absent(),
                Value<String?> eventId = const Value.absent(),
                Value<DateTime?> syncedAt = const Value.absent(),
              }) => RewardsCompanion.insert(
                id: id,
                profileId: profileId,
                awardKey: awardKey,
                kind: kind,
                at: at,
                seenAt: seenAt,
                eventId: eventId,
                syncedAt: syncedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$RewardsTable, Reward>(table),
                  BaseReferences<_$AppDatabase, $RewardsTable, Reward>(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$RewardsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $RewardsTable,
      Reward,
      $$RewardsTableFilterComposer,
      $$RewardsTableOrderingComposer,
      $$RewardsTableAnnotationComposer,
      $$RewardsTableCreateCompanionBuilder,
      $$RewardsTableUpdateCompanionBuilder,
      (Reward, BaseReferences<_$AppDatabase, $RewardsTable, Reward>),
      Reward,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$ProfilesTableTableManager get profiles => $$ProfilesTableTableManager(_db, _db.profiles);
  $$AppSettingsTableTableManager get appSettings => $$AppSettingsTableTableManager(_db, _db.appSettings);
  $$LocalEventsTableTableManager get localEvents => $$LocalEventsTableTableManager(_db, _db.localEvents);
  $$InstalledPacksTableTableManager get installedPacks =>
      $$InstalledPacksTableTableManager(_db, _db.installedPacks);
  $$AttemptsTableTableManager get attempts => $$AttemptsTableTableManager(_db, _db.attempts);
  $$SessionsTableTableManager get sessions => $$SessionsTableTableManager(_db, _db.sessions);
  $$VoiceListensTableTableManager get voiceListens => $$VoiceListensTableTableManager(_db, _db.voiceListens);
  $$AlertsTableTableManager get alerts => $$AlertsTableTableManager(_db, _db.alerts);
  $$RewardsTableTableManager get rewards => $$RewardsTableTableManager(_db, _db.rewards);
}
