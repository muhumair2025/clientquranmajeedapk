import '../widgets/app_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import '../services/live_video_service.dart';
import '../services/video_pin_service.dart';
import '../models/live_video_models.dart';
import '../themes/app_theme.dart';
import '../localization/app_localizations_extension.dart';

class LiveDarsScreen extends StatefulWidget {
  const LiveDarsScreen({super.key});

  @override
  State<LiveDarsScreen> createState() => _LiveDarsScreenState();
}

enum VideoSortBy { dateNewest, dateOldest, status }
enum VideoStatusFilter { all, live, upcoming, ended }

class _LiveDarsScreenState extends State<LiveDarsScreen> {
  final LiveVideoService _videoService = LiveVideoService();
  final VideoPinService _pinService = VideoPinService();
  
  List<LiveVideo> _liveVideos = [];
  List<int> _pinnedVideoIds = [];
  bool _isLoading = true;
  String? _errorMessage;
  
  // Filter and sort states
  VideoSortBy _sortBy = VideoSortBy.dateNewest;
  VideoStatusFilter _statusFilter = VideoStatusFilter.all;

  @override
  void initState() {
    super.initState();
    _loadLiveVideos();
    _loadPinnedVideos();
  }

  Future<void> _loadLiveVideos() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final videos = await _videoService.getLiveVideos();

      if (mounted) {
        setState(() {
          _liveVideos = videos;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load live videos';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadPinnedVideos() async {
    final pinnedIds = await _pinService.getPinnedVideoIds();
    if (mounted) {
      setState(() {
        _pinnedVideoIds = pinnedIds;
      });
    }
  }

  Future<void> _refreshVideos() async {
    try {
      final videos = await _videoService.getLiveVideos(forceRefresh: true);
      await _loadPinnedVideos();
      
      if (mounted) {
        setState(() {
          _liveVideos = videos;
        });
      }
    } catch (e) {
      debugPrint('Refresh failed: $e');
    }
  }

  List<LiveVideo> _getFilteredAndSortedVideos() {
    var videos = List<LiveVideo>.from(_liveVideos);

    // Apply status filter
    switch (_statusFilter) {
      case VideoStatusFilter.live:
        videos = videos.where((v) => v.isLive).toList();
        break;
      case VideoStatusFilter.upcoming:
        videos = videos.where((v) => v.isUpcomingStream).toList();
        break;
      case VideoStatusFilter.ended:
        videos = videos.where((v) => v.hasEnded).toList();
        break;
      case VideoStatusFilter.all:
        // No filter
        break;
    }

    // Apply sorting
    switch (_sortBy) {
      case VideoSortBy.dateNewest:
        videos.sort((a, b) {
          final aDate = a.scheduledAt ?? DateTime(2000);
          final bDate = b.scheduledAt ?? DateTime(2000);
          return bDate.compareTo(aDate);
        });
        break;
      case VideoSortBy.dateOldest:
        videos.sort((a, b) {
          final aDate = a.scheduledAt ?? DateTime(2000);
          final bDate = b.scheduledAt ?? DateTime(2000);
          return aDate.compareTo(bDate);
        });
        break;
      case VideoSortBy.status:
        videos.sort((a, b) {
          // Priority: live > upcoming > ended
          int getPriority(LiveVideo v) {
            if (v.isLive) return 0;
            if (v.isUpcomingStream) return 1;
            if (v.hasEnded) return 2;
            return 3;
          }
          return getPriority(a).compareTo(getPriority(b));
        });
        break;
    }

    // Separate pinned and unpinned videos
    final pinnedVideos = videos.where((v) => _pinnedVideoIds.contains(v.id)).toList();
    final unpinnedVideos = videos.where((v) => !_pinnedVideoIds.contains(v.id)).toList();

    // Return pinned videos first, then unpinned
    return [...pinnedVideos, ...unpinnedVideos];
  }

  Future<void> _togglePin(LiveVideo video) async {
    final isPinned = _pinnedVideoIds.contains(video.id);
    
    if (isPinned) {
      // Unpin
      final success = await _pinService.unpinVideo(video.id);
      if (success && mounted) {
        setState(() {
          _pinnedVideoIds.remove(video.id);
        });
        _showSnackBar('Video unpinned');
      }
    } else {
      // Pin
      final canPin = await _pinService.canPinMore();
      if (!canPin) {
        _showSnackBar('Maximum 4 videos can be pinned', isError: true);
        return;
      }
      
      final success = await _pinService.pinVideo(video.id);
      if (success && mounted) {
        setState(() {
          _pinnedVideoIds.add(video.id);
        });
        _showSnackBar('Video pinned to top');
      }
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: AppText(message),
        backgroundColor: isError ? Colors.red.shade400 : null,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showFilterSortSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildFilterSortSheet(),
    );
  }

  Widget _buildFilterSortSheet() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: isDark ? Colors.white24 : Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Title
          Padding(
            padding: const EdgeInsets.all(16),
            child: AppText(
              'Filter & Sort',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
          ),

          // Scrollable content
          Flexible(
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Sort By Section
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AppText(
                          'Sort By',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white70 : Colors.grey.shade700,
                          ),
                        ),
                        const SizedBox(height: 8),
                        _buildSortOption('Date (Newest First)', VideoSortBy.dateNewest, Icons.calendar_today, isDark),
                        _buildSortOption('Date (Oldest First)', VideoSortBy.dateOldest, Icons.history, isDark),
                        _buildSortOption('Status', VideoSortBy.status, Icons.category, isDark),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Filter By Status Section
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AppText(
                          'Filter By Status',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white70 : Colors.grey.shade700,
                          ),
                        ),
                        const SizedBox(height: 8),
                        _buildFilterOption('All', VideoStatusFilter.all, Icons.apps, isDark),
                        _buildFilterOption('Live', VideoStatusFilter.live, Icons.sensors, isDark, color: Colors.red),
                        _buildFilterOption('Upcoming', VideoStatusFilter.upcoming, Icons.schedule, isDark, color: Colors.blue),
                        _buildFilterOption('Ended', VideoStatusFilter.ended, Icons.check_circle, isDark, color: Colors.grey),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSortOption(String label, VideoSortBy value, IconData icon, bool isDark) {
    final isSelected = _sortBy == value;
    
    return InkWell(
      onTap: () {
        setState(() {
          _sortBy = value;
        });
        Navigator.pop(context);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
        margin: const EdgeInsets.only(bottom: 4),
        decoration: BoxDecoration(
          color: isSelected
              ? Colors.red.shade50.withOpacity(isDark ? 0.1 : 1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 20,
              color: isSelected
                  ? Colors.red.shade400
                  : (isDark ? Colors.white60 : Colors.grey.shade600),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: AppText(
                label,
                style: TextStyle(
                  fontSize: 15,
                  color: isSelected
                      ? Colors.red.shade400
                      : (isDark ? Colors.white : Colors.black87),
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle,
                size: 20,
                color: Colors.red.shade400,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterOption(String label, VideoStatusFilter value, IconData icon, bool isDark, {Color? color}) {
    final isSelected = _statusFilter == value;
    final iconColor = color ?? (isDark ? Colors.white60 : Colors.grey.shade600);
    
    return InkWell(
      onTap: () {
        setState(() {
          _statusFilter = value;
        });
        Navigator.pop(context);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
        margin: const EdgeInsets.only(bottom: 4),
        decoration: BoxDecoration(
          color: isSelected
              ? Colors.red.shade50.withOpacity(isDark ? 0.1 : 1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 20,
              color: isSelected ? Colors.red.shade400 : iconColor,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: AppText(
                label,
                style: TextStyle(
                  fontSize: 15,
                  color: isSelected
                      ? Colors.red.shade400
                      : (isDark ? Colors.white : Colors.black87),
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle,
                size: 20,
                color: Colors.red.shade400,
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Loading state
    if (_isLoading && _liveVideos.isEmpty) {
      return Center(
        child: CircularProgressIndicator(
          color: Colors.red.shade400,
        ),
      );
    }

    // Error state (only if no cached videos)
    if (_errorMessage != null && _liveVideos.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: Colors.red.shade400,
            ),
            const SizedBox(height: 12),
            AppText(
              _errorMessage!,
              style: TextStyle(
                fontSize: 14,
                color: isDark ? Colors.white : Colors.grey.shade800,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadLiveVideos,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade400,
                foregroundColor: Colors.white,
              ),
              child: const AppText('Retry'),
            ),
          ],
        ),
      );
    }

    // No videos available
    if (_liveVideos.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.sensors_off_rounded,
              size: 48,
              color: Colors.red.shade400,
            ),
            const SizedBox(height: 12),
            AppText(
              'No live streams available',
              style: TextStyle(
                fontSize: 14,
                color: isDark ? Colors.white70 : Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _refreshVideos,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade400,
                foregroundColor: Colors.white,
              ),
              child: const AppText('Refresh'),
            ),
          ],
        ),
      );
    }

    final filteredVideos = _getFilteredAndSortedVideos();

    // Display live videos - YouTube style with filter button
    return Column(
      children: [
        // Filter/Sort Bar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
            border: Border(
              bottom: BorderSide(
                color: isDark ? Colors.white10 : Colors.grey.shade200,
                width: 1,
              ),
            ),
          ),
          child: Row(
            children: [
              // Filter/Sort Button
              TextButton.icon(
                onPressed: _showFilterSortSheet,
                icon: Icon(
                  Icons.filter_list,
                  size: 18,
                  color: isDark ? Colors.white70 : Colors.grey.shade700,
                ),
                label: AppText(
                  'Filter & Sort',
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? Colors.white70 : Colors.grey.shade700,
                  ),
                ),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
              ),
              
              // Active filters indicator
              if (_statusFilter != VideoStatusFilter.all || _sortBy != VideoSortBy.dateNewest)
                Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                ),
              
              const Spacer(),
              
              // Video count
              AppText(
                '${filteredVideos.length} video${filteredVideos.length != 1 ? 's' : ''}',
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? Colors.white60 : Colors.grey.shade600,
                ),
              ),
              const SizedBox(width: 12),
            ],
          ),
        ),

        // Videos List
        Expanded(
          child: filteredVideos.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.filter_list_off,
                        size: 48,
                        color: Colors.red.shade400,
                      ),
                      const SizedBox(height: 12),
                      AppText(
                        'No videos match the filters',
                        style: TextStyle(
                          fontSize: 14,
                          color: isDark ? Colors.white70 : Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _statusFilter = VideoStatusFilter.all;
                            _sortBy = VideoSortBy.dateNewest;
                          });
                        },
                        child: AppText(
                          'Clear Filters',
                          style: TextStyle(color: Colors.red.shade400),
                        ),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _refreshVideos,
                  color: Colors.red.shade400,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(4),
                    itemCount: filteredVideos.length,
                    itemBuilder: (context, index) {
                      final video = filteredVideos[index];
                      final isPinned = _pinnedVideoIds.contains(video.id);
                      return _buildYouTubeCard(video, isDark, isPinned);
                    },
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildYouTubeCard(LiveVideo video, bool isDark, bool isPinned) {
    return Container(
      margin: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black26 : Colors.grey.shade200,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // YouTube Player with Pin Badge
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                child: YouTubePlayerWidget(
                  videoId: video.youtubeVideoId,
                  thumbnailUrl: video.thumbnailUrl,
                ),
              ),
              
              // Pin Badge (top left)
              if (isPinned)
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade700,
                      borderRadius: BorderRadius.circular(4),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 4,
                        ),
                      ],
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.push_pin,
                          size: 12,
                          color: Colors.white,
                        ),
                        SizedBox(width: 3),
                        AppText(
                          'PINNED',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Poppins',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),

          // Video Info - Compact
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Status badges and Pin button row
                Row(
                  children: [
                    // Live badge
                    if (video.isLive)
                      Container(
                        margin: const EdgeInsets.only(right: 6),
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(3),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 4),
                            const AppText(
                              'LIVE',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Poppins',
                              ),
                            ),
                          ],
                        ),
                      ),
                    
                    // Upcoming badge
                    if (video.isUpcomingStream)
                      Container(
                        margin: const EdgeInsets.only(right: 6),
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.blue,
                          borderRadius: BorderRadius.circular(3),
                        ),
                        child: const AppText(
                          'UPCOMING',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Poppins',
                          ),
                        ),
                      ),
                    
                    // Ended badge
                    if (video.hasEnded)
                      Container(
                        margin: const EdgeInsets.only(right: 6),
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.grey,
                          borderRadius: BorderRadius.circular(3),
                        ),
                        child: const AppText(
                          'ENDED',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Poppins',
                          ),
                        ),
                      ),
                    
                    // Scheduled time for upcoming
                    if (video.isUpcomingStream && video.scheduledAt != null)
                      Expanded(
                        child: Row(
                          children: [
                            Icon(
                              Icons.schedule,
                              size: 12,
                              color: isDark ? Colors.white60 : Colors.grey.shade600,
                            ),
                            const SizedBox(width: 3),
                            Flexible(
                              child: AppText(
                                _formatDate(video.scheduledAt!),
                                style: TextStyle(
                                  fontSize: 11,
                                  color: isDark ? Colors.white60 : Colors.grey.shade600,
                                  fontFamily: 'Poppins',
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    
                    if (!video.isUpcomingStream || video.scheduledAt == null)
                      const Spacer(),
                    
                    // Pin Button
                    InkWell(
                      onTap: () => _togglePin(video),
                      borderRadius: BorderRadius.circular(20),
                      child: Padding(
                        padding: const EdgeInsets.all(4),
                        child: Icon(
                          isPinned ? Icons.push_pin : Icons.push_pin_outlined,
                          size: 20,
                          color: isPinned
                              ? Colors.amber.shade700
                              : (isDark ? Colors.white60 : Colors.grey.shade600),
                        ),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 8),
                
                // Title
                AppText(
                  video.title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : Colors.black87,
                    height: 1.3,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = date.difference(now);

    if (difference.isNegative) {
      return 'Started ${_formatDuration(difference.abs())} ago';
    } else {
      return 'In ${_formatDuration(difference)}';
    }
  }

  String _formatDuration(Duration duration) {
    if (duration.inDays > 0) {
      return '${duration.inDays}d';
    } else if (duration.inHours > 0) {
      return '${duration.inHours}h';
    } else if (duration.inMinutes > 0) {
      return '${duration.inMinutes}m';
    } else {
      return 'now';
    }
  }
}

// Compact YouTube Player Widget
class YouTubePlayerWidget extends StatefulWidget {
  final String videoId;
  final String thumbnailUrl;

  const YouTubePlayerWidget({
    super.key,
    required this.videoId,
    required this.thumbnailUrl,
  });

  @override
  State<YouTubePlayerWidget> createState() => _YouTubePlayerWidgetState();
}

class _YouTubePlayerWidgetState extends State<YouTubePlayerWidget> {
  late YoutubePlayerController _controller;
  bool _isPlayerReady = false;

  @override
  void initState() {
    super.initState();
    _controller = YoutubePlayerController(
      initialVideoId: widget.videoId,
      flags: const YoutubePlayerFlags(
        autoPlay: false,
        mute: false,
        enableCaption: true,
        controlsVisibleAtStart: true,
      ),
    )..addListener(_listener);
  }

  void _listener() {
    if (_isPlayerReady && mounted && !_controller.value.isFullScreen) {
      setState(() {});
    }
  }

  @override
  void deactivate() {
    _controller.pause();
    super.deactivate();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return YoutubePlayerBuilder(
      onEnterFullScreen: () {
        // Hide system UI when entering fullscreen
        SystemChrome.setEnabledSystemUIMode(
          SystemUiMode.immersiveSticky,
        );
      },
      onExitFullScreen: () {
        // Restore system UI when exiting fullscreen
        SystemChrome.setEnabledSystemUIMode(
          SystemUiMode.manual,
          overlays: SystemUiOverlay.values,
        );
      },
      player: YoutubePlayer(
        controller: _controller,
        showVideoProgressIndicator: true,
        progressIndicatorColor: Colors.red,
        topActions: [
          const SizedBox(width: 8),
          Expanded(
            child: AppText(
              _controller.metadata.title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
                fontFamily: 'Poppins', // Use English font for player
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
        ],
        bottomActions: [
          CurrentPosition(),
          const SizedBox(width: 10),
          ProgressBar(
            isExpanded: true,
            colors: const ProgressBarColors(
              playedColor: Colors.red,
              handleColor: Colors.redAccent,
            ),
          ),
          const SizedBox(width: 10),
          RemainingDuration(),
          FullScreenButton(),
        ],
        onReady: () {
          _isPlayerReady = true;
        },
      ),
      builder: (context, player) {
        return AspectRatio(
          aspectRatio: 16 / 9,
          child: player,
        );
      },
    );
  }
}
