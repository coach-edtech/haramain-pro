import 'package:flutter/material.dart';
import '../../../design/tokens/app_colors.dart';
import '../../../design/tokens/app_typography.dart';
import '../../../design/tokens/app_spacing.dart';
import '../../../features/panic/widgets/group_card.dart';
import '../../../features/group/models/group_model.dart';
import '../../../services/location_service.dart';

/// TeamSupport Home Screen as per FRONTEND-SPEC.md Section 4.3
/// Layout:
///   - Home: Assigned Jamaah
///   - Groups
///   - Profile
class TeamSupportHomeScreen extends StatefulWidget {
  final String teamSupportId;
  final String teamSupportName;
  final List<Map<String, dynamic>> assignedJamaah;
  final List<Map<String, dynamic>> groups;
  final LocationData? currentLocation;

  const TeamSupportHomeScreen({
    super.key,
    required this.teamSupportId,
    required this.teamSupportName,
    this.assignedJamaah = const [],
    this.groups = const [],
    this.currentLocation,
  });

  @override
  State<TeamSupportHomeScreen> createState() => _TeamSupportHomeScreenState();
}

class _TeamSupportHomeScreenState extends State<TeamSupportHomeScreen> {
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
              _buildStatsSection(),
              if (widget.assignedJamaah.isNotEmpty) _buildAssignedJamaahSection(),
              if (widget.groups.isNotEmpty) _buildGroupsSection(),
              const SizedBox(height: 80),
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
        color: AppColors.amber600,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Assalamu\'alaikum',
            style: AppTypography.bodyLarge.copyWith(
              color: AppColors.amber50,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            widget.teamSupportName,
            style: AppTypography.headlineMedium.copyWith(
              color: Colors.white,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              const Icon(
                Icons.support_agent,
                size: 14,
                color: AppColors.amber50,
              ),
              const SizedBox(width: AppSpacing.xs),
              Text(
                'Team Support',
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.amber50,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              const Icon(
                Icons.calendar_today,
                size: 14,
                color: AppColors.amber50,
              ),
              const SizedBox(width: AppSpacing.xs),
              Text(
                gregorianDate,
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.amber50,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatsSection() {
    return Container(
      margin: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          Expanded(
            child: _StatCard(
              icon: Icons.group,
              value: '${widget.assignedJamaah.length}',
              label: 'Jamaah Ditugaskan',
              color: AppColors.amber500,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: _StatCard(
              icon: Icons.groups,
              value: '${widget.groups.length}',
              label: 'Grup',
              color: AppColors.emerald500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAssignedJamaahSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.people,
                size: 18,
                color: AppColors.amber600,
              ),
              const SizedBox(width: AppSpacing.xs),
              Text(
                'Jamaah Ditugaskan',
                style: AppTypography.titleMedium.copyWith(
                  color: AppColors.slate900,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          ...widget.assignedJamaah.map((jamaah) => _JamaahTile(
                name: jamaah['name'] ?? '',
                travelName: jamaah['travel_name'] ?? '',
                status: jamaah['status'] ?? 'active',
              )),
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
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: Row(
              children: [
                const Icon(
                  Icons.groups,
                  size: 18,
                  color: AppColors.emerald700,
                ),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  'Grup',
                  style: AppTypography.titleMedium.copyWith(
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
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            itemCount: widget.groups.length > 3 ? 3 : widget.groups.length,
            separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
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

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: AppSpacing.sm),
          Text(
            value,
            style: AppTypography.headlineMedium.copyWith(
              color: AppColors.slate900,
            ),
          ),
          Text(
            label,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.slate600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _JamaahTile extends StatelessWidget {
  final String name;
  final String travelName;
  final String status;

  const _JamaahTile({
    required this.name,
    required this.travelName,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = status == 'active';
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.cardLight,
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        border: Border.all(
          color: isActive ? AppColors.emerald500 : AppColors.slate200,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.amber50,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.amber500, width: 2),
            ),
            child: Center(
              child: Text(
                name.split(' ').map((e) => e.isNotEmpty ? e[0] : '').take(2).join(),
                style: AppTypography.titleSmall.copyWith(
                  color: AppColors.amber600,
                  fontWeight: FontWeight.bold,
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
                  name,
                  style: AppTypography.titleSmall.copyWith(
                    color: AppColors.slate900,
                  ),
                ),
                if (travelName.isNotEmpty)
                  Text(
                    travelName,
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.slate600,
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
              color: isActive ? AppColors.emerald100 : AppColors.slate100,
              borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
            ),
            child: Text(
              isActive ? 'Aktif' : 'Offline',
              style: AppTypography.labelSmall.copyWith(
                color: isActive ? AppColors.emerald700 : AppColors.slate600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
