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
      body: Image.asset(
        'assets/onboading.png',
        key: const Key('session-startup-brand-image'),
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
      ),
    );
  }
}
