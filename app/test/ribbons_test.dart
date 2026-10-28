// The parents' promises and the child's prize (M8b): what a promise may say, where it lives, that it goes with the family's
// settings and with the child, that the alert for a trophy holds only the trophy's key, and that the prize a companion
// wears reaches the family's other phones without ever being wiped by a phone that has not heard of it.
import 'dart:convert';

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nitznutz/data/app_database.dart';
import 'package:nitznutz/rewards/ribbon_alerts.dart';
import 'package:nitznutz/rewards/ribbons.dart';
import 'package:nitznutz/strings/niqqud.dart';

import 'engine/fixtures.dart';
import 'support/fake_family_server.dart';
import 'sync_engine_test.dart' show Phone, dev1, dev2, kid;

const String gold = 'trophy:counting:gold';
const String silver = 'trophy:counting:silver';
const String promise = 'הולכים לגלידה';

Reward trophy(int id, String key) => Reward(
  id: id,
  profileId: kid,
  awardKey: key,
  kind: 'trophy',
  at: day0,
  seenAt: null,
  eventId: null,
  syncedAt: null,
);

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  group('what a promise may say', () {
    test('1 to 60 plain characters', () {
      expect(checkPromise(promise), PromiseCheck.ok);
      expect(checkPromise('א' * 60), PromiseCheck.ok);
      expect(checkPromise('א' * 61), PromiseCheck.tooLong);
      expect(checkPromise(''), PromiseCheck.empty);
      expect(checkPromise('   '), PromiseCheck.empty);
    });

    test('no links, no addresses, no markup, no control characters (the server refuses the same)', () {
      for (final String bad in <String>[
        'https://example.com',
        'http://x',
        'www.example.com',
        'גלידה אצל x@y.com',
        'go to shop.co now',
        'shop.com',
      ]) {
        expect(checkPromise(bad), PromiseCheck.link, reason: bad);
      }
      for (final String bad in <String>['<b>גלידה</b>', 'גלידה\nבפארק', 'a\u0007b']) {
        expect(checkPromise(bad), PromiseCheck.badCharacter, reason: bad);
      }
      expect(checkPromise('הולכים לגלידה, יום שישי!'), PromiseCheck.ok, reason: 'punctuation is fine');
    });
  });

  group('the promises as a whole', () {
    test('they are kept by child and trophy, read back, and a damaged value is no promises', () {
      Promises p = const <String, Map<String, String>>{};
      p = withPromise(p, kid, gold, promise)!;
      p = withPromise(p, kid, silver, 'יום בפארק')!;
      expect(decodeRibbons(encodeRibbons(p)), p);
      expect(decodeRibbons(null), isEmpty);
      expect(decodeRibbons('not json'), isEmpty);
      expect(decodeRibbons('[1]'), isEmpty);
      expect(
        decodeRibbons('{"$kid":{"$gold":"https://x.com"}}')[kid],
        isEmpty,
        reason: 'a bad promise is dropped',
      );
    });

    test('empty words remove a promise; too many are refused; another child\'s are not touched', () {
      Promises p = withPromise(const <String, Map<String, String>>{}, kid, gold, promise)!;
      p = withPromise(p, 'child-bbbb-0002', gold, 'שוקו')!;
      expect(withPromise(p, kid, gold, '')![kid], isEmpty);
      expect(withPromise(p, kid, gold, '')!['child-bbbb-0002'], <String, String>{gold: 'שוקו'});
      expect(withPromise(p, kid, gold, '<b>'), isNull);
      Promises many = const <String, Map<String, String>>{};
      for (int i = 0; i < maxPromises; i++) {
        many = withPromise(many, 'child-aaaa-00${i ~/ 10}0', 'trophy:land$i:gold', 'x')!;
      }
      expect(countPromises(many), maxPromises);
      expect(withPromise(many, kid, gold, 'one more'), isNull);
      expect(withPromise(many, kid, gold, ''), isNotNull, reason: 'removing is always allowed');
    });

    test('a removed child\'s promises go with the child', () {
      final Promises p = withPromise(
        withPromise(const <String, Map<String, String>>{}, kid, gold, promise)!,
        'child-bbbb-0002',
        gold,
        'שוקו',
      )!;
      expect(withoutChild(p, kid).keys, <String>['child-bbbb-0002']);
    });

    test('the adult screens read a land\'s name without niqqud', () {
      expect(withoutNiqqud('גִּבְעוֹת הַסְּפִירָה'), 'גבעות הספירה');
    });
  });

  group('the alert for a trophy with a promise', () {
    late AppDatabase db;
    setUp(() async {
      db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);
      await db.putSetting(
        'ribbons',
        encodeRibbons(<String, Map<String, String>>{
          kid: <String, String>{gold: promise},
        }),
      );
    });

    test('it holds the child and the trophy\'s key, and never the words', () async {
      final int n = await raiseRibbonAlerts(db, childId: kid, fresh: <Reward>[trophy(1, gold)], now: day0);
      expect(n, 1);
      final Alert a = (await db.allAlerts()).single;
      expect(a.category, 'ribbonEarned');
      expect(a.severity, 'info');
      expect(a.profileId, kid);
      expect(a.detail, gold);
      expect(a.words, isEmpty);
      expect(jsonEncode(<String>[a.category, a.detail, a.words, a.dedupeKey]).contains(promise), isFalse);
    });

    test(
      'only for a trophy that has a promise, once however often it is looked at, and never for another child',
      () async {
        expect(await raiseRibbonAlerts(db, childId: kid, fresh: <Reward>[trophy(1, silver)], now: day0), 0);
        expect(
          await raiseRibbonAlerts(
            db,
            childId: kid,
            fresh: <Reward>[
              Reward(
                id: 2,
                profileId: kid,
                awardKey: 'sticker:butterflies:1',
                kind: 'sticker',
                at: day0,
                seenAt: null,
                eventId: null,
                syncedAt: null,
              ),
            ],
            now: day0,
          ),
          0,
        );
        expect(await raiseRibbonAlerts(db, childId: kid, fresh: <Reward>[trophy(3, gold)], now: day0), 1);
        expect(await raiseRibbonAlerts(db, childId: kid, fresh: <Reward>[trophy(3, gold)], now: day0), 0);
        expect(
          await raiseRibbonAlerts(
            db,
            childId: 'child-bbbb-0002',
            fresh: <Reward>[trophy(4, gold)],
            now: day0,
          ),
          0,
        );
        expect(await db.allAlerts(), hasLength(1));
      },
    );

    test('deleting the child deletes the promises here too', () async {
      await db.putSetting(
        'ribbons',
        encodeRibbons(<String, Map<String, String>>{
          kid: <String, String>{gold: promise},
          'child-bbbb-0002': <String, String>{gold: 'שוקו'},
        }),
      );
      await db.deleteChildData(kid);
      final Promises left = decodeRibbons(await db.setting('ribbons'));
      expect(left.containsKey(kid), isFalse);
      expect(left['child-bbbb-0002'], <String, String>{gold: 'שוקו'});
    });
  });

  group('across the family\'s phones', () {
    late FakeFamilyServer server;
    late Phone p1;
    late Phone p2;
    setUp(() {
      server = FakeFamilyServer();
      p1 = Phone(dev1, server);
      p2 = Phone(dev2, server);
    });
    tearDown(() async {
      await p1.db.close();
      await p2.db.close();
    });

    test(
      'the ceremony switch and the promises are family rules: set on one phone, taken by the other',
      () async {
        await p1.engine.syncOnce(); // the family's first rules
        await p1.db.putSetting('ceremonies', 'off');
        await p1.db.putSetting(
          'ribbons',
          encodeRibbons(<String, Map<String, String>>{
            kid: <String, String>{gold: promise},
          }),
        );
        await p1.engine.syncOnce();
        expect(server.rules!['ceremonies'], isFalse);
        expect((server.rules!['ribbons']! as Map<String, Object?>)[kid], <String, Object?>{gold: promise});

        final report = await p2.engine.syncOnce();
        expect(report.rulesApplied, isTrue);
        expect(await p2.db.setting('ceremonies'), 'off');
        expect(decodeRibbons(await p2.db.setting('ribbons'))[kid], <String, String>{gold: promise});
      },
    );

    test('a promise that is not allowed is not taken from the server, whoever put it there', () async {
      server.rules = <String, Object?>{
        'ribbons': <String, Object?>{
          kid: <String, Object?>{gold: 'https://evil.example', silver: 'יום בפארק'},
        },
      };
      server.rulesVersion = 3;
      await p2.engine.syncOnce();
      expect(decodeRibbons(await p2.db.setting('ribbons'))[kid], <String, String>{silver: 'יום בפארק'});
    });

    test(
      'the alert that reaches the parents holds the trophy and not the words, and no event does either',
      () async {
        await p1.addChild();
        await p1.db.putSetting(
          'ribbons',
          encodeRibbons(<String, Map<String, String>>{
            kid: <String, String>{gold: promise},
          }),
        );
        await raiseRibbonAlerts(p1.db, childId: kid, fresh: <Reward>[trophy(1, gold)], now: day0);
        await p1.engine.syncOnce();
        expect(server.alerts, hasLength(1));
        expect(server.alerts.single['category'], 'ribbonEarned');
        expect(server.alerts.single['detail'], gold);
        expect(jsonEncode(server.alerts).contains(promise), isFalse);
        expect(jsonEncode(server.log).contains(promise), isFalse);
        // The parent's other phone reads the words from the family's rules, never from the alert.
        await p2.engine.syncOnce();
        expect(decodeRibbons(await p2.db.setting('ribbons'))[kid]![gold], promise);
        expect((await p2.db.allAlerts()).single.detail, gold);
      },
    );

    test('the prize the companion wears reaches the other phone; a phone that has not heard of one never wipes it', () async {
      await p1.addChild();
      await p1.db.setOutfit(kid, 'sky');
      await p1.engine.syncOnce();
      expect(server.children[kid]!['outfit_id'], 'sky');
      await p2.engine.syncOnce();
      expect(await p2.db.outfitOf(kid), 'sky');

      // The server's copy has no prize (an older phone saved the child): the choice made here stays.
      server.children[kid]!['outfit_id'] = null;
      await p2.engine.syncOnce();
      expect(await p2.db.outfitOf(kid), 'sky');
      // And since this is a parent phone, it sends the choice back to the family.
      await p2.engine.syncOnce();
      expect(server.children[kid]!['outfit_id'], 'sky');
    });

    test('choosing no scarf is a choice that travels too', () async {
      await p1.addChild();
      await p1.db.setOutfit(kid, 'sky');
      await p1.engine.syncOnce();
      await p2.engine.syncOnce();
      await p1.db.setOutfit(kid, 'none');
      await p1.engine.syncOnce();
      expect(server.children[kid]!['outfit_id'], 'none');
      await p2.engine.syncOnce();
      expect(await p2.db.outfitOf(kid), 'none');
    });
  });
}
