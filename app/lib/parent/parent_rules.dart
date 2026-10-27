import 'dart:convert';

/// What the parent decided about time, kept on this device as one small JSON setting (it is synced in M7b). Every
/// number is clamped when read, so a damaged or hand-edited value can never produce an absurd rule.
class ParentRules {
  const ParentRules({
    this.limitByBand = defaultLimits,
    this.limitByChild = const <String, int>{},
    this.restOn = true,
    this.restStartMinute = 19 * 60 + 30,
    this.restEndMinute = 6 * 60 + 30,
    this.schedule = const <int, List<List<int>>>{},
    this.lockWhenDone = true,
  });

  factory ParentRules.fromJson(Map<String, Object?> j) {
    int number(Object? v, int fallback, int low, int high) => v is int ? v.clamp(low, high) : fallback;
    final Object? bands = j['limitByBand'];
    final Object? kids = j['limitByChild'];
    final Object? windows = j['schedule'];
    return ParentRules(
      limitByBand: <String, int>{
        for (final String b in const <String>['A', 'B', 'C'])
          b: number(bands is Map<String, Object?> ? bands[b] : null, defaultLimits[b]!, minLimit, maxLimit),
      },
      limitByChild: <String, int>{
        if (kids is Map<String, Object?>)
          for (final MapEntry<String, Object?> e in kids.entries)
            if (e.value is int) e.key: (e.value! as int).clamp(minLimit, maxLimit),
      },
      restOn: j['restOn'] is bool ? j['restOn']! as bool : true,
      restStartMinute: number(j['restStartMinute'], 19 * 60 + 30, 0, 1439),
      restEndMinute: number(j['restEndMinute'], 6 * 60 + 30, 0, 1439),
      schedule: <int, List<List<int>>>{
        if (windows is Map<String, Object?>)
          for (final MapEntry<String, Object?> e in windows.entries)
            if (int.tryParse(e.key) case final int day? when day >= 1 && day <= 7 && e.value is List<Object?>)
              day: <List<int>>[
                for (final Object? w in e.value! as List<Object?>)
                  if (w is List<Object?> && w.length == 2 && w[0] is int && w[1] is int)
                    <int>[(w[0]! as int).clamp(0, 1439), (w[1]! as int).clamp(0, 1439)],
              ],
      },
      lockWhenDone: j['lockWhenDone'] is bool ? j['lockWhenDone']! as bool : true,
    );
  }

  factory ParentRules.decode(String? text) {
    if (text == null || text.isEmpty) return const ParentRules();
    try {
      final Object? j = jsonDecode(text);
      return j is Map<String, Object?> ? ParentRules.fromJson(j) : const ParentRules();
    } on FormatException {
      return const ParentRules();
    }
  }

  /// Minutes of play a day for band A, B and C (PLAN, M7 Q2).
  static const Map<String, int> defaultLimits = <String, int>{'A': 20, 'B': 30, 'C': 40};
  static const int minLimit = 5;
  static const int maxLimit = 180;

  final Map<String, int> limitByBand;

  /// A limit chosen for one child, by profile id; it wins over the band's.
  final Map<String, int> limitByChild;

  /// Rest hours: no new play between [restStartMinute] and [restEndMinute] (minutes after midnight; may wrap midnight).
  final bool restOn;
  final int restStartMinute;
  final int restEndMinute;

  /// Weekdays (1 Monday to 7 Sunday) to the windows (start and end minute) in which play is allowed. A weekday with
  /// no entry, or an empty one, allows any time.
  final Map<int, List<List<int>>> schedule;

  /// When time is up (limit, rest hours or schedule): true means no new activity is offered; false means the guide
  /// suggests resting but the child may go on (and the parent gets a note).
  final bool lockWhenDone;

  /// The daily limit for a child: the child's own, else the band's (0, 1 or 2 for A, B, C).
  int limitFor(String profileId, int ageBand) =>
      limitByChild[profileId] ?? limitByBand[const <String>['A', 'B', 'C'][ageBand.clamp(0, 2)]]!;

  ParentRules copyWith({
    Map<String, int>? limitByBand,
    Map<String, int>? limitByChild,
    bool? restOn,
    int? restStartMinute,
    int? restEndMinute,
    Map<int, List<List<int>>>? schedule,
    bool? lockWhenDone,
  }) => ParentRules(
    limitByBand: limitByBand ?? this.limitByBand,
    limitByChild: limitByChild ?? this.limitByChild,
    restOn: restOn ?? this.restOn,
    restStartMinute: restStartMinute ?? this.restStartMinute,
    restEndMinute: restEndMinute ?? this.restEndMinute,
    schedule: schedule ?? this.schedule,
    lockWhenDone: lockWhenDone ?? this.lockWhenDone,
  );

  Map<String, Object?> toJson() => <String, Object?>{
    'limitByBand': limitByBand,
    'limitByChild': limitByChild,
    'restOn': restOn,
    'restStartMinute': restStartMinute,
    'restEndMinute': restEndMinute,
    'schedule': <String, Object?>{
      for (final MapEntry<int, List<List<int>>> e in schedule.entries) '${e.key}': e.value,
    },
    'lockWhenDone': lockWhenDone,
  };

  String encode() => jsonEncode(toJson());
}
