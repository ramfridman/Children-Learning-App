// The recordings of the language courses (`voice-lang-<course>`) reach a lesson through the guide: every guide, whoever it is, says
// the lines of a course (`vo:eng.…`, the slow copies and the cut Hebrew words included) from the installed, verified pack, and a
// course with no pack (or a refused one) is text only, never an error.
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nitznutz/app/companion.dart';
import 'package:nitznutz/characters/character.dart';
import 'package:nitznutz/characters/character_source.dart';
import 'package:nitznutz/characters/resolver.dart';
import 'package:nitznutz/content/pack_verify.dart';
import 'package:nitznutz/voice/voice_bank.dart';

import 'support/companion_fixtures.dart';
import 'support/language_voice.dart';

/// A source that holds the given banks and refuses the voice of the courses in [refused] the way the installer does.
class _Source implements CharacterSource {
  _Source(this.inner, this.banks, {this.refused = const <String>{}});

  final FixedCharacterSource inner;
  final Map<String, VoiceBank> banks;
  final Set<String> refused;

  @override
  Future<CharacterResolver> resolver() => inner.resolver();

  @override
  Future<VoiceBank> voice(String characterId) async {
    if (refused.contains(characterId)) throw PackRejected('signature', 'refused');
    return banks[characterId] ?? VoiceBank.empty(characterId);
  }
}

void main() {
  late FixedCharacterSource fixed;

  setUpAll(() async => fixed = await makeSource(friends: <String>['hero-son'], voices: false));

  Future<Guide> guideOf(
    String id,
    Map<String, VoiceBank> banks, {
    Set<String> refused = const <String>{},
  }) async {
    final Character c = fixed.characters.firstWhere((Character x) => x.id == id);
    final ProviderContainer container = ProviderContainer(
      overrides: [
        characterSourceProvider.overrideWith((Ref ref) async => _Source(fixed, banks, refused: refused)),
        characterForRoleProvider.overrideWith((Ref ref, CharacterRole role) async => c),
      ],
    );
    addTearDown(container.dispose);
    return container.read(guideProvider.future);
  }

  test(
    'a lesson of a course finds its lines, the slow copy and a cut word in the course pack, for Nitzi',
    () async {
      final Guide g = await guideOf('nitzi', <String, VoiceBank>{
        'nitzi': await bankOf(<String>['vo:core.greeting.hello']),
        'lang-eng': await bankOf(<String>[
          'vo:eng.en_hello',
          'vo:eng.en_hello_slow',
          'vo:eng.he_bye',
        ], character: 'lang-eng'),
        'lang-heb': await bankOf(<String>['vo:heb.cut_shalom'], character: 'lang-heb'),
      });
      for (final String id in <String>[
        'vo:eng.en_hello',
        'vo:eng.en_hello_slow',
        'vo:eng.he_bye',
        'vo:heb.cut_shalom',
        'vo:core.greeting.hello',
      ]) {
        expect(g.bank.clip(id), isNotNull, reason: id);
      }
      // The mouth cues come with the clip, as for any line.
      expect(g.bank.clip('vo:eng.en_hello')!.mouth, isNotNull);
      expect(g.bank.clip('vo:eng.en_hello')!.mp3, isNotEmpty);
      expect(g.bank.has('vo:rus.f01'), isFalse, reason: 'no Russian pack: text only');
    },
  );

  test(
    'a friend with a voice of its own plays the course lines too, and keeps its own lines first',
    () async {
      final Guide g = await guideOf('hero-son', <String, VoiceBank>{
        'hero-son': await bankOf(<String>['vo:core.greeting.hello'], character: 'hero-son'),
        'lang-rus': await bankOf(<String>['vo:rus.f01'], character: 'lang-rus'),
      });
      expect(g.bank.has('vo:rus.f01'), isTrue);
      expect(g.bank.has('vo:core.greeting.hello'), isTrue);
      expect(String.fromCharCodes(g.bank.clip('vo:core.greeting.hello')!.mp3), contains('hero-son'));
    },
  );

  test('no course pack at all is text only, and a refused one leaves the others', () async {
    final Guide none = await guideOf('nitzi', <String, VoiceBank>{
      'nitzi': await bankOf(<String>['vo:core.greeting.hello']),
    });
    expect(none.bank.has('vo:eng.en_hello'), isFalse);
    expect(none.bank.has('vo:core.greeting.hello'), isTrue);

    final Guide some = await guideOf(
      'nitzi',
      <String, VoiceBank>{
        'lang-eng': await bankOf(<String>['vo:eng.en_hello'], character: 'lang-eng'),
        'lang-rus': await bankOf(<String>['vo:rus.f01'], character: 'lang-rus'),
      },
      refused: <String>{'lang-heb'},
    );
    expect(some.bank.has('vo:eng.en_hello'), isTrue);
    expect(some.bank.has('vo:rus.f01'), isTrue);
  });

  group('the real course packs (checked when they are copied in, skipped when they are not)', () {
    for (final String course in <String>['eng', 'heb', 'rus']) {
      final File pack = File('assets/packs/voice-lang-$course-1.0.0.nnpack');
      test(
        'voice-lang-$course holds every line its lessons name, with a cue document each',
        () async {
          final Uint8List publicKey = unhex(File('assets/pack_signing_public_key.txt').readAsStringSync());
          final VoiceBank bank = VoiceBank.fromPack(
            await verifyPack(pack.readAsBytesSync(), publicKey: publicKey),
          );
          expect(bank.characterId, 'lang-$course');
          final RegExp ref = RegExp('"vo:($course\\.[A-Za-z0-9_.\\-]+)"');
          final Set<String> named = <String>{};
          for (final FileSystemEntity e in Directory('../content/languages/$course/pack').listSync()) {
            if (e is File && e.path.endsWith('.json')) {
              for (final RegExpMatch m in ref.allMatches(e.readAsStringSync())) {
                named.add('vo:${m.group(1)}');
              }
            }
          }
          expect(named, isNotEmpty);
          // A line the voice plan marks `"voice": null` is text only on purpose (the Hebrew course's short cheers).
          final Set<String> textOnly = <String>{};
          void walk(Object? node) {
            if (node is Map<String, Object?>) {
              if (node['voice'] == null && node['vo'] is String) textOnly.add(node['vo']! as String);
              node.values.forEach(walk);
            } else if (node is List<Object?>) {
              node.forEach(walk);
            }
          }

          walk(jsonDecode(File('../content/languages/$course/voice-plan.json').readAsStringSync()));
          final List<String> missing =
              named.where((String id) => !bank.has(id) && !textOnly.contains(id)).toList()..sort();
          expect(missing, isEmpty, reason: '${missing.length} of ${named.length} lines have no recording');
        },
        skip: pack.existsSync() ? false : 'the voice pack is not copied into the assets',
        timeout: const Timeout(Duration(minutes: 2)),
      );
    }
  });
}
