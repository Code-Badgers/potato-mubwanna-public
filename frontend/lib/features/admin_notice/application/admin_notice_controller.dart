import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/application/auth_controller.dart';
import '../data/admin_notice_repository.dart';
import '../domain/admin_notice.dart';

final adminNoticeRepositoryProvider = Provider<AdminNoticeRepository>(
  (ref) => AdminNoticeRepository(dio: ref.watch(dioClientProvider).dio),
);

final adminNoticesProvider = FutureProvider.autoDispose<List<AdminNotice>>(
  (ref) => ref.watch(adminNoticeRepositoryProvider).fetchNotices(),
);
