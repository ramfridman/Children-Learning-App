import 'answer_matcher.dart';

/// Why a listen ended.
enum ListenEnd { silence, maxLength, early, cancelled, failed }

sealed class ListenEvent {
  const ListenEvent();
}

/// How loud the child is now, from 0 to 1 (draws the ring around the mic).
class ListenLevel extends ListenEvent {
  const ListenLevel(this.level);

  final double level;
}

/// What has been recognised so far. [stableMs] is how long the text has not changed.
class ListenPartial extends ListenEvent {
  const ListenPartial(this.text, this.confidence, this.stableMs);

  final String text;
  final double confidence;
  final int stableMs;
}

/// The end of a listen, with the readings of the speech (empty when nothing was heard).
class ListenDone extends ListenEvent {
  const ListenDone(this.hypotheses, this.reason);

  final List<Hypothesis> hypotheses;
  final ListenEnd reason;
}

/// Turns what the child says into text, on the device. The audio never leaves the engine: it is read from the
/// microphone in small pieces, held in memory only while the child speaks, and dropped.
abstract interface class SpeechEngine {
  /// The model is loaded and a listen can start now.
  bool get ready;

  /// The model files are on the phone (a quick look; they are checked completely by [prepare]).
  Future<bool> modelInstalled();

  /// Asks Android for the microphone permission. Only ever called from the parent's voice switch.
  Future<bool> requestPermission();

  /// Loads the model (once). Throws if its files are missing or do not match their pinned hashes.
  Future<void> prepare();

  /// Opens the microphone and listens until the child stops (after [silence] without speech), until [maxLength],
  /// or until [cancel]. The stream ends with exactly one [ListenDone]; the microphone is closed before it.
  Stream<ListenEvent> listen({required Duration silence, required Duration maxLength});

  /// Stops a listen now (the stream ends with a [ListenDone] of reason `cancelled`).
  Future<void> cancel();

  Future<void> dispose();
}
