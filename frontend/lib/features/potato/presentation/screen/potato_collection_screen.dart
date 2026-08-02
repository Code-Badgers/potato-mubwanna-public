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
const _potatoCream = Color(0xFFFFF8EA);
const _potatoYellow = Color(0xFFF5D84E);
const _potatoLine = Color(0xFFE8E2D8);

String _formatInt(int value) {
  return value.toString().replaceAllMapped(
        RegExp(r'\B(?=(\d{3})+(?!\d))'),
        (_) => ',',
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
  PotatoRarity? _selectedRarity;
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

  List<PotatoCollectionItem> _filteredItems(List<PotatoCollectionItem> items) {
    final selectedRarity = _selectedRarity;
    if (selectedRarity == null) {
      return items;
    }
    return items.where((item) => item.rarity == selectedRarity).toList();
  }

  void _showPotatoDetail(PotatoCollectionItem item) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => _PotatoDetailSheet(
        item: item,
        updatingRepresentative: _isUpdatingRepresentative,
        onSetRepresentative: () {
          Navigator.of(sheetContext).pop();
          _updateRepresentativePotato(item);
        },
      ),
    );
  }

  void _showRepresentativePicker(PotatoCollection collection) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => _RepresentativePotatoSheet(
        collection: collection,
        onSelect: (item) {
          Navigator.of(sheetContext).pop();
          _updateRepresentativePotato(item);
        },
      ),
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
                    selectedRarity: _selectedRarity,
                    filteredItems: _filteredItems(collection.items),
                    onRarityChanged: (rarity) {
                      setState(() => _selectedRarity = rarity);
                    },
                    onTapItem: _showPotatoDetail,
                    updatingRepresentative: _isUpdatingRepresentative,
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
          borderRadius: BorderRadius.circular(8),
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
                  borderRadius: BorderRadius.circular(8),
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
    required this.selectedRarity,
    required this.filteredItems,
    required this.onRarityChanged,
    required this.onTapItem,
    required this.updatingRepresentative,
    required this.onChangeRepresentative,
  });

  final PotatoCollection collection;
  final PotatoRarity? selectedRarity;
  final List<PotatoCollectionItem> filteredItems;
  final ValueChanged<PotatoRarity?> onRarityChanged;
  final ValueChanged<PotatoCollectionItem> onTapItem;
  final bool updatingRepresentative;
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
            onChangeRepresentative: onChangeRepresentative,
          ),
        ),
        const SliverToBoxAdapter(child: _TodayStepCard()),
        SliverToBoxAdapter(
          child: _PotatoRarityFilter(
            selectedRarity: selectedRarity,
            onChanged: onRarityChanged,
          ),
        ),
        const SliverToBoxAdapter(
          child: _SectionTitle(title: '나의 감자 도감'),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 28),
          sliver: filteredItems.isEmpty
              ? const SliverToBoxAdapter(child: _PotatoEmptyState())
              : SliverGrid.builder(
                  itemCount: filteredItems.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    childAspectRatio: 0.72,
                  ),
                  itemBuilder: (context, index) {
                    final item = filteredItems[index];
                    return _PotatoTile(
                      item: item,
                      onTap: () => onTapItem(item),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _PotatoHeader extends StatelessWidget {
  const _PotatoHeader();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.fromLTRB(20, 18, 20, 10),
      child: Row(
        children: [
          Expanded(
            child: Text(
              '감자',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 28,
                fontWeight: FontWeight.w900,
                letterSpacing: 0,
              ),
            ),
          ),
          Icon(
            Icons.help_outline_rounded,
            color: AppColors.textSecondary,
            size: 24,
          ),
        ],
      ),
    );
  }
}

class _RepresentativePotatoCard extends StatelessWidget {
  const _RepresentativePotatoCard({
    required this.item,
    required this.acquiredCount,
    required this.totalCount,
    required this.updating,
    required this.onChangeRepresentative,
  });

  final PotatoCollectionItem? item;
  final int acquiredCount;
  final int totalCount;
  final bool updating;
  final VoidCallback onChangeRepresentative;

  @override
  Widget build(BuildContext context) {
    final potato = item;
    final progress = totalCount == 0 ? 0.0 : acquiredCount / totalCount;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(color: _potatoCream),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _PotatoArtSlot(
                item: potato,
                locked: potato == null || !potato.acquired,
                size: 86,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '대표 감자',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      potato?.name ?? '아직 대표 감자가 없어요',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (potato == null)
                      const Text(
                        '감자 스팟을 방문해 첫 감자를 모아보세요.',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                          height: 1.35,
                          letterSpacing: 0,
                        ),
                      )
                    else
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          _RarityBadge(rarity: potato.rarity),
                          _MetaChip(label: potato.region),
                          _MetaChip(label: 'Lv.${potato.level}'),
                        ],
                      ),
                  ],
                ),
              ),
            ],
          ),
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
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: acquiredCount == 0 || updating
                  ? null
                  : onChangeRepresentative,
              style: FilledButton.styleFrom(
                backgroundColor: _potatoPrimary,
                disabledBackgroundColor: const Color(0xFFBFE5CC),
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
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
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0,
                      ),
                    ),
            ),
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
              dailyStepGoal: 0,
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

class _TodayStepCardContent extends StatelessWidget {
  const _TodayStepCardContent({required this.summary});

  final PotatoGrowthSummary summary;

  @override
  Widget build(BuildContext context) {
    final ratio = summary.stepRatio;
    final percentage = (ratio * 100).round();
    final remainingDistance = summary.remainingDistanceKmForRepresentative;
    final remainingLabel = remainingDistance <= 0
        ? '성장 목표를 달성했어요'
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
                width: 92,
                height: 92,
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
                        '$percentage%',
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
                      '${_formatInt(summary.todaySteps)} / '
                      '${_formatInt(summary.dailyStepGoal)}보',
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 22,
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
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _StepSummaryTile(
                  label: '이번 주',
                  value: '${summary.weeklyDistanceKm.toStringAsFixed(1)} km',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _StepSummaryTile(
                  label: '이번 달',
                  value: '${summary.monthlyDistanceKm.toStringAsFixed(1)} km',
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

class _StepSummaryTile extends StatelessWidget {
  const _StepSummaryTile({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFFF8FBF5),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _potatoLine),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 0,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 17,
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

class _PotatoRarityFilter extends StatelessWidget {
  const _PotatoRarityFilter({
    required this.selectedRarity,
    required this.onChanged,
  });

  final PotatoRarity? selectedRarity;
  final ValueChanged<PotatoRarity?> onChanged;

  @override
  Widget build(BuildContext context) {
    final filters = <({String label, PotatoRarity? rarity})>[
      (label: '전체', rarity: null),
      (label: '일반', rarity: PotatoRarity.common),
      (label: '희귀', rarity: PotatoRarity.rare),
      (label: '영웅', rarity: PotatoRarity.epic),
      (label: '전설', rarity: PotatoRarity.legendary),
    ];

    return SizedBox(
      height: 46,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        scrollDirection: Axis.horizontal,
        itemCount: filters.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final filter = filters[index];
          final selected = selectedRarity == filter.rarity;
          return ChoiceChip(
            selected: selected,
            label: Text(filter.label),
            showCheckmark: false,
            selectedColor: _potatoPrimary.withValues(alpha: 0.16),
            backgroundColor: AppColors.surface,
            side: BorderSide(
              color: selected ? _potatoPrimary : _potatoLine,
            ),
            labelStyle: TextStyle(
              color: selected ? _potatoDark : AppColors.textSecondary,
              fontSize: 13,
              fontWeight: FontWeight.w800,
              letterSpacing: 0,
            ),
            onSelected: (_) => onChanged(filter.rarity),
          );
        },
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 2, 20, 12),
      child: Text(
        title,
        style: const TextStyle(
          color: AppColors.textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w900,
          letterSpacing: 0,
        ),
      ),
    );
  }
}

class _PotatoTile extends StatelessWidget {
  const _PotatoTile({
    required this.item,
    required this.onTap,
  });

  final PotatoCollectionItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final locked = !item.acquired;
    final borderColor = locked ? _potatoLine : _rarityColor(item.rarity);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Ink(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: borderColor,
              width: locked ? 1 : 1.5,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(9),
            child: Column(
              children: [
                _PotatoArtSlot(item: item, locked: locked, size: 70),
                const SizedBox(height: 8),
                Text(
                  locked ? '미획득' : item.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: locked
                        ? AppColors.textSecondary
                        : AppColors.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  potatoRarityLabel(item.rarity),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: _rarityColor(item.rarity),
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
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

class _PotatoArtSlot extends StatelessWidget {
  const _PotatoArtSlot({
    required this.item,
    required this.locked,
    required this.size,
  });

  final PotatoCollectionItem? item;
  final bool locked;
  final double size;

  @override
  Widget build(BuildContext context) {
    final potato = item;
    final imageUrl = potato?.imageUrl;
    final assetPath = locked || potato == null
        ? 'assets/potatoes/potato_unknown.png'
        : potatoLocalAssetPath(potato.code);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: locked ? const Color(0xFFF2F0EA) : const Color(0xFFFFF3C7),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: locked ? _potatoLine : _potatoYellow,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: EdgeInsets.all(size * 0.12),
        child: imageUrl != null && imageUrl.isNotEmpty
            ? Image.network(
                imageUrl,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) =>
                    _PotatoArtFallback(locked: locked),
              )
            : Image.asset(
                assetPath,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) =>
                    _PotatoArtFallback(locked: locked),
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
    return Icon(
      locked ? Icons.question_mark_rounded : Icons.eco_rounded,
      color: locked ? AppColors.textSecondary : _potatoDark,
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

class _PotatoDetailSheet extends StatelessWidget {
  const _PotatoDetailSheet({
    required this.item,
    required this.updatingRepresentative,
    required this.onSetRepresentative,
  });

  final PotatoCollectionItem item;
  final bool updatingRepresentative;
  final VoidCallback onSetRepresentative;

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
                  locked ? '아직 만나지 못한 감자' : item.name,
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
          const SizedBox(height: 12),
          Center(child: _PotatoArtSlot(item: item, locked: locked, size: 144)),
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
          const SizedBox(height: 16),
          _InfoBlock(
            title: '감자 소개',
            body: locked ? '획득 후 감자의 이야기가 열립니다.' : item.description,
          ),
          const SizedBox(height: 12),
          _InfoBlock(
            title: '획득 방법',
            body: item.acquisitionHint,
          ),
          const SizedBox(height: 14),
          _GrowthProgress(item: item),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: locked || item.representative || updatingRepresentative
                  ? null
                  : onSetRepresentative,
              style: FilledButton.styleFrom(
                backgroundColor: _potatoPrimary,
                disabledBackgroundColor: const Color(0xFFBFE5CC),
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(52),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: updatingRepresentative
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      item.representative ? '대표 감자로 설정됨' : '대표 감자로 설정',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RepresentativePotatoSheet extends StatelessWidget {
  const _RepresentativePotatoSheet({
    required this.collection,
    required this.onSelect,
  });

  final PotatoCollection collection;
  final ValueChanged<PotatoCollectionItem> onSelect;

  @override
  Widget build(BuildContext context) {
    final acquiredItems =
        collection.items.where((item) => item.acquired).toList(growable: false);

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
          const SizedBox(height: 8),
          Text(
            '대표로 세울 감자를 선택하세요. 수집한 감자 ${acquiredItems.length}개',
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
              fontWeight: FontWeight.w800,
              letterSpacing: 0,
            ),
          ),
          const SizedBox(height: 16),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: acquiredItems.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 0.76,
            ),
            itemBuilder: (context, index) {
              final item = acquiredItems[index];
              return _RepresentativePotatoOption(
                item: item,
                onSelect: () => onSelect(item),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _RepresentativePotatoOption extends StatelessWidget {
  const _RepresentativePotatoOption({
    required this.item,
    required this.onSelect,
  });

  final PotatoCollectionItem item;
  final VoidCallback onSelect;

  @override
  Widget build(BuildContext context) {
    final selected = item.representative;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: selected ? null : onSelect,
        child: Ink(
          decoration: BoxDecoration(
            color: selected
                ? _potatoPrimary.withValues(alpha: 0.12)
                : AppColors.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: selected ? _potatoPrimary : _potatoLine,
              width: selected ? 1.6 : 1,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(9),
            child: Column(
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    _PotatoArtSlot(item: item, locked: false, size: 66),
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
                  item.name,
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

class _InfoBlock extends StatelessWidget {
  const _InfoBlock({
    required this.title,
    required this.body,
  });

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFFF8FBF5),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _potatoLine),
      ),
      child: Padding(
        padding: const EdgeInsets.all(13),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w900,
                letterSpacing: 0,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              body,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
                height: 1.45,
                fontWeight: FontWeight.w600,
                letterSpacing: 0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GrowthProgress extends StatelessWidget {
  const _GrowthProgress({required this.item});

  final PotatoCollectionItem item;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                '성장 진행',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0,
                ),
              ),
            ),
            Text(
              '${(item.growthDistance / 1000).toStringAsFixed(1)} / '
              '${(item.growthGoalDistance / 1000).toStringAsFixed(1)}km',
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w800,
                letterSpacing: 0,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            minHeight: 10,
            value: item.growthRatio,
            backgroundColor: const Color(0xFFE7EFE9),
            valueColor: const AlwaysStoppedAnimation<Color>(_potatoPrimary),
          ),
        ),
      ],
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

class _PotatoEmptyState extends StatelessWidget {
  const _PotatoEmptyState();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _cardDecoration(),
      child: const Text(
        '조건에 맞는 감자가 없습니다.',
        textAlign: TextAlign.center,
        style: TextStyle(
          color: AppColors.textSecondary,
          fontSize: 14,
          fontWeight: FontWeight.w800,
          letterSpacing: 0,
        ),
      ),
    );
  }
}

BoxDecoration _cardDecoration({Color color = AppColors.surface}) {
  return BoxDecoration(
    color: color,
    borderRadius: BorderRadius.circular(8),
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
