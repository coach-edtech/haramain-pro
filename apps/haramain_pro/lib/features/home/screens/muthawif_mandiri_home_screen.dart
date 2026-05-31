import 'package:flutter/material.dart';
import '../../../design/tokens/app_colors.dart';
import '../../../design/tokens/app_typography.dart';
import '../../../design/tokens/app_spacing.dart';
import '../../../features/panic/panic_button_widget_new.dart';
import '../../../features/panic/widgets/group_card.dart';
import '../../../features/group/models/group_model.dart';
import '../../../services/location_service.dart';

/// MuthawifMandiri Home Screen as per FRONTEND-SPEC.md Section 4.3
/// Layout:
///   - Home (group + Panic)
///   - Groups
///   - Invite
///   - Broadcast
///   - Profile
/// Note: Has Panic Button visible like Jamaah
class MuthawifMandiriHomeScreen extends StatefulWidget {
  final String muthawifId;
  final String muthawifName;
  final List<Map<String, dynamic>> groups;
  final LocationData? currentLocation;
  final String? nextPrayer;
  final String? nextPrayerTime;

  const MuthawifMandiriHomeScreen({
    super.key,
    required this.muthawifId,
    required this.muthawifName,
    this.groups = const [],
    this.currentLocation,
    this.nextPrayer,
    this.nextPrayerTime,
  });

  @override
  State<MuthawifMandiriHomeScreen> createState() => _MuthawifMandiriHomeScreenState();
}

class _MuthawifMandiriHomeScreenState extends State<MuthawifMandiriHomeScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.slate50,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildHeader(),
              _buildPanicSection(),
              if (widget.nextPrayer != null) _buildPrayerSection(),
              if (widget.groups.isNotEmpty) _buildGroupsSection(),
              const SizedBox(height: 120),
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
            widget.muthawifName,
            style: AppTypography.headlineMedium.copyWith(
              color: Colors.white,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Icon(
                Icons.person,
                size: 14,
                color: AppColors.emerald100,
              ),
              const SizedBox(width: AppSpacing.xs),
              Text(
                'Muthawif Mandiri',
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.emerald100,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Icon(
                Icons.calendar_today,
                size: 14,
                color: AppColors.emerald100,
              ),
              const SizedBox(width: AppSpacing.xs),
              Text(
                gregorianDate,
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.emerald100,
                ),
              ),
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
            jamaaahId: widget.muthawifId,
            grupId: widget.groups.isNotEmpty ? widget.groups.first['id'] : '',
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
                  'Grup Saya',
                  style: AppTypography.titleSmall.copyWith(
                    color: AppColors.slate900,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            itemCount: widget.groups.length > 3 ? 3 : widget.groups.length,
            separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
            itemBuilder: (context, index) {
              final group = widget.groups[index];
              return GroupCard(
                group: GroupModel.fromJson(group),
                isActive: true,
                onTap: () {
                  Navigator.pushNamed(
                    context,
                    '/group-detail',
                    arguments: {'groupId': group['id']},
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
}
