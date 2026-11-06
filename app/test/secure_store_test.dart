// SEC-B29-2 (the Dart part): every item in secure storage sits in the iOS Keychain for this device only and is never synced.
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nitznutz/device/secure_store.dart';

void main() {
  test('the iOS options are first-unlock, this device only, and not synchronizable', () {
    expect(iosSecureOptions.accessibility, KeychainAccessibility.first_unlock_this_device);
    expect(iosSecureOptions.synchronizable, isFalse);
    expect(iosSecureOptions.toMap()['accessibility'], 'first_unlock_this_device');
    expect(iosSecureOptions.toMap()['synchronizable'], 'false');
  });

  test('the store every part of the app gets uses them on every call', () {
    final FlutterSecureStorage used = PlatformSecureStore().storage;
    expect(used.iOptions.accessibility, KeychainAccessibility.first_unlock_this_device);
    expect(used.iOptions.synchronizable, isFalse);
    expect(identical(used, platformSecureStorage), isTrue);
  });
}
