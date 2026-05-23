import { useState, useEffect } from 'react'
import { supabase } from '../lib/supabase'
import type { PanicAlert } from '../types'
import { CheckCircle, XCircle, Clock } from 'lucide-react'

export default function PanicAlerts() {
  const [alerts, setAlerts] = useState<PanicAlert[]>([])
  const [loading, setLoading] = useState(true)
  const [filter, setFilter] = useState<'all' | 'pending' | 'resolved'>('all')

  useEffect(() => {
    fetchAlerts()
  }, [filter])

  const fetchAlerts = async () => {
    try {
      let query = supabase
        .from('panic_alerts')
        .select('*')
        .order('timestamp', { ascending: false })

      if (filter !== 'all') {
        query = query.eq('status', filter)
      }

      const { data, error } = await query

      if (error) throw error
      setAlerts(data || [])
    } catch (error) {
      console.error('Error fetching alerts:', error)
    } finally {
      setLoading(false)
    }
  }

  const updateAlertStatus = async (id: string, status: string) => {
    try {
      const { error } = await supabase
        .from('panic_alerts')
        .update({ 
          status,
          responded_at: new Date().toISOString()
        })
        .eq('id', id)

      if (error) throw error
      fetchAlerts()
    } catch (error) {
      console.error('Error updating alert:', error)
    }
  }

  const statusConfig = {
    pending: { icon: Clock, color: 'text-yellow-600', bg: 'bg-yellow-100' },
    responded: { icon: CheckCircle, color: 'text-blue-600', bg: 'bg-blue-100' },
    resolved: { icon: CheckCircle, color: 'text-green-600', bg: 'bg-green-100' },
    cancelled: { icon: XCircle, color: 'text-gray-600', bg: 'bg-gray-100' },
  }

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-2xl font-bold text-gray-900">Panic Alerts</h1>
        <p className="text-gray-500">Monitor and respond to emergency alerts</p>
      </div>

      <div className="flex gap-2">
        {(['all', 'pending', 'resolved'] as const).map((f) => (
          <button
            key={f}
            onClick={() => setFilter(f)}
            className={`px-4 py-2 rounded-lg text-sm font-medium transition-colors ${
              filter === f
                ? 'bg-primary-600 text-white'
                : 'bg-white text-gray-600 hover:bg-gray-50'
            }`}
          >
            {f.charAt(0).toUpperCase() + f.slice(1)}
          </button>
        ))}
      </div>

      <div className="card">
        {loading ? (
          <div className="p-6 text-center">Loading...</div>
        ) : alerts.length === 0 ? (
          <div className="p-6 text-center text-gray-500">
            No panic alerts found.
          </div>
        ) : (
          <div className="divide-y divide-gray-100">
            {alerts.map((alert) => {
              const config = statusConfig[alert.status]
              const Icon = config.icon
              return (
                <div key={alert.id} className="p-4">
                  <div className="flex items-start justify-between">
                    <div className="flex items-start gap-4">
                      <div className={`p-2 rounded-full ${config.bg}`}>
                        <Icon className={`w-5 h-5 ${config.color}`} />
                      </div>
                      <div>
                        <p className="font-medium text-gray-900">
                          Alert from {alert.jamaah_id.slice(0, 8)}...
                        </p>
                        <p className="text-sm text-gray-500 mt-1">
                          Location: {alert.latitude.toFixed(4)}, {alert.longitude.toFixed(4)}
                        </p>
                        <p className="text-sm text-gray-500">
                          {new Date(alert.timestamp).toLocaleString()}
                        </p>
                      </div>
                    </div>
                    <div className="flex items-center gap-2">
                      {alert.status === 'pending' && (
                        <>
                          <button
                            onClick={() => updateAlertStatus(alert.id, 'responded')}
                            className="px-3 py-1.5 bg-blue-600 text-white text-sm rounded-lg hover:bg-blue-700"
                          >
                            Respond
                          </button>
                          <button
                            onClick={() => updateAlertStatus(alert.id, 'resolved')}
                            className="px-3 py-1.5 bg-green-600 text-white text-sm rounded-lg hover:bg-green-700"
                          >
                            Resolve
                          </button>
                        </>
                      )}
                      <span className={`px-3 py-1 rounded-full text-xs font-medium ${config.bg} ${config.color}`}>
                        {alert.status}
                      </span>
                    </div>
                  </div>
                </div>
              )
            })}
          </div>
        )}
      </div>
    </div>
  )
}