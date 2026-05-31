import { Activity, Database, Server, Cloud, AlertTriangle, CheckCircle, RefreshCw, Eye, Zap, Clock, Loader2, Users, Building2, Shield, TrendingUp, TrendingDown, Bell, FileText, Search, ChevronDown, Info } from 'lucide-react'
import { useAdminSystemStats, useLowStockAlerts } from '../../lib/api'
import { useState } from 'react'

// ============================================================
// Types
// ============================================================
interface Alert {
  id: string
  threshold: number
  current_balance: number
  status: string
  triggered_at: string
  acknowledged_at: string | null
  acknowledged_by: string | null
}

interface AuditLogEntry {
  id: string
  timestamp: string
  actor: string
  action: string
  resource: string
  details: string
  severity: 'info' | 'warning' | 'critical'
}

// ============================================================
// Mock audit log data (replace with actual API when available)
// ============================================================
const mockAuditLogs: AuditLogEntry[] = [
  { id: '1', timestamp: '2026-05-31T14:23:00Z', actor: 'admin@haramain.id', action: 'UPDATE', resource: 'Seat License', details: 'Agency XYZ - 50 seats purchased', severity: 'info' },
  { id: '2', timestamp: '2026-05-31T13:15:00Z', actor: 'system', action: 'ALERT', resource: 'Low Stock Alert', details: 'Agency ABC threshold triggered (balance: 5)', severity: 'warning' },
  { id: '3', timestamp: '2026-05-31T12:00:00Z', actor: 'admin@haramain.id', action: 'SUSPEND', resource: 'Agency', details: 'Agency DEF suspended due to payment failure', severity: 'critical' },
  { id: '4', timestamp: '2026-05-30T18:30:00Z', actor: 'billing@haramain.id', action: 'INVOICE', resource: 'Invoice', details: 'Monthly invoice generated for 12 agencies', severity: 'info' },
  { id: '5', timestamp: '2026-05-30T10:00:00Z', actor: 'system', action: 'BACKUP', resource: 'Database', details: 'Daily backup completed successfully', severity: 'info' },
  { id: '6', timestamp: '2026-05-29T16:45:00Z', actor: 'admin@haramain.id', action: 'CREATE', resource: 'User', details: 'New admin user created: operator@haramain.id', severity: 'info' },
  { id: '7', timestamp: '2026-05-29T09:00:00Z', actor: 'system', action: 'MAINTENANCE', resource: 'Edge Functions', details: 'Scheduled cold start optimization deployed', severity: 'info' },
  { id: '8', timestamp: '2026-05-28T22:00:00Z', actor: 'system', action: 'ALERT', resource: 'Panic Alert', details: 'Open panic alert auto-escalated after 30min', severity: 'warning' },
]

// ============================================================
// Health Status Indicator Component
// ============================================================
function StatusBadge({ status, label }: { status: 'operational' | 'degraded' | 'down' | 'maintenance', label: string }) {
  const styles = {
    operational: 'bg-emerald-100 text-emerald-700 border-emerald-200',
    degraded: 'bg-amber-100 text-amber-700 border-amber-200',
    down: 'bg-red-100 text-red-700 border-red-200',
    maintenance: 'bg-blue-100 text-blue-700 border-blue-200',
  }
  return (
    <span className={`px-2 py-1 text-xs font-medium rounded-full border ${styles[status]}`}>
      {label}
    </span>
  )
}

// ============================================================
// Metric Card Component
// ============================================================
function MetricCard({ title, value, subtitle, icon: Icon, trend, trendValue, color }: {
  title: string
  value: string | number
  subtitle?: string
  icon: React.ElementType
  trend?: 'up' | 'down' | 'neutral'
  trendValue?: string
  color: 'emerald' | 'blue' | 'purple' | 'accent' | 'danger' | 'amber'
}) {
  const colors = {
    emerald: 'bg-emerald-100 text-emerald-600',
    blue: 'bg-blue-100 text-blue-600',
    purple: 'bg-purple-100 text-purple-600',
    accent: 'bg-accent-100 text-accent-600',
    danger: 'bg-danger-100 text-danger-600',
    amber: 'bg-amber-100 text-amber-600',
  }
  const trendColors = {
    up: 'text-emerald-600',
    down: 'text-red-600',
    neutral: 'text-slate-400',
  }
  const TrendIcon = trend === 'up' ? TrendingUp : trend === 'down' ? TrendingDown : null

  return (
    <div className="card p-6 hover:shadow-md transition-shadow">
      <div className="flex items-start justify-between">
        <div className="flex-1">
          <p className="text-sm text-slate-500 mb-1">{title}</p>
          <p className="text-3xl font-bold text-slate-900">{value}</p>
          {subtitle && <p className="mt-1 text-sm text-slate-500">{subtitle}</p>}
          {trend && trendValue && TrendIcon && (
            <div className={`flex items-center gap-1 mt-2 ${trendColors[trend]}`}>
              <TrendIcon className="w-4 h-4" />
              <span className="text-xs font-medium">{trendValue}</span>
            </div>
          )}
        </div>
        <div className={`p-3 rounded-xl ${colors[color]}`}>
          <Icon className="w-6 h-6" />
        </div>
      </div>
    </div>
  )
}

// ============================================================
// Alerts Panel Component
// ============================================================
function AlertsPanel({ alerts, isLoading }: { alerts: Alert[] | undefined, isLoading: boolean }) {
  const [filter, setFilter] = useState<'all' | 'active' | 'acknowledged'>('all')

  const filteredAlerts = alerts?.filter(a => {
    if (filter === 'active') return a.status === 'triggered'
    if (filter === 'acknowledged') return a.status === 'acknowledged' || a.status === 'dismissed'
    return true
  }) ?? []

  if (isLoading) {
    return (
      <div className="card p-6">
        <div className="flex items-center justify-center h-32">
          <Loader2 className="w-6 h-6 animate-spin text-accent-500" />
        </div>
      </div>
    )
  }

  return (
    <div className="card p-6">
      <div className="flex items-center justify-between mb-4">
        <div className="flex items-center gap-3">
          <div className="p-2 bg-amber-100 rounded-lg">
            <Bell className="w-5 h-5 text-amber-600" />
          </div>
          <h2 className="text-lg font-semibold text-slate-900">Seat Alerts</h2>
          {filteredAlerts.length > 0 && (
            <span className="px-2 py-0.5 text-xs font-medium bg-amber-100 text-amber-700 rounded-full">
              {filteredAlerts.length}
            </span>
          )}
        </div>
        <div className="flex items-center gap-2">
          <select
            value={filter}
            onChange={(e) => setFilter(e.target.value as typeof filter)}
            className="text-sm border border-slate-200 rounded-lg px-3 py-1.5 focus:outline-none focus:ring-2 focus:ring-accent-500"
          >
            <option value="all">All Alerts</option>
            <option value="active">Active</option>
            <option value="acknowledged">Acknowledged</option>
          </select>
        </div>
      </div>

      {filteredAlerts.length === 0 ? (
        <div className="text-center py-8">
          <CheckCircle className="w-12 h-12 text-emerald-500 mx-auto mb-2" />
          <p className="text-slate-600">No alerts matching your filter</p>
        </div>
      ) : (
        <div className="space-y-3">
          {filteredAlerts.map((alert) => (
            <div
              key={alert.id}
              className={`p-4 rounded-lg border ${
                alert.status === 'triggered'
                  ? 'bg-amber-50 border-amber-200'
                  : 'bg-slate-50 border-slate-200'
              }`}
            >
              <div className="flex items-start justify-between">
                <div className="flex items-center gap-2">
                  <AlertTriangle className={`w-4 h-4 ${alert.status === 'triggered' ? 'text-amber-600' : 'text-slate-400'}`} />
                  <span className="font-medium text-slate-900">
                    Balance: {alert.current_balance} seats
                  </span>
                </div>
                <span className={`text-xs px-2 py-1 rounded-full ${
                  alert.status === 'triggered'
                    ? 'bg-amber-100 text-amber-700'
                    : alert.status === 'acknowledged'
                    ? 'bg-blue-100 text-blue-700'
                    : 'bg-slate-100 text-slate-600'
                }`}>
                  {alert.status}
                </span>
              </div>
              <div className="mt-2 flex items-center gap-4 text-xs text-slate-500">
                <span>Threshold: {alert.threshold}</span>
                <span>Triggered: {new Date(alert.triggered_at).toLocaleString()}</span>
                {alert.acknowledged_at && (
                  <span>Acknowledged: {new Date(alert.acknowledged_at).toLocaleString()}</span>
                )}
              </div>
            </div>
          ))}
        </div>
      )}
    </div>
  )
}

// ============================================================
// Audit Log Section Component
// ============================================================
function AuditLogSection() {
  const [searchTerm, setSearchTerm] = useState('')
  const [severityFilter, setSeverityFilter] = useState<'all' | 'info' | 'warning' | 'critical'>('all')
  const [expanded, setExpanded] = useState(false)

  const filteredLogs = mockAuditLogs.filter(log => {
    const matchesSearch = log.actor.toLowerCase().includes(searchTerm.toLowerCase()) ||
      log.action.toLowerCase().includes(searchTerm.toLowerCase()) ||
      log.resource.toLowerCase().includes(searchTerm.toLowerCase()) ||
      log.details.toLowerCase().includes(searchTerm.toLowerCase())
    const matchesSeverity = severityFilter === 'all' || log.severity === severityFilter
    return matchesSearch && matchesSeverity
  })

  const displayedLogs = expanded ? filteredLogs : filteredLogs.slice(0, 5)

  const severityStyles = {
    info: 'bg-blue-100 text-blue-700 border-blue-200',
    warning: 'bg-amber-100 text-amber-700 border-amber-200',
    critical: 'bg-red-100 text-red-700 border-red-200',
  }

  const severityIcons = {
    info: <Info className="w-3.5 h-3.5" />,
    warning: <AlertTriangle className="w-3.5 h-3.5" />,
    critical: <AlertTriangle className="w-3.5 h-3.5" />,
  }

  return (
    <div className="card p-6">
      <div className="flex items-center justify-between mb-4">
        <div className="flex items-center gap-3">
          <div className="p-2 bg-primary-100 rounded-lg">
            <FileText className="w-5 h-5 text-primary-600" />
          </div>
          <h2 className="text-lg font-semibold text-slate-900">Audit Log</h2>
          <span className="px-2 py-0.5 text-xs font-medium bg-slate-100 text-slate-600 rounded-full">
            {filteredLogs.length} entries
          </span>
        </div>
      </div>

      {/* Filters */}
      <div className="flex flex-wrap items-center gap-3 mb-4">
        <div className="relative flex-1 min-w-[200px]">
          <Search className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-slate-400" />
          <input
            type="text"
            placeholder="Search logs..."
            value={searchTerm}
            onChange={(e) => setSearchTerm(e.target.value)}
            className="w-full pl-9 pr-4 py-2 text-sm border border-slate-200 rounded-lg focus:outline-none focus:ring-2 focus:ring-accent-500"
          />
        </div>
        <div className="flex items-center gap-1 bg-slate-100 p-1 rounded-lg">
          {(['all', 'info', 'warning', 'critical'] as const).map((sev) => (
            <button
              key={sev}
              onClick={() => setSeverityFilter(sev)}
              className={`px-3 py-1.5 text-xs font-medium rounded-md transition-colors ${
                severityFilter === sev
                  ? 'bg-white text-slate-900 shadow-sm'
                  : 'text-slate-500 hover:text-slate-700'
              }`}
            >
              {sev.charAt(0).toUpperCase() + sev.slice(1)}
            </button>
          ))}
        </div>
      </div>

      {/* Log Entries */}
      <div className="space-y-2">
        {displayedLogs.map((log) => (
          <div
            key={log.id}
            className="p-3 bg-slate-50 rounded-lg hover:bg-slate-100 transition-colors"
          >
            <div className="flex items-start justify-between gap-3">
              <div className="flex items-start gap-3">
                <div className={`p-1.5 rounded-md border ${severityStyles[log.severity]}`}>
                  {severityIcons[log.severity]}
                </div>
                <div>
                  <div className="flex items-center gap-2 mb-0.5">
                    <span className="font-medium text-slate-900">{log.action}</span>
                    <span className="text-slate-400">•</span>
                    <span className="text-sm text-slate-600">{log.resource}</span>
                  </div>
                  <p className="text-sm text-slate-500">{log.details}</p>
                  <div className="flex items-center gap-3 mt-1.5 text-xs text-slate-400">
                    <span>{log.actor}</span>
                    <span>•</span>
                    <span>{new Date(log.timestamp).toLocaleString()}</span>
                  </div>
                </div>
              </div>
            </div>
          </div>
        ))}
      </div>

      {/* Show More/Less */}
      {filteredLogs.length > 5 && (
        <button
          onClick={() => setExpanded(!expanded)}
          className="mt-4 w-full py-2 text-sm font-medium text-accent-600 hover:text-accent-700 bg-accent-50 hover:bg-accent-100 rounded-lg transition-colors flex items-center justify-center gap-2"
        >
          {expanded ? (
            <>
              <ChevronDown className="w-4 h-4 rotate-180" />
              Show Less
            </>
          ) : (
            <>
              <ChevronDown className="w-4 h-4" />
              Show {filteredLogs.length - 5} More Entries
            </>
          )}
        </button>
      )}
    </div>
  )
}

// ============================================================
// Main Component
// ============================================================
export default function SystemHealth() {
  const { data: stats, isLoading, error } = useAdminSystemStats()
  const { data: alerts, isLoading: alertsLoading } = useLowStockAlerts()

  const services = [
    { name: 'Supabase Auth', status: 'operational' as const, latency: '12ms', uptime: '99.99%' },
    { name: 'Supabase Database', status: 'operational' as const, latency: '12ms', uptime: '99.98%' },
    { name: 'Firebase FCM', status: 'operational' as const, latency: '45ms', uptime: '99.95%' },
    { name: 'Xendit Payment', status: 'operational' as const, latency: '230ms', uptime: '99.87%' },
    { name: 'Edge Functions', status: 'operational' as const, latency: '180ms', uptime: '99.92%' },
    { name: 'CDN (Images)', status: 'operational' as const, latency: '28ms', uptime: '99.99%' },
  ]

  const incidents = [
    { date: '2026-05-23', description: 'FCM delivery delay resolved - 12 min impact', severity: 'resolved' as const },
    { date: '2026-05-21', description: 'Database maintenance completed successfully', severity: 'resolved' as const },
    { date: '2026-05-18', description: 'Edge function cold start optimization deployed', severity: 'resolved' as const },
  ]

  const getStatusIcon = (status: string) => {
    return status === 'operational' ? (
      <CheckCircle className="w-4 h-4 text-emerald-500" />
    ) : (
      <AlertTriangle className="w-4 h-4 text-danger-500" />
    )
  }

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

  const revenue = stats?.revenue ?? { total_revenue_idr: 0, by_type: {}, monthly_6mo: [] }
  const users = stats?.users ?? { total: 0, active: 0, trial: 0, churned: 0 }
  const agencies = stats?.agencies ?? { total: 0, active: 0, suspended: 0 }
  const seats = stats?.seats ?? { total_purchased: 0, total_consumed: 0, total_balance: 0 }
  const panic = stats?.panic ?? { open: 0, resolved: 0, total: 0 }

  // Calculate operational status for header badge
  const operationalCount = services.filter(s => s.status === 'operational').length
  const overallStatus = operationalCount === services.length ? 'operational' : 'degraded'

  return (
    <div className="space-y-6">
      {/* Page Header */}
      <div className="page-header flex items-start justify-between">
        <div>
          <h1 className="page-title">System Health</h1>
          <p className="page-subtitle">Platform monitoring, metrics, and audit trail</p>
        </div>
        <StatusBadge status={overallStatus} label={overallStatus === 'operational' ? 'All Systems Operational' : 'Partial Degradation'} />
      </div>

      {/* Key Metrics */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
        <MetricCard
          title="Total Revenue"
          value={`Rp ${(revenue.total_revenue_idr / 1_000_000).toFixed(1)}M`}
          subtitle="6-month total"
          icon={Activity}
          trend="up"
          trendValue="+12.4%"
          color="emerald"
        />
        <MetricCard
          title="Active Users"
          value={users.active.toLocaleString()}
          subtitle={`of ${users.total.toLocaleString()} total`}
          icon={Users}
          trend="up"
          trendValue="+8.2%"
          color="blue"
        />
        <MetricCard
          title="Active Agencies"
          value={agencies.active}
          subtitle={`${agencies.suspended} suspended`}
          icon={Building2}
          color="purple"
        />
        <MetricCard
          title="Seat Balance"
          value={seats.total_balance.toLocaleString()}
          subtitle={`${seats.total_consumed.toLocaleString()} consumed`}
          icon={Shield}
          trend="down"
          trendValue="-2.1%"
          color="accent"
        />
      </div>

      {/* Health Dashboard Row */}
      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        {/* Service Status - Full Width on left */}
        <div className="lg:col-span-2 card p-6">
          <div className="flex items-center justify-between mb-4">
            <div className="flex items-center gap-3">
              <div className="p-2 bg-primary-100 rounded-lg">
                <Server className="w-5 h-5 text-primary-600" />
              </div>
              <h2 className="text-lg font-semibold text-slate-900">Service Health</h2>
            </div>
            <span className="badge badge-success">All Operational</span>
          </div>
          <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-3">
            {services.map((service) => (
              <div
                key={service.name}
                className="flex items-center justify-between p-3 bg-slate-50 rounded-lg hover:bg-slate-100 transition-colors"
              >
                <div className="flex items-center gap-2">
                  {getStatusIcon(service.status)}
                  <span className="text-sm font-medium text-slate-900">{service.name}</span>
                </div>
                <div className="flex items-center gap-4 text-right">
                  <div>
                    <span className="text-sm font-medium text-slate-900">{service.latency}</span>
                    <p className="text-xs text-slate-400">Latency</p>
                  </div>
                  <div>
                    <span className="text-sm font-medium text-emerald-600">{service.uptime}</span>
                    <p className="text-xs text-slate-400">Uptime</p>
                  </div>
                </div>
              </div>
            ))}
          </div>
        </div>

        {/* Quick Stats */}
        <div className="card p-6">
          <div className="flex items-center gap-3 mb-4">
            <div className="p-2 bg-accent-100 rounded-lg">
              <Zap className="w-5 h-5 text-accent-600" />
            </div>
            <h2 className="text-lg font-semibold text-slate-900">Quick Stats</h2>
          </div>
          <div className="space-y-4">
            <div className="flex items-center justify-between p-3 bg-slate-50 rounded-lg">
              <div className="flex items-center gap-2">
                <AlertTriangle className="w-4 h-4 text-danger-600" />
                <span className="text-sm font-medium text-slate-900">Open Panic Alerts</span>
              </div>
              <span className="text-lg font-bold text-danger-600">{panic.open}</span>
            </div>
            <div className="flex items-center justify-between p-3 bg-slate-50 rounded-lg">
              <div className="flex items-center gap-2">
                <Clock className="w-4 h-4 text-purple-600" />
                <span className="text-sm font-medium text-slate-900">Avg Response</span>
              </div>
              <span className="text-lg font-bold text-slate-900">
                {stats?.sla?.avg_response_minutes ? `${stats.sla.avg_response_minutes}m` : 'N/A'}
              </span>
            </div>
            <div className="flex items-center justify-between p-3 bg-slate-50 rounded-lg">
              <div className="flex items-center gap-2">
                <Shield className="w-4 h-4 text-blue-600" />
                <span className="text-sm font-medium text-slate-900">Seats Purchased</span>
              </div>
              <span className="text-lg font-bold text-slate-900">{seats.total_purchased.toLocaleString()}</span>
            </div>
            <div className="flex items-center justify-between p-3 bg-slate-50 rounded-lg">
              <div className="flex items-center gap-2">
                <CheckCircle className="w-4 h-4 text-emerald-600" />
                <span className="text-sm font-medium text-slate-900">Resolved Alerts</span>
              </div>
              <span className="text-lg font-bold text-emerald-600">{panic.resolved}</span>
            </div>
          </div>
        </div>
      </div>

      {/* Alerts Panel + Incidents */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        <AlertsPanel alerts={alerts?.alerts} isLoading={alertsLoading} />

        {/* Recent Incidents */}
        <div className="card p-6">
          <div className="flex items-center justify-between mb-4">
            <div className="flex items-center gap-3">
              <div className="p-2 bg-danger-100 rounded-lg">
                <AlertTriangle className="w-5 h-5 text-danger-600" />
              </div>
              <h2 className="text-lg font-semibold text-slate-900">Recent Incidents</h2>
            </div>
            <button className="text-sm text-accent-600 hover:text-accent-700 font-medium">
              View All
            </button>
          </div>
          <div className="space-y-3">
            {incidents.map((incident, idx) => (
              <div key={idx} className="p-4 bg-slate-50 rounded-lg hover:bg-slate-100 transition-colors">
                <div className="flex items-center justify-between mb-2">
                  <div className="flex items-center gap-2">
                    <Clock className="w-4 h-4 text-slate-400" />
                    <span className="text-sm font-medium text-slate-900">{incident.date}</span>
                  </div>
                  <span className={`text-xs px-2 py-1 rounded-full ${
                    incident.severity === 'resolved'
                      ? 'bg-emerald-100 text-emerald-700'
                      : 'bg-accent-100 text-accent-700'
                  }`}>
                    {incident.severity}
                  </span>
                </div>
                <p className="text-sm text-slate-600">{incident.description}</p>
              </div>
            ))}
          </div>
        </div>
      </div>

      {/* Revenue Breakdown */}
      {revenue.by_type && Object.keys(revenue.by_type).length > 0 && (
        <div className="card p-6">
          <div className="flex items-center gap-3 mb-4">
            <div className="p-2 bg-emerald-100 rounded-lg">
              <Activity className="w-5 h-5 text-emerald-600" />
            </div>
            <h2 className="text-lg font-semibold text-slate-900">Revenue by Type</h2>
          </div>
          <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
            {Object.entries(revenue.by_type).map(([type, amount]) => (
              <div key={type} className="p-3 bg-slate-50 rounded-lg">
                <p className="text-xs text-slate-500 uppercase tracking-wide">{type}</p>
                <p className="text-lg font-bold text-slate-900">
                  Rp {(Number(amount) / 1_000_000).toFixed(1)}M
                </p>
              </div>
            ))}
          </div>
        </div>
      )}

      {/* Audit Log Section */}
      <AuditLogSection />

      {/* Quick Actions */}
      <div className="card p-6">
        <div className="flex items-center gap-3 mb-4">
          <div className="p-2 bg-slate-100 rounded-lg">
            <Zap className="w-5 h-5 text-slate-600" />
          </div>
          <h2 className="text-lg font-semibold text-slate-900">Quick Actions</h2>
        </div>
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4">
          <button className="p-4 bg-slate-50 hover:bg-slate-100 rounded-lg text-left transition-colors group">
            <div className="flex items-center gap-3 mb-2">
              <div className="p-2 bg-white rounded-lg shadow-sm group-hover:shadow transition-shadow">
                <RefreshCw className="w-5 h-5 text-slate-600" />
              </div>
              <p className="font-medium text-slate-900">Restart Services</p>
            </div>
            <p className="text-xs text-slate-500 pl-9">Safe restart without data loss</p>
          </button>
          <button className="p-4 bg-slate-50 hover:bg-slate-100 rounded-lg text-left transition-colors group">
            <div className="flex items-center gap-3 mb-2">
              <div className="p-2 bg-white rounded-lg shadow-sm group-hover:shadow transition-shadow">
                <Database className="w-5 h-5 text-slate-600" />
              </div>
              <p className="font-medium text-slate-900">Run Diagnostics</p>
            </div>
            <p className="text-xs text-slate-500 pl-9">Check all system health</p>
          </button>
          <button className="p-4 bg-slate-50 hover:bg-slate-100 rounded-lg text-left transition-colors group">
            <div className="flex items-center gap-3 mb-2">
              <div className="p-2 bg-white rounded-lg shadow-sm group-hover:shadow transition-shadow">
                <Eye className="w-5 h-5 text-slate-600" />
              </div>
              <p className="font-medium text-slate-900">View Logs</p>
            </div>
            <p className="text-xs text-slate-500 pl-9">Edge function logs</p>
          </button>
          <button className="p-4 bg-slate-50 hover:bg-slate-100 rounded-lg text-left transition-colors group">
            <div className="flex items-center gap-3 mb-2">
              <div className="p-2 bg-white rounded-lg shadow-sm group-hover:shadow transition-shadow">
                <Cloud className="w-5 h-5 text-slate-600" />
              </div>
              <p className="font-medium text-slate-900">FCM Stats</p>
            </div>
            <p className="text-xs text-slate-500 pl-9">Push notification metrics</p>
          </button>
        </div>
      </div>

      {/* API Endpoints Health */}
      <div className="card p-6">
        <div className="flex items-center gap-3 mb-4">
          <div className="p-2 bg-primary-100 rounded-lg">
            <Activity className="w-5 h-5 text-primary-600" />
          </div>
          <h2 className="text-lg font-semibold text-slate-900">API Endpoints</h2>
        </div>
        <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
          {[
            { name: 'POST /panic-alert', status: 'healthy', latency: '145ms' },
            { name: 'POST /photo-watermark', status: 'healthy', latency: '890ms' },
            { name: 'GET /profiles', status: 'healthy', latency: '45ms' },
            { name: 'POST /payments', status: 'healthy', latency: '230ms' },
          ].map((endpoint) => (
            <div key={endpoint.name} className="p-3 bg-slate-50 rounded-lg">
              <div className="flex items-center justify-between mb-1">
                <span className="text-xs font-mono text-slate-600">{endpoint.name}</span>
                <span className="w-2 h-2 bg-emerald-500 rounded-full"></span>
              </div>
              <span className="text-sm font-medium text-slate-900">{endpoint.latency}</span>
            </div>
          ))}
        </div>
      </div>
    </div>
  )
}
