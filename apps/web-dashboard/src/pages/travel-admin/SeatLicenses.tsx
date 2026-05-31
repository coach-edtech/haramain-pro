import { Shield, ShoppingCart, Key, AlertTriangle, Loader2 } from 'lucide-react'
import { useState } from 'react'
import { useSeatLicenseBalance, useSeatLicenseCheckout, useRedeemCodes, useGenerateRedeemCodes } from '../../lib/api'
import { useAgencyProfile } from '../../hooks/useAgencyProfile'

export default function SeatLicensesTravelAdmin() {
  const { profile, loading: profileLoading } = useAgencyProfile()
  const [showPurchaseModal, setShowPurchaseModal] = useState(false)
  const [showRedeemModal, setShowRedeemModal] = useState(false)
  const [redeemQty, setRedeemQty] = useState(1)
  const [redeemType, setRedeemType] = useState<'jama_redeem' | 'team_invite'>('jama_redeem')

  const { data: balance, isLoading, error } = useSeatLicenseBalance(profile?.agency_id)
  const { data: codesData } = useRedeemCodes(profile?.agency_id)
  const checkoutMutation = useSeatLicenseCheckout()
  const generateMutation = useGenerateRedeemCodes()

  const seatBalance = balance?.seat_balance ?? 0
  const totalPurchased = balance?.total_purchased ?? 0
  const totalConsumed = balance?.total_consumed ?? 0
  const alertThreshold = balance?.alert?.threshold ?? 20

  async function handlePurchase(packageId: string) {
    try {
      const result = await checkoutMutation.mutateAsync(packageId)
      if (result.xendit_checkout_url) {
        window.open(result.xendit_checkout_url, '_blank')
      }
    } catch (e) {
      alert(String(e))
    }
  }

  async function handleGenerateCodes() {
    if (!profile?.agency_id) return
    try {
      await generateMutation.mutateAsync({
        agency_id: profile.agency_id,
        quantity: redeemQty,
        type: redeemType,
      })
      setShowRedeemModal(false)
      setRedeemQty(1)
    } catch (e) {
      alert(String(e))
    }
  }

  const packages = [
    { id: 'pkg_10', label: '10 seats', price: 'Rp 900.000', pricePerSeat: 'Rp 90.000' },
    { id: 'pkg_50', label: '50 seats', price: 'Rp 4.000.000', pricePerSeat: 'Rp 80.000' },
    { id: 'pkg_100', label: '100 seats', price: 'Rp 7.000.000', pricePerSeat: 'Rp 70.000' },
  ]

  if (profileLoading || isLoading) {
    return (
      <div className="flex items-center justify-center h-64">
        <Loader2 className="w-8 h-8 animate-spin text-emerald-600" />
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

  const hasNoBalance = seatBalance === 0 && totalPurchased === 0

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

      {hasNoBalance ? (
        <div className="card p-12 text-center">
          <Shield className="w-12 h-12 text-gray-300 mx-auto mb-4" />
          <h3 className="text-lg font-semibold text-gray-900 mb-2">No Licenses Yet</h3>
          <p className="text-gray-500 mb-4">
            {profile?.agency_id
              ? "You haven't purchased any seat licenses yet."
              : "Your account is not linked to an agency. Contact support to set up your travel agency."}
          </p>
          {profile?.agency_id && (
            <button
              onClick={() => setShowPurchaseModal(true)}
              className="px-4 py-2 bg-emerald-600 text-white rounded-lg hover:bg-emerald-700"
            >
              Purchase First License
            </button>
          )}
        </div>
      ) : (
        <>
          <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
            <div className="card p-6">
              <div className="flex items-start justify-between">
                <div>
                  <p className="text-sm text-gray-500 mb-1">Total Seats</p>
                  <p className="text-3xl font-bold text-gray-900">{totalPurchased}</p>
                </div>
                <div className="p-3 bg-emerald-50 rounded-lg">
                  <Shield className="w-6 h-6 text-emerald-600" />
                </div>
              </div>
              <div className="mt-4">
                <div className="flex justify-between text-sm mb-1">
                  <span className="text-gray-500">Usage</span>
                  <span className="font-medium">{totalConsumed} / {totalPurchased}</span>
                </div>
                <div className="bg-gray-200 rounded-full h-2">
                  <div
                    className="bg-emerald-500 h-2 rounded-full"
                    style={{ width: totalPurchased > 0 ? `${(totalConsumed / totalPurchased) * 100}%` : '0%' }}
                  />
                </div>
              </div>
            </div>

            <div className="card p-6">
              <div className="flex items-start justify-between">
                <div>
                  <p className="text-sm text-gray-500 mb-1">Available</p>
                  <p className="text-3xl font-bold text-emerald-600">{seatBalance}</p>
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
                  <p className={`text-3xl font-bold ${seatBalance < 10 ? 'text-red-600' : 'text-gray-900'}`}>
                    {seatBalance < 10 ? <><AlertTriangle className="w-6 h-6 inline mr-2" />{seatBalance}</> : 'Good'}
                  </p>
                </div>
                <div className={`p-3 rounded-lg ${seatBalance < 10 ? 'bg-red-50' : 'bg-gray-50'}`}>
                  <AlertTriangle className={`w-6 h-6 ${seatBalance < 10 ? 'text-red-600' : 'text-gray-400'}`} />
                </div>
              </div>
            </div>
          </div>

          {/* Recent Transactions */}
          {balance?.recent_transactions && balance.recent_transactions.length > 0 && (
            <div className="card">
              <div className="p-4 border-b border-gray-200 flex items-center justify-between">
                <h2 className="text-lg font-semibold text-gray-900">Recent Transactions</h2>
              </div>
              <div className="overflow-x-auto">
                <table className="w-full">
                  <thead className="bg-gray-50">
                    <tr>
                      <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Type</th>
                      <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Qty</th>
                      <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Balance After</th>
                      <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Date</th>
                    </tr>
                  </thead>
                  <tbody className="divide-y divide-gray-200">
                    {balance.recent_transactions.map((tx) => (
                      <tr key={tx.id} className="hover:bg-gray-50">
                        <td className="px-6 py-4">
                          <span className={`px-2 py-1 text-xs font-medium rounded-full ${
                            tx.type === 'purchase' ? 'bg-emerald-100 text-emerald-700' :
                            tx.type === 'consume' ? 'bg-blue-100 text-blue-700' :
                            'bg-gray-100 text-gray-700'
                          }`}>
                            {tx.type}
                          </span>
                        </td>
                        <td className="px-6 py-4 font-medium text-gray-900">
                          {tx.quantity > 0 ? `+${tx.quantity}` : tx.quantity}
                        </td>
                        <td className="px-6 py-4 text-gray-600">{tx.balance_after}</td>
                        <td className="px-6 py-4 text-gray-500 text-sm">
                          {new Date(tx.created_at).toLocaleDateString('id-ID', { day: '2-digit', month: 'short', year: 'numeric' })}
                        </td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              </div>
            </div>
          )}
        </>
      )}

      {showPurchaseModal && (
        <div className="fixed inset-0 bg-black/50 flex items-center justify-center z-50">
          <div className="bg-white rounded-xl p-6 w-full max-w-md">
            <h3 className="text-lg font-semibold text-gray-900 mb-4">Purchase Seat Licenses</h3>
            <div className="space-y-3">
              {packages.map((pkg) => (
                <button
                  key={pkg.id}
                  onClick={() => { handlePurchase(pkg.id); setShowPurchaseModal(false) }}
                  className="w-full p-4 border border-gray-200 rounded-lg hover:border-emerald-500 hover:bg-emerald-50 text-left transition-colors"
                >
                  <div className="flex justify-between items-center">
                    <div>
                      <p className="font-semibold text-gray-900">{pkg.label}</p>
                      <p className="text-sm text-gray-500">{pkg.pricePerSeat}/seat</p>
                    </div>
                    <p className="font-bold text-gray-900">{pkg.price}</p>
                  </div>
                </button>
              ))}
            </div>
            <button
              onClick={() => setShowPurchaseModal(false)}
              className="w-full mt-3 px-4 py-2 border border-gray-300 rounded-lg hover:bg-gray-50"
            >
              Cancel
            </button>
          </div>
        </div>
      )}

      {showRedeemModal && (
        <div className="fixed inset-0 bg-black/50 flex items-center justify-center z-50">
          <div className="bg-white rounded-xl p-6 w-full max-w-md">
            <h3 className="text-lg font-semibold text-gray-900 mb-4">Generate Redeem Codes</h3>
            <div className="space-y-4">
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">Quantity</label>
                <input
                  type="number"
                  min={1}
                  max={100}
                  value={redeemQty}
                  onChange={e => setRedeemQty(Math.max(1, parseInt(e.target.value) || 1))}
                  className="input w-full"
                />
              </div>
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">Type</label>
                <select
                  value={redeemType}
                  onChange={e => setRedeemType(e.target.value as typeof redeemType)}
                  className="input w-full"
                >
                  <option value="jama_redeem">Jamaah Redeem</option>
                  <option value="team_invite">Team Invite</option>
                </select>
              </div>
              <p className="text-sm text-gray-500">
                This will consume {redeemQty} seat{redeemQty > 1 ? 's' : ''} from your balance.
                Available: {seatBalance}
              </p>
              <div className="flex gap-3">
                <button
                  onClick={() => setShowRedeemModal(false)}
                  className="flex-1 px-4 py-2 border border-gray-300 rounded-lg hover:bg-gray-50"
                >
                  Cancel
                </button>
                <button
                  onClick={handleGenerateCodes}
                  disabled={generateMutation.isPending || redeemQty > seatBalance || seatBalance === 0}
                  className="flex-1 px-4 py-2 bg-emerald-600 text-white rounded-lg hover:bg-emerald-700 disabled:opacity-50 flex items-center justify-center gap-2"
                >
                  {generateMutation.isPending && <Loader2 className="w-4 h-4 animate-spin" />}
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
