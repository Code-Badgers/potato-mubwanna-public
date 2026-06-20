import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';

const _couponPrimary = Color(0xFF56C787);
const _couponLine = Color(0xFFE7E1D7);
const _couponCream = Color(0xFFFFF8EA);
const _couponGold = Color(0xFFF6C23E);
const _couponBrown = Color(0xFF7A4A24);

class CouponScreen extends StatefulWidget {
  const CouponScreen({super.key});

  @override
  State<CouponScreen> createState() => _CouponScreenState();
}

class _CouponScreenState extends State<CouponScreen> {
  _CouponTab _selectedTab = _CouponTab.available;

  static const _availableCoupons = [
    _Coupon(
      title: '강원 감자 여행 상품권',
      benefit: '5,000원',
      validity: '2026. 12. 31까지',
      code: 'POTATO-GW-5000',
      accent: _couponGold,
    ),
    _Coupon(
      title: '춘천 감자전 할인쿠폰',
      benefit: '10% 할인',
      validity: '2026. 11. 30까지',
      code: 'POTATO-CC-10',
      accent: _couponPrimary,
    ),
  ];

  static const _usedCoupons = [
    _Coupon(
      title: '춘천 감자전 할인쿠폰',
      benefit: '10% 할인',
      validity: '2026. 06. 12 사용 완료',
      code: 'POTATO-CC-USED',
      accent: AppColors.textSecondary,
    ),
  ];

  List<_Coupon> get _coupons =>
      _selectedTab == _CouponTab.available ? _availableCoupons : _usedCoupons;

  void _showQrPreview(_Coupon coupon) {
    showDialog<void>(
      context: context,
      builder: (context) => _QrPreviewDialog(coupon: coupon),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            const _CouponHeader(),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: _CouponTabBar(
                selectedTab: _selectedTab,
                onChanged: (tab) => setState(() => _selectedTab = tab),
              ),
            ),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
                itemCount: _coupons.length + 1,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return _CouponSummary(
                      available: _availableCoupons.length,
                      used: _usedCoupons.length,
                    );
                  }

                  final coupon = _coupons[index - 1];
                  return _CouponCard(
                    coupon: coupon,
                    isUsed: _selectedTab == _CouponTab.used,
                    onShowQr: () => _showQrPreview(coupon),
                  );
                },
              ),
            ),
          ],
        ),
      ),
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
              letterSpacing: 0,
            ),
          ),
        ],
      ),
    );
  }
}

class _CouponTabBar extends StatelessWidget {
  const _CouponTabBar({
    required this.selectedTab,
    required this.onChanged,
  });

  final _CouponTab selectedTab;
  final ValueChanged<_CouponTab> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFF0EEE8),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(
            child: _CouponTabButton(
              label: '사용 가능 2',
              selected: selectedTab == _CouponTab.available,
              onTap: () => onChanged(_CouponTab.available),
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: _CouponTabButton(
              label: '사용 완료 1',
              selected: selectedTab == _CouponTab.used,
              onTap: () => onChanged(_CouponTab.used),
            ),
          ),
        ],
      ),
    );
  }
}

class _CouponTabButton extends StatelessWidget {
  const _CouponTabButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.surface : Colors.transparent,
      borderRadius: BorderRadius.circular(6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: selected ? AppColors.textPrimary : AppColors.textSecondary,
              fontSize: 15,
              fontWeight: FontWeight.w900,
              letterSpacing: 0,
            ),
          ),
        ),
      ),
    );
  }
}

class _CouponSummary extends StatelessWidget {
  const _CouponSummary({
    required this.available,
    required this.used,
  });

  final int available;
  final int used;

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
          Container(
            width: 44,
            height: 44,
            decoration: const BoxDecoration(
              color: Color(0xFFFFE9A5),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.redeem_rounded,
              color: _couponBrown,
              size: 24,
            ),
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
                    letterSpacing: 0,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '사용 가능 $available장 · 사용 완료 $used장',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
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

class _CouponCard extends StatelessWidget {
  const _CouponCard({
    required this.coupon,
    required this.isUsed,
    required this.onShowQr,
  });

  final _Coupon coupon;
  final bool isUsed;
  final VoidCallback onShowQr;

  @override
  Widget build(BuildContext context) {
    final muted = isUsed;
    final foreground = muted ? AppColors.textSecondary : AppColors.textPrimary;

    return Material(
      color: muted ? const Color(0xFFF4F3EF) : AppColors.surface,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border:
              Border.all(color: muted ? const Color(0xFFDEDCD5) : _couponLine),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: muted
                        ? const Color(0xFFE3E1DB)
                        : coupon.accent.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.confirmation_number_rounded,
                    color: muted ? AppColors.textSecondary : coupon.accent,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    coupon.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: foreground,
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0,
                    ),
                  ),
                ),
                _CouponStatus(isUsed: isUsed),
              ],
            ),
            const SizedBox(height: 18),
            Text(
              coupon.benefit,
              style: TextStyle(
                color: muted ? AppColors.textSecondary : _couponBrown,
                fontSize: 28,
                fontWeight: FontWeight.w900,
                letterSpacing: 0,
              ),
            ),
            const SizedBox(height: 7),
            Text(
              coupon.validity,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
                fontWeight: FontWeight.w700,
                letterSpacing: 0,
              ),
            ),
            if (!isUsed) ...[
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: onShowQr,
                  icon: const Icon(Icons.qr_code_2_rounded, size: 20),
                  label: const Text('QR 보기'),
                  style: FilledButton.styleFrom(
                    backgroundColor: _couponPrimary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                    textStyle: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _CouponStatus extends StatelessWidget {
  const _CouponStatus({required this.isUsed});

  final bool isUsed;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: isUsed ? const Color(0xFFE3E1DB) : const Color(0xFFE5F6EA),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        isUsed ? '사용 완료' : '사용 가능',
        style: TextStyle(
          color: isUsed ? AppColors.textSecondary : const Color(0xFF31764A),
          fontSize: 12,
          fontWeight: FontWeight.w900,
          letterSpacing: 0,
        ),
      ),
    );
  }
}

class _QrPreviewDialog extends StatelessWidget {
  const _QrPreviewDialog({required this.coupon});

  final _Coupon coupon;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'QR 코드',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0,
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
            const SizedBox(height: 12),
            Container(
              width: 190,
              height: 190,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: _couponLine, width: 8),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.qr_code_2_rounded,
                color: AppColors.textPrimary,
                size: 148,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              coupon.title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w900,
                letterSpacing: 0,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              coupon.validity,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
                fontWeight: FontWeight.w700,
                letterSpacing: 0,
              ),
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.textPrimary,
                  side: const BorderSide(color: _couponLine),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                  textStyle: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0,
                  ),
                ),
                child: const Text('닫기'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

enum _CouponTab { available, used }

class _Coupon {
  const _Coupon({
    required this.title,
    required this.benefit,
    required this.validity,
    required this.code,
    required this.accent,
  });

  final String title;
  final String benefit;
  final String validity;
  final String code;
  final Color accent;
}
