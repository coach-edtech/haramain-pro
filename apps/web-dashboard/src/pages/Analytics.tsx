import { BarChart3, TrendingUp, Users, AlertTriangle } from 'lucide-react'

export default function Analytics() {
  // Placeholder data - would connect to Supabase analytics
  const metrics = [
    { label: 'Total Users', value: '1,234', change: '+8%', icon: Users },
    { label: 'Active Rombongans', value: '12', change: '+2', icon: BarChart3 },
    { label: 'Panic Alerts (30d)', value: '23', change: '-15%', icon: AlertTriangle },
    { label: 'Response Time', value: '28s', change: '-12%', icon: TrendingUp },
  ]

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-2xl font-bold text-gray-900">Analytics</h1>
        <p className="text-gray-500">Track performance and usage metrics</p>
      </div>

      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
        {metrics.map((metric) => {
          const Icon = metric.icon
          return (
            <div key={metric.label} className="card p-6">
              <div className="flex items-center justify-between mb-4">
                <div className="p-2 bg-primary-50 rounded-lg">
                  <Icon className="w-5 h-5 text-primary-600" />
                </div>
                <span className="text-green-600 text-sm font-medium">{metric.change}</span>
              </div>
              <p className="text-2xl font-bold text-gray-900">{metric.value}</p>
              <p className="text-sm text-gray-500">{metric.label}</p>
            </div>
          )
        })}
      </div>

      <div className="card p-6">
        <h2 className="text-lg font-semibold text-gray-900 mb-4">Usage Over Time</h2>
        <div className="h-64 bg-gray-50 rounded-lg flex items-center justify-center text-gray-400">
          Chart would render here with real data from Supabase
        </div>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        <div className="card p-6">
          <h2 className="text-lg font-semibold text-gray-900 mb-4">Top Rombongans</h2>
          <div className="space-y-3">
            {['Makkah Express 2026', 'Madinah Comfort', 'Premium Umrah'].map((name) => (
              <div key={name} className="flex items-center justify-between">
                <span className="text-gray-700">{name}</span>
                <span className="text-gray-500">{Math.floor(Math.random() * 50 + 20)} users</span>
              </div>
            ))}
          </div>
        </div>

        <div className="card p-6">
          <h2 className="text-lg font-semibold text-gray-900 mb-4">Alert Response</h2>
          <div className="space-y-3">
            <div className="flex items-center justify-between">
              <span className="text-gray-700">Average Response</span>
              <span className="font-medium text-gray-900">&lt; 30 seconds</span>
            </div>
            <div className="flex items-center justify-between">
              <span className="text-gray-700">Resolution Rate</span>
              <span className="font-medium text-gray-900">100%</span>
            </div>
            <div className="flex items-center justify-between">
              <span className="text-gray-700">False Alarms</span>
              <span className="font-medium text-gray-900">2%</span>
            </div>
          </div>
        </div>
      </div>
    </div>
  )
}