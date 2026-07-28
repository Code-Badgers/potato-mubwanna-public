import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/location/location_service.dart';
import '../../../../core/network/api_exception.dart';
import '../../../audio/application/audio_guide_controller.dart';
import '../../../audio/application/audio_playback_controller.dart';
import '../../../audio/data/audio_guide_repository.dart';
import '../../../audio/domain/audio_guide.dart';
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
        data: (spot) => _VisitVerificationBar(spot: spot),
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
                    label: spot.congestionLabel,
                    background: _congestionBackground(spot.congestionLevel),
                    foreground: _congestionForeground(spot.congestionLevel),
                  ),
                ],
              ),
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
              const _SectionTitle(
                icon: Icons.headphones_rounded,
                title: '점순이 오디오',
              ),
              const SizedBox(height: 12),
              audioGuide.when(
                loading: () => const _AudioGuideLoading(),
                error: (error, _) {
                  if (error is AudioGuideException &&
                      error.type == AudioGuideFailureType.unavailable) {
                    return const _AudioGuideUnavailable();
                  }
                  return _AudioGuideError(
                    message: error is AudioGuideException
                        ? error.message
                        : '오디오 가이드를 불러오지 못했습니다.',
                    onRetry: () => ref.invalidate(audioGuideProvider(spot.id)),
                  );
                },
                data: (guide) => _AudioGuideContent(guide: guide),
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
    final canVerify = spot.stampEnabled && !state.isLoading;

    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          border: Border(top: BorderSide(color: _audioLine)),
        ),
        child: FilledButton.icon(
          key: const ValueKey('visit-verify-button'),
          onPressed: canVerify
              ? () => _handleVisitVerification(context, ref, spot)
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
                ? '방문 인증 중'
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
      _showLocationFailureSnackBar(context, ref, error);
      return;
    }

    final message = error is ApiException ? error.message : '방문 인증에 실패했습니다.';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void _showLocationFailureSnackBar(
    BuildContext context,
    WidgetRef ref,
    LocationFailure error,
  ) {
    final settingsTarget = error.settingsTarget;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(error.message),
        action: settingsTarget == null
            ? null
            : SnackBarAction(
                label: error.actionLabel ?? '설정',
                onPressed: () {
                  ref.read(locationServiceProvider).openSettings(
                        settingsTarget,
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

class _VisitResultSheet extends StatelessWidget {
  const _VisitResultSheet({
    required this.result,
    required this.spot,
  });

  final VisitVerificationResult result;
  final SpotDetail spot;

  @override
  Widget build(BuildContext context) {
    final potato = result.acquiredPotato;
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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
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
              const _VisitResultLine(
                icon: Icons.flag_rounded,
                label: '점순이 미션 등장',
                color: Color(0xFF56C787),
              ),
            ],
            const SizedBox(height: 20),
            FilledButton.icon(
              key: const ValueKey('visit-result-potato-book'),
              onPressed: () {
                Navigator.of(context).pop();
                context.go('/main/potatoes');
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
            if (result.missionAvailable) ...[
              FilledButton.icon(
                key: const ValueKey('visit-result-mission-entry'),
                onPressed: () {
                  Navigator.of(context).pop();
                  context.go(
                    Uri(
                      path: '/main/missions',
                      queryParameters: {
                        'entry': 'visit',
                        'spotName': spot.name,
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
            OutlinedButton.icon(
              key: const ValueKey('visit-result-next-route'),
              onPressed: () {
                Navigator.of(context).pop();
                context.go(
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
                  potato.alreadyOwned ? '이미 보유한 감자예요' : '감자 획득',
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
              IconButton.filled(
                key: const ValueKey('audio-play-toggle'),
                tooltip: playback.isPlaying ? '일시정지' : '재생',
                onPressed:
                    playback.canPlay ? () => controller.togglePlayback() : null,
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

class _AudioGuideUnavailable extends StatelessWidget {
  const _AudioGuideUnavailable();

  @override
  Widget build(BuildContext context) {
    return const _AudioMessagePanel(
      key: ValueKey('audio-guide-unavailable'),
      icon: Icons.headset_off_rounded,
      title: '오디오 가이드가 준비되지 않았어요',
      message: '관광지 정보는 계속 확인할 수 있습니다.',
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
      title: '오디오 가이드를 불러오지 못했습니다',
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
    _ => Icons.directions_walk_rounded,
  };
}

Color _congestionBackground(String level) {
  return switch (level) {
    'LOW' => const Color(0xFFE7F5EB),
    'HIGH' => const Color(0xFFFFE8E3),
    _ => const Color(0xFFFFF3CD),
  };
}

Color _congestionForeground(String level) {
  return switch (level) {
    'LOW' => _audioGreen,
    'HIGH' => const Color(0xFFA23E2A),
    _ => const Color(0xFF76561A),
  };
}

String _formatDuration(Duration duration) {
  final hours = duration.inHours;
  final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
  final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
  return hours > 0 ? '$hours:$minutes:$seconds' : '$minutes:$seconds';
}
