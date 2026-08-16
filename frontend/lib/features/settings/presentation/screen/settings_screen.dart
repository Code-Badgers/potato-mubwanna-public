import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_design_tokens.dart';
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
  String? _permissionMessage;

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

    final requestedStatus = await widget.permissionService.requestLocation();
    if (!mounted) {
      return;
    }

    setState(() {
      _locationStatus = requestedStatus;
      _permissionMessage = _permissionMessageFor(
        requestedStatus,
        deniedMessage: '위치 권한이 허용되지 않았습니다. 주변 탐색과 방문 인증이 제한됩니다.',
        settingsMessage: '위치 권한이 차단되어 있습니다. iPhone 설정에서 감자무봤나 위치 권한을 허용해주세요.',
      );
    });
    await _loadStatuses();
  }

  Future<void> _manageNotificationPermission() async {
    final status = _notificationStatus!;
    if (status.isPermanentlyDenied || status.isRestricted) {
      await widget.permissionService.openSettings();
      return;
    }

    final requestedStatus =
        await widget.permissionService.requestNotification();
    if (!mounted) {
      return;
    }

    setState(() {
      _notificationStatus = requestedStatus;
      _permissionMessage = _permissionMessageFor(
        requestedStatus,
        deniedMessage: '알림 권한이 허용되지 않았습니다. 미션과 쿠폰 알림을 받을 수 없습니다.',
        settingsMessage: '알림 권한이 차단되어 있습니다. 설정에서 알림 권한을 허용해주세요.',
      );
    });
    await _loadStatuses();
  }

  String? _permissionMessageFor(
    PermissionStatus status, {
    required String deniedMessage,
    required String settingsMessage,
  }) {
    if (status.isGranted || status.isProvisional) {
      return null;
    }
    if (status.isPermanentlyDenied || status.isRestricted) {
      return settingsMessage;
    }
    return deniedMessage;
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
                  const SliverToBoxAdapter(child: _LegalSettingsSection()),
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
                              permissionMessage: _permissionMessage,
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
                          const SliverToBoxAdapter(
                            child: _LegalSettingsSection(),
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
      padding: const EdgeInsets.fromLTRB(12, 12, 20, 12),
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
                fontSize: 26,
                fontWeight: FontWeight.w800,
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
    required this.permissionMessage,
    required this.onLocationAction,
    required this.onNotificationAction,
  });

  final PermissionStatus locationStatus;
  final PermissionStatus notificationStatus;
  final String? permissionMessage;
  final VoidCallback onLocationAction;
  final VoidCallback onNotificationAction;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (permissionMessage != null) ...[
            _PermissionMessage(message: permissionMessage!),
            const SizedBox(height: 12),
          ],
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

class _PermissionMessage extends StatelessWidget {
  const _PermissionMessage({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: _settingsGlassDecoration(radius: AppDimens.compactCardRadius)
          .copyWith(color: AppColors.cream.withValues(alpha: 0.74)),
      child: Text(
        message,
        style: const TextStyle(
          color: AppColors.textPrimary,
          fontSize: 13,
          fontWeight: FontWeight.w800,
          height: 1.35,
          letterSpacing: 0,
        ),
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
      decoration: _settingsGlassDecoration(radius: AppDimens.compactCardRadius),
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
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
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
        color: Colors.transparent,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimens.cardRadius),
        ),
        child: Column(
          children: [
            Container(
              decoration: _settingsGlassDecoration(),
              child: Column(
                children: [
                  _SettingsActionRow(
                    icon: Icons.logout_rounded,
                    label: '로그아웃',
                    description: '현재 계정 연결을 해제합니다',
                    onTap: onLogout,
                  ),
                  Divider(
                    height: 1,
                    indent: 64,
                    endIndent: 18,
                    color: AppColors.line.withValues(alpha: 0.32),
                  ),
                  _SettingsActionRow(
                    icon: Icons.person_off_outlined,
                    label: '회원 탈퇴',
                    description: '계정과 여행 기록을 삭제합니다',
                    destructive: true,
                    onTap: onWithdraw,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LegalSettingsSection extends StatelessWidget {
  const _LegalSettingsSection();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
      child: Material(
        color: Colors.transparent,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimens.cardRadius),
        ),
        child: Column(
          children: [
            Container(
              decoration: _settingsGlassDecoration(),
              child: Column(
                children: [
                  _SettingsActionRow(
                    icon: Icons.description_outlined,
                    label: '서비스 이용약관',
                    description: '서비스 이용 기준',
                    onTap: () => context.push('/legal/service-terms'),
                  ),
                  _SettingsDivider(),
                  _SettingsActionRow(
                    icon: Icons.shield_outlined,
                    label: '개인정보처리방침',
                    description: '개인정보 처리와 보관',
                    onTap: () => context.push('/legal/privacy-policy'),
                  ),
                  _SettingsDivider(),
                  _SettingsActionRow(
                    icon: Icons.location_on_outlined,
                    label: '위치정보 동의 관리',
                    description: '방문 인증 위치 동의',
                    onTap: () =>
                        context.push('/legal/location-terms?manage=true'),
                  ),
                  _SettingsDivider(),
                  _SettingsActionRow(
                    icon: Icons.directions_walk_rounded,
                    label: '걸음 정보 동의 관리',
                    description: '감자걸음 성장 동의',
                    onTap: () =>
                        context.push('/legal/health-data-consent?manage=true'),
                  ),
                ],
              ),
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
    required this.description,
    required this.onTap,
    this.destructive = false,
  });

  final IconData icon;
  final String label;
  final String description;
  final VoidCallback onTap;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final color = destructive ? AppColors.error : AppColors.textPrimary;
    final iconColor = destructive ? AppColors.error : AppColors.primaryDark;

    return InkWell(
      onTap: onTap,
      child: SizedBox(
        height: 68,
        child: Row(
          children: [
            const SizedBox(width: 20),
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: color,
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    description,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0,
                    ),
                  ),
                ],
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

class _SettingsDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Divider(
      height: 1,
      indent: 68,
      endIndent: 18,
      color: AppColors.line.withValues(alpha: 0.32),
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

BoxDecoration _settingsGlassDecoration({
  double radius = AppDimens.cardRadius,
}) {
  return BoxDecoration(
    color: AppColors.surface.withValues(alpha: 0.9),
    borderRadius: BorderRadius.circular(radius),
    boxShadow: [
      BoxShadow(
        color: AppColors.textPrimary.withValues(alpha: 0.045),
        blurRadius: 24,
        offset: const Offset(0, 10),
      ),
      BoxShadow(
        color: AppColors.primary.withValues(alpha: 0.03),
        blurRadius: 32,
        offset: const Offset(0, 16),
      ),
    ],
  );
}
