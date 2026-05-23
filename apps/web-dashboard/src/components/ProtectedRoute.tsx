import { ReactNode, useEffect, useState } from 'react'
import { Navigate, useLocation } from 'react-router-dom'
import { supabase } from '../lib/supabase'
import { UserRole } from '../types'

interface ProtectedRouteProps {
  children: ReactNode
  allowedRoles: UserRole[]
}

/**
 * Server-validated route guard.
 * Validates the user's role from the database on each protected route access.
 * Redirects to /login if unauthenticated, or to default route if unauthorized.
 */
export default function ProtectedRoute({ children, allowedRoles }: ProtectedRouteProps) {
  const location = useLocation()
  const [session, setSession] = useState<any>(null)
  const [loading, setLoading] = useState(true)
  const [userRole, setUserRole] = useState<UserRole | null>(null)
  const [roleLoading, setRoleLoading] = useState(true)

  useEffect(() => {
    supabase.auth.getSession().then(({ data }) => {
      setSession(data.session)
      setLoading(false)
    })
  }, [])

  // Fetch server-validated role from validate-role edge function
  useEffect(() => {
    async function fetchServerRole() {
      if (!session?.access_token) {
        setRoleLoading(false)
        return
      }

      try {
        const supabaseUrl = import.meta.env.VITE_SUPABASE_URL
        const res = await fetch(`${supabaseUrl}/functions/v1/validate-role`, {
          headers: {
            Authorization: `Bearer ${session.access_token}`,
            'Content-Type': 'application/json',
          },
        })

        if (res.ok) {
          const data = await res.json()
          setUserRole(data.role as UserRole)
        } else {
          // Fallback: use metadata if server validation fails
          const meta = session.user?.user_metadata
          setUserRole(mapMetaRoleToUserRole(meta?.role || 'jamaah'))
        }
      } catch {
        // Fallback: use metadata on network error
        const meta = session.user?.user_metadata
        setUserRole(mapMetaRoleToUserRole(meta?.role || 'jamaah'))
      } finally {
        setRoleLoading(false)
      }
    }

    if (session) {
      fetchServerRole()
    } else {
      setRoleLoading(false)
    }
  }, [session])

  if (loading || roleLoading) {
    return (
      <div className="min-h-screen flex items-center justify-center bg-gray-100">
        <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-primary-600"></div>
      </div>
    )
  }

  if (!session) {
    return <Navigate to="/login" state={{ from: location }} replace />
  }

  // userRole is guaranteed non-null after roleLoading=false due to fallback
  if (!userRole || !allowedRoles.includes(userRole)) {
    const defaultRoute = getDefaultRouteForRole(userRole || 'jamaah')
    return <Navigate to={defaultRoute} replace />
  }

  return <>{children}</>
}

function getDefaultRouteForRole(role: string): string {
  switch (role) {
    case 'super_admin':
    case 'admin_haramain_pro':
      return '/admin'
    case 'travel_admin':
    case 'team_support':
    case 'muthawif':
      return '/travel-admin'
    case 'jamaah':
    case 'jamaah_mandiri':
      return '/jamaah'
    default:
      return '/'
  }
}

function mapMetaRoleToUserRole(metaRole: string): UserRole {
  const map: Record<string, UserRole> = {
    super_admin: 'super_admin',
    admin: 'admin_haramain_pro',
    admin_haramain_pro: 'admin_haramain_pro',
    travel_admin: 'travel_admin',
    agency: 'travel_admin',
    team_support: 'team_support',
    muthawif: 'muthawif',
    pilgrim: 'jamaah',
    jamaah: 'jamaah',
    jamaaah_mandiri: 'jamaah_mandiri',
  }
  return map[metaRole.toLowerCase()] || 'jamaah'
}
