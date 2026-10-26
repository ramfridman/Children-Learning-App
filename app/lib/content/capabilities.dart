import '../core/config.dart' as config;
import 'schemas.dart';

/// Compares two versions written `major.minor.patch`; negative if [a] is older than [b].
/// Both must already have passed the `semver` pattern of the schemas.
int compareSemver(String a, String b) {
  final List<int> x = a.split('.').map(int.parse).toList();
  final List<int> y = b.split('.').map(int.parse).toList();
  for (int i = 0; i < 3; i++) {
    final int d = x[i] - y[i];
    if (d != 0) return d;
  }
  return 0;
}

/// Compares template versions written `major.minor`.
int compareTemplateVersion(String a, String b) {
  final List<int> x = a.split('.').map(int.parse).toList();
  final List<int> y = b.split('.').map(int.parse).toList();
  return x[0] != y[0] ? x[0] - y[0] : x[1] - y[1];
}

/// What this app can play: its own version and the template versions it has.
class AppCapabilities {
  const AppCapabilities({required this.appVersion, required this.templates});

  static const AppCapabilities current = AppCapabilities(
    appVersion: config.appVersion,
    templates: supportedTemplates,
  );

  final String appVersion;
  final Map<String, String> templates;

  /// Null if this app can play the pack the [manifest] describes, otherwise why not. A pack that
  /// cannot be played is still installed, but kept hidden, so an old app never meets content it
  /// does not understand.
  String? incompatibility(Map<String, Object?> manifest) {
    final String needs = manifest['minAppVersion']! as String;
    if (compareSemver(needs, appVersion) > 0) return 'needs app version $needs (this is $appVersion)';
    final Map<String, Object?> wanted = manifest['templates']! as Map<String, Object?>;
    for (final MapEntry<String, Object?> t in wanted.entries) {
      final String? have = templates[t.key];
      if (have == null) return 'needs the template ${t.key}, which this app does not have';
      if (compareTemplateVersion(t.value! as String, have) > 0) {
        return 'needs template ${t.key} ${t.value} (this app has $have)';
      }
    }
    return null;
  }
}
