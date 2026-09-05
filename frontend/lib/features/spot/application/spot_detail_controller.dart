import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/location/location_service.dart';
import '../../../core/network/api_exception.dart';
import '../../auth/application/auth_controller.dart';
import '../../legal/data/legal_consent_store.dart';
import '../../mission/application/mission_controller.dart';
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

final visitVerificationControllerProvider = StateNotifierProvider.autoDispose
    .family<VisitVerificationController, AsyncValue<VisitVerificationResult?>,
        SpotDetail>(
  (ref, spot) => VisitVerificationController(
    spot: spot,
    repository: ref.watch(visitVerificationRepositoryProvider),
    locationService: ref.watch(locationServiceProvider),
    onSuccess: () {
      ref.invalidate(potatoCollectionProvider);
      ref.invalidate(stampBookProvider);
      ref.invalidate(missionsProvider);
    },
  ),
);

class VisitVerificationController
    extends StateNotifier<AsyncValue<VisitVerificationResult?>> {
  VisitVerificationController({
    required SpotDetail spot,
    required VisitVerificationRepository repository,
    required LocationService locationService,
    required void Function() onSuccess,
  })  : _spot = spot,
        _repository = repository,
        _locationService = locationService,
        _onSuccess = onSuccess,
        super(const AsyncValue.data(null));

  final SpotDetail _spot;
  final VisitVerificationRepository _repository;
  final LocationService _locationService;
  final void Function() _onSuccess;

  Future<VisitVerificationResult?> verify() async {
    if (state.isLoading) {
      return null;
    }

    try {
      state = const AsyncValue.loading();
      final position = await _locationService.getCurrentPosition();
      final result = await _repository.verifyVisit(
        VisitVerificationRequest(
          spotId: _spot.id,
          latitude: position.latitude,
          longitude: position.longitude,
        ),
      );
      state = AsyncValue.data(result);
      _onSuccess();
      return result;
    } on ApiException catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      return null;
    } on LocationFailure catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      return null;
    } catch (error, stackTrace) {
      state = AsyncValue.error(
        const ApiException(message: '현재 위치를 확인하지 못했습니다.'),
        stackTrace,
      );
      return null;
    }
  }
}
