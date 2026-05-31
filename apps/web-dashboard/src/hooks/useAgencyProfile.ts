import { useState, useEffect } from 'react'
import { supabase } from '../lib/supabase'
import type { UserRole } from '../types'

export interface AgencyProfile {
  id: string
  name: string
  role: UserRole
  agency_id: string | null
}

/**
 * Returns the current user's profile from Supabase.
 * Used to determine agency context for scoped B2B queries.
 */
export function useAgencyProfile() {
  const [profile, setProfile] = useState<AgencyProfile | null>(null)
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)

  useEffect(() => {
    async function fetchProfile() {
      try {
        const { data: { user } } = await supabase.auth.getUser()
        if (!user) {
          setProfile(null)
          setLoading(false)
          return
        }

        const { data, error: err } = await supabase
          .from('profiles')
          .select('id, name, role, agency_id')
          .eq('id', user.id)
          .single()

        if (err) throw err
        setProfile(data as AgencyProfile)
      } catch (e) {
        setError(String(e))
      } finally {
        setLoading(false)
      }
    }

    fetchProfile()
  }, [])

  return { profile, loading, error }
}
