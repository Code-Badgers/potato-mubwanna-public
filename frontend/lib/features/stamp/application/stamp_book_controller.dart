import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/application/auth_controller.dart';
import '../data/stamp_repository.dart';
import '../domain/stamp_book.dart';

final stampRepositoryProvider = Provider<StampRepository>(
  (ref) => StampRepository(dio: ref.watch(dioClientProvider).dio),
);

final stampBookProvider = FutureProvider.autoDispose<StampBook?>(
  (ref) async {
    final authStatus = ref.watch(
      authControllerProvider.select((state) => state.status),
    );
    if (authStatus != AuthStatus.authenticated) {
      return null;
    }

    return ref.watch(stampRepositoryProvider).fetchStampBook();
  },
);
