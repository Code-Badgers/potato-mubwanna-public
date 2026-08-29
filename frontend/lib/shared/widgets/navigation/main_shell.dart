import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'main_bottom_navigation.dart';

class MainShell extends StatelessWidget {
  const MainShell({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return BackButtonListener(
      // The main tab shell is the app's root. Keep repeated system-back
      // presses inside the app instead of letting the activity disappear.
      onBackButtonPressed: () async {
        final location = GoRouterState.of(context).location;
        if (location != '/main/map' && location.startsWith('/main/')) {
          context.go('/main/map');
          return true;
        }

        final messenger = ScaffoldMessenger.maybeOf(context);
        messenger
          ?..clearSnackBars()
          ..showSnackBar(
            const SnackBar(
              content: Text('현재 첫 화면입니다.'),
              duration: Duration(milliseconds: 1200),
            ),
          );
        return true;
      },
      child: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) {
            _handleBack(context);
          }
        },
        child: Scaffold(
          body: child,
          bottomNavigationBar: const MainBottomNavigation(),
        ),
      ),
    );
  }

  Future<void> _handleBack(BuildContext context) async {
    final location = GoRouterState.of(context).location;
    if (location != '/main/map' && location.startsWith('/main/')) {
      context.go('/main/map');
      return;
    }

    final messenger = ScaffoldMessenger.maybeOf(context);
    messenger
      ?..clearSnackBars()
      ..showSnackBar(
        const SnackBar(
          content: Text('현재 첫 화면입니다.'),
          duration: Duration(milliseconds: 1200),
        ),
      );
  }
}
