import { Link, useLocation } from 'react-router-dom'
import { 
  LayoutDashboard, 
  Shield, 
  Users, 
  CreditCard,
  Activity,
  Globe,
  X
} from 'lucide-react'
import clsx from 'clsx'
import { UserRole } from '../types'
import { canAccessBilling } from '../lib/auth'

interface AdminSidebarProps {
  userRole: UserRole
  isOpen?: boolean
  onClose?: () => void
}

const adminNavItems = [
  { path: '/admin', label: 'Dashboard', icon: LayoutDashboard },
  { path: '/admin/seat-licenses', label: 'Seat Licenses', icon: Shield, requireBilling: false },
  { path: '/admin/travels', label: 'Travels', icon: Globe },
  { path: '/admin/billing', label: 'Billing & Invoices', icon: CreditCard, requireBilling: true },
  { path: '/admin/users', label: 'Users', icon: Users },
  { path: '/admin/system', label: 'System Health', icon: Activity },
]

export default function AdminSidebar({ userRole, isOpen, onClose }: AdminSidebarProps) {
  const location = useLocation()

  const filteredNavItems = adminNavItems.filter(item => {
    if (item.requireBilling && !canAccessBilling(userRole)) return false
    return true
  })

  const roleLabel = userRole === 'super_admin' ? 'SuperAdmin' : 'Admin HaramainPro'

  return (
    <>
      {isOpen && (
        <div 
          className="fixed inset-0 bg-black/50 z-40 lg:hidden"
          onClick={onClose}
        />
      )}
      <aside className={clsx(
        "w-64 bg-gray-900 text-white flex flex-col fixed inset-y-0 left-0 z-50 transform transition-transform duration-300 lg:translate-x-0 lg:static lg:z-auto",
        isOpen ? "translate-x-0" : "-translate-x-full"
      )}>
        <div className="flex items-center justify-between p-4 border-b border-gray-700 lg:hidden">
          <h1 className="font-bold text-white">Haramain Pro</h1>
          <button onClick={onClose} className="p-2 hover:bg-gray-800 rounded-lg">
            <X className="w-5 h-5" />
          </button>
        </div>
        <div className="hidden lg:block p-6 border-b border-gray-700">
          <div className="flex items-center gap-3">
            <div className="w-10 h-10 bg-gradient-to-br from-amber-500 to-orange-600 rounded-lg flex items-center justify-center">
              <Shield className="w-6 h-6 text-white" />
            </div>
            <div>
              <h1 className="font-bold text-white">Haramain Pro</h1>
              <p className="text-xs text-gray-400">{roleLabel}</p>
            </div>
          </div>
        </div>

      <nav className="flex-1 p-4 space-y-1">
        {filteredNavItems.map((item) => {
          const Icon = item.icon
          const isActive = location.pathname === item.path
          return (
            <Link
              key={item.path}
              to={item.path}
              className={clsx(
                'flex items-center gap-3 px-4 py-3 rounded-lg transition-colors',
                isActive 
                  ? 'bg-amber-500/20 text-amber-400 font-medium' 
                  : 'text-gray-300 hover:bg-gray-800'
              )}
            >
              <Icon className="w-5 h-5" />
              {item.label}
            </Link>
          )
        })}
      </nav>

      <div className="p-4 border-t border-gray-700">
        <p className="text-xs text-gray-500 text-center">v1.12 - Dashboard</p>
      </div>
      </aside>
    </>
  )
}
