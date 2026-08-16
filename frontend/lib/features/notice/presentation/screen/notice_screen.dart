import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_design_tokens.dart';

class NoticeScreen extends StatelessWidget {
  const NoticeScreen({super.key});

  static const _notices = [
    _NoticeItem(
      publishedAt: '2026.08.16',
      category: '안내',
      title: '감자 스팟 데이터는 계속 보정됩니다',
      body:
          '감자 스팟은 강원도 관광지와 지역 맛집 데이터를 바탕으로 제공됩니다. 실제 운영 전까지 위치, 분류, 설명을 계속 다듬어 더 정확한 여행 탐색을 제공할 예정입니다.',
    ),
    _NoticeItem(
      publishedAt: '2026.08.16',
      category: '스탬프',
      title: '방문 인증은 현장 위치를 기준으로 합니다',
      body:
          '스탬프는 지정된 장소 근처에서 위치 확인을 마치면 찍을 수 있습니다. 위치 권한이 꺼져 있으면 인증이 제한될 수 있으니, 여행 전 앱 위치 권한을 확인해주세요.',
    ),
    _NoticeItem(
      publishedAt: '2026.08.16',
      category: '보상',
      title: '제휴 보상은 추후 순차적으로 추가됩니다',
      body:
          '현재는 공모전 MVP 단계라 실제 지자체·상점 제휴 보상은 준비 중입니다. 향후 협의가 완료되면 미션, 스탬프, 보상함에서 사용할 수 있는 쿠폰과 혜택이 순차적으로 추가될 예정입니다.',
    ),
  ];

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
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
              sliver: SliverList.separated(
                itemCount: _notices.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final notice = _notices[index];
                  return _NoticeRow(
                    notice: notice,
                    onTap: () => _showNoticeDetail(context, notice),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  static void _showNoticeDetail(BuildContext context, _NoticeItem notice) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _NoticeMeta(item: notice),
              const SizedBox(height: 14),
              Text(
                notice.title,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  height: 1.24,
                  letterSpacing: 0,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                notice.body,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  height: 1.56,
                  letterSpacing: 0,
                ),
              ),
              const SizedBox(height: 22),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('확인'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NoticeRow extends StatelessWidget {
  const _NoticeRow({
    required this.notice,
    required this.onTap,
  });

  final _NoticeItem notice;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(AppDimens.compactCardRadius),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppDimens.compactCardRadius),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
          decoration: BoxDecoration(
            color: AppColors.surface.withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(AppDimens.compactCardRadius),
            boxShadow: [
              BoxShadow(
                color: AppColors.textPrimary.withValues(alpha: 0.04),
                blurRadius: 22,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.primaryTint.withValues(alpha: 0.86),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.campaign_rounded,
                  color: AppColors.primaryDark,
                  size: 19,
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      notice.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0,
                      ),
                    ),
                    const SizedBox(height: 5),
                    _NoticeMeta(item: notice),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.textSecondary,
                size: 22,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NoticeMeta extends StatelessWidget {
  const _NoticeMeta({required this.item});

  final _NoticeItem item;

  @override
  Widget build(BuildContext context) {
    return Text(
      '${item.category} · ${item.publishedAt}',
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: const TextStyle(
        color: AppColors.textSecondary,
        fontSize: 12,
        fontWeight: FontWeight.w600,
        letterSpacing: 0,
      ),
    );
  }
}

class _NoticeItem {
  const _NoticeItem({
    required this.publishedAt,
    required this.category,
    required this.title,
    required this.body,
  });

  final String publishedAt;
  final String category;
  final String title;
  final String body;
}
