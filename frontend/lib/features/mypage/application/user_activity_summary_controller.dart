import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/application/auth_controller.dart';
import '../data/user_activity_summary_repository.dart';
import '../domain/user_activity_summary.dart';

final userActivitySummaryRepositoryProvider =
    Provider<UserActivitySummaryRepository>(
      (ref) =>
          UserActivitySummaryRepository(dio: ref.watch(dioClientProvider).dio),
    );

final userActivitySummaryProvider =
    FutureProvider.autoDispose<UserActivitySummary?>((ref) async {
      final authStatus = ref.watch(
        authControllerProvider.select((state) => state.status),
      );
      if (authStatus != AuthStatus.authenticated) {
        return null;
      }

      return ref
          .watch(userActivitySummaryRepositoryProvider)
          .fetchActivitySummary();
    });
