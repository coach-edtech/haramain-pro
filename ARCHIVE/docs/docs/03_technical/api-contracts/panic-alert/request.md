# Panic Alert API — Request Contracts

> Owner: OpenClaw
> Status: Starter content created
> Note: This file contains initial operational content and may be refined later by Onyx.

## Purpose
Request formats for panic alert endpoints.

---

## POST /panic/trigger

Trigger a panic alert (user-initiated).

### Request
```json
{
  "latitude": 21.4225,
  "longitude": 39.8262,
  "accuracy": 10.5,
  "altitude": 277,
  "message": "Separated from group near Masjidil Haram"
}
```

### Fields
| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `latitude` | float | Yes | GPS latitude |
| `longitude` | float | Yes | GPS longitude |
| `accuracy` | float | No | GPS accuracy in meters |
| `altitude` | float | No | Altitude in meters |
| `message` | string | No | Optional context message |

### Notes
- **Location payload** embedded in request — fetched from device GPS
- **Muthawif target resolution**: server resolves all members of same rombongan + assigned muthawif
- **Safety Pass validation**: must have active subscription (trial, b2c_lifetime, or b2b_assigned)
- **Fallback**: if FCM delivery fails within 5s, Twilio SMS triggered automatically

---

## POST /panic/acknowledge

Acknowledge a received panic alert.

### Request
```json
{
  "alert_id": "uuid"
}
```

### Fields
| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `alert_id` | uuid | Yes | ID of the alert to acknowledge |

---

## POST /panic/resolve

Mark a panic alert as resolved.

### Request
```json
{
  "alert_id": "uuid",
  "resolution": "false_alarm"
}
```

### Fields
| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `alert_id` | uuid | Yes | ID of alert |
| `resolution` | enum | Yes | "resolved" \| "false_alarm" |

## Related
- `docs/03_technical/api-contracts/panic-alert/response.md`
- `docs/03_technical/api-contracts/panic-alert/error.md`
