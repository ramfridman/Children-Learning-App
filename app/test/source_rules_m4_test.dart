// Rules of milestone 4 that are easiest to keep by checking the source: screens ask for roles and never name a
// character, nothing records a child, sound plays only from verified bytes, and the new package is pinned.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

List<File> dartFiles(String folder) => <File>[
  for (final FileSystemEntity e in Directory(folder).listSync(recursive: true))
    if (e is File && e.path.endsWith('.dart') && !e.path.endsWith('.g.dart')) e,
];

String slashed(File f) => f.path.replaceAll(r'\', '/');

String code(File f) => f.readAsLinesSync().where((String l) => !l.trimLeft().startsWith('//')).join('\n');

void main() {
  group('screens never name a character', () {
    final RegExp ids = RegExp(
      '[\'"](nitzi|hero-[a-z-]+|friend-[a-z-]+|alien-[a-z-]+|climber-[a-z-]+|compass-[a-z-]+|inventor-[a-z-]+|tower-[a-z-]+|weaver-[a-z-]+)[\'"]',
    );

    test('the child space, the lessons and the app shell hold no character id', () {
      final List<File> screens = <File>[
        ...dartFiles('lib/child'),
        ...dartFiles('lib/play'),
        File('lib/app/app.dart'),
      ];
      expect(screens, isNotEmpty);
      for (final File f in screens) {
        expect(ids.hasMatch(code(f)), isFalse, reason: '${slashed(f)} names a character');
      }
    });

    test('the house character is named in one place only: the character source and its pack id', () {
      final List<String> hits = <String>[
        for (final File f in dartFiles('lib'))
          if (RegExp("['\"]char-nitzi['\"]").hasMatch(code(f))) slashed(f),
      ];
      expect(hits, <String>['lib/characters/character_source.dart']);
    });
  });

  group('nothing records a child', () {
    test('no microphone, recording or speech code anywhere in the app', () {
      final RegExp banned = RegExp(
        'AudioRecorder|MediaRecorder|speech_to_text|SpeechRecognizer|startRecording|record_audio|RECORD_AUDIO|getUserMedia',
        caseSensitive: false,
      );
      for (final File f in dartFiles('lib')) {
        expect(banned.hasMatch(code(f)), isFalse, reason: slashed(f));
      }
      final String manifest = File('android/app/src/main/AndroidManifest.xml').readAsStringSync();
      expect(manifest.contains('RECORD_AUDIO'), isFalse);
      final String pubspec = File('pubspec.yaml').readAsStringSync();
      expect(
        RegExp(
          r'^\s+(record|speech_to_text|flutter_sound|permission_handler):',
          multiLine: true,
        ).hasMatch(pubspec),
        isFalse,
      );
    });

    test('sound plays only from bytes of a verified pack, never from a URL or a file', () {
      final String player = File('lib/voice/voice_player.dart').readAsStringSync();
      expect(player, contains('BytesSource'));
      expect(player, isNot(contains('UrlSource')));
      expect(player, isNot(contains('DeviceFileSource')));
    });
  });

  group('packages', () {
    test('audioplayers is pinned to the exact version the owner approved', () {
      final String pubspec = File('pubspec.yaml').readAsStringSync();
      expect(pubspec, contains('audioplayers: 6.8.1'));
      expect(RegExp(r'audioplayers:\s*[\^~>]').hasMatch(pubspec), isFalse);
    });
  });
}
