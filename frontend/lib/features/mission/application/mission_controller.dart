import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/mission_repository.dart';
import '../domain/mission_challenge.dart';

final missionRepositoryProvider = Provider<MissionRepository>(
  (_) => const MissionRepository(),
);

final missionsProvider = Provider<List<MissionChallenge>>(
  (ref) => ref.watch(missionRepositoryProvider).fetchMissions(),
);

final missionByIdProvider = Provider.family<MissionChallenge?, String>(
  (ref, missionId) {
    for (final mission in ref.watch(missionsProvider)) {
      if (mission.id == missionId) {
        return mission;
      }
    }
    return null;
  },
);
