import clsx from 'clsx'
import { LucideIcon } from 'lucide-react'

interface StatsCardProps {
  title: string
  value: string | number
  change?: string
  changeType?: 'positive' | 'negative'
  icon: LucideIcon
  color: 'primary' | 'danger' | 'warning' | 'success'
}

const colorMap = {
  primary: 'bg-primary-50 text-primary-600',
  danger: 'bg-red-50 text-danger',
  warning: 'bg-yellow-50 text-yellow-600',
  success: 'bg-green-50 text-green-600',
}

export default function StatsCard({ 
  title, 
  value, 
  change, 
  changeType, 
  icon: Icon, 
  color 
}: StatsCardProps) {
  return (
    <div className="card p-6">
      <div className="flex items-start justify-between">
        <div>
          <p className="text-sm text-gray-500 mb-1">{title}</p>
          <p className="text-3xl font-bold text-gray-900">{value}</p>
          {change && (
            <p className={clsx(
              'text-sm mt-1',
              changeType === 'positive' ? 'text-green-600' : 'text-red-600'
            )}>
              {change}
            </p>
          )}
        </div>
        <div className={clsx('p-3 rounded-lg', colorMap[color])}>
          <Icon className="w-6 h-6" />
        </div>
      </div>
    </div>
  )
}