import { Globe, Plus, Search, Shield, Users, Edit, Eye, Ban, CheckCircle, Loader2 } from 'lucide-react'
import { useState } from 'react'
import { useAgencies, useAdminSeatLicenses } from '../../lib/api'

export default function TravelsAdmin() {
  const [search, setSearch] = useState('')
  const [statusFilter, setStatusFilter] = useState<'all' | 'active' | 'suspended'>('all')

  const wlStatusMap: Record<string, string> = { active: 'active', suspended: 'suspended' }
  const apiWlStatus = statusFilter === 'all' ? undefined : wlStatusMap[statusFilter]

  const { data: agenciesData, isLoading: agenciesLoading } = useAgencies(search || undefined, apiWlStatus)
  const { data: licensesData, isLoading: licensesLoading } = useAdminSeatLicenses()

  const agencies = agenciesData?.agencies ?? []
  const licenses = licensesData?.licenses ?? []
  const stats = licensesData?.stats

  // Map licenses by agency_id for quick lookup
  const licenseMap = Object.fromEntries(licenses.map(l => [l.agency_name.toLowerCase(), l]))

  const filteredAgencies = agencies.filter(agency => {
    return agency.name.toLowerCase().includes(search.toLowerCase())
  })

  const totalTravels = agenciesData?.count ?? 0
  const activeCount = agencies.filter(a => a.wl_status === 'active').length
  const totalJamaah = stats?.total_used ?? 0

  const getStatusBadge = (status: string) => {
    switch (status) {
      case 'active':
        return <span className="badge badge-success">Active</span>
      case 'suspended':
        return <span className="badge badge-danger">Suspended</span>
      default:
        return <span className="badge badge-info">{status}</span>
    }
  }

  if (agenciesLoading || licensesLoading) {
    return (
      <div className="flex items-center justify-center h-64">
        <Loader2 className="w-8 h-8 animate-spin text-accent-500" />
      </div>
    )
  }

  return (
    <div className="space-y-6">
      {/* Page Header */}
      <div className="flex items-center justify-between">
        <div className="page-header mb-0">
          <h1 className="page-title">Travel Accounts</h1>
          <p className="page-subtitle">Manage all registered travel agencies</p>
        </div>
        <button className="btn-primary flex items-center gap-2">
          <Plus className="w-4 h-4" />
          Add Travel
        </button>
      </div>

      {/* Stats Summary */}
      <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
        <div className="card p-4 flex items-center gap-4">
          <div className="p-3 bg-primary-100 rounded-xl">
            <Globe className="w-6 h-6 text-primary-600" />
          </div>
          <div>
            <p className="text-2xl font-bold text-slate-900">{totalTravels}</p>
            <p className="text-sm text-slate-500">Total Travels</p>
          </div>
        </div>
        <div className="card p-4 flex items-center gap-4">
          <div className="p-3 bg-emerald-100 rounded-xl">
            <CheckCircle className="w-6 h-6 text-emerald-600" />
          </div>
          <div>
            <p className="text-2xl font-bold text-slate-900">{activeCount}</p>
            <p className="text-sm text-slate-500">Active</p>
          </div>
        </div>
        <div className="card p-4 flex items-center gap-4">
          <div className="p-3 bg-slate-100 rounded-xl">
            <Users className="w-6 h-6 text-slate-600" />
          </div>
          <div>
            <p className="text-2xl font-bold text-slate-900">{totalJamaah.toLocaleString()}</p>
            <p className="text-sm text-slate-500">Total Jamaah</p>
          </div>
        </div>
      </div>

      {/* Travels Table */}
      <div className="card">
        <div className="p-4 border-b border-slate-100">
          <div className="flex flex-col md:flex-row gap-4">
            {/* Search */}
            <div className="relative flex-1">
              <Search className="absolute left-3 top-1/2 -translate-y-1/2 w-5 h-5 text-slate-400" />
              <input
                type="text"
                placeholder="Search by name or email..."
                value={search}
                onChange={(e) => setSearch(e.target.value)}
                className="input pl-10"
              />
            </div>
            {/* Status Filter */}
            <div className="flex gap-2">
              {(['all', 'active', 'suspended'] as const).map((f) => (
                <button
                  key={f}
                  onClick={() => setStatusFilter(f)}
                  className={`px-4 py-2 text-sm font-medium rounded-lg transition-colors ${
                    statusFilter === f
                      ? 'bg-accent-500 text-white'
                      : 'bg-slate-100 text-slate-600 hover:bg-slate-200'
                  }`}
                >
                  {f.charAt(0).toUpperCase() + f.slice(1)}
                </button>
              ))}
            </div>
          </div>
        </div>
        <div className="overflow-x-auto">
          <table className="w-full">
            <thead>
              <tr className="table-header">
                <th className="px-6 py-3 text-left">Travel Agency</th>
                <th className="px-6 py-3 text-left">Contact</th>
                <th className="px-6 py-3 text-left">Licenses</th>
                <th className="px-6 py-3 text-left">Active Jamaah</th>
                <th className="px-6 py-3 text-left">Status</th>
                <th className="px-6 py-3 text-left">Actions</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-slate-100">
              {filteredAgencies.map((agency) => {
                const license = licenseMap[agency.name.toLowerCase()]
                return (
                <tr key={agency.id} className="table-row">
                  <td className="px-6 py-4">
                    <div className="flex items-center gap-3">
                      <div className="w-12 h-12 bg-gradient-to-br from-accent-400 to-accent-600 rounded-xl flex items-center justify-center">
                        <Globe className="w-6 h-6 text-white" />
                      </div>
                      <div>
                        <p className="font-semibold text-slate-900">{agency.name}</p>
                        <p className="text-xs text-slate-400">ID: {agency.id}</p>
                      </div>
                    </div>
                  </td>
                  <td className="px-6 py-4">
                    <p className="text-slate-900">{agency.phone ?? '-'}</p>
                    <p className="text-xs text-slate-500">{agency.address ?? '-'}</p>
                  </td>
                  <td className="px-6 py-4">
                    <div className="flex items-center gap-2">
                      <Shield className="w-4 h-4 text-slate-400" />
                      <span className="font-semibold text-slate-900">{license?.total_seats ?? 0}</span>
                    </div>
                  </td>
                  <td className="px-6 py-4">
                    <div className="flex items-center gap-2">
                      <Users className="w-4 h-4 text-slate-400" />
                      <span className="font-semibold text-slate-900">{license?.used_seats ?? 0}</span>
                    </div>
                  </td>
                  <td className="px-6 py-4">
                    {getStatusBadge(agency.wl_status)}
                  </td>
                  <td className="px-6 py-4">
                    <div className="flex items-center gap-2">
                      <button className="p-2 text-slate-500 hover:bg-slate-100 rounded-lg transition-colors">
                        <Eye className="w-4 h-4" />
                      </button>
                      <button className="p-2 text-accent-600 hover:bg-accent-50 rounded-lg transition-colors">
                        <Edit className="w-4 h-4" />
                      </button>
                      {agency.wl_status === 'active' ? (
                        <button className="p-2 text-danger-600 hover:bg-danger-50 rounded-lg transition-colors">
                          <Ban className="w-4 h-4" />
                        </button>
                      ) : (
                        <button className="p-2 text-emerald-600 hover:bg-emerald-50 rounded-lg transition-colors">
                          <CheckCircle className="w-4 h-4" />
                        </button>
                      )}
                    </div>
                  </td>
                </tr>
              )})}
            </tbody>
          </table>
        </div>
        {filteredAgencies.length === 0 && (
          <div className="p-8 text-center">
            <Globe className="w-12 h-12 text-slate-300 mx-auto mb-3" />
            <p className="text-slate-500">No travels found matching your criteria</p>
          </div>
        )}
      </div>
    </div>
  )
}
