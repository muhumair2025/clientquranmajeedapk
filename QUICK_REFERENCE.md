# 🚀 Quick Reference Card

## Your API Key
```
de9cc0578682fe54e2b7fc4702947a5080b57ce69bb002f45f18f688d283e4a4
```

## Send This To Your Mobile Developers

```
Header Name:  X-API-Key
Header Value: de9cc0578682fe54e2b7fc4702947a5080b57ce69bb002f45f18f688d283e4a4
```

## Example Request

```javascript
fetch('https://yourdomain.com/api/categories', {
  headers: {
    'X-API-Key': 'de9cc0578682fe54e2b7fc4702947a5080b57ce69bb002f45f18f688d283e4a4'
  }
})
```

## All Protected Endpoints

**Content Management:**
- `/api/categories`
- `/api/categories/{id}`
- `/api/subcategories/{id}`
- `/api/contents/{id}`
- `/api/search`

**Quran (د آیات فایدی، د آیات تفسیر، د آیه لغات):**
- `/api/ayah/{surah}/{ayah}`
- `/api/ayah/{surah}/{ayah}/{type}`
- `/api/section/{type}`
- `/api/surah/{surah}/{type}`
- `/api/surahs`
- `/api/surah/{surah}`

## Without API Key = 401 Error

```json
{
  "success": false,
  "message": "Unauthorized. Invalid or missing API key."
}
```

## Documentation Files

- **DEVELOPER_GUIDE.md** - Complete documentation
- **API_AUTHENTICATION_SUMMARY.md** - Security details
- **API_KEY_SETUP.txt** - Setup instructions

## Keep This Key SECRET! 🔒

