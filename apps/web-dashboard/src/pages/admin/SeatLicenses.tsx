import { Shield, Download, AlertTriangle, TrendingUp, Search, Eye, Loader2, Key, BarChart3, Bell, Copy } from 'lucide-react'
import { useState } from 'react'
import { useAdminSeatLicenses, useRedeemCodes } from '../../lib/api'

export default function SeatLicensesAdmin() {
  const [filter, setFilter] = useState<'all' | 'low_stock' | 'depleted'>('all')
  const [searchQuery, setSearchQuery] = useState('')
  const [codeFilter, setCodeFilter] = useState<'all' | 'available' | 'used'>('all')
  const [alertThreshold, setAlertThreshold] = useState(20)
  const [alertActive, setAlertActive] = useState(true)
  const [copiedCode, setCopiedCode] = useState<string | null>(null)

  const { data, isLoading, error } = useAdminSeatLicenses(filter === 'all' ? undefined : filter, searchQuery || undefined)
  const { data: codesData } = useRedeemCodes(undefined, codeFilter === 'all' ? undefined : codeFilter)

  const licenses = data?.licenses ?? []
  const stats = data?.stats
  const redeemCodes = codesData?.codes ?? []

  const filteredLicenses = licenses.filter(license => {
    if (!searchQuery) return true
    return license.agency_name.toLowerCase().includes(searchQuery.toLowerCase())
  })

  const totalSeats = stats?.total_seats_sold ?? 0
  const usedSeats = stats?.total_used ?? 0
  const balance = stats?.total_balance ?? 0
  const lowStockCount = stats?.low_stock_count ?? 0

  // Usage analytics: simulate weekly/monthly usage data
  const usageAnalytics = [
    { period: 'Week 1', used: Math.floor(usedSeats * 0.1), total: Math.floor(totalSeats * 0.1) },
    { period: 'Week 2', used: Math.floor(usedSeats * 0.18), total: Math.floor(totalSeats * 0.18) },
    { period: 'Week 3', used: Math.floor(usedSeats * 0.28), total: Math.floor(totalSeats * 0.28) },
    { period: 'Week 4', used: usedSeats, total: totalSeats },
  ]
  const peakUsage = Math.max(...usageAnalytics.map(w => w.used))
  const avgUsageRate = totalSeats > 0 ? Math.round((usedSeats / totalSeats) * 100) : 0

  const copyToClipboard = (code: string) => {
    navigator.clipboard.writeText(code)
    setCopiedCode(code)
    setTimeout(() => setCopiedCode(null), 2000)
  }

  const getStatusBadge = (status: string) => {
    switch (status) {
      case 'active':
        return <span className="badge badge-success">Active</span>
      case 'low_stock':
        return <span className="badge badge-warning">Low Stock</span>
      case 'depleted':
        return <span className="badge badge-danger">Depleted</span>
      default:
        return <span className="badge badge-info">{status}</span>
    }
  }

  if (isLoading) {
    return (
      <div className="flex items-center justify-center h-64">
        <Loader2 className="w-8 h-8 animate-spin text-accent-500" />
      </div>
    )
  }

  if (error) {
    return (
      <div className="flex items-center justify-center h-64">
        <div className="text-center">
          <p className="text-red-600 font-medium">{error.message}</p>
        </div>
      </div>
    )
  }

  return (
    <div className="space-y-6">
      {/* Page Header */}
      <div className="flex items-center justify-between">
        <div className="page-header mb-0">
          <h1 className="page-title">Seat Licenses</h1>
          <p className="page-subtitle">Platform-wide seat license management</p>
        </div>
        <button className="btn-secondary flex items-center gap-2">
          <Download className="w-4 h-4" />
          Export Report
        </button>
      </div>

      {/* Stats */}
      <div className="grid grid-cols-1 md:grid-cols-4 gap-6">
        <div className="card p-6">
          <div className="flex items-start justify-between">
            <div>
              <p className="text-sm text-slate-500 mb-1">Total Seats Sold</p>
              <p className="text-3xl font-bold text-slate-900">{totalSeats.toLocaleString()}</p>
            </div>
            <div className="p-3 bg-accent-100 rounded-xl">
              <Shield className="w-6 h-6 text-accent-600" />
            </div>
          </div>
        </div>
        <div className="card p-6">
          <div className="flex items-start justify-between">
            <div>
              <p className="text-sm text-slate-500 mb-1">Seats Used</p>
              <p className="text-3xl font-bold text-slate-900">{usedSeats.toLocaleString()}</p>
            </div>
            <div className="p-3 bg-primary-100 rounded-xl">
              <TrendingUp className="w-6 h-6 text-primary-600" />
            </div>
          </div>
        </div>
        <div className="card p-6">
          <div className="flex items-start justify-between">
            <div>
              <p className="text-sm text-slate-500 mb-1">Available Balance</p>
              <p className="text-3xl font-bold text-slate-900">{balance.toLocaleString()}</p>
            </div>
            <div className="p-3 bg-blue-100 rounded-xl">
              <Shield className="w-6 h-6 text-blue-600" />
            </div>
          </div>
        </div>
        <div className="card p-6">
          <div className="flex items-start justify-between">
            <div>
              <p className="text-sm text-slate-500 mb-1">Low Stock Alerts</p>
              <p className="text-3xl font-bold text-danger-600">{lowStockCount}</p>
            </div>
            <div className="p-3 bg-danger-100 rounded-xl">
              <AlertTriangle className="w-6 h-6 text-danger-600" />
            </div>
          </div>
        </div>
      </div>

      {/* Usage Analytics Card */}
      <div className="card p-6">
        <div className="flex items-center justify-between mb-4">
          <div className="flex items-center gap-2">
            <BarChart3 className="w-5 h-5 text-accent-600" />
            <h2 className="text-lg font-semibold text-slate-900">Usage Analytics</h2>
          </div>
          <div className="flex items-center gap-4 text-sm">
            <div className="flex items-center gap-1">
              <span className="text-slate-500">Avg Usage:</span>
              <span className="font-medium text-slate-900">{avgUsageRate}%</span>
            </div>
            <div className="flex items-center gap-1">
              <span className="text-slate-500">Peak:</span>
              <span className="font-medium text-slate-900">{peakUsage}</span>
            </div>
          </div>
        </div>
        <div className="space-y-3">
          {usageAnalytics.map((week) => {
            const pct = week.total > 0 ? Math.round((week.used / week.total) * 100) : 0
            return (
              <div key={week.period} className="flex items-center gap-4">
                <span className="text-sm text-slate-500 w-16">{week.period}</span>
                <div className="flex-1 bg-slate-100 rounded-full h-6 relative overflow-hidden">
                  <div
                    className="bg-gradient-to-r from-accent-400 to-accent-600 h-6 rounded-full flex items-center justify-end pr-2 transition-all duration-500"
                    style={{ width: `${pct}%` }}
                  >
                    {pct > 15 && <span className="text-xs text-white font-medium">{pct}%</span>}
                  </div>
                </div>
                <span className="text-sm text-slate-600 w-20 text-right">
                  {week.used} / {week.total}
                </span>
              </div>
            )
          })}
        </div>
      </div>

      {/* Alert Config + Redeem Codes Row */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        {/* Alert Configuration */}
        <div className="card p-6">
          <div className="flex items-center gap-2 mb-4">
            <Bell className="w-5 h-5 text-accent-600" />
            <h2 className="text-lg font-semibold text-slate-900">Alert Configuration</h2>
          </div>
          <div className="space-y-4">
            <div className="flex items-center justify-between">
              <div>
                <p className="font-medium text-slate-900">Low Stock Alerts</p>
                <p className="text-sm text-slate-500">Notify agencies when seats run low</p>
              </div>
              <button
                onClick={() => setAlertActive(!alertActive)}
                className={`relative inline-flex h-6 w-11 items-center rounded-full transition-colors ${
                  alertActive ? 'bg-accent-500' : 'bg-slate-200'
                }`}
              >
                <span
                  className={`inline-block h-4 w-4 transform rounded-full bg-white transition-transform ${
                    alertActive ? 'translate-x-6' : 'translate-x-1'
                  }`}
                />
              </button>
            </div>
            <div>
              <label className="block text-sm font-medium text-slate-700 mb-1">
                Alert Threshold (seats remaining)
              </label>
              <div className="flex items-center gap-3">
                <input
                  type="range"
                  min={5}
                  max={100}
                  value={alertThreshold}
                  onChange={(e) => setAlertThreshold(parseInt(e.target.value))}
                  className="flex-1 accent-accent-500"
                />
                <span className="text-sm font-medium text-slate-900 w-12 text-right">{alertThreshold}</span>
              </div>
              <p className="text-xs text-slate-500 mt-1">
                Agencies will be alerted when their balance drops below {alertThreshold} seats
              </p>
            </div>
          </div>
        </div>

        {/* Redeem Codes Table */}
        <div className="card flex flex-col">
          <div className="p-4 border-b border-slate-100 flex items-center justify-between">
            <div className="flex items-center gap-2">
              <Key className="w-5 h-5 text-accent-600" />
              <h2 className="text-lg font-semibold text-slate-900">Redeem Codes</h2>
            </div>
            <div className="flex gap-2">
              {(['all', 'available', 'used'] as const).map((f) => (
                <button
                  key={f}
                  onClick={() => setCodeFilter(f)}
                  className={`px-2 py-1 text-xs font-medium rounded-md transition-colors ${
                    codeFilter === f
                      ? 'bg-accent-500 text-white'
                      : 'bg-slate-100 text-slate-600 hover:bg-slate-200'
                  }`}
                >
                  {f.charAt(0).toUpperCase() + f.slice(1)}
                </button>
              ))}
            </div>
          </div>
          <div className="overflow-y-auto flex-1 max-h-64">
            {redeemCodes.length === 0 ? (
              <div className="p-8 text-center">
                <Key className="w-8 h-8 text-slate-300 mx-auto mb-2" />
                <p className="text-sm text-slate-500">No redeem codes found</p>
              </div>
            ) : (
              <table className="w-full">
                <thead className="bg-slate-50">
                  <tr>
                    <th className="px-4 py-2 text-left text-xs font-medium text-slate-500 uppercase">Code</th>
                    <th className="px-4 py-2 text-left text-xs font-medium text-slate-500 uppercase">Status</th>
                    <th className="px-4 py-2 text-left text-xs font-medium text-slate-500 uppercase">Expires</th>
                    <th className="px-4 py-2 text-right text-xs font-medium text-slate-500 uppercase">Copy</th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-slate-100">
                  {redeemCodes.map((code) => (
                    <tr key={code.id} className="hover:bg-slate-50">
                      <td className="px-4 py-3">
                        <span className="font-mono text-sm font-medium text-slate-900">{code.code}</span>
                      </td>
                      <td className="px-4 py-3">
                        <span className={`px-2 py-0.5 text-xs font-medium rounded-full ${
                          code.status === 'available'
                            ? 'bg-emerald-100 text-emerald-700'
                            : code.status === 'used'
                            ? 'bg-slate-100 text-slate-600'
                            : 'bg-amber-100 text-amber-700'
                        }`}>
                          {code.status}
                        </span>
                      </td>
                      <td className="px-4 py-3 text-sm text-slate-500">
                        {code.expires_at
                          ? new Date(code.expires_at).toLocaleDateString('id-ID', { day: '2-digit', month: 'short', year: 'numeric' })
                          : '-'}
                      </td>
                      <td className="px-4 py-3 text-right">
                        <button
                          onClick={() => copyToClipboard(code.code)}
                          className="inline-flex items-center gap-1 text-accent-600 hover:text-accent-700 text-xs font-medium"
                        >
                          {copiedCode === code.code ? (
                            <span className="text-emerald-600">Copied!</span>
                          ) : (
                            <><Copy className="w-3 h-3" /> Copy</>
                          )}
                        </button>
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            )}
          </div>
        </div>
      </div>

      {/* Seat License Details Table */}
      <div className="card">
        <div className="p-4 border-b border-slate-100">
          <div className="flex flex-col md:flex-row md:items-center justify-between gap-4">
            <h2 className="text-lg font-semibold text-slate-900">License Details</h2>
            <div className="flex flex-col md:flex-row gap-3">
              {/* Search */}
              <div className="relative">
                <Search className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-slate-400" />
                <input
                  type="text"
                  placeholder="Search travel..."
                  value={searchQuery}
                  onChange={(e) => setSearchQuery(e.target.value)}
                  className="input pl-9 w-full md:w-64"
                />
              </div>
              {/* Filter buttons */}
              <div className="flex gap-2">
                {(['all', 'low_stock', 'depleted'] as const).map((f) => (
                  <button
                    key={f}
                    onClick={() => setFilter(f)}
                    className={`px-3 py-2 text-sm font-medium rounded-lg transition-colors ${
                      filter === f
                        ? 'bg-accent-500 text-white'
                        : 'bg-slate-100 text-slate-600 hover:bg-slate-200'
                    }`}
                  >
                    {f === 'all' ? 'All' : f === 'low_stock' ? 'Low Stock' : 'Depleted'}
                  </button>
                ))}
              </div>
            </div>
          </div>
        </div>
        <div className="overflow-x-auto">
          <table className="w-full">
            <thead>
              <tr className="table-header">
                <th className="px-6 py-3 text-left">Travel Agency</th>
                <th className="px-6 py-3 text-left">Total</th>
                <th className="px-6 py-3 text-left">Used</th>
                <th className="px-6 py-3 text-left">Balance</th>
                <th className="px-6 py-3 text-left">Last Purchase</th>
                <th className="px-6 py-3 text-left">Status</th>
                <th className="px-6 py-3 text-left">Actions</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-slate-100">
              {filteredLicenses.map((license) => (
                <tr key={license.id} className="table-row">
                  <td className="px-6 py-4">
                    <div className="flex items-center gap-3">
                      <div className="w-10 h-10 bg-accent-100 rounded-lg flex items-center justify-center">
                        <Shield className="w-5 h-5 text-accent-600" />
                      </div>
                      <span className="font-medium text-slate-900">{license.agency_name}</span>
                    </div>
                  </td>
                  <td className="px-6 py-4 text-slate-600">{license.total_seats}</td>
                  <td className="px-6 py-4">
                    <div className="flex items-center gap-2">
                      <div className="w-16 bg-slate-100 rounded-full h-1.5">
                        <div
                          className="bg-primary-500 h-1.5 rounded-full"
                          style={{ width: `${license.total_seats > 0 ? (license.used_seats / license.total_seats) * 100 : 0}%` }}
                        />
                      </div>
                      <span className="text-slate-600">{license.used_seats}</span>
                    </div>
                  </td>
                  <td className="px-6 py-4">
                    <span className={license.balance < 10 ? 'text-danger-600 font-medium' : 'text-slate-600'}>
                      {license.balance}
                    </span>
                  </td>
                  <td className="px-6 py-4 text-slate-500 text-sm">
                    {license.last_purchase ? new Date(license.last_purchase).toLocaleDateString('id-ID', { day: '2-digit', month: 'short', year: 'numeric' }) : '-'}
                  </td>
                  <td className="px-6 py-4">{getStatusBadge(license.status ?? 'active')}</td>
                  <td className="px-6 py-4">
                    <button className="inline-flex items-center gap-1 text-accent-600 hover:text-accent-700 text-sm font-medium">
                      <Eye className="w-4 h-4" />
                      View
                    </button>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
        {filteredLicenses.length === 0 && (
          <div className="p-8 text-center">
            <Shield className="w-12 h-12 text-slate-300 mx-auto mb-3" />
            <p className="text-slate-500">No licenses found matching your criteria</p>
          </div>
        )}
      </div>
    </div>
  )
}
