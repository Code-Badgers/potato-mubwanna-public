import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_design_tokens.dart';
import '../../../../shared/widgets/auth_required_view.dart';
import '../../../auth/application/auth_controller.dart';
import '../../application/user_activity_summary_controller.dart';
import '../../application/user_profile_controller.dart';
import '../../domain/user_activity_summary.dart';
import '../../domain/user_profile.dart';

class MyPageScreen extends ConsumerWidget {
  const MyPageScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authStatus = ref.watch(authControllerProvider).status;

    if (authStatus == AuthStatus.loading) {
      return const _MyPageLoading();
    }

    if (authStatus != AuthStatus.authenticated) {
      return _GuestMyPage(
        onLogin: () => context.go('/login'),
      );
    }

    final activitySummaryState = ref.watch(userActivitySummaryProvider);
    final profileState = ref.watch(userProfileProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            const SliverToBoxAdapter(child: SizedBox(height: 18)),
            SliverToBoxAdapter(
                child: _ProfileHeader(profileState: profileState)),
            SliverToBoxAdapter(
              child: _TravelStats(
                summaryState: activitySummaryState,
                onRetry: () => ref.invalidate(userActivitySummaryProvider),
              ),
            ),
            const SliverToBoxAdapter(child: _QuickActionGrid()),
            SliverToBoxAdapter(
              child: _AccountMenu(
                onSettings: () => context.push('/settings'),
                onNotices: () => context.push('/notices'),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 24)),
          ],
        ),
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({required this.profileState});

  final AsyncValue<UserProfile?> profileState;

  @override
  Widget build(BuildContext context) {
    final profile = profileState.valueOrNull;
    final nickname = profile == null || profile.nickname.trim().isEmpty
        ? '감자여행자'
        : profile.nickname.trim();

    return Container(
      margin: const EdgeInsets.fromLTRB(
        AppDimens.pageHorizontalPadding,
        0,
        AppDimens.pageHorizontalPadding,
        16,
      ),
      padding: const EdgeInsets.all(18),
      decoration: _myPageCardDecoration(),
      child: Row(
        children: [
          _ProfileAvatar(profile: profile),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  nickname,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0,
                  ),
                ),
                const SizedBox(height: 5),
                const Text(
                  '강원 감자 여행자',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileAvatar extends StatelessWidget {
  const _ProfileAvatar({required this.profile});

  final UserProfile? profile;

  @override
  Widget build(BuildContext context) {
    final profileImage = profile?.profileImage.trim() ?? '';

    return Container(
      width: 68,
      height: 68,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFEAF9F0),
            Color(0xFFFFF8EA),
          ],
        ),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white.withValues(alpha: 0.82)),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryDark.withValues(alpha: 0.12),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: profileImage.isEmpty
          ? const Center(
              child: Icon(
                Icons.person_rounded,
                color: AppColors.primaryDark,
                size: 34,
              ),
            )
          : Image.network(
              profileImage,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => const Center(
                child: Icon(
                  Icons.person_rounded,
                  color: AppColors.primaryDark,
                  size: 34,
                ),
              ),
            ),
    );
  }
}

class _GuestMyPage extends StatelessWidget {
  const _GuestMyPage({
    required this.onLogin,
  });

  final VoidCallback onLogin;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: AuthRequiredView(
          description: '마이페이지를 확인하려면 로그인해주세요.',
          onLogin: onLogin,
        ),
      ),
    );
  }
}

class _MyPageLoading extends StatelessWidget {
  const _MyPageLoading();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Stack(
          children: [
            ModalBarrier(dismissible: false, color: Colors.black12),
            Center(child: CircularProgressIndicator()),
          ],
        ),
      ),
    );
  }
}

class _TravelStats extends StatelessWidget {
  const _TravelStats({
    required this.summaryState,
    required this.onRetry,
  });

  final AsyncValue<UserActivitySummary?> summaryState;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(
        AppDimens.pageHorizontalPadding,
        0,
        AppDimens.pageHorizontalPadding,
        24,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 18),
      decoration: _myPageCardDecoration(),
      child: summaryState.when(
        data: (summary) => _TravelStatRow(
          summary: summary ?? UserActivitySummary.empty,
        ),
        loading: () => const _TravelStatRow(
          summary: UserActivitySummary.empty,
          isLoading: true,
        ),
        error: (_, __) => Column(
          children: [
            const _TravelStatRow(
              summary: UserActivitySummary.empty,
              hasError: true,
            ),
            const SizedBox(height: 10),
            TextButton.icon(
              key: const ValueKey('activity-summary-retry'),
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('활동 요약 다시 시도'),
            ),
          ],
        ),
      ),
    );
  }
}

class _TravelStatRow extends StatelessWidget {
  const _TravelStatRow({
    required this.summary,
    this.isLoading = false,
    this.hasError = false,
  });

  final UserActivitySummary summary;
  final bool isLoading;
  final bool hasError;

  @override
  Widget build(BuildContext context) {
    final placeholder = isLoading ? '…' : '-';
    return Row(
      children: [
        Expanded(
          child: _StatItem(
            label: '누적 걸음 수',
            value: isLoading || hasError
                ? placeholder
                : _formatInt(summary.totalSteps),
          ),
        ),
        const _VerticalDivider(),
        Expanded(
          child: _StatItem(
            label: '누적 스탬프 수',
            value: isLoading || hasError
                ? placeholder
                : _formatInt(summary.stampCount),
          ),
        ),
        const _VerticalDivider(),
        Expanded(
          child: _StatItem(
            label: '보유 감자 수',
            value: isLoading || hasError
                ? placeholder
                : _formatInt(summary.ownedPotatoCount),
          ),
        ),
      ],
    );
  }
}

class _StatItem extends StatelessWidget {
  const _StatItem({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 13,
            fontWeight: FontWeight.w800,
            letterSpacing: 0,
          ),
        ),
        const SizedBox(height: 9),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            value,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 25,
              fontWeight: FontWeight.w900,
              letterSpacing: 0,
            ),
          ),
        ),
      ],
    );
  }
}

class _VerticalDivider extends StatelessWidget {
  const _VerticalDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 54,
      color: AppColors.line,
    );
  }
}

String _formatInt(int value) {
  return value.toString().replaceAllMapped(
        RegExp(r'\B(?=(\d{3})+(?!\d))'),
        (_) => ',',
      );
}

class _QuickActionGrid extends StatelessWidget {
  const _QuickActionGrid();

  @override
  Widget build(BuildContext context) {
    final actions = [
      _QuickAction(
        icon: Icons.card_giftcard_rounded,
        label: '보상함',
        key: const ValueKey('mypage-quick-action-coupons'),
        onTap: () => context.push('/coupons'),
      ),
      _QuickAction(
        icon: Icons.menu_book_rounded,
        label: '여행 기록',
        key: const ValueKey('mypage-quick-action-travel-records'),
        onTap: () => context.push('/travel-records'),
      ),
      _QuickAction(
        icon: Icons.grid_view_rounded,
        label: '스탬프 투어',
        key: const ValueKey('mypage-quick-action-stamp-tour'),
        onTap: () => context.go('/main/stamps/cities'),
      ),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppDimens.pageHorizontalPadding,
        0,
        AppDimens.pageHorizontalPadding,
        20,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var index = 0; index < actions.length; index++) ...[
            Expanded(child: _QuickActionCard(action: actions[index])),
            if (index < actions.length - 1) const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  const _QuickActionCard({required this.action});

  final _QuickAction action;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface.withValues(alpha: 0.9),
      borderRadius: BorderRadius.circular(AppDimens.compactCardRadius),
      child: InkWell(
        key: action.key,
        onTap: action.onTap,
        borderRadius: BorderRadius.circular(AppDimens.compactCardRadius),
        child: Container(
          height: 90,
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppDimens.compactCardRadius),
            border: Border.all(
              color: AppColors.line.withValues(alpha: 0.84),
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.primaryTint.withValues(alpha: 0.92),
                  shape: BoxShape.circle,
                ),
                child:
                    Icon(action.icon, color: AppColors.primaryDark, size: 21),
              ),
              const SizedBox(height: 9),
              Text(
                action.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 12,
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

class _AccountMenu extends StatelessWidget {
  const _AccountMenu({
    required this.onSettings,
    required this.onNotices,
  });

  final VoidCallback onSettings;
  final VoidCallback onNotices;

  static const _items = [
    _MenuItem(
      icon: Icons.settings_outlined,
      label: '설정',
      destination: _MenuDestination.settings,
    ),
    _MenuItem(
      icon: Icons.campaign_outlined,
      label: '공지사항',
      destination: _MenuDestination.notices,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimens.pageHorizontalPadding,
      ),
      child: Material(
        color: AppColors.surface.withValues(alpha: 0.9),
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimens.cardRadius),
          side: BorderSide(color: AppColors.line.withValues(alpha: 0.84)),
        ),
        child: Column(
          children: [
            for (var index = 0; index < _items.length; index++) ...[
              _MenuRow(
                item: _items[index],
                onTap: switch (_items[index].destination) {
                  _MenuDestination.settings => onSettings,
                  _MenuDestination.notices => onNotices,
                },
              ),
              if (index < _items.length - 1)
                const Divider(height: 1, color: AppColors.line, indent: 58),
            ],
          ],
        ),
      ),
    );
  }
}

class _MenuRow extends StatelessWidget {
  const _MenuRow({
    required this.item,
    required this.onTap,
  });

  final _MenuItem item;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      key: switch (item.destination) {
        _MenuDestination.settings => const ValueKey('mypage-menu-settings'),
        _MenuDestination.notices => const ValueKey('mypage-menu-notices'),
      },
      onTap: onTap,
      child: SizedBox(
        height: 64,
        child: Row(
          children: [
            const SizedBox(width: 20),
            Icon(
              item.icon,
              color: AppColors.primaryDark,
              size: 25,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                item.label,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0,
                ),
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.textSecondary,
              size: 25,
            ),
            const SizedBox(width: 16),
          ],
        ),
      ),
    );
  }
}

class _QuickAction {
  const _QuickAction({
    required this.icon,
    required this.label,
    required this.key,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final Key key;
  final VoidCallback? onTap;
}

class _MenuItem {
  const _MenuItem({
    required this.icon,
    required this.label,
    required this.destination,
  });

  final IconData icon;
  final String label;
  final _MenuDestination destination;
}

enum _MenuDestination { settings, notices }

BoxDecoration _myPageCardDecoration() {
  return BoxDecoration(
    color: AppColors.surface.withValues(alpha: 0.92),
    borderRadius: BorderRadius.circular(AppDimens.cardRadius),
    border: Border.all(color: AppColors.line.withValues(alpha: 0.82)),
    boxShadow: AppShadows.softCard,
  );
}
