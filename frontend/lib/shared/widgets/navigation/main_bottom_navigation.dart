import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_design_tokens.dart';
import '../../../features/feature_tour/presentation/feature_tour_targets.dart';

class MainBottomNavigation extends StatelessWidget {
  const MainBottomNavigation({super.key});

  @override
  Widget build(BuildContext context) {
    // Shell의 route state는 push된 탭을 반영하지 않으므로 실제 경로를 구독한다.
    return AnimatedBuilder(
      animation: GoRouter.of(context),
      builder: (context, _) => _buildNavigation(context),
    );
  }

  Widget _buildNavigation(BuildContext context) {
    final selectedIndex = _selectedIndex(context);
    final bottomInset = MediaQuery.viewPaddingOf(context).bottom;
    final labelGrowth = MediaQuery.textScalerOf(context).scale(10) - 10;

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: SizedBox(
          height: AppDimens.bottomNavigationHeight + bottomInset + labelGrowth,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: AppColors.surface.withValues(alpha: 0.88),
              border: Border(
                top: BorderSide(color: AppColors.line.withValues(alpha: 0.72)),
              ),
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 430),
                child: Padding(
                  padding: EdgeInsets.fromLTRB(10, 14, 10, 8 + bottomInset),
                  child: Row(
                    children: List.generate(_destinations.length, (index) {
                      final destination = _destinations[index];

                      return Expanded(
                        child: KeyedSubtree(
                          key: _targetKeyFor(index),
                          child: _FooterItem(
                            icon: destination.icon,
                            label: destination.label,
                            isSelected: selectedIndex == index,
                            onTap: () {
                              if (selectedIndex != index) {
                                _openTab(context, _paths[index]);
                              }
                            },
                          ),
                        ),
                      );
                    }),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  int _selectedIndex(BuildContext context) {
    final location = GoRouter.of(context).location;
    final index = _paths.indexWhere(location.startsWith);
    return index < 0 ? 0 : index;
  }

  void _openTab(BuildContext context, String path) {
    final router = GoRouter.of(context);
    final alreadyOpen = router.routerDelegate.currentConfiguration.matches.any(
      (match) => match.route is GoRoute && match.matchedLocation == path,
    );
    // 같은 화면을 중복 push하면 안내용 GlobalKey와 화면 상태가 충돌한다.
    if (alreadyOpen) {
      while (Uri.parse(router.location).path != path && router.canPop()) {
        router.pop();
      }
      return;
    }
    router.push(path);
  }

  static const _paths = [
    '/main/map',
    '/main/stamps',
    '/main/potatoes',
    '/main/missions',
    '/main/mypage',
  ];

  static const _destinations = [
    _FooterDestination(icon: Icons.map_rounded, label: '지도'),
    _FooterDestination(icon: Icons.approval_rounded, label: '스탬프'),
    _FooterDestination(icon: Icons.egg_alt_rounded, label: '감자밭'),
    _FooterDestination(icon: Icons.flag_rounded, label: '미션'),
    _FooterDestination(icon: Icons.person_rounded, label: '마이'),
  ];

  static GlobalKey? _targetKeyFor(int index) {
    switch (index) {
      case 0:
        return FeatureTourTargets.mapNavigation;
      case 1:
        return FeatureTourTargets.stampNavigation;
      case 2:
        return FeatureTourTargets.potatoNavigation;
      case 3:
        return FeatureTourTargets.missionNavigation;
      default:
        return null;
    }
  }
}

class _FooterItem extends StatelessWidget {
  const _FooterItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final foregroundColor =
        isSelected ? AppColors.actionGreen : AppColors.textSecondary;

    return Semantics(
      button: true,
      selected: isSelected,
      child: Tooltip(
        excludeFromSemantics: true,
        message: label,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppDimens.compactCardRadius),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: isSelected ? 42 : 36,
                height: 30,
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.primary.withValues(alpha: 0.18)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(AppDimens.pillRadius),
                ),
                child: Icon(icon, color: foregroundColor, size: 21),
              ),
              const SizedBox(height: 3),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: foregroundColor,
                  fontSize: 10,
                  fontWeight: isSelected ? FontWeight.w900 : FontWeight.w700,
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

class _FooterDestination {
  const _FooterDestination({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;
}
