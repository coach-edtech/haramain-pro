import { Shield, Download, AlertTriangle, TrendingUp } from 'lucide-react'
import { mockSeatLicenses } from '../../lib/mockData'
import { useState } from 'react'

export default function SeatLicensesAdmin() {
  const [filter, setFilter] = useState<'all' | 'low_stock' | 'depleted'>('all')

  const filteredLicenses = mockSeatLicenses.filter(license => {
    if (filter === 'all') return true
    return license.status === filter
  })

  const totalSeats = mockSeatLicenses.reduce((acc, l) => acc + l.total_seats, 0)
  const usedSeats = mockSeatLicenses.reduce((acc, l) => acc + l.used_seats, 0)
  const balance = totalSeats - usedSeats

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold text-gray-900">Seat License Management</h1>
          <p className="text-gray-500">Platform-wide seat license overview</p>
        </div>
        <button className="btn-primary flex items-center gap-2">
          <Download className="w-4 h-4" />
          Export Report
        </button>
      </div>

      <div className="grid grid-cols-1 md:grid-cols-4 gap-6">
        <div className="card p-6">
          <div className="flex items-start justify-between">
            <div>
              <p className="text-sm text-gray-500 mb-1">Total Seats Sold</p>
              <p className="text-3xl font-bold text-gray-900">{totalSeats}</p>
            </div>
            <div className="p-3 bg-amber-50 rounded-lg">
              <Shield className="w-6 h-6 text-amber-600" />
            </div>
          </div>
        </div>
        <div className="card p-6">
          <div className="flex items-start justify-between">
            <div>
              <p className="text-sm text-gray-500 mb-1">Seats Used</p>
              <p className="text-3xl font-bold text-gray-900">{usedSeats}</p>
            </div>
            <div className="p-3 bg-emerald-50 rounded-lg">
              <TrendingUp className="w-6 h-6 text-emerald-600" />
            </div>
          </div>
        </div>
        <div className="card p-6">
          <div className="flex items-start justify-between">
            <div>
              <p className="text-sm text-gray-500 mb-1">Available Balance</p>
              <p className="text-3xl font-bold text-gray-900">{balance}</p>
            </div>
            <div className="p-3 bg-blue-50 rounded-lg">
              <Shield className="w-6 h-6 text-blue-600" />
            </div>
          </div>
        </div>
        <div className="card p-6">
          <div className="flex items-start justify-between">
            <div>
              <p className="text-sm text-gray-500 mb-1">Low Stock Alerts</p>
              <p className="text-3xl font-bold text-red-600">
                {mockSeatLicenses.filter(l => l.status !== 'active').length}
              </p>
            </div>
            <div className="p-3 bg-red-50 rounded-lg">
              <AlertTriangle className="w-6 h-6 text-red-600" />
            </div>
          </div>
        </div>
      </div>

      <div className="card">
        <div className="p-4 border-b border-gray-200 flex items-center justify-between">
          <h2 className="text-lg font-semibold text-gray-900">Seat License Details</h2>
          <div className="flex gap-2">
            {(['all', 'low_stock', 'depleted'] as const).map((f) => (
              <button
                key={f}
                onClick={() => setFilter(f)}
                className={`px-3 py-1.5 text-sm rounded-lg transition-colors ${
                  filter === f
                    ? 'bg-amber-100 text-amber-700'
                    : 'text-gray-600 hover:bg-gray-100'
                }`}
              >
                {f === 'all' ? 'All' : f === 'low_stock' ? 'Low Stock' : 'Depleted'}
              </button>
            ))}
          </div>
        </div>
        <div className="overflow-x-auto">
          <table className="w-full">
            <thead className="bg-gray-50">
              <tr>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Travel</th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Total</th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Used</th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Balance</th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Last Purchase</th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Status</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-gray-200">
              {filteredLicenses.map((license) => (
                <tr key={license.id} className="hover:bg-gray-50">
                  <td className="px-6 py-4 font-medium text-gray-900">{license.agency_name}</td>
                  <td className="px-6 py-4 text-gray-600">{license.total_seats}</td>
                  <td className="px-6 py-4 text-gray-600">{license.used_seats}</td>
                  <td className="px-6 py-4 text-gray-600">{license.balance}</td>
                  <td className="px-6 py-4 text-gray-600">{license.last_purchase}</td>
                  <td className="px-6 py-4">
                    <span className={`px-2 py-1 text-xs font-medium rounded-full ${
                      license.status === 'active' ? 'bg-emerald-100 text-emerald-700' :
                      license.status === 'low_stock' ? 'bg-yellow-100 text-yellow-700' :
                      'bg-red-100 text-red-700'
                    }`}>
                      {license.status.replace('_', ' ')}
                    </span>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </div>
    </div>
  )
}
