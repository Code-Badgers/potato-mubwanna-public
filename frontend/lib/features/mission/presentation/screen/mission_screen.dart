import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../application/mission_controller.dart';
import '../../domain/mission_challenge.dart';

const _missionPrimary = Color(0xFF56C787);
const _missionDark = Color(0xFF6A4A2A);
const _missionGold = Color(0xFFF6C23E);
const _missionCream = Color(0xFFFFF8EA);
const _missionLine = Color(0xFFE8E2D8);

class MissionScreen extends ConsumerStatefulWidget {
  const MissionScreen({super.key});

  @override
  ConsumerState<MissionScreen> createState() => _MissionScreenState();
}

class _MissionScreenState extends ConsumerState<MissionScreen> {
  MissionGroup? _selectedGroup;
  String? _selectedMissionId;

  List<MissionChallenge> _filteredMissions(List<MissionChallenge> missions) {
    final selectedGroup = _selectedGroup;
    if (selectedGroup == null) {
      return missions;
    }
    return missions.where((mission) => mission.group == selectedGroup).toList();
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

  @override
  Widget build(BuildContext context) {
    final missions = ref.watch(missionsProvider);
    final selectedMissionId = _selectedMissionId;
    final selectedMission = selectedMissionId == null
        ? null
        : ref.watch(missionByIdProvider(selectedMissionId));

    if (selectedMissionId != null && selectedMission != null) {
      return _MissionDetailView(
        mission: selectedMission,
        onBack: _closeMissionDetail,
        onComplete: () => _showRewardDialog(selectedMission),
      );
    }

    final filteredMissions = _filteredMissions(missions);
    final completedCount = missions
        .where((mission) => mission.status == MissionStatus.completed)
        .length;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: _MissionHeader(
                completedCount: completedCount,
                totalCount: missions.length,
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
              sliver: SliverList.separated(
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

class _MissionHeader extends StatelessWidget {
  const _MissionHeader({
    required this.completedCount,
    required this.totalCount,
  });

  final int completedCount;
  final int totalCount;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '미션',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 30,
              fontWeight: FontWeight.w900,
              letterSpacing: 0,
            ),
          ),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFEAF8EF),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFD5EFDE)),
            ),
            child: Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: const BoxDecoration(
                    color: AppColors.surface,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.flag_rounded,
                    color: _missionPrimary,
                    size: 26,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '점순이와 함께 도전해요',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '완료 $completedCount / $totalCount',
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
                const Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.textSecondary,
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
  final VoidCallback onComplete;

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
