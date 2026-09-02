import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'main_bottom_navigation.dart';

class MainShell extends StatelessWidget {
  const MainShell({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      // Let the router close a modal, an inner page, or the previously visited
      // tab before applying the root-screen fallback below.
      canPop: Navigator.of(context).canPop(),
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          _handleRootBack(context);
        }
      },
      child: Scaffold(
        body: child,
        bottomNavigationBar: const MainBottomNavigation(),
      ),
    );
  }

  void _handleRootBack(BuildContext context) {
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
