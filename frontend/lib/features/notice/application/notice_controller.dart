import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/application/auth_controller.dart';
import '../data/notice_repository.dart';
import '../domain/notice.dart';

final noticeRepositoryProvider = Provider<NoticeRepository>(
  (ref) => NoticeRepository(dio: ref.watch(dioClientProvider).dio),
);

final noticesProvider = FutureProvider.autoDispose<List<Notice>>(
  (ref) => ref.watch(noticeRepositoryProvider).fetchNotices(),
);
