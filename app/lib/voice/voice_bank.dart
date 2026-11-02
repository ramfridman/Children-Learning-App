import 'dart:typed_data';

import '../characters/lip_sync.dart';
import '../content/capabilities.dart';
import '../content/pack_verify.dart';
import 'voice_pack_ids.dart';

/// One recorded line: the sound and when the mouth is open in it.
class VoiceClip {
  const VoiceClip(this.mp3, this.mouth, {this.mime = 'audio/mpeg'});

  final Uint8List mp3;
  final String mime;
  final MouthTrack mouth;
}

/// The clips of one verified voice pack, by `vo:` id: the audio files of its manifest and its cue documents.
Map<String, VoiceClip> clipsOfVoicePack(VerifiedPack pack) {
  final Map<String, VoiceClip> clips = <String, VoiceClip>{};
  for (final Object? v in pack.manifest['vo']! as List<Object?>) {
    final Map<String, Object?> entry = v! as Map<String, Object?>;
    final String id = entry['id']! as String;
    final String file = entry['file']! as String;
    final Uint8List? mp3 = pack.files[file];
    if (mp3 == null) continue;
    final Object? cue = pack.docs['cue.$id.json'];
    final List<Object?> cues = cue is Map<String, Object?>
        ? (cue['cues'] as List<Object?>? ?? const <Object?>[])
        : const <Object?>[];
    clips['vo:$id'] = VoiceClip(
      mp3,
      MouthTrack.fromJson(cues),
      mime: file.endsWith('.wav') ? 'audio/wav' : 'audio/mpeg',
    );
  }
  return clips;
}

/// The voice packs of one character, read one at a time as their lines are needed (B-45: a narrator's voice is about sixteen
/// packs and about 100 to 240 MB, too much to hold at once).
///
/// [index] says which pack holds each line (`vo:` id to pack id), from the manifests alone. The [pinned] packs (the shared
/// lines, which every lesson uses) are loaded once and never let go. Of the others at most [maxParts] are in memory at
/// once: a pack is loaded by [loader] when one of its lines is first wanted, and the one used longest ago makes room for it.
/// So the memory is the pinned packs plus [maxParts] more (each at most 40 MiB), the pack being loaded counted among them.
/// A pack that fails to load ([loader] returns null or throws) is given up for the life of this object: its lines are
/// simply missing, as a line with no recording always was.
class LazyVoicePacks {
  LazyVoicePacks({
    required this.index,
    required this.loader,
    this.pinned = const <String>{},
    this.maxParts = 2,
  }) : assert(maxParts >= 1);

  final Map<String, String> index;
  final Future<VerifiedPack?> Function(String packId) loader;
  final Set<String> pinned;
  final int maxParts;

  /// The clips of each pack in memory; the pack used longest ago comes first.
  final Map<String, Map<String, VoiceClip>> _resident = <String, Map<String, VoiceClip>>{};
  final Map<String, Future<Map<String, VoiceClip>?>> _loading = <String, Future<Map<String, VoiceClip>?>>{};
  final Set<String> _failed = <String>{};

  /// The packs in memory now, the one used longest ago first (for tests and measuring).
  List<String> get residentPacks => _resident.keys.toList();

  /// The packs that gave up.
  Set<String> get failedPacks => Set<String>.of(_failed);

  /// Whether a pack that has not given up holds the line.
  bool knows(String voId) {
    final String? pack = index[voId];
    return pack != null && !_failed.contains(pack);
  }

  /// Whether the line is known but its pack is not in memory, so asking for it would load a pack.
  bool canLoad(String voId) => knows(voId) && !_resident.containsKey(index[voId]);

  /// The clip, if its pack is in memory now (and the pack counts as just used).
  VoiceClip? peek(String voId) {
    final String? pack = index[voId];
    final Map<String, VoiceClip>? clips = pack == null ? null : _resident.remove(pack);
    if (clips == null) return null;
    _resident[pack!] = clips;
    return clips[voId];
  }

  /// The clip, loading its pack first if it is not in memory. Null if no pack holds the line or its pack gave up.
  Future<VoiceClip?> fetch(String voId) async {
    final String? pack = index[voId];
    if (pack == null) return null;
    return (await _pack(pack))?[voId];
  }

  /// Loads the packs of [voIds] ahead of their use, in the order given, at most [maxParts] of them, so that what is loaded
  /// here cannot push out what was loaded here.
  Future<void> prefetch(Iterable<String> voIds) async {
    final List<String> wanted = <String>[];
    for (final String id in voIds) {
      final String? pack = index[id];
      if (pack == null || _failed.contains(pack) || pinned.contains(pack) || wanted.contains(pack)) continue;
      wanted.add(pack);
      if (wanted.length == maxParts) break;
    }
    for (final String pack in wanted) {
      await _pack(pack);
    }
  }

  /// Loads the pinned packs (the shared lines) now.
  Future<void> loadPinned() async {
    for (final String pack in pinned) {
      if (index.containsValue(pack)) await _pack(pack);
    }
  }

  Future<Map<String, VoiceClip>?> _pack(String packId) {
    final Map<String, VoiceClip>? have = _resident.remove(packId);
    if (have != null) {
      _resident[packId] = have;
      return Future<Map<String, VoiceClip>?>.value(have);
    }
    if (_failed.contains(packId)) return Future<Map<String, VoiceClip>?>.value();
    return _loading[packId] ??= _load(packId).whenComplete(() {
      _loading.remove(packId);
    });
  }

  Future<Map<String, VoiceClip>?> _load(String packId) async {
    if (!pinned.contains(packId)) _makeRoom(1);
    try {
      final VerifiedPack? pack = await loader(packId);
      if (pack == null) {
        _failed.add(packId);
        return null;
      }
      final Map<String, VoiceClip> clips = clipsOfVoicePack(pack);
      _resident[packId] = clips;
      _makeRoom(0);
      return clips;
    } on Object {
      // Why is not kept: a message could name a file. The pack's lines are missing, as a line with no recording is.
      _failed.add(packId);
      return null;
    }
  }

  /// Lets go of the packs used longest ago until at most `maxParts - spare` unpinned packs are in memory.
  void _makeRoom(int spare) {
    final List<String> parts = <String>[
      for (final String id in _resident.keys)
        if (!pinned.contains(id)) id,
    ];
    for (final String id in parts.toList()) {
      if (parts.length <= maxParts - spare) break;
      _resident.remove(id);
      parts.remove(id);
    }
  }
}

/// The recorded lines of one character's voice packs, by `vo:` id. A line with no recording is simply absent.
///
/// A bank is either read whole from packs already in memory ([fromPacks], for a few small packs and for tests) or lazy
/// ([VoiceBank.lazy]: the packs come one at a time, [LazyVoicePacks]). [clip] answers at once and only from memory; for a
/// line whose pack is not in memory, [canLoad] says so and [fetch] loads it.
class VoiceBank {
  VoiceBank._(this.characterId, this._clips) : _lazy = null, fallback = null;

  /// Reads one verified voice pack (`voice-<character id>`): the audio files of its manifest and its cue documents.
  factory VoiceBank.fromPack(VerifiedPack pack) =>
      VoiceBank.fromPacks(characterOfVoicePack(pack.id), <VerifiedPack>[pack]);

  /// Reads all the verified voice packs of [characterId] into one bank, so a line is found whichever pack holds it. If
  /// two packs hold the same line (a pack of an older layout left behind), the newer pack's clip is used, and between
  /// equal versions the pack that comes first by id: always the same one.
  factory VoiceBank.fromPacks(String characterId, Iterable<VerifiedPack> packs) {
    final List<VerifiedPack> ordered = packs.toList()
      ..sort((VerifiedPack a, VerifiedPack b) {
        final int newer = compareSemver(b.version, a.version);
        return newer != 0 ? newer : a.id.compareTo(b.id);
      });
    final Map<String, VoiceClip> clips = <String, VoiceClip>{};
    for (final VerifiedPack pack in ordered) {
      for (final MapEntry<String, VoiceClip> c in clipsOfVoicePack(pack).entries) {
        clips.putIfAbsent(c.key, () => c.value);
      }
    }
    return VoiceBank._(characterId, clips);
  }

  /// A bank whose packs are read one at a time, as [packs] says. The caller loads the pinned packs first
  /// ([LazyVoicePacks.loadPinned]) so that the shared lines are in memory from the start.
  VoiceBank.lazy(this.characterId, LazyVoicePacks packs)
    : _clips = const <String, VoiceClip>{},
      _lazy = packs,
      fallback = null;

  /// A bank with no recordings (a character that has no voice pack yet).
  VoiceBank.empty(this.characterId) : _clips = const <String, VoiceClip>{}, _lazy = null, fallback = null;

  /// [primary] with the narrator behind it: a line that [primary] has no recording of is said by [fallback]'s voice, so a
  /// friend with only its own greetings and cheers still teaches aloud (M9, Q5: the flagship voices say every line).
  VoiceBank.withFallback(VoiceBank primary, VoiceBank this.fallback)
    : characterId = primary.characterId,
      _clips = primary._clips,
      _lazy = primary._lazy;

  final String characterId;
  final Map<String, VoiceClip> _clips;
  final LazyVoicePacks? _lazy;

  /// The narrator's bank, for the lines this voice does not have; null for a bank that stands alone.
  final VoiceBank? fallback;

  /// The lazy packs behind this bank, if it is lazy (for tests and measuring).
  LazyVoicePacks? get packs => _lazy;

  int get length => _clips.length + (_lazy?.index.length ?? 0);

  Iterable<String> get ids => <String>[..._clips.keys, ...?_lazy?.index.keys];

  /// Whether the line has a recording, in memory or in a pack that has not given up.
  bool has(String voId) =>
      _clips.containsKey(voId) || (_lazy?.knows(voId) ?? false) || (fallback?.has(voId) ?? false);

  /// The clip, if it is in memory now; null for a line with no recording, and for one whose pack is not loaded yet
  /// ([canLoad]).
  VoiceClip? clip(String voId) {
    final VoiceClip? own = _clips[voId] ?? _lazy?.peek(voId);
    if (own != null) return own;
    // The narrator's version only when this voice does not have the line (a pack that has to be loaded first has it).
    return (_lazy?.canLoad(voId) ?? false) ? null : fallback?.clip(voId);
  }

  /// Whether the line is recorded but its pack is not in memory, so [clip] says nothing yet and [fetch] has to load it.
  bool canLoad(String voId) {
    if (_clips.containsKey(voId)) return false;
    if (_lazy?.canLoad(voId) ?? false) return true;
    return !(_lazy?.knows(voId) ?? false) && (fallback?.canLoad(voId) ?? false);
  }

  /// The clip, loading its pack first if it is not in memory. Null for a line with no recording, and for a line whose pack
  /// cannot be loaded: the same as a line that was never recorded.
  Future<VoiceClip?> fetch(String voId) async {
    final VoiceClip? own = _clips[voId] ?? await _lazy?.fetch(voId);
    return own ?? await fallback?.fetch(voId);
  }

  /// Loads the packs of the lines [voIds] ahead of their use (a lesson that is opening).
  Future<void> prefetch(Iterable<String> voIds) async {
    final List<String> ids = voIds.toList();
    await _lazy?.prefetch(ids);
    await fallback?.prefetch(ids);
  }
}
