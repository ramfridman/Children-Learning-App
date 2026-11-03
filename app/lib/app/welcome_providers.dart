import 'dart:typed_data';

import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show FutureProviderFamily;

import '../core/errors.dart';
import '../device/secure_store.dart';
import '../voice/name_clips.dart';
import '../world/welcome_table.dart';
import 'companion.dart';
import 'providers.dart';
import 'state.dart';

/// The welcome's lines and topic table, read once from `assets/lines/welcome.json`.
final FutureProvider<WelcomeTable> welcomeTableProvider = FutureProvider<WelcomeTable>(
  (Ref ref) async =>
      WelcomeTable.parse(await rootBundle.loadString('assets/lines/welcome.json', cache: false)),
);

/// Whether the daily welcome is given at all. Tests that are about something else switch it off, so that the first map of
/// the day shows what it always showed.
final Provider<bool> welcomeEnabledProvider = Provider<bool>((Ref ref) => true);

/// Whether the welcome is said aloud. There is no sound switch in the app yet; when there is one, it is read here, and the
/// welcome is then only shown (B42.md 2.4).
final Provider<bool> welcomeSpokenProvider = Provider<bool>((Ref ref) => true);

/// The sound of the child's name in the voice of the friend they chose (the guide's), or null when there is none: until a
/// parent has tapped "listen" in the parent area the welcome plays without it. Invalidated when a clip is made.
final FutureProviderFamily<Uint8List?, String> nameClipProvider = FutureProvider.family<Uint8List?, String>(
  (Ref ref, String childId) async => nameClipFor(
    await ref.watch(databaseProvider.future),
    childId,
    (await ref.watch(guideProvider.future)).character.id,
  ),
);

/// Asks the gateway for the sound of a child's name. Tests give a fake: nothing else reaches the network.
final Provider<NameVoice> nameVoiceProvider = Provider<NameVoice>(
  (Ref ref) => GatewayNameVoice((String name, Map<String, Object?> body) async {
    final String? deviceId = await ref.read(secureStoreProvider).read(StoreKeys.deviceId);
    final String? token = await ref.read(sessionManagerProvider).accessToken();
    if (deviceId == null || token == null) throw const GatewayException('unauthorized');
    return ref.read(gatewayProvider).call(name, body, deviceId: deviceId, accessToken: token);
  }),
);
