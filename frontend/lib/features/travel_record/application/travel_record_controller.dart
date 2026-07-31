import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/application/auth_controller.dart';
import '../data/travel_record_repository.dart';
import '../domain/travel_record.dart';

final travelRecordRepositoryProvider = Provider<TravelRecordRepository>(
  (ref) => TravelRecordRepository(dio: ref.watch(dioClientProvider).dio),
);

final travelRecordsProvider = FutureProvider.autoDispose<List<TravelRecord>>(
  (ref) => ref.watch(travelRecordRepositoryProvider).fetchTravelRecords(),
);
