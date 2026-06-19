import 'package:flutter/material.dart';

import 'router/app_router.dart';
import 'theme/app_theme.dart';

class PotatoMubwannaApp extends StatelessWidget {
  const PotatoMubwannaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: '감자무봤나',
      theme: AppTheme.light,
      routerConfig: appRouter,
    );
  }
}
