import { UserRole } from '../types'

export const ROLE_LABELS: Record<UserRole, string> = {
  super_admin: 'SuperAdmin',
  admin_haramain_pro: 'Admin HaramainPro',
  travel_admin: 'TravelAdmin',
  team_support: 'Team Support',
  muthawif: 'Muthawif',
  jamaah: 'Jamaah',
  jamaah_mandiri: 'Jamaah Mandiri',
}

export function canAccessAdmin(role: UserRole): boolean {
  return role === 'super_admin' || role === 'admin_haramain_pro'
}

export function canAccessBilling(role: UserRole): boolean {
  return role === 'super_admin'
}

export function canAccessSeatLicenseManagement(role: UserRole): boolean {
  return role === 'super_admin' || role === 'travel_admin'
}

export function canManageTravels(role: UserRole): boolean {
  return role === 'super_admin'
}

export function getDefaultRouteForRole(role: UserRole): string {
  switch (role) {
    case 'super_admin':
    case 'admin_haramain_pro':
      return '/admin'
    case 'travel_admin':
    case 'team_support':
    case 'muthawif':
      return '/travel-admin'
    default:
      return '/'
  }
}

export function getRoleFromMockRole(mockRole: string): UserRole {
  const roleMap: Record<string, UserRole> = {
    'super_admin': 'super_admin',
    'admin': 'admin_haramain_pro',
    'travel_admin': 'travel_admin',
    'agency': 'travel_admin',
    'team_support': 'team_support',
    'muthawif': 'muthawif',
    'pilgrim': 'jamaah',
    'jamaah': 'jamaah',
  }
  return roleMap[mockRole.toLowerCase()] || 'jamaah'
}

export const MOCK_USERS: Record<string, { role: UserRole; name: string; email: string }> = {
  'super@haramain.pro': {
    role: 'super_admin',
    name: 'Coach Chaidir',
    email: 'super@haramain.pro',
  },
  'admin@haramain.pro': {
    role: 'admin_haramain_pro',
    name: 'Ops Admin',
    email: 'admin@haramain.pro',
  },
  'travel@example.com': {
    role: 'travel_admin',
    name: 'PT Umrah Berkah',
    email: 'travel@example.com',
  },
}

export function getMockUser(email: string) {
  return MOCK_USERS[email.toLowerCase()] || null
}

export function useMockAuth() {
  return {
    getMockUser,
    getRoleFromMockRole,
    getDefaultRouteForRole,
    canAccessAdmin,
    canAccessBilling,
    canAccessSeatLicenseManagement,
    canManageTravels,
  }
}
