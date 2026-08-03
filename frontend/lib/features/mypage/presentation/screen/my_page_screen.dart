import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../shared/widgets/auth_required_view.dart';
import '../../../auth/application/auth_controller.dart';
import '../../../stamp/application/stamp_book_controller.dart';
import '../../../stamp/domain/stamp_book.dart';
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
    final stampBookState = ref.watch(stampBookProvider);

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
            SliverToBoxAdapter(
              child: _CityStampSummary(
                stampBookState: stampBookState,
                onRetry: () => ref.invalidate(stampBookProvider),
              ),
            ),
            const SliverToBoxAdapter(child: _QuickActionGrid()),
            SliverToBoxAdapter(
              child: _AccountMenu(onSettings: () => context.push('/settings')),
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
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.line),
      ),
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
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        color: AppColors.primaryTint,
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.28)),
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
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.line),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 18,
            offset: const Offset(0, 7),
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

class _CityStampSummary extends StatelessWidget {
  const _CityStampSummary({
    required this.stampBookState,
    required this.onRetry,
  });

  final AsyncValue<StampBook?> stampBookState;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.line),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: stampBookState.when(
        data: (stampBook) {
          final progress = stampBook?.progress;
          if (progress == null) {
            return const _CityStampEmpty();
          }
          return _CityStampProgress(progress: progress);
        },
        loading: () => const _CityStampLoading(),
        error: (_, __) => _CityStampError(onRetry: onRetry),
      ),
    );
  }
}

class _CityStampProgress extends StatelessWidget {
  const _CityStampProgress({required this.progress});

  final StampProgress progress;

  @override
  Widget build(BuildContext context) {
    final totalCount = progress.totalCount == 0 ? 18 : progress.totalCount;
    final acquiredCount = progress.acquiredCount.clamp(0, totalCount);
    final ratio = totalCount == 0 ? 0.0 : acquiredCount / totalCount;
    final percent = (ratio * 100).round();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: const BoxDecoration(
                color: AppColors.primaryTint,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.verified_rounded,
                color: AppColors.primaryDark,
                size: 22,
              ),
            ),
            const SizedBox(width: 10),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '시군별 스탬프',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    '강원 18개 시군 수집 현황',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              '$percent%',
              style: const TextStyle(
                color: AppColors.primaryDark,
                fontSize: 24,
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
            minHeight: 9,
            value: ratio.clamp(0, 1),
            backgroundColor: const Color(0xFFEFE9DC),
            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          '$acquiredCount / $totalCount개 수집',
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 13,
            fontWeight: FontWeight.w800,
            letterSpacing: 0,
          ),
        ),
        const SizedBox(height: 14),
        Wrap(
          spacing: 7,
          runSpacing: 8,
          children: [
            for (final stamp in progress.stamps) _CityStampChip(stamp: stamp),
          ],
        ),
      ],
    );
  }
}

class _CityStampChip extends StatelessWidget {
  const _CityStampChip({required this.stamp});

  final RallybookStamp stamp;

  @override
  Widget build(BuildContext context) {
    final acquired = stamp.acquired;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: acquired ? AppColors.primaryTint : AppColors.background,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: acquired ? AppColors.primary : AppColors.line,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            acquired
                ? Icons.check_circle_rounded
                : Icons.radio_button_unchecked,
            color: acquired ? AppColors.primaryDark : AppColors.textSecondary,
            size: 15,
          ),
          const SizedBox(width: 5),
          Text(
            stamp.cityName,
            style: TextStyle(
              color: acquired ? AppColors.textPrimary : AppColors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w900,
              letterSpacing: 0,
            ),
          ),
        ],
      ),
    );
  }
}

class _CityStampLoading extends StatelessWidget {
  const _CityStampLoading();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: 92,
      child: Center(child: CircularProgressIndicator()),
    );
  }
}

class _CityStampEmpty extends StatelessWidget {
  const _CityStampEmpty();

  @override
  Widget build(BuildContext context) {
    return const Text(
      '스탬프 수집 현황을 준비하고 있어요.',
      style: TextStyle(
        color: AppColors.textSecondary,
        fontSize: 14,
        fontWeight: FontWeight.w800,
        letterSpacing: 0,
      ),
    );
  }
}

class _CityStampError extends StatelessWidget {
  const _CityStampError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(
          child: Text(
            '시군별 스탬프를 불러오지 못했어요.',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
              fontWeight: FontWeight.w800,
              letterSpacing: 0,
            ),
          ),
        ),
        TextButton(
          onPressed: onRetry,
          child: const Text('다시 시도'),
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
        onTap: () => context.push('/coupons'),
      ),
      _QuickAction(
        icon: Icons.menu_book_rounded,
        label: '여행 기록',
        onTap: () => context.push('/travel-records'),
      ),
      _QuickAction(
        icon: Icons.eco_rounded,
        label: '감자 도감',
        onTap: () => context.go('/main/potato'),
      ),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
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
            border: Border.all(color: AppColors.line),
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
              Icon(action.icon, color: AppColors.primaryDark, size: 28),
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

class _AccountMenu extends StatelessWidget {
  const _AccountMenu({
    required this.onSettings,
  });

  final VoidCallback onSettings;

  static const _items = [
    _MenuItem(
      icon: Icons.settings_outlined,
      label: '설정',
      isSettings: true,
    ),
    _MenuItem(icon: Icons.campaign_outlined, label: '공지사항'),
    _MenuItem(icon: Icons.help_outline_rounded, label: '고객센터'),
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Material(
        color: AppColors.surface,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: AppColors.line),
        ),
        child: Column(
          children: [
            for (var index = 0; index < _items.length; index++) ...[
              _MenuRow(
                item: _items[index],
                onTap: _items[index].isSettings ? onSettings : () {},
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
    this.isSettings = false,
  });

  final IconData icon;
  final String label;
  final bool isSettings;
}
