import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show FutureProviderFamily;

import '../rewards/ribbons.dart';
import 'state.dart';

/// The setting that holds the parents' promises: child id, then trophy key, then the words (M8, Q9). It is part of the
/// family's rules, so every phone has the same ones.
const String ribbonsKey = 'ribbons';

/// What the parents promised one child, by trophy key (for example `trophy:counting:gold`). Shown on that child's trophy
/// only; never sent anywhere but the family's own settings.
final FutureProviderFamily<Map<String, String>, String> ribbonsProvider =
    FutureProvider.family<Map<String, String>, String>((Ref ref, String childId) async {
      final String? text = await (await ref.watch(databaseProvider.future)).setting(ribbonsKey);
      return decodeRibbons(text)[childId] ?? const <String, String>{};
    });
