import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/location/location_service.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../shared/widgets/place_visit_actions.dart';
import '../../../audio/application/audio_guide_controller.dart';
import '../../../audio/application/audio_playback_controller.dart';
import '../../../audio/data/audio_guide_repository.dart';
import '../../../audio/domain/audio_guide.dart';
import '../../../feature_tour/presentation/feature_tour_host.dart';
import '../../../feature_tour/presentation/feature_tour_targets.dart';
import '../../../stamp/presentation/widget/attraction_stamp_image.dart';
import '../../application/spot_detail_controller.dart';
import '../../domain/spot_detail.dart';
import '../../domain/visit_verification.dart';

const _audioGreen = Color(0xFF367A50);
const _audioMint = Color(0xFFE7F5EB);
const _audioLine = Color(0xFFE4E0D8);

class SpotDetailScreen extends ConsumerWidget {
  const SpotDetailScreen({required this.spotId, super.key});

  final String spotId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detail = ref.watch(spotDetailProvider(spotId));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
        title: const Text(
          '관광지 상세',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: detail.when(
        loading: () => const _SpotDetailLoading(),
        error: (_, __) => _SpotDetailError(
          onRetry: () => ref.invalidate(spotDetailProvider(spotId)),
        ),
        data: (spot) => _SpotDetailBody(spot: spot),
      ),
      bottomNavigationBar: detail.maybeWhen(
        data: (spot) =>
            spot.stampEnabled ? _VisitVerificationBar(spot: spot) : null,
        orElse: () => null,
      ),
    );
  }
}

class _SpotDetailBody extends ConsumerWidget {
  const _SpotDetailBody({required this.spot});

  final SpotDetail spot;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final audioGuide = ref.watch(audioGuideProvider(spot.id));

    return ListView(
      key: const ValueKey('spot-detail-content'),
      padding: const EdgeInsets.only(bottom: 132),
      children: [
        _SpotHeroImage(spot: spot),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 22, 20, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _SpotBadge(
                    icon: Icons.place_rounded,
                    label: spot.categoryLabel,
                    background: _audioMint,
                    foreground: _audioGreen,
                  ),
                  _SpotBadge(
                    icon: _congestionIcon(spot.congestionLevel),
                    label: spot.congestionLevel == 'UNKNOWN' ? '혼잡도 정보 없음' : '${spot.congestionLabel} 예측',
                    background: _congestionBackground(spot.congestionLevel),
                    foreground: _congestionForeground(spot.congestionLevel),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(spot.congestionDescription,
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 12, height: 1.4)),
              const SizedBox(height: 14),
              Text(
                spot.name,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 10),
              _LocationLine(
                icon: Icons.location_on_outlined,
                text: spot.address.isEmpty ? spot.cityName : spot.address,
              ),
              if (spot.stampEnabled) ...[
                const SizedBox(height: 8),
                _LocationLine(
                  icon: Icons.verified_outlined,
                  text: spot.verificationRadiusMeter > 0
                      ? '${spot.verificationRadiusMeter}m 안에서 스탬프 인증 가능'
                      : '스탬프 인증 가능',
                ),
              ],
              if (spot.potatoTags.isNotEmpty) ...[
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final tag in spot.potatoTags) _PotatoTag(label: tag),
                  ],
                ),
              ],
              const SizedBox(height: 30),
              _SpotInformationSection(spot: spot),
              _AudioGuideSection(
                audioGuide: audioGuide,
                onRetry: () => ref.invalidate(audioGuideProvider(spot.id)),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _VisitVerificationBar extends ConsumerWidget {
  const _VisitVerificationBar({required this.spot});

  final SpotDetail spot;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(visitVerificationControllerProvider(spot));
    final phase = ref.watch(visitVerificationPhaseProvider(spot));
    final canVerify = spot.stampEnabled && !state.isLoading;

    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          border: Border(top: BorderSide(color: _audioLine)),
        ),
        child: KeyedSubtree(
          key: FeatureTourTargets.visitVerify,
          child: FilledButton.icon(
            key: const ValueKey('visit-verify-button'),
            onPressed: canVerify
                ? () {
                    FeatureTourScope.maybeOf(context)?.completeTarget(
                      FeatureTourTargets.visitVerify,
                    );
                    _handleVisitVerification(context, ref, spot);
                  }
                : null,
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF56C787),
              foregroundColor: Colors.white,
              disabledBackgroundColor: const Color(0xFFD7DED6),
              disabledForegroundColor: AppColors.textSecondary,
              minimumSize: const Size.fromHeight(54),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            icon: state.isLoading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.verified_rounded),
            label: Text(
              state.isLoading
                  ? phase == VisitVerificationPhase.location
                      ? '현재 위치 확인 중'
                      : '서버 인증 중'
                  : spot.stampEnabled
                      ? '방문 인증하기'
                      : '방문 인증 준비 중',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                letterSpacing: 0,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handleVisitVerification(
    BuildContext context,
    WidgetRef ref,
    SpotDetail spot,
  ) async {
    final controller = ref.read(
      visitVerificationControllerProvider(spot).notifier,
    );
    final result = await controller.verify();
    if (!context.mounted) {
      return;
    }

    if (result != null) {
      _showVisitResultSheet(context, result, spot);
      return;
    }

    final error = ref.read(visitVerificationControllerProvider(spot)).error;
    if (error is LocationFailure) {
      _showLocationFailureSnackBar(context, ref, spot, error);
      return;
    }

    final message = error is ApiException ? error.message : '방문 인증에 실패했습니다.';
    final canRetry = error is ApiException &&
        (error.statusCode == null || error.statusCode! >= 500);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        action: canRetry
            ? SnackBarAction(
                label: '다시 시도',
                onPressed: () => _handleVisitVerification(context, ref, spot),
              )
            : null,
      ),
    );
  }

  void _showLocationFailureSnackBar(
    BuildContext context,
    WidgetRef ref,
    SpotDetail spot,
    LocationFailure error,
  ) {
    final settingsTarget = error.settingsTarget;
    final needsConsent = error.type == LocationFailureType.consentRequired;
    final canRetry = error.type == LocationFailureType.timeout ||
        error.type == LocationFailureType.inaccurate ||
        error.type == LocationFailureType.unavailable;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(error.message),
        action: !needsConsent && settingsTarget == null && !canRetry
            ? null
            : SnackBarAction(
                label: error.actionLabel ?? '설정',
                onPressed: () {
                  if (needsConsent) {
                    context.push(
                      '/legal/location-terms?manage=true&returnOnAccept=true',
                    );
                    return;
                  }
                  if (canRetry) {
                    _handleVisitVerification(context, ref, spot);
                    return;
                  }
                  ref.read(locationServiceProvider).openSettings(
                        settingsTarget!,
                      );
                },
              ),
      ),
    );
  }
}

void _showVisitResultSheet(
  BuildContext context,
  VisitVerificationResult result,
  SpotDetail spot,
) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) => _VisitResultSheet(
      result: result,
      spot: spot,
    ),
  );
}

class _VisitResultSheet extends StatefulWidget {
  const _VisitResultSheet({
    required this.result,
    required this.spot,
  });

  final VisitVerificationResult result;
  final SpotDetail spot;

  @override
  State<_VisitResultSheet> createState() => _VisitResultSheetState();
}

class _VisitResultSheetState extends State<_VisitResultSheet>
    with SingleTickerProviderStateMixin {
  late final AnimationController _stampController;
  late final Animation<double> _imprintScale;
  late final Animation<double> _imprintTurns;
  late final Animation<double> _imprintOpacity;
  late final Animation<double> _stampPressOffset;
  late final Animation<double> _stampPressScale;
  late final Animation<double> _stampPressOpacity;
  late final Animation<double> _impactScale;
  late final Animation<double> _impactOpacity;
  bool _didHapticImpact = false;

  @override
  void initState() {
    super.initState();
    _stampController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 840),
    );
    _imprintScale = TweenSequence<double>([
      TweenSequenceItem(
        tween: ConstantTween(0.72),
        weight: 40,
      ),
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 0.72,
          end: 1.0,
        ).chain(CurveTween(curve: Curves.elasticOut)),
        weight: 60,
      ),
    ]).animate(_stampController);
    _imprintTurns = Tween<double>(begin: -0.025, end: 0).animate(
      CurvedAnimation(
        parent: _stampController,
        curve: const Interval(0.4, 1, curve: Curves.easeOutBack),
      ),
    );
    _imprintOpacity = TweenSequence<double>([
      TweenSequenceItem(tween: ConstantTween(0), weight: 40),
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0), weight: 8),
      TweenSequenceItem(tween: ConstantTween(1), weight: 52),
    ]).animate(_stampController);
    _stampPressOffset = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: -72.0, end: 0.0)
            .chain(CurveTween(curve: Curves.easeInCubic)),
        weight: 42,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 0.0, end: -78.0)
            .chain(CurveTween(curve: Curves.easeOutCubic)),
        weight: 34,
      ),
      TweenSequenceItem(tween: ConstantTween(-78), weight: 24),
    ]).animate(_stampController);
    _stampPressScale = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.94), weight: 42),
      TweenSequenceItem(tween: Tween(begin: 0.94, end: 1.0), weight: 34),
      TweenSequenceItem(tween: ConstantTween(1), weight: 24),
    ]).animate(_stampController);
    _stampPressOpacity = TweenSequence<double>([
      TweenSequenceItem(tween: ConstantTween(1), weight: 56),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0), weight: 20),
      TweenSequenceItem(tween: ConstantTween(0), weight: 24),
    ]).animate(_stampController);
    _impactScale = Tween<double>(begin: 0.75, end: 1.35).animate(
      CurvedAnimation(
        parent: _stampController,
        curve: const Interval(0.38, 0.82, curve: Curves.easeOut),
      ),
    );
    _impactOpacity = TweenSequence<double>([
      TweenSequenceItem(tween: ConstantTween(0), weight: 38),
      TweenSequenceItem(tween: Tween(begin: 0.55, end: 0), weight: 44),
      TweenSequenceItem(tween: ConstantTween(0), weight: 18),
    ]).animate(_stampController);
    _stampController.addListener(_triggerHapticAtImpact);
    if (widget.result.stampIssued) {
      _stampController.forward();
    }
  }

  void _triggerHapticAtImpact() {
    if (_didHapticImpact || _stampController.value < 0.42) {
      return;
    }
    _didHapticImpact = true;
    HapticFeedback.heavyImpact();
  }

  @override
  void dispose() {
    _stampController
      ..removeListener(_triggerHapticAtImpact)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final result = widget.result;
    final spot = widget.spot;
    final potato = result.acquiredPotato;
    final unlockedMission = result.unlockedMission;
    return SafeArea(
      child: Container(
        key: const ValueKey('visit-result-sheet'),
        margin: const EdgeInsets.all(12),
        padding: const EdgeInsets.fromLTRB(22, 24, 22, 18),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: _audioLine),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (result.stampIssued)
                SizedBox(
                  key: const ValueKey('visit-stamp-impact'),
                  height: 132,
                  child: AnimatedBuilder(
                    animation: _stampController,
                    builder: (context, child) => Stack(
                      alignment: Alignment.center,
                      clipBehavior: Clip.none,
                      children: [
                        Opacity(
                          opacity: _impactOpacity.value,
                          child: Transform.scale(
                            scale: _impactScale.value,
                            child: Container(
                              width: 92,
                              height: 92,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: const Color(0xFF56C787),
                                  width: 3,
                                ),
                              ),
                            ),
                          ),
                        ),
                        Opacity(
                          key: const ValueKey('visit-stamp-imprint'),
                          opacity: _imprintOpacity.value,
                          child: Transform.rotate(
                            angle: _imprintTurns.value * 6.283185307179586,
                            child: Transform.scale(
                              scale: _imprintScale.value,
                              child: child,
                            ),
                          ),
                        ),
                        Opacity(
                          opacity: _stampPressOpacity.value,
                          child: Transform.translate(
                            offset: Offset(0, _stampPressOffset.value),
                            child: Transform.scale(
                              scale: _stampPressScale.value,
                              child: const _PhysicalStampPress(),
                            ),
                          ),
                        ),
                      ],
                    ),
                    child: AttractionStampImage(
                      spotName: spot.name,
                      size: 104,
                      fallback: const Icon(
                        Icons.workspace_premium_rounded,
                        color: Color(0xFF367A50),
                        size: 72,
                      ),
                    ),
                  ),
                )
              else
                const Icon(
                  Icons.celebration_rounded,
                  color: Color(0xFF56C787),
                  size: 44,
                ),
              const SizedBox(height: 12),
              const Text(
                '인증 성공',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0,
                ),
              ),
              const SizedBox(height: 18),
              _VisitResultLine(
                icon: Icons.workspace_premium_rounded,
                label: result.stampIssued ? '지역 스탬프 획득' : '이미 획득한 지역 스탬프',
                color: const Color(0xFFD8A232),
              ),
              if (potato != null) ...[
                const SizedBox(height: 10),
                _PotatoAcquisitionCard(potato: potato),
              ],
              if (result.missionAvailable) ...[
                const SizedBox(height: 10),
                if (unlockedMission == null)
                  const _VisitResultLine(
                    icon: Icons.flag_rounded,
                    label: '점순이 미션 등장',
                    color: Color(0xFF56C787),
                  )
                else
                  _UnlockedMissionCard(mission: unlockedMission),
              ],
              const SizedBox(height: 20),
              if (result.missionAvailable) ...[
                FilledButton.icon(
                  key: const ValueKey('visit-result-mission-entry'),
                  onPressed: () {
                    Navigator.of(context).pop();
                    context.push(
                      Uri(
                        path: '/main/missions',
                        queryParameters: {
                          'entry': 'visit',
                          'spotName': spot.name,
                          if (unlockedMission?.id.isNotEmpty == true)
                            'missionId': unlockedMission!.id,
                        },
                      ).toString(),
                    );
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF6A4A2A),
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  icon: const Icon(Icons.flag_rounded),
                  label: const Text('점순이 미션 보기'),
                ),
                const SizedBox(height: 8),
              ],
              if (potato != null) ...[
                FilledButton.icon(
                  key: const ValueKey('visit-result-potato-book'),
                  onPressed: () {
                    Navigator.of(context).pop();
                    context.push('/main/potatoes');
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF56C787),
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  icon: const Icon(Icons.eco_rounded),
                  label: const Text('도감 보기'),
                ),
                const SizedBox(height: 8),
              ],
              OutlinedButton.icon(
                key: const ValueKey('visit-result-next-route'),
                onPressed: () {
                  Navigator.of(context).pop();
                  context.push(
                    Uri(
                      path: '/main/map',
                      queryParameters: {'recommendFrom': result.spotId},
                    ).toString(),
                  );
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF367A50),
                  minimumSize: const Size.fromHeight(50),
                  side: const BorderSide(color: Color(0xFFC9E7D4)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                icon: const Icon(Icons.map_rounded),
                label: const Text('다음 장소 추천'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PhysicalStampPress extends StatelessWidget {
  const _PhysicalStampPress();

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '스탬프를 찍는 중',
      child: SizedBox(
        key: const ValueKey('visit-stamp-press'),
        width: 76,
        height: 92,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Container(
              width: 34,
              height: 42,
              decoration: BoxDecoration(
                color: const Color(0xFF8C5A32),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(18),
                  bottom: Radius.circular(8),
                ),
                border: Border.all(color: const Color(0xFF68401F), width: 2),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x33000000),
                    blurRadius: 6,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
            ),
            Container(
              width: 58,
              height: 10,
              decoration: const BoxDecoration(
                color: Color(0xFF6A4325),
                borderRadius: BorderRadius.vertical(top: Radius.circular(5)),
              ),
            ),
            Container(
              width: 76,
              height: 24,
              decoration: BoxDecoration(
                color: const Color(0xFF3F7654),
                borderRadius: BorderRadius.circular(5),
                border: Border.all(color: const Color(0xFF28563B), width: 2),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _UnlockedMissionCard extends StatelessWidget {
  const _UnlockedMissionCard({required this.mission});

  final VisitUnlockedMission mission;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF9F2),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFC7EED9)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: const BoxDecoration(
              color: Color(0xFF56C787),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.flag_rounded,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  mission.title,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${mission.cityName} · ${mission.rewardLabel}',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _VisitResultLine extends StatelessWidget {
  const _VisitResultLine({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 15,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PotatoAcquisitionCard extends StatelessWidget {
  const _PotatoAcquisitionCard({required this.potato});

  final VisitAcquiredPotato potato;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8EA),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFEEDB9D)),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: const Color(0xFFFFE9A6),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.eco_rounded,
              color: Color(0xFF76561A),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  potato.acquisitionMessage,
                  style: const TextStyle(
                    color: Color(0xFF76561A),
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  potato.name,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${potato.region} · 희귀도 ${potato.rarityLabel}',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SpotHeroImage extends StatelessWidget {
  const _SpotHeroImage({required this.spot});

  final SpotDetail spot;

  @override
  Widget build(BuildContext context) {
    final imageUrl = spot.imageUrl;
    return AspectRatio(
      aspectRatio: 16 / 9,
      child: imageUrl == null
          ? const _SpotImageFallback()
          : CachedNetworkImage(
              imageUrl: imageUrl,
              fit: BoxFit.cover,
              placeholder: (_, __) => const _SpotImageLoading(),
              errorWidget: (_, __, ___) => const _SpotImageFallback(),
            ),
    );
  }
}

class _SpotImageLoading extends StatelessWidget {
  const _SpotImageLoading();

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      color: Color(0xFFE9EEE5),
      child: Center(child: CircularProgressIndicator()),
    );
  }
}

class _SpotImageFallback extends StatelessWidget {
  const _SpotImageFallback();

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      color: Color(0xFFE3EFE6),
      child: Center(
        child: Icon(
          Icons.landscape_rounded,
          size: 68,
          color: _audioGreen,
        ),
      ),
    );
  }
}

class _SpotBadge extends StatelessWidget {
  const _SpotBadge({
    required this.icon,
    required this.label,
    required this.background,
    required this.foreground,
  });

  final IconData icon;
  final String label;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: foreground),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: foreground,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _LocationLine extends StatelessWidget {
  const _LocationLine({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 19, color: AppColors.textSecondary),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
              height: 1.45,
            ),
          ),
        ),
      ],
    );
  }
}

class _PotatoTag extends StatelessWidget {
  const _PotatoTag({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3CD),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFF0D783)),
      ),
      child: Text(
        '#$label',
        style: const TextStyle(
          color: Color(0xFF76561A),
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.icon, required this.title});

  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: _audioGreen, size: 24),
        const SizedBox(width: 9),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.w900,
              letterSpacing: 0,
            ),
          ),
        ),
      ],
    );
  }
}

class _SpotInformationSection extends StatelessWidget {
  const _SpotInformationSection({required this.spot});

  final SpotDetail spot;

  @override
  Widget build(BuildContext context) {
    final rows = <_SpotInformationItem>[
      _SpotInformationItem(
        Icons.storefront_rounded,
        switch (spot.businessOpenNow) {
          true => '영업 중',
          false => '영업 종료',
          null => null,
        },
      ),
      _SpotInformationItem(Icons.today_rounded, spot.businessTodayText),
      _SpotInformationItem(
        Icons.star_rounded,
        spot.rating == null || spot.rating! <= 0
            ? null
            : '평점 ${spot.rating!.toStringAsFixed(1)}',
      ),
      _SpotInformationItem(
        Icons.public_rounded,
        _websiteLabel(spot.website),
      ),
      _SpotInformationItem(
        Icons.call_rounded,
        spot.phone ?? spot.contactPhone,
      ),
      _SpotInformationItem(Icons.schedule_rounded, spot.openingHours),
      _SpotInformationItem(
          Icons.confirmation_number_rounded, spot.admissionFee),
      _SpotInformationItem(Icons.event_busy_rounded, spot.closedDays),
      _SpotInformationItem(Icons.local_parking_rounded, spot.parking),
    ].where((item) => item.text != null && item.text!.isNotEmpty).toList();

    return Column(
      key: const ValueKey('spot-information-section'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitle(
          icon: Icons.info_outline_rounded,
          title: '이용 안내',
        ),
        if (spot.description != null) ...[
          const SizedBox(height: 12),
          Text(
            spot.description!,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
              fontWeight: FontWeight.w600,
              height: 1.65,
            ),
          ),
        ],
        if (spot.openingHours == null && spot.businessTodayText == null)
          const Padding(
            padding: EdgeInsets.only(top: 12),
            child: Text('영업시간은 방문 전 확인해주세요.',
                style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
          ),
        PlaceVisitActions(phone: spot.phone ?? spot.contactPhone, website: spot.website),
        if (spot.openingHours != null)
          const Text('영업정보 출처: 한국관광공사', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
        if (spot.businessTodayText != null)
          const Text('영업정보 출처: Google Places', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
        if (rows.isNotEmpty) ...[
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _audioLine),
            ),
            child: Column(
              children: [
                for (var index = 0; index < rows.length; index++) ...[
                  _SpotInformationRow(item: rows[index]),
                  if (index < rows.length - 1) const SizedBox(height: 12),
                ],
              ],
            ),
          ),
        ],
      ],
    );
  }

  String? _websiteLabel(String? website) {
    if (website == null || website.isEmpty) {
      return null;
    }
    final uri = Uri.tryParse(website);
    if (uri == null || uri.host.isEmpty) {
      return website;
    }
    return uri.host.replaceFirst(RegExp(r'^www\.'), '');
  }
}

class _SpotInformationRow extends StatelessWidget {
  const _SpotInformationRow({required this.item});

  final _SpotInformationItem item;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(item.icon, color: _audioGreen, size: 20),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            item.text!,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
              fontWeight: FontWeight.w700,
              height: 1.45,
            ),
          ),
        ),
      ],
    );
  }
}

class _SpotInformationItem {
  const _SpotInformationItem(this.icon, this.text);

  final IconData icon;
  final String? text;
}

class _AudioGuideSection extends StatelessWidget {
  const _AudioGuideSection({
    required this.audioGuide,
    required this.onRetry,
  });

  final AsyncValue<AudioGuide> audioGuide;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return audioGuide.when(
      loading: () => _buildSection(const _AudioGuideLoading()),
      error: (error, _) {
        if (error is AudioGuideException &&
            error.type == AudioGuideFailureType.unavailable) {
          return const SizedBox.shrink();
        }
        return _buildSection(
          _AudioGuideError(
            message: error is AudioGuideException
                ? error.message
                : '오디오 가이드를 불러오지 못했습니다.',
            onRetry: onRetry,
          ),
        );
      },
      data: (guide) => _buildSection(_AudioGuideContent(guide: guide)),
    );
  }

  Widget _buildSection(Widget content) {
    return Column(
      key: const ValueKey('audio-guide-section'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 30),
        const _SectionTitle(
          icon: Icons.headphones_rounded,
          title: '관광 해설 오디오',
        ),
        const SizedBox(height: 4),
        const Text(
          '한국관광공사 오디(Odii) 제공',
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),
        content,
      ],
    );
  }
}

class _AudioGuideContent extends StatelessWidget {
  const _AudioGuideContent({required this.guide});

  final AudioGuide guide;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _AudioPlayerCard(guide: guide),
        if (guide.characterScript != null) ...[
          const SizedBox(height: 18),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _audioMint,
              borderRadius: BorderRadius.circular(8),
              border: const Border(
                left: BorderSide(color: _audioGreen, width: 4),
              ),
            ),
            child: Text(
              guide.characterScript!,
              style: const TextStyle(
                color: Color(0xFF315A3E),
                fontSize: 14,
                fontWeight: FontWeight.w700,
                height: 1.55,
              ),
            ),
          ),
        ],
        if (guide.script.trim().isNotEmpty) ...[
          const SizedBox(height: 24),
          const Text(
            '해설 원문',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 9),
          SelectableText(
            guide.script,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
              height: 1.7,
            ),
          ),
        ],
      ],
    );
  }
}

class _AudioPlayerCard extends ConsumerWidget {
  const _AudioPlayerCard({required this.guide});

  final AudioGuide guide;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playback = ref.watch(
      audioPlaybackControllerProvider(guide.audioUrl),
    );
    final controller = ref.read(
      audioPlaybackControllerProvider(guide.audioUrl).notifier,
    );
    final durationMilliseconds = playback.duration.inMilliseconds;
    final sliderMax =
        durationMilliseconds > 0 ? durationMilliseconds.toDouble() : 1.0;
    final sliderValue = playback.position.inMilliseconds
        .clamp(0, durationMilliseconds > 0 ? durationMilliseconds : 0)
        .toDouble();

    return Container(
      key: const ValueKey('audio-player-card'),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _audioLine),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: _audioMint,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.graphic_eq_rounded,
                  color: _audioGreen,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  guide.title,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              KeyedSubtree(
                key: FeatureTourTargets.audioPlay,
                child: IconButton.filled(
                  key: const ValueKey('audio-play-toggle'),
                  tooltip: playback.isPlaying ? '일시정지' : '재생',
                  onPressed: playback.canPlay
                      ? () {
                          FeatureTourScope.maybeOf(context)?.completeTarget(
                            FeatureTourTargets.audioPlay,
                          );
                          controller.togglePlayback();
                        }
                      : null,
                  style: IconButton.styleFrom(
                    backgroundColor: _audioGreen,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: const Color(0xFFB7C8BC),
                    fixedSize: const Size(48, 48),
                  ),
                  icon: playback.status == AudioPlaybackStatus.loading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Icon(
                          playback.isPlaying
                              ? Icons.pause_rounded
                              : Icons.play_arrow_rounded,
                          size: 28,
                        ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  children: [
                    Slider(
                      key: const ValueKey('audio-position-slider'),
                      value: sliderValue,
                      max: sliderMax,
                      onChanged: playback.canPlay && durationMilliseconds > 0
                          ? (value) => controller.seek(
                                Duration(milliseconds: value.round()),
                              )
                          : null,
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _formatDuration(playback.position),
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                              fontFeatures: [FontFeature.tabularFigures()],
                            ),
                          ),
                          Text(
                            _formatDuration(playback.duration),
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                              fontFeatures: [FontFeature.tabularFigures()],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (playback.status == AudioPlaybackStatus.failure) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: Text(
                    playback.errorMessage ?? '오디오를 재생하지 못했습니다.',
                    style: const TextStyle(
                      color: AppColors.error,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: '오디오 다시 불러오기',
                  onPressed: controller.retry,
                  icon: const Icon(Icons.refresh_rounded),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _AudioGuideLoading extends StatelessWidget {
  const _AudioGuideLoading();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      key: ValueKey('audio-guide-loading'),
      height: 148,
      child: Center(child: CircularProgressIndicator()),
    );
  }
}

class _AudioGuideError extends StatelessWidget {
  const _AudioGuideError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return _AudioMessagePanel(
      key: const ValueKey('audio-guide-error'),
      icon: Icons.wifi_off_rounded,
      title: '지금은 오디오를 불러올 수 없어요',
      message: message,
      action: OutlinedButton.icon(
        onPressed: onRetry,
        icon: const Icon(Icons.refresh_rounded),
        label: const Text('다시 시도'),
      ),
    );
  }
}

class _AudioMessagePanel extends StatelessWidget {
  const _AudioMessagePanel({
    required this.icon,
    required this.title,
    required this.message,
    this.action,
    super.key,
  });

  final IconData icon;
  final String title;
  final String message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _audioLine),
      ),
      child: Column(
        children: [
          Icon(icon, size: 32, color: AppColors.textSecondary),
          const SizedBox(height: 10),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
              height: 1.45,
            ),
          ),
          if (action != null) ...[
            const SizedBox(height: 14),
            action!,
          ],
        ],
      ),
    );
  }
}

class _SpotDetailLoading extends StatelessWidget {
  const _SpotDetailLoading();

  @override
  Widget build(BuildContext context) {
    return const Center(
      key: ValueKey('spot-detail-loading'),
      child: CircularProgressIndicator(),
    );
  }
}

class _SpotDetailError extends StatelessWidget {
  const _SpotDetailError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      key: const ValueKey('spot-detail-error'),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.location_off_rounded,
              size: 44,
              color: AppColors.textSecondary,
            ),
            const SizedBox(height: 14),
            const Text(
              '관광지 정보를 불러오지 못했습니다.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 17,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 14),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('다시 시도'),
            ),
          ],
        ),
      ),
    );
  }
}

IconData _congestionIcon(String level) {
  return switch (level) {
    'LOW' => Icons.sentiment_satisfied_alt_rounded,
    'HIGH' => Icons.groups_rounded,
    'UNKNOWN' => Icons.help_outline_rounded,
    _ => Icons.directions_walk_rounded,
  };
}

Color _congestionBackground(String level) {
  return switch (level) {
    'LOW' => const Color(0xFFE7F5EB),
    'HIGH' => const Color(0xFFFFE8E3),
    'UNKNOWN' => const Color(0xFFF0F0F0),
    _ => const Color(0xFFFFF3CD),
  };
}

Color _congestionForeground(String level) {
  return switch (level) {
    'LOW' => _audioGreen,
    'HIGH' => const Color(0xFFA23E2A),
    'UNKNOWN' => AppColors.textSecondary,
    _ => const Color(0xFF76561A),
  };
}

String _formatDuration(Duration duration) {
  final hours = duration.inHours;
  final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
  final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
  return hours > 0 ? '$hours:$minutes:$seconds' : '$minutes:$seconds';
}
