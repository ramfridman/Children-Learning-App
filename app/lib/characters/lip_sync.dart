/// When the mouth of a spoken line is open, from its cue file: a list of (time in ms, open) switches.
class MouthTrack {
  MouthTrack(List<(int, bool)> cues) : _cues = List<(int, bool)>.of(cues);

  /// From the `cues` of a `cue.<line>.json`: `[{t: 0, o: 0}, {t: 120, o: 1}, ...]`.
  factory MouthTrack.fromJson(List<Object?> cues) => MouthTrack(<(int, bool)>[
    for (final Object? c in cues)
      ((c! as Map<String, Object?>)['t']! as int, (c as Map<String, Object?>)['o'] == 1),
  ]);

  final List<(int, bool)> _cues;

  int get length => _cues.length;

  /// How long the track says anything about, in milliseconds (the time of its last switch).
  int get lastMs => _cues.isEmpty ? 0 : _cues.last.$1;

  /// Whether the mouth should be open [ms] milliseconds into the line. Before the first cue it is closed.
  bool openAt(int ms) {
    int lo = 0;
    int hi = _cues.length - 1;
    bool open = false;
    while (lo <= hi) {
      final int mid = (lo + hi) ~/ 2;
      if (_cues[mid].$1 <= ms) {
        open = _cues[mid].$2;
        lo = mid + 1;
      } else {
        hi = mid - 1;
      }
    }
    return open;
  }
}

/// Keeps a mouth from flickering: it changes at most once per [minHoldMs], however fast the cues switch.
class MouthFlap {
  MouthFlap({this.minHoldMs = 70});

  final int minHoldMs;
  bool _open = false;
  int _changedAt = -1 << 30;

  bool get open => _open;

  /// The mouth at [nowMs] (any steady clock) when the cues want it [wanted].
  bool update(int nowMs, bool wanted) {
    if (wanted != _open && nowMs - _changedAt >= minHoldMs) {
      _open = wanted;
      _changedAt = nowMs;
    }
    return _open;
  }

  void reset() {
    _open = false;
    _changedAt = -1 << 30;
  }
}
