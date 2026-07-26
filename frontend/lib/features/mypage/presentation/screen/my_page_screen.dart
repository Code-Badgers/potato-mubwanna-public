import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../shared/widgets/auth_required_view.dart';
import '../../../auth/application/auth_controller.dart';
import '../../application/user_activity_summary_controller.dart';
import '../../application/user_profile_controller.dart';
import '../../domain/user_activity_summary.dart';
import '../../domain/user_profile.dart';

const _mypagePrimary = Color(0xFF56C787);
const _mypageLine = Color(0xFFE8E2D8);
const _mypageCream = Color(0xFFFFF8EA);
const _mypageBrown = Color(0xFF7A4A24);
const _mypageGold = Color(0xFFF6C23E);

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
        onSettings: () => context.push('/settings'),
      );
    }

    final profileState = ref.watch(userProfileProvider);
    final activitySummaryState = ref.watch(userActivitySummaryProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: profileState.when(
          data: (profile) {
            if (profile == null) {
              return _ProfileErrorState(
                message: '프로필 정보를 찾을 수 없습니다.',
                onRetry: () => ref.invalidate(userProfileProvider),
              );
            }

            return CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: _MyPageHeader(
                    onSettings: () => context.push('/settings'),
                  ),
                ),
                SliverToBoxAdapter(child: _ProfileSummary(profile: profile)),
                SliverToBoxAdapter(
                  child: _TravelStats(
                    summaryState: activitySummaryState,
                    onRetry: () => ref.invalidate(userActivitySummaryProvider),
                  ),
                ),
                const SliverToBoxAdapter(child: _QuickActionGrid()),
                const SliverToBoxAdapter(child: _TravelBanner()),
                SliverToBoxAdapter(
                  child: _AccountMenu(
                    isLoggingOut: authStatus == AuthStatus.loading,
                    onSettings: () => context.push('/settings'),
                    onLogout: () async {
                      await ref.read(authControllerProvider.notifier).logout();
                      if (context.mounted) {
                        context.go('/login');
                      }
                    },
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 24)),
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, __) => _ProfileErrorState(
            onRetry: () => ref.invalidate(userProfileProvider),
          ),
        ),
      ),
    );
  }
}

class _GuestMyPage extends StatelessWidget {
  const _GuestMyPage({
    required this.onLogin,
    required this.onSettings,
  });

  final VoidCallback onLogin;
  final VoidCallback onSettings;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _MyPageHeader(onSettings: onSettings),
            Expanded(
              child: AuthRequiredView(
                description: '마이페이지를 확인하려면 로그인해주세요.',
                onLogin: onLogin,
              ),
            ),
          ],
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

class _ProfileErrorState extends StatelessWidget {
  const _ProfileErrorState({
    this.message = '내 정보를 불러오지 못했습니다.',
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: onRetry,
              child: const Text('다시 시도'),
            ),
          ],
        ),
      ),
    );
  }
}

class _MyPageHeader extends StatelessWidget {
  const _MyPageHeader({required this.onSettings});

  final VoidCallback onSettings;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 18, 24, 10),
      child: Row(
        children: [
          const Expanded(
            child: Text(
              '마이',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 30,
                fontWeight: FontWeight.w900,
                letterSpacing: 0,
              ),
            ),
          ),
          IconButton(
            tooltip: '설정',
            onPressed: onSettings,
            icon: const Icon(
              Icons.settings_outlined,
              color: AppColors.textPrimary,
              size: 28,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileSummary extends StatelessWidget {
  const _ProfileSummary({required this.profile});

  final UserProfile profile;

  @override
  Widget build(BuildContext context) {
    final nickname = profile.nickname.trim();
    final profileImage =
        profile.hasProfileImage ? profile.profileImage.trim() : null;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 22),
      child: Row(
        children: [
          _ProfileAvatar(profileImage: profileImage),
          const SizedBox(width: 22),
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
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  '프로필 정보',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
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
  const _ProfileAvatar({required this.profileImage});

  final String? profileImage;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 102,
      height: 102,
      decoration: BoxDecoration(
        color: const Color(0xFFFFE17A),
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xFFF8D14E), width: 4),
        boxShadow: [
          BoxShadow(
            color: _mypageGold.withValues(alpha: 0.22),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: profileImage == null
          ? const Icon(
              Icons.face_3_rounded,
              size: 58,
              color: _mypageBrown,
            )
          : Image.network(
              profileImage!,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => const Icon(
                Icons.face_3_rounded,
                size: 58,
                color: _mypageBrown,
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
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _mypageLine),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
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
      color: _mypageLine,
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
        onTap: () => context.push('/coupons'),
      ),
      _QuickAction(
        icon: Icons.menu_book_rounded,
        label: '여행 기록',
        onTap: () => context.push('/travel-records'),
      ),
      const _QuickAction(
          icon: Icons.assignment_turned_in_rounded, label: '내 미션'),
      const _QuickAction(icon: Icons.inventory_2_rounded, label: '감자 도감'),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 22),
      child: Row(
        children: [
          for (var index = 0; index < actions.length; index++) ...[
            Expanded(child: _QuickActionCard(action: actions[index])),
            if (index < actions.length - 1) const SizedBox(width: 12),
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
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: action.onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          height: 96,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: _mypageLine),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(action.icon, color: _mypageBrown, size: 30),
              const SizedBox(height: 10),
              Text(
                action.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
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
    );
  }
}

class _TravelBanner extends StatelessWidget {
  const _TravelBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 22),
      height: 94,
      decoration: BoxDecoration(
        color: const Color(0xFFCDE8D7),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Stack(
        children: [
          Positioned(
            right: 20,
            bottom: -4,
            child: Icon(
              Icons.eco_rounded,
              color: _mypagePrimary.withValues(alpha: 0.42),
              size: 86,
            ),
          ),
          const Positioned(
            right: 82,
            top: 20,
            child: Icon(Icons.location_on_rounded, color: Color(0xFF4E93B8)),
          ),
          const Positioned(
            right: 34,
            top: 12,
            child: Icon(Icons.location_on_rounded, color: Color(0xFFE85B4F)),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(24, 21, 126, 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '강원 감자 여행',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  '기록을 확인해보세요!',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
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

class _AccountMenu extends StatelessWidget {
  const _AccountMenu({
    required this.isLoggingOut,
    required this.onSettings,
    required this.onLogout,
  });

  final bool isLoggingOut;
  final VoidCallback onSettings;
  final VoidCallback onLogout;

  static const _items = [
    _MenuItem(
      icon: Icons.settings_outlined,
      label: '설정',
      isSettings: true,
    ),
    _MenuItem(icon: Icons.campaign_outlined, label: '공지사항'),
    _MenuItem(icon: Icons.help_outline_rounded, label: '고객센터'),
    _MenuItem(
      icon: Icons.logout_rounded,
      label: '로그아웃',
      isLogout: true,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Material(
        color: _mypageCream,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: _mypageLine),
        ),
        child: Column(
          children: [
            for (var index = 0; index < _items.length; index++) ...[
              _MenuRow(
                item: _items[index],
                onTap: _items[index].isLogout
                    ? (isLoggingOut ? null : onLogout)
                    : _items[index].isSettings
                        ? onSettings
                        : () {},
              ),
              if (index < _items.length - 1)
                const Divider(height: 1, color: _mypageLine, indent: 58),
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
      onTap: onTap,
      child: SizedBox(
        height: 64,
        child: Row(
          children: [
            const SizedBox(width: 20),
            Icon(item.icon, color: _mypageBrown, size: 25),
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
    this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;
}

class _MenuItem {
  const _MenuItem({
    required this.icon,
    required this.label,
    this.isLogout = false,
    this.isSettings = false,
  });

  final IconData icon;
  final String label;
  final bool isLogout;
  final bool isSettings;
}
