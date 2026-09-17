import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../onboarding/data/onboarding_status_store.dart';
import '../../../onboarding/presentation/screen/onboarding_screen.dart';
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
    Future.microtask(_completePendingKakaoLogin);
  }

  Future<void> _completePendingKakaoLogin() async {
    // 웹 OAuth가 돌아오는 경로는 유지하고, 별도 로그인 소개 화면만 없앤다.
    final loggedIn = await ref
        .read(authControllerProvider.notifier)
        .completePendingKakaoLogin();
    if (!loggedIn || !mounted) {
      return;
    }
    try {
      await ref.read(onboardingStatusStoreProvider).markOnboardingCompleted();
    } catch (_) {
      // 설정 저장 실패가 로그인 완료 흐름을 막지 않게 한다.
    }
    if (mounted) {
      context.go('/permissions');
    }
  }

  @override
  Widget build(BuildContext context) {
    return const OnboardingScreen(initialPage: 3);
  }
}
