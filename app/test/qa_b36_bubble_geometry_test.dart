import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nitznutz/child/activity_shell.dart';
import 'package:nitznutz/design/board.dart';
import 'package:nitznutz/play/activity_frame.dart';
import 'package:nitznutz/play/robot_path_session.dart';

import 'support/harness.dart';

/// QA's second look at QA-B36-3 (docs/qa/b36-verification.md, re-verification): the fitted bubble of every text of the pack, on
/// every board (the robot's own layout of the phones included), does not meet the stage, the answer tiles, the microphone, the
/// progress trail or the three round buttons of the top bar. The first test of qa_b36_open_defects_test.dart checks the font and
/// the room; this one checks what the room must stay clear of.
void main() {
  const String sources = '../content/starter';

  setUpAll(() async {
    await loadAppFonts();
  });

  Size boardOf(ActivitySpec s) => identical(s, ActivitySpec.phone)
      ? BoardClass.phone.size
      : identical(s, ActivitySpec.phoneSE)
      ? BoardClass.phoneSE.size
      : identical(s, ActivitySpec.tabletLandscape)
      ? BoardClass.tabletLandscape.size
      : BoardClass.tabletPortrait.size;

  // What a bubble must stay clear of on one layout, in board points. The guide is not here: her box has empty margins and the
  // pictures show the bubble stopping short of her art (the PNGs of the record).
  Map<String, Rect> fixed(ActivitySpec s) => <String, Rect>{
    'stage': s.stage,
    'tiles': Rect.fromLTWH(s.tilesLeft, s.tilesTop, s.tilesWidth, 96),
    'mic': Rect.fromLTWH(s.micLeft, s.micTop, s.micSize, s.micSize),
    'trail': Rect.fromLTWH(s.trailLeft, s.trailTop, s.trailWidth, 36),
    'eye': Rect.fromLTWH(s.eyeLeft, s.controlsTop, 64, 64),
    'hint': Rect.fromLTWH(s.hintLeft, s.controlsTop, 64, 64),
  };

  test('QA-B36-3 (second look): a fitted bubble stays clear of the stage, the tiles, the mic, the trail and the top bar', () {
    final List<String> lines = <String>[];
    void walk(Object? n) {
      if (n is Map<String, Object?>) {
        if (n['caption'] is List<Object?>) {
          final String t = (n['caption']! as List<Object?>)
              .map((Object? c) => (c! as Map<String, Object?>)['v']! as String)
              .join(' ');
          if (t.isNotEmpty) lines.add(t);
        }
        n.values.forEach(walk);
      } else if (n is List<Object?>) {
        n.forEach(walk);
      }
    }

    for (final File f in Directory(sources).listSync().whereType<File>()) {
      if (!f.uri.pathSegments.last.startsWith('activity.')) continue;
      walk(jsonDecode(f.readAsStringSync()));
    }
    final List<(String, ActivitySpec, Size)> layouts = <(String, ActivitySpec, Size)>[
      for (final ActivitySpec b in <ActivitySpec>[
        ActivitySpec.phone,
        ActivitySpec.phoneSE,
        ActivitySpec.tabletLandscape,
        ActivitySpec.tabletPortrait,
      ])
        ('${boardOf(b).width.round()}', b, boardOf(b)),
      for (final ActivitySpec b in <ActivitySpec>[ActivitySpec.phone, ActivitySpec.phoneSE])
        ('robot ${boardOf(b).width.round()}', RobotPathSession.laidOut(b), boardOf(b)),
    ];
    final Set<String> bad = <String>{};
    int texts = 0;
    // The check can see the fault: without the fit (the bubble at its own top and width, at the smallest font) the small phone's long
    // lines would meet the tiles.
    int wouldMeet = 0;
    for (final String text in lines.toSet()) {
      texts++;
      for (final (String, ActivitySpec, Size) l in layouts) {
        final ActivitySpec s = l.$2;
        if (l.$1 == '667') {
          final double h = ActivityFrame.bubbleHeight(text, ActivityFrame.minFont, s.bubbleMaxWidth);
          if (Rect.fromLTWH(
            s.bubbleLeft!,
            s.bubbleTop,
            s.bubbleMaxWidth,
            h,
          ).deflate(0.5).overlaps(fixed(s)['tiles']!)) {
            wouldMeet++;
          }
        }
        final BubbleFit fit = ActivityFrame.fitBubble(text, s);
        final double left = fit.left ?? (l.$3.width - s.bubbleRight! - fit.maxWidth);
        // The body is as wide as its text (the bubble shrinks to fit), so the widest box is the strict test.
        final Rect box = Rect.fromLTWH(left, fit.top, fit.maxWidth, fit.height);
        for (final MapEntry<String, Rect> e in fixed(s).entries) {
          // The tablet's stage is a card that lies below the bubble's room by its own numbers; a touch of 0.5 is rounding.
          if (box.deflate(0.5).overlaps(e.value)) {
            bad.add(
              '${l.$1} bubble $box meets ${e.key} ${e.value}: ${text.substring(0, text.length.clamp(0, 30))}',
            );
          }
        }
      }
    }
    // ignore: avoid_print
    print(
      'QA-B36-3 second look: $texts distinct texts on ${layouts.length} layouts, ${bad.length} meetings ($wouldMeet would meet the tiles unfitted)',
    );
    expect(wouldMeet, greaterThan(100), reason: 'the check must be able to see the fault it guards');
    expect(bad, isEmpty, reason: '${bad.length} cases\n${bad.take(30).join('\n')}');
  });
}
