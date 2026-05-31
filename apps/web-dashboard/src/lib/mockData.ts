import type { SeatLicense, Travel, Invoice, Jamaah, RedeemCode, TeamMember, SalesAgent, OTAVersion, Payment, Album, Review, PanicAlert } from '../types'

export const mockSeatLicenses: SeatLicense[] = [
  { id: 'lic-1', agency_id: 't1', license_key: 'LIC-UMRAH-001', romongan_id: null, total_seats: 100, used_seats: 67, balance: 33, valid_until: '2027-12-31', created_at: '2026-01-10', agency_name: 'PT Umrah Berkah', last_purchase: '2026-05-10', status: 'active' },
  { id: 'lic-2', agency_id: 't2', license_key: 'LIC-MUSLIM-002', romongan_id: null, total_seats: 50, used_seats: 48, balance: 2, valid_until: '2027-12-31', created_at: '2026-01-08', agency_name: 'CV Muslim Travel', last_purchase: '2026-05-08', status: 'low_stock' },
  { id: 'lic-3', agency_id: 't3', license_key: 'LIC-AMANAH-003', romongan_id: null, total_seats: 200, used_seats: 145, balance: 55, valid_until: '2027-12-31', created_at: '2026-01-12', agency_name: 'PT Amanah Tours', last_purchase: '2026-05-12', status: 'active' },
  { id: 'lic-4', agency_id: 't4', license_key: 'LIC-EXPRESS-004', romongan_id: null, total_seats: 30, used_seats: 30, balance: 0, valid_until: '2027-12-31', created_at: '2026-01-20', agency_name: 'Umrah Express', last_purchase: '2026-04-20', status: 'depleted' },
  { id: 'lic-5', agency_id: 't5', license_key: 'LIC-HIDAYAH-005', romongan_id: null, total_seats: 75, used_seats: 42, balance: 33, valid_until: '2027-12-31', created_at: '2026-01-01', agency_name: 'Hidayah Travels', last_purchase: '2026-05-01', status: 'active' },
]

export const mockTravels: Travel[] = [
  { id: 't1', name: 'PT Umrah Berkah', email: 'info@umrahberkah.co.id', phone: '021-1234567', license_count: 100, active_jamaah: 67, status: 'active', created_at: '2025-01-15' },
  { id: 't2', name: 'CV Muslim Travel', email: 'cs@muslimtravel.id', phone: '021-7654321', license_count: 50, active_jamaah: 48, status: 'active', created_at: '2025-03-20' },
  { id: 't3', name: 'PT Amanah Tours', email: 'amanah@tours.co.id', phone: '021-9876543', license_count: 200, active_jamaah: 145, status: 'active', created_at: '2024-11-01' },
  { id: 't4', name: 'Umrah Express', email: 'booking@umrahexpress.com', phone: '021-5551234', license_count: 30, active_jamaah: 30, status: 'suspended', created_at: '2025-06-10' },
  { id: 't5', name: 'Hidayah Travels', email: 'hidayah@travel.co.id', phone: '021-3334444', license_count: 75, active_jamaah: 42, status: 'active', created_at: '2025-02-28' },
]

export const mockInvoices: Invoice[] = [
  { id: 'inv1', travel_id: 't1', travel_name: 'PT Umrah Berkah', amount: 12000000, seat_count: 100, status: 'paid', due_date: '2026-05-15', created_at: '2026-05-01' },
  { id: 'inv2', travel_id: 't2', travel_name: 'CV Muslim Travel', amount: 6000000, seat_count: 50, status: 'pending', due_date: '2026-05-20', created_at: '2026-05-08' },
  { id: 'inv3', travel_id: 't3', travel_name: 'PT Amanah Tours', amount: 24000000, seat_count: 200, status: 'paid', due_date: '2026-05-25', created_at: '2026-05-12' },
  { id: 'inv4', travel_id: 't4', travel_name: 'Umrah Express', amount: 3600000, seat_count: 30, status: 'overdue', due_date: '2026-04-30', created_at: '2026-04-15' },
  { id: 'inv5', travel_id: 't5', travel_name: 'Hidayah Travels', amount: 9000000, seat_count: 75, status: 'pending', due_date: '2026-05-28', created_at: '2026-05-10' },
]

export const mockJamaah: (Jamaah & { role: string })[] = [
  { id: 'j1', name: 'Ahmad Fauzi', email: 'ahmad.fauzi@email.com', phone: '081234567890', travel_id: 't1', group_name: 'Grup Badr', status: 'active', join_date: '2026-01-15', last_active: '2026-05-14', role: 'jamaah' },
  { id: 'j2', name: 'Siti Nurhaliza', email: 'siti.n@email.com', phone: '081234567891', travel_id: 't1', group_name: 'Grup Badr', status: 'active', join_date: '2026-02-01', last_active: '2026-05-13', role: 'jamaah' },
  { id: 'j3', name: 'Budi Santoso', email: 'budi.s@email.com', phone: '081234567892', travel_id: 't2', group_name: 'Grup Cahaya', status: 'active', join_date: '2026-03-10', last_active: '2026-05-12', role: 'jamaah' },
  { id: 'j4', name: 'Dewi Lestari', email: 'dewi.l@email.com', phone: '081234567893', travel_id: 't3', group_name: 'Grup Muthawwir', status: 'inactive', join_date: '2025-12-01', last_active: '2026-04-20', role: 'jamaah' },
  { id: 'j5', name: 'Hasanuddin', email: 'hasan.u@email.com', phone: '081234567894', travel_id: 't1', group_name: 'Grup Badr', status: 'active', join_date: '2026-04-15', last_active: '2026-05-14', role: 'jamaah' },
  { id: 'j6', name: 'Admin Travel', email: 'admin@travel.com', phone: '081234567895', travel_id: 't1', group_name: 'PT Umrah Berkah', status: 'active', join_date: '2025-01-15', last_active: '2026-05-14', role: 'travel_admin' },
  { id: 'j7', name: 'Team Support', email: 'support@travel.com', phone: '081234567896', travel_id: 't1', group_name: 'PT Umrah Berkah', status: 'active', join_date: '2025-06-01', last_active: '2026-05-14', role: 'team_support' },
]

export const mockRedeemCodes: RedeemCode[] = [
  { id: 'rc1', code: 'HRA001', agency_id: 't1', used_by: 'j1', used_at: '2026-05-01', status: 'used', expires_at: '2026-06-01' },
  { id: 'rc2', code: 'HRA002', agency_id: 't1', used_by: 'j2', used_at: '2026-05-02', status: 'used', expires_at: '2026-06-02' },
  { id: 'rc3', code: 'HRA003', agency_id: 't1', status: 'available', expires_at: '2026-06-10' },
  { id: 'rc4', code: 'HRA004', agency_id: 't1', status: 'available', expires_at: '2026-06-10' },
  { id: 'rc5', code: 'HRA005', agency_id: 't1', status: 'expired', expires_at: '2026-05-01' },
]

export const mockTeamMembers: TeamMember[] = [
  { id: 'tm1', name: 'Ustadz Abdullah', email: 'abdullah@travel.com', role: 'muthawif', status: 'active', invited_at: '2026-01-10' },
  { id: 'tm2', name: 'Pak Rahman', email: 'rahman@travel.com', role: 'team_support', status: 'active', invited_at: '2026-02-15' },
  { id: 'tm3', name: 'Bu Aminah', email: 'aminah@travel.com', role: 'team_support', status: 'pending', invited_at: '2026-05-10' },
  { id: 'tm4', name: 'Ustadz Faruq', email: 'faruq@travel.com', role: 'muthawif', status: 'active', invited_at: '2026-03-01' },
]

export const mockSalesAgents: SalesAgent[] = [
  { id: 'sa1', name: 'Andi Wijaya', email: 'andi@email.com', phone: '081298765432', referral_code: 'AW2026', total_sales: 25, active_jamaah: 23, joined_at: '2026-01-05' },
  { id: 'sa2', name: 'Rina Susilowati', email: 'rina.s@email.com', phone: '081298765433', referral_code: 'RS2026', total_sales: 18, active_jamaah: 16, joined_at: '2026-02-20' },
  { id: 'sa3', name: 'Dedi Kurniawan', email: 'dedi.k@email.com', phone: '081298765434', referral_code: 'DK2026', total_sales: 12, active_jamaah: 11, joined_at: '2026-03-15' },
  { id: 'sa4', name: 'Maya Sari', email: 'maya.s@email.com', phone: '081298765435', referral_code: 'MS2026', total_sales: 8, active_jamaah: 7, joined_at: '2026-04-01' },
]

export const mockOTAVersions: OTAVersion[] = [
  { id: 'ota1', version: '2.1.0', platform: 'android', release_notes: 'Performance improvements and bug fixes', status: 'published', published_at: '2026-05-10', created_at: '2026-05-08' },
  { id: 'ota2', version: '2.0.5', platform: 'ios', release_notes: 'UI improvements and crash fixes', status: 'published', published_at: '2026-05-05', created_at: '2026-05-03' },
  { id: 'ota3', version: '2.2.0-beta', platform: 'android', release_notes: 'New panic alert feature', status: 'draft', created_at: '2026-05-12' },
  { id: 'ota4', version: '1.9.0', platform: 'android', release_notes: 'Legacy version', status: 'deprecated', created_at: '2026-01-01' },
]

export const mockPayments: Payment[] = [
  { id: 'pay1', travel_id: 't1', amount: 12000000, type: 'seat_license', status: 'completed', xendit_invoice_id: 'INV-001', created_at: '2026-05-01' },
  { id: 'pay2', travel_id: 't1', amount: 2400000, type: 'addon', status: 'completed', xendit_invoice_id: 'INV-002', created_at: '2026-04-15' },
  { id: 'pay3', travel_id: 't1', amount: 6000000, type: 'seat_license', status: 'pending', created_at: '2026-05-10' },
  { id: 'pay4', travel_id: 't1', amount: 1200000, type: 'renewal', status: 'failed', created_at: '2026-05-08' },
]

export const mockAlbums: Album[] = [
  { id: 'alb1', perjalanan_id: 'p1', title: 'Grup Badr - Mei 2026', photo_count: 45, created_at: '2026-05-12' },
  { id: 'alb2', perjalanan_id: 'p2', title: 'Grup Cahaya - April 2026', photo_count: 78, created_at: '2026-04-28' },
  { id: 'alb3', perjalanan_id: 'p3', title: 'Grup Muthawwir - Maret 2026', photo_count: 120, created_at: '2026-03-15' },
]

export const mockReviews: Review[] = [
  { id: 'rev1', profile_id: 'j1', rating: 5, comment: 'Pelayanan sangat memuaskan, muthawif的专业!', travel_id: 't1', created_at: '2026-05-13' },
  { id: 'rev2', profile_id: 'j2', rating: 4, comment: 'Good experience, hotel dekat Masjidil Haram', travel_id: 't1', created_at: '2026-05-12' },
  { id: 'rev3', profile_id: 'j3', rating: 5, comment: 'Umrah terasa sangat nyaman dengan aplikasi ini', travel_id: 't2', created_at: '2026-05-10' },
]

export const mockPanicAlerts: PanicAlert[] = [
  { id: 'pa1', jamaah_id: 'j1', grup_id: 'p1', latitude: 21.4225, longitude: 39.8262, timestamp: '2026-05-15T08:30:00Z', status: 'resolved', responded_by: 'tm1', responded_at: '2026-05-15T08:32:00Z' },
  { id: 'pa2', jamaah_id: 'j3', grup_id: 'p2', latitude: 21.3891, longitude: 39.8579, timestamp: '2026-05-14T14:20:00Z', status: 'pending' },
]

export const PLATFORM_STATS = {
  totalSeatsSold: 455,
  totalSeatsUsed: 332,
  totalRevenue: 54600000000,
  totalTravels: 12,
  totalJamaah: 332,
  activeUsers: 285,
  systemHealth: 'operational',
  dbResponseTime: '12ms',
  fcmDeliveryRate: '99.7%',
  edgeFunctionErrors: 0,
  activeSessions: 142,
}
