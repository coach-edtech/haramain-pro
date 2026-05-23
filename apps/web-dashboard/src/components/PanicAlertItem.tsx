import { CheckCircle, XCircle, Clock } from 'lucide-react'
import type { PanicAlert } from '../types'

interface PanicAlertItemProps {
  alert: PanicAlert
  onRespond?: (id: string) => void
  onResolve?: (id: string) => void
}

const statusConfig = {
  pending: { icon: Clock, color: 'text-yellow-600', bg: 'bg-yellow-100' },
  responded: { icon: CheckCircle, color: 'text-blue-600', bg: 'bg-blue-100' },
  resolved: { icon: CheckCircle, color: 'text-green-600', bg: 'bg-green-100' },
  cancelled: { icon: XCircle, color: 'text-gray-600', bg: 'bg-gray-100' },
}

export default function PanicAlertItem({ alert, onRespond, onResolve }: PanicAlertItemProps) {
  const config = statusConfig[alert.status]
  const Icon = config.icon

  return (
    <div className="p-4 border-b border-gray-100 last:border-b-0">
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
              {onRespond && (
                <button
                  onClick={() => onRespond(alert.id)}
                  className="px-3 py-1.5 bg-blue-600 text-white text-sm rounded-lg hover:bg-blue-700"
                >
                  Respond
                </button>
              )}
              {onResolve && (
                <button
                  onClick={() => onResolve(alert.id)}
                  className="px-3 py-1.5 bg-green-600 text-white text-sm rounded-lg hover:bg-green-700"
                >
                  Resolve
                </button>
              )}
            </>
          )}
          <span className={`px-3 py-1 rounded-full text-xs font-medium ${config.bg} ${config.color}`}>
            {alert.status}
          </span>
        </div>
      </div>
    </div>
  )
}