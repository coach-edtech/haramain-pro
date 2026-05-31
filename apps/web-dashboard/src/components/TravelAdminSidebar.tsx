import { Link, useLocation } from 'react-router-dom'
import { 
  LayoutDashboard, 
  Shield,
  CreditCard,
  Users,
  Bell,
  UserPlus,
  Package,
  X
} from 'lucide-react'
import clsx from 'clsx'
import { UserRole } from '../types'

interface TravelAdminSidebarProps {
  userRole: UserRole
  isOpen?: boolean
  onClose?: () => void
}

const travelAdminNavItems = [
  { path: '/travel-admin', label: 'Dashboard', icon: LayoutDashboard },
  { path: '/travel-admin/seat-licenses', label: 'Seat Licenses', icon: Shield },
  { path: '/travel-admin/payments', label: 'Payments', icon: CreditCard },
  { path: '/travel-admin/crm', label: 'CRM', icon: Users },
  { path: '/travel-admin/ota', label: 'OTA Updates', icon: Bell },
  { path: '/travel-admin/team', label: 'Team', icon: UserPlus },
  { path: '/travel-admin/agents', label: 'Sales Agents', icon: Package },
]

export default function TravelAdminSidebar({ userRole, isOpen, onClose }: TravelAdminSidebarProps) {
  const location = useLocation()

  const roleLabel = userRole === 'travel_admin' ? 'TravelAdmin' : 
                     userRole === 'team_support' ? 'Team Support' : 'Muthawif'

  return (
    <>
      {/* Mobile overlay */}
      {isOpen && (
        <div 
          className="fixed inset-0 bg-slate-900/60 backdrop-blur-sm z-40 lg:hidden"
          onClick={onClose}
        />
      )}
      <aside className={clsx(
        "w-64 bg-white border-r border-slate-200 flex flex-col fixed inset-y-0 left-0 z-50",
        "transform transition-transform duration-300 ease-out lg:translate-x-0 lg:static lg:z-auto",
        isOpen ? "translate-x-0" : "-translate-x-full"
      )}>
        {/* Mobile header */}
        <div className="flex items-center justify-between p-4 border-b border-slate-200 lg:hidden">
          <div className="flex items-center gap-3">
            <div className="w-10 h-10 bg-gradient-to-br from-primary-600 to-primary-700 rounded-lg flex items-center justify-center">
              <Shield className="w-6 h-6 text-white" />
            </div>
            <span className="font-bold text-slate-900">Haramain Pro</span>
          </div>
          <button 
            onClick={onClose} 
            className="p-2 hover:bg-slate-100 rounded-lg transition-colors"
            aria-label="Close sidebar"
          >
            <X className="w-5 h-5 text-slate-500" />
          </button>
        </div>

        {/* Desktop header */}
        <div className="hidden lg:block p-6 border-b border-slate-100">
          <div className="flex items-center gap-3">
            <div className="w-12 h-12 bg-gradient-to-br from-primary-600 to-primary-700 rounded-xl flex items-center justify-center shadow-lg">
              <Shield className="w-7 h-7 text-white" />
            </div>
            <div>
              <h1 className="font-bold text-slate-900 text-lg">Haramain Pro</h1>
              <p className="text-xs text-slate-500 mt-0.5">{roleLabel}</p>
            </div>
          </div>
        </div>

      <nav className="flex-1 p-4 space-y-1 overflow-y-auto">
        {travelAdminNavItems.map((item) => {
          const Icon = item.icon
          const isActive = location.pathname === item.path || 
            (item.path !== '/travel-admin' && location.pathname.startsWith(item.path))
          return (
            <Link
              key={item.path}
              to={item.path}
              onClick={onClose}
              className={clsx(
                'flex items-center gap-3 px-4 py-3 rounded-lg transition-all duration-200',
                isActive 
                  ? 'bg-primary-50 text-primary-700 font-medium border-l-4 border-primary-500' 
                  : 'text-slate-600 hover:bg-slate-50 hover:text-slate-900'
              )}
            >
              <Icon className="w-5 h-5 flex-shrink-0" />
              <span>{item.label}</span>
            </Link>
          )
        })}
      </nav>

      {/* Footer */}
      <div className="p-4 border-t border-slate-100">
        <div className="bg-slate-50 rounded-lg p-3">
          <div className="flex items-center gap-2 text-xs text-slate-500">
            <div className="w-2 h-2 bg-primary-500 rounded-full animate-pulse" />
            <span>System Operational</span>
          </div>
        </div>
        <p className="text-[10px] text-slate-400 text-center mt-3">v1.12 - Dashboard</p>
      </div>
      </aside>
    </>
  )
}
