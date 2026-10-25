import 'dart:convert';

/// The hosts this app may contact, read from `network_hosts.json`. Every request goes through
/// [allows] before it leaves the phone.
class NetworkHosts {
  const NetworkHosts(this._hosts);

  /// Parses the JSON asset. Throws [FormatException] if it is malformed.
  factory NetworkHosts.parse(String source) {
    final Object? root = jsonDecode(source);
    if (root is! Map<String, dynamic>) throw const FormatException('hosts: not an object');
    final Object? list = root['hosts'];
    if (list is! List<dynamic> || list.isEmpty) throw const FormatException('hosts: empty');
    final Set<String> names = <String>{};
    for (final Object? entry in list) {
      if (entry is! Map<String, dynamic>) throw const FormatException('hosts: bad entry');
      final Object? host = entry['host'];
      final Object? scheme = entry['scheme'];
      if (host is! String || host.isEmpty || scheme != 'https') {
        throw const FormatException('hosts: only https hosts are allowed');
      }
      names.add(host.toLowerCase());
    }
    return NetworkHosts(names);
  }

  final Set<String> _hosts;

  bool allows(Uri uri) {
    if (uri.scheme != 'https') return false;
    if (uri.hasPort && uri.port != 443) return false;
    if (uri.userInfo.isNotEmpty) return false;
    return _hosts.contains(uri.host.toLowerCase());
  }
}
