import { useState, useEffect, useCallback } from 'react'
import { supabase } from '../lib/supabase'

export interface AdminSystemStats {
  totalSeatLicenses: number
  activeJamaah: number
  totalRevenue: number
  activeRombongans: number
  pendingPayments: number
  loading: boolean
  error: string | null
  refetch: () => Promise<void>
}

export default function useAdminSystemStats(): AdminSystemStats {
  const [stats, setStats] = useState<Omit<AdminSystemStats, 'loading' | 'error' | 'refetch'>>({
    totalSeatLicenses: 0,
    activeJamaah: 0,
    totalRevenue: 0,
    activeRombongans: 0,
    pendingPayments: 0,
  })
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)

  const fetchStats = useCallback(async () => {
    try {
      setError(null)

      const [
        seatLicensesRes,
        pilgrimsRes,
        romonganRes,
        revenueRes,
        pendingPaymentsRes,
      ] = await Promise.all([
        supabase.from('seat_licenses').select('id', { count: 'exact', head: true }),
        supabase.from('profiles').select('id', { count: 'exact', head: true }).eq('role', 'jamaah'),
        supabase.from('rombongans').select('id', { count: 'exact', head: true }).eq('status', 'active'),
        supabase.from('payments').select('amount').eq('status', 'settlement'),
        supabase.from('payments').select('id', { count: 'exact', head: true }).eq('status', 'pending'),
      ])

      const totalRevenue = revenueRes.data?.reduce((sum, p) => sum + (p.amount || 0), 0) || 0

      setStats({
        totalSeatLicenses: seatLicensesRes.count || 0,
        activeJamaah: pilgrimsRes.count || 0,
        activeRombongans: romonganRes.count || 0,
        totalRevenue,
        pendingPayments: pendingPaymentsRes.count || 0,
      })
    } catch (err) {
      console.error('Error fetching admin system stats:', err)
      setError('Failed to load system statistics. Please try again.')
    } finally {
      setLoading(false)
    }
  }, [])

  useEffect(() => {
    fetchStats()
  }, [fetchStats])

  return {
    ...stats,
    loading,
    error,
    refetch: fetchStats,
  }
}
