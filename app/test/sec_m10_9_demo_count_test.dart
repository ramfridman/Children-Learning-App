// SEC-M10-9 (info): the count of block demonstrations a child has seen (`blocks.demo.<profileId>`, a setting of this phone) goes with
// the child when a parent deletes the child, like every other per-child setting (`deleteChildData`: "everything this device holds about
// a child").
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nitznutz/data/app_database.dart';

const String kid = 'child-aaaa-0001';
const String kid2 = 'child-aaaa-0002';

void main() {
  test('SEC-M10-9: deleting a child deletes its block-demonstration count, and only its own', () async {
    final AppDatabase db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    await db.putSetting('blocks.demo.$kid', '2');
    await db.putSetting('blocks.demo.$kid2', '1');
    await db.deleteChildData(kid);
    expect(await db.setting('blocks.demo.$kid'), isNull);
    expect(await db.setting('blocks.demo.$kid2'), '1');
  });
}
