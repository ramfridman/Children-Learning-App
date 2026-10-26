import 'dart:async';

import 'package:nitznutz/speech/answer_matcher.dart';
import 'package:nitznutz/speech/speech_engine.dart';

/// What one listen of the fake engine does.
class Scripted {
  const Scripted._(this.partials, this.hypotheses, this.reason, this.fail, this.hang);

  /// The child says [text] with the recogniser's [confidence] (and nothing else).
  factory Scripted.says(String text, {double confidence = 0.9}) => Scripted._(
    const <ListenPartial>[],
    <Hypothesis>[Hypothesis(text, confidence)],
    ListenEnd.silence,
    false,
    false,
  );

  /// Several readings, best first.
  factory Scripted.nbest(List<Hypothesis> h) =>
      Scripted._(const <ListenPartial>[], h, ListenEnd.silence, false, false);

  /// Nothing is said.
  factory Scripted.silence() =>
      const Scripted._(<ListenPartial>[], <Hypothesis>[], ListenEnd.silence, false, false);

  /// The text settles after [stableMs] and then the listen would go on for ever (until cancelled).
  factory Scripted.settles(String text, {int stableMs = 700, double confidence = 0.9}) => Scripted._(
    <ListenPartial>[ListenPartial(text, confidence, stableMs)],
    const <Hypothesis>[],
    ListenEnd.silence,
    false,
    true,
  );

  /// The microphone cannot be opened.
  factory Scripted.fails() =>
      const Scripted._(<ListenPartial>[], <Hypothesis>[], ListenEnd.failed, true, false);

  /// The listen never ends by itself (the test cancels it).
  factory Scripted.hangs() =>
      const Scripted._(<ListenPartial>[], <Hypothesis>[], ListenEnd.silence, false, true);

  final List<ListenPartial> partials;
  final List<Hypothesis> hypotheses;
  final ListenEnd reason;
  final bool fail;
  final bool hang;
}

/// A recogniser that does what the test tells it, and counts what was asked of it.
class FakeSpeechEngine implements SpeechEngine {
  FakeSpeechEngine([Iterable<Scripted> script = const <Scripted>[]]) : _script = List<Scripted>.of(script);

  final List<Scripted> _script;
  final List<String> log = <String>[];
  bool _ready = false;
  bool failPrepare = false;
  int prepares = 0;
  int listens = 0;
  int cancels = 0;
  bool micOpen = false;
  Duration? lastSilence;
  Duration? lastMax;
  StreamController<ListenEvent>? _live;

  void add(Scripted s) => _script.add(s);

  @override
  bool get ready => _ready;

  bool installed = true;
  bool permission = true;

  @override
  Future<bool> modelInstalled() async => installed;

  @override
  Future<bool> requestPermission() async => permission;

  @override
  Future<void> prepare() async {
    prepares++;
    log.add('prepare');
    if (failPrepare) throw StateError('no model');
    _ready = true;
  }

  @override
  Stream<ListenEvent> listen({required Duration silence, required Duration maxLength}) {
    listens++;
    lastSilence = silence;
    lastMax = maxLength;
    log.add('listen');
    final Scripted s = _script.isEmpty ? Scripted.silence() : _script.removeAt(0);
    final StreamController<ListenEvent> c = StreamController<ListenEvent>();
    _live = c;
    micOpen = true;
    Future<void>(() async {
      if (s.fail) {
        micOpen = false;
        c.add(const ListenDone(<Hypothesis>[], ListenEnd.failed));
        await c.close();
        return;
      }
      c.add(const ListenLevel(0.5));
      for (final ListenPartial p in s.partials) {
        if (c.isClosed) return;
        c.add(p);
        await Future<void>.delayed(Duration.zero);
      }
      if (s.hang) return; // until cancel()
      if (c.isClosed) return;
      micOpen = false;
      c.add(ListenDone(s.hypotheses, s.reason));
      await c.close();
    });
    return c.stream;
  }

  @override
  Future<void> cancel() async {
    cancels++;
    final StreamController<ListenEvent>? c = _live;
    _live = null;
    if (c != null && !c.isClosed) {
      micOpen = false;
      c.add(const ListenDone(<Hypothesis>[], ListenEnd.cancelled));
      await c.close();
    }
  }

  @override
  Future<void> dispose() async {
    await cancel();
  }
}
