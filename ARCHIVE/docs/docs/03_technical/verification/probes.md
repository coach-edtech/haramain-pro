# Probes

> Owner: OpenClaw
> Status: Starter content created
> Note: This file contains initial operational content and may be refined later by Onyx.

## Purpose
Health check endpoints and system probes.

## Probes

### Liveness Probe
- **Endpoint**: `GET /api/health`
- **Expected**: `{ "status": "ok" }`
- **Purpose**: Is the app running?

### Readiness Probe
- **Endpoint**: `GET /api/ready`
- **Expected**: `{ "status": "ready", "db": true, "auth": true }`
- **Purpose**: Is the app ready to serve traffic?

### Panic Alert Probe
- **Endpoint**: `GET /api/probe/panic`
- **Expected**: FCM test message sent to self
- **Purpose**: Is panic alert flow working?

### Payment Probe
- **Endpoint**: `POST /api/probe/payment`
- **Expected**: Midtrans Snap sandbox transaction
- **Purpose**: Is payment integration working?

## Related
- `docs/03_technical/verification/staging-checklist.md`
- `docs/03_technical/verification/production-gates.md`
