# Quran XML Maker API Documentation

**Base URL:** `https://quranxmlmaker.ssatechs.com/api`

## Overview

The Quran XML Maker API provides access to audio and video content for Quranic verses across three educational categories in Pashto language. This RESTful API is designed for mobile app developers who need structured access to Islamic educational content.

## Categories (Sections)

| Section Key | Pashto Name | English Description |
|-------------|-------------|-------------------|
| `lughat` | د آیه لغات | Verse Vocabulary/Word Meanings |
| `tafseer` | د آیات تفسیر | Verse Commentary/Interpretation |
| `faidi` | د آیات فایدی | Verse Benefits/Lessons |

## Authentication

Currently, no authentication is required. All endpoints are publicly accessible.

## Response Format

All API responses follow this consistent JSON structure:

```json
{
  "success": true,
  "section_name": "د آیه لغات",
  "section_key": "lughat",
  "surah": "1",
  "ayah": "1",
  "surah_info": {
    "name_arabic": "الفاتحه",
    "name_pashto": "فاتحه",
    "total_ayahs": 7
  },
  "audio_url": "https://example.com/audio.mp3",
  "video_url": "https://example.com/video.mp4"
}
```

## API Endpoints

### 1. Get Specific Section Data for an Ayah

**Endpoint:** `GET /api/ayah/{surah}/{ayah}/{section}`

**Description:** Retrieve audio and video URLs for a specific section of a Quranic verse.

**Parameters:**
- `surah` (integer): Surah number (1-114)
- `ayah` (integer): Ayah number within the surah
- `section` (string): Section type (`lughat`, `tafseer`, or `faidi`)

**Example Requests:**
```
GET https://quranxmlmaker.ssatechs.com/api/ayah/1/1/lughat
GET https://quranxmlmaker.ssatechs.com/api/ayah/2/255/tafseer
GET https://quranxmlmaker.ssatechs.com/api/ayah/36/9/faidi
```

**Example Response:**
```json
{
  "success": true,
  "section_name": "د آیه لغات",
  "section_key": "lughat",
  "surah": "1",
  "ayah": "1",
  "surah_info": {
    "name_arabic": "الفاتحه",
    "name_pashto": "فاتحه",
    "total_ayahs": 7
  },
  "audio_url": "https://f002.backblazeb2.com/file/mktpsh/audio/lughat_1_1.mp3",
  "video_url": "https://f002.backblazeb2.com/file/mktpsh/video/lughat_1_1.mp4"
}
```

### 2. Get All Sections for an Ayah

**Endpoint:** `GET /api/ayah/{surah}/{ayah}`

**Description:** Retrieve all three sections (lughat, tafseer, faidi) data for a specific verse.

**Parameters:**
- `surah` (integer): Surah number (1-114)
- `ayah` (integer): Ayah number within the surah

**Example Request:**
```
GET https://quranxmlmaker.ssatechs.com/api/ayah/1/1
```

**Example Response:**
```json
{
  "lughat": {
    "success": true,
    "section_name": "د آیه لغات",
    "section_key": "lughat",
    "surah": "1",
    "ayah": "1",
    "surah_info": {
      "name_arabic": "الفاتحه",
      "name_pashto": "فاتحه",
      "total_ayahs": 7
    },
    "audio_url": "https://example.com/lughat_audio.mp3",
    "video_url": "https://example.com/lughat_video.mp4"
  },
  "tafseer": {
    "success": true,
    "section_name": "د آیات تفسیر",
    "section_key": "tafseer",
    "surah": "1",
    "ayah": "1",
    "surah_info": {
      "name_arabic": "الفاتحه",
      "name_pashto": "فاتحه",
      "total_ayahs": 7
    },
    "audio_url": null,
    "video_url": "https://example.com/tafseer_video.mp4"
  },
  "faidi": {
    "success": true,
    "section_name": "د آیات فایدی",
    "section_key": "faidi",
    "surah": "1",
    "ayah": "1",
    "surah_info": {
      "name_arabic": "الفاتحه",
      "name_pashto": "فاتحه",
      "total_ayahs": 7
    },
    "audio_url": "https://example.com/faidi_audio.mp3",
    "video_url": null
  }
}
```

### 3. Get All Data for a Section

**Endpoint:** `GET /api/section/{section}`

**Description:** Retrieve all available data for a specific section across all surahs.

**Parameters:**
- `section` (string): Section type (`lughat`, `tafseer`, or `faidi`)

**Example Request:**
```
GET https://quranxmlmaker.ssatechs.com/api/section/lughat
```

**Example Response:**
```json
{
  "success": true,
  "section_name": "د آیه لغات",
  "section_key": "lughat",
  "total_entries": 150,
  "data": [
    {
      "success": true,
      "section_name": "د آیه لغات",
      "section_key": "lughat",
      "surah": "1",
      "ayah": "1",
      "surah_info": {
        "name_arabic": "الفاتحه",
        "name_pashto": "فاتحه",
        "total_ayahs": 7
      },
      "audio_url": "https://example.com/audio1.mp3",
      "video_url": "https://example.com/video1.mp4"
    }
    // ... more entries
  ]
}
```

### 4. Get Section Data for Specific Surah

**Endpoint:** `GET /api/surah/{surah}/{section}`

**Description:** Retrieve all data for a specific section within a particular surah.

**Parameters:**
- `surah` (integer): Surah number (1-114)
- `section` (string): Section type (`lughat`, `tafseer`, or `faidi`)

**Example Request:**
```
GET https://quranxmlmaker.ssatechs.com/api/surah/1/lughat
```

### 5. Get All Surahs Information

**Endpoint:** `GET /api/surahs`

**Description:** Retrieve information about all 114 surahs including Arabic names, Pashto names, and verse counts.

**Example Request:**
```
GET https://quranxmlmaker.ssatechs.com/api/surahs
```

**Example Response:**
```json
{
  "success": true,
  "total_surahs": 114,
  "surahs": {
    "1": {
      "name": "الفاتحه",
      "pashto": "فاتحه",
      "ayahs": 7
    },
    "2": {
      "name": "البقرة",
      "pashto": "بقره",
      "ayahs": 286
    }
    // ... all 114 surahs
  }
}
```

### 6. Get Surah Statistics

**Endpoint:** `GET /api/surah/{surah}`

**Description:** Get detailed information and statistics for a specific surah.

**Parameters:**
- `surah` (integer): Surah number (1-114)

**Example Request:**
```
GET https://quranxmlmaker.ssatechs.com/api/surah/1
```

**Example Response:**
```json
{
  "success": true,
  "surah": "1",
  "surah_info": {
    "name_arabic": "الفاتحه",
    "name_pashto": "فاتحه",
    "total_ayahs": 7
  },
  "statistics": {
    "lughat": {
      "section_name": "د آیه لغات",
      "audio_count": 5,
      "video_count": 7,
      "total_count": 12
    },
    "tafseer": {
      "section_name": "د آیات تفسیر",
      "audio_count": 3,
      "video_count": 4,
      "total_count": 7
    },
    "faidi": {
      "section_name": "د آیات فایدی",
      "audio_count": 2,
      "video_count": 6,
      "total_count": 8
    }
  }
}
```

## Error Handling

### Error Response Format
```json
{
  "success": false,
  "message": "Error description"
}
```

### Common Error Codes

| HTTP Status | Error Message | Description |
|-------------|---------------|-------------|
| 404 | "Invalid surah or ayah number" | Surah number not between 1-114 or ayah number exceeds surah's total |
| 404 | "Invalid section type. Valid types: lughat, tafseer, faidi" | Section parameter is not one of the valid types |

## Usage Examples

### Android (Java/Kotlin)
```java
// Example using OkHttp
OkHttpClient client = new OkHttpClient();
Request request = new Request.Builder()
    .url("https://quranxmlmaker.ssatechs.com/api/ayah/1/1/lughat")
    .build();

client.newCall(request).enqueue(new Callback() {
    @Override
    public void onResponse(Call call, Response response) throws IOException {
        String jsonData = response.body().string();
        // Parse JSON and use data
    }
});
```

### iOS (Swift)
```swift
// Example using URLSession
let url = URL(string: "https://quranxmlmaker.ssatechs.com/api/ayah/1/1/lughat")!
let task = URLSession.shared.dataTask(with: url) { data, response, error in
    if let data = data {
        // Parse JSON and use data
        let json = try? JSONSerialization.jsonObject(with: data, options: [])
    }
}
task.resume()
```

### React Native (JavaScript)
```javascript
// Example using fetch
fetch('https://quranxmlmaker.ssatechs.com/api/ayah/1/1/lughat')
  .then(response => response.json())
  .then(data => {
    console.log('Audio URL:', data.audio_url);
    console.log('Video URL:', data.video_url);
  })
  .catch(error => console.error('Error:', error));
```

## Data Availability

- **Audio URLs**: Direct links to MP3 audio files
- **Video URLs**: Direct links to MP4 video files
- **Null Values**: When `audio_url` or `video_url` is `null`, it means no content is available for that media type
- **Content Language**: All educational content is in Pashto language
- **File Hosting**: Media files are hosted on reliable CDN services

## Rate Limiting

Currently, there are no rate limits imposed. However, please use the API responsibly and implement appropriate caching in your applications.

## Support

For technical support or questions about the API, please contact the development team through the [Quran XML Maker website](https://quranxmlmaker.ssatechs.com/).

## Changelog

### Version 1.0 (2025)
- Initial API release
- Support for lughat, tafseer, and faidi sections
- Audio and video content endpoints
- Complete Quran coverage (114 surahs)

---

**Last Updated:** January 2025  
**API Version:** 1.0  
**Base URL:** https://quranxmlmaker.ssatechs.com/api
