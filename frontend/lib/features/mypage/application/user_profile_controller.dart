import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/application/auth_controller.dart';
import '../data/user_profile_repository.dart';
import '../domain/user_profile.dart';

final userProfileRepositoryProvider = Provider<UserProfileRepository>(
  (ref) => UserProfileRepository(dio: ref.watch(dioClientProvider).dio),
);

final userProfileProvider = FutureProvider.autoDispose<UserProfile?>(
  (ref) async {
    final authStatus = ref.watch(
      authControllerProvider.select((state) => state.status),
    );
    if (authStatus != AuthStatus.authenticated) {
      return null;
    }

    return ref.watch(userProfileRepositoryProvider).fetchProfile();
  },
);
