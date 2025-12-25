# Live Videos System Documentation

## 📺 Overview

The Live Videos system allows admins to add YouTube live stream links that will be displayed in the mobile app's "Live" section. Users can watch live streams directly within the app.

---

## 🎯 Features

### Admin Panel Features
- ✅ Add YouTube live stream URLs
- ✅ Set video title
- ✅ Schedule date and time for upcoming streams
- ✅ Set status: **Upcoming**, **Live Now**, or **Ended**
- ✅ Display order management
- ✅ Active/Inactive toggle
- ✅ Automatic thumbnail extraction from YouTube
- ✅ Support for multiple YouTube URL formats

### Mobile App Features
- ✅ Fetch all live videos via API
- ✅ Fetch only currently live videos
- ✅ Get YouTube video ID for embedding
- ✅ Get embed URL for in-app player
- ✅ Get thumbnail URL for preview
- ✅ Check if video is live now or upcoming
- ✅ Scheduled date/time information
- ✅ **Pin up to 4 videos to top** (locally stored)
- ✅ **Filter by status:** All, Live, Upcoming, Ended
- ✅ **Sort by:** Date (Newest/Oldest), Status
- ✅ Compact card design with 4px padding
- ✅ Pull-to-refresh functionality
- ✅ Offline caching support

---

## 📍 Admin Panel URLs

| URL | Purpose |
|-----|---------|
| `/app-management` | App Management Dashboard |
| `/app-management/live-videos` | View all live videos |
| `/app-management/live-videos/create` | Add new live video |
| `/app-management/live-videos/{id}/edit` | Edit existing live video |

---

## 🔌 API Endpoints

### Base URL
```
https://yourdomain.com/api
```

### Authentication
All endpoints require the `X-API-Key` header:
```http
X-API-Key: your-api-key-here
```

---

### 1. Get All Live Videos

**Endpoint:** `GET /api/live-videos`

**Description:** Fetch all active live videos (all statuses: upcoming, live, ended)

**Request Example:**
```bash
curl -H "X-API-Key: de9cc0578682fe54e2b7fc4702947a5080b57ce69bb002f45f18f688d283e4a4" \
     https://yourdomain.com/api/live-videos
```

**Response:**
```json
{
  "success": true,
  "message": "Live videos retrieved successfully",
  "data": [
    {
      "id": 1,
      "title": "Friday Jummah Prayer Live",
      "youtube_url": "https://www.youtube.com/watch?v=dQw4w9WgXcQ",
      "youtube_video_id": "dQw4w9WgXcQ",
      "embed_url": "https://www.youtube.com/embed/dQw4w9WgXcQ",
      "thumbnail_url": "https://img.youtube.com/vi/dQw4w9WgXcQ/maxresdefault.jpg",
      "scheduled_at": "2025-12-27T13:00:00+00:00",
      "status": "upcoming",
      "is_live_now": false,
      "is_upcoming": true,
      "order": 0
    },
    {
      "id": 2,
      "title": "Quran Recitation Live Stream",
      "youtube_url": "https://youtu.be/abc123xyz",
      "youtube_video_id": "abc123xyz",
      "embed_url": "https://www.youtube.com/embed/abc123xyz",
      "thumbnail_url": "https://img.youtube.com/vi/abc123xyz/maxresdefault.jpg",
      "scheduled_at": "2025-12-25T10:00:00+00:00",
      "status": "live",
      "is_live_now": true,
      "is_upcoming": false,
      "order": 1
    }
  ]
}
```

---

### 2. Get Currently Live Videos Only

**Endpoint:** `GET /api/live-videos/current`

**Description:** Fetch only videos with status "live" (currently streaming)

**Request Example:**
```bash
curl -H "X-API-Key: de9cc0578682fe54e2b7fc4702947a5080b57ce69bb002f45f18f688d283e4a4" \
     https://yourdomain.com/api/live-videos/current
```

**Response:**
```json
{
  "success": true,
  "message": "Current live videos retrieved successfully",
  "data": [
    {
      "id": 2,
      "title": "Quran Recitation Live Stream",
      "youtube_url": "https://youtu.be/abc123xyz",
      "youtube_video_id": "abc123xyz",
      "embed_url": "https://www.youtube.com/embed/abc123xyz",
      "thumbnail_url": "https://img.youtube.com/vi/abc123xyz/maxresdefault.jpg",
      "scheduled_at": "2025-12-25T10:00:00+00:00"
    }
  ]
}
```

---

## 📱 Flutter/Android Implementation

### 1. Setup API Service

```dart
class LiveVideoService {
  final String baseUrl = 'https://yourdomain.com/api';
  final String apiKey = 'your-api-key-here';

  Future<List<LiveVideo>> getAllLiveVideos() async {
    final response = await http.get(
      Uri.parse('$baseUrl/live-videos'),
      headers: {'X-API-Key': apiKey},
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return (data['data'] as List)
          .map((video) => LiveVideo.fromJson(video))
          .toList();
    } else {
      throw Exception('Failed to load live videos');
    }
  }

  Future<List<LiveVideo>> getCurrentLiveVideos() async {
    final response = await http.get(
      Uri.parse('$baseUrl/live-videos/current'),
      headers: {'X-API-Key': apiKey},
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return (data['data'] as List)
          .map((video) => LiveVideo.fromJson(video))
          .toList();
    } else {
      throw Exception('Failed to load current live videos');
    }
  }
}
```

### 2. Create Model Class

```dart
class LiveVideo {
  final int id;
  final String title;
  final String youtubeUrl;
  final String youtubeVideoId;
  final String embedUrl;
  final String thumbnailUrl;
  final DateTime? scheduledAt;
  final String status;
  final bool isLiveNow;
  final bool isUpcoming;
  final int order;

  LiveVideo({
    required this.id,
    required this.title,
    required this.youtubeUrl,
    required this.youtubeVideoId,
    required this.embedUrl,
    required this.thumbnailUrl,
    this.scheduledAt,
    required this.status,
    required this.isLiveNow,
    required this.isUpcoming,
    required this.order,
  });

  factory LiveVideo.fromJson(Map<String, dynamic> json) {
    return LiveVideo(
      id: json['id'],
      title: json['title'],
      youtubeUrl: json['youtube_url'],
      youtubeVideoId: json['youtube_video_id'],
      embedUrl: json['embed_url'],
      thumbnailUrl: json['thumbnail_url'],
      scheduledAt: json['scheduled_at'] != null 
          ? DateTime.parse(json['scheduled_at']) 
          : null,
      status: json['status'],
      isLiveNow: json['is_live_now'],
      isUpcoming: json['is_upcoming'],
      order: json['order'],
    );
  }
}
```

### 3. Display Live Videos

```dart
class LiveVideosScreen extends StatefulWidget {
  @override
  _LiveVideosScreenState createState() => _LiveVideosScreenState();
}

class _LiveVideosScreenState extends State<LiveVideosScreen> {
  final LiveVideoService _service = LiveVideoService();
  List<LiveVideo> _videos = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadVideos();
  }

  Future<void> _loadVideos() async {
    try {
      final videos = await _service.getAllLiveVideos();
      setState(() {
        _videos = videos;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading videos: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Center(child: CircularProgressIndicator());
    }

    return ListView.builder(
      itemCount: _videos.length,
      itemBuilder: (context, index) {
        final video = _videos[index];
        return LiveVideoCard(video: video);
      },
    );
  }
}
```

### 4. Video Card Widget

```dart
class LiveVideoCard extends StatelessWidget {
  final LiveVideo video;

  const LiveVideoCard({required this.video});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Thumbnail with Live Badge
          Stack(
            children: [
              Image.network(
                video.thumbnailUrl,
                width: double.infinity,
                height: 200,
                fit: BoxFit.cover,
              ),
              if (video.isLiveNow)
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.circle, color: Colors.white, size: 8),
                        SizedBox(width: 6),
                        Text(
                          'LIVE',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          
          // Video Info
          Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  video.title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8),
                
                // Status Badge
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getStatusColor(video.status),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    video.status.toUpperCase(),
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                
                // Scheduled Time
                if (video.scheduledAt != null) ...[
                  SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.schedule, size: 16, color: Colors.grey),
                      SizedBox(width: 4),
                      Text(
                        DateFormat('MMM dd, yyyy - hh:mm a')
                            .format(video.scheduledAt!),
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                ],
                
                SizedBox(height: 12),
                
                // Watch Button
                ElevatedButton.icon(
                  onPressed: () => _openVideo(context, video),
                  icon: Icon(Icons.play_arrow),
                  label: Text('Watch on YouTube'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    minimumSize: Size(double.infinity, 45),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'live':
        return Colors.red;
      case 'upcoming':
        return Colors.blue;
      case 'ended':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  void _openVideo(BuildContext context, LiveVideo video) {
    // Option 1: Open in YouTube app/browser
    launch(video.youtubeUrl);
    
    // Option 2: Embed in app using youtube_player_flutter package
    // Navigator.push(
    //   context,
    //   MaterialPageRoute(
    //     builder: (context) => VideoPlayerScreen(videoId: video.youtubeVideoId),
    //   ),
    // );
  }
}
```

### 5. Embedded YouTube Player (Optional)

Add dependency in `pubspec.yaml`:
```yaml
dependencies:
  youtube_player_flutter: ^8.1.2
```

```dart
class VideoPlayerScreen extends StatefulWidget {
  final String videoId;

  const VideoPlayerScreen({required this.videoId});

  @override
  _VideoPlayerScreenState createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  late YoutubePlayerController _controller;

  @override
  void initState() {
    super.initState();
    _controller = YoutubePlayerController(
      initialVideoId: widget.videoId,
      flags: YoutubePlayerFlags(
        autoPlay: true,
        mute: false,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Live Stream')),
      body: YoutubePlayer(
        controller: _controller,
        showVideoProgressIndicator: true,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
```

---

## 🎨 Supported YouTube URL Formats

The system automatically extracts video IDs from these formats:

1. **Standard Watch URL:**
   ```
   https://www.youtube.com/watch?v=VIDEO_ID
   ```

2. **Live URL:**
   ```
   https://www.youtube.com/live/VIDEO_ID
   ```

3. **Short URL:**
   ```
   https://youtu.be/VIDEO_ID
   ```

4. **Embed URL:**
   ```
   https://www.youtube.com/embed/VIDEO_ID
   ```

---

## 📊 Database Schema

### `live_videos` Table

| Column | Type | Description |
|--------|------|-------------|
| `id` | bigint | Primary key |
| `title` | varchar(255) | Video title |
| `youtube_url` | varchar(255) | Full YouTube URL |
| `scheduled_at` | datetime | Scheduled start time (nullable) |
| `status` | enum | upcoming, live, ended |
| `is_active` | boolean | Visibility toggle |
| `order` | integer | Display order |
| `created_at` | timestamp | Creation timestamp |
| `updated_at` | timestamp | Last update timestamp |

---

## 🔄 Status Management

### Status Types

1. **Upcoming** 🔵
   - Video is scheduled but not yet live
   - Shows scheduled date/time
   - Users can set reminders

2. **Live** 🔴
   - Video is currently streaming
   - Shows "LIVE" badge
   - Highest priority in app

3. **Ended** ⚫
   - Stream has finished
   - Can be watched as replay
   - Lower priority in app

---

## 💡 Best Practices

### For Admins

1. **Set Accurate Status:**
   - Update status to "Live" when stream starts
   - Change to "Ended" after stream finishes

2. **Schedule Information:**
   - Always set scheduled date/time for upcoming streams
   - Helps users plan to watch

3. **Display Order:**
   - Use order 0, 1, 2, etc.
   - Lower numbers appear first
   - Live videos should have lower order numbers

4. **Active Toggle:**
   - Deactivate old/irrelevant videos
   - Keep only recent content active

### For Developers

1. **Refresh Frequency:**
   - Poll `/api/live-videos/current` every 30-60 seconds
   - Check for new live streams

2. **Caching:**
   - Cache thumbnail images locally
   - Reduce bandwidth usage

3. **Error Handling:**
   - Handle invalid YouTube URLs gracefully
   - Show fallback UI if video unavailable

4. **Notifications:**
   - Implement push notifications for new live streams
   - Alert users when scheduled streams go live

---

## 🧪 Testing

### Test API Endpoints (PowerShell)

```powershell
# Get all live videos
Invoke-WebRequest -Uri "https://yourdomain.com/api/live-videos" `
  -Headers @{"X-API-Key"="your-api-key"} `
  -UseBasicParsing | Select-Object -ExpandProperty Content

# Get current live videos
Invoke-WebRequest -Uri "https://yourdomain.com/api/live-videos/current" `
  -Headers @{"X-API-Key"="your-api-key"} `
  -UseBasicParsing | Select-Object -ExpandProperty Content
```

### Test API Endpoints (cURL)

```bash
# Get all live videos
curl -H "X-API-Key: your-api-key" \
     https://yourdomain.com/api/live-videos

# Get current live videos
curl -H "X-API-Key: your-api-key" \
     https://yourdomain.com/api/live-videos/current
```

---

## 🎯 Use Cases

1. **Friday Prayers:**
   - Schedule weekly Jummah prayer streams
   - Set status to "Live" during prayer
   - Keep as "Ended" for replay access

2. **Ramadan Programs:**
   - Add daily Taraweeh prayers
   - Schedule Iftar programs
   - Quran recitation sessions

3. **Islamic Lectures:**
   - Weekly scholar talks
   - Q&A sessions
   - Educational series

4. **Special Events:**
   - Eid prayers
   - Hajj coverage
   - Islamic conferences

---

## 📞 Support

For issues or questions:
- Check API response for error messages
- Verify API key is correct
- Ensure YouTube URLs are valid and public
- Contact system administrator

---

**Version:** 1.0  
**Last Updated:** December 25, 2025  
**Status:** ✅ Production Ready
