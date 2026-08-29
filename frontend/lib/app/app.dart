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
  Future<bool> didPopRoute() async {
    // GoRouter's nested ShellRoute navigator can report an unhandled pop at
    // its root, which Android interprets as a request to finish the activity.
    // Consume that root-level back action so repeated presses never leave the
    // app unexpectedly. Nested routes still flow through GoRouter normally.
    if (appRouter.location != '/main/map') {
      return false;
    }
    _scaffoldMessengerKey.currentState
      ?..clearSnackBars()
      ..showSnackBar(
        const SnackBar(
          content: Text('현재 첫 화면입니다.'),
          duration: Duration(milliseconds: 1200),
        ),
      );
    return true;
  }

  @override
  Widget build(BuildContext context) {
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
