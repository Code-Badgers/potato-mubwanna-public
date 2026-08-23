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
                                _showTravelRecordPreview(context, record),
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

void _showTravelRecordPreview(BuildContext context, TravelRecord record) {
  showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: '여행 기록 닫기',
    barrierColor: Colors.black.withValues(alpha: 0.62),
    transitionDuration: const Duration(milliseconds: 180),
    pageBuilder: (context, animation, secondaryAnimation) {
      return _TravelRecordPreviewModal(record: record);
    },
    transitionBuilder: (context, animation, secondaryAnimation, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
      );
      return FadeTransition(
        opacity: curved,
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.94, end: 1).animate(curved),
          child: child,
        ),
      );
    },
  );
}

void _showEmptyTravelRecordPreview(
  BuildContext context,
  _EmptyTravelRecordPreview preview,
) {
  showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: '여행 기록 미리보기 닫기',
    barrierColor: Colors.black.withValues(alpha: 0.62),
    transitionDuration: const Duration(milliseconds: 220),
    pageBuilder: (_, __, ___) => _EmptyTravelRecordPreviewModal(
      preview: preview,
    ),
    transitionBuilder: (context, animation, secondaryAnimation, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
      );
      return FadeTransition(
        opacity: curved,
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.94, end: 1).animate(curved),
          child: child,
        ),
      );
    },
  );
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
    return LayoutBuilder(
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
              index: index,
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
        _TravelRecordFrameVariant.wide => 1.04,
        _TravelRecordFrameVariant.portrait => 0.58,
        _TravelRecordFrameVariant.square => 0.7,
        _TravelRecordFrameVariant.narrow => 0.54,
      };

  bool get usesPortraitFrame =>
      this == _TravelRecordFrameVariant.portrait ||
      this == _TravelRecordFrameVariant.narrow;
}

class _TravelRecordTypeStamp extends StatelessWidget {
  const _TravelRecordTypeStamp({required this.record});

  final TravelRecord record;

  bool get _isMissionPhoto {
    final uploadedImageUrl = record.uploadedImageUrl?.trim();
    return uploadedImageUrl != null && uploadedImageUrl.isNotEmpty;
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
        key: ValueKey('travel-record-type-${record.visitId}'),
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
    required this.index,
    required this.variant,
    required this.width,
    required this.onTap,
  });

  final TravelRecord record;
  final int index;
  final _TravelRecordFrameVariant variant;
  final double width;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final angle = switch (index % 6) {
      0 => -0.018,
      1 => 0.014,
      2 => -0.01,
      3 => 0.018,
      4 => -0.006,
      _ => 0.01,
    };

    return Transform.rotate(
      angle: angle,
      child: Material(
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
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final height = constraints.maxHeight;
        final photoInsets = variant.usesPortraitFrame
            ? EdgeInsets.fromLTRB(
                width * 0.14,
                height * 0.07,
                width * 0.14,
                height * 0.37,
              )
            : EdgeInsets.fromLTRB(
                width * 0.08,
                height * 0.07,
                width * 0.08,
                height * 0.38,
              );

        return Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: const Color(0xFFFFFCF7),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: const Color(0xFFEDE5D8).withValues(alpha: 0.62),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 18,
                      offset: const Offset(0, 9),
                    ),
                  ],
                ),
              ),
            ),
            Positioned.fill(
              child: Padding(
                padding: photoInsets,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(5),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      _TravelRecordPhoto(record: record),
                      DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.white.withValues(alpha: 0.08),
                              Colors.transparent,
                              Colors.black.withValues(alpha: 0.04),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              left: 18,
              right: 18,
              bottom: variant.usesPortraitFrame ? 18 : 15,
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

class _TravelRecordPreviewModal extends StatelessWidget {
  const _TravelRecordPreviewModal({required this.record});

  final TravelRecord record;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Material(
        color: Colors.transparent,
        child: Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => Navigator.of(context).pop(),
              ),
            ),
            Center(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 92),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final cardWidth =
                        (constraints.maxWidth * 0.78).clamp(260.0, 340.0);
                    return SizedBox(
                      width: constraints.maxWidth,
                      height: constraints.maxHeight,
                      child: Stack(
                        alignment: Alignment.center,
                        clipBehavior: Clip.none,
                        children: [
                          Transform.translate(
                            offset: Offset(-cardWidth * 0.48, -34),
                            child: Transform.rotate(
                              angle: -0.13,
                              child: _TravelRecordBackdropFrame(
                                width: cardWidth * 0.76,
                                record: record,
                                opacity: 0.34,
                              ),
                            ),
                          ),
                          Transform.translate(
                            offset: Offset(cardWidth * 0.48, -24),
                            child: Transform.rotate(
                              angle: 0.12,
                              child: _TravelRecordBackdropFrame(
                                width: cardWidth * 0.7,
                                record: record,
                                opacity: 0.24,
                              ),
                            ),
                          ),
                          _TravelRecordPreviewCard(
                            width: cardWidth,
                            record: record,
                          ),
                          Positioned(
                            bottom: 10,
                            child: IconButton(
                              key:
                                  const ValueKey('travel-record-preview-close'),
                              tooltip: '닫기',
                              onPressed: () => Navigator.of(context).pop(),
                              icon: const Icon(Icons.close_rounded),
                              color: Colors.white,
                              style: IconButton.styleFrom(
                                backgroundColor:
                                    Colors.white.withValues(alpha: 0.18),
                                side: BorderSide(
                                  color: Colors.white.withValues(alpha: 0.34),
                                ),
                                fixedSize: const Size(48, 48),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TravelRecordPreviewCard extends StatelessWidget {
  const _TravelRecordPreviewCard({
    required this.width,
    required this.record,
  });

  final double width;
  final TravelRecord record;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey('travel-record-preview-card'),
      width: width,
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 26),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFCF7),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(
          color: const Color(0xFFEDE5D8).withValues(alpha: 0.7),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.34),
            blurRadius: 30,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AspectRatio(
            aspectRatio: 0.9,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(7),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  _TravelRecordPhoto(record: record),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.white.withValues(alpha: 0.08),
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.05),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    top: 10,
                    right: 10,
                    child: _TravelRecordTypeStamp(record: record),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            record.spotName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.w900,
              fontStyle: FontStyle.italic,
              letterSpacing: 0,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _formatHandwrittenDate(record.visitedAt),
            style: TextStyle(
              color: AppColors.textSecondary.withValues(alpha: 0.86),
              fontSize: 15,
              fontWeight: FontWeight.w800,
              fontStyle: FontStyle.italic,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}

class _TravelRecordBackdropFrame extends StatelessWidget {
  const _TravelRecordBackdropFrame({
    required this.width,
    required this.record,
    required this.opacity,
  });

  final double width;
  final TravelRecord record;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Opacity(
        opacity: opacity,
        child: SizedBox(
          width: width,
          child: AspectRatio(
            aspectRatio: 0.66,
            child: _TravelRecordFramedPhoto(
              record: record,
              variant: _TravelRecordFrameVariant.portrait,
            ),
          ),
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
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
      children: [
        _EmptyTravelArchive(
          onFrameSelected: (preview) =>
              _showEmptyTravelRecordPreview(context, preview),
        ),
      ],
    );
  }
}

class _EmptyTravelArchive extends StatelessWidget {
  const _EmptyTravelArchive({required this.onFrameSelected});

  final ValueChanged<_EmptyTravelRecordPreview> onFrameSelected;

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
      padding: const EdgeInsets.symmetric(horizontal: 2),
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
                onTap: () => onFrameSelected(
                  _EmptyTravelRecordPreview(
                    index: index,
                    variant: variant,
                  ),
                ),
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
    required this.onTap,
  });

  final int index;
  final _TravelRecordFrameVariant variant;
  final double width;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final angle = switch (index % 6) {
      0 => -0.018,
      1 => 0.014,
      2 => -0.01,
      3 => 0.018,
      4 => -0.006,
      _ => 0.01,
    };

    return Transform.rotate(
      angle: angle,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          key: ValueKey('empty-travel-record-frame-$index'),
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: SizedBox(
            width: width,
            child: AspectRatio(
              aspectRatio: variant.aspectRatio,
              child: _EmptyTravelRecordPhoto(
                index: index,
                variant: variant,
              ),
            ),
          ),
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
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final height = constraints.maxHeight;
        final photoInsets = variant.usesPortraitFrame
            ? EdgeInsets.fromLTRB(
                width * 0.16,
                height * 0.08,
                width * 0.16,
                height * 0.36,
              )
            : EdgeInsets.fromLTRB(
                width * 0.09,
                height * 0.08,
                width * 0.09,
                height * 0.37,
              );

        return Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: const Color(0xFFFFFCF7),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: const Color(0xFFEDE5D8).withValues(alpha: 0.56),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.07),
                      blurRadius: 17,
                      offset: const Offset(0, 9),
                    ),
                  ],
                ),
              ),
            ),
            Positioned.fill(
              child: Padding(
                padding: photoInsets,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(5),
                  child: _TravelRecordPlaceholderImage(index: index),
                ),
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

class _TravelRecordPlaceholderImage extends StatelessWidget {
  const _TravelRecordPlaceholderImage({required this.index});

  final int index;

  @override
  Widget build(BuildContext context) {
    final tint = _emptyRecordTint(index);

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            tint.withValues(alpha: 0.3),
            AppColors.primaryTint.withValues(alpha: 0.2),
            AppColors.surface.withValues(alpha: 0.94),
          ],
        ),
      ),
    );
  }
}

class _EmptyTravelRecordPreview {
  const _EmptyTravelRecordPreview({
    required this.index,
    required this.variant,
  });

  final int index;
  final _TravelRecordFrameVariant variant;

  bool get isMission => index == 3 || index == 7;

  String get badgeLabel => isMission ? '미션' : '스탬프';

  Color get badgeColor => isMission ? const Color(0xFF4F8CCB) : _travelPrimary;

  IconData get badgeIcon =>
      isMission ? Icons.flag_rounded : Icons.location_on_rounded;
}

class _EmptyTravelRecordPreviewModal extends StatelessWidget {
  const _EmptyTravelRecordPreviewModal({required this.preview});

  final _EmptyTravelRecordPreview preview;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Material(
        color: Colors.transparent,
        child: Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => Navigator.of(context).pop(),
              ),
            ),
            Center(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 92),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final cardWidth =
                        (constraints.maxWidth * 0.78).clamp(260.0, 340.0);
                    return SizedBox(
                      width: constraints.maxWidth,
                      height: constraints.maxHeight,
                      child: Stack(
                        alignment: Alignment.center,
                        clipBehavior: Clip.none,
                        children: [
                          Transform.translate(
                            offset: Offset(-cardWidth * 0.46, -30),
                            child: Transform.rotate(
                              angle: -0.12,
                              child: _EmptyTravelRecordBackdropFrame(
                                width: cardWidth * 0.7,
                                preview: preview,
                                indexOffset: 1,
                                opacity: 0.26,
                              ),
                            ),
                          ),
                          Transform.translate(
                            offset: Offset(cardWidth * 0.45, -22),
                            child: Transform.rotate(
                              angle: 0.11,
                              child: _EmptyTravelRecordBackdropFrame(
                                width: cardWidth * 0.66,
                                preview: preview,
                                indexOffset: 2,
                                opacity: 0.2,
                              ),
                            ),
                          ),
                          _EmptyTravelRecordPreviewCard(
                            width: cardWidth,
                            preview: preview,
                          ),
                          Positioned(
                            bottom: 10,
                            child: IconButton(
                              key: const ValueKey(
                                'empty-travel-record-preview-close',
                              ),
                              tooltip: '닫기',
                              onPressed: () => Navigator.of(context).pop(),
                              icon: const Icon(Icons.close_rounded),
                              color: Colors.white,
                              style: IconButton.styleFrom(
                                backgroundColor:
                                    Colors.white.withValues(alpha: 0.18),
                                side: BorderSide(
                                  color: Colors.white.withValues(alpha: 0.34),
                                ),
                                fixedSize: const Size(48, 48),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyTravelRecordPreviewCard extends StatelessWidget {
  const _EmptyTravelRecordPreviewCard({
    required this.width,
    required this.preview,
  });

  final double width;
  final _EmptyTravelRecordPreview preview;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey('empty-travel-record-preview-card'),
      width: width,
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 28),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFCF7),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(
          color: const Color(0xFFEDE5D8).withValues(alpha: 0.72),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.34),
            blurRadius: 30,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AspectRatio(
            aspectRatio: 0.92,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(7),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  _TravelRecordPlaceholderImage(index: preview.index),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.white.withValues(alpha: 0.1),
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.03),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    top: 10,
                    right: 10,
                    child: _EmptyTravelRecordStamp(
                      label: preview.badgeLabel,
                      color: preview.badgeColor,
                      icon: preview.badgeIcon,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            '곧 채워질 여행 사진',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.w900,
              fontStyle: FontStyle.italic,
              letterSpacing: 0,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '여행을 남겨보세요',
            style: TextStyle(
              color: AppColors.textSecondary.withValues(alpha: 0.86),
              fontSize: 15,
              fontWeight: FontWeight.w800,
              fontStyle: FontStyle.italic,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyTravelRecordBackdropFrame extends StatelessWidget {
  const _EmptyTravelRecordBackdropFrame({
    required this.width,
    required this.preview,
    required this.indexOffset,
    required this.opacity,
  });

  final double width;
  final _EmptyTravelRecordPreview preview;
  final int indexOffset;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Opacity(
        opacity: opacity,
        child: SizedBox(
          width: width,
          child: AspectRatio(
            aspectRatio: 0.58,
            child: _EmptyTravelRecordPhoto(
              index: preview.index + indexOffset,
              variant: _TravelRecordFrameVariant.portrait,
            ),
          ),
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
