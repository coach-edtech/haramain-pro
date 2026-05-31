import { useState, useEffect } from 'react'
import { supabase } from '../lib/supabase'
import type { Rombongan, EmiPlan, Package } from '../types'
import { Plus, Search, Calendar, Users, Package, CreditCard, Trash2, Edit2, X, Check } from 'lucide-react'

type TabType = 'rombongan' | 'packages' | 'emi'

export default function Packages() {
  const [activeTab, setActiveTab] = useState<TabType>('rombongan')
  const [rombongans, setRombongans] = useState<Rombongan[]>([])
  const [packages, setPackages] = useState<Package[]>([])
  const [emiPlans, setEmiPlans] = useState<EmiPlan[]>([])
  const [loading, setLoading] = useState(true)
  const [searchTerm, setSearchTerm] = useState('')
  
  // Modal state
  const [showModal, setShowModal] = useState(false)
  const [modalType, setModalType] = useState<'rombongan' | 'package' | 'emi'>('rombongan')
  const [editingItem, setEditingItem] = useState<any>(null)

  // Rombongan form state
  const [rombonganForm, setRombonganForm] = useState({
    name: '',
    start_date: '',
    end_date: '',
    status: 'planned' as 'planned' | 'active' | 'completed'
  })

  // Package form state
  const [packageForm, setPackageForm] = useState({
    romongan_id: '',
    name: '',
    description: '',
    price: 0,
    capacity: 0,
    included_services: ''
  })

  // EMI Plan form state
  const [emiForm, setEmiForm] = useState({
    romongan_id: '',
    name: '',
    total_amount: 0,
    down_payment: 0,
    tenor_months: 3,
    interest_rate: 0,
    status: 'active' as 'active' | 'completed' | 'cancelled',
    start_date: '',
    end_date: ''
  })

  useEffect(() => {
    fetchAllData()
  }, [])

  const fetchAllData = async () => {
    setLoading(true)
    await Promise.all([fetchRombongans(), fetchPackages(), fetchEmiPlans()])
    setLoading(false)
  }

  const fetchRombongans = async () => {
    try {
      const { data, error } = await supabase
        .from('rombongans')
        .select('*')
        .order('created_at', { ascending: false })
      if (error) throw error
      setRombongans(data || [])
    } catch (error) {
      console.error('Error fetching rombangans:', error)
    }
  }

  const fetchPackages = async () => {
    try {
      const { data, error } = await supabase
        .from('packages')
        .select('*')
        .order('created_at', { ascending: false })
      if (error) throw error
      setPackages(data || [])
    } catch (error) {
      console.error('Error fetching packages:', error)
    }
  }

  const fetchEmiPlans = async () => {
    try {
      const { data, error } = await supabase
        .from('emi_plans')
        .select('*')
        .order('created_at', { ascending: false })
      if (error) throw error
      setEmiPlans(data || [])
    } catch (error) {
      console.error('Error fetching EMI plans:', error)
    }
  }

  // CRUD Operations
  const handleCreateRombongan = async () => {
    try {
      const { data, error } = await supabase
        .from('rombongans')
        .insert([rombonganForm])
        .select()
        .single()
      if (error) throw error
      setRombongans(prev => [data, ...prev])
      closeModal()
    } catch (error) {
      console.error('Error creating romongan:', error)
      alert('Failed to create romongan')
    }
  }

  const handleUpdateRombongan = async () => {
    if (!editingItem) return
    try {
      const { data, error } = await supabase
        .from('rombongans')
        .update(rombonganForm)
        .eq('id', editingItem.id)
        .select()
        .single()
      if (error) throw error
      setRombongans(prev => prev.map(r => r.id === data.id ? data : r))
      closeModal()
    } catch (error) {
      console.error('Error updating romongan:', error)
      alert('Failed to update romongan')
    }
  }

  const handleDeleteRombongan = async (id: string) => {
    if (!confirm('Are you sure you want to delete this romongan?')) return
    try {
      const { error } = await supabase.from('rombongans').delete().eq('id', id)
      if (error) throw error
      setRombongans(prev => prev.filter(r => r.id !== id))
    } catch (error) {
      console.error('Error deleting romongan:', error)
      alert('Failed to delete romongan')
    }
  }

  const handleCreatePackage = async () => {
    const payload = {
      ...packageForm,
      included_services: packageForm.included_services.split(',').map(s => s.trim()).filter(Boolean)
    }
    try {
      const { data, error } = await supabase
        .from('packages')
        .insert([payload])
        .select()
        .single()
      if (error) throw error
      setPackages(prev => [data, ...prev])
      closeModal()
    } catch (error) {
      console.error('Error creating package:', error)
      alert('Failed to create package')
    }
  }

  const handleUpdatePackage = async () => {
    if (!editingItem) return
    const payload = {
      ...packageForm,
      included_services: packageForm.included_services.split(',').map(s => s.trim()).filter(Boolean)
    }
    try {
      const { data, error } = await supabase
        .from('packages')
        .update(payload)
        .eq('id', editingItem.id)
        .select()
        .single()
      if (error) throw error
      setPackages(prev => prev.map(p => p.id === data.id ? data : p))
      closeModal()
    } catch (error) {
      console.error('Error updating package:', error)
      alert('Failed to update package')
    }
  }

  const handleDeletePackage = async (id: string) => {
    if (!confirm('Are you sure you want to delete this package?')) return
    try {
      const { error } = await supabase.from('packages').delete().eq('id', id)
      if (error) throw error
      setPackages(prev => prev.filter(p => p.id !== id))
    } catch (error) {
      console.error('Error deleting package:', error)
      alert('Failed to delete package')
    }
  }

  const handleCreateEmiPlan = async () => {
    const monthlyAmount = (emiForm.total_amount - emiForm.down_payment) / emiForm.tenor_months
    const payload = {
      ...emiForm,
      monthly_amount: Math.round(monthlyAmount * 100) / 100
    }
    try {
      const { data, error } = await supabase
        .from('emi_plans')
        .insert([payload])
        .select()
        .single()
      if (error) throw error
      setEmiPlans(prev => [data, ...prev])
      closeModal()
    } catch (error) {
      console.error('Error creating EMI plan:', error)
      alert('Failed to create EMI plan')
    }
  }

  const handleUpdateEmiPlan = async () => {
    if (!editingItem) return
    const monthlyAmount = (emiForm.total_amount - emiForm.down_payment) / emiForm.tenor_months
    const payload = {
      ...emiForm,
      monthly_amount: Math.round(monthlyAmount * 100) / 100
    }
    try {
      const { data, error } = await supabase
        .from('emi_plans')
        .update(payload)
        .eq('id', editingItem.id)
        .select()
        .single()
      if (error) throw error
      setEmiPlans(prev => prev.map(e => e.id === data.id ? data : e))
      closeModal()
    } catch (error) {
      console.error('Error updating EMI plan:', error)
      alert('Failed to update EMI plan')
    }
  }

  const handleDeleteEmiPlan = async (id: string) => {
    if (!confirm('Are you sure you want to delete this EMI plan?')) return
    try {
      const { error } = await supabase.from('emi_plans').delete().eq('id', id)
      if (error) throw error
      setEmiPlans(prev => prev.filter(e => e.id !== id))
    } catch (error) {
      console.error('Error deleting EMI plan:', error)
      alert('Failed to delete EMI plan')
    }
  }

  const openModal = (type: 'rombongan' | 'package' | 'emi', item?: any) => {
    setModalType(type)
    setEditingItem(item)
    if (item) {
      if (type === 'rombongan') {
        setRombonganForm({ name: item.name, start_date: item.start_date, end_date: item.end_date, status: item.status })
      } else if (type === 'package') {
        setPackageForm({ 
          romongan_id: item.romongan_id, 
          name: item.name, 
          description: item.description, 
          price: item.price, 
          capacity: item.capacity, 
          included_services: item.included_services?.join(', ') || '' 
        })
      } else {
        setEmiForm({ 
          romongan_id: item.romongan_id, 
          name: item.name, 
          total_amount: item.total_amount, 
          down_payment: item.down_payment, 
          tenor_months: item.tenor_months, 
          interest_rate: item.interest_rate, 
          status: item.status, 
          start_date: item.start_date, 
          end_date: item.end_date 
        })
      }
    } else {
      if (type === 'rombongan') {
        setRombonganForm({ name: '', start_date: '', end_date: '', status: 'planned' })
      } else if (type === 'package') {
        setPackageForm({ romongan_id: '', name: '', description: '', price: 0, capacity: 0, included_services: '' })
      } else {
        setEmiForm({ romongan_id: '', name: '', total_amount: 0, down_payment: 0, tenor_months: 3, interest_rate: 0, status: 'active', start_date: '', end_date: '' })
      }
    }
    setShowModal(true)
  }

  const closeModal = () => {
    setShowModal(false)
    setEditingItem(null)
  }

  const handleSubmit = () => {
    if (modalType === 'rombongan') {
      editingItem ? handleUpdateRombongan() : handleCreateRombongan()
    } else if (modalType === 'package') {
      editingItem ? handleUpdatePackage() : handleCreatePackage()
    } else {
      editingItem ? handleUpdateEmiPlan() : handleCreateEmiPlan()
    }
  }

  const filteredRombongans = rombongans.filter(r => r.name.toLowerCase().includes(searchTerm.toLowerCase()))
  const filteredPackages = packages.filter(p => p.name.toLowerCase().includes(searchTerm.toLowerCase()))
  const filteredEmiPlans = emiPlans.filter(e => e.name.toLowerCase().includes(searchTerm.toLowerCase()))

  const statusColors: Record<string, string> = {
    planned: 'bg-blue-100 text-blue-700',
    active: 'bg-green-100 text-green-700',
    completed: 'bg-gray-100 text-gray-700',
    cancelled: 'bg-red-100 text-red-700'
  }

  const formatCurrency = (amount: number) => {
    return new Intl.NumberFormat('id-ID', { style: 'currency', currency: 'IDR' }).format(amount)
  }

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold text-gray-900">Packages</h1>
          <p className="text-gray-500">Manage travel packages, rombongans, and EMI plans</p>
        </div>
        <button 
          onClick={() => openModal(activeTab === 'rombongan' ? 'rombongan' : activeTab === 'packages' ? 'package' : 'emi')}
          className="btn-primary flex items-center gap-2"
        >
          <Plus className="w-4 h-4" />
          New {activeTab === 'rombongan' ? 'Rombongan' : activeTab === 'packages' ? 'Package' : 'EMI Plan'}
        </button>
      </div>

      {/* Tabs */}
      <div className="border-b border-gray-200">
        <nav className="-mb-px flex gap-6">
          {[
            { id: 'rombongan', label: 'Rombongans', icon: Users },
            { id: 'packages', label: 'Packages', icon: Package },
            { id: 'emi', label: 'EMI Plans', icon: CreditCard }
          ].map(tab => (
            <button
              key={tab.id}
              onClick={() => { setActiveTab(tab.id as TabType); setSearchTerm(''); }}
              className={`flex items-center gap-2 py-3 px-1 border-b-2 font-medium text-sm transition-colors ${
                activeTab === tab.id
                  ? 'border-primary-500 text-primary-600'
                  : 'border-transparent text-gray-500 hover:text-gray-700 hover:border-gray-300'
              }`}
            >
              <tab.icon className="w-4 h-4" />
              {tab.label}
            </button>
          ))}
        </nav>
      </div>

      <div className="card">
        <div className="p-4 border-b border-gray-200">
          <div className="relative max-w-md">
            <Search className="absolute left-3 top-1/2 -translate-y-1/2 w-5 h-5 text-gray-400" />
            <input
              type="text"
              placeholder={`Search ${activeTab}...`}
              value={searchTerm}
              onChange={(e) => setSearchTerm(e.target.value)}
              className="input pl-10"
            />
          </div>
        </div>

        {loading ? (
          <div className="p-6 text-center">Loading...</div>
        ) : (
          <>
            {/* Rombongans Tab */}
            {activeTab === 'rombongan' && (
              filteredRombongans.length === 0 ? (
                <div className="p-6 text-center text-gray-500">No rombongans found.</div>
              ) : (
                <div className="divide-y divide-gray-100">
                  {filteredRombongans.map((rombongan) => (
                    <div key={rombongan.id} className="p-4 flex items-center justify-between hover:bg-gray-50">
                      <div className="flex items-center gap-4">
                        <div className="w-12 h-12 bg-primary-100 rounded-lg flex items-center justify-center">
                          <Users className="w-6 h-6 text-primary-600" />
                        </div>
                        <div>
                          <p className="font-medium text-gray-900">{rombongan.name}</p>
                          <div className="flex items-center gap-4 text-sm text-gray-500 mt-1">
                            <span className="flex items-center gap-1">
                              <Calendar className="w-4 h-4" />
                              {rombongan.start_date} - {rombongan.end_date}
                            </span>
                          </div>
                        </div>
                      </div>
                      <div className="flex items-center gap-3">
                        <span className={`px-3 py-1 rounded-full text-xs font-medium ${statusColors[rombongan.status]}`}>
                          {rombongan.status}
                        </span>
                        <button onClick={() => openModal('rombongan', romongan)} className="text-primary-600 hover:text-primary-700 text-sm font-medium">
                          <Edit2 className="w-4 h-4" />
                        </button>
                        <button onClick={() => handleDeleteRombongan(rombongan.id)} className="text-red-600 hover:text-red-700 text-sm font-medium">
                          <Trash2 className="w-4 h-4" />
                        </button>
                      </div>
                    </div>
                  ))}
                </div>
              )
            )}

            {/* Packages Tab */}
            {activeTab === 'packages' && (
              filteredPackages.length === 0 ? (
                <div className="p-6 text-center text-gray-500">No packages found.</div>
              ) : (
                <div className="divide-y divide-gray-100">
                  {filteredPackages.map((pkg) => (
                    <div key={pkg.id} className="p-4 flex items-center justify-between hover:bg-gray-50">
                      <div className="flex items-center gap-4">
                        <div className="w-12 h-12 bg-indigo-100 rounded-lg flex items-center justify-center">
                          <Package className="w-6 h-6 text-indigo-600" />
                        </div>
                        <div>
                          <p className="font-medium text-gray-900">{pkg.name}</p>
                          <div className="flex items-center gap-4 text-sm text-gray-500 mt-1">
                            <span>Capacity: {pkg.capacity}</span>
                            <span>{formatCurrency(pkg.price)}</span>
                          </div>
                        </div>
                      </div>
                      <div className="flex items-center gap-3">
                        <button onClick={() => openModal('package', pkg)} className="text-primary-600 hover:text-primary-700 text-sm font-medium">
                          <Edit2 className="w-4 h-4" />
                        </button>
                        <button onClick={() => handleDeletePackage(pkg.id)} className="text-red-600 hover:text-red-700 text-sm font-medium">
                          <Trash2 className="w-4 h-4" />
                        </button>
                      </div>
                    </div>
                  ))}
                </div>
              )
            )}

            {/* EMI Plans Tab */}
            {activeTab === 'emi' && (
              filteredEmiPlans.length === 0 ? (
                <div className="p-6 text-center text-gray-500">No EMI plans found.</div>
              ) : (
                <div className="divide-y divide-gray-100">
                  {filteredEmiPlans.map((plan) => (
                    <div key={plan.id} className="p-4 flex items-center justify-between hover:bg-gray-50">
                      <div className="flex items-center gap-4">
                        <div className="w-12 h-12 bg-green-100 rounded-lg flex items-center justify-center">
                          <CreditCard className="w-6 h-6 text-green-600" />
                        </div>
                        <div>
                          <p className="font-medium text-gray-900">{plan.name}</p>
                          <div className="flex items-center gap-4 text-sm text-gray-500 mt-1">
                            <span>{formatCurrency(plan.total_amount)}</span>
                            <span>{plan.tenor_months}x</span>
                            <span>{formatCurrency(plan.monthly_amount)}/mo</span>
                          </div>
                        </div>
                      </div>
                      <div className="flex items-center gap-3">
                        <span className={`px-3 py-1 rounded-full text-xs font-medium ${statusColors[plan.status]}`}>
                          {plan.status}
                        </span>
                        <button onClick={() => openModal('emi', plan)} className="text-primary-600 hover:text-primary-700 text-sm font-medium">
                          <Edit2 className="w-4 h-4" />
                        </button>
                        <button onClick={() => handleDeleteEmiPlan(plan.id)} className="text-red-600 hover:text-red-700 text-sm font-medium">
                          <Trash2 className="w-4 h-4" />
                        </button>
                      </div>
                    </div>
                  ))}
                </div>
              )
            )}
          </>
        )}
      </div>

      {/* Modal */}
      {showModal && (
        <div className="fixed inset-0 bg-black/50 flex items-center justify-center z-50">
          <div className="bg-white rounded-xl shadow-xl w-full max-w-lg max-h-[90vh] overflow-y-auto">
            <div className="flex items-center justify-between p-4 border-b border-gray-200">
              <h2 className="text-lg font-semibold text-gray-900">
                {editingItem ? 'Edit' : 'New'} {modalType === 'rombongan' ? 'Rombongan' : modalType === 'package' ? 'Package' : 'EMI Plan'}
              </h2>
              <button onClick={closeModal} className="text-gray-400 hover:text-gray-600">
                <X className="w-5 h-5" />
              </button>
            </div>
            
            <div className="p-4 space-y-4">
              {modalType === 'rombongan' && (
                <>
                  <div>
                    <label className="block text-sm font-medium text-gray-700 mb-1">Name</label>
                    <input
                      type="text"
                      value={rombonganForm.name}
                      onChange={(e) => setRombonganForm(prev => ({ ...prev, name: e.target.value }))}
                      className="input w-full"
                      placeholder="e.g., Group Jakarta 2026"
                    />
                  </div>
                  <div className="grid grid-cols-2 gap-4">
                    <div>
                      <label className="block text-sm font-medium text-gray-700 mb-1">Start Date</label>
                      <input
                        type="date"
                        value={rombonganForm.start_date}
                        onChange={(e) => setRombonganForm(prev => ({ ...prev, start_date: e.target.value }))}
                        className="input w-full"
                      />
                    </div>
                    <div>
                      <label className="block text-sm font-medium text-gray-700 mb-1">End Date</label>
                      <input
                        type="date"
                        value={rombonganForm.end_date}
                        onChange={(e) => setRombonganForm(prev => ({ ...prev, end_date: e.target.value }))}
                        className="input w-full"
                      />
                    </div>
                  </div>
                  <div>
                    <label className="block text-sm font-medium text-gray-700 mb-1">Status</label>
                    <select
                      value={rombonganForm.status}
                      onChange={(e) => setRombonganForm(prev => ({ ...prev, status: e.target.value as any }))}
                      className="input w-full"
                    >
                      <option value="planned">Planned</option>
                      <option value="active">Active</option>
                      <option value="completed">Completed</option>
                    </select>
                  </div>
                </>
              )}

              {modalType === 'package' && (
                <>
                  <div>
                    <label className="block text-sm font-medium text-gray-700 mb-1">Rombongan</label>
                    <select
                      value={packageForm.romongan_id}
                      onChange={(e) => setPackageForm(prev => ({ ...prev, romongan_id: e.target.value }))}
                      className="input w-full"
                    >
                      <option value="">Select Rombongan</option>
                      {rombongans.map(r => (
                        <option key={r.id} value={r.id}>{r.name}</option>
                      ))}
                    </select>
                  </div>
                  <div>
                    <label className="block text-sm font-medium text-gray-700 mb-1">Name</label>
                    <input
                      type="text"
                      value={packageForm.name}
                      onChange={(e) => setPackageForm(prev => ({ ...prev, name: e.target.value }))}
                      className="input w-full"
                    />
                  </div>
                  <div>
                    <label className="block text-sm font-medium text-gray-700 mb-1">Description</label>
                    <textarea
                      value={packageForm.description}
                      onChange={(e) => setPackageForm(prev => ({ ...prev, description: e.target.value }))}
                      className="input w-full"
                      rows={3}
                    />
                  </div>
                  <div className="grid grid-cols-2 gap-4">
                    <div>
                      <label className="block text-sm font-medium text-gray-700 mb-1">Price (IDR)</label>
                      <input
                        type="number"
                        value={packageForm.price}
                        onChange={(e) => setPackageForm(prev => ({ ...prev, price: Number(e.target.value) }))}
                        className="input w-full"
                      />
                    </div>
                    <div>
                      <label className="block text-sm font-medium text-gray-700 mb-1">Capacity</label>
                      <input
                        type="number"
                        value={packageForm.capacity}
                        onChange={(e) => setPackageForm(prev => ({ ...prev, capacity: Number(e.target.value) }))}
                        className="input w-full"
                      />
                    </div>
                  </div>
                  <div>
                    <label className="block text-sm font-medium text-gray-700 mb-1">Included Services (comma-separated)</label>
                    <input
                      type="text"
                      value={packageForm.included_services}
                      onChange={(e) => setPackageForm(prev => ({ ...prev, included_services: e.target.value }))}
                      className="input w-full"
                      placeholder="e.g., Transport, Hotel, Meals"
                    />
                  </div>
                </>
              )}

              {modalType === 'emi' && (
                <>
                  <div>
                    <label className="block text-sm font-medium text-gray-700 mb-1">Rombongan</label>
                    <select
                      value={emiForm.romongan_id}
                      onChange={(e) => setEmiForm(prev => ({ ...prev, romongan_id: e.target.value }))}
                      className="input w-full"
                    >
                      <option value="">Select Rombongan</option>
                      {rombongans.map(r => (
                        <option key={r.id} value={r.id}>{r.name}</option>
                      ))}
                    </select>
                  </div>
                  <div>
                    <label className="block text-sm font-medium text-gray-700 mb-1">Plan Name</label>
                    <input
                      type="text"
                      value={emiForm.name}
                      onChange={(e) => setEmiForm(prev => ({ ...prev, name: e.target.value }))}
                      className="input w-full"
                    />
                  </div>
                  <div className="grid grid-cols-2 gap-4">
                    <div>
                      <label className="block text-sm font-medium text-gray-700 mb-1">Total Amount (IDR)</label>
                      <input
                        type="number"
                        value={emiForm.total_amount}
                        onChange={(e) => setEmiForm(prev => ({ ...prev, total_amount: Number(e.target.value) }))}
                        className="input w-full"
                      />
                    </div>
                    <div>
                      <label className="block text-sm font-medium text-gray-700 mb-1">Down Payment (IDR)</label>
                      <input
                        type="number"
                        value={emiForm.down_payment}
                        onChange={(e) => setEmiForm(prev => ({ ...prev, down_payment: Number(e.target.value) }))}
                        className="input w-full"
                      />
                    </div>
                  </div>
                  <div className="grid grid-cols-2 gap-4">
                    <div>
                      <label className="block text-sm font-medium text-gray-700 mb-1">Tenor (Months)</label>
                      <select
                        value={emiForm.tenor_months}
                        onChange={(e) => setEmiForm(prev => ({ ...prev, tenor_months: Number(e.target.value) }))}
                        className="input w-full"
                      >
                        {[3, 6, 9, 12, 18, 24].map(n => (
                          <option key={n} value={n}>{n} Months</option>
                        ))}
                      </select>
                    </div>
                    <div>
                      <label className="block text-sm font-medium text-gray-700 mb-1">Interest Rate (%)</label>
                      <input
                        type="number"
                        value={emiForm.interest_rate}
                        onChange={(e) => setEmiForm(prev => ({ ...prev, interest_rate: Number(e.target.value) }))}
                        className="input w-full"
                        step="0.1"
                      />
                    </div>
                  </div>
                  <div className="grid grid-cols-2 gap-4">
                    <div>
                      <label className="block text-sm font-medium text-gray-700 mb-1">Start Date</label>
                      <input
                        type="date"
                        value={emiForm.start_date}
                        onChange={(e) => setEmiForm(prev => ({ ...prev, start_date: e.target.value }))}
                        className="input w-full"
                      />
                    </div>
                    <div>
                      <label className="block text-sm font-medium text-gray-700 mb-1">End Date</label>
                      <input
                        type="date"
                        value={emiForm.end_date}
                        onChange={(e) => setEmiForm(prev => ({ ...prev, end_date: e.target.value }))}
                        className="input w-full"
                      />
                    </div>
                  </div>
                  <div>
                    <label className="block text-sm font-medium text-gray-700 mb-1">Status</label>
                    <select
                      value={emiForm.status}
                      onChange={(e) => setEmiForm(prev => ({ ...prev, status: e.target.value as any }))}
                      className="input w-full"
                    >
                      <option value="active">Active</option>
                      <option value="completed">Completed</option>
                      <option value="cancelled">Cancelled</option>
                    </select>
                  </div>
                  {emiForm.total_amount > 0 && emiForm.down_payment >= 0 && emiForm.tenor_months > 0 && (
                    <div className="bg-green-50 p-3 rounded-lg">
                      <p className="text-sm text-green-800">
                        <strong>Estimated Monthly:</strong> {formatCurrency((emiForm.total_amount - emiForm.down_payment) / emiForm.tenor_months)}
                      </p>
                    </div>
                  )}
                </>
              )}
            </div>

            <div className="flex items-center justify-end gap-3 p-4 border-t border-gray-200">
              <button onClick={closeModal} className="btn-secondary">
                Cancel
              </button>
              <button onClick={handleSubmit} className="btn-primary flex items-center gap-2">
                <Check className="w-4 h-4" />
                {editingItem ? 'Update' : 'Create'}
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  )
}
