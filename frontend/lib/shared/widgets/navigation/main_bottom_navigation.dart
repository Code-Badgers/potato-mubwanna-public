import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/app_colors.dart';

class MainBottomNavigation extends StatelessWidget {
  const MainBottomNavigation({super.key});

  @override
  Widget build(BuildContext context) {
    final selectedIndex = _selectedIndex(context);
    final bottomInset = MediaQuery.viewPaddingOf(context).bottom;

    return SizedBox(
      height: 72 + bottomInset,
      child: ColoredBox(
        color: AppColors.surface,
        child: Column(
          children: [
            SizedBox(
              height: 72,
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 430),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(6, 8, 6, 10),
                    decoration: const BoxDecoration(
                      color: AppColors.surface,
                      border: Border(top: BorderSide(color: AppColors.line)),
                    ),
                    child: Row(
                      children: List.generate(_destinations.length, (index) {
                        final destination = _destinations[index];

                        return Expanded(
                          child: _FooterItem(
                            icon: destination.icon,
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
          ],
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
    _FooterDestination(icon: Icons.emoji_events_rounded, label: '랠리북'),
    _FooterDestination(icon: Icons.eco_rounded, label: '감자'),
    _FooterDestination(icon: Icons.flag_rounded, label: '미션'),
    _FooterDestination(icon: Icons.person_rounded, label: '마이'),
  ];
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
        isSelected ? AppColors.primary : AppColors.textSecondary;

    return Tooltip(
      message: label,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 42,
              height: 28,
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primary.withValues(alpha: 0.16)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Icon(icon, color: foregroundColor, size: 22),
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
  });

  final IconData icon;
  final String label;
}
