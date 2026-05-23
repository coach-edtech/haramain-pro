import { Shield, ShoppingCart, Key, Plus, AlertTriangle } from 'lucide-react'
import { mockSeatLicenses, mockRedeemCodes } from '../../lib/mockData'
import { useState } from 'react'

export default function SeatLicensesTravelAdmin() {
  const [showPurchaseModal, setShowPurchaseModal] = useState(false)
  const [showRedeemModal, setShowRedeemModal] = useState(false)

  const myLicense = mockSeatLicenses[0]
  const myCodes = mockRedeemCodes.filter(c => c.agency_id === 't1')

  const availableCodes = myCodes.filter(c => c.status === 'available')
  const usedCodes = myCodes.filter(c => c.status === 'used')

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold text-gray-900">Seat License Management</h1>
          <p className="text-gray-500">Manage your seat licenses and redeem codes</p>
        </div>
        <div className="flex gap-3">
          <button 
            onClick={() => setShowRedeemModal(true)}
            className="btn-primary flex items-center gap-2"
          >
            <Key className="w-4 h-4" />
            Generate Codes
          </button>
          <button 
            onClick={() => setShowPurchaseModal(true)}
            className="px-4 py-2 bg-emerald-600 text-white rounded-lg hover:bg-emerald-700 flex items-center gap-2"
          >
            <ShoppingCart className="w-4 h-4" />
            Purchase More
          </button>
        </div>
      </div>

      <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
        <div className="card p-6">
          <div className="flex items-start justify-between">
            <div>
              <p className="text-sm text-gray-500 mb-1">Total Seats</p>
              <p className="text-3xl font-bold text-gray-900">{myLicense.total_seats}</p>
            </div>
            <div className="p-3 bg-emerald-50 rounded-lg">
              <Shield className="w-6 h-6 text-emerald-600" />
            </div>
          </div>
          <div className="mt-4">
            <div className="flex justify-between text-sm mb-1">
              <span className="text-gray-500">Usage</span>
              <span className="font-medium">{myLicense.used_seats} / {myLicense.total_seats}</span>
            </div>
            <div className="bg-gray-200 rounded-full h-2">
              <div 
                className="bg-emerald-500 h-2 rounded-full"
                style={{ width: `${(myLicense.used_seats / myLicense.total_seats) * 100}%` }}
              />
            </div>
          </div>
        </div>

        <div className="card p-6">
          <div className="flex items-start justify-between">
            <div>
              <p className="text-sm text-gray-500 mb-1">Available</p>
              <p className="text-3xl font-bold text-emerald-600">{myLicense.balance}</p>
            </div>
            <div className="p-3 bg-blue-50 rounded-lg">
              <Key className="w-6 h-6 text-blue-600" />
            </div>
          </div>
          <div className="mt-4 flex items-center gap-2">
            <div className="w-2 h-2 bg-emerald-500 rounded-full" />
            <span className="text-sm text-gray-600">Active</span>
          </div>
        </div>

        <div className="card p-6">
          <div className="flex items-start justify-between">
            <div>
              <p className="text-sm text-gray-500 mb-1">Low Stock Alert</p>
              <p className={`text-3xl font-bold ${myLicense.balance < 10 ? 'text-red-600' : 'text-gray-900'}`}>
                {myLicense.balance < 10 ? <><AlertTriangle className="w-6 h-6 inline mr-2" />{myLicense.balance}</> : 'Good'}
              </p>
            </div>
            <div className={`p-3 rounded-lg ${myLicense.balance < 10 ? 'bg-red-50' : 'bg-gray-50'}`}>
              <AlertTriangle className={`w-6 h-6 ${myLicense.balance < 10 ? 'text-red-600' : 'text-gray-400'}`} />
            </div>
          </div>
        </div>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        <div className="card">
          <div className="p-4 border-b border-gray-200 flex items-center justify-between">
            <h2 className="text-lg font-semibold text-gray-900">Redeem Codes</h2>
            <button className="text-emerald-600 hover:text-emerald-700 text-sm font-medium flex items-center gap-1">
              <Plus className="w-4 h-4" />
              Generate New
            </button>
          </div>
          <div className="p-4">
            <h3 className="text-sm font-medium text-gray-500 mb-3">Available Codes ({availableCodes.length})</h3>
            <div className="space-y-2">
              {availableCodes.slice(0, 3).map((code) => (
                <div key={code.id} className="flex items-center justify-between p-3 bg-emerald-50 rounded-lg">
                  <code className="font-mono text-lg font-bold text-emerald-700">{code.code}</code>
                  <span className="text-xs text-emerald-600">Expires: {code.expires_at}</span>
                </div>
              ))}
            </div>
          </div>
          <div className="p-4 border-t border-gray-200">
            <h3 className="text-sm font-medium text-gray-500 mb-3">Used Codes ({usedCodes.length})</h3>
            <div className="space-y-2">
              {usedCodes.slice(0, 2).map((code) => (
                <div key={code.id} className="flex items-center justify-between p-3 bg-gray-50 rounded-lg">
                  <code className="font-mono text-lg font-bold text-gray-400">{code.code}</code>
                  <span className="text-xs text-gray-500">Used: {code.used_at}</span>
                </div>
              ))}
            </div>
          </div>
        </div>

        <div className="card p-6">
          <h2 className="text-lg font-semibold text-gray-900 mb-4">Purchase History</h2>
          <div className="space-y-4">
            {[
              { date: '2026-05-10', seats: 50, amount: 'Rp 6.000.000' },
              { date: '2026-04-05', seats: 50, amount: 'Rp 6.000.000' },
              { date: '2026-03-01', seats: 50, amount: 'Rp 6.000.000' },
            ].map((purchase, idx) => (
              <div key={idx} className="flex items-center justify-between p-4 bg-gray-50 rounded-lg">
                <div>
                  <p className="font-medium text-gray-900">{purchase.seats} seats</p>
                  <p className="text-sm text-gray-500">{purchase.date}</p>
                </div>
                <div className="text-right">
                  <p className="font-medium text-gray-900">{purchase.amount}</p>
                  <button className="text-xs text-emerald-600">Download Invoice</button>
                </div>
              </div>
            ))}
          </div>
        </div>
      </div>

      {showPurchaseModal && (
        <div className="fixed inset-0 bg-black/50 flex items-center justify-center z-50">
          <div className="bg-white rounded-xl p-6 w-full max-w-md">
            <h3 className="text-lg font-semibold text-gray-900 mb-4">Purchase Seat Licenses</h3>
            <div className="space-y-4">
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">Number of Seats</label>
                <select className="input">
                  <option>50 seats - Rp 6.000.000</option>
                  <option>100 seats - Rp 11.000.000</option>
                  <option>200 seats - Rp 20.000.000</option>
                </select>
              </div>
              <div className="flex gap-3">
                <button onClick={() => setShowPurchaseModal(false)} className="flex-1 px-4 py-2 border border-gray-300 rounded-lg hover:bg-gray-50">
                  Cancel
                </button>
                <button className="flex-1 px-4 py-2 bg-emerald-600 text-white rounded-lg hover:bg-emerald-700">
                  Proceed to Payment
                </button>
              </div>
            </div>
          </div>
        </div>
      )}

      {showRedeemModal && (
        <div className="fixed inset-0 bg-black/50 flex items-center justify-center z-50">
          <div className="bg-white rounded-xl p-6 w-full max-w-md">
            <h3 className="text-lg font-semibold text-gray-900 mb-4">Generate Redeem Codes</h3>
            <div className="space-y-4">
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">Number of Codes</label>
                <input type="number" min="1" max="50" defaultValue="10" className="input" />
              </div>
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">Expiry Date</label>
                <input type="date" className="input" />
              </div>
              <div className="flex gap-3">
                <button onClick={() => setShowRedeemModal(false)} className="flex-1 px-4 py-2 border border-gray-300 rounded-lg hover:bg-gray-50">
                  Cancel
                </button>
                <button className="flex-1 px-4 py-2 bg-emerald-600 text-white rounded-lg hover:bg-emerald-700">
                  Generate
                </button>
              </div>
            </div>
          </div>
        </div>
      )}
    </div>
  )
}
