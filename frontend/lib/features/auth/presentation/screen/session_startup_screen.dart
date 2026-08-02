import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/session_startup_route_gate.dart';
import '../../../../app/theme/app_colors.dart';
import '../../application/auth_controller.dart';
import '../../application/session_startup_coordinator.dart';

class SessionStartupScreen extends ConsumerStatefulWidget {
  const SessionStartupScreen({super.key});

  @override
  ConsumerState<SessionStartupScreen> createState() =>
      _SessionStartupScreenState();
}

class _SessionStartupScreenState extends ConsumerState<SessionStartupScreen> {
  bool _isOpeningInitialRoute = false;

  Future<void> _openInitialRoute() async {
    if (_isOpeningInitialRoute) {
      return;
    }
    setState(() => _isOpeningInitialRoute = true);

    final fallbackRoute =
        await ref.read(sessionStartupCoordinatorProvider).resolveInitialRoute();
    final route = sessionStartupRouteGate.completeSessionStartup(
      fallbackRoute: fallbackRoute,
      isAuthenticated:
          ref.read(authControllerProvider).status == AuthStatus.authenticated,
    );
    if (mounted) {
      context.go(route);
    }
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
            SafeArea(
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 34),
                  child: _isOpeningInitialRoute
                      ? const SizedBox.shrink()
                      : const _BlinkingStartText(label: '터치하여 시작하기'),
                ),
              ),
            ),
          ],
        ),
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
