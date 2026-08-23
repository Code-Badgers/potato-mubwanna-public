import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_design_tokens.dart';

class MainBottomNavigation extends StatelessWidget {
  const MainBottomNavigation({super.key});

  @override
  Widget build(BuildContext context) {
    final selectedIndex = _selectedIndex(context);
    final bottomInset = MediaQuery.viewPaddingOf(context).bottom;

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: SizedBox(
          height: AppDimens.bottomNavigationHeight + bottomInset,
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
                        child: _FooterItem(
                          icon: destination.icon,
                          assetPath: destination.assetPath,
                          label: destination.label,
                          isSelected: selectedIndex == index,
                          onTap: () => context.go(_paths[index]),
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
    final location = GoRouterState.of(context).location;
    final index = _paths.indexWhere(location.startsWith);
    return index < 0 ? 0 : index;
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
    _FooterDestination(icon: Icons.emoji_events_rounded, label: '스탬프'),
    _FooterDestination(
      icon: Icons.eco_rounded,
      assetPath: 'assets/characters/potatoes/default_beginner_potato.png',
      label: '감자밭',
    ),
    _FooterDestination(icon: Icons.flag_rounded, label: '미션'),
    _FooterDestination(icon: Icons.person_rounded, label: '마이'),
  ];
}

class _FooterItem extends StatelessWidget {
  const _FooterItem({
    required this.icon,
    this.assetPath,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final IconData icon;
  final String? assetPath;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final foregroundColor =
        isSelected ? AppColors.primary : AppColors.textSecondary;

    return Tooltip(
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
              child: assetPath == null
                  ? Icon(icon, color: foregroundColor, size: 21)
                  : Center(
                      child: Image.asset(
                        assetPath!,
                        width: 23,
                        height: 23,
                        fit: BoxFit.contain,
                        opacity: AlwaysStoppedAnimation<double>(
                          isSelected ? 1 : 0.72,
                        ),
                      ),
                    ),
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
    );
  }
}

class _FooterDestination {
  const _FooterDestination({
    required this.icon,
    required this.label,
    this.assetPath,
  });

  final IconData icon;
  final String label;
  final String? assetPath;
}
