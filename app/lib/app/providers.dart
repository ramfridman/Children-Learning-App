import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../auth/auth_client.dart';
import '../auth/session_manager.dart';
import '../core/clock.dart';
import '../core/config.dart';
import '../core/hosts.dart';
import '../device/device_key_service.dart';
import '../device/enrolment_service.dart';
import '../device/secure_store.dart';
import '../net/gateway_client.dart';
import '../net/net_gate.dart';

// main() overrides these two with the values loaded at start-up.
final Provider<AppConfig> configProvider = Provider<AppConfig>((Ref ref) => throw UnimplementedError());
final Provider<NetworkHosts> hostsProvider = Provider<NetworkHosts>((Ref ref) => throw UnimplementedError());

final Provider<Clock> clockProvider = Provider<Clock>((Ref ref) => const SystemClock());

final Provider<http.Client> httpClientProvider = Provider<http.Client>((Ref ref) {
  final http.Client client = http.Client();
  ref.onDispose(client.close);
  return client;
});

final Provider<NetGate> netGateProvider = Provider<NetGate>(
  (Ref ref) => NetGate(client: ref.watch(httpClientProvider), hosts: ref.watch(hostsProvider)),
);

final Provider<SecureStore> secureStoreProvider = Provider<SecureStore>((Ref ref) => PlatformSecureStore());

final Provider<DeviceKeyService> deviceKeysProvider = Provider<DeviceKeyService>(
  (Ref ref) => AndroidDeviceKeyService(),
);

final Provider<GatewayClient> gatewayProvider = Provider<GatewayClient>((Ref ref) {
  final AppConfig config = ref.watch(configProvider);
  return GatewayClient(
    baseUrl: config.supabaseUrl,
    publishableKey: config.publishableKey,
    gate: ref.watch(netGateProvider),
    keys: ref.watch(deviceKeysProvider),
    clock: ref.watch(clockProvider),
  );
});

final Provider<AuthClient> authClientProvider = Provider<AuthClient>((Ref ref) {
  final AppConfig config = ref.watch(configProvider);
  return AuthClient(
    baseUrl: config.supabaseUrl,
    publishableKey: config.publishableKey,
    gate: ref.watch(netGateProvider),
    clock: ref.watch(clockProvider),
  );
});

final Provider<SessionManager> sessionManagerProvider = Provider<SessionManager>(
  (Ref ref) => SessionManager(
    auth: ref.watch(authClientProvider),
    store: ref.watch(secureStoreProvider),
    clock: ref.watch(clockProvider),
  ),
);

final Provider<EnrolmentService> enrolmentProvider = Provider<EnrolmentService>(
  (Ref ref) => EnrolmentService(
    gateway: ref.watch(gatewayProvider),
    auth: ref.watch(authClientProvider),
    sessions: ref.watch(sessionManagerProvider),
    keys: ref.watch(deviceKeysProvider),
    store: ref.watch(secureStoreProvider),
    config: ref.watch(configProvider),
  ),
);
