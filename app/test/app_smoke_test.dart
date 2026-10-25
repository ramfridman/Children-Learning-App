import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nitznutz/app/app.dart';
import 'package:nitznutz/app/providers.dart';

import 'support/fakes.dart';

void main() {
  testWidgets('the prod flavour shows only a placeholder, no harness', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          configProvider.overrideWithValue(testConfig()),
          hostsProvider.overrideWithValue(testHosts()),
        ],
        child: const NitznutzApp(),
      ),
    );
    expect(find.text('Nitznutz'), findsOneWidget);
    expect(find.text('Enrol as parent'), findsNothing);
  });

  testWidgets('the dev flavour shows the harness', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          configProvider.overrideWithValue(testConfig(dev: true)),
          hostsProvider.overrideWithValue(testHosts()),
          secureStoreProvider.overrideWithValue(MemoryStore()),
          deviceKeysProvider.overrideWithValue(FakeKeys()),
        ],
        child: const NitznutzApp(),
      ),
    );
    await tester.pump();
    expect(find.text('Enrolled device: none'), findsOneWidget);
    expect(find.byType(FilledButton), findsWidgets);
  });
}
