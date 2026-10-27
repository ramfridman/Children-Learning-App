// The server sends with the FCM v1 `token` field, which takes the classic registration token. The newer `register()` and
// `onRegistered` give a Firebase Installation ID for a different way of sending, so this file keeps the classic calls
// (marked deprecated by the package) until the server is moved to the new way and proved on a phone.
// ignore_for_file: deprecated_member_use
import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import 'push_backend.dart';

/// Firebase Cloud Messaging on Android. Firebase is started here, on a parent's phone that asked for push, and nowhere
/// else: the manifest keeps the library from registering the phone by itself. A build without its Firebase client file
/// (see `android/app/build.gradle.kts`) cannot start it, which is reported as "unavailable".
class FirebasePush implements PushBackend {
  FirebaseMessaging? _fcm;

  Future<FirebaseMessaging?> _open() async {
    if (_fcm != null) return _fcm;
    if (!Platform.isAndroid) return null;
    try {
      await Firebase.initializeApp();
      return _fcm = FirebaseMessaging.instance;
    } on Object {
      return null;
    }
  }

  @override
  Future<PushStart> start({required bool askPermission}) async {
    final FirebaseMessaging? fcm = await _open();
    if (fcm == null) return PushStart.unavailable;
    try {
      if (askPermission) {
        final NotificationSettings s = await fcm.requestPermission(
          alert: true,
          badge: false,
          sound: false,
          provisional: false,
        );
        if (s.authorizationStatus != AuthorizationStatus.authorized) return PushStart.denied;
      }
      await fcm.setAutoInitEnabled(true);
      return PushStart.ready;
    } on Object {
      return PushStart.unavailable;
    }
  }

  @override
  Future<String?> token() async {
    try {
      return await _fcm?.getToken();
    } on Object {
      return null;
    }
  }

  @override
  Stream<String> get tokenRefreshed => _fcm?.onTokenRefresh ?? const Stream<String>.empty();

  @override
  Stream<void> get arrived => FirebaseMessaging.onMessage.map((RemoteMessage _) {});

  @override
  Stream<void> get opened => FirebaseMessaging.onMessageOpenedApp.map((RemoteMessage _) {});

  @override
  Future<void> stop() async {
    try {
      await _fcm?.deleteToken();
      await _fcm?.setAutoInitEnabled(false);
    } on Object {
      // The phone is off the server's list either way (the caller removed it there first).
    }
  }
}
