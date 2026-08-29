import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_design_tokens.dart';
import '../../../../core/location/location_service.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../shared/widgets/loading/potato_loading_view.dart';
import '../../../auth/application/auth_controller.dart';
import '../../../feature_tour/presentation/feature_tour_host.dart';
import '../../../feature_tour/presentation/feature_tour_targets.dart';
import '../../application/mission_controller.dart';
import '../../data/mission_native_input_service.dart';
import '../../data/mission_repository.dart';
import '../../data/mission_upload_repository.dart';
import '../../domain/mission_challenge.dart';
import '../../domain/mission_verification.dart';
import '../mission_jumsooni_dialogue.dart';

const _missionPrimary = Color(0xFF56C787);
const _missionDark = Color(0xFF6A4A2A);
const _missionGold = Color(0xFFF6C23E);
const _missionLine = Color(0xFFE8E2D8);
const _missionCardRadius = AppDimens.cardRadius;
const _featuredJumsooniAssets = [
  'assets/characters/jumsooni/jumsooni_neutral.png',
  'assets/characters/jumsooni/jumsooni_wave_hand.png',
  'assets/characters/jumsooni/jumsooni_point.png',
  'assets/characters/jumsooni/jumsooni_potato_hold.png',
  'assets/characters/jumsooni/jumsooni_cheer.png',
  'assets/characters/jumsooni/jumsooni_thinking.png',
  'assets/characters/jumsooni/jumsooni_surprised.png',
  'assets/characters/jumsooni/jumsooni_thumb.png',
];

class MissionScreen extends ConsumerStatefulWidget {
  const MissionScreen({
    this.visitEntrySpotName,
    this.visitEntryMissionId,
    super.key,
  });

  final String? visitEntrySpotName;
  final String? visitEntryMissionId;

  @override
  ConsumerState<MissionScreen> createState() => _MissionScreenState();
}

class _MissionScreenState extends ConsumerState<MissionScreen> {
  static const _verificationService = MissionVerificationService();

  String? _selectedMissionId;
  bool _isCompleting = false;

  @override
  void initState() {
    super.initState();
    _selectedMissionId = widget.visitEntryMissionId;
  }

  void _showMissionDetail(String missionId) {
    setState(() => _selectedMissionId = missionId);
  }

  void _closeMissionDetail() {
    setState(() => _selectedMissionId = null);
  }

  void _showRewardDialog(MissionChallenge mission) {
    showDialog<void>(
      context: context,
      builder: (_) => _MissionRewardDialog(mission: mission),
    );
  }

  Future<void> _completeMission(
    MissionChallenge mission,
    MissionVerificationPayload payload,
  ) async {
    if (_isCompleting) {
      return;
    }
    setState(() => _isCompleting = true);
    try {
      final completedMission = await ref
          .read(missionsProvider.notifier)
          .complete(mission.id, payload);
      if (!mounted) {
        return;
      }
      _showRewardDialog(completedMission);
    } on ApiException catch (error) {
      if (!mounted) {
        return;
      }
      _showSnackBar(error.message);
    } catch (_) {
      if (!mounted) {
        return;
      }
      _showSnackBar('미션 완료에 실패했습니다. 잠시 후 다시 시도해주세요.');
    } finally {
      if (mounted) {
        setState(() => _isCompleting = false);
      }
    }
  }

  Future<void> _startMission(MissionChallenge mission) async {
    final payload = await switch (mission.type) {
      MissionType.quiz => Future<MissionVerificationPayload?>.value(null),
      MissionType.visitAndStep => _verifyStepMission(mission),
      MissionType.photo || MissionType.photoOcr => _showPhotoChallenge(mission),
      MissionType.qrScan => _scanQrMission(mission),
      _ => Future<MissionVerificationPayload?>.value(
          MissionVerificationPayload(type: mission.type),
        ),
    };
    if (!mounted || payload == null) {
      return;
    }
    await _completeMission(mission, payload);
  }

  Future<MissionVerificationPayload?> _verifyStepMission(
    MissionChallenge mission,
  ) async {
    return MissionVerificationPayload(
      type: mission.type,
      stepCount: mission.progress,
    );
  }

  Future<MissionVerificationPayload?> _showPhotoChallenge(
    MissionChallenge mission,
  ) async {
    final evidence = await _showPhotoInputSheet(mission);
    if (evidence == null) {
      return null;
    }
    final result = _verificationService.verifyPhotoUpload(
      mission: mission,
      uploaded: evidence.uploadKey.isNotEmpty,
    );
    if (!result.canComplete) {
      _showSnackBar(result.message);
      return null;
    }
    return MissionVerificationPayload(
      type: mission.type,
      uploadKey: evidence.uploadKey,
      latitude: evidence.latitude,
      longitude: evidence.longitude,
    );
  }

  Future<MissionVerificationPayload?> _scanQrMission(
    MissionChallenge mission,
  ) async {
    try {
      final qrCode =
          await ref.read(missionNativeInputServiceProvider).scanQrCode(context);
      if (!mounted || qrCode == null) {
        return null;
      }
      if (qrCode.trim().isEmpty) {
        _showSnackBar('QR 코드를 스캔한 뒤 다시 시도해주세요.');
        return null;
      }
      return MissionVerificationPayload(
        type: mission.type,
        qrCode: qrCode,
      );
    } on MissionInputException catch (error) {
      if (mounted) {
        _showSnackBar(error.message);
      }
      return null;
    }
  }

  MissionNativeInputService get _nativeInputService {
    return ref.read(missionNativeInputServiceProvider);
  }

  Future<_MissionPhotoEvidence?> _showPhotoInputSheet(
    MissionChallenge mission,
  ) {
    return showModalBottomSheet<_MissionPhotoEvidence>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _MissionPhotoSheet(
        mission: mission,
        inputService: _nativeInputService,
        uploadRepository: ref.read(missionUploadRepositoryProvider),
        locationService: ref.read(missionLocationServiceProvider),
      ),
    );
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authStatus = ref.watch(authControllerProvider).status;
    if (authStatus == AuthStatus.loading) {
      return const _MissionScaffold(
        child: _MissionLoadingState(),
      );
    }
    if (authStatus != AuthStatus.authenticated) {
      return _MissionScaffold(
        child: _MissionGuestPreview(onLogin: () => context.go('/login')),
      );
    }

    final missionsState = ref.watch(missionsProvider);
    final selectedMissionId = _selectedMissionId;
    final selectedMission = selectedMissionId == null
        ? null
        : ref.watch(missionByIdProvider(selectedMissionId));

    if (selectedMissionId != null && selectedMission != null) {
      return _wrapMissionDetailBack(
        _MissionDetailView(
          mission: selectedMission,
          onBack: _closeMissionDetail,
          isCompleting: _isCompleting,
          onComplete:
              _isCompleting ? null : () => _startMission(selectedMission),
          onSubmitQuiz: _isCompleting
              ? null
              : (answer) => _completeMission(
                    selectedMission,
                    MissionVerificationPayload(
                      type: selectedMission.type,
                      answer: answer,
                    ),
                  ),
        ),
      );
    }

    if (selectedMissionId != null && missionsState.isLoading) {
      return _wrapMissionDetailBack(
        const _MissionScaffold(
          child: _MissionLoadingState(),
        ),
      );
    }

    if (selectedMissionId != null && missionsState.hasError) {
      final error = missionsState.error;
      return _wrapMissionDetailBack(
        _MissionScaffold(
          child: _MissionErrorState(
            message:
                error is ApiException ? error.message : '미션 정보를 불러오지 못했습니다.',
            onRetry: () => ref.read(missionsProvider.notifier).load(),
          ),
        ),
      );
    }

    if (selectedMissionId != null && selectedMission == null) {
      return _wrapMissionDetailBack(
        _MissionScaffold(
          child: _MissionErrorState(
            message: '미션 정보를 찾지 못했습니다.',
            onRetry: _closeMissionDetail,
          ),
        ),
      );
    }

    return missionsState.when(
      loading: () => const _MissionScaffold(
        child: _MissionLoadingState(),
      ),
      error: (error, _) => _MissionScaffold(
        child: _MissionErrorState(
          message: error is ApiException ? error.message : '미션 정보를 불러오지 못했습니다.',
          onRetry: () => ref.read(missionsProvider.notifier).load(),
        ),
      ),
      data: _buildMissionList,
    );
  }

  Widget _wrapMissionDetailBack(Widget child) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          _closeMissionDetail();
        }
      },
      child: child,
    );
  }

  Widget _buildMissionList(List<MissionChallenge> missions) {
    final featuredMission = _featuredMission(missions);
    final todayMissions = _todayMissions(
      missions,
      excludedMissionId: featuredMission?.id,
    );
    final todayMissionTotalCount = missions
        .where((mission) =>
            mission.active &&
            mission.status != MissionStatus.locked &&
            mission.id != featuredMission?.id)
        .length
        .clamp(0, _todayMissionLimit)
        .toInt();
    // 완료된 카드는 목록에서 제외되므로, 진행 수치는 필터 전 상태로 계산한다.
    final completedMissionCount = missions
        .where((mission) =>
            mission.active && mission.status == MissionStatus.completed)
        .length
        .clamp(0, todayMissionTotalCount)
        .toInt();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            if (widget.visitEntrySpotName != null)
              SliverToBoxAdapter(
                child: _VisitMissionEntryBanner(
                  spotName: widget.visitEntrySpotName!,
                ),
              ),
            SliverToBoxAdapter(
              child: _MissionGentleStart(
                featuredMission: featuredMission,
                missions: todayMissions,
                completedCount: completedMissionCount,
                totalCount: todayMissionTotalCount,
                onMissionTap: _showMissionDetail,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

const _todayMissionLimit = 3;

MissionChallenge? _featuredMission(List<MissionChallenge> missions) {
  final candidates = missions
      .where((mission) =>
          mission.active &&
          mission.status != MissionStatus.locked &&
          mission.status != MissionStatus.completed)
      .toList()
    ..sort(_compareMissionPriority);
  for (final mission in candidates) {
    if (mission.type == MissionType.photo ||
        mission.type == MissionType.photoOcr) {
      return mission;
    }
  }
  return candidates.isEmpty ? null : candidates.first;
}

List<MissionChallenge> _todayMissions(
  List<MissionChallenge> missions, {
  String? excludedMissionId,
}) {
  final candidates = missions
      .where((mission) =>
          mission.active &&
          mission.status != MissionStatus.locked &&
          mission.status != MissionStatus.completed &&
          mission.id != excludedMissionId)
      .toList()
    ..sort(_compareMissionPriority);
  final selected = <MissionChallenge>[];

  void addFirstWhere(bool Function(MissionChallenge mission) test) {
    for (final mission in candidates) {
      final alreadySelected =
          selected.any((selectedMission) => selectedMission.id == mission.id);
      if (!alreadySelected &&
          test(mission) &&
          selected.length < _todayMissionLimit) {
        selected.add(mission);
        return;
      }
    }
  }

  addFirstWhere((mission) => mission.type == MissionType.visitAndStep);
  addFirstWhere((mission) =>
      mission.type == MissionType.photo ||
      mission.type == MissionType.photoOcr);
  addFirstWhere((mission) => mission.type == MissionType.quiz);
  addFirstWhere((mission) => mission.type == MissionType.qrScan);
  addFirstWhere((mission) =>
      mission.type == MissionType.visit || mission.type == MissionType.stamp);

  for (final mission in candidates) {
    if (selected.length >= _todayMissionLimit) {
      break;
    }
    if (!selected.any((selectedMission) => selectedMission.id == mission.id)) {
      selected.add(mission);
    }
  }

  return selected;
}

class _VisitMissionEntryBanner extends StatelessWidget {
  const _VisitMissionEntryBanner({required this.spotName});

  final String spotName;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
      child: Container(
        key: const ValueKey('visit-mission-entry-banner'),
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF6DE),
          borderRadius: BorderRadius.circular(_missionCardRadius),
          border: Border.all(color: const Color(0xFFFFE1A3)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: const BoxDecoration(
                color: AppColors.surface,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.flag_rounded,
                color: _missionGold,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '방문 인증 미션이 열렸어요',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$spotName에서 이어지는 미션을 확인하고 바로 도전해보세요.',
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      height: 1.35,
                      letterSpacing: 0,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

int _compareMissionPriority(MissionChallenge a, MissionChallenge b) {
  final priority = _missionSortPriority(a).compareTo(_missionSortPriority(b));
  if (priority != 0) {
    return priority;
  }
  return a.title.compareTo(b.title);
}

int _missionSortPriority(MissionChallenge mission) {
  if (mission.status == MissionStatus.completed) {
    return 3;
  }
  if (!mission.active || mission.status == MissionStatus.locked) {
    return 2;
  }
  return 1;
}

class _MissionScaffold extends StatelessWidget {
  const _MissionScaffold({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(child: child),
    );
  }
}

class _MissionLoadingState extends StatelessWidget {
  const _MissionLoadingState();

  @override
  Widget build(BuildContext context) {
    return const PotatoLoadingView.fullScreen(
      subtitle: '점순이가 오늘 미션을 고르고 있어요',
    );
  }
}

class _MissionGuestPreview extends StatelessWidget {
  const _MissionGuestPreview({required this.onLogin});

  final VoidCallback onLogin;

  @override
  Widget build(BuildContext context) {
    final previews = [
      (Icons.directions_walk_rounded, '가볍게 걷기', '감자 걸음은 로그인 후 저장돼요'),
      (Icons.place_rounded, '명소 방문하기', '방문 인증은 로그인 후 남길 수 있어요'),
      (Icons.quiz_rounded, '강원 퀴즈 풀기', '정답 기록은 로그인 후 반영돼요'),
    ];

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 18, 24, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '점순이의 미션',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 30,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  '둘러보기는 바로 가능해요. 미션 기록과 보상 저장은 로그인 후 이어집니다.',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    height: 1.45,
                    letterSpacing: 0,
                  ),
                ),
                const SizedBox(height: 18),
                for (final preview in previews) ...[
                  _MissionGuestPreviewTile(
                    icon: preview.$1,
                    title: preview.$2,
                    subtitle: preview.$3,
                  ),
                  const SizedBox(height: 10),
                ],
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: FilledButton(
                    onPressed: onLogin,
                    style: FilledButton.styleFrom(
                      backgroundColor: _missionPrimary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                    child: const Text(
                      '로그인하고 기록 저장하기',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _MissionGuestPreviewTile extends StatelessWidget {
  const _MissionGuestPreviewTile({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(_missionCardRadius),
        boxShadow: AppShadows.softCard,
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.primaryTint.withValues(alpha: 0.9),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: AppColors.primaryDark, size: 23),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
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

class _MissionErrorState extends StatelessWidget {
  const _MissionErrorState({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              color: _missionDark,
              size: 42,
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w800,
                letterSpacing: 0,
              ),
            ),
            const SizedBox(height: 18),
            FilledButton(
              onPressed: onRetry,
              style: FilledButton.styleFrom(
                backgroundColor: _missionPrimary,
                foregroundColor: AppColors.surface,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(_missionCardRadius),
                ),
              ),
              child: const Text('다시 시도'),
            ),
          ],
        ),
      ),
    );
  }
}

class _MissionEmptyState extends StatelessWidget {
  const _MissionEmptyState();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(_missionCardRadius),
        border: Border.all(color: _missionLine),
      ),
      child: const Text(
        '표시할 미션이 없습니다.',
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

class _MissionGentleStart extends StatelessWidget {
  const _MissionGentleStart({
    required this.featuredMission,
    required this.missions,
    required this.completedCount,
    required this.totalCount,
    required this.onMissionTap,
  });

  final MissionChallenge? featuredMission;
  final List<MissionChallenge> missions;
  final int completedCount;
  final int totalCount;
  final ValueChanged<String> onMissionTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (featuredMission != null) ...[
            KeyedSubtree(
              key: FeatureTourTargets.missionFeatured,
              child: _MissionFeaturedCard(
                mission: featuredMission!,
                onTap: () {
                  FeatureTourScope.maybeOf(context)?.completeTarget(
                    FeatureTourTargets.missionFeatured,
                  );
                  onMissionTap(featuredMission!.id);
                },
              ),
            ),
            const SizedBox(height: 24),
          ],
          _MissionSectionTitle(
            completedCount: completedCount,
            totalCount: totalCount,
          ),
          const SizedBox(height: 12),
          if (missions.isEmpty)
            const _MissionEmptyState()
          else
            for (final entry in missions.indexed) ...[
              _MissionCompactTile(
                index: entry.$1,
                mission: entry.$2,
                onTap: () => onMissionTap(entry.$2.id),
              ),
              const SizedBox(height: 10),
            ],
        ],
      ),
    );
  }
}

class _MissionFeaturedCard extends StatelessWidget {
  const _MissionFeaturedCard({
    required this.mission,
    required this.onTap,
  });

  final MissionChallenge mission;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(_missionCardRadius),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          width: double.infinity,
          constraints: const BoxConstraints(minHeight: 216),
          padding: const EdgeInsets.fromLTRB(18, 0, 18, 0),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(_missionCardRadius),
            border: Border.all(color: AppColors.line.withValues(alpha: 0.82)),
            boxShadow: AppShadows.softCard,
          ),
          child: Stack(
            children: [
              const Positioned(
                left: 0,
                top: 0,
                child: _SpecialLabel(),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 56),
                  const Text(
                    '점순이의 미션',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _SpeechBubble(
                    text: MissionJumsooniDialogue.pick(
                      MissionJumsooniDialogue.featured,
                      mission.id,
                    ),
                  ),
                ],
              ),
              Positioned(
                right: 0,
                bottom: 0,
                child: IgnorePointer(
                  child: Image.asset(
                    _featuredJumsooniAsset(mission),
                    width: 132,
                    height: 176,
                    fit: BoxFit.contain,
                    filterQuality: FilterQuality.high,
                  ),
                ),
              ),
              const Positioned(
                right: 0,
                top: 18,
                child: _FeaturedChevronButton(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FeaturedChevronButton extends StatelessWidget {
  const _FeaturedChevronButton();

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: AppColors.surface.withValues(alpha: 0.74),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: AppColors.surface.withValues(alpha: 0.9)),
          ),
          child: const Icon(
            Icons.chevron_right_rounded,
            color: _missionPrimary,
            size: 28,
          ),
        ),
      ),
    );
  }
}

String _featuredJumsooniAsset(MissionChallenge mission) {
  final seed = mission.id.codeUnits.fold<int>(0, (sum, code) => sum + code);
  return _featuredJumsooniAssets[seed % _featuredJumsooniAssets.length];
}

class _SpecialLabel extends StatelessWidget {
  const _SpecialLabel();

  @override
  Widget build(BuildContext context) {
    return ClipPath(
      clipper: const _BookmarkLabelClipper(),
      child: Container(
        width: 48,
        height: 44,
        alignment: const Alignment(0, -0.25),
        color: const Color(0xFFE86B4F),
        child: const Text(
          '특별',
          style: TextStyle(
            color: AppColors.surface,
            fontSize: 14,
            fontWeight: FontWeight.w900,
            letterSpacing: 0,
          ),
        ),
      ),
    );
  }
}

class _BookmarkLabelClipper extends CustomClipper<Path> {
  const _BookmarkLabelClipper();

  @override
  Path getClip(Size size) {
    return Path()
      ..lineTo(size.width, 0)
      ..lineTo(size.width, size.height)
      ..lineTo(size.width / 2, size.height - 8)
      ..lineTo(0, size.height)
      ..close();
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) {
    return false;
  }
}

class _MissionSectionTitle extends StatelessWidget {
  const _MissionSectionTitle({
    required this.completedCount,
    required this.totalCount,
  });

  final int completedCount;
  final int totalCount;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(
          child: Text(
            '오늘의 일일 미션',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.w900,
              letterSpacing: 0,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.primaryTint,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            '$completedCount / $totalCount',
            style: const TextStyle(
              color: _missionPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w900,
              letterSpacing: 0,
            ),
          ),
        ),
      ],
    );
  }
}

class _MissionCompactTile extends StatelessWidget {
  const _MissionCompactTile({
    required this.index,
    required this.mission,
    required this.onTap,
  });

  final int index;
  final MissionChallenge mission;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final enabled = mission.active && mission.status != MissionStatus.locked;

    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(_missionCardRadius),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: enabled ? onTap : null,
        child: Container(
          padding: const EdgeInsets.fromLTRB(13, 11, 13, 11),
          decoration: BoxDecoration(
            color: mission.status == MissionStatus.completed
                ? AppColors.primaryTint
                : AppColors.surface,
            borderRadius: BorderRadius.circular(_missionCardRadius),
            border: Border.all(color: AppColors.line),
          ),
          child: Row(
            children: [
              _MissionTypeCircle(type: mission.type, enabled: enabled),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _gentleMissionLine(mission),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: enabled
                            ? AppColors.textPrimary
                            : AppColors.textSecondary,
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      mission.spotName.isEmpty
                          ? mission.cityName
                          : '${mission.cityName} · ${mission.spotName}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0,
                      ),
                    ),
                    if (mission.target > 1) ...[
                      const SizedBox(height: 9),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(999),
                        child: LinearProgressIndicator(
                          value: mission.progressRatio,
                          minHeight: 6,
                          color: enabled ? _missionPrimary : _missionLine,
                          backgroundColor: const Color(0xFFF0EEE8),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        mission.progressLabel,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.primaryTint,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: const Icon(
                  Icons.chevron_right_rounded,
                  color: _missionPrimary,
                  size: 26,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MissionTypeCircle extends StatelessWidget {
  const _MissionTypeCircle({
    required this.type,
    required this.enabled,
  });

  final MissionType type;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: enabled ? AppColors.primaryTint : const Color(0xFFF0EEE8),
        shape: BoxShape.circle,
      ),
      child: Icon(
        type.icon,
        color: enabled ? _missionPrimary : AppColors.textSecondary,
        size: 25,
      ),
    );
  }
}

String _compactRewardLabel(MissionChallenge mission) {
  return switch (mission.rewardType) {
    MissionRewardType.potato => '감자 카드 후보',
    MissionRewardType.coupon => '제휴 혜택 준비중',
    MissionRewardType.item => '여행 기록 저장',
    MissionRewardType.coin => '참여 기록 저장',
  };
}

String _completionRewardMessage(MissionChallenge mission) {
  return switch (mission.rewardType) {
    MissionRewardType.potato => '감자 카드 수집 후보로 기록됐어요.',
    MissionRewardType.coupon => '제휴 혜택은 준비되는 대로 보상함에 이어집니다.',
    MissionRewardType.item || MissionRewardType.coin => '미션 참여 기록이 저장됐어요.',
  };
}

String _gentleMissionLine(MissionChallenge mission) {
  return switch (mission.type) {
    MissionType.visitAndStep => '천천히 걸어볼까요?',
    MissionType.photo || MissionType.photoOcr => '사진 한 장 남겨볼까요?',
    MissionType.qrScan => '작은 표식을 찾아봐요',
    MissionType.quiz => '강원도 이야기 풀어볼까요?',
    _ => '가볍게 들러볼까요?',
  };
}

class _MissionDetailView extends StatefulWidget {
  const _MissionDetailView({
    required this.mission,
    required this.onBack,
    required this.isCompleting,
    required this.onComplete,
    required this.onSubmitQuiz,
  });

  final MissionChallenge mission;
  final VoidCallback onBack;
  final bool isCompleting;
  final VoidCallback? onComplete;
  final Future<void> Function(String answer)? onSubmitQuiz;

  @override
  State<_MissionDetailView> createState() => _MissionDetailViewState();
}

class _MissionDetailViewState extends State<_MissionDetailView> {
  static const _verificationService = MissionVerificationService();

  late List<String> _quizOptions;
  String? _selectedAnswer;
  String? _quizFeedback;
  bool _quizCorrect = false;

  @override
  void initState() {
    super.initState();
    _quizOptions = _verificationService.quizOptions(widget.mission);
  }

  @override
  void didUpdateWidget(covariant _MissionDetailView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.mission.id != widget.mission.id) {
      _quizOptions = _verificationService.quizOptions(widget.mission);
      _selectedAnswer = null;
      _quizFeedback = null;
      _quizCorrect = false;
    }
  }

  Future<void> _submitQuiz() async {
    final answer = _selectedAnswer;
    if (answer == null || widget.onSubmitQuiz == null || widget.isCompleting) {
      return;
    }
    final result = _verificationService.verifyQuizAnswer(
      mission: widget.mission,
      selectedAnswer: answer,
    );
    if (!result.canComplete) {
      setState(() {
        _quizCorrect = false;
        _quizFeedback = result.message;
      });
      return;
    }
    setState(() {
      _quizCorrect = true;
      _quizFeedback = MissionJumsooniDialogue.pick(
        MissionJumsooniDialogue.quizSuccess,
        widget.mission.id,
      );
    });
    await widget.onSubmitQuiz!(answer);
  }

  @override
  Widget build(BuildContext context) {
    final mission = widget.mission;
    final isCompleted = mission.status == MissionStatus.completed;
    final canComplete = mission.active &&
        mission.status != MissionStatus.locked &&
        !isCompleted &&
        !widget.isCompleting;
    final isQuiz = mission.type == MissionType.quiz;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _MissionDetailTopBar(onBack: widget.onBack),
            Expanded(
              child: CustomScrollView(
                slivers: [
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate.fixed([
                        _MissionDetailIntro(mission: mission),
                        const SizedBox(height: 14),
                        _MissionHowToCard(mission: mission),
                        const SizedBox(height: 18),
                        _MissionRewardSection(mission: mission),
                        if (isQuiz) ...[
                          const SizedBox(height: 18),
                          _MissionInlineQuiz(
                            mission: mission,
                            options: _quizOptions,
                            selectedAnswer: _selectedAnswer,
                            feedback: _quizFeedback,
                            correct: _quizCorrect,
                            onChanged: (answer) => setState(() {
                              _selectedAnswer = answer;
                              _quizFeedback = null;
                              _quizCorrect = false;
                            }),
                          ),
                        ],
                        if (!isQuiz &&
                            mission.type == MissionType.photoOcr) ...[
                          const SizedBox(height: 18),
                          const _MissionNoticeCard(
                            title: '주의사항',
                            body: '다른 사람의 사진은 사용할 수 없어요. 장소가 잘 보이도록 찍어주세요.',
                          ),
                        ],
                      ]),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 18),
              child: FilledButton(
                onPressed: isQuiz
                    ? (_selectedAnswer == null || !canComplete
                        ? null
                        : _submitQuiz)
                    : (canComplete ? widget.onComplete : null),
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(56),
                  backgroundColor: _missionPrimary,
                  foregroundColor: AppColors.surface,
                  disabledBackgroundColor: _missionLine,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(_missionCardRadius),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0,
                  ),
                ),
                child: Text(
                  widget.isCompleting
                      ? '처리 중...'
                      : isCompleted
                          ? '완료된 미션'
                          : isQuiz
                              ? '정답 제출하기'
                              : _detailActionLabel(mission),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MissionDetailTopBar extends StatelessWidget {
  const _MissionDetailTopBar({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 6, 8, 4),
      child: Row(
        children: [
          IconButton(
            tooltip: '뒤로 가기',
            onPressed: onBack,
            icon: const Icon(Icons.arrow_back_rounded),
          ),
          const Expanded(
            child: Text(
              '미션 상세',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w900,
                letterSpacing: 0,
              ),
            ),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }
}

class _MissionDetailIntro extends StatelessWidget {
  const _MissionDetailIntro({required this.mission});

  final MissionChallenge mission;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 430,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: 0,
            top: 2,
            child: Image.asset(
              _detailJumsooniAsset(mission),
              width: 156,
              height: 210,
              fit: BoxFit.contain,
              filterQuality: FilterQuality.high,
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            top: 178,
            child: _MissionDetailSummaryCard(mission: mission),
          ),
          Positioned(
            right: 0,
            top: 28,
            child: _SpeechBubble(text: _detailSpeech(mission)),
          ),
        ],
      ),
    );
  }
}

class _SpeechBubble extends StatelessWidget {
  const _SpeechBubble({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 196),
              padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 14),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: AppColors.line),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Text(
                text,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 14,
                  height: 1.45,
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

class _MissionDetailSummaryCard extends StatelessWidget {
  const _MissionDetailSummaryCard({required this.mission});

  final MissionChallenge mission;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(_missionCardRadius),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _MissionKindBadge(label: '일일 미션'),
          const SizedBox(height: 12),
          Text(
            _detailTitle(mission),
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 24,
              fontWeight: FontWeight.w900,
              letterSpacing: 0,
            ),
          ),
          const SizedBox(height: 14),
          _MissionMetaRow(
            icon: Icons.location_on_outlined,
            text: _spotLine(mission),
          ),
          const _MissionMetaDivider(),
          _MissionMetaRow(icon: mission.type.icon, text: mission.type.label),
          const _MissionMetaDivider(),
          const _MissionMetaRow(
              icon: Icons.schedule_rounded, text: '오늘 23:59까지'),
        ],
      ),
    );
  }
}

class _MissionHowToCard extends StatelessWidget {
  const _MissionHowToCard({required this.mission});

  final MissionChallenge mission;

  @override
  Widget build(BuildContext context) {
    final steps = _detailSteps(mission);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF9F2),
        borderRadius: BorderRadius.circular(_missionCardRadius),
        border: Border.all(color: const Color(0xFFD8F0DF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '미션 진행 방법',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w900,
              letterSpacing: 0,
            ),
          ),
          const SizedBox(height: 12),
          for (final entry in steps.indexed) ...[
            _MissionStepLine(index: entry.$1 + 1, text: entry.$2),
            if (entry.$1 != steps.length - 1) const SizedBox(height: 10),
          ],
        ],
      ),
    );
  }
}

class _MissionRewardSection extends StatelessWidget {
  const _MissionRewardSection({required this.mission});

  final MissionChallenge mission;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '보상',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w900,
            letterSpacing: 0,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            const Expanded(
              child: _RewardSmallCard(
                icon: Icons.eco_rounded,
                label: '수집 후보',
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _RewardSmallCard(
                icon: _rewardIconData(mission.rewardType),
                label: _compactRewardLabel(mission),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _MissionInlineQuiz extends StatelessWidget {
  const _MissionInlineQuiz({
    required this.mission,
    required this.options,
    required this.selectedAnswer,
    required this.feedback,
    required this.correct,
    required this.onChanged,
  });

  final MissionChallenge mission;
  final List<String> options;
  final String? selectedAnswer;
  final String? feedback;
  final bool correct;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(_missionCardRadius),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '문제 미리보기',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
              fontWeight: FontWeight.w900,
              letterSpacing: 0,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            '강원도에서 가장 많이 재배되는 감자 품종은 무엇일까요?',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 16,
              height: 1.35,
              fontWeight: FontWeight.w900,
              letterSpacing: 0,
            ),
          ),
          const SizedBox(height: 14),
          for (final entry in options.indexed) ...[
            _MissionQuizOption(
              label: entry.$2,
              prefix: String.fromCharCode(65 + entry.$1),
              selected: selectedAnswer == entry.$2,
              onTap: () => onChanged(entry.$2),
            ),
            const SizedBox(height: 8),
          ],
          if (feedback != null) ...[
            const SizedBox(height: 6),
            Text(
              feedback!,
              style: TextStyle(
                color: correct ? _missionPrimary : AppColors.error,
                fontSize: 13,
                fontWeight: FontWeight.w900,
                letterSpacing: 0,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _MissionKindBadge extends StatelessWidget {
  const _MissionKindBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
      decoration: BoxDecoration(
        color: AppColors.primaryTint,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: AppColors.primaryDark,
          fontSize: 12,
          fontWeight: FontWeight.w900,
          letterSpacing: 0,
        ),
      ),
    );
  }
}

class _MissionMetaRow extends StatelessWidget {
  const _MissionMetaRow({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          Icon(icon, color: AppColors.textSecondary, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w800,
                letterSpacing: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MissionMetaDivider extends StatelessWidget {
  const _MissionMetaDivider();

  @override
  Widget build(BuildContext context) {
    return const Divider(height: 1, color: AppColors.line);
  }
}

class _MissionStepLine extends StatelessWidget {
  const _MissionStepLine({required this.index, required this.text});

  final int index;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 20,
          height: 20,
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            color: Color(0xFFCDEDD8),
            shape: BoxShape.circle,
          ),
          child: Text(
            '$index',
            style: const TextStyle(
              color: AppColors.primaryDark,
              fontSize: 11,
              fontWeight: FontWeight.w900,
              letterSpacing: 0,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 14,
              height: 1.35,
              fontWeight: FontWeight.w800,
              letterSpacing: 0,
            ),
          ),
        ),
      ],
    );
  }
}

class _RewardSmallCard extends StatelessWidget {
  const _RewardSmallCard({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(_missionCardRadius),
        border: Border.all(color: AppColors.line),
      ),
      child: Row(
        children: [
          Icon(icon, color: _missionGold, size: 24),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.textPrimary,
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

class _MissionNoticeCard extends StatelessWidget {
  const _MissionNoticeCard({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8EA),
        borderRadius: BorderRadius.circular(_missionCardRadius),
        border: Border.all(color: const Color(0xFFF1DBA9)),
      ),
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
          const SizedBox(height: 8),
          Text(
            body,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
              height: 1.45,
              fontWeight: FontWeight.w700,
              letterSpacing: 0,
            ),
          ),
        ],
      ),
    );
  }
}

class _MissionQuizOption extends StatelessWidget {
  const _MissionQuizOption({
    required this.label,
    required this.prefix,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final String prefix;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.primaryTint : AppColors.surface,
      borderRadius: BorderRadius.circular(_missionCardRadius),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(_missionCardRadius),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(_missionCardRadius),
            border: Border.all(
              color: selected ? _missionPrimary : AppColors.line,
              width: selected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 26,
                height: 26,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                      color: selected ? _missionPrimary : AppColors.line),
                ),
                child: Text(
                  prefix,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
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

String _detailJumsooniAsset(MissionChallenge mission) {
  return switch (mission.type) {
    MissionType.photo ||
    MissionType.photoOcr =>
      'assets/characters/jumsooni/jumsooni_wave_hand.png',
    MissionType.quiz => 'assets/characters/jumsooni/jumsooni_thinking.png',
    MissionType.visitAndStep => 'assets/characters/jumsooni/jumsooni_point.png',
    _ => 'assets/characters/jumsooni/jumsooni_thumb.png',
  };
}

String _detailSpeech(MissionChallenge mission) {
  return MissionJumsooniDialogue.detail(mission);
}

String _detailTitle(MissionChallenge mission) {
  return switch (mission.type) {
    MissionType.photo || MissionType.photoOcr => '사진으로 추억 남기기',
    MissionType.quiz => '강원도 감자 퀴즈',
    MissionType.visitAndStep ||
    MissionType.visit ||
    MissionType.stamp =>
      '${mission.spotName} 방문하기',
    MissionType.qrScan => '숨은 QR 찾기',
    _ => mission.title,
  };
}

String _spotLine(MissionChallenge mission) {
  return mission.spotName.isEmpty
      ? mission.cityName
      : '${mission.cityName} · ${mission.spotName}';
}

List<String> _detailSteps(MissionChallenge mission) {
  return switch (mission.type) {
    MissionType.photo || MissionType.photoOcr => [
        '${mission.spotName}에 방문해요.',
        '풍경이나 감자 사진을 찍어봐요.',
        '사진을 제출하면 완료돼요.'
      ],
    MissionType.quiz => [
        '문제를 천천히 읽어봐요.',
        '정답이라고 생각하는 답을 선택해요.',
        '정답 제출 시 미션 완료!'
      ],
    MissionType.visitAndStep => [
        '근처 여행길을 천천히 걸어요.',
        '목표 걸음 수를 채워요.',
        '걸음 인증 버튼을 눌러요.'
      ],
    MissionType.qrScan => [
        '장소에 숨겨진 QR을 찾아요.',
        'QR 코드를 스캔해요.',
        '스캔에 성공하면 완료돼요.'
      ],
    _ => ['장소 근처로 이동해요.', '인증 버튼을 눌러요.', '인증에 성공하면 완료돼요.'],
  };
}

String _detailActionLabel(MissionChallenge mission) {
  return switch (mission.type) {
    MissionType.photo => '사진 찍기',
    MissionType.photoOcr => '사진 찍기',
    MissionType.qrScan => 'QR 스캔하기',
    MissionType.visitAndStep => '걸음 인증하기',
    _ => '위치 확인하기',
  };
}

class _MissionPhotoEvidence {
  const _MissionPhotoEvidence({
    required this.uploadKey,
    required this.latitude,
    required this.longitude,
  });

  final String uploadKey;
  final double latitude;
  final double longitude;
}

class _MissionPhotoSheet extends StatefulWidget {
  const _MissionPhotoSheet({
    required this.mission,
    required this.inputService,
    required this.uploadRepository,
    required this.locationService,
  });

  final MissionChallenge mission;
  final MissionNativeInputService inputService;
  final MissionUploadRepository uploadRepository;
  final LocationService locationService;

  @override
  State<_MissionPhotoSheet> createState() => _MissionPhotoSheetState();
}

class _MissionPhotoSheetState extends State<_MissionPhotoSheet> {
  MissionPhotoInput? _selectedInput;
  String? _errorMessage;
  bool _isPicking = false;
  bool _isUploading = false;

  Future<void> _pick(MissionPhotoSource source) async {
    setState(() {
      _isPicking = true;
      _errorMessage = null;
    });
    try {
      final input = await widget.inputService.pickPhoto(
        missionId: widget.mission.id,
        source: source,
      );
      if (!mounted) {
        return;
      }
      if (input == null) {
        setState(() {
          _isPicking = false;
          _errorMessage = '이미지 선택이 취소되었습니다.';
        });
        return;
      }
      setState(() {
        _selectedInput = input;
        _isPicking = false;
      });
    } on MissionInputException catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isPicking = false;
        _errorMessage = error.message;
      });
    }
  }

  Future<void> _uploadSelectedPhoto() async {
    final input = _selectedInput;
    if (input == null || _isUploading) {
      return;
    }
    setState(() {
      _isUploading = true;
      _errorMessage = null;
    });
    try {
      final position = await widget.locationService.getCurrentPosition();
      final result = await widget.uploadRepository.uploadPhoto(
        missionId: widget.mission.id,
        file: input.file,
      );
      if (!mounted) {
        return;
      }
      Navigator.of(context).pop(_MissionPhotoEvidence(
        uploadKey: result.uploadKey,
        latitude: position.latitude,
        longitude: position.longitude,
      ));
    } on LocationFailure catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isUploading = false;
        _errorMessage = error.message;
      });
    } on ApiException catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isUploading = false;
        _errorMessage = error.message;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isUploading = false;
        _errorMessage = '인증샷 업로드에 실패했습니다. 다시 시도해주세요.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return _MissionActionSheet(
      title: '인증샷 업로드',
      subtitle: widget.mission.title,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '현장 위치와 이미지가 모두 확인되어야 미션을 완료할 수 있어요.',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
              fontWeight: FontWeight.w800,
              letterSpacing: 0,
            ),
          ),
          const SizedBox(height: 16),
          _MissionSheetButton(
            icon: Icons.photo_camera_rounded,
            label: '카메라로 촬영하기',
            onTap: _isPicking || _isUploading
                ? null
                : () => _pick(MissionPhotoSource.camera),
          ),
          const SizedBox(height: 8),
          _MissionSheetButton(
            icon: Icons.photo_library_rounded,
            label: '갤러리에서 선택하기',
            onTap: _isPicking || _isUploading
                ? null
                : () => _pick(MissionPhotoSource.gallery),
          ),
          if (_isPicking) ...[
            const SizedBox(height: 14),
            const _MissionInputProgress(label: '이미지를 불러오는 중이에요.'),
          ],
          if (_errorMessage != null) ...[
            const SizedBox(height: 14),
            _MissionInputError(message: _errorMessage!),
          ],
          if (_selectedInput != null) ...[
            const SizedBox(height: 14),
            _MissionUploadPreview(label: _selectedInput!.previewLabel),
          ],
          if (_isUploading) ...[
            const SizedBox(height: 14),
            const _MissionInputProgress(
              label: '현재 위치를 확인하고 인증샷을 업로드하는 중이에요.',
            ),
          ],
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _selectedInput == null || _isPicking || _isUploading
                ? null
                : _uploadSelectedPhoto,
            icon: const Icon(Icons.cloud_done_rounded),
            label: const Text('인증 완료하기'),
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
              backgroundColor: _missionPrimary,
              foregroundColor: AppColors.surface,
              disabledBackgroundColor: _missionLine,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(_missionCardRadius),
              ),
              textStyle: const TextStyle(
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

class _MissionActionSheet extends StatelessWidget {
  const _MissionActionSheet({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.86,
        ),
        child: Container(
          margin: const EdgeInsets.all(12),
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(_missionCardRadius),
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            subtitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: '닫기',
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                child,
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MissionUploadPreview extends StatelessWidget {
  const _MissionUploadPreview({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF8EF),
        borderRadius: BorderRadius.circular(_missionCardRadius),
        border: Border.all(color: const Color(0xFFD5EFDE)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(_missionCardRadius),
            ),
            child: const Icon(
              Icons.image_rounded,
              color: _missionPrimary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0,
                  ),
                ),
                const SizedBox(height: 2),
                const Text(
                  '업로드 준비 완료',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
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

class _MissionInputProgress extends StatelessWidget {
  const _MissionInputProgress({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8EA),
        borderRadius: BorderRadius.circular(_missionCardRadius),
        border: Border.all(color: const Color(0xFFF1DBA9)),
      ),
      child: Row(
        children: [
          const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 3),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 14,
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

class _MissionInputError extends StatelessWidget {
  const _MissionInputError({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF0F0),
        borderRadius: BorderRadius.circular(_missionCardRadius),
        border: Border.all(color: const Color(0xFFF4C7C7)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_rounded, color: Color(0xFFD9534F)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w800,
                letterSpacing: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MissionSheetButton extends StatelessWidget {
  const _MissionSheetButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: onTap == null ? const Color(0xFFF2F0EC) : const Color(0xFFEAF8EF),
      borderRadius: BorderRadius.circular(_missionCardRadius),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(_missionCardRadius),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          child: Row(
            children: [
              Icon(
                icon,
                color:
                    onTap == null ? AppColors.textSecondary : _missionPrimary,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
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
    );
  }
}

class _MissionRewardDialog extends StatelessWidget {
  const _MissionRewardDialog({required this.mission});

  final MissionChallenge mission;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 28),
      child: Container(
        padding: const EdgeInsets.fromLTRB(22, 24, 22, 20),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(_missionCardRadius),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 78,
              height: 78,
              decoration: const BoxDecoration(
                color: Color(0xFFFFE9A5),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _rewardIconData(mission.rewardType),
                color: _missionGold,
                size: 42,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              MissionJumsooniDialogue.pick(
                MissionJumsooniDialogue.complete,
                mission.id,
              ),
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 22,
                height: 1.32,
                fontWeight: FontWeight.w900,
                letterSpacing: 0,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _completionRewardMessage(mission),
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
                backgroundColor: _missionPrimary,
                foregroundColor: AppColors.surface,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(_missionCardRadius),
                ),
              ),
              child: const Text(
                '확인',
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

IconData _rewardIconData(MissionRewardType type) {
  return switch (type) {
    MissionRewardType.potato => Icons.eco_rounded,
    MissionRewardType.coupon => Icons.local_activity_rounded,
    MissionRewardType.item => Icons.auto_awesome_rounded,
    MissionRewardType.coin => Icons.paid_rounded,
  };
}
