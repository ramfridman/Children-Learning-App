import '../core/clock.dart';
import '../core/errors.dart';
import '../device/secure_store.dart';
import 'auth_client.dart';

/// Holds the current sign-in, keeps the refresh token in secure storage, and renews the access
/// token shortly before it expires.
class SessionManager {
  SessionManager({required AuthClient auth, required SecureStore store, required Clock clock})
    : _auth = auth,
      _store = store,
      _clock = clock;

  static const int _renewBeforeMs = 60 * 1000;

  final AuthClient _auth;
  final SecureStore _store;
  final Clock _clock;
  AuthSession? _session;

  Future<void> setSession(AuthSession session) async {
    _session = session;
    await _store.write(StoreKeys.refreshToken, session.refreshToken);
  }

  /// A valid access token, or null if the user has to sign in again.
  Future<String?> accessToken() async {
    final AuthSession? current = _session;
    if (current != null && current.expiresAtMs - _clock.nowMs() > _renewBeforeMs) {
      return current.accessToken;
    }
    final String? refreshToken = current?.refreshToken ?? await _store.read(StoreKeys.refreshToken);
    if (refreshToken == null) return null;
    try {
      final AuthSession renewed = await _auth.refresh(refreshToken);
      await setSession(renewed);
      return renewed.accessToken;
    } on GatewayException catch (e) {
      if (e.code == 'auth_failed') {
        await signOut();
        return null;
      }
      rethrow;
    }
  }

  Future<void> signOut() async {
    _session = null;
    await _store.delete(StoreKeys.refreshToken);
  }
}
