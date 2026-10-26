import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../device/secure_store.dart';
import '../tutor/tutor.dart';
import 'providers.dart';
import 'state.dart';

const String _aiKey = 'ai_helper';

/// The AI helper switch of this device: off until it is turned on. In M6 the switch is on the dev page; the parent's
/// real control comes with the parent area in M7.
class AiHelper extends AsyncNotifier<bool> {
  @override
  Future<bool> build() async => (await (await ref.watch(databaseProvider.future)).setting(_aiKey)) == 'on';

  Future<void> set(bool on) async {
    await (await ref.read(databaseProvider.future)).putSetting(_aiKey, on ? 'on' : 'off');
    state = AsyncData<bool>(on);
  }
}

final AsyncNotifierProvider<AiHelper, bool> aiHelperProvider = AsyncNotifierProvider<AiHelper, bool>(
  AiHelper.new,
);

final Provider<TutorClient> tutorClientProvider = Provider<TutorClient>(
  (Ref ref) => GatewayTutorClient(
    call: (String name, Map<String, Object?> body, {String? deviceId, String? accessToken}) =>
        ref.read(gatewayProvider).call(name, body, deviceId: deviceId, accessToken: accessToken),
    deviceId: () => ref.read(secureStoreProvider).read(StoreKeys.deviceId),
    accessToken: () => ref.read(sessionManagerProvider).accessToken(),
  ),
);

/// The kill switch and the minimum of the server, read at most every 15 minutes.
class RemoteSwitches {
  RemoteSwitches(this._read, this._nowMs);

  final Future<bool> Function() _read;
  final int Function() _nowMs;
  bool? _value;
  int _at = 0;

  Future<bool> tutorEnabled() async {
    if (_value != null && _nowMs() - _at < 15 * 60 * 1000) return _value!;
    _value = await _read();
    _at = _nowMs();
    return _value!;
  }
}

final Provider<RemoteSwitches> remoteSwitchesProvider = Provider<RemoteSwitches>((Ref ref) {
  return RemoteSwitches(() async {
    try {
      final String? id = await ref.read(secureStoreProvider).read(StoreKeys.deviceId);
      final String? token = await ref.read(sessionManagerProvider).accessToken();
      if (id == null || token == null) return false;
      final Map<String, Object?> answer = await ref
          .read(gatewayProvider)
          .call('app-config', const <String, Object?>{}, deviceId: id, accessToken: token);
      return answer['tutor_enabled'] == true;
    } on Object {
      return false;
    }
  }, () => ref.read(clockProvider).nowMs());
});

/// The tutor can be used in this lesson: the helper is on here and the server says it is on. Resolves fast (a second
/// at most), and doubles as the light call that warms the function. A failure is "off".
final FutureProvider<bool> tutorAvailableProvider = FutureProvider<bool>((Ref ref) async {
  if (!await ref.watch(aiHelperProvider.future)) return false;
  return ref
      .read(remoteSwitchesProvider)
      .tutorEnabled()
      .timeout(const Duration(seconds: 1), onTimeout: () => false);
});
