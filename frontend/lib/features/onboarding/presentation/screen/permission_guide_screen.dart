import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_colors.dart';

const _permissionButtonColor = Color(0xFF56C787);

class PermissionGuideScreen extends StatelessWidget {
  const PermissionGuideScreen({super.key});

  static const _items = [
    _PermissionGuideItem(
      icon: Icons.notifications_none_rounded,
      title: '알림 [선택]',
      description: '점순이 미션, 쿠폰 지급, 이벤트 알림에 사용합니다.',
    ),
    _PermissionGuideItem(
      icon: Icons.photo_camera_outlined,
      title: '카메라 [선택]',
      description: 'QR 인증, 방문 인증, 미션 인증 촬영에 사용합니다.',
    ),
    _PermissionGuideItem(
      icon: Icons.photo_library_outlined,
      title: '사진 및 동영상 [선택]',
      description: '미션 인증 이미지 첨부와 여행 기록 등록에 사용합니다.',
    ),
    _PermissionGuideItem(
      icon: Icons.location_on_outlined,
      title: '위치 [필수]',
      description: '주변 감자 스팟 탐색과 관광지 방문 인증에 사용합니다.',
    ),
    _PermissionGuideItem(
      icon: Icons.person_outline_rounded,
      title: '닉네임 [필수]',
      description: '앱 내 프로필 표시와 스탬프/보상/미션 내역 식별에 사용합니다.',
    ),
    _PermissionGuideItem(
      icon: Icons.alternate_email_rounded,
      title: '이메일 [선택]',
      description: '계정 식별, 보상 지급 내역 확인, 이용 문의 응대에 사용합니다.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
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
                      letterSpacing: 0,
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
                          return const _PermissionNotice();
                        }

                        return _PermissionItemTile(item: _items[index]);
                      },
                    ),
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    height: 58,
                    child: FilledButton(
                      onPressed: () => context.go('/main/map'),
                      style: FilledButton.styleFrom(
                        backgroundColor: _permissionButtonColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        textStyle: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0,
                        ),
                      ),
                      child: const Text('확인'),
                    ),
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
          child: Icon(
            item.icon,
            color: _permissionButtonColor,
            size: 28,
          ),
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
                  letterSpacing: 0,
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
                  letterSpacing: 0,
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
  const _PermissionNotice();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.only(top: 6),
      child: Text(
        '선택 접근권한에 동의하지 않아도 서비스 이용이 가능합니다. '
        '다만 해당 권한이 필요한 기능은 일부 제한될 수 있습니다. '
        '닉네임과 이메일은 카카오 로그인 단계에서 동의를 요청합니다.',
        style: TextStyle(
          color: AppColors.textSecondary,
          fontSize: 13,
          fontWeight: FontWeight.w600,
          height: 1.45,
          letterSpacing: 0,
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
