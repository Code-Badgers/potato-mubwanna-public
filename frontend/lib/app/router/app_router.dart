import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/screen/login_screen.dart';
import '../../features/coupon/presentation/screen/coupon_screen.dart';
import '../../features/map/presentation/screen/map_screen.dart';
import '../../features/mission/presentation/screen/mission_screen.dart';
import '../../features/mypage/presentation/screen/my_page_screen.dart';
import '../../features/onboarding/presentation/screen/onboarding_screen.dart';
import '../../features/onboarding/presentation/screen/permission_guide_screen.dart';
import '../../features/potato/presentation/screen/potato_collection_screen.dart';
import '../../features/spot/presentation/screen/spot_detail_screen.dart';
import '../../features/stamp/presentation/screen/stamp_book_screen.dart';
import '../../features/settings/presentation/screen/settings_screen.dart';
import '../../features/travel_record/presentation/screen/travel_record_screen.dart';
import '../../shared/widgets/navigation/main_shell.dart';

final appRouter = GoRouter(
  initialLocation: '/onboarding',
  routes: [
    GoRoute(
      path: '/onboarding',
      builder: (context, state) => const OnboardingScreen(),
    ),
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/permissions',
      builder: (context, state) => const PermissionGuideScreen(),
    ),
    GoRoute(
      path: '/coupons',
      builder: (context, state) => const CouponScreen(),
    ),
    GoRoute(
      path: '/travel-records',
      builder: (context, state) => const TravelRecordScreen(),
    ),
    GoRoute(
      path: '/settings',
      builder: (context, state) => SettingsScreen(),
    ),
    ShellRoute(
      builder: (context, state, child) => MainShell(child: child),
      routes: [
        GoRoute(
          path: '/main/map',
          builder: (context, state) => const MapScreen(),
        ),
        GoRoute(
          path: '/main/stamps',
          builder: (context, state) => const StampBookScreen(),
        ),
        GoRoute(
          path: '/main/potatoes',
          builder: (context, state) => const PotatoCollectionScreen(),
        ),
        GoRoute(
          path: '/main/missions',
          builder: (context, state) => const MissionScreen(),
        ),
        GoRoute(
          path: '/main/mypage',
          builder: (context, state) => const MyPageScreen(),
        ),
      ],
    ),
    GoRoute(
      path: '/main',
      redirect: (context, state) => '/main/map',
    ),
    GoRoute(
      path: '/spots/:spotId',
      builder: (context, state) {
        final spotId = state.pathParameters['spotId']!;
        return SpotDetailScreen(spotId: spotId);
      },
    ),
    GoRoute(
      path: '/',
      redirect: (context, state) => '/onboarding',
    ),
  ],
  errorBuilder: (context, state) => Scaffold(
    body: Center(
      child: Text(state.error?.message ?? 'Page not found'),
    ),
  ),
);
