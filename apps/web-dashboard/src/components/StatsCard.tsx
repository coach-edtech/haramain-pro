import clsx from 'clsx'
import { LucideIcon } from 'lucide-react'
import { TrendingUp, TrendingDown } from 'lucide-react'

interface StatsCardProps {
  title: string
  value: string | number
  change?: string
  changeType?: 'positive' | 'negative'
  icon: LucideIcon
  color: 'primary' | 'danger' | 'warning' | 'success' | 'info'
  subtitle?: string
}

const colorMap = {
  primary: {
    bg: 'bg-primary-50',
    text: 'text-primary-600',
    icon: 'bg-primary-100 text-primary-600',
  },
  success: {
    bg: 'bg-emerald-50',
    text: 'text-emerald-600',
    icon: 'bg-emerald-100 text-emerald-600',
  },
  warning: {
    bg: 'bg-accent-50',
    text: 'text-accent-600',
    icon: 'bg-accent-100 text-accent-600',
  },
  danger: {
    bg: 'bg-danger-50',
    text: 'text-danger-600',
    icon: 'bg-danger-100 text-danger-600',
  },
  info: {
    bg: 'bg-blue-50',
    text: 'text-blue-600',
    icon: 'bg-blue-100 text-blue-600',
  },
}

export default function StatsCard({ 
  title, 
  value, 
  change, 
  changeType, 
  icon: Icon, 
  color,
  subtitle
}: StatsCardProps) {
  const colors = colorMap[color]

  return (
    <div className="card p-6 hover:shadow-elevated transition-shadow duration-200">
      <div className="flex items-start justify-between">
        <div className="flex-1">
          <p className="text-sm font-medium text-slate-500 mb-1">{title}</p>
          <p className="text-3xl font-bold text-slate-900">{value}</p>
          {subtitle && (
            <p className="text-xs text-slate-400 mt-1">{subtitle}</p>
          )}
          {change && (
            <div className={clsx(
              'flex items-center gap-1 mt-2 text-sm',
              changeType === 'positive' ? 'text-primary-600' : 'text-danger-600'
            )}>
              {changeType === 'positive' ? (
                <TrendingUp className="w-4 h-4" />
              ) : (
                <TrendingDown className="w-4 h-4" />
              )}
              <span>{change}</span>
            </div>
          )}
        </div>
        <div className={clsx('p-3 rounded-xl', colors.icon)}>
          <Icon className="w-6 h-6" />
        </div>
      </div>
    </div>
  )
}
