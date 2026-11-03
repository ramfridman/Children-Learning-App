import 'dart:typed_data';

import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show FutureProviderFamily;

import '../world/welcome_table.dart';

/// The welcome's lines and topic table, read once from `assets/lines/welcome.json`.
final FutureProvider<WelcomeTable> welcomeTableProvider = FutureProvider<WelcomeTable>(
  (Ref ref) async =>
      WelcomeTable.parse(await rootBundle.loadString('assets/lines/welcome.json', cache: false)),
);

/// Whether the daily welcome is given at all. Tests that are about something else switch it off, so that the first map of
/// the day shows what it always showed.
final Provider<bool> welcomeEnabledProvider = Provider<bool>((Ref ref) => true);

/// Whether the welcome is said aloud. There is no sound switch in the app yet; when there is one, it is read here, and the
/// welcome is then only shown (B42.md 2.4).
final Provider<bool> welcomeSpokenProvider = Provider<bool>((Ref ref) => true);

/// The sound of the child's name in the voice of the friend they chose, or null when there is none. Filled in by the name
/// path (B42.md 3.2); until a parent has made the clip it is null and the welcome plays without it.
final FutureProviderFamily<Uint8List?, String> nameClipProvider = FutureProvider.family<Uint8List?, String>(
  (Ref ref, String childId) async => null,
);
