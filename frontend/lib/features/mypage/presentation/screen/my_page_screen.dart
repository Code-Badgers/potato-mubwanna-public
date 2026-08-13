import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_design_tokens.dart';
import '../../../../shared/widgets/auth_required_view.dart';
import '../../../auth/application/auth_controller.dart';
import '../../../potato/application/potato_collection_controller.dart';
import '../../../potato/domain/potato_collection.dart';
import '../../../potato/presentation/potato_asset.dart';
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
    final potatoCollectionState = ref.watch(potatoCollectionProvider);

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
              child: _MyPotatoCardAlbum(
                collectionState: potatoCollectionState,
                onRetry: () => ref.invalidate(potatoCollectionProvider),
              ),
            ),
            const SliverToBoxAdapter(child: _QuickActionGrid()),
            SliverToBoxAdapter(
              child: _AccountMenu(
                onSettings: () => context.push('/settings'),
                onNotices: () => context.push('/notices'),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 18)),
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
        14,
      ),
      padding: const EdgeInsets.all(16),
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
        18,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
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
          maxLines: 2,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 11,
            fontWeight: FontWeight.w800,
            height: 1.15,
            letterSpacing: 0,
          ),
        ),
        const SizedBox(height: 8),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            value,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 23,
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
      color: AppColors.line.withValues(alpha: 0.68),
    );
  }
}

class _MyPotatoCardAlbum extends StatelessWidget {
  const _MyPotatoCardAlbum({
    required this.collectionState,
    required this.onRetry,
  });

  final AsyncValue<PotatoCollection?> collectionState;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(
        AppDimens.pageHorizontalPadding,
        0,
        AppDimens.pageHorizontalPadding,
        16,
      ),
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
      decoration: _myPageGlassDecoration(alpha: 0.9),
      child: collectionState.when(
        data: (collection) {
          final cards = (collection?.items ?? const <PotatoCollectionItem>[])
              .where((item) => item.acquired)
              .toList(growable: false);
          if (cards.isEmpty) {
            return const _PotatoAlbumEmpty();
          }
          return _PotatoAlbumContent(cards: cards);
        },
        loading: () => const _PotatoAlbumLoading(),
        error: (_, __) => _PotatoAlbumError(onRetry: onRetry),
      ),
    );
  }
}

class _PotatoAlbumContent extends StatefulWidget {
  const _PotatoAlbumContent({required this.cards});

  final List<PotatoCollectionItem> cards;

  @override
  State<_PotatoAlbumContent> createState() => _PotatoAlbumContentState();
}

class _PotatoAlbumContentState extends State<_PotatoAlbumContent> {
  late final PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(
      viewportFraction: widget.cards.length > 1 ? 0.78 : 1,
    );
  }

  @override
  void didUpdateWidget(covariant _PotatoAlbumContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.cards.length != widget.cards.length) {
      _pageController.jumpToPage(0);
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cards = widget.cards;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '내 감자 도감',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    '수집한 감자만 카드로 보여요',
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
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.primaryTint.withValues(alpha: 0.92),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                '${cards.length}장',
                style: const TextStyle(
                  color: AppColors.primaryDark,
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 260,
          child: PageView.builder(
            key: const ValueKey('mypage-potato-card-album'),
            controller: _pageController,
            padEnds: cards.length > 1,
            itemCount: cards.length,
            itemBuilder: (context, index) {
              return AnimatedBuilder(
                animation: _pageController,
                builder: (context, child) {
                  var scale = 1.0;
                  if (_pageController.hasClients &&
                      _pageController.position.haveDimensions) {
                    final page = _pageController.page ?? 0;
                    scale = (1 - (page - index).abs() * 0.08).clamp(0.92, 1);
                  }
                  return Transform.scale(scale: scale, child: child);
                },
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: cards.length > 1 ? 7 : 0,
                  ),
                  child: _MyPotatoCollectionCard(item: cards[index]),
                ),
              );
            },
          ),
        ),
        if (cards.length > 1) ...[
          const SizedBox(height: 10),
          const Center(
            child: Text(
              '좌우로 넘겨 카드 보기',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w800,
                letterSpacing: 0,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _MyPotatoCollectionCard extends StatelessWidget {
  const _MyPotatoCollectionCard({required this.item});

  final PotatoCollectionItem item;

  @override
  Widget build(BuildContext context) {
    final rarityColor = _rarityColor(item.rarity);
    final acquiredAt = item.acquiredAt;
    final acquiredLabel = acquiredAt == null
        ? '수집 완료'
        : '${acquiredAt.year}.${acquiredAt.month.toString().padLeft(2, '0')}.${acquiredAt.day.toString().padLeft(2, '0')} 수집';

    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        gradient: _rarityGradient(item.rarity),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: rarityColor.withValues(alpha: 0.20),
            blurRadius: 22,
            offset: const Offset(0, 13),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(21),
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: _potatoCardSurfaceGradient(item.rarity),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 13, 16, 15),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '#${item.id.padLeft(3, '0')}',
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.1,
                        ),
                      ),
                    ),
                    _PotatoRarityPill(rarity: item.rarity),
                  ],
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: Center(
                    child: Image.asset(
                      potatoLocalAssetPath(item.code),
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => const Icon(
                        Icons.eco_rounded,
                        color: AppColors.primaryDark,
                        size: 72,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  item.name.trim().isEmpty ? '감자 카드' : item.name.trim(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  [
                    if (item.region.trim().isNotEmpty) item.region.trim(),
                    acquiredLabel,
                  ].join(' · '),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  item.description.trim().isEmpty
                      ? '강원 여행길에서 만난 감자 카드예요.'
                      : item.description.trim(),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                    height: 1.38,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PotatoRarityPill extends StatelessWidget {
  const _PotatoRarityPill({required this.rarity});

  final PotatoRarity rarity;

  @override
  Widget build(BuildContext context) {
    final color = _rarityColor(rarity);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        _rarityLabel(rarity),
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w900,
          letterSpacing: 0,
        ),
      ),
    );
  }
}

class _PotatoAlbumEmpty extends StatelessWidget {
  const _PotatoAlbumEmpty();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '내 감자 카드',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w900,
              letterSpacing: 0,
            ),
          ),
          SizedBox(height: 10),
          Text(
            '아직 수집한 카드가 없어요. 감자 스팟을 방문하면 이곳에 카드가 채워져요.',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
              height: 1.42,
              fontWeight: FontWeight.w700,
              letterSpacing: 0,
            ),
          ),
        ],
      ),
    );
  }
}

class _PotatoAlbumLoading extends StatelessWidget {
  const _PotatoAlbumLoading();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: 150,
      child: Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      ),
    );
  }
}

class _PotatoAlbumError extends StatelessWidget {
  const _PotatoAlbumError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '내 감자 카드',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w900,
            letterSpacing: 0,
          ),
        ),
        const SizedBox(height: 10),
        const Text(
          '감자 카드를 불러오지 못했어요.',
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 13,
            fontWeight: FontWeight.w700,
            letterSpacing: 0,
          ),
        ),
        const SizedBox(height: 8),
        TextButton.icon(
          onPressed: onRetry,
          icon: const Icon(Icons.refresh_rounded, size: 18),
          label: const Text('다시 불러오기'),
        ),
      ],
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
        onTap: () => context.push('/main/stamps/cities'),
      ),
    ];

    return Container(
      margin: const EdgeInsets.fromLTRB(
        AppDimens.pageHorizontalPadding,
        0,
        AppDimens.pageHorizontalPadding,
        16,
      ),
      padding: const EdgeInsets.fromLTRB(
        10,
        12,
        10,
        12,
      ),
      decoration: _myPageGlassDecoration(alpha: 0.78),
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
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(AppDimens.compactCardRadius),
      child: InkWell(
        key: action.key,
        onTap: action.onTap,
        borderRadius: BorderRadius.circular(AppDimens.compactCardRadius),
        child: SizedBox(
          height: 74,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: AppColors.primaryTint.withValues(alpha: 0.92),
                  shape: BoxShape.circle,
                ),
                child:
                    Icon(action.icon, color: AppColors.primaryDark, size: 21),
              ),
              const SizedBox(height: 7),
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
    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: AppDimens.pageHorizontalPadding,
      ),
      decoration: _myPageGlassDecoration(alpha: 0.82),
      child: Material(
        color: Colors.transparent,
        clipBehavior: Clip.antiAlias,
        borderRadius: BorderRadius.circular(AppDimens.cardRadius),
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
                Divider(
                  height: 1,
                  indent: 56,
                  endIndent: 18,
                  color: AppColors.line.withValues(alpha: 0.34),
                ),
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
        height: 58,
        child: Row(
          children: [
            const SizedBox(width: 18),
            Icon(
              item.icon,
              color: AppColors.primaryDark,
              size: 22,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                item.label,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0,
                ),
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.textSecondary,
              size: 22,
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
    color: AppColors.surface.withValues(alpha: 0.86),
    borderRadius: BorderRadius.circular(AppDimens.cardRadius),
    boxShadow: [
      BoxShadow(
        color: AppColors.textPrimary.withValues(alpha: 0.055),
        blurRadius: 26,
        offset: const Offset(0, 12),
      ),
      BoxShadow(
        color: Colors.white.withValues(alpha: 0.86),
        blurRadius: 0,
        spreadRadius: 0.6,
      ),
    ],
  );
}

BoxDecoration _myPageGlassDecoration({double alpha = 0.82}) {
  return BoxDecoration(
    color: AppColors.surface.withValues(alpha: alpha),
    borderRadius: BorderRadius.circular(AppDimens.cardRadius),
    boxShadow: [
      BoxShadow(
        color: AppColors.textPrimary.withValues(alpha: 0.045),
        blurRadius: 24,
        offset: const Offset(0, 10),
      ),
      BoxShadow(
        color: AppColors.primary.withValues(alpha: 0.035),
        blurRadius: 34,
        offset: const Offset(0, 16),
      ),
    ],
  );
}

Color _rarityColor(PotatoRarity rarity) {
  return switch (rarity) {
    PotatoRarity.common => const Color(0xFF7A6F5B),
    PotatoRarity.rare => const Color(0xFF56B982),
    PotatoRarity.epic => const Color(0xFF9B6CE8),
    PotatoRarity.legendary => const Color(0xFFE0A91B),
  };
}

String _rarityLabel(PotatoRarity rarity) {
  return switch (rarity) {
    PotatoRarity.common => '일반',
    PotatoRarity.rare => '희귀',
    PotatoRarity.epic => '영웅',
    PotatoRarity.legendary => '전설',
  };
}

Gradient _rarityGradient(PotatoRarity rarity) {
  return switch (rarity) {
    PotatoRarity.common => const LinearGradient(
        colors: [
          Color(0xFFE8E0D1),
          Color(0xFFB7AA95),
          Color(0xFFF7F0E2),
        ],
      ),
    PotatoRarity.rare => const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          AppColors.primary,
          Color(0xFFFFD66B),
          AppColors.primary,
        ],
      ),
    PotatoRarity.epic => const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFF7A5AF8),
          Color(0xFFF6C23E),
          AppColors.primary,
        ],
      ),
    PotatoRarity.legendary => const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFFFFF3A1),
          Color(0xFF6FE6FF),
          Color(0xFFFF91DF),
          Color(0xFFFFD66B),
        ],
      ),
  };
}

Gradient _potatoCardSurfaceGradient(PotatoRarity rarity) {
  return switch (rarity) {
    PotatoRarity.common => const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0xFFFFFCF4),
          Color(0xFFF6F0E5),
        ],
      ),
    PotatoRarity.rare => const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Colors.white,
          Color(0xFFE9FAEF),
          Color(0xFFFFF5D8),
        ],
      ),
    PotatoRarity.epic => const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFFFFFBF3),
          Color(0xFFF1EAFF),
          Color(0xFFE8F8EE),
        ],
      ),
    PotatoRarity.legendary => const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFFFFF8D9),
          Color(0xFFE9FAFF),
          Color(0xFFFFEFFA),
        ],
      ),
  };
}
