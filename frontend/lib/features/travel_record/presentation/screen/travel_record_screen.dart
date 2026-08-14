import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_design_tokens.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../shared/widgets/auth_required_view.dart';
import '../../../auth/application/auth_controller.dart';
import '../../application/travel_record_controller.dart';
import '../../domain/travel_record.dart';

const _travelPrimary = Color(0xFF56C787);
const _travelDark = Color(0xFF509B64);
const _travelFilm = Color(0xFFF9F4E8);

class TravelRecordScreen extends ConsumerWidget {
  const TravelRecordScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authStatus = ref.watch(authControllerProvider).status;
    final recordsState = authStatus == AuthStatus.authenticated
        ? ref.watch(travelRecordsProvider)
        : null;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _TravelRecordHeader(
              onBack: () {
                if (context.canPop()) {
                  context.pop();
                } else {
                  context.go('/main/mypage');
                }
              },
            ),
            Expanded(
              child: switch (authStatus) {
                AuthStatus.authenticated => recordsState!.when(
                    data: (records) => records.isEmpty
                        ? const _TravelRecordEmptyState()
                        : _TravelRecordList(
                            records: records,
                            onRefresh: () =>
                                ref.refresh(travelRecordsProvider.future),
                            onRecordSelected: (record) =>
                                context.push('/spots/${record.spotId}'),
                          ),
                    loading: () => const _TravelRecordLoadingState(),
                    error: (error, _) => _TravelRecordErrorState(
                      message: error is ApiException
                          ? error.message
                          : '여행 기록을 불러오지 못했습니다.',
                      onRetry: () => ref.invalidate(travelRecordsProvider),
                    ),
                  ),
                AuthStatus.loading =>
                  const Center(child: CircularProgressIndicator()),
                AuthStatus.idle || AuthStatus.failure => AuthRequiredView(
                    description: '여행 기록을 확인하려면 로그인해주세요.',
                    onLogin: () => context.go('/login'),
                  ),
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _TravelRecordHeader extends StatelessWidget {
  const _TravelRecordHeader({required this.onBack});

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
              '여행 기록',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 28,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TravelRecordList extends StatelessWidget {
  const _TravelRecordList({
    required this.records,
    required this.onRefresh,
    required this.onRecordSelected,
  });

  final List<TravelRecord> records;
  final Future<void> Function() onRefresh;
  final ValueChanged<TravelRecord> onRecordSelected;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      color: _travelPrimary,
      child: CustomScrollView(
        key: const ValueKey('travel-record-list'),
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
            sliver: SliverToBoxAdapter(
              child: _TravelRecordSummary(count: records.length),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
            sliver: SliverGrid.builder(
              itemCount: records.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 14,
                crossAxisSpacing: 14,
                childAspectRatio: 0.72,
              ),
              itemBuilder: (context, index) {
                final record = records[index];
                return _TravelRecordFilmCard(
                  record: record,
                  onTap: () => onRecordSelected(record),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _TravelRecordSummary extends StatelessWidget {
  const _TravelRecordSummary({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primaryTint.withValues(alpha: 0.92),
            AppColors.cream.withValues(alpha: 0.76),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppDimens.cardRadius),
        boxShadow: AppShadows.softCard,
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: const BoxDecoration(
              color: AppColors.surface,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.route_rounded,
              color: _travelDark,
              size: 28,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '강원 감자 여행',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '총 $count곳을 방문했어요',
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 19,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TravelRecordFilmCard extends StatelessWidget {
  const _TravelRecordFilmCard({required this.record, required this.onTap});

  final TravelRecord record;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(AppDimens.compactCardRadius),
      child: InkWell(
        key: ValueKey('travel-record-${record.visitId}'),
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppDimens.compactCardRadius),
        child: Container(
          padding: const EdgeInsets.fromLTRB(10, 10, 10, 12),
          decoration: BoxDecoration(
            color: AppColors.surface.withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(AppDimens.compactCardRadius),
            boxShadow: AppShadows.softCard,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _TravelRecordSlide(record: record),
              const SizedBox(height: 10),
              Text(
                record.spotName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                '${record.cityName} · ${record.categoryLabel}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              Row(
                children: [
                  const Icon(
                    Icons.check_circle_rounded,
                    color: _travelPrimary,
                    size: 14,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      _formatVisitedAt(record.visitedAt),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _travelDark,
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TravelRecordSlide extends StatelessWidget {
  const _TravelRecordSlide({required this.record});

  final TravelRecord record;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 0.9,
      child: Container(
        decoration: BoxDecoration(
          color: _travelFilm,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.fromLTRB(12, 14, 12, 10),
        child: Column(
          children: [
            Expanded(
              child: Center(
                child: AspectRatio(
                  aspectRatio: 1,
                  child: _TravelRecordPhoto(record: record),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Container(
              height: 2,
              width: 38,
              decoration: BoxDecoration(
                color: AppColors.line.withValues(alpha: 0.78),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TravelRecordPhoto extends ConsumerWidget {
  const _TravelRecordPhoto({required this.record});

  final TravelRecord record;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final uploadedImageUrl = record.uploadedImageUrl?.trim();
    final uploadedImage = uploadedImageUrl == null || uploadedImageUrl.isEmpty
        ? null
        : ref.watch(travelRecordImageProvider(uploadedImageUrl)).valueOrNull;

    Widget child;
    if (uploadedImage != null && uploadedImage.isNotEmpty) {
      child = Image.memory(
        uploadedImage,
        key: ValueKey('travel-record-uploaded-image-${record.visitId}'),
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _touristImageOrFallback(),
      );
    } else {
      child = _touristImageOrFallback();
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(7),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.primaryTint.withValues(alpha: 0.42),
        ),
        child: child,
      ),
    );
  }

  Widget _touristImageOrFallback() {
    final touristImageUrl = record.imageUrl?.trim();
    if (touristImageUrl == null || touristImageUrl.isEmpty) {
      return _fallbackIcon();
    }
    return Image.network(
      touristImageUrl,
      key: ValueKey('travel-record-tourist-image-${record.visitId}'),
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => _fallbackIcon(),
    );
  }

  Widget _fallbackIcon() {
    return Container(
      key: ValueKey('travel-record-image-fallback-${record.visitId}'),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primaryTint.withValues(alpha: 0.72),
            AppColors.cream,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: const Center(
        child: Icon(
          Icons.photo_camera_rounded,
          color: _travelDark,
          size: 28,
        ),
      ),
    );
  }
}

class _TravelRecordLoadingState extends StatelessWidget {
  const _TravelRecordLoadingState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: CircularProgressIndicator(color: _travelPrimary),
    );
  }
}

class _TravelRecordEmptyState extends StatelessWidget {
  const _TravelRecordEmptyState();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
      children: const [
        _EmptyTravelArchive(),
        SizedBox(height: 18),
        Text(
          '아직 여행 기록이 없어요',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 19,
            fontWeight: FontWeight.w900,
            letterSpacing: 0,
          ),
        ),
        SizedBox(height: 8),
        Text(
          '스탬프 인증이나 미션 사진을 남기면\n이곳에 여행 필름처럼 모여요.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 14,
            fontWeight: FontWeight.w700,
            height: 1.5,
          ),
        ),
      ],
    );
  }
}

class _EmptyTravelArchive extends StatelessWidget {
  const _EmptyTravelArchive();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(AppDimens.cardRadius),
        boxShadow: AppShadows.softCard,
      ),
      child: GridView.builder(
        itemCount: 6,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 0.78,
        ),
        itemBuilder: (context, index) {
          return Container(
            decoration: BoxDecoration(
              color: _travelFilm,
              borderRadius: BorderRadius.circular(13),
            ),
            padding: const EdgeInsets.all(9),
            child: Column(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.primaryTint.withValues(alpha: 0.36),
                      borderRadius: BorderRadius.circular(7),
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.image_rounded,
                        color: _travelDark,
                        size: 21,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 7),
                Container(
                  height: 2,
                  width: 28,
                  decoration: BoxDecoration(
                    color: AppColors.line.withValues(alpha: 0.82),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _TravelRecordErrorState extends StatelessWidget {
  const _TravelRecordErrorState({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              color: _travelDark,
              size: 48,
            ),
            const SizedBox(height: 14),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              key: const ValueKey('travel-record-retry'),
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('다시 시도'),
            ),
          ],
        ),
      ),
    );
  }
}

String _formatVisitedAt(DateTime visitedAt) {
  final local = visitedAt.toLocal();
  final month = local.month.toString().padLeft(2, '0');
  final day = local.day.toString().padLeft(2, '0');
  final hour = local.hour.toString().padLeft(2, '0');
  final minute = local.minute.toString().padLeft(2, '0');
  return '${local.year}.$month.$day · $hour:$minute 방문';
}
