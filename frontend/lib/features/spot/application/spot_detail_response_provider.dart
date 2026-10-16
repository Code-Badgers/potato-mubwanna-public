import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/application/auth_controller.dart';
import '../data/spot_detail_repository.dart';

final spotDetailRepositoryProvider = Provider<SpotDetailRepository>(
  (ref) => SpotDetailRepository(dio: ref.watch(dioClientProvider).dio),
);

const spotDetailCacheDuration = Duration(minutes: 2);

Future<Map<String, dynamic>> _loadAndKeepResponse(
  Ref<Object?> ref,
  Future<Map<String, dynamic>> Function() load,
) async {
  // Reuse an in-flight request even across a brief gap between the two screens.
  final link = ref.keepAlive();
  var disposed = false;
  ref.onDispose(() => disposed = true);
  try {
    final response = await load();
    if (!disposed) {
      final timer = Timer(spotDetailCacheDuration, link.close);
      ref.onDispose(timer.cancel);
    }
    return response;
  } catch (_) {
    if (!disposed) {
      link.close();
    }
    rethrow;
  }
}

// Both domain models share the same response and in-flight request.
final spotDetailResponseProvider = FutureProvider.autoDispose
    .family<Map<String, dynamic>, String>((ref, id) => _loadAndKeepResponse(
          ref,
          () => ref
              .watch(spotDetailRepositoryProvider)
              .fetchSpotDetailPayload(id),
        ));

final spotBasicDetailResponseProvider = FutureProvider.autoDispose
    .family<Map<String, dynamic>, String>((ref, id) => _loadAndKeepResponse(
          ref,
          () => ref
              .watch(spotDetailRepositoryProvider)
              .fetchSpotDetailPayload(id, basic: true),
        ));
