import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nitznutz/design/layout.dart';
import 'package:nitznutz/design/theme.dart';
import 'package:nitznutz/design/token_types.dart';
import 'package:nitznutz/strings/he.dart';

/// Loads the two real font files so that tests (and golden screenshots) draw Hebrew with Heebo and
/// Secular One instead of the test font's blocks.
Future<void> loadAppFonts() async {
  Future<void> load(String family, String path) async {
    final FontLoader loader = FontLoader(family)
      ..addFont(Future<ByteData>.value(ByteData.sublistView(File(path).readAsBytesSync())));
    await loader.load();
  }

  await load('Heebo', 'assets/fonts/Heebo-Variable.ttf');
  // The Material icon font is not loaded by flutter test; take it from the SDK so icons are drawn in screenshots.
  final String? sdk = Platform.environment['FLUTTER_ROOT'];
  if (sdk != null) {
    final String icons = '$sdk/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf';
    if (File(icons).existsSync()) await load('MaterialIcons', icons);
  }
  await load('SecularOne', 'assets/fonts/SecularOne-Regular.ttf');
}

/// Pumps [child] the way the app shows it: Hebrew locale (so the layout is right to left), the
/// child or parent theme, and the layout scope for the given [band].
Future<void> pumpScreen(
  WidgetTester tester,
  Widget child, {
  Size size = const Size(852, 393),
  Band band = Band.b,
  bool parent = false,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      locale: const Locale('he'),
      supportedLocales: const <Locale>[Locale('he')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      theme: parent ? AppTheme.parent() : AppTheme.child(),
      home: Builder(
        builder: (BuildContext context) => LayoutScope(
          band: band,
          child: Scaffold(body: child),
        ),
      ),
    ),
  );
  await tester.pump();
}

/// Taps the counting hills on the map and then the play button of its island: since M8 a land opens as an island first,
/// with its objects growing, and the lesson is one tap further.
Future<void> openCountingLesson(WidgetTester tester) async {
  await tester.tap(find.text(He.landCounting.text));
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(const Key('land-play')));
}
