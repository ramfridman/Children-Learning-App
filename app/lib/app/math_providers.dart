import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../play/math_signs.dart';
import 'state.dart';

const String _divisionKey = 'division_sign';

/// The sign a division is drawn with on this device: ÷ until a parent chooses the colon (CLAUDE.md, Hebrew rules). Kept with the app's
/// other device settings; it is not synced.
class DivisionSetting extends AsyncNotifier<DivisionSign> {
  @override
  Future<DivisionSign> build() async =>
      DivisionSign.fromStored(await (await ref.watch(databaseProvider.future)).setting(_divisionKey));

  Future<void> set(DivisionSign sign) async {
    await (await ref.read(databaseProvider.future)).putSetting(_divisionKey, sign.stored);
    state = AsyncData<DivisionSign>(sign);
  }
}

final AsyncNotifierProvider<DivisionSetting, DivisionSign> divisionSignProvider =
    AsyncNotifierProvider<DivisionSetting, DivisionSign>(DivisionSetting.new);
