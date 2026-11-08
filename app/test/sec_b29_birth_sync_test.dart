// Security-engineer proofs for the B-29 birth sync review (2026-11-08). Run from D:\nitznutz-b29-steps5-9\app.
import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nitznutz/core/errors.dart';
import 'package:nitznutz/data/app_database.dart';
import 'package:nitznutz/engine/age.dart';
import 'package:nitznutz/sync/sync_engine.dart';

import 'support/fake_family_server.dart';

const String kid = 'child-aaaa-0001';
const String dev1 = 'd1d1d1d1-0000-4000-8000-000000000001';
const String dev3 = 'd3d3d3d3-0000-4000-8000-000000000003';
final int noon = DateTime.utc(2026, 11, 20, 12).millisecondsSinceEpoch;

typedef Call = Future<Map<String, Object?>> Function(String, Map<String, Object?>);

class Phone {
  Phone(
    this.id,
    FakeFamilyServer server, {
    bool parent = true,
    Call Function(Call)? wrap,
    int Function()? nowMs,
  }) : db = AppDatabase(NativeDatabase.memory()) {
    final Call base = server.callFor(id, parent: parent);
    engine = SyncEngine(
      db: db,
      call: wrap == null ? base : wrap(base),
      deviceId: id,
      isParent: parent,
      nowMs: nowMs ?? () => noon,
      pageSize: 4,
      batch: 4,
    );
  }
  final String id;
  final AppDatabase db;
  late final SyncEngine engine;

  Future<void> addChild() => db.addProfile(
    ProfilesCompanion.insert(
      id: kid,
      name: 'נועה',
      avatar: 'avatar-noa',
      addressForm: 'f',
      ageBand: 1,
      createdAt: DateTime.utc(2026, 11, 1),
    ),
  );
}

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  test(
    'SEC-B29-6: on a child-role device the server copy wins; a local birth edit there never sticks for ever',
    () async {
      final FakeFamilyServer server = FakeFamilyServer();
      final Phone parent = Phone(dev1, server);
      final Phone kidPhone = Phone(dev3, server, parent: false);
      addTearDown(parent.db.close);
      addTearDown(kidPhone.db.close);
      await parent.addChild();
      await parent.db.setBirth(kid, const BirthMonth(2018, 12));
      await parent.engine.syncOnce();
      await kidPhone.engine.syncOnce();
      expect(await kidPhone.db.birthOf(kid), const BirthMonth(2018, 12));

      // A parent opens the age page on the child's tablet (no role check) and changes the month there.
      await kidPhone.db.setBirth(kid, const BirthMonth(2019, 3));
      // Later the parent clears the birth on the parent phone (wants it gone everywhere).
      await parent.db.setBirth(kid, null);
      await parent.engine.syncOnce();
      expect(server.children[kid]!['birth'], isNull);
      for (int i = 0; i < 3; i++) {
        await kidPhone.engine.syncOnce();
      }
      expect(
        await kidPhone.db.birthOf(kid),
        isNull,
        reason: 'a child device cannot send, so it must take the server copy',
      );
    },
  );

  group('SEC-B29-5 deploy order', () {
    // The old child-put: the shape refuses the unknown key `birth` (the client sees only bad_request, 400).
    Call Function(Call) old(List<String> seen, {bool Function()? stillOld}) {
      return (Call base) => (String name, Map<String, Object?> body) async {
        if (name == 'child-put') seen.add(body.containsKey('birth') ? 'with' : 'without');
        if (name == 'child-put' && body.containsKey('birth') && (stillOld?.call() ?? true)) {
          throw const GatewayException('bad_request', status: 400);
        }
        return base(name, body);
      };
    }

    test('an app that sends `birth` to a child-put without it still saves the child, and keeps the birth waiting', () async {
      final FakeFamilyServer server = FakeFamilyServer();
      final List<String> seen = <String>[];
      final Phone p = Phone(dev1, server, wrap: old(seen));
      addTearDown(p.db.close);
      await p.addChild();
      await p.db.setBirth(kid, const BirthMonth(2021, 5));
      for (int i = 0; i < 3; i++) {
        await p.engine.syncOnce();
      }
      expect(
        server.children.containsKey(kid),
        isTrue,
        reason: 'the child (and so its held answers) must reach the server',
      );
      expect(server.children[kid]!['birth'], isNull);
      expect(
        await p.db.birthOf(kid),
        const BirthMonth(2021, 5),
        reason: 'the birth waits on the phone, a pull never wipes it',
      );
      expect(seen, <String>[
        'with',
        'without',
      ], reason: 'one refused call, one retry, then nothing more in the next rounds');
    });

    test('after a restart the birth is tried again and, once the function knows it, saved', () async {
      final FakeFamilyServer server = FakeFamilyServer();
      bool stillOld = true;
      final List<String> seen = <String>[];
      final Phone first = Phone(dev1, server, wrap: old(seen, stillOld: () => stillOld));
      addTearDown(first.db.close);
      await first.addChild();
      await first.db.setBirth(kid, const BirthMonth(2021, 5));
      await first.engine.syncOnce();
      expect(server.children.containsKey(kid), isTrue);
      stillOld = false;
      // The same engine does not ask again until 24 hours have gone; a new start does, on the same database.
      await first.engine.syncOnce();
      expect(server.children[kid]!['birth'], isNull);
      final SyncEngine restarted = SyncEngine(
        db: first.db,
        call: old(seen, stillOld: () => stillOld)(server.callFor(dev1, parent: true)),
        deviceId: dev1,
        isParent: true,
        nowMs: () => noon,
        pageSize: 4,
        batch: 4,
      );
      await restarted.syncOnce();
      expect(server.children[kid]!['birth'], <String, Object?>{'year': 2021, 'month': 5});
    });

    test('the refusal is forgotten after 24 hours', () async {
      final FakeFamilyServer server = FakeFamilyServer();
      bool stillOld = true;
      int now = noon;
      final Phone p = Phone(
        dev1,
        server,
        wrap: (Call base) => (String name, Map<String, Object?> body) async {
          if (name == 'child-put' && body.containsKey('birth') && stillOld) {
            throw const GatewayException('bad_request', status: 400);
          }
          return base(name, body);
        },
        nowMs: () => now,
      );
      addTearDown(p.db.close);
      await p.addChild();
      await p.db.setBirth(kid, const BirthMonth(2021, 5));
      await p.engine.syncOnce();
      stillOld = false;
      now += const Duration(hours: 23).inMilliseconds;
      await p.engine.syncOnce();
      expect(server.children[kid]!['birth'], isNull, reason: 'inside the 24 hours it is not asked again');
      now += const Duration(hours: 2).inMilliseconds;
      await p.engine.syncOnce();
      expect(server.children[kid]!['birth'], <String, Object?>{'year': 2021, 'month': 5});
    });

    test('a bad_request for a put without `birth` still leaves the child unsaved, as before', () async {
      final FakeFamilyServer server = FakeFamilyServer();
      int calls = 0;
      final Phone p = Phone(
        dev1,
        server,
        wrap: (Call base) => (String name, Map<String, Object?> body) async {
          if (name == 'child-put') {
            calls++;
            throw const GatewayException('bad_request', status: 400);
          }
          return base(name, body);
        },
      );
      addTearDown(p.db.close);
      await p.addChild();
      await p.engine.syncOnce();
      expect(server.children.containsKey(kid), isFalse);
      expect(calls, 1, reason: 'no birth, so no retry');
    });
  });
}
