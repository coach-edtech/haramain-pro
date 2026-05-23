import { Activity, Database, Server, Cloud, AlertTriangle, CheckCircle } from 'lucide-react'
import { PLATFORM_STATS } from '../../lib/mockData'

export default function SystemHealth() {
  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-2xl font-bold text-gray-900">System Health</h1>
        <p className="text-gray-500">Platform monitoring and diagnostics</p>
      </div>

      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
        <div className="card p-6">
          <div className="flex items-start justify-between">
            <div>
              <p className="text-sm text-gray-500 mb-1">Active Sessions</p>
              <p className="text-3xl font-bold text-gray-900">{PLATFORM_STATS.activeSessions}</p>
            </div>
            <div className="p-3 bg-blue-50 rounded-lg">
              <Activity className="w-6 h-6 text-blue-600" />
            </div>
          </div>
          <div className="mt-4 flex items-center gap-2">
            <div className="w-2 h-2 bg-emerald-500 rounded-full animate-pulse" />
            <span className="text-sm text-emerald-600">Live</span>
          </div>
        </div>

        <div className="card p-6">
          <div className="flex items-start justify-between">
            <div>
              <p className="text-sm text-gray-500 mb-1">DB Response</p>
              <p className="text-3xl font-bold text-gray-900">{PLATFORM_STATS.dbResponseTime}</p>
            </div>
            <div className="p-3 bg-purple-50 rounded-lg">
              <Database className="w-6 h-6 text-purple-600" />
            </div>
          </div>
          <p className="mt-4 text-sm text-gray-500">PostgreSQL on Supabase</p>
        </div>

        <div className="card p-6">
          <div className="flex items-start justify-between">
            <div>
              <p className="text-sm text-gray-500 mb-1">Edge Function Errors</p>
              <p className="text-3xl font-bold text-emerald-600">{PLATFORM_STATS.edgeFunctionErrors}</p>
            </div>
            <div className="p-3 bg-emerald-50 rounded-lg">
              <CheckCircle className="w-6 h-6 text-emerald-600" />
            </div>
          </div>
          <p className="mt-4 text-sm text-emerald-600">All systems operational</p>
        </div>

        <div className="card p-6">
          <div className="flex items-start justify-between">
            <div>
              <p className="text-sm text-gray-500 mb-1">FCM Delivery</p>
              <p className="text-3xl font-bold text-gray-900">{PLATFORM_STATS.fcmDeliveryRate}</p>
            </div>
            <div className="p-3 bg-amber-50 rounded-lg">
              <Cloud className="w-6 h-6 text-amber-600" />
            </div>
          </div>
          <p className="mt-4 text-sm text-gray-500">Firebase Cloud Messaging</p>
        </div>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        <div className="card p-6">
          <h2 className="text-lg font-semibold text-gray-900 mb-4">Service Status</h2>
          <div className="space-y-4">
            {[
              { name: 'Supabase Auth', status: 'operational', latency: '12ms' },
              { name: 'Supabase Database', status: 'operational', latency: '12ms' },
              { name: 'Firebase FCM', status: 'operational', latency: '45ms' },
              { name: 'Xendit Payment', status: 'operational', latency: '230ms' },
              { name: 'Edge Functions', status: 'operational', latency: '180ms' },
            ].map((service) => (
              <div key={service.name} className="flex items-center justify-between p-3 bg-gray-50 rounded-lg">
                <div className="flex items-center gap-3">
                  <div className="w-2 h-2 bg-emerald-500 rounded-full" />
                  <span className="font-medium text-gray-900">{service.name}</span>
                </div>
                <div className="flex items-center gap-4">
                  <span className="text-sm text-gray-500">{service.latency}</span>
                  <span className="text-xs text-emerald-600 bg-emerald-100 px-2 py-1 rounded-full">
                    {service.status}
                  </span>
                </div>
              </div>
            ))}
          </div>
        </div>

        <div className="card p-6">
          <h2 className="text-lg font-semibold text-gray-900 mb-4">Recent Incidents</h2>
          <div className="space-y-4">
            {[
              { date: '2026-05-12', description: 'FCM delivery delay resolved', severity: 'resolved' },
              { date: '2026-05-10', description: 'Database maintenance completed', severity: 'resolved' },
            ].map((incident, idx) => (
              <div key={idx} className="p-4 bg-gray-50 rounded-lg">
                <div className="flex items-center justify-between mb-2">
                  <span className="text-sm font-medium text-gray-900">{incident.date}</span>
                  <span className={`text-xs px-2 py-1 rounded-full ${
                    incident.severity === 'resolved' ? 'bg-emerald-100 text-emerald-700' : 'bg-yellow-100 text-yellow-700'
                  }`}>
                    {incident.severity}
                  </span>
                </div>
                <p className="text-sm text-gray-600">{incident.description}</p>
              </div>
            ))}
            {Array(3).fill(null).map((_, idx) => (
              <div key={`empty-${idx}`} className="h-20 bg-gray-50 rounded-lg opacity-50" />
            ))}
          </div>
        </div>
      </div>

      <div className="card p-6">
        <h2 className="text-lg font-semibold text-gray-900 mb-4">Quick Actions</h2>
        <div className="grid grid-cols-1 md:grid-cols-4 gap-4">
          <button className="p-4 bg-gray-50 hover:bg-gray-100 rounded-lg text-left transition-colors">
            <Server className="w-5 h-5 text-gray-600 mb-2" />
            <p className="font-medium text-gray-900">Restart Services</p>
            <p className="text-xs text-gray-500">Safe restart without data loss</p>
          </button>
          <button className="p-4 bg-gray-50 hover:bg-gray-100 rounded-lg text-left transition-colors">
            <Database className="w-5 h-5 text-gray-600 mb-2" />
            <p className="font-medium text-gray-900">Run Diagnostics</p>
            <p className="text-xs text-gray-500">Check all system health</p>
          </button>
          <button className="p-4 bg-gray-50 hover:bg-gray-100 rounded-lg text-left transition-colors">
            <AlertTriangle className="w-5 h-5 text-gray-600 mb-2" />
            <p className="font-medium text-gray-900">View Logs</p>
            <p className="text-xs text-gray-500">Edge function logs</p>
          </button>
          <button className="p-4 bg-gray-50 hover:bg-gray-100 rounded-lg text-left transition-colors">
            <Cloud className="w-5 h-5 text-gray-600 mb-2" />
            <p className="font-medium text-gray-900">FCM Stats</p>
            <p className="text-xs text-gray-500">Push notification metrics</p>
          </button>
        </div>
      </div>
    </div>
  )
}
