import { BrowserRouter, Routes, Route, Navigate } from 'react-router-dom'
import { useState, useEffect } from 'react'
import { QueryClient, QueryClientProvider } from '@tanstack/react-query'
import { supabase } from './lib/supabase'
import { UserRole } from './types'
import Layout from './components/Layout'
import ProtectedRoute from './components/ProtectedRoute'
import Login from './pages/Login'

import AdminDashboard from './pages/admin/Dashboard'
import SeatLicensesAdmin from './pages/admin/SeatLicenses'
import TravelsAdmin from './pages/admin/Travels'
import BillingAdmin from './pages/admin/Billing'
import UsersAdmin from './pages/admin/Users'
import SystemHealth from './pages/admin/System'
import JamaahPage from './pages/Jamaah'

import TravelAdminDashboard from './pages/travel-admin/Dashboard'
import SeatLicensesTravelAdmin from './pages/travel-admin/SeatLicenses'
import PaymentsTravelAdmin from './pages/travel-admin/Payments'
import CRMTravelAdmin from './pages/travel-admin/CRM'
import OTATravelAdmin from './pages/travel-admin/OTA'
import TeamTravelAdmin from './pages/travel-admin/Team'
import AgentsTravelAdmin from './pages/travel-admin/Agents'

function AppContent() {
  const [session, setSession] = useState<any>(null)
  const [loading, setLoading] = useState(true)
  // Default to null — no role until verified from server. Defaulting to super_admin was a security hole.
  const [userRole, setUserRole] = useState<UserRole | null>(null)
  const [userName, setUserName] = useState<string>('')

  useEffect(() => {
    supabase.auth.getSession().then(({ data: { session } }) => {
      setSession(session)
      setLoading(false)
    })

    const { data: { subscription } } = supabase.auth.onAuthStateChange((_event, session) => {
      setSession(session)
    })

    return () => subscription.unsubscribe()
  }, [])

  // Fetch real role from Supabase profiles — the authoritative source.
  // MOCK_USERS bypass removed: role must come from the database, never from hardcoded maps.
  useEffect(() => {
    async function fetchRealRole() {
      if (!session?.user?.id) return

      const { data: profile } = await supabase
        .from('profiles')
        .select('role, name')
        .eq('id', session.user.id)
        .single()

      if (profile) {
        setUserRole(profile.role as UserRole)
        setUserName(profile.name || session.user.email || '')
      } else {
        // No profile row — default to jamaah_mandiri (lowest privilege), don't expose as super_admin
        setUserRole('jamaah_mandiri')
        setUserName(session.user.email || '')
      }
    }

    fetchRealRole()
  }, [session])

  if (loading) {
    return (
      <div className="min-h-screen flex items-center justify-center bg-gray-100">
        <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-primary-600"></div>
      </div>
    )
  }

  if (!session) {
    return <Login />
  }

  // Still loading role from server — show spinner
  if (userRole === null) {
    return (
      <div className="min-h-screen flex items-center justify-center bg-gray-100">
        <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-primary-600"></div>
      </div>
    )
  }

  return (
    <Layout
      userRole={userRole}
      userEmail={session.user.email}
      userName={userName}
    >
      <Routes>
        <Route path="/" element={<Navigate to="/travel-admin" replace />} />

        <Route path="/travel-admin" element={
          <ProtectedRoute allowedRoles={['travel_admin', 'team_support', 'muthawif']}>
            <TravelAdminDashboard />
          </ProtectedRoute>
        } />
        <Route path="/travel-admin/seat-licenses" element={
          <ProtectedRoute allowedRoles={['travel_admin']}>
            <SeatLicensesTravelAdmin />
          </ProtectedRoute>
        } />
        <Route path="/travel-admin/payments" element={
          <ProtectedRoute allowedRoles={['travel_admin', 'team_support']}>
            <PaymentsTravelAdmin />
          </ProtectedRoute>
        } />
        <Route path="/travel-admin/crm" element={
          <ProtectedRoute allowedRoles={['travel_admin', 'team_support', 'muthawif']}>
            <CRMTravelAdmin />
          </ProtectedRoute>
        } />
        <Route path="/travel-admin/ota" element={
          <ProtectedRoute allowedRoles={['travel_admin']}>
            <OTATravelAdmin />
          </ProtectedRoute>
        } />
        <Route path="/travel-admin/team" element={
          <ProtectedRoute allowedRoles={['travel_admin', 'team_support']}>
            <TeamTravelAdmin />
          </ProtectedRoute>
        } />
        <Route path="/travel-admin/agents" element={
          <ProtectedRoute allowedRoles={['travel_admin']}>
            <AgentsTravelAdmin />
          </ProtectedRoute>
        } />

        <Route path="/admin" element={
          <ProtectedRoute allowedRoles={['super_admin', 'admin_haramain_pro']}>
            <AdminDashboard />
          </ProtectedRoute>
        } />
        <Route path="/admin/seat-licenses" element={
          <ProtectedRoute allowedRoles={['super_admin', 'admin_haramain_pro']}>
            <SeatLicensesAdmin />
          </ProtectedRoute>
        } />
        <Route path="/admin/travels" element={
          <ProtectedRoute allowedRoles={['super_admin']}>
            <TravelsAdmin />
          </ProtectedRoute>
        } />
        <Route path="/admin/billing" element={
          <ProtectedRoute allowedRoles={['super_admin']}>
            <BillingAdmin />
          </ProtectedRoute>
        } />
        <Route path="/admin/users" element={
          <ProtectedRoute allowedRoles={['super_admin', 'admin_haramain_pro']}>
            <UsersAdmin />
          </ProtectedRoute>
        } />
        <Route path="/admin/system" element={
          <ProtectedRoute allowedRoles={['super_admin']}>
            <SystemHealth />
          </ProtectedRoute>
        } />

        <Route path="/jamaah" element={
          <ProtectedRoute allowedRoles={['jamaah', 'jamaah_mandiri']}>
            <JamaahPage />
          </ProtectedRoute>
        } />

        <Route path="*" element={<Navigate to="/travel-admin" replace />} />
      </Routes>
    </Layout>
  )
}

function App() {
  const queryClient = new QueryClient({
    defaultOptions: {
      queries: {
        staleTime: 1000 * 60 * 5, // 5 minutes
        retry: 2,
      },
    },
  })
  return (
    <QueryClientProvider client={queryClient}>
      <BrowserRouter>
        <AppContent />
      </BrowserRouter>
    </QueryClientProvider>
  )
}

export default App
