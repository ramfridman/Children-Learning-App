// The time on an alert card: day.month hours:minutes of the parent's wall clock, padded to two digits. The screen
// takes the wall clock from localTimeProvider, which is the device's own zone in the app and UTC in the golden test.
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:nitznutz/app/providers.dart';
import 'package:nitznutz/parent/alerts_screen.dart';

void main() {
  test('the card time is day.month hours:minutes with two digits each', () {
    expect(alertWhen(DateTime.utc(2026, 10, 26, 5, 33)), '26.10 05:33');
    expect(alertWhen(DateTime.utc(2026, 1, 3, 0, 7)), '03.01 00:07');
    expect(alertWhen(DateTime.utc(2026, 12, 31, 23, 59)), '31.12 23:59');
  });

  test('the parent sees the device\'s local time unless a test pins it', () {
    final ProviderContainer app = ProviderContainer();
    addTearDown(app.dispose);
    final DateTime moment = DateTime.utc(2026, 10, 25, 1, 30);
    expect(app.read(localTimeProvider)(moment), moment.toLocal());
    expect(app.read(localTimeProvider)(moment).isUtc, isFalse);

    final ProviderContainer pinned = ProviderContainer(
      overrides: <Override>[localTimeProvider.overrideWithValue((DateTime t) => t.toUtc())],
    );
    addTearDown(pinned.dispose);
    expect(alertWhen(pinned.read(localTimeProvider)(moment)), '25.10 01:30');
  });
}
