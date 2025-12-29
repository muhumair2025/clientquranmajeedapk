import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:chewie/chewie.dart';
import '../themes/app_theme.dart';
import '../services/lughat_service.dart';
import '../services/tafseer_service.dart';
import '../services/faidi_service.dart';
import '../services/common_models.dart';
import '../localization/app_localizations_extension.dart';
import 'app_text.dart';
import 'dart:io';
import '../utils/theme_extensions.dart';

class FullScreenTextViewer extends StatelessWidget {
  final String content;
  final String title;

  const FullScreenTextViewer({
    super.key,
    required this.content,
    required this.title,
  });

  List<Widget> _buildFormattedTashreeh(String content, bool isDark) {
    List<Widget> wordCards = [];
    
    // Split content by | to get individual word explanations
    List<String> wordExplanations = content.split(' | ');
    
    for (int i = 0; i < wordExplanations.length; i++) {
      String explanation = wordExplanations[i].trim();
      if (explanation.isEmpty) continue;
      
      // Split by : to separate Arabic word from Pashto meaning
      List<String> parts = explanation.split(':');
      if (parts.length >= 2) {
        String arabicWord = parts[0].trim();
        String pashtoMeaning = parts.sublist(1).join(':').trim();
        
        // Add compact word card
        wordCards.add(
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: AppTheme.primaryGreen.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: AppTheme.primaryGreen.withValues(alpha: 0.2),
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Arabic word
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryGreen.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    arabicWord,
                    style: TextStyle(
                      fontFamily: 'Al Qalam Quran Majeed',
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryGreen,
                      height: 1.3,
                    ),
                    textAlign: TextAlign.center,
                    textDirection: TextDirection.rtl,
                  ),
                ),
                
                const SizedBox(height: 6),
                
                // Pashto meaning
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.grey.shade800 : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: AppText(
                    pashtoMeaning,
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark ? Colors.white : Colors.black87,
                      height: 1.4,
                    ),
                    textAlign: TextAlign.center,
                    textDirection: TextDirection.rtl,
                  ),
                ),
              ],
            ),
          ),
        );
      } else {
        // If format is different, show as plain text spanning full width
        wordCards.add(
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark ? Colors.grey.shade800 : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: AppText(
              explanation,
              style: TextStyle(
                fontSize: 14,
                color: isDark ? Colors.white : Colors.black87,
                height: 1.4,
              ),
              textAlign: TextAlign.right,
              textDirection: TextDirection.rtl,
            ),
          ),
        );
      }
    }
    
    // Create a grid layout with 2 columns
    List<Widget> gridRows = [];
    for (int i = 0; i < wordCards.length; i += 2) {
      List<Widget> rowChildren = [];
      
      // Add first card
      rowChildren.add(
        Expanded(child: wordCards[i]),
      );
      
      // Add second card if it exists, otherwise add empty space
      if (i + 1 < wordCards.length) {
        rowChildren.add(const SizedBox(width: 8));
        rowChildren.add(
          Expanded(child: wordCards[i + 1]),
        );
      } else {
        rowChildren.add(const SizedBox(width: 8));
        rowChildren.add(const Expanded(child: SizedBox()));
      }
      
      gridRows.add(
        Row(
          children: rowChildren,
        ),
      );
      
      // Add spacing between rows
      if (i + 2 < wordCards.length) {
        gridRows.add(const SizedBox(height: 8));
      }
    }
    
    return gridRows;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? context.backgroundColor : context.backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Theme.of(context).colorScheme.primary,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.right,
                      textDirection: TextDirection.rtl,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(
                      Icons.close_rounded,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            
            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: _buildFormattedTashreeh(content, isDark),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class FullScreenAudioPlayer extends StatefulWidget {
  final String audioUrl;
  final String title;
  final bool autoPlay;
  final int surahIndex;
  final int ayahIndex;
  final String sectionType; // lughat, tafseer, or faidi

  const FullScreenAudioPlayer({
    super.key,
    required this.audioUrl,
    required this.title,
    required this.surahIndex,
    required this.ayahIndex,
    this.autoPlay = true,
    this.sectionType = 'lughat', // Default to lughat for backward compatibility
  });

  @override
  State<FullScreenAudioPlayer> createState() => _FullScreenAudioPlayerState();
}

class _FullScreenAudioPlayerState extends State<FullScreenAudioPlayer> 
    with TickerProviderStateMixin {
  late AudioPlayer _audioPlayer;
  bool _isPlaying = false;
  bool _isLoading = false;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;
  
  // Animation for rotating icon
  late AnimationController _rotationController;
  
  // Download related
  DownloadStatus _downloadStatus = DownloadStatus.notStarted;
  double _downloadProgress = 0.0;
  String? _localFilePath;

  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();
    
    // Initialize rotation animation
    _rotationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    
    _setupAudioPlayer();
    _initializePlayer();
  }
  
  Future<void> _initializePlayer() async {
    await _checkDownloadStatus();
    
    if (widget.autoPlay) {
      _startAutoPlay();
    }
  }

  Future<void> _checkDownloadStatus() async {
    // Check the status from appropriate service based on section type
    DownloadStatus status;
    double progress;
    
    switch (widget.sectionType) {
      case 'lughat':
        status = LughatService.getDownloadStatus(widget.surahIndex, widget.ayahIndex, LughatType.audio);
        progress = LughatService.getDownloadProgress(widget.surahIndex, widget.ayahIndex, LughatType.audio);
        break;
      case 'tafseer':
        status = TafseerService.getDownloadStatus(widget.surahIndex, widget.ayahIndex, TafseerType.audio);
        progress = TafseerService.getDownloadProgress(widget.surahIndex, widget.ayahIndex, TafseerType.audio);
        break;
      case 'faidi':
        status = FaidiService.getDownloadStatus(widget.surahIndex, widget.ayahIndex, FaidiType.audio);
        progress = FaidiService.getDownloadProgress(widget.surahIndex, widget.ayahIndex, FaidiType.audio);
        break;
      default:
        status = LughatService.getDownloadStatus(widget.surahIndex, widget.ayahIndex, LughatType.audio);
        progress = LughatService.getDownloadProgress(widget.surahIndex, widget.ayahIndex, LughatType.audio);
        break;
    }
    
    setState(() {
      _downloadStatus = status;
      _downloadProgress = progress;
    });
    
    // Always try to get local file path if status indicates completed
    // This ensures we get the correct path even after app restart
    if (_downloadStatus == DownloadStatus.completed) {
      String? localPath;
      
      switch (widget.sectionType) {
        case 'lughat':
          localPath = await LughatService.getLocalFilePath(widget.surahIndex, widget.ayahIndex, LughatType.audio);
          break;
        case 'tafseer':
          localPath = await TafseerService.getLocalFilePath(widget.surahIndex, widget.ayahIndex, TafseerType.audio);
          break;
        case 'faidi':
          localPath = await FaidiService.getLocalFilePath(widget.surahIndex, widget.ayahIndex, FaidiType.audio);
          break;
        default:
          localPath = await LughatService.getLocalFilePath(widget.surahIndex, widget.ayahIndex, LughatType.audio);
          break;
      }
      
      if (mounted && localPath != null) {
        setState(() {
          _localFilePath = localPath;
        });
      }
    }
  }

  void _setupAudioPlayer() {
    _audioPlayer.onPlayerStateChanged.listen((state) {
      if (mounted) {
        setState(() {
          _isPlaying = state == PlayerState.playing;
          _isLoading = state == PlayerState.playing && _position == Duration.zero;
        });
        
        // Control rotation animation based on playing state
        if (state == PlayerState.playing || _isLoading) {
          _rotationController.repeat();
        } else {
          _rotationController.stop();
        }
      }
    });

    _audioPlayer.onDurationChanged.listen((duration) {
      if (mounted) {
        setState(() {
          _duration = duration;
        });
      }
    });

    _audioPlayer.onPositionChanged.listen((position) {
      if (mounted) {
        setState(() {
          _position = position;
          _isLoading = false;
        });
      }
    });

    // Add error listener for better debugging
    _audioPlayer.onPlayerStateChanged.listen((state) {
      if (state == PlayerState.stopped && mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    });
  }

  Future<void> _startAutoPlay() async {
    try {
      setState(() {
        _isLoading = true;
      });
      
      // Use local file if available, otherwise stream
      if (_localFilePath != null) {
        debugPrint('Playing local audio file: $_localFilePath');
        await _audioPlayer.play(DeviceFileSource(_localFilePath!));
      } else {
        debugPrint('Streaming audio from URL: ${widget.audioUrl}');
        await _audioPlayer.play(UrlSource(widget.audioUrl));
      }
          } catch (e) {
        debugPrint('Audio playback error: $e');
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
          _showUserFriendlyError(context.l.audioPlaybackError, e);
        }
      }
  }

  Future<void> _playPause() async {
    try {
      if (_isPlaying) {
        await _audioPlayer.pause();
      } else {
        setState(() {
          _isLoading = true;
        });
        _rotationController.repeat(); // Start animation immediately
        
        // Use local file if available, otherwise stream
        if (_localFilePath != null) {
          await _audioPlayer.play(DeviceFileSource(_localFilePath!));
        } else {
          await _audioPlayer.play(UrlSource(widget.audioUrl));
        }
      }
    } catch (e) {
      if (mounted) {
        _showUserFriendlyError(context.l.audioPlaybackError, e);
      }
    }
  }

  Future<void> _startDownload() async {
    setState(() {
      _downloadStatus = DownloadStatus.downloading;
    });

    try {
      String localPath;
      
      switch (widget.sectionType) {
        case 'lughat':
          localPath = await LughatService.downloadFile(
            widget.surahIndex,
            widget.ayahIndex,
            LughatType.audio,
            _onDownloadProgress,
            _onDownloadError,
          );
          break;
        case 'tafseer':
          localPath = await TafseerService.downloadFile(
            widget.surahIndex,
            widget.ayahIndex,
            TafseerType.audio,
            _onDownloadProgress,
            _onDownloadError,
          );
          break;
        case 'faidi':
          localPath = await FaidiService.downloadFile(
            widget.surahIndex,
            widget.ayahIndex,
            FaidiType.audio,
            _onDownloadProgress,
            _onDownloadError,
          );
          break;
        default:
          localPath = await LughatService.downloadFile(
            widget.surahIndex,
            widget.ayahIndex,
            LughatType.audio,
            _onDownloadProgress,
            _onDownloadError,
          );
          break;
      }

      // Ensure final state is set even if progress callback didn't reach 100%
      if (mounted) {
        setState(() {
          _downloadStatus = DownloadStatus.completed;
          _localFilePath = localPath;
          _downloadProgress = 1.0; // Ensure progress shows 100%
        });
        
        // Only show success message if not already shown
        if (_downloadProgress < 1.0) {
          _showSuccessSnackBar(context.l.audioDownloadSuccess);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _downloadStatus = DownloadStatus.failed;
        });
        _showUserFriendlyError(context.l.downloadError, e);
      }
    }
  }
  
  void _onDownloadProgress(double progress) {
    if (mounted) {
      setState(() {
        _downloadProgress = progress;
        
        // Check if download is completed (100%)
        if (progress >= 1.0) {
          _downloadStatus = DownloadStatus.completed;
        }
      });
      
      // Show success message when download reaches 100%
      if (progress >= 1.0) {
        _showSuccessSnackBar(context.l.audioDownloadSuccess);
        
        // Get the local file path for completed download
        _getLocalFilePathForSection().then((localPath) {
          if (mounted && localPath != null) {
            setState(() {
              _localFilePath = localPath;
            });
          }
        });
      }
    }
  }
  
  void _onDownloadError(String error) {
    // Don't show error if download was cancelled by user
    if (error.toLowerCase().contains('cancelled') || 
        error.toLowerCase().contains('canceled')) {
      debugPrint('Download cancelled by user - not showing error');
      return;
    }
    
    if (mounted) {
      _showUserFriendlyError(context.l.downloadError, error);
    }
  }
  
  Future<String?> _getLocalFilePathForSection() async {
    switch (widget.sectionType) {
      case 'lughat':
        return await LughatService.getLocalFilePath(widget.surahIndex, widget.ayahIndex, LughatType.audio);
      case 'tafseer':
        return await TafseerService.getLocalFilePath(widget.surahIndex, widget.ayahIndex, TafseerType.audio);
      case 'faidi':
        return await FaidiService.getLocalFilePath(widget.surahIndex, widget.ayahIndex, FaidiType.audio);
      default:
        return await LughatService.getLocalFilePath(widget.surahIndex, widget.ayahIndex, LughatType.audio);
    }
  }

  void _pauseDownload() {
    try {
      switch (widget.sectionType) {
        case 'lughat':
          LughatService.pauseDownload(widget.surahIndex, widget.ayahIndex, LughatType.audio);
          break;
        case 'tafseer':
          TafseerService.pauseDownload(widget.surahIndex, widget.ayahIndex, TafseerType.audio);
          break;
        case 'faidi':
          FaidiService.pauseDownload(widget.surahIndex, widget.ayahIndex, FaidiType.audio);
          break;
        default:
          LughatService.pauseDownload(widget.surahIndex, widget.ayahIndex, LughatType.audio);
          break;
      }
      
      if (mounted) {
        setState(() {
          _downloadStatus = DownloadStatus.paused;
          _downloadProgress = 0.0; // Reset progress
        });
        _showSuccessSnackBar(context.l.downloadCancelledStatus);
      }
    } catch (e) {
      debugPrint('Error stopping download: $e');
      if (mounted) {
        setState(() {
          _downloadStatus = DownloadStatus.failed;
        });
      }
    }
  }

  Future<void> _resumeDownload() async {
    setState(() {
      _downloadStatus = DownloadStatus.downloading;
    });

    try {
      switch (widget.sectionType) {
        case 'lughat':
          await LughatService.resumeDownload(
            widget.surahIndex,
            widget.ayahIndex,
            LughatType.audio,
            _onDownloadProgress,
            _onDownloadError,
          );
          break;
        case 'tafseer':
          await TafseerService.resumeDownload(
            widget.surahIndex,
            widget.ayahIndex,
            TafseerType.audio,
            _onDownloadProgress,
            _onDownloadError,
          );
          break;
        case 'faidi':
          await FaidiService.resumeDownload(
            widget.surahIndex,
            widget.ayahIndex,
            FaidiType.audio,
            _onDownloadProgress,
            _onDownloadError,
          );
          break;
        default:
          await LughatService.resumeDownload(
            widget.surahIndex,
            widget.ayahIndex,
            LughatType.audio,
            _onDownloadProgress,
            _onDownloadError,
          );
          break;
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _downloadStatus = DownloadStatus.failed;
        });
        _showUserFriendlyError(context.l.downloadError, e);
      }
    }
  }

  Future<void> _deleteDownload() async {
    switch (widget.sectionType) {
      case 'lughat':
        await LughatService.deleteDownload(widget.surahIndex, widget.ayahIndex, LughatType.audio);
        break;
      case 'tafseer':
        await TafseerService.deleteDownload(widget.surahIndex, widget.ayahIndex, TafseerType.audio);
        break;
      case 'faidi':
        await FaidiService.deleteDownload(widget.surahIndex, widget.ayahIndex, FaidiType.audio);
        break;
      default:
        await LughatService.deleteDownload(widget.surahIndex, widget.ayahIndex, LughatType.audio);
        break;
    }
    if (mounted) {
      setState(() {
        _downloadStatus = DownloadStatus.notStarted;
        _downloadProgress = 0.0;
        _localFilePath = null;
      });
      _showSuccessSnackBar(context.l.downloadedFileDeleted);
    }
  }

  void _showUserFriendlyError(String title, dynamic error) {
    String friendlyMessage = _getFriendlyErrorMessage(error);
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        final theme = Theme.of(context);
        final isDark = theme.brightness == Brightness.dark;
        
        return AlertDialog(
          backgroundColor: isDark ? context.surfaceColor : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(
                Icons.error_outline_rounded,
                color: Colors.red,
                size: 24,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                  textDirection: TextDirection.rtl,
                ),
              ),
            ],
          ),
          content: Text(
            friendlyMessage,
            style: TextStyle(
              fontSize: 14,
              color: isDark ? Colors.white70 : Colors.black87,
            ),
            textDirection: TextDirection.rtl,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                context.l.ok,
                style: TextStyle(
                  color: context.primaryColor,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  String _getFriendlyErrorMessage(dynamic error) {
    String errorStr = error.toString().toLowerCase();
    
    // Network/Connection related errors
    if (errorStr.contains('network') || 
        errorStr.contains('connection') || 
        errorStr.contains('timeout') ||
        errorStr.contains('unknownhostexception') ||
        errorStr.contains('unable to resolve host') ||
        errorStr.contains('no address associated') ||
        errorStr.contains('eai_nodata') ||
        errorStr.contains('socketexception') ||
        errorStr.contains('host lookup') ||
        errorStr.contains('failed host lookup') ||
        errorStr.contains('no internet') ||
        errorStr.contains('unreachable')) {
      return context.l.networkConnectionError;
    } else if (errorStr.contains('media_error') || 
               errorStr.contains('mediaplayer') ||
               errorStr.contains('failed to set source') ||
               errorStr.contains('platformexception') && errorStr.contains('audio')) {
      return context.l.networkConnectionError;
    } else if (errorStr.contains('permission') || errorStr.contains('denied')) {
      return context.l.filePermissionError;
    } else if (errorStr.contains('space') || errorStr.contains('storage')) {
      return context.l.insufficientSpaceError;
    } else if (errorStr.contains('format') || errorStr.contains('codec')) {
      return context.l.unsupportedFormatError;
    } else if (errorStr.contains('404') || errorStr.contains('not found')) {
      return context.l.fileNotFoundError;
    } else if (errorStr.contains('500') || errorStr.contains('server')) {
      return context.l.serverError;
    } else {
      return context.l.unknownError;
    }
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(),
          textDirection: TextDirection.rtl,
        ),
        backgroundColor: context.primaryColor,
      ),
    );
  }

  Widget _buildDownloadSection() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDark 
            ? context.primaryColor.withOpacity(0.08)
            : context.primaryColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: context.primaryColor.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Download button on the right
          _buildDownloadButton(),
          const SizedBox(width: 12),
          // Status text on the left
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  _getDownloadStatusText(),
                  style: context.textStyle(
                    fontSize: 13,
                    color: context.primaryColor,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.right,
                  textDirection: TextDirection.rtl,
                ),
                if (_downloadStatus == DownloadStatus.downloading || _downloadStatus == DownloadStatus.paused) ...[
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: _downloadProgress,
                      backgroundColor: context.primaryColor.withOpacity(0.2),
                      valueColor: AlwaysStoppedAnimation<Color>(context.primaryColor),
                      minHeight: 6,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${(_downloadProgress * 100).toInt()}%',
                    style: context.textStyle(
                      fontSize: 11,
                      color: context.primaryColor,
                    ),
                    textAlign: TextAlign.right,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getDownloadStatusText() {
    switch (_downloadStatus) {
      case DownloadStatus.notStarted:
        return context.l.audioNotDownloaded;
      case DownloadStatus.downloading:
        return context.l.downloadInProgress;
      case DownloadStatus.paused:
        return context.l.downloadCancelledStatus;
      case DownloadStatus.completed:
        return context.l.audioDownloaded;
      case DownloadStatus.failed:
        return context.l.downloadError;
    }
  }

  Widget _buildDownloadButton() {
    switch (_downloadStatus) {
      case DownloadStatus.notStarted:
      case DownloadStatus.failed:
        return Container(
          decoration: BoxDecoration(color: Theme.of(context).colorScheme.primary.withOpacity(0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: IconButton(
            onPressed: _startDownload,
            icon: Icon(Icons.download_rounded),
            color: context.primaryColor,
          ),
        );
      case DownloadStatus.downloading:
        return Container(
          decoration: BoxDecoration(
            color: Colors.orange.withOpacity(0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: IconButton(
            onPressed: _pauseDownload,
            icon: Icon(Icons.stop_rounded),
            color: Colors.orange,
          ),
        );
      case DownloadStatus.paused:
        return Container(
          decoration: BoxDecoration(color: Theme.of(context).colorScheme.primary.withOpacity(0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: IconButton(
            onPressed: _resumeDownload,
            icon: Icon(Icons.play_arrow_rounded),
            color: context.primaryColor,
          ),
        );
      case DownloadStatus.completed:
        return Container(
          decoration: BoxDecoration(
            color: Colors.red.withOpacity(0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: IconButton(
            onPressed: _deleteDownload,
            icon: Icon(Icons.delete_rounded),
            color: Colors.red,
          ),
        );
    }
  }

  Future<void> _seek(double value) async {
    final position = Duration(seconds: value.toInt());
    await _audioPlayer.seek(position);
  }

  Future<void> _seekBackward() async {
    final newPosition = _position - const Duration(seconds: 10);
    final seekPosition = newPosition < Duration.zero ? Duration.zero : newPosition;
    await _audioPlayer.seek(seekPosition);
  }

  Future<void> _seekForward() async {
    final newPosition = _position + const Duration(seconds: 10);
    final seekPosition = newPosition > _duration ? _duration : newPosition;
    await _audioPlayer.seek(seekPosition);
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return '$twoDigitMinutes:$twoDigitSeconds';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? context.backgroundColor : context.backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(color: Theme.of(context).colorScheme.primary,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      widget.title,
                      style: context.textStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.right,
                      textDirection: TextDirection.rtl,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(
                      Icons.close_rounded,
                      color: Colors.white,
                      size: 24,
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),
            
            // Audio Player UI
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    const SizedBox(height: 30),
                    
                    // Audio icon with rotation animation
                    Container(
                      width: 160,
                      height: 160,
                      decoration: BoxDecoration(color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: AnimatedBuilder(
                        animation: _rotationController,
                        builder: (context, child) {
                          return Transform.rotate(
                            angle: _rotationController.value * 2 * 3.14159,
                            child: Icon(
                              _localFilePath != null ? Icons.offline_bolt_rounded : Icons.headphones_rounded,
                              size: 70,
                              color: context.primaryColor,
                            ),
                          );
                        },
                      ),
                    ),
                    
                    const SizedBox(height: 30),
                    
                    // Progress bar
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        children: [
                          SliderTheme(
                            data: SliderTheme.of(context).copyWith(
                              trackHeight: 4,
                              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                              overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
                            ),
                            child: Slider(
                              value: _position.inSeconds.toDouble(),
                              max: _duration.inSeconds.toDouble(),
                              onChanged: _seek,
                              activeColor: context.primaryColor,
                              inactiveColor: context.primaryColor.withValues(alpha: 0.2),
                            ),
                          ),
                          
                          // Time display
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  _formatDuration(_position),
                                  style: TextStyle(
                                    color: isDark ? Colors.white70 : Colors.black54,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                Text(
                                  _formatDuration(_duration),
                                  style: TextStyle(
                                    color: isDark ? Colors.white70 : Colors.black54,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 30),
                    
                    // Audio Controls
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Backward 10s button
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: IconButton(
                            onPressed: _seekBackward,
                            icon: Icon(
                              Icons.replay_10_rounded,
                              color: context.primaryColor,
                              size: 26,
                            ),
                          ),
                        ),
                        
                        const SizedBox(width: 24),
                        
                        // Play/Pause button
                        Container(
                          width: 70,
                          height: 70,
                          decoration: BoxDecoration(color: Theme.of(context).colorScheme.primary,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: context.primaryColor.withValues(alpha: 0.4),
                                blurRadius: 16,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: IconButton(
                            onPressed: _playPause,
                            icon: _isLoading
                                ? AnimatedBuilder(
                                    animation: _rotationController,
                                    builder: (context, child) {
                                      return Transform.rotate(
                                        angle: _rotationController.value * 2 * 3.14159,
                                        child: Icon(
                                          Icons.sync_rounded,
                                          color: Colors.white,
                                          size: 28,
                                        ),
                                      );
                                    },
                                  )
                                : Icon(
                                    _isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                                    color: Colors.white,
                                    size: 36,
                                  ),
                          ),
                        ),
                        
                        const SizedBox(width: 24),
                        
                        // Forward 10s button
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: IconButton(
                            onPressed: _seekForward,
                            icon: Icon(
                              Icons.forward_10_rounded,
                              color: context.primaryColor,
                              size: 26,
                            ),
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Download section
                    _buildDownloadSection(),
                    
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    _rotationController.dispose();
    super.dispose();
  }
}

class FullScreenVideoPlayer extends StatefulWidget {
  final String videoUrl;
  final String title;
  final bool autoPlay;
  final int surahIndex;
  final int ayahIndex;
  final String sectionType; // lughat, tafseer, or faidi

  const FullScreenVideoPlayer({
    super.key,
    required this.videoUrl,
    required this.title,
    required this.surahIndex,
    required this.ayahIndex,
    this.autoPlay = true,
    this.sectionType = 'lughat', // Default to lughat for backward compatibility
  });

  @override
  State<FullScreenVideoPlayer> createState() => _FullScreenVideoPlayerState();
}

class _FullScreenVideoPlayerState extends State<FullScreenVideoPlayer> 
    with TickerProviderStateMixin {
  late VideoPlayerController _videoPlayerController;
  ChewieController? _chewieController;
  bool _isLoading = true;
  String? _error;
  
  // Animation for rotating icon when buffering
  late AnimationController _rotationController;
  
  // Download related
  DownloadStatus _downloadStatus = DownloadStatus.notStarted;
  double _downloadProgress = 0.0;
  String? _localFilePath;

  @override
  void initState() {
    super.initState();
    
    // Initialize rotation animation
    _rotationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    
    _initializePlayer();
  }
  
  Future<void> _initializePlayer() async {
    await _checkDownloadStatus();
    await _initializeVideoPlayer();
  }

  Future<void> _checkDownloadStatus() async {
    // Check the status from appropriate service based on section type
    DownloadStatus status;
    double progress;
    
    switch (widget.sectionType) {
      case 'lughat':
        status = LughatService.getDownloadStatus(widget.surahIndex, widget.ayahIndex, LughatType.video);
        progress = LughatService.getDownloadProgress(widget.surahIndex, widget.ayahIndex, LughatType.video);
        break;
      case 'tafseer':
        status = TafseerService.getDownloadStatus(widget.surahIndex, widget.ayahIndex, TafseerType.video);
        progress = TafseerService.getDownloadProgress(widget.surahIndex, widget.ayahIndex, TafseerType.video);
        break;
      case 'faidi':
        status = FaidiService.getDownloadStatus(widget.surahIndex, widget.ayahIndex, FaidiType.video);
        progress = FaidiService.getDownloadProgress(widget.surahIndex, widget.ayahIndex, FaidiType.video);
        break;
      default:
        status = LughatService.getDownloadStatus(widget.surahIndex, widget.ayahIndex, LughatType.video);
        progress = LughatService.getDownloadProgress(widget.surahIndex, widget.ayahIndex, LughatType.video);
        break;
    }
    
    setState(() {
      _downloadStatus = status;
      _downloadProgress = progress;
    });
    
    // Always try to get local file path if status indicates completed
    // This ensures we get the correct path even after app restart
    if (_downloadStatus == DownloadStatus.completed) {
      String? localPath;
      
      switch (widget.sectionType) {
        case 'lughat':
          localPath = await LughatService.getLocalFilePath(widget.surahIndex, widget.ayahIndex, LughatType.video);
          break;
        case 'tafseer':
          localPath = await TafseerService.getLocalFilePath(widget.surahIndex, widget.ayahIndex, TafseerType.video);
          break;
        case 'faidi':
          localPath = await FaidiService.getLocalFilePath(widget.surahIndex, widget.ayahIndex, FaidiType.video);
          break;
        default:
          localPath = await LughatService.getLocalFilePath(widget.surahIndex, widget.ayahIndex, LughatType.video);
          break;
      }
      
      if (mounted && localPath != null) {
        setState(() {
          _localFilePath = localPath;
        });
      }
    }
  }

  Future<void> _initializeVideoPlayer() async {
    try {
      // Use local file if available, otherwise stream
      if (_localFilePath != null) {
        debugPrint('Playing local video file: $_localFilePath');
        _videoPlayerController = VideoPlayerController.file(File(_localFilePath!));
      } else {
        debugPrint('Streaming video from URL: ${widget.videoUrl}');
        _videoPlayerController = VideoPlayerController.networkUrl(
          Uri.parse(widget.videoUrl),
        );
      }

      await _videoPlayerController.initialize();

      // Add listener for video player state changes
      _videoPlayerController.addListener(() {
        if (mounted) {
          if (_videoPlayerController.value.isBuffering) {
            _rotationController.repeat();
          } else {
            _rotationController.stop();
          }
        }
      });

      _chewieController = ChewieController(
        videoPlayerController: _videoPlayerController,
        autoPlay: widget.autoPlay,
        looping: false,
        allowFullScreen: true,
        allowMuting: true,
        showControls: true,
        materialProgressColors: ChewieProgressColors(
          playedColor: context.primaryColor,
          handleColor: context.primaryColor,
          backgroundColor: context.primaryColor.withValues(alpha: 0.3),
          bufferedColor: context.primaryColor.withValues(alpha: 0.5),
        ),
        placeholder: Container(
          color: Colors.black,
          child: Center(
            child: AnimatedBuilder(
              animation: _rotationController,
              builder: (context, child) {
                return Transform.rotate(
                  angle: _rotationController.value * 2 * 3.14159,
                  child: Icon(
                    Icons.videocam_outlined,
                    size: 80,
                    color: context.primaryColor,
                  ),
                );
              },
            ),
          ),
        ),
        errorBuilder: (context, errorMessage) {
          return Container(
            color: Colors.black,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline_rounded,
                    color: Colors.red,
                    size: 48,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    context.l.videoPlaybackError,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                    ),
                    textDirection: TextDirection.rtl,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    errorMessage,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        },
      );

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Video initialization error: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = 'Video initialization failed';
        });
        _showUserFriendlyError(context.l.videoPlaybackError, e);
      }
    }
  }

  Future<void> _startDownload() async {
    setState(() {
      _downloadStatus = DownloadStatus.downloading;
    });

    try {
      String localPath;
      
      switch (widget.sectionType) {
        case 'lughat':
          localPath = await LughatService.downloadFile(
            widget.surahIndex,
            widget.ayahIndex,
            LughatType.video,
            _onVideoDownloadProgress,
            _onVideoDownloadError,
          );
          break;
        case 'tafseer':
          localPath = await TafseerService.downloadFile(
            widget.surahIndex,
            widget.ayahIndex,
            TafseerType.video,
            _onVideoDownloadProgress,
            _onVideoDownloadError,
          );
          break;
        case 'faidi':
          localPath = await FaidiService.downloadFile(
            widget.surahIndex,
            widget.ayahIndex,
            FaidiType.video,
            _onVideoDownloadProgress,
            _onVideoDownloadError,
          );
          break;
        default:
          localPath = await LughatService.downloadFile(
            widget.surahIndex,
            widget.ayahIndex,
            LughatType.video,
            _onVideoDownloadProgress,
            _onVideoDownloadError,
          );
          break;
      }

      // Ensure final state is set even if progress callback didn't reach 100%
      if (mounted) {
        setState(() {
          _downloadStatus = DownloadStatus.completed;
          _localFilePath = localPath;
          _downloadProgress = 1.0; // Ensure progress shows 100%
        });
        
        // Only show success message if not already shown
        if (_downloadProgress < 1.0) {
          _showSuccessSnackBar(context.l.videoDownloadSuccess);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _downloadStatus = DownloadStatus.failed;
        });
        _showUserFriendlyError(context.l.downloadError, e);
      }
    }
  }
  
  void _onVideoDownloadProgress(double progress) {
    if (mounted) {
      setState(() {
        _downloadProgress = progress;
        
        // Check if download is completed (100%)
        if (progress >= 1.0) {
          _downloadStatus = DownloadStatus.completed;
        }
      });
      
      // Show success message when download reaches 100%
      if (progress >= 1.0) {
        _showSuccessSnackBar(context.l.videoDownloadSuccess);
        
        // Get the local file path for completed download
        _getLocalVideoFilePathForSection().then((localPath) {
          if (mounted && localPath != null) {
            setState(() {
              _localFilePath = localPath;
            });
          }
        });
      }
    }
  }
  
  void _onVideoDownloadError(String error) {
    if (mounted) {
      _showUserFriendlyError(context.l.downloadError, error);
    }
  }
  
  Future<String?> _getLocalVideoFilePathForSection() async {
    switch (widget.sectionType) {
      case 'lughat':
        return await LughatService.getLocalFilePath(widget.surahIndex, widget.ayahIndex, LughatType.video);
      case 'tafseer':
        return await TafseerService.getLocalFilePath(widget.surahIndex, widget.ayahIndex, TafseerType.video);
      case 'faidi':
        return await FaidiService.getLocalFilePath(widget.surahIndex, widget.ayahIndex, FaidiType.video);
      default:
        return await LughatService.getLocalFilePath(widget.surahIndex, widget.ayahIndex, LughatType.video);
    }
  }

  void _pauseDownload() {
    switch (widget.sectionType) {
      case 'lughat':
        LughatService.pauseDownload(widget.surahIndex, widget.ayahIndex, LughatType.video);
        break;
      case 'tafseer':
        TafseerService.pauseDownload(widget.surahIndex, widget.ayahIndex, TafseerType.video);
        break;
      case 'faidi':
        FaidiService.pauseDownload(widget.surahIndex, widget.ayahIndex, FaidiType.video);
        break;
      default:
        LughatService.pauseDownload(widget.surahIndex, widget.ayahIndex, LughatType.video);
        break;
    }
    setState(() {
      _downloadStatus = DownloadStatus.paused;
    });
  }

  Future<void> _resumeDownload() async {
    setState(() {
      _downloadStatus = DownloadStatus.downloading;
    });

    try {
      switch (widget.sectionType) {
        case 'lughat':
          await LughatService.resumeDownload(
            widget.surahIndex,
            widget.ayahIndex,
            LughatType.video,
            _onVideoDownloadProgress,
            _onVideoDownloadError,
          );
          break;
        case 'tafseer':
          await TafseerService.resumeDownload(
            widget.surahIndex,
            widget.ayahIndex,
            TafseerType.video,
            _onVideoDownloadProgress,
            _onVideoDownloadError,
          );
          break;
        case 'faidi':
          await FaidiService.resumeDownload(
            widget.surahIndex,
            widget.ayahIndex,
            FaidiType.video,
            _onVideoDownloadProgress,
            _onVideoDownloadError,
          );
          break;
        default:
          await LughatService.resumeDownload(
            widget.surahIndex,
            widget.ayahIndex,
            LughatType.video,
            _onVideoDownloadProgress,
            _onVideoDownloadError,
          );
          break;
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _downloadStatus = DownloadStatus.failed;
        });
        _showUserFriendlyError(context.l.downloadError, e);
      }
    }
  }

  Future<void> _deleteDownload() async {
    switch (widget.sectionType) {
      case 'lughat':
        await LughatService.deleteDownload(widget.surahIndex, widget.ayahIndex, LughatType.video);
        break;
      case 'tafseer':
        await TafseerService.deleteDownload(widget.surahIndex, widget.ayahIndex, TafseerType.video);
        break;
      case 'faidi':
        await FaidiService.deleteDownload(widget.surahIndex, widget.ayahIndex, FaidiType.video);
        break;
      default:
        await LughatService.deleteDownload(widget.surahIndex, widget.ayahIndex, LughatType.video);
        break;
    }
    if (mounted) {
      setState(() {
        _downloadStatus = DownloadStatus.notStarted;
        _downloadProgress = 0.0;
        _localFilePath = null;
      });
      _showSuccessSnackBar(context.l.fileDeletedSuccess);
    }
  }

  void _showUserFriendlyError(String title, dynamic error) {
    String friendlyMessage = _getFriendlyErrorMessage(error);
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        final theme = Theme.of(context);
        final isDark = theme.brightness == Brightness.dark;
        
        return AlertDialog(
          backgroundColor: isDark ? context.surfaceColor : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(
                Icons.error_outline_rounded,
                color: Colors.red,
                size: 24,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                  textDirection: TextDirection.rtl,
                ),
              ),
            ],
          ),
          content: Text(
            friendlyMessage,
            style: TextStyle(
              fontSize: 14,
              color: isDark ? Colors.white70 : Colors.black87,
            ),
            textDirection: TextDirection.rtl,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                context.l.ok,
                style: TextStyle(
                  color: context.primaryColor,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  String _getFriendlyErrorMessage(dynamic error) {
    String errorStr = error.toString().toLowerCase();
    
    // Network/Connection related errors
    if (errorStr.contains('network') || 
        errorStr.contains('connection') || 
        errorStr.contains('timeout') ||
        errorStr.contains('unknownhostexception') ||
        errorStr.contains('unable to resolve host') ||
        errorStr.contains('no address associated') ||
        errorStr.contains('eai_nodata') ||
        errorStr.contains('socketexception') ||
        errorStr.contains('host lookup') ||
        errorStr.contains('failed host lookup') ||
        errorStr.contains('no internet') ||
        errorStr.contains('unreachable')) {
      return context.l.networkConnectionError;
    } else if (errorStr.contains('media_error') || 
               errorStr.contains('mediaplayer') ||
               errorStr.contains('failed to set source') ||
               errorStr.contains('platformexception') && errorStr.contains('video')) {
      return context.l.networkConnectionError;
    } else if (errorStr.contains('permission') || errorStr.contains('denied')) {
      return context.l.filePermissionError;
    } else if (errorStr.contains('space') || errorStr.contains('storage')) {
      return context.l.insufficientSpaceError;
    } else if (errorStr.contains('format') || errorStr.contains('codec')) {
      return context.l.unsupportedFormatError;
    } else if (errorStr.contains('404') || errorStr.contains('not found')) {
      return context.l.fileNotFoundError;
    } else if (errorStr.contains('500') || errorStr.contains('server')) {
      return context.l.serverError;
    } else {
      return context.l.unknownError;
    }
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(),
          textDirection: TextDirection.rtl,
        ),
        backgroundColor: context.primaryColor,
      ),
    );
  }

  Widget _buildDownloadSection() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _getDownloadStatusText(),
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
                textDirection: TextDirection.rtl,
              ),
              _buildDownloadButton(),
            ],
          ),
          
          if (_downloadStatus == DownloadStatus.downloading || _downloadStatus == DownloadStatus.paused) ...[
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: _downloadProgress,
              backgroundColor: Colors.grey.shade300,
              valueColor: AlwaysStoppedAnimation<Color>(context.primaryColor),
            ),
            const SizedBox(height: 8),
            Text(
              '${(_downloadProgress * 100).toInt()}%',
              style: const TextStyle(
                fontSize: 12,
                color: Colors.white,
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _getDownloadStatusText() {
    switch (_downloadStatus) {
      case DownloadStatus.notStarted:
        return context.l.videoNotDownloaded;
      case DownloadStatus.downloading:
        return context.l.downloadInProgress;
      case DownloadStatus.paused:
        return context.l.downloadCancelledStatus;
      case DownloadStatus.completed:
        return context.l.videoDownloaded;
      case DownloadStatus.failed:
        return context.l.downloadError;
    }
  }

  Widget _buildDownloadButton() {
    switch (_downloadStatus) {
      case DownloadStatus.notStarted:
      case DownloadStatus.failed:
        return IconButton(
          onPressed: _startDownload,
          icon: Icon(Icons.download_rounded),
          color: Colors.white,
        );
      case DownloadStatus.downloading:
        return IconButton(
          onPressed: _pauseDownload,
          icon: Icon(Icons.pause_rounded),
          color: Colors.white,
        );
      case DownloadStatus.paused:
        return IconButton(
          onPressed: _resumeDownload,
          icon: Icon(Icons.play_arrow_rounded),
          color: Colors.white,
        );
      case DownloadStatus.completed:
        return IconButton(
          onPressed: _deleteDownload,
          icon: Icon(Icons.delete_rounded),
          color: Colors.red,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: context.primaryColor,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      widget.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.right,
                      textDirection: TextDirection.rtl,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(
                      Icons.close_rounded,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            
            // Video Player
            Expanded(
              child: _isLoading
                  ? Center(
                      child: CircularProgressIndicator(
                        color: context.primaryColor,
                      ),
                    )
                  : _error != null
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.error_outline_rounded,
                                color: Colors.red,
                                size: 48,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                context.l.videoPlaybackError,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                ),
                                textDirection: TextDirection.rtl,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _error!,
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        )
                      : Column(
                          children: [
                            // Video player
                            Expanded(
                              child: _chewieController != null
                                  ? Chewie(controller: _chewieController!)
                                  : Center(
                                      child: CircularProgressIndicator(
                                        color: context.primaryColor,
                                      ),
                                    ),
                            ),
                            
                            // Download section
                            _buildDownloadSection(),
                          ],
                        ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _chewieController?.dispose();
    _videoPlayerController.dispose();
    _rotationController.dispose();
    super.dispose();
  }
} 