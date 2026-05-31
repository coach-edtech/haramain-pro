import { Search, AlertTriangle, Mail, Phone, Eye, Ban, CheckCircle, UserCog, X, ChevronDown, ChevronUp, History, Shield, ShieldAlert, ShieldCheck } from 'lucide-react'
import { useState, useEffect, useMemo } from 'react'
import { supabase } from '../../lib/supabase'
import type { Profile } from '../../types'

// Extended profile with fraud risk fields
interface UserWithFraud extends Profile {
  fraud_score?: number
  fraud_flags?: string[]
  ban_reason?: string
  banned_at?: string
  banned_by?: string
  ban_history?: BanRecord[]
}

interface BanRecord {
  id: string
  banned_by: string
  reason: string
  banned_at: string
  unbanned_by?: string
  unbanned_at?: string
}

// Fraud risk thresholds
const FRAUD_THRESHOLDS = {
  LOW: 30,
  MEDIUM: 60,
  HIGH: 80,
}

function getFraudRiskBadge(score: number) {
  if (score >= FRAUD_THRESHOLDS.HIGH) {
    return (
      <span className="inline-flex items-center gap-1 px-2 py-1 rounded-full text-xs font-medium bg-danger-100 text-danger-700">
        <ShieldAlert className="w-3 h-3" />
        High Risk ({score})
      </span>
    )
  }
  if (score >= FRAUD_THRESHOLDS.MEDIUM) {
    return (
      <span className="inline-flex items-center gap-1 px-2 py-1 rounded-full text-xs font-medium bg-amber-100 text-amber-700">
        <Shield className="w-3 h-3" />
        Medium ({score})
      </span>
    )
  }
  if (score >= FRAUD_THRESHOLDS.LOW) {
    return (
      <span className="inline-flex items-center gap-1 px-2 py-1 rounded-full text-xs font-medium bg-yellow-100 text-yellow-700">
        <Shield className="w-3 h-3" />
        Low ({score})
      </span>
    )
  }
  return (
    <span className="inline-flex items-center gap-1 px-2 py-1 rounded-full text-xs font-medium bg-emerald-100 text-emerald-700">
      <ShieldCheck className="w-3 h-3" />
      Safe ({score})
    </span>
  )
}

// Compute fraud score from profile data (demo implementation)
function computeFraudScore(user: Profile): number {
  let score = 0
  const flags: string[] = []

  // New account (< 7 days)
  const created = new Date(user.created_at)
  const daysSinceCreation = (Date.now() - created.getTime()) / (1000 * 60 * 60 * 24)
  if (daysSinceCreation < 7) { score += 20; flags.push('new_account') }

  // Suspicious status
  if (user.status === 'suspended') { score += 40; flags.push('suspended') }
  if (user.status === 'inactive') { score += 10; flags.push('inactive') }

  // No phone verified
  if (!user.phone) { score += 15; flags.push('no_phone') }

  // Jamaah role with no group
  if (user.role === 'jamaah' && !user.group_name) { score += 25; flags.push('no_group') }

  // Expired subscription
  if (user.subscription_tier === 'expired') { score += 20; flags.push('expired_subscription') }

  return Math.min(score, 100)
}

interface UserDetailModalProps {
  user: UserWithFraud
  onClose: () => void
  onBan: (userId: string, reason: string) => void
  onUnban: (userId: string) => void
}

function UserDetailModal({ user, onClose, onBan, onUnban }: UserDetailModalProps) {
  const [showBanForm, setShowBanForm] = useState(false)
  const [banReason, setBanReason] = useState('')
  const [activeTab, setActiveTab] = useState<'details' | 'history'>('details')

  const fraudScore = user.fraud_score ?? computeFraudScore(user)
  const fraudFlags = user.fraud_flags ?? []

  const handleBan = () => {
    if (banReason.trim()) {
      onBan(user.id, banReason)
      setShowBanForm(false)
    }
  }

  return (
    <div className="fixed inset-0 bg-black/50 flex items-center justify-center z-50 p-4">
      <div className="bg-white rounded-2xl shadow-xl w-full max-w-2xl max-h-[90vh] overflow-hidden">
        {/* Header */}
        <div className="flex items-center justify-between p-6 border-b border-slate-100">
          <div className="flex items-center gap-4">
            <div className="w-12 h-12 bg-gradient-to-br from-accent-400 to-accent-600 rounded-full flex items-center justify-center">
              <span className="text-white font-semibold">
                {user.name.split(' ').map(n => n[0]).join('')}
              </span>
            </div>
            <div>
              <h2 className="text-xl font-semibold text-slate-900">{user.name}</h2>
              <p className="text-sm text-slate-500">{user.email}</p>
            </div>
          </div>
          <button onClick={onClose} className="p-2 hover:bg-slate-100 rounded-lg transition-colors">
            <X className="w-5 h-5 text-slate-500" />
          </button>
        </div>

        {/* Tabs */}
        <div className="flex border-b border-slate-100">
          <button
            onClick={() => setActiveTab('details')}
            className={`flex-1 px-6 py-3 text-sm font-medium transition-colors ${
              activeTab === 'details'
                ? 'text-accent-600 border-b-2 border-accent-600'
                : 'text-slate-500 hover:text-slate-700'
            }`}
          >
            User Details
          </button>
          <button
            onClick={() => setActiveTab('history')}
            className={`flex-1 px-6 py-3 text-sm font-medium transition-colors flex items-center justify-center gap-2 ${
              activeTab === 'history'
                ? 'text-accent-600 border-b-2 border-accent-600'
                : 'text-slate-500 hover:text-slate-700'
            }`}
          >
            <History className="w-4 h-4" />
            Ban History
          </button>
        </div>

        {/* Content */}
        <div className="p-6 overflow-y-auto max-h-[60vh]">
          {activeTab === 'details' ? (
            <div className="space-y-6">
              {/* Fraud Risk Section */}
              <div className="bg-slate-50 rounded-xl p-4">
                <div className="flex items-center justify-between mb-3">
                  <h3 className="font-medium text-slate-900">Fraud Risk Assessment</h3>
                  {getFraudRiskBadge(fraudScore)}
                </div>
                {fraudFlags.length > 0 ? (
                  <div className="flex flex-wrap gap-2">
                    {fraudFlags.map((flag) => (
                      <span key={flag} className="inline-flex items-center gap-1 px-2 py-1 bg-amber-100 text-amber-700 rounded text-xs">
                        <AlertTriangle className="w-3 h-3" />
                        {flag.replace('_', ' ')}
                      </span>
                    ))}
                  </div>
                ) : (
                  <p className="text-sm text-slate-500">No risk flags detected</p>
                )}
              </div>

              {/* User Info Grid */}
              <div className="grid grid-cols-2 gap-4">
                <div>
                  <label className="block text-xs font-medium text-slate-500 mb-1">User ID</label>
                  <p className="text-sm text-slate-900 font-mono">{user.id}</p>
                </div>
                <div>
                  <label className="block text-xs font-medium text-slate-500 mb-1">Phone</label>
                  <p className="text-sm text-slate-900">{user.phone || 'Not provided'}</p>
                </div>
                <div>
                  <label className="block text-xs font-medium text-slate-500 mb-1">Role</label>
                  <p className="text-sm text-slate-900">{user.role}</p>
                </div>
                <div>
                  <label className="block text-xs font-medium text-slate-500 mb-1">Status</label>
                  <p className="text-sm text-slate-900 capitalize">{user.status || 'unknown'}</p>
                </div>
                <div>
                  <label className="block text-xs font-medium text-slate-500 mb-1">Group</label>
                  <p className="text-sm text-slate-900">{user.group_name || 'None'}</p>
                </div>
                <div>
                  <label className="block text-xs font-medium text-slate-500 mb-1">Subscription</label>
                  <p className="text-sm text-slate-900 capitalize">{user.subscription_tier}</p>
                </div>
                <div>
                  <label className="block text-xs font-medium text-slate-500 mb-1">Last Active</label>
                  <p className="text-sm text-slate-900">{user.last_seen || 'Never'}</p>
                </div>
                <div>
                  <label className="block text-xs font-medium text-slate-500 mb-1">Member Since</label>
                  <p className="text-sm text-slate-900">{new Date(user.created_at).toLocaleDateString()}</p>
                </div>
              </div>

              {/* Ban/Unban Actions */}
              <div className="pt-4 border-t border-slate-100">
                {user.status === 'suspended' ? (
                  <div className="space-y-3">
                    <div className="flex items-center justify-between p-3 bg-danger-50 rounded-lg">
                      <div>
                        <p className="font-medium text-danger-700">User is suspended</p>
                        {user.ban_reason && (
                          <p className="text-sm text-danger-600">Reason: {user.ban_reason}</p>
                        )}
                        {user.banned_at && (
                          <p className="text-xs text-danger-500">
                            Suspended on {new Date(user.banned_at).toLocaleString()}
                          </p>
                        )}
                      </div>
                    </div>
                    <button
                      onClick={() => onUnban(user.id)}
                      className="w-full btn-secondary flex items-center justify-center gap-2"
                    >
                      <CheckCircle className="w-4 h-4" />
                      Remove Suspension
                    </button>
                  </div>
                ) : showBanForm ? (
                  <div className="space-y-3">
                    <textarea
                      value={banReason}
                      onChange={(e) => setBanReason(e.target.value)}
                      placeholder="Enter reason for suspension..."
                      className="input min-h-[80px]"
                    />
                    <div className="flex gap-2">
                      <button
                        onClick={() => setShowBanForm(false)}
                        className="flex-1 btn-secondary"
                      >
                        Cancel
                      </button>
                      <button
                        onClick={handleBan}
                        disabled={!banReason.trim()}
                        className="flex-1 btn-danger disabled:opacity-50"
                      >
                        Confirm Suspension
                      </button>
                    </div>
                  </div>
                ) : (
                  <button
                    onClick={() => setShowBanForm(true)}
                    className="w-full btn-danger flex items-center justify-center gap-2"
                  >
                    <Ban className="w-4 h-4" />
                    Suspend User
                  </button>
                )}
              </div>
            </div>
          ) : (
            <div className="space-y-4">
              {user.ban_history && user.ban_history.length > 0 ? (
                user.ban_history.map((record) => (
                  <div key={record.id} className="p-4 bg-slate-50 rounded-lg space-y-2">
                    <div className="flex items-center justify-between">
                      <span className="font-medium text-slate-900">
                        {record.unbanned_at ? 'Unbanned' : 'Banned'}
                      </span>
                      <span className="text-sm text-slate-500">
                        {new Date(record.unbanned_at || record.banned_at).toLocaleString()}
                      </span>
                    </div>
                    <p className="text-sm text-slate-600">
                      By: {record.unbanned_by || record.banned_by}
                    </p>
                    {record.reason && (
                      <p className="text-sm text-slate-500">Reason: {record.reason}</p>
                    )}
                  </div>
                ))
              ) : (
                <div className="text-center py-8">
                  <History className="w-12 h-12 text-slate-300 mx-auto mb-3" />
                  <p className="text-slate-500">No ban history</p>
                </div>
              )}
            </div>
          )}
        </div>
      </div>
    </div>
  )
}

export default function UsersAdmin() {
  const [users, setUsers] = useState<UserWithFraud[]>([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)
  const [search, setSearch] = useState('')
  const [roleFilter, setRoleFilter] = useState<'all' | 'travel_admin' | 'team_support' | 'jamaah'>('all')
  const [selectedUsers, setSelectedUsers] = useState<Set<string>>(new Set())
  const [showBulkBanModal, setShowBulkBanModal] = useState(false)
  const [bulkBanReason, setBulkBanReason] = useState('')
  const [selectedUser, setSelectedUser] = useState<UserWithFraud | null>(null)
  const [showFraudOnly, setShowFraudOnly] = useState(false)

  useEffect(() => {
    fetchUsers()
  }, [])

  async function fetchUsers() {
    try {
      const { data, error: err } = await supabase
        .from('profiles')
        .select('*')
        .order('created_at', { ascending: false })
        .limit(100)

      if (err) throw err

      // Attach computed fraud data
      const usersWithFraud = ((data || []) as Profile[]).map(user => ({
        ...user,
        fraud_score: computeFraudScore(user),
        fraud_flags: getFraudFlags(user),
      }))

      setUsers(usersWithFraud)
    } catch (e) {
      setError(String(e))
    } finally {
      setLoading(false)
    }
  }

  function getFraudFlags(user: Profile): string[] {
    const flags: string[] = []
    const created = new Date(user.created_at)
    const daysSinceCreation = (Date.now() - created.getTime()) / (1000 * 60 * 60 * 24)
    if (daysSinceCreation < 7) flags.push('new_account')
    if (user.status === 'suspended') flags.push('suspended')
    if (user.status === 'inactive') flags.push('inactive')
    if (!user.phone) flags.push('no_phone')
    if (user.role === 'jamaah' && !user.group_name) flags.push('no_group')
    if (user.subscription_tier === 'expired') flags.push('expired_subscription')
    return flags
  }

  const filteredUsers = useMemo(() => {
    return users.filter(user => {
      const matchesSearch =
        user.name.toLowerCase().includes(search.toLowerCase()) ||
        user.email.toLowerCase().includes(search.toLowerCase()) ||
        (user.phone || '').includes(search)
      const matchesRole = roleFilter === 'all' || user.role === roleFilter
      const matchesFraud = !showFraudOnly || (user.fraud_score ?? 0) >= FRAUD_THRESHOLDS.MEDIUM
      return matchesSearch && matchesRole && matchesFraud
    })
  }, [users, search, roleFilter, showFraudOnly])

  const handleBanUser = async (userId: string, reason: string) => {
    try {
      const { error: err } = await supabase
        .from('profiles')
        .update({ status: 'suspended' })
        .eq('id', userId)

      if (err) throw err

      // Update local state
      setUsers(prev => prev.map(u =>
        u.id === userId
          ? { ...u, status: 'suspended', ban_reason: reason, banned_at: new Date().toISOString() }
          : u
      ))
      setSelectedUser(null)
    } catch (e) {
      console.error('Failed to ban user:', e)
    }
  }

  const handleUnbanUser = async (userId: string) => {
    try {
      const { error: err } = await supabase
        .from('profiles')
        .update({ status: 'active' })
        .eq('id', userId)

      if (err) throw err

      setUsers(prev => prev.map(u =>
        u.id === userId
          ? { ...u, status: 'active', ban_reason: undefined, banned_at: undefined }
          : u
      ))
      setSelectedUser(null)
    } catch (e) {
      console.error('Failed to unban user:', e)
    }
  }

  const handleBulkBan = async () => {
    if (!bulkBanReason.trim() || selectedUsers.size === 0) return

    try {
      const userIds = Array.from(selectedUsers)
      const { error: err } = await supabase
        .from('profiles')
        .update({ status: 'suspended' })
        .in('id', userIds)

      if (err) throw err

      setUsers(prev => prev.map(u =>
        selectedUsers.has(u.id)
          ? { ...u, status: 'suspended', ban_reason: bulkBanReason, banned_at: new Date().toISOString() }
          : u
      ))
      setSelectedUsers(new Set())
      setShowBulkBanModal(false)
      setBulkBanReason('')
    } catch (e) {
      console.error('Failed to bulk ban:', e)
    }
  }

  const toggleUserSelection = (userId: string) => {
    setSelectedUsers(prev => {
      const next = new Set(prev)
      if (next.has(userId)) {
        next.delete(userId)
      } else {
        next.add(userId)
      }
      return next
    })
  }

  const toggleAllSelection = () => {
    if (selectedUsers.size === filteredUsers.length) {
      setSelectedUsers(new Set())
    } else {
      setSelectedUsers(new Set(filteredUsers.map(u => u.id)))
    }
  }

  const stats = {
    total: users.length,
    active: users.filter(u => u.status === 'active').length,
    newToday: users.filter(u => {
      const created = new Date(u.created_at)
      const today = new Date()
      return created.toDateString() === today.toDateString()
    }).length,
    fraudFlags: users.filter(u => (u.fraud_score ?? 0) >= FRAUD_THRESHOLDS.MEDIUM).length
  }

  if (loading) {
    return (
      <div className="flex items-center justify-center h-64">
        <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-emerald-600" />
      </div>
    )
  }

  if (error) {
    return (
      <div className="flex items-center justify-center h-64">
        <div className="text-center">
          <p className="text-red-600 font-medium">{error}</p>
          <button onClick={fetchUsers} className="mt-2 text-emerald-600 underline">Retry</button>
        </div>
      </div>
    )
  }

  return (
    <div className="space-y-6">
      {/* Page Header */}
      <div className="flex items-center justify-between">
        <div className="page-header mb-0">
          <h1 className="page-title">User Management</h1>
          <p className="page-subtitle">Platform-wide user search and management</p>
        </div>
        <div className="flex gap-3">
          <button
            onClick={() => setShowFraudOnly(!showFraudOnly)}
            className={`btn-secondary flex items-center gap-2 ${showFraudOnly ? 'bg-danger-100 text-danger-700 border-danger-200' : ''}`}
          >
            <AlertTriangle className="w-4 h-4" />
            Fraud Flags ({stats.fraudFlags})
          </button>
          {selectedUsers.size > 0 && (
            <button
              onClick={() => setShowBulkBanModal(true)}
              className="btn-danger flex items-center gap-2"
            >
              <Ban className="w-4 h-4" />
              Ban Selected ({selectedUsers.size})
            </button>
          )}
          <button className="btn-primary flex items-center gap-2">
            <UserCog className="w-4 h-4" />
            Add User
          </button>
        </div>
      </div>

      {/* Stats */}
      <div className="grid grid-cols-1 md:grid-cols-4 gap-4">
        <div className="card p-4 flex items-center gap-4">
          <div className="p-3 bg-primary-100 rounded-xl">
            <Mail className="w-6 h-6 text-primary-600" />
          </div>
          <div>
            <p className="text-2xl font-bold text-slate-900">{stats.total}</p>
            <p className="text-sm text-slate-500">Total Users</p>
          </div>
        </div>
        <div className="card p-4 flex items-center gap-4">
          <div className="p-3 bg-emerald-100 rounded-xl">
            <CheckCircle className="w-6 h-6 text-emerald-600" />
          </div>
          <div>
            <p className="text-2xl font-bold text-slate-900">{stats.active}</p>
            <p className="text-sm text-slate-500">Active</p>
          </div>
        </div>
        <div className="card p-4 flex items-center gap-4">
          <div className="p-3 bg-accent-100 rounded-xl">
            <Phone className="w-6 h-6 text-accent-600" />
          </div>
          <div>
            <p className="text-2xl font-bold text-slate-900">{stats.newToday}</p>
            <p className="text-sm text-slate-500">New Today</p>
          </div>
        </div>
        <div className="card p-4 flex items-center gap-4">
          <div className="p-3 bg-danger-100 rounded-xl">
            <AlertTriangle className="w-6 h-6 text-danger-600" />
          </div>
          <div>
            <p className="text-2xl font-bold text-danger-600">{stats.fraudFlags}</p>
            <p className="text-sm text-slate-500">Fraud Flags</p>
          </div>
        </div>
      </div>

      {/* Users Table */}
      <div className="card">
        <div className="p-4 border-b border-slate-100">
          <div className="flex flex-col md:flex-row gap-4">
            {/* Search */}
            <div className="relative flex-1">
              <Search className="absolute left-3 top-1/2 -translate-y-1/2 w-5 h-5 text-slate-400" />
              <input
                type="text"
                placeholder="Search by name, email, or phone..."
                value={search}
                onChange={(e) => setSearch(e.target.value)}
                className="input pl-10"
              />
            </div>
            {/* Role Filter */}
            <div className="flex gap-2">
              {(['all', 'travel_admin', 'team_support', 'jamaah'] as const).map((f) => (
                <button
                  key={f}
                  onClick={() => setRoleFilter(f)}
                  className={`px-3 py-2 text-sm font-medium rounded-lg transition-colors ${
                    roleFilter === f
                      ? 'bg-accent-500 text-white'
                      : 'bg-slate-100 text-slate-600 hover:bg-slate-200'
                  }`}
                >
                  {f === 'all' ? 'All' : f.replace('_', ' ')}
                </button>
              ))}
            </div>
          </div>
        </div>
        <div className="overflow-x-auto">
          <table className="w-full">
            <thead>
              <tr className="table-header">
                <th className="px-4 py-3 text-left w-10">
                  <input
                    type="checkbox"
                    checked={selectedUsers.size === filteredUsers.length && filteredUsers.length > 0}
                    onChange={toggleAllSelection}
                    className="rounded border-slate-300 text-accent-600 focus:ring-accent-500"
                  />
                </th>
                <th className="px-6 py-3 text-left">User</th>
                <th className="px-6 py-3 text-left">Contact</th>
                <th className="px-6 py-3 text-left">Role</th>
                <th className="px-6 py-3 text-left">Travel/Group</th>
                <th className="px-6 py-3 text-left">Fraud Risk</th>
                <th className="px-6 py-3 text-left">Status</th>
                <th className="px-6 py-3 text-left">Last Active</th>
                <th className="px-6 py-3 text-left">Actions</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-slate-100">
              {filteredUsers.map((user) => (
                <tr key={user.id} className={`table-row ${selectedUsers.has(user.id) ? 'bg-accent-50' : ''}`}>
                  <td className="px-4 py-4">
                    <input
                      type="checkbox"
                      checked={selectedUsers.has(user.id)}
                      onChange={() => toggleUserSelection(user.id)}
                      className="rounded border-slate-300 text-accent-600 focus:ring-accent-500"
                    />
                  </td>
                  <td className="px-6 py-4">
                    <div className="flex items-center gap-3">
                      <div className="w-10 h-10 bg-gradient-to-br from-accent-400 to-accent-600 rounded-full flex items-center justify-center">
                        <span className="text-white font-semibold text-sm">
                          {user.name.split(' ').map(n => n[0]).join('')}
                        </span>
                      </div>
                      <div>
                        <p className="font-medium text-slate-900">{user.name}</p>
                        <p className="text-xs text-slate-400">ID: {user.id.slice(0, 8)}...</p>
                      </div>
                    </div>
                  </td>
                  <td className="px-6 py-4">
                    <div className="space-y-1">
                      <p className="text-slate-600 flex items-center gap-1.5 text-sm">
                        <Mail className="w-3.5 h-3.5 text-slate-400" />
                        {user.email}
                      </p>
                      <p className="text-slate-500 flex items-center gap-1.5 text-xs">
                        <Phone className="w-3.5 h-3.5 text-slate-400" />
                        {user.phone || '-'}
                      </p>
                    </div>
                  </td>
                  <td className="px-6 py-4">
                    <span className="badge badge-info">{user.role.replace('_', ' ')}</span>
                  </td>
                  <td className="px-6 py-4">
                    <p className="font-medium text-slate-900">{user.group_name || '-'}</p>
                  </td>
                  <td className="px-6 py-4">
                    {getFraudRiskBadge(user.fraud_score ?? 0)}
                  </td>
                  <td className="px-6 py-4">
                    <span className={`badge ${
                      user.status === 'active' ? 'badge-success' :
                      user.status === 'suspended' ? 'badge-danger' : 'badge-info'
                    }`}>
                      {user.status || 'unknown'}
                    </span>
                  </td>
                  <td className="px-6 py-4 text-slate-500 text-sm">{user.last_seen || '-'}</td>
                  <td className="px-6 py-4">
                    <div className="flex items-center gap-1">
                      <button
                        onClick={() => setSelectedUser(user)}
                        className="p-2 text-slate-500 hover:bg-slate-100 rounded-lg transition-colors"
                      >
                        <Eye className="w-4 h-4" />
                      </button>
                      <button className="p-2 text-accent-600 hover:bg-accent-50 rounded-lg transition-colors">
                        <UserCog className="w-4 h-4" />
                      </button>
                      {user.status === 'active' || user.status === 'inactive' ? (
                        <button
                          onClick={() => setSelectedUser({ ...user, status: 'suspended' } as UserWithFraud)}
                          className="p-2 text-danger-600 hover:bg-danger-50 rounded-lg transition-colors"
                        >
                          <Ban className="w-4 h-4" />
                        </button>
                      ) : (
                        <button
                          onClick={() => handleUnbanUser(user.id)}
                          className="p-2 text-emerald-600 hover:bg-emerald-50 rounded-lg transition-colors"
                        >
                          <CheckCircle className="w-4 h-4" />
                        </button>
                      )}
                    </div>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
        {filteredUsers.length === 0 && (
          <div className="p-8 text-center">
            <Search className="w-12 h-12 text-slate-300 mx-auto mb-3" />
            <p className="text-slate-500">No users found matching your criteria</p>
          </div>
        )}
      </div>

      {/* User Detail Modal */}
      {selectedUser && (
        <UserDetailModal
          user={selectedUser}
          onClose={() => setSelectedUser(null)}
          onBan={handleBanUser}
          onUnban={handleUnbanUser}
        />
      )}

      {/* Bulk Ban Modal */}
      {showBulkBanModal && (
        <div className="fixed inset-0 bg-black/50 flex items-center justify-center z-50 p-4">
          <div className="bg-white rounded-2xl shadow-xl w-full max-w-md p-6">
            <div className="flex items-center justify-between mb-4">
              <h2 className="text-lg font-semibold text-slate-900">Bulk Suspend Users</h2>
              <button
                onClick={() => setShowBulkBanModal(false)}
                className="p-2 hover:bg-slate-100 rounded-lg transition-colors"
              >
                <X className="w-5 h-5 text-slate-500" />
              </button>
            </div>
            <p className="text-sm text-slate-600 mb-4">
              You are about to suspend <strong>{selectedUsers.size}</strong> users. This action can be reversed individually.
            </p>
            <textarea
              value={bulkBanReason}
              onChange={(e) => setBulkBanReason(e.target.value)}
              placeholder="Enter reason for suspension..."
              className="input min-h-[100px] mb-4"
            />
            <div className="flex gap-3">
              <button
                onClick={() => setShowBulkBanModal(false)}
                className="flex-1 btn-secondary"
              >
                Cancel
              </button>
              <button
                onClick={handleBulkBan}
                disabled={!bulkBanReason.trim()}
                className="flex-1 btn-danger disabled:opacity-50"
              >
                Suspend {selectedUsers.size} Users
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  )
}
