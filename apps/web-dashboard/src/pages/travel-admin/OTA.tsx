import { Bell, Plus, Send, Smartphone, CheckCircle, AlertCircle } from 'lucide-react'
import { mockOTAVersions } from '../../lib/mockData'
import { useState } from 'react'

export default function OTATravelAdmin() {
  const [showNewVersionModal, setShowNewVersionModal] = useState(false)

  const publishedVersions = mockOTAVersions.filter(v => v.status === 'published')
  const draftVersions = mockOTAVersions.filter(v => v.status === 'draft')

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold text-gray-900">OTA Updates</h1>
          <p className="text-gray-500">Push notifications and app version management</p>
        </div>
        <button 
          onClick={() => setShowNewVersionModal(true)}
          className="btn-primary flex items-center gap-2"
        >
          <Plus className="w-4 h-4" />
          New Version
        </button>
      </div>

      <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
        <div className="card p-6">
          <div className="flex items-start justify-between">
            <div>
              <p className="text-sm text-gray-500 mb-1">Published Versions</p>
              <p className="text-2xl font-bold text-emerald-600">{publishedVersions.length}</p>
            </div>
            <div className="p-3 bg-emerald-50 rounded-lg">
              <CheckCircle className="w-6 h-6 text-emerald-600" />
            </div>
          </div>
        </div>
        <div className="card p-6">
          <div className="flex items-start justify-between">
            <div>
              <p className="text-sm text-gray-500 mb-1">Draft Versions</p>
              <p className="text-2xl font-bold text-yellow-600">{draftVersions.length}</p>
            </div>
            <div className="p-3 bg-yellow-50 rounded-lg">
              <AlertCircle className="w-6 h-6 text-yellow-600" />
            </div>
          </div>
        </div>
        <div className="card p-6">
          <div className="flex items-start justify-between">
            <div>
              <p className="text-sm text-gray-500 mb-1">Active Users</p>
              <p className="text-2xl font-bold text-gray-900">285</p>
            </div>
            <div className="p-3 bg-blue-50 rounded-lg">
              <Smartphone className="w-6 h-6 text-blue-600" />
            </div>
          </div>
        </div>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        <div className="card p-6">
          <h2 className="text-lg font-semibold text-gray-900 mb-4">Push Notification</h2>
          <div className="space-y-4">
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">Title</label>
              <input type="text" placeholder="Notification title" className="input" />
            </div>
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">Message</label>
              <textarea placeholder="Notification message" rows={3} className="input" />
            </div>
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">Target</label>
              <select className="input">
                <option>All Users</option>
                <option>Android Only</option>
                <option>iOS Only</option>
                <option>Specific Version</option>
              </select>
            </div>
            <button className="w-full btn-primary flex items-center justify-center gap-2">
              <Send className="w-4 h-4" />
              Send Notification
            </button>
          </div>
        </div>

        <div className="card p-6">
          <h2 className="text-lg font-semibold text-gray-900 mb-4">Recent Notifications</h2>
          <div className="space-y-3">
            {[
              { title: 'App Update Available', sent: '2026-05-10', status: 'delivered' },
              { title: 'New Feature: Panic Alert', sent: '2026-05-08', status: 'delivered' },
              { title: 'Maintenance Notice', sent: '2026-05-05', status: 'delivered' },
            ].map((notif, idx) => (
              <div key={idx} className="flex items-center justify-between p-3 bg-gray-50 rounded-lg">
                <div className="flex items-center gap-3">
                  <div className="w-10 h-10 bg-emerald-100 rounded-full flex items-center justify-center">
                    <Bell className="w-5 h-5 text-emerald-600" />
                  </div>
                  <div>
                    <p className="font-medium text-gray-900">{notif.title}</p>
                    <p className="text-xs text-gray-500">{notif.sent}</p>
                  </div>
                </div>
                <span className="px-2 py-1 text-xs font-medium bg-emerald-100 text-emerald-700 rounded-full">
                  {notif.status}
                </span>
              </div>
            ))}
          </div>
        </div>
      </div>

      <div className="card">
        <div className="p-4 border-b border-gray-200">
          <h2 className="text-lg font-semibold text-gray-900">Version History</h2>
        </div>
        <div className="overflow-x-auto">
          <table className="w-full">
            <thead className="bg-gray-50">
              <tr>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Version</th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Platform</th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Release Notes</th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Status</th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Actions</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-gray-200">
              {mockOTAVersions.map((version) => (
                <tr key={version.id} className="hover:bg-gray-50">
                  <td className="px-6 py-4 font-medium text-gray-900">{version.version}</td>
                  <td className="px-6 py-4">
                    <span className="px-2 py-1 text-xs font-medium bg-gray-100 text-gray-700 rounded-full">
                      {version.platform}
                    </span>
                  </td>
                  <td className="px-6 py-4 text-gray-600 max-w-xs truncate">{version.release_notes}</td>
                  <td className="px-6 py-4">
                    <span className={`px-2 py-1 text-xs font-medium rounded-full ${
                      version.status === 'published' ? 'bg-emerald-100 text-emerald-700' :
                      version.status === 'draft' ? 'bg-yellow-100 text-yellow-700' :
                      'bg-gray-100 text-gray-600'
                    }`}>
                      {version.status}
                    </span>
                  </td>
                  <td className="px-6 py-4">
                    {version.status === 'draft' ? (
                      <button className="text-emerald-600 hover:text-emerald-700 text-sm font-medium">
                        Publish
                      </button>
                    ) : (
                      <button className="text-gray-500 hover:text-gray-600 text-sm">
                        View
                      </button>
                    )}
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </div>

      {showNewVersionModal && (
        <div className="fixed inset-0 bg-black/50 flex items-center justify-center z-50">
          <div className="bg-white rounded-xl p-6 w-full max-w-md">
            <h3 className="text-lg font-semibold text-gray-900 mb-4">Create New Version</h3>
            <div className="space-y-4">
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">Version Number</label>
                <input type="text" placeholder="e.g., 2.1.1" className="input" />
              </div>
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">Platform</label>
                <select className="input">
                  <option>Android</option>
                  <option>iOS</option>
                  <option>Both</option>
                </select>
              </div>
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">Release Notes</label>
                <textarea rows={4} className="input" placeholder="What's new in this version..." />
              </div>
              <div className="flex gap-3">
                <button onClick={() => setShowNewVersionModal(false)} className="flex-1 px-4 py-2 border border-gray-300 rounded-lg hover:bg-gray-50">
                  Cancel
                </button>
                <button className="flex-1 px-4 py-2 bg-emerald-600 text-white rounded-lg hover:bg-emerald-700">
                  Create Draft
                </button>
              </div>
            </div>
          </div>
        </div>
      )}
    </div>
  )
}
