import { useState, useEffect } from 'react'
import { supabase } from '../lib/supabase'
import type { Profile } from '../types'
import { Search, Mail, Phone, Shield, Calendar, CreditCard, ChevronDown, ChevronUp } from 'lucide-react'

interface SubscriptionInfo {
  plan: string
  status: 'trial' | 'active' | 'expired'
  expiry_date?: string
  auto_renew?: boolean
}

export default function Jamaah() {
  const [jamaah, setJamaah] = useState<Profile[]>([])
  const [loading, setLoading] = useState(true)
  const [searchTerm, setSearchTerm] = useState('')
  const [expandedId, setExpandedId] = useState<string | null>(null)

  useEffect(() => {
    fetchJamaah()
  }, [])

  const fetchJamaah = async () => {
    try {
      const { data, error } = await supabase
        .from('profiles')
        .select('*')
        .eq('role', 'jamaah')
        .order('created_at', { ascending: false })

      if (error) throw error
      setJamaah(data || [])
    } catch (error) {
      console.error('Error fetching Jamaah:', error)
    } finally {
      setLoading(false)
    }
  }

  const filteredJamaah = jamaah.filter(j =>
    j.name.toLowerCase().includes(searchTerm.toLowerCase()) ||
    j.email.toLowerCase().includes(searchTerm.toLowerCase())
  )

  const getSubscriptionInfo = (profile: Profile): SubscriptionInfo => {
    const tier = profile.subscription_tier || 'trial'
    const planNames: Record<string, string> = {
      trial: 'Umrah Mandiri Trial',
      basic: 'Umrah Mandiri Basic',
      premium: 'Umrah Mandiri Premium',
      active: 'Umrah Mandiri Premium',
      expired: 'Umrah Mandiri Expired',
    }
    return {
      plan: planNames[tier] || 'Umrah Mandiri Trial',
      status: tier as SubscriptionInfo['status'],
      expiry_date: profile.subscription_expiry,
      auto_renew: profile.auto_renew || false,
    }
  }

  const tierStyles = {
    trial: {
      bg: 'bg-amber-50',
      text: 'text-amber-700',
      border: 'border-amber-200',
      badge: 'bg-amber-100 text-amber-800',
      icon: '🏖️',
    },
    basic: {
      bg: 'bg-blue-50',
      text: 'text-blue-700',
      border: 'border-blue-200',
      badge: 'bg-blue-100 text-blue-800',
      icon: '🌙',
    },
    premium: {
      bg: 'bg-emerald-50',
      text: 'text-emerald-700',
      border: 'border-emerald-200',
      badge: 'bg-emerald-100 text-emerald-800',
      icon: '🕌',
    },
    active: {
      bg: 'bg-emerald-50',
      text: 'text-emerald-700',
      border: 'border-emerald-200',
      badge: 'bg-emerald-100 text-emerald-800',
      icon: '🕌',
    },
    expired: {
      bg: 'bg-red-50',
      text: 'text-red-700',
      border: 'border-red-200',
      badge: 'bg-red-100 text-red-800',
      icon: '⏰',
    },
  }

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-2xl font-bold text-gray-900">Jamaah</h1>
        <p className="text-gray-500">View and manage pilgrims</p>
      </div>

      <div className="card">
        <div className="p-4 border-b border-gray-200">
          <div className="relative max-w-md">
            <Search className="absolute left-3 top-1/2 -translate-y-1/2 w-5 h-5 text-gray-400" />
            <input
              type="text"
              placeholder="Search by name or email..."
              value={searchTerm}
              onChange={(e) => setSearchTerm(e.target.value)}
              className="input pl-10"
            />
          </div>
        </div>

        {loading ? (
          <div className="p-6 text-center">Loading...</div>
        ) : filteredJamaah.length === 0 ? (
          <div className="p-6 text-center text-gray-500">
            No Jamaah found.
          </div>
        ) : (
          <div className="overflow-x-auto">
            <table className="w-full">
              <thead className="bg-gray-50">
                <tr>
                  <th className="px-4 py-3 text-left text-xs font-medium text-gray-500 uppercase">Name</th>
                  <th className="px-4 py-3 text-left text-xs font-medium text-gray-500 uppercase">Email</th>
                  <th className="px-4 py-3 text-left text-xs font-medium text-gray-500 uppercase">Subscription</th>
                  <th className="px-4 py-3 text-left text-xs font-medium text-gray-500 uppercase">Actions</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-gray-100">
                {filteredJamaah.map((person) => (
                  <tr key={person.id} className="hover:bg-gray-50">
                    <td className="px-4 py-3">
                      <div className="flex items-center gap-3">
                        <div className="w-8 h-8 bg-primary-100 rounded-full flex items-center justify-center">
                          <span className="text-primary-700 font-medium text-sm">
                            {person.name[0].toUpperCase()}
                          </span>
                        </div>
                        <span className="font-medium text-gray-900">{person.name}</span>
                      </div>
                    </td>
                    <td className="px-4 py-3 text-gray-600">{person.email}</td>
                    <td className="px-4 py-3">
                      {(() => {
                        const sub = getSubscriptionInfo(person)
                        const style = tierStyles[sub.status] || tierStyles.trial
                        return (
                          <div className="space-y-2">
                            {/* Tier Badge with Icon */}
                            <span className={`inline-flex items-center gap-1.5 px-2.5 py-1 rounded-full text-xs font-semibold ${style.badge}`}>
                              <span>{style.icon}</span>
                              <span className="capitalize">{sub.status}</span>
                            </span>
                            
                            {/* Subscription Plan Name */}
                            <div className="text-sm font-medium text-gray-900">{sub.plan}</div>
                            
                            {/* Expiry & Auto-renew info */}
                            <div className="flex items-center gap-3 text-xs text-gray-500">
                              {sub.expiry_date && (
                                <span className="flex items-center gap-1">
                                  <Calendar className="w-3 h-3" />
                                  {new Date(sub.expiry_date).toLocaleDateString('id-ID', { day: 'numeric', month: 'short', year: 'numeric' })}
                                </span>
                              )}
                              {sub.auto_renew && (
                                <span className="flex items-center gap-1 text-emerald-600">
                                  <CreditCard className="w-3 h-3" />
                                  Auto-renew
                                </span>
                              )}
                            </div>
                          </div>
                        )
                      })()}
                    </td>
                    <td className="px-4 py-3">
                      <div className="flex items-center gap-2">
                        <button className="p-1.5 text-gray-500 hover:text-primary-600 hover:bg-gray-100 rounded">
                          <Mail className="w-4 h-4" />
                        </button>
                        <button className="p-1.5 text-gray-500 hover:text-primary-600 hover:bg-gray-100 rounded">
                          <Phone className="w-4 h-4" />
                        </button>
                        <button className="p-1.5 text-gray-500 hover:text-primary-600 hover:bg-gray-100 rounded">
                          <Shield className="w-4 h-4" />
                        </button>
                      </div>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}
      </div>
    </div>
  )
}