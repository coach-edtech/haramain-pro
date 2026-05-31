import { Users, Star, Image as ImageIcon, UserPlus, Loader2, TrendingUp, Plus, Pencil, Trash2, X, Upload, Eye } from 'lucide-react'
import { useState } from 'react'
import { useCRMLifecycle } from '../../lib/api'
import { useAgencyProfile } from '../../hooks/useAgencyProfile'
import {
  useAlbums, useAlbumPhotos, useCreateAlbum, useUpdateAlbum, useDeleteAlbum,
  useAddAlbumPhoto, useDeleteAlbumPhoto,
  useReviews, useCreateReview, useUpdateReview, useDeleteReview,
  type TravelAlbum, type AlbumPhoto, type AlumniReview,
} from '../../lib/api'

const STAGE_COLORS: Record<string, string> = {
  prospect: 'bg-slate-100 text-slate-700',
  booked: 'bg-blue-100 text-blue-700',
  active: 'bg-emerald-100 text-emerald-700',
  alumni: 'bg-purple-100 text-purple-700',
  churned: 'bg-red-100 text-red-700',
}

export default function CRMTravelAdmin() {
  const { profile } = useAgencyProfile()
  const [tab, setTab] = useState<'funnel' | 'albums' | 'reviews'>('funnel')
  const [selectedStage, setSelectedStage] = useState<string | undefined>(undefined)

  const { data, isLoading, error } = useCRMLifecycle(profile?.agency_id ?? undefined, selectedStage)

  // Albums
  const { data: albumsData, isLoading: albumsLoading } = useAlbums(profile?.agency_id ?? undefined)
  const [showAlbumModal, setShowAlbumModal] = useState(false)
  const [editingAlbum, setEditingAlbum] = useState<TravelAlbum | null>(null)
  const [albumTitle, setAlbumTitle] = useState('')
  const [albumDesc, setAlbumDesc] = useState('')
  const [albumCoverUrl, setAlbumCoverUrl] = useState('')
  const [selectedAlbum, setSelectedAlbum] = useState<TravelAlbum | null>(null)
  const [showPhotoModal, setShowPhotoModal] = useState(false)
  const [photoUrl, setPhotoUrl] = useState('')
  const [photoCaption, setPhotoCaption] = useState('')
  const createAlbum = useCreateAlbum()
  const updateAlbum = useUpdateAlbum()
  const deleteAlbum = useDeleteAlbum()
  const addPhoto = useAddAlbumPhoto()
  const deletePhoto = useDeleteAlbumPhoto()
  const { data: photosData, isLoading: photosLoading } = useAlbumPhotos(selectedAlbum?.id || '')
  const albumCount = albumsData?.count ?? 0

  // Reviews
  const { data: reviewsData, isLoading: reviewsLoading } = useReviews(profile?.agency_id ?? undefined)
  const [showReviewModal, setShowReviewModal] = useState(false)
  const [editingReview, setEditingReview] = useState<AlumniReview | null>(null)
  const [reviewRating, setReviewRating] = useState(5)
  const [reviewText, setReviewText] = useState('')
  const [reviewPublished, setReviewPublished] = useState(false)
  const [reviewAdminResponse, setReviewAdminResponse] = useState('')
  const [showAllReviews, setShowAllReviews] = useState(false)
  const createReview = useCreateReview()
  const updateReview = useUpdateReview()
  const deleteReview = useDeleteReview()
  const reviewCount = reviewsData?.count ?? 0

  const stages = data?.stages ?? []
  const counts = data?.counts ?? {}
  const pilgrims = data?.pilgrims ?? []
  const funnel = data?.conversion_funnel ?? []

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold text-gray-900">CRM - Pilgrim Lifecycle</h1>
          <p className="text-gray-500">Manage Jamaah lifecycle from prospect to alumni</p>
        </div>
        <button className="btn-primary flex items-center gap-2">
          <UserPlus className="w-4 h-4" />
          Add Jamaah
        </button>
      </div>

      {/* Tabs */}
      <div className="flex gap-2 border-b border-gray-200">
        {[
          { id: 'funnel', label: 'Lifecycle', icon: TrendingUp, count: Object.values(counts).reduce((a: number, b) => a + (Number(b) || 0), 0) },
          { id: 'albums', label: 'Albums', icon: ImageIcon, count: albumCount },
          { id: 'reviews', label: 'Reviews', icon: Star, count: reviewCount },
        ].map((t) => (
          <button
            key={t.id}
            onClick={() => setTab(t.id as typeof tab)}
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

      {isLoading ? (
        <div className="flex items-center justify-center h-64">
          <Loader2 className="w-8 h-8 animate-spin text-emerald-600" />
        </div>
      ) : error ? (
        <div className="card p-8 text-center">
          <p className="text-red-600">{error.message}</p>
        </div>
      ) : tab === 'funnel' ? (
        <>
          {/* Stage cards */}
          <div className="grid grid-cols-2 md:grid-cols-5 gap-4">
            {stages.map((stage) => (
              <button
                key={stage}
                onClick={() => setSelectedStage(selectedStage === stage ? undefined : stage)}
                className={`card p-4 text-left transition-all ${
                  selectedStage === stage
                    ? 'ring-2 ring-emerald-500'
                    : 'hover:shadow-md'
                }`}
              >
                <p className={`text-xs font-medium px-2 py-1 rounded-full inline-block mb-2 ${STAGE_COLORS[stage] ?? 'bg-gray-100 text-gray-700'}`}>
                  {stage}
                </p>
                <p className="text-3xl font-bold text-gray-900">{counts[stage] ?? 0}</p>
              </button>
            ))}
          </div>

          {/* Conversion funnel */}
          {funnel.length > 0 && (
            <div className="card p-6">
              <h3 className="text-sm font-medium text-gray-500 mb-4">Conversion Funnel</h3>
              <div className="space-y-2">
                {funnel.map((f) => (
                  <div key={f.stage} className="flex items-center gap-3">
                    <span className="text-sm text-gray-600 w-20">{f.stage}</span>
                    <div className="flex-1 bg-gray-100 rounded-full h-6 relative overflow-hidden">
                      <div
                        className="bg-emerald-500 h-6 rounded-full flex items-center justify-end pr-2 transition-all"
                        style={{ width: `${Math.max(f.rate, 1)}%` }}
                      >
                        <span className="text-xs font-medium text-white">{f.count}</span>
                      </div>
                    </div>
                    <span className="text-xs text-gray-400 w-12 text-right">{f.rate.toFixed(0)}%</span>
                  </div>
                ))}
              </div>
            </div>
          )}

          {/* Pilgrims list */}
          <div className="card">
            <div className="p-4 border-b border-gray-200 flex items-center justify-between">
              <h3 className="font-semibold text-gray-900">
                {selectedStage ? `${selectedStage.charAt(0).toUpperCase() + selectedStage.slice(1)} Pilgrims` : 'All Pilgrims'}
              </h3>
              {selectedStage && (
                <button
                  onClick={() => setSelectedStage(undefined)}
                  className="text-sm text-emerald-600 hover:text-emerald-700"
                >
                  Show all
                </button>
              )}
            </div>
            {pilgrims.length === 0 ? (
              <div className="p-12 text-center">
                <Users className="w-12 h-12 text-gray-300 mx-auto mb-4" />
                <p className="text-gray-500">No pilgrims in this stage.</p>
              </div>
            ) : (
              <div className="overflow-x-auto">
                <table className="w-full">
                  <thead className="bg-gray-50">
                    <tr>
                      <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Name</th>
                      <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Stage</th>
                      <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Stage Changed</th>
                      <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Booking Date</th>
                      <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Notes</th>
                      <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Actions</th>
                    </tr>
                  </thead>
                  <tbody className="divide-y divide-gray-200">
                    {pilgrims.map((p) => {
                      const initials = (p.pilgrim?.name || 'U')
                        .split(' ')
                        .map((n: string) => n[0])
                        .join('')
                        .slice(0, 2)
                        .toUpperCase()

                      return (
                        <tr key={p.id} className="hover:bg-gray-50">
                          <td className="px-6 py-4">
                            <div className="flex items-center gap-3">
                              <div className="w-10 h-10 bg-emerald-100 rounded-full flex items-center justify-center">
                                <span className="text-emerald-700 font-medium text-sm">{initials}</span>
                              </div>
                              <div>
                                <p className="font-medium text-gray-900">{p.pilgrim?.name ?? 'Unknown'}</p>
                                <p className="text-xs text-gray-500">{p.pilgrim?.email ?? ''}</p>
                              </div>
                            </div>
                          </td>
                          <td className="px-6 py-4">
                            <span className={`px-2 py-1 text-xs font-medium rounded-full ${STAGE_COLORS[p.stage] ?? 'bg-gray-100 text-gray-700'}`}>
                              {p.stage}
                            </span>
                          </td>
                          <td className="px-6 py-4 text-gray-600 text-sm">
                            {new Date(p.stage_changed_at).toLocaleDateString('id-ID', { day: '2-digit', month: 'short', year: 'numeric' })}
                          </td>
                          <td className="px-6 py-4 text-gray-600 text-sm">
                            {p.booking_date ? new Date(p.booking_date).toLocaleDateString('id-ID', { day: '2-digit', month: 'short', year: 'numeric' }) : '-'}
                          </td>
                          <td className="px-6 py-4 text-gray-600 text-sm max-w-xs truncate">
                            {p.notes ?? '-'}
                          </td>
                          <td className="px-6 py-4">
                            <button className="text-emerald-600 hover:text-emerald-700 text-sm font-medium">
                              View
                            </button>
                          </td>
                        </tr>
                      )
                    })}
                  </tbody>
                </table>
              </div>
            )}
          </div>
        </>
      ) : tab === 'albums' ? (
        <AlbumsTab
          albums={albumsData?.albums ?? []}
          isLoading={albumsLoading}
          onAdd={() => { setEditingAlbum(null); setAlbumTitle(''); setAlbumDesc(''); setAlbumCoverUrl(''); setShowAlbumModal(true) }}
          onEdit={(a) => { setEditingAlbum(a); setAlbumTitle(a.title); setAlbumDesc(a.description || ''); setAlbumCoverUrl(a.cover_url || ''); setShowAlbumModal(true) }}
          onDelete={(a) => { if (confirm(`Delete album "${a.title}"?`)) deleteAlbum.mutate({ id: a.id, agency_id: profile!.agency_id! }) }}
          onView={(a) => { setSelectedAlbum(a); setShowPhotoModal(true) }}
          onAddPhoto={(albumId, url, caption) => addPhoto.mutate({ album_id: albumId, url, caption })}
          onDeletePhoto={(photoId, albumId) => deletePhoto.mutate({ photo_id: photoId, album_id: albumId })}
          photos={photosData?.photos ?? []}
          photosLoading={photosLoading}
          selectedAlbum={selectedAlbum}
          showPhotoModal={showPhotoModal}
          setShowPhotoModal={setShowPhotoModal}
          photoUrl={photoUrl} setPhotoUrl={setPhotoUrl}
          photoCaption={photoCaption} setPhotoCaption={setPhotoCaption}
          showAlbumModal={showAlbumModal} setShowAlbumModal={setShowAlbumModal}
          editingAlbum={editingAlbum}
          albumTitle={albumTitle} setAlbumTitle={setAlbumTitle}
          albumDesc={albumDesc} setAlbumDesc={setAlbumDesc}
          albumCoverUrl={albumCoverUrl} setAlbumCoverUrl={setAlbumCoverUrl}
          createAlbum={createAlbum} updateAlbum={updateAlbum}
          agencyId={profile?.agency_id || ''}
        />
      ) : (
        <ReviewsTab
          reviews={reviewsData?.reviews ?? []}
          isLoading={reviewsLoading}
          showAll={showAllReviews}
          onToggleShow={() => setShowAllReviews(!showAllReviews)}
          onAdd={() => { setEditingReview(null); setReviewRating(5); setReviewText(''); setReviewPublished(false); setReviewAdminResponse(''); setShowReviewModal(true) }}
          onEdit={(r) => { setEditingReview(r); setReviewRating(r.rating); setReviewText(r.review_text || ''); setReviewPublished(r.is_published); setReviewAdminResponse(r.admin_response || ''); setShowReviewModal(true) }}
          onDelete={(r) => { if (confirm('Delete this review?')) deleteReview.mutate({ id: r.id, agency_id: profile!.agency_id! }) }}
          showReviewModal={showReviewModal} setShowReviewModal={setShowReviewModal}
          editingReview={editingReview}
          reviewRating={reviewRating} setReviewRating={setReviewRating}
          reviewText={reviewText} setReviewText={setReviewText}
          reviewPublished={reviewPublished} setReviewPublished={setReviewPublished}
          reviewAdminResponse={reviewAdminResponse} setReviewAdminResponse={setReviewAdminResponse}
          createReview={createReview} updateReview={updateReview}
          agencyId={profile?.agency_id || ''}
        />
      )}
    </div>
  )
}

// ================================================================
// AlbumsTab
// ================================================================
interface AlbumsTabProps {
  albums: TravelAlbum[];
  isLoading: boolean;
  onAdd: () => void;
  onEdit: (a: TravelAlbum) => void;
  onDelete: (a: TravelAlbum) => void;
  onView: (a: TravelAlbum) => void;
  onAddPhoto: (albumId: string, url: string, caption: string) => void;
  onDeletePhoto: (photoId: string, albumId: string) => void;
  photos: AlbumPhoto[];
  photosLoading: boolean;
  selectedAlbum: TravelAlbum | null;
  showPhotoModal: boolean;
  setShowPhotoModal: (v: boolean) => void;
  photoUrl: string; setPhotoUrl: (v: string) => void;
  photoCaption: string; setPhotoCaption: (v: string) => void;
  showAlbumModal: boolean; setShowAlbumModal: (v: boolean) => void;
  editingAlbum: TravelAlbum | null;
  albumTitle: string; setAlbumTitle: (v: string) => void;
  albumDesc: string; setAlbumDesc: (v: string) => void;
  albumCoverUrl: string; setAlbumCoverUrl: (v: string) => void;
  createAlbum: ReturnType<typeof import('../../lib/api').useCreateAlbum>;
  updateAlbum: ReturnType<typeof import('../../lib/api').useUpdateAlbum>;
  agencyId: string;
}

function AlbumsTab({
  albums, isLoading, onAdd, onEdit, onDelete, onView, onAddPhoto, onDeletePhoto,
  photos, photosLoading, selectedAlbum, showPhotoModal, setShowPhotoModal,
  photoUrl, setPhotoUrl, photoCaption, setPhotoCaption,
  showAlbumModal, setShowAlbumModal, editingAlbum,
  albumTitle, setAlbumTitle, albumDesc, setAlbumDesc, albumCoverUrl, setAlbumCoverUrl,
  createAlbum, updateAlbum, agencyId,
}: AlbumsTabProps) {

  async function handleSaveAlbum() {
    if (!albumTitle.trim()) return
    if (editingAlbum) {
      await updateAlbum.mutateAsync({ id: editingAlbum.id, title: albumTitle, description: albumDesc, cover_url: albumCoverUrl, agency_id: agencyId })
    } else {
      await createAlbum.mutateAsync({ agency_id: agencyId, title: albumTitle, description: albumDesc, cover_url: albumCoverUrl })
    }
    setShowAlbumModal(false)
  }

  async function handleAddPhoto() {
    if (!photoUrl.trim() || !selectedAlbum) return
    onAddPhoto(selectedAlbum.id, photoUrl, photoCaption)
    setPhotoUrl('')
    setPhotoCaption('')
  }

  if (isLoading) {
    return <div className="flex items-center justify-center h-64"><Loader2 className="w-8 h-8 animate-spin text-emerald-600" /></div>
  }

  return (
    <>
      <div className="flex items-center justify-between">
        <p className="text-gray-500">{albums.length} album{albums.length !== 1 ? 's' : ''}</p>
        <button onClick={onAdd} className="btn-primary flex items-center gap-2">
          <Plus className="w-4 h-4" /> New Album
        </button>
      </div>

      {albums.length === 0 ? (
        <div className="card p-12 text-center">
          <ImageIcon className="w-12 h-12 text-gray-300 mx-auto mb-4" />
          <p className="text-gray-500 mb-4">No albums yet. Create your first album.</p>
          <button onClick={onAdd} className="btn-primary">Create Album</button>
        </div>
      ) : (
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
          {albums.map((album) => (
            <div key={album.id} className="card overflow-hidden hover:shadow-md transition-shadow">
              {/* Cover */}
              <div className="h-40 bg-gray-100 relative overflow-hidden">
                {album.cover_url ? (
                  <img src={album.cover_url} alt={album.title} className="w-full h-full object-cover" />
                ) : (
                  <div className="w-full h-full flex items-center justify-center bg-emerald-50">
                    <ImageIcon className="w-12 h-12 text-emerald-300" />
                  </div>
                )}
                <div className="absolute top-2 right-2 flex gap-1">
                  <button onClick={() => onEdit(album)} className="p-1.5 bg-white/90 rounded-md hover:bg-white text-gray-600" title="Edit">
                    <Pencil className="w-4 h-4" />
                  </button>
                  <button onClick={() => onDelete(album)} className="p-1.5 bg-white/90 rounded-md hover:bg-white text-red-500" title="Delete">
                    <Trash2 className="w-4 h-4" />
                  </button>
                </div>
              </div>
              {/* Info */}
              <div className="p-4">
                <h3 className="font-semibold text-gray-900 mb-1 truncate">{album.title}</h3>
                {album.description && <p className="text-sm text-gray-500 line-clamp-2 mb-2">{album.description}</p>}
                <div className="flex items-center justify-between">
                  <span className="text-xs text-gray-400">{album.photo_count} photo{album.photo_count !== 1 ? 's' : ''}</span>
                  <button onClick={() => onView(album)} className="text-emerald-600 hover:text-emerald-700 text-sm font-medium flex items-center gap-1">
                    <Eye className="w-3.5 h-3.5" /> View
                  </button>
                </div>
                <p className="text-xs text-gray-400 mt-2">
                  {new Date(album.created_at).toLocaleDateString('id-ID', { day: '2-digit', month: 'short', year: 'numeric' })}
                </p>
              </div>
            </div>
          ))}
        </div>
      )}

      {/* Create/Edit Album Modal */}
      {showAlbumModal && (
        <div className="fixed inset-0 bg-black/50 flex items-center justify-center z-50">
          <div className="bg-white rounded-xl p-6 w-full max-w-md">
            <div className="flex items-center justify-between mb-4">
              <h3 className="text-lg font-semibold text-gray-900">{editingAlbum ? 'Edit Album' : 'New Album'}</h3>
              <button onClick={() => setShowAlbumModal(false)} className="text-gray-400 hover:text-gray-600"><X className="w-5 h-5" /></button>
            </div>
            <div className="space-y-4">
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">Title *</label>
                <input value={albumTitle} onChange={e => setAlbumTitle(e.target.value)} placeholder="Album title" className="input w-full" />
              </div>
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">Description</label>
                <textarea value={albumDesc} onChange={e => setAlbumDesc(e.target.value)} placeholder="Optional description" rows={3} className="input w-full resize-none" />
              </div>
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">Cover Image URL</label>
                <input value={albumCoverUrl} onChange={e => setAlbumCoverUrl(e.target.value)} placeholder="https://..." className="input w-full" />
                {albumCoverUrl && <img src={albumCoverUrl} alt="cover preview" className="mt-2 h-24 w-full object-cover rounded-md" />}
              </div>
              <div className="flex gap-3">
                <button onClick={() => setShowAlbumModal(false)} className="flex-1 px-4 py-2 border border-gray-300 rounded-lg hover:bg-gray-50">Cancel</button>
                <button
                  onClick={handleSaveAlbum}
                  disabled={!albumTitle.trim() || createAlbum.isPending || updateAlbum.isPending}
                  className="flex-1 px-4 py-2 bg-emerald-600 text-white rounded-lg hover:bg-emerald-700 disabled:opacity-50 flex items-center justify-center gap-2"
                >
                  {(createAlbum.isPending || updateAlbum.isPending) && <Loader2 className="w-4 h-4 animate-spin" />}
                  {editingAlbum ? 'Update' : 'Create'}
                </button>
              </div>
            </div>
          </div>
        </div>
      )}

      {/* Photo Viewer / Add Photo Modal */}
      {showPhotoModal && selectedAlbum && (
        <div className="fixed inset-0 bg-black/50 flex items-center justify-center z-50">
          <div className="bg-white rounded-xl p-6 w-full max-w-3xl max-h-[90vh] overflow-y-auto">
            <div className="flex items-center justify-between mb-4">
              <h3 className="text-lg font-semibold text-gray-900">{selectedAlbum.title} — Photos</h3>
              <button onClick={() => setShowPhotoModal(false)} className="text-gray-400 hover:text-gray-600"><X className="w-5 h-5" /></button>
            </div>

            {/* Add photo form */}
            <div className="mb-6 p-4 bg-gray-50 rounded-lg space-y-3">
              <p className="text-sm font-medium text-gray-700">Add Photo</p>
              <div className="flex gap-2">
                <input value={photoUrl} onChange={e => setPhotoUrl(e.target.value)} placeholder="Photo URL" className="input flex-1" />
                <input value={photoCaption} onChange={e => setPhotoCaption(e.target.value)} placeholder="Caption (optional)" className="input flex-1" />
                <button
                  onClick={handleAddPhoto}
                  disabled={!photoUrl.trim()}
                  className="btn-primary flex items-center gap-1 disabled:opacity-50"
                >
                  <Upload className="w-4 h-4" /> Add
                </button>
              </div>
            </div>

            {photosLoading ? (
              <div className="flex justify-center py-8"><Loader2 className="w-6 h-6 animate-spin text-emerald-600" /></div>
            ) : photos.length === 0 ? (
              <p className="text-center text-gray-400 py-8">No photos yet. Add one above.</p>
            ) : (
              <div className="grid grid-cols-2 md:grid-cols-3 gap-4">
                {photos.map((photo) => (
                  <div key={photo.id} className="relative group">
                    <img src={photo.url} alt={photo.caption || ''} className="w-full h-40 object-cover rounded-lg" />
                    {photo.caption && (
                      <p className="text-xs text-gray-600 mt-1 truncate">{photo.caption}</p>
                    )}
                    <button
                      onClick={() => onDeletePhoto(photo.id, selectedAlbum.id)}
                      className="absolute top-1 right-1 p-1 bg-white/90 rounded-md text-red-500 opacity-0 group-hover:opacity-100 transition-opacity"
                    >
                      <Trash2 className="w-3.5 h-3.5" />
                    </button>
                  </div>
                ))}
              </div>
            )}
          </div>
        </div>
      )}
    </>
  )
}

// ================================================================
// ReviewsTab
// ================================================================
interface ReviewsTabProps {
  reviews: AlumniReview[];
  isLoading: boolean;
  showAll: boolean;
  onToggleShow: () => void;
  onAdd: () => void;
  onEdit: (r: AlumniReview) => void;
  onDelete: (r: AlumniReview) => void;
  showReviewModal: boolean; setShowReviewModal: (v: boolean) => void;
  editingReview: AlumniReview | null;
  reviewRating: number; setReviewRating: (v: number) => void;
  reviewText: string; setReviewText: (v: string) => void;
  reviewPublished: boolean; setReviewPublished: (v: boolean) => void;
  reviewAdminResponse: string; setReviewAdminResponse: (v: string) => void;
  createReview: ReturnType<typeof import('../../lib/api').useCreateReview>;
  updateReview: ReturnType<typeof import('../../lib/api').useUpdateReview>;
  agencyId: string;
}

function StarRating({ value, onChange, interactive = false }: { value: number; onChange?: (v: number) => void; interactive?: boolean }) {
  return (
    <div className="flex gap-1">
      {[1, 2, 3, 4, 5].map((star) => (
        <button
          key={star}
          type="button"
          onClick={() => interactive && onChange && onChange(star)}
          className={`${interactive ? 'cursor-pointer hover:scale-110' : 'cursor-default'} transition-transform`}
        >
          <Star
            className={`w-5 h-5 ${star <= value ? 'fill-yellow-400 text-yellow-400' : 'text-gray-300'}`}
          />
        </button>
      ))}
    </div>
  )
}

function ReviewsTab({
  reviews, isLoading, showAll, onToggleShow, onAdd, onEdit, onDelete,
  showReviewModal, setShowReviewModal, editingReview,
  reviewRating, setReviewRating, reviewText, setReviewText,
  reviewPublished, setReviewPublished, reviewAdminResponse, setReviewAdminResponse,
  createReview, updateReview, agencyId,
}: ReviewsTabProps) {

  const displayed = showAll ? reviews : reviews.filter(r => r.is_published)
  const avgRating = reviews.length > 0
    ? (reviews.reduce((sum, r) => sum + r.rating, 0) / reviews.length).toFixed(1)
    : '0.0'

  async function handleSaveReview() {
    if (!reviewText.trim()) return
    if (editingReview) {
      await updateReview.mutateAsync({
        id: editingReview.id, rating: reviewRating, review_text: reviewText,
        is_published: reviewPublished, admin_response: reviewAdminResponse, agency_id: agencyId,
      })
    } else {
      // user_id required for create — use a placeholder since we may not have it
      await createReview.mutateAsync({
        agency_id: agencyId, user_id: '00000000-0000-0000-0000-000000000000',
        rating: reviewRating, review_text: reviewText, is_published: reviewPublished,
      })
    }
    setShowReviewModal(false)
  }

  if (isLoading) {
    return <div className="flex items-center justify-center h-64"><Loader2 className="w-8 h-8 animate-spin text-emerald-600" /></div>
  }

  return (
    <>
      <div className="flex items-center justify-between">
        <div className="flex items-center gap-4">
          <div className="flex items-center gap-2">
            <StarRating value={Math.round(Number(avgRating))} />
            <span className="font-semibold text-gray-900">{avgRating}</span>
            <span className="text-gray-400 text-sm">({reviews.length} review{reviews.length !== 1 ? 's' : ''})</span>
          </div>
          <label className="flex items-center gap-2 text-sm text-gray-600">
            <input type="checkbox" checked={showAll} onChange={onToggleShow} className="rounded" />
            Show unpublished
          </label>
        </div>
        <button onClick={onAdd} className="btn-primary flex items-center gap-2">
          <Plus className="w-4 h-4" /> Add Review
        </button>
      </div>

      {displayed.length === 0 ? (
        <div className="card p-12 text-center">
          <Star className="w-12 h-12 text-gray-300 mx-auto mb-4" />
          <p className="text-gray-500 mb-4">No reviews yet.</p>
          <button onClick={onAdd} className="btn-primary">Add First Review</button>
        </div>
      ) : (
        <div className="space-y-4">
          {displayed.map((review) => (
            <div key={review.id} className="card p-5">
              <div className="flex items-start justify-between mb-3">
                <div>
                  <div className="flex items-center gap-3 mb-1">
                    <StarRating value={review.rating} />
                    <span className="text-sm text-gray-500">
                      {review.pilgrim?.name || 'Anonymous'}
                    </span>
                    {!review.is_published && (
                      <span className="px-2 py-0.5 bg-yellow-100 text-yellow-700 text-xs rounded-full">Draft</span>
                    )}
                  </div>
                  <p className="text-xs text-gray-400">
                    {new Date(review.created_at).toLocaleDateString('id-ID', { day: '2-digit', month: 'short', year: 'numeric' })}
                  </p>
                </div>
                <div className="flex gap-2">
                  <button onClick={() => onEdit(review)} className="p-1.5 text-gray-400 hover:text-emerald-600 rounded-md hover:bg-emerald-50">
                    <Pencil className="w-4 h-4" />
                  </button>
                  <button onClick={() => onDelete(review)} className="p-1.5 text-gray-400 hover:text-red-500 rounded-md hover:bg-red-50">
                    <Trash2 className="w-4 h-4" />
                  </button>
                </div>
              </div>
              <p className="text-gray-700 text-sm mb-3">{review.review_text}</p>
              {review.admin_response && (
                <div className="mt-3 pl-3 border-l-2 border-emerald-200 bg-emerald-50 rounded-r-md p-3">
                  <p className="text-xs font-medium text-emerald-700 mb-1">Agency Response</p>
                  <p className="text-sm text-gray-700">{review.admin_response}</p>
                </div>
              )}
            </div>
          ))}
        </div>
      )}

      {/* Create/Edit Review Modal */}
      {showReviewModal && (
        <div className="fixed inset-0 bg-black/50 flex items-center justify-center z-50">
          <div className="bg-white rounded-xl p-6 w-full max-w-lg">
            <div className="flex items-center justify-between mb-4">
              <h3 className="text-lg font-semibold text-gray-900">{editingReview ? 'Edit Review' : 'Add Review'}</h3>
              <button onClick={() => setShowReviewModal(false)} className="text-gray-400 hover:text-gray-600"><X className="w-5 h-5" /></button>
            </div>
            <div className="space-y-4">
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-2">Rating *</label>
                <StarRating value={reviewRating} onChange={setReviewRating} interactive />
              </div>
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">Review Text *</label>
                <textarea
                  value={reviewText}
                  onChange={e => setReviewText(e.target.value)}
                  placeholder="Write the review..."
                  rows={4}
                  className="input w-full resize-none"
                />
              </div>
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">Admin Response</label>
                <textarea
                  value={reviewAdminResponse}
                  onChange={e => setReviewAdminResponse(e.target.value)}
                  placeholder="Optional response to this review..."
                  rows={2}
                  className="input w-full resize-none"
                />
              </div>
              <div className="flex items-center gap-2">
                <input
                  type="checkbox"
                  id="publish-review"
                  checked={reviewPublished}
                  onChange={e => setReviewPublished(e.target.checked)}
                  className="rounded"
                />
                <label htmlFor="publish-review" className="text-sm text-gray-700">Published (visible to public)</label>
              </div>
              <div className="flex gap-3">
                <button onClick={() => setShowReviewModal(false)} className="flex-1 px-4 py-2 border border-gray-300 rounded-lg hover:bg-gray-50">Cancel</button>
                <button
                  onClick={handleSaveReview}
                  disabled={!reviewText.trim() || createReview.isPending || updateReview.isPending}
                  className="flex-1 px-4 py-2 bg-emerald-600 text-white rounded-lg hover:bg-emerald-700 disabled:opacity-50 flex items-center justify-center gap-2"
                >
                  {(createReview.isPending || updateReview.isPending) && <Loader2 className="w-4 h-4 animate-spin" />}
                  {editingReview ? 'Update' : 'Create'}
                </button>
              </div>
            </div>
          </div>
        </div>
      )}
    </>
  )
}
