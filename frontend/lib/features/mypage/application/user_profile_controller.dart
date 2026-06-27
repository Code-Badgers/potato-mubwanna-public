import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/application/auth_controller.dart';
import '../data/user_profile_repository.dart';
import '../domain/user_profile.dart';

final userProfileRepositoryProvider = Provider<UserProfileRepository>(
  (ref) => UserProfileRepository(dio: ref.watch(dioClientProvider).dio),
);

final userProfileProvider = FutureProvider.autoDispose<UserProfile>(
  (ref) => ref.watch(userProfileRepositoryProvider).fetchProfile(),
);
