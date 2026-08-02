import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/network/api_exception.dart';
import '../../application/stamp_book_controller.dart';
import '../../domain/stamp_book.dart';

class StampBookScreen extends ConsumerWidget {
  const StampBookScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stampBook = ref.watch(stampBookProvider);
    final nextTargets = ref.watch(stampNextTargetsProvider);
    final claimState = ref.watch(stampRewardClaimProvider);
    ref.listen(stampRewardClaimProvider, (_, next) {
      next.whenOrNull(
        data: (result) {
          if (result == null) {
            return;
          }
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(
              const SnackBar(content: Text('보상 수령이 완료됐어요. 쿠폰함에서 확인해 주세요.')),
            );
        },
        error: (error, _) {
          final message = error is ApiException && error.message.isNotEmpty
              ? error.message
              : '보상을 받지 못했습니다. 잠시 후 다시 시도해 주세요.';
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(SnackBar(content: Text(message)));
        },
      );
    });

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: stampBook.when(
          data: (value) => value == null
              ? const _SignedOutState()
              : _StampBookBody(
                  stampBook: value,
                  nextTargets: nextTargets,
                  isClaiming: claimState.isLoading,
                  onClaim: (targetCount) => ref
                      .read(stampRewardClaimProvider.notifier)
                      .claim(targetCount),
                  onRetryTargets: () =>
                      ref.invalidate(stampNextTargetsProvider),
                ),
          loading: () => const _StampBookStatusBody(
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (_, __) => _StampBookStatusBody(
            child: _StampBookError(
              onRetry: () => ref.invalidate(stampBookProvider),
            ),
          ),
        ),
      ),
    );
  }
}

class _StampBookStatusBody extends StatelessWidget {
  const _StampBookStatusBody({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        const SliverToBoxAdapter(child: _StampHeader()),
        SliverFillRemaining(hasScrollBody: false, child: child),
      ],
    );
  }
}

class _StampBookBody extends StatelessWidget {
  const _StampBookBody({
    required this.stampBook,
    required this.nextTargets,
    required this.isClaiming,
    required this.onClaim,
    required this.onRetryTargets,
  });

  final StampBook stampBook;
  final AsyncValue<List<StampNextTarget>?> nextTargets;
  final bool isClaiming;
  final ValueChanged<int> onClaim;
  final VoidCallback onRetryTargets;

  @override
  Widget build(BuildContext context) {
    final progress = stampBook.progress;
    final reward = stampBook.nextReward;

    return CustomScrollView(
      slivers: [
        const SliverToBoxAdapter(child: _StampHeader()),
        SliverToBoxAdapter(
          child: _ProgressSummary(
            acquiredCount: progress.acquiredCount,
            totalCount: progress.totalCount,
            reward: reward,
          ),
        ),
        SliverToBoxAdapter(
          child: _NextTargetsSection(
            state: nextTargets,
            completed: reward.completed,
            onRetry: onRetryTargets,
            onTargetTap: (target) => context.push('/spots/${target.spotId}'),
          ),
        ),
        const SliverToBoxAdapter(child: _SectionTitle(title: '시군별 스탬프')),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 18),
          sliver: SliverGrid.builder(
            itemCount: progress.stamps.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 0.92,
            ),
            itemBuilder: (context, index) {
              return _StampTile(stamp: progress.stamps[index]);
            },
          ),
        ),
        SliverToBoxAdapter(
          child: _RewardCard(
            reward: reward,
            isClaiming: isClaiming,
            onClaim: onClaim,
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 24)),
      ],
    );
  }
}

class _StampHeader extends StatelessWidget {
  const _StampHeader();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(height: 18);
  }
}

class _ProgressSummary extends StatelessWidget {
  const _ProgressSummary({
    required this.acquiredCount,
    required this.totalCount,
    required this.reward,
  });

  final int acquiredCount;
  final int totalCount;
  final NextStampReward reward;

  @override
  Widget build(BuildContext context) {
    final progress = totalCount == 0 ? 0.0 : acquiredCount / totalCount;
    final targetCount = reward.nextTargetCount;
    final rewardMessage = reward.canClaim
        ? '${reward.claimableTargetCount}개 달성 보상을 받을 수 있어요'
        : reward.completed || targetCount == null
            ? '모든 보상 기준을 달성했어요'
            : '$targetCount개 달성까지 ${reward.remainingCount}개 남았어요';

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 18),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.line),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Expanded(
                child: Text(
                  '수집률',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0,
                  ),
                ),
              ),
              Text(
                '$acquiredCount / $totalCount',
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              minHeight: 12,
              value: progress.clamp(0, 1),
              backgroundColor: AppColors.primaryTint,
              valueColor:
                  const AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              const Icon(
                Icons.card_giftcard_rounded,
                color: AppColors.secondary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  rewardMessage,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _NextTargetsSection extends StatelessWidget {
  const _NextTargetsSection({
    required this.state,
    required this.completed,
    required this.onRetry,
    required this.onTargetTap,
  });

  final AsyncValue<List<StampNextTarget>?> state;
  final bool completed;
  final VoidCallback onRetry;
  final ValueChanged<StampNextTarget> onTargetTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 18),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.explore_rounded,
                  color: AppColors.primaryDark, size: 24),
              SizedBox(width: 8),
              Text(
                '다음 목표',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0,
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          const Text(
            '아직 스탬프가 없는 지역부터 추천해요.',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 14),
          state.when(
            loading: () => const _NextTargetStatus(
              key: ValueKey('stamp-next-target-loading'),
              icon: Icons.hourglass_top_rounded,
              message: '다음 목표를 찾고 있어요.',
            ),
            error: (_, __) => _NextTargetError(onRetry: onRetry),
            data: (targets) {
              if (targets == null) {
                return const SizedBox.shrink();
              }
              if (targets.isEmpty) {
                return _NextTargetStatus(
                  key: const ValueKey('stamp-next-target-empty'),
                  icon: completed
                      ? Icons.emoji_events_rounded
                      : Icons.location_off_rounded,
                  message:
                      completed ? '모든 지역 스탬프를 모았어요.' : '추천 가능한 스탬프 관광지가 없어요.',
                );
              }
              return Column(
                children: [
                  for (var index = 0; index < targets.length; index++) ...[
                    _NextTargetTile(
                      target: targets[index],
                      onTap: () => onTargetTap(targets[index]),
                    ),
                    if (index < targets.length - 1) const SizedBox(height: 10),
                  ],
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _NextTargetTile extends StatelessWidget {
  const _NextTargetTile({required this.target, required this.onTap});

  final StampNextTarget target;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        key: ValueKey('stamp-next-target-${target.spotId}'),
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.line),
          ),
          child: Row(
            children: [
              _NextTargetThumbnail(imageUrl: target.imageUrl),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      target.spotName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${target.cityName} · ${target.categoryLabel}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right_rounded,
                  color: AppColors.primaryDark),
            ],
          ),
        ),
      ),
    );
  }
}

class _NextTargetThumbnail extends StatelessWidget {
  const _NextTargetThumbnail({required this.imageUrl});

  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    final url = imageUrl?.trim();
    if (url == null || url.isEmpty) {
      return const _NextTargetPlaceholder();
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(9),
      child: Image.network(
        url,
        width: 48,
        height: 48,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => const _NextTargetPlaceholder(),
      ),
    );
  }
}

class _NextTargetPlaceholder extends StatelessWidget {
  const _NextTargetPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: AppColors.cream,
        borderRadius: BorderRadius.circular(9),
      ),
      child:
          const Icon(Icons.location_on_rounded, color: AppColors.primaryDark),
    );
  }
}

class _NextTargetStatus extends StatelessWidget {
  const _NextTargetStatus({
    super.key,
    required this.icon,
    required this.message,
  });

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: AppColors.primaryDark, size: 20),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            message,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }
}

class _NextTargetError extends StatelessWidget {
  const _NextTargetError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Row(
      key: const ValueKey('stamp-next-target-error'),
      children: [
        const Expanded(
          child: Text(
            '다음 목표를 불러오지 못했어요.',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        TextButton(
          key: const ValueKey('stamp-next-target-retry'),
          onPressed: onRetry,
          child: const Text('다시 시도'),
        ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 2, 20, 12),
      child: Text(
        title,
        style: const TextStyle(
          color: AppColors.textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w900,
          letterSpacing: 0,
        ),
      ),
    );
  }
}

class _StampTile extends StatelessWidget {
  const _StampTile({required this.stamp});

  final RallybookStamp stamp;

  @override
  Widget build(BuildContext context) {
    final foreground =
        stamp.acquired ? AppColors.textPrimary : AppColors.textSecondary;
    final borderColor = stamp.acquired ? AppColors.primary : AppColors.line;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: borderColor, width: stamp.acquired ? 1.6 : 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: stamp.acquired
                    ? AppColors.primaryTint
                    : const Color(0xFFF1F1EC),
                shape: BoxShape.circle,
              ),
              child: Icon(
                stamp.acquired
                    ? Icons.check_rounded
                    : Icons.lock_outline_rounded,
                color: stamp.acquired
                    ? AppColors.primaryDark
                    : AppColors.textSecondary,
                size: stamp.acquired ? 26 : 22,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              stamp.cityName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: foreground,
                fontSize: 15,
                fontWeight: FontWeight.w900,
                letterSpacing: 0,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              stamp.acquired ? stamp.stampName : '미획득',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RewardCard extends StatelessWidget {
  const _RewardCard({
    required this.reward,
    required this.isClaiming,
    required this.onClaim,
  });

  final NextStampReward reward;
  final bool isClaiming;
  final ValueChanged<int> onClaim;

  @override
  Widget build(BuildContext context) {
    final targetCount = reward.nextTargetCount;
    final claimableTargetCount = reward.claimableTargetCount;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 0),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.cream,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.line),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: const BoxDecoration(
              color: AppColors.surface,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.card_giftcard_rounded,
              color: AppColors.secondary,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  reward.canClaim ? '받을 수 있는 보상' : '다음 보상',
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0,
                  ),
                ),
                const SizedBox(height: 4),
                if (reward.canClaim && claimableTargetCount != null) ...[
                  Text(
                    '$claimableTargetCount개 달성 보상이 준비됐어요.',
                    style: const TextStyle(
                      color: AppColors.primaryDark,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0,
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      key: const ValueKey('stamp-reward-claim-button'),
                      onPressed: isClaiming
                          ? null
                          : () => onClaim(claimableTargetCount),
                      child: isClaiming
                          ? const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                ),
                                SizedBox(width: 8),
                                Text('보상 받는 중...'),
                              ],
                            )
                          : Text('$claimableTargetCount개 보상 받기'),
                    ),
                  ),
                ] else if (reward.completed || targetCount == null)
                  const Text(
                    '18개 시군 랠리를 모두 완주했어요.',
                    style: TextStyle(
                      color: AppColors.primaryDark,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0,
                    ),
                  )
                else ...[
                  Text(
                    '$targetCount개 달성 시 지역쿠폰 지급',
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0,
                    ),
                  ),
                  Text(
                    '앞으로 ${reward.remainingCount}개만 더 모으면 받을 수 있어요.',
                    style: const TextStyle(
                      color: AppColors.primaryDark,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StampBookError extends StatelessWidget {
  const _StampBookError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              color: AppColors.textSecondary,
              size: 36,
            ),
            const SizedBox(height: 12),
            const Text(
              '랠리북을 불러오지 못했습니다.',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 12),
            FilledButton(onPressed: onRetry, child: const Text('다시 시도')),
          ],
        ),
      ),
    );
  }
}

class _SignedOutState extends StatelessWidget {
  const _SignedOutState();

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        _StampHeader(),
        Expanded(
          child: Center(
            child: Text(
              '로그인 후 랠리북을 확인할 수 있어요.',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
