import { Shield, Users, CreditCard, Activity, AlertTriangle, TrendingUp, Globe, Clock } from 'lucide-react'
import StatsCard from '../../components/StatsCard'
import useAdminSystemStats from '../../hooks/useAdminSystemStats'

interface Activity {
  id: number
  type: 'new_travel' | 'panic_alert' | 'license_purchase' | 'user_signup'
  message: string
  time: string
}

export default function AdminDashboard() {
  const {
    totalSeatLicenses,
    activeJamaah,
    totalRevenue,
    activeRombongans,
    pendingPayments,
    loading,
    error,
    refetch,
  } = useAdminSystemStats()

  // Mock activity feed - in production this would come from a hook/API
  const activities: Activity[] = [
    { id: 1, type: 'new_travel', message: 'Al-Mabrur Travel registered as new partner', time: '2 hours ago' },
    { id: 2, type: 'panic_alert', message: 'Panic alert #8821 acknowledged by Muthawif Ahmad', time: '4 hours ago' },
    { id: 3, type: 'license_purchase', message: 'Mekkah Wisata purchased 50 seat licenses', time: '6 hours ago' },
    { id: 4, type: 'user_signup', message: '12 new Jamaah registered today', time: '8 hours ago' },
    { id: 5, type: 'license_purchase', message: 'Nurul Ilmi Travel renewed 100 seat licenses', time: '1 day ago' },
  ]

  const formatRevenue = (amount: number): string => {
    if (amount >= 1000000000) return `Rp ${(amount / 1000000000).toFixed(1)}B`
    if (amount >= 1000000) return `Rp ${(amount / 1000000).toFixed(1)}M`
    if (amount >= 1000) return `Rp ${(amount / 1000).toFixed(1)}K`
    return `Rp ${amount.toLocaleString()}`
  }

  const getActivityIcon = (type: Activity['type']) => {
    switch (type) {
      case 'new_travel': return <Globe className="w-4 h-4 text-accent-600" />
      case 'panic_alert': return <AlertTriangle className="w-4 h-4 text-danger-600" />
      case 'license_purchase': return <Shield className="w-4 h-4 text-primary-600" />
      case 'user_signup': return <Users className="w-4 h-4 text-blue-600" />
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
          <AlertTriangle className="w-12 h-12 text-danger-600 mx-auto mb-4" />
          <p className="text-slate-900 font-medium">{error}</p>
          <button
            onClick={refetch}
            className="mt-4 btn-primary"
          >
            Retry
          </button>
        </div>
      </div>
    )
  }

  return (
    <div className="space-y-6">
      {/* Page Header */}
      <div className="page-header">
        <h1 className="page-title">SuperAdmin Dashboard</h1>
        <p className="page-subtitle">Platform-wide overview and key metrics</p>
      </div>

      {/* Stats Grid */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
        <StatsCard
          title="Total Seat Licenses"
          value={totalSeatLicenses.toLocaleString()}
          change="+8% from last month"
          changeType="positive"
          icon={Shield}
          color="warning"
        />
        <StatsCard
          title="Active Jamaah"
          value={activeJamaah.toLocaleString()}
          icon={Users}
          color="primary"
          subtitle="Across all travels"
        />
        <StatsCard
          title="Total Revenue"
          value={formatRevenue(totalRevenue)}
          change="+12% from last month"
          changeType="positive"
          icon={CreditCard}
          color="success"
        />
        <StatsCard
          title="Pending Payments"
          value={pendingPayments}
          icon={AlertTriangle}
          color={pendingPayments > 0 ? 'danger' : 'success'}
          subtitle={pendingPayments > 0 ? 'Requires attention' : 'All clear'}
        />
      </div>

      {/* Charts Row */}
      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        {/* Seat License Usage */}
        <div className="card p-6">
          <div className="flex items-center justify-between mb-4">
            <div className="flex items-center gap-3">
              <div className="p-2 bg-accent-100 rounded-lg">
                <Shield className="w-5 h-5 text-accent-600" />
              </div>
              <div>
                <h2 className="text-lg font-semibold text-slate-900">Seat License Usage</h2>
                <p className="text-sm text-slate-500">Platform-wide consumption</p>
              </div>
            </div>
          </div>
          <div className="space-y-4">
            <div className="flex justify-between text-sm">
              <span className="text-slate-600">32,450 / 46,000 seats</span>
              <span className="font-medium text-accent-600">70.5%</span>
            </div>
            <div className="w-full bg-slate-100 rounded-full h-3">
              <div 
                className="bg-gradient-to-r from-primary-500 to-primary-600 h-3 rounded-full transition-all duration-500"
                style={{ width: '70%' }}
              />
            </div>
            <div className="flex justify-between text-xs text-slate-400">
              <span>Used: 32,450</span>
              <span>Available: 13,550</span>
            </div>
          </div>
        </div>

        {/* Active Rombongans */}
        <div className="card p-6">
          <div className="flex items-center gap-3 mb-4">
            <div className="p-2 bg-primary-100 rounded-lg">
              <TrendingUp className="w-5 h-5 text-primary-600" />
            </div>
            <div>
              <h2 className="text-lg font-semibold text-slate-900">Active Rombongans</h2>
              <p className="text-sm text-slate-500">Travel groups</p>
            </div>
          </div>
          <div className="text-center py-6">
            <p className="text-5xl font-bold text-slate-900">{activeRombongans}</p>
            <p className="text-sm text-slate-500 mt-1">active travel groups</p>
          </div>
          <div className="mt-4 pt-4 border-t border-slate-100">
            <div className="flex items-center justify-between text-sm">
              <span className="text-slate-600">Avg. group size</span>
              <span className="font-medium text-slate-900">24 Jamaah</span>
            </div>
          </div>
        </div>

        {/* System Health Summary */}
        <div className="card p-6">
          <div className="flex items-center gap-3 mb-4">
            <div className="p-2 bg-emerald-100 rounded-lg">
              <Activity className="w-5 h-5 text-emerald-600" />
            </div>
            <div>
              <h2 className="text-lg font-semibold text-slate-900">System Health</h2>
              <p className="text-sm text-slate-500">Current status</p>
            </div>
          </div>
          <div className="space-y-3">
            <div className="flex items-center justify-between p-2 bg-slate-50 rounded-lg">
              <span className="text-sm text-slate-600">Database</span>
              <span className="badge badge-success">Healthy</span>
            </div>
            <div className="flex items-center justify-between p-2 bg-slate-50 rounded-lg">
              <span className="text-sm text-slate-600">Edge Functions</span>
              <span className="badge badge-success">Operational</span>
            </div>
            <div className="flex items-center justify-between p-2 bg-slate-50 rounded-lg">
              <span className="text-sm text-slate-600">FCM Delivery</span>
              <span className="badge badge-success">98.5%</span>
            </div>
          </div>
          <div className="mt-4 flex items-center gap-2 pt-4 border-t border-slate-100">
            <div className="w-2 h-2 bg-primary-500 rounded-full animate-pulse" />
            <span className="text-sm text-primary-600 font-medium">All systems operational</span>
          </div>
        </div>
      </div>

      {/* Activity Feed */}
      <div className="card p-6">
        <div className="flex items-center justify-between mb-4">
          <div className="flex items-center gap-3">
            <div className="p-2 bg-slate-100 rounded-lg">
              <Clock className="w-5 h-5 text-slate-600" />
            </div>
            <h2 className="text-lg font-semibold text-slate-900">Recent Activity</h2>
          </div>
          <button className="text-sm text-accent-600 hover:text-accent-700 font-medium">
            View All
          </button>
        </div>
        <div className="space-y-3">
          {activities.map((activity) => (
            <div 
              key={activity.id} 
              className="flex items-start gap-3 p-3 bg-slate-50 rounded-lg hover:bg-slate-100 transition-colors"
            >
              <div className="p-2 bg-white rounded-lg shadow-sm">
                {getActivityIcon(activity.type)}
              </div>
              <div className="flex-1 min-w-0">
                <p className="text-sm text-slate-900">{activity.message}</p>
                <p className="text-xs text-slate-400 mt-0.5">{activity.time}</p>
              </div>
            </div>
          ))}
        </div>
      </div>
    </div>
  )
}
