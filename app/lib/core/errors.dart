/// A failed call to our own backend. [code] is one of the gateway's public codes
/// (`unauthorized`, `clock_skew`, `rate_limited`, ...) or one of the client-side codes
/// `network`, `host_not_allowed`, `bad_response`, `auth_failed`. It never carries user data.
class GatewayException implements Exception {
  const GatewayException(this.code, {this.status, this.serverTimeMs});

  final String code;
  final int? status;
  final int? serverTimeMs;

  @override
  String toString() => 'GatewayException($code${status == null ? '' : ', $status'})';
}
