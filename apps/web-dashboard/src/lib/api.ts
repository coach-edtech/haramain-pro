// API client for Haramain Pro Dashboard Edge Functions
// React Query hooks for all v1.12 dashboard features

import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { supabase } from './supabase';

// ============================================================
// Auth helper
// ============================================================
async function getAuthHeaders(): Promise<Record<string, string>> {
  const { data: { session } } = await supabase.auth.getSession();
  const token = session?.access_token;
  if (!token) throw new Error('Not authenticated');
  return {
    'Authorization': `Bearer ${token}`,
    'Content-Type': 'application/json',
  };
}

async function fetchAPI<T>(endpoint: string, params?: Record<string, string>): Promise<T> {
  const headers = await getAuthHeaders();
  let url = `/functions/v1/${endpoint}`;
  if (params) {
    const searchParams = new URLSearchParams(params);
    url += `?${searchParams.toString()}`;
  }
  const res = await fetch(url, { headers });
  if (!res.ok) {
    const err = await res.json().catch(() => ({ error: 'Request failed' }));
    throw new Error(err.error || `HTTP ${res.status}`);
  }
  return res.json();
}

async function postAPI<T>(endpoint: string, body: unknown): Promise<T> {
  const headers = await getAuthHeaders();
  const res = await fetch(`/functions/v1/${endpoint}`, {
    method: 'POST',
    headers,
    body: JSON.stringify(body),
  });
  if (!res.ok) {
    const err = await res.json().catch(() => ({ error: 'Request failed' }));
    throw new Error(err.error || `HTTP ${res.status}`);
  }
  return res.json();
}

async function patchAPI<T>(endpoint: string, body: unknown, queryParams?: Record<string, string>): Promise<T> {
  const headers = await getAuthHeaders();
  let url = `/functions/v1/${endpoint}`;
  if (queryParams) {
    const searchParams = new URLSearchParams(queryParams);
    url += `?${searchParams.toString()}`;
  }
  const res = await fetch(url, {
    method: 'PATCH',
    headers,
    body: JSON.stringify(body),
  });
  if (!res.ok) {
    const err = await res.json().catch(() => ({ error: 'Request failed' }));
    throw new Error(err.error || `HTTP ${res.status}`);
  }
  return res.json();
}

// ============================================================
// Types
// ============================================================
export interface SeatLicenseBalance {
  agency_id: string;
  agency_name: string;
  seat_balance: number;
  total_purchased: number;
  total_consumed: number;
  total_refunded: number;
  wl_status: string;
  alert: { threshold: number; is_active: boolean; triggered: boolean } | null;
  recent_transactions: Array<{
    id: string;
    type: string;
    quantity: number;
    balance_after: number;
    created_at: string;
  }>;
}

export interface RedeemCode {
  id: string;
  code: string;
  type: string;
  status: string;
  expires_at: string | null;
  used_at: string | null;
  used_by_user_id: string | null;
  created_at: string;
}

export interface PilgrimLifecycle {
  id: string;
  user_id: string;
  stage: 'prospect' | 'booked' | 'active' | 'alumni' | 'churned';
  stage_changed_at: string;
  booking_date: string | null;
  departure_date: string | null;
  return_date: string | null;
  notes: string | null;
  pilgrim?: { id: string; name: string; email: string; subscription_tier: string } | null;
}

export interface SystemStats {
  revenue: {
    total_revenue_idr: number;
    by_type: Record<string, number>;
    monthly_6mo: Array<{ month: string; amount: number }>;
  };
  users: { total: number; active: number; trial: number; churned: number };
  agencies: { total: number; active: number; suspended: number };
  seats: { total_purchased: number; total_consumed: number; total_balance: number };
  panic: { open: number; resolved: number; total: number };
  sla: { avg_response_minutes: number | null; open_alert_count: number };
}

export interface BillingInvoice {
  id: string;
  invoice_number: string;
  agency_id: string;
  agency_name?: string;
  agency_email?: string;
  billing_period_start: string;
  billing_period_end: string;
  active_pax_count: number;
  price_per_seat: number;
  subtotal: number;
  adjustments: number;
  total_due: number;
  status: string;
  due_date: string;
  paid_at: string | null;
  pdf_url: string | null;
  created_at: string;
}

// ============================================================
// Hooks: Seat Licenses
// ============================================================
export function useSeatLicenseBalance(agencyId?: string) {
  return useQuery({
    queryKey: ['seat-license-balance', agencyId],
    queryFn: () => fetchAPI<SeatLicenseBalance>(
      'seat-license-balance',
      agencyId ? { agency_id: agencyId } : undefined
    ),
    enabled: !!agencyId,
  });
}

export function useAdminSeatLicenses(filter?: string, search?: string) {
  return useQuery({
    queryKey: ['admin-seat-licenses', filter, search],
    queryFn: () => {
      const params: Record<string, string> = {};
      if (filter) params.filter = filter;
      if (search) params.search = search;
      return fetchAPI<{
        stats: { total_seats_sold: number; total_used: number; total_balance: number; low_stock_count: number; depleted_count: number };
        licenses: Array<{
          id: string; agency_name: string; total_seats: number; used_seats: number;
          balance: number; wl_status: string; last_purchase: string | null; status: string;
        }>;
      }>('admin-seat-licenses', Object.keys(params).length > 0 ? params : undefined);
    },
  });
}

export function useSeatLicenseCheckout() {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: (packageId: string) =>
      postAPI<{
        success: boolean;
        xendit_checkout_url: string;
        package_id: string;
        payment_id: string;
      }>('seat-license-checkout', { package_id: packageId }),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['seat-license-balance'] });
    },
  });
}

export function useRedeemCodes(agencyId?: string, status?: string) {
  return useQuery({
    queryKey: ['redeem-codes', agencyId, status],
    queryFn: () => {
      const params: Record<string, string> = {};
      if (agencyId) params.agency_id = agencyId;
      if (status) params.status = status;
      return fetchAPI<{ codes: RedeemCode[]; count: number }>(
        'redeem-codes',
        Object.keys(params).length > 0 ? params : undefined
      );
    },
    initialPageParam: undefined as void,
  });
}

export function useGenerateRedeemCodes() {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: (payload: { agency_id?: string; quantity: number; type: string; expires_at?: string }) =>
      postAPI<{ success: boolean; codes: RedeemCode[]; count: number }>('redeem-codes', payload),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['redeem-codes'] });
    },
  });
}

// ============================================================
// Hooks: CRM Lifecycle
// ============================================================
export function useCRMLifecycle(agencyId?: string, stage?: string) {
  return useQuery({
    queryKey: ['crm-lifecycle', agencyId, stage],
    queryFn: () => {
      const params: Record<string, string> = {};
      if (agencyId) params.agency_id = agencyId;
      if (stage) params.stage = stage;
      return fetchAPI<{
        stages: string[];
        counts: Record<string, number>;
        conversion_funnel: Array<{ stage: string; count: number; rate: number }>;
        pilgrims: PilgrimLifecycle[];
      }>('crm-lifecycle', Object.keys(params).length > 0 ? params : undefined);
    },
  });
}

export function useCRMLifecycleDetail(userId: string) {
  return useQuery({
    queryKey: ['crm-lifecycle-detail', userId],
    queryFn: () => fetchAPI<{
      pilgrim_detail: any;
      lifecycle: PilgrimLifecycle | null;
      communications: any[];
    }>('crm-lifecycle', { user_id: userId }),
    enabled: !!userId,
  });
}

export function useUpdatePilgrimStage() {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: (payload: { user_id: string; stage: string; notes?: string }) =>
      patchAPI<{ success: boolean; stage: string }>('crm-lifecycle', payload),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['crm-lifecycle'] });
    },
  });
}

// ============================================================
// Hooks: Billing
// ============================================================
export function useBillingInvoices(agencyId?: string, status?: string) {
  return useQuery({
    queryKey: ['billing-invoices', agencyId, status],
    queryFn: () => {
      const params: Record<string, string> = {};
      if (agencyId) params.agency_id = agencyId;
      if (status) params.status = status;
      return fetchAPI<{ invoices: BillingInvoice[]; count: number }>(
        'billing-invoices',
        Object.keys(params).length > 0 ? params : undefined
      );
    },
  });
}

export function useGenerateInvoice() {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: (payload: {
      agency_id: string;
      period_start: string;
      period_end: string;
      price_per_seat?: number;
    }) => postAPI<{ success: boolean; invoice: BillingInvoice }>('billing-invoices', payload),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['billing-invoices'] });
    },
  });
}

export function useUpdateInvoiceStatus() {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: (payload: { id: string; status: string; payment_method?: string; payment_proof_url?: string }) =>
      patchAPI<{ success: boolean }>('billing-invoices', payload, { id: payload.id }),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['billing-invoices'] });
    },
  });
}

export function useBillingInvoicesByDate(agencyId?: string, status?: string, dateFrom?: string, dateTo?: string) {
  return useQuery({
    queryKey: ['billing-invoices', agencyId, status, dateFrom, dateTo],
    queryFn: () => {
      const params: Record<string, string> = {};
      if (agencyId) params.agency_id = agencyId;
      if (status) params.status = status;
      if (dateFrom) params.date_from = dateFrom;
      if (dateTo) params.date_to = dateTo;
      return fetchAPI<{ invoices: BillingInvoice[]; count: number }>(
        'billing-invoices',
        Object.keys(params).length > 0 ? params : undefined
      );
    },
  });
}

export function useSendInvoiceEmail() {
  return useMutation({
    mutationFn: (payload: { invoice_id: string; recipient_email?: string }) =>
      postAPI<{ success: boolean }>('billing-invoices/send-email', payload),
  });
}

export function useResendInvoiceEmail() {
  return useMutation({
    mutationFn: (payload: { invoice_id: string; recipient_email: string }) =>
      postAPI<{ success: boolean }>('billing-invoices/resend-email', payload),
  });
}

// ============================================================
// Hooks: Admin
// ============================================================
export function useAdminSystemStats() {
  return useQuery({
    queryKey: ['admin-system-stats'],
    queryFn: () => fetchAPI<SystemStats>('admin-system-stats'),
  });
}

export function useLowStockAlerts(agencyId?: string, status?: string) {
  return useQuery({
    queryKey: ['low-stock-alerts', agencyId, status],
    queryFn: () => {
      const params: Record<string, string> = {};
      if (agencyId) params.agency_id = agencyId;
      if (status) params.status = status;
      return fetchAPI<{
        alerts: Array<{
          id: string; threshold: number; current_balance: number;
          status: string; triggered_at: string;
          acknowledged_at: string | null; acknowledged_by: string | null;
        }>;
        count: number;
      }>('low-stock-alert', Object.keys(params).length > 0 ? params : undefined);
    },
  });
}

export function useAcknowledgeAlert() {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: (payload: { id: string; status: 'acknowledged' | 'dismissed' }) =>
      patchAPI<{ success: boolean }>('low-stock-alert', payload, { id: payload.id }),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['low-stock-alerts'] });
    },
  });
}

// ============================================================
// Hooks: Agency & Team
// ============================================================
export function useAgencies(search?: string, wlStatus?: string) {
  return useQuery({
    queryKey: ['agencies', search, wlStatus],
    queryFn: () => {
      const params: Record<string, string> = {};
      if (search) params.search = search;
      if (wlStatus) params.wl_status = wlStatus;
      return fetchAPI<{
        agencies: Array<{
          id: string; name: string; address: string | null;
          phone: string | null; wl_status: string;
          seat_balance: number; created_at: string;
        }>;
        count: number;
      }>('travel-agency-crud', Object.keys(params).length > 0 ? params : undefined);
    },
  });
}

export function useTeamMembers(agencyId?: string) {
  return useQuery({
    queryKey: ['team-members', agencyId],
    queryFn: () => {
      const params: Record<string, string> = {};
      if (agencyId) params.agency_id = agencyId;
      return fetchAPI<{
        members: Array<{
          id: string; name: string; email: string;
          role: string; wl_status: string; created_at: string;
        }>;
        count: number;
      }>('team-agent-management', Object.keys(params).length > 0 ? params : undefined);
    },
  });
}

export function useInviteAgent() {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: (payload: { email: string; name: string; role?: string; invite_code?: string }) =>
      postAPI<{ success: boolean; profile: any }>('team-agent-management', payload),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['team-members'] });
    },
  });
}

export function useUpdateAgent() {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: (payload: { id: string; role?: string; wl_status?: string; name?: string }) =>
      patchAPI<{ success: boolean }>('team-agent-management', payload, { id: payload.id }),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['team-members'] });
    },
  });
}

// ============================================================
// Hooks: Rombongan (Groups)
// ============================================================
export function useRombongans(agencyId?: string) {
  return useQuery({
    queryKey: ['rombongans', agencyId],
    queryFn: () => {
      const params: Record<string, string> = {};
      if (agencyId) params.agency_id = agencyId;
      return fetchAPI<{
        rombongans: Array<{
          id: string; name: string; start_date: string; end_date: string;
          status: string; muthawif_id: string | null; muthawif_name: string | null;
          created_at: string;
        }>;
        count: number;
      }>('rombongan-list', Object.keys(params).length > 0 ? params : undefined);
    },
  });
}

export function useAssignMuthawif() {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: (payload: { romongan_id: string; muthawif_id: string }) =>
      patchAPI<{ success: boolean }>('rombongan-assign-muthawif', payload, { romongan_id: payload.romongan_id }),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['rombongans'] });
    },
  });
}

// ============================================================
// Albums
// ============================================================
export interface TravelAlbum {
  id: string;
  agency_id: string;
  title: string;
  description: string | null;
  cover_url: string | null;
  photo_count: number;
  created_at: string;
}

export interface AlbumPhoto {
  id: string;
  album_id: string;
  url: string;
  caption: string | null;
  created_at: string;
}

export function useAlbums(agencyId?: string) {
  return useQuery({
    queryKey: ['albums', agencyId],
    queryFn: () => {
      const params: Record<string, string> = {};
      if (agencyId) params.agency_id = agencyId;
      return fetchAPI<{ albums: TravelAlbum[]; count: number }>(
        'travel-albums',
        Object.keys(params).length > 0 ? params : undefined
      );
    },
  });
}

export function useAlbumPhotos(albumId: string) {
  return useQuery({
    queryKey: ['album-photos', albumId],
    queryFn: () => fetchAPI<{ photos: AlbumPhoto[]; count: number }>('travel-albums', { album_id: albumId }),
    enabled: !!albumId,
  });
}

export function useCreateAlbum() {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: (payload: { agency_id: string; title: string; description?: string; cover_url?: string }) =>
      postAPI<{ success: boolean; album: TravelAlbum }>('travel-albums', payload),
    onSuccess: (_, vars) => {
      queryClient.invalidateQueries({ queryKey: ['albums', vars.agency_id] });
    },
  });
}

export function useUpdateAlbum() {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: (payload: { id: string; title?: string; description?: string; cover_url?: string; agency_id: string }) =>
      patchAPI<{ success: boolean }>('travel-albums', payload, { id: payload.id }),
    onSuccess: (_, vars) => {
      queryClient.invalidateQueries({ queryKey: ['albums', vars.agency_id] });
    },
  });
}

export function useDeleteAlbum() {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: (payload: { id: string; agency_id: string }) =>
      postAPI<{ success: boolean }>('travel-albums-delete', { id: payload.id }),
    onSuccess: (_, vars) => {
      queryClient.invalidateQueries({ queryKey: ['albums', vars.agency_id] });
    },
  });
}

export function useAddAlbumPhoto() {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: (payload: { album_id: string; url: string; caption?: string }) =>
      postAPI<{ success: boolean; photo: AlbumPhoto }>('travel-albums', { ...payload, _action: 'add_photo' }),
    onSuccess: (_, vars) => {
      queryClient.invalidateQueries({ queryKey: ['album-photos', vars.album_id] });
    },
  });
}

export function useDeleteAlbumPhoto() {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: (payload: { photo_id: string; album_id: string }) =>
      postAPI<{ success: boolean }>('travel-albums-delete', { ...payload, _action: 'delete_photo' }),
    onSuccess: (_, vars) => {
      queryClient.invalidateQueries({ queryKey: ['album-photos', vars.album_id] });
    },
  });
}

// ============================================================
// Reviews
// ============================================================
export interface AlumniReview {
  id: string;
  user_id: string;
  agency_id: string;
  rating: number;
  review_text: string | null;
  is_published: boolean;
  admin_response: string | null;
  created_at: string;
  pilgrim?: { name: string; email: string } | null;
}

export function useReviews(agencyId?: string, publishedOnly = false) {
  return useQuery({
    queryKey: ['reviews', agencyId, publishedOnly],
    queryFn: () => {
      const params: Record<string, string> = {};
      if (agencyId) params.agency_id = agencyId;
      if (publishedOnly) params.published_only = 'true';
      return fetchAPI<{ reviews: AlumniReview[]; count: number }>(
        'alumni-reviews',
        Object.keys(params).length > 0 ? params : undefined
      );
    },
  });
}

export function useCreateReview() {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: (payload: { agency_id: string; user_id: string; rating: number; review_text: string; is_published?: boolean }) =>
      postAPI<{ success: boolean; review: AlumniReview }>('alumni-reviews', payload),
    onSuccess: (_, vars) => {
      queryClient.invalidateQueries({ queryKey: ['reviews', vars.agency_id] });
    },
  });
}

export function useUpdateReview() {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: (payload: { id: string; rating?: number; review_text?: string; is_published?: boolean; admin_response?: string; agency_id: string }) =>
      patchAPI<{ success: boolean }>('alumni-reviews', payload, { id: payload.id }),
    onSuccess: (_, vars) => {
      queryClient.invalidateQueries({ queryKey: ['reviews', vars.agency_id] });
    },
  });
}

export function useDeleteReview() {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: (payload: { id: string; agency_id: string }) =>
      postAPI<{ success: boolean }>('alumni-reviews-delete', { id: payload.id }),
    onSuccess: (_, vars) => {
      queryClient.invalidateQueries({ queryKey: ['reviews', vars.agency_id] });
    },
  });
}
