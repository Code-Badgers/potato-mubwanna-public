import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';

class NoticeScreen extends StatelessWidget {
  const NoticeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 10, 18, 18),
                child: Row(
                  children: [
                    IconButton(
                      tooltip: '뒤로 가기',
                      onPressed: () => Navigator.of(context).maybePop(),
                      icon: const Icon(Icons.arrow_back_ios_new_rounded),
                    ),
                    const SizedBox(width: 4),
                    const Text(
                      '공지사항',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
              sliver: SliverList.list(
                children: const [
                  _NoticeCard(
                    badge: '안내',
                    title: '감자 스팟은 계속 다듬고 있어요',
                    body:
                        '지도에 보이는 감자 스팟은 강원도 여행지와 지역 맛집 데이터를 바탕으로 제공됩니다. 운영 중에도 위치와 분류를 꾸준히 보정할 예정이에요.',
                  ),
                  SizedBox(height: 12),
                  _NoticeCard(
                    badge: '스탬프',
                    title: '방문 인증은 현장 위치를 기준으로 해요',
                    body:
                        '스탬프는 지정된 장소 근처에서 위치 확인을 마치면 찍을 수 있습니다. 위치 권한이 꺼져 있으면 인증이 제한될 수 있어요.',
                  ),
                  SizedBox(height: 12),
                  _NoticeCard(
                    badge: '보상',
                    title: '쿠폰과 보상은 순차적으로 열립니다',
                    body:
                        '스탬프와 미션 보상은 제휴 및 운영 상태에 맞춰 순차적으로 제공됩니다. 사용 가능한 보상은 보상함에서 확인할 수 있어요.',
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

class _NoticeCard extends StatelessWidget {
  const _NoticeCard({
    required this.badge,
    required this.title,
    required this.body,
  });

  final String badge;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.line.withValues(alpha: 0.82)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: AppColors.primaryTint,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                badge,
                style: const TextStyle(
                  color: AppColors.primaryDark,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w900,
                height: 1.25,
                letterSpacing: 0,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              body,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
                fontWeight: FontWeight.w700,
                height: 1.5,
                letterSpacing: 0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
