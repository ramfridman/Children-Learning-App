// The security findings of the word alerts (docs/security/findings.md, SEC-25, SEC-26, SEC-28), on the phone:
// - SEC-25: the words of an alert always fit what alert-create takes (every character the speech model can write is
//   tried), and one alert the gateway refuses never holds up the alerts after it;
// - SEC-26: the lists are checked when they are read, a bad or older source keeps the lists of the app, and a long
//   answer costs a bounded amount of work;
// - SEC-28: "keep the words" off and the 30 days hold on every phone, after every sync and at the start.
import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart' show Value, driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nitznutz/core/errors.dart';
import 'package:nitznutz/data/app_database.dart';
import 'package:nitznutz/parent/alerts.dart';
import 'package:nitznutz/speech/alert_lists.dart';
import 'package:nitznutz/speech/alert_words.dart';
import 'package:nitznutz/speech/model_spec.dart';
import 'package:nitznutz/sync/sync_engine.dart';

import 'support/fake_family_server.dart';

const String kid = 'child-aaaa-0001';
const String dev = 'd3d3d3d3-0000-4000-8000-000000000003';
final DateTime noon = DateTime.utc(2026, 11, 20, 12);

/// What alert-create takes (testvectors/wire-patterns.json, held equal to the gateway by alerts_test.ts).
final Map<String, Object?> wire =
    (jsonDecode(File('../testvectors/wire-patterns.json').readAsStringSync())
            as Map<String, Object?>)['alert_create']!
        as Map<String, Object?>;

RegExp patternOf(String field) => RegExp((wire[field]! as Map<String, Object?>)['pattern']! as String);
int maxOf(String field) => (wire[field]! as Map<String, Object?>)['max']! as int;

Map<String, Object?> listsWith({
  String listVersion = '2026-10-29.1',
  List<Object?> rules = const <Object?>[],
  List<Object?> words = const <Object?>[],
}) => <String, Object?>{...bundledAlertLists, 'listVersion': listVersion, 'rules': rules, 'words': words};

Map<String, Object?> rule(Map<String, Object?> over) => <String, Object?>{
  'id': 'W-90',
  'sub': 'PHYS',
  'tier': 1,
  'seq': <String>['מכים'],
  ...over,
};

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  group('SEC-25: the words fit the gateway', () {
    final RegExp words = patternOf('words');

    test(
      'every character of the Basic Multilingual Plane, alone and in a phrase, comes out in the pattern',
      () {
        for (int c = 0; c <= 0xFFFF; c++) {
          if (c >= 0xD800 && c <= 0xDFFF) continue; // half of a pair, not a character
          final String ch = String.fromCharCode(c);
          for (final String text in <String>[ch, 'מכים $ch אותי', '$ch$ch$ch']) {
            final String w = wireWords(text);
            expect(
              words.hasMatch(w) && w.length <= maxOf('words'),
              isTrue,
              reason: 'U+${c.toRadixString(16)}',
            );
          }
        }
        expect(wireWords('😀 מכים 😀 אותי'), 'מכים אותי', reason: 'a character outside the plane');
      },
    );

    test("every character of the speech model's tokens.txt comes out in the pattern", () {
      final Map<String, Object?> f =
          jsonDecode(File('test/fixtures/asr_token_chars.json').readAsStringSync()) as Map<String, Object?>;
      expect(
        f['tokens_sha256'],
        SpeechModel.files.singleWhere((ModelFile m) => m.name == 'tokens.txt').sha256Hex,
        reason: 'the fixture is of the model the app downloads',
      );
      final String all = String.fromCharCodes(<int>[
        for (final Object? c in f['code_points']! as List<Object?>) c! as int,
      ]);
      expect(all.length, greaterThan(200));
      expect(
        words.hasMatch(all),
        isFalse,
        reason: 'the model can write what the gateway refuses (the finding)',
      );
      expect(words.hasMatch(wireWords(all)), isTrue);
      expect(words.hasMatch(wireWords('השעה 3:30, 50% (בערך) ← יופי')), isTrue);
    });

    test('spaces collapse, the ends are trimmed, and a long answer is cut to 200 characters', () {
      expect(wireWords('  מכים \t\n אותי  '), 'מכים אותי');
      expect(wireWords('מכים:אותי'), 'מכים אותי');
      final String long = wireWords(List<String>.filled(100, 'מכים').join(' '));
      expect(long.length, lessThanOrEqualTo(200));
      expect(long.endsWith(' '), isFalse);
      expect(
        wireWords('FUCK you, אמא! "זה" לא-נכון?'),
        'FUCK you, אמא! "זה" לא-נכון?',
        reason: 'what fits stays',
      );
    });

    test('every detail and key the bundled lists can make fits alert-create', () {
      final RegExp detail = patternOf('detail');
      final RegExp key = patternOf('key');
      final List<String> rows = <String>[
        for (final Object? r in bundledAlertLists['rules']! as List<Object?>)
          (r! as Map<String, Object?>)['id']! as String,
      ];
      final Set<String> subs = <String>{
        for (final Object? r in bundledAlertLists['rules']! as List<Object?>)
          (r! as Map<String, Object?>)['sub']! as String,
        'SWEAR',
        'EXPOSE',
      };
      for (final String sub in subs) {
        for (final String id in rows) {
          final String d = WordDetail(
            tier: 1,
            sub: sub,
            rule: id,
            listVersion: AlertLists.bundled.listVersion,
            flags: const <String>{'often', 'secret', 'repeat'},
          ).encode();
          expect(detail.hasMatch(d) && d.length <= maxOf('detail'), isTrue, reason: d);
        }
        final String note = noteKey(List<String>.filled(64, 'a').join(), sub, DateTime(2026, 11, 20));
        expect(key.hasMatch(note) && note.length <= maxOf('key'), isTrue, reason: note);
      }
      expect(WordDetail(tier: 1, sub: 'A B', rule: 'x/y', listVersion: '1 2').encode(), '1:AB:xy:12');
    });
  });

  group('SEC-25: one refused alert never holds up the next', () {
    late AppDatabase db;
    late List<Map<String, Object?>> stored;
    late List<Map<String, Object?>> tried;
    setUp(() {
      db = AppDatabase(NativeDatabase.memory());
      stored = <Map<String, Object?>>[];
      tried = <Map<String, Object?>>[];
    });
    tearDown(() => db.close());

    SyncEngine engine(Set<String> categories, {int version = 1, bool down = false}) => SyncEngine(
      db: db,
      call: (String name, Map<String, Object?> body) async {
        if (name != 'alert-create') return <String, Object?>{};
        tried.add(body);
        if (down) throw const GatewayException('network');
        final String w = body['words'] as String? ?? '';
        if (!categories.contains(body['category']) || w.length > 200 || !patternOf('words').hasMatch(w)) {
          throw const GatewayException('bad_request', status: 400);
        }
        stored.add(body);
        return <String, Object?>{'status': 'new'};
      },
      deviceId: dev,
      isParent: false,
      nowMs: () => noon.millisecondsSinceEpoch,
      engineVersion: version,
      batch: 4,
    );

    Future<void> raise(String key, String category, String w) => db.addAlert(
      AlertsCompanion.insert(
        at: noon.subtract(const Duration(hours: 1)),
        profileId: const Value<String?>(kid),
        category: category,
        severity: 'info',
        dedupeKey: key,
        words: Value<String>(w),
      ),
    );

    const Set<String> server = <String>{
      'pastLimit',
      'restHours',
      'gateAttempts',
      'guessing',
      'frustration',
      'inappropriateWords',
      'disclosure', //
      'absence', 'ribbonEarned', 'concern',
    };

    test(
      '(a) words the gateway refuses: the alert goes again without them, and the act after it arrives',
      () async {
        await raise('words:1', 'inappropriateWords', 'חרא 50%');
        await raise('words:2', 'disclosure', '');
        await engine(server).syncOnce();
        expect(stored.map((Map<String, Object?> a) => a['key']), <String>['words:1', 'words:2']);
        expect(
          stored.first.containsKey('words'),
          isFalse,
          reason: 'the privacy-safe side: the words are lost',
        );
        expect(await db.unsyncedAlerts(), isEmpty);
      },
    );

    test(
      '(b) a category the gateway does not know: refused and kept aside, the act after it arrives',
      () async {
        await raise('words:1', 'concern', 'מפחידים אותי');
        await raise('words:2', 'disclosure', '');
        await engine(server.difference(<String>{'concern'})).syncOnce();
        expect(stored.map((Map<String, Object?> a) => a['key']), <String>['words:2']);
        expect(
          tried.where((Map<String, Object?> a) => a['key'] == 'words:1').length,
          2,
          reason: 'with and without words',
        );
        final Alert refused = (await db.allAlerts()).singleWhere((Alert a) => a.dedupeKey == 'words:1');
        expect(AppDatabase.wasRefusedBySync(refused.syncedAt), isTrue);
        await engine(server.difference(<String>{'concern'})).syncOnce();
        expect(
          tried.where((Map<String, Object?> a) => a['key'] == 'words:1').length,
          2,
          reason: 'not again this version',
        );
        // A new version of the app sends what was refused once more (the gateway is right by then).
        await engine(server, version: 2).syncOnce();
        expect(stored.map((Map<String, Object?> a) => a['key']), contains('words:1'));
      },
    );

    test(
      'a phone whose clock runs ahead sends the time the server knows, never later (it would be refused)',
      () async {
        await db.addAlert(
          AlertsCompanion.insert(
            at: noon.add(const Duration(minutes: 10)), // made by a clock 10 minutes fast
            profileId: const Value<String?>(kid),
            category: 'disclosure',
            severity: 'important',
            dedupeKey: 'words:1',
          ),
        );
        final SyncEngine fast = SyncEngine(
          db: db,
          call: (String name, Map<String, Object?> body) async {
            if (name == 'alert-create') stored.add(body);
            return <String, Object?>{'status': 'new'};
          },
          deviceId: dev,
          isParent: false,
          nowMs: () => noon.add(const Duration(minutes: 10)).millisecondsSinceEpoch,
          serverNowMs: () => noon.millisecondsSinceEpoch,
        );
        await fast.syncOnce();
        expect(stored.single['at'], noon.millisecondsSinceEpoch);
      },
    );

    test(
      'SEC-30: the time is worked out again on each try, so a skew learned by the first try is used at once',
      () async {
        final int server = noon.millisecondsSinceEpoch;
        final int phone = server + 600000;
        int skew = 0;
        await db.addAlert(
          AlertsCompanion.insert(
            at: DateTime.fromMillisecondsSinceEpoch(phone, isUtc: true),
            profileId: const Value<String?>(kid),
            category: 'disclosure',
            severity: 'important',
            dedupeKey: 'words:1',
            words: const Value<String>('מכים אותי'),
          ),
        );
        final SyncEngine e = SyncEngine(
          db: db,
          call: (String name, Map<String, Object?> body) async {
            if (name != 'alert-create') return <String, Object?>{};
            // The gateway client learnt the skew on this call (clock_skew) and sent the same body again.
            skew = server - phone;
            if ((body['at']! as int) > server + 120000) {
              throw const GatewayException('bad_request', status: 400);
            }
            stored.add(body);
            return <String, Object?>{'status': 'new'};
          },
          deviceId: dev,
          isParent: false,
          nowMs: () => phone,
          serverNowMs: () => phone + skew,
        );
        await e.syncOnce();
        expect(stored.single['key'], 'words:1');
        expect(stored.single['words'], 'מכים אותי', reason: 'the words are not lost to a clock');
        expect(AppDatabase.wasRefusedBySync((await db.allAlerts()).single.syncedAt), isFalse);
      },
    );

    test('no network: nothing is marked, everything goes next time', () async {
      await raise('words:1', 'disclosure', '');
      await engine(server, down: true).syncOnce();
      expect((await db.unsyncedAlerts()).length, 1);
      await engine(server).syncOnce();
      expect(stored.single['key'], 'words:1');
    });

    test(
      'each alert is marked as it is answered: a failure half-way keeps only the rest for later',
      () async {
        await raise('words:1', 'disclosure', '');
        await raise('words:2', 'disclosure', '');
        int calls = 0;
        final SyncEngine half = SyncEngine(
          db: db,
          call: (String name, Map<String, Object?> body) async {
            if (name != 'alert-create') return <String, Object?>{};
            if (calls++ == 1) throw const GatewayException('network');
            return <String, Object?>{'status': 'new'};
          },
          deviceId: dev,
          isParent: false,
          nowMs: () => noon.millisecondsSinceEpoch,
        );
        await half.syncOnce();
        expect((await db.unsyncedAlerts()).map((Alert a) => a.dedupeKey), <String>['words:2']);
      },
    );
  });

  group('SEC-26: the lists are checked when they are read', () {
    test('values that would break an alert, numbers out of bounds and wrong types are refused', () {
      final List<(String, Map<String, Object?>)> bad = <(String, Map<String, Object?>)>[
        ('a version with a space', listsWith(listVersion: '1 2')),
        ('a version that is not a date', listsWith(listVersion: 'latest')),
        (
          'a sub with a colon',
          listsWith(
            rules: <Object?>[
              rule(<String, Object?>{'sub': 'A:B'}),
            ],
          ),
        ),
        (
          'an unknown sub',
          listsWith(
            rules: <Object?>[
              rule(<String, Object?>{'sub': 'OTHER'}),
            ],
          ),
        ),
        (
          'a long id',
          listsWith(
            rules: <Object?>[
              rule(<String, Object?>{'id': List<String>.filled(100, 'x').join()}),
            ],
          ),
        ),
        (
          'a gap of 24',
          listsWith(
            rules: <Object?>[
              rule(<String, Object?>{'gap': 24}),
            ],
          ),
        ),
        (
          'a negative gap',
          listsWith(
            rules: <Object?>[
              rule(<String, Object?>{'gap': -1}),
            ],
          ),
        ),
        (
          'a window of 0',
          listsWith(
            rules: <Object?>[
              rule(<String, Object?>{
                'seq': null,
                'win': 0,
                'all': <String>['מכים'],
              }),
            ],
          ),
        ),
        (
          'a near of 9',
          listsWith(
            rules: <Object?>[
              rule(<String, Object?>{'near': 9}),
            ],
          ),
        ),
        (
          'an afterWin of 9',
          listsWith(
            rules: <Object?>[
              rule(<String, Object?>{'afterWin': 9}),
            ],
          ),
        ),
        (
          'nine slots',
          listsWith(
            rules: <Object?>[
              rule(<String, Object?>{'seq': List<String>.filled(9, 'מכים')}),
            ],
          ),
        ),
        (
          'an empty stem',
          listsWith(
            rules: <Object?>[
              rule(<String, Object?>{
                'seq': <String>['*', 'מכים'],
              }),
            ],
          ),
        ),
        (
          'a long token',
          listsWith(
            rules: <Object?>[
              rule(<String, Object?>{
                'seq': <String>[List<String>.filled(40, 'מ').join()],
              }),
            ],
          ),
        ),
        (
          'a tier as a string',
          listsWith(
            rules: <Object?>[
              rule(<String, Object?>{'tier': '1'}),
            ],
          ),
        ),
        ('a list instead of a map', <String, Object?>{...bundledAlertLists, 'rules': 'none'}),
        (
          'a word row without forms',
          listsWith(
            words: <Object?>[
              <String, Object?>{'id': 'S-90', 'sub': 'SWEAR'},
            ],
          ),
        ),
        (
          'an unknown set',
          listsWith(
            rules: <Object?>[
              rule(<String, Object?>{
                'seq': <String>['@NOPE'],
              }),
            ],
          ),
        ),
      ];
      for (final (String why, Map<String, Object?> json) in bad) {
        expect(() => AlertLists.fromJson(json), throwsFormatException, reason: why);
      }
    });

    test('a window rule of more than 4 slots is refused when the lists are read (SEC-26 residual)', () {
      for (final int n in <int>[5, 8]) {
        expect(
          () => AlertLists.fromJson(
            listsWith(
              rules: <Object?>[
                rule(<String, Object?>{'seq': null, 'win': 5, 'all': List<String>.filled(n, 'מ*')}),
              ],
            ),
          ),
          throwsFormatException,
          reason: '$n slots',
        );
      }
      expect(
        AlertLists.fromJson(
          listsWith(
            rules: <Object?>[
              rule(<String, Object?>{'seq': null, 'win': 5, 'all': List<String>.filled(4, 'מ*')}),
            ],
          ),
        ),
        isNotNull,
      );
    });

    test('the worst windows a list may hold, 300 of them, on 240 words, stop within the step budget', () {
      final AlertLists worst = AlertLists.fromJson(
        listsWith(
          rules: <Object?>[
            for (int i = 0; i < 300; i++)
              rule(<String, Object?>{
                'id': 'W-${(100 + i).toString()}',
                'seq': null,
                'win': 5,
                'all': <String>['מ*', 'מ*', 'מ*', 'אאאא'],
              }),
          ],
        ),
      );
      final List<String> text = <String>[List<String>.filled(240, 'מילה').join(' ')];
      final Stopwatch w = Stopwatch()..start();
      expect(worst.check(text, ageBand: 1, answerWords: const <String>{}), isNull);
      w.stop();
      // ignore: avoid_print
      print('worst windows: ${w.elapsedMilliseconds} ms');
      expect(w.elapsedMilliseconds, lessThan(2000));
      expect(AlertLists.stepBudget, lessThanOrEqualTo(200000));
    });

    test('a real answer is far inside the budget: every bundled act still matches in a long answer', () {
      // 203 words: under the token cap, so the whole answer is looked at.
      final String filler = List<String>.filled(50, 'פרפר אדום').join(' ');
      expect(checkWords(<String>['$filler מכים אותי'])?.tier, 1);
      expect(checkWords(<String>['$filler אני רוצה למות $filler'])?.tier, 1);
    });

    test('the check off the UI isolate gives what the check on it gives', () async {
      for (final String text in <String>['מכים אותי', 'הוא מרביץ לי', 'חרא', 'ארבע']) {
        final WordMatch? here = checkWords(<String>[text]);
        final WordMatch? there = await checkWordsOffThread(<String>[text]);
        expect(
          <Object?>[there?.tier, there?.rule, there?.text],
          <Object?>[here?.tier, here?.rule, here?.text],
        );
      }
    });

    test('the most a list may ask for still checks a long answer quickly', () {
      final AlertLists worst = AlertLists.fromJson(
        listsWith(
          rules: <Object?>[
            rule(<String, Object?>{
              'seq': <String>['מ*', 'מ*', 'מ*', 'מ*', 'מ*', 'מ*', 'מ*', 'אאאא'],
              'gap': 2,
            }),
          ],
        ),
      );
      final List<String> text = <String>[List<String>.filled(400, 'מילה').join(' ')];
      worst.check(text, ageBand: 1, answerWords: const <String>{});
      final Stopwatch w = Stopwatch()..start();
      expect(worst.check(text, ageBand: 1, answerWords: const <String>{}), isNull);
      expect(w.elapsedMilliseconds, lessThan(200));
    });

    test('a long answer is looked at only at its start and its end', () {
      final String filler = List<String>.filled(2000, 'פרפר').join(' ');
      expect(checkWords(<String>['מכים אותי $filler'])?.tier, 1);
      expect(checkWords(<String>['$filler מכים אותי'])?.tier, 1);
      expect(checkWords(<String>['$filler מכים אותי $filler']), isNull, reason: 'the middle of 4,000 words');
    });

    test('a source that fails, is older, or has fewer acts keeps the lists of the app', () {
      expect(AlertLists.load(null), same(AlertLists.bundled));
      expect(AlertLists.load('garbage'), same(AlertLists.bundled));
      expect(AlertLists.load(listsWith(listVersion: '1 2')), same(AlertLists.bundled));
      expect(
        AlertLists.load(<String, Object?>{...bundledAlertLists, 'listVersion': '2026-10-28.9'}),
        same(AlertLists.bundled),
      );
      // A newer list with no acts of its own keeps every act of the app (the floor).
      final AlertLists empty = AlertLists.load(listsWith(listVersion: '2027-01-01.1'));
      expect(empty.listVersion, '2027-01-01.1');
      expect(checkWords(<String>['מכים אותי'], lists: empty)?.tier, 1);
      expect(checkWords(<String>['אני רוצה למות'], lists: empty)?.tier, 1);
      expect(checkWords(<String>['הוא מרביץ לי'], lists: empty), isNull, reason: 'only the acts are a floor');
      final AlertLists newer = AlertLists.load(<String, Object?>{
        ...bundledAlertLists,
        'listVersion': '2026-10-29.10',
      });
      expect(newer.listVersion, '2026-10-29.10', reason: 'a newer complete list is taken (10 is after 1)');
    });
  });

  group('SEC-28: keep the words off, and 30 days, on every phone', () {
    late FakeFamilyServer server;
    setUp(() => server = FakeFamilyServer());

    Future<AppDatabase> phone() async {
      final AppDatabase db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);
      return db;
    }

    SyncEngine engineOf(AppDatabase db, String id, {bool parent = true}) => SyncEngine(
      db: db,
      call: server.callFor(id, parent: parent),
      deviceId: id,
      isParent: parent,
      nowMs: () => noon.millisecondsSinceEpoch,
    );

    Future<void> addChild(AppDatabase db) => db.addProfile(
      ProfilesCompanion.insert(
        id: kid,
        name: 'נועה',
        avatar: 'avatar-noa',
        addressForm: 'f',
        ageBand: 1,
        createdAt: DateTime.utc(2026, 11, 1),
      ),
    );

    Future<void> raise(AppDatabase db, String key, {Duration ago = const Duration(hours: 1)}) => db.addAlert(
      AlertsCompanion.insert(
        at: noon.subtract(ago),
        profileId: const Value<String?>(kid),
        category: 'disclosure',
        severity: 'important',
        dedupeKey: key,
        words: const Value<String>('מכים אותי'),
      ),
    );

    test('turning it off on one parent phone empties the words on the server, the other phones and the child phone', () async {
      final AppDatabase p1 = await phone();
      final AppDatabase p2 = await phone();
      final AppDatabase child = await phone();
      await addChild(p1);
      await engineOf(p1, 'd1d1d1d1-0000-4000-8000-000000000001').syncOnce();
      await engineOf(child, dev, parent: false).syncOnce();
      await raise(child, 'words:1');
      await engineOf(child, dev, parent: false).syncOnce();
      await engineOf(p2, 'd2d2d2d2-0000-4000-8000-000000000002').syncOnce();
      expect((await p2.allAlerts()).single.words, 'מכים אותי');

      await p1.putSetting('keep_words', 'off');
      await engineOf(p1, 'd1d1d1d1-0000-4000-8000-000000000001').syncOnce();
      expect(server.alerts.single['words'] ?? '', isEmpty, reason: 'the server cleared them');
      await engineOf(p2, 'd2d2d2d2-0000-4000-8000-000000000002').syncOnce();
      await engineOf(child, dev, parent: false).syncOnce();
      expect((await p2.allAlerts()).single.words, isEmpty);
      expect((await child.allAlerts()).single.words, isEmpty);
    });

    test('a phone that does not keep the words takes none from the family', () async {
      final AppDatabase p1 = await phone();
      await addChild(p1);
      await engineOf(p1, 'd1d1d1d1-0000-4000-8000-000000000001').syncOnce();
      server.alerts.add(<String, Object?>{
        'id': 'a0', 'child_id': kid, 'category': 'disclosure', 'severity': 'important', 'count': 1, //
        'detail': '',
        'words': 'מכים אותי',
        'key': 'words:9',
        'at': noon.millisecondsSinceEpoch,
        'read_at': null,
      });
      final AppDatabase p2 = await phone();
      await p2.putSetting('keep_words', 'off');
      await engineOf(p2, 'd2d2d2d2-0000-4000-8000-000000000002').syncOnce();
      expect((await p2.allAlerts()).single.words, isEmpty);
    });

    test(
      'after a sync, and at the start, an alert older than 30 days is gone and the setting is applied',
      () async {
        final AppDatabase db = await phone();
        await raise(db, 'old', ago: const Duration(days: 31));
        await raise(db, 'new');
        await engineOf(db, dev, parent: false).syncOnce();
        expect((await db.allAlerts()).map((Alert a) => a.dedupeKey), <String>['new']);

        await db.putSetting('keep_words', 'off');
        await db.tidyAlerts(noon);
        expect((await db.allAlerts()).single.words, isEmpty);
      },
    );
  });
}
