// QA B-45: the narrator speaks only in the child's space. No parent-area, sign-in, device, sync, network, security, push, tutor,
// engine, data or dev-page file may reach the voice director or the player, so a map-card line (or any line) can never be heard
// outside the child's screens.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('only the child space, the lesson player and the app shell use the voice director or player', () {
    final RegExp speaks = RegExp(
      r'voiceDirectorProvider|voicePlayerProvider|VoiceDirector|VoicePlayer|\.say\(|\.sayNext\(',
    );
    const Set<String> allowed = <String>{
      'lib/app/app.dart', // the bottle of the child's home
      'lib/app/bottle_hold.dart',
      'lib/app/companion.dart', // the providers
      'lib/child/ceremony_screen.dart',
      'lib/child/companion_views.dart',
      'lib/child/friends_beach.dart',
      'lib/child/land_screen.dart',
      'lib/child/trophy_hall.dart',
      'lib/play/lesson_screen.dart',
    };
    final Set<String> found = <String>{};
    for (final FileSystemEntity f in Directory('lib').listSync(recursive: true)) {
      if (f is! File || !f.path.endsWith('.dart')) continue;
      final String path = f.path.replaceAll(Platform.pathSeparator, '/');
      if (path.startsWith('lib/voice/')) continue; // the voice code itself
      if (speaks.hasMatch(f.readAsStringSync())) found.add(path);
    }
    expect(found, allowed);
    for (final String path in found) {
      for (final String outside in <String>[
        'lib/parent/',
        'lib/auth/',
        'lib/device/',
        'lib/sync/',
        'lib/net/',
        'lib/security/',
        'lib/push/',
        'lib/tutor/',
        'lib/ui/dev/',
      ]) {
        expect(path.startsWith(outside), isFalse, reason: '$path speaks outside the child space');
      }
    }
  });
}
