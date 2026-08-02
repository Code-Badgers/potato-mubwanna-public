import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/permissions/permission_service.dart';
import '../../../push/application/push_notification_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({
    PermissionService? permissionService,
    this.pushTokenLifecycle = const NoopPushTokenLifecycle(),
    this.showAccountActions = false,
    this.onLogout,
    this.onWithdrawAccount,
    this.authMessage,
    this.onOpenLogin,
    super.key,
  }) : permissionService = permissionService ?? const PermissionService();

  final PermissionService permissionService;
  final PushTokenLifecycle pushTokenLifecycle;
  final bool showAccountActions;
  final Future<void> Function()? onLogout;
  final Future<bool> Function()? onWithdrawAccount;
  final String? Function()? authMessage;
  final VoidCallback? onOpenLogin;

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
                  if (widget.showAccountActions)
                    SliverToBoxAdapter(
                      child: _AccountSettingsSection(
                        onLogout: _logout,
                        onWithdraw: _confirmAccountWithdrawal,
                      ),
                    ),
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
                          if (widget.showAccountActions)
                            SliverToBoxAdapter(
                              child: _AccountSettingsSection(
                                onLogout: _logout,
                                onWithdraw: _confirmAccountWithdrawal,
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

  Future<void> _logout() async {
    final logout = widget.onLogout;
    if (logout == null) {
      return;
    }

    await logout();
    if (mounted) {
      widget.onOpenLogin?.call();
    }
  }

  Future<void> _confirmAccountWithdrawal() async {
    final withdraw = widget.onWithdrawAccount;
    if (withdraw == null) {
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        icon: const Icon(
          Icons.warning_amber_rounded,
          color: AppColors.error,
          size: 36,
        ),
        title: const Text('정말 탈퇴하시겠어요?'),
        content: const Text(
          '스탬프, 감자, 쿠폰과 여행 기록이 모두 삭제되며 복구할 수 없습니다.\n\n'
          '카카오 계정 자체는 삭제되지 않습니다.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('취소'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('회원 탈퇴'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) {
      return;
    }

    final withdrawn = await withdraw();
    if (!mounted) {
      return;
    }
    if (withdrawn) {
      widget.onOpenLogin?.call();
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(widget.authMessage?.call() ?? '회원 탈퇴에 실패했습니다.')),
    );
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
              '설정',
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
        border: Border.all(color: AppColors.line),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: const BoxDecoration(
              color: AppColors.primaryTint,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: AppColors.primaryDark, size: 24),
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
                    color: isGranted
                        ? AppColors.primaryDark
                        : AppColors.textSecondary,
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

class _AccountSettingsSection extends StatelessWidget {
  const _AccountSettingsSection({
    required this.onLogout,
    required this.onWithdraw,
  });

  final VoidCallback onLogout;
  final VoidCallback onWithdraw;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
      child: Material(
        color: AppColors.cream,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(color: AppColors.line),
        ),
        child: Column(
          children: [
            _SettingsActionRow(
              icon: Icons.logout_rounded,
              label: '로그아웃',
              onTap: onLogout,
            ),
            const Divider(height: 1, color: AppColors.line, indent: 58),
            _SettingsActionRow(
              icon: Icons.person_off_outlined,
              label: '회원 탈퇴',
              destructive: true,
              onTap: onWithdraw,
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingsActionRow extends StatelessWidget {
  const _SettingsActionRow({
    required this.icon,
    required this.label,
    required this.onTap,
    this.destructive = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final color = destructive ? AppColors.error : AppColors.textPrimary;

    return InkWell(
      onTap: onTap,
      child: SizedBox(
        height: 62,
        child: Row(
          children: [
            const SizedBox(width: 20),
            Icon(icon, color: color, size: 24),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0,
                ),
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.textSecondary,
              size: 24,
            ),
            const SizedBox(width: 16),
          ],
        ),
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
