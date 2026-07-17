import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/application/auth_controller.dart';
import '../data/reward_history_repository.dart';
import '../domain/reward_history.dart';

final rewardHistoryRepositoryProvider = Provider<RewardHistoryRepository>(
  (ref) => RewardHistoryRepository(dio: ref.watch(dioClientProvider).dio),
);

final rewardHistoryProvider = FutureProvider.autoDispose<List<RewardHistory>?>(
  (ref) async {
    final authStatus = ref.watch(
      authControllerProvider.select((state) => state.status),
    );
    if (authStatus != AuthStatus.authenticated) {
      return null;
    }
    return ref.watch(rewardHistoryRepositoryProvider).fetchRewardHistory();
  },
);
