import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../ui/dev/dev_home_page.dart';
import '../ui/dev/dev_strings.dart';
import 'providers.dart';

/// Milestone 0: the dev flavour shows the device-chain harness; the prod flavour shows a blank
/// placeholder until the real app exists.
class NitznutzApp extends ConsumerWidget {
  const NitznutzApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool isDev = ref.watch(configProvider).isDev;
    return MaterialApp(
      title: 'Nitznutz',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(colorSchemeSeed: Colors.teal),
      home: isDev ? const DevHomePage() : const Scaffold(body: Center(child: Text(DevStrings.prodPlaceholder))),
    );
  }
}

/// Shown instead of the app when the build settings are wrong. Says nothing about the values.
class ConfigProblemApp extends StatelessWidget {
  const ConfigProblemApp({super.key});

  @override
  Widget build(BuildContext context) => const MaterialApp(
    home: Scaffold(body: Center(child: Text(DevStrings.configProblem))),
  );
}
