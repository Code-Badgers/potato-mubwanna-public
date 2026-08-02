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
  @override
  void initState() {
    super.initState();
    Future.microtask(_openInitialRoute);
  }

  Future<void> _openInitialRoute() async {
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
      body: Stack(
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
                padding: const EdgeInsets.only(bottom: 42),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: AppColors.surface.withValues(alpha: 0.82),
                    shape: BoxShape.circle,
                  ),
                  child: const SizedBox.square(
                    dimension: 46,
                    child: Padding(
                      padding: EdgeInsets.all(10),
                      child: CircularProgressIndicator(
                        key: Key('session-startup-progress'),
                        strokeWidth: 3,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
