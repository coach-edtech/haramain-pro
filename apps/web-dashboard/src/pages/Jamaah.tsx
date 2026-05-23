import { useState, useEffect } from 'react'
import { supabase } from '../lib/supabase'
import type { Profile } from '../types'
import { Search, Mail, Phone, Shield } from 'lucide-react'

export default function Jamaah() {
  const [jamaah, setJamaah] = useState<Profile[]>([])
  const [loading, setLoading] = useState(true)
  const [searchTerm, setSearchTerm] = useState('')

  useEffect(() => {
    fetchJamaah()
  }, [])

  const fetchJamaah = async () => {
    try {
      const { data, error } = await supabase
        .from('profiles')
        .select('*')
        .eq('role', 'pilgrim')
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

  const tierColors = {
    trial: 'bg-gray-100 text-gray-700',
    active: 'bg-green-100 text-green-700',
    expired: 'bg-red-100 text-red-700',
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
                      <span className={`px-2 py-1 rounded-full text-xs font-medium ${tierColors[person.subscription_tier]}`}>
                        {person.subscription_tier}
                      </span>
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