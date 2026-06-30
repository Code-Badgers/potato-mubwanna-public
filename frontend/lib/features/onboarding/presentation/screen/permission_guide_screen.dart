import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/permissions/permission_service.dart';

const _permissionButtonColor = Color(0xFF56C787);

class PermissionGuideScreen extends StatefulWidget {
  const PermissionGuideScreen({
    this.permissionService = const PermissionService(),
    super.key,
  });

  final PermissionService permissionService;

  @override
  State<PermissionGuideScreen> createState() => _PermissionGuideScreenState();
}

class _PermissionGuideScreenState extends State<PermissionGuideScreen> {
  static const _items = [
    _PermissionGuideItem(
      icon: Icons.location_on_outlined,
      title: '위치 [선택]',
      description: '주변 감자 스팟 탐색과 관광지 방문 인증에 사용합니다.',
    ),
    _PermissionGuideItem(
      icon: Icons.notifications_none_rounded,
      title: '알림 [선택]',
      description: '점순이 미션, 쿠폰 지급, 이벤트 알림에 사용합니다.',
    ),
  ];

  bool _isRequesting = false;
  String? _permissionMessage;
  bool _canContinueWithoutPermission = false;

  Future<void> _confirmPermissions() async {
    if (!widget.permissionService.supportsRuntimePermissions) {
      context.go('/main/map');
      return;
    }

    setState(() {
      _isRequesting = true;
      _permissionMessage = null;
      _canContinueWithoutPermission = false;
    });

    try {
      final status = await widget.permissionService.requestLocation();
      if (!mounted) {
        return;
      }

      if (status.isGranted || status.isLimited) {
        context.go('/main/map');
        return;
      }

      setState(() {
        _isRequesting = false;
        _permissionMessage = status.isPermanentlyDenied
            ? '위치 권한이 차단되어 있습니다. 설정의 권한 관리에서 허용해주세요.'
            : '위치 권한 없이 둘러볼 수 있지만 주변 탐색과 방문 인증은 제한됩니다.';
        _canContinueWithoutPermission = true;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isRequesting = false;
        _permissionMessage = '위치 권한을 확인하지 못했습니다. 다시 시도해주세요.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final supportsRuntimePermissions =
        widget.permissionService.supportsRuntimePermissions;

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 430),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 34, 24, 22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 18),
                  const Text(
                    '편리한 감자여행을 위해\n접근권한을 확인해주세요',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      height: 1.26,
                    ),
                  ),
                  const SizedBox(height: 28),
                  Expanded(
                    child: ListView.separated(
                      physics: const BouncingScrollPhysics(),
                      itemCount: _items.length + 1,
                      separatorBuilder: (_, __) => const SizedBox(height: 22),
                      itemBuilder: (context, index) {
                        if (index == _items.length) {
                          return _PermissionNotice(
                            supportsRuntimePermissions:
                                supportsRuntimePermissions,
                          );
                        }

                        return _PermissionItemTile(item: _items[index]);
                      },
                    ),
                  ),
                  if (_permissionMessage != null) ...[
                    const SizedBox(height: 14),
                    Text(
                      _permissionMessage!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        height: 1.4,
                      ),
                    ),
                  ],
                  const SizedBox(height: 18),
                  SizedBox(
                    height: 58,
                    child: FilledButton(
                      onPressed: _isRequesting ? null : _confirmPermissions,
                      style: FilledButton.styleFrom(
                        backgroundColor: _permissionButtonColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        textStyle: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      child: _isRequesting
                          ? const SizedBox.square(
                              dimension: 22,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2.5,
                              ),
                            )
                          : const Text('확인'),
                    ),
                  ),
                  if (_canContinueWithoutPermission)
                    TextButton(
                      onPressed: () => context.go('/main/map'),
                      child: const Text('권한 없이 둘러보기'),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PermissionItemTile extends StatelessWidget {
  const _PermissionItemTile({required this.item});

  final _PermissionGuideItem item;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 54,
          height: 54,
          decoration: BoxDecoration(
            color: _permissionButtonColor.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: Icon(item.icon, color: _permissionButtonColor, size: 28),
        ),
        const SizedBox(width: 18),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.title,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 19,
                  fontWeight: FontWeight.w900,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                item.description,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  height: 1.42,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PermissionNotice extends StatelessWidget {
  const _PermissionNotice({required this.supportsRuntimePermissions});

  final bool supportsRuntimePermissions;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Text(
        supportsRuntimePermissions
            ? '선택 접근권한에 동의하지 않아도 서비스를 둘러볼 수 있습니다. '
                '다만 해당 권한이 필요한 기능은 제한될 수 있습니다.'
            : '웹에서는 브라우저 설정에서 위치와 알림 권한을 관리해주세요.',
        style: const TextStyle(
          color: AppColors.textSecondary,
          fontSize: 13,
          fontWeight: FontWeight.w600,
          height: 1.45,
        ),
      ),
    );
  }
}

class _PermissionGuideItem {
  const _PermissionGuideItem({
    required this.icon,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final String title;
  final String description;
}
