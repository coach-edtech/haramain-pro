import { useState, useEffect } from 'react'
import { supabase } from '../../lib/supabase'
import StatsCard from '../../components/StatsCard'
import { Shield, Users, CreditCard, Activity, AlertTriangle, TrendingUp } from 'lucide-react'

interface AdminStats {
  totalSeatLicenses: number
  activeJamaah: number
  totalRevenue: number
  activeRombongans: number
  pendingPayments: number
}

export default function AdminDashboard() {
  const [stats, setStats] = useState<AdminStats>({
    totalSeatLicenses: 0,
    activeJamaah: 0,
    totalRevenue: 0,
    activeRombongans: 0,
    pendingPayments: 0,
  })
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)

  useEffect(() => {
    fetchDashboardData()
  }, [])

  const fetchDashboardData = async () => {
    try {
      setError(null)

      // Fetch all stats in parallel
      const [
        seatLicensesRes,
        pilgrimsRes,
        romonganRes,
        revenueRes,
        pendingPaymentsRes,
      ] = await Promise.all([
        supabase.from('seat_licenses').select('id', { count: 'exact', head: true }),
        supabase.from('profiles').select('id', { count: 'exact', head: true }).eq('role', 'pilgrim'),
        supabase.from('rombongans').select('id', { count: 'exact', head: true }).eq('status', 'active'),
        supabase.from('payments').select('amount').eq('status', 'settlement'),
        supabase.from('payments').select('id', { count: 'exact', head: true }).eq('status', 'pending'),
      ])

      // Calculate total revenue from settled payments
      const totalRevenue = revenueRes.data?.reduce((sum, p) => sum + (p.amount || 0), 0) || 0

      setStats({
        totalSeatLicenses: seatLicensesRes.count || 0,
        activeJamaah: pilgrimsRes.count || 0,
        activeRombongans: romonganRes.count || 0,
        totalRevenue,
        pendingPayments: pendingPaymentsRes.count || 0,
      })
    } catch (err) {
      console.error('Error fetching dashboard data:', err)
      setError('Failed to load dashboard data. Please try again.')
    } finally {
      setLoading(false)
    }
  }

  if (loading) {
    return (
      <div className="flex items-center justify-center h-64">
        <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-primary-600"></div>
      </div>
    )
  }

  if (error) {
    return (
      <div className="flex items-center justify-center h-64">
        <div className="text-center">
          <AlertTriangle className="w-12 h-12 text-red-500 mx-auto mb-4" />
          <p className="text-gray-900 font-medium">{error}</p>
          <button
            onClick={fetchDashboardData}
            className="mt-4 px-4 py-2 bg-primary-600 text-white rounded-lg hover:bg-primary-700"
          >
            Retry
          </button>
        </div>
      </div>
    )
  }

  const formatRevenue = (amount: number): string => {
    if (amount >= 1000000000) return `Rp ${(amount / 1000000000).toFixed(1)}B`
    if (amount >= 1000000) return `Rp ${(amount / 1000000).toFixed(1)}M`
    if (amount >= 1000) return `Rp ${(amount / 1000).toFixed(1)}K`
    return `Rp ${amount.toLocaleString()}`
  }

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-2xl font-bold text-gray-900">SuperAdmin Dashboard</h1>
        <p className="text-gray-500">Platform-wide overview and key metrics</p>
      </div>

      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
        <StatsCard
          title="Total Seat Licenses"
          value={stats.totalSeatLicenses}
          change="+8% from last month"
          changeType="positive"
          icon={Shield}
          color="primary"
        />
        <StatsCard
          title="Active Jamaah"
          value={stats.activeJamaah}
          icon={Users}
          color="success"
        />
        <StatsCard
          title="Total Revenue"
          value={formatRevenue(stats.totalRevenue)}
          change="+12% from last month"
          changeType="positive"
          icon={CreditCard}
          color="warning"
        />
        <StatsCard
          title="Pending Payments"
          value={stats.pendingPayments}
          icon={AlertTriangle}
          color={stats.pendingPayments > 0 ? 'danger' : 'success'}
        />
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        <div className="card p-6">
          <div className="flex items-center gap-3 mb-4">
            <TrendingUp className="w-5 h-5 text-amber-600" />
            <h2 className="text-lg font-semibold text-gray-900">Active Rombongans</h2>
          </div>
          <div className="text-center py-8">
            <p className="text-4xl font-bold text-gray-900">{stats.activeRombongans}</p>
            <p className="text-sm text-gray-500 mt-1">active travel groups</p>
          </div>
        </div>

        <div className="card p-6">
          <div className="flex items-center gap-3 mb-4">
            <Activity className="w-5 h-5 text-emerald-600" />
            <h2 className="text-lg font-semibold text-gray-900">System Health</h2>
          </div>
          <div className="grid grid-cols-2 gap-4">
            <div className="bg-gray-50 rounded-lg p-4">
              <p className="text-sm text-gray-500">Profiles</p>
              <p className="text-xl font-bold text-gray-900">{stats.activeJamaah}</p>
            </div>
            <div className="bg-gray-50 rounded-lg p-4">
              <p className="text-sm text-gray-500">Revenue</p>
              <p className="text-xl font-bold text-emerald-600">{formatRevenue(stats.totalRevenue)}</p>
            </div>
            <div className="bg-gray-50 rounded-lg p-4">
              <p className="text-sm text-gray-500">Seat Licenses</p>
              <p className="text-xl font-bold text-gray-900">{stats.totalSeatLicenses}</p>
            </div>
            <div className="bg-gray-50 rounded-lg p-4">
              <p className="text-sm text-gray-500">Pending Payments</p>
              <p className="text-xl font-bold text-amber-600">{stats.pendingPayments}</p>
            </div>
          </div>
          <div className="mt-4 flex items-center gap-2">
            <div className="w-3 h-3 bg-emerald-500 rounded-full animate-pulse" />
            <span className="text-sm text-gray-600">All systems operational</span>
          </div>
        </div>
      </div>
    </div>
  )
}
