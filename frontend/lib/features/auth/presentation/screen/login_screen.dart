import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_colors.dart';
import '../../application/auth_controller.dart';

class LoginScreen extends ConsumerWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authControllerProvider);
    final isLoading = authState.status == AuthStatus.loading;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('로그인')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 36),
              Text(
                '감자 여행을 시작해볼까요?',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0,
                    ),
              ),
              const SizedBox(height: 12),
              const Text(
                '방문 인증, 스탬프 수집, 감자 성장을 위해 계정 연결이 필요합니다.',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 15,
                  height: 1.45,
                  letterSpacing: 0,
                ),
              ),
              if (authState.status == AuthStatus.failure) ...[
                const SizedBox(height: 18),
                _LoginMessage(message: authState.message ?? '로그인에 실패했습니다.'),
              ],
              const Spacer(),
              SizedBox(
                height: 54,
                child: ElevatedButton(
                  onPressed: isLoading
                      ? null
                      : () async {
                          final loggedIn = await ref
                              .read(authControllerProvider.notifier)
                              .loginWithKakao();
                          if (loggedIn && context.mounted) {
                            context.go('/main/map');
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: EdgeInsets.zero,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: isLoading
                      ? const SizedBox.square(
                          dimension: 20,
                          child: CircularProgressIndicator(strokeWidth: 2.5),
                        )
                      : Ink(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            image: const DecorationImage(
                              image: AssetImage(
                                'assets/kakao_login_button.png',
                              ),
                              fit: BoxFit.cover,
                            ),
                          ),
                          child: Container(
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              color: const Color(0xFF191600)
                                  .withValues(alpha: 0.38),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 24,
                                  height: 24,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFEE500),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Text(
                                    'K',
                                    style: TextStyle(
                                      color: Color(0xFF191600),
                                      fontSize: 14,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 0,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                const Text(
                                  '카카오 로그인',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => context.go('/main/map'),
                child: const Text('나중에 로그인하기'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LoginMessage extends StatelessWidget {
  const _LoginMessage({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.18)),
      ),
      child: Text(
        message,
        style: const TextStyle(
          color: AppColors.error,
          fontSize: 14,
          height: 1.4,
          letterSpacing: 0,
        ),
      ),
    );
  }
}
