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
    test('the microphone and the recogniser are touched in one file only', () {
      final List<String> users = <String>[
        for (final File f in dartFiles('lib'))
          if (RegExp(r'package:(record|sherpa_onnx)/').hasMatch(code(f))) slashed(f),
      ];
      expect(users, <String>['lib/speech/sherpa_engine.dart']);
      for (final File f in dartFiles('lib')) {
        if (slashed(f) == 'lib/speech/sherpa_engine.dart') continue;
        expect(
          RegExp('AudioRecorder|startStream|MediaRecorder|SpeechRecognizer|getUserMedia|speech_to_text')
              .hasMatch(code(f)),
          isFalse,
          reason: slashed(f),
        );
      }
    });

    test('the permission is declared once, and the other packages for sound or speech are not used', () {
      final String manifest = File('android/app/src/main/AndroidManifest.xml').readAsStringSync();
      expect('RECORD_AUDIO'.allMatches(manifest).length, 1);
      final String pubspec = File('pubspec.yaml').readAsStringSync();
      expect(
        RegExp(r'^\s+(speech_to_text|flutter_sound|permission_handler):', multiLine: true).hasMatch(pubspec),
        isFalse,
      );
    });

    test('the speech code writes no file and has no network', () {
      for (final File f in dartFiles('lib/speech')) {
        final String c = code(f);
        expect(
          RegExp(
            r'writeAs(Bytes|String)|openWrite|createSync|\.create\(|package:http|dart:io.*HttpClient|Socket',
          ).hasMatch(c),
          isFalse,
          reason: slashed(f),
        );
      }
    });

    test('audio is never kept: no sample buffer outlives a listen (the engine frees its stream)', () {
      final String engine = File('lib/speech/sherpa_engine.dart').readAsStringSync();
      expect(engine, contains('s.free()'));
      expect(engine, contains('recorder.dispose()'));
    });

    test('sound plays only from bytes of a verified pack, never from a URL or a file', () {
      final String player = File('lib/voice/voice_player.dart').readAsStringSync();
      expect(player, contains('BytesSource'));
      expect(player, isNot(contains('UrlSource')));
      expect(player, isNot(contains('DeviceFileSource')));
    });
  });

  group('packages', () {
    test('the packages the owner approved are pinned to the exact versions', () {
      final String pubspec = File('pubspec.yaml').readAsStringSync();
      for (final String line in <String>['audioplayers: 6.8.1', 'record: 7.1.2', 'sherpa_onnx: 2.0.0']) {
        expect(pubspec, contains(line));
        final String name = line.split(':').first;
        expect(
          RegExp(
            '$name:'
            r'\s*[\^~>]',
          ).hasMatch(pubspec),
          isFalse,
          reason: name,
        );
      }
    });
  });
}
