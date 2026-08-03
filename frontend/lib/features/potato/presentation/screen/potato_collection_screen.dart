import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/network/api_exception.dart';
import '../../application/potato_collection_controller.dart';
import '../../domain/potato_collection.dart';
import '../potato_asset.dart';

const _potatoPrimary = Color(0xFF56C787);
const _potatoDark = Color(0xFF509B64);
const _potatoYellow = Color(0xFFF5D84E);
const _potatoLine = Color(0xFFE8E2D8);
const _potatoCardRadius = 20.0;

String _formatInt(int value) {
  return value.toString().replaceAllMapped(
        RegExp(r'\B(?=(\d{3})+(?!\d))'),
        (match) => ',',
      );
}

class PotatoCollectionScreen extends ConsumerStatefulWidget {
  const PotatoCollectionScreen({super.key});

  @override
  ConsumerState<PotatoCollectionScreen> createState() =>
      _PotatoCollectionScreenState();
}

class _PotatoCollectionScreenState extends ConsumerState<PotatoCollectionScreen>
    with WidgetsBindingObserver {
  bool _isUpdatingRepresentative = false;
  bool _isGrowthFeedbackScheduled = false;
  bool _hasShownGrowthFeedback = false;
  bool _hasLeftForeground = false;
  Future<void>? _refreshFuture;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!mounted) {
      return;
    }

    if (state == AppLifecycleState.resumed) {
      if (!_hasLeftForeground) {
        return;
      }
      _hasLeftForeground = false;
      unawaited(_refreshPotatoData());
      return;
    }

    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.hidden ||
        state == AppLifecycleState.paused) {
      _hasLeftForeground = true;
    }
  }

  Future<void> _refreshPotatoData() {
    final pendingRefresh = _refreshFuture;
    if (pendingRefresh != null) {
      return pendingRefresh;
    }

    late final Future<void> refresh;
    refresh = _performPotatoDataRefresh().whenComplete(() {
      if (identical(_refreshFuture, refresh)) {
        _refreshFuture = null;
      }
    });
    _refreshFuture = refresh;
    return refresh;
  }

  Future<void> _performPotatoDataRefresh() async {
    ref.invalidate(potatoActivitySyncProvider);
    ref.invalidate(potatoCollectionProvider);
    ref.invalidate(potatoGrowthSummaryProvider);

    try {
      await Future.wait<Object?>([
        ref.read(potatoActivitySyncProvider.future),
        ref.read(potatoCollectionProvider.future),
        ref.read(potatoGrowthSummaryProvider.future),
      ]);
    } catch (_) {
      // 각 provider가 기존 오류 UI를 유지하므로 새로고침 제스처만 정상 종료한다.
    }
  }

  void _showRepresentativePicker(PotatoCollection collection) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => _RepresentativePotatoSheet(
        collection: collection,
        onShowDetail: (item) {
          Navigator.of(sheetContext).pop();
          _showPotatoDetail(item);
        },
        onSelect: (item) {
          Navigator.of(sheetContext).pop();
          _updateRepresentativePotato(item);
        },
      ),
    );
  }

  void _showPotatoDetail(PotatoCollectionItem item) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _PotatoDetailSheet(item: item),
    );
  }

  Future<void> _updateRepresentativePotato(PotatoCollectionItem item) async {
    if (item.representative || _isUpdatingRepresentative) {
      return;
    }

    setState(() => _isUpdatingRepresentative = true);
    try {
      await ref
          .read(potatoRepositoryProvider)
          .updateRepresentativePotato(item.id);
      ref.invalidate(potatoCollectionProvider);
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('대표 감자를 ${item.name}로 변경했어요.')),
      );
    } on ApiException catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message)),
      );
    } catch (_) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('대표 감자를 변경하지 못했습니다.')),
      );
    } finally {
      if (mounted) {
        setState(() => _isUpdatingRepresentative = false);
      }
    }
  }

  Future<void> _showGrowthFeedbackAfterCollectionLoads(
    PotatoGrowthResult growthResult,
  ) async {
    if (!growthResult.leveledUp ||
        _isGrowthFeedbackScheduled ||
        _hasShownGrowthFeedback) {
      return;
    }

    _isGrowthFeedbackScheduled = true;
    try {
      // 성장 결과와 도감 수치가 어긋나 보이지 않도록 최신 도감 조회 완료 후 안내한다.
      await ref.read(potatoCollectionProvider.future);
      if (!mounted || _hasShownGrowthFeedback) {
        return;
      }
      _hasShownGrowthFeedback = true;
      await showDialog<void>(
        context: context,
        builder: (_) => _PotatoGrowthDialog(growthResult: growthResult),
      );
    } catch (_) {
      // 도감 로드 실패는 기존 오류 상태에서 처리하고 성장 안내만 생략한다.
    } finally {
      _isGrowthFeedbackScheduled = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncValue<PotatoGrowthResult?>>(potatoActivitySyncProvider, (
      previous,
      next,
    ) {
      final growthResult = next.valueOrNull;
      if (growthResult != null) {
        _showGrowthFeedbackAfterCollectionLoads(growthResult);
      }
    });
    final collectionState = ref.watch(potatoCollectionProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: collectionState.when(
          data: (collection) => collection == null
              ? const _SignedOutPotatoState()
              : RefreshIndicator(
                  color: _potatoPrimary,
                  onRefresh: _refreshPotatoData,
                  child: _PotatoCollectionBody(
                    collection: collection,
                    updatingRepresentative: _isUpdatingRepresentative,
                    onShowDetail: _showPotatoDetail,
                    onChangeRepresentative: () {
                      _showRepresentativePicker(collection);
                    },
                  ),
                ),
          loading: () => const _PotatoStatusBody(
            child: Center(
              child: CircularProgressIndicator(color: _potatoPrimary),
            ),
          ),
          error: (error, _) => _PotatoStatusBody(
            child: _PotatoErrorState(
              message:
                  error is ApiException ? error.message : '감자 도감을 불러오지 못했습니다.',
              onRetry: () => ref.invalidate(potatoCollectionProvider),
            ),
          ),
        ),
      ),
    );
  }
}

class _PotatoGrowthDialog extends StatelessWidget {
  const _PotatoGrowthDialog({required this.growthResult});

  final PotatoGrowthResult growthResult;

  @override
  Widget build(BuildContext context) {
    final fullyGrown = growthResult.fullyGrown;
    final accentColor = fullyGrown ? const Color(0xFFE0A91B) : _potatoDark;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 28),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 360),
        padding: const EdgeInsets.fromLTRB(22, 24, 22, 20),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(_potatoCardRadius),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 78,
              height: 78,
              decoration: BoxDecoration(
                color: fullyGrown
                    ? const Color(0xFFFFE9A5)
                    : const Color(0xFFE6F7EC),
                shape: BoxShape.circle,
              ),
              child: Icon(
                fullyGrown
                    ? Icons.workspace_premium_rounded
                    : Icons.trending_up_rounded,
                color: accentColor,
                size: 42,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              fullyGrown
                  ? '${growthResult.potatoName}가 완전히 자랐어요!'
                  : '${growthResult.potatoName}가 성장했어요!',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 22,
                fontWeight: FontWeight.w900,
                letterSpacing: 0,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              fullyGrown
                  ? '최종 성장 단계 Lv.${growthResult.currentLevel}에 도달했어요.'
                  : 'Lv.${growthResult.previousLevel}에서 '
                      'Lv.${growthResult.currentLevel}으로 성장했어요.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 15,
                fontWeight: FontWeight.w800,
                letterSpacing: 0,
              ),
            ),
            const SizedBox(height: 22),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(50),
                backgroundColor: accentColor,
                foregroundColor: AppColors.surface,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(_potatoCardRadius),
                ),
              ),
              child: const Text(
                '도감에서 확인',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PotatoCollectionBody extends StatelessWidget {
  const _PotatoCollectionBody({
    required this.collection,
    required this.updatingRepresentative,
    required this.onShowDetail,
    required this.onChangeRepresentative,
  });

  final PotatoCollection collection;
  final bool updatingRepresentative;
  final ValueChanged<PotatoCollectionItem> onShowDetail;
  final VoidCallback onChangeRepresentative;

  @override
  Widget build(BuildContext context) {
    final representative = collection.representativePotato;

    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        const SliverToBoxAdapter(child: _PotatoHeader()),
        SliverToBoxAdapter(
          child: _RepresentativePotatoCard(
            item: representative,
            acquiredCount: collection.acquiredCount,
            totalCount: collection.totalCount,
            updating: updatingRepresentative,
            onShowDetail: representative == null
                ? null
                : () => onShowDetail(representative),
            onChangeRepresentative: onChangeRepresentative,
          ),
        ),
        const SliverToBoxAdapter(child: _TodayStepCard()),
        const SliverToBoxAdapter(child: SizedBox(height: 28)),
      ],
    );
  }
}

class _PotatoHeader extends StatelessWidget {
  const _PotatoHeader();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(height: 18);
  }
}

class _RepresentativePotatoCard extends StatelessWidget {
  const _RepresentativePotatoCard({
    required this.item,
    required this.acquiredCount,
    required this.totalCount,
    required this.updating,
    required this.onShowDetail,
    required this.onChangeRepresentative,
  });

  final PotatoCollectionItem? item;
  final int acquiredCount;
  final int totalCount;
  final bool updating;
  final VoidCallback? onShowDetail;
  final VoidCallback onChangeRepresentative;

  @override
  Widget build(BuildContext context) {
    final potato = item;
    final progress = totalCount == 0 ? 0.0 : acquiredCount / totalCount;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 20),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: _PotatoArtSlot(
              item: potato,
              locked: potato == null || !potato.acquired,
              size: 244,
              framed: false,
            ),
          ),
          const SizedBox(height: 10),
          Center(
            child: Text(
              potato?.name ?? '초보 감자',
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 26,
                fontWeight: FontWeight.w900,
                letterSpacing: 0,
              ),
            ),
          ),
          if (potato != null) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                _RarityBadge(rarity: potato.rarity),
                _MetaChip(label: potato.region),
                _MetaChip(label: 'Lv.${potato.level}'),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              potato.description.isEmpty
                  ? '${potato.region}에서 만난 감자예요. 감자걸음을 쌓으면 더 단단하게 성장합니다.'
                  : potato.description,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
                fontWeight: FontWeight.w700,
                height: 1.45,
                letterSpacing: 0,
              ),
            ),
          ],
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    minHeight: 10,
                    value: progress.clamp(0, 1),
                    backgroundColor: const Color(0xFFE7EFE9),
                    valueColor:
                        const AlwaysStoppedAnimation<Color>(_potatoPrimary),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                '$acquiredCount / $totalCount',
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: potato == null ? null : onShowDetail,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _potatoDark,
                    disabledForegroundColor: AppColors.textSecondary,
                    side: BorderSide(
                      color: potato == null
                          ? _potatoLine
                          : _potatoPrimary.withValues(alpha: 0.55),
                    ),
                    minimumSize: const Size.fromHeight(48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(_potatoCardRadius),
                    ),
                  ),
                  icon: const Icon(Icons.info_outline_rounded, size: 18),
                  label: const Text(
                    '정보 보기',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton(
                  onPressed: updating ? null : onChangeRepresentative,
                  style: FilledButton.styleFrom(
                    backgroundColor: _potatoPrimary,
                    disabledBackgroundColor: const Color(0xFFBFE5CC),
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(_potatoCardRadius),
                    ),
                  ),
                  child: updating
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          '대표 감자 변경',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TodayStepCard extends ConsumerWidget {
  const _TodayStepCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaryState = ref.watch(potatoGrowthSummaryProvider);

    return summaryState.when(
      data: (summary) => _TodayStepCardContent(
        summary: summary ??
            const PotatoGrowthSummary(
              todaySteps: 0,
              dailyStepGoal: 10000,
              weeklyDistanceKm: 0,
              monthlyDistanceKm: 0,
              remainingDistanceKmForRepresentative: 0,
            ),
      ),
      loading: () => const _TodayStepCardShell(
        child: SizedBox(
          height: 148,
          child: Center(
            child: CircularProgressIndicator(color: _potatoPrimary),
          ),
        ),
      ),
      error: (error, _) => _TodayStepCardShell(
        child: _InlineErrorState(
          message:
              error is ApiException ? error.message : '오늘의 감자걸음을 불러오지 못했습니다.',
          onRetry: () => ref.invalidate(potatoGrowthSummaryProvider),
        ),
      ),
    );
  }
}

class _PotatoDetailSheet extends StatelessWidget {
  const _PotatoDetailSheet({required this.item});

  final PotatoCollectionItem item;

  @override
  Widget build(BuildContext context) {
    final locked = !item.acquired;

    return _BottomSheetFrame(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  locked ? '???' : item.name,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0,
                  ),
                ),
              ),
              IconButton(
                tooltip: '닫기',
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close_rounded),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Center(
            child: _PotatoArtSlot(item: item, locked: locked, size: 144),
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _RarityBadge(rarity: item.rarity),
              _MetaChip(label: item.region),
              _MetaChip(label: locked ? '미획득' : 'Lv.${item.level}'),
            ],
          ),
          const SizedBox(height: 18),
          _InfoBlock(
            title: '감자 소개',
            body: item.description.isEmpty
                ? '획득하면 감자의 이야기가 열립니다.'
                : item.description,
          ),
          _InfoBlock(title: '획득 방법', body: item.acquisitionHint),
          _GrowthProgress(item: item),
        ],
      ),
    );
  }
}

class _InfoBlock extends StatelessWidget {
  const _InfoBlock({
    required this.title,
    required this.body,
  });

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w900,
              letterSpacing: 0,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            body,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
              fontWeight: FontWeight.w700,
              height: 1.45,
              letterSpacing: 0,
            ),
          ),
        ],
      ),
    );
  }
}

class _GrowthProgress extends StatelessWidget {
  const _GrowthProgress({required this.item});

  final PotatoCollectionItem item;

  @override
  Widget build(BuildContext context) {
    final goal = item.growthGoalDistance;
    final progress = goal <= 0 ? 0.0 : item.growthDistance / goal;
    final distanceLabel = item.acquired
        ? '${(item.growthDistance / 1000).toStringAsFixed(1)}km 이동'
        : '획득 후 성장 기록이 쌓입니다.';

    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFFF8FBF5),
        borderRadius: BorderRadius.circular(_potatoCardRadius),
        border: Border.all(color: _potatoLine),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    '성장 진행',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0,
                    ),
                  ),
                ),
                Text(
                  item.acquired ? 'Lv.${item.level}' : '잠김',
                  style: const TextStyle(
                    color: _potatoDark,
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                minHeight: 9,
                value: progress.clamp(0, 1),
                backgroundColor: const Color(0xFFE7EFE9),
                valueColor: const AlwaysStoppedAnimation<Color>(_potatoPrimary),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              distanceLabel,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
                fontWeight: FontWeight.w700,
                letterSpacing: 0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TodayStepCardContent extends StatelessWidget {
  const _TodayStepCardContent({required this.summary});

  final PotatoGrowthSummary summary;

  @override
  Widget build(BuildContext context) {
    final ratio = summary.stepRatio;
    final percent = (ratio * 100).round();
    final remainingDistance = summary.remainingDistanceKmForRepresentative;
    final remainingLabel = remainingDistance <= 0
        ? '오늘 성장 목표를 달성했어요'
        : '성장까지 약 ${remainingDistance.toStringAsFixed(1)}km 남았어요';

    return _TodayStepCardShell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '오늘의 감자걸음',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w900,
              letterSpacing: 0,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              SizedBox(
                width: 104,
                height: 104,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    CircularProgressIndicator(
                      strokeWidth: 10,
                      value: ratio,
                      backgroundColor: const Color(0xFFE7EFE9),
                      valueColor:
                          const AlwaysStoppedAnimation<Color>(_potatoPrimary),
                    ),
                    Center(
                      child: Text(
                        '$percent%',
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${_formatInt(summary.todaySteps)} 걸음',
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 27,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '/${_formatInt(summary.dailyStepGoal)} 걸음',
                      style: const TextStyle(
                        color: _potatoDark,
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      remainingLabel,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TodayStepCardShell extends StatelessWidget {
  const _TodayStepCardShell({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 14),
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: child,
    );
  }
}

class _InlineErrorState extends StatelessWidget {
  const _InlineErrorState({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 148,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
              fontWeight: FontWeight.w700,
              letterSpacing: 0,
            ),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: onRetry,
            child: const Text('다시 불러오기'),
          ),
        ],
      ),
    );
  }
}

class _PotatoArtSlot extends StatelessWidget {
  const _PotatoArtSlot({
    required this.item,
    required this.locked,
    required this.size,
    this.framed = true,
  });

  final PotatoCollectionItem? item;
  final bool locked;
  final double size;
  final bool framed;

  @override
  Widget build(BuildContext context) {
    final potato = item;
    final imageUrl = potato?.imageUrl;
    final assetPath = potato == null
        ? 'assets/potatoes/potato_unknown.png'
        : potatoLocalAssetPath(potato.code);

    final image = imageUrl != null && imageUrl.isNotEmpty
        ? Image.network(
            imageUrl,
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => _PotatoArtFallback(locked: locked),
          )
        : Image.asset(
            assetPath,
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => _PotatoArtFallback(locked: locked),
          );
    final visualImage = locked && potato != null
        ? ColorFiltered(
            colorFilter: ColorFilter.mode(
              Colors.black.withValues(alpha: 0.58),
              BlendMode.srcATop,
            ),
            child: Opacity(opacity: 0.32, child: image),
          )
        : image;
    final alignedImage = locked && potato == null
        ? Transform.translate(
            offset: Offset(size * 0.092, size * 0.033),
            child: visualImage,
          )
        : visualImage;

    if (!framed) {
      return SizedBox(
        width: size,
        height: size,
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(size * 0.02),
            child: alignedImage,
          ),
        ),
      );
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: locked ? const Color(0xFFF2F0EA) : const Color(0xFFFFF3C7),
        borderRadius: BorderRadius.circular(_potatoCardRadius),
        border: Border.all(color: locked ? _potatoLine : _potatoYellow),
      ),
      clipBehavior: Clip.antiAlias,
      child: Center(
        child: Padding(
          padding: EdgeInsets.all(size * 0.12),
          child: alignedImage,
        ),
      ),
    );
  }
}

class _PotatoArtFallback extends StatelessWidget {
  const _PotatoArtFallback({required this.locked});

  final bool locked;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: locked ? const Color(0xFFF2F0EA) : AppColors.primaryTint,
        borderRadius: BorderRadius.circular(_potatoCardRadius),
      ),
      child: const SizedBox.expand(),
    );
  }
}

class _RarityBadge extends StatelessWidget {
  const _RarityBadge({required this.rarity});

  final PotatoRarity rarity;

  @override
  Widget build(BuildContext context) {
    final color = _rarityColor(rarity);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
        child: Text(
          potatoRarityLabel(rarity),
          style: TextStyle(
            color: color,
            fontSize: 12,
            fontWeight: FontWeight.w900,
            letterSpacing: 0,
          ),
        ),
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: _potatoLine),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
        child: Text(
          label,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w800,
            letterSpacing: 0,
          ),
        ),
      ),
    );
  }
}

class _RepresentativePotatoSheet extends StatelessWidget {
  const _RepresentativePotatoSheet({
    required this.collection,
    required this.onShowDetail,
    required this.onSelect,
  });

  final PotatoCollection collection;
  final ValueChanged<PotatoCollectionItem> onShowDetail;
  final ValueChanged<PotatoCollectionItem> onSelect;

  @override
  Widget build(BuildContext context) {
    final allItems = collection.items;
    return _BottomSheetFrame(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  '나의 감자 도감',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0,
                  ),
                ),
              ),
              IconButton(
                tooltip: '닫기',
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close_rounded),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (allItems.isEmpty)
            const _RepresentativePotatoEmpty()
          else
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: allItems.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: 0.92,
              ),
              itemBuilder: (context, index) {
                final item = allItems[index];
                return _RepresentativePotatoOption(
                  item: item,
                  onShowDetail: () => onShowDetail(item),
                  onSelect: () => onSelect(item),
                );
              },
            ),
        ],
      ),
    );
  }
}

class _RepresentativePotatoEmpty extends StatelessWidget {
  const _RepresentativePotatoEmpty();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
      decoration: BoxDecoration(
        color: AppColors.primaryTint,
        borderRadius: BorderRadius.circular(_potatoCardRadius),
        border: Border.all(color: _potatoPrimary.withValues(alpha: 0.24)),
      ),
      child: const Column(
        children: [
          Icon(
            Icons.lock_open_rounded,
            color: _potatoDark,
            size: 30,
          ),
          SizedBox(height: 10),
          Text(
            '아직 변경할 감자가 없어요',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w900,
              letterSpacing: 0,
            ),
          ),
          SizedBox(height: 6),
          Text(
            '지도에서 감자 스팟을 방문하고 첫 감자를 수집하면 대표 감자를 선택할 수 있어요.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
              fontWeight: FontWeight.w700,
              height: 1.45,
              letterSpacing: 0,
            ),
          ),
        ],
      ),
    );
  }
}

class _RepresentativePotatoOption extends StatelessWidget {
  const _RepresentativePotatoOption({
    required this.item,
    required this.onShowDetail,
    required this.onSelect,
  });

  final PotatoCollectionItem item;
  final VoidCallback onShowDetail;
  final VoidCallback onSelect;

  @override
  Widget build(BuildContext context) {
    final selected = item.representative;
    final locked = !item.acquired;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(_potatoCardRadius),
        onTap: locked || selected ? onShowDetail : onSelect,
        child: Ink(
          decoration: BoxDecoration(
            color: selected
                ? _potatoPrimary.withValues(alpha: 0.12)
                : AppColors.surface,
            borderRadius: BorderRadius.circular(_potatoCardRadius),
            border: Border.all(
              color: selected ? _potatoPrimary : _potatoLine,
              width: selected ? 1.6 : 1,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(9, 10, 9, 12),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    _PotatoArtSlot(item: item, locked: locked, size: 66),
                    if (selected)
                      Positioned(
                        right: -5,
                        top: -5,
                        child: Container(
                          width: 22,
                          height: 22,
                          decoration: const BoxDecoration(
                            color: _potatoPrimary,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.check_rounded,
                            color: Colors.white,
                            size: 15,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  locked ? '???' : item.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BottomSheetFrame extends StatelessWidget {
  const _BottomSheetFrame({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.76,
      minChildSize: 0.42,
      maxChildSize: 0.92,
      builder: (context, scrollController) {
        return DecoratedBox(
          decoration: const BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: ListView(
            controller: scrollController,
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
            children: [
              Center(
                child: Container(
                  width: 38,
                  height: 4,
                  decoration: BoxDecoration(
                    color: _potatoLine,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              child,
            ],
          ),
        );
      },
    );
  }
}

class _PotatoStatusBody extends StatelessWidget {
  const _PotatoStatusBody({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        const SliverToBoxAdapter(child: _PotatoHeader()),
        SliverFillRemaining(
          hasScrollBody: false,
          child: child,
        ),
      ],
    );
  }
}

class _SignedOutPotatoState extends StatelessWidget {
  const _SignedOutPotatoState();

  @override
  Widget build(BuildContext context) {
    return const _PotatoStatusBody(
      child: Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            '로그인 후 수집한 감자를 확인할 수 있습니다.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 15,
              fontWeight: FontWeight.w700,
              letterSpacing: 0,
            ),
          ),
        ),
      ),
    );
  }
}

class _PotatoErrorState extends StatelessWidget {
  const _PotatoErrorState({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline_rounded,
            color: AppColors.error,
            size: 36,
          ),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w800,
              letterSpacing: 0,
            ),
          ),
          const SizedBox(height: 14),
          OutlinedButton(
            onPressed: onRetry,
            child: const Text('다시 불러오기'),
          ),
        ],
      ),
    );
  }
}

BoxDecoration _cardDecoration({Color color = AppColors.surface}) {
  return BoxDecoration(
    color: color,
    borderRadius: BorderRadius.circular(_potatoCardRadius),
    border: Border.all(color: _potatoLine),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.05),
        blurRadius: 18,
        offset: const Offset(0, 8),
      ),
    ],
  );
}

Color _rarityColor(PotatoRarity rarity) {
  return switch (rarity) {
    PotatoRarity.common => const Color(0xFF4E9B46),
    PotatoRarity.rare => const Color(0xFF8D74C9),
    PotatoRarity.epic => const Color(0xFFE98A2A),
    PotatoRarity.legendary => const Color(0xFFF6A800),
  };
}
