import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show FutureProviderFamily;

import 'state.dart';

/// The setting that holds the parents' promises: child id, then trophy key, then the words (M8, Q9). It is part of the
/// family's rules, so every phone has the same ones.
const String ribbonsKey = 'ribbons';

/// Reads the promises of every child from the setting's text. A damaged value is no promises at all.
Map<String, Map<String, String>> decodeRibbons(String? text) {
  if (text == null || text.isEmpty) return const <String, Map<String, String>>{};
  try {
    final Object? j = jsonDecode(text);
    if (j is! Map<String, Object?>) return const <String, Map<String, String>>{};
    return <String, Map<String, String>>{
      for (final MapEntry<String, Object?> kid in j.entries)
        if (kid.value is Map<String, Object?>)
          kid.key: <String, String>{
            for (final MapEntry<String, Object?> r in (kid.value! as Map<String, Object?>).entries)
              if (r.value is String && (r.value! as String).trim().isNotEmpty) r.key: r.value! as String,
          },
    };
  } on FormatException {
    return const <String, Map<String, String>>{};
  }
}

/// What the parents promised one child, by trophy key (for example `trophy:counting:gold`). Shown on that child's trophy
/// only; never sent anywhere but the family's own settings.
final FutureProviderFamily<Map<String, String>, String> ribbonsProvider =
    FutureProvider.family<Map<String, String>, String>((Ref ref, String childId) async {
      final String? text = await (await ref.watch(databaseProvider.future)).setting(ribbonsKey);
      return decodeRibbons(text)[childId] ?? const <String, String>{};
    });
