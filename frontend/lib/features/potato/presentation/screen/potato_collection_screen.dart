import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_design_tokens.dart';
import '../../../../core/network/api_exception.dart';
import '../../application/potato_collection_controller.dart';
import '../../domain/potato_collection.dart';
import '../potato_asset.dart';

const _potatoPrimary = Color(0xFF56C787);
const _potatoDark = Color(0xFF509B64);
const _potatoYellow = Color(0xFFF5D84E);
const _potatoLine = Color(0xFFE8E2D8);
const _potatoCardRadius = AppDimens.cardRadius;
const _defaultPotatoSpeech = '아직은 작아도, 여행길은 잘 따라갈게요';
const _potatoCareBackgroundPath =
    'assets/characters/potatoes/potato_care_garden_background.png';
const _defaultPotatoCard = _PotatoCardSkeletonData(
  name: '새싹 감자',
  rarity: PotatoRarity.common,
  region: '강원 여행길',
  story: '아직 여행을 시작하지 않은 작은 감자예요. 첫 스탬프를 찍으면 도감 이야기가 하나씩 열립니다.',
  acquisitionLabel: '첫 감자 스팟 방문 전',
  acquiredDateLabel: '아직 없음',
  assetPath: potatoDefaultAssetPath,
  locked: false,
  cardNumber: '000',
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

  void _showDefaultPotatoDetail() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _PotatoCardDetailSheet(data: _defaultPotatoCard),
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
                    onShowDefaultDetail: _showDefaultPotatoDetail,
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
    required this.onShowDefaultDetail,
    required this.onChangeRepresentative,
  });

  final PotatoCollection collection;
  final bool updatingRepresentative;
  final ValueChanged<PotatoCollectionItem> onShowDetail;
  final VoidCallback onShowDefaultDetail;
  final VoidCallback onChangeRepresentative;

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
              padding: const EdgeInsets.fromLTRB(0, 28, 0, 12),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  _RepresentativePotatoCard(
                    item: representative,
                    acquiredCount: collection.acquiredCount,
                    totalCount: collection.totalCount,
                    updating: updatingRepresentative,
                    onShowDetail: representative == null
                        ? onShowDefaultDetail
                        : () => onShowDetail(representative),
                    onChangeRepresentative: onChangeRepresentative,
                  ),
                  const SizedBox(height: 8),
                  const _TodayStepCard(),
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
  State<_RepresentativePotatoCard> createState() =>
      _RepresentativePotatoCardState();
}

class _RepresentativePotatoCardState extends State<_RepresentativePotatoCard> {
  String? _careMessage;

  void _reactToCare(_PotatoCareAction action) {
    setState(() {
      _careMessage = switch (action) {
        _PotatoCareAction.pat => '기분이 조금 좋아졌어요',
        _PotatoCareAction.water => '좋아요, 오늘도 단단하게 자라볼게요',
        _PotatoCareAction.walk => '산책길은 내가 따라갈게요',
      };
    });
  }

  @override
  Widget build(BuildContext context) {
    final potato = widget.item;
    final progress =
        widget.totalCount == 0 ? 0.0 : widget.acquiredCount / widget.totalCount;
    final careMessage = _careMessage;
    final level = potato?.level ?? 1;
    final health = (62 + level * 4).clamp(62, 96);
    final moisture = (58 + widget.acquiredCount * 3).clamp(58, 94);
    final mood = careMessage == null ? 82 : 94;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      padding: const EdgeInsets.fromLTRB(0, 0, 0, 14),
      decoration: _cardDecoration(color: const Color(0xFFFFFCF2)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _PotatoCareStage(
            potato: potato,
            speech: careMessage ??
                (potato == null || !potato.acquired
                    ? _defaultPotatoSpeech
                    : _potatoSpeechFor(potato)),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    _MetaChip(label: 'Lv. $level'),
                    if (potato != null) _RarityBadge(rarity: potato.rarity),
                    if (potato != null) _MetaChip(label: potato.region),
                  ],
                ),
                const SizedBox(height: 10),
                _PotatoCareStats(
                  health: health,
                  moisture: moisture,
                  mood: mood,
                ),
                const SizedBox(height: 12),
                _PotatoCareBar(
                  onCare: _reactToCare,
                  enabled: potato == null || potato.acquired,
                ),
                const SizedBox(height: 12),
                _PotatoGrowthPanel(
                  potato: potato,
                  progress: progress.clamp(0, 1),
                  acquiredCount: widget.acquiredCount,
                  totalCount: widget.totalCount,
                  updating: widget.updating,
                  onShowDetail: widget.onShowDetail,
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
    required this.speech,
  });

  final PotatoCollectionItem? potato;
  final String speech;

  @override
  Widget build(BuildContext context) {
    final potatoName = potato?.name ?? '새싹 감자';
    final subtitle = potato == null ? '첫 여행을 기다리는 단계' : '강원 여행을 함께하는 대표 감자';

    return SizedBox(
      height: 328,
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
              top: 28,
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
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0,
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              top: 104,
              left: 20,
              child: Align(
                alignment: Alignment.centerLeft,
                child: _PotatoSpeechBubble(message: speech),
              ),
            ),
            Positioned(
              left: 80,
              right: 8,
              bottom: -22,
              child: SizedBox(
                height: 258,
                child: _PotatoArtSlot(
                  item: potato,
                  locked: potato?.acquired != true,
                  size: 258,
                  framed: false,
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
    required this.health,
    required this.moisture,
    required this.mood,
  });

  final int health;
  final int moisture;
  final int mood;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.84),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.textPrimary.withValues(alpha: 0.06),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _PotatoStatMeter(
              icon: Icons.eco_rounded,
              label: '포만감',
              value: health,
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

class _PotatoGrowthPanel extends StatelessWidget {
  const _PotatoGrowthPanel({
    required this.potato,
    required this.progress,
    required this.acquiredCount,
    required this.totalCount,
    required this.updating,
    required this.onShowDetail,
    required this.onChangeRepresentative,
  });

  final PotatoCollectionItem? potato;
  final double progress;
  final int acquiredCount;
  final int totalCount;
  final bool updating;
  final VoidCallback? onShowDetail;
  final VoidCallback onChangeRepresentative;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.82),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.textPrimary.withValues(alpha: 0.06),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  '다음 성장까지',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0,
                  ),
                ),
              ),
              Text(
                '$acquiredCount / $totalCount',
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            potato == null
                ? '첫 감자 카드를 만나면 성장 기록이 채워져요'
                : '감자걸음과 여행 기록으로 더 단단하게 자라요',
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
              fontWeight: FontWeight.w700,
              letterSpacing: 0,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              minHeight: 9,
              value: progress,
              backgroundColor: const Color(0xFFE8E5DA),
              valueColor: const AlwaysStoppedAnimation<Color>(_potatoPrimary),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onShowDetail,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _potatoDark,
                    side: BorderSide(
                      color: _potatoPrimary.withValues(alpha: 0.55),
                    ),
                    minimumSize: const Size.fromHeight(46),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(999),
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
                    minimumSize: const Size.fromHeight(46),
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

enum _PotatoCareAction {
  pat,
  water,
  walk,
}

class _PotatoCareBar extends StatelessWidget {
  const _PotatoCareBar({
    required this.onCare,
    required this.enabled,
  });

  final ValueChanged<_PotatoCareAction> onCare;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _PotatoCareButton(
            icon: Icons.favorite_rounded,
            label: '쓰다듬기',
            enabled: enabled,
            onPressed: () => onCare(_PotatoCareAction.pat),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _PotatoCareButton(
            icon: Icons.water_drop_rounded,
            label: '물 주기',
            enabled: enabled,
            onPressed: () => onCare(_PotatoCareAction.water),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _PotatoCareButton(
            icon: Icons.directions_walk_rounded,
            label: '산책',
            enabled: enabled,
            onPressed: () => onCare(_PotatoCareAction.walk),
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
    required this.enabled,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
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
                ? AppColors.primaryTint.withValues(alpha: 0.72)
                : const Color(0xFFF1F0EC),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: enabled ? _potatoDark : AppColors.textSecondary,
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
                    fontSize: 12,
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
          Center(
            child: _CollectiblePotatoCard(data: data),
          ),
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
          _InfoBlock(
            title: '감자 이야기',
            body: data.story,
          ),
          _InfoBlock(title: '획득 기록', body: data.acquisitionLabel),
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
        ? '이 카드는 아직 뒷면만 보여요. 관련 장소를 방문하면 감자의 이야기가 열립니다.'
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
      acquisitionLabel: locked
          ? (item.acquisitionHint.trim().isEmpty
              ? '관련 감자 스팟을 방문하면 열립니다.'
              : item.acquisitionHint.trim())
          : '${item.region}에서 수집',
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
      decoration: BoxDecoration(
        gradient: _cardSurfaceGradient(data.rarity),
      ),
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
          colors: [
            Color(0xFFEEF5EA),
            Color(0xFFFFFAEC),
          ],
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
    final stepLabel =
        '${_formatInt(summary.todaySteps)} / ${_formatInt(summary.dailyStepGoal)}걸음';
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
              color: AppColors.textSecondary,
              fontSize: 15,
              fontWeight: FontWeight.w800,
              letterSpacing: 0,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              SizedBox(
                width: 96,
                height: 96,
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
                          color: _potatoDark,
                          fontSize: 18,
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
                      stepLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0,
                      ),
                    ),
                    const SizedBox(height: 7),
                    Text(
                      '오늘 목표까지 $percent%',
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
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
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
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
    final assetPath = potato == null
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
        colors: [
          Color(0xFFE8E0D1),
          Color(0xFFB7AA95),
          Color(0xFFF7F0E2),
        ],
      ),
    PotatoRarity.rare => const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFF56C787),
          Color(0xFFFFD66B),
          Color(0xFF56C787),
        ],
      ),
    PotatoRarity.epic => const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFF7A5AF8),
          Color(0xFFF6C23E),
          Color(0xFF56C787),
        ],
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
        colors: [
          Color(0xFFFFFCF4),
          Color(0xFFF6F0E5),
        ],
      ),
    PotatoRarity.rare => const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFFFFFFFF),
          Color(0xFFE9FAEF),
          Color(0xFFFFF5D8),
        ],
      ),
    PotatoRarity.epic => const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFFFFFBF3),
          Color(0xFFF1EAFF),
          Color(0xFFE8F8EE),
        ],
      ),
    PotatoRarity.legendary => const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFFFFF8D9),
          Color(0xFFE9FAFF),
          Color(0xFFFFEFFA),
        ],
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
