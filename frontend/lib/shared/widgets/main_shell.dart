import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class MainShell extends StatelessWidget {
  const MainShell({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex(context),
        onDestinationSelected: (index) => context.go(_paths[index]),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.map), label: '지도'),
          NavigationDestination(icon: Icon(Icons.book), label: '랠리북'),
          NavigationDestination(icon: Icon(Icons.eco), label: '감자도감'),
          NavigationDestination(icon: Icon(Icons.redeem), label: '보상'),
          NavigationDestination(icon: Icon(Icons.person), label: '마이'),
        ],
      ),
    );
  }

  int _selectedIndex(BuildContext context) {
    final location = GoRouterState.of(context).location;
    final index = _paths.indexWhere(location.startsWith);
    return index < 0 ? 0 : index;
  }

  static const _paths = [
    '/main/map',
    '/main/stamps',
    '/main/potatoes',
    '/main/coupons',
    '/main/mypage',
  ];
}
