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
          ..write('sessionId: $sessionId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
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
  );
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
          other.sessionId == this.sessionId);
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
          ..write('sessionId: $sessionId')
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
  @override
  List<GeneratedColumn> get $columns => [id, profileId, startedAt, endedAt, plan, endReason];
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
  const Session({
    required this.id,
    required this.profileId,
    required this.startedAt,
    this.endedAt,
    required this.plan,
    required this.endReason,
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
    };
  }

  Session copyWith({
    int? id,
    String? profileId,
    DateTime? startedAt,
    Value<DateTime?> endedAt = const Value.absent(),
    String? plan,
    String? endReason,
  }) => Session(
    id: id ?? this.id,
    profileId: profileId ?? this.profileId,
    startedAt: startedAt ?? this.startedAt,
    endedAt: endedAt.present ? endedAt.value : this.endedAt,
    plan: plan ?? this.plan,
    endReason: endReason ?? this.endReason,
  );
  Session copyWithCompanion(SessionsCompanion data) {
    return Session(
      id: data.id.present ? data.id.value : this.id,
      profileId: data.profileId.present ? data.profileId.value : this.profileId,
      startedAt: data.startedAt.present ? data.startedAt.value : this.startedAt,
      endedAt: data.endedAt.present ? data.endedAt.value : this.endedAt,
      plan: data.plan.present ? data.plan.value : this.plan,
      endReason: data.endReason.present ? data.endReason.value : this.endReason,
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
          ..write('endReason: $endReason')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, profileId, startedAt, endedAt, plan, endReason);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Session &&
          other.id == this.id &&
          other.profileId == this.profileId &&
          other.startedAt == this.startedAt &&
          other.endedAt == this.endedAt &&
          other.plan == this.plan &&
          other.endReason == this.endReason);
}

class SessionsCompanion extends UpdateCompanion<Session> {
  final Value<int> id;
  final Value<String> profileId;
  final Value<DateTime> startedAt;
  final Value<DateTime?> endedAt;
  final Value<String> plan;
  final Value<String> endReason;
  const SessionsCompanion({
    this.id = const Value.absent(),
    this.profileId = const Value.absent(),
    this.startedAt = const Value.absent(),
    this.endedAt = const Value.absent(),
    this.plan = const Value.absent(),
    this.endReason = const Value.absent(),
  });
  SessionsCompanion.insert({
    this.id = const Value.absent(),
    required String profileId,
    required DateTime startedAt,
    this.endedAt = const Value.absent(),
    this.plan = const Value.absent(),
    this.endReason = const Value.absent(),
  }) : profileId = Value(profileId),
       startedAt = Value(startedAt);
  static Insertable<Session> custom({
    Expression<int>? id,
    Expression<String>? profileId,
    Expression<DateTime>? startedAt,
    Expression<DateTime>? endedAt,
    Expression<String>? plan,
    Expression<String>? endReason,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (profileId != null) 'profile_id': profileId,
      if (startedAt != null) 'started_at': startedAt,
      if (endedAt != null) 'ended_at': endedAt,
      if (plan != null) 'plan': plan,
      if (endReason != null) 'end_reason': endReason,
    });
  }

  SessionsCompanion copyWith({
    Value<int>? id,
    Value<String>? profileId,
    Value<DateTime>? startedAt,
    Value<DateTime?>? endedAt,
    Value<String>? plan,
    Value<String>? endReason,
  }) {
    return SessionsCompanion(
      id: id ?? this.id,
      profileId: profileId ?? this.profileId,
      startedAt: startedAt ?? this.startedAt,
      endedAt: endedAt ?? this.endedAt,
      plan: plan ?? this.plan,
      endReason: endReason ?? this.endReason,
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
          ..write('endReason: $endReason')
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
});
typedef $$SessionsTableUpdateCompanionBuilder = SessionsCompanion Function({
  Value<int> id,
  Value<String> profileId,
  Value<DateTime> startedAt,
  Value<DateTime?> endedAt,
  Value<String> plan,
  Value<String> endReason,
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
              }) => SessionsCompanion(
                id: id,
                profileId: profileId,
                startedAt: startedAt,
                endedAt: endedAt,
                plan: plan,
                endReason: endReason,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String profileId,
                required DateTime startedAt,
                Value<DateTime?> endedAt = const Value.absent(),
                Value<String> plan = const Value.absent(),
                Value<String> endReason = const Value.absent(),
              }) => SessionsCompanion.insert(
                id: id,
                profileId: profileId,
                startedAt: startedAt,
                endedAt: endedAt,
                plan: plan,
                endReason: endReason,
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
}
