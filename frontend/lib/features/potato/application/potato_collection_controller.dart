import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/application/auth_controller.dart';
import '../data/potato_repository.dart';
import '../domain/potato_collection.dart';

final potatoRepositoryProvider = Provider<PotatoRepository>(
  (ref) => PotatoRepository(dio: ref.watch(dioClientProvider).dio),
);

final potatoCollectionProvider =
    FutureProvider.autoDispose<PotatoCollection?>((ref) async {
  final authStatus = ref.watch(
    authControllerProvider.select((state) => state.status),
  );
  if (authStatus != AuthStatus.authenticated) {
    return null;
  }

  return ref.watch(potatoRepositoryProvider).fetchMyPotatoes();
});
