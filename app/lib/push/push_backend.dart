/// How a request to start push ended on this phone.
enum PushStart { ready, denied, unavailable }

/// The phone's push service as the app sees it, so that the app's own rules (who may turn it on, what it does with a
/// message, what it sends the server) can be tested without Firebase. A push carries no data the app reads: a message
/// only means "look at the alerts", and the alerts themselves come from the server through the usual sync.
abstract class PushBackend {
  /// Starts the service. [askPermission] shows Android's own question about showing notifications; it is true only when a
  /// parent has just turned the switch on, never at app start.
  Future<PushStart> start({required bool askPermission});

  /// This phone's push address, or null when there is none.
  Future<String?> token();

  /// A new push address, after the service changed it.
  Stream<String> get tokenRefreshed;

  /// A message arrived while the app is open.
  Stream<void> get arrived;

  /// The parent tapped the notification while the app was in the background.
  Stream<void> get opened;

  /// The parent tapped the notification and so started the app.
  Future<bool> startedByNotification();

  /// Takes this phone off the push service.
  Future<void> stop();
}

/// Used on phones and builds where push does not exist (the child space, iOS for now, tests).
class NoPush implements PushBackend {
  const NoPush();

  @override
  Future<PushStart> start({required bool askPermission}) async => PushStart.unavailable;

  @override
  Future<String?> token() async => null;

  @override
  Stream<String> get tokenRefreshed => const Stream<String>.empty();

  @override
  Stream<void> get arrived => const Stream<void>.empty();

  @override
  Stream<void> get opened => const Stream<void>.empty();

  @override
  Future<bool> startedByNotification() async => false;

  @override
  Future<void> stop() async {}
}
