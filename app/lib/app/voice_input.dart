import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/app_database.dart';
import '../speech/model_spec.dart';
import '../speech/sherpa_engine.dart';
import '../speech/speech_engine.dart';
import 'state.dart';

/// The recogniser. Tests give a fake one.
final Provider<SpeechEngine> speechEngineProvider = Provider<SpeechEngine>((Ref ref) {
  final SherpaEngine engine = SherpaEngine(
    modelDir: () async => Directory(
      '${await ref.read(platformProvider).noBackupDir()}${Platform.pathSeparator}${SpeechModel.folderName}',
    ),
  );
  ref.onDispose(engine.dispose);
  return engine;
});

/// What happened when a parent flipped the "Voice answers" switch.
enum VoiceSwitch { on, off, modelMissing, permissionDenied }

const String _voiceKey = 'voice_enabled';

/// The parent's switch for voice answers: off until a parent turns it on, for this device. Turning it on needs the
/// speech model on the phone and the microphone permission, which Android asks of the parent, never of the child.
class VoiceEnabled extends AsyncNotifier<bool> {
  @override
  Future<bool> build() async => (await (await ref.watch(databaseProvider.future)).setting(_voiceKey)) == 'on';

  Future<VoiceSwitch> set(bool on) async {
    final AppDatabase db = await ref.read(databaseProvider.future);
    if (!on) {
      await db.putSetting(_voiceKey, 'off');
      state = const AsyncData<bool>(false);
      return VoiceSwitch.off;
    }
    final SpeechEngine engine = ref.read(speechEngineProvider);
    if (!await engine.modelInstalled()) return VoiceSwitch.modelMissing;
    if (!await engine.requestPermission()) return VoiceSwitch.permissionDenied;
    await db.putSetting(_voiceKey, 'on');
    state = const AsyncData<bool>(true);
    return VoiceSwitch.on;
  }
}

final AsyncNotifierProvider<VoiceEnabled, bool> voiceEnabledProvider =
    AsyncNotifierProvider<VoiceEnabled, bool>(VoiceEnabled.new);

/// Voice can be offered to a child now: a parent turned it on and the model is on the phone.
final FutureProvider<bool> voiceAvailableProvider = FutureProvider<bool>((Ref ref) async {
  if (!await ref.watch(voiceEnabledProvider.future)) return false;
  return ref.read(speechEngineProvider).modelInstalled();
});
