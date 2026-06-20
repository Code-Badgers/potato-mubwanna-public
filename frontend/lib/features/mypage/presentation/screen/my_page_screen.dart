import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';

const _mypagePrimary = Color(0xFF56C787);
const _mypageDark = Color(0xFF509B64);
const _mypageLine = Color(0xFFE8E2D8);
const _mypageCream = Color(0xFFFFF8EA);
const _mypageBrown = Color(0xFF7A4A24);
const _mypageGold = Color(0xFFF6C23E);

class MyPageScreen extends StatelessWidget {
  const MyPageScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _MyPageHeader()),
            SliverToBoxAdapter(child: _ProfileSummary()),
            SliverToBoxAdapter(child: _TravelStats()),
            SliverToBoxAdapter(child: _QuickActionGrid()),
            SliverToBoxAdapter(child: _TravelBanner()),
            SliverToBoxAdapter(child: _AccountMenu()),
            SliverToBoxAdapter(child: SizedBox(height: 24)),
          ],
        ),
      ),
    );
  }
}

class _MyPageHeader extends StatelessWidget {
  const _MyPageHeader();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 18, 24, 10),
      child: Row(
        children: [
          const Expanded(
            child: Text(
              '마이',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 30,
                fontWeight: FontWeight.w900,
                letterSpacing: 0,
              ),
            ),
          ),
          IconButton(
            tooltip: '설정',
            onPressed: () {},
            icon: const Icon(
              Icons.settings_outlined,
              color: AppColors.textPrimary,
              size: 28,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileSummary extends StatelessWidget {
  const _ProfileSummary();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 22),
      child: Row(
        children: [
          Container(
            width: 102,
            height: 102,
            decoration: BoxDecoration(
              color: const Color(0xFFFFE17A),
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFF8D14E), width: 4),
              boxShadow: [
                BoxShadow(
                  color: _mypageGold.withValues(alpha: 0.22),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: const Icon(
              Icons.face_3_rounded,
              size: 58,
              color: _mypageBrown,
            ),
          ),
          const SizedBox(width: 22),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '감자여행자',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Lv.2',
                  style: TextStyle(
                    color: _mypageBrown,
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0,
                  ),
                ),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: const LinearProgressIndicator(
                    minHeight: 11,
                    value: 0.642,
                    backgroundColor: Color(0xFFE5E0D5),
                    valueColor: AlwaysStoppedAnimation<Color>(_mypageDark),
                  ),
                ),
                const SizedBox(height: 6),
                const Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    '6,420 / 10,000',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
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

class _TravelStats extends StatelessWidget {
  const _TravelStats();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _mypageLine),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: const Row(
        children: [
          Expanded(
            child: _StatItem(label: '누적 걸음 수', value: '256,842'),
          ),
          _VerticalDivider(),
          Expanded(
            child: _StatItem(label: '누적 스탬프 수', value: '8'),
          ),
          _VerticalDivider(),
          Expanded(
            child: _StatItem(label: '보유 감자 수', value: '12'),
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  const _StatItem({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 13,
            fontWeight: FontWeight.w800,
            letterSpacing: 0,
          ),
        ),
        const SizedBox(height: 9),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            value,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 25,
              fontWeight: FontWeight.w900,
              letterSpacing: 0,
            ),
          ),
        ),
      ],
    );
  }
}

class _VerticalDivider extends StatelessWidget {
  const _VerticalDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 54,
      color: _mypageLine,
    );
  }
}

class _QuickActionGrid extends StatelessWidget {
  const _QuickActionGrid();

  static const _actions = [
    _QuickAction(icon: Icons.card_giftcard_rounded, label: '보상함'),
    _QuickAction(icon: Icons.menu_book_rounded, label: '여행 기록'),
    _QuickAction(icon: Icons.assignment_turned_in_rounded, label: '내 미션'),
    _QuickAction(icon: Icons.inventory_2_rounded, label: '감자 도감'),
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 22),
      child: Row(
        children: [
          for (var index = 0; index < _actions.length; index++) ...[
            Expanded(child: _QuickActionCard(action: _actions[index])),
            if (index < _actions.length - 1) const SizedBox(width: 12),
          ],
        ],
      ),
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  const _QuickActionCard({required this.action});

  final _QuickAction action;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: () {},
        borderRadius: BorderRadius.circular(18),
        child: Container(
          height: 96,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: _mypageLine),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(action.icon, color: _mypageBrown, size: 30),
              const SizedBox(height: 10),
              Text(
                action.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
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
    );
  }
}

class _TravelBanner extends StatelessWidget {
  const _TravelBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 22),
      height: 94,
      decoration: BoxDecoration(
        color: const Color(0xFFCDE8D7),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Stack(
        children: [
          Positioned(
            right: 20,
            bottom: -4,
            child: Icon(
              Icons.eco_rounded,
              color: _mypagePrimary.withValues(alpha: 0.42),
              size: 86,
            ),
          ),
          const Positioned(
            right: 82,
            top: 20,
            child: Icon(Icons.location_on_rounded, color: Color(0xFF4E93B8)),
          ),
          const Positioned(
            right: 34,
            top: 12,
            child: Icon(Icons.location_on_rounded, color: Color(0xFFE85B4F)),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(24, 21, 126, 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '강원 감자 여행',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  '기록을 확인해보세요!',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
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

class _AccountMenu extends StatelessWidget {
  const _AccountMenu();

  static const _items = [
    _MenuItem(icon: Icons.settings_outlined, label: '설정'),
    _MenuItem(icon: Icons.campaign_outlined, label: '공지사항'),
    _MenuItem(icon: Icons.help_outline_rounded, label: '고객센터'),
    _MenuItem(icon: Icons.logout_rounded, label: '로그아웃'),
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Material(
        color: _mypageCream,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: _mypageLine),
        ),
        child: Column(
          children: [
            for (var index = 0; index < _items.length; index++) ...[
              _MenuRow(item: _items[index]),
              if (index < _items.length - 1)
                const Divider(height: 1, color: _mypageLine, indent: 58),
            ],
          ],
        ),
      ),
    );
  }
}

class _MenuRow extends StatelessWidget {
  const _MenuRow({required this.item});

  final _MenuItem item;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {},
      child: SizedBox(
        height: 64,
        child: Row(
          children: [
            const SizedBox(width: 20),
            Icon(item.icon, color: _mypageBrown, size: 25),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                item.label,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0,
                ),
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.textSecondary,
              size: 25,
            ),
            const SizedBox(width: 16),
          ],
        ),
      ),
    );
  }
}

class _QuickAction {
  const _QuickAction({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;
}

class _MenuItem {
  const _MenuItem({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;
}
