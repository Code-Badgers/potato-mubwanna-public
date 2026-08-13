import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_design_tokens.dart';
import '../../../../core/network/api_exception.dart';
import '../../application/stamp_book_controller.dart';
import '../../domain/stamp_book.dart';
import '../model/gangwon_map_projection.dart';
import '../model/gangwon_map_region.dart';

const _stampTourLockedAsset = 'assets/stamps/stamp_tour_locked.png';
const _stampTourCompletedAsset = 'assets/stamps/stamp_tour_completed.png';

class StampBookScreen extends ConsumerWidget {
  const StampBookScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stampBook = ref.watch(stampBookProvider);
    final rallybookSpots = ref.watch(stampRallybookSpotsProvider);
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
                  rallybookSpots: rallybookSpots,
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
                  onPressed: () {
                    if (Navigator.of(context).canPop()) {
                      context.pop();
                      return;
                    }
                    context.go('/main/mypage');
                  },
                  icon: const Icon(Icons.arrow_back_rounded),
                  tooltip: '이전 화면으로 돌아가기',
                  style: IconButton.styleFrom(
                    backgroundColor: AppColors.surface,
                    foregroundColor: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    '지역별 랠리북',
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
                        '지역 세트 진행률',
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
            acquired ? '지역 완료' : '명소 대기',
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
    required this.rallybookSpots,
  });

  final StampBook stampBook;
  final AsyncValue<List<RallybookSpot>?> rallybookSpots;

  @override
  Widget build(BuildContext context) {
    final progress = stampBook.progress;
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: _GangwonStampMap(
            progress: progress,
            rallybookSpots: rallybookSpots,
            onSpotTap: (spot) => context.push('/spots/${spot.spotId}'),
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
    required this.rallybookSpots,
    required this.onSpotTap,
  });

  final StampProgress progress;
  final AsyncValue<List<RallybookSpot>?> rallybookSpots;
  final ValueChanged<RallybookSpot> onSpotTap;

  @override
  State<_GangwonStampMap> createState() => _GangwonStampMapState();
}

class _GangwonStampMapState extends State<_GangwonStampMap>
    with SingleTickerProviderStateMixin {
  String? _selectedCity;
  int? _selectedSpotId;
  String? _travelFromCity;
  late final AnimationController _travelController;

  @override
  void initState() {
    super.initState();
    _travelController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 780),
    )..value = 1;
  }

  @override
  void dispose() {
    _travelController.dispose();
    super.dispose();
  }

  void _selectSpot(RallybookSpot spot) {
    if (_selectedSpotId == spot.spotId) {
      return;
    }
    final city = _normalizeCityName(spot.cityName);
    setState(() {
      _travelFromCity = _selectedCity;
      _selectedCity = city;
      _selectedSpotId = spot.spotId;
    });
    _travelController.forward(from: 0);
  }

  void _selectCity(
    String city,
    Map<String, List<RallybookSpot>> spotsByCity,
  ) {
    final citySpots = spotsByCity[city];
    if (citySpots == null || citySpots.isEmpty) {
      return;
    }
    _selectSpot(citySpots.first);
  }

  @override
  Widget build(BuildContext context) {
    final stampsByCity = {
      for (final stamp in widget.progress.stamps)
        _normalizeCityName(stamp.cityName): stamp,
    };
    final rallybookSpots = widget.rallybookSpots.maybeWhen(
      data: (spots) => spots ?? const <RallybookSpot>[],
      orElse: () => const <RallybookSpot>[],
    );
    final spotsByCity = <String, List<RallybookSpot>>{};
    for (final spot in rallybookSpots) {
      spotsByCity
          .putIfAbsent(_normalizeCityName(spot.cityName), () => [])
          .add(spot);
    }
    final totalSpotCount = rallybookSpots.isEmpty ? 29 : rallybookSpots.length;
    final acquiredRegionCount = widget.progress.acquiredCount.clamp(
      0,
      widget.progress.totalCount == 0 ? 18 : widget.progress.totalCount,
    );
    final selectedSpot = _selectedSpotId == null
        ? null
        : _findSpotById(rallybookSpots, _selectedSpotId!);
    final selectedRegion = selectedSpot == null
        ? null
        : _findRegion(_normalizeCityName(selectedSpot.cityName));
    final selectedStamp =
        selectedRegion == null ? null : stampsByCity[selectedRegion.city];
    final selectedCitySpots = selectedRegion == null
        ? const <RallybookSpot>[]
        : spotsByCity[selectedRegion.city] ?? const <RallybookSpot>[];

    return Column(
      children: [
        Container(
          margin: const EdgeInsets.fromLTRB(14, 12, 14, 12),
          height: 438,
          decoration: BoxDecoration(
            color: const Color(0xFFDDF2FA),
            borderRadius: BorderRadius.circular(AppDimens.sheetRadius),
            border: Border.all(color: const Color(0xFFC7E7F0)),
          ),
          clipBehavior: Clip.antiAlias,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final size = constraints.biggest;
              final mapRect = _gangwonMapRect(size);

              Widget buildSpotNode(
                RallybookSpot spot, {
                required bool selected,
              }) {
                final anchor = _rallybookSpotAnchor(spot, mapRect);
                final width = selected ? 124.0 : 40.0;
                return Positioned(
                  left: anchor.dx - width / 2,
                  top: anchor.dy - (selected ? 19 : 16),
                  width: width,
                  child: GestureDetector(
                    key: ValueKey('rallybook-spot-marker-${spot.spotId}'),
                    behavior: HitTestBehavior.opaque,
                    onTap: () => _selectSpot(spot),
                    child: _RallybookSpotMapNode(
                      spot: spot,
                      stamp: stampsByCity[_normalizeCityName(spot.cityName)],
                      selected: selected,
                    ),
                  ),
                );
              }

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
                      _selectCity(city, spotsByCity);
                    },
                    child: CustomPaint(
                      painter: _GangwonMapPainter(
                        stampsByCity: stampsByCity,
                        selectedCity: selectedRegion?.city,
                      ),
                      child: const SizedBox.expand(),
                    ),
                  ),
                  if (selectedRegion != null && selectedSpot != null)
                    Positioned.fill(
                      child: IgnorePointer(
                        child: AnimatedBuilder(
                          animation: _travelController,
                          builder: (context, _) {
                            final start = _stampTravelStart(
                              mapRect,
                              fromCity: _travelFromCity,
                            );
                            return CustomPaint(
                              painter: _StampTravelRoutePainter(
                                start: start,
                                end: _rallybookSpotAnchor(
                                  selectedSpot,
                                  mapRect,
                                ),
                                progress: _travelController.value,
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  for (final spot in rallybookSpots)
                    if (spot.spotId != selectedSpot?.spotId)
                      buildSpotNode(spot, selected: false),
                  if (selectedSpot != null)
                    buildSpotNode(selectedSpot, selected: true),
                  if (selectedRegion != null && selectedSpot != null)
                    Positioned.fill(
                      child: IgnorePointer(
                        child: AnimatedBuilder(
                          animation: _travelController,
                          builder: (context, _) {
                            final start = _stampTravelStart(
                              mapRect,
                              fromCity: _travelFromCity,
                            );
                            final end = _rallybookSpotAnchor(
                              selectedSpot,
                              mapRect,
                            );
                            final value = Curves.easeInOutCubic
                                .transform(_travelController.value);
                            final position = Offset.lerp(start, end, value)!;

                            return Stack(
                              children: [
                                Positioned(
                                  left: position.dx - 18,
                                  top: position.dy - 18,
                                  width: 36,
                                  height: 36,
                                  child: const _StampTravelCarMarker(),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                    ),
                  Positioned(
                    top: 14,
                    right: 14,
                    child: _MapProgressBadge(
                      stampCount: acquiredRegionCount,
                      totalStampCount: totalSpotCount,
                      regionCount: acquiredRegionCount,
                      totalRegionCount: widget.progress.totalCount == 0
                          ? 18
                          : widget.progress.totalCount,
                      onTap: () => context.push('/main/stamps/cities'),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
        if (selectedRegion != null && selectedSpot != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
            child: _SelectedRegionCard(
              region: selectedRegion,
              stamp: selectedStamp,
              spot: selectedSpot,
              citySpots: selectedCitySpots,
              onSpotSelect: _selectSpot,
              onSpotTap: () => widget.onSpotTap(selectedSpot),
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

Offset _stampTravelStart(
  Rect mapRect, {
  String? fromCity,
}) {
  if (fromCity != null) {
    final fromRegion = _findRegion(fromCity);
    if (fromRegion != null) {
      return _stampRegionAnchor(fromRegion, mapRect);
    }
  }

  return Offset(
    mapRect.left + mapRect.width * 0.16,
    mapRect.top + mapRect.height * 0.86,
  );
}

Offset _stampRegionAnchor(GangwonMapRegion region, Rect mapRect) {
  return Offset(
    mapRect.left + region.anchor.dx * mapRect.width,
    mapRect.top + region.anchor.dy * mapRect.height,
  );
}

Offset _rallybookSpotAnchor(RallybookSpot spot, Rect mapRect) {
  final normalized = projectToGangwonMap(
    latitude: spot.latitude,
    longitude: spot.longitude,
  );
  return Offset(
    mapRect.left + normalized.dx * mapRect.width,
    mapRect.top + normalized.dy * mapRect.height,
  );
}

class _StampTravelRoutePainter extends CustomPainter {
  const _StampTravelRoutePainter({
    required this.start,
    required this.end,
    required this.progress,
  });

  final Offset start;
  final Offset end;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final control = Offset(
      (start.dx + end.dx) / 2,
      (start.dy + end.dy) / 2 - 44,
    );
    final routePaint = Paint()
      ..color = AppColors.primary.withValues(alpha: 0.52)
      ..style = PaintingStyle.fill;
    const dotCount = 22;
    for (var index = 0; index <= dotCount; index += 1) {
      final t = index / dotCount;
      if (t > progress) {
        break;
      }
      final point = _quadraticPoint(start, control, end, t);
      final fade = (0.42 + t * 0.36).clamp(0.0, 1.0);
      canvas.drawCircle(
        point,
        2.2,
        routePaint..color = AppColors.primary.withValues(alpha: fade),
      );
    }

    final haloPaint = Paint()
      ..color = AppColors.secondary.withValues(alpha: 0.16 * progress)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(end, 22 * progress, haloPaint);
  }

  Offset _quadraticPoint(Offset a, Offset control, Offset b, double t) {
    final oneMinusT = 1 - t;
    return Offset(
      oneMinusT * oneMinusT * a.dx +
          2 * oneMinusT * t * control.dx +
          t * t * b.dx,
      oneMinusT * oneMinusT * a.dy +
          2 * oneMinusT * t * control.dy +
          t * t * b.dy,
    );
  }

  @override
  bool shouldRepaint(covariant _StampTravelRoutePainter oldDelegate) {
    return oldDelegate.start != start ||
        oldDelegate.end != end ||
        oldDelegate.progress != progress;
  }
}

class _StampTravelCarMarker extends StatelessWidget {
  const _StampTravelCarMarker();

  @override
  Widget build(BuildContext context) {
    return const CustomPaint(
      painter: _StampTravelCarPainter(),
    );
  }
}

class _StampTravelCarPainter extends CustomPainter {
  const _StampTravelCarPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final bodyPaint = Paint()
      ..color = AppColors.primary
      ..style = PaintingStyle.fill;
    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.14)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.5);
    final windowPaint = Paint()
      ..color = const Color(0xFFDDF2FA)
      ..style = PaintingStyle.fill;
    final wheelPaint = Paint()
      ..color = const Color(0xFF6D6252)
      ..style = PaintingStyle.fill;

    final body = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        size.width * 0.19,
        size.height * 0.42,
        size.width * 0.62,
        size.height * 0.25,
      ),
      const Radius.circular(5),
    );
    final roof = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        size.width * 0.31,
        size.height * 0.29,
        size.width * 0.37,
        size.height * 0.22,
      ),
      const Radius.circular(5),
    );
    canvas.drawOval(
      Rect.fromLTWH(
        size.width * 0.18,
        size.height * 0.68,
        size.width * 0.64,
        size.height * 0.16,
      ),
      shadowPaint,
    );
    canvas.drawRRect(body, bodyPaint);
    canvas.drawRRect(roof, bodyPaint);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          size.width * 0.39,
          size.height * 0.34,
          size.width * 0.20,
          size.height * 0.12,
        ),
        const Radius.circular(2),
      ),
      windowPaint,
    );
    canvas.drawCircle(
      Offset(size.width * 0.33, size.height * 0.69),
      size.width * 0.055,
      wheelPaint,
    );
    canvas.drawCircle(
      Offset(size.width * 0.68, size.height * 0.69),
      size.width * 0.055,
      wheelPaint,
    );
    canvas.drawCircle(
      Offset(size.width * 0.75, size.height * 0.51),
      size.width * 0.025,
      Paint()..color = AppColors.secondary,
    );
  }

  @override
  bool shouldRepaint(covariant _StampTravelCarPainter oldDelegate) => false;
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

RallybookSpot? _findSpotById(List<RallybookSpot> spots, int spotId) {
  for (final spot in spots) {
    if (spot.spotId == spotId) {
      return spot;
    }
  }
  return null;
}

class _SelectedRegionCard extends StatelessWidget {
  const _SelectedRegionCard({
    required this.region,
    required this.stamp,
    required this.spot,
    required this.citySpots,
    required this.onSpotSelect,
    required this.onSpotTap,
  });

  final GangwonMapRegion region;
  final RallybookStamp? stamp;
  final RallybookSpot spot;
  final List<RallybookSpot> citySpots;
  final ValueChanged<RallybookSpot> onSpotSelect;
  final VoidCallback onSpotTap;

  @override
  Widget build(BuildContext context) {
    final acquired = stamp?.acquired ?? false;
    final statusText = acquired ? '지역 기록 완료' : '관광지 스탬프 대기';

    return Container(
      height: 214,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.97),
        borderRadius: BorderRadius.circular(AppDimens.cardRadius),
        border: Border.all(color: AppColors.line.withValues(alpha: 0.82)),
        boxShadow: AppShadows.floating,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.max,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _TourStampImage(
                acquired: acquired,
                size: 42,
                fallbackSize: 22,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      spot.spotName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0,
                      ),
                    ),
                    const SizedBox(height: 2),
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
          const SizedBox(height: 8),
          Text(
            '이곳에서 인증하면 ${region.city} 여행 기록이 채워져요',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
              height: 1.3,
              fontWeight: FontWeight.w800,
              letterSpacing: 0,
            ),
          ),
          const SizedBox(height: 7),
          SizedBox(
            height: 32,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: citySpots.length,
              separatorBuilder: (_, __) => const SizedBox(width: 6),
              itemBuilder: (context, index) {
                final citySpot = citySpots[index];
                return ChoiceChip(
                  key: ValueKey('rallybook-city-spot-${citySpot.spotId}'),
                  label: Text(citySpot.spotName),
                  selected: citySpot.spotId == spot.spotId,
                  onSelected: (_) => onSpotSelect(citySpot),
                  labelStyle: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                  visualDensity: VisualDensity.compact,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: FilledButton(
              onPressed: onSpotTap,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppDimens.buttonRadius),
                ),
              ),
              child: const Text(
                '방문 인증하기',
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

class _MapProgressBadge extends StatelessWidget {
  const _MapProgressBadge({
    required this.stampCount,
    required this.totalStampCount,
    required this.regionCount,
    required this.totalRegionCount,
    required this.onTap,
  });

  final int stampCount;
  final int totalStampCount;
  final int regionCount;
  final int totalRegionCount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: '지역별 랠리북 보기',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: AppColors.surface.withValues(alpha: 0.78),
            borderRadius: BorderRadius.circular(AppDimens.pillRadius),
            border: Border.all(
              color: AppColors.surface.withValues(alpha: 0.92),
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.textPrimary.withValues(alpha: 0.07),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.local_activity_rounded,
                  color: AppColors.primaryDark,
                  size: 16,
                ),
                const SizedBox(width: 6),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '스탬프 $stampCount/$totalStampCount',
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0,
                      ),
                    ),
                    Text(
                      '지역 $regionCount/$totalRegionCount',
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0,
                      ),
                    ),
                  ],
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
      height: 168,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimens.cardRadius),
        border: Border.all(color: AppColors.line.withValues(alpha: 0.82)),
        boxShadow: AppShadows.softCard,
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
              const SizedBox(width: 10),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '오늘 찍을 스탬프를 골라보세요',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      '강원 대표 명소 스탬프 랠리',
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
          const SizedBox(height: 8),
          const Text(
            '명소에서 인증하면 관광지 스탬프가 쌓여요.\n지역 랠리북도 함께 채워집니다.',
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
              height: 1.42,
              fontWeight: FontWeight.w800,
              letterSpacing: 0,
            ),
          ),
        ],
      ),
    );
  }
}

class _TourStampImage extends StatelessWidget {
  const _TourStampImage({
    required this.acquired,
    required this.size,
    required this.fallbackSize,
  });

  final bool acquired;
  final double size;
  final double fallbackSize;

  @override
  Widget build(BuildContext context) {
    final assetPath =
        acquired ? _stampTourCompletedAsset : _stampTourLockedAsset;
    return Image.asset(
      assetPath,
      width: size,
      height: size,
      fit: BoxFit.contain,
      semanticLabel: acquired ? '획득한 관광지 스탬프' : '잠긴 관광지 스탬프',
      errorBuilder: (_, __, ___) => Icon(
        acquired ? Icons.verified_rounded : Icons.lock_rounded,
        color: acquired ? AppColors.primaryDark : AppColors.textSecondary,
        size: fallbackSize,
      ),
    );
  }
}

class _RallybookSpotMapNode extends StatelessWidget {
  const _RallybookSpotMapNode({
    required this.spot,
    required this.stamp,
    required this.selected,
  });

  final RallybookSpot spot;
  final RallybookStamp? stamp;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final acquired = stamp?.acquired ?? false;
    final stampColor = acquired
        ? AppColors.primary
        : selected
            ? AppColors.secondary
            : const Color(0xFFC9BFA8);
    final fillColor = acquired
        ? AppColors.primaryTint
        : selected
            ? const Color(0xFFFFF4CF)
            : AppColors.surface.withValues(alpha: 0.96);

    return Semantics(
      label: spot.spotName,
      button: true,
      child: AnimatedScale(
        scale: selected ? 1.07 : 1,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: selected ? 38 : 30,
              height: selected ? 38 : 30,
              decoration: BoxDecoration(
                color: fillColor,
                shape: BoxShape.circle,
                border: Border.all(
                  color: stampColor,
                  width: selected ? 3 : 2.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: stampColor.withValues(
                      alpha: selected ? 0.24 : 0.12,
                    ),
                    blurRadius: selected ? 12 : 5,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: selected ? 19 : 15,
                    height: selected ? 19 : 15,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: stampColor.withValues(alpha: 0.62),
                        width: 2,
                      ),
                    ),
                  ),
                  Icon(
                    acquired ? Icons.check_rounded : Icons.flag_rounded,
                    color: stampColor,
                    size: acquired ? 18 : 14,
                  ),
                ],
              ),
            ),
            if (selected) ...[
              const SizedBox(height: 2),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 6,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: AppColors.surface.withValues(alpha: 0.94),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.secondary),
                ),
                child: Text(
                  spot.spotName,
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
          ],
        ),
      ),
    );
  }
}

String _normalizeCityName(String value) {
  return value.replaceAll(RegExp(r'(특별자치도|시|군|구)$'), '').trim();
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
