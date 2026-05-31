import {
  CreditCard, Download, Search, CheckCircle, Clock, AlertCircle,
  FileText, Send, Loader2, X, Mail, Calendar, Plus, Eye, RefreshCw
} from 'lucide-react'
import { useState, useEffect } from 'react'
import {
  useBillingInvoices,
  useSendInvoiceEmail,
  useGenerateInvoice,
  useAgencies,
} from '../../lib/api'

interface GenerateInvoiceModalProps {
  isOpen: boolean
  onClose: () => void
  onSuccess?: () => void
}

function GenerateInvoiceModal({ isOpen, onClose, onSuccess }: GenerateInvoiceModalProps) {
  const [agencyId, setAgencyId] = useState('')
  const [periodStart, setPeriodStart] = useState('')
  const [periodEnd, setPeriodEnd] = useState('')
  const [pricePerSeat, setPricePerSeat] = useState('')
  const [customEmail, setCustomEmail] = useState('')
  const [sendEmail, setSendEmail] = useState(true)

  const generateInvoice = useGenerateInvoice()
  const sendEmailMutation = useSendInvoiceEmail()
  const { data: agencies } = useAgencies()

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault()
    try {
      const result = await generateInvoice.mutateAsync({
        agency_id: agencyId,
        period_start: periodStart,
        period_end: periodEnd,
        price_per_seat: pricePerSeat ? parseFloat(pricePerSeat) : undefined,
      })

      if (sendEmail && result.invoice) {
        const agency = agencies?.agencies?.find((a: any) => a.id === agencyId)
        await sendEmailMutation.mutateAsync({
          invoice_id: result.invoice.id,
          recipient_email: customEmail || agency?.email,
        })
      }

      onSuccess?.()
      onClose()
      // Reset form
      setAgencyId('')
      setPeriodStart('')
      setPeriodEnd('')
      setPricePerSeat('')
      setCustomEmail('')
    } catch (err) {
      console.error('Failed to generate invoice:', err)
    }
  }

  if (!isOpen) return null

  return (
    <div className="fixed inset-0 bg-black/50 flex items-center justify-center z-50">
      <div className="bg-white rounded-2xl shadow-xl w-full max-w-lg mx-4">
        <div className="flex items-center justify-between p-6 border-b border-slate-100">
          <h2 className="text-lg font-semibold text-slate-900">Generate New Invoice</h2>
          <button
            onClick={onClose}
            className="p-2 hover:bg-slate-100 rounded-lg transition-colors"
          >
            <X className="w-5 h-5 text-slate-500" />
          </button>
        </div>

        <form onSubmit={handleSubmit} className="p-6 space-y-4">
          <div>
            <label className="block text-sm font-medium text-slate-700 mb-1">
              Agency <span className="text-red-500">*</span>
            </label>
            <select
              value={agencyId}
              onChange={(e) => setAgencyId(e.target.value)}
              required
              className="input w-full"
            >
              <option value="">Select agency...</option>
              {agencies?.agencies?.map((agency: any) => (
                <option key={agency.id} value={agency.id}>
                  {agency.name}
                </option>
              ))}
            </select>
          </div>

          <div className="grid grid-cols-2 gap-4">
            <div>
              <label className="block text-sm font-medium text-slate-700 mb-1">
                Period Start <span className="text-red-500">*</span>
              </label>
              <input
                type="date"
                value={periodStart}
                onChange={(e) => setPeriodStart(e.target.value)}
                required
                className="input w-full"
              />
            </div>
            <div>
              <label className="block text-sm font-medium text-slate-700 mb-1">
                Period End <span className="text-red-500">*</span>
              </label>
              <input
                type="date"
                value={periodEnd}
                onChange={(e) => setPeriodEnd(e.target.value)}
                required
                className="input w-full"
              />
            </div>
          </div>

          <div>
            <label className="block text-sm font-medium text-slate-700 mb-1">
              Price per Seat (IDR)
            </label>
            <input
              type="number"
              value={pricePerSeat}
              onChange={(e) => setPricePerSeat(e.target.value)}
              placeholder="Leave empty for default"
              className="input w-full"
              min="0"
              step="1000"
            />
          </div>

          <div className="flex items-center gap-2">
            <input
              type="checkbox"
              id="sendEmail"
              checked={sendEmail}
              onChange={(e) => setSendEmail(e.target.checked)}
              className="w-4 h-4 rounded border-slate-300 text-accent-500 focus:ring-accent-500"
            />
            <label htmlFor="sendEmail" className="text-sm text-slate-700">
              Send invoice email to agency
            </label>
          </div>

          {sendEmail && (
            <div>
              <label className="block text-sm font-medium text-slate-700 mb-1">
                Custom Email (optional)
              </label>
              <input
                type="email"
                value={customEmail}
                onChange={(e) => setCustomEmail(e.target.value)}
                placeholder="Leave empty to use agency default"
                className="input w-full"
              />
            </div>
          )}

          <div className="flex gap-3 pt-4">
            <button
              type="button"
              onClick={onClose}
              className="flex-1 btn-secondary"
            >
              Cancel
            </button>
            <button
              type="submit"
              disabled={generateInvoice.isPending || sendEmailMutation.isPending}
              className="flex-1 btn-primary flex items-center justify-center gap-2"
            >
              {(generateInvoice.isPending || sendEmailMutation.isPending) ? (
                <>
                  <Loader2 className="w-4 h-4 animate-spin" />
                  Processing...
                </>
              ) : (
                <>
                  <Plus className="w-4 h-4" />
                  Generate & Send
                </>
              )}
            </button>
          </div>
        </form>
      </div>
    </div>
  )
}

interface InvoiceDetailModalProps {
  invoice: any
  isOpen: boolean
  onClose: () => void
}

function InvoiceDetailModal({ invoice, isOpen, onClose }: InvoiceDetailModalProps) {
  const sendEmail = useSendInvoiceEmail()
  const [customEmail, setCustomEmail] = useState('')
  const [emailSent, setEmailSent] = useState(false)

  const formatCurrency = (amount: number) => {
    return new Intl.NumberFormat('id-ID', {
      style: 'currency',
      currency: 'IDR',
      minimumFractionDigits: 0,
    }).format(amount)
  }

  const handleSendEmail = async () => {
    if (!invoice) return
    try {
      await sendEmail.mutateAsync({
        invoice_id: invoice.id,
        recipient_email: customEmail || undefined,
      })
      setEmailSent(true)
      setTimeout(() => setEmailSent(false), 3000)
    } catch (err) {
      console.error('Failed to send email:', err)
    }
  }

  if (!isOpen || !invoice) return null

  return (
    <div className="fixed inset-0 bg-black/50 flex items-center justify-center z-50">
      <div className="bg-white rounded-2xl shadow-xl w-full max-w-2xl mx-4 max-h-[90vh] overflow-y-auto">
        <div className="flex items-center justify-between p-6 border-b border-slate-100 sticky top-0 bg-white">
          <div>
            <h2 className="text-lg font-semibold text-slate-900">{invoice.invoice_number}</h2>
            <p className="text-sm text-slate-500">Invoice Details</p>
          </div>
          <button
            onClick={onClose}
            className="p-2 hover:bg-slate-100 rounded-lg transition-colors"
          >
            <X className="w-5 h-5 text-slate-500" />
          </button>
        </div>

        <div className="p-6 space-y-6">
          {/* Agency Info */}
          <div className="flex items-start justify-between">
            <div>
              <p className="text-sm text-slate-500">Bill To</p>
              <p className="font-semibold text-slate-900">{invoice.agency_name || 'N/A'}</p>
              <p className="text-sm text-slate-600">{invoice.agency_email || 'No email on record'}</p>
            </div>
            <div className="text-right">
              <p className="text-sm text-slate-500">Status</p>
              <span
                className={`inline-block px-2 py-1 rounded-full text-xs font-medium ${
                  invoice.status === 'paid'
                    ? 'bg-emerald-100 text-emerald-700'
                    : invoice.status === 'pending'
                    ? 'bg-amber-100 text-amber-700'
                    : invoice.status === 'overdue'
                    ? 'bg-red-100 text-red-700'
                    : 'bg-slate-100 text-slate-700'
                }`}
              >
                {invoice.status?.charAt(0).toUpperCase() + invoice.status?.slice(1)}
              </span>
            </div>
          </div>

          {/* Billing Period */}
          <div className="grid grid-cols-2 gap-4 p-4 bg-slate-50 rounded-xl">
            <div>
              <p className="text-xs text-slate-500 mb-1">Billing Period</p>
              <p className="text-sm font-medium text-slate-900">
                {new Date(invoice.billing_period_start).toLocaleDateString('id-ID', {
                  day: '2-digit',
                  month: 'short',
                  year: 'numeric',
                })}
                {' — '}
                {new Date(invoice.billing_period_end).toLocaleDateString('id-ID', {
                  day: '2-digit',
                  month: 'short',
                  year: 'numeric',
                })}
              </p>
            </div>
            <div>
              <p className="text-xs text-slate-500 mb-1">Due Date</p>
              <p className="text-sm font-medium text-slate-900">
                {new Date(invoice.due_date).toLocaleDateString('id-ID', {
                  day: '2-digit',
                  month: 'short',
                  year: 'numeric',
                })}
              </p>
            </div>
          </div>

          {/* Line Items */}
          <div className="border border-slate-200 rounded-xl overflow-hidden">
            <table className="w-full text-sm">
              <thead className="bg-slate-50">
                <tr>
                  <th className="px-4 py-3 text-left text-xs font-medium text-slate-500 uppercase">Description</th>
                  <th className="px-4 py-3 text-right text-xs font-medium text-slate-500 uppercase">Amount</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-slate-100">
                <tr>
                  <td className="px-4 py-3">
                    <p className="font-medium text-slate-900">Active Seats</p>
                    <p className="text-xs text-slate-500">
                      {invoice.active_pax_count} seats × {formatCurrency(invoice.price_per_seat)}
                    </p>
                  </td>
                  <td className="px-4 py-3 text-right text-slate-900">
                    {formatCurrency(invoice.subtotal)}
                  </td>
                </tr>
                {invoice.adjustments !== 0 && (
                  <tr>
                    <td className="px-4 py-3">
                      <p className="font-medium text-slate-900">Adjustments</p>
                    </td>
                    <td className="px-4 py-3 text-right text-slate-900">
                      {invoice.adjustments > 0 ? '+' : ''}
                      {formatCurrency(invoice.adjustments)}
                    </td>
                  </tr>
                )}
                <tr className="bg-slate-50 font-semibold">
                  <td className="px-4 py-3 text-slate-900">Total Due</td>
                  <td className="px-4 py-3 text-right text-slate-900">
                    {formatCurrency(invoice.total_due)}
                  </td>
                </tr>
              </tbody>
            </table>
          </div>

          {/* Send Email Section */}
          <div className="border border-dashed border-slate-300 rounded-xl p-4">
            <div className="flex items-center gap-2 mb-3">
              <Mail className="w-4 h-4 text-accent-600" />
              <p className="text-sm font-medium text-slate-900">Send Invoice Email</p>
            </div>
            <div className="flex gap-2">
              <input
                type="email"
                value={customEmail}
                onChange={(e) => setCustomEmail(e.target.value)}
                placeholder={invoice.agency_email || 'Recipient email'}
                className="input flex-1"
              />
              <button
                onClick={handleSendEmail}
                disabled={sendEmail.isPending}
                className="btn-secondary flex items-center gap-2"
              >
                {sendEmail.isPending ? (
                  <Loader2 className="w-4 h-4 animate-spin" />
                ) : emailSent ? (
                  <>
                    <CheckCircle className="w-4 h-4" />
                    Sent!
                  </>
                ) : (
                  <>
                    <Send className="w-4 h-4" />
                    Send
                  </>
                )}
              </button>
            </div>
          </div>

          {/* Actions */}
          <div className="flex gap-3 pt-4 border-t border-slate-100">
            {invoice.pdf_url && (
              <a
                href={invoice.pdf_url}
                target="_blank"
                rel="noopener noreferrer"
                className="flex-1 btn-secondary flex items-center justify-center gap-2"
              >
                <Download className="w-4 h-4" />
                Download PDF
              </a>
            )}
            <button onClick={onClose} className="flex-1 btn-primary">
              Close
            </button>
          </div>
        </div>
      </div>
    </div>
  )
}

export default function BillingAdmin() {
  const [search, setSearch] = useState('')
  const [statusFilter, setStatusFilter] = useState<'all' | 'pending' | 'paid' | 'overdue'>('all')
  const [dateFrom, setDateFrom] = useState('')
  const [dateTo, setDateTo] = useState('')
  const [showDateFilter, setShowDateFilter] = useState(false)
  const [showGenerateModal, setShowGenerateModal] = useState(false)
  const [selectedInvoice, setSelectedInvoice] = useState<any>(null)
  const [emailFilter, setEmailFilter] = useState('')

  const { data, isLoading, error, refetch } = useBillingInvoices(
    undefined,
    statusFilter === 'all' ? undefined : statusFilter
  )

  const invoices = data?.invoices ?? []

  // Client-side filtering for email and search
  const filteredInvoices = invoices.filter((inv) => {
    const matchesSearch =
      !search ||
      inv.invoice_number.toLowerCase().includes(search.toLowerCase()) ||
      (inv.agency_name?.toLowerCase().includes(search.toLowerCase()) ?? false)

    const matchesEmail =
      !emailFilter ||
      (inv.agency_email?.toLowerCase().includes(emailFilter.toLowerCase()) ?? false)

    const matchesDate =
      (!dateFrom || new Date(inv.created_at) >= new Date(dateFrom)) &&
      (!dateTo || new Date(inv.created_at) <= new Date(dateTo + 'T23:59:59'))

    return matchesSearch && matchesEmail && matchesDate
  })

  const totalPending = invoices.filter((i) => i.status === 'pending').reduce((acc, i) => acc + i.total_due, 0)
  const totalOverdue = invoices.filter((i) => i.status === 'overdue').reduce((acc, i) => acc + i.total_due, 0)
  const totalPaid = invoices.filter((i) => i.status === 'paid').reduce((acc, i) => acc + i.total_due, 0)

  const formatCurrency = (amount: number) => {
    return new Intl.NumberFormat('id-ID', {
      style: 'currency',
      currency: 'IDR',
      minimumFractionDigits: 0,
    }).format(amount)
  }

  const getStatusBadge = (status: string) => {
    switch (status) {
      case 'paid':
        return <span className="badge badge-success">Paid</span>
      case 'pending':
        return <span className="badge badge-warning">Pending</span>
      case 'overdue':
        return <span className="badge badge-danger">Overdue</span>
      default:
        return <span className="badge badge-info">{status}</span>
    }
  }

  const getStatusIcon = (status: string) => {
    switch (status) {
      case 'paid':
        return <CheckCircle className="w-5 h-5 text-emerald-600" />
      case 'pending':
        return <Clock className="w-5 h-5 text-accent-600" />
      case 'overdue':
        return <AlertCircle className="w-5 h-5 text-danger-600" />
      default:
        return <CreditCard className="w-5 h-5 text-slate-600" />
    }
  }

  const clearDateFilter = () => {
    setDateFrom('')
    setDateTo('')
  }

  const hasActiveDateFilter = dateFrom || dateTo

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
      {/* Generate Invoice Modal */}
      <GenerateInvoiceModal
        isOpen={showGenerateModal}
        onClose={() => setShowGenerateModal(false)}
        onSuccess={() => refetch()}
      />

      {/* Invoice Detail Modal */}
      <InvoiceDetailModal
        invoice={selectedInvoice}
        isOpen={!!selectedInvoice}
        onClose={() => setSelectedInvoice(null)}
      />

      {/* Page Header */}
      <div className="flex items-center justify-between">
        <div className="page-header mb-0">
          <h1 className="page-title">Billing & Invoices</h1>
          <p className="page-subtitle">Platform-wide billing management</p>
        </div>
        <div className="flex gap-3">
          <button
            onClick={() => refetch()}
            className="btn-secondary flex items-center gap-2"
          >
            <RefreshCw className="w-4 h-4" />
            Refresh
          </button>
          <button
            onClick={() => setShowGenerateModal(true)}
            className="btn-primary flex items-center gap-2"
          >
            <Plus className="w-4 h-4" />
            Generate Invoice
          </button>
        </div>
      </div>

      {/* Billing Stats */}
      <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
        <div className="card p-6 border-l-4 border-accent-500">
          <div className="flex items-start justify-between">
            <div>
              <p className="text-sm text-slate-500 mb-1">Pending</p>
              <p className="text-2xl font-bold text-accent-600">{formatCurrency(totalPending)}</p>
              <p className="text-xs text-slate-400 mt-1">Awaiting payment</p>
            </div>
            <div className="p-3 bg-accent-100 rounded-xl">
              <Clock className="w-6 h-6 text-accent-600" />
            </div>
          </div>
        </div>
        <div className="card p-6 border-l-4 border-danger-500">
          <div className="flex items-start justify-between">
            <div>
              <p className="text-sm text-slate-500 mb-1">Overdue</p>
              <p className="text-2xl font-bold text-danger-600">{formatCurrency(totalOverdue)}</p>
              <p className="text-xs text-slate-400 mt-1">Requires action</p>
            </div>
            <div className="p-3 bg-danger-100 rounded-xl">
              <AlertCircle className="w-6 h-6 text-danger-600" />
            </div>
          </div>
        </div>
        <div className="card p-6 border-l-4 border-emerald-500">
          <div className="flex items-start justify-between">
            <div>
              <p className="text-sm text-slate-500 mb-1">Paid (This Month)</p>
              <p className="text-2xl font-bold text-emerald-600">{formatCurrency(totalPaid)}</p>
              <p className="text-xs text-slate-400 mt-1">Settled payments</p>
            </div>
            <div className="p-3 bg-emerald-100 rounded-xl">
              <CheckCircle className="w-6 h-6 text-emerald-600" />
            </div>
          </div>
        </div>
      </div>

      {/* Invoices Table */}
      <div className="card">
        <div className="p-4 border-b border-slate-100">
          <div className="flex flex-col gap-4 justify-between">
            <h2 className="text-lg font-semibold text-slate-900">Invoice History</h2>
            <div className="flex flex-col md:flex-row gap-3 flex-wrap">
              {/* Search */}
              <div className="relative">
                <Search className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-slate-400" />
                <input
                  type="text"
                  placeholder="Search invoices or agency..."
                  value={search}
                  onChange={(e) => setSearch(e.target.value)}
                  className="input pl-9 w-full md:w-64"
                />
              </div>

              {/* Email Filter */}
              <div className="relative">
                <Mail className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-slate-400" />
                <input
                  type="email"
                  placeholder="Filter by email..."
                  value={emailFilter}
                  onChange={(e) => setEmailFilter(e.target.value)}
                  className="input pl-9 w-full md:w-64"
                />
              </div>

              {/* Date Filter Toggle */}
              <button
                onClick={() => setShowDateFilter(!showDateFilter)}
                className={`btn-secondary flex items-center gap-2 ${
                  showDateFilter || hasActiveDateFilter ? 'bg-accent-100 border-accent-300' : ''
                }`}
              >
                <Calendar className="w-4 h-4" />
                Date Filter
                {hasActiveDateFilter && (
                  <span className="w-2 h-2 bg-accent-500 rounded-full" />
                )}
              </button>

              {/* Status Filter */}
              <div className="flex gap-2">
                {(['all', 'pending', 'paid', 'overdue'] as const).map((f) => (
                  <button
                    key={f}
                    onClick={() => setStatusFilter(f)}
                    className={`px-3 py-2 text-sm font-medium rounded-lg transition-colors ${
                      statusFilter === f
                        ? 'bg-accent-500 text-white'
                        : 'bg-slate-100 text-slate-600 hover:bg-slate-200'
                    }`}
                  >
                    {f.charAt(0).toUpperCase() + f.slice(1)}
                  </button>
                ))}
              </div>
            </div>

            {/* Date Range Filter Panel */}
            {showDateFilter && (
              <div className="flex items-center gap-4 p-4 bg-slate-50 rounded-xl">
                <div className="flex-1">
                  <label className="block text-xs font-medium text-slate-500 mb-1">From</label>
                  <input
                    type="date"
                    value={dateFrom}
                    onChange={(e) => setDateFrom(e.target.value)}
                    className="input w-full"
                  />
                </div>
                <div className="flex-1">
                  <label className="block text-xs font-medium text-slate-500 mb-1">To</label>
                  <input
                    type="date"
                    value={dateTo}
                    onChange={(e) => setDateTo(e.target.value)}
                    className="input w-full"
                  />
                </div>
                {hasActiveDateFilter && (
                  <button
                    onClick={clearDateFilter}
                    className="flex items-center gap-1 text-sm text-slate-500 hover:text-slate-700 mt-5"
                  >
                    <X className="w-4 h-4" />
                    Clear
                  </button>
                )}
              </div>
            )}

            {/* Active Filters Summary */}
            {(emailFilter || hasActiveDateFilter) && (
              <div className="flex items-center gap-2 text-sm text-slate-500">
                <span>Active filters:</span>
                {emailFilter && (
                  <span className="inline-flex items-center gap-1 px-2 py-1 bg-accent-100 text-accent-700 rounded-full">
                    Email: {emailFilter}
                    <button onClick={() => setEmailFilter('')}>
                      <X className="w-3 h-3" />
                    </button>
                  </span>
                )}
                {hasActiveDateFilter && (
                  <span className="inline-flex items-center gap-1 px-2 py-1 bg-accent-100 text-accent-700 rounded-full">
                    {dateFrom && dateTo
                      ? `${dateFrom} — ${dateTo}`
                      : dateFrom
                      ? `From ${dateFrom}`
                      : `Until ${dateTo}`}
                    <button onClick={clearDateFilter}>
                      <X className="w-3 h-3" />
                    </button>
                  </span>
                )}
              </div>
            )}
          </div>
        </div>
        <div className="overflow-x-auto">
          <table className="w-full">
            <thead>
              <tr className="table-header">
                <th className="px-6 py-3 text-left">Invoice</th>
                <th className="px-6 py-3 text-left">Agency</th>
                <th className="px-6 py-3 text-left">Period</th>
                <th className="px-6 py-3 text-left">Amount</th>
                <th className="px-6 py-3 text-left">Seats</th>
                <th className="px-6 py-3 text-left">Due Date</th>
                <th className="px-6 py-3 text-left">Status</th>
                <th className="px-6 py-3 text-left">Actions</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-slate-100">
              {filteredInvoices.map((invoice) => (
                <tr key={invoice.id} className="table-row">
                  <td className="px-6 py-4">
                    <div className="flex items-center gap-3">
                      <div className="p-2 bg-accent-100 rounded-lg">
                        <FileText className="w-5 h-5 text-accent-600" />
                      </div>
                      <div>
                        <p className="font-semibold text-slate-900">{invoice.invoice_number}</p>
                        <p className="text-xs text-slate-400">
                          {new Date(invoice.created_at).toLocaleDateString('id-ID', {
                            day: '2-digit',
                            month: 'short',
                            year: 'numeric',
                          })}
                        </p>
                      </div>
                    </div>
                  </td>
                  <td className="px-6 py-4">
                    <div>
                      <p className="font-medium text-slate-900">{invoice.agency_name || 'N/A'}</p>
                      <p className="text-xs text-slate-500">{invoice.agency_email || 'No email'}</p>
                    </div>
                  </td>
                  <td className="px-6 py-4 text-sm text-slate-600">
                    {new Date(invoice.billing_period_start).toLocaleDateString('id-ID', {
                      day: '2-digit',
                      month: 'short',
                    })}
                    {' — '}
                    {new Date(invoice.billing_period_end).toLocaleDateString('id-ID', {
                      day: '2-digit',
                      month: 'short',
                      year: 'numeric',
                    })}
                  </td>
                  <td className="px-6 py-4 font-semibold text-slate-900">
                    {formatCurrency(invoice.total_due)}
                  </td>
                  <td className="px-6 py-4 text-slate-600">{invoice.active_pax_count} seats</td>
                  <td className="px-6 py-4 text-slate-500">
                    {new Date(invoice.due_date).toLocaleDateString('id-ID', {
                      day: '2-digit',
                      month: 'short',
                      year: 'numeric',
                    })}
                  </td>
                  <td className="px-6 py-4">
                    <div className="flex items-center gap-2">
                      {getStatusIcon(invoice.status)}
                      {getStatusBadge(invoice.status)}
                    </div>
                  </td>
                  <td className="px-6 py-4">
                    <div className="flex items-center gap-2">
                      <button
                        onClick={() => setSelectedInvoice(invoice)}
                        className="text-accent-600 hover:text-accent-700 text-sm font-medium flex items-center gap-1"
                      >
                        <Eye className="w-4 h-4" />
                        View
                      </button>
                      {invoice.pdf_url && (
                        <a
                          href={invoice.pdf_url}
                          target="_blank"
                          rel="noopener noreferrer"
                          className="text-primary-600 hover:text-primary-700 text-sm font-medium flex items-center gap-1"
                        >
                          <Download className="w-4 h-4" />
                          Download
                        </a>
                      )}
                    </div>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
        {filteredInvoices.length === 0 && (
          <div className="p-8 text-center">
            <CreditCard className="w-12 h-12 text-slate-300 mx-auto mb-3" />
            <p className="text-slate-500">No invoices found matching your criteria</p>
          </div>
        )}
      </div>
    </div>
  )
}
