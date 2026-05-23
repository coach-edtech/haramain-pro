# Tech Spec: F09 — Informasi Umrah (Content Library)

_Source: PRD v1.10-FINAL Section 3.11 (NEW)_
_Status: NEW — Added in v1.5_

---

## Overview

Content library containing Islamic educational content (video, audio, text) created by SuperAdmin. Available FREE for all users — acts as Sales Agent tool for prospect demos.

---

## Content Types

| Type | Format | Use Case |
|------|--------|----------|
| Video | MP4, HLS | Tutorial, virtual tour |
| Audio | MP3 | Doa, talbiyah, zikir |
| Text | Markdown | Articles, guides |

---

## User Flow

### Browse Content
```
User opens app → Informasi Umrah tab
       ↓
List view: thumbnail, title, type icon
       ↓
Filter: All / Video / Audio / Text
       ↓
Tap item → inline player (video/audio) or reader (text)
```

### Share Content
```
Tap share icon → WhatsApp share
       ↓
Link sent: deep-link to content
       ↓
Recipient opens → content page
```

---

## Database Schema

### `informasi_umrah`

```sql
CREATE TABLE informasi_umrah (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  title VARCHAR(255) NOT NULL,
  content_type VARCHAR(20) NOT NULL,
  -- 'video' | 'audio' | 'text'
  content_url TEXT NOT NULL,
  -- CDN URL for media, or markdown for text
  thumbnail_url TEXT,
  description TEXT,
  created_by UUID REFERENCES users(id),
  is_published BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMPTZ DEFAULT NOW()
);
```

### `informasi_umrah_views`

```sql
CREATE TABLE informasi_umrah_views (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  informasi_id UUID REFERENCES informasi_umrah(id),
  user_id UUID REFERENCES users(id),
  viewed_at TIMESTAMPTZ DEFAULT NOW()
);
```

---

## API Endpoints

### GET /informasi
List all published content.

```json
// Response
{
  "items": [
    {
      "id": "uuid",
      "title": "Doa Saat Masuk Masjidil Haram",
      "content_type": "audio",
      "thumbnail_url": "https://cdn.../thumb.jpg",
      "description": "Audiodoa dari Ustadz Hanan Attaki"
    }
  ]
}
```

### GET /informasi/{id}
Get single content item.

### POST /informasi (SuperAdmin only)
Create content.

### POST /informasi/{id}/view
Track view.

---

## CDN Strategy

- Media files hosted on CDN (e.g., Cloudflare R2, AWS CloudFront)
- Cost borne by Haramain Pro
- Free for all users (no paywall)

---

## Sales Agent Use Case

Sales Agent can use Informasi Umrah as demo content when pitching to Travel prospects:
- Show app value before purchase
- No Safety Pass required to view
- Acts as "app preview" for marketing

---

## Key Decisions

| Decision | Rationale |
|----------|-----------|
| Free for all users | Maximizes reach, supports sales pipeline |
| SuperAdmin creates content | Quality control |
| CDN cost borne by Haramain Pro | Operational cost |
| No paywall | Removes friction for prospects |

---

## Dependencies

- Supabase (auth, db)
- CDN for media hosting
- Deep-link handling for share

---

_Maintained by: Hermes (CTO)_
_Last Updated: 2026-05-02 (v1.10-FINAL)_
