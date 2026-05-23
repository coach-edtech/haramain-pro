import { useState, useEffect } from 'react'
import { supabase } from '../lib/supabase'
import type { Rombongan } from '../types'
import { Plus, Search, Calendar, Users } from 'lucide-react'

export default function Packages() {
  const [rombongans, setRombongans] = useState<Rombongan[]>([])
  const [loading, setLoading] = useState(true)
  const [searchTerm, setSearchTerm] = useState('')

  useEffect(() => {
    fetchRombongans()
  }, [])

  const fetchRombongans = async () => {
    try {
      const { data, error } = await supabase
        .from('rombangans')
        .select('*')
        .order('created_at', { ascending: false })

      if (error) throw error
      setRombongans(data || [])
    } catch (error) {
      console.error('Error fetching rombangans:', error)
    } finally {
      setLoading(false)
    }
  }

  const filteredRombongans = rombongans.filter(r =>
    r.name.toLowerCase().includes(searchTerm.toLowerCase())
  )

  const statusColors = {
    planned: 'bg-blue-100 text-blue-700',
    active: 'bg-green-100 text-green-700',
    completed: 'bg-gray-100 text-gray-700',
  }

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold text-gray-900">Packages</h1>
          <p className="text-gray-500">Manage travel packages and rombongans</p>
        </div>
        <button className="btn-primary flex items-center gap-2">
          <Plus className="w-4 h-4" />
          New Package
        </button>
      </div>

      <div className="card">
        <div className="p-4 border-b border-gray-200">
          <div className="relative max-w-md">
            <Search className="absolute left-3 top-1/2 -translate-y-1/2 w-5 h-5 text-gray-400" />
            <input
              type="text"
              placeholder="Search packages..."
              value={searchTerm}
              onChange={(e) => setSearchTerm(e.target.value)}
              className="input pl-10"
            />
          </div>
        </div>

        {loading ? (
          <div className="p-6 text-center">Loading...</div>
        ) : filteredRombongans.length === 0 ? (
          <div className="p-6 text-center text-gray-500">
            No packages found. Create your first package.
          </div>
        ) : (
          <div className="divide-y divide-gray-100">
            {filteredRombongans.map((rombongan) => (
              <div key={rombongan.id} className="p-4 flex items-center justify-between hover:bg-gray-50">
                <div className="flex items-center gap-4">
                  <div className="w-12 h-12 bg-primary-100 rounded-lg flex items-center justify-center">
                    <Users className="w-6 h-6 text-primary-600" />
                  </div>
                  <div>
                    <p className="font-medium text-gray-900">{rombongan.name}</p>
                    <div className="flex items-center gap-4 text-sm text-gray-500 mt-1">
                      <span className="flex items-center gap-1">
                        <Calendar className="w-4 h-4" />
                        {rombongan.start_date} - {rombongan.end_date}
                      </span>
                    </div>
                  </div>
                </div>
                <div className="flex items-center gap-3">
                  <span className={`px-3 py-1 rounded-full text-xs font-medium ${statusColors[rombongan.status]}`}>
                    {rombongan.status}
                  </span>
                  <button className="text-primary-600 hover:text-primary-700 text-sm font-medium">
                    Edit
                  </button>
                </div>
              </div>
            ))}
          </div>
        )}
      </div>
    </div>
  )
}