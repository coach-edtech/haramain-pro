import { ReactNode, useState } from 'react'
import { useLocation } from 'react-router-dom'
import AdminSidebar from './AdminSidebar'
import TravelAdminSidebar from './TravelAdminSidebar'
import Header from './Header'
import { UserRole } from '../types'

interface LayoutProps {
  children: ReactNode
  userRole: UserRole
  userEmail: string
  userName: string
}

export default function Layout({ children, userRole, userEmail, userName }: LayoutProps) {
  const location = useLocation()
  const [sidebarOpen, setSidebarOpen] = useState(false)
  const isAdminRoute = location.pathname.startsWith('/admin')
  const isTravelAdminRoute = location.pathname.startsWith('/travel-admin')
  const showSidebar = isAdminRoute || isTravelAdminRoute

  const user = {
    email: userEmail,
    user_metadata: { name: userName },
  }

  return (
    <div className="min-h-screen bg-slate-50 flex">
      {showSidebar && (
        <>
          {isAdminRoute && (
            <AdminSidebar 
              userRole={userRole} 
              isOpen={sidebarOpen}
              onClose={() => setSidebarOpen(false)}
            />
          )}
          {isTravelAdminRoute && (
            <TravelAdminSidebar 
              userRole={userRole} 
              isOpen={sidebarOpen}
              onClose={() => setSidebarOpen(false)}
            />
          )}
        </>
      )}
      <div className="flex-1 flex flex-col min-w-0">
        <Header 
          user={user} 
          onToggleSidebar={showSidebar ? () => setSidebarOpen(!sidebarOpen) : undefined} 
        />
        <main className="flex-1 p-4 lg:p-6 overflow-x-hidden overflow-auto">
          <div className="max-w-7xl mx-auto animate-fade-in">
            {children}
          </div>
        </main>
      </div>
    </div>
  )
}
