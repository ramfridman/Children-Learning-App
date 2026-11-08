import 'dart:convert';

import 'package:http/http.dart' as http;

import '../core/clock.dart';
import '../core/errors.dart';
import '../net/net_gate.dart';

/// A Supabase Auth session. Held in memory; only the refresh token is stored on the device.
class AuthSession {
  const AuthSession({required this.accessToken, required this.refreshToken, required this.expiresAtMs});

  final String accessToken;
  final String refreshToken;
  final int expiresAtMs;
}

/// A small hand-written client for the four Supabase Auth calls the app needs, so the app does not
/// carry the large Supabase SDK. Email code sign-in is for parents; `signInWithTokenHash` finishes
/// a child device's pairing.
class AuthClient {
  AuthClient({
    required Uri baseUrl,
    required String publishableKey,
    required NetGate gate,
    required Clock clock,
  }) : _base = baseUrl,
       _publishableKey = publishableKey,
       _gate = gate,
       _clock = clock;

  final Uri _base;
  final String _publishableKey;
  final NetGate _gate;
  final Clock _clock;

  /// Sends a 6-digit code by email. A new address becomes a new parent account (open sign-up, owner,
  /// 2026-11-08); the server's "Allow new users to sign up" switch decides, and every other call still
  /// needs an enrolled device. The same code flow signs a returning parent in. An address the owner did
  /// not invite is refused by the sign-up hook with 403 (or 422); that is `not_invited`, and only the
  /// status is read, never the server's text.
  Future<void> sendEmailCode(String email) async {
    try {
      await _post('/auth/v1/otp', <String, Object?>{'email': email, 'create_user': true});
    } on GatewayException catch (e) {
      if (e.status == 403 || e.status == 422) throw GatewayException('not_invited', status: e.status);
      rethrow;
    }
  }

  Future<AuthSession> verifyEmailCode(String email, String code) async {
    final Map<String, Object?> json = await _post('/auth/v1/verify', <String, Object?>{
      'type': 'email',
      'email': email,
      'token': code,
    });
    return _session(json);
  }

  /// The one-time token a freshly paired child device receives from `device-pair`.
  Future<AuthSession> signInWithTokenHash(String tokenHash) async {
    final Map<String, Object?> json = await _post('/auth/v1/verify', <String, Object?>{
      'type': 'magiclink',
      'token_hash': tokenHash,
    });
    return _session(json);
  }

  Future<AuthSession> refresh(String refreshToken) async {
    final Map<String, Object?> json = await _post(
      '/auth/v1/token',
      <String, Object?>{'refresh_token': refreshToken},
      query: <String, String>{'grant_type': 'refresh_token'},
    );
    return _session(json);
  }

  AuthSession _session(Map<String, Object?> json) {
    final Object? access = json['access_token'];
    final Object? refresh = json['refresh_token'];
    final Object? expiresIn = json['expires_in'];
    if (access is! String || refresh is! String || expiresIn is! num) {
      throw const GatewayException('bad_response');
    }
    return AuthSession(
      accessToken: access,
      refreshToken: refresh,
      expiresAtMs: _clock.nowMs() + expiresIn.toInt() * 1000,
    );
  }

  Future<Map<String, Object?>> _post(
    String path,
    Map<String, Object?> body, {
    Map<String, String>? query,
  }) async {
    final Uri uri = _base.replace(path: path, queryParameters: query);
    final http.Response response = await _gate.post(
      uri,
      headers: <String, String>{'content-type': 'application/json; charset=utf-8', 'apikey': _publishableKey},
      body: utf8.encode(jsonEncode(body)),
    );
    if (response.statusCode >= 400) {
      throw GatewayException(
        response.statusCode == 429 ? 'rate_limited' : 'auth_failed',
        status: response.statusCode,
      );
    }
    final Object? decoded;
    try {
      decoded = jsonDecode(utf8.decode(response.bodyBytes));
    } on FormatException {
      // The email-code request answers with an empty or small body; that is fine.
      return <String, Object?>{};
    }
    return decoded is Map<String, dynamic> ? Map<String, Object?>.from(decoded) : <String, Object?>{};
  }
}
