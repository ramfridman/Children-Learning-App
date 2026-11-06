import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show FutureProviderFamily, ProviderFamily;

import '../data/app_database.dart';
import '../engine/course.dart';
import '../parent/language_settings.dart';
import '../speech/model_spec.dart';
import '../speech/sherpa_engine.dart';
import '../speech/speech_engine.dart';
import 'language_providers.dart';
import 'state.dart';

SherpaEngine _engineOf(Ref ref, SpeechModelSpec spec) {
  final SherpaEngine engine = SherpaEngine(
    spec: spec,
    modelDir: () async => Directory(
      '${await ref.read(platformProvider).noBackupDir()}${Platform.pathSeparator}${spec.folderName}',
    ),
  );
  ref.onDispose(engine.dispose);
  return engine;
}

/// The Hebrew recogniser of the lands. Tests give a fake one.
final Provider<SpeechEngine> speechEngineProvider = Provider<SpeechEngine>(
  (Ref ref) => _engineOf(ref, SpeechModels.hebrew),
);

/// The recogniser of a language course (`eng`, `heb`, `rus`). It is made here but not loaded: nothing is read from disk until a
/// say-it step of a child whose parent turned that language's voice on asks it to prepare. It is freed (and its model with it)
/// when the last child's voice switch for this language turns off: the provider watches that, so it is made again, empty, if a
/// switch is turned on later. Tests give a fake one.
final ProviderFamily<SpeechEngine, String> languageSpeechEngineProvider =
    Provider.family<SpeechEngine, String>((Ref ref, String course) {
      ref.watch(
        languagesProvider.select((AsyncValue<FamilyLanguages> f) => f.value?.anyVoice(course) ?? false),
      );
      return _engineOf(ref, SpeechModels.forCourse(course)!);
    });

/// Whether a language's say-it has passed its release gate and may use the microphone ([SpeechModelSpec.released]). A test that
/// needs the microphone overrides it.
final ProviderFamily<bool, String> sayItReleasedProvider = Provider.family<bool, String>(
  (Ref ref, String course) => SpeechModels.forCourse(course)?.released ?? false,
);

/// What a say-it step may do now for one child and one course: the language has passed its release gate, the parent's voice switch
/// for that language is on, and its model is on the phone. False in every other case, and then the step runs as echo. Nothing is loaded by asking.
final FutureProviderFamily<bool, ({String childId, String course})> sayItAvailableProvider =
    FutureProvider.family<bool, ({String childId, String course})>((
      Ref ref,
      ({String childId, String course}) k,
    ) async {
      if (!Course.isLanguage(k.course) || !ref.watch(sayItReleasedProvider(k.course))) return false;
      final FamilyLanguages family = await ref.watch(languagesProvider.future);
      if (!family.of(k.childId, k.course).voice) return false;
      return ref.read(languageSpeechEngineProvider(k.course)).modelInstalled();
    });

/// A parent switched voice on for a language: Android asks the parent (never the child) for the microphone. The model is not
/// loaded and nothing listens.
final Provider<Future<bool> Function(String course)> microphonePermissionProvider =
    Provider<Future<bool> Function(String course)>(
      (Ref ref) =>
          (String course) => ref.read(languageSpeechEngineProvider(course)).requestPermission(),
    );

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
