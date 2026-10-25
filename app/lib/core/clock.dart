/// The only source of "now" for signing, so tests can set the time.
abstract interface class Clock {
  int nowMs();
}

class SystemClock implements Clock {
  const SystemClock();

  @override
  int nowMs() => DateTime.now().millisecondsSinceEpoch;
}
