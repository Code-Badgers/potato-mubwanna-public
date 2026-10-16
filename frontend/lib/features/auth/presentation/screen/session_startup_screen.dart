import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/session_startup_route_gate.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../shared/widgets/loading/potato_loading_view.dart';
import '../../../../shared/widgets/app_state_message.dart';
import '../../application/auth_controller.dart';
import '../../application/session_startup_coordinator.dart';

class SessionStartupScreen extends StatefulWidget {
  const SessionStartupScreen({super.key});

  @override
  State<SessionStartupScreen> createState() => _SessionStartupScreenState();
}

class _SessionStartupScreenState extends State<SessionStartupScreen> {
  bool _didContinue = false;

  void _openInitialRoute() {
    if (_didContinue) {
      return;
    }
    _didContinue = true;
    context.go('/startup/loading');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _openInitialRoute,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(
              'assets/onboading.png',
              key: const Key('session-startup-brand-image'),
              fit: BoxFit.cover,
            ),
            const SafeArea(
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: EdgeInsets.fromLTRB(24, 0, 24, 34),
                  child: _BlinkingStartText(label: '터치하여 시작하기'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SessionStartupLoadingScreen extends ConsumerStatefulWidget {
  const SessionStartupLoadingScreen({super.key});

  @override
  ConsumerState<SessionStartupLoadingScreen> createState() =>
      _SessionStartupLoadingScreenState();
}

class _SessionStartupLoadingScreenState
    extends ConsumerState<SessionStartupLoadingScreen> {
  bool _isResolving = false;
  bool _hasFailed = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _resolveInitialRoute());
  }

  Future<void> _resolveInitialRoute() async {
    if (_isResolving) {
      return;
    }
    _isResolving = true;
    setState(() => _hasFailed = false);
    try {
      final fallbackRoute = await ref
          .read(sessionStartupCoordinatorProvider)
          .resolveInitialRoute();
      if (!mounted) {
        return;
      }
      if (fallbackRoute == '/legal-consent') {
        context.go(fallbackRoute);
        return;
      }
      final route = sessionStartupRouteGate.completeSessionStartup(
        fallbackRoute: fallbackRoute,
        isAuthenticated:
            ref.read(authControllerProvider).status == AuthStatus.authenticated,
      );
      context.go(route);
    } catch (_) {
      if (mounted) {
        setState(() => _hasFailed = true);
      }
    } finally {
      _isResolving = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: const Key('session-startup-loading'),
      body: _hasFailed
          ? SafeArea(
              child: LayoutBuilder(builder: (context, constraints) {
                return SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints:
                        BoxConstraints(minHeight: constraints.maxHeight),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 480),
                        child: AppStateMessage(
                          icon: Icons.cloud_off_rounded,
                          title: '로그인 상태를 확인하지 못했어요',
                          description:
                              '연결 상태를 확인한 뒤 다시 시도해주세요.\n저장된 로그인 정보는 그대로 유지돼요.',
                          actionLabel: '다시 시도',
                          onAction: _resolveInitialRoute,
                        ),
                      ),
                    ),
                  ),
                );
              }),
            )
          : const PotatoLoadingView.fullScreen(
              message: '여행을 준비하고 있어요',
              subtitle: '필요한 정보는 화면이 열린 뒤에도 이어서 불러올게요',
            ),
    );
  }
}

class _BlinkingStartText extends StatefulWidget {
  const _BlinkingStartText({required this.label});

  final String label;

  @override
  State<_BlinkingStartText> createState() => _BlinkingStartTextState();
}

class _BlinkingStartTextState extends State<_BlinkingStartText>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 850),
  )..repeat(reverse: true);

  late final Animation<double> _opacity = Tween<double>(
    begin: 0.35,
    end: 1,
  ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: Text(
        widget.label,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: AppColors.textPrimary,
          fontSize: 17,
          fontWeight: FontWeight.w900,
          letterSpacing: 0,
        ),
      ),
    );
  }
}
