import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../shared/widgets/auth_required_view.dart';
import '../../../auth/application/auth_controller.dart';

const _couponGold = Color(0xFFF6C23E);

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
                AuthStatus.authenticated => const _CouponPreparationState(),
                AuthStatus.loading =>
                  const Center(child: CircularProgressIndicator()),
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

class _CouponPreparationState extends StatelessWidget {
  const _CouponPreparationState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Text(
          '보상 데이터 연동을 준비하고 있어요.',
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
