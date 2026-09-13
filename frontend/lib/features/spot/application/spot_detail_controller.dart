import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/location/location_service.dart';
import '../../../core/network/api_exception.dart';
import '../../auth/application/auth_controller.dart';
import '../../legal/data/legal_consent_store.dart';
import '../../mission/application/mission_controller.dart';
import '../../mypage/application/user_activity_summary_controller.dart';
import '../../potato/application/potato_collection_controller.dart';
import '../../stamp/application/stamp_book_controller.dart';
import '../data/spot_detail_repository.dart';
import '../data/visit_verification_repository.dart';
import '../domain/spot_detail.dart';
import '../domain/visit_verification.dart';

final locationServiceProvider = Provider<LocationService>(
  (ref) => LocationService(
    hasPersonalLocationConsent:
        ref.watch(legalConsentStoreProvider).hasAcceptedPersonalLocation,
  ),
);

final spotDetailRepositoryProvider = Provider<SpotDetailRepository>(
  (ref) => SpotDetailRepository(dio: ref.watch(dioClientProvider).dio),
);

final visitVerificationRepositoryProvider =
    Provider<VisitVerificationRepository>(
  (ref) => VisitVerificationRepository(dio: ref.watch(dioClientProvider).dio),
);

final spotDetailProvider =
    FutureProvider.autoDispose.family<SpotDetail, String>(
  (ref, spotId) =>
      ref.watch(spotDetailRepositoryProvider).fetchSpotDetail(spotId),
);

enum VisitVerificationPhase { idle, location, server }

final visitVerificationPhaseProvider = StateProvider.autoDispose
    .family<VisitVerificationPhase, SpotDetail>((ref, spot) => VisitVerificationPhase.idle);

final visitVerificationControllerProvider = StateNotifierProvider.autoDispose
    .family<VisitVerificationController, AsyncValue<VisitVerificationResult?>,
        SpotDetail>(
  (ref, spot) => VisitVerificationController(
    spot: spot,
    repository: ref.watch(visitVerificationRepositoryProvider),
    locationService: ref.watch(locationServiceProvider),
    onSuccess: () {
      // 도감과 별도로 유지되는 성장/활동 요약도 인증 결과와 함께 갱신한다.
      ref.invalidate(potatoCollectionProvider);
      ref.invalidate(potatoGrowthSummaryProvider);
      ref.invalidate(userActivitySummaryProvider);
      ref.invalidate(stampBookProvider);
      ref.invalidate(missionsProvider);
    },
    onPhaseChanged: (phase) => ref.read(visitVerificationPhaseProvider(spot).notifier).state = phase,
  ),
);

class VisitVerificationController
    extends StateNotifier<AsyncValue<VisitVerificationResult?>> {
  VisitVerificationController({
    required SpotDetail spot,
    required VisitVerificationRepository repository,
    required LocationService locationService,
    required void Function() onSuccess,
    required void Function(VisitVerificationPhase phase) onPhaseChanged,
  })  : _spot = spot,
        _repository = repository,
        _locationService = locationService,
        _onSuccess = onSuccess,
        _onPhaseChanged = onPhaseChanged,
        super(const AsyncValue.data(null));

  final SpotDetail _spot;
  final VisitVerificationRepository _repository;
  final LocationService _locationService;
  final void Function() _onSuccess;
  final void Function(VisitVerificationPhase phase) _onPhaseChanged;

  Future<VisitVerificationResult?> verify() async {
    if (state.isLoading) {
      return null;
    }

    try {
      state = const AsyncValue.loading();
      _onPhaseChanged(VisitVerificationPhase.location);
      final position = await _locationService.getCurrentPosition();
      state = const AsyncValue.loading();
      _onPhaseChanged(VisitVerificationPhase.server);
      final result = await _repository.verifyVisit(
        VisitVerificationRequest(
          spotId: _spot.id,
          latitude: position.latitude,
          longitude: position.longitude,
        ),
      );
      state = AsyncValue.data(result);
      _onPhaseChanged(VisitVerificationPhase.idle);
      _onSuccess();
      return result;
    } on ApiException catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      _onPhaseChanged(VisitVerificationPhase.idle);
      return null;
    } on LocationFailure catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      _onPhaseChanged(VisitVerificationPhase.idle);
      return null;
    } catch (error, stackTrace) {
      state = AsyncValue.error(
        const ApiException(message: '현재 위치를 확인하지 못했습니다.'),
        stackTrace,
      );
      _onPhaseChanged(VisitVerificationPhase.idle);
      return null;
    }
  }
}
