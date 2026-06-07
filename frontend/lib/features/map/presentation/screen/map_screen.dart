import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_colors.dart';
import '../widget/kakao_map_view.dart';

const _mapPrimary = Color(0xFF36D98F);
const _mapDark = Color(0xFF509B64);
const _rareGold = Color(0xFFF6C23E);

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  int _selectedCategoryIndex = 0;
  int _selectedSpotIndex = 0;

  static const _categories = ['전체', '관광', '카페', '체험', '맛집'];

  static const _spots = [
    _MapSpot(
      id: 'jeongseon-market',
      name: '정선 5일장',
      area: '정선군',
      category: '관광',
      congestion: '여유',
      potatoName: '곤드레감자',
      isRare: true,
    ),
    _MapSpot(
      id: 'gangneung-coffee',
      name: '강릉 커피거리',
      area: '강릉시',
      category: '카페',
      congestion: '보통',
      potatoName: '바다감자',
      isRare: false,
    ),
    _MapSpot(
      id: 'pyeongchang-ranch',
      name: '대관령 목장',
      area: '평창군',
      category: '체험',
      congestion: '여유',
      potatoName: '눈꽃감자',
      isRare: true,
    ),
    _MapSpot(
      id: 'sokcho-market',
      name: '속초 중앙시장',
      area: '속초시',
      category: '맛집',
      congestion: '혼잡',
      potatoName: '오징어감자',
      isRare: false,
    ),
  ];

  List<_MapSpot> get _visibleSpots {
    final selectedCategory = _categories[_selectedCategoryIndex];
    if (selectedCategory == '전체') {
      return _spots;
    }
    return _spots.where((spot) => spot.category == selectedCategory).toList();
  }

  _MapSpot get _selectedSpot {
    final spots = _visibleSpots;
    if (_selectedSpotIndex >= spots.length) {
      return spots.first;
    }
    return spots[_selectedSpotIndex];
  }

  void _selectCategory(int index) {
    setState(() {
      _selectedCategoryIndex = index;
      _selectedSpotIndex = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: Stack(
                  children: [
                    const Positioned.fill(child: _PotatoMapPreview()),
                    Positioned(
                      left: 12,
                      right: 12,
                      bottom: 126,
                      child: _CategoryFilterBar(
                        categories: _categories,
                        selectedIndex: _selectedCategoryIndex,
                        onSelected: _selectCategory,
                      ),
                    ),
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: _SpotBottomSheet(
                        spot: _selectedSpot,
                        onDetailPressed: () {
                          context.go('/spots/${_selectedSpot.id}');
                        },
                      ),
                    ),
                  ],
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
  const _PotatoMapPreview();

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: const DecoratedBox(
        decoration: BoxDecoration(color: Color(0xFFEAF5D5)),
        child: Stack(
          children: [
            Positioned.fill(child: KakaoMapView()),
            Positioned(
              left: 18,
              top: 18,
              child: _MapStatusBadge(),
            ),
          ],
        ),
      ),
    );
  }
}

class _MapStatusBadge extends StatelessWidget {
  const _MapStatusBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(999),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: const Text(
        '주변 감자 스팟 4곳',
        style: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 13,
          fontWeight: FontWeight.w800,
          letterSpacing: 0,
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

  final List<String> categories;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (var index = 0; index < categories.length; index++) ...[
            ChoiceChip(
              label: Text(categories[index]),
              selected: selectedIndex == index,
              onSelected: (_) => onSelected(index),
              selectedColor: _mapPrimary,
              backgroundColor: Colors.white.withValues(alpha: 0.94),
              labelStyle: TextStyle(
                color: selectedIndex == index
                    ? Colors.white
                    : AppColors.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w800,
                letterSpacing: 0,
              ),
              side: const BorderSide(color: Color(0xFFE8E2D8)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            if (index < categories.length - 1) const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }
}

class _SpotBottomSheet extends StatelessWidget {
  const _SpotBottomSheet({
    required this.spot,
    required this.onDetailPressed,
  });

  final _MapSpot spot;
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
                      '${spot.area} · ${spot.category} · ${spot.potatoName}',
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
              _CongestionBadge(label: spot.congestion),
            ],
          ),
          const SizedBox(height: 12),
          if (spot.isRare)
            const _RarePotatoLine()
          else
            const _NormalPotatoLine(),
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

class _MapSpot {
  const _MapSpot({
    required this.id,
    required this.name,
    required this.area,
    required this.category,
    required this.congestion,
    required this.potatoName,
    required this.isRare,
  });

  final String id;
  final String name;
  final String area;
  final String category;
  final String congestion;
  final String potatoName;
  final bool isRare;
}
