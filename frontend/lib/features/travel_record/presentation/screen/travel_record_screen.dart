import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_colors.dart';

const _recordPrimary = Color(0xFF509B64);
const _recordLine = Color(0xFFE8E2D8);
const _recordCream = Color(0xFFFFF8EA);
const _recordGold = Color(0xFFF6C23E);

class TravelRecordScreen extends StatelessWidget {
  const TravelRecordScreen({super.key});

  static const _records = [
    _TravelRecord(
      date: '2026. 06. 14',
      city: '정선군',
      spot: '정선 5일장',
    ),
    _TravelRecord(
      date: '2026. 06. 08',
      city: '강릉시',
      spot: '강릉 커피거리',
    ),
    _TravelRecord(
      date: '2026. 05. 31',
      city: '평창군',
      spot: '대관령 양떼목장',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: _TravelRecordHeader(
                onBack: () => context.pop(),
              ),
            ),
            SliverToBoxAdapter(child: _TravelSummary(count: _records.length)),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
              sliver: SliverList.separated(
                itemCount: _records.length,
                itemBuilder: (_, index) => _TravelRecordCard(
                  record: _records[index],
                ),
                separatorBuilder: (_, __) => const SizedBox(height: 10),
              ),
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
      padding: const EdgeInsets.fromLTRB(12, 12, 20, 10),
      child: Row(
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
                fontSize: 28,
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

class _TravelSummary extends StatelessWidget {
  const _TravelSummary({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 8, 20, 20),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _recordCream,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _recordLine),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: const BoxDecoration(
              color: Color(0xFFFFE9A5),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.route_rounded,
              color: _recordGold,
              size: 26,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '총 $count곳 방문',
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0,
                  ),
                ),
                const SizedBox(height: 3),
                const Text(
                  '방문한 여행지와 스탬프를 확인하세요.',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
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

class _TravelRecordCard extends StatelessWidget {
  const _TravelRecordCard({required this.record});

  final _TravelRecord record;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _recordLine),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: const BoxDecoration(
              color: Color(0xFFE5F6EA),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.emoji_events_rounded,
              color: _recordPrimary,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  record.spot,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${record.city} · ${record.date}',
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
          const _StampAcquiredBadge(),
        ],
      ),
    );
  }
}

class _StampAcquiredBadge extends StatelessWidget {
  const _StampAcquiredBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFE5F6EA),
        borderRadius: BorderRadius.circular(999),
      ),
      child: const Text(
        '스탬프 획득',
        style: TextStyle(
          color: _recordPrimary,
          fontSize: 11,
          fontWeight: FontWeight.w900,
          letterSpacing: 0,
        ),
      ),
    );
  }
}

class _TravelRecord {
  const _TravelRecord({
    required this.date,
    required this.city,
    required this.spot,
  });

  final String date;
  final String city;
  final String spot;
}
