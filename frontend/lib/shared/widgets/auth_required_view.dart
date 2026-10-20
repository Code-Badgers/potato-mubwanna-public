import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';

class AuthRequiredView extends StatelessWidget {
  const AuthRequiredView({
    required this.description,
    required this.onLogin,
    super.key,
  });

  final String description;
  final VoidCallback onLogin;

  @override
  Widget build(BuildContext context) {
    final content = Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.lock_outline_rounded,
              color: AppColors.textSecondary,
              size: 44,
            ),
            const SizedBox(height: 16),
            const Text(
              '로그인이 필요한 서비스예요',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              description,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
                fontWeight: FontWeight.w700,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: onLogin,
              child: const Text('로그인하러 가기'),
            ),
          ],
        ),
      ),
    );
    // 큰 글씨/가로 화면에서도 로그인 동작이 화면 밖으로 잘리지 않게 한다.
    return LayoutBuilder(builder: (context, constraints) {
      if (!constraints.hasBoundedHeight) return content;
      return SingleChildScrollView(
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: content,
        ),
      );
    });
  }
}
