import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/admin_notice/presentation/screen/admin_notice_screen.dart';
import '../../features/auth/application/auth_controller.dart';
import '../../features/auth/application/session_startup_coordinator.dart';
import '../../features/auth/presentation/screen/login_screen.dart';
import '../../features/auth/presentation/screen/session_startup_screen.dart';
import '../../features/coupon/presentation/screen/coupon_screen.dart';
import '../../features/legal/data/legal_consent_store.dart';
import '../../features/map/presentation/screen/map_screen.dart';
import '../../features/mission/presentation/screen/mission_screen.dart';
import '../../features/mypage/presentation/screen/my_page_screen.dart';
import '../../features/legal/domain/legal_document.dart';
import '../../features/legal/domain/legal_document_catalog.dart';
import '../../features/legal/presentation/screen/legal_consent_screen.dart';
import '../../features/legal/presentation/screen/legal_document_screen.dart';
import '../../features/notice/presentation/screen/notice_screen.dart';
import '../../features/onboarding/presentation/screen/onboarding_screen.dart';
import '../../features/onboarding/presentation/screen/permission_guide_screen.dart';
import '../../features/potato/presentation/screen/potato_collection_screen.dart';
import '../../features/potato/application/potato_collection_controller.dart';
import '../../features/push/application/push_notification_service.dart';
import '../../features/spot/presentation/screen/spot_detail_screen.dart';
import '../../features/stamp/presentation/screen/stamp_book_screen.dart';
import '../../features/settings/presentation/screen/settings_screen.dart';
import '../../features/travel_record/presentation/screen/travel_record_screen.dart';
import '../../shared/widgets/navigation/main_shell.dart';
import 'session_startup_route_gate.dart';

final appRouter = GoRouter(
  initialLocation: '/startup',
  redirect: (context, state) =>
      sessionStartupRouteGate.redirectBeforeSessionStartup(state.location),
  routes: [
    GoRoute(
      path: '/startup',
      builder: (context, state) => const SessionStartupScreen(),
    ),
    GoRoute(
      path: '/legal-consent',
      builder: (context, state) => Consumer(
        builder: (context, ref, child) => LegalConsentScreen(
          consentStore: ref.read(legalConsentStoreProvider),
          requestHealthDataAccess: () async {
            await ref.read(stepCountReaderProvider).readTodaySteps();
          },
          onAccepted: () async {
            final fallbackRoute = await ref
                .read(sessionStartupCoordinatorProvider)
                .resolveInitialRouteAfterLegalConsent();
            final route = sessionStartupRouteGate.completeSessionStartup(
              fallbackRoute: fallbackRoute,
              isAuthenticated: ref.read(authControllerProvider).status ==
                  AuthStatus.authenticated,
            );
            if (context.mounted) {
              context.go(route);
            }
          },
        ),
      ),
    ),
    ..._legalDocumentRoutes(),
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
      path: '/notices',
      builder: (context, state) => const NoticeScreen(),
    ),
    GoRoute(
      path: '/admin/notices',
      builder: (context, state) => const AdminNoticeScreen(),
    ),
    GoRoute(
      path: '/settings',
      builder: (context, state) => Consumer(
        builder: (context, ref, child) {
          final isAuthenticated = ref.watch(
            authControllerProvider.select(
              (state) => state.status == AuthStatus.authenticated,
            ),
          );
          return SettingsScreen(
            pushTokenLifecycle: isAuthenticated
                ? ref.read(pushNotificationServiceProvider)
                : const NoopPushTokenLifecycle(),
            showAccountActions: isAuthenticated,
            onLogout: ref.read(authControllerProvider.notifier).logout,
            onWithdrawAccount:
                ref.read(authControllerProvider.notifier).withdrawAccount,
            authMessage: () => ref.read(authControllerProvider).message,
            onOpenLogin: () => context.go('/login'),
          );
        },
      ),
    ),
    ShellRoute(
      builder: (context, state, child) => MainShell(child: child),
      routes: [
        GoRoute(
          path: '/main/map',
          builder: (context, state) => MapScreen(
            recommendationSourceSpotId: state.queryParameters['recommendFrom'],
          ),
        ),
        GoRoute(
          path: '/main/stamps',
          builder: (context, state) => const StampBookScreen(),
        ),
        GoRoute(
          path: '/main/stamps/cities',
          builder: (context, state) => const PassportStampGridScreen(),
        ),
        GoRoute(
          path: '/main/potatoes',
          builder: (context, state) => const PotatoCollectionScreen(),
        ),
        GoRoute(
          path: '/main/missions',
          builder: (context, state) => MissionScreen(
            visitEntrySpotName: state.queryParameters['entry'] == 'visit'
                ? state.queryParameters['spotName']
                : null,
            visitEntryMissionId: state.queryParameters['entry'] == 'visit'
                ? state.queryParameters['missionId']
                : null,
          ),
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
      redirect: (context, state) => '/startup',
    ),
  ],
  errorBuilder: (context, state) => Scaffold(
    body: Center(
      child: Text(state.error?.message ?? 'Page not found'),
    ),
  ),
);

List<GoRoute> _legalDocumentRoutes() {
  return [
    _legalDocumentRoute(
      path: '/legal/service-terms',
      type: LegalDocumentType.serviceTerms,
    ),
    _legalDocumentRoute(
      path: '/legal/privacy-policy',
      type: LegalDocumentType.privacyPolicy,
    ),
    _legalDocumentRoute(
      path: '/legal/location-terms',
      type: LegalDocumentType.locationServiceTerms,
    ),
    _legalDocumentRoute(
      path: '/legal/health-data-consent',
      type: LegalDocumentType.healthDataConsent,
    ),
  ];
}

GoRoute _legalDocumentRoute({
  required String path,
  required LegalDocumentType type,
}) {
  return GoRoute(
    path: path,
    builder: (context, state) => Consumer(
      builder: (context, ref, child) => LegalDocumentScreen(
        document: LegalDocumentCatalog.document(type),
        manageConsent: state.queryParameters['manage'] == 'true',
        returnOnAccept: state.queryParameters['returnOnAccept'] == 'true',
        consentStore: ref.read(legalConsentStoreProvider),
        onConsentChanged: () async {
          if (ref.read(authControllerProvider).status !=
              AuthStatus.authenticated) {
            return;
          }
          try {
            await ref.read(legalConsentSyncServiceProvider).synchronize();
          } catch (_) {
            // 로컬 철회는 즉시 적용하고 서버는 다음 세션에서 다시 동기화한다.
          }
        },
      ),
    ),
  );
}
