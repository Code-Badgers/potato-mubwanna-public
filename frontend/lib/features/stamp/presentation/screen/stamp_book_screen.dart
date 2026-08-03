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

class CityStampGridScreen extends ConsumerWidget {
  const CityStampGridScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stampBook = ref.watch(stampBookProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: stampBook.when(
          data: (value) => value == null
              ? const _SignedOutState()
              : _CityStampGridBody(progress: value.progress),
          loading: () => const Center(child: CircularProgressIndicator()),
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

class _CityStampGridBody extends StatelessWidget {
  const _CityStampGridBody({required this.progress});

  final StampProgress progress;

  @override
  Widget build(BuildContext context) {
    final totalCount = progress.totalCount == 0 ? 18 : progress.totalCount;
    final acquiredCount = progress.acquiredCount.clamp(0, totalCount);
    final ratio = totalCount == 0 ? 0.0 : acquiredCount / totalCount;

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
            child: Row(
              children: [
                IconButton.filledTonal(
                  onPressed: () => context.go('/main/mypage'),
                  icon: const Icon(Icons.arrow_back_rounded),
                  tooltip: '마이페이지로 돌아가기',
                  style: IconButton.styleFrom(
                    backgroundColor: AppColors.surface,
                    foregroundColor: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    '시군별 스탬프',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Container(
            margin: const EdgeInsets.fromLTRB(20, 0, 20, 18),
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.line),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        '강원 18개 시군 수집률',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0,
                        ),
                      ),
                    ),
                    Text(
                      '$acquiredCount / $totalCount',
                      style: const TextStyle(
                        color: AppColors.primaryDark,
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    minHeight: 10,
                    value: ratio.clamp(0, 1),
                    backgroundColor: AppColors.line,
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
          sliver: SliverGrid.builder(
            itemCount: progress.stamps.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 1,
            ),
            itemBuilder: (context, index) => _CityStampTile(
              stamp: progress.stamps[index],
            ),
          ),
        ),
      ],
    );
  }
}

class _CityStampTile extends StatelessWidget {
  const _CityStampTile({required this.stamp});

  final RallybookStamp stamp;

  @override
  Widget build(BuildContext context) {
    final acquired = stamp.acquired;

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: acquired ? AppColors.primaryTint : AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: acquired ? AppColors.primary : AppColors.line,
          width: acquired ? 1.6 : 1,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: acquired ? AppColors.primary : AppColors.background,
              shape: BoxShape.circle,
            ),
            child: Icon(
              acquired ? Icons.check_rounded : Icons.lock_outline_rounded,
              color: acquired ? Colors.white : AppColors.textSecondary,
              size: 22,
            ),
          ),
          const SizedBox(height: 9),
          Text(
            stamp.cityName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: acquired ? AppColors.textPrimary : AppColors.textSecondary,
              fontSize: 13,
              fontWeight: FontWeight.w900,
              letterSpacing: 0,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            acquired ? '완료' : '미획득',
            style: TextStyle(
              color: acquired ? AppColors.primaryDark : AppColors.textSecondary,
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 0,
            ),
          ),
        ],
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
        SliverFillRemaining(hasScrollBody: false, child: child),
      ],
    );
  }
}

class _StampBookBody extends StatelessWidget {
  const _StampBookBody({
    required this.stampBook,
    required this.nextTargets,
  });

  final StampBook stampBook;
  final AsyncValue<List<StampNextTarget>?> nextTargets;

  @override
  Widget build(BuildContext context) {
    final progress = stampBook.progress;
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: _GangwonStampMap(
            progress: progress,
            nextTargets: nextTargets,
            onTargetTap: (target) => context.push('/spots/${target.spotId}'),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 24)),
      ],
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
    final selectedRegion =
        _selectedCity == null ? null : _findRegion(_selectedCity!);
    final selectedStamp =
        selectedRegion == null ? null : stampsByCity[selectedRegion.city];
    final targetsByCity = widget.nextTargets.maybeWhen(
      data: (targets) {
        if (targets == null || targets.isEmpty) {
          return const <String, StampNextTarget>{};
        }
        final values = <String, StampNextTarget>{};
        for (final target in targets) {
          values.putIfAbsent(_normalizeCityName(target.cityName), () => target);
        }
        return values;
      },
      orElse: () => const <String, StampNextTarget>{},
    );
    final selectedTarget =
        selectedRegion == null ? null : targetsByCity[selectedRegion.city];

    return Column(
      children: [
        Container(
          margin: const EdgeInsets.fromLTRB(14, 12, 14, 12),
          height: 470,
          decoration: BoxDecoration(
            color: const Color(0xFFDDF2FA),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFFC7E7F0)),
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
                      final city =
                          _hitTestRegion(details.localPosition, mapRect);
                      if (city == null) {
                        return;
                      }
                      setState(() => _selectedCity = city);
                    },
                    child: CustomPaint(
                      painter: _GangwonMapPainter(
                        stampsByCity: stampsByCity,
                        selectedCity: selectedRegion?.city,
                      ),
                      child: const SizedBox.expand(),
                    ),
                  ),
                  for (final region in gangwonMapRegions)
                    Positioned(
                      left:
                          mapRect.left + region.anchor.dx * mapRect.width - 38,
                      top: mapRect.top + region.anchor.dy * mapRect.height - 20,
                      width: 76,
                      child: GestureDetector(
                        onTap: () =>
                            setState(() => _selectedCity = region.city),
                        child: _StampMapNode(
                          region: region,
                          stamp: stampsByCity[region.city],
                          target: targetsByCity[region.city],
                          selected: selectedRegion?.city == region.city,
                        ),
                      ),
                    ),
                  Positioned(
                    top: 14,
                    right: 14,
                    child: _MapPassportBadge(
                      acquiredCount: widget.progress.acquiredCount,
                      totalCount: widget.progress.totalCount,
                      onTap: () => context.push('/main/stamps/cities'),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
        if (selectedRegion != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
            child: _SelectedRegionCard(
              region: selectedRegion,
              stamp: selectedStamp,
              target: selectedTarget,
              onTargetTap: () {
                if (selectedTarget == null) {
                  ScaffoldMessenger.of(context)
                    ..hideCurrentSnackBar()
                    ..showSnackBar(
                      SnackBar(
                        content: Text(
                          '${_primaryLandmark(selectedRegion)} 스탬프 장소 데이터를 연결한 뒤 방문 인증할 수 있어요.',
                        ),
                      ),
                    );
                  return;
                }
                widget.onTargetTap(selectedTarget);
              },
            ),
          )
        else
          const Padding(
            padding: EdgeInsets.fromLTRB(14, 0, 14, 14),
            child: _EmptyRegionCard(),
          ),
      ],
    );
  }
}

class _GangwonMapPainter extends CustomPainter {
  const _GangwonMapPainter({
    required this.stampsByCity,
    required this.selectedCity,
  });

  final Map<String, RallybookStamp> stampsByCity;
  final String? selectedCity;

  @override
  void paint(Canvas canvas, Size size) {
    final mapRect = _gangwonMapRect(size);
    canvas.drawRect(
        Offset.zero & size, Paint()..color = const Color(0xFFDDF2FA));

    var fullPath = Path();
    final fillPaint = Paint()..style = PaintingStyle.fill;
    final thinLinePaint = Paint()
      ..color = const Color(0xFFB9E2EA)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final selectedLinePaint = Paint()
      ..color = const Color(0xFF59B8C7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    for (final region in gangwonMapRegions) {
      final path = _regionPath(region, mapRect);
      try {
        fullPath = fullPath.computeMetrics().isEmpty
            ? path
            : Path.combine(PathOperation.union, fullPath, path);
      } catch (_) {
        fullPath.addPath(path, Offset.zero);
      }
    }

    final coastlinePaint = Paint()
      ..color = const Color(0xFF9FCFE0).withValues(alpha: 0.55)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.6);
    canvas.drawPath(fullPath.shift(const Offset(7, 8)), coastlinePaint);

    for (final region in gangwonMapRegions) {
      if (region.city == selectedCity) {
        continue;
      }
      final path = _regionPath(region, mapRect);
      final acquired = stampsByCity[region.city]?.acquired ?? false;
      fillPaint.color = acquired ? const Color(0xFFF1FFF6) : AppColors.surface;
      canvas.drawPath(path, fillPaint);
      canvas.drawPath(path, thinLinePaint);
    }

    final outerPaint = Paint()
      ..color = const Color(0xFFB9E2EA)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(fullPath, outerPaint);

    final selectedRegion =
        selectedCity == null ? null : _findRegion(selectedCity!);
    if (selectedRegion != null) {
      final path = _scaledPath(_regionPath(selectedRegion, mapRect), 1.035);
      fillPaint.color = const Color(0xFFE9FBF4);
      canvas.drawPath(path, fillPaint);
      canvas.drawPath(path, selectedLinePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _GangwonMapPainter oldDelegate) {
    return oldDelegate.stampsByCity != stampsByCity ||
        oldDelegate.selectedCity != selectedCity;
  }
}

Rect _gangwonMapRect(Size size) {
  const mapAspectRatio = 1000 / 1180;
  final available = Rect.fromLTWH(10, 34, size.width - 20, size.height - 68);
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
  var regionPath = Path();
  for (final polygon in region.polygons) {
    if (polygon.length < 3) {
      continue;
    }
    final polygonPath = Path()
      ..addPolygon(
        [
          for (final point in polygon)
            Offset(
              mapRect.left + point.dx * mapRect.width,
              mapRect.top + point.dy * mapRect.height,
            ),
        ],
        true,
      );

    try {
      regionPath = regionPath.computeMetrics().isEmpty
          ? polygonPath
          : Path.combine(PathOperation.union, regionPath, polygonPath);
    } catch (_) {
      regionPath.addPath(polygonPath, Offset.zero);
    }
  }
  return regionPath;
}

Path _scaledPath(Path path, double scale) {
  final bounds = path.getBounds();
  if (bounds.isEmpty) {
    return path;
  }
  final center = bounds.center;
  final matrix = Matrix4.identity()
    ..translateByDouble(center.dx, center.dy, 0, 1)
    ..scaleByDouble(scale, scale, 1, 1)
    ..translateByDouble(-center.dx, -center.dy, 0, 1);
  return path.transform(matrix.storage);
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
  final VoidCallback onTargetTap;

  @override
  Widget build(BuildContext context) {
    final acquired = stamp?.acquired ?? false;
    final statusText = acquired ? '스탬프 완료' : '방문 인증 필요';
    final spotName = target?.spotName ?? _primaryLandmark(region);
    final spotDescription = target == null
        ? region.landmarks
        : '${region.city} 스탬프 투어 명소 · ${target!.categoryLabel}';

    return Container(
      height: 186,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.97),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.line),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.max,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: acquired ? AppColors.primaryTint : AppColors.cream,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  acquired ? Icons.check_rounded : Icons.location_on_rounded,
                  color: acquired ? AppColors.primaryDark : AppColors.brown,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      spotName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${region.city} · $statusText',
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
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            spotDescription,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
              height: 1.35,
              fontWeight: FontWeight.w800,
              letterSpacing: 0,
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: FilledButton(
              onPressed: onTargetTap,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Text(
                '스탬프 찍기',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MapPassportBadge extends StatelessWidget {
  const _MapPassportBadge({
    required this.acquiredCount,
    required this.totalCount,
    required this.onTap,
  });

  final int acquiredCount;
  final int totalCount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: '스탬프 투어 보기',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: AppColors.surface.withValues(alpha: 0.94),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: AppColors.line),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.auto_stories_rounded,
                  color: AppColors.primaryDark,
                  size: 17,
                ),
                const SizedBox(width: 6),
                Text(
                  '$acquiredCount/$totalCount',
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyRegionCard extends StatelessWidget {
  const _EmptyRegionCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 186,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.line),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 18,
            offset: const Offset(0, 9),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.max,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: const BoxDecoration(
                  color: AppColors.primaryTint,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.touch_app_rounded,
                  color: AppColors.primaryDark,
                  size: 23,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '여행할 지역을 골라보세요',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0,
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      '강원 18개 시군 스탬프 투어',
                      style: TextStyle(
                        color: AppColors.primaryDark,
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            '지도 위 명소를 선택하면 방문 인증으로 이어지는 스탬프 장소가 나타나요.',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
              height: 1.35,
              fontWeight: FontWeight.w800,
              letterSpacing: 0,
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
    required this.target,
    required this.selected,
  });

  final GangwonMapRegion region;
  final RallybookStamp? stamp;
  final StampNextTarget? target;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final acquired = stamp?.acquired ?? false;
    final label = target?.spotName ?? _primaryLandmark(region);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: selected ? 34 : 26,
          height: selected ? 34 : 26,
          decoration: BoxDecoration(
            color: selected
                ? AppColors.secondary
                : acquired
                    ? AppColors.primary
                    : AppColors.surface,
            shape: BoxShape.circle,
            border: Border.all(
              color: AppColors.surface,
              width: selected ? 3 : 2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: selected ? 0.18 : 0.1),
                blurRadius: selected ? 12 : 5,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Icon(
            acquired ? Icons.check_rounded : Icons.flag_rounded,
            color:
                acquired || selected ? Colors.white : const Color(0xFF9A8C72),
            size: acquired ? 18 : 14,
          ),
        ),
        const SizedBox(height: 2),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
          decoration: BoxDecoration(
            color: AppColors.surface.withValues(alpha: 0.94),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: selected ? AppColors.secondary : AppColors.line,
            ),
          ),
          child: Text(
            label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 9,
              height: 1.1,
              fontWeight: FontWeight.w900,
              letterSpacing: 0,
            ),
          ),
        ),
      ],
    );
  }
}

String _normalizeCityName(String value) {
  return value.replaceAll(RegExp(r'(특별자치도|시|군|구)$'), '').trim();
}

String _primaryLandmark(GangwonMapRegion region) {
  return region.landmarks.split('/').first.trim();
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
              '스탬프 투어를 불러오지 못했습니다.',
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
    return const Center(
      child: Text(
        '로그인 후 스탬프 투어를 확인할 수 있어요.',
        style: TextStyle(
          color: AppColors.textSecondary,
          fontSize: 15,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
