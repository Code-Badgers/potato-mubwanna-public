import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_design_tokens.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../shared/widgets/loading/potato_loading_view.dart';
import '../../../feature_tour/presentation/feature_tour_host.dart';
import '../../../feature_tour/presentation/feature_tour_targets.dart';
import '../../application/potato_collection_controller.dart';
import '../../domain/potato_collection.dart';
import '../default_potato.dart';
import '../potato_asset.dart';

const _potatoPrimary = Color(0xFF56C787);
const _potatoDark = AppColors.actionGreen;
const _potatoYellow = Color(0xFFF5D84E);
const _potatoLine = Color(0xFFE8E2D8);
const _potatoCardRadius = AppDimens.cardRadius;
const _defaultPotatoSpeech = '아직은 작아도, 여행길은 잘 따라갈게요';
const _potatoCareBackgroundPath =
    'assets/characters/potatoes/potato_care_garden_background.png';
final _defaultPotatoCard = _PotatoCardSkeletonData(
  name: defaultBeginnerPotato.name,
  rarity: defaultBeginnerPotato.rarity,
  region: defaultBeginnerPotato.region,
  story: defaultBeginnerPotato.description,
  acquisitionLabel: defaultBeginnerPotato.acquisitionHint,
  acquiredDateLabel: '아직 없음',
  assetPath: potatoLocalAssetPath(defaultBeginnerPotato.code),
  locked: false,
  cardNumber: defaultBeginnerPotato.id.padLeft(3, '0'),
);

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

  Future<void> _showRepresentativePicker(PotatoCollection collection) async {
    final result = await showModalBottomSheet<
        ({PotatoCollectionItem item, bool showDetail})>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => _RepresentativePotatoSheet(
        collection: collection,
        onShowDetail: (item) {
          Navigator.of(sheetContext).pop((item: item, showDetail: true));
        },
        onSelect: (item) {
          Navigator.of(sheetContext).pop((item: item, showDetail: false));
        },
      ),
    );
    if (!mounted || result == null) {
      return;
    }
    if (result.showDetail) {
      await _showPotatoDetail(result.item);
    } else {
      await _updateRepresentativePotato(result.item);
    }
  }

  Future<void> _showPotatoDetail(PotatoCollectionItem item) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _PotatoDetailSheet(item: item),
    );
  }

  Future<void> _showDefaultPotatoDetail() {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _PotatoCardDetailSheet(data: _defaultPotatoCard),
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('대표 감자를 ${item.name}로 변경했어요.')));
    } on ApiException catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    } catch (_) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('대표 감자를 변경하지 못했습니다.')));
    } finally {
      if (mounted) {
        setState(() => _isUpdatingRepresentative = false);
      }
    }
  }

  Future<PotatoInteractionResult> _interactWithRepresentativePotato(
    PotatoInteractionAction action,
  ) async {
    final result = await ref
        .read(potatoRepositoryProvider)
        .interactWithRepresentativePotato(action);
    ref.invalidate(potatoCollectionProvider);
    ref.invalidate(potatoGrowthSummaryProvider);

    final growthResult = result.growthResult;
    if (growthResult?.leveledUp == true) {
      unawaited(_showGrowthFeedbackAfterCollectionLoads(growthResult!));
    }
    return result;
  }

  Future<PotatoHarvestResult> _harvestRepresentativePotato() async {
    final result =
        await ref.read(potatoRepositoryProvider).harvestRepresentativePotato();
    ref.invalidate(potatoCollectionProvider);
    ref.invalidate(potatoGrowthSummaryProvider);
    return result;
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
                    onShowDefaultDetail: _showDefaultPotatoDetail,
                    onChangeRepresentative: () =>
                        _showRepresentativePicker(collection),
                    onCare: _interactWithRepresentativePotato,
                    onHarvest: _harvestRepresentativePotato,
                  ),
                ),
          loading: () => const _PotatoStatusBody(
            child: PotatoLoadingView.compact(
              subtitle: '감자밭 상태를 확인하고 있어요',
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
                foregroundColor:
                    fullyGrown ? AppColors.textPrimary : AppColors.surface,
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
    required this.onShowDefaultDetail,
    required this.onChangeRepresentative,
    required this.onCare,
    required this.onHarvest,
  });

  final PotatoCollection collection;
  final bool updatingRepresentative;
  final Future<void> Function(PotatoCollectionItem) onShowDetail;
  final Future<void> Function() onShowDefaultDetail;
  final Future<void> Function() onChangeRepresentative;
  final Future<PotatoInteractionResult> Function(PotatoInteractionAction action)
      onCare;
  final Future<PotatoHarvestResult> Function() onHarvest;

  @override
  Widget build(BuildContext context) {
    final representative = collection.representativePotato;

    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(0, 16, 0, 12),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  _RepresentativePotatoCard(
                    item: representative,
                    growthProgress: representative?.growthRatio ?? 0.0,
                    updating: updatingRepresentative,
                    onShowDetail: representative == null
                        ? () => unawaited(onShowDefaultDetail())
                        : () => unawaited(onShowDetail(representative)),
                    onOpenDetail: representative == null
                        ? onShowDefaultDetail
                        : () => onShowDetail(representative),
                    onChangeRepresentative: onChangeRepresentative,
                    onCare: representative == null ? null : onCare,
                    onHarvest: representative == null ? null : onHarvest,
                  ),
                ],
              ),
            ),
          ),
        );
      },
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

class _RepresentativePotatoCard extends StatefulWidget {
  const _RepresentativePotatoCard({
    required this.item,
    required this.growthProgress,
    required this.updating,
    required this.onShowDetail,
    required this.onOpenDetail,
    required this.onChangeRepresentative,
    required this.onCare,
    required this.onHarvest,
  });

  final PotatoCollectionItem? item;
  final double growthProgress;
  final bool updating;
  final VoidCallback? onShowDetail;
  final Future<void> Function()? onOpenDetail;
  final Future<void> Function() onChangeRepresentative;
  final Future<PotatoInteractionResult> Function(
    PotatoInteractionAction action,
  )? onCare;
  final Future<PotatoHarvestResult> Function()? onHarvest;

  @override
  State<_RepresentativePotatoCard> createState() =>
      _RepresentativePotatoCardState();
}

class _RepresentativePotatoCardState extends State<_RepresentativePotatoCard> {
  String? _careMessage;
  bool _isCaring = false;
  bool _harvestedLocally = false;
  double _localHarvestProgressBonus = 0;

  @override
  void didUpdateWidget(covariant _RepresentativePotatoCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    final oldItem = oldWidget.item;
    final item = widget.item;
    if (oldItem?.id != item?.id) {
      _harvestedLocally = false;
      _localHarvestProgressBonus = 0;
      return;
    }
    if (oldItem?.level != item?.level ||
        oldItem?.growthDistance != item?.growthDistance ||
        oldItem?.growthGoalDistance != item?.growthGoalDistance) {
      _localHarvestProgressBonus = 0;
    }
  }

  Future<void> _reactToCare(PotatoInteractionAction action) async {
    final onCare = widget.onCare;
    if (onCare == null || _isCaring) {
      return;
    }

    setState(() => _isCaring = true);
    try {
      final result = await onCare(action);
      if (!mounted) {
        return;
      }
      setState(() {
        _localHarvestProgressBonus += _harvestProgressDelta(result);
        _careMessage = switch (action) {
          PotatoInteractionAction.pat => '잘했어요. 오늘은 조금 더 가까워졌네요',
          PotatoInteractionAction.water => '물을 줬어요. 싹이 또렷해졌네요',
          PotatoInteractionAction.snack => '영양제를 줬어요. 제법 잘 자라요',
        };
      });
      FeatureTourScope.maybeOf(context)?.completeTarget(
        FeatureTourTargets.potatoCareActions,
      );
    } on ApiException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.message)));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('감자를 돌보지 못했습니다. 다시 시도해주세요.')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isCaring = false);
      }
    }
  }

  Future<void> _harvestPotato(PotatoCollectionItem item) async {
    final onHarvest = widget.onHarvest;
    if (onHarvest == null) {
      return;
    }

    try {
      await onHarvest();
      if (!mounted) {
        return;
      }
      setState(() => _harvestedLocally = true);
      await showGeneralDialog<void>(
        context: context,
        barrierDismissible: true,
        barrierLabel: '감자 수확 닫기',
        barrierColor: Colors.black.withValues(alpha: 0.6),
        transitionDuration: const Duration(milliseconds: 220),
        pageBuilder: (_, __, ___) => _PotatoHarvestDialog(item: item),
        transitionBuilder: (_, animation, __, child) {
          final curved = CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
          );
          return FadeTransition(
            opacity: curved,
            child: ScaleTransition(
              scale: Tween<double>(
                begin: 0.94,
                end: 1,
              ).animate(curved),
              child: child,
            ),
          );
        },
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
        const SnackBar(content: Text('감자를 수확하지 못했습니다. 잠시 후 다시 시도해주세요.')),
      );
    }
  }

  double _harvestProgressDelta(PotatoInteractionResult result) {
    final item = widget.item;
    if (item == null ||
        item.growthGoalDistance <= 0 ||
        item.maxGrowthLevel <= 1) {
      return 0;
    }
    return result.growthDistanceAdded /
        item.growthGoalDistance /
        (item.maxGrowthLevel - 1);
  }

  @override
  Widget build(BuildContext context) {
    final potato = widget.item;
    final careMessage = _careMessage;
    final level = potato?.level ?? 1;
    final satiety = potato?.careStatus?.satiety ?? 0;
    final moisture = potato?.careStatus?.moisture ?? 0;
    final mood = potato?.careStatus?.mood ?? 0;
    final growthRatio = widget.growthProgress.clamp(0, 1).toDouble();
    final baseHarvestProgress = potato?.harvestProgress ?? growthRatio;
    final harvestProgress = (baseHarvestProgress + _localHarvestProgressBonus)
        .clamp(0, 1)
        .toDouble();
    final harvestPercent = (harvestProgress * 100).round();
    final growthStage = potato?.growthStage ?? 1;
    final harvested = _harvestedLocally || (potato?.harvested ?? false);
    final canHarvest = (potato?.canHarvest ?? false) && !harvested;
    final displayGrowthStage =
        harvested ? growthStage : growthStage.clamp(1, 3);

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      padding: const EdgeInsets.fromLTRB(0, 0, 0, 14),
      decoration: _cardDecoration(color: const Color(0xFFFFFCF2)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          KeyedSubtree(
            key: FeatureTourTargets.potatoGrowth,
            child: _PotatoCareStage(
              potato: potato,
              level: level,
              growthStage: displayGrowthStage,
              revealIdentity: harvested,
              speech: careMessage ??
                  (potato == null || !potato.acquired
                      ? _defaultPotatoSpeech
                      : _potatoSpeechFor(potato)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (potato != null)
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      _RarityBadge(rarity: potato.rarity),
                      _MetaChip(label: potato.region),
                    ],
                  ),
                if (potato != null) const SizedBox(height: 8),
                _PotatoCareStats(
                  satiety: satiety,
                  moisture: moisture,
                  mood: mood,
                ),
                const SizedBox(height: 16),
                _PotatoProgressLine(
                  label: '성장 진행도',
                  valueLabel: '$harvestPercent%',
                  value: harvestProgress,
                ),
                if (!harvested) ...[
                  const SizedBox(height: 8),
                  const Text('어떤 감자가 자랄까요?',
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
                ],
                const SizedBox(height: 16),
                KeyedSubtree(
                  key: FeatureTourTargets.potatoCareActions,
                  child: _PotatoCareBar(
                    onCare: _reactToCare,
                    enabled: potato != null &&
                        potato.acquired &&
                        widget.onCare != null &&
                        !_isCaring,
                  ),
                ),
                const SizedBox(height: 10),
                const _PotatoStepGrowthPanel(),
                const SizedBox(height: 16),
                _PotatoHarvestAction(
                  item: potato,
                  canHarvest: canHarvest,
                  harvested: harvested,
                  onHarvest: () {
                    final item = potato;
                    if (item == null) {
                      return;
                    }
                    unawaited(_harvestPotato(item));
                  },
                  onShowHarvested: widget.onShowDetail,
                ),
                const SizedBox(height: 10),
                _PotatoMainActions(
                  updating: widget.updating,
                  onOpenDetail: widget.onOpenDetail,
                  onChangeRepresentative: widget.onChangeRepresentative,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PotatoCareStage extends StatelessWidget {
  const _PotatoCareStage({
    required this.potato,
    required this.level,
    required this.growthStage,
    required this.revealIdentity,
    required this.speech,
  });

  final PotatoCollectionItem? potato;
  final int level;
  final int growthStage;
  final bool revealIdentity;
  final String speech;

  @override
  Widget build(BuildContext context) {
    final potatoName =
        revealIdentity ? (potato?.name ?? defaultBeginnerPotato.name) : '???';

    return SizedBox(
      height: 318,
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(_potatoCardRadius),
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: Image.asset(
                _potatoCareBackgroundPath,
                fit: BoxFit.cover,
                alignment: Alignment.bottomCenter,
              ),
            ),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.white.withValues(alpha: 0.84),
                      Colors.white.withValues(alpha: 0.06),
                      const Color(0xFFFFFCF2).withValues(alpha: 0.58),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              left: 20,
              right: 116,
              top: 24,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    potatoName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0,
                    ),
                  ),
                  const SizedBox(height: 6),
                  _PotatoSpeechBubble(message: speech),
                ],
              ),
            ),
            Positioned(
              right: 20,
              top: 26,
              child: _PotatoLevelBadge(level: level),
            ),
            Positioned(
              left: 28,
              right: 28,
              bottom: -28,
              child: SizedBox(
                height: 258,
                child: _PotatoArtSlot(
                  item: potato,
                  locked: potato?.acquired != true,
                  size: 258,
                  framed: false,
                  growthStage: growthStage,
                  useGrowthStageAsset: true,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PotatoCareStats extends StatelessWidget {
  const _PotatoCareStats({
    required this.satiety,
    required this.moisture,
    required this.mood,
  });

  final int satiety;
  final int moisture;
  final int mood;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: _PotatoStatMeter(
              icon: Icons.eco_rounded,
              label: '포만감',
              value: satiety,
              color: _potatoPrimary,
            ),
          ),
          _PotatoStatDivider(),
          Expanded(
            child: _PotatoStatMeter(
              icon: Icons.water_drop_rounded,
              label: '수분',
              value: moisture,
              color: const Color(0xFF51AEEB),
            ),
          ),
          _PotatoStatDivider(),
          Expanded(
            child: _PotatoStatMeter(
              icon: Icons.sentiment_satisfied_rounded,
              label: '기분',
              value: mood,
              color: const Color(0xFFF5C84B),
            ),
          ),
        ],
      ),
    );
  }
}

class _PotatoHarvestAction extends StatelessWidget {
  const _PotatoHarvestAction({
    required this.item,
    required this.canHarvest,
    required this.harvested,
    required this.onHarvest,
    required this.onShowHarvested,
  });

  final PotatoCollectionItem? item;
  final bool canHarvest;
  final bool harvested;
  final VoidCallback onHarvest;
  final VoidCallback? onShowHarvested;

  @override
  Widget build(BuildContext context) {
    final potato = item;
    final enabled = potato != null && (canHarvest || harvested);
    final label = potato == null
        ? '아직 자라고 있어요'
        : harvested
            ? '획득한 감자 보기'
            : canHarvest
                ? '감자 수확하기'
                : '아직 자라고 있어요';
    final helper = harvested
        ? '수확한 감자는 도감 카드에서 다시 볼 수 있어요'
        : canHarvest
            ? '완전히 자란 감자를 카드로 받을 수 있어요'
            : '조금만 더 돌보면 수확할 수 있어요';

    return DecoratedBox(
      decoration: BoxDecoration(
        color: canHarvest
            ? _potatoPrimary.withValues(alpha: 0.12)
            : const Color(0xFFF7F5EE),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 13, 14, 13),
        child: Row(
          children: [
            if (potato != null) ...[
              Expanded(
                child: Text(
                  helper,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                    height: 1.35,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0,
                  ),
                ),
              ),
              const SizedBox(width: 12),
            ] else
              const Spacer(),
            FilledButton(
              onPressed: enabled
                  ? harvested
                      ? onShowHarvested
                      : onHarvest
                  : null,
              style: FilledButton.styleFrom(
                backgroundColor: _potatoPrimary,
                disabledBackgroundColor: const Color(0xFFE1DED4),
                foregroundColor: AppColors.onPrimary,
                disabledForegroundColor: AppColors.textSecondary,
                minimumSize: const Size(132, 42),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 13,
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

class _PotatoHarvestDialog extends StatelessWidget {
  const _PotatoHarvestDialog({required this.item});

  final PotatoCollectionItem item;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Material(
        color: Colors.transparent,
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: const Color(0xFFFFFCF2),
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.18),
                    blurRadius: 32,
                    offset: const Offset(0, 18),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(22, 22, 22, 18),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 78,
                      height: 78,
                      decoration: BoxDecoration(
                        color: _potatoPrimary.withValues(alpha: 0.14),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.auto_awesome_rounded,
                        color: _potatoDark,
                        size: 38,
                      ),
                    ),
                    const SizedBox(height: 18),
                    const Text(
                      '새로운 감자를 수확했어요!',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${item.name} 카드가 도감에 들어왔어요',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0,
                      ),
                    ),
                    const SizedBox(height: 18),
                    _CollectiblePotatoCard(
                      data: _PotatoCardSkeletonData.fromItem(item),
                    ),
                    const SizedBox(height: 18),
                    FilledButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(50),
                        backgroundColor: _potatoPrimary,
                        foregroundColor: AppColors.onPrimary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                      child: const Text(
                        '감자 카드 보기',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PotatoMainActions extends StatelessWidget {
  const _PotatoMainActions({
    required this.updating,
    required this.onOpenDetail,
    required this.onChangeRepresentative,
  });

  final bool updating;
  final Future<void> Function()? onOpenDetail;
  final Future<void> Function() onChangeRepresentative;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: KeyedSubtree(
            key: FeatureTourTargets.potatoInfo,
            child: OutlinedButton.icon(
              onPressed: onOpenDetail == null
                  ? null
                  : () async {
                      await onOpenDetail!();
                      if (!context.mounted) {
                        return;
                      }
                      FeatureTourScope.maybeOf(context)?.completeNavigation();
                    },
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.actionGreen,
                side: BorderSide(color: _potatoPrimary.withValues(alpha: 0.55)),
                minimumSize: const Size.fromHeight(44),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              icon: const Icon(Icons.info_outline_rounded, size: 17),
              label: const Text(
                '정보 보기',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: KeyedSubtree(
            key: FeatureTourTargets.representativePotato,
            child: FilledButton(
              onPressed: updating
                  ? null
                  : () async {
                      await onChangeRepresentative();
                      if (!context.mounted) {
                        return;
                      }
                      FeatureTourScope.maybeOf(context)?.completeNavigation();
                    },
              style: FilledButton.styleFrom(
                backgroundColor: _potatoPrimary,
                disabledBackgroundColor: const Color(0xFFBFE5CC),
                foregroundColor: AppColors.onPrimary,
                minimumSize: const Size.fromHeight(44),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(999),
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
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0,
                      ),
                    ),
            ),
          ),
        ),
      ],
    );
  }
}

class _PotatoLevelBadge extends StatelessWidget {
  const _PotatoLevelBadge({required this.level});

  final int level;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: _potatoPrimary,
        borderRadius: BorderRadius.circular(999),
        boxShadow: [
          BoxShadow(
            color: _potatoPrimary.withValues(alpha: 0.22),
            blurRadius: 14,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
        child: Text(
          'Lv. $level',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w900,
            letterSpacing: 0,
          ),
        ),
      ),
    );
  }
}

class _PotatoStatDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 42,
      margin: const EdgeInsets.symmetric(horizontal: 8),
      color: _potatoLine.withValues(alpha: 0.72),
    );
  }
}

class _PotatoStatMeter extends StatelessWidget {
  const _PotatoStatMeter({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final int value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final progress = (value / 100).clamp(0, 1).toDouble();
    return Row(
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0,
                ),
              ),
              const SizedBox(height: 5),
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  minHeight: 5,
                  value: progress,
                  backgroundColor: const Color(0xFFE8E5DA),
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '$value / 100',
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
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

class _PotatoCareBar extends StatelessWidget {
  const _PotatoCareBar({required this.onCare, required this.enabled});

  final ValueChanged<PotatoInteractionAction> onCare;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _PotatoCareButton(
            icon: Icons.favorite_rounded,
            label: '쓰다듬기',
            color: _potatoPrimary,
            enabled: enabled,
            onPressed: () => onCare(PotatoInteractionAction.pat),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _PotatoCareButton(
            icon: Icons.water_drop_rounded,
            label: '물 주기',
            color: const Color(0xFF3FA9E6),
            enabled: enabled,
            onPressed: () => onCare(PotatoInteractionAction.water),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _PotatoCareButton(
            icon: Icons.eco_rounded,
            label: '영양제',
            color: const Color(0xFF78B95C),
            enabled: enabled,
            onPressed: () => onCare(PotatoInteractionAction.snack),
          ),
        ),
      ],
    );
  }
}

class _PotatoCareButton extends StatelessWidget {
  const _PotatoCareButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.enabled,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final Color color;
  final bool enabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: enabled ? onPressed : null,
        child: Ink(
          height: 38,
          decoration: BoxDecoration(
            color: enabled
                ? color.withValues(alpha: 0.18)
                : const Color(0xFFF1F0EC),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: enabled
                  ? color.withValues(alpha: 0.34)
                  : const Color(0xFFE0DED6),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: enabled ? color : AppColors.textSecondary,
                size: 16,
              ),
              const SizedBox(width: 5),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: enabled ? _potatoDark : AppColors.textSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PotatoSpeechBubble extends StatelessWidget {
  const _PotatoSpeechBubble({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 260),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: _potatoLine),
          boxShadow: [
            BoxShadow(
              color: AppColors.textPrimary.withValues(alpha: 0.05),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
          child: Text(
            message,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 13,
              height: 1.35,
              fontWeight: FontWeight.w800,
              letterSpacing: 0,
            ),
          ),
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
    return _PotatoCardDetailSheet(data: _PotatoCardSkeletonData.fromItem(item));
  }
}

class _PotatoCardDetailSheet extends StatelessWidget {
  const _PotatoCardDetailSheet({required this.data});

  final _PotatoCardSkeletonData data;

  @override
  Widget build(BuildContext context) {
    final locked = data.locked;

    return _BottomSheetFrame(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  locked ? '아직 만나지 못한 감자' : data.name,
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
          Center(child: _CollectiblePotatoCard(data: data)),
          const SizedBox(height: 18),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _RarityBadge(rarity: data.rarity),
              _MetaChip(label: data.region),
              _MetaChip(label: locked ? '미획득' : data.acquiredDateLabel),
            ],
          ),
          const SizedBox(height: 18),
          _InfoBlock(title: '감자 이야기', body: data.story),
          _InfoBlock(title: '획득 방법', body: data.acquisitionLabel),
          if (data.item != null) _GrowthProgress(item: data.item!),
        ],
      ),
    );
  }
}

class _PotatoCardSkeletonData {
  const _PotatoCardSkeletonData({
    required this.name,
    required this.rarity,
    required this.region,
    required this.story,
    required this.acquisitionLabel,
    required this.acquiredDateLabel,
    required this.assetPath,
    required this.locked,
    required this.cardNumber,
    this.item,
  });

  final String name;
  final PotatoRarity rarity;
  final String region;
  final String story;
  final String acquisitionLabel;
  final String acquiredDateLabel;
  final String assetPath;
  final bool locked;
  final String cardNumber;
  final PotatoCollectionItem? item;

  static _PotatoCardSkeletonData fromItem(PotatoCollectionItem item) {
    final locked = !item.acquired;
    final story = locked
        ? '아직 만나지 못한 감자예요. 획득하면 감자의 이야기가 열려요.'
        : (item.description.trim().isEmpty
            ? '${item.region} 여행길에서 열린 감자 카드예요.'
            : item.description.trim());
    final acquiredDate = item.acquiredAt == null
        ? '획득 전'
        : '${item.acquiredAt!.year}.${item.acquiredAt!.month.toString().padLeft(2, '0')}.${item.acquiredAt!.day.toString().padLeft(2, '0')}';

    return _PotatoCardSkeletonData(
      name: locked ? '???' : item.name,
      rarity: item.rarity,
      region: item.region.trim().isEmpty ? '강원' : item.region,
      story: story,
      acquisitionLabel: item.acquisitionGuidance,
      acquiredDateLabel: acquiredDate,
      assetPath: potatoLocalAssetPath(item.code),
      locked: locked,
      cardNumber: item.id.padLeft(3, '0'),
      item: item,
    );
  }
}

class _CollectiblePotatoCard extends StatefulWidget {
  const _CollectiblePotatoCard({required this.data});

  final _PotatoCardSkeletonData data;

  @override
  State<_CollectiblePotatoCard> createState() => _CollectiblePotatoCardState();
}

class _CollectiblePotatoCardState extends State<_CollectiblePotatoCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _shineController;
  Offset _dragOffset = Offset.zero;

  @override
  void initState() {
    super.initState();
    _shineController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat();
  }

  @override
  void dispose() {
    _shineController.dispose();
    super.dispose();
  }

  void _updateTilt(DragUpdateDetails details) {
    final renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null) {
      return;
    }
    final size = renderBox.size;
    if (size.isEmpty) {
      return;
    }
    final local = renderBox.globalToLocal(details.globalPosition);
    setState(() {
      _dragOffset = Offset(
        ((local.dx / size.width) - 0.5).clamp(-0.5, 0.5),
        ((local.dy / size.height) - 0.5).clamp(-0.5, 0.5),
      );
    });
  }

  void _resetTilt() {
    setState(() => _dragOffset = Offset.zero);
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.data;
    final border = _cardBorderGradient(data.rarity);
    final tiltX = _dragOffset.dy * -0.16;
    final tiltY = _dragOffset.dx * 0.16;

    return GestureDetector(
      onPanUpdate: _updateTilt,
      onPanEnd: (_) => _resetTilt(),
      onPanCancel: _resetTilt,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOut,
        transform: Matrix4.identity()
          ..setEntry(3, 2, 0.001)
          ..rotateX(tiltX)
          ..rotateY(tiltY),
        transformAlignment: Alignment.center,
        child: Container(
          width: 232,
          height: 330,
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            gradient: border,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: _rarityColor(data.rarity).withValues(alpha: 0.20),
                blurRadius: 24,
                offset: const Offset(0, 16),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(21),
            child: Stack(
              fit: StackFit.expand,
              children: [
                data.locked
                    ? _PotatoCardBack(data: data)
                    : _PotatoCardFront(data: data),
                if (!data.locked)
                  _CardShineOverlay(animation: _shineController),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PotatoCardFront extends StatelessWidget {
  const _PotatoCardFront({required this.data});

  final _PotatoCardSkeletonData data;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(gradient: _cardSurfaceGradient(data.rarity)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    '#${data.cardNumber}',
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
                _RarityBadge(rarity: data.rarity),
              ],
            ),
            const SizedBox(height: 10),
            Expanded(
              child: Center(
                child: Image.asset(
                  data.assetPath,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) =>
                      const _PotatoArtFallback(locked: false),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              data.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 21,
                fontWeight: FontWeight.w900,
                letterSpacing: 0,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              data.region,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
                fontWeight: FontWeight.w800,
                letterSpacing: 0,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              data.story,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
                height: 1.42,
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

class _PotatoCardBack extends StatelessWidget {
  const _PotatoCardBack({required this.data});

  final _PotatoCardSkeletonData data;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFEEF5EA), Color(0xFFFFFAEC)],
        ),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(painter: _CardBackPatternPainter()),
          ),
          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              children: [
                Align(
                  alignment: Alignment.topLeft,
                  child: Text(
                    '#${data.cardNumber}',
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
                const Spacer(),
                Container(
                  width: 88,
                  height: 88,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.72),
                  ),
                  child: const Icon(
                    Icons.lock_rounded,
                    color: AppColors.textSecondary,
                    size: 34,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  '아직 만나지 못한 감자',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  data.acquisitionLabel,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                    height: 1.42,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0,
                  ),
                ),
                const Spacer(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CardShineOverlay extends AnimatedWidget {
  const _CardShineOverlay({required Animation<double> animation})
      : super(listenable: animation);

  @override
  Widget build(BuildContext context) {
    final value = (listenable as Animation<double>).value;
    final start = -1.1 + value * 2.2;

    return IgnorePointer(
      child: FractionalTranslation(
        translation: Offset(start, 0),
        child: Transform.rotate(
          angle: math.pi / 10,
          child: Container(
            width: 74,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.white.withValues(alpha: 0),
                  Colors.white.withValues(alpha: 0.24),
                  Colors.white.withValues(alpha: 0),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CardBackPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = _potatoPrimary.withValues(alpha: 0.08)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;
    for (double x = -size.height; x < size.width; x += 18) {
      canvas.drawLine(
        Offset(x, size.height),
        Offset(x + size.height, 0),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _InfoBlock extends StatelessWidget {
  const _InfoBlock({required this.title, required this.body});

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

class _PotatoStepGrowthPanel extends ConsumerWidget {
  const _PotatoStepGrowthPanel();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaryState = ref.watch(potatoGrowthSummaryProvider);
    final summary = summaryState.valueOrNull ??
        const PotatoGrowthSummary(
          todaySteps: 0,
          dailyStepGoal: 10000,
          weeklyDistanceKm: 0,
          monthlyDistanceKm: 0,
          remainingDistanceKmForRepresentative: 0,
        );
    final ratio = summary.stepRatio;
    final stepLabel =
        '${_formatInt(summary.todaySteps)} / ${_formatInt(summary.dailyStepGoal)}걸음';
    final isLoading =
        summaryState.isLoading && summaryState.valueOrNull == null;
    final hasError = summaryState.hasError && summaryState.valueOrNull == null;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.74),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: _potatoPrimary.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.directions_walk_rounded,
                    color: _potatoDark,
                    size: 19,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '오늘 감자걸음',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        isLoading
                            ? '걸음 수를 불러오는 중'
                            : hasError
                                ? '걸음 수를 다시 확인해주세요'
                                : stepLabel,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                minHeight: 7,
                value: ratio,
                backgroundColor: const Color(0xFFE7EFE9),
                valueColor: const AlwaysStoppedAnimation<Color>(_potatoPrimary),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PotatoProgressLine extends StatelessWidget {
  const _PotatoProgressLine({
    required this.label,
    required this.valueLabel,
    required this.value,
  });

  final String label;
  final String valueLabel;
  final double value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0,
                ),
              ),
            ),
            Text(
              valueLabel,
              style: const TextStyle(
                color: _potatoDark,
                fontSize: 13,
                fontWeight: FontWeight.w900,
                letterSpacing: 0,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            minHeight: 8,
            value: value,
            backgroundColor: const Color(0xFFE7EFE9),
            valueColor: const AlwaysStoppedAnimation<Color>(_potatoPrimary),
          ),
        ),
      ],
    );
  }
}

class _PotatoArtSlot extends StatelessWidget {
  const _PotatoArtSlot({
    required this.item,
    required this.locked,
    required this.size,
    this.framed = true,
    this.growthStage,
    this.useGrowthStageAsset = false,
  });

  final PotatoCollectionItem? item;
  final bool locked;
  final double size;
  final bool framed;
  final int? growthStage;
  final bool useGrowthStageAsset;

  @override
  Widget build(BuildContext context) {
    final potato = item;
    final assetPath = useGrowthStageAsset
        ? potatoGrowthStageAssetPath(
            stage: growthStage ?? potato?.growthStage ?? 1,
            finalPotatoCode: potato?.code ?? defaultBeginnerPotato.code,
          )
        : potato == null
            ? potatoDefaultAssetPath
            : potatoLocalAssetPath(potato.code);

    final image = Image.asset(
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
    if (!framed) {
      return SizedBox(
        width: size,
        height: size,
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(size * 0.02),
            child: visualImage,
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
          child: visualImage,
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
          Icon(Icons.lock_open_rounded, color: _potatoDark, size: 30),
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
        SliverFillRemaining(hasScrollBody: false, child: child),
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
  const _PotatoErrorState({required this.message, required this.onRetry});

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
          OutlinedButton(onPressed: onRetry, child: const Text('다시 불러오기')),
        ],
      ),
    );
  }
}

BoxDecoration _cardDecoration({Color color = AppColors.surface}) {
  return BoxDecoration(
    color: color.withValues(alpha: 0.94),
    borderRadius: BorderRadius.circular(_potatoCardRadius),
    border: Border.all(color: _potatoLine.withValues(alpha: 0.82)),
    boxShadow: AppShadows.softCard,
  );
}

Color _rarityColor(PotatoRarity rarity) {
  return switch (rarity) {
    PotatoRarity.common => const Color(0xFF7A6F5B),
    PotatoRarity.rare => const Color(0xFF56B982),
    PotatoRarity.epic => const Color(0xFF9B6CE8),
    PotatoRarity.legendary => const Color(0xFFE0A91B),
  };
}

Gradient _cardBorderGradient(PotatoRarity rarity) {
  return switch (rarity) {
    PotatoRarity.common => const LinearGradient(
        colors: [Color(0xFFE8E0D1), Color(0xFFB7AA95), Color(0xFFF7F0E2)],
      ),
    PotatoRarity.rare => const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF56C787), Color(0xFFFFD66B), Color(0xFF56C787)],
      ),
    PotatoRarity.epic => const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF7A5AF8), Color(0xFFF6C23E), Color(0xFF56C787)],
      ),
    PotatoRarity.legendary => const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFFFFF3A1),
          Color(0xFF6FE6FF),
          Color(0xFFFF91DF),
          Color(0xFFFFD66B),
        ],
      ),
  };
}

Gradient _cardSurfaceGradient(PotatoRarity rarity) {
  return switch (rarity) {
    PotatoRarity.common => const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFFFFFCF4), Color(0xFFF6F0E5)],
      ),
    PotatoRarity.rare => const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFFFFFFF), Color(0xFFE9FAEF), Color(0xFFFFF5D8)],
      ),
    PotatoRarity.epic => const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFFFFBF3), Color(0xFFF1EAFF), Color(0xFFE8F8EE)],
      ),
    PotatoRarity.legendary => const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFFFF8D9), Color(0xFFE9FAFF), Color(0xFFFFEFFA)],
      ),
  };
}

String _potatoSpeechFor(PotatoCollectionItem potato) {
  if (potato.region.trim().isNotEmpty) {
    return '${potato.region} 바람은 좀 다르네요';
  }
  return switch (potato.rarity) {
    PotatoRarity.common => '오늘도 한 걸음만 더 가봐요',
    PotatoRarity.rare => '나, 아무 데서나 만나는 감자 아니에요',
    PotatoRarity.epic => '이 정도면 꽤 멀리 온 거예요',
    PotatoRarity.legendary => '강원도 길을 제법 아는 얼굴이네요',
  };
}
