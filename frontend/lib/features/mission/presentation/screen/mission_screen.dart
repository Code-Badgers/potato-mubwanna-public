import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../shared/widgets/auth_required_view.dart';
import '../../../auth/application/auth_controller.dart';
import '../../application/mission_controller.dart';
import '../../data/mission_native_input_service.dart';
import '../../data/mission_repository.dart';
import '../../data/mission_upload_repository.dart';
import '../../domain/mission_challenge.dart';
import '../../domain/mission_verification.dart';

const _missionPrimary = Color(0xFF56C787);
const _missionDark = Color(0xFF6A4A2A);
const _missionGold = Color(0xFFF6C23E);
const _missionCream = Color(0xFFFFF8EA);
const _missionLine = Color(0xFFE8E2D8);

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

  MissionGroup? _selectedGroup;
  String? _selectedMissionId;
  bool _isCompleting = false;

  @override
  void initState() {
    super.initState();
    _selectedMissionId = widget.visitEntryMissionId;
  }

  List<MissionChallenge> _filteredMissions(List<MissionChallenge> missions) {
    final selectedGroup = _selectedGroup;
    final filtered = selectedGroup == null
        ? missions
        : missions.where((mission) => mission.group == selectedGroup).toList();
    return [...filtered]..sort(_compareMissionPriority);
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
      MissionType.quiz => _showQuizChallenge(mission),
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

  Future<MissionVerificationPayload?> _showQuizChallenge(
    MissionChallenge mission,
  ) async {
    final selectedAnswer = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _MissionQuizSheet(
        mission: mission,
        options: _verificationService.quizOptions(mission),
      ),
    );
    if (selectedAnswer == null) {
      return null;
    }
    return MissionVerificationPayload(
      type: mission.type,
      answer: selectedAnswer,
    );
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
    final uploadKey = await _showPhotoInputSheet(mission);
    if (uploadKey == null) {
      return null;
    }
    final result = _verificationService.verifyPhotoUpload(
      mission: mission,
      uploaded: uploadKey.isNotEmpty,
    );
    if (!result.canComplete) {
      _showSnackBar(result.message);
      return null;
    }
    return MissionVerificationPayload(
      type: mission.type,
      uploadKey: uploadKey,
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

  Future<String?> _showPhotoInputSheet(
    MissionChallenge mission,
  ) {
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _MissionPhotoSheet(
        mission: mission,
        inputService: _nativeInputService,
        uploadRepository: ref.read(missionUploadRepositoryProvider),
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
        child: AuthRequiredView(
          description: '점순이 미션에 도전하려면 로그인해주세요.',
          onLogin: () => context.go('/login'),
        ),
      );
    }

    final missionsState = ref.watch(missionsProvider);
    final selectedMissionId = _selectedMissionId;
    final selectedMission = selectedMissionId == null
        ? null
        : ref.watch(missionByIdProvider(selectedMissionId));

    if (selectedMissionId != null && selectedMission != null) {
      return _MissionDetailView(
        mission: selectedMission,
        onBack: _closeMissionDetail,
        onComplete: _isCompleting ? null : () => _startMission(selectedMission),
      );
    }

    if (selectedMissionId != null && missionsState.isLoading) {
      return const _MissionScaffold(
        child: _MissionLoadingState(),
      );
    }

    if (selectedMissionId != null && missionsState.hasError) {
      final error = missionsState.error;
      return _MissionScaffold(
        child: _MissionErrorState(
          message: error is ApiException ? error.message : '미션 정보를 불러오지 못했습니다.',
          onRetry: () => ref.read(missionsProvider.notifier).load(),
        ),
      );
    }

    if (selectedMissionId != null && selectedMission == null) {
      return _MissionScaffold(
        child: _MissionErrorState(
          message: '미션 정보를 찾지 못했습니다.',
          onRetry: _closeMissionDetail,
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

  Widget _buildMissionList(List<MissionChallenge> missions) {
    final filteredMissions = _filteredMissions(missions);
    final completedCount = missions
        .where((mission) => mission.status == MissionStatus.completed)
        .length;
    final actionableCount = missions
        .where((mission) =>
            mission.active &&
            mission.status != MissionStatus.locked &&
            mission.status != MissionStatus.completed)
        .length;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: _MissionHeader(
                actionableCount: actionableCount,
                completedCount: completedCount,
                totalCount: missions.length,
              ),
            ),
            if (widget.visitEntrySpotName != null)
              SliverToBoxAdapter(
                child: _VisitMissionEntryBanner(
                  spotName: widget.visitEntrySpotName!,
                ),
              ),
            SliverToBoxAdapter(
              child: _MissionFilterBar(
                selectedGroup: _selectedGroup,
                onChanged: (group) => setState(() => _selectedGroup = group),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 28),
              sliver: filteredMissions.isEmpty
                  ? const SliverToBoxAdapter(child: _MissionEmptyState())
                  : SliverList.separated(
                      itemCount: filteredMissions.length,
                      itemBuilder: (_, index) {
                        final mission = filteredMissions[index];
                        return _MissionCard(
                          mission: mission,
                          onTap: () => _showMissionDetail(mission.id),
                        );
                      },
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                    ),
            ),
          ],
        ),
      ),
    );
  }
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
          borderRadius: BorderRadius.circular(8),
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
    return const Center(
      child: CircularProgressIndicator(color: _missionPrimary),
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
                  borderRadius: BorderRadius.circular(8),
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
        borderRadius: BorderRadius.circular(8),
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

class _MissionHeader extends StatelessWidget {
  const _MissionHeader({
    required this.actionableCount,
    required this.completedCount,
    required this.totalCount,
  });

  final int actionableCount;
  final int completedCount;
  final int totalCount;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppColors.line),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: AppColors.primaryTint,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.task_alt_rounded,
                    color: _missionPrimary,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '오늘의 미션',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 21,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$actionableCount개 도전 가능 · 완료 $completedCount/$totalCount',
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
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primaryTint,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    '$completedCount/$totalCount',
                    style: const TextStyle(
                      color: AppColors.primaryDark,
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0,
                    ),
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

class _MissionFilterBar extends StatelessWidget {
  const _MissionFilterBar({
    required this.selectedGroup,
    required this.onChanged,
  });

  final MissionGroup? selectedGroup;
  final ValueChanged<MissionGroup?> onChanged;

  @override
  Widget build(BuildContext context) {
    const visibleGroups = [
      MissionGroup.daily,
      MissionGroup.weekly,
      MissionGroup.event,
    ];
    final filters = <_MissionFilter>[
      const _MissionFilter(label: '전체'),
      ...visibleGroups.map((group) => _MissionFilter(
            label: group.label,
            group: group,
          )),
    ];

    return SizedBox(
      height: 48,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        scrollDirection: Axis.horizontal,
        itemCount: filters.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final filter = filters[index];
          final selected = filter.group == selectedGroup;
          return _MissionFilterChip(
            label: filter.label,
            selected: selected,
            onTap: () => onChanged(filter.group),
          );
        },
      ),
    );
  }
}

class _MissionFilterChip extends StatelessWidget {
  const _MissionFilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? _missionDark : AppColors.surface,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          constraints: const BoxConstraints(minWidth: 72),
          padding: const EdgeInsets.symmetric(horizontal: 18),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: selected ? _missionDark : _missionLine,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: selected ? AppColors.surface : AppColors.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w900,
              letterSpacing: 0,
            ),
          ),
        ),
      ),
    );
  }
}

class _MissionCard extends StatelessWidget {
  const _MissionCard({
    required this.mission,
    required this.onTap,
  });

  final MissionChallenge mission;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final enabled = mission.active && mission.status != MissionStatus.locked;

    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(8),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: enabled ? onTap : null,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _MissionTypeIcon(type: mission.type, enabled: enabled),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          mission.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: enabled
                                ? AppColors.textPrimary
                                : AppColors.textSecondary,
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${mission.cityName} · ${mission.spotName}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
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
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  if (mission.isNew) const _NewBadge(),
                  _MissionStatusBadge(status: mission.status),
                  _RewardPill(mission: mission),
                ],
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  value: mission.progressRatio,
                  minHeight: 7,
                  color: enabled ? _missionPrimary : _missionLine,
                  backgroundColor: const Color(0xFFF0EEE8),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      mission.conditionLabel,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    mission.progressLabel,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0,
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

class _MissionDetailView extends StatelessWidget {
  const _MissionDetailView({
    required this.mission,
    required this.onBack,
    required this.onComplete,
  });

  final MissionChallenge mission;
  final VoidCallback onBack;
  final VoidCallback? onComplete;

  @override
  Widget build(BuildContext context) {
    final isCompleted = mission.status == MissionStatus.completed;
    final canComplete = mission.active &&
        mission.status != MissionStatus.locked &&
        !isCompleted;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: _MissionDetailHero(
                mission: mission,
                onBack: onBack,
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
              sliver: SliverList(
                delegate: SliverChildListDelegate.fixed([
                  _MissionDialogue(dialogue: mission.dialogue),
                  const SizedBox(height: 12),
                  _MissionInfoPanel(mission: mission),
                  const SizedBox(height: 12),
                  _MissionConditionPanel(mission: mission),
                  const SizedBox(height: 18),
                  FilledButton.icon(
                    onPressed: canComplete ? onComplete : null,
                    icon: Icon(_actionIcon(mission.type)),
                    label: Text(_actionLabel(mission)),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(58),
                      backgroundColor: _missionDark,
                      foregroundColor: AppColors.surface,
                      disabledBackgroundColor: _missionLine,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      textStyle: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0,
                      ),
                    ),
                  ),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static IconData _actionIcon(MissionType type) {
    return switch (type) {
      MissionType.photo => Icons.camera_alt_rounded,
      MissionType.photoOcr => Icons.document_scanner_rounded,
      MissionType.qrScan => Icons.qr_code_scanner_rounded,
      MissionType.quiz => Icons.quiz_rounded,
      MissionType.visitAndStep => Icons.directions_walk_rounded,
      _ => Icons.location_on_rounded,
    };
  }

  static String _actionLabel(MissionChallenge mission) {
    if (mission.status == MissionStatus.completed) {
      return '완료된 미션';
    }
    return switch (mission.type) {
      MissionType.photo => '사진 인증하기',
      MissionType.photoOcr => '촬영 인증하기',
      MissionType.qrScan => 'QR 스캔하기',
      MissionType.quiz => '퀴즈 풀기',
      MissionType.visitAndStep => '걸음 인증하기',
      _ => '미션 인증하기',
    };
  }
}

class _MissionDetailHero extends StatelessWidget {
  const _MissionDetailHero({
    required this.mission,
    required this.onBack,
  });

  final MissionChallenge mission;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 8, 20, 20),
      decoration: const BoxDecoration(
        color: _missionCream,
        border: Border(bottom: BorderSide(color: _missionLine)),
      ),
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
              const Expanded(
                child: Text(
                  '점순이의 미션',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0,
                  ),
                ),
              ),
              const SizedBox(width: 48),
            ],
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Row(
              children: [
                Container(
                  width: 66,
                  height: 66,
                  decoration: const BoxDecoration(
                    color: Color(0xFFE6F7EC),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    mission.type.icon,
                    color: _missionPrimary,
                    size: 34,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        mission.spotName,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        mission.title,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0,
                        ),
                      ),
                    ],
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

class _MissionDialogue extends StatelessWidget {
  const _MissionDialogue({required this.dialogue});

  final String dialogue;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _missionLine),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.chat_bubble_rounded, color: _missionPrimary),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              dialogue,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 15,
                fontWeight: FontWeight.w800,
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

class _MissionInfoPanel extends StatelessWidget {
  const _MissionInfoPanel({required this.mission});

  final MissionChallenge mission;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _missionLine),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '보상',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w900,
              letterSpacing: 0,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _RewardIcon(type: mission.rewardType),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  '${mission.rewardType.label} · ${mission.rewardLabel}',
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
        ],
      ),
    );
  }
}

class _MissionConditionPanel extends StatelessWidget {
  const _MissionConditionPanel({required this.mission});

  final MissionChallenge mission;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _missionLine),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '미션 조건',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w900,
              letterSpacing: 0,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            mission.conditionLabel,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
              fontWeight: FontWeight.w800,
              letterSpacing: 0,
            ),
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: mission.progressRatio,
              minHeight: 8,
              color: _missionPrimary,
              backgroundColor: const Color(0xFFF0EEE8),
            ),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              mission.progressLabel,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 12,
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

class _MissionQuizSheet extends StatefulWidget {
  const _MissionQuizSheet({
    required this.mission,
    required this.options,
  });

  final MissionChallenge mission;
  final List<String> options;

  @override
  State<_MissionQuizSheet> createState() => _MissionQuizSheetState();
}

class _MissionQuizSheetState extends State<_MissionQuizSheet> {
  String? _selectedAnswer;

  @override
  Widget build(BuildContext context) {
    return _MissionActionSheet(
      title: '퀴즈 풀기',
      subtitle: widget.mission.title,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '정선 향토 음식 미션에서 점순이가 찾는 감자는 무엇일까요?',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 17,
              fontWeight: FontWeight.w900,
              height: 1.35,
              letterSpacing: 0,
            ),
          ),
          const SizedBox(height: 16),
          for (final answer in widget.options) ...[
            _MissionChoiceButton(
              label: answer,
              selected: _selectedAnswer == answer,
              onTap: () => setState(() => _selectedAnswer = answer),
            ),
            const SizedBox(height: 8),
          ],
          const SizedBox(height: 8),
          FilledButton(
            onPressed: _selectedAnswer == null
                ? null
                : () => Navigator.of(context).pop(_selectedAnswer),
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
              backgroundColor: _missionPrimary,
              foregroundColor: AppColors.surface,
              disabledBackgroundColor: _missionLine,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              textStyle: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                letterSpacing: 0,
              ),
            ),
            child: const Text('정답 제출하기'),
          ),
        ],
      ),
    );
  }
}

class _MissionPhotoSheet extends StatefulWidget {
  const _MissionPhotoSheet({
    required this.mission,
    required this.inputService,
    required this.uploadRepository,
  });

  final MissionChallenge mission;
  final MissionNativeInputService inputService;
  final MissionUploadRepository uploadRepository;

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
      final result = await widget.uploadRepository.uploadPhoto(
        missionId: widget.mission.id,
        file: input.file,
      );
      if (!mounted) {
        return;
      }
      Navigator.of(context).pop(result.uploadKey);
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
            '이미지가 업로드되어야 미션을 완료할 수 있어요.',
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
            const _MissionInputProgress(label: '인증샷을 업로드하는 중이에요.'),
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
                borderRadius: BorderRadius.circular(8),
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
            borderRadius: BorderRadius.circular(8),
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

class _MissionChoiceButton extends StatelessWidget {
  const _MissionChoiceButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? const Color(0xFFE1F7EA) : AppColors.surface,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: selected ? _missionPrimary : _missionLine,
              width: selected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Icon(
                selected
                    ? Icons.radio_button_checked_rounded
                    : Icons.radio_button_unchecked_rounded,
                color: selected ? _missionPrimary : AppColors.textSecondary,
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
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFD5EFDE)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(8),
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
        borderRadius: BorderRadius.circular(8),
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
        borderRadius: BorderRadius.circular(8),
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
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
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
          borderRadius: BorderRadius.circular(8),
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
            const Text(
              '미션 완료!',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 24,
                fontWeight: FontWeight.w900,
                letterSpacing: 0,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${mission.rewardLabel}을 획득했어요.',
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
                  borderRadius: BorderRadius.circular(8),
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

class _MissionTypeIcon extends StatelessWidget {
  const _MissionTypeIcon({
    required this.type,
    required this.enabled,
  });

  final MissionType type;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: enabled ? const Color(0xFFE6F7EC) : const Color(0xFFF0EEE8),
        shape: BoxShape.circle,
      ),
      child: Icon(
        type.icon,
        color: enabled ? _missionPrimary : AppColors.textSecondary,
        size: 22,
      ),
    );
  }
}

class _RewardPill extends StatelessWidget {
  const _RewardPill({required this.mission});

  final MissionChallenge mission;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 96),
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
      decoration: BoxDecoration(
        color: _missionCream,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFFFE3A3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _rewardIconData(mission.rewardType),
            size: 14,
            color: _missionGold,
          ),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              mission.rewardType.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: _missionDark,
                fontSize: 11,
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

class _MissionStatusBadge extends StatelessWidget {
  const _MissionStatusBadge({required this.status});

  final MissionStatus status;

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      MissionStatus.completed => _missionPrimary,
      MissionStatus.inProgress => _missionGold,
      MissionStatus.ready => _missionDark,
      MissionStatus.locked => AppColors.textSecondary,
    };
    final backgroundColor = switch (status) {
      MissionStatus.completed => const Color(0xFFE6F7EC),
      MissionStatus.inProgress => const Color(0xFFFFF2C7),
      MissionStatus.ready => const Color(0xFFFFF8EA),
      MissionStatus.locked => const Color(0xFFF0EEE8),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.32)),
      ),
      child: Text(
        status.label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w900,
          letterSpacing: 0,
        ),
      ),
    );
  }
}

class _RewardIcon extends StatelessWidget {
  const _RewardIcon({required this.type});

  final MissionRewardType type;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 46,
      height: 46,
      decoration: const BoxDecoration(
        color: Color(0xFFFFF2C7),
        shape: BoxShape.circle,
      ),
      child: Icon(
        _rewardIconData(type),
        color: _missionGold,
      ),
    );
  }
}

class _NewBadge extends StatelessWidget {
  const _NewBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFFFFE1A3),
        borderRadius: BorderRadius.circular(999),
      ),
      child: const Text(
        'NEW',
        style: TextStyle(
          color: _missionDark,
          fontSize: 10,
          fontWeight: FontWeight.w900,
          letterSpacing: 0,
        ),
      ),
    );
  }
}

class _MissionFilter {
  const _MissionFilter({
    required this.label,
    this.group,
  });

  final String label;
  final MissionGroup? group;
}

IconData _rewardIconData(MissionRewardType type) {
  return switch (type) {
    MissionRewardType.potato => Icons.eco_rounded,
    MissionRewardType.coupon => Icons.local_activity_rounded,
    MissionRewardType.item => Icons.auto_awesome_rounded,
    MissionRewardType.coin => Icons.paid_rounded,
  };
}
