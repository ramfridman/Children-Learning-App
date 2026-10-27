import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nitznutz/characters/character.dart';
import 'package:nitznutz/characters/character_view.dart';
import 'package:nitznutz/content/pack_verify.dart';

import '../tool/pack_builder_lib.dart';
import 'support/character_fixtures.dart';
import 'support/harness.dart';
import 'support/pack_fixtures.dart';

Uint8List _bytesOf(WidgetTester tester) {
  final Image image = tester.widget<Image>(find.byType(Image));
  return (image.image as MemoryImage).bytes;
}

Widget _host(Widget child, {bool reduced = false, double size = 300}) => MediaQuery(
  data: MediaQueryData(disableAnimations: reduced),
  child: Directionality(
    textDirection: TextDirection.rtl,
    child: Center(
      child: SizedBox(width: size, height: size, child: child),
    ),
  ),
);

void main() {
  late Character hero;
  late Character nitzi;

  setUpAll(() async {
    await loadAppFonts();
    final PackKey key = await newTestKey();
    final Directory tmp = Directory.systemTemp.createTempSync('nn_view_');
    hero = Character.fromPack(
      await verifyPack(
        (await buildCharacterPack(writeCharacterFolder(tmp, 'hero-son'), key)).bytes,
        publicKey: key.publicKey,
      ),
    );
    nitzi = Character.fromPack(
      await verifyPack(
        File('assets/characters/char-nitzi-1.0.0.nnpack').readAsBytesSync(),
        publicKey: unhex(File('assets/pack_signing_public_key.txt').readAsStringSync()),
      ),
    );
    try {
      tmp.deleteSync(recursive: true);
    } on FileSystemException {
      // Left for the system.
    }
  });

  testWidgets('shows the picture of each state (family character: PNG)', (WidgetTester tester) async {
    for (final (CharacterState, String) s in <(CharacterState, String)>[
      (CharacterState.idle, 'idle'),
      (CharacterState.listen, 'listen'),
      (CharacterState.think, 'think'),
      (CharacterState.encourage, 'encourage'),
      (CharacterState.celebrate, 'celebrate'),
    ]) {
      await tester.pumpWidget(_host(CharacterView(character: hero, state: s.$1)));
      await tester.pump(const Duration(milliseconds: 300));
      expect(_bytesOf(tester), hero.images[s.$2]!.png, reason: s.$2);
    }
    // States the character has no picture for borrow a close one.
    await tester.pumpWidget(_host(CharacterView(character: hero, state: CharacterState.sleepy)));
    await tester.pump(const Duration(milliseconds: 300));
    expect(_bytesOf(tester), hero.images['idle']!.png);
    await tester.pumpWidget(_host(const SizedBox()));
  });

  testWidgets('the mouth: talk with the mouth open and closed show two different pictures, without a fade', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(_host(CharacterView(character: hero, state: CharacterState.talk)));
    await tester.pump(const Duration(milliseconds: 300));
    expect(_bytesOf(tester), hero.images['talk_closed']!.png);
    await tester.pumpWidget(
      _host(CharacterView(character: hero, state: CharacterState.talk, mouthOpen: true)),
    );
    await tester.pump();
    expect(_bytesOf(tester), hero.images['talk_open']!.png);
    expect(
      find.byType(Image),
      findsOneWidget,
      reason: 'one picture at a time while the mouth flaps: no cross-fade',
    );
    await tester.pumpWidget(_host(const SizedBox()));
  });

  testWidgets('Nitzi is drawn from her vector pictures, and her mouth flaps too', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(_host(CharacterView(character: nitzi, state: CharacterState.talk)));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byType(SvgPicture), findsOneWidget);
    final String closed = (tester.widget<SvgPicture>(find.byType(SvgPicture)).bytesLoader as SvgStringLoader)
        .provideSvg(null);
    await tester.pumpWidget(
      _host(CharacterView(character: nitzi, state: CharacterState.talk, mouthOpen: true)),
    );
    await tester.pump();
    final String open = (tester.widget<SvgPicture>(find.byType(SvgPicture)).bytesLoader as SvgStringLoader)
        .provideSvg(null);
    expect(open, isNot(closed));
    expect(open, nitzi.images['talk_open']!.svg);
    await tester.pumpWidget(_host(const SizedBox()));
  });

  testWidgets('it breathes: the picture moves a little over time, and celebrating adds a hop and sparks', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(_host(CharacterView(character: hero)));
    final List<Matrix4> seen = <Matrix4>[];
    for (int i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 500));
      seen.add(
        tester
            .widget<Transform>(
              find.descendant(of: find.byType(CharacterView), matching: find.byType(Transform)).first,
            )
            .transform
            .clone(),
      );
    }
    expect(seen.map((Matrix4 m) => m.storage[5].toStringAsFixed(4)).toSet().length, greaterThan(2));
    final int paintsBefore = find.byType(CustomPaint).evaluate().length;
    await tester.pumpWidget(_host(CharacterView(character: hero, state: CharacterState.celebrate)));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byType(CustomPaint).evaluate().length, greaterThan(paintsBefore), reason: 'the sparks');
    await tester.pump(const Duration(milliseconds: 900));
    await tester.pump();
    await tester.pumpWidget(_host(const SizedBox()));
  });

  testWidgets('with "reduce motion" nothing moves: no breathing, no hop, no sparks, only a cross-fade', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(_host(CharacterView(character: hero), reduced: true));
    await tester.pump(const Duration(seconds: 2));
    expect(tester.hasRunningAnimations, isFalse, reason: 'a still picture asks for no frames');
    await tester.pumpWidget(
      _host(CharacterView(character: hero, state: CharacterState.celebrate), reduced: true),
    );
    await tester.pump(const Duration(milliseconds: 300));
    expect(
      find
          .byType(CustomPaint)
          .evaluate()
          .where((Element e) => e.widget is CustomPaint && (e.widget as CustomPaint).painter != null)
          .isEmpty,
      isTrue,
    );
    await tester.pump(const Duration(seconds: 1));
    expect(_bytesOf(tester), hero.images['celebrate']!.png);
    await tester.pumpWidget(_host(const SizedBox()));
  });

  testWidgets('it has a Hebrew name for a screen reader, and takes a label of its own', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(_host(CharacterView(character: nitzi)));
    expect(find.bySemanticsLabel('נִיצִי'), findsOneWidget);
    await tester.pumpWidget(_host(CharacterView(character: nitzi, semanticLabel: 'המדריכה')));
    expect(find.bySemanticsLabel('המדריכה'), findsOneWidget);
    await tester.pumpWidget(_host(const SizedBox()));
  });

  testWidgets('frame cost: a talking, breathing, hopping guide builds and paints well inside a 16 ms frame', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(_host(CharacterView(character: hero, state: CharacterState.celebrate)));
    final Stopwatch sw = Stopwatch();
    int frames = 0;
    final List<int> micros = <int>[];
    for (int i = 0; i < 240; i++) {
      // Every few frames the mouth flaps and the state changes, the heaviest thing the view does.
      final CharacterState state = i % 60 < 30 ? CharacterState.talk : CharacterState.celebrate;
      await tester.pumpWidget(_host(CharacterView(character: hero, state: state, mouthOpen: i.isOdd)));
      sw.reset();
      sw.start();
      await tester.pump(const Duration(milliseconds: 16));
      sw.stop();
      micros.add(sw.elapsedMicroseconds);
      frames++;
    }
    micros.sort();
    final double mean = micros.reduce((int a, int b) => a + b) / frames / 1000;
    final double p95 = micros[(frames * 0.95).floor()] / 1000;
    // ignore: avoid_print
    print(
      'character frame cost on this PC: mean ${mean.toStringAsFixed(2)} ms, 95th percentile ${p95.toStringAsFixed(2)} ms over $frames frames',
    );
    expect(
      p95,
      lessThan(8),
      reason: 'half a frame, to leave room for a phone that is several times slower than a PC',
    );
    await tester.pumpWidget(_host(const SizedBox()));
  });
}
