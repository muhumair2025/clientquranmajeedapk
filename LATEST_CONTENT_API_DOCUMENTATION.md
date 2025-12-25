# Latest Content API Documentation

## Overview

The Latest Content feature shows users the newest content added to the system. This includes:
- New Categories
- New Subcategories
- New Content/Materials (Text, Q&A, PDF, Audio, Video)
- New Ayah Audio/Video content

All items are sorted by creation date, with newest items appearing first.

---

## Required Backend Endpoint

### GET /api/latest

**Purpose:** Fetch all recently added content from across the system

**Authentication:** Required (X-API-Key header)

**Query Parameters:**
| Parameter | Type | Description |
|-----------|------|-------------|
| `types` | string | Comma-separated list of content types to filter (optional) |
| `limit` | integer | Maximum number of items to return (optional, default: 50) |
| `offset` | integer | Number of items to skip for pagination (optional, default: 0) |

**Valid Types:**
- `category` - New categories
- `subcategory` - New subcategories
- `text` - Text content
- `qa` - Question & Answer content
- `pdf` - PDF documents
- `audio` - Audio files
- `video` - Video files
- `ayah_audio` - Ayah-specific audio (from Quran XML Maker)
- `ayah_video` - Ayah-specific video (from Quran XML Maker)

---

## Response Format

```json
{
  "success": true,
  "message": "Latest content retrieved successfully",
  "total_count": 25,
  "last_updated": "2025-12-25T10:30:00Z",
  "data": [
    {
      "id": 1,
      "type": "category",
      "title": "New Category Name",
      "subtitle": null,
      "description": "Category description",
      "image_url": "https://example.com/icon.png",
      "content_url": null,
      "created_at": "2025-12-25T10:00:00Z",
      "updated_at": "2025-12-25T10:00:00Z",
      "category_id": 1,
      "category_name": "New Category Name",
      "category_color": "#10b981",
      "subcategory_id": null,
      "subcategory_name": null,
      "surah_number": null,
      "ayah_number": null,
      "surah_name": null,
      "section_type": null
    },
    {
      "id": 5,
      "type": "subcategory",
      "title": "Quran Basics",
      "subtitle": null,
      "description": "Learn the fundamentals",
      "image_url": null,
      "content_url": null,
      "created_at": "2025-12-24T15:30:00Z",
      "updated_at": null,
      "category_id": 1,
      "category_name": "Islamic Studies",
      "category_color": "#10b981",
      "subcategory_id": 5,
      "subcategory_name": "Quran Basics",
      "surah_number": null,
      "ayah_number": null,
      "surah_name": null,
      "section_type": null
    },
    {
      "id": 10,
      "type": "text",
      "title": "Introduction to Tafseer",
      "subtitle": "Understanding Quran",
      "description": "A comprehensive guide...",
      "image_url": null,
      "content_url": null,
      "created_at": "2025-12-24T12:00:00Z",
      "updated_at": null,
      "category_id": 1,
      "category_name": "Islamic Studies",
      "category_color": "#10b981",
      "subcategory_id": 5,
      "subcategory_name": "Quran Basics",
      "surah_number": null,
      "ayah_number": null,
      "surah_name": null,
      "section_type": null
    },
    {
      "id": 15,
      "type": "audio",
      "title": "Surah Al-Fatiha Recitation",
      "subtitle": "Beautiful recitation",
      "description": null,
      "image_url": null,
      "content_url": "https://example.com/audio/fatiha.mp3",
      "created_at": "2025-12-23T18:00:00Z",
      "updated_at": null,
      "category_id": 2,
      "category_name": "Quran",
      "category_color": "#6366f1",
      "subcategory_id": 10,
      "subcategory_name": "Recitations",
      "surah_number": null,
      "ayah_number": null,
      "surah_name": null,
      "section_type": null
    },
    {
      "id": 20,
      "type": "ayah_audio",
      "title": "Al-Fatiha Verse 1 - Vocabulary",
      "subtitle": "د آیه لغات",
      "description": "Word meanings for verse 1",
      "image_url": null,
      "content_url": "https://example.com/audio/lughat_1_1.mp3",
      "created_at": "2025-12-22T09:00:00Z",
      "updated_at": null,
      "category_id": null,
      "category_name": null,
      "category_color": null,
      "subcategory_id": null,
      "subcategory_name": null,
      "surah_number": 1,
      "ayah_number": 1,
      "surah_name": "الفاتحه",
      "section_type": "lughat"
    }
  ]
}
```

---

## Field Descriptions

| Field | Type | Description |
|-------|------|-------------|
| `id` | integer | Unique identifier for the item |
| `type` | string | Content type (category, subcategory, text, qa, pdf, audio, video, ayah_audio, ayah_video) |
| `title` | string | Display title |
| `subtitle` | string? | Optional subtitle/secondary title |
| `description` | string? | Optional description text |
| `image_url` | string? | URL to image/icon (if applicable) |
| `content_url` | string? | URL to content file (for audio/video/pdf) |
| `created_at` | datetime | When the item was created (ISO 8601 format) |
| `updated_at` | datetime? | When the item was last updated (optional) |
| `category_id` | integer? | Parent category ID (for navigation) |
| `category_name` | string? | Parent category name |
| `category_color` | string? | Category color (hex format like #10b981) |
| `subcategory_id` | integer? | Parent subcategory ID (for navigation) |
| `subcategory_name` | string? | Parent subcategory name |
| `surah_number` | integer? | Surah number (for ayah content, 1-114) |
| `ayah_number` | integer? | Ayah number (for ayah content) |
| `surah_name` | string? | Surah name in Arabic (for ayah content) |
| `section_type` | string? | Section type for ayah content (lughat, tafseer, faidi) |

---

## Backend Implementation Notes

### Database Query (Pseudo-code)

```sql
-- Combine latest items from multiple tables
SELECT 
    'category' as type,
    id,
    names->>'english' as title,
    description,
    icon_url as image_url,
    NULL as content_url,
    created_at,
    updated_at,
    id as category_id,
    names->>'english' as category_name,
    color as category_color,
    NULL as subcategory_id,
    NULL as subcategory_name,
    NULL as surah_number,
    NULL as ayah_number,
    NULL as surah_name,
    NULL as section_type
FROM categories
WHERE is_active = true

UNION ALL

SELECT 
    'subcategory' as type,
    s.id,
    s.name as title,
    s.description,
    NULL as image_url,
    NULL as content_url,
    s.created_at,
    s.updated_at,
    c.id as category_id,
    c.names->>'english' as category_name,
    c.color as category_color,
    s.id as subcategory_id,
    s.name as subcategory_name,
    NULL as surah_number,
    NULL as ayah_number,
    NULL as surah_name,
    NULL as section_type
FROM subcategories s
JOIN categories c ON s.category_id = c.id
WHERE s.is_active = true

UNION ALL

SELECT 
    content.type as type,
    content.id,
    content.title,
    content.text_content as description,
    NULL as image_url,
    COALESCE(content.audio_url, content.video_url, content.pdf_url) as content_url,
    content.created_at,
    content.updated_at,
    c.id as category_id,
    c.names->>'english' as category_name,
    c.color as category_color,
    s.id as subcategory_id,
    s.name as subcategory_name,
    NULL as surah_number,
    NULL as ayah_number,
    NULL as surah_name,
    NULL as section_type
FROM contents content
JOIN subcategories s ON content.subcategory_id = s.id
JOIN categories c ON s.category_id = c.id
WHERE content.is_active = true

ORDER BY created_at DESC
LIMIT 50;
```

### Laravel Controller Example

```php
public function getLatest(Request $request)
{
    $types = $request->get('types') ? explode(',', $request->get('types')) : null;
    $limit = $request->get('limit', 50);
    $offset = $request->get('offset', 0);

    $items = [];
    
    // Get latest categories
    if (!$types || in_array('category', $types)) {
        $categories = Category::where('is_active', true)
            ->orderBy('created_at', 'desc')
            ->take($limit)
            ->get()
            ->map(fn($c) => [
                'id' => $c->id,
                'type' => 'category',
                'title' => $c->names['english'],
                'description' => $c->description,
                'image_url' => $c->icon_url,
                'created_at' => $c->created_at->toIso8601String(),
                'category_id' => $c->id,
                'category_name' => $c->names['english'],
                'category_color' => $c->color,
                // ... other fields as null
            ]);
        $items = array_merge($items, $categories->toArray());
    }
    
    // Get latest subcategories
    if (!$types || in_array('subcategory', $types)) {
        // Similar logic...
    }
    
    // Get latest content (text, qa, pdf, audio, video)
    // Similar logic for each type...
    
    // Sort by created_at descending
    usort($items, fn($a, $b) => strtotime($b['created_at']) - strtotime($a['created_at']));
    
    // Apply pagination
    $items = array_slice($items, $offset, $limit);
    
    return response()->json([
        'success' => true,
        'message' => 'Latest content retrieved successfully',
        'total_count' => count($items),
        'last_updated' => now()->toIso8601String(),
        'data' => $items
    ]);
}
```

---

## Flutter Integration

The Flutter app already implements:

1. **Model:** `lib/models/latest_content_models.dart`
   - `LatestItem` class with all fields
   - `LatestContentType` enum with icons and colors
   - `LatestContentFilter` for filtering
   - `LatestContentResponse` for API response parsing

2. **Service:** `lib/services/content_api_service.dart`
   - `getLatestContent()` method with caching
   - `refreshLatestContent()` for pull-to-refresh
   - Background cache updates

3. **Screen:** `lib/screens/latest_content_screen.dart`
   - Filter chips for content types
   - Compact list view with type indicators
   - NEW badge for items added within 24 hours
   - Time ago display
   - Breadcrumb navigation path
   - Localization support (EN, PS, UR, AR)

---

## UI Features

- ✅ Filter by content type
- ✅ NEW badge for recent items (< 24 hours)
- ✅ Time ago display (e.g., "2 hours ago")
- ✅ Breadcrumb path (Category › Subcategory)
- ✅ Color-coded type icons
- ✅ Pull-to-refresh
- ✅ Offline caching
- ✅ RTL support
- ✅ Dark mode support
- ✅ Multi-language support

---

## Content Type Colors

| Type | Color | Icon |
|------|-------|------|
| Category | Green (#10B981) | category |
| Subcategory | Indigo (#6366F1) | folder |
| Text | Blue (#3B82F6) | article |
| Q&A | Green (#22C55E) | question_answer |
| PDF | Red (#EF4444) | picture_as_pdf |
| Audio | Orange (#F97316) | audiotrack |
| Video | Purple (#8B5CF6) | video_library |
| Ayah Audio | Pink (#EC4899) | headphones |
| Ayah Video | Teal (#14B8A6) | ondemand_video |

---

## Testing

### Test Endpoint with cURL

```bash
# Get all latest content
curl -H "X-API-Key: YOUR_API_KEY" \
     https://yourdomain.com/api/latest

# Filter by type
curl -H "X-API-Key: YOUR_API_KEY" \
     "https://yourdomain.com/api/latest?types=audio,video"

# With pagination
curl -H "X-API-Key: YOUR_API_KEY" \
     "https://yourdomain.com/api/latest?limit=20&offset=0"
```

---

**Version:** 1.0  
**Date:** December 25, 2025  
**Status:** Flutter Implementation Complete ✅  
**Backend Status:** Pending Implementation ⏳

