import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_colors.dart';
import '../../application/map_spot_controller.dart';
import '../../domain/map_spot.dart';
import '../widget/kakao_map_view.dart';

const _mapPrimary = Color(0xFF36D98F);
const _mapDark = Color(0xFF509B64);
const _rareGold = Color(0xFFF6C23E);

class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key});

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen> {
  int _selectedCategoryIndex = 0;
  int _selectedSpotIndex = 0;
  final Set<String> _favoriteSpotIds = {};

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

  List<MapSpot> _visibleSpots(List<MapSpot> spots) {
    final selectedCategory = _categories[_selectedCategoryIndex].label;
    if (selectedCategory == '전체') {
      return spots;
    }
    return spots
        .where((spot) => spot.matchesCategoryLabel(selectedCategory))
        .toList();
  }

  MapSpot? _selectedSpot(List<MapSpot> spots) {
    if (_selectedSpotIndex >= spots.length) {
      return spots.isEmpty ? null : spots.first;
    }
    return spots[_selectedSpotIndex];
  }

  void _selectCategory(int index) {
    setState(() {
      _selectedCategoryIndex = index;
      _selectedSpotIndex = 0;
    });
  }

  void _selectSpotById(List<MapSpot> visibleSpots, String spotId) {
    final nextIndex = visibleSpots.indexWhere((spot) => spot.id == spotId);
    if (nextIndex < 0) {
      return;
    }
    setState(() {
      _selectedSpotIndex = nextIndex;
    });
  }

  void _toggleFavorite(String spotId) {
    setState(() {
      if (!_favoriteSpotIds.add(spotId)) {
        _favoriteSpotIds.remove(spotId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final spotsState = ref.watch(mapSpotsProvider);

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
                    final visibleSpots = _visibleSpots(spots);
                    final selectedSpot = _selectedSpot(visibleSpots);
                    return Stack(
                      children: [
                        Positioned.fill(
                          child: _PotatoMapPreview(
                            spots: visibleSpots,
                            onSpotSelected: (spotId) {
                              _selectSpotById(visibleSpots, spotId);
                            },
                          ),
                        ),
                        Positioned(
                          left: 12,
                          right: 12,
                          top: 18,
                          child: _CategoryFilterBar(
                            categories: _categories,
                            selectedIndex: _selectedCategoryIndex,
                            onSelected: _selectCategory,
                          ),
                        ),
                        if (selectedSpot == null)
                          const Positioned.fill(
                            child: _EmptySpotMessage(),
                          )
                        else
                          Positioned(
                            left: 0,
                            right: 0,
                            bottom: 0,
                            child: _SpotBottomSheet(
                              spot: selectedSpot,
                              favoriteCount: _favoriteSpotIds.length,
                              isFavorite:
                                  _favoriteSpotIds.contains(selectedSpot.id),
                              onFavoritePressed: () {
                                _toggleFavorite(selectedSpot.id);
                              },
                              onDetailPressed: () {
                                context.go('/spots/${selectedSpot.id}');
                              },
                            ),
                          ),
                      ],
                    );
                  },
                  loading: () => const _MapLoading(),
                  error: (_, __) => Stack(
                    children: [
                      const Positioned.fill(
                        child: _PotatoMapPreview(spots: []),
                      ),
                      Positioned(
                        left: 12,
                        right: 12,
                        top: 18,
                        child: _CategoryFilterBar(
                          categories: _categories,
                          selectedIndex: _selectedCategoryIndex,
                          onSelected: _selectCategory,
                        ),
                      ),
                      const Positioned.fill(child: _MapError()),
                    ],
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

class _PotatoMapPreview extends StatelessWidget {
  const _PotatoMapPreview({
    required this.spots,
    this.onSpotSelected,
  });

  final List<MapSpot> spots;
  final ValueChanged<String>? onSpotSelected;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: DecoratedBox(
        decoration: const BoxDecoration(color: Color(0xFFEAF5D5)),
        child: Stack(
          children: [
            Positioned.fill(
              child: KakaoMapView(
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

class _SpotBottomSheet extends StatelessWidget {
  const _SpotBottomSheet({
    required this.spot,
    required this.favoriteCount,
    required this.isFavorite,
    required this.onFavoritePressed,
    required this.onDetailPressed,
  });

  final MapSpot spot;
  final int favoriteCount;
  final bool isFavorite;
  final VoidCallback onFavoritePressed;
  final VoidCallback onDetailPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE8E2D8)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.10),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
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
          if (spot.isRare)
            const _RarePotatoLine()
          else
            const _NormalPotatoLine(),
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
      ),
    );
  }
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

class _MapError extends StatelessWidget {
  const _MapError();

  @override
  Widget build(BuildContext context) {
    return const IgnorePointer(
      child: Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            '감자 스팟을 불러오지 못했습니다.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w800,
              letterSpacing: 0,
            ),
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
