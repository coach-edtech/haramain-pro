import 'package:flutter/material.dart';
import '../../../design/tokens/app_colors.dart';
import '../../../design/tokens/app_typography.dart';
import '../../../design/tokens/app_spacing.dart';

/// Custom Bottom Navigation Bar as per FRONTEND-SPEC.md Section 4.2
/// Items: 4 (adjustable per role)
/// Style: white background, icons + labels, emerald-600 when active
/// Height: 64dp + safe area
/// Behavior: Cross-fade between tabs, no page jump
class BottomNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;
  final List<NavItem> items;

  const BottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(items.length, (index) {
              final item = items[index];
              final isActive = index == currentIndex;
              
              return Expanded(
                child: GestureDetector(
                  onTap: () => onTap(index),
                  behavior: HitTestBehavior.opaque,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 200),
                          child: Icon(
                            isActive ? item.activeIcon : item.icon,
                            key: ValueKey(isActive),
                            color: isActive
                                ? AppColors.emerald700
                                : AppColors.slate600,
                            size: 24,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          item.label,
                          style: AppTypography.labelSmall.copyWith(
                            color: isActive
                                ? AppColors.emerald700
                                : AppColors.slate600,
                            fontWeight: isActive
                                ? FontWeight.w600
                                : FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

/// Navigation item definition
class NavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final String route;

  const NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.route,
  });
}

/// Jamaah role navigation items
const List<NavItem> jamaahNavItems = [
  NavItem(
    icon: Icons.home_outlined,
    activeIcon: Icons.home,
    label: 'Home',
    route: '/home',
  ),
  NavItem(
    icon: Icons.groups_outlined,
    activeIcon: Icons.groups,
    label: 'Groups',
    route: '/groups',
  ),
  NavItem(
    icon: Icons.photo_library_outlined,
    activeIcon: Icons.photo_library,
    label: 'Album',
    route: '/album',
  ),
  NavItem(
    icon: Icons.person_outline,
    activeIcon: Icons.person,
    label: 'Profile',
    route: '/profile',
  ),
];

/// Muthawif role navigation items
const List<NavItem> muthawifNavItems = [
  NavItem(
    icon: Icons.home_outlined,
    activeIcon: Icons.home,
    label: 'Home',
    route: '/home',
  ),
  NavItem(
    icon: Icons.groups_outlined,
    activeIcon: Icons.groups,
    label: 'Groups',
    route: '/groups',
  ),
  NavItem(
    icon: Icons.camera_alt_outlined,
    activeIcon: Icons.camera_alt,
    label: 'Camera',
    route: '/camera',
  ),
  NavItem(
    icon: Icons.person_outline,
    activeIcon: Icons.person,
    label: 'Profile',
    route: '/profile',
  ),
];

/// Team Support role navigation items
const List<NavItem> teamSupportNavItems = [
  NavItem(
    icon: Icons.home_outlined,
    activeIcon: Icons.home,
    label: 'Home',
    route: '/home',
  ),
  NavItem(
    icon: Icons.groups_outlined,
    activeIcon: Icons.groups,
    label: 'Groups',
    route: '/groups',
  ),
  NavItem(
    icon: Icons.support_agent_outlined,
    activeIcon: Icons.support_agent,
    label: 'Support',
    route: '/support',
  ),
  NavItem(
    icon: Icons.person_outline,
    activeIcon: Icons.person,
    label: 'Profile',
    route: '/profile',
  ),
];

/// Sales Agent role navigation items
const List<NavItem> salesAgentNavItems = [
  NavItem(
    icon: Icons.home_outlined,
    activeIcon: Icons.home,
    label: 'Home',
    route: '/home',
  ),
  NavItem(
    icon: Icons.trending_up_outlined,
    activeIcon: Icons.trending_up,
    label: 'Prospects',
    route: '/prospects',
  ),
  NavItem(
    icon: Icons.inventory_2_outlined,
    activeIcon: Icons.inventory_2,
    label: 'Catalog',
    route: '/catalog',
  ),
  NavItem(
    icon: Icons.person_outline,
    activeIcon: Icons.person,
    label: 'Profile',
    route: '/profile',
  ),
];
