import { useState, useEffect } from 'react'
import { supabase } from '../../lib/supabase'
import StatsCard from '../../components/StatsCard'
import { Users, Package, AlertTriangle, CreditCard } from 'lucide-react'
import type { DashboardStats, PanicAlert } from '../../types'

export default function TravelAdminDashboard() {
  const [stats, setStats] = useState<DashboardStats>({
    totalJamaah: 0,
    activeRombongans: 0,
    panicAlertsToday: 0,
    pendingBroadcasts: 0,
  })
  const [recentAlerts, setRecentAlerts] = useState<PanicAlert[]>([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)

  useEffect(() => {
    fetchDashboardData()
  }, [])

  const fetchDashboardData = async () => {
    try {
      setError(null)

      const today = new Date().toISOString().split('T')[0]

      const [
        pilgrimsRes,
        romonganRes,
        panicRes,
      ] = await Promise.all([
        supabase.from('profiles').select('id', { count: 'exact', head: true }).eq('role', 'jamaah'),
        supabase.from('rombongans').select('id', { count: 'exact', head: true }).eq('status', 'active'),
        supabase.from('panic_alerts').select('id', { count: 'exact', head: true }).gte('created_at', today),
      ])

      setStats({
        totalJamaah: pilgrimsRes.count || 0,
        activeRombongans: romonganRes.count || 0,
        panicAlertsToday: panicRes.count || 0,
        pendingBroadcasts: 0,
      })

      // Fetch recent panic alerts
      const { data: alerts } = await supabase
        .from('panic_alerts')
        .select('*')
        .order('created_at', { ascending: false })
        .limit(5)

      setRecentAlerts(alerts || [])
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
        <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-emerald-600"></div>
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
            className="mt-4 px-4 py-2 bg-emerald-600 text-white rounded-lg hover:bg-emerald-700"
          >
            Retry
          </button>
        </div>
      </div>
    )
  }

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-2xl font-bold text-gray-900">Dashboard</h1>
        <p className="text-gray-500">Welcome back, Travel Admin</p>
      </div>

      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
        <StatsCard
          title="Total Jamaah"
          value={stats.totalJamaah}
          change="+5% from last month"
          changeType="positive"
          icon={Users}
          color="primary"
        />
        <StatsCard
          title="Active Groups"
          value={stats.activeRombongans}
          icon={Package}
          color="success"
        />
        <StatsCard
          title="Panic Alerts Today"
          value={stats.panicAlertsToday}
          icon={AlertTriangle}
          color="danger"
        />
        <StatsCard
          title="Pending Broadcasts"
          value={stats.pendingBroadcasts}
          icon={CreditCard}
          color="warning"
        />
      </div>

      {recentAlerts.length > 0 && (
        <div className="card">
          <div className="p-6 border-b border-gray-200">
            <h2 className="text-lg font-semibold text-gray-900">Recent Panic Alerts</h2>
          </div>
          <div className="divide-y divide-gray-100">
            {recentAlerts.map((alert) => (
              <div key={alert.id} className="p-4 flex items-center justify-between">
                <div className="flex items-center gap-4">
                  <div className="w-10 h-10 bg-red-100 rounded-full flex items-center justify-center">
                    <AlertTriangle className="w-5 h-5 text-red-600" />
                  </div>
                  <div>
                    <p className="font-medium text-gray-900">
                      {alert.status === 'pending' ? 'Active Alert' : alert.status}
                    </p>
                    <p className="text-sm text-gray-500">
                      {new Date(alert.timestamp).toLocaleString()}
                    </p>
                  </div>
                </div>
                <span className={`px-3 py-1 rounded-full text-xs font-medium ${
                  alert.status === 'pending'
                    ? 'bg-red-100 text-red-700'
                    : 'bg-green-100 text-green-700'
                }`}>
                  {alert.status}
                </span>
              </div>
            ))}
          </div>
        </div>
      )}

      <div className="card p-6">
        <div className="flex items-center gap-3 mb-4">
          <CreditCard className="w-5 h-5 text-emerald-600" />
          <h2 className="text-lg font-semibold text-gray-900">Quick Stats</h2>
        </div>
        <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
          <div className="bg-gray-50 rounded-lg p-4">
            <p className="text-sm text-gray-500">Total Jamaah</p>
            <p className="text-xl font-bold text-gray-900">{stats.totalJamaah}</p>
          </div>
          <div className="bg-gray-50 rounded-lg p-4">
            <p className="text-sm text-gray-500">Active Groups</p>
            <p className="text-xl font-bold text-emerald-600">{stats.activeRombongans}</p>
          </div>
          <div className="bg-gray-50 rounded-lg p-4">
            <p className="text-sm text-gray-500">Panic Alerts Today</p>
            <p className="text-xl font-bold text-gray-900">{stats.panicAlertsToday}</p>
          </div>
          <div className="bg-gray-50 rounded-lg p-4">
            <p className="text-sm text-gray-500">System Status</p>
            <p className="text-xl font-bold text-green-600">Operational</p>
          </div>
        </div>
      </div>
    </div>
  )
}
