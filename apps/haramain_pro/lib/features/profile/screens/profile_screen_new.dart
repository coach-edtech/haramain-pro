import 'package:flutter/material.dart';
import '../../../design/design.dart';

class ProfileScreenPremium extends StatefulWidget {
  const ProfileScreenPremium({super.key});

  @override
  State<ProfileScreenPremium> createState() => _ProfileScreenPremiumState();
}

class _ProfileScreenPremiumState extends State<ProfileScreenPremium> {
  final Map<String, dynamic> _userData = {
    'name': 'Ahmad Fauzi',
    'email': 'ahmad.fauzi@email.com',
    'phone': '+62 812 3456 7890',
    'role': 'Pilgrim',
    'joinDate': '15 Jan 2026',
    'subscription': 'Premium Pass',
  };

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              _buildHeader(isDark),
              _buildProfileCard(isDark),
              _buildMenuSection(isDark),
              _buildLogoutButton(isDark),
              const SizedBox(height: 32),
            ],
          ),
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
            Icons.person,
            color: AppColors.gold,
            size: 28,
          ),
          const SizedBox(width: AppSpacing.md),
          Text(
            'Profile',
            style: AppTypography.headlineMedium.copyWith(
              color: isDark ? AppColors.onSurfaceDark : AppColors.onSurfaceLight,
              fontWeight: FontWeight.w700,
            ),
          ),
          const Spacer(),
          IconButton(
            onPressed: () {},
            icon: Icon(
              Icons.edit,
              color: AppColors.gold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileCard(bool isDark) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.gold.withValues(alpha: 0.1),
            AppColors.gold.withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(
          color: AppColors.gold.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.gold, width: 3),
              color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
            ),
            child: Center(
              child: Text(
                _userData['name'][0].toUpperCase(),
                style: AppTypography.displaySmall.copyWith(
                  color: AppColors.gold,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            _userData['name'],
            style: AppTypography.headlineSmall.copyWith(
              color: isDark ? AppColors.onSurfaceDark : AppColors.onSurfaceLight,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.xs,
            ),
            decoration: BoxDecoration(
              color: AppColors.gold,
              borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
            ),
            child: Text(
              _userData['subscription'],
              style: AppTypography.labelSmall.copyWith(
                color: AppColors.primaryDark,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildStatItem('Role', _userData['role'], isDark),
              Container(
                width: 1,
                height: 40,
                color: isDark ? AppColors.dividerDark : AppColors.dividerLight,
              ),
              _buildStatItem('Bergabung', _userData['joinDate'], isDark),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, bool isDark) {
    return Column(
      children: [
        Text(
          value,
          style: AppTypography.bodyMedium.copyWith(
            color: AppColors.gold,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: AppTypography.labelSmall.copyWith(
            color: (isDark ? AppColors.onSurfaceDark : AppColors.onSurfaceLight)
                .withValues(alpha: 0.6),
          ),
        ),
      ],
    );
  }

  Widget _buildMenuSection(bool isDark) {
    return Container(
      margin: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        children: [
          _buildMenuItem(
            icon: Icons.person_outline,
            title: 'Edit Profile',
            subtitle: 'Ubah informasi pribadi',
            isDark: isDark,
          ),
          _buildMenuItem(
            icon: Icons.notifications_outlined,
            title: 'Notifikasi',
            subtitle: 'Pengaturan notifikasi',
            isDark: isDark,
          ),
          _buildMenuItem(
            icon: Icons.security_outlined,
            title: 'Keamanan',
            subtitle: 'Ubah password & PIN',
            isDark: isDark,
          ),
          _buildMenuItem(
            icon: Icons.credit_card_outlined,
            title: 'Langganan',
            subtitle: 'Kelola paket langganan',
            isDark: isDark,
          ),
          _buildMenuItem(
            icon: Icons.help_outline,
            title: 'Bantuan',
            subtitle: 'FAQ & kontak support',
            isDark: isDark,
          ),
          _buildMenuItem(
            icon: Icons.info_outline,
            title: 'Tentang',
            subtitle: 'Versi app & info lainnya',
            isDark: isDark,
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isDark,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.cardLight,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(
          color: isDark ? AppColors.dividerDark : AppColors.dividerLight,
        ),
      ),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.gold.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          ),
          child: Icon(
            icon,
            color: AppColors.gold,
            size: 20,
          ),
        ),
        title: Text(
          title,
          style: AppTypography.bodyMedium.copyWith(
            color: isDark ? AppColors.onSurfaceDark : AppColors.onSurfaceLight,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: AppTypography.bodySmall.copyWith(
            color: (isDark ? AppColors.onSurfaceDark : AppColors.onSurfaceLight)
                .withValues(alpha: 0.6),
          ),
        ),
        trailing: Icon(
          Icons.chevron_right,
          color: (isDark ? AppColors.onSurfaceDark : AppColors.onSurfaceLight)
              .withValues(alpha: 0.5),
        ),
        onTap: () {},
      ),
    );
  }

  Widget _buildLogoutButton(bool isDark) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: () {},
          icon: const Icon(Icons.logout, color: AppColors.error),
          label: Text(
            'Logout',
            style: AppTypography.labelLarge.copyWith(
              color: AppColors.error,
            ),
          ),
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: AppColors.error),
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            ),
          ),
        ),
      ),
    );
  }
}
