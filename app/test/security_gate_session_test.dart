import 'dart:math';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nitznutz/security/parent_gate.dart';
import 'package:nitznutz/security/parent_session.dart';

import 'support/fakes.dart';
import 'support/security_fakes.dart';

void main() {
  late MemoryStore store;
  late ControlledClock clock;
  late List<String> events;

  ParentGate make({int seed = 1}) => ParentGate(
    store: store,
    clock: clock,
    random: Random(seed),
    onEvent: (String kind, String detail) async => events.add('$kind $detail'),
  );

  setUp(() {
    store = MemoryStore();
    clock = ControlledClock(1793000000000);
    events = <String>[];
  });

  group('the questions', () {
    test('are small sums of two single digits, shown in digits', () {
      final ParentGate g = make();
      for (int i = 0; i < 200; i++) {
        final GateQuestion q = g.newQuestion();
        expect(q.a, inInclusiveRange(3, 9));
        expect(q.b, inInclusiveRange(2, 9));
        expect(q.answer, q.a + q.b);
        expect(q.answer, inInclusiveRange(5, 18));
        expect(q.expression, '${q.a} + ${q.b}');
      }
    });

    test('have a keypad with every digit exactly once, shuffled', () {
      final ParentGate g = make();
      final Set<String> orders = <String>{};
      for (int i = 0; i < 50; i++) {
        final List<int> pad = g.newQuestion().keypad;
        expect(<int>[...pad]..sort(), <int>[0, 1, 2, 3, 4, 5, 6, 7, 8, 9]);
        orders.add(pad.join());
      }
      expect(orders.length, greaterThan(40));
    });

    test('a few real questions read correctly', () {
      expect(const GateQuestion(a: 6, b: 7, keypad: <int>[]).expression, '6 + 7');
      expect(const GateQuestion(a: 6, b: 7, keypad: <int>[]).answer, 13);
      expect(const GateQuestion(a: 9, b: 9, keypad: <int>[]).answer, 18);
    });
  });

  group('the gate', () {
    test('opens on the right answer and refuses a wrong one', () async {
      final ParentGate g = make();
      final GateQuestion q = g.newQuestion();
      expect(await g.submit(q, '${q.answer}'), isA<GateOk>());
      expect(await g.submit(q, '${q.answer + 1}'), isA<GateWrong>());
      expect(await g.submit(q, ''), isA<GateWrong>());
    });

    test('3 wrong answers in a row give a 30 second cool-down, also for the right answer', () async {
      final ParentGate g = make();
      final GateQuestion q = g.newQuestion();
      expect(await g.submit(q, '1'), isA<GateWrong>());
      expect(await g.submit(q, '2'), isA<GateWrong>());
      final GateOutcome third = await g.submit(q, '3');
      expect(third, isA<GateWait>());
      expect((third as GateWait).remaining, const Duration(seconds: 30));
      expect(third.long, isFalse);
      expect(await g.submit(q, '${q.answer}'), isA<GateWait>());
      clock.advance(const Duration(seconds: 31));
      expect(await g.submit(q, '${q.answer}'), isA<GateOk>());
    });

    test('5 wrong answers within 2 minutes lock the gate for 10 minutes', () async {
      final ParentGate g = make();
      final GateQuestion q = g.newQuestion();
      GateOutcome last = const GateOk();
      for (int i = 0; i < 5; i++) {
        last = await g.submit(q, '${i + 1000}');
        // A person waits out each 30 second cool-down before trying again.
        if (last is GateWait && !last.long) clock.advance(const Duration(seconds: 31));
      }
      expect(last, isA<GateWait>());
      expect((last as GateWait).long, isTrue);
      expect(last.remaining, const Duration(minutes: 10));
    });

    test('a long lock is not ended by the 30 second cool-down, only by its 10 minutes', () async {
      final ParentGate g = make();
      final GateQuestion q = g.newQuestion();
      for (int i = 0; i < 5; i++) {
        final GateOutcome o = await g.submit(q, 'x');
        if (o is GateWait && !o.long) clock.advance(const Duration(seconds: 31));
      }
      expect(await g.submit(q, '${q.answer}'), isA<GateWait>());
      clock.advance(const Duration(minutes: 1));
      expect(await g.submit(q, '${q.answer}'), isA<GateWait>());
      clock.advance(const Duration(minutes: 10));
      expect(await g.submit(q, '${q.answer}'), isA<GateOk>());
    });

    test('a right answer clears the run of wrong ones', () async {
      final ParentGate g = make();
      final GateQuestion q = g.newQuestion();
      await g.submit(q, '1');
      await g.submit(q, '2');
      expect(await g.submit(q, '${q.answer}'), isA<GateOk>());
      expect(await g.submit(q, '1'), isA<GateWrong>());
      expect(await g.submit(q, '2'), isA<GateWrong>());
    });

    test('the cool-down survives closing the app', () async {
      final ParentGate first = make();
      final GateQuestion q = first.newQuestion();
      for (int i = 0; i < 3; i++) {
        await first.submit(q, 'x');
      }
      expect(await make().waiting(), isNotNull);
    });

    test('events: the 3rd wrong answer and the lock are recorded, with no answers in them', () async {
      final ParentGate g = make();
      final GateQuestion q = g.newQuestion();
      for (int i = 0; i < 5; i++) {
        final GateOutcome o = await g.submit(q, '9999');
        if (o is GateWait && !o.long) clock.advance(const Duration(seconds: 31));
      }
      expect(events, <String>['gate_alert n=3', 'gate_lock min=10']);
    });
  });

  group('the parent session', () {
    late FakePlatform phone;
    late ParentSession session;

    setUp(() {
      phone = FakePlatform();
      session = ParentSession(platform: phone);
    });
    tearDown(() => session.dispose());

    testWidgets('is closed at the start and opens only when told to', (WidgetTester tester) async {
      expect(session.unlocked.value, isFalse);
      await session.unlock();
      expect(session.unlocked.value, isTrue);
      expect(phone.secure, isTrue, reason: 'screenshots are blocked while the parent area is open');
      session.lock();
    });

    testWidgets('closes after 5 idle minutes and lifts the screenshot block', (WidgetTester tester) async {
      await session.unlock();
      await tester.pump(const Duration(minutes: 4, seconds: 59));
      expect(session.unlocked.value, isTrue);
      await tester.pump(const Duration(seconds: 2));
      expect(session.unlocked.value, isFalse);
      expect(phone.secure, isFalse);
    });

    testWidgets('every touch restarts the idle clock', (WidgetTester tester) async {
      await session.unlock();
      for (int i = 0; i < 4; i++) {
        await tester.pump(const Duration(minutes: 4));
        session.touch();
      }
      expect(session.unlocked.value, isTrue);
      await tester.pump(const Duration(minutes: 5, seconds: 1));
      expect(session.unlocked.value, isFalse);
    });

    testWidgets('closes the moment the app goes to the background', (WidgetTester tester) async {
      await session.unlock();
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      expect(session.unlocked.value, isFalse);
      expect(phone.secure, isFalse);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      expect(session.unlocked.value, isFalse, reason: 'coming back does not reopen it');
    });

    testWidgets('a brief interruption (inactive) does not close it, but hidden does', (
      WidgetTester tester,
    ) async {
      await session.unlock();
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      expect(session.unlocked.value, isTrue);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
      expect(session.unlocked.value, isFalse);
    });

    testWidgets('touching while closed does nothing, and locking twice is harmless', (
      WidgetTester tester,
    ) async {
      session.touch();
      session.lock();
      session.lock();
      expect(session.unlocked.value, isFalse);
      expect(phone.secureCalls, isEmpty);
    });
  });
}
