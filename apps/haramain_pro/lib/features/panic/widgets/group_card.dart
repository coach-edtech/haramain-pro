import 'package:flutter/material.dart';
import '../../../design/tokens/app_colors.dart';
import '../../../design/tokens/app_typography.dart';
import '../../../design/tokens/app_spacing.dart';
import '../../group/models/group_model.dart';

/// GroupCard widget as per FRONTEND-SPEC.md Section 4.2
/// Content: Group name, member count, status badge, travel name (if applicable)
/// States: active (green border), alumni (muted), pending (amber)
/// Actions: Tap -> Group detail, long-press -> quick actions
class GroupCard extends StatelessWidget {
  final GroupModel group;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final bool isActive;
  final bool isAlumni;
  final bool isPending;
  final String? travelName;

  const GroupCard({
    super.key,
    required this.group,
    this.onTap,
    this.onLongPress,
    this.isActive = true,
    this.isAlumni = false,
    this.isPending = false,
    this.travelName,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Container(
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
          border: Border.all(
            color: _getBorderColor(),
            width: isActive || isPending ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row
            Row(
              children: [
                // Group avatar
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.emerald100,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.emerald500,
                      width: 2,
                    ),
                  ),
                  child: const Icon(
                    Icons.group,
                    color: AppColors.emerald700,
                    size: 22,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                
                // Group info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        group.name,
                        style: AppTypography.titleMedium.copyWith(
                          color: isAlumni
                              ? AppColors.slate600
                              : AppColors.slate900,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${group.memberCount} anggota',
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.slate600,
                        ),
                      ),
                    ],
                  ),
                ),

                // Status badge
                _StatusBadge(
                  isActive: isActive,
                  isAlumni: isAlumni,
                  isPending: isPending,
                ),
              ],
            ),

            // Travel name (if available)
            if (travelName != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.xs,
                ),
                decoration: BoxDecoration(
                  color: AppColors.slate50,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusXs),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.business,
                      size: 12,
                      color: AppColors.slate600,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      travelName!,
                      style: AppTypography.labelSmall.copyWith(
                        color: AppColors.slate600,
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // PIN indicator (for easy reference)
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                const Icon(
                  Icons.pin,
                  size: 14,
                  color: AppColors.slate600,
                ),
                const SizedBox(width: 4),
                Text(
                  'PIN: ${group.pin}',
                  style: AppTypography.labelSmall.copyWith(
                    color: AppColors.slate600,
                    letterSpacing: 1.5,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getBorderColor() {
    if (isPending) return AppColors.amber500;
    if (isAlumni) return AppColors.slate200;
    if (isActive) return AppColors.emerald500;
    return AppColors.slate200;
  }
}

class _StatusBadge extends StatelessWidget {
  final bool isActive;
  final bool isAlumni;
  final bool isPending;

  const _StatusBadge({
    required this.isActive,
    required this.isAlumni,
    required this.isPending,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: _getBackgroundColor(),
        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
      ),
      child: Text(
        _getLabel(),
        style: AppTypography.labelSmall.copyWith(
          color: _getTextColor(),
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Color _getBackgroundColor() {
    if (isPending) return AppColors.amber50;
    if (isAlumni) return AppColors.slate100;
    if (isActive) return AppColors.emerald100;
    return AppColors.slate100;
  }

  Color _getTextColor() {
    if (isPending) return AppColors.amber600;
    if (isAlumni) return AppColors.slate600;
    if (isActive) return AppColors.emerald700;
    return AppColors.slate600;
  }

  String _getLabel() {
    if (isPending) return 'Tertunda';
    if (isAlumni) return 'Alumni';
    if (isActive) return 'Aktif';
    return 'Tidak Aktif';
  }
}

/// JamaahAvatar widget as per FRONTEND-SPEC.md Section 4.2
/// Circular avatar with role badge
/// Size: 40dp (list), 64dp (detail)
/// Badge: Role-colored dot (Muthawif=emerald, Jamaah=blue, TS=amber)
/// Offline indicator: greyed out + "Offline" label
class JamaahAvatar extends StatelessWidget {
  final String? imageUrl;
  final String name;
  final String role; // 'muthawif', 'jamaah', 'team_support'
  final bool isOffline;
  final double size; // 40 or 64

  const JamaahAvatar({
    super.key,
    this.imageUrl,
    required this.name,
    required this.role,
    this.isOffline = false,
    this.size = 40,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Stack(
          children: [
            // Avatar
            Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _getAvatarColor(),
                border: Border.all(
                  color: _getBorderColor(),
                  width: 2,
                ),
              ),
              child: imageUrl != null
                  ? ClipOval(
                      child: Image.network(
                        imageUrl!,
                        width: size,
                        height: size,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => _buildInitials(),
                      ),
                    )
                  : _buildInitials(),
            ),
            
            // Role badge
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                width: size * 0.3,
                height: size * 0.3,
                decoration: BoxDecoration(
                  color: _getRoleColor(),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white,
                    width: 2,
                  ),
                ),
              ),
            ),
          ],
        ),
        
        // Offline label
        if (isOffline) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Offline',
            style: AppTypography.labelSmall.copyWith(
              color: AppColors.slate600,
              fontSize: 10,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildInitials() {
    final initials = name.split(' ').map((e) => e.isNotEmpty ? e[0] : '').take(2).join();
    return Center(
      child: Text(
        initials.toUpperCase(),
        style: TextStyle(
          color: _getBorderColor(),
          fontSize: size * 0.35,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Color _getAvatarColor() {
    return isOffline ? AppColors.slate200 : AppColors.emerald100;
  }

  Color _getBorderColor() {
    return isOffline ? AppColors.slate300 : _getRoleColor();
  }

  Color _getRoleColor() {
    switch (role) {
      case 'muthawif':
        return AppColors.emerald700;
      case 'team_support':
        return AppColors.amber500;
      case 'jamaah':
      default:
        return AppColors.amber500;
    }
  }
}
