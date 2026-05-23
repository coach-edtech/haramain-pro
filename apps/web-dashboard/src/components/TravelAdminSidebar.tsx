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
      {isOpen && (
        <div 
          className="fixed inset-0 bg-black/50 z-40 lg:hidden"
          onClick={onClose}
        />
      )}
      <aside className={clsx(
        "w-64 bg-white border-r border-gray-200 flex flex-col fixed inset-y-0 left-0 z-50 transform transition-transform duration-300 lg:translate-x-0 lg:static lg:z-auto",
        isOpen ? "translate-x-0" : "-translate-x-full"
      )}>
        <div className="flex items-center justify-between p-4 border-b border-gray-200 lg:hidden">
          <h1 className="font-bold text-gray-900">Haramain Pro</h1>
          <button onClick={onClose} className="p-2 hover:bg-gray-100 rounded-lg">
            <X className="w-5 h-5" />
          </button>
        </div>
        <div className="hidden lg:block p-6 border-b border-gray-200">
          <div className="flex items-center gap-3">
            <div className="w-10 h-10 bg-gradient-to-br from-emerald-500 to-teal-600 rounded-lg flex items-center justify-center">
              <Shield className="w-6 h-6 text-white" />
            </div>
            <div>
              <h1 className="font-bold text-gray-900">Haramain Pro</h1>
              <p className="text-xs text-gray-500">{roleLabel}</p>
            </div>
          </div>
        </div>

      <nav className="flex-1 p-4 space-y-1">
        {travelAdminNavItems.map((item) => {
          const Icon = item.icon
          const isActive = location.pathname === item.path
          return (
            <Link
              key={item.path}
              to={item.path}
              className={clsx(
                'flex items-center gap-3 px-4 py-3 rounded-lg transition-colors',
                isActive 
                  ? 'bg-emerald-50 text-emerald-700 font-medium' 
                  : 'text-gray-600 hover:bg-gray-50'
              )}
            >
              <Icon className="w-5 h-5" />
              {item.label}
            </Link>
          )
        })}
      </nav>

      <div className="p-4 border-t border-gray-200">
        <p className="text-xs text-gray-400 text-center">v1.12 - Dashboard</p>
      </div>
      </aside>
    </>
  )
}
