import 'package:flutter/material.dart';
import '../../../design/design.dart';

class IbadahScreenPremium extends StatefulWidget {
  const IbadahScreenPremium({super.key});

  @override
  State<IbadahScreenPremium> createState() => _IbadahScreenPremiumState();
}

class _IbadahScreenPremiumState extends State<IbadahScreenPremium> {
  bool _ibadahModeEnabled = false;
  int _currentPrayerIndex = 0;

  final List<Map<String, dynamic>> _prayerTimes = [
    {'name': 'Subuh', 'time': '04:45', 'status': 'upcoming'},
    {'name': 'Dzuhur', 'time': '11:55', 'status': 'upcoming'},
    {'name': 'Ashar', 'time': '15:20', 'status': 'upcoming'},
    {'name': 'Maghrib', 'time': '18:15', 'status': 'upcoming'},
    {'name': 'Isya', 'time': '19:30', 'status': 'upcoming'},
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: _buildHeader(isDark),
            ),
            SliverToBoxAdapter(
              child: _buildIbadahModeCard(isDark),
            ),
            SliverToBoxAdapter(
              child: _buildPrayerTimesList(isDark),
            ),
            SliverToBoxAdapter(
              child: _buildGeofenceSection(isDark),
            ),
            const SliverToBoxAdapter(
              child: SizedBox(height: 100),
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
            Icons.schedule,
            color: AppColors.gold,
            size: 28,
          ),
          const SizedBox(width: AppSpacing.md),
          Text(
            'Ibadah',
            style: AppTypography.headlineMedium.copyWith(
              color: isDark ? AppColors.onSurfaceDark : AppColors.onSurfaceLight,
              fontWeight: FontWeight.w700,
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: AppSpacing.xs,
            ),
            decoration: BoxDecoration(
              color: AppColors.gold.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.location_on,
                  size: 14,
                  color: AppColors.gold,
                ),
                const SizedBox(width: 4),
                Text(
                  'Makkah',
                  style: AppTypography.labelSmall.copyWith(
                    color: AppColors.gold,
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

  Widget _buildIbadahModeCard(bool isDark) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: _ibadahModeEnabled
              ? [AppColors.gold, AppColors.goldDark]
              : [
                  isDark ? AppColors.cardDark : AppColors.cardLight,
                  isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
                ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        boxShadow: _ibadahModeEnabled
            ? [
                BoxShadow(
                  color: AppColors.gold.withValues(alpha: 0.4),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ]
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: _ibadahModeEnabled
                      ? Colors.white.withValues(alpha: 0.2)
                      : AppColors.gold.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                ),
                child: Icon(
                  _ibadahModeEnabled ? Icons.pause_circle : Icons.play_circle,
                  color: _ibadahModeEnabled ? Colors.white : AppColors.gold,
                  size: 32,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Mode Ibadah',
                      style: AppTypography.titleMedium.copyWith(
                        color: _ibadahModeEnabled
                            ? Colors.white
                            : (isDark ? AppColors.onSurfaceDark : AppColors.onSurfaceLight),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _ibadahModeEnabled
                          ? 'Aktif - Notifikasi dimatikan'
                          : 'Nyalakan untuk fokus beribadah',
                      style: AppTypography.bodySmall.copyWith(
                        color: _ibadahModeEnabled
                            ? Colors.white.withValues(alpha: 0.9)
                            : (isDark ? AppColors.onSurfaceDark : AppColors.onSurfaceLight)
                                .withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: _ibadahModeEnabled,
                onChanged: (value) => setState(() => _ibadahModeEnabled = value),
                activeColor: Colors.white,
                activeTrackColor: Colors.white.withValues(alpha: 0.5),
              ),
            ],
          ),
          if (_ibadahModeEnabled) ...[
            const SizedBox(height: AppSpacing.md),
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: Colors.white.withValues(alpha: 0.9),
                    size: 20,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      'Panggilan sholat dan notifikasi akan dinonaktifkan saat mode ibadah aktif.',
                      style: AppTypography.bodySmall.copyWith(
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPrayerTimesList(bool isDark) {
    return Container(
      margin: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Jadwal Sholat',
            style: AppTypography.titleMedium.copyWith(
              color: isDark ? AppColors.onSurfaceDark : AppColors.onSurfaceLight,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          ...List.generate(_prayerTimes.length, (index) {
            final prayer = _prayerTimes[index];
            final isNext = index == _getNextPrayerIndex();
            return _buildPrayerTimeItem(prayer, isNext, isDark, index);
          }),
        ],
      ),
    );
  }

  int _getNextPrayerIndex() {
    for (int i = 0; i < _prayerTimes.length; i++) {
      if (_prayerTimes[i]['status'] == 'upcoming') {
        return i;
      }
    }
    return 0;
  }

  Widget _buildPrayerTimeItem(
    Map<String, dynamic> prayer,
    bool isNext,
    bool isDark,
    int index,
  ) {
    final isActive = isNext && !_ibadahModeEnabled;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: isActive
            ? AppColors.gold.withValues(alpha: 0.1)
            : (isDark ? AppColors.cardDark : AppColors.cardLight),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: isActive
            ? Border.all(color: AppColors.gold, width: 2)
            : Border.all(
                color: isDark ? AppColors.dividerDark : AppColors.dividerLight,
              ),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: isActive
                  ? AppColors.gold
                  : AppColors.gold.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            ),
            child: Center(
              child: Text(
                '${index + 1}',
                style: AppTypography.titleMedium.copyWith(
                  color: isActive
                      ? Colors.white
                      : AppColors.gold,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  prayer['name'] as String,
                  style: AppTypography.bodyLarge.copyWith(
                    color: isDark ? AppColors.onSurfaceDark : AppColors.onSurfaceLight,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (isActive)
                  Text(
                    'Selanjutnya',
                    style: AppTypography.labelSmall.copyWith(
                      color: AppColors.gold,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
              ],
            ),
          ),
          Text(
            prayer['time'] as String,
            style: AppTypography.titleMedium.copyWith(
              color: isActive
                  ? AppColors.gold
                  : (isDark ? AppColors.onSurfaceDark : AppColors.onSurfaceLight),
              fontWeight: FontWeight.w700,
            ),
          ),
          if (isActive) ...[
            const SizedBox(width: AppSpacing.sm),
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: AppColors.gold.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.notifications_active,
                size: 16,
                color: AppColors.gold,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildGeofenceSection(bool isDark) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Zona Geofence',
            style: AppTypography.titleMedium.copyWith(
              color: isDark ? AppColors.onSurfaceDark : AppColors.onSurfaceLight,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          _buildGeofenceItem(
            name: 'Masjidil Haram',
            distance: '50m',
            isActive: true,
            isDark: isDark,
          ),
          _buildGeofenceItem(
            name: 'Masjid Nabawi',
            distance: 'Offline',
            isActive: false,
            isDark: isDark,
          ),
        ],
      ),
    );
  }

  Widget _buildGeofenceItem({
    required String name,
    required String distance,
    required bool isActive,
    required bool isDark,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
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
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: isActive
                  ? AppColors.success.withValues(alpha: 0.1)
                  : AppColors.gold.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            ),
            child: Icon(
              Icons.place,
              color: isActive ? AppColors.success : AppColors.gold,
              size: 20,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: AppTypography.bodyMedium.copyWith(
                    color: isDark ? AppColors.onSurfaceDark : AppColors.onSurfaceLight,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  'Radius: 100m',
                  style: AppTypography.bodySmall.copyWith(
                    color: (isDark ? AppColors.onSurfaceDark : AppColors.onSurfaceLight)
                        .withValues(alpha: 0.6),
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
              color: isActive
                  ? AppColors.success.withValues(alpha: 0.1)
                  : AppColors.gold.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
            ),
            child: Text(
              distance,
              style: AppTypography.labelSmall.copyWith(
                color: isActive ? AppColors.success : AppColors.gold,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
