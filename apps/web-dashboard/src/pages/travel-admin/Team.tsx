import { UserPlus, Mail, Search, Users, Loader2, UserCog, MapPin } from 'lucide-react'
import { useState } from 'react'
import { useTeamMembers, useInviteAgent, useRombongans, useAssignMuthawif } from '../../lib/api'
import { useAgencyProfile } from '../../hooks/useAgencyProfile'

type TeamTab = 'members' | 'muthawif'

export default function TeamTravelAdmin() {
  const { profile } = useAgencyProfile()
  const [activeTab, setActiveTab] = useState<TeamTab>('members')
  const [showInviteModal, setShowInviteModal] = useState(false)
  const [showAssignModal, setShowAssignModal] = useState(false)
  const [search, setSearch] = useState('')
  const [inviteEmail, setInviteEmail] = useState('')
  const [inviteName, setInviteName] = useState('')
  const [inviteRole, setInviteRole] = useState('team_support')
  const [assigningMuthawif, setAssigningMuthawif] = useState<{ id: string; name: string } | null>(null)
  const [selectedRomongan, setSelectedRomongan] = useState('')

  const { data, isLoading, error } = useTeamMembers(profile?.agency_id)
  const { data: romonganData, isLoading: romonganLoading } = useRombongans(profile?.agency_id)
  const inviteMutation = useInviteAgent()
  const assignMutation = useAssignMuthawif()

  const members = data?.members ?? []
  const muthawifMembers = members.filter(m => m.role === 'muthawif')
  const activeCount = members.filter(m => m.wl_status === 'active').length
  const pendingCount = members.filter(m => m.wl_status === 'pending').length

  const filteredMembers = search
    ? members.filter(m =>
        (m.name || '').toLowerCase().includes(search.toLowerCase()) ||
        (m.email || '').toLowerCase().includes(search.toLowerCase())
      ).filter(m => activeTab === 'muthawif' ? m.role === 'muthawif' : m.role !== 'muthawif')
    : members.filter(m => activeTab === 'muthawif' ? m.role === 'muthawif' : m.role !== 'muthawif')

  const rombongans = romonganData?.rombongans ?? []

  async function handleInvite() {
    if (!inviteEmail || !inviteName) return
    try {
      await inviteMutation.mutateAsync({ email: inviteEmail, name: inviteName, role: inviteRole })
      setShowInviteModal(false)
      setInviteEmail('')
      setInviteName('')
      setInviteRole('team_support')
    } catch (e) {
      alert(String(e))
    }
  }

  function openAssignModal(muthawif: { id: string; name: string }) {
    setAssigningMuthawif(muthawif)
    setSelectedRomongan('')
    setShowAssignModal(true)
  }

  async function handleAssign() {
    if (!assigningMuthawif || !selectedRomongan) return
    try {
      await assignMutation.mutateAsync({ romongan_id: selectedRomongan, muthawif_id: assigningMuthawif.id })
      setShowAssignModal(false)
      setAssigningMuthawif(null)
      setSelectedRomongan('')
    } catch (e) {
      alert(String(e))
    }
  }

  function getRomonganForMuthawif(muthawifId: string) {
    return rombongans.find(r => r.muthawif_id === muthawifId)
  }

  if (isLoading) {
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

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold text-gray-900">Team Management</h1>
          <p className="text-gray-500">Manage your team members, muthawif, and group assignments</p>
        </div>
        <button
          onClick={() => setShowInviteModal(true)}
          className="btn-primary flex items-center gap-2"
        >
          <UserPlus className="w-4 h-4" />
          Invite Member
        </button>
      </div>

      {/* Stats */}
      <div className="grid grid-cols-1 md:grid-cols-4 gap-6">
        <div className="card p-6">
          <div className="flex items-start justify-between">
            <div>
              <p className="text-sm text-gray-500 mb-1">Total Members</p>
              <p className="text-2xl font-bold text-gray-900">{members.length}</p>
            </div>
            <div className="p-3 bg-emerald-50 rounded-lg">
              <Users className="w-6 h-6 text-emerald-600" />
            </div>
          </div>
        </div>
        <div className="card p-6">
          <div className="flex items-start justify-between">
            <div>
              <p className="text-sm text-gray-500 mb-1">Active</p>
              <p className="text-2xl font-bold text-emerald-600">{activeCount}</p>
            </div>
            <div className="p-3 bg-emerald-50 rounded-lg">
              <Users className="w-6 h-6 text-emerald-600" />
            </div>
          </div>
        </div>
        <div className="card p-6">
          <div className="flex items-start justify-between">
            <div>
              <p className="text-sm text-gray-500 mb-1">Pending Invites</p>
              <p className="text-2xl font-bold text-yellow-600">{pendingCount}</p>
            </div>
            <div className="p-3 bg-yellow-50 rounded-lg">
              <Mail className="w-6 h-6 text-yellow-600" />
            </div>
          </div>
        </div>
        <div className="card p-6">
          <div className="flex items-start justify-between">
            <div>
              <p className="text-sm text-gray-500 mb-1">Muthawif</p>
              <p className="text-2xl font-bold text-violet-600">{muthawifMembers.length}</p>
            </div>
            <div className="p-3 bg-violet-50 rounded-lg">
              <UserCog className="w-6 h-6 text-violet-600" />
            </div>
          </div>
        </div>
      </div>

      {/* Tab Navigation */}
      <div className="border-b border-gray-200">
        <nav className="-mb-px flex gap-6">
          <button
            onClick={() => { setActiveTab('members'); setSearch('') }}
            className={`pb-3 px-1 border-b-2 font-medium text-sm transition-colors ${
              activeTab === 'members'
                ? 'border-emerald-500 text-emerald-600'
                : 'border-transparent text-gray-500 hover:text-gray-700 hover:border-gray-300'
            }`}
          >
            <Users className="w-4 h-4 inline mr-1.5" />
            Team Members
          </button>
          <button
            onClick={() => { setActiveTab('muthawif'); setSearch('') }}
            className={`pb-3 px-1 border-b-2 font-medium text-sm transition-colors flex items-center gap-1.5 ${
              activeTab === 'muthawif'
                ? 'border-emerald-500 text-emerald-600'
                : 'border-transparent text-gray-500 hover:text-gray-700 hover:border-gray-300'
            }`}
          >
            <UserCog className="w-4 h-4" />
            Muthawif
          </button>
        </nav>
      </div>

      {/* Content Card */}
      <div className="card">
        <div className="p-4 border-b border-gray-200">
          <div className="flex items-center justify-between">
            <h2 className="text-lg font-semibold text-gray-900">
              {activeTab === 'members' ? 'Team Members' : 'Muthawif'}
            </h2>
            <div className="relative max-w-xs">
              <Search className="absolute left-3 top-1/2 -translate-y-1/2 w-5 h-5 text-gray-400" />
              <input
                type="text"
                placeholder={activeTab === 'muthawif' ? 'Search muthawif...' : 'Search members...'}
                value={search}
                onChange={(e) => setSearch(e.target.value)}
                className="input pl-10"
              />
            </div>
          </div>
        </div>

        {filteredMembers.length === 0 ? (
          <div className="p-12 text-center">
            <Users className="w-12 h-12 text-gray-300 mx-auto mb-4" />
            <p className="text-gray-500">
              {search ? 'No results match your search.' : 'No members found.'}
            </p>
          </div>
        ) : (
          <div className="overflow-x-auto">
            <table className="w-full">
              <thead className="bg-gray-50">
                <tr>
                  {activeTab === 'muthawif' ? (
                    <>
                      <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Name</th>
                      <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Email</th>
                      <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Status</th>
                      <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Assigned To</th>
                      <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Actions</th>
                    </>
                  ) : (
                    <>
                      <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Name</th>
                      <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Email</th>
                      <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Role</th>
                      <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Status</th>
                      <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Invited</th>
                      <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Actions</th>
                    </>
                  )}
                </tr>
              </thead>
              <tbody className="divide-y divide-gray-200">
                {filteredMembers.map((member) => {
                  const initials = (member.name || 'U')
                    .split(' ')
                    .map(n => n[0])
                    .join('')
                    .slice(0, 2)
                    .toUpperCase()

                  const assignedRomongan = activeTab === 'muthawif' ? getRomonganForMuthawif(member.id) : null

                  return (
                    <tr key={member.id} className="hover:bg-gray-50">
                      <td className="px-6 py-4">
                        <div className="flex items-center gap-3">
                          <div className={`w-10 h-10 rounded-full flex items-center justify-center ${
                            activeTab === 'muthawif' ? 'bg-violet-100' : 'bg-blue-100'
                          }`}>
                            <span className={`font-medium text-sm ${
                              activeTab === 'muthawif' ? 'text-violet-700' : 'text-blue-700'
                            }`}>{initials}</span>
                          </div>
                          <p className="font-medium text-gray-900">{member.name}</p>
                        </div>
                      </td>
                      <td className="px-6 py-4 text-gray-600">{member.email}</td>
                      {activeTab === 'muthawif' ? (
                        <>
                          <td className="px-6 py-4">
                            <span className={`px-2 py-1 text-xs font-medium rounded-full ${
                              member.wl_status === 'active'
                                ? 'bg-emerald-100 text-emerald-700'
                                : 'bg-yellow-100 text-yellow-700'
                            }`}>
                              {member.wl_status}
                            </span>
                          </td>
                          <td className="px-6 py-4">
                            {assignedRomongan ? (
                              <span className="inline-flex items-center gap-1 px-2 py-1 text-xs font-medium bg-violet-50 text-violet-700 rounded-full">
                                <MapPin className="w-3 h-3" />
                                {assignedRomongan.name}
                              </span>
                            ) : (
                              <span className="text-gray-400 text-sm italic">Unassigned</span>
                            )}
                          </td>
                          <td className="px-6 py-4">
                            <button
                              onClick={() => openAssignModal({ id: member.id, name: member.name })}
                              className="text-violet-600 hover:text-violet-700 text-sm font-medium flex items-center gap-1"
                            >
                              <UserCog className="w-3.5 h-3.5" />
                              Assign
                            </button>
                          </td>
                        </>
                      ) : (
                        <>
                          <td className="px-6 py-4">
                            <span className="px-2 py-1 text-xs font-medium bg-gray-100 text-gray-700 rounded-full">
                              {member.role.replace('_', ' ')}
                            </span>
                          </td>
                          <td className="px-6 py-4">
                            <span className={`px-2 py-1 text-xs font-medium rounded-full ${
                              member.wl_status === 'active' ? 'bg-emerald-100 text-emerald-700' : 'bg-yellow-100 text-yellow-700'
                            }`}>
                              {member.wl_status}
                            </span>
                          </td>
                          <td className="px-6 py-4 text-gray-600">
                            {new Date(member.created_at).toLocaleDateString('id-ID')}
                          </td>
                          <td className="px-6 py-4">
                            <button className="text-emerald-600 hover:text-emerald-700 text-sm font-medium">
                              Edit
                            </button>
                          </td>
                        </>
                      )}
                    </tr>
                  )
                })}
              </tbody>
            </table>
          </div>
        )}
      </div>

      {/* Invite Modal */}
      {showInviteModal && (
        <div className="fixed inset-0 bg-black/50 flex items-center justify-center z-50">
          <div className="bg-white rounded-xl p-6 w-full max-w-md">
            <h3 className="text-lg font-semibold text-gray-900 mb-4">Invite Team Member</h3>
            <div className="space-y-4">
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">Full Name</label>
                <input
                  type="text"
                  value={inviteName}
                  onChange={e => setInviteName(e.target.value)}
                  placeholder="John Doe"
                  className="input w-full"
                />
              </div>
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">Email</label>
                <input
                  type="email"
                  value={inviteEmail}
                  onChange={e => setInviteEmail(e.target.value)}
                  placeholder="john@example.com"
                  className="input w-full"
                />
              </div>
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">Role</label>
                <select
                  value={inviteRole}
                  onChange={e => setInviteRole(e.target.value)}
                  className="input w-full"
                >
                  <option value="team_support">Team Support</option>
                  <option value="muthawif">Muthawif</option>
                </select>
              </div>
              <div className="flex gap-3">
                <button
                  onClick={() => setShowInviteModal(false)}
                  className="flex-1 px-4 py-2 border border-gray-300 rounded-lg hover:bg-gray-50"
                >
                  Cancel
                </button>
                <button
                  onClick={handleInvite}
                  disabled={inviteMutation.isPending || !inviteEmail || !inviteName}
                  className="flex-1 px-4 py-2 bg-emerald-600 text-white rounded-lg hover:bg-emerald-700 disabled:opacity-50 flex items-center justify-center gap-2"
                >
                  {inviteMutation.isPending && <Loader2 className="w-4 h-4 animate-spin" />}
                  Send Invite
                </button>
              </div>
            </div>
          </div>
        </div>
      )}

      {/* Assign Muthawif Modal */}
      {showAssignModal && assigningMuthawif && (
        <div className="fixed inset-0 bg-black/50 flex items-center justify-center z-50">
          <div className="bg-white rounded-xl p-6 w-full max-w-md">
            <h3 className="text-lg font-semibold text-gray-900 mb-1">
              Assign Muthawif
            </h3>
            <p className="text-sm text-gray-500 mb-4">
              Assign <strong>{assigningMuthawif.name}</strong> to a romongan group
            </p>
            <div className="space-y-4">
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">Select Romongan</label>
                {romonganLoading ? (
                  <div className="flex items-center justify-center py-8">
                    <Loader2 className="w-5 h-5 animate-spin text-gray-400" />
                  </div>
                ) : (
                  <select
                    value={selectedRomongan}
                    onChange={e => setSelectedRomongan(e.target.value)}
                    className="input w-full"
                  >
                    <option value="">-- Choose Romongan --</option>
                    {rombongans.map(r => (
                      <option key={r.id} value={r.id}>
                        {r.name} ({r.start_date} – {r.end_date})
                        {r.muthawif_name ? ` [${r.muthawif_name}]` : ''}
                      </option>
                    ))}
                  </select>
                )}
              </div>
              <div className="flex gap-3">
                <button
                  onClick={() => { setShowAssignModal(false); setAssigningMuthawif(null) }}
                  className="flex-1 px-4 py-2 border border-gray-300 rounded-lg hover:bg-gray-50"
                >
                  Cancel
                </button>
                <button
                  onClick={handleAssign}
                  disabled={assignMutation.isPending || !selectedRomongan}
                  className="flex-1 px-4 py-2 bg-violet-600 text-white rounded-lg hover:bg-violet-700 disabled:opacity-50 flex items-center justify-center gap-2"
                >
                  {assignMutation.isPending && <Loader2 className="w-4 h-4 animate-spin" />}
                  Assign
                </button>
              </div>
            </div>
          </div>
        </div>
      )}
    </div>
  )
}
