# Content API Endpoints - Quick Reference

## 🔐 Authentication
**All requests require API Key authentication**

**Header Required:**
```
X-API-Key: de9cc0578682fe54e2b7fc4702947a5080b57ce69bb002f45f18f688d283e4a4
```

---

## 📍 Base URL
```
Development: http://localhost:8000/api
Production:  https://yourdomain.com/api
```

---

## 🎯 Available Endpoints

### 1. Get All Categories
**Purpose:** Fetch all active categories for homepage display

**Endpoint:** `GET /api/categories`

**Response:**
```json
{
  "success": true,
  "message": "Categories retrieved successfully",
  "data": [
    {
      "id": 1,
      "names": {
        "english": "Islamic Studies",
        "urdu": "اسلامی تعلیمات",
        "arabic": "الدراسات الإسلامية",
        "pashto": "اسلامي زده کړې"
      },
      "description": "Learn about Islamic teachings",
      "icon_url": "https://yourdomain.com/storage/icons/islamic.png",
      "color": "#10b981",
      "subcategories_count": 5
    }
  ]
}
```

**Use Case:** Display main category cards on app homepage

---

### 2. Get Single Category with Subcategories
**Purpose:** Fetch a specific category with all its subcategories

**Endpoint:** `GET /api/categories/{id}`

**Parameters:**
- `{id}` - Category ID (integer)

**Example:** `/api/categories/1`

**Response:**
```json
{
  "success": true,
  "message": "Category retrieved successfully",
  "data": {
    "id": 1,
    "names": {
      "english": "Islamic Studies",
      "urdu": "اسلامی تعلیمات",
      "arabic": "الدراسات الإسلامية",
      "pashto": "اسلامي زده کړې"
    },
    "description": "Learn about Islamic teachings",
    "icon_url": "https://yourdomain.com/storage/icons/islamic.png",
    "color": "#10b981",
    "subcategories": [
      {
        "id": 1,
        "name": "Quran",
        "description": "About Holy Quran",
        "contents_count": 10
      },
      {
        "id": 2,
        "name": "Hadith",
        "description": "Prophetic traditions",
        "contents_count": 15
      }
    ]
  }
}
```

**Use Case:** Display subcategories when user taps a category

---

### 3. Get Subcategory with Materials
**Purpose:** Fetch a subcategory with all its content/materials

**Endpoint:** `GET /api/subcategories/{id}`

**Parameters:**
- `{id}` - Subcategory ID (integer)

**Example:** `/api/subcategories/1`

**Response:**
```json
{
  "success": true,
  "message": "Subcategory retrieved successfully",
  "data": {
    "id": 1,
    "name": "Quran",
    "description": "About Holy Quran",
    "category": {
      "id": 1,
      "names": {
        "english": "Islamic Studies",
        "urdu": "اسلامی تعلیمات",
        "arabic": "الدراسات الإسلامية",
        "pashto": "اسلامي زده کړې"
      },
      "icon_url": "https://yourdomain.com/storage/icons/islamic.png",
      "color": "#10b981"
    },
    "contents": [
      {
        "id": 1,
        "type": "text",
        "title": "Introduction to Quran",
        "text_content": "The Quran is the holy book..."
      },
      {
        "id": 2,
        "type": "qa",
        "title": "What is Quran?",
        "question": "What is the Quran?",
        "answer": "The Quran is the word of Allah..."
      },
      {
        "id": 3,
        "type": "pdf",
        "title": "Quran Study Guide",
        "pdf_url": "https://f000.backblazeb2.com/file/bucket/guide.pdf"
      }
    ]
  }
}
```

**Use Case:** Display all content/materials in a subcategory

---

### 4. Get Single Content/Material
**Purpose:** Fetch detailed information about a specific content item

**Endpoint:** `GET /api/contents/{id}`

**Parameters:**
- `{id}` - Content ID (integer)

**Example:** `/api/contents/1`

**Response (Text Type):**
```json
{
  "success": true,
  "message": "Content retrieved successfully",
  "data": {
    "id": 1,
    "type": "text",
    "title": "Introduction to Quran",
    "text_content": "Full text content here...",
    "subcategory": {
      "id": 1,
      "name": "Quran"
    },
    "category": {
      "id": 1,
      "names": {
        "english": "Islamic Studies",
        "urdu": "اسلامی تعلیمات",
        "arabic": "الدراسات الإسلامية",
        "pashto": "اسلامي زده کړې"
      },
      "icon_url": "https://yourdomain.com/storage/icons/islamic.png",
      "color": "#10b981"
    }
  }
}
```

**Response (Q&A Type):**
```json
{
  "data": {
    "id": 2,
    "type": "qa",
    "title": "What is Quran?",
    "question": "What is the Quran?",
    "answer": "The Quran is the holy book...",
    "subcategory": { ... },
    "category": { ... }
  }
}
```

**Response (PDF Type):**
```json
{
  "data": {
    "id": 3,
    "type": "pdf",
    "title": "Study Guide",
    "pdf_url": "https://f000.backblazeb2.com/file/bucket/guide.pdf",
    "subcategory": { ... },
    "category": { ... }
  }
}
```

**Use Case:** Display full content details

---

### 5. Search Content
**Purpose:** Search across all content/materials

**Endpoint:** `GET /api/search?q={query}`

**Query Parameters:**
- `q` - Search query (string, required)

**Example:** `/api/search?q=quran`

**Response:**
```json
{
  "success": true,
  "message": "Search completed successfully",
  "query": "quran",
  "results_count": 3,
  "data": [
    {
      "id": 1,
      "type": "text",
      "title": "Introduction to Quran",
      "preview": "The Quran is the holy book of Islam...",
      "subcategory": {
        "id": 1,
        "name": "Quran"
      },
      "category": {
        "id": 1,
        "names": {
          "english": "Islamic Studies",
          "urdu": "اسلامی تعلیمات",
          "arabic": "الدراسات الإسلامية",
          "pashto": "اسلامي زده کړې"
        },
        "icon_url": "https://yourdomain.com/storage/icons/islamic.png",
        "color": "#10b981"
      }
    }
  ]
}
```

**Use Case:** Search functionality in the app

---

## 📊 Content Types

### 1. Text Content (`type: "text"`)
**Fields:**
- `id` - Content ID
- `type` - "text"
- `title` - Content title
- `text_content` - Full text content

**Best For:** Articles, lessons, explanations

---

### 2. Q&A Content (`type: "qa"`)
**Fields:**
- `id` - Content ID
- `type` - "qa"
- `title` - Content title
- `question` - The question
- `answer` - The answer

**Best For:** FAQs, knowledge base items

---

### 3. PDF Content (`type: "pdf"`)
**Fields:**
- `id` - Content ID
- `type` - "pdf"
- `title` - Content title
- `pdf_url` - External PDF URL (Backblaze B2, CDN)

**Best For:** Books, guides, downloadable documents

**Note:** PDFs are NOT uploaded to the server - external URLs are used

---

## ⚠️ Error Responses

### 401 Unauthorized
**Cause:** Invalid or missing API key

```json
{
  "success": false,
  "message": "Unauthorized. Invalid or missing API key."
}
```

**Solution:** Check API key in request header

---

### 404 Not Found
**Cause:** Resource doesn't exist

```json
{
  "success": false,
  "message": "Category not found"
}
```

**Solution:** Verify the ID is correct

---

### 400 Bad Request
**Cause:** Invalid request (e.g., empty search query)

```json
{
  "success": false,
  "message": "Search query is required"
}
```

**Solution:** Check request parameters

---

## 🔄 User Flow Example

```
1. App Opens
   ↓
   GET /api/categories
   ↓
   Display category cards

2. User taps "Islamic Studies"
   ↓
   GET /api/categories/1
   ↓
   Display subcategories (Quran, Hadith, etc.)

3. User taps "Quran"
   ↓
   GET /api/subcategories/1
   ↓
   Display materials/contents list

4. User taps "Introduction to Quran"
   ↓
   GET /api/contents/1
   ↓
   Display full content
```

---

## 🌍 Multilingual Support

All categories include names in 4 languages:

```json
"names": {
  "english": "Islamic Studies",
  "urdu": "اسلامی تعلیمات",
  "arabic": "الدراسات الإسلامية",
  "pashto": "اسلامي زده کړې"
}
```

**Implementation:**
```javascript
// JavaScript
const displayName = category.names[userLanguage];

// Flutter/Dart
final displayName = category.names[userLanguage];

// Swift
let displayName = category.names[userLanguage]
```

---

## 📱 Testing Endpoints

### Using cURL
```bash
# Get all categories
curl -H "X-API-Key: de9cc0578682fe54e2b7fc4702947a5080b57ce69bb002f45f18f688d283e4a4" \
     https://yourdomain.com/api/categories

# Get category with subcategories
curl -H "X-API-Key: de9cc0578682fe54e2b7fc4702947a5080b57ce69bb002f45f18f688d283e4a4" \
     https://yourdomain.com/api/categories/1

# Search
curl -H "X-API-Key: de9cc0578682fe54e2b7fc4702947a5080b57ce69bb002f45f18f688d283e4a4" \
     "https://yourdomain.com/api/search?q=quran"
```

### Using Postman
1. Create new request
2. Set method to GET
3. Add header: `X-API-Key` with value
4. Enter endpoint URL
5. Send request

---

## 📋 Summary Table

| Endpoint | Method | Purpose | Authentication |
|----------|--------|---------|----------------|
| `/api/categories` | GET | Get all categories | Required |
| `/api/categories/{id}` | GET | Get category + subcategories | Required |
| `/api/subcategories/{id}` | GET | Get subcategory + materials | Required |
| `/api/contents/{id}` | GET | Get single content | Required |
| `/api/search?q={query}` | GET | Search content | Required |

---

## ✅ Implementation Checklist

- [ ] Store API key securely (environment variables)
- [ ] Add `X-API-Key` header to all requests
- [ ] Handle 401 (unauthorized) errors
- [ ] Handle 404 (not found) errors
- [ ] Implement loading states
- [ ] Add error messages
- [ ] Implement retry logic
- [ ] Support offline mode (cache data)
- [ ] Add pull-to-refresh
- [ ] Test with slow network
- [ ] Implement multilingual support
- [ ] Handle RTL languages (Urdu, Arabic, Pashto)

---

## 📖 Documentation Files

1. **FLUTTER_API_DOCUMENTATION.md** - Complete Flutter implementation guide
2. **DEVELOPER_GUIDE.md** - General developer guide (all platforms)
3. **API_ENDPOINTS_SUMMARY.md** - This file (quick reference)
4. **API_AUTHENTICATION_SUMMARY.md** - Authentication details

---

**Version:** 1.0  
**Last Updated:** December 2025  
**API Status:** ✅ Production Ready  
**Authentication:** API Key Required

