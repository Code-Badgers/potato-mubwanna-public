import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../shared/widgets/auth_required_view.dart';
import '../../../auth/application/auth_controller.dart';
import '../../../reward/application/reward_history_controller.dart';
import '../../../reward/domain/reward_history.dart';
import '../../application/coupon_controller.dart';
import '../../domain/coupon.dart';

const _couponPrimary = Color(0xFF56C787);
const _couponLine = Color(0xFFE7E1D7);
const _couponCream = Color(0xFFFFF8EA);
const _couponGold = Color(0xFFF6C23E);
const _couponBrown = Color(0xFF7A4A24);

class CouponScreen extends ConsumerWidget {
  const CouponScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authStatus = ref.watch(authControllerProvider).status;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            const _CouponHeader(),
            Expanded(
              child: switch (authStatus) {
                AuthStatus.authenticated => const _RewardBox(),
                AuthStatus.loading => const Center(
                    child: CircularProgressIndicator(),
                  ),
                AuthStatus.idle || AuthStatus.failure => AuthRequiredView(
                    description: '보상함을 확인하려면 로그인해주세요.',
                    onLogin: () => context.go('/login'),
                  ),
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _RewardBox extends StatefulWidget {
  const _RewardBox();

  @override
  State<_RewardBox> createState() => _RewardBoxState();
}

class _RewardBoxState extends State<_RewardBox> {
  _RewardBoxSection _selectedSection = _RewardBoxSection.coupons;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
          child: _RewardBoxSectionBar(
            selectedSection: _selectedSection,
            onChanged: (section) => setState(() => _selectedSection = section),
          ),
        ),
        Expanded(
          child: switch (_selectedSection) {
            _RewardBoxSection.coupons => const _CouponInbox(),
            _RewardBoxSection.history => const _RewardHistoryInbox(),
          },
        ),
      ],
    );
  }
}

class _RewardBoxSectionBar extends StatelessWidget {
  const _RewardBoxSectionBar({
    required this.selectedSection,
    required this.onChanged,
  });

  final _RewardBoxSection selectedSection;
  final ValueChanged<_RewardBoxSection> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 48),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F4EB),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(
            child: _SegmentButton(
              key: const ValueKey('reward-box-coupon-tab'),
              label: '쿠폰',
              selected: selectedSection == _RewardBoxSection.coupons,
              onTap: () => onChanged(_RewardBoxSection.coupons),
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: _SegmentButton(
              key: const ValueKey('reward-box-history-tab'),
              label: '보상 내역',
              selected: selectedSection == _RewardBoxSection.history,
              onTap: () => onChanged(_RewardBoxSection.history),
            ),
          ),
        ],
      ),
    );
  }
}

class _CouponInbox extends ConsumerStatefulWidget {
  const _CouponInbox();

  @override
  ConsumerState<_CouponInbox> createState() => _CouponInboxState();
}

class _CouponInboxState extends ConsumerState<_CouponInbox> {
  _CouponTab _selectedTab = _CouponTab.available;

  @override
  Widget build(BuildContext context) {
    final coupons = ref.watch(couponListProvider);

    return coupons.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) =>
          _CouponError(onRetry: () => ref.invalidate(couponListProvider)),
      data: (value) {
        final allCoupons = value ?? const <CouponSummary>[];
        final available = allCoupons
            .where((coupon) => coupon.status == CouponStatus.available)
            .toList(growable: false);
        final completed = allCoupons
            .where((coupon) => coupon.status != CouponStatus.available)
            .toList(growable: false);
        final selected =
            _selectedTab == _CouponTab.available ? available : completed;

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: _CouponTabBar(
                selectedTab: _selectedTab,
                availableCount: available.length,
                completedCount: completed.length,
                onChanged: (tab) => setState(() => _selectedTab = tab),
              ),
            ),
            Expanded(
              child: selected.isEmpty
                  ? _CouponEmpty(tab: _selectedTab)
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
                      itemCount: selected.length + 1,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        if (index == 0) {
                          return _CouponSummaryCard(
                            available: available.length,
                            completed: completed.length,
                          );
                        }
                        final coupon = selected[index - 1];
                        return _CouponCard(
                          key: ValueKey('coupon-${coupon.userCouponId}'),
                          coupon: coupon,
                          onTap: () =>
                              _showCouponDetail(context, coupon.userCouponId),
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showCouponDetail(BuildContext context, int userCouponId) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _CouponDetailSheet(userCouponId: userCouponId),
    );
  }
}

class _CouponHeader extends StatelessWidget {
  const _CouponHeader();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.fromLTRB(24, 18, 24, 10),
      child: Row(
        children: [
          Icon(Icons.card_giftcard_rounded, color: _couponGold, size: 30),
          SizedBox(width: 10),
          Text(
            '보상함',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 28,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _RewardHistoryInbox extends ConsumerWidget {
  const _RewardHistoryInbox();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final history = ref.watch(rewardHistoryProvider);

    return history.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => _RewardHistoryError(
        onRetry: () => ref.invalidate(rewardHistoryProvider),
      ),
      data: (value) {
        final rewards = value ?? const <RewardHistory>[];
        if (rewards.isEmpty) {
          return const _RewardHistoryEmpty();
        }

        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
          itemCount: rewards.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final reward = rewards[index];
            return _RewardHistoryCard(
              key: ValueKey('reward-history-${reward.rewardHistoryId}'),
              reward: reward,
            );
          },
        );
      },
    );
  }
}

class _RewardHistoryCard extends StatelessWidget {
  const _RewardHistoryCard({super.key, required this.reward});

  final RewardHistory reward;

  @override
  Widget build(BuildContext context) {
    final (icon, color) = switch (reward.rewardType) {
      RewardType.potato => (
          Icons.agriculture_rounded,
          const Color(0xFF9A642D),
        ),
      RewardType.coupon => (
          Icons.confirmation_number_rounded,
          _couponPrimary,
        ),
      RewardType.item => (
          Icons.inventory_2_rounded,
          const Color(0xFF6C63A8),
        ),
      RewardType.coin => (
          Icons.monetization_on_rounded,
          _couponGold,
        ),
    };

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _couponLine),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            backgroundColor: color.withAlpha(36),
            foregroundColor: color,
            child: Icon(icon, size: 21),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  reward.rewardName,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    _RewardHistoryChip(
                      label: reward.rewardType.label,
                      color: color,
                    ),
                    _RewardHistoryChip(
                      label: reward.sourceType.label,
                      color: AppColors.textSecondary,
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  '${_formatDateTime(reward.createdAt)} 지급',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
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

class _RewardHistoryChip extends StatelessWidget {
  const _RewardHistoryChip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha(26),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _CouponTabBar extends StatelessWidget {
  const _CouponTabBar({
    required this.selectedTab,
    required this.availableCount,
    required this.completedCount,
    required this.onChanged,
  });

  final _CouponTab selectedTab;
  final int availableCount;
  final int completedCount;
  final ValueChanged<_CouponTab> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 48),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFF0EEE8),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(
            child: _SegmentButton(
              label: '사용 가능 $availableCount',
              selected: selectedTab == _CouponTab.available,
              onTap: () => onChanged(_CouponTab.available),
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: _SegmentButton(
              label: '사용 완료 $completedCount',
              selected: selectedTab == _CouponTab.completed,
              onTap: () => onChanged(_CouponTab.completed),
            ),
          ),
        ],
      ),
    );
  }
}

class _SegmentButton extends StatelessWidget {
  const _SegmentButton({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      child: Material(
        color: selected ? AppColors.surface : Colors.transparent,
        borderRadius: BorderRadius.circular(6),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(6),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
            child: Center(
              child: Text(
                label,
                style: TextStyle(
                  color: selected
                      ? AppColors.textPrimary
                      : AppColors.textSecondary,
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CouponSummaryCard extends StatelessWidget {
  const _CouponSummaryCard({required this.available, required this.completed});

  final int available;
  final int completed;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _couponCream,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFF0DBA2)),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            backgroundColor: Color(0xFFFFE9A5),
            child: Icon(Icons.redeem_rounded, color: _couponBrown),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '여행 중 받은 보상',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '사용 가능 $available장 · 사용 완료 $completed장',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
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

class _CouponCard extends StatelessWidget {
  const _CouponCard({
    super.key,
    required this.coupon,
    required this.onTap,
  });

  final CouponSummary coupon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final available = coupon.status == CouponStatus.available;

    return Material(
      color: available ? AppColors.surface : const Color(0xFFF4F3EF),
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: _couponLine),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.confirmation_number_rounded,
                    color: available ? _couponPrimary : AppColors.textSecondary,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      coupon.name,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  _CouponStatusChip(status: coupon.status),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                _formatAmount(coupon.benefitAmount),
                style: TextStyle(
                  color: available ? _couponBrown : AppColors.textSecondary,
                  fontSize: 27,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '${_formatDate(coupon.expiresAt)}까지',
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CouponStatusChip extends StatelessWidget {
  const _CouponStatusChip({required this.status});

  final CouponStatus status;

  @override
  Widget build(BuildContext context) {
    final (label, background, foreground) = switch (status) {
      CouponStatus.available => (
          '사용 가능',
          const Color(0xFFE5F6EA),
          const Color(0xFF31764A),
        ),
      CouponStatus.used => (
          '사용 완료',
          const Color(0xFFE3E1DB),
          AppColors.textSecondary,
        ),
      CouponStatus.expired => (
          '기간 만료',
          const Color(0xFFF4E4E1),
          AppColors.error,
        ),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: foreground,
          fontSize: 12,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _CouponDetailSheet extends ConsumerWidget {
  const _CouponDetailSheet({required this.userCouponId});

  final int userCouponId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detail = ref.watch(couponDetailProvider(userCouponId));
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 28),
        child: detail.when(
          loading: () => const SizedBox(
            height: 260,
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (_, __) => SizedBox(
            height: 260,
            child: _CouponError(
              onRetry: () => ref.invalidate(couponDetailProvider(userCouponId)),
            ),
          ),
          data: (coupon) => Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      '쿠폰 상세',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: '닫기',
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                coupon.name,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 19,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                coupon.description,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 20),
              _DetailRow(
                label: '혜택',
                value: _formatAmount(coupon.benefitAmount),
              ),
              _DetailRow(label: '사용처', value: coupon.usagePlace),
              _DetailRow(
                label: '발급일',
                value: '${_formatDate(coupon.issuedAt)} 발급',
              ),
              _DetailRow(
                label: '유효기간',
                value: '${_formatDate(coupon.expiresAt)}까지',
              ),
              if (coupon.usedAt != null)
                _DetailRow(
                  label: '사용일',
                  value: '${_formatDate(coupon.usedAt!)} 사용',
                ),
              if (coupon.status == CouponStatus.available) ...[
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () => showDialog<void>(
                      context: context,
                      barrierDismissible: false,
                      builder: (_) => _CouponQrDialog(
                        userCouponId: userCouponId,
                      ),
                    ),
                    icon: const Icon(Icons.qr_code_2_rounded),
                    label: const Text('QR 코드 보기'),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _CouponQrDialog extends ConsumerStatefulWidget {
  const _CouponQrDialog({required this.userCouponId});

  final int userCouponId;

  @override
  ConsumerState<_CouponQrDialog> createState() => _CouponQrDialogState();
}

class _CouponQrDialogState extends ConsumerState<_CouponQrDialog> {
  bool _isUsing = false;
  String? _useError;

  @override
  Widget build(BuildContext context) {
    final qr = ref.watch(couponQrProvider(widget.userCouponId));

    return AlertDialog(
      title: Row(
        children: [
          const Expanded(child: Text('쿠폰 QR')),
          IconButton(
            tooltip: 'QR 새로고침',
            onPressed: _isUsing
                ? null
                : () => ref.invalidate(
                      couponQrProvider(widget.userCouponId),
                    ),
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      content: SizedBox(
        width: 280,
        child: qr.when(
          loading: () => const SizedBox(
            height: 280,
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (_, __) => SizedBox(
            height: 220,
            child: _CouponError(
              onRetry: () => ref.invalidate(
                couponQrProvider(widget.userCouponId),
              ),
            ),
          ),
          data: (value) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              QrImageView(
                data: value.payload,
                size: 220,
                backgroundColor: Colors.white,
                semanticsLabel: '쿠폰 사용 QR 코드',
              ),
              const SizedBox(height: 12),
              Text(
                '${_formatDateTime(value.expiresAt)}까지 유효',
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                '현장에서 직원 확인 후 사용 완료를 눌러주세요.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                ),
              ),
              if (_useError != null) ...[
                const SizedBox(height: 8),
                Text(
                  _useError!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.error, fontSize: 12),
                ),
              ],
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _isUsing ? null : () => _confirmAndUse(value),
                  child: _isUsing
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('사용 완료 처리'),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isUsing ? null : () => Navigator.of(context).pop(),
          child: const Text('닫기'),
        ),
      ],
    );
  }

  Future<void> _confirmAndUse(CouponQr qr) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('쿠폰을 사용하시겠어요?'),
        content: const Text('사용 완료 후에는 되돌릴 수 없습니다.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('사용하기'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await _useCoupon(qr);
    }
  }

  Future<void> _useCoupon(CouponQr qr) async {
    setState(() {
      _isUsing = true;
      _useError = null;
    });
    try {
      await ref
          .read(couponRepositoryProvider)
          .useCoupon(widget.userCouponId, qr.payload);
      ref.invalidate(couponListProvider);
      ref.invalidate(couponDetailProvider(widget.userCouponId));
      ref.invalidate(couponQrProvider(widget.userCouponId));
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isUsing = false;
          _useError = '쿠폰 사용 처리에 실패했습니다. 다시 시도해주세요.';
        });
      }
    }
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 72,
            child: Text(
              label,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CouponEmpty extends StatelessWidget {
  const _CouponEmpty({required this.tab});

  final _CouponTab tab;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        tab == _CouponTab.available
            ? '사용 가능한 쿠폰이 없어요.'
            : '사용 완료 또는 만료된 쿠폰이 없어요.',
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: AppColors.textSecondary,
          fontSize: 15,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _RewardHistoryEmpty extends StatelessWidget {
  const _RewardHistoryEmpty();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Text(
          '아직 받은 보상이 없어요.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _RewardHistoryError extends StatelessWidget {
  const _RewardHistoryError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            '보상 내역을 불러오지 못했습니다.',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton(onPressed: onRetry, child: const Text('다시 시도')),
        ],
      ),
    );
  }
}

class _CouponError extends StatelessWidget {
  const _CouponError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            '쿠폰을 불러오지 못했습니다.',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton(onPressed: onRetry, child: const Text('다시 시도')),
        ],
      ),
    );
  }
}

String _formatAmount(int amount) {
  final value = amount.toString().replaceAllMapped(
        RegExp(r'\B(?=(\d{3})+(?!\d))'),
        (_) => ',',
      );
  return '$value원';
}

String _formatDate(DateTime date) {
  final local = date.toLocal();
  final month = local.month.toString().padLeft(2, '0');
  final day = local.day.toString().padLeft(2, '0');
  return '${local.year}. $month. $day.';
}

String _formatDateTime(DateTime date) {
  final local = date.toLocal();
  final hour = local.hour.toString().padLeft(2, '0');
  final minute = local.minute.toString().padLeft(2, '0');
  return '${_formatDate(local)} $hour:$minute';
}

enum _RewardBoxSection { coupons, history }

enum _CouponTab { available, completed }
