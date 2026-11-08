// The permanent audit of the speech bubble over every land (QA-C1d-1): on the board and at the text size of each case below, every
// activity (or, where the case says so, a sample of every template: its longest lines and every tenth activity) is opened, and at the
// start and at hint 1, 2 and 3 its bubble must lie over no answer tile and no key. A failure names the activity and the state.
//
// The audit is in three files, so that they run side by side: the small phone (the board with the least room, the full pack at the largest
// text size), the phone, and the tablets. About three minutes each.
//
//   flutter test --no-pub test/all_lands_bubble_audit_tablet_test.dart
import 'package:flutter/material.dart';

import 'support/bubble_audit.dart';

void main() => bubbleAuditTests(<BubbleAuditCase>[
  (board: 'tabletL', size: Size(1180, 820), scale: 1.0, full: false),
  (board: 'tabletL', size: Size(1180, 820), scale: 1.3, full: false),
  (board: 'tabletP', size: Size(820, 1180), scale: 1.0, full: false),
  (board: 'tabletP', size: Size(820, 1180), scale: 1.3, full: false),
]);
