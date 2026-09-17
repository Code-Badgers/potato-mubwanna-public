import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/auth/application/auth_controller.dart';
import '../features/push/domain/push_message.dart';
import 'router/app_router.dart';
import 'theme/app_theme.dart';

class PotatoMubwannaApp extends ConsumerStatefulWidget {
  const PotatoMubwannaApp({super.key});

  @override
  ConsumerState<PotatoMubwannaApp> createState() => _PotatoMubwannaAppState();
}

class _PotatoMubwannaAppState extends ConsumerState<PotatoMubwannaApp>
    with WidgetsBindingObserver {
  final _scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

  StreamSubscription<PushMessage>? _foregroundMessageSubscription;
  StreamSubscription<PushMessage>? _openedMessageSubscription;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    final pushNotifications = ref.read(pushNotificationServiceProvider);
    _foregroundMessageSubscription =
        pushNotifications.foregroundMessages.listen(_showForegroundMessage);
    _openedMessageSubscription =
        pushNotifications.openedMessages.listen(_openPushMessage);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    unawaited(_foregroundMessageSubscription?.cancel());
    unawaited(_openedMessageSubscription?.cancel());
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed ||
        ref.read(authControllerProvider).status != AuthStatus.authenticated) {
      return;
    }
    unawaited(_synchronizePushToken());
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AuthState>(authControllerProvider, (previous, next) {
      if (previous?.status == AuthStatus.authenticated &&
          next.status != AuthStatus.authenticated) {
        // 이전 계정의 알림이 로그아웃 뒤 온보딩 화면에 남지 않게 한다.
        _scaffoldMessengerKey.currentState?.clearSnackBars();
      }
    });

    return MaterialApp.router(
      scaffoldMessengerKey: _scaffoldMessengerKey,
      debugShowCheckedModeBanner: false,
      title: '감자무봤나',
      theme: AppTheme.light,
      routerConfig: appRouter,
    );
  }

  Future<void> _synchronizePushToken() async {
    try {
      await ref.read(pushNotificationServiceProvider).synchronize();
    } catch (_) {
      // 권한 변경 동기화는 다음 foreground 진입에서 다시 시도한다.
    }
  }

  void _showForegroundMessage(PushMessage message) {
    if (ref.read(authControllerProvider).status != AuthStatus.authenticated ||
        !message.hasDisplayContent) {
      return;
    }
    final route = PushRouteResolver.resolve(message.data);
    final title = message.title ?? '새 알림';
    final body = message.body;
    final content = body == null || body.isEmpty ? title : '$title\n$body';

    _scaffoldMessengerKey.currentState
      ?..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(content),
          action: route == null
              ? null
              : SnackBarAction(
                  label: '보기',
                  onPressed: () => appRouter.go(route),
                ),
        ),
      );
  }

  void _openPushMessage(PushMessage message) {
    if (ref.read(authControllerProvider).status != AuthStatus.authenticated) {
      return;
    }
    final route = PushRouteResolver.resolve(message.data);
    if (route != null) {
      appRouter.go(route);
    }
  }
}
