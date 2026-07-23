import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/config/app_environment.dart';
import '../../../../app/theme/app_colors.dart';
import '../../application/map_spot_controller.dart';
import '../../domain/favorite_spot_route.dart';
import '../../domain/map_spot.dart';
import '../widget/kakao_map_view.dart';

typedef MapViewBuilder = Widget Function(
  List<MapSpot> spots,
  ValueChanged<String> onSpotSelected,
);

const _mapPrimary = Color(0xFF36D98F);
const _mapDark = Color(0xFF509B64);
const _rareGold = Color(0xFFF6C23E);

class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({
    this.hasMapConfiguration,
    this.mapViewBuilder,
    super.key,
  });

  final bool? hasMapConfiguration;
  final MapViewBuilder? mapViewBuilder;

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen> {
  int _selectedCategoryIndex = 0;
  String? _selectedSpotId;
  bool _showFavoriteRouteOnly = false;

  static const _categories = [
    _MapCategoryFilter(label: '전체', icon: Icons.grid_view_rounded),
    _MapCategoryFilter(label: '맛집', icon: Icons.restaurant_rounded),
    _MapCategoryFilter(label: '카페', icon: Icons.local_cafe_rounded),
    _MapCategoryFilter(label: '관광', icon: Icons.landscape_rounded),
    _MapCategoryFilter(label: '체험', icon: Icons.directions_walk_rounded),
    _MapCategoryFilter(label: '간식', icon: Icons.bakery_dining_rounded),
    _MapCategoryFilter(label: '시장', icon: Icons.storefront_rounded),
    _MapCategoryFilter(label: '바 & 페어링', icon: Icons.sports_bar_rounded),
    _MapCategoryFilter(label: '쇼핑', icon: Icons.shopping_bag_rounded),
  ];

  List<MapSpot> _visibleSpots(
      List<MapSpot> spots, Set<String> favoriteSpotIds) {
    final selectedCategory = _categories[_selectedCategoryIndex].label;
    return spots.where((spot) {
      final matchesCategory = selectedCategory == '전체' ||
          spot.matchesCategoryLabel(selectedCategory);
      final matchesFavoriteRoute =
          !_showFavoriteRouteOnly || favoriteSpotIds.contains(spot.id);
      return matchesCategory && matchesFavoriteRoute;
    }).toList();
  }

  MapSpot? _selectedSpot(List<MapSpot> spots) {
    if (spots.isEmpty) {
      return null;
    }
    final selectedSpotId = _selectedSpotId;
    if (selectedSpotId == null) {
      return spots.first;
    }
    for (final spot in spots) {
      if (spot.id == selectedSpotId) {
        return spot;
      }
    }
    return spots.first;
  }

  List<MapSpot> _recommendedRouteSpots(
    List<MapSpot> spots,
    Set<String> favoriteSpotIds,
    MapSpot? selectedSpot,
  ) {
    final favoriteSpots = spots
        .where((spot) => favoriteSpotIds.contains(spot.id))
        .where((spot) => spot.latitude != 0 && spot.longitude != 0)
        .toList();
    if (favoriteSpots.length <= 2) {
      return favoriteSpots;
    }

    final route = <MapSpot>[];
    final remaining = [...favoriteSpots];
    MapSpot current =
        selectedSpot != null && favoriteSpotIds.contains(selectedSpot.id)
            ? selectedSpot
            : remaining.first;
    route.add(current);
    remaining.removeWhere((spot) => spot.id == current.id);

    while (remaining.isNotEmpty) {
      remaining.sort((a, b) {
        final distanceA = current.distanceKmTo(a);
        final distanceB = current.distanceKmTo(b);
        return distanceA.compareTo(distanceB);
      });
      current = remaining.removeAt(0);
      route.add(current);
    }

    return route;
  }

  List<MapSpot> _routeSpotsFromBackend(
    List<MapSpot> spots,
    FavoriteSpotRoute route,
  ) {
    if (!route.hasRoute) {
      return const [];
    }
    final spotsById = {for (final spot in spots) spot.id: spot};
    return route.waypoints
        .map((waypoint) => spotsById[waypoint.spotId])
        .whereType<MapSpot>()
        .toList();
  }

  void _selectCategory(int index) {
    setState(() {
      _selectedCategoryIndex = index;
      _selectedSpotId = null;
    });
  }

  void _toggleFavoriteRouteOnly() {
    setState(() {
      _showFavoriteRouteOnly = !_showFavoriteRouteOnly;
      _selectedSpotId = null;
    });
  }

  void _selectSpotById(String spotId) {
    setState(() {
      _selectedSpotId = spotId;
    });
  }

  @override
  Widget build(BuildContext context) {
    final spotsState = ref.watch(mapSpotsProvider);
    final favoriteSpotsState = ref.watch(favoriteSpotControllerProvider);
    final favoriteSpotRouteState = ref.watch(favoriteSpotRouteProvider);
    final favoriteSpotIds = favoriteSpotsState.valueOrNull ?? <String>{};

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: spotsState.when(
                  data: (spots) {
                    final hasMapConfiguration = widget.hasMapConfiguration ??
                        (kIsWeb
                            ? AppEnvironment.kakaoJavaScriptKey.isNotEmpty
                            : AppEnvironment.kakaoNativeAppKey.isNotEmpty);
                    if (!hasMapConfiguration) {
                      return const _MapConfigurationError();
                    }

                    final visibleSpots = _visibleSpots(spots, favoriteSpotIds);
                    final selectedSpot = _selectedSpot(visibleSpots);
                    final routeSpots = _recommendedRouteSpots(
                      spots,
                      favoriteSpotIds,
                      selectedSpot,
                    );
                    final backendRoute = favoriteSpotRouteState.valueOrNull;
                    final backendRouteSpots = backendRoute == null
                        ? const <MapSpot>[]
                        : _routeSpotsFromBackend(spots, backendRoute);
                    final recommendedRouteSpots = backendRouteSpots.length >= 2
                        ? backendRouteSpots
                        : routeSpots;
                    final recommendedRouteDistanceKm =
                        backendRouteSpots.length >= 2
                            ? backendRoute?.totalDistanceKm
                            : null;
                    return Stack(
                      children: [
                        Positioned.fill(
                          child: _PotatoMapPreview(
                            spots: visibleSpots,
                            onSpotSelected: _selectSpotById,
                            mapViewBuilder: widget.mapViewBuilder,
                          ),
                        ),
                        Positioned(
                          left: 12,
                          right: 12,
                          top: 18,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _RouteModeChip(
                                enabled: _showFavoriteRouteOnly,
                                favoriteCount: favoriteSpotIds.length,
                                onTap: _toggleFavoriteRouteOnly,
                              ),
                              const SizedBox(height: 10),
                              _CategoryFilterBar(
                                categories: _categories,
                                selectedIndex: _selectedCategoryIndex,
                                onSelected: _selectCategory,
                              ),
                            ],
                          ),
                        ),
                        if (selectedSpot == null)
                          const Positioned.fill(
                            child: _EmptySpotMessage(),
                          )
                        else
                          _RouteRecommendationSheet(
                            selectedSpot: selectedSpot,
                            routeSpots: recommendedRouteSpots,
                            routeDistanceKm: recommendedRouteDistanceKm,
                            favoriteCount: favoriteSpotIds.length,
                            isFavorite:
                                favoriteSpotIds.contains(selectedSpot.id),
                            onFavoritePressed: () async {
                              try {
                                await ref
                                    .read(
                                      favoriteSpotControllerProvider.notifier,
                                    )
                                    .toggle(selectedSpot.id);
                                ref.invalidate(favoriteSpotRouteProvider);
                              } on FavoriteSpotToggleException catch (error) {
                                if (!context.mounted) {
                                  return;
                                }
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(error.message),
                                  ),
                                );
                              } catch (_) {
                                if (!context.mounted) {
                                  return;
                                }
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('내 동선을 저장하지 못했습니다.'),
                                  ),
                                );
                              }
                            },
                            onDetailPressed: () {
                              context.go('/spots/${selectedSpot.id}');
                            },
                          ),
                      ],
                    );
                  },
                  loading: () => const _MapLoading(),
                  error: (_, __) => _MapDataError(
                    onRetry: () => ref.invalidate(mapSpotsProvider),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RouteRecommendationSheet extends StatelessWidget {
  const _RouteRecommendationSheet({
    required this.selectedSpot,
    required this.routeSpots,
    required this.routeDistanceKm,
    required this.favoriteCount,
    required this.isFavorite,
    required this.onFavoritePressed,
    required this.onDetailPressed,
  });

  final MapSpot selectedSpot;
  final List<MapSpot> routeSpots;
  final double? routeDistanceKm;
  final int favoriteCount;
  final bool isFavorite;
  final Future<void> Function() onFavoritePressed;
  final VoidCallback onDetailPressed;

  @override
  Widget build(BuildContext context) {
    final hasRoute = routeSpots.length >= 2;
    final totalDistance = routeDistanceKm ?? routeSpots.totalRouteDistanceKm;
    return DraggableScrollableSheet(
      minChildSize: 0.24,
      initialChildSize: hasRoute ? 0.34 : 0.28,
      maxChildSize: 0.78,
      snap: true,
      snapSizes: hasRoute ? const [0.34, 0.78] : const [0.28, 0.56],
      builder: (context, scrollController) {
        return DecoratedBox(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border.all(color: const Color(0xFFE8E2D8)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.12),
                blurRadius: 24,
                offset: const Offset(0, -8),
              ),
            ],
          ),
          child: SingleChildScrollView(
            controller: scrollController,
            padding: const EdgeInsets.fromLTRB(18, 10, 18, 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Center(child: _SheetDragHandle()),
                const SizedBox(height: 8),
                _SelectedSpotSummary(
                  spot: selectedSpot,
                  favoriteCount: favoriteCount,
                  isFavorite: isFavorite,
                  onFavoritePressed: onFavoritePressed,
                  onDetailPressed: onDetailPressed,
                ),
                if (hasRoute) ...[
                  const SizedBox(height: 18),
                  _RouteSummaryHeader(
                    count: routeSpots.length,
                    distanceKm: totalDistance,
                  ),
                  const SizedBox(height: 12),
                  for (var index = 0; index < routeSpots.length; index++) ...[
                    _RouteStopTile(
                      index: index,
                      spot: routeSpots[index],
                      distanceFromPrevious: index == 0
                          ? null
                          : routeSpots[index - 1]
                              .distanceKmTo(routeSpots[index]),
                    ),
                    if (index < routeSpots.length - 1) const _RouteConnector(),
                  ],
                  const SizedBox(height: 14),
                  FilledButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.near_me_rounded, size: 19),
                    label: const Text('이 동선 따라가기'),
                    style: FilledButton.styleFrom(
                      backgroundColor: _rareGold,
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      textStyle: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

class _SheetDragHandle extends StatelessWidget {
  const _SheetDragHandle();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 5,
      decoration: BoxDecoration(
        color: const Color(0xFFD8D2C8),
        borderRadius: BorderRadius.circular(999),
      ),
    );
  }
}

class _SelectedSpotSummary extends StatelessWidget {
  const _SelectedSpotSummary({
    required this.spot,
    required this.favoriteCount,
    required this.isFavorite,
    required this.onFavoritePressed,
    required this.onDetailPressed,
  });

  final MapSpot spot;
  final int favoriteCount;
  final bool isFavorite;
  final Future<void> Function() onFavoritePressed;
  final VoidCallback onDetailPressed;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    spot.name,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 19,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${spot.cityName} · ${spot.categoryLabel} · ${spot.potatoName}',
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0,
                    ),
                  ),
                ],
              ),
            ),
            IconButton.filledTonal(
              onPressed: onFavoritePressed,
              style: IconButton.styleFrom(
                backgroundColor: isFavorite
                    ? const Color(0xFFFFF2B8)
                    : const Color(0xFFEAF8EF),
                foregroundColor: isFavorite ? _rareGold : _mapDark,
              ),
              icon: Icon(
                isFavorite ? Icons.bookmark_rounded : Icons.bookmark_border,
              ),
              tooltip: isFavorite ? '동선에서 제거' : '내 동선에 추가',
            ),
            const SizedBox(width: 8),
            _CongestionBadge(label: spot.congestionLabel),
          ],
        ),
        const SizedBox(height: 12),
        if (spot.isRare) const _RarePotatoLine() else const _NormalPotatoLine(),
        if (favoriteCount > 0) ...[
          const SizedBox(height: 10),
          _FavoriteRouteLine(count: favoriteCount),
        ],
        const SizedBox(height: 14),
        Row(
          children: [
            SizedBox(
              width: 118,
              child: OutlinedButton(
                onPressed: () {},
                style: OutlinedButton.styleFrom(
                  foregroundColor: _mapDark,
                  side: const BorderSide(color: Color(0xFFC9E9D3)),
                  minimumSize: const Size.fromHeight(48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                child: const Text('길찾기'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: FilledButton(
                onPressed: onDetailPressed,
                style: FilledButton.styleFrom(
                  backgroundColor: _mapPrimary,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                child: const Text('상세보기'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _RouteSummaryHeader extends StatelessWidget {
  const _RouteSummaryHeader({
    required this.count,
    required this.distanceKm,
  });

  final int count;
  final double distanceKm;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(
          child: Text(
            '추천 동선',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w900,
              letterSpacing: 0,
            ),
          ),
        ),
        Text(
          '$count곳 · 직선 ${distanceKm.toStringAsFixed(1)}km',
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w800,
            letterSpacing: 0,
          ),
        ),
      ],
    );
  }
}

class _RouteStopTile extends StatelessWidget {
  const _RouteStopTile({
    required this.index,
    required this.spot,
    required this.distanceFromPrevious,
  });

  final int index;
  final MapSpot spot;
  final double? distanceFromPrevious;

  @override
  Widget build(BuildContext context) {
    final isFirst = index == 0;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _RouteStepBadge(index: index, first: isFirst),
        const SizedBox(width: 12),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFECE6DC)),
            ),
            child: Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Color(
                      int.parse(spot.markerColorHex.replaceFirst('#', '0xFF')),
                    ).withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    spot.isRare ? '🥔★' : '🥔',
                    style: const TextStyle(fontSize: 18),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        spot.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isFirst
                            ? '출발 위치'
                            : '이전 장소에서 직선 ${distanceFromPrevious!.toStringAsFixed(1)}km',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _RouteStepBadge extends StatelessWidget {
  const _RouteStepBadge({
    required this.index,
    required this.first,
  });

  final int index;
  final bool first;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 30,
      height: 30,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: first ? const Color(0xFF65B7E8) : _mapDark,
        shape: BoxShape.circle,
      ),
      child: first
          ? const Icon(Icons.flag_rounded, size: 16, color: Colors.white)
          : Text(
              '${index + 1}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w900,
                letterSpacing: 0,
              ),
            ),
    );
  }
}

class _RouteConnector extends StatelessWidget {
  const _RouteConnector();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.only(left: 15),
      child: SizedBox(
        height: 14,
        child: VerticalDivider(
          width: 1,
          thickness: 1,
          color: Color(0xFFD5E7DB),
        ),
      ),
    );
  }
}

class _RouteModeChip extends StatelessWidget {
  const _RouteModeChip({
    required this.enabled,
    required this.favoriteCount,
    required this.onTap,
  });

  final bool enabled;
  final int favoriteCount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final backgroundColor = enabled ? const Color(0xFFFFF2B8) : Colors.white;
    final foregroundColor = enabled ? AppColors.textPrimary : _mapDark;
    return Material(
      color: backgroundColor.withValues(alpha: 0.96),
      borderRadius: BorderRadius.circular(999),
      elevation: 3,
      shadowColor: Colors.black.withValues(alpha: 0.12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                enabled ? Icons.route_rounded : Icons.bookmark_border_rounded,
                size: 18,
                color: enabled ? _rareGold : _mapDark,
              ),
              const SizedBox(width: 7),
              Text(
                enabled ? '내 동선만 보기' : '내 동선 $favoriteCount곳',
                style: TextStyle(
                  color: foregroundColor,
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PotatoMapPreview extends StatelessWidget {
  const _PotatoMapPreview({
    required this.spots,
    required this.onSpotSelected,
    this.mapViewBuilder,
  });

  final List<MapSpot> spots;
  final ValueChanged<String> onSpotSelected;
  final MapViewBuilder? mapViewBuilder;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: DecoratedBox(
        decoration: const BoxDecoration(color: Color(0xFFEAF5D5)),
        child: Stack(
          children: [
            Positioned.fill(
              child: mapViewBuilder?.call(spots, onSpotSelected) ??
                  KakaoMapView(
                    spots: spots,
                    onSpotSelected: onSpotSelected,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryFilterBar extends StatelessWidget {
  const _CategoryFilterBar({
    required this.categories,
    required this.selectedIndex,
    required this.onSelected,
  });

  final List<_MapCategoryFilter> categories;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (var index = 0; index < categories.length; index++) ...[
            _MapCategoryChip(
              category: categories[index],
              selected: selectedIndex == index,
              onTap: () => onSelected(index),
            ),
            if (index < categories.length - 1) const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }
}

class _MapCategoryChip extends StatelessWidget {
  const _MapCategoryChip({
    required this.category,
    required this.selected,
    required this.onTap,
  });

  final _MapCategoryFilter category;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final foregroundColor = selected ? Colors.white : AppColors.textPrimary;
    return Material(
      color: selected ? _mapPrimary : Colors.white.withValues(alpha: 0.94),
      borderRadius: BorderRadius.circular(999),
      elevation: selected ? 4 : 1,
      shadowColor: Colors.black.withValues(alpha: 0.14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          height: 40,
          padding: const EdgeInsets.symmetric(horizontal: 13),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: selected ? _mapPrimary : const Color(0xFFE8E2D8),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(category.icon, size: 17, color: foregroundColor),
              const SizedBox(width: 6),
              Text(
                category.label,
                style: TextStyle(
                  color: foregroundColor,
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MapCategoryFilter {
  const _MapCategoryFilter({
    required this.label,
    required this.icon,
  });

  final String label;
  final IconData icon;
}

class _CongestionBadge extends StatelessWidget {
  const _CongestionBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF8EF),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        '혼잡도 $label',
        style: const TextStyle(
          color: _mapDark,
          fontSize: 12,
          fontWeight: FontWeight.w900,
          letterSpacing: 0,
        ),
      ),
    );
  }
}

class _RarePotatoLine extends StatelessWidget {
  const _RarePotatoLine();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        Icon(Icons.star_rounded, color: _rareGold, size: 19),
        SizedBox(width: 6),
        Text(
          '희귀 감자 출현 가능',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w800,
            letterSpacing: 0,
          ),
        ),
      ],
    );
  }
}

class _NormalPotatoLine extends StatelessWidget {
  const _NormalPotatoLine();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        Icon(Icons.eco_rounded, color: _mapPrimary, size: 18),
        SizedBox(width: 6),
        Text(
          '방문 인증 시 지역 감자 획득',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w800,
            letterSpacing: 0,
          ),
        ),
      ],
    );
  }
}

class _FavoriteRouteLine extends StatelessWidget {
  const _FavoriteRouteLine({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFAE5),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFF4E0A2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.route_rounded, color: _rareGold, size: 18),
          const SizedBox(width: 7),
          Text(
            '내 동선 $count곳 저장됨',
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w800,
              letterSpacing: 0,
            ),
          ),
        ],
      ),
    );
  }
}

class _MapLoading extends StatelessWidget {
  const _MapLoading();

  @override
  Widget build(BuildContext context) {
    return const DecoratedBox(
      decoration: BoxDecoration(color: Color(0xFFEAF5D5)),
      child: Center(
        child: CircularProgressIndicator(color: _mapPrimary),
      ),
    );
  }
}

class _MapConfigurationError extends StatelessWidget {
  const _MapConfigurationError();

  @override
  Widget build(BuildContext context) {
    return const _MapStatusCard(
      icon: Icons.map_outlined,
      title: '지도를 표시할 수 없습니다.',
      description: '지도 설정이 완료되지 않았습니다. 앱 관리자에게 문의해주세요.',
    );
  }
}

class _MapDataError extends StatelessWidget {
  const _MapDataError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return _MapStatusCard(
      icon: Icons.cloud_off_outlined,
      title: '감자 스팟 정보를 불러오지 못했습니다.',
      description: '네트워크 연결을 확인한 뒤 다시 시도해주세요.',
      actionLabel: '다시 시도',
      onAction: onRetry,
    );
  }
}

class _MapStatusCard extends StatelessWidget {
  const _MapStatusCard({
    required this.icon,
    required this.title,
    required this.description,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String description;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFFEAF5D5),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: _mapDark, size: 42),
              const SizedBox(height: 16),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                description,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  height: 1.45,
                  letterSpacing: 0,
                ),
              ),
              if (actionLabel != null && onAction != null) ...[
                const SizedBox(height: 20),
                FilledButton.icon(
                  onPressed: onAction,
                  icon: const Icon(Icons.refresh_rounded, size: 19),
                  label: Text(actionLabel!),
                  style: FilledButton.styleFrom(
                    backgroundColor: _mapDark,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptySpotMessage extends StatelessWidget {
  const _EmptySpotMessage();

  @override
  Widget build(BuildContext context) {
    return const IgnorePointer(
      child: Center(
        child: Padding(
          padding: EdgeInsets.fromLTRB(24, 0, 24, 120),
          child: Text(
            '아직 저장된 감자 스팟이 없습니다.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w900,
              letterSpacing: 0,
            ),
          ),
        ),
      ),
    );
  }
}

extension _MapSpotRouteDistance on MapSpot {
  double distanceKmTo(MapSpot other) {
    const earthRadiusKm = 6371.0;
    final lat1 = _toRadians(latitude);
    final lat2 = _toRadians(other.latitude);
    final deltaLat = _toRadians(other.latitude - latitude);
    final deltaLng = _toRadians(other.longitude - longitude);

    final haversine = math.sin(deltaLat / 2) * math.sin(deltaLat / 2) +
        math.cos(lat1) *
            math.cos(lat2) *
            math.sin(deltaLng / 2) *
            math.sin(deltaLng / 2);
    final centralAngle =
        2 * math.atan2(math.sqrt(haversine), math.sqrt(1 - haversine));
    return earthRadiusKm * centralAngle;
  }

  static double _toRadians(double degrees) {
    return degrees * math.pi / 180;
  }
}

extension _MapSpotRouteListDistance on List<MapSpot> {
  double get totalRouteDistanceKm {
    if (length < 2) {
      return 0;
    }
    var distance = 0.0;
    for (var index = 1; index < length; index++) {
      distance += this[index - 1].distanceKmTo(this[index]);
    }
    return distance;
  }
}
