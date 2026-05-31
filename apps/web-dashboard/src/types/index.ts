export type UserRole = 'super_admin' | 'admin_haramain_pro' | 'travel_admin' | 'team_support' | 'muthawif' | 'jamaah' | 'jamaah_mandiri'

export interface Profile {
  id: string
  email: string
  name: string
  phone?: string
  role: UserRole
  subscription_tier: 'trial' | 'active' | 'expired'
  created_at: string
  agency_id?: string
  group_name?: string
  status?: 'active' | 'inactive' | 'suspended'
  last_seen?: string
}

export interface Rombongan {
  id: string
  agency_id: string
  name: string
  start_date: string
  end_date: string
  status: 'planned' | 'active' | 'completed'
  muthawif_id?: string | null
  muthawif_name?: string | null
  created_at: string
}

export interface PanicAlert {
  id: string
  jamaah_id: string
  grup_id: string
  latitude: number
  longitude: number
  timestamp: string
  status: 'pending' | 'responded' | 'resolved' | 'cancelled'
  responded_by?: string
  responded_at?: string
}

export interface BroadcastLog {
  id: string
  group_id: string
  sender_id: string
  message: string
  sent_at: string
}

export interface DashboardStats {
  totalJamaah: number
  activeRombongans: number
  panicAlertsToday: number
  pendingBroadcasts: number
}

export interface SeatLicense {
  id: string
  agency_id: string
  license_key: string
  romongan_id: string | null
  total_seats: number
  used_seats: number
  balance: number
  valid_until: string | null
  created_at: string
  // UI-only computed fields (not stored in DB)
  agency_name?: string
  last_purchase?: string
  status?: 'active' | 'low_stock' | 'depleted'
}

export interface Travel {
  id: string
  name: string
  email: string
  phone: string
  license_count: number
  active_jamaah: number
  status: 'active' | 'suspended'
  created_at: string
}

export interface Invoice {
  id: string
  travel_id: string
  travel_name: string
  amount: number
  seat_count: number
  status: 'pending' | 'paid' | 'overdue'
  due_date: string
  created_at: string
}

export interface RedeemCode {
  id: string
  code: string
  agency_id: string
  used_by?: string
  used_at?: string
  status: 'available' | 'used' | 'expired'
  expires_at: string
}

export interface Jamaah {
  id: string
  name: string
  email: string
  phone: string
  passport_number?: string
  travel_id: string
  group_name: string
  status: 'active' | 'inactive' | 'suspended'
  join_date: string
  last_active: string
  // Extra fields from profiles table
  agency_id?: string
  romongan_id?: string
}

export interface TeamMember {
  id: string
  name: string
  email: string
  role: 'team_support' | 'muthawif'
  status: 'active' | 'pending'
  invited_at: string
}

export interface SalesAgent {
  id: string
  name: string
  email: string
  phone: string
  referral_code: string
  total_sales: number
  active_jamaah: number
  joined_at: string
}

export interface OTAVersion {
  id: string
  version: string
  platform: 'ios' | 'android'
  release_notes: string
  status: 'draft' | 'published' | 'deprecated'
  published_at?: string
  created_at: string
}

export interface Payment {
  id: string
  travel_id: string
  amount: number
  type: 'seat_license' | 'renewal' | 'addon'
  status: 'pending' | 'completed' | 'failed'
  xendit_invoice_id?: string
  created_at: string
}

export interface Album {
  id: string
  perjalanan_id: string
  title: string
  photo_count: number
  created_at: string
}

export interface Review {
  id: string
  profile_id: string
  rating: number
  comment: string
  travel_id: string
  created_at: string
}

export interface EmiPlan {
  id: string
  romongan_id: string
  name: string
  total_amount: number
  down_payment: number
  tenor_months: number
  monthly_amount: number
  interest_rate: number
  status: 'active' | 'completed' | 'cancelled'
  start_date: string
  end_date: string
  created_at: string
}

export interface Package {
  id: string
  romongan_id: string
  name: string
  description: string
  price: number
  capacity: number
  included_services: string[]
  created_at: string
}
