import 'package:flutter/material.dart';
import '../../../design/tokens/app_colors.dart';
import '../../../design/tokens/app_typography.dart';
import '../../../design/tokens/app_spacing.dart';
import '../../../features/panic/panic_service.dart';
import '../../../features/panic/widgets/group_card.dart';
import '../../../services/location_service.dart';

/// Muthawif Home Screen as per FRONTEND-SPEC.md Section 4.3
/// Layout:
///   - Greeting + group name
///   - Incoming Alert Banner (if any)
///   - Quick Stats: X Jamaah, Y lokasi
///   - Group Members list (compact)
///   - Status indicators per Jamaah
///   - FAB: Broadcast (green, 56dp)
class MuthawifHomeScreen extends StatefulWidget {
  final String muthawifId;
  final String muthawifName;
  final String groupName;
  final int totalJamaah;
  final List<Map<String, dynamic>> JamaahMembers;
  final LocationData? currentLocation;
  final PanicAlert? activeAlert;

  const MuthawifHomeScreen({
    super.key,
    required this.muthawifId,
    required this.muthawifName,
    required this.groupName,
    required this.totalJamaah,
    required this.JamaahMembers,
    this.currentLocation,
    this.activeAlert,
  });

  @override
  State<MuthawifHomeScreen> createState() => _MuthawifHomeScreenState();
}

class _MuthawifHomeScreenState extends State<MuthawifHomeScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.slate50,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.pushNamed(context, '/broadcast');
        },
        backgroundColor: AppColors.emerald500,
        icon: const Icon(Icons.campaign, color: Colors.white),
        label: Text(
          'Broadcast',
          style: AppTypography.labelLarge.copyWith(color: Colors.white),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              _buildHeader(),
              
              // Incoming Alert Banner (if any active panic)
              if (widget.activeAlert != null)
                _buildAlertBanner(),
              
              // Quick Stats
              _buildStatsSection(),
              
              // Group Members
              _buildMembersSection(),
              
              const SizedBox(height: 80), // Space for FAB
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
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
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: AppSpacing.xs,
            ),
            decoration: BoxDecoration(
              color: AppColors.emerald700,
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            ),
            child: Text(
              widget.groupName,
              style: AppTypography.labelMedium.copyWith(
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAlertBanner() {
    final alert = widget.activeAlert!;
    return Container(
      margin: const EdgeInsets.all(AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.red100,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.red600, width: 2),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: const BoxDecoration(
              color: AppColors.red600,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.warning,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'PANIC ALERT!',
                  style: AppTypography.titleSmall.copyWith(
                    color: AppColors.red600,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Jamaah butuh bantuan di lokasi Anda',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.red600,
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () {
              _showResponseDialog(alert);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              decoration: BoxDecoration(
                color: AppColors.red600,
                borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
              ),
              child: Text(
                'RESPOND',
                style: AppTypography.labelMedium.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showResponseDialog(PanicAlert alert) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppSpacing.radiusXl),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Respon Panic Alert',
              style: AppTypography.titleLarge.copyWith(
                color: AppColors.slate900,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            
            // Option A: Stay,jemput
            _ResponseOption(
              icon: Icons.directions_walk,
              title: 'Stay, saya jemput',
              subtitle: 'Tidak berbagi lokasi',
              color: AppColors.amber500,
              onTap: () async {
                Navigator.pop(context);
                await PanicService.instance.respondToPanic(
                  alertId: alert.id,
                  action: PanicResponseAction.stayJemput,
                  responderId: widget.muthawifId,
                );
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Anda akan menjemput Jamaah'),
                      backgroundColor: AppColors.emerald700,
                    ),
                  );
                }
              },
            ),
            const SizedBox(height: AppSpacing.md),
            
            // Option B: Saya di sini
            _ResponseOption(
              icon: Icons.location_on,
              title: 'Saya di sini',
              subtitle: 'Berbagi lokasi Anda ke Jamaah',
              color: AppColors.emerald500,
              onTap: () async {
                Navigator.pop(context);
                await PanicService.instance.respondToPanic(
                  alertId: alert.id,
                  action: PanicResponseAction.sayaDiSini,
                  responderId: widget.muthawifId,
                );
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Lokasi Anda dikirim ke Jamaah'),
                      backgroundColor: AppColors.emerald700,
                    ),
                  );
                }
              },
            ),
            
            const SizedBox(height: AppSpacing.lg),
          ],
        ),
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
              value: '${widget.totalJamaah}',
              label: 'Jamaah',
              color: AppColors.emerald500,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: _StatCard(
              icon: Icons.location_on,
              value: '0',
              label: 'Lokasi',
              color: AppColors.amber500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMembersSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Anggota Grup',
            style: AppTypography.titleMedium.copyWith(
              color: AppColors.slate900,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          ...widget.JamaahMembers.map((member) => _MemberTile(
            name: member['name'] ?? '',
            isOnline: member['is_online'] ?? false,
            lastSeen: member['last_seen'],
          )),
        ],
      ),
    );
  }
}

class _ResponseOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _ResponseOption({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          border: Border.all(color: color, width: 2),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: Colors.white, size: 24),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTypography.titleSmall.copyWith(
                      color: AppColors.slate900,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.slate600,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right,
              color: AppColors.slate400,
            ),
          ],
        ),
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
          ),
        ],
      ),
    );
  }
}

class _MemberTile extends StatelessWidget {
  final String name;
  final bool isOnline;
  final String? lastSeen;

  const _MemberTile({
    required this.name,
    required this.isOnline,
    this.lastSeen,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.cardLight,
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        border: Border.all(
          color: isOnline ? AppColors.emerald500 : AppColors.slate200,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          JamaahAvatar(
            name: name,
            role: 'jamaah',
            isOffline: !isOnline,
            size: 40,
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
                Text(
                  isOnline ? 'Online' : (lastSeen ?? 'Offline'),
                  style: AppTypography.bodySmall.copyWith(
                    color: isOnline ? AppColors.emerald700 : AppColors.slate600,
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: isOnline ? AppColors.emerald500 : AppColors.slate400,
              shape: BoxShape.circle,
            ),
          ),
        ],
      ),
    );
  }
}
