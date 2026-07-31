import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/permissions/permission_service.dart';
import '../../../push/application/push_notification_service.dart';

const _settingsPrimary = Color(0xFF509B64);
const _settingsLine = Color(0xFFE8E2D8);
const _settingsCream = Color(0xFFFFF8EA);

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({
    PermissionService? permissionService,
    this.pushTokenLifecycle = const NoopPushTokenLifecycle(),
    super.key,
  }) : permissionService = permissionService ?? const PermissionService();

  final PermissionService permissionService;
  final PushTokenLifecycle pushTokenLifecycle;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen>
    with WidgetsBindingObserver {
  PermissionStatus? _locationStatus;
  PermissionStatus? _notificationStatus;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    if (widget.permissionService.supportsRuntimePermissions) {
      WidgetsBinding.instance.addObserver(this);
      _loadStatuses();
    }
  }

  @override
  void dispose() {
    if (widget.permissionService.supportsRuntimePermissions) {
      WidgetsBinding.instance.removeObserver(this);
    }
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (widget.permissionService.supportsRuntimePermissions &&
        state == AppLifecycleState.resumed) {
      _loadStatuses();
    }
  }

  Future<void> _loadStatuses() async {
    if (!widget.permissionService.supportsRuntimePermissions) {
      return;
    }

    if (_errorMessage != null) {
      setState(() => _errorMessage = null);
    }

    try {
      final locationStatus = await widget.permissionService.locationStatus();
      final notificationStatus =
          await widget.permissionService.notificationStatus();
      await _updatePushRegistration(notificationStatus);

      if (!mounted) {
        return;
      }

      setState(() {
        _locationStatus = locationStatus;
        _notificationStatus = notificationStatus;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() => _errorMessage = '권한 상태를 불러오지 못했습니다.');
    }
  }

  Future<void> _updatePushRegistration(PermissionStatus status) async {
    try {
      if (status.isGranted || status.isProvisional) {
        await widget.pushTokenLifecycle.synchronize();
      } else {
        await widget.pushTokenLifecycle.unregister();
      }
    } catch (_) {
      // 시스템 권한 상태 표시는 유지하고 서버 동기화는 다음 진입에서 재시도한다.
    }
  }

  Future<void> _manageLocationPermission() async {
    final status = _locationStatus!;
    if (status.isPermanentlyDenied || status.isRestricted) {
      await widget.permissionService.openSettings();
      return;
    }

    await widget.permissionService.requestLocation();
    await _loadStatuses();
  }

  Future<void> _manageNotificationPermission() async {
    final status = _notificationStatus!;
    if (status.isPermanentlyDenied || status.isRestricted) {
      await widget.permissionService.openSettings();
      return;
    }

    await widget.permissionService.requestNotification();
    await _loadStatuses();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: !widget.permissionService.supportsRuntimePermissions
            ? CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: _SettingsHeader(onBack: _handleBack),
                  ),
                  const SliverToBoxAdapter(child: _WebPermissionGuide()),
                ],
              )
            : _errorMessage != null
                ? _SettingsErrorState(
                    message: _errorMessage!,
                    onRetry: _loadStatuses,
                  )
                : _locationStatus == null || _notificationStatus == null
                    ? const Center(child: CircularProgressIndicator())
                    : CustomScrollView(
                        slivers: [
                          SliverToBoxAdapter(
                            child: _SettingsHeader(
                              onBack: _handleBack,
                            ),
                          ),
                          SliverToBoxAdapter(
                            child: _SettingsIntro(
                              locationStatus: _locationStatus!,
                              notificationStatus: _notificationStatus!,
                              onLocationAction: _manageLocationPermission,
                              onNotificationAction:
                                  _manageNotificationPermission,
                            ),
                          ),
                        ],
                      ),
      ),
    );
  }

  void _handleBack() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/main/mypage');
    }
  }
}

class _WebPermissionGuide extends StatelessWidget {
  const _WebPermissionGuide();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(24),
      child: Text(
        '웹에서는 브라우저 설정에서 위치와 알림 권한을 관리해주세요.',
        textAlign: TextAlign.center,
        style: TextStyle(
          color: AppColors.textSecondary,
          fontSize: 15,
          fontWeight: FontWeight.w700,
          height: 1.5,
        ),
      ),
    );
  }
}

class _SettingsHeader extends StatelessWidget {
  const _SettingsHeader({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 20, 10),
      child: Row(
        children: [
          IconButton(
            tooltip: '뒤로 가기',
            onPressed: onBack,
            icon: const Icon(Icons.arrow_back_rounded),
          ),
          const SizedBox(width: 4),
          const Expanded(
            child: Text(
              '권한 관리',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 28,
                fontWeight: FontWeight.w900,
                letterSpacing: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsIntro extends StatelessWidget {
  const _SettingsIntro({
    required this.locationStatus,
    required this.notificationStatus,
    required this.onLocationAction,
    required this.onNotificationAction,
  });

  final PermissionStatus locationStatus;
  final PermissionStatus notificationStatus;
  final VoidCallback onLocationAction;
  final VoidCallback onNotificationAction;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: _settingsCream,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: _settingsLine),
            ),
            child: const Text(
              '필수 기능에 필요한 접근권한을 관리합니다.',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w800,
                letterSpacing: 0,
              ),
            ),
          ),
          const SizedBox(height: 18),
          _PermissionRow(
            icon: Icons.location_on_outlined,
            title: '위치 권한',
            description: '주변 관광지 탐색과 방문 인증에 사용합니다.',
            status: locationStatus,
            onAction: onLocationAction,
          ),
          const SizedBox(height: 12),
          _PermissionRow(
            icon: Icons.notifications_none_rounded,
            title: '알림 권한',
            description: '미션과 쿠폰 지급 소식을 알려드립니다.',
            status: notificationStatus,
            onAction: onNotificationAction,
          ),
        ],
      ),
    );
  }
}

class _PermissionRow extends StatelessWidget {
  const _PermissionRow({
    required this.icon,
    required this.title,
    required this.description,
    required this.status,
    required this.onAction,
  });

  final IconData icon;
  final String title;
  final String description;
  final PermissionStatus status;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    final isGranted = status.isGranted;
    final needsSettings = status.isPermanentlyDenied || status.isRestricted;
    final actionLabel = isGranted
        ? null
        : needsSettings
            ? '설정 열기'
            : '허용하기';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _settingsLine),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: const BoxDecoration(
              color: Color(0xFFE5F6EA),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: _settingsPrimary, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  isGranted
                      ? '허용됨'
                      : needsSettings
                          ? '설정에서 허용 필요'
                          : '허용 필요',
                  style: TextStyle(
                    color:
                        isGranted ? _settingsPrimary : AppColors.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0,
                  ),
                ),
              ],
            ),
          ),
          if (actionLabel != null) ...[
            const SizedBox(width: 10),
            actionLabel == '설정 열기'
                ? OutlinedButton(
                    onPressed: onAction,
                    child: Text(actionLabel),
                  )
                : FilledButton(
                    onPressed: onAction,
                    child: Text(actionLabel),
                  ),
          ],
        ],
      ),
    );
  }
}

class _SettingsErrorState extends StatelessWidget {
  const _SettingsErrorState({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            OutlinedButton(onPressed: onRetry, child: const Text('다시 시도')),
          ],
        ),
      ),
    );
  }
}
