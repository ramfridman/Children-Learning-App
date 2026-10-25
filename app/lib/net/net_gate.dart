import 'dart:async';

import 'package:http/http.dart' as http;

import '../core/errors.dart';
import '../core/hosts.dart';

/// Every request in the app leaves through here. A URL whose host is not in
/// `network_hosts.json` is refused before anything is sent.
class NetGate {
  NetGate({
    required http.Client client,
    required NetworkHosts hosts,
    this.timeout = const Duration(seconds: 15),
  }) : _client = client,
       _hosts = hosts;

  final http.Client _client;
  final NetworkHosts _hosts;
  final Duration timeout;

  Future<http.Response> post(Uri uri, {required Map<String, String> headers, required List<int> body}) async {
    if (!_hosts.allows(uri)) throw const GatewayException('host_not_allowed');
    try {
      return await _client.post(uri, headers: headers, body: body).timeout(timeout);
    } on TimeoutException {
      throw const GatewayException('network');
    } on http.ClientException {
      throw const GatewayException('network');
    }
  }
}
