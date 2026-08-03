import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../shared/widgets/auth_required_view.dart';
import '../../../auth/application/auth_controller.dart';
import '../../application/travel_record_controller.dart';
import '../../domain/travel_record.dart';

const _travelPrimary = Color(0xFF56C787);
const _travelDark = Color(0xFF509B64);
const _travelCream = Color(0xFFFFF8EA);
const _travelLine = Color(0xFFE8E2D8);

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
      child: ListView.separated(
        key: const ValueKey('travel-record-list'),
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
        itemCount: records.length + 1,
        separatorBuilder: (_, index) => SizedBox(height: index == 0 ? 16 : 12),
        itemBuilder: (context, index) {
          if (index == 0) {
            return _TravelRecordSummary(count: records.length);
          }
          final record = records[index - 1];
          return _TravelRecordCard(
            record: record,
            onTap: () => onRecordSelected(record),
          );
        },
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
        color: const Color(0xFFE5F6EA),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFCDE8D7)),
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

class _TravelRecordCard extends StatelessWidget {
  const _TravelRecordCard({required this.record, required this.onTap});

  final TravelRecord record;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        key: ValueKey('travel-record-${record.visitId}'),
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: _travelLine),
          ),
          child: Row(
            children: [
              _TravelRecordThumbnail(record: record),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      record.spotName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      '${record.cityName} · ${record.categoryLabel}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 7),
                    Row(
                      children: [
                        const Icon(
                          Icons.check_circle_rounded,
                          color: _travelPrimary,
                          size: 16,
                        ),
                        const SizedBox(width: 5),
                        Expanded(
                          child: Text(
                            _formatVisitedAt(record.visitedAt),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: _travelDark,
                              fontSize: 12,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TravelRecordThumbnail extends ConsumerWidget {
  const _TravelRecordThumbnail({required this.record});

  final TravelRecord record;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final uploadedImageUrl = record.uploadedImageUrl?.trim();
    final uploadedImage = uploadedImageUrl == null || uploadedImageUrl.isEmpty
        ? null
        : ref.watch(travelRecordImageProvider(uploadedImageUrl)).valueOrNull;

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: SizedBox(
        width: 54,
        height: 54,
        child: uploadedImage != null && uploadedImage.isNotEmpty
            ? Image.memory(
                uploadedImage,
                key: ValueKey('travel-record-uploaded-image-${record.visitId}'),
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _touristImageOrFallback(),
              )
            : _touristImageOrFallback(),
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
      color: _travelCream,
      child: const Icon(
        Icons.location_on_rounded,
        color: _travelDark,
        size: 30,
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
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.map_outlined,
              color: _travelDark,
              size: 52,
            ),
            SizedBox(height: 16),
            Text(
              '아직 여행 기록이 없어요',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 19,
                fontWeight: FontWeight.w900,
                letterSpacing: 0,
              ),
            ),
            SizedBox(height: 8),
            Text(
              '감자 스팟을 방문 인증하면\n이곳에 여행 기록이 쌓여요.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
                fontWeight: FontWeight.w700,
                height: 1.5,
              ),
            ),
          ],
        ),
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
