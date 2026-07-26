import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_colors.dart';
import '../../application/auth_controller.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(_prepareKakaoLogin);
  }

  Future<void> _prepareKakaoLogin() async {
    await ref.read(kakaoLoginServiceProvider).preload().catchError((_) {});
    if (!mounted) {
      return;
    }
    final loggedIn = await ref
        .read(authControllerProvider.notifier)
        .completePendingKakaoLogin();
    if (loggedIn && mounted) {
      context.go('/permissions');
    }
  }

  @override
  Widget build(BuildContext context) {
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
              const Spacer(flex: 4),
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 300),
                  child: AspectRatio(
                    aspectRatio: 300 / 45,
                    child: ElevatedButton(
                      onPressed: isLoading
                          ? null
                          : () async {
                              final loggedIn = await ref
                                  .read(authControllerProvider.notifier)
                                  .loginWithKakao();
                              if (loggedIn && context.mounted) {
                                context.go('/permissions');
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFEE500),
                        foregroundColor: const Color(0xFF191600),
                        elevation: 0,
                        padding: EdgeInsets.zero,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: isLoading
                          ? const SizedBox.square(
                              dimension: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                              ),
                            )
                          : const SizedBox.expand(
                              key: Key('kakao-login-button-content'),
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  Positioned(
                                    left: 14,
                                    child: Icon(
                                      Icons.chat_bubble_rounded,
                                      color: Color(0xFF191600),
                                      size: 19,
                                    ),
                                  ),
                                  Text(
                                    '카카오 로그인',
                                    style: TextStyle(
                                      color: Color(0xFF191600),
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => context.go('/permissions'),
                child: const Text('나중에 로그인하기'),
              ),
              const Spacer(),
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
