import 'package:flutter/material.dart';
import '../../../design/design.dart';

class HistoryScreenPremium extends StatefulWidget {
  const HistoryScreenPremium({super.key});

  @override
  State<HistoryScreenPremium> createState() => _HistoryScreenPremiumState();
}

class _HistoryScreenPremiumState extends State<HistoryScreenPremium>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final List<Map<String, dynamic>> _panicHistory = [
    {
      'id': '1',
      'time': '14 Mar 2026, 10:30',
      'status': 'resolved',
      'location': 'Masjidil Haram, Mekkah',
    },
    {
      'id': '2',
      'time': '12 Mar 2026, 15:45',
      'status': 'resolved',
      'location': 'Arafah',
    },
  ];

  final List<Map<String, dynamic>> _photoJourney = [
    {'id': '1', 'date': '10 Mar 2026', 'location': 'Masjidil Haram'},
    {'id': '2', 'date': '11 Mar 2026', 'location': 'Arafah'},
    {'id': '3', 'date': '12 Mar 2026', 'location': 'Muzdalifah'},
    {'id': '4', 'date': '13 Mar 2026', 'location': 'Mina'},
    {'id': '5', 'date': '14 Mar 2026', 'location': 'Masjid Nabawi'},
    {'id': '6', 'date': '15 Mar 2026', 'location': 'Makkah'},
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(isDark),
            _buildTabBar(isDark),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildPanicHistoryList(isDark),
                  _buildPhotoJourneyList(isDark),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Row(
        children: [
          Icon(
            Icons.history,
            color: AppColors.gold,
            size: 28,
          ),
          const SizedBox(width: AppSpacing.md),
          Text(
            'Riwayat',
            style: AppTypography.headlineMedium.copyWith(
              color: isDark ? AppColors.onSurfaceDark : AppColors.onSurfaceLight,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar(bool isDark) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          color: AppColors.gold,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        ),
        labelColor: AppColors.primaryDark,
        unselectedLabelColor: isDark ? AppColors.onSurfaceDark : AppColors.onSurfaceLight,
        labelStyle: AppTypography.labelLarge.copyWith(fontWeight: FontWeight.w600),
        dividerColor: Colors.transparent,
        tabs: const [
          Tab(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.warning_amber, size: 18),
                SizedBox(width: 8),
                Text('Panic'),
              ],
            ),
          ),
          Tab(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.photo_library, size: 18),
                SizedBox(width: 8),
                Text('Jejak'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPanicHistoryList(bool isDark) {
    if (_panicHistory.isEmpty) {
      return _buildEmptyState(
        icon: Icons.check_circle_outline,
        message: 'Tidak ada riwayat panic',
        isDark: isDark,
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(AppSpacing.lg),
      itemCount: _panicHistory.length,
      itemBuilder: (context, index) {
        final item = _panicHistory[index];
        return _buildPanicHistoryItem(item, isDark);
      },
    );
  }

  Widget _buildPanicHistoryItem(Map<String, dynamic> item, bool isDark) {
    final isResolved = item['status'] == 'resolved';

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.cardLight,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(
          color: isDark ? AppColors.dividerDark : AppColors.dividerLight,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: isResolved
                  ? AppColors.success.withValues(alpha: 0.1)
                  : AppColors.warning.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            ),
            child: Icon(
              isResolved ? Icons.check_circle : Icons.warning,
              color: isResolved ? AppColors.success : AppColors.warning,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item['time'] as String,
                  style: AppTypography.bodyMedium.copyWith(
                    color: isDark ? AppColors.onSurfaceDark : AppColors.onSurfaceLight,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  item['location'] as String,
                  style: AppTypography.bodySmall.copyWith(
                    color: (isDark ? AppColors.onSurfaceDark : AppColors.onSurfaceLight)
                        .withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: AppSpacing.xs,
            ),
            decoration: BoxDecoration(
              color: isResolved
                  ? AppColors.success.withValues(alpha: 0.1)
                  : AppColors.warning.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
            ),
            child: Text(
              isResolved ? 'Resolved' : 'Active',
              style: AppTypography.labelSmall.copyWith(
                color: isResolved ? AppColors.success : AppColors.warning,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoJourneyList(bool isDark) {
    if (_photoJourney.isEmpty) {
      return _buildEmptyState(
        icon: Icons.photo_library_outlined,
        message: 'Tidak ada foto',
        isDark: isDark,
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(AppSpacing.lg),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: AppSpacing.md,
        crossAxisSpacing: AppSpacing.md,
        childAspectRatio: 1.0,
      ),
      itemCount: _photoJourney.length,
      itemBuilder: (context, index) {
        final item = _photoJourney[index];
        return _buildPhotoItem(item, isDark);
      },
    );
  }

  Widget _buildPhotoItem(Map<String, dynamic> item, bool isDark) {
    return GestureDetector(
      onTap: () {},
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.cardDark : AppColors.cardLight,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          border: Border.all(
            color: isDark ? AppColors.dividerDark : AppColors.dividerLight,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.gold.withValues(alpha: 0.1),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(AppSpacing.radiusMd),
                  ),
                ),
                child: Center(
                  child: Icon(
                    Icons.image,
                    size: 48,
                    color: AppColors.gold.withValues(alpha: 0.5),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.sm),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item['location'] as String,
                    style: AppTypography.bodySmall.copyWith(
                      color: isDark ? AppColors.onSurfaceDark : AppColors.onSurfaceLight,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    item['date'] as String,
                    style: AppTypography.labelSmall.copyWith(
                      color: (isDark ? AppColors.onSurfaceDark : AppColors.onSurfaceLight)
                          .withValues(alpha: 0.6),
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

  Widget _buildEmptyState({
    required IconData icon,
    required String message,
    required bool isDark,
  }) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 64,
            color: AppColors.gold.withValues(alpha: 0.5),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            message,
            style: AppTypography.bodyMedium.copyWith(
              color: (isDark ? AppColors.onSurfaceDark : AppColors.onSurfaceLight)
                  .withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }
}
