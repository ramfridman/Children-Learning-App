// B-42 part (d): the parent area's "how the name is said", end to end inside the real app with a mock gateway: the parent
// writes the spelling, taps "listen", hears the clip; the clip is kept on the phone; the friend then says the name before
// the welcome's greeting and before the map bubble's clip; a wrong spelling, an off switch, a cap and no network are told
// calmly; nothing is made until the parent taps.
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:nitznutz/app/push_providers.dart' show isParentDeviceProvider;
import 'package:nitznutz/app/welcome_providers.dart';
import 'package:nitznutz/child/home_screen.dart';
import 'package:nitznutz/design/components.dart';
import 'package:nitznutz/parent/name_spoken_screen.dart';
import 'package:nitznutz/strings/he.dart';
import 'package:nitznutz/voice/name_clips.dart';

import 'support/app_harness.dart';
import 'support/companion_fixtures.dart';
import 'support/harness.dart';
import 'support/voice_fixtures.dart';

const String spelling = 'נֹעָה';

/// Lines the friend needs: the welcome's (a few are enough: the new child's first day) and the bubble's shared clip.
const List<String> lines = <String>[
  'welcome.hello.first',
  'welcome.close',
  'core.home.bubble',
  'core.greeting.hello',
];

Future<AppRig> rigWith({
  FakePlayer? player,
  FakeNameVoice? voice,
  bool welcome = false,
  bool childDevice = false,
}) async {
  final FakePlayer p = player ?? FakePlayer();
  final List<String> ids = <String>[...lines, for (final String id in welcomeTopicIds) id];
  return AppRig(
    welcome: welcome,
    player: p,
    characters: await sourceWithLines(ids),
    extraOverrides: <Override>[
      if (voice != null) nameVoiceProvider.overrideWithValue(voice),
      if (childDevice) isParentDeviceProvider.overrideWith((Ref ref) async => false),
    ],
  );
}

/// The lines of the welcome (ids without `vo:`): any of them is in the voice, so the welcome is voiced whatever it names.
final List<String> welcomeTopicIds = <String>[
  for (final String id
      in ((jsonDecode(File('assets/lines/welcome.json').readAsStringSync()) as Map<String, Object?>)['lines']!
              as Map<String, Object?>)
          .keys)
    id.substring('vo:'.length),
];

/// What a sound says: the fixtures make every clip a small text that names its character and line.
String said(Uint8List sound) => utf8.decode(sound);

Future<void> toParentArea(WidgetTester tester, AppRig rig) async {
  await rig.seedFinishedSetup();
  await rig.pump(tester);
  await tester.tap(find.text('נועה'));
  await tester.pumpAndSettle();
  await tester.tap(find.text(He.homeParents.text));
  await tester.pumpAndSettle();
  await tapDigits(tester, '${rig.gateQuestion.answer}');
  await tester.tap(find.text(He.pinOk.text));
  await tester.pumpAndSettle();
  await tapDigits(tester, testPin);
  await tester.tap(find.text(He.pinOk.text));
  await tester.pumpAndSettle();
}

Future<void> openSpelling(WidgetTester tester) async {
  final Finder button = find.byKey(const Key('name-spoken-p-1'));
  await tester.ensureVisible(button);
  await tester.pumpAndSettle();
  await tester.tap(button);
  await tester.pumpAndSettle();
  expect(find.byType(NameSpokenScreen), findsOneWidget);
}

String note(WidgetTester tester) => tester.widget<Text>(find.byKey(const Key('name-spoken-note'))).data!;

void main() {
  setUpAll(loadAppFonts);

  testWidgets(
    'listen: the spelling is saved with the child, the gateway is asked with two ids, the clip is kept and heard',
    (WidgetTester tester) async {
      final FakeNameVoice voice = FakeNameVoice();
      final FakePlayer player = FakePlayer();
      final AppRig rig = await rigWith(player: player, voice: voice);
      await toParentArea(tester, rig);
      await openSpelling(tester);
      expect(voice.asked, isEmpty, reason: 'nothing is made until the parent taps');
      await tester.enterText(find.byKey(const Key('name-spoken-field')), spelling);
      await tester.pump();
      await tester.tap(find.byKey(const Key('name-spoken-listen')));
      await tester.pumpAndSettle();

      expect(voice.asked, hasLength(1));
      expect(voice.asked.single.childId, 'p-1');
      expect(
        voice.asked.single.characterId,
        'nitzi',
        reason: 'the voice of the friend the child chose (Nitzi by default)',
      );
      expect(await rig.db.nameSpokenOf('p-1'), spelling);
      expect(await nameClipFor(rig.db, 'p-1', 'nitzi'), voice.sound, reason: 'kept on this phone');
      expect(player.played, <Object?>[voice.sound], reason: 'and played, so the parent hears it first');
      expect(note(tester), He.nameSpokenHeard.text);
    },
  );

  testWidgets('when the server voiced an older spelling, the clip is not kept as the new one (SEC-B42-3)', (
    WidgetTester tester,
  ) async {
    final FakeNameVoice voice = FakeNameVoice(spelling: 'נועה');
    final AppRig rig = await rigWith(voice: voice);
    await toParentArea(tester, rig);
    await openSpelling(tester);
    await tester.enterText(find.byKey(const Key('name-spoken-field')), spelling);
    await tester.pump();
    await tester.tap(find.byKey(const Key('name-spoken-listen')));
    await tester.pumpAndSettle();
    expect(voice.asked, hasLength(1), reason: 'the gateway was asked');
    expect(note(tester), He.nameSpokenNotYet.text);
    expect(await rig.db.select(rig.db.nameClips).get(), isEmpty, reason: 'and nothing was kept');
    expect(await rig.db.nameSpokenOf('p-1'), spelling, reason: 'the new spelling itself is saved');
    voice.spelling = spelling;
    await tester.tap(find.byKey(const Key('name-spoken-listen')));
    await tester.pumpAndSettle();
    expect(note(tester), He.nameSpokenHeard.text, reason: 'once the server has it, the clip is kept');
    expect(await rig.db.select(rig.db.nameClips).get(), hasLength(1));
  });

  testWidgets('a child device has no "how the name is said" button (O1)', (WidgetTester tester) async {
    final AppRig rig = await rigWith(voice: FakeNameVoice(), childDevice: true);
    await toParentArea(tester, rig);
    expect(find.byKey(const Key('name-spoken-p-1')), findsNothing);
  });

  testWidgets('a parent device has it (O1)', (WidgetTester tester) async {
    final AppRig rig = await rigWith(voice: FakeNameVoice());
    await toParentArea(tester, rig);
    await tester.ensureVisible(find.byKey(const Key('name-spoken-p-1')));
    expect(find.byKey(const Key('name-spoken-p-1')), findsOneWidget);
  });

  testWidgets('a spelling outside the rule is told at once and cannot be listened to; nothing is asked', (
    WidgetTester tester,
  ) async {
    final FakeNameVoice voice = FakeNameVoice();
    final AppRig rig = await rigWith(voice: voice);
    await toParentArea(tester, rig);
    await openSpelling(tester);
    await tester.enterText(find.byKey(const Key('name-spoken-field')), 'Noa');
    await tester.pump();
    expect(note(tester), He.nameSpokenBadChars.text);
    await tester.tap(find.byKey(const Key('name-spoken-listen')), warnIfMissed: false);
    await tester.pumpAndSettle();
    expect(voice.asked, isEmpty);
    await tester.enterText(find.byKey(const Key('name-spoken-field')), 'א' * 25);
    await tester.pump();
    expect(note(tester), He.nameSpokenTooLong.text);
    await tester.enterText(find.byKey(const Key('name-spoken-field')), '');
    await tester.pump();
    expect(find.byKey(const Key('name-spoken-note')), findsNothing);
    expect(
      tester.widget<ParentButton>(find.byKey(const Key('name-spoken-listen'))).onPressed,
      isNull,
      reason: 'an empty field has nothing to listen to',
    );
  });

  for (final (NameVoiceFailure failure, String text) in <(NameVoiceFailure, String)>[
    (NameVoiceFailure.off, He.nameSpokenOff.text),
    (NameVoiceFailure.cap, He.nameSpokenCap.text),
    (NameVoiceFailure.unreachable, He.nameSpokenOffline.text),
    (NameVoiceFailure.notThere, He.nameSpokenOffline.text),
  ]) {
    testWidgets('when the gateway says ${failure.name} the parent is told so calmly, and no clip is kept', (
      WidgetTester tester,
    ) async {
      final FakeNameVoice voice = FakeNameVoice()..fail = failure;
      final AppRig rig = await rigWith(voice: voice);
      await toParentArea(tester, rig);
      await openSpelling(tester);
      await tester.enterText(find.byKey(const Key('name-spoken-field')), spelling);
      await tester.pump();
      await tester.tap(find.byKey(const Key('name-spoken-listen')));
      await tester.pumpAndSettle();
      expect(note(tester), text);
      expect(await rig.db.select(rig.db.nameClips).get(), isEmpty);
      expect(await rig.db.nameSpokenOf('p-1'), spelling, reason: 'the spelling itself is saved');
    });
  }

  testWidgets(
    'save without listening keeps the spelling and makes nothing; an empty field clears it and the clip',
    (WidgetTester tester) async {
      final FakeNameVoice voice = FakeNameVoice();
      final AppRig rig = await rigWith(voice: voice);
      await toParentArea(tester, rig);
      await openSpelling(tester);
      await tester.enterText(find.byKey(const Key('name-spoken-field')), spelling);
      await tester.pump();
      await tester.tap(find.byKey(const Key('name-spoken-save')));
      await tester.pumpAndSettle();
      expect(await rig.db.nameSpokenOf('p-1'), spelling);
      expect(voice.asked, isEmpty);
      expect(note(tester), He.nameSpokenSaved.text);

      await tester.tap(find.byKey(const Key('name-spoken-listen')));
      await tester.pumpAndSettle();
      expect(await rig.db.select(rig.db.nameClips).get(), hasLength(1));
      await tester.enterText(find.byKey(const Key('name-spoken-field')), '');
      await tester.pump();
      await tester.tap(find.byKey(const Key('name-spoken-save')));
      await tester.pumpAndSettle();
      expect(await rig.db.nameSpokenOf('p-1'), isNull);
      expect(await rig.db.select(rig.db.nameClips).get(), isEmpty, reason: 'no spelling, no clip');
    },
  );

  testWidgets('with the clip made, the welcome says the name first and then the greeting', (
    WidgetTester tester,
  ) async {
    final FakePlayer player = FakePlayer()..endsAfter = const Duration(milliseconds: 400);
    final FakeNameVoice voice = FakeNameVoice();
    final AppRig rig = await rigWith(player: player, voice: voice, welcome: true);
    await rig.seedFinishedSetup();
    await rig.db.setNameSpoken('p-1', spelling);
    await rig.db.putNameClip(
      profileId: 'p-1',
      characterId: 'nitzi',
      spellingHash: spellingHash(spelling),
      sound: voice.sound,
      at: DateTime.utc(2026, 11, 3),
    );
    await rig.pump(tester);
    await tester.tap(find.text('נועה'));
    for (int i = 0; i < 80; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    final List<String> heard = <String>[for (final Uint8List b in player.played) said(b)];
    expect(heard.first, said(voice.sound), reason: 'the name first');
    expect(heard[1], 'mp3:nitzi:welcome.hello.first');
    expect(heard.where((String s) => s == said(voice.sound)), hasLength(1), reason: 'once');
  });

  testWidgets(
    'a touch on the friend says the name and the bubble\'s shared clip once the name clip is made, its hello before',
    (WidgetTester tester) async {
      final FakePlayer player = FakePlayer()..endsAfter = const Duration(milliseconds: 300);
      final FakeNameVoice voice = FakeNameVoice();
      final AppRig rig = await rigWith(player: player, voice: voice);
      await rig.seedFinishedSetup();
      await rig.pump(tester);
      await tester.tap(find.text('נועה'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('home-companion')));
      await tester.pump(const Duration(seconds: 2));
      expect(
        <String>[for (final Uint8List b in player.played) said(b)],
        <String>['mp3:nitzi:core.greeting.hello'],
      );

      await rig.db.setNameSpoken('p-1', spelling);
      await rig.db.putNameClip(
        profileId: 'p-1',
        characterId: 'nitzi',
        spellingHash: spellingHash(spelling),
        sound: voice.sound,
        at: DateTime.utc(2026, 11, 3),
      );
      player.played.clear();
      // The map reads the clip when it is built; the parent area refreshes it with an invalidate, as here.
      ProviderScope.containerOf(tester.element(find.byType(HomeScreen))).invalidate(nameClipProvider('p-1'));
      await tester.pump(const Duration(milliseconds: 200));
      await tester.tap(find.byKey(const Key('home-companion')));
      await tester.pump(const Duration(seconds: 2));
      expect(
        <String>[for (final Uint8List b in player.played) said(b)],
        <String>[said(voice.sound), 'mp3:nitzi:core.home.bubble'],
      );
    },
  );
}
