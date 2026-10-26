import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app/providers.dart';
import '../auth/auth_client.dart';
import '../core/errors.dart';
import '../device/secure_store.dart';

/// What the setup screens need from the network, as an interface so widget tests use a fake.
abstract interface class SetupBackend {
  Future<void> sendCode(String email);
  Future<void> verifyCode(String email, String code);
  Future<bool> hasSession();
  Future<bool> isEnrolled();
  Future<void> enrol();
}

class RealSetupBackend implements SetupBackend {
  RealSetupBackend(this._ref);

  final Ref _ref;

  @override
  Future<void> sendCode(String email) => _ref.read(authClientProvider).sendEmailCode(email);

  @override
  Future<void> verifyCode(String email, String code) async {
    final AuthSession s = await _ref.read(authClientProvider).verifyEmailCode(email, code);
    await _ref.read(sessionManagerProvider).setSession(s);
  }

  @override
  Future<bool> hasSession() async => (await _ref.read(sessionManagerProvider).accessToken()) != null;

  @override
  Future<bool> isEnrolled() async => (await _ref.read(enrolmentProvider).enrolledDeviceId()) != null;

  @override
  Future<void> enrol() async {
    await _ref.read(enrolmentProvider).enrolParent();
  }
}

final Provider<SetupBackend> setupBackendProvider = Provider<SetupBackend>(
  (Ref ref) => RealSetupBackend(ref),
);

/// One device of the family, as the parent area shows it.
class DeviceInfo {
  const DeviceInfo({required this.id, required this.role, required this.thisDevice, required this.platform});

  final String id;
  final String role;
  final bool thisDevice;
  final String platform;
}

abstract interface class DevicesBackend {
  Future<List<DeviceInfo>> list();
  Future<void> revoke(String deviceId);
}

class RealDevicesBackend implements DevicesBackend {
  RealDevicesBackend(this._ref);

  final Ref _ref;

  Future<Map<String, Object?>> _call(String function, Map<String, Object?> body) async {
    final String? id = await _ref.read(secureStoreProvider).read(StoreKeys.deviceId);
    final String? token = await _ref.read(sessionManagerProvider).accessToken();
    if (id == null || token == null) throw const GatewayException('unauthorized');
    return _ref.read(gatewayProvider).call(function, body, deviceId: id, accessToken: token);
  }

  @override
  Future<List<DeviceInfo>> list() async {
    final Map<String, Object?> r = await _call('device-list', const <String, Object?>{});
    final Object? devices = r['devices'];
    if (devices is! List<Object?>) throw const GatewayException('bad_response');
    return <DeviceInfo>[
      for (final Object? d in devices)
        if (d is Map<String, Object?>)
          DeviceInfo(
            id: '${d['id']}',
            role: '${d['role']}',
            platform: '${d['platform']}',
            thisDevice: d['this_device'] == true,
          ),
    ];
  }

  @override
  Future<void> revoke(String deviceId) async {
    await _call('device-revoke', <String, Object?>{'device_id': deviceId});
  }
}

final Provider<DevicesBackend> devicesBackendProvider = Provider<DevicesBackend>(
  (Ref ref) => RealDevicesBackend(ref),
);
