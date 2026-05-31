import 'package:flutter/material.dart';
import '../../../design/tokens/app_colors.dart';
import '../../../design/tokens/app_typography.dart';
import '../../../design/tokens/app_spacing.dart';

/// SalesAgent Home Screen as per FRONTEND-SPEC.md Section 4.3
/// Layout:
///   - Home (prospect stats)
///   - Prospects
///   - Content Bank
///   - Katalog
///   - Earnings
class SalesAgentHomeScreen extends StatefulWidget {
  final String agentId;
  final String agentName;
  final int totalProspects;
  final int activeDeals;
  final double totalEarnings;
  final List<Map<String, dynamic>> recentProspects;

  const SalesAgentHomeScreen({
    super.key,
    required this.agentId,
    required this.agentName,
    this.totalProspects = 0,
    this.activeDeals = 0,
    this.totalEarnings = 0,
    this.recentProspects = const [],
  });

  @override
  State<SalesAgentHomeScreen> createState() => _SalesAgentHomeScreenState();
}

class _SalesAgentHomeScreenState extends State<SalesAgentHomeScreen> {
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
              _buildQuickActions(),
              if (widget.recentProspects.isNotEmpty) _buildRecentProspects(),
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
            widget.agentName,
            style: AppTypography.headlineMedium.copyWith(
              color: Colors.white,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              const Icon(
                Icons.trending_up,
                size: 14,
                color: AppColors.emerald100,
              ),
              const SizedBox(width: AppSpacing.xs),
              Text(
                'Sales Agent',
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.emerald100,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              const Icon(
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

  Widget _buildStatsSection() {
    return Container(
      margin: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  icon: Icons.people,
                  value: '${widget.totalProspects}',
                  label: 'Total Prospects',
                  color: AppColors.amber500,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: _StatCard(
                  icon: Icons.handshake,
                  value: '${widget.activeDeals}',
                  label: 'Deal Aktif',
                  color: AppColors.emerald500,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          _EarningsCard(
            totalEarnings: widget.totalEarnings,
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Aksi Cepat',
            style: AppTypography.titleMedium.copyWith(
              color: AppColors.slate900,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: _QuickActionCard(
                  icon: Icons.person_add,
                  label: 'Tambah Prospect',
                  color: AppColors.emerald500,
                  onTap: () {
                    Navigator.pushNamed(context, '/prospects/add');
                  },
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: _QuickActionCard(
                  icon: Icons.content_copy,
                  label: 'Content Bank',
                  color: AppColors.amber500,
                  onTap: () {
                    Navigator.pushNamed(context, '/content-bank');
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: _QuickActionCard(
                  icon: Icons.inventory_2,
                  label: 'Katalog',
                  color: AppColors.emerald700,
                  onTap: () {
                    Navigator.pushNamed(context, '/catalog');
                  },
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: _QuickActionCard(
                  icon: Icons.account_balance_wallet,
                  label: 'Earnings',
                  color: AppColors.amber600,
                  onTap: () {
                    Navigator.pushNamed(context, '/earnings');
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRecentProspects() {
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
                  Icons.history,
                  size: 18,
                  color: AppColors.emerald700,
                ),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  'Prospect Terbaru',
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
            itemCount: widget.recentProspects.length > 5 ? 5 : widget.recentProspects.length,
            separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
            itemBuilder: (context, index) {
              final prospect = widget.recentProspects[index];
              return _ProspectTile(
                name: prospect['name'] ?? '',
                travelName: prospect['travel_name'] ?? '',
                status: prospect['status'] ?? 'cold',
                onTap: () {
                  Navigator.pushNamed(
                    context,
                    '/prospect-detail',
                    arguments: {'prospectId': prospect['id']},
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
          ),
        ],
      ),
    );
  }
}

class _EarningsCard extends StatelessWidget {
  final double totalEarnings;

  const _EarningsCard({required this.totalEarnings});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.emerald900, AppColors.emerald700],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        boxShadow: [
          BoxShadow(
            color: AppColors.emerald700.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppColors.emerald600.withValues(alpha: 0.3),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.account_balance_wallet,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Total Earnings',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.emerald100,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Rp ${totalEarnings.toStringAsFixed(0)}',
                  style: AppTypography.headlineMedium.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.arrow_forward_ios,
            color: AppColors.emerald100,
            size: 18,
          ),
        ],
      ),
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.icon,
    required this.label,
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
          color: AppColors.cardLight,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          border: Border.all(color: AppColors.slate200, width: 1),
        ),
        child: Column(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              label,
              style: AppTypography.labelMedium.copyWith(
                color: AppColors.slate900,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _ProspectTile extends StatelessWidget {
  final String name;
  final String travelName;
  final String status;
  final VoidCallback onTap;

  const _ProspectTile({
    required this.name,
    required this.travelName,
    required this.status,
    required this.onTap,
  });

  Color _getStatusColor() {
    switch (status) {
      case 'hot':
        return AppColors.red600;
      case 'warm':
        return AppColors.amber500;
      case 'cold':
      default:
        return AppColors.slate400;
    }
  }

  String _getStatusLabel() {
    switch (status) {
      case 'hot':
        return 'Hot';
      case 'warm':
        return 'Warm';
      case 'cold':
      default:
        return 'Cold';
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.cardLight,
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          border: Border.all(color: AppColors.slate200, width: 1),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.slate100,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  name.split(' ').map((e) => e.isNotEmpty ? e[0] : '').take(2).join(),
                  style: AppTypography.titleSmall.copyWith(
                    color: AppColors.slate700,
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
                color: _getStatusColor().withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
              ),
              child: Text(
                _getStatusLabel(),
                style: AppTypography.labelSmall.copyWith(
                  color: _getStatusColor(),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
