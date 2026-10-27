import 'dart:convert';

import 'hosts.dart';

class ConfigException implements Exception {
  const ConfigException(this.message);
  final String message;

  @override
  String toString() => 'ConfigException($message)';
}

/// Build-time settings, passed with `--dart-define-from-file=config/dev.local.json`.
/// The app holds only the project URL and the publishable key. A secret key is refused.
class AppConfig {
  const AppConfig({required this.supabaseUrl, required this.publishableKey, required this.isDev});

  factory AppConfig.fromEnvironment(NetworkHosts hosts) => AppConfig.parse(
    url: const String.fromEnvironment('SUPABASE_URL'),
    key: const String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY'),
    flavor: const String.fromEnvironment('FLAVOR', defaultValue: 'prod'),
    hosts: hosts,
  );

  factory AppConfig.parse({
    required String url,
    required String key,
    required String flavor,
    required NetworkHosts hosts,
  }) {
    final Uri? uri = Uri.tryParse(url);
    if (uri == null || !hosts.allows(uri)) {
      throw const ConfigException('SUPABASE_URL is missing or not in network_hosts.json');
    }
    if (key.isEmpty || key.contains(' ') || key.startsWith('paste')) {
      throw const ConfigException('SUPABASE_PUBLISHABLE_KEY is missing');
    }
    if (key.startsWith('sb_secret_') || _isServiceRoleJwt(key)) {
      throw const ConfigException('a secret key must never be put in the app');
    }
    if (flavor != 'dev' && flavor != 'prod') throw const ConfigException('FLAVOR must be dev or prod');
    return AppConfig(
      supabaseUrl: Uri(scheme: 'https', host: uri.host),
      publishableKey: key,
      isDev: flavor == 'dev',
    );
  }

  final Uri supabaseUrl;
  final String publishableKey;
  final bool isDev;

  static bool _isServiceRoleJwt(String key) {
    final List<String> parts = key.split('.');
    if (parts.length != 3) return false;
    try {
      final Object? payload = jsonDecode(utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))));
      return payload is Map<String, dynamic> && payload['role'] == 'service_role';
    } on FormatException {
      return false;
    }
  }
}

/// The version string sent at enrolment (letters, digits and `._+-` only).
const String appVersion = String.fromEnvironment('APP_VERSION', defaultValue: '0.3.0');
