import 'package:flutter/material.dart';
import '../../../../shared/widgets/app_state_message.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_design_tokens.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../shared/widgets/loading/potato_loading_view.dart';
import '../../../feature_tour/presentation/feature_tour_host.dart';
import '../../../feature_tour/presentation/feature_tour_targets.dart';
import '../../../map/application/map_spot_controller.dart';
import '../../../map/domain/spot_detail.dart';
import '../../application/stamp_book_controller.dart';
import '../../domain/stamp_book.dart';
import '../model/gangwon_context_region.dart';
import '../model/gangwon_map_projection.dart';
import '../model/gangwon_map_region.dart';

class StampBookScreen extends ConsumerWidget {
  const StampBookScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stampBook = ref.watch(stampBookProvider);
    final rallybookSpots = ref.watch(stampRallybookSpotsProvider);
    final rewardClaim = ref.watch(stampRewardClaimProvider);
    ref.listen(stampRewardClaimProvider, (_, next) {
      next.whenOrNull(
        data: (result) {
          if (result == null) {
            return;
          }
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(
              SnackBar(content: Text('${result.couponName}을 받았어요.')),
            );
        },
        error: (error, _) {
          final message = error is ApiException && error.message.isNotEmpty
              ? error.message
              : '스탬프 보상 기록을 저장하지 못했습니다. 잠시 후 다시 시도해 주세요.';
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(SnackBar(content: Text(message)));
        },
      );
    });

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: stampBook.when(
          data: (value) => value == null
              ? const _SignedOutState()
              : _StampBookBody(
                  stampBook: value,
                  rallybookSpots: rallybookSpots,
                  isRewardClaiming: rewardClaim.isLoading,
                  onClaimReward: () {
                    final targetCount = value.nextReward.claimableTargetCount;
                    if (targetCount == null) {
                      return;
                    }
                    ref
                        .read(stampRewardClaimProvider.notifier)
                        .claim(targetCount);
                  },
                ),
          loading: () => const _StampBookStatusBody(
            child: PotatoLoadingView.compact(
              subtitle: '강원도 스탬프 지도를 준비하고 있어요',
            ),
          ),
          error: (_, __) => _StampBookStatusBody(
            child: _StampBookError(
              onRetry: () => ref.invalidate(stampBookProvider),
            ),
          ),
        ),
      ),
    );
  }
}

class PassportStampGridScreen extends ConsumerWidget {
  const PassportStampGridScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stampBook = ref.watch(stampBookProvider);
    final rallybookSpots = ref.watch(stampRallybookSpotsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: stampBook.when(
          data: (value) => value == null
              ? const _SignedOutState()
              : _PassportStampGridBody(
                  progress: value.progress,
                  rallybookSpots: rallybookSpots,
                ),
          loading: () => const PotatoLoadingView.fullScreen(
            subtitle: '여행 패스포트를 펼치고 있어요',
          ),
          error: (_, __) => _StampBookStatusBody(
            child: _StampBookError(
              onRetry: () => ref.invalidate(stampBookProvider),
            ),
          ),
        ),
      ),
    );
  }
}

class _PassportStampGridBody extends StatelessWidget {
  const _PassportStampGridBody({
    required this.progress,
    required this.rallybookSpots,
  });

  final StampProgress progress;
  final AsyncValue<List<RallybookSpot>?> rallybookSpots;

  @override
  Widget build(BuildContext context) {
    final spots = rallybookSpots.maybeWhen(
      data: (values) => values ?? const <RallybookSpot>[],
      orElse: () => const <RallybookSpot>[],
    );
    final entries = spots.isEmpty
        ? _fallbackPassportEntries(progress.stamps)
        : _passportEntriesFor(spots, progress.stamps);
    final totalCount = entries.isEmpty ? 29 : entries.length;
    final acquiredCount = entries.where((entry) => entry.acquired).length;
    final pages = _paginatePassportEntries(entries);

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
            child: _PassportHeader(onBack: () => _goBack(context))),
        SliverToBoxAdapter(
          child: _PassportSummaryCard(
            acquiredCount: acquiredCount,
            totalCount: totalCount,
          ),
        ),
        SliverToBoxAdapter(
          child: KeyedSubtree(
            key: FeatureTourTargets.passportBook,
            child: _PassportPageBook(
              pages: pages,
              acquiredCount: acquiredCount,
              totalCount: totalCount,
            ),
          ),
        ),
      ],
    );
  }
}

void _goBack(BuildContext context) {
  if (Navigator.of(context).canPop()) {
    context.pop();
    return;
  }
  context.go('/main/mypage');
}

class _PassportSummaryCard extends StatelessWidget {
  const _PassportSummaryCard({
    required this.acquiredCount,
    required this.totalCount,
  });

  final int acquiredCount;
  final int totalCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(24, 2, 24, 18),
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.surface,
            AppColors.primaryTint.withValues(alpha: 0.58),
          ],
        ),
        borderRadius: BorderRadius.circular(AppDimens.cardRadius),
        boxShadow: AppShadows.softCard,
      ),
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: const BoxDecoration(
              color: AppColors.surface,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.confirmation_number_rounded,
              color: AppColors.primaryDark,
              size: 25,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '강원 여행 패스포트',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  '명소에서 인증하면 스탬프가 채워져요',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            decoration: BoxDecoration(
              color: AppColors.surface.withValues(alpha: 0.86),
              borderRadius: BorderRadius.circular(AppDimens.pillRadius),
            ),
            child: Text(
              '$acquiredCount / $totalCount',
              style: const TextStyle(
                color: AppColors.actionGreen,
                fontSize: 16,
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

class _PassportHeader extends StatelessWidget {
  const _PassportHeader({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
      child: Row(
        children: [
          IconButton.filledTonal(
            onPressed: onBack,
            icon: const Icon(Icons.arrow_back_rounded),
            tooltip: '이전 화면으로 돌아가기',
            style: IconButton.styleFrom(
              backgroundColor: AppColors.surface,
              foregroundColor: AppColors.textPrimary,
            ),
          ),
          const Spacer(),
        ],
      ),
    );
  }
}

class _PassportPageBook extends StatelessWidget {
  const _PassportPageBook({
    required this.pages,
    required this.acquiredCount,
    required this.totalCount,
  });

  final List<List<_PassportStampEntry>> pages;
  final int acquiredCount;
  final int totalCount;

  @override
  Widget build(BuildContext context) {
    if (pages.isEmpty) {
      return const SizedBox.shrink();
    }

    return SizedBox(
      height: 500,
      child: PageView.builder(
        controller: PageController(viewportFraction: 0.9),
        itemCount: pages.length,
        itemBuilder: (context, index) => Padding(
          padding: const EdgeInsets.fromLTRB(0, 2, 12, 32),
          child: _PassportSpread(
            stamps: pages[index],
            pageNumber: index + 1,
            pageCount: pages.length,
            showGuide: index == 0,
            acquiredCount: acquiredCount,
            totalCount: totalCount,
          ),
        ),
      ),
    );
  }
}

class _PassportSpread extends StatelessWidget {
  const _PassportSpread({
    required this.stamps,
    required this.pageNumber,
    required this.pageCount,
    required this.showGuide,
    required this.acquiredCount,
    required this.totalCount,
  });

  final List<_PassportStampEntry> stamps;
  final int pageNumber;
  final int pageCount;
  final bool showGuide;
  final int acquiredCount;
  final int totalCount;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8E8),
        borderRadius: BorderRadius.circular(24),
        boxShadow: AppShadows.floating,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: CustomPaint(
          painter: const _PassportPaperPainter(),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'GANGWON PASSPORT',
                        style: TextStyle(
                          color: AppColors.actionGreen,
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                    Text(
                      '$pageNumber / $pageCount',
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (showGuide) ...[
                  const Text(
                    '도장을 모으면 강원 여행 패스포트가 채워져요',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                      height: 1.35,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0,
                    ),
                  ),
                  const SizedBox(height: 18),
                ] else
                  const SizedBox(height: 12),
                Expanded(
                  child: Column(
                    children: [
                      for (var index = 0; index < stamps.length; index++) ...[
                        Expanded(
                          child: _PassportStampTile(entry: stamps[index]),
                        ),
                        if (index < stamps.length - 1)
                          const SizedBox(height: 8),
                      ],
                    ],
                  ),
                ),
                if (showGuide) ...[
                  const SizedBox(height: 14),
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.swipe_rounded,
                        size: 16,
                        color: AppColors.textSecondary,
                      ),
                      SizedBox(width: 5),
                      Text(
                        '좌우로 넘겨 다음 페이지 보기',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PassportPaperPainter extends CustomPainter {
  const _PassportPaperPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final spinePaint = Paint()
      ..color = AppColors.brown.withValues(alpha: 0.08)
      ..strokeWidth = 2;
    canvas.drawLine(
      Offset(size.width * 0.5, 0),
      Offset(size.width * 0.5, size.height),
      spinePaint,
    );

    final postmarkPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..color = AppColors.primaryDark.withValues(alpha: 0.12);
    canvas.drawCircle(Offset(size.width - 52, 54), 25, postmarkPaint);
    canvas.drawCircle(Offset(size.width - 52, 54), 15, postmarkPaint);

    final stripePaint = Paint()
      ..color = AppColors.brown.withValues(alpha: 0.08)
      ..strokeWidth = 4;
    for (var x = -size.height; x < size.width; x += 22) {
      canvas.drawLine(
        Offset(x.toDouble(), size.height),
        Offset(x + 14, size.height - 14),
        stripePaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _PassportPaperPainter oldDelegate) => false;
}

class _PassportStampTile extends StatelessWidget {
  const _PassportStampTile({required this.entry});

  final _PassportStampEntry entry;

  @override
  Widget build(BuildContext context) {
    final acquired = entry.acquired;
    final sketchAsset = _passportSketchAssetFor(entry.cityName, entry.landmark);

    return Container(
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
      decoration: BoxDecoration(
        color: acquired
            ? AppColors.surface.withValues(alpha: 0.54)
            : AppColors.surface.withValues(alpha: 0.36),
        borderRadius: BorderRadius.circular(AppDimens.compactCardRadius),
        border: Border.all(
          color: acquired
              ? AppColors.primary.withValues(alpha: 0.22)
              : AppColors.line.withValues(alpha: 0.44),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 58,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CustomPaint(
                  size: const Size.square(54),
                  painter: _PassportStampSlotPainter(acquired: acquired),
                ),
                if (acquired)
                  Transform.rotate(
                    angle: -0.16,
                    child: Text(
                      '감자무봤나',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppColors.actionGreen.withValues(alpha: 0.78),
                        fontSize: 8,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 84,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.cityName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: acquired
                        ? AppColors.textPrimary
                        : AppColors.textSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  entry.landmark,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: acquired
                        ? AppColors.primaryDark
                        : AppColors.textSecondary,
                    fontSize: 17,
                    height: 1.06,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            flex: 3,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Transform.scale(
                    scale: 1.22,
                    child: Image.asset(
                      sketchAsset,
                      fit: BoxFit.contain,
                      alignment: Alignment.center,
                      filterQuality: FilterQuality.high,
                    ),
                  ),
                  const _PassportSketchFade(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PassportSketchFade extends StatelessWidget {
  const _PassportSketchFade();

  @override
  Widget build(BuildContext context) {
    return const IgnorePointer(
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            radius: 0.9,
            colors: [
              Color(0x00FFFDF7),
              Color(0x00FFFDF7),
              Color(0xAAFFFDF7),
            ],
            stops: [0, 0.68, 1],
          ),
        ),
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color(0xDDFFFDF7),
                Color(0x00FFFDF7),
                Color(0x00FFFDF7),
                Color(0xBBFFFDF7),
              ],
              stops: [0, 0.11, 0.89, 1],
            ),
          ),
        ),
      ),
    );
  }
}

class _PassportStampSlotPainter extends CustomPainter {
  const _PassportStampSlotPainter({required this.acquired});

  final bool acquired;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.shortestSide / 2 - 3;
    final baseColor = acquired ? AppColors.primaryDark : AppColors.secondary;
    final outerPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = acquired ? 2.8 : 1.8
      ..color = baseColor.withValues(alpha: acquired ? 0.72 : 0.78);
    final innerPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..color = baseColor.withValues(alpha: acquired ? 0.42 : 0.64);

    canvas.drawCircle(center, radius, outerPaint);
    canvas.drawCircle(center, radius * 0.72, innerPaint);

    if (acquired) {
      final fillPaint = Paint()
        ..style = PaintingStyle.fill
        ..color = AppColors.primary.withValues(alpha: 0.09);
      canvas.drawCircle(center, radius * 0.9, fillPaint);
      final linePaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.1
        ..color = AppColors.primaryDark.withValues(alpha: 0.24);
      for (var index = -2; index <= 2; index += 1) {
        final dy = index * radius * 0.26;
        canvas.drawLine(
          Offset(center.dx - radius * 0.72, center.dy + dy),
          Offset(center.dx + radius * 0.72, center.dy + dy - radius * 0.34),
          linePaint,
        );
      }
      return;
    }

    final dashPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.1
      ..strokeCap = StrokeCap.round
      ..color = baseColor.withValues(alpha: 0.58);
    const dashCount = 18;
    for (var index = 0; index < dashCount; index += 1) {
      final start = index * 2 * 3.141592653589793 / dashCount;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius * 0.86),
        start,
        0.13,
        false,
        dashPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _PassportStampSlotPainter oldDelegate) {
    return oldDelegate.acquired != acquired;
  }
}

class _PassportStampEntry {
  const _PassportStampEntry({
    required this.id,
    required this.cityName,
    required this.landmark,
    required this.acquired,
  });

  final int id;
  final String cityName;
  final String landmark;
  final bool acquired;
}

List<_PassportStampEntry> _passportEntriesFor(
  List<RallybookSpot> spots,
  List<RallybookStamp> stamps,
) {
  return spots
      .map(
        (spot) => _PassportStampEntry(
          id: spot.spotId,
          cityName: _normalizeCityName(spot.cityName),
          landmark: spot.spotName,
          acquired: _isPassportSpotAcquired(spot, stamps),
        ),
      )
      .toList(growable: false);
}

List<_PassportStampEntry> _fallbackPassportEntries(
  List<RallybookStamp> stamps,
) {
  if (stamps.isNotEmpty) {
    return stamps
        .map(
          (stamp) => _PassportStampEntry(
            id: stamp.spotId,
            cityName: _normalizeCityName(stamp.cityName),
            landmark: stamp.stampName,
            acquired: stamp.acquired,
          ),
        )
        .toList(growable: false);
  }

  return _defaultPassportEntries
      .map(
        (entry) => _PassportStampEntry(
          id: entry.id,
          cityName: entry.cityName,
          landmark: entry.landmark,
          acquired: false,
        ),
      )
      .toList(growable: false);
}

bool _isPassportSpotAcquired(
  RallybookSpot spot,
  List<RallybookStamp> stamps,
) {
  return stamps.any((stamp) => stamp.spotId == spot.spotId && stamp.acquired);
}

List<List<_PassportStampEntry>> _paginatePassportEntries(
  List<_PassportStampEntry> entries,
) {
  const pageSizes = [3, 4, 4, 4, 4, 4, 3, 3];
  final pages = <List<_PassportStampEntry>>[];
  var cursor = 0;

  for (final size in pageSizes) {
    if (cursor >= entries.length) {
      break;
    }
    final end = (cursor + size).clamp(0, entries.length);
    pages.add(entries.sublist(cursor, end));
    cursor = end;
  }

  while (cursor < entries.length) {
    final end = (cursor + 4).clamp(0, entries.length);
    pages.add(entries.sublist(cursor, end));
    cursor = end;
  }

  return pages;
}

const _defaultPassportEntries = <_PassportStampEntry>[
  _PassportStampEntry(id: 1, cityName: '춘천', landmark: '남이섬', acquired: false),
  _PassportStampEntry(
    id: 2,
    cityName: '춘천',
    landmark: '소양강 스카이워크',
    acquired: false,
  ),
  _PassportStampEntry(
      id: 3, cityName: '원주', landmark: '뮤지엄 산', acquired: false),
  _PassportStampEntry(id: 4, cityName: '강릉', landmark: '경포대', acquired: false),
  _PassportStampEntry(id: 5, cityName: '강릉', landmark: '안목해변', acquired: false),
  _PassportStampEntry(id: 6, cityName: '동해', landmark: '논골담길', acquired: false),
  _PassportStampEntry(id: 7, cityName: '동해', landmark: '묵호등대', acquired: false),
  _PassportStampEntry(id: 8, cityName: '태백', landmark: '황지연못', acquired: false),
  _PassportStampEntry(
    id: 9,
    cityName: '속초',
    landmark: '속초관광수산시장',
    acquired: false,
  ),
  _PassportStampEntry(id: 10, cityName: '속초', landmark: '영금정', acquired: false),
  _PassportStampEntry(id: 11, cityName: '삼척', landmark: '장호항', acquired: false),
  _PassportStampEntry(id: 12, cityName: '삼척', landmark: '환선굴', acquired: false),
  _PassportStampEntry(
      id: 13, cityName: '홍천', landmark: '비발디파크', acquired: false),
  _PassportStampEntry(id: 14, cityName: '홍천', landmark: '수타사', acquired: false),
  _PassportStampEntry(
      id: 15, cityName: '횡성', landmark: '횡성호수길', acquired: false),
  _PassportStampEntry(id: 16, cityName: '영월', landmark: '장릉', acquired: false),
  _PassportStampEntry(id: 17, cityName: '영월', landmark: '청령포', acquired: false),
  _PassportStampEntry(
    id: 18,
    cityName: '평창',
    landmark: '대관령 양떼목장',
    acquired: false,
  ),
  _PassportStampEntry(
    id: 19,
    cityName: '평창',
    landmark: '이효석문학관',
    acquired: false,
  ),
  _PassportStampEntry(
      id: 20, cityName: '정선', landmark: '정선 5일장', acquired: false),
  _PassportStampEntry(id: 21, cityName: '철원', landmark: '고석정', acquired: false),
  _PassportStampEntry(
    id: 22,
    cityName: '화천',
    landmark: '산천어축제장',
    acquired: false,
  ),
  _PassportStampEntry(id: 23, cityName: '양구', landmark: '두타연', acquired: false),
  _PassportStampEntry(
    id: 24,
    cityName: '양구',
    landmark: '박수근미술관',
    acquired: false,
  ),
  _PassportStampEntry(
    id: 25,
    cityName: '인제',
    landmark: '원대리 자작나무숲',
    acquired: false,
  ),
  _PassportStampEntry(
    id: 26,
    cityName: '고성',
    landmark: '통일전망대',
    acquired: false,
  ),
  _PassportStampEntry(id: 27, cityName: '고성', landmark: '화진포', acquired: false),
  _PassportStampEntry(id: 28, cityName: '양양', landmark: '낙산사', acquired: false),
  _PassportStampEntry(
      id: 29, cityName: '양양', landmark: '서피비치', acquired: false),
];

String _passportSketchAssetFor(String cityName, String landmark) {
  final key = '${_normalizeCityName(cityName)} $landmark';
  if (key.contains('소양강')) {
    return 'assets/stamps/passport/spots/passport_spot_02_soyang_skywalk.png';
  }
  if (key.contains('경포')) {
    return 'assets/stamps/passport/spots/passport_spot_04_gyeongpodae.png';
  }
  if (key.contains('논골담')) {
    return 'assets/stamps/passport/spots/passport_spot_06_nongoldam_road.png';
  }
  if (key.contains('영금정')) {
    return 'assets/stamps/passport/spots/passport_spot_10_yeonggeumjeong.png';
  }
  if (key.contains('장호')) {
    return 'assets/stamps/passport/spots/passport_spot_11_jangho_port.png';
  }
  if (key.contains('비발디')) {
    return 'assets/stamps/passport/spots/passport_spot_13_vivaldi_park.png';
  }
  if (key.contains('장릉')) {
    return 'assets/stamps/passport/spots/passport_spot_16_jangneung.png';
  }
  if (key.contains('이효석')) {
    return 'assets/stamps/passport/spots/passport_spot_19_lee_hyoseok_museum.png';
  }
  if (key.contains('박수근')) {
    return 'assets/stamps/passport/spots/passport_spot_24_park_sookeun_museum.png';
  }
  if (key.contains('화진포')) {
    return 'assets/stamps/passport/spots/passport_spot_27_hwajinpo.png';
  }
  if (key.contains('낙산')) {
    return 'assets/stamps/passport/spots/passport_spot_28_naksansa.png';
  }

  final city = _normalizeCityName(cityName);
  return switch (city) {
    '춘천' => 'assets/stamps/passport/spots/passport_spot_01_nami_island.png',
    '원주' => 'assets/stamps/passport/spots/passport_spot_03_museum_san.png',
    '강릉' => 'assets/stamps/passport/spots/passport_spot_05_anmok_beach.png',
    '동해' =>
      'assets/stamps/passport/spots/passport_spot_07_mukho_lighthouse.png',
    '태백' => 'assets/stamps/passport/spots/passport_spot_08_hwangji_pond.png',
    '속초' => 'assets/stamps/passport/spots/passport_spot_09_sokcho_market.png',
    '삼척' => 'assets/stamps/passport/spots/passport_spot_12_hwanseon_cave.png',
    '홍천' => 'assets/stamps/passport/spots/passport_spot_14_sutasa.png',
    '횡성' =>
      'assets/stamps/passport/spots/passport_spot_15_hoengseong_lake_trail.png',
    '영월' => 'assets/stamps/passport/spots/passport_spot_17_cheongnyeongpo.png',
    '평창' =>
      'assets/stamps/passport/spots/passport_spot_18_daegwallyeong_sheep_ranch.png',
    '정선' =>
      'assets/stamps/passport/spots/passport_spot_20_jeongseon_market.png',
    '철원' => 'assets/stamps/passport/spots/passport_spot_21_goseokjeong.png',
    '화천' =>
      'assets/stamps/passport/spots/passport_spot_22_sancheoneo_festival.png',
    '양구' => 'assets/stamps/passport/spots/passport_spot_23_dutayeon.png',
    '인제' =>
      'assets/stamps/passport/spots/passport_spot_25_wondaeri_birch_forest.png',
    '고성' =>
      'assets/stamps/passport/spots/passport_spot_26_unification_observatory.png',
    '양양' => 'assets/stamps/passport/spots/passport_spot_29_surfyy_beach.png',
    _ => 'assets/stamps/passport/spots/passport_spot_01_nami_island.png',
  };
}

class _StampBookStatusBody extends StatelessWidget {
  const _StampBookStatusBody({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverFillRemaining(hasScrollBody: false, child: child),
      ],
    );
  }
}

class _StampBookBody extends StatelessWidget {
  const _StampBookBody({
    required this.stampBook,
    required this.rallybookSpots,
    required this.isRewardClaiming,
    required this.onClaimReward,
  });

  final StampBook stampBook;
  final AsyncValue<List<RallybookSpot>?> rallybookSpots;
  final bool isRewardClaiming;
  final VoidCallback onClaimReward;

  @override
  Widget build(BuildContext context) {
    final progress = stampBook.progress;
    return LayoutBuilder(
      builder: (context, constraints) {
        final hasClaimableReward = stampBook.nextReward.canClaim;
        final reservedHeight = hasClaimableReward ? 454 : 314;
        final mapHeight = (constraints.maxHeight - reservedHeight).clamp(
          376.0,
          432.0,
        );
        return CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: _StampTourHero(
                progress: progress,
                rallybookSpots: rallybookSpots,
              ),
            ),
            if (hasClaimableReward)
              SliverToBoxAdapter(
                child: _StampRewardClaimCard(
                  targetCount: stampBook.nextReward.claimableTargetCount!,
                  isLoading: isRewardClaiming,
                  onPressed: onClaimReward,
                ),
              ),
            SliverToBoxAdapter(
              child: KeyedSubtree(
                key: FeatureTourTargets.stampMap,
                child: _GangwonStampMap(
                  progress: progress,
                  rallybookSpots: rallybookSpots,
                  mapHeight: mapHeight,
                  hasClaimableReward: hasClaimableReward,
                  onSpotTap: (spot) => context.push('/spots/${spot.spotId}'),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: SizedBox(height: hasClaimableReward ? 58 : 10),
            ),
          ],
        );
      },
    );
  }
}

class _StampRewardClaimCard extends StatelessWidget {
  const _StampRewardClaimCard({
    required this.targetCount,
    required this.isLoading,
    required this.onPressed,
  });

  final int targetCount;
  final bool isLoading;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey('stamp-reward-claim-card'),
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 12),
      padding: const EdgeInsets.fromLTRB(16, 14, 14, 14),
      decoration: BoxDecoration(
        color: AppColors.cream,
        borderRadius: BorderRadius.circular(AppDimens.cardRadius),
        border: Border.all(color: AppColors.secondary.withValues(alpha: 0.34)),
        boxShadow: AppShadows.softCard,
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.surface.withValues(alpha: 0.9),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.card_giftcard_rounded,
              color: AppColors.primaryDark,
              size: 23,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$targetCount개 스탬프 달성!',
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0,
                  ),
                ),
                const SizedBox(height: 3),
                const Text(
                  '지금 달성 보상을 받을 수 있어요',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          FilledButton(
            key: const ValueKey('stamp-reward-claim-button'),
            onPressed: isLoading ? null : onPressed,
            style: FilledButton.styleFrom(
              minimumSize: const Size(88, 42),
              padding: const EdgeInsets.symmetric(horizontal: 14),
            ),
            child: isLoading
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.surface,
                    ),
                  )
                : const Text('보상 받기'),
          ),
        ],
      ),
    );
  }
}

class _StampTourHero extends StatelessWidget {
  const _StampTourHero({
    required this.progress,
    required this.rallybookSpots,
  });

  final StampProgress progress;
  final AsyncValue<List<RallybookSpot>?> rallybookSpots;

  @override
  Widget build(BuildContext context) {
    final spots = rallybookSpots.maybeWhen(
      data: (values) => values ?? const <RallybookSpot>[],
      orElse: () => const <RallybookSpot>[],
    );
    final entries = spots.isEmpty
        ? _fallbackPassportEntries(progress.stamps)
        : _passportEntriesFor(spots, progress.stamps);
    final totalCount = entries.isEmpty ? 29 : entries.length;
    final acquiredCount = entries.where((entry) => entry.acquired).length;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Expanded(
            child: Text(
              '강원도\n스탬프 투어',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 23,
                height: 1.15,
                fontWeight: FontWeight.w700,
                letterSpacing: 0,
              ),
            ),
          ),
          const SizedBox(width: 8),
          KeyedSubtree(
            key: FeatureTourTargets.passportButton,
            child: _StampTourProgressPill(
              acquiredCount: acquiredCount,
              totalCount: totalCount,
              onTap: () {
                FeatureTourScope.maybeOf(context)?.completeTarget(
                  FeatureTourTargets.passportButton,
                );
                context.push('/main/stamps/cities');
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _StampTourProgressPill extends StatelessWidget {
  const _StampTourProgressPill({
    required this.acquiredCount,
    required this.totalCount,
    required this.onTap,
  });

  final int acquiredCount;
  final int totalCount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: '강원 여행 패스포트 보기',
      child: Material(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimens.pillRadius),
        elevation: 0,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppDimens.pillRadius),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.card_travel_rounded,
                  color: AppColors.textSecondary,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Text(
                  '패스포트  $acquiredCount/$totalCount',
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0,
                  ),
                ),
                const SizedBox(width: 5),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.textSecondary,
                  size: 19,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _GangwonStampMap extends StatefulWidget {
  const _GangwonStampMap({
    required this.progress,
    required this.rallybookSpots,
    required this.mapHeight,
    required this.hasClaimableReward,
    required this.onSpotTap,
  });

  final StampProgress progress;
  final AsyncValue<List<RallybookSpot>?> rallybookSpots;
  final double mapHeight;
  final bool hasClaimableReward;
  final ValueChanged<RallybookSpot> onSpotTap;

  @override
  State<_GangwonStampMap> createState() => _GangwonStampMapState();
}

class _GangwonStampMapState extends State<_GangwonStampMap>
    with SingleTickerProviderStateMixin {
  String? _selectedCity;
  int? _selectedSpotId;
  String? _travelFromCity;
  late final AnimationController _travelController;
  List<RallybookStamp>? _cachedStamps;
  List<RallybookSpot>? _cachedSpots;
  _StampMapDerivedData? _cachedDerivedData;

  @override
  void initState() {
    super.initState();
    _travelController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 780),
    )..value = 1;
  }

  @override
  void dispose() {
    _travelController.dispose();
    super.dispose();
  }

  void _selectSpot(RallybookSpot spot) {
    if (_selectedSpotId == spot.spotId) {
      return;
    }
    final city = _normalizeCityName(spot.cityName);
    setState(() {
      _travelFromCity = _selectedCity;
      _selectedCity = city;
      _selectedSpotId = spot.spotId;
    });
    FeatureTourScope.maybeOf(context)?.completeTarget(
      FeatureTourTargets.stampMarker,
    );
    _travelController.forward(from: 0);
    if (widget.hasClaimableReward) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final visitContext = FeatureTourTargets.stampVisit.currentContext;
        if (mounted && visitContext != null) {
          // 보상 카드가 위를 차지해도 인증 CTA는 사용자가 직접 스크롤하지 않아도 보인다.
          Scrollable.ensureVisible(
            visitContext,
            alignment: 0.85,
            duration: const Duration(milliseconds: 240),
            curve: Curves.easeOutCubic,
          );
        }
      });
    }
  }

  void _selectCity(
    String city,
    Map<String, List<RallybookSpot>> spotsByCity,
  ) {
    final citySpots = spotsByCity[city];
    if (citySpots == null || citySpots.isEmpty) {
      return;
    }
    _selectSpot(citySpots.first);
  }

  @override
  Widget build(BuildContext context) {
    final rallybookSpots = widget.rallybookSpots.maybeWhen(
      data: (spots) => spots ?? const <RallybookSpot>[],
      orElse: () => const <RallybookSpot>[],
    );
    final derivedData = _derivedDataFor(
      rallybookSpots,
      widget.progress.stamps,
    );
    final stampsBySpotId = derivedData.stampsBySpotId;
    final spotsByCity = derivedData.spotsByCity;
    final completedByCity = derivedData.completedByCity;
    final selectedSpot = _selectedSpotId == null
        ? null
        : _findSpotById(rallybookSpots, _selectedSpotId!);
    final selectedRegion = selectedSpot == null
        ? null
        : _findRegion(_normalizeCityName(selectedSpot.cityName));
    final selectedStamp =
        selectedSpot == null ? null : stampsBySpotId[selectedSpot.spotId];

    return Column(
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          margin: const EdgeInsets.fromLTRB(16, 2, 16, 10),
          // 장소를 고른 뒤에는 아래 인증 카드까지 첫 화면에 보이도록 지도를 접는다.
          height: selectedSpot == null ? widget.mapHeight : 300,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFFEAF7F0),
                Color(0xFFDDF2FA),
              ],
            ),
            borderRadius: BorderRadius.circular(32),
            boxShadow: [
              BoxShadow(
                color: AppColors.primaryDark.withValues(alpha: 0.08),
                blurRadius: 28,
                offset: const Offset(0, 14),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final size = constraints.biggest;
              final mapRect = _gangwonMapRect(size);

              Widget buildSpotNode(
                RallybookSpot spot, {
                required bool selected,
                required bool coachTarget,
              }) {
                final anchor = _rallybookSpotAnchor(spot, mapRect);
                final width = selected ? 124.0 : 40.0;
                Widget marker = IgnorePointer(
                  child: _RallybookSpotMapNode(
                    spot: spot,
                    stamp: stampsBySpotId[spot.spotId],
                    selected: selected,
                  ),
                );
                if (coachTarget) {
                  marker = KeyedSubtree(
                    key: FeatureTourTargets.stampMarker,
                    child: marker,
                  );
                }
                return Positioned(
                  left: anchor.dx - width / 2,
                  top: anchor.dy - (selected ? 19 : 16),
                  width: width,
                  child: KeyedSubtree(
                    key: ValueKey('rallybook-spot-marker-${spot.spotId}'),
                    child: marker,
                  ),
                );
              }

              return GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTapDown: (details) => _handleMapTap(
                  details.localPosition,
                  mapRect: mapRect,
                  spots: rallybookSpots,
                  spotsByCity: spotsByCity,
                ),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    CustomPaint(
                      painter: _GangwonMapPainter(
                        completedByCity: completedByCity,
                        selectedCity: selectedRegion?.city,
                      ),
                      child: const SizedBox.expand(),
                    ),
                    if (selectedRegion != null && selectedSpot != null)
                      Positioned.fill(
                        child: IgnorePointer(
                          child: AnimatedBuilder(
                            animation: _travelController,
                            builder: (context, _) {
                              final start = _stampTravelStart(
                                mapRect,
                                fromCity: _travelFromCity,
                              );
                              return CustomPaint(
                                painter: _StampTravelRoutePainter(
                                  start: start,
                                  end: _rallybookSpotAnchor(
                                    selectedSpot,
                                    mapRect,
                                  ),
                                  progress: _travelController.value,
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    for (final entry in rallybookSpots.indexed)
                      if (entry.$2.spotId != selectedSpot?.spotId)
                        buildSpotNode(
                          entry.$2,
                          selected: false,
                          coachTarget: entry.$1 == 0,
                        ),
                    if (selectedSpot != null)
                      buildSpotNode(
                        selectedSpot,
                        selected: true,
                        coachTarget: rallybookSpots.isNotEmpty &&
                            rallybookSpots.first.spotId == selectedSpot.spotId,
                      ),
                    if (selectedRegion != null && selectedSpot != null)
                      Positioned.fill(
                        child: IgnorePointer(
                          child: AnimatedBuilder(
                            animation: _travelController,
                            builder: (context, _) {
                              final start = _stampTravelStart(
                                mapRect,
                                fromCity: _travelFromCity,
                              );
                              final end = _rallybookSpotAnchor(
                                selectedSpot,
                                mapRect,
                              );
                              final value = Curves.easeInOutCubic
                                  .transform(_travelController.value);
                              final position = Offset.lerp(start, end, value)!;

                              return Stack(
                                children: [
                                  Positioned(
                                    left: position.dx - 18,
                                    top: position.dy - 18,
                                    width: 36,
                                    height: 36,
                                    child: const _StampTravelCarMarker(),
                                  ),
                                ],
                              );
                            },
                          ),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
          child: _StampSpotActionCard(
            region: selectedRegion,
            stamp: selectedStamp,
            spot: selectedSpot,
            onSpotTap: selectedSpot == null
                ? null
                : () => widget.onSpotTap(selectedSpot),
          ),
        ),
      ],
    );
  }

  void _handleMapTap(
    Offset position, {
    required Rect mapRect,
    required List<RallybookSpot> spots,
    required Map<String, List<RallybookSpot>> spotsByCity,
  }) {
    final spot = _findSpotAtPosition(position, mapRect, spots);
    if (spot != null) {
      _selectSpot(spot);
      return;
    }

    final city = _hitTestRegion(position, mapRect);
    if (city != null) {
      _selectCity(city, spotsByCity);
    }
  }

  RallybookSpot? _findSpotAtPosition(
    Offset position,
    Rect mapRect,
    List<RallybookSpot> spots,
  ) {
    RallybookSpot? nearest;
    var nearestDistanceSquared = double.infinity;
    for (final spot in spots) {
      final anchor = _rallybookSpotAnchor(spot, mapRect);
      final distanceSquared = (anchor - position).distanceSquared;
      if (distanceSquared < nearestDistanceSquared) {
        nearest = spot;
        nearestDistanceSquared = distanceSquared;
      }
    }

    const markerHitRadius = 28.0;
    if (nearest == null ||
        nearestDistanceSquared > markerHitRadius * markerHitRadius) {
      return null;
    }
    return nearest;
  }

  _StampMapDerivedData _derivedDataFor(
    List<RallybookSpot> spots,
    List<RallybookStamp> stamps,
  ) {
    final cached = _cachedDerivedData;
    if (identical(_cachedSpots, spots) &&
        identical(_cachedStamps, stamps) &&
        cached != null) {
      return cached;
    }

    final stampsBySpotId = {
      for (final stamp in stamps) stamp.spotId: stamp,
    };
    final spotsByCity = <String, List<RallybookSpot>>{};
    for (final spot in spots) {
      spotsByCity
          .putIfAbsent(_normalizeCityName(spot.cityName), () => [])
          .add(spot);
    }
    final completedByCity = {
      for (final entry in spotsByCity.entries)
        entry.key: entry.value.every(
          (spot) => stampsBySpotId[spot.spotId]?.acquired ?? false,
        ),
    };

    final next = _StampMapDerivedData(
      stampsBySpotId: stampsBySpotId,
      spotsByCity: spotsByCity,
      completedByCity: completedByCity,
    );
    _cachedSpots = spots;
    _cachedStamps = stamps;
    _cachedDerivedData = next;
    return next;
  }
}

class _StampMapDerivedData {
  const _StampMapDerivedData({
    required this.stampsBySpotId,
    required this.spotsByCity,
    required this.completedByCity,
  });

  final Map<int, RallybookStamp> stampsBySpotId;
  final Map<String, List<RallybookSpot>> spotsByCity;
  final Map<String, bool> completedByCity;
}

class _GangwonMapPainter extends CustomPainter {
  const _GangwonMapPainter({
    required this.completedByCity,
    required this.selectedCity,
  });

  final Map<String, bool> completedByCity;
  final String? selectedCity;

  @override
  void paint(Canvas canvas, Size size) {
    assert(() {
      _logGangwonContextRegionsOnce();
      return true;
    }());

    final mapRect = _gangwonMapRect(size);
    final pathCache = _GangwonMapPathCache.forRect(mapRect);
    canvas.drawRect(
        Offset.zero & size, Paint()..color = const Color(0xFFDDF2FA));

    final fillPaint = Paint()..style = PaintingStyle.fill;
    final thinLinePaint = Paint()
      ..color = const Color(0xFFB9E2EA)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final selectedLinePaint = Paint()
      ..color = const Color(0xFF59B8C7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final landmassPaint = Paint()
      ..color = AppColors.primary.withValues(alpha: 0.22)
      ..style = PaintingStyle.fill;
    final landmassPath = pathCache.landmassPath;
    if (!landmassPath.getBounds().isEmpty) {
      canvas.drawPath(landmassPath, landmassPaint);
    }

    final fullPath = pathCache.fullPath;
    final coastlinePaint = Paint()
      ..color = const Color(0xFF9FCFE0).withValues(alpha: 0.55)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.6);
    canvas.drawPath(fullPath.shift(const Offset(7, 8)), coastlinePaint);

    for (final region in gangwonMapRegions) {
      if (region.city == selectedCity) {
        continue;
      }
      final path = pathCache.regionPath(region);
      final completed = completedByCity[region.city] ?? false;
      fillPaint.color = completed ? const Color(0xFFF1FFF6) : AppColors.surface;
      canvas.drawPath(path, fillPaint);
      canvas.drawPath(path, thinLinePaint);
    }

    final outerPaint = Paint()
      ..color = const Color(0xFFB9E2EA)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(fullPath, outerPaint);

    final selectedRegion =
        selectedCity == null ? null : _findRegion(selectedCity!);
    if (selectedRegion != null) {
      final path = _scaledPath(pathCache.regionPath(selectedRegion), 1.035);
      fillPaint.color = const Color(0xFFE9FBF4);
      canvas.drawPath(path, fillPaint);
      canvas.drawPath(path, selectedLinePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _GangwonMapPainter oldDelegate) {
    return oldDelegate.completedByCity != completedByCity ||
        oldDelegate.selectedCity != selectedCity;
  }
}

Offset _stampTravelStart(
  Rect mapRect, {
  String? fromCity,
}) {
  if (fromCity != null) {
    final fromRegion = _findRegion(fromCity);
    if (fromRegion != null) {
      return _stampRegionAnchor(fromRegion, mapRect);
    }
  }

  return Offset(
    mapRect.left + mapRect.width * 0.16,
    mapRect.top + mapRect.height * 0.86,
  );
}

Offset _stampRegionAnchor(GangwonMapRegion region, Rect mapRect) {
  return Offset(
    mapRect.left + region.anchor.dx * mapRect.width,
    mapRect.top + region.anchor.dy * mapRect.height,
  );
}

Offset _rallybookSpotAnchor(RallybookSpot spot, Rect mapRect) {
  final normalized = projectToGangwonMap(
    latitude: spot.latitude,
    longitude: spot.longitude,
  );
  return Offset(
    mapRect.left + normalized.dx * mapRect.width,
    mapRect.top + normalized.dy * mapRect.height,
  );
}

class _StampTravelRoutePainter extends CustomPainter {
  const _StampTravelRoutePainter({
    required this.start,
    required this.end,
    required this.progress,
  });

  final Offset start;
  final Offset end;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final control = Offset(
      (start.dx + end.dx) / 2,
      (start.dy + end.dy) / 2 - 44,
    );
    final routePaint = Paint()
      ..color = AppColors.primary.withValues(alpha: 0.52)
      ..style = PaintingStyle.fill;
    const dotCount = 22;
    for (var index = 0; index <= dotCount; index += 1) {
      final t = index / dotCount;
      if (t > progress) {
        break;
      }
      final point = _quadraticPoint(start, control, end, t);
      final fade = (0.42 + t * 0.36).clamp(0.0, 1.0);
      canvas.drawCircle(
        point,
        2.2,
        routePaint..color = AppColors.primary.withValues(alpha: fade),
      );
    }

    final haloPaint = Paint()
      ..color = AppColors.secondary.withValues(alpha: 0.16 * progress)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(end, 22 * progress, haloPaint);
  }

  Offset _quadraticPoint(Offset a, Offset control, Offset b, double t) {
    final oneMinusT = 1 - t;
    return Offset(
      oneMinusT * oneMinusT * a.dx +
          2 * oneMinusT * t * control.dx +
          t * t * b.dx,
      oneMinusT * oneMinusT * a.dy +
          2 * oneMinusT * t * control.dy +
          t * t * b.dy,
    );
  }

  @override
  bool shouldRepaint(covariant _StampTravelRoutePainter oldDelegate) {
    return oldDelegate.start != start ||
        oldDelegate.end != end ||
        oldDelegate.progress != progress;
  }
}

class _StampTravelCarMarker extends StatelessWidget {
  const _StampTravelCarMarker();

  @override
  Widget build(BuildContext context) {
    return const CustomPaint(
      painter: _StampTravelCarPainter(),
    );
  }
}

class _StampTravelCarPainter extends CustomPainter {
  const _StampTravelCarPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final bodyPaint = Paint()
      ..color = AppColors.primary
      ..style = PaintingStyle.fill;
    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.14)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.5);
    final windowPaint = Paint()
      ..color = const Color(0xFFDDF2FA)
      ..style = PaintingStyle.fill;
    final wheelPaint = Paint()
      ..color = const Color(0xFF6D6252)
      ..style = PaintingStyle.fill;

    final body = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        size.width * 0.19,
        size.height * 0.42,
        size.width * 0.62,
        size.height * 0.25,
      ),
      const Radius.circular(5),
    );
    final roof = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        size.width * 0.31,
        size.height * 0.29,
        size.width * 0.37,
        size.height * 0.22,
      ),
      const Radius.circular(5),
    );
    canvas.drawOval(
      Rect.fromLTWH(
        size.width * 0.18,
        size.height * 0.68,
        size.width * 0.64,
        size.height * 0.16,
      ),
      shadowPaint,
    );
    canvas.drawRRect(body, bodyPaint);
    canvas.drawRRect(roof, bodyPaint);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          size.width * 0.39,
          size.height * 0.34,
          size.width * 0.20,
          size.height * 0.12,
        ),
        const Radius.circular(2),
      ),
      windowPaint,
    );
    canvas.drawCircle(
      Offset(size.width * 0.33, size.height * 0.69),
      size.width * 0.055,
      wheelPaint,
    );
    canvas.drawCircle(
      Offset(size.width * 0.68, size.height * 0.69),
      size.width * 0.055,
      wheelPaint,
    );
    canvas.drawCircle(
      Offset(size.width * 0.75, size.height * 0.51),
      size.width * 0.025,
      Paint()..color = AppColors.secondary,
    );
  }

  @override
  bool shouldRepaint(covariant _StampTravelCarPainter oldDelegate) => false;
}

Rect _gangwonMapRect(Size size) {
  const mapAspectRatio = 1000 / 1180;
  final available = Rect.fromLTWH(10, 34, size.width - 20, size.height - 68);
  const westContextShift = Offset.zero;
  if (available.width / available.height > mapAspectRatio) {
    final width = available.height * mapAspectRatio;
    return Rect.fromLTWH(
      available.left + (available.width - width) / 2,
      available.top,
      width,
      available.height,
    ).shift(westContextShift);
  }
  final height = available.width / mapAspectRatio;
  return Rect.fromLTWH(
    available.left,
    available.top + (available.height - height) / 2,
    available.width,
    height,
  ).shift(westContextShift);
}

class _GangwonMapPathCache {
  _GangwonMapPathCache._({
    required this.mapRect,
    required this.regionPaths,
    required this.fullPath,
    required this.landmassPath,
  });

  final Rect mapRect;
  final Map<String, Path> regionPaths;
  final Path fullPath;
  final Path landmassPath;

  static _GangwonMapPathCache forRect(Rect mapRect) {
    final cached = _cachedPath;
    if (cached != null && _sameRect(cached.mapRect, mapRect)) {
      return cached;
    }

    final regionPaths = <String, Path>{};
    final fullPath = _combinedPath([
      for (final region in gangwonMapRegions)
        regionPaths[region.city] = _regionPath(region, mapRect),
    ]);
    final landmassPath = _combinedPath([
      for (final region in gangwonContextRegions)
        _contextRegionPath(region, mapRect),
    ]);

    final next = _GangwonMapPathCache._(
      mapRect: mapRect,
      regionPaths: regionPaths,
      fullPath: fullPath,
      landmassPath: landmassPath,
    );
    _cachedPath = next;
    return next;
  }

  Path regionPath(GangwonMapRegion region) =>
      regionPaths[region.city] ?? Path();
}

_GangwonMapPathCache? _cachedPath;

bool _sameRect(Rect a, Rect b) {
  const tolerance = 0.01;
  return (a.left - b.left).abs() < tolerance &&
      (a.top - b.top).abs() < tolerance &&
      (a.width - b.width).abs() < tolerance &&
      (a.height - b.height).abs() < tolerance;
}

Path _regionPath(GangwonMapRegion region, Rect mapRect) {
  return _combinedPath([
    for (final polygon in region.polygons)
      if (polygon.length >= 3) _polygonPath(polygon, mapRect),
  ]);
}

Path _contextRegionPath(GangwonContextRegion region, Rect mapRect) {
  return _combinedPath([
    for (final polygon in region.polygons)
      if (polygon.length >= 3) _polygonPath(polygon, mapRect),
  ]);
}

Path _polygonPath(List<Offset> polygon, Rect mapRect) {
  return Path()
    ..addPolygon(
      [
        for (final point in polygon)
          Offset(
            mapRect.left + point.dx * mapRect.width,
            mapRect.top + point.dy * mapRect.height,
          ),
      ],
      true,
    );
}

Path _combinedPath(List<Path> paths) {
  var combined = Path();
  for (final path in paths) {
    if (path.getBounds().isEmpty) {
      continue;
    }

    try {
      combined = combined.getBounds().isEmpty
          ? path
          : Path.combine(PathOperation.union, combined, path);
    } catch (_) {
      combined.addPath(path, Offset.zero);
    }
  }
  return combined;
}

var _didLogGangwonContextRegions = false;

void _logGangwonContextRegionsOnce() {
  if (_didLogGangwonContextRegions) {
    return;
  }
  _didLogGangwonContextRegions = true;
  debugPrint(
    'Stamp context GeoJSON regions: ${gangwonContextRegionNames.join(', ')}',
  );
}

Path _scaledPath(Path path, double scale) {
  final bounds = path.getBounds();
  if (bounds.isEmpty) {
    return path;
  }
  final center = bounds.center;
  final matrix = Matrix4.identity()
    ..translateByDouble(center.dx, center.dy, 0, 1)
    ..scaleByDouble(scale, scale, 1, 1)
    ..translateByDouble(-center.dx, -center.dy, 0, 1);
  return path.transform(matrix.storage);
}

String? _hitTestRegion(Offset position, Rect mapRect) {
  final pathCache = _GangwonMapPathCache.forRect(mapRect);
  for (final region in gangwonMapRegions.reversed) {
    if (pathCache.regionPath(region).contains(position)) {
      return region.city;
    }
  }
  return null;
}

GangwonMapRegion? _findRegion(String city) {
  for (final region in gangwonMapRegions) {
    if (region.city == city) {
      return region;
    }
  }
  return null;
}

RallybookSpot? _findSpotById(List<RallybookSpot> spots, int spotId) {
  for (final spot in spots) {
    if (spot.spotId == spotId) {
      return spot;
    }
  }
  return null;
}

class _StampSpotActionCard extends ConsumerWidget {
  const _StampSpotActionCard({
    required this.region,
    required this.stamp,
    required this.spot,
    required this.onSpotTap,
  });

  final GangwonMapRegion? region;
  final RallybookStamp? stamp;
  final RallybookSpot? spot;
  final VoidCallback? onSpotTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasSelection = region != null && spot != null;
    final spotDetail = hasSelection
        ? ref.watch(spotDetailProvider(spot!.spotId.toString()))
        : null;

    return Container(
      key: hasSelection ? const ValueKey('stamp-selected-spot-card') : null,
      width: double.infinity,
      constraints: hasSelection ? null : const BoxConstraints(minHeight: 196),
      padding: hasSelection
          ? const EdgeInsets.fromLTRB(16, 14, 16, 14)
          : const EdgeInsets.fromLTRB(20, 18, 20, 14),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(AppDimens.cardRadius),
        boxShadow: AppShadows.softCard,
      ),
      child: Stack(
        children: [
          AnimatedSize(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOutCubic,
            alignment: Alignment.topCenter,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 160),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeOutCubic,
              child: hasSelection
                  ? _SelectedStampSpotContent(
                      key: ValueKey(spot!.spotId),
                      stamp: stamp,
                      spot: spot!,
                      spotDetail: spotDetail,
                      onSpotTap: onSpotTap,
                    )
                  : const _EmptyStampSpotContent(
                      key: ValueKey('empty-stamp-spot-card'),
                    ),
            ),
          ),
          if (hasSelection)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              height: 40,
              child: IgnorePointer(
                child: SizedBox(key: FeatureTourTargets.stampVisit),
              ),
            ),
        ],
      ),
    );
  }
}

class _SelectedStampSpotContent extends StatelessWidget {
  const _SelectedStampSpotContent({
    super.key,
    required this.stamp,
    required this.spot,
    required this.spotDetail,
    required this.onSpotTap,
  });

  final RallybookStamp? stamp;
  final RallybookSpot spot;
  final AsyncValue<SpotDetail>? spotDetail;
  final VoidCallback? onSpotTap;

  @override
  Widget build(BuildContext context) {
    final acquired = stamp?.acquired ?? false;
    final detail = spotDetail?.valueOrNull;
    final imageUrl = _firstNonEmpty(
      detail == null
          ? <String?>[spot.imageUrl]
          : <String?>[detail.imageUrl, ...detail.imageUrls, spot.imageUrl],
    );
    final description = _cleanSpotText(detail?.description);
    final address = _cleanSpotText(
      detail?.address.isNotEmpty == true ? detail!.address : spot.address,
    );
    final openingHours = _firstNonEmpty([
      detail?.openingHours,
      detail?.businessOpeningHours?.todayText,
    ]);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                spot.spotName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0,
                ),
              ),
            ),
            const SizedBox(width: 8),
            _StampPill(
              label: acquired ? '획득' : '미획득',
              backgroundColor: acquired
                  ? AppColors.primaryTint
                  : AppColors.line.withValues(alpha: 0.32),
              foregroundColor:
                  acquired ? AppColors.primaryDark : AppColors.textSecondary,
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _StampSpotThumbnail(
              key: ValueKey('stamp-spot-image-${spot.spotId}'),
              imageUrl: imageUrl,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${spot.cityName} · ${spot.categoryLabel}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0,
                    ),
                  ),
                  if (address.isNotEmpty) ...[
                    const SizedBox(height: 5),
                    _StampSpotInfoLine(
                      icon: Icons.location_on_outlined,
                      label: address,
                      maxLines: 2,
                    ),
                  ],
                  if (openingHours != null) ...[
                    const SizedBox(height: 4),
                    _StampSpotInfoLine(
                      icon: Icons.schedule_rounded,
                      label: openingHours,
                    ),
                  ],
                  if (description.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      description,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 10,
                        height: 1.3,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          height: 40,
          child: FilledButton.icon(
            onPressed: onSpotTap == null
                ? null
                : () {
                    FeatureTourScope.maybeOf(context)?.completeTarget(
                      FeatureTourTargets.stampVisit,
                    );
                    onSpotTap!();
                  },
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.onPrimary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
            ),
            icon: const Icon(Icons.photo_camera_rounded, size: 20),
            label: const Text(
              '방문 인증하기',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                letterSpacing: 0,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

String? _firstNonEmpty(Iterable<String?> values) {
  for (final value in values) {
    final trimmed = value?.trim();
    if (trimmed != null && trimmed.isNotEmpty) {
      return trimmed;
    }
  }
  return null;
}

String _cleanSpotText(String? value) {
  final text = value?.trim() ?? '';
  if (text.isEmpty) {
    return '';
  }
  return text
      .replaceAll(RegExp(r'<[^>]*>'), ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
}

class _StampSpotThumbnail extends StatelessWidget {
  const _StampSpotThumbnail({required this.imageUrl, super.key});

  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: SizedBox(
        width: 92,
        height: 92,
        child: imageUrl == null
            ? const _StampSpotImagePlaceholder()
            : CachedNetworkImage(
                imageUrl: imageUrl!,
                fit: BoxFit.cover,
                fadeInDuration: Duration.zero,
                fadeOutDuration: Duration.zero,
                errorWidget: (_, __, ___) => const _StampSpotImagePlaceholder(),
              ),
      ),
    );
  }
}

class _StampSpotImagePlaceholder extends StatelessWidget {
  const _StampSpotImagePlaceholder();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primaryTint.withValues(alpha: 0.9),
            AppColors.cream.withValues(alpha: 0.96),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: const Center(
        child: Icon(
          Icons.landscape_rounded,
          color: AppColors.primaryDark,
          size: 24,
        ),
      ),
    );
  }
}

class _StampSpotInfoLine extends StatelessWidget {
  const _StampSpotInfoLine({
    required this.icon,
    required this.label,
    this.maxLines = 1,
  });

  final IconData icon;
  final String label;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primaryDark, size: 14),
          const SizedBox(width: 5),
          Expanded(
            child: Text(
              label,
              maxLines: maxLines,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyStampSpotContent extends StatelessWidget {
  const _EmptyStampSpotContent({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 160,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: const BoxDecoration(
                  color: AppColors.primaryTint,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.touch_app_rounded,
                  color: AppColors.primaryDark,
                  size: 23,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '여행할 명소를 골라보세요',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0,
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      '강원 여행 패스포트',
                      style: TextStyle(
                        color: AppColors.actionGreen,
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          const Text(
            '지도 위 깃발을 누르면 방문 인증 장소가 여기에 표시돼요.',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
              height: 1.42,
              fontWeight: FontWeight.w700,
              letterSpacing: 0,
            ),
          ),
          const Spacer(),
          Container(
            width: double.infinity,
            height: 42,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.primaryTint.withValues(alpha: 0.72),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Text(
              '명소를 선택하면 바로 인증할 수 있어요',
              style: TextStyle(
                color: AppColors.actionGreen,
                fontSize: 13,
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

class _StampPill extends StatelessWidget {
  const _StampPill({
    required this.label,
    required this.backgroundColor,
    required this.foregroundColor,
  });

  final String label;
  final Color backgroundColor;
  final Color foregroundColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(AppDimens.pillRadius),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: foregroundColor,
          fontSize: 12,
          fontWeight: FontWeight.w900,
          letterSpacing: 0,
        ),
      ),
    );
  }
}

class _RallybookSpotMapNode extends StatelessWidget {
  const _RallybookSpotMapNode({
    required this.spot,
    required this.stamp,
    required this.selected,
  });

  final RallybookSpot spot;
  final RallybookStamp? stamp;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final acquired = stamp?.acquired ?? false;
    final stampColor = acquired
        ? AppColors.primary
        : selected
            ? AppColors.primary
            : const Color(0xFFC9BFA8);
    final fillColor = acquired
        ? AppColors.primaryTint
        : selected
            ? AppColors.primaryTint
            : AppColors.surface.withValues(alpha: 0.96);

    return Semantics(
      label: spot.spotName,
      button: true,
      child: AnimatedScale(
        scale: selected ? 1.07 : 1,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: selected ? 38 : 30,
              height: selected ? 38 : 30,
              decoration: BoxDecoration(
                color: fillColor,
                shape: BoxShape.circle,
                border: Border.all(
                  color: stampColor,
                  width: selected ? 3 : 2.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: stampColor.withValues(
                      alpha: selected ? 0.24 : 0.12,
                    ),
                    blurRadius: selected ? 12 : 5,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: selected ? 19 : 15,
                    height: selected ? 19 : 15,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: stampColor.withValues(alpha: 0.62),
                        width: 2,
                      ),
                    ),
                  ),
                  Icon(
                    acquired
                        ? Icons.check_rounded
                        : selected
                            ? Icons.directions_car_rounded
                            : Icons.flag_rounded,
                    color: stampColor,
                    size: selected ? 17 : 14,
                  ),
                ],
              ),
            ),
            if (selected) ...[
              const SizedBox(height: 2),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 6,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: AppColors.surface.withValues(alpha: 0.94),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.secondary),
                ),
                child: Text(
                  spot.spotName,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 9,
                    height: 1.1,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

String _normalizeCityName(String value) {
  return value.replaceAll(RegExp(r'(특별자치도|시|군|구)$'), '').trim();
}

class _StampBookError extends StatelessWidget {
  const _StampBookError({required this.onRetry});
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
        child: SingleChildScrollView(
            child: AppStateMessage(
          icon: Icons.cloud_off_outlined,
          title: '스탬프 투어를 불러오지 못했습니다.',
          actionLabel: '다시 시도',
          onAction: onRetry,
        )),
      );
}

class _SignedOutState extends StatelessWidget {
  const _SignedOutState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        '로그인 후 스탬프 투어를 확인할 수 있어요.',
        style: TextStyle(
          color: AppColors.textSecondary,
          fontSize: 15,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
