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
  { path: '/admin/seat-licenses', label: 'Seat Licenses', icon: Shield },
  { path: '/admin/travels', label: 'Travels', icon: Globe },
  { path: '/admin/billing', label: 'Billing', icon: CreditCard, requireBilling: true },
  { path: '/admin/users', label: 'Users', icon: Users },
  { path: '/admin/system', label: 'System', icon: Activity },
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
      {/* Mobile overlay */}
      {isOpen && (
        <div 
          className="fixed inset-0 bg-slate-900/60 backdrop-blur-sm z-40 lg:hidden"
          onClick={onClose}
        />
      )}
      
      {/* Sidebar */}
      <aside className={clsx(
        "w-64 bg-slate-900 text-white flex flex-col fixed inset-y-0 left-0 z-50",
        "transform transition-transform duration-300 ease-out lg:translate-x-0 lg:static lg:z-auto",
        isOpen ? "translate-x-0" : "-translate-x-full"
      )}>
        {/* Mobile header */}
        <div className="flex items-center justify-between p-4 border-b border-slate-700 lg:hidden">
          <div className="flex items-center gap-3">
            <div className="w-10 h-10 bg-gradient-to-br from-accent-500 to-accent-600 rounded-lg flex items-center justify-center">
              <Shield className="w-6 h-6 text-white" />
            </div>
            <span className="font-bold text-white">Haramain Pro</span>
          </div>
          <button 
            onClick={onClose} 
            className="p-2 hover:bg-slate-800 rounded-lg transition-colors"
            aria-label="Close sidebar"
          >
            <X className="w-5 h-5" />
          </button>
        </div>

        {/* Desktop header */}
        <div className="hidden lg:block p-6 border-b border-slate-700">
          <div className="flex items-center gap-3">
            <div className="w-12 h-12 bg-gradient-to-br from-accent-500 to-accent-600 rounded-xl flex items-center justify-center shadow-lg">
              <Shield className="w-7 h-7 text-white" />
            </div>
            <div>
              <h1 className="font-bold text-white text-lg">Haramain Pro</h1>
              <p className="text-xs text-slate-400 mt-0.5">{roleLabel}</p>
            </div>
          </div>
        </div>

        {/* Navigation */}
        <nav className="flex-1 p-4 space-y-1 overflow-y-auto">
          {filteredNavItems.map((item) => {
            const Icon = item.icon
            const isActive = location.pathname === item.path || 
              (item.path !== '/admin' && location.pathname.startsWith(item.path))
            
            return (
              <Link
                key={item.path}
                to={item.path}
                onClick={onClose}
                className={clsx(
                  'sidebar-item',
                  isActive ? 'sidebar-item-active' : ''
                )}
              >
                <Icon className="w-5 h-5 flex-shrink-0" />
                <span className="font-medium">{item.label}</span>
              </Link>
            )
          })}
        </nav>

        {/* Footer */}
        <div className="p-4 border-t border-slate-700">
          <div className="bg-slate-800 rounded-lg p-3">
            <div className="flex items-center gap-2 text-xs text-slate-400">
              <div className="w-2 h-2 bg-primary-500 rounded-full animate-pulse" />
              <span>System Operational</span>
            </div>
          </div>
          <p className="text-[10px] text-slate-500 text-center mt-3">v1.12 - Dashboard</p>
        </div>
      </aside>
    </>
  )
}
