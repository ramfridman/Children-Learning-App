import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../device/secure_store.dart';
import 'providers.dart';

/// One line of what the AI helper said (or why the usual message was heard instead), as the server keeps it for 30 days.
class TutorLogLine {
  const TutorLogLine({
    required this.at,
    required this.childId,
    required this.source,
    required this.outcome,
    required this.line,
  });

  final DateTime at;
  final String childId;

  /// `live`, `cache` or `prefetch` (a line was made or kept), or `rule` (the usual message was used).
  final String source;
  final String outcome;
  final String? line;

  bool get spoken => source != 'rule' && line != null;
}

/// The family's helper log, asked from the server each time the screen opens (the caller invalidates it first).
/// Null means the server could not be reached.
final FutureProvider<List<TutorLogLine>?> tutorLogProvider = FutureProvider<List<TutorLogLine>?>((
  Ref ref,
) async {
  try {
    final String? id = await ref.read(secureStoreProvider).read(StoreKeys.deviceId);
    final String? token = await ref.read(sessionManagerProvider).accessToken();
    if (id == null || token == null) return null;
    final Map<String, Object?> answer = await ref
        .read(gatewayProvider)
        .call('tutor-log', const <String, Object?>{}, deviceId: id, accessToken: token);
    return <TutorLogLine>[
      for (final Object? raw in (answer['entries'] as List<Object?>? ?? const <Object?>[]))
        TutorLogLine(
          at: DateTime.fromMillisecondsSinceEpoch((raw! as Map<String, Object?>)['at']! as int),
          childId: (raw as Map<String, Object?>)['child_id']! as String,
          source: raw['source']! as String,
          outcome: raw['outcome']! as String,
          line: raw['line'] as String?,
        ),
    ];
  } on Object {
    return null;
  }
});
