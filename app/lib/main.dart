import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';
import 'app/providers.dart';
import 'core/config.dart';
import 'core/hosts.dart';
import 'play/hint_hand.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final NetworkHosts hosts = NetworkHosts.parse(await rootBundle.loadString('network_hosts.json'));
  final AppConfig config;
  try {
    config = AppConfig.fromEnvironment(hosts);
  } on ConfigException {
    runApp(const ConfigProblemApp());
    return;
  }
  // The hands of the hints are read once, here, so that the first hint a child asks for finds them ready.
  unawaited(warmHintHands());
  runApp(
    ProviderScope(
      overrides: [configProvider.overrideWithValue(config), hostsProvider.overrideWithValue(hosts)],
      child: const NitznutzApp(),
    ),
  );
}
