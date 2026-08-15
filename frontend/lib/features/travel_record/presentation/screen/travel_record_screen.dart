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
const _filmFrameLandscape = 'assets/travel_records/film_frame_landscape.png';
const _filmFramePortrait = 'assets/travel_records/film_frame_portrait.png';

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
      padding: const EdgeInsets.fromLTRB(12, 14, 24, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
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
                    fontSize: 34,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0,
                  ),
                ),
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(24, 6, 0, 0),
            child: Text(
              '미션과 스탬프 인증을 위해 업로드한 사진은\n자동으로 이곳에 모여요.',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 15,
                fontWeight: FontWeight.w700,
                height: 1.45,
                letterSpacing: 0,
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
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
            sliver: SliverToBoxAdapter(
              child: _TravelRecordPhotoBoard(
                records: records,
                onRecordSelected: onRecordSelected,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TravelRecordPhotoBoard extends StatelessWidget {
  const _TravelRecordPhotoBoard({
    required this.records,
    required this.onRecordSelected,
  });

  final List<TravelRecord> records;
  final ValueChanged<TravelRecord> onRecordSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 22, 18, 24),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.74),
        borderRadius: BorderRadius.circular(34),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 28,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          const spacing = 12.0;
          final columnWidth = (constraints.maxWidth - spacing) / 2;
          final children = <Widget>[];

          for (var index = 0; index < records.length; index += 1) {
            final record = records[index];
            final variant = _TravelRecordFrameVariant.fromIndex(index);
            final width = variant.isWide
                ? constraints.maxWidth
                : variant.isNarrow
                    ? columnWidth * 0.82
                    : columnWidth;

            children.add(
              _TravelRecordFilmCard(
                record: record,
                variant: variant,
                width: width,
                onTap: () => onRecordSelected(record),
              ),
            );
          }

          return Wrap(
            spacing: spacing,
            runSpacing: 18,
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.start,
            children: children,
          );
        },
      ),
    );
  }
}

enum _TravelRecordFrameVariant {
  wide,
  portrait,
  square,
  narrow;

  const _TravelRecordFrameVariant();

  factory _TravelRecordFrameVariant.fromIndex(int index) {
    return switch (index % 7) {
      0 || 3 => _TravelRecordFrameVariant.wide,
      1 || 6 => _TravelRecordFrameVariant.portrait,
      2 => _TravelRecordFrameVariant.narrow,
      _ => _TravelRecordFrameVariant.square,
    };
  }

  bool get isWide => this == _TravelRecordFrameVariant.wide;
  bool get isNarrow => this == _TravelRecordFrameVariant.narrow;

  double get aspectRatio => switch (this) {
        _TravelRecordFrameVariant.wide => 1.42,
        _TravelRecordFrameVariant.portrait => 0.72,
        _TravelRecordFrameVariant.square => 0.9,
        _TravelRecordFrameVariant.narrow => 0.68,
      };

  bool get usesPortraitFrame =>
      this == _TravelRecordFrameVariant.portrait ||
      this == _TravelRecordFrameVariant.narrow;
}

class _TravelRecordTypeStamp extends StatelessWidget {
  const _TravelRecordTypeStamp({required this.record});

  final TravelRecord record;

  bool get _isMissionPhoto {
    final category = record.category.toUpperCase();
    return category.contains('MISSION') || category.contains('PHOTO');
  }

  @override
  Widget build(BuildContext context) {
    final color = _isMissionPhoto ? const Color(0xFF4F8CCB) : _travelPrimary;
    final label = _isMissionPhoto ? '미션' : '스탬프';
    final icon =
        _isMissionPhoto ? Icons.flag_rounded : Icons.location_on_rounded;

    return Transform.rotate(
      angle: _isMissionPhoto ? -0.08 : 0.02,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 5),
        decoration: BoxDecoration(
          color: AppColors.surface.withValues(alpha: 0.78),
          border: Border.all(color: color.withValues(alpha: 0.66)),
          borderRadius: BorderRadius.circular(7),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 14),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 8,
                fontWeight: FontWeight.w900,
                letterSpacing: 0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TravelRecordFilmCard extends StatelessWidget {
  const _TravelRecordFilmCard({
    required this.record,
    required this.variant,
    required this.width,
    required this.onTap,
  });

  final TravelRecord record;
  final _TravelRecordFrameVariant variant;
  final double width;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(AppDimens.cardRadius),
      child: InkWell(
        key: ValueKey('travel-record-${record.visitId}'),
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppDimens.cardRadius),
        child: SizedBox(
          width: width,
          child: AspectRatio(
            aspectRatio: variant.aspectRatio,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned.fill(
                  child: _TravelRecordFramedPhoto(
                    record: record,
                    variant: variant,
                  ),
                ),
                Positioned(
                  top: variant.usesPortraitFrame ? 8 : 10,
                  right: variant.usesPortraitFrame ? 10 : 12,
                  child: _TravelRecordTypeStamp(record: record),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TravelRecordFramedPhoto extends StatelessWidget {
  const _TravelRecordFramedPhoto({
    required this.record,
    required this.variant,
  });

  final TravelRecord record;
  final _TravelRecordFrameVariant variant;

  @override
  Widget build(BuildContext context) {
    final frameAsset =
        variant.usesPortraitFrame ? _filmFramePortrait : _filmFrameLandscape;

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final height = constraints.maxHeight;
        final photoInsets = variant.usesPortraitFrame
            ? EdgeInsets.fromLTRB(
                width * 0.31,
                height * 0.22,
                width * 0.33,
                height * 0.22,
              )
            : EdgeInsets.fromLTRB(
                width * 0.18,
                height * 0.26,
                width * 0.19,
                height * 0.34,
              );

        return Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: _travelFilm,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 14,
                      offset: const Offset(0, 7),
                    ),
                  ],
                ),
              ),
            ),
            Positioned.fill(
              child: Padding(
                padding: photoInsets,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(7),
                  child: _TravelRecordPhoto(record: record),
                ),
              ),
            ),
            Positioned.fill(
              child: Image.asset(
                frameAsset,
                fit: BoxFit.fill,
                filterQuality: FilterQuality.medium,
              ),
            ),
            Positioned(
              left: 20,
              right: 20,
              bottom: variant.usesPortraitFrame ? 18 : 14,
              child: Text(
                _formatHandwrittenDate(record.visitedAt),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: AppColors.textSecondary.withValues(alpha: 0.82),
                  fontSize: variant.usesPortraitFrame ? 11 : 12,
                  fontStyle: FontStyle.italic,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.24,
                ),
              ),
            ),
          ],
        );
      },
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

    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.primaryTint.withValues(alpha: 0.42),
      ),
      child: child,
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
      ],
    );
  }
}

class _EmptyTravelArchive extends StatelessWidget {
  const _EmptyTravelArchive();

  static const _variants = [
    _TravelRecordFrameVariant.wide,
    _TravelRecordFrameVariant.portrait,
    _TravelRecordFrameVariant.narrow,
    _TravelRecordFrameVariant.wide,
    _TravelRecordFrameVariant.square,
    _TravelRecordFrameVariant.wide,
    _TravelRecordFrameVariant.narrow,
    _TravelRecordFrameVariant.wide,
    _TravelRecordFrameVariant.portrait,
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 22, 18, 24),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.82),
        borderRadius: BorderRadius.circular(34),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.07),
            blurRadius: 28,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          const spacing = 12.0;
          final columnWidth = (constraints.maxWidth - spacing) / 2;
          final children = <Widget>[];

          for (var index = 0; index < _variants.length; index++) {
            final variant = _variants[index];
            final width = switch (variant) {
              _TravelRecordFrameVariant.wide => columnWidth,
              _TravelRecordFrameVariant.square => columnWidth * 0.72,
              _TravelRecordFrameVariant.portrait => columnWidth * 0.64,
              _TravelRecordFrameVariant.narrow => columnWidth * 0.52,
            };

            children.add(
              _EmptyTravelRecordFrame(
                index: index,
                variant: variant,
                width: width,
              ),
            );
          }

          return Wrap(
            spacing: spacing,
            runSpacing: 18,
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.start,
            children: children,
          );
        },
      ),
    );
  }
}

class _EmptyTravelRecordFrame extends StatelessWidget {
  const _EmptyTravelRecordFrame({
    required this.index,
    required this.variant,
    required this.width,
  });

  final int index;
  final _TravelRecordFrameVariant variant;
  final double width;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: AspectRatio(
        aspectRatio: variant.aspectRatio,
        child: _EmptyTravelRecordPhoto(
          index: index,
          variant: variant,
        ),
      ),
    );
  }
}

class _EmptyTravelRecordPhoto extends StatelessWidget {
  const _EmptyTravelRecordPhoto({
    required this.index,
    required this.variant,
  });

  final int index;
  final _TravelRecordFrameVariant variant;

  @override
  Widget build(BuildContext context) {
    final frameAsset =
        variant.usesPortraitFrame ? _filmFramePortrait : _filmFrameLandscape;
    final tint = _emptyRecordTint(index);

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final height = constraints.maxHeight;
        final photoInsets = variant.usesPortraitFrame
            ? EdgeInsets.fromLTRB(
                width * 0.31,
                height * 0.22,
                width * 0.33,
                height * 0.22,
              )
            : EdgeInsets.fromLTRB(
                width * 0.18,
                height * 0.26,
                width * 0.19,
                height * 0.34,
              );

        return Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: _travelFilm,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.07),
                      blurRadius: 14,
                      offset: const Offset(0, 7),
                    ),
                  ],
                ),
              ),
            ),
            Positioned.fill(
              child: Padding(
                padding: photoInsets,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(7),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          tint.withValues(alpha: 0.26),
                          AppColors.primaryTint.withValues(alpha: 0.18),
                          AppColors.surface.withValues(alpha: 0.9),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Positioned.fill(
              child: Image.asset(
                frameAsset,
                fit: BoxFit.fill,
                filterQuality: FilterQuality.medium,
              ),
            ),
            if (index == 0 || index == 3 || index == 7)
              Positioned(
                top: variant.usesPortraitFrame ? 8 : 10,
                right: variant.usesPortraitFrame ? 10 : 12,
                child: Opacity(
                  opacity: 0.42,
                  child: _EmptyTravelRecordStamp(
                    label: index == 3 ? '미션' : '스탬프',
                    color:
                        index == 3 ? const Color(0xFF4F8CCB) : _travelPrimary,
                    icon: index == 3
                        ? Icons.flag_rounded
                        : Icons.location_on_rounded,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _EmptyTravelRecordStamp extends StatelessWidget {
  const _EmptyTravelRecordStamp({
    required this.label,
    required this.color,
    required this.icon,
  });

  final String label;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: -0.06,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 5),
        decoration: BoxDecoration(
          color: AppColors.surface.withValues(alpha: 0.76),
          border: Border.all(color: color.withValues(alpha: 0.62)),
          borderRadius: BorderRadius.circular(7),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 14),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 8,
                fontWeight: FontWeight.w900,
                letterSpacing: 0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Color _emptyRecordTint(int index) {
  return switch (index % 5) {
    0 => const Color(0xFF79B8D8),
    1 => const Color(0xFF8FBF75),
    2 => const Color(0xFFB7D7A8),
    3 => const Color(0xFFF1C46D),
    _ => const Color(0xFF8ECAC4),
  };
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

String _formatHandwrittenDate(DateTime visitedAt) {
  final local = visitedAt.toLocal();
  final month = local.month.toString().padLeft(2, '0');
  final day = local.day.toString().padLeft(2, '0');
  return '${local.year}. $month. $day';
}
