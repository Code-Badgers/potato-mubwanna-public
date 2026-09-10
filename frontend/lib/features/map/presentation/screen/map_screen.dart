import 'dart:async';
import 'dart:math' as math;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/config/app_environment.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_design_tokens.dart';
import '../../../../core/logging/app_logger.dart';
import '../../../../shared/widgets/loading/potato_loading_view.dart';
import '../../../feature_tour/presentation/feature_tour_targets.dart';
import '../../../feature_tour/presentation/feature_tour_host.dart';
import '../../application/kakao_map_navigation.dart';
import '../../application/map_spot_controller.dart';
import '../../data/travel_course_catalog.dart';
import '../../domain/favorite_spot_route.dart';
import '../../domain/map_spot.dart';
import '../../domain/spot_detail.dart';
import '../../domain/spot_recommendation.dart';
import '../widget/kakao_map_view.dart';
import '../widget/map_spot_selection_message.dart';

typedef MapViewBuilder = Widget Function(
  List<MapSpot> spots,
  ValueChanged<String> onSpotSelected,
);

const _mapPrimary = AppColors.primary;
const _mapDark = AppColors.primaryDark;
const _rareGold = AppColors.secondary;

class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({
    this.hasMapConfiguration,
    this.mapViewBuilder,
    this.mapUriLauncher = launchExternalMapUri,
    this.recommendationSourceSpotId,
    this.showFullMapInitially = false,
    super.key,
  });

  final bool? hasMapConfiguration;
  final MapViewBuilder? mapViewBuilder;
  final MapUriLauncher mapUriLauncher;
  final String? recommendationSourceSpotId;
  final bool showFullMapInitially;

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen> {
  int _selectedCategoryIndex = 0;
  String? _selectedSpotId;
  bool _isRouteMode = false;
  bool _showFullMap = false;
  List<String> _routeSpotOrder = const [];
  FavoriteSpotRoutePoint? _currentLocation;
  int _currentLocationFocusTick = 0;
  final _spotSheetController = DraggableScrollableController();
  final _routeSheetController = DraggableScrollableController();

  static const _categories = [
    _MapCategoryFilter(label: '전체', icon: Icons.grid_view_rounded),
    _MapCategoryFilter(label: '식당', icon: Icons.restaurant_rounded),
    _MapCategoryFilter(label: '카페·디저트', icon: Icons.local_cafe_rounded),
    _MapCategoryFilter(label: '관광·쇼핑', icon: Icons.landscape_rounded),
    _MapCategoryFilter(label: '체험', icon: Icons.directions_walk_rounded),
    _MapCategoryFilter(label: '시장·상권', icon: Icons.storefront_rounded),
  ];

  List<MapSpot> _visibleSpots(
      List<MapSpot> spots, Set<String> favoriteSpotIds) {
    final selectedCategory = _categories[_selectedCategoryIndex].label;
    return spots.where((spot) {
      final matchesCategory = selectedCategory == '전체' ||
          spot.matchesCategoryLabel(selectedCategory);
      return matchesCategory;
    }).toList();
  }

  MapSpot? _selectedSpot(List<MapSpot> spots, {String? preferredSpotId}) {
    if (spots.isEmpty) {
      return null;
    }
    final selectedSpotId = _selectedSpotId ?? preferredSpotId;
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

  List<MapSpot> _mergeRecommendations(
    List<MapSpot> spots,
    List<SpotRecommendation> recommendations,
  ) {
    if (recommendations.isEmpty) {
      return spots;
    }

    final spotsById = {for (final spot in spots) spot.id: spot};
    for (final recommendation in recommendations) {
      final existing = spotsById[recommendation.spotId];
      spotsById[recommendation.spotId] =
          existing?.asRecommended() ?? recommendation.toMapSpot();
    }
    return spotsById.values.toList();
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

  List<MapSpot> _orderedFavoriteSpots(
    List<MapSpot> spots,
    Set<String> favoriteSpotIds,
    FavoriteSpotRoute? backendRoute,
    MapSpot? selectedSpot,
  ) {
    final favoriteSpotsById = {
      for (final spot in spots)
        if (favoriteSpotIds.contains(spot.id)) spot.id: spot,
    };
    if (favoriteSpotsById.isEmpty) {
      return const [];
    }

    final backendOrder = backendRoute == null
        ? const <String>[]
        : _routeSpotsFromBackend(spots, backendRoute)
            .map((spot) => spot.id)
            .where(favoriteSpotsById.containsKey)
            .toList();
    final suggestedOrder = _recommendedRouteSpots(
      spots,
      favoriteSpotIds,
      selectedSpot,
    ).map((spot) => spot.id);
    final sourceOrder = _routeSpotOrder.isNotEmpty
        ? _routeSpotOrder
        : backendOrder.isNotEmpty
            ? backendOrder
            : suggestedOrder;

    final orderedIds = <String>[];
    for (final spotId in sourceOrder) {
      if (favoriteSpotsById.containsKey(spotId) &&
          !orderedIds.contains(spotId)) {
        orderedIds.add(spotId);
      }
    }
    for (final spot in spots) {
      if (favoriteSpotsById.containsKey(spot.id) &&
          !orderedIds.contains(spot.id)) {
        orderedIds.add(spot.id);
      }
    }

    return orderedIds.map((spotId) => favoriteSpotsById[spotId]!).toList();
  }

  void _selectCategory(int index) {
    setState(() {
      _selectedCategoryIndex = index;
      _isRouteMode = false;
      _selectedSpotId = null;
    });
  }

  @override
  void initState() {
    super.initState();
    _showFullMap = widget.showFullMapInitially ||
        widget.recommendationSourceSpotId != null;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_loadCurrentLocation());
    });
  }

  @override
  void dispose() {
    _spotSheetController.dispose();
    _routeSheetController.dispose();
    super.dispose();
  }

  Future<void> _loadCurrentLocation({bool focusMap = false}) async {
    if (kIsWeb) {
      return;
    }
    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return;
      }
      final position = await Geolocator.getCurrentPosition();
      if (!mounted) {
        return;
      }
      setState(() {
        _currentLocation = FavoriteSpotRoutePoint(
          latitude: position.latitude,
          longitude: position.longitude,
        );
        if (focusMap) {
          _currentLocationFocusTick += 1;
        }
      });
    } catch (_) {
      // 현재 위치는 지도 보조 정보라 실패해도 감자 스팟 탐색 흐름은 유지한다.
    }
  }

  void _selectSpotById(String spotId) {
    final normalizedSpotId = mapSpotIdFromSelectionMessage(spotId);
    if (normalizedSpotId == null) {
      return;
    }
    setState(() {
      _selectedSpotId = normalizedSpotId;
    });
    FeatureTourScope.maybeOf(context)?.completeTarget(
      FeatureTourTargets.mapMarker,
    );
  }

  void _enterRouteMode(List<MapSpot> routeSpots) {
    setState(() {
      _isRouteMode = true;
      _selectedSpotId = null;
      _routeSpotOrder = routeSpots.map((spot) => spot.id).toList();
    });
    FeatureTourScope.maybeOf(context)?.completeTarget(
      FeatureTourTargets.routeMode,
    );
  }

  void _exitRouteMode() {
    setState(() {
      _isRouteMode = false;
    });
  }

  void _openFullMap() {
    setState(() {
      _showFullMap = true;
    });
    FeatureTourScope.maybeOf(context)?.completeTarget(
      FeatureTourTargets.mapFullView,
    );
  }

  void _returnToDiscoveryHome() {
    setState(() {
      _showFullMap = false;
      _isRouteMode = false;
    });
    FeatureTourScope.maybeOf(context)?.completeNavigation(
      targetKey: FeatureTourTargets.mapGoodNowCard,
    );
  }

  void _reorderRouteSpot(
    int oldIndex,
    int newIndex,
    List<MapSpot> routeSpots,
  ) {
    final previousOrder = _routeSpotOrder;
    final nextOrder = routeSpots.map((spot) => spot.id).toList();
    final movedSpotId = nextOrder.removeAt(oldIndex);
    nextOrder.insert(newIndex, movedSpotId);
    setState(() {
      _routeSpotOrder = nextOrder;
    });
    unawaited(_persistRouteSpotOrder(nextOrder, previousOrder));
  }

  Future<void> _persistRouteSpotOrder(
    List<String> nextOrder,
    List<String> previousOrder,
  ) async {
    try {
      await ref
          .read(favoriteSpotControllerProvider.notifier)
          .reorder(nextOrder);
      ref.invalidate(favoriteSpotRouteProvider);
    } on FavoriteSpotToggleException catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _routeSpotOrder = previousOrder;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message)),
      );
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _routeSpotOrder = previousOrder;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('내 동선 순서를 저장하지 못했습니다.'),
        ),
      );
    }
  }

  Future<void> _toggleFavoriteSpot(
    String spotId, {
    required bool wasFavorite,
  }) async {
    try {
      await ref.read(favoriteSpotControllerProvider.notifier).toggle(spotId);
      ref.invalidate(favoriteSpotRouteProvider);
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            wasFavorite ? '내 동선에서 삭제했어요' : '내 동선에 추가했어요',
          ),
        ),
      );
    } on FavoriteSpotToggleException catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message)),
      );
    } catch (_) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('내 동선을 저장하지 못했습니다.'),
        ),
      );
    }
  }

  Future<void> _openSpotNavigation(MapSpot spot) async {
    try {
      await _launchMapUri(KakaoMapNavigation.destinationUri(spot));
    } catch (_) {
      _showNavigationError();
    }
  }

  Future<void> _launchMapUri(Uri uri) async {
    final didLaunch = await widget.mapUriLauncher(uri);
    if (!didLaunch) {
      _showNavigationError();
    }
  }

  void _showNavigationError() {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('카카오맵 길찾기를 열지 못했습니다. 잠시 후 다시 시도해주세요.'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final spotsState = ref.watch(mapSpotsProvider);
    final favoriteSpotsState = ref.watch(favoriteSpotControllerProvider);
    final favoriteSpotRouteState = ref.watch(favoriteSpotRouteProvider);
    final favoriteSpotIds = favoriteSpotsState.valueOrNull ?? <String>{};
    final recommendationSourceSpotId = widget.recommendationSourceSpotId;
    final AsyncValue<List<SpotRecommendation>> recommendationState =
        recommendationSourceSpotId == null
            ? const AsyncValue.data(<SpotRecommendation>[])
            : ref
                .watch(spotRecommendationsProvider(recommendationSourceSpotId));

    if (!_showFullMap) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: _MapDiscoveryHome(
            spotsState: spotsState,
            onRetry: () => ref.invalidate(mapSpotsProvider),
            onOpenFullMap: _openFullMap,
            onSpotPressed: (spot) {
              FeatureTourScope.maybeOf(context)?.beginNavigation(
                FeatureTourTargets.mapGoodNowCard,
              );
              setState(() {
                _showFullMap = true;
                _selectedSpotId = spot.id;
              });
            },
            onSpotDetailPressed: (spot) => context.push('/spots/${spot.id}'),
            onAddCourseToRoute: (spots) => _addCourseToRoute(
              spots,
              favoriteSpotIds,
            ),
          ),
        ),
      );
    }

    return Builder(
      builder: (context) {
        final scaffold = Scaffold(
          backgroundColor: AppColors.background,
          body: SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                    child: spotsState.when(
                      data: (spots) {
                        final hasMapConfiguration = widget
                                .hasMapConfiguration ??
                            (kIsWeb
                                ? AppEnvironment.kakaoJavaScriptKey.isNotEmpty
                                : AppEnvironment.kakaoNativeAppKey.isNotEmpty);
                        if (!hasMapConfiguration) {
                          return const _MapConfigurationError();
                        }

                        final recommendations =
                            recommendationState.valueOrNull ??
                                const <SpotRecommendation>[];
                        final displaySpots = _mergeRecommendations(
                          spots,
                          recommendations,
                        );
                        final visibleSpots = _visibleSpots(
                          displaySpots,
                          favoriteSpotIds,
                        );
                        final selectedSpot = _selectedSpot(
                          visibleSpots,
                          preferredSpotId: recommendations.isEmpty
                              ? null
                              : recommendations.first.spotId,
                        );
                        final backendRoute = favoriteSpotRouteState.valueOrNull;
                        final orderedFavoriteSpots = _orderedFavoriteSpots(
                          displaySpots,
                          favoriteSpotIds,
                          backendRoute,
                          selectedSpot,
                        );
                        final activeMapSpots =
                            _isRouteMode ? orderedFavoriteSpots : visibleSpots;
                        final activeRoutePolyline = _isRouteMode
                            ? orderedFavoriteSpots
                                .map(
                                  (spot) => FavoriteSpotRoutePoint(
                                    latitude: spot.latitude,
                                    longitude: spot.longitude,
                                  ),
                                )
                                .toList()
                            : const <FavoriteSpotRoutePoint>[];
                        final activeSheetController = _isRouteMode
                            ? _routeSheetController
                            : _spotSheetController;
                        final initialSheetSize = _isRouteMode
                            ? (orderedFavoriteSpots.isEmpty ? 0.34 : 0.46)
                            : selectedSpot == null
                                ? 0.24
                                : (selectedSpot.effectiveImageUrls.isNotEmpty ||
                                        selectedSpot.menuItems.isNotEmpty ||
                                        selectedSpot.hasBusinessInfo)
                                    ? 0.40
                                    : 0.28;
                        return Stack(
                          children: [
                            Positioned.fill(
                              child: _PotatoMapPreview(
                                spots: activeMapSpots,
                                routePolyline: activeRoutePolyline,
                                routeSpotIds: _isRouteMode
                                    ? orderedFavoriteSpots
                                        .map((spot) => spot.id)
                                        .toList(growable: false)
                                    : const [],
                                favoriteSpotIds: favoriteSpotIds,
                                currentLocation: _currentLocation,
                                currentLocationFocusTick:
                                    _currentLocationFocusTick,
                                onSpotSelected: _selectSpotById,
                                mapViewBuilder: widget.mapViewBuilder,
                              ),
                            ),
                            if (!_isRouteMode && activeMapSpots.isNotEmpty)
                              Positioned.fill(
                                child: IgnorePointer(
                                  child: FractionallySizedBox(
                                    alignment: Alignment.topCenter,
                                    widthFactor: 1,
                                    heightFactor: 1 - initialSheetSize,
                                    child: SizedBox(
                                      key: FeatureTourTargets.mapMarker,
                                    ),
                                  ),
                                ),
                              ),
                            Positioned(
                              left: 12,
                              right: 12,
                              top: 18,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _CategoryFilterBar(
                                    categories: _categories,
                                    selectedIndex: _selectedCategoryIndex,
                                    onSelected: _selectCategory,
                                  ),
                                  const SizedBox(height: 10),
                                  _RouteModeChip(
                                    favoriteCount: favoriteSpotIds.length,
                                    selected: _isRouteMode,
                                    onTap: _isRouteMode
                                        ? _exitRouteMode
                                        : () => _enterRouteMode(
                                              orderedFavoriteSpots,
                                            ),
                                  ),
                                  if (recommendationSourceSpotId != null) ...[
                                    const SizedBox(height: 10),
                                    _RecommendationStatusChip(
                                      state: recommendationState,
                                      onRetry: () => ref.invalidate(
                                        spotRecommendationsProvider(
                                          recommendationSourceSpotId,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            if (_isRouteMode)
                              _FavoriteRouteSheet(
                                sheetController: _routeSheetController,
                                routeSpots: orderedFavoriteSpots,
                                currentLocation: _currentLocation,
                                onBrowsePressed: _exitRouteMode,
                                onReorder: (oldIndex, newIndex) =>
                                    _reorderRouteSpot(
                                  oldIndex,
                                  newIndex,
                                  orderedFavoriteSpots,
                                ),
                                onFavoritePressed: (spot) =>
                                    _toggleFavoriteSpot(
                                  spot.id,
                                  wasFavorite: true,
                                ),
                              )
                            else if (selectedSpot == null)
                              const Positioned.fill(
                                child: _EmptySpotMessage(),
                              )
                            else
                              _RouteRecommendationSheet(
                                key: const ValueKey('route-sheet'),
                                sheetController: _spotSheetController,
                                selectedSpot: selectedSpot,
                                isFavorite:
                                    favoriteSpotIds.contains(selectedSpot.id),
                                onNavigationPressed: () =>
                                    _openSpotNavigation(selectedSpot),
                                onFavoritePressed: () async {
                                  await _toggleFavoriteSpot(
                                    selectedSpot.id,
                                    wasFavorite: favoriteSpotIds
                                        .contains(selectedSpot.id),
                                  );
                                },
                              ),
                            Positioned.fill(
                              child: _SheetAnchoredMapControls(
                                controller: activeSheetController,
                                initialSheetSize: initialSheetSize,
                                onHomePressed: _returnToDiscoveryHome,
                                onLocatePressed: () => unawaited(
                                  _loadCurrentLocation(focusMap: true),
                                ),
                              ),
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
        if (Router.maybeOf(context) == null) {
          return PopScope(
            canPop: false,
            onPopInvokedWithResult: (didPop, _) {
              if (!didPop) {
                _returnToDiscoveryHome();
              }
            },
            child: scaffold,
          );
        }
        return BackButtonListener(
          onBackButtonPressed: () async {
            // 다른 탭 또는 안쪽/루트 Navigator의 팝업이 먼저 뒤로가기를 처리한다.
            if (ModalRoute.of(context)?.isCurrent != true ||
                ModalRoute.of(Navigator.of(context).context)?.isCurrent == false) {
              return false;
            }
            _returnToDiscoveryHome();
            return true;
          },
          child: scaffold,
        );
      },
    );
  }

  Future<void> _addCourseToRoute(
    List<MapSpot> courseSpots,
    Set<String> favoriteSpotIds,
  ) async {
    final newSpots = courseSpots
        .where((spot) => !favoriteSpotIds.contains(spot.id))
        .toList();
    if (newSpots.isEmpty) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('이미 내 동선에 담긴 코스예요')),
      );
      return;
    }

    try {
      for (final spot in newSpots) {
        await ref.read(favoriteSpotControllerProvider.notifier).toggle(spot.id);
      }
      ref.invalidate(favoriteSpotRouteProvider);
      if (!mounted) {
        return;
      }
      final shouldOpenRoute = await showDialog<bool>(
        context: context,
        barrierColor: Colors.black.withValues(alpha: 0.62),
        builder: (context) => _CourseAddedRouteDialog(
          addedCount: newSpots.length,
          totalCount: courseSpots.length,
        ),
      );
      if (shouldOpenRoute == true && mounted) {
        setState(() {
          _showFullMap = true;
          _isRouteMode = true;
          _selectedSpotId = courseSpots.first.id;
          _routeSpotOrder = courseSpots.map((spot) => spot.id).toList();
        });
      }
    } on FavoriteSpotToggleException catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message)),
      );
    } catch (_) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('코스를 내 동선에 담지 못했습니다.')),
      );
    }
  }
}

class _MapDiscoveryHome extends StatelessWidget {
  const _MapDiscoveryHome({
    required this.spotsState,
    required this.onRetry,
    required this.onOpenFullMap,
    required this.onSpotPressed,
    required this.onSpotDetailPressed,
    required this.onAddCourseToRoute,
  });

  final AsyncValue<List<MapSpot>> spotsState;
  final VoidCallback onRetry;
  final VoidCallback onOpenFullMap;
  final ValueChanged<MapSpot> onSpotPressed;
  final ValueChanged<MapSpot> onSpotDetailPressed;
  final Future<void> Function(List<MapSpot> spots) onAddCourseToRoute;

  @override
  Widget build(BuildContext context) {
    return spotsState.when(
      data: _buildContent,
      loading: () => _buildContent(const [], isLoading: true),
      error: (_, __) => _buildContent(const [], hasError: true),
    );
  }

  Widget _buildContent(
    List<MapSpot> spots, {
    bool isLoading = false,
    bool hasError = false,
  }) {
    final previewSpots = _previewSpots(spots);
    final courses = buildTravelCourses(spots);

    return CustomScrollView(
      key: const ValueKey('map-discovery-home'),
      physics: const BouncingScrollPhysics(),
      slivers: [
            const SliverPadding(
              padding: EdgeInsets.fromLTRB(20, 18, 20, 14),
              sliver: SliverToBoxAdapter(
                child: _DiscoveryHeroHeader(),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              sliver: SliverToBoxAdapter(
                child: KeyedSubtree(
                  key: FeatureTourTargets.mapDiscovery,
                  child: _DiscoveryMapPreviewCard(
                    spots: previewSpots,
                    onOpenFullMap: onOpenFullMap,
                  ),
                ),
              ),
            ),
            if (isLoading || hasError)
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                sliver: SliverToBoxAdapter(
                  child: _DiscoverySpotsStatus(
                    isLoading: isLoading,
                    onRetry: onRetry,
                  ),
                ),
              ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 26, 0, 0),
              sliver: SliverToBoxAdapter(
                child: _TravelCourseSection(
                  courses: courses,
                  onAddCourseToRoute: onAddCourseToRoute,
                  onSpotDetailPressed: onSpotDetailPressed,
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 26, 20, 28),
              sliver: SliverToBoxAdapter(
                child: _GoodNowSpotSection(
                  spots: spots,
                  onSpotPressed: onSpotPressed,
                ),
              ),
            ),
      ],
    );
  }

  List<MapSpot> _previewSpots(List<MapSpot> spots) {
    final selected = <MapSpot>[];
    for (final category in [
      'POTATO_CAFE',
      'POTATO_RESTAURANT',
      'POTATO_TOUR',
      'POTATO_EXPERIENCE',
    ]) {
      final spot = spots.where((spot) => spot.category == category).firstOrNull;
      if (spot != null && !selected.any((item) => item.id == spot.id)) {
        selected.add(spot);
      }
    }
    if (selected.length < 4) {
      for (final spot in spots) {
        if (selected.length >= 4) {
          break;
        }
        if (!selected.any((item) => item.id == spot.id)) {
          selected.add(spot);
        }
      }
    }
    return selected;
  }
}

class _DiscoverySpotsStatus extends StatelessWidget {
  const _DiscoverySpotsStatus({
    required this.isLoading,
    required this.onRetry,
  });

  final bool isLoading;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: ValueKey(isLoading ? 'map-spots-progress' : 'map-spots-error'),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.primaryTint,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          if (isLoading)
            const SizedBox.square(
              dimension: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2.4,
                color: _mapPrimary,
              ),
            )
          else
            const Icon(Icons.cloud_off_rounded, color: _mapPrimary, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              isLoading
                  ? '장소 정보는 불러오는 대로 채워드릴게요'
                  : '장소 정보를 불러오지 못했어요',
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w800,
                letterSpacing: 0,
              ),
            ),
          ),
          if (!isLoading)
            TextButton(
              key: const ValueKey('map-spots-retry'),
              onPressed: onRetry,
              child: const Text('다시 시도'),
            ),
        ],
      ),
    );
  }
}

class _DiscoveryHeroHeader extends StatelessWidget {
  const _DiscoveryHeroHeader();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '오늘은 어디로 떠나볼까요?',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.w800,
            letterSpacing: 0,
          ),
        ),
        SizedBox(height: 8),
        Text(
          '강원도 여행 코스 짜기',
          style: TextStyle(
            color: _mapPrimary,
            fontSize: 31,
            fontWeight: FontWeight.w900,
            height: 1.08,
            letterSpacing: 0,
          ),
        ),
        SizedBox(height: 10),
        Text(
          '추천 장소를 발견하고 내 동선에 담아보세요',
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 14,
            fontWeight: FontWeight.w700,
            letterSpacing: 0,
          ),
        ),
      ],
    );
  }
}

class _DiscoveryMapPreviewCard extends StatelessWidget {
  const _DiscoveryMapPreviewCard({
    required this.spots,
    required this.onOpenFullMap,
  });

  final List<MapSpot> spots;
  final VoidCallback onOpenFullMap;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey('map-discovery-preview-card'),
      height: 286,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: AppShadows.softCard,
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Positioned.fill(
            child: AbsorbPointer(
              child: KakaoMapView(
                spots: spots,
              ),
            ),
          ),
          Positioned(
            left: 18,
            bottom: 18,
            child: KeyedSubtree(
              key: FeatureTourTargets.mapFullView,
              child: FilledButton.icon(
                key: const ValueKey('open-full-map-button'),
                onPressed: onOpenFullMap,
                icon: const Icon(Icons.open_in_full_rounded, size: 18),
                label: const Text('지도 크게 보기'),
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: _mapPrimary,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 13,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(17),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SheetAnchoredMapControls extends StatefulWidget {
  const _SheetAnchoredMapControls({
    required this.controller,
    required this.initialSheetSize,
    required this.onHomePressed,
    required this.onLocatePressed,
  });

  final DraggableScrollableController controller;
  final double initialSheetSize;
  final VoidCallback onHomePressed;
  final VoidCallback onLocatePressed;

  @override
  State<_SheetAnchoredMapControls> createState() =>
      _SheetAnchoredMapControlsState();
}

class _SheetAnchoredMapControlsState extends State<_SheetAnchoredMapControls> {
  late double _sheetSize = widget.initialSheetSize;
  bool _refreshScheduled = false;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_handleControllerChanged);
  }

  @override
  void didUpdateWidget(covariant _SheetAnchoredMapControls oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_handleControllerChanged);
      widget.controller.addListener(_handleControllerChanged);
    }
    _scheduleRefresh();
  }

  @override
  void dispose() {
    widget.controller.removeListener(_handleControllerChanged);
    super.dispose();
  }

  void _handleControllerChanged() {
    _scheduleRefresh();
  }

  void _scheduleRefresh() {
    if (_refreshScheduled) {
      return;
    }
    _refreshScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshScheduled = false;
      if (!mounted) {
        return;
      }
      final nextSize = widget.controller.isAttached
          ? widget.controller.size
          : widget.initialSheetSize;
      if (nextSize != _sheetSize) {
        setState(() {
          _sheetSize = nextSize;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final buttonBottom = constraints.maxHeight * _sheetSize + 12;
        return Stack(
          children: [
            Positioned(
              left: 14,
              bottom: buttonBottom,
              child: _FullMapHomeButton(onTap: widget.onHomePressed),
            ),
            Positioned(
              right: 18,
              bottom: buttonBottom,
              child: _FullMapLocateButton(onTap: widget.onLocatePressed),
            ),
          ],
        );
      },
    );
  }
}

class _FullMapHomeButton extends StatelessWidget {
  const _FullMapHomeButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      key: const ValueKey('full-map-home-button'),
      color: Colors.white.withValues(alpha: 0.96),
      shape: const CircleBorder(),
      elevation: 4,
      shadowColor: Colors.black.withValues(alpha: 0.12),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: const SizedBox.square(
          dimension: 52,
          child: Icon(
            Icons.keyboard_arrow_left_rounded,
            color: _mapDark,
            size: 30,
          ),
        ),
      ),
    );
  }
}

class _FullMapLocateButton extends StatelessWidget {
  const _FullMapLocateButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      key: const ValueKey('full-map-locate-button'),
      color: Colors.white.withValues(alpha: 0.96),
      shape: const CircleBorder(),
      elevation: 5,
      shadowColor: Colors.black.withValues(alpha: 0.13),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: const SizedBox.square(
          dimension: 52,
          child: Icon(
            Icons.my_location_rounded,
            color: _mapDark,
            size: 26,
          ),
        ),
      ),
    );
  }
}

class _TravelCourseSection extends StatelessWidget {
  const _TravelCourseSection({
    required this.courses,
    required this.onAddCourseToRoute,
    required this.onSpotDetailPressed,
  });

  final List<TravelCourse> courses;
  final Future<void> Function(List<MapSpot> spots) onAddCourseToRoute;
  final ValueChanged<MapSpot> onSpotDetailPressed;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _DiscoverySectionHeader(title: '오늘 어떤 여행이 끌리나요?'),
        const SizedBox(height: 12),
        SizedBox(
          height: 304,
          child: courses.isEmpty
              ? const Padding(
                  padding: EdgeInsets.only(right: 20),
                  child: _DiscoverySectionStatus(
                    icon: Icons.route_rounded,
                    title: '추천 코스를 준비하지 못했어요',
                    description: '장소 데이터가 모이면 코스를 보여드릴게요.',
                  ),
                )
              : ListView.separated(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.only(right: 20),
                  itemBuilder: (context, index) {
                    final course = courses[index];
                    final card = _TravelCourseCard(
                      course: course,
                      onPressed: () async {
                        final tour = FeatureTourScope.maybeOf(context);
                        tour?.beginNavigation(
                          FeatureTourTargets.mapCourseCard,
                        );
                        await _showTravelCourseDetail(
                          context,
                          course,
                          onAddCourseToRoute,
                          onSpotDetailPressed,
                        );
                        if (context.mounted) {
                          tour?.completeNavigation(
                            targetKey: FeatureTourTargets.mapCourseCard,
                          );
                        }
                      },
                    );
                    return index == 0
                        ? KeyedSubtree(
                            key: FeatureTourTargets.mapCourseCard,
                            child: card,
                          )
                        : card;
                  },
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemCount: courses.length,
                ),
        ),
      ],
    );
  }

  Future<void> _showTravelCourseDetail(
    BuildContext context,
    TravelCourse course,
    Future<void> Function(List<MapSpot> spots) onAddCourseToRoute,
    ValueChanged<MapSpot> onSpotDetailPressed,
  ) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (pageContext) {
          return _TravelCourseDetailPage(
            course: course,
            onSpotDetailPressed: (spot) {
              Navigator.of(pageContext).pop();
              onSpotDetailPressed(spot);
            },
            onAddPressed: course.spots.isEmpty
                ? null
                : () async {
                    Navigator.of(pageContext).pop();
                    await onAddCourseToRoute(course.spots);
                  },
          );
        },
      ),
    );
  }
}

class _TravelCourseCard extends StatelessWidget {
  const _TravelCourseCard({
    required this.course,
    required this.onPressed,
  });

  final TravelCourse course;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          width: 266,
          height: 292,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(24),
            boxShadow: AppShadows.softCard,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  ClipRRect(
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(24)),
                    child: SizedBox(
                      height: 142,
                      width: double.infinity,
                      child: _CourseImage(
                        imageUrl: course.heroImageUrl,
                        icon: _courseFallbackIcon(course.id),
                      ),
                    ),
                  ),
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(24),
                        ),
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withValues(alpha: 0.02),
                            Colors.black.withValues(alpha: 0.36),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    left: 14,
                    bottom: 14,
                    right: 14,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _CourseOverlayTag(label: course.categoryTitle),
                        const SizedBox(height: 8),
                        Text(
                          course.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 21,
                            fontWeight: FontWeight.w900,
                            height: 1.12,
                            letterSpacing: 0,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 11, 14, 11),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        course.description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          height: 1.36,
                          letterSpacing: 0,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          for (final tag in course.tags.take(3))
                            _CourseTag(label: tag),
                        ],
                      ),
                      const Spacer(),
                      Row(
                        children: [
                          Icon(
                            Icons.route_rounded,
                            color: _mapDark.withValues(alpha: 0.86),
                            size: 16,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            '${course.stops.length}곳 · ${course.estimatedDuration}',
                            style: const TextStyle(
                              color: _mapDark,
                              fontSize: 12,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0,
                            ),
                          ),
                          const Spacer(),
                          const Icon(
                            Icons.chevron_right_rounded,
                            color: _mapDark,
                            size: 24,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CourseImage extends StatelessWidget {
  const _CourseImage({
    this.imageUrl,
    required this.icon,
  });

  final String? imageUrl;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final effectiveImageUrl = imageUrl?.trim();
    if (effectiveImageUrl != null && effectiveImageUrl.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: effectiveImageUrl,
        fit: BoxFit.cover,
        placeholder: (_, __) => _CourseImageFallback(icon: icon),
        errorWidget: (_, error, ___) {
          _logImageLoadFailure(effectiveImageUrl, error);
          return _CourseImageFallback(icon: icon);
        },
      );
    }
    return _CourseImageFallback(icon: icon);
  }
}

void _logImageLoadFailure(String imageUrl, Object error) {
  final uri = Uri.tryParse(imageUrl);
  final host = uri?.host;
  AppLogger.debug(
    'image load failed: host=${host == null || host.isEmpty ? 'invalid' : host}, '
    'error=${error.runtimeType}',
    name: 'map',
  );
}

class _CourseImageFallback extends StatelessWidget {
  const _CourseImageFallback({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.primaryTint,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Icon(
        icon,
        size: 44,
        color: _mapDark.withValues(alpha: 0.32),
      ),
    );
  }
}

class _CourseOverlayTag extends StatelessWidget {
  const _CourseOverlayTag({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: _mapDark,
            fontSize: 11,
            fontWeight: FontWeight.w900,
            letterSpacing: 0,
          ),
        ),
      ),
    );
  }
}

IconData _courseFallbackIcon(String courseId) {
  return switch (courseId) {
    'potato_food' => Icons.restaurant_rounded,
    'people_energy' => Icons.groups_rounded,
    'gangwon_hotplace' => Icons.local_fire_department_rounded,
    'introvert' => Icons.eco_rounded,
    'east_sea' => Icons.waves_rounded,
    'photo_mood' => Icons.photo_camera_rounded,
    _ => Icons.route_rounded,
  };
}

class _TravelCourseDetailPage extends StatelessWidget {
  const _TravelCourseDetailPage({
    required this.course,
    required this.onSpotDetailPressed,
    required this.onAddPressed,
  });

  final TravelCourse course;
  final ValueChanged<MapSpot> onSpotDetailPressed;
  final Future<void> Function()? onAddPressed;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: 330,
            backgroundColor: AppColors.background,
            foregroundColor: AppColors.textPrimary,
            elevation: 0,
            leading: Padding(
              padding: const EdgeInsets.only(left: 12),
              child: _CircularIconButton(
                icon: Icons.arrow_back_rounded,
                onTap: () => Navigator.of(context).pop(),
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              collapseMode: CollapseMode.pin,
              background: Stack(
                fit: StackFit.expand,
                children: [
                  _CourseImage(
                    imageUrl: course.heroImageUrl,
                    icon: _courseFallbackIcon(course.id),
                  ),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.08),
                          Colors.black.withValues(alpha: 0.60),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    left: 22,
                    right: 22,
                    bottom: 28,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _CourseOverlayTag(label: course.categoryTitle),
                        const SizedBox(height: 12),
                        Text(
                          course.title,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 32,
                            fontWeight: FontWeight.w900,
                            height: 1.08,
                            letterSpacing: 0,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          course.description,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.92),
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            height: 1.35,
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
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 28),
            sliver: SliverList.list(
              children: [
                Text(
                  course.editorialIntro,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 21,
                    fontWeight: FontWeight.w900,
                    height: 1.32,
                    letterSpacing: 0,
                  ),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 7,
                  runSpacing: 7,
                  children: [
                    _CourseTag(label: course.estimatedDuration),
                    _CourseTag(label: '${course.stops.length}곳'),
                    _CourseTag(label: course.focusLabel),
                    for (final tag in course.tags) _CourseTag(label: tag),
                  ],
                ),
                const SizedBox(height: 32),
                if (course.spots.isEmpty)
                  const _DiscoverySectionStatus(
                    icon: Icons.route_rounded,
                    title: '아직 연결된 장소가 없어요',
                    description: '장소 데이터가 준비되면 코스에 담아둘게요.',
                  )
                else
                  for (var index = 0; index < course.stops.length; index++) ...[
                    _CourseStopCard(
                      index: index + 1,
                      stop: course.stops[index],
                      onDetailPressed: () =>
                          onSpotDetailPressed(course.stops[index].spot),
                    ),
                    if (course.stops[index].transitionText.isNotEmpty)
                      _CourseTransitionText(
                        text: course.stops[index].transitionText,
                      ),
                  ],
                const SizedBox(height: 10),
                const Text(
                  '이 코스에 담긴 장소',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0,
                  ),
                ),
                const SizedBox(height: 12),
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: AppShadows.softCard,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: Column(
                      children: [
                        for (var index = 0;
                            index < course.stops.length;
                            index++) ...[
                          _CourseSpotRow(
                            index: index + 1,
                            spot: course.stops[index].spot,
                            onPressed: () =>
                                onSpotDetailPressed(course.stops[index].spot),
                          ),
                          if (index < course.stops.length - 1)
                            const SizedBox(height: 4),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: onAddPressed == null
                        ? null
                        : () => unawaited(onAddPressed!()),
                    icon: const Icon(Icons.bookmark_add_rounded),
                    label: Text('내 동선에 ${course.stops.length}곳 담기'),
                    style: FilledButton.styleFrom(
                      backgroundColor: _mapPrimary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                      textStyle: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: MediaQuery.paddingOf(context).bottom + 8),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CircularIconButton extends StatelessWidget {
  const _CircularIconButton({
    required this.icon,
    required this.onTap,
  });

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.94),
      shape: const CircleBorder(),
      elevation: 3,
      shadowColor: Colors.black.withValues(alpha: 0.12),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: SizedBox.square(
          dimension: 42,
          child: Icon(icon, color: AppColors.textPrimary, size: 23),
        ),
      ),
    );
  }
}

class _CourseTransitionText extends StatelessWidget {
  const _CourseTransitionText({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 6, 10, 28),
      child: Text(
        text,
        style: const TextStyle(
          color: AppColors.textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w900,
          height: 1.34,
          letterSpacing: 0,
        ),
      ),
    );
  }
}

class _CourseSpotRow extends StatelessWidget {
  const _CourseSpotRow({
    required this.index,
    required this.spot,
    required this.onPressed,
  });

  final int index;
  final MapSpot spot;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.background,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                width: 30,
                height: 30,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '$index',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                  ),
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
                      '${spot.cityName} · ${spot.categoryLabel}',
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
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.textSecondary,
                size: 22,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CourseStopCard extends StatelessWidget {
  const _CourseStopCard({
    required this.index,
    required this.stop,
    required this.onDetailPressed,
  });

  final int index;
  final TravelCourseStop stop;
  final VoidCallback onDetailPressed;

  @override
  Widget build(BuildContext context) {
    final image = ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: AspectRatio(
        aspectRatio: 1.72,
        child: _CourseImage(
          imageUrl: stop.spot.imageUrl,
          icon: Icons.place_rounded,
        ),
      ),
    );
    final text = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 9,
                vertical: 6,
              ),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                index.toString().padLeft(2, '0'),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    stop.heading,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: _mapDark,
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    stop.spot.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      height: 1.18,
                      letterSpacing: 0,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    '${stop.spot.cityName} · ${stop.spot.categoryLabel}',
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Text(
          stop.editorial,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 13,
            fontWeight: FontWeight.w700,
            height: 1.45,
            letterSpacing: 0,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            _CourseTag(label: stop.featureLabel),
            const Spacer(),
            TextButton.icon(
              onPressed: onDetailPressed,
              icon: const Icon(Icons.arrow_forward_rounded, size: 17),
              label: const Text('장소 자세히 보기'),
              style: TextButton.styleFrom(
                foregroundColor: _mapDark,
                textStyle: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        ),
      ],
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          image,
          const SizedBox(height: 14),
          text,
        ],
      ),
    );
  }
}

class _CourseTag extends StatelessWidget {
  const _CourseTag({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.cream,
        borderRadius: BorderRadius.circular(AppDimens.pillRadius),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: AppColors.brown,
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 0,
        ),
      ),
    );
  }
}

class _CourseAddedRouteDialog extends StatelessWidget {
  const _CourseAddedRouteDialog({
    required this.addedCount,
    required this.totalCount,
  });

  final int addedCount;
  final int totalCount;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 36),
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.fromLTRB(22, 24, 22, 18),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.20),
              blurRadius: 32,
              offset: const Offset(0, 18),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: const BoxDecoration(
                color: AppColors.primaryTint,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.route_rounded,
                color: _mapDark,
                size: 34,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              '내 동선에 $addedCount곳을 담았어요',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 22,
                fontWeight: FontWeight.w900,
                height: 1.2,
                letterSpacing: 0,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              addedCount == totalCount
                  ? '지도에서 여행 순서를 확인해보세요.'
                  : '이미 담긴 곳은 건너뛰고 새 장소만 추가했어요.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
                fontWeight: FontWeight.w700,
                height: 1.4,
                letterSpacing: 0,
              ),
            ),
            const SizedBox(height: 22),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: FilledButton.styleFrom(
                  backgroundColor: _mapPrimary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(17),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                child: const Text('지도에서 확인하기'),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              style: TextButton.styleFrom(
                foregroundColor: _mapDark,
                textStyle: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
              child: const Text('닫기'),
            ),
          ],
        ),
      ),
    );
  }
}

class _GoodNowSpotSection extends StatelessWidget {
  const _GoodNowSpotSection({
    required this.spots,
    required this.onSpotPressed,
  });

  final List<MapSpot> spots;
  final ValueChanged<MapSpot> onSpotPressed;

  @override
  Widget build(BuildContext context) {
    final calmSpots = _spotsByCongestion('LOW');
    final hotSpots = _spotsByCongestion('HIGH');
    final firstTargetGroup = calmSpots.isNotEmpty ? 'calm' : 'hot';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _DiscoverySectionHeader(title: '지금 가기 좋은 곳'),
        const SizedBox(height: 6),
        const Text(
          '관광지 집중률 예측을 바탕으로 골라봤어요.',
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 13,
            fontWeight: FontWeight.w700,
            height: 1.35,
            letterSpacing: 0,
          ),
        ),
        const SizedBox(height: 12),
        if (spots.isEmpty)
          const _DiscoverySectionStatus(
            icon: Icons.place_outlined,
            title: '표시할 장소가 없습니다',
            description: '관광지 데이터가 준비되면 이곳에 보여드릴게요.',
          )
        else
          Column(
            children: [
              _GoodNowSpotGroup(
                title: '내향인 전용 여유로운 장소',
                description: '사람이 덜 몰리는 곳부터 천천히 둘러봐요.',
                spots: calmSpots,
                onSpotPressed: onSpotPressed,
                targetKey: firstTargetGroup == 'calm'
                    ? FeatureTourTargets.mapGoodNowCard
                    : null,
              ),
              const SizedBox(height: 14),
              _GoodNowSpotGroup(
                title: '외향인 전용 사람 좋아 핫플',
                description: '활기 있는 분위기를 즐기고 싶을 때 좋아요.',
                spots: hotSpots,
                onSpotPressed: onSpotPressed,
                targetKey: firstTargetGroup == 'hot'
                    ? FeatureTourTargets.mapGoodNowCard
                    : null,
              ),
            ],
          ),
      ],
    );
  }

  List<MapSpot> _spotsByCongestion(String level) {
    final fallbackLevel = level == 'HIGH' ? 'NORMAL' : 'LOW';
    final prioritized = [
      ...spots.where((spot) => spot.congestionLevel == level),
      ...spots.where((spot) => spot.congestionLevel == fallbackLevel),
      ...spots.where((spot) => spot.stampEnabled),
      ...spots,
    ];
    final unique = <String, MapSpot>{};
    for (final spot in prioritized) {
      unique.putIfAbsent(spot.id, () => spot);
      if (unique.length >= 2) {
        break;
      }
    }
    return unique.values.toList();
  }
}

class _GoodNowSpotGroup extends StatelessWidget {
  const _GoodNowSpotGroup({
    required this.title,
    required this.description,
    required this.spots,
    required this.onSpotPressed,
    this.targetKey,
  });

  final String title;
  final String description;
  final List<MapSpot> spots;
  final ValueChanged<MapSpot> onSpotPressed;
  final GlobalKey? targetKey;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: AppShadows.softCard,
      ),
      child: Column(
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
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        height: 1.35,
                        letterSpacing: 0,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          for (var index = 0; index < spots.length; index++) ...[
            if (index == 0 && targetKey != null)
              KeyedSubtree(
                key: targetKey,
                child: _PopularSpotCard(
                  spot: spots[index],
                  onPressed: () => onSpotPressed(spots[index]),
                ),
              )
            else
              _PopularSpotCard(
                spot: spots[index],
                onPressed: () => onSpotPressed(spots[index]),
              ),
            if (index < spots.length - 1) const SizedBox(height: 10),
          ],
        ],
      ),
    );
  }
}

class _PopularSpotCard extends StatelessWidget {
  const _PopularSpotCard({
    required this.spot,
    required this.onPressed,
  });

  final MapSpot spot;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(20),
      elevation: 0,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(20),
            boxShadow: AppShadows.softCard,
          ),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: SizedBox(
                  width: 72,
                  height: 72,
                  child: _CourseImage(
                    imageUrl: spot.effectiveImageUrls.isEmpty
                        ? null
                        : spot.effectiveImageUrls.first,
                    icon: Icons.place_rounded,
                  ),
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
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      '${spot.cityName} · ${spot.categoryLabel}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0,
                      ),
                    ),
                    if (spot.address.trim().isNotEmpty) ...[
                      const SizedBox(height: 6),
                      _PopularSpotMetaLine(
                        icon: Icons.place_outlined,
                        label: spot.address,
                      ),
                    ],
                    const SizedBox(height: 8),
                    if (spot.todayOpeningText != null) ...[
                      _PopularSpotMetaLine(
                        icon: Icons.schedule_rounded,
                        label: spot.todayOpeningText!,
                      ),
                      const SizedBox(height: 7),
                    ],
                    if (spot.menuItems.isNotEmpty) ...[
                      _PopularSpotMetaLine(
                        icon: Icons.restaurant_menu_rounded,
                        label:
                            '${spot.menuItems.first.name} · ${spot.menuItems.first.priceLabel}',
                      ),
                      const SizedBox(height: 7),
                    ],
                    _CongestionBadge(label: '혼잡도 ${spot.congestionLabel}'),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DiscoverySectionHeader extends StatelessWidget {
  const _DiscoverySectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
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

class _PopularSpotMetaLine extends StatelessWidget {
  const _PopularSpotMetaLine({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 14, color: AppColors.textSecondary),
        const SizedBox(width: 5),
        Expanded(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0,
            ),
          ),
        ),
      ],
    );
  }
}

class _DiscoverySectionStatus extends StatelessWidget {
  const _DiscoverySectionStatus({
    required this.icon,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 28),
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(22),
          boxShadow: AppShadows.softCard,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: _mapDark, size: 34),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w900,
                letterSpacing: 0,
              ),
            ),
            const SizedBox(height: 7),
            Text(
              description,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
                fontWeight: FontWeight.w700,
                height: 1.4,
                letterSpacing: 0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RouteRecommendationSheet extends ConsumerWidget {
  const _RouteRecommendationSheet({
    super.key,
    required this.sheetController,
    required this.selectedSpot,
    required this.isFavorite,
    required this.onNavigationPressed,
    required this.onFavoritePressed,
  });

  final DraggableScrollableController sheetController;
  final MapSpot selectedSpot;
  final bool isFavorite;
  final VoidCallback onNavigationPressed;
  final Future<void> Function() onFavoritePressed;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasPreviewInfo = selectedSpot.effectiveImageUrls.isNotEmpty ||
        selectedSpot.menuItems.isNotEmpty ||
        selectedSpot.hasBusinessInfo;
    final initialChildSize = hasPreviewInfo ? 0.40 : 0.28;
    final snapSizes = hasPreviewInfo ? const [0.40, 0.72] : const [0.28, 0.62];
    final spotDetail = ref.watch(spotDetailProvider(selectedSpot.id));
    return NotificationListener<DraggableScrollableNotification>(
      onNotification: (notification) {
        if (notification.extent > notification.minExtent + 0.10) {
          FeatureTourScope.maybeOf(context)?.completeSwipe(
            FeatureTourTargets.spotSheetHandle,
          );
        }
        return false;
      },
      child: DraggableScrollableSheet(
        key: const ValueKey('selected-spot-sheet'),
        controller: sheetController,
        minChildSize: 0.24,
        initialChildSize: initialChildSize,
        maxChildSize: 0.78,
        snap: true,
        snapSizes: snapSizes,
        builder: (context, scrollController) {
          return DecoratedBox(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(24)),
              border: Border.all(color: AppColors.line),
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
                  Center(
                    child: KeyedSubtree(
                      key: FeatureTourTargets.spotSheetHandle,
                      child: const _SheetDragHandle(
                        key: ValueKey('selected-spot-sheet-handle'),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  KeyedSubtree(
                    key: FeatureTourTargets.mapSelectedSpotCard,
                    child: _SelectedSpotSummary(
                      spot: selectedSpot,
                      spotDetail: spotDetail,
                      isFavorite: isFavorite,
                      onNavigationPressed: onNavigationPressed,
                      onFavoritePressed: onFavoritePressed,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _FavoriteRouteSheet extends StatelessWidget {
  const _FavoriteRouteSheet({
    required this.sheetController,
    required this.routeSpots,
    required this.currentLocation,
    required this.onBrowsePressed,
    required this.onReorder,
    required this.onFavoritePressed,
  });

  final DraggableScrollableController sheetController;
  final List<MapSpot> routeSpots;
  final FavoriteSpotRoutePoint? currentLocation;
  final VoidCallback onBrowsePressed;
  final void Function(int oldIndex, int newIndex) onReorder;
  final Future<void> Function(MapSpot spot) onFavoritePressed;

  @override
  Widget build(BuildContext context) {
    final initialChildSize = routeSpots.isEmpty ? 0.34 : 0.46;
    return DraggableScrollableSheet(
      key: const ValueKey('favorite-route-sheet'),
      controller: sheetController,
      minChildSize: 0.28,
      initialChildSize: initialChildSize,
      maxChildSize: 0.78,
      snap: true,
      snapSizes: routeSpots.isEmpty ? const [0.34, 0.58] : const [0.46, 0.78],
      builder: (context, scrollController) {
        return DecoratedBox(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.10),
                blurRadius: 24,
                offset: const Offset(0, -8),
              ),
            ],
          ),
          child: routeSpots.isEmpty
              ? _FavoriteRouteEmptyState(
                  scrollController: scrollController,
                  onBrowsePressed: onBrowsePressed,
                )
              : _FavoriteRouteList(
                  scrollController: scrollController,
                  routeSpots: routeSpots,
                  currentLocation: currentLocation,
                  onBrowsePressed: onBrowsePressed,
                  onReorder: onReorder,
                  onFavoritePressed: onFavoritePressed,
                ),
        );
      },
    );
  }
}

class _FavoriteRouteEmptyState extends StatelessWidget {
  const _FavoriteRouteEmptyState({
    required this.scrollController,
    required this.onBrowsePressed,
  });

  final ScrollController scrollController;
  final VoidCallback onBrowsePressed;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      controller: scrollController,
      padding: const EdgeInsets.fromLTRB(22, 10, 22, 24),
      child: Column(
        children: [
          const _SheetDragHandle(),
          const SizedBox(height: 28),
          Container(
            width: 58,
            height: 58,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: AppColors.primaryTint,
              shape: BoxShape.circle,
            ),
            child: const Text('🥔', style: TextStyle(fontSize: 28)),
          ),
          const SizedBox(height: 16),
          const Text(
            '아직 내 동선이 비어 있어요 🥔',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w900,
              letterSpacing: 0,
            ),
          ),
          const SizedBox(height: 9),
          const Text(
            '지도에서 가보고 싶은 장소의\n책갈피를 눌러 동선에 추가해보세요.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
              fontWeight: FontWeight.w700,
              height: 1.45,
              letterSpacing: 0,
            ),
          ),
          const SizedBox(height: 20),
          FilledButton(
            key: const ValueKey('route-browse-button'),
            onPressed: onBrowsePressed,
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
            child: const Text('장소 둘러보기'),
          ),
        ],
      ),
    );
  }
}

class _FavoriteRouteList extends StatelessWidget {
  const _FavoriteRouteList({
    required this.scrollController,
    required this.routeSpots,
    required this.currentLocation,
    required this.onBrowsePressed,
    required this.onReorder,
    required this.onFavoritePressed,
  });

  final ScrollController scrollController;
  final List<MapSpot> routeSpots;
  final FavoriteSpotRoutePoint? currentLocation;
  final VoidCallback onBrowsePressed;
  final void Function(int oldIndex, int newIndex) onReorder;
  final Future<void> Function(MapSpot spot) onFavoritePressed;

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      controller: scrollController,
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 10, 18, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Center(child: _SheetDragHandle()),
                const SizedBox(height: 14),
                Row(
                  children: [
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '내 동선',
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            '오늘 어디부터 가볼까요?',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primaryTint,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        '${routeSpots.length}곳',
                        style: const TextStyle(
                          color: _mapDark,
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    TextButton(
                      key: const ValueKey('route-browse-button'),
                      onPressed: onBrowsePressed,
                      style: TextButton.styleFrom(
                        foregroundColor: _mapDark,
                        textStyle: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      child: const Text('장소 보기'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
          sliver: SliverReorderableList(
            itemCount: routeSpots.length,
            onReorderItem: routeSpots.length > 1 ? onReorder : (_, __) {},
            itemBuilder: (context, index) {
              final spot = routeSpots[index];
              return _FavoriteRouteTile(
                key: ValueKey('route-row-${spot.id}'),
                index: index,
                spot: spot,
                distanceLabel: _distanceLabelFor(spot),
                canReorder: routeSpots.length > 1,
                onFavoritePressed: () => onFavoritePressed(spot),
              );
            },
          ),
        ),
      ],
    );
  }

  String? _distanceLabelFor(MapSpot spot) {
    final location = currentLocation;
    if (location == null || spot.latitude == 0 || spot.longitude == 0) {
      return null;
    }
    final distanceKm = _distanceKm(
      location.latitude,
      location.longitude,
      spot.latitude,
      spot.longitude,
    );
    return '약 ${distanceKm.toStringAsFixed(1)}km';
  }

  double _distanceKm(
    double fromLatitude,
    double fromLongitude,
    double toLatitude,
    double toLongitude,
  ) {
    const earthRadiusKm = 6371.0;
    final lat1 = _toRadians(fromLatitude);
    final lat2 = _toRadians(toLatitude);
    final deltaLat = _toRadians(toLatitude - fromLatitude);
    final deltaLng = _toRadians(toLongitude - fromLongitude);
    final haversine = math.sin(deltaLat / 2) * math.sin(deltaLat / 2) +
        math.cos(lat1) *
            math.cos(lat2) *
            math.sin(deltaLng / 2) *
            math.sin(deltaLng / 2);
    final centralAngle =
        2 * math.atan2(math.sqrt(haversine), math.sqrt(1 - haversine));
    return earthRadiusKm * centralAngle;
  }

  double _toRadians(double degrees) {
    return degrees * math.pi / 180;
  }
}

class _FavoriteRouteTile extends StatelessWidget {
  const _FavoriteRouteTile({
    super.key,
    required this.index,
    required this.spot,
    required this.distanceLabel,
    required this.canReorder,
    required this.onFavoritePressed,
  });

  final int index;
  final MapSpot spot;
  final String? distanceLabel;
  final bool canReorder;
  final VoidCallback onFavoritePressed;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 10, 10),
          child: Row(
            children: [
              _RouteOrderBadge(index: index, spotId: spot.id),
              const SizedBox(width: 10),
              _RouteSpotThumbnail(spot: spot),
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
                      '${spot.categoryLabel} · ${spot.cityName}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0,
                      ),
                    ),
                    if (distanceLabel != null) ...[
                      const SizedBox(height: 5),
                      Text(
                        distanceLabel!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: _mapDark,
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              IconButton(
                key: ValueKey('route-remove-${spot.id}'),
                onPressed: onFavoritePressed,
                icon: const Icon(Icons.bookmark_rounded),
                color: _mapDark,
                tooltip: '내 동선에서 제거',
              ),
              if (canReorder)
                ReorderableDragStartListener(
                  key: ValueKey('route-drag-${spot.id}'),
                  index: index,
                  child: const Padding(
                    padding: EdgeInsets.all(8),
                    child: Icon(
                      Icons.drag_handle_rounded,
                      color: AppColors.textSecondary,
                    ),
                  ),
                )
              else
                const SizedBox(width: 40),
            ],
          ),
        ),
      ),
    );
  }
}

class _RouteOrderBadge extends StatelessWidget {
  const _RouteOrderBadge({required this.index, required this.spotId});

  final int index;
  final String spotId;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: ValueKey('route-order-$spotId'),
      width: 34,
      height: 34,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        color: _mapPrimary,
        shape: BoxShape.circle,
      ),
      child: Text(
        '${index + 1}',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.w900,
          letterSpacing: 0,
        ),
      ),
    );
  }
}

class _RouteSpotThumbnail extends StatelessWidget {
  const _RouteSpotThumbnail({required this.spot});

  final MapSpot spot;

  @override
  Widget build(BuildContext context) {
    final color = Color(
      int.parse(spot.markerColorHex.replaceFirst('#', '0xFF')),
    );
    return Container(
      width: 56,
      height: 56,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.13),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Icon(
        spot.matchesCategoryLabel('카페·디저트')
            ? Icons.local_cafe_rounded
            : spot.matchesCategoryLabel('식당')
                ? Icons.restaurant_rounded
                : spot.matchesCategoryLabel('시장·상권')
                    ? Icons.storefront_rounded
                    : spot.matchesCategoryLabel('체험')
                        ? Icons.directions_walk_rounded
                        : Icons.landscape_rounded,
        color: color,
        size: 26,
      ),
    );
  }
}

class _SheetDragHandle extends StatelessWidget {
  const _SheetDragHandle({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 5,
      decoration: BoxDecoration(
        color: AppColors.line,
        borderRadius: BorderRadius.circular(999),
      ),
    );
  }
}

class _SelectedSpotSummary extends StatelessWidget {
  const _SelectedSpotSummary({
    required this.spot,
    required this.spotDetail,
    required this.isFavorite,
    required this.onNavigationPressed,
    required this.onFavoritePressed,
  });

  final MapSpot spot;
  final AsyncValue<SpotDetail> spotDetail;
  final bool isFavorite;
  final VoidCallback onNavigationPressed;
  final Future<void> Function() onFavoritePressed;

  @override
  Widget build(BuildContext context) {
    final detail = spotDetail.valueOrNull;
    final address = (detail?.address.trim().isNotEmpty ?? false)
        ? detail!.address
        : spot.address;
    final menuItems = (detail?.menuItems.isNotEmpty ?? false)
        ? detail!.menuItems
        : spot.menuItems;
    final shouldShowMenuSection = _shouldShowMenuSection(spot.category);
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
                  if (spot.isRecommended) ...[
                    const _RecommendedSpotBadge(),
                    const SizedBox(height: 7),
                  ],
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
                  if (address.trim().isNotEmpty) ...[
                    const SizedBox(height: 8),
                    _SpotAddressLine(address: address),
                  ],
                  if (spot.todayOpeningText != null) ...[
                    const SizedBox(height: 7),
                    _SpotBusinessLine(label: spot.todayOpeningText!),
                  ],
                  const SizedBox(height: 9),
                  _CongestionBadge(label: spot.congestionLabel),
                ],
              ),
            ),
            IconButton.filledTonal(
              onPressed: onFavoritePressed,
              style: IconButton.styleFrom(
                backgroundColor:
                    isFavorite ? AppColors.cream : AppColors.primaryTint,
                foregroundColor: isFavorite ? _rareGold : _mapDark,
              ),
              icon: Icon(
                isFavorite ? Icons.bookmark_rounded : Icons.bookmark_border,
              ),
              tooltip: isFavorite ? '동선에서 제거' : '내 동선에 추가',
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: onNavigationPressed,
            style: OutlinedButton.styleFrom(
              foregroundColor: _mapDark,
              side: const BorderSide(color: AppColors.line),
              minimumSize: const Size.fromHeight(48),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              textStyle: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w900,
              ),
            ),
            icon: const Icon(Icons.navigation_rounded, size: 18),
            label: const Text('길찾기'),
          ),
        ),
        _SpotTourInfoSection(
          spot: spot,
          spotDetail: spotDetail,
        ),
        if (menuItems.isNotEmpty || shouldShowMenuSection) ...[
          const SizedBox(height: 14),
          _SpotMenuPreview(
            key: ValueKey('spot-menu-preview-${spot.id}'),
            menuItems: menuItems,
          ),
        ],
      ],
    );
  }
}

class _SpotAddressLine extends StatelessWidget {
  const _SpotAddressLine({required this.address});

  final String address;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(
          Icons.place_outlined,
          size: 16,
          color: AppColors.textSecondary,
        ),
        const SizedBox(width: 5),
        Expanded(
          child: Text(
            address,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              height: 1.35,
              letterSpacing: 0,
            ),
          ),
        ),
      ],
    );
  }
}

class _SpotBusinessLine extends StatelessWidget {
  const _SpotBusinessLine({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(
          Icons.schedule_rounded,
          size: 16,
          color: AppColors.textSecondary,
        ),
        const SizedBox(width: 5),
        Expanded(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              height: 1.35,
              letterSpacing: 0,
            ),
          ),
        ),
      ],
    );
  }
}

class _SpotTourInfoSection extends StatelessWidget {
  const _SpotTourInfoSection({
    required this.spot,
    required this.spotDetail,
  });

  final MapSpot spot;
  final AsyncValue<SpotDetail> spotDetail;

  @override
  Widget build(BuildContext context) {
    return spotDetail.when(
      data: (detail) => _buildContent(detail),
      loading: () => _buildContent(null, isLoading: true),
      error: (_, __) => _buildContent(null),
    );
  }

  Widget _buildContent(SpotDetail? detail, {bool isLoading = false}) {
    final imageUrls = _imageUrls(detail, spot);
    final guideRows = _tourGuideRows(detail, spot).take(6).toList();
    final description = detail?.description;
    final shouldShowGuidePlaceholder =
        _shouldShowBusinessSection(spot.category) && guideRows.isEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        _SpotImageGallery(
          key: ValueKey('spot-image-gallery-${spot.id}'),
          imageUrls: imageUrls,
        ),
        if (isLoading && imageUrls.isEmpty) ...[
          const SizedBox(height: 10),
          const _SpotTourInfoSkeleton(),
        ],
        if (description != null) ...[
          const SizedBox(height: 16),
          const Text(
            '이곳은 어떤 곳인가요?',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w900,
              letterSpacing: 0,
            ),
          ),
          const SizedBox(height: 7),
          Text(
            description,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
              fontWeight: FontWeight.w700,
              height: 1.48,
              letterSpacing: 0,
            ),
          ),
        ],
        if (guideRows.isNotEmpty || shouldShowGuidePlaceholder) ...[
          const SizedBox(height: 16),
          const Text(
            '이용 안내',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w900,
              letterSpacing: 0,
            ),
          ),
          const SizedBox(height: 8),
          if (guideRows.isEmpty)
            const _SpotInfoPlaceholder(
              icon: Icons.schedule_rounded,
              label: '영업시간과 연락처 정보를 준비 중이에요.',
            )
          else
            for (final row in guideRows) ...[
              _TourInfoRow(icon: row.icon, label: row.label),
              const SizedBox(height: 7),
            ],
        ],
      ],
    );
  }

  List<_TourInfoItem> _tourGuideRows(SpotDetail? detail, MapSpot spot) {
    return [
      _TourInfoItem(
        Icons.storefront_rounded,
        _businessOpenLabel(
          detail?.businessOpeningHours?.openNow ??
              spot.businessOpeningHours?.openNow,
        ),
      ),
      _TourInfoItem(
        Icons.today_rounded,
        detail?.businessOpeningHours?.todayText ??
            spot.businessOpeningHours?.todayText,
      ),
      _TourInfoItem(
        Icons.star_rounded,
        _ratingLabel(detail?.rating ?? spot.rating),
      ),
      _TourInfoItem(
        Icons.public_rounded,
        _websiteLabel(detail?.website ?? spot.website),
      ),
      _TourInfoItem(Icons.call_rounded, detail?.phone ?? spot.phone),
      _TourInfoItem(Icons.schedule_rounded, detail?.openingHours),
      _TourInfoItem(Icons.confirmation_number_rounded, detail?.admissionFee),
      _TourInfoItem(Icons.event_busy_rounded, detail?.closedDays),
      _TourInfoItem(Icons.local_parking_rounded, detail?.parking),
      _TourInfoItem(
        Icons.call_rounded,
        detail?.phone == null ? detail?.contactPhone : null,
      ),
    ]
        .where((item) => item.label != null && item.label!.trim().isNotEmpty)
        .toList();
  }

  String? _businessOpenLabel(bool? openNow) {
    return switch (openNow) {
      true => '영업 중',
      false => '영업 종료',
      null => null,
    };
  }

  String? _ratingLabel(double? rating) {
    if (rating == null || rating <= 0) {
      return null;
    }
    return '평점 ${rating.toStringAsFixed(1)}';
  }

  String? _websiteLabel(String? website) {
    if (website == null || website.trim().isEmpty) {
      return null;
    }
    final uri = Uri.tryParse(website.trim());
    if (uri == null || uri.host.isEmpty) {
      return website.trim();
    }
    return uri.host.replaceFirst(RegExp(r'^www\.'), '');
  }

  List<String> _imageUrls(SpotDetail? detail, MapSpot spot) {
    final urls = <String>[
      ...?detail?.imageUrls,
      if (detail?.imageUrl != null) detail!.imageUrl!,
      ...spot.imageUrls,
      if (spot.imageUrl != null) spot.imageUrl!,
    ];
    return urls
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty)
        .toSet()
        .take(3)
        .toList(growable: false);
  }
}

bool _shouldShowMenuSection(String category) {
  return const {
    'POTATO_RESTAURANT',
    'POTATO_CAFE',
    'POTATO_SNACK',
    'POTATO_MARKET',
    'POTATO_BREWERY',
  }.contains(category);
}

bool _shouldShowBusinessSection(String category) {
  return const {
    'POTATO_RESTAURANT',
    'POTATO_CAFE',
    'POTATO_SNACK',
    'POTATO_MARKET',
    'POTATO_BREWERY',
    'POTATO_EXPERIENCE',
    'POTATO_TOUR',
    'POTATO_SHOP',
  }.contains(category);
}

class _SpotImageGallery extends StatelessWidget {
  const _SpotImageGallery({required this.imageUrls, super.key});

  final List<String> imageUrls;

  @override
  Widget build(BuildContext context) {
    if (imageUrls.isEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: const _SpotImagePlaceholder(),
      );
    }
    if (imageUrls.length == 1) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: SizedBox(
          width: double.infinity,
          height: 154,
          child: _CourseImage(
            imageUrl: imageUrls.first,
            icon: Icons.landscape_rounded,
          ),
        ),
      );
    }
    return SizedBox(
      height: 142,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: imageUrls.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          return ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: SizedBox(
              width: index == 0 ? 214 : 154,
              child: _CourseImage(
                imageUrl: imageUrls[index],
                icon: Icons.landscape_rounded,
              ),
            ),
          );
        },
      ),
    );
  }
}

class _SpotImagePlaceholder extends StatelessWidget {
  const _SpotImagePlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 148,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primaryTint.withValues(alpha: 0.74),
            AppColors.cream.withValues(alpha: 0.82),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.image_search_rounded,
            color: _mapDark,
            size: 34,
          ),
          SizedBox(height: 8),
          Text(
            '장소 이미지를 준비 중이에요',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w800,
              letterSpacing: 0,
            ),
          ),
        ],
      ),
    );
  }
}

class _TourInfoItem {
  const _TourInfoItem(this.icon, this.label);

  final IconData icon;
  final String? label;
}

class _TourInfoRow extends StatelessWidget {
  const _TourInfoRow({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String? label;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 17, color: _mapDark),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label ?? '',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w800,
              height: 1.35,
              letterSpacing: 0,
            ),
          ),
        ),
      ],
    );
  }
}

class _SpotInfoPlaceholder extends StatelessWidget {
  const _SpotInfoPlaceholder({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      decoration: BoxDecoration(
        color: AppColors.primaryTint.withValues(alpha: 0.58),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(icon, size: 17, color: _mapDark),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w800,
                letterSpacing: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SpotTourInfoSkeleton extends StatelessWidget {
  const _SpotTourInfoSkeleton();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.primaryTint.withValues(alpha: 0.62),
        borderRadius: BorderRadius.circular(18),
      ),
      child: const SizedBox(
        width: double.infinity,
        height: 96,
      ),
    );
  }
}

class _SpotMenuPreview extends StatelessWidget {
  const _SpotMenuPreview({required this.menuItems, super.key});

  final List<MapSpotMenuItem> menuItems;

  @override
  Widget build(BuildContext context) {
    if (menuItems.isEmpty) {
      return const _SpotEmptyMenuPreview();
    }
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.cream.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(
                Icons.restaurant_menu_rounded,
                size: 18,
                color: _mapDark,
              ),
              const SizedBox(width: 7),
              const Expanded(
                child: Text(
                  '대표 메뉴',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0,
                  ),
                ),
              ),
              Text(
                '${menuItems.first.verifiedOnLabel} 확인',
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0,
                ),
              ),
            ],
          ),
          const SizedBox(height: 9),
          for (var index = 0; index < menuItems.length; index++) ...[
            Row(
              children: [
                Expanded(
                  child: Text(
                    menuItems[index].name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  menuItems[index].priceLabel,
                  style: const TextStyle(
                    color: _mapDark,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0,
                  ),
                ),
              ],
            ),
            if (index < menuItems.length - 1) const SizedBox(height: 7),
          ],
          const SizedBox(height: 8),
          const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              '가격은 매장 상황에 따라 달라질 수 있어요.',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 10,
                fontWeight: FontWeight.w600,
                letterSpacing: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SpotEmptyMenuPreview extends StatelessWidget {
  const _SpotEmptyMenuPreview();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.cream.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(14),
      ),
      child: const Row(
        children: [
          Icon(
            Icons.restaurant_menu_rounded,
            size: 18,
            color: _mapDark,
          ),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              '대표 메뉴와 가격 정보를 준비 중이에요.',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w800,
                letterSpacing: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RecommendedSpotBadge extends StatelessWidget {
  const _RecommendedSpotBadge();

  @override
  Widget build(BuildContext context) {
    return const Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.auto_awesome_rounded,
          color: _rareGold,
          size: 16,
        ),
        SizedBox(width: 5),
        Text(
          '방문 후 추천 장소',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 12,
            fontWeight: FontWeight.w900,
            letterSpacing: 0,
          ),
        ),
      ],
    );
  }
}

class _RecommendationStatusChip extends StatelessWidget {
  const _RecommendationStatusChip({required this.state, required this.onRetry});

  final AsyncValue<List<SpotRecommendation>> state;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final (icon, label, canRetry) = state.when(
      loading: () => (Icons.travel_explore_rounded, '추천 장소를 찾고 있어요', false),
      error: (_, __) => (Icons.cloud_off_rounded, '추천 장소를 불러오지 못했어요', true),
      data: (recommendations) => recommendations.isEmpty
          ? (Icons.location_off_rounded, '추천 장소를 찾지 못했어요', false)
          : (
              Icons.auto_awesome_rounded,
              '다음 추천 ${recommendations.length}곳 · 노란 핀',
              false,
            ),
    );

    return Material(
      color: Colors.white.withValues(alpha: 0.96),
      borderRadius: BorderRadius.circular(999),
      elevation: 3,
      shadowColor: Colors.black.withValues(alpha: 0.12),
      child: InkWell(
        key: const ValueKey('recommendation-status-chip'),
        onTap: canRetry ? onRetry : null,
        borderRadius: BorderRadius.circular(999),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18, color: _rareGold),
              const SizedBox(width: 7),
              Text(
                label,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0,
                ),
              ),
              if (canRetry) ...[
                const SizedBox(width: 7),
                const Text(
                  '다시 시도',
                  style: TextStyle(
                    color: _mapDark,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0,
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

class _RouteModeChip extends StatelessWidget {
  const _RouteModeChip({
    required this.favoriteCount,
    required this.selected,
    required this.onTap,
  });

  final int favoriteCount;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      key: FeatureTourTargets.routeMode,
      color: selected
          ? AppColors.primaryTint
          : Colors.white.withValues(alpha: 0.96),
      borderRadius: BorderRadius.circular(999),
      elevation: 3,
      shadowColor: Colors.black.withValues(alpha: 0.12),
      child: InkWell(
        key: const ValueKey('route-mode-chip'),
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.bookmark_border_rounded,
                size: 18,
                color: _mapDark,
              ),
              const SizedBox(width: 7),
              Text(
                '내 동선 $favoriteCount곳',
                style: const TextStyle(
                  color: _mapDark,
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
    required this.routePolyline,
    required this.routeSpotIds,
    required this.favoriteSpotIds,
    required this.currentLocation,
    required this.currentLocationFocusTick,
    required this.onSpotSelected,
    this.mapViewBuilder,
  });

  final List<MapSpot> spots;
  final List<FavoriteSpotRoutePoint> routePolyline;
  final List<String> routeSpotIds;
  final Set<String> favoriteSpotIds;
  final FavoriteSpotRoutePoint? currentLocation;
  final int currentLocationFocusTick;
  final ValueChanged<String> onSpotSelected;
  final MapViewBuilder? mapViewBuilder;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: DecoratedBox(
        decoration: const BoxDecoration(color: AppColors.primaryTint),
        child: Stack(
          children: [
            Positioned.fill(
              child: mapViewBuilder?.call(spots, onSpotSelected) ??
                  KakaoMapView(
                    spots: spots,
                    routePolyline: routePolyline,
                    routeSpotIds: routeSpotIds,
                    favoriteSpotIds: favoriteSpotIds,
                    currentLocation: currentLocation,
                    currentLocationFocusTick: currentLocationFocusTick,
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
              color: selected ? _mapPrimary : AppColors.line,
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
    final normalizedLabel = label.startsWith('혼잡도') ? label : '혼잡도 $label';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: AppColors.primaryTint,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        normalizedLabel,
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

class _MapLoading extends StatelessWidget {
  const _MapLoading();

  @override
  Widget build(BuildContext context) {
    return const PotatoLoadingView.fullScreen(
      subtitle: '강원도의 특별한 장소를 불러오고 있어요',
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
        color: AppColors.primaryTint,
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
