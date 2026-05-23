import { Users, Search, Mail, Phone, Star, Image as ImageIcon, UserPlus } from 'lucide-react'
import { mockJamaah, mockAlbums, mockReviews } from '../../lib/mockData'
import { useState } from 'react'

export default function CRMTravelAdmin() {
  const [tab, setTab] = useState<'jamaah' | 'albums' | 'reviews'>('jamaah')
  const [search, setSearch] = useState('')

  const filteredJamaah = mockJamaah.filter(j => 
    j.name.toLowerCase().includes(search.toLowerCase()) ||
    j.email.toLowerCase().includes(search.toLowerCase())
  )

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold text-gray-900">CRM - Pilgrim Lifecycle</h1>
          <p className="text-gray-500">Manage Jamaah, albums, and reviews</p>
        </div>
        <button className="btn-primary flex items-center gap-2">
          <UserPlus className="w-4 h-4" />
          Add Jamaah
        </button>
      </div>

      <div className="flex gap-2 border-b border-gray-200">
        {[
          { id: 'jamaah', label: 'Jamaah', icon: Users, count: mockJamaah.length },
          { id: 'albums', label: 'Albums', icon: ImageIcon, count: mockAlbums.length },
          { id: 'reviews', label: 'Reviews', icon: Star, count: mockReviews.length },
        ].map((t) => (
          <button
            key={t.id}
            onClick={() => setTab(t.id as any)}
            className={`flex items-center gap-2 px-4 py-3 border-b-2 transition-colors ${
              tab === t.id
                ? 'border-emerald-500 text-emerald-600'
                : 'border-transparent text-gray-500 hover:text-gray-700'
            }`}
          >
            <t.icon className="w-4 h-4" />
            {t.label}
            <span className="px-2 py-0.5 bg-gray-100 rounded-full text-xs">{t.count}</span>
          </button>
        ))}
      </div>

      {tab === 'jamaah' && (
        <>
          <div className="card">
            <div className="p-4 border-b border-gray-200">
              <div className="relative max-w-md">
                <Search className="absolute left-3 top-1/2 -translate-y-1/2 w-5 h-5 text-gray-400" />
                <input
                  type="text"
                  placeholder="Search Jamaah..."
                  value={search}
                  onChange={(e) => setSearch(e.target.value)}
                  className="input pl-10"
                />
              </div>
            </div>
            <div className="overflow-x-auto">
              <table className="w-full">
                <thead className="bg-gray-50">
                  <tr>
                    <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Name</th>
                    <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Contact</th>
                    <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Group</th>
                    <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Status</th>
                    <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Last Active</th>
                    <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Actions</th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-gray-200">
                  {filteredJamaah.map((jamaah) => (
                    <tr key={jamaah.id} className="hover:bg-gray-50">
                      <td className="px-6 py-4">
                        <div className="flex items-center gap-3">
                          <div className="w-10 h-10 bg-emerald-100 rounded-full flex items-center justify-center">
                            <span className="text-emerald-700 font-medium text-sm">
                              {jamaah.name.split(' ').map(n => n[0]).join('')}
                            </span>
                          </div>
                          <div>
                            <p className="font-medium text-gray-900">{jamaah.name}</p>
                            {jamaah.passport_number && (
                              <p className="text-xs text-gray-500">Passport: {jamaah.passport_number}</p>
                            )}
                          </div>
                        </div>
                      </td>
                      <td className="px-6 py-4">
                        <p className="text-gray-600 flex items-center gap-1">
                          <Mail className="w-3 h-3" />
                          {jamaah.email}
                        </p>
                        <p className="text-gray-600 flex items-center gap-1 text-xs">
                          <Phone className="w-3 h-3" />
                          {jamaah.phone}
                        </p>
                      </td>
                      <td className="px-6 py-4 font-medium text-gray-900">{jamaah.group_name}</td>
                      <td className="px-6 py-4">
                        <span className={`px-2 py-1 text-xs font-medium rounded-full ${
                          jamaah.status === 'active' ? 'bg-emerald-100 text-emerald-700' : 'bg-gray-100 text-gray-600'
                        }`}>
                          {jamaah.status}
                        </span>
                      </td>
                      <td className="px-6 py-4 text-gray-600">{jamaah.last_active}</td>
                      <td className="px-6 py-4">
                        <button className="text-emerald-600 hover:text-emerald-700 text-sm font-medium">
                          View
                        </button>
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          </div>
        </>
      )}

      {tab === 'albums' && (
        <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
          {mockAlbums.map((album) => (
            <div key={album.id} className="card overflow-hidden">
              <div className="bg-gradient-to-br from-emerald-400 to-teal-500 h-32 flex items-center justify-center">
                <ImageIcon className="w-12 h-12 text-white/50" />
              </div>
              <div className="p-4">
                <h3 className="font-semibold text-gray-900">{album.title}</h3>
                <p className="text-sm text-gray-500">{album.photo_count} photos</p>
                <p className="text-xs text-gray-400 mt-1">{album.created_at}</p>
              </div>
            </div>
          ))}
        </div>
      )}

      {tab === 'reviews' && (
        <div className="space-y-4">
          {mockReviews.map((review) => (
            <div key={review.id} className="card p-6">
              <div className="flex items-start justify-between mb-3">
                <div className="flex items-center gap-3">
                  <div className="w-10 h-10 bg-emerald-100 rounded-full flex items-center justify-center">
                    <span className="text-emerald-700 font-medium">U</span>
                  </div>
                  <div>
                    <p className="font-medium text-gray-900">Anonymous Jamaah</p>
                    <p className="text-xs text-gray-500">{review.created_at}</p>
                  </div>
                </div>
                <div className="flex gap-0.5">
                  {[...Array(5)].map((_, i) => (
                    <Star key={i} className={`w-4 h-4 ${i < review.rating ? 'text-amber-400 fill-amber-400' : 'text-gray-300'}`} />
                  ))}
                </div>
              </div>
              <p className="text-gray-600">{review.comment}</p>
            </div>
          ))}
        </div>
      )}
    </div>
  )
}
