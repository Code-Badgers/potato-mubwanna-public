import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/network/api_exception.dart';
import '../../application/stamp_book_controller.dart';
import '../../domain/stamp_book.dart';
import '../model/gangwon_map_region.dart';

class StampBookScreen extends ConsumerWidget {
  const StampBookScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stampBook = ref.watch(stampBookProvider);
    final nextTargets = ref.watch(stampNextTargetsProvider);
    final claimState = ref.watch(stampRewardClaimProvider);
    ref.listen(stampRewardClaimProvider, (_, next) {
      next.whenOrNull(
        data: (result) {
          if (result == null) {
            return;
          }
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(
              const SnackBar(content: Text('보상 수령이 완료됐어요. 쿠폰함에서 확인해 주세요.')),
            );
        },
        error: (error, _) {
          final message = error is ApiException && error.message.isNotEmpty
              ? error.message
              : '보상을 받지 못했습니다. 잠시 후 다시 시도해 주세요.';
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(SnackBar(content: Text(message)));
        },
      );
    });

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: stampBook.when(
          data: (value) => value == null
              ? const _SignedOutState()
              : _StampBookBody(
                  stampBook: value,
                  nextTargets: nextTargets,
                  isClaiming: claimState.isLoading,
                  onClaim: (targetCount) => ref
                      .read(stampRewardClaimProvider.notifier)
                      .claim(targetCount),
                  onRetryTargets: () =>
                      ref.invalidate(stampNextTargetsProvider),
                ),
          loading: () => const _StampBookStatusBody(
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (_, __) => _StampBookStatusBody(
            child: _StampBookError(
              onRetry: () => ref.invalidate(stampBookProvider),
            ),
          ),
        ),
      ),
    );
  }
}

class _StampBookStatusBody extends StatelessWidget {
  const _StampBookStatusBody({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        const SliverToBoxAdapter(child: _StampHeader()),
        SliverFillRemaining(hasScrollBody: false, child: child),
      ],
    );
  }
}

class _StampBookBody extends StatelessWidget {
  const _StampBookBody({
    required this.stampBook,
    required this.nextTargets,
    required this.isClaiming,
    required this.onClaim,
    required this.onRetryTargets,
  });

  final StampBook stampBook;
  final AsyncValue<List<StampNextTarget>?> nextTargets;
  final bool isClaiming;
  final ValueChanged<int> onClaim;
  final VoidCallback onRetryTargets;

  @override
  Widget build(BuildContext context) {
    final progress = stampBook.progress;
    final reward = stampBook.nextReward;

    return CustomScrollView(
      slivers: [
        const SliverToBoxAdapter(child: _StampHeader()),
        SliverToBoxAdapter(
          child: _GangwonStampMap(
            progress: progress,
            nextTargets: nextTargets,
            onTargetTap: (target) => context.push('/spots/${target.spotId}'),
          ),
        ),
        SliverToBoxAdapter(
          child: _RallyProgressCard(
            acquiredCount: progress.acquiredCount,
            totalCount: progress.totalCount,
            reward: reward,
            isClaiming: isClaiming,
            onClaim: onClaim,
          ),
        ),
        SliverToBoxAdapter(
          child: _NextStampHintCard(
            state: nextTargets,
            completed: reward.completed,
            onRetry: onRetryTargets,
            onTargetTap: (target) => context.push('/spots/${target.spotId}'),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 24)),
      ],
    );
  }
}

class _StampHeader extends StatelessWidget {
  const _StampHeader();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.fromLTRB(20, 22, 20, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '스탬프 투어',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 34,
              fontWeight: FontWeight.w900,
              letterSpacing: 0,
            ),
          ),
          SizedBox(height: 4),
          Text(
            '강원도 지도 위에 도장을 모아보세요',
            style: TextStyle(
              color: AppColors.primaryDark,
              fontSize: 17,
              fontWeight: FontWeight.w800,
              letterSpacing: 0,
            ),
          ),
        ],
      ),
    );
  }
}

class _GangwonStampMap extends StatefulWidget {
  const _GangwonStampMap({
    required this.progress,
    required this.nextTargets,
    required this.onTargetTap,
  });

  final StampProgress progress;
  final AsyncValue<List<StampNextTarget>?> nextTargets;
  final ValueChanged<StampNextTarget> onTargetTap;

  @override
  State<_GangwonStampMap> createState() => _GangwonStampMapState();
}

class _GangwonStampMapState extends State<_GangwonStampMap> {
  String? _selectedCity;

  @override
  Widget build(BuildContext context) {
    final stampsByCity = {
      for (final stamp in widget.progress.stamps)
        _normalizeCityName(stamp.cityName): stamp,
    };
    final nearbyCity = widget.nextTargets.maybeWhen(
      data: (targets) => targets == null || targets.isEmpty
          ? _firstIncompleteCity(stampsByCity)
          : _normalizeCityName(targets.first.cityName),
      orElse: () => _firstIncompleteCity(stampsByCity),
    );
    final selectedCity = _selectedCity ?? nearbyCity;
    final selectedRegion = _findRegion(selectedCity) ?? gangwonMapRegions.first;
    final selectedStamp = stampsByCity[selectedRegion.city];
    final selectedTarget = widget.nextTargets.maybeWhen(
      data: (targets) {
        if (targets == null || targets.isEmpty) {
          return null;
        }
        for (final target in targets) {
          if (_normalizeCityName(target.cityName) == selectedRegion.city) {
            return target;
          }
        }
        return targets.first;
      },
      orElse: () => null,
    );

    return Container(
      margin: const EdgeInsets.fromLTRB(14, 0, 14, 14),
      height: 540,
      decoration: BoxDecoration(
        color: AppColors.cream,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.line),
      ),
      clipBehavior: Clip.antiAlias,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final size = constraints.biggest;
          final mapRect = _gangwonMapRect(size);

          return Stack(
            fit: StackFit.expand,
            children: [
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTapDown: (details) {
                  final city = _hitTestRegion(details.localPosition, mapRect);
                  if (city == null) {
                    return;
                  }
                  setState(() => _selectedCity = city);
                },
                child: CustomPaint(
                  painter: _GangwonMapPainter(
                    stampsByCity: stampsByCity,
                    selectedCity: selectedRegion.city,
                    nearbyCity: nearbyCity,
                  ),
                  child: const SizedBox.expand(),
                ),
              ),
              for (final region in gangwonMapRegions)
                Positioned(
                  left: mapRect.left + region.anchor.dx * mapRect.width - 32,
                  top: mapRect.top + region.anchor.dy * mapRect.height - 27,
                  width: 64,
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedCity = region.city),
                    child: _StampMapNode(
                      region: region,
                      stamp: stampsByCity[region.city],
                      nearby: nearbyCity == region.city,
                      selected: selectedRegion.city == region.city,
                    ),
                  ),
                ),
              Positioned(
                top: 14,
                right: 14,
                child: _MapPassportBadge(
                  acquiredCount: widget.progress.acquiredCount,
                  totalCount: widget.progress.totalCount,
                ),
              ),
              Positioned(
                left: 16,
                right: 16,
                bottom: 16,
                child: _SelectedRegionCard(
                  region: selectedRegion,
                  stamp: selectedStamp,
                  target: selectedTarget,
                  onTargetTap: selectedTarget == null
                      ? null
                      : () => widget.onTargetTap(selectedTarget),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _GangwonMapPainter extends CustomPainter {
  const _GangwonMapPainter({
    required this.stampsByCity,
    required this.selectedCity,
    required this.nearbyCity,
  });

  final Map<String, RallybookStamp> stampsByCity;
  final String selectedCity;
  final String nearbyCity;

  @override
  void paint(Canvas canvas, Size size) {
    final mapRect = _gangwonMapRect(size);
    final seaPaint = Paint()..color = const Color(0xFFDFF4F7);
    canvas.drawRect(
      Rect.fromLTRB(
        mapRect.left + mapRect.width * 0.76,
        0,
        size.width,
        size.height,
      ),
      seaPaint,
    );
    _drawWaves(canvas, mapRect);

    var fullPath = Path();
    final fillPaint = Paint()..style = PaintingStyle.fill;
    final thinLinePaint = Paint()
      ..color = const Color(0xFFB8CB9B)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;
    final selectedLinePaint = Paint()
      ..color = AppColors.primaryDark
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2;

    for (final region in gangwonMapRegions) {
      final path = _regionPath(region, mapRect);
      final acquired = stampsByCity[region.city]?.acquired ?? false;
      final nearby = region.city == nearbyCity;
      final selected = region.city == selectedCity;
      fillPaint.color = selected
          ? const Color(0xFFD6F1DE)
          : nearby
              ? const Color(0xFFFFF1BF)
              : acquired
                  ? AppColors.primaryTint
                  : const Color(0xFFF1F6E7);
      canvas.drawPath(path, fillPaint);
      canvas.drawPath(path, selected ? selectedLinePaint : thinLinePaint);

      try {
        fullPath = fullPath.computeMetrics().isEmpty
            ? path
            : Path.combine(PathOperation.union, fullPath, path);
      } catch (_) {
        fullPath.addPath(path, Offset.zero);
      }
    }

    final outerPaint = Paint()
      ..color = AppColors.primaryDark.withValues(alpha: 0.42)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.4;
    canvas.drawPath(fullPath, outerPaint);
  }

  void _drawWaves(Canvas canvas, Rect mapRect) {
    final wavePaint = Paint()
      ..color = const Color(0xFF91CED7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;
    for (final yRatio in [0.18, 0.35, 0.52, 0.69, 0.86]) {
      final path = Path();
      final y = mapRect.top + mapRect.height * yRatio;
      final startX = mapRect.left + mapRect.width * 0.78;
      path.moveTo(startX, y);
      for (var i = 0; i <= 7; i++) {
        final x = startX + i * 34;
        path.quadraticBezierTo(x + 17, y + 7, x + 34, y);
      }
      canvas.drawPath(path, wavePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _GangwonMapPainter oldDelegate) {
    return oldDelegate.stampsByCity != stampsByCity ||
        oldDelegate.selectedCity != selectedCity ||
        oldDelegate.nearbyCity != nearbyCity;
  }
}

Rect _gangwonMapRect(Size size) {
  const mapAspectRatio = 1000 / 1180;
  final available = Rect.fromLTWH(8, 2, size.width - 16, size.height - 112);
  if (available.width / available.height > mapAspectRatio) {
    final width = available.height * mapAspectRatio;
    return Rect.fromLTWH(
      available.left + (available.width - width) / 2,
      available.top,
      width,
      available.height,
    );
  }
  final height = available.width / mapAspectRatio;
  return Rect.fromLTWH(
    available.left,
    available.top + (available.height - height) / 2,
    available.width,
    height,
  );
}

Path _regionPath(GangwonMapRegion region, Rect mapRect) {
  final path = Path();
  for (final polygon in region.polygons) {
    if (polygon.length < 3) {
      continue;
    }
    path.addPolygon(
      [
        for (final point in polygon)
          Offset(
            mapRect.left + point.dx * mapRect.width,
            mapRect.top + point.dy * mapRect.height,
          ),
      ],
      true,
    );
  }
  return path;
}

String? _hitTestRegion(Offset position, Rect mapRect) {
  for (final region in gangwonMapRegions.reversed) {
    if (_regionPath(region, mapRect).contains(position)) {
      return region.city;
    }
  }
  return null;
}

GangwonMapRegion? _findRegion(String city) {
  for (final region in gangwonMapRegions) {
    if (region.city == city) {
      return region;
    }
  }
  return null;
}

class _SelectedRegionCard extends StatelessWidget {
  const _SelectedRegionCard({
    required this.region,
    required this.stamp,
    required this.target,
    required this.onTargetTap,
  });

  final GangwonMapRegion region;
  final RallybookStamp? stamp;
  final StampNextTarget? target;
  final VoidCallback? onTargetTap;

  @override
  Widget build(BuildContext context) {
    final acquired = stamp?.acquired ?? false;
    final statusText = acquired ? '도장 완료' : '도장 필요';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.line),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: acquired ? AppColors.primaryTint : AppColors.cream,
              shape: BoxShape.circle,
              border: Border.all(
                color: acquired ? AppColors.primary : AppColors.secondary,
                width: 2,
              ),
            ),
            child: Icon(
              acquired ? Icons.check_rounded : Icons.location_on_rounded,
              color: acquired ? AppColors.primaryDark : AppColors.brown,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${region.city} 스탬프',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0,
                        ),
                      ),
                    ),
                    Text(
                      statusText,
                      style: TextStyle(
                        color:
                            acquired ? AppColors.primaryDark : AppColors.brown,
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  region.landmarks,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: onTargetTap,
                        child: Text(target == null ? '대표 스팟 준비중' : '대표 스팟 보기'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: OutlinedButton(
                        onPressed: null,
                        child: Text('오디오 준비중'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StampMapNode extends StatelessWidget {
  const _StampMapNode({
    required this.region,
    required this.stamp,
    required this.nearby,
    required this.selected,
  });

  final GangwonMapRegion region;
  final RallybookStamp? stamp;
  final bool nearby;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final acquired = stamp?.acquired ?? false;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: selected || nearby ? 48 : 38,
          height: selected || nearby ? 48 : 38,
          decoration: BoxDecoration(
            color: AppColors.surface,
            shape: BoxShape.circle,
            border: Border.all(
              color: selected || nearby
                  ? AppColors.secondary
                  : acquired
                      ? AppColors.primary
                      : const Color(0xFFCDBF9F),
              width: selected || nearby ? 4 : 2.5,
            ),
            boxShadow: [
              BoxShadow(
                color: (selected || nearby
                        ? AppColors.secondary
                        : AppColors.primary)
                    .withValues(alpha: selected || nearby ? 0.28 : 0.1),
                blurRadius: selected || nearby ? 16 : 7,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Icon(
            acquired ? Icons.check_rounded : Icons.circle_outlined,
            color: acquired ? AppColors.primaryDark : const Color(0xFFB5A88D),
            size: acquired ? 27 : 20,
          ),
        ),
        const SizedBox(height: 3),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.surface.withValues(alpha: 0.94),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: selected ? AppColors.secondary : AppColors.line,
            ),
          ),
          child: Text(
            region.city,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 11,
              fontWeight: FontWeight.w900,
              letterSpacing: 0,
            ),
          ),
        ),
      ],
    );
  }
}

class _MapPassportBadge extends StatelessWidget {
  const _MapPassportBadge({
    required this.acquiredCount,
    required this.totalCount,
  });

  final int acquiredCount;
  final int totalCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.line),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.auto_stories_rounded,
              color: AppColors.primaryDark, size: 18),
          const SizedBox(width: 6),
          Text(
            '$acquiredCount/$totalCount',
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w900,
              letterSpacing: 0,
            ),
          ),
        ],
      ),
    );
  }
}

class _RallyProgressCard extends StatelessWidget {
  const _RallyProgressCard({
    required this.acquiredCount,
    required this.totalCount,
    required this.reward,
    required this.isClaiming,
    required this.onClaim,
  });

  final int acquiredCount;
  final int totalCount;
  final NextStampReward reward;
  final bool isClaiming;
  final ValueChanged<int> onClaim;

  @override
  Widget build(BuildContext context) {
    final progress = totalCount == 0 ? 0.0 : acquiredCount / totalCount;
    final targetCount = reward.nextTargetCount;
    final claimableTargetCount = reward.claimableTargetCount;
    final title = reward.canClaim ? '받을 수 있는 보상' : '투어 진행률';
    final message = reward.canClaim && claimableTargetCount != null
        ? '$claimableTargetCount개 달성 보상이 준비됐어요.'
        : reward.completed || targetCount == null
            ? '18개 시군 랠리를 모두 완주했어요.'
            : '$targetCount개 달성까지 ${reward.remainingCount}개 남았어요';

    return Container(
      margin: const EdgeInsets.fromLTRB(14, 0, 14, 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.line),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: const BoxDecoration(
                  color: AppColors.primaryTint,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_rounded,
                    color: AppColors.primaryDark, size: 32),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(999),
                      child: LinearProgressIndicator(
                        minHeight: 10,
                        value: progress.clamp(0, 1),
                        backgroundColor: const Color(0xFFEFE9DC),
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          AppColors.primary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      message,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: '$acquiredCount',
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontSize: 36,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0,
                      ),
                    ),
                    TextSpan(
                      text: ' / $totalCount',
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (reward.canClaim && claimableTargetCount != null) ...[
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                key: const ValueKey('stamp-reward-claim-button'),
                onPressed:
                    isClaiming ? null : () => onClaim(claimableTargetCount),
                child: isClaiming
                    ? const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          SizedBox(width: 8),
                          Text('보상 받는 중...'),
                        ],
                      )
                    : Text('$claimableTargetCount개 보상 받기'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _NextStampHintCard extends StatelessWidget {
  const _NextStampHintCard({
    required this.state,
    required this.completed,
    required this.onRetry,
    required this.onTargetTap,
  });

  final AsyncValue<List<StampNextTarget>?> state;
  final bool completed;
  final VoidCallback onRetry;
  final ValueChanged<StampNextTarget> onTargetTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(14, 0, 14, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primaryTint,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.line),
      ),
      child: state.when(
        loading: () => const _NextTargetStatus(
          key: ValueKey('stamp-next-target-loading'),
          icon: Icons.hourglass_top_rounded,
          message: '다음 도장을 찾고 있어요.',
        ),
        error: (_, __) => _NextTargetError(onRetry: onRetry),
        data: (targets) {
          if (targets == null) {
            return const SizedBox.shrink();
          }
          if (targets.isEmpty) {
            return _NextTargetStatus(
              key: const ValueKey('stamp-next-target-empty'),
              icon: completed
                  ? Icons.emoji_events_rounded
                  : Icons.location_off_rounded,
              message: completed ? '모든 지역 스탬프를 모았어요.' : '추천 가능한 스탬프 관광지가 없어요.',
            );
          }
          final target = targets.first;
          return InkWell(
            onTap: () => onTargetTap(target),
            borderRadius: BorderRadius.circular(8),
            child: Row(
              children: [
                const Icon(Icons.explore_rounded,
                    color: AppColors.primaryDark, size: 24),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '다음 스탬프 추천',
                        style: TextStyle(
                          color: AppColors.primaryDark,
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '${target.spotName} · ${target.cityName}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded,
                    color: AppColors.primaryDark),
              ],
            ),
          );
        },
      ),
    );
  }
}

String _normalizeCityName(String value) {
  return value.replaceAll(RegExp(r'(특별자치도|시|군|구)$'), '').trim();
}

String _firstIncompleteCity(Map<String, RallybookStamp> stampsByCity) {
  for (final region in gangwonMapRegions) {
    if (stampsByCity[region.city]?.acquired != true) {
      return region.city;
    }
  }
  return '';
}

class _NextTargetStatus extends StatelessWidget {
  const _NextTargetStatus({
    super.key,
    required this.icon,
    required this.message,
  });

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: AppColors.primaryDark, size: 20),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            message,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }
}

class _NextTargetError extends StatelessWidget {
  const _NextTargetError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Row(
      key: const ValueKey('stamp-next-target-error'),
      children: [
        const Expanded(
          child: Text(
            '다음 목표를 불러오지 못했어요.',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        TextButton(
          key: const ValueKey('stamp-next-target-retry'),
          onPressed: onRetry,
          child: const Text('다시 시도'),
        ),
      ],
    );
  }
}

class _StampBookError extends StatelessWidget {
  const _StampBookError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              color: AppColors.textSecondary,
              size: 36,
            ),
            const SizedBox(height: 12),
            const Text(
              '랠리북을 불러오지 못했습니다.',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 12),
            FilledButton(onPressed: onRetry, child: const Text('다시 시도')),
          ],
        ),
      ),
    );
  }
}

class _SignedOutState extends StatelessWidget {
  const _SignedOutState();

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        _StampHeader(),
        Expanded(
          child: Center(
            child: Text(
              '로그인 후 랠리북을 확인할 수 있어요.',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
