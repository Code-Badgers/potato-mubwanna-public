import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/application/auth_controller.dart';
import '../data/audio_guide_repository.dart';
import '../domain/audio_guide.dart';

final audioGuideRepositoryProvider = Provider<AudioGuideRepository>(
  (ref) => AudioGuideRepository(dio: ref.watch(dioClientProvider).dio),
);

final audioGuideProvider =
    FutureProvider.autoDispose.family<AudioGuide, String>(
  (ref, spotId) =>
      ref.watch(audioGuideRepositoryProvider).fetchAudioGuide(spotId),
);
