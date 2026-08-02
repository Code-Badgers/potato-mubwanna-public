import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../domain/potato_collection.dart';

abstract interface class PendingPotatoGrowthStore {
  Future<void> save(PotatoGrowthResult growthResult);

  Future<PotatoGrowthResult?> take();
}

class SharedPreferencesPendingPotatoGrowthStore
    implements PendingPotatoGrowthStore {
  const SharedPreferencesPendingPotatoGrowthStore();

  static const _pendingGrowthKey = 'pendingPotatoGrowthResult';

  @override
  Future<void> save(PotatoGrowthResult growthResult) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(
      _pendingGrowthKey,
      jsonEncode(growthResult.toJson()),
    );
  }

  @override
  Future<PotatoGrowthResult?> take() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.reload();
    final encodedGrowth = preferences.getString(_pendingGrowthKey);
    if (encodedGrowth == null || encodedGrowth.isEmpty) {
      return null;
    }

    await preferences.remove(_pendingGrowthKey);
    try {
      final decodedGrowth = jsonDecode(encodedGrowth);
      if (decodedGrowth is! Map<String, dynamic>) {
        return null;
      }
      return PotatoGrowthResult.fromJson(decodedGrowth);
    } catch (_) {
      return null;
    }
  }
}
