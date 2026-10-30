// The parent's text of a word alert (docs/child-safety/hebrew-validation.md, section 5.1): one text per tier, the
// add-on of the subcategory, "once" or "{n} times" in the weekly note, the child's name never after a prefix letter,
// and only the three checked help numbers, isolated left to right.
import 'package:flutter_test/flutter_test.dart';
import 'package:nitznutz/data/app_database.dart';
import 'package:nitznutz/parent/word_alert_text.dart';
import 'package:nitznutz/strings/he.dart';

Alert alert(String category, {String detail = '', String words = '', int count = 1}) => Alert(
  id: 1,
  at: DateTime(2026, 11, 20, 12),
  profileId: 'p-1',
  category: category,
  severity: 'info',
  count: count,
  detail: detail,
  words: words,
  dedupeKey: 'k',
);

List<String> textOf(Alert a) => wordAlertText(a, 'Dana')!.lines.map((AlertLine l) => l.text).toList();

void main() {
  test('an act: the words heard, the steps, the add-on of its subcategory and the help numbers', () {
    final ({String title, List<AlertLine> lines}) t = wordAlertText(
      alert('disclosure', detail: '1:SELF:W-30:2026-10-29.1', words: 'אני רוצה למות'),
      'Dana',
    )!;
    expect(t.title, He.alertActTitle.text);
    final List<String> lines = t.lines.map((AlertLine l) => l.text).toList();
    expect(lines.first, He.alertHeard.fill(<String, String>{'child': 'Dana', 'w': 'אני רוצה למות'}));
    expect(lines, contains(He.alertAddSelf.fill(<String, String>{'child': 'Dana'})));
    expect(lines, isNot(contains(He.alertAddPhys.fill(<String, String>{'child': 'Dana'}))));
    expect(
      lines,
      containsAll(<String>[He.alertHelp118.text, He.alertHelp1201.text, He.alertActNoReport.text]),
    );
    expect(t.lines.where((AlertLine l) => l.kind == AlertLineKind.bullet).length, 7);
  });

  test('every subcategory of an act has its add-on, and a secret adds the secrets one (C-2)', () {
    const Map<String, Str?> addOn = <String, Str?>{
      'PHYS': He.alertAddPhys,
      'SEX': He.alertAddSex,
      'NEGL': He.alertAddNegl,
      'EMERG': He.alertAddEmerg,
      'ONLINE': He.alertAddOnline,
      'SECRET': He.alertAddSecret,
      'FEAR': null,
    };
    addOn.forEach((String sub, Str? s) {
      final List<String> lines = textOf(alert('disclosure', detail: '1:$sub:W-00:v'));
      if (s != null) expect(lines, contains(s.fill(<String, String>{'child': 'Dana'})), reason: sub);
    });
    expect(textOf(alert('disclosure', detail: '1:PHYS:W-03:v:secret')), contains(He.alertAddSecret.text));
  });

  test('words not kept: the act says so; "repeated" has its own title and sentence', () {
    expect(textOf(alert('disclosure', detail: '1:PHYS:W-01:v')).first, He.alertWordsNotKept.text);
    final ({String title, List<AlertLine> lines}) r = wordAlertText(
      alert('disclosure', detail: '1:FEAR:W-21:v:repeat'),
      'Dana',
    )!;
    expect(r.title, He.alertRepeatTitle.text);
    expect(r.lines.first.text, He.alertRepeatHeardNoWords.text);
    expect(
      textOf(alert('disclosure', detail: '1:FEAR:W-21:v:repeat', words: 'מפחידים אותי')).first,
      He.alertRepeatHeard.fill(<String, String>{'w': 'מפחידים אותי'}),
    );
  });

  test('a check is calm and short', () {
    final ({String title, List<AlertLine> lines}) t = wordAlertText(
      alert('concern', detail: '2:PHYS:W-03:v', words: 'הוא מרביץ לי'),
      'Dana',
    )!;
    expect(t.title, He.alertCheckTitle.text);
    expect(t.lines.map((AlertLine l) => l.text), isNot(contains(He.alertHelp118.text)));
    expect(t.lines.length, 4);
  });

  test(
    'the weekly note says "once" for one time and "{n} times" for more; the adult world has its own text',
    () {
      expect(
        textOf(alert('inappropriateWords', detail: '3:SWEAR:S-01:v')).first,
        He.alertNoteOnce.fill(<String, String>{'child': 'Dana'}),
      );
      expect(
        textOf(alert('inappropriateWords', detail: '3:SWEAR:S-01:v', count: 5)).first,
        He.alertNoteMany.fill(<String, String>{'child': 'Dana', 'n': '5'}),
      );
      expect(
        wordAlertText(alert('inappropriateWords', detail: '3:EXPOSE:S-12:v'), 'Dana')!.title,
        He.alertExposeTitle.text,
      );
      expect(
        wordAlertText(alert('inappropriateWords'), 'Dana')!.title,
        He.alertNoteTitle.text,
        reason: 'an old swear alert',
      );
      expect(wordAlertText(alert('pastLimit'), 'Dana'), isNull);
    },
  );

  test('C-5 is said under an act and a check, and how many times it was heard in its half hour', () {
    final List<String> act = textOf(alert('disclosure', detail: '1:PHYS:W-01:v:often', count: 3));
    expect(act, contains(He.alertOften.text));
    expect(act, contains(He.alertHeardTimes.fill(<String, String>{'n': '3'})));
    expect(
      act.indexOf(He.alertOften.text),
      lessThan(act.indexOf(He.alertActHelp.text)),
      reason: 'before the help block',
    );
    final List<String> check = textOf(alert('concern', detail: '2:PHYS:W-03:v:often'));
    expect(check, contains(He.alertOften.text));
    expect(
      check,
      isNot(contains(He.alertHeardTimes.fill(<String, String>{'n': '1'}))),
      reason: 'once is not said',
    );
    expect(textOf(alert('disclosure', detail: '1:PHYS:W-01:v')), isNot(contains(He.alertOften.text)));
  });

  test('the weekly notes of a request to keep a secret and of a young child hitting themselves', () {
    expect(
      wordAlertText(alert('inappropriateWords', detail: '3:SECRET:W-47:v'), 'Dana')!.title,
      He.alertSecretAskTitle.text,
    );
    expect(
      textOf(alert('inappropriateWords', detail: '3:SECRET:W-47:v', count: 4)).first,
      He.alertSecretAskMany.fill(<String, String>{'child': 'Dana', 'n': '4'}),
    );
    expect(
      wordAlertText(alert('inappropriateWords', detail: '3:SELF:W-37:v'), 'Dana')!.title,
      He.alertSelfHitTitle.text,
    );
    expect(
      textOf(alert('inappropriateWords', detail: '3:SELF:W-37:v')).first,
      He.alertSelfHitOnce.fill(<String, String>{'child': 'Dana'}),
    );
  });

  test('QA-42: the category decides the tier; a detail of another tier only loses its subcategory', () {
    expect(
      wordAlertText(alert('inappropriateWords', detail: '1:PHYS:W-01:v'), 'Dana')!.title,
      He.alertNoteTitle.text,
    );
    expect(
      wordAlertText(alert('disclosure', detail: '3:SWEAR:S-01:v'), 'Dana')!.title,
      He.alertActTitle.text,
    );
    expect(
      wordAlertText(alert('concern', detail: '1:PHYS:W-01:v:often'), 'Dana')!.title,
      He.alertCheckTitle.text,
    );
  });

  group('the strings', () {
    final List<Str> all = <Str>[
      He.alertHeard,
      He.alertWordsNotKept,
      He.alertActTitle,
      He.alertActUnsure,
      He.alertActNow,
      He.alertActStep1, //
      He.alertActStep2,
      He.alertActStep3,
      He.alertActStep4,
      He.alertActStep5,
      He.alertActHelp,
      He.alertHelp118, //
      He.alertHelp1201,
      He.alertActDuty,
      He.alertActNoReport,
      He.alertAddPhys,
      He.alertAddSex,
      He.alertAddSelf, //
      He.alertAddNegl, He.alertAddEmerg, He.alertAddOnline, He.alertAddSecret, He.alertCheckTitle, //
      He.alertCheckMaybe, He.alertCheckAsk, He.alertCheckIf, He.alertRepeatTitle, He.alertRepeatHeard, //
      He.alertRepeatHeardNoWords,
      He.alertRepeatNext,
      He.alertNoteTitle,
      He.alertNoteMany,
      He.alertNoteOnce, //
      He.alertNoteCalm, He.alertNoteHidden, He.alertExposeTitle, He.alertExposeBody, He.alertsHonest, //
      He.alertCardTitle, He.alertCard1, He.alertCard2, He.alertCard3, He.alertCard4, He.alertOften, //
      He.alertHeardTimes, He.alertSecretAskTitle, He.alertSecretAskMany, He.alertSecretAskOnce, //
      He.alertSecretAskCalm,
      He.alertSelfHitTitle,
      He.alertSelfHitMany,
      He.alertSelfHitOnce,
      He.alertSelfHitCalm,
    ];

    test('the child\'s name never follows a prefix letter', () {
      for (final Str s in all) {
        expect(RegExp('[א-ת]\\{child\\}').hasMatch(s.text), isFalse, reason: s.text);
      }
    });

    test('only 118, 1201 and 105 (and the WhatsApp number of 118), each isolated left to right', () {
      final RegExp number = RegExp(r'[0-9][0-9-]*[0-9]');
      final Set<String> seen = <String>{};
      for (final Str s in all) {
        for (final RegExpMatch m in number.allMatches(s.text)) {
          if (m.group(0) == '24' || m.group(0) == '30') continue; // "24 hours", not a number to call
          seen.add(m.group(0)!);
          expect(s.text.substring(m.start - 1, m.start), '\u2066', reason: s.text);
          expect(s.text.substring(m.end, m.end + 1), '\u2069', reason: s.text);
        }
      }
      expect(seen, <String>{'118', '1201', '105', '050-2270118'});
    });

    test('the acronyms take gershayim and geresh, and no text promises protection', () {
      expect(He.alertHelp1201.text, contains('ער״ן'));
      expect(He.alertHelp1201.text, contains('צ׳אט'));
      for (final Str s in all) {
        expect(s.text, isNot(contains('רשת ביטחון')), reason: s.text);
        expect(s.text, isNot(contains('«')));
      }
    });
  });
}
