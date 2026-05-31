import 'package:flutter/material.dart';
import '../../../design/tokens/app_colors.dart';
import '../../../design/tokens/app_typography.dart';
import '../../../design/tokens/app_spacing.dart';
import '../../panic/panic_button_widget_new.dart';
import '../../panic/widgets/doa_card.dart';
import '../../panic/widgets/group_card.dart';
import '../../group/models/group_model.dart';
import '../../../services/location_service.dart';

/// Jamaah Home Screen as per FRONTEND-SPEC.md Section 4.3
/// Layout:
///   - Greeting + date (Hijri/Gregorian)
///   - Panic Button (centered, 80dp)
///   - "Tekan jika butuh bantuan"
///   - Map Preview Widget (200dp)
///   - "Peta Luring Aktif"
///   - Next Prayer + countdown
///   - Doa Suggestion card
///   - Active Groups (horizontal scroll)
class JamaahHomeScreen extends StatefulWidget {
  final String jamaaahId;
  final String grupId;
  final String userName;
  final String? travelName;
  final List<Map<String, dynamic>> activeGroups;
  final LocationData? currentLocation;
  final String? nextPrayer;
  final String? nextPrayerTime;
  final Map<String, dynamic>? nearestDoa;

  const JamaahHomeScreen({
    super.key,
    required this.jamaaahId,
    required this.grupId,
    required this.userName,
    this.travelName,
    this.activeGroups = const [],
    this.currentLocation,
    this.nextPrayer,
    this.nextPrayerTime,
    this.nearestDoa,
  });

  @override
  State<JamaahHomeScreen> createState() => _JamaahHomeScreenState();
}

class _JamaahHomeScreenState extends State<JamaahHomeScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.slate50,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header with greeting
              _buildHeader(),
              
              // Panic Button Section
              _buildPanicSection(),
              
              // Map Preview
              _buildMapPreview(),
              
              // Prayer Time Section
              if (widget.nextPrayer != null)
                _buildPrayerSection(),
              
              // Doa Suggestion
              if (widget.nearestDoa != null)
                _buildDoaSection(),
              
              // Active Groups
              if (widget.activeGroups.isNotEmpty)
                _buildGroupsSection(),
              
              const SizedBox(height: 120), // Space for panic button
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final now = DateTime.now();
    final gregorianDate = '${now.day}/${now.month}/${now.year}';
    
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: const BoxDecoration(
        color: AppColors.emerald900,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Assalamu\'alaikum',
            style: AppTypography.bodyLarge.copyWith(
              color: AppColors.emerald100,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            widget.userName,
            style: AppTypography.headlineMedium.copyWith(
              color: Colors.white,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Icon(
                Icons.calendar_today,
                size: 14,
                color: AppColors.emerald200,
              ),
              const SizedBox(width: AppSpacing.xs),
              Text(
                gregorianDate,
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.emerald200,
                ),
              ),
              if (widget.travelName != null) ...[
                const SizedBox(width: AppSpacing.md),
                Icon(
                  Icons.business,
                  size: 14,
                  color: AppColors.emerald200,
                ),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  widget.travelName!,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.emerald200,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPanicSection() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
      child: Column(
        children: [
          PanicButtonPremium(
            jamaaahId: widget.jamaaahId,
            grupId: widget.grupId,
            initialLocation: widget.currentLocation,
            onPanicSent: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Panic alert terkirim!'),
                  backgroundColor: AppColors.emerald700,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                  ),
                ),
              );
            },
            onPanicFailed: (error) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Gagal: $error'),
                  backgroundColor: AppColors.red600,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMapPreview() {
    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(context, '/map');
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        height: 200,
        decoration: BoxDecoration(
          color: AppColors.slate200,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Map placeholder (actual map would be flutter_map)
            ClipRRect(
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              child: Container(
                color: AppColors.darkNavy,
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.map,
                        size: 48,
                        color: AppColors.amber500,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        'Peta Luring Aktif',
                        style: AppTypography.titleMedium.copyWith(
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        'Tap untuk melihat peta lengkap',
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.slate400,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            
            // Location indicator
            if (widget.currentLocation != null)
              Positioned(
                top: AppSpacing.sm,
                right: AppSpacing.sm,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: AppSpacing.xs,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.emerald700,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.my_location,
                        size: 12,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'GPS Aktif',
                        style: AppTypography.labelSmall.copyWith(
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPrayerSection() {
    return Container(
      margin: const EdgeInsets.all(AppSpacing.lg),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.cardLight,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: const BoxDecoration(
              color: AppColors.emerald100,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.access_time,
              color: AppColors.emerald700,
              size: 24,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Shalat Berikutnya',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.slate600,
                  ),
                ),
                Text(
                  widget.nextPrayer ?? '',
                  style: AppTypography.titleMedium.copyWith(
                    color: AppColors.slate900,
                  ),
                ),
              ],
            ),
          ),
          if (widget.nextPrayerTime != null)
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              decoration: BoxDecoration(
                color: AppColors.amber50,
                borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
              ),
              child: Text(
                widget.nextPrayerTime!,
                style: AppTypography.titleMedium.copyWith(
                  color: AppColors.amber600,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDoaSection() {
    final doa = widget.nearestDoa!;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: Row(
              children: [
                const Icon(
                  Icons.auto_awesome,
                  size: 18,
                  color: AppColors.amber500,
                ),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  'Doa di Sekitar Anda',
                  style: AppTypography.titleSmall.copyWith(
                    color: AppColors.slate900,
                  ),
                ),
              ],
            ),
          ),
          DoaCard(
            zoneId: doa['id'] ?? '',
            zoneName: doa['name'] ?? '',
            arabicText: doa['arabic'] ?? '',
            latinText: doa['latin'] ?? '',
            indonesianText: doa['indonesian'] ?? '',
            locationBadge: doa['mosque'] ?? '',
          ),
        ],
      ),
    );
  }

  Widget _buildGroupsSection() {
    return Container(
      margin: const EdgeInsets.only(top: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Row(
              children: [
                const Icon(
                  Icons.groups,
                  size: 18,
                  color: AppColors.emerald700,
                ),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  'Grup Aktif',
                  style: AppTypography.titleSmall.copyWith(
                    color: AppColors.slate900,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          SizedBox(
            height: 120,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              itemCount: widget.activeGroups.length,
              separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.md),
              itemBuilder: (context, index) {
                final group = widget.activeGroups[index];
                return SizedBox(
                  width: 200,
                  child: GroupCard(
                    group: GroupModel.fromJson(group),
                    isActive: true,
                    travelName: widget.travelName,
                    onTap: () {
                      Navigator.pushNamed(
                        context,
                        '/group-detail',
                        arguments: {'groupId': group['id']},
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
