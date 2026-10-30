import '../data/app_database.dart';
import '../strings/he.dart';
import 'alerts.dart';

/// How one line of an alert's text is shown.
enum AlertLineKind { body, heading, bullet, small }

class AlertLine {
  const AlertLine(this.text, [this.kind = AlertLineKind.body, this.hasWords = false]);

  final String text;
  final AlertLineKind kind;

  /// True for a line that quotes the child's words: the screen does not let it be selected or copied (SEC-33).
  final bool hasWords;
}

/// The parent's text of a word alert, line by line (docs/child-safety/hebrew-validation.md, section 5.1, and
/// hebrew-validation-app.md, section 3), or null for an alert of another kind. [child] is the child's name; it is only
/// ever put after a word, never after a prefix letter.
///
/// The **category** decides the tier (a note that was never pushed never reads as an act, QA-42); the detail adds the
/// subcategory and the flags only when its tier agrees. An alert saved before the tiers (empty detail) reads as its
/// category's tier.
({String title, List<AlertLine> lines})? wordAlertText(Alert a, String child) {
  final int? tier = switch (a.category) {
    'disclosure' => 1,
    'concern' => 2,
    'inappropriateWords' => 3,
    _ => null,
  };
  if (tier == null) return null;
  final WordDetail? parsed = WordDetail.parse(a.detail);
  final WordDetail? d = parsed?.tier == tier ? parsed : null;
  final String sub = d?.sub ?? (tier == 3 ? 'SWEAR' : '');
  final Set<String> flags = d?.flags ?? const <String>{};
  final int count = a.count < 1 ? 1 : a.count;
  String fill(Str s) => s.fill(<String, String>{'child': child, 'w': a.words, 'n': '$count'});
  final bool hasWords = a.words.isNotEmpty;
  final AlertLine heard = AlertLine(
    fill(hasWords ? He.alertHeard : He.alertWordsNotKept),
    AlertLineKind.body,
    hasWords,
  );
  final List<AlertLine> times = <AlertLine>[if (count > 1) AlertLine(fill(He.alertHeardTimes))];
  final List<AlertLine> often = <AlertLine>[if (flags.contains('often')) AlertLine(fill(He.alertOften))];

  if (tier == 3) return _note(sub, count, hasWords ? heard : null, fill);
  if (tier == 2) {
    return (
      title: He.alertCheckTitle.text,
      lines: <AlertLine>[
        heard,
        ...times,
        AlertLine(fill(He.alertCheckMaybe)),
        AlertLine(fill(He.alertCheckAsk)),
        AlertLine(fill(He.alertCheckIf)),
        ...often,
      ],
    );
  }
  final bool repeat = flags.contains('repeat');
  final Str? addOn = switch (sub) {
    'PHYS' => He.alertAddPhys,
    'SEX' => He.alertAddSex,
    'SELF' => He.alertAddSelf,
    'NEGL' => He.alertAddNegl,
    'EMERG' => He.alertAddEmerg,
    'ONLINE' => He.alertAddOnline,
    'SECRET' => He.alertAddSecret,
    _ => null,
  };
  return (
    title: repeat ? He.alertRepeatTitle.text : He.alertActTitle.text,
    lines: <AlertLine>[
      if (repeat) ...<AlertLine>[
        AlertLine(
          fill(hasWords ? He.alertRepeatHeard : He.alertRepeatHeardNoWords),
          AlertLineKind.body,
          hasWords,
        ),
        AlertLine(fill(He.alertRepeatNext)),
      ] else
        heard,
      ...times,
      AlertLine(fill(He.alertActUnsure)),
      AlertLine(He.alertActNow.text, AlertLineKind.heading),
      for (final Str s in <Str>[
        He.alertActStep1,
        He.alertActStep2,
        He.alertActStep3,
        He.alertActStep4,
        He.alertActStep5,
      ])
        AlertLine(fill(s), AlertLineKind.bullet),
      if (addOn != null) AlertLine(fill(addOn)),
      if (flags.contains('secret') && sub != 'SECRET') AlertLine(fill(He.alertAddSecret)),
      ...often,
      AlertLine(He.alertActHelp.text, AlertLineKind.heading),
      AlertLine(He.alertHelp118.text, AlertLineKind.bullet),
      AlertLine(He.alertHelp1201.text, AlertLineKind.bullet),
      AlertLine(He.alertActDuty.text, AlertLineKind.small),
      AlertLine(He.alertActNoReport.text, AlertLineKind.small),
    ],
  );
}

/// A weekly note: the adult world, a request to keep a secret, a young child hitting themselves, or swearing.
({String title, List<AlertLine> lines}) _note(
  String sub,
  int count,
  AlertLine? heard,
  String Function(Str) fill,
) {
  if (sub == 'EXPOSE') {
    return (title: He.alertExposeTitle.text, lines: <AlertLine>[AlertLine(fill(He.alertExposeBody)), ?heard]);
  }
  final (Str title, Str once, Str many, Str calm) = switch (sub) {
    'SECRET' => (He.alertSecretAskTitle, He.alertSecretAskOnce, He.alertSecretAskMany, He.alertSecretAskCalm),
    'SELF' => (He.alertSelfHitTitle, He.alertSelfHitOnce, He.alertSelfHitMany, He.alertSelfHitCalm),
    _ => (He.alertNoteTitle, He.alertNoteOnce, He.alertNoteMany, He.alertNoteCalm),
  };
  return (
    title: title.text,
    lines: <AlertLine>[
      AlertLine(fill(count <= 1 ? once : many)),
      ?heard,
      AlertLine(fill(calm)),
      AlertLine(He.alertNoteHidden.text, AlertLineKind.small),
    ],
  );
}
