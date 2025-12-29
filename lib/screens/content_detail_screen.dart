import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:chewie/chewie.dart';
import '../providers/language_provider.dart';
import '../localization/app_localizations_extension.dart';
import '../services/content_storage_service.dart';
import '../models/content_models.dart';
import '../utils/theme_extensions.dart';
import '../utils/font_manager.dart';
import '../widgets/app_text.dart';
import 'pdf_viewer_screen.dart';

/// Clean minimal content detail screen
class ContentDetailScreen extends StatefulWidget {
  final ContentItem content;

  const ContentDetailScreen({
    super.key,
    required this.content,
  });

  @override
  State<ContentDetailScreen> createState() => _ContentDetailScreenState();
}

class _ContentDetailScreenState extends State<ContentDetailScreen> {
  final ContentStorageService _storageService = ContentStorageService();
  
  late ContentItem _content;
  bool _isDownloading = false;
  double _downloadProgress = 0.0;

  @override
  void initState() {
    super.initState();
    _content = widget.content;
    _checkDownloadStatus();
  }

  Future<void> _checkDownloadStatus() async {
    if (_content.requiresDownload) {
      final isDownloaded = await _storageService.isContentDownloaded(_content.id);
      if (isDownloaded) {
        final localPath = await _storageService.getLocalPath(_content.id);
        if (mounted) {
          setState(() {
            _content = _content.copyWith(isDownloaded: true, localFilePath: localPath);
          });
        }
      }
    }
  }

  Future<void> _startDownload() async {
    setState(() {
      _isDownloading = true;
      _downloadProgress = 0.0;
    });

    try {
      final localPath = await _storageService.downloadContent(
        _content,
        onProgress: (progress) {
          if (mounted) setState(() => _downloadProgress = progress);
        },
        onError: (error) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: AppText(error), backgroundColor: context.errorColor),
            );
          }
        },
      );

      if (mounted) {
        setState(() {
          _content = _content.copyWith(isDownloaded: true, localFilePath: localPath);
          _isDownloading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: AppText(context.l.downloadSuccess),
            backgroundColor: context.primaryColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) setState(() => _isDownloading = false);
    }
  }

  void _cancelDownload() {
    _storageService.cancelDownload(_content.id);
    setState(() {
      _isDownloading = false;
      _downloadProgress = 0.0;
    });
  }

  /// Download and return future for PDF auto-open
  Future<void> _startDownloadAndReturn() async {
    setState(() {
      _isDownloading = true;
      _downloadProgress = 0.0;
    });

    try {
      final localPath = await _storageService.downloadContent(
        _content,
        onProgress: (progress) {
          if (mounted) setState(() => _downloadProgress = progress);
        },
        onError: (error) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: AppText(error), backgroundColor: context.errorColor),
            );
          }
        },
      );

      if (mounted) {
        setState(() {
          _content = _content.copyWith(isDownloaded: true, localFilePath: localPath);
          _isDownloading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isDownloading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.backgroundColor,
      appBar: AppBar(
        title: AppText(
          _content.title,
          style: const TextStyle(fontWeight: FontWeight.w600),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        backgroundColor: context.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _buildContentBody(),
    );
  }

  Widget _buildContentBody() {
    switch (_content.type) {
      case ContentType.text:
        return _TextContentView(content: _content);
      case ContentType.qa:
        return _FAQContentView(content: _content);
      case ContentType.pdf:
        return _PDFContentView(
          content: _content,
          isDownloading: _isDownloading,
          downloadProgress: _downloadProgress,
          onDownload: _startDownloadAndReturn,
          onCancel: _cancelDownload,
        );
      case ContentType.audio:
        return _AudioContentView(
          content: _content,
          isDownloading: _isDownloading,
          downloadProgress: _downloadProgress,
          onDownload: _startDownload,
          onCancel: _cancelDownload,
        );
      case ContentType.video:
        return _VideoContentView(
          content: _content,
          isDownloading: _isDownloading,
          downloadProgress: _downloadProgress,
          onDownload: _startDownload,
          onCancel: _cancelDownload,
        );
    }
  }
}

// ============== TEXT CONTENT ==============
class _TextContentView extends StatelessWidget {
  final ContentItem content;
  const _TextContentView({required this.content});

  @override
  Widget build(BuildContext context) {
    final languageProvider = context.watch<LanguageProvider>();
    final languageCode = languageProvider.currentLanguage;
    final isRTL = FontManager.isRTL(languageCode);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: AppText(
        content.textContent ?? '',
        style: FontManager.getTextStyle(
          languageCode,
          fontSize: 16,
          color: context.textColor,
          height: 1.8,
        ),
        textAlign: isRTL ? TextAlign.right : TextAlign.left,
        textDirection: isRTL ? TextDirection.rtl : TextDirection.ltr,
      ),
    );
  }
}

// ============== FAQ STYLE Q&A ==============
class _FAQContentView extends StatefulWidget {
  final ContentItem content;
  const _FAQContentView({required this.content});

  @override
  State<_FAQContentView> createState() => _FAQContentViewState();
}

class _FAQContentViewState extends State<_FAQContentView> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final languageProvider = context.watch<LanguageProvider>();
    final languageCode = languageProvider.currentLanguage;
    final isRTL = FontManager.isRTL(languageCode);
    final isDark = context.isDarkTheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Container(
        decoration: BoxDecoration(
          color: context.cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: context.primaryColor.withOpacity(0.15)),
        ),
        child: Column(
          children: [
            // Question (clickable header)
            Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.vertical(
                  top: const Radius.circular(12),
                  bottom: Radius.circular(_isExpanded ? 0 : 12),
                ),
                onTap: () => setState(() => _isExpanded = !_isExpanded),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    textDirection: isRTL ? TextDirection.rtl : TextDirection.ltr,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.help_outline,
                        color: context.primaryColor,
                        size: 22,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: AppText(
                          widget.content.question ?? '',
                          style: FontManager.getTextStyle(
                            languageCode,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: context.textColor,
                            height: 1.5,
                          ),
                          textAlign: isRTL ? TextAlign.right : TextAlign.left,
                          textDirection: isRTL ? TextDirection.rtl : TextDirection.ltr,
                        ),
                      ),
                      const SizedBox(width: 8),
                      AnimatedRotation(
                        turns: _isExpanded ? 0.5 : 0,
                        duration: const Duration(milliseconds: 200),
                        child: Icon(
                          Icons.keyboard_arrow_down,
                          color: context.primaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            
            // Answer (expandable)
            AnimatedCrossFade(
              firstChild: const SizedBox.shrink(),
              secondChild: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: context.primaryColor.withOpacity(isDark ? 0.08 : 0.04),
                  borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)),
                ),
                child: Directionality(
                  textDirection: isRTL ? TextDirection.rtl : TextDirection.ltr,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.check_circle_outline, color: context.primaryColor, size: 18),
                            const SizedBox(width: 8),
                            AppText(
                              context.l.questionAnswer.split('&').length > 1 
                                  ? context.l.questionAnswer.split('&')[1].trim()
                                  : 'Answer',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: context.primaryColor,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        AppText(
                          widget.content.answer ?? '',
                          style: FontManager.getTextStyle(
                            languageCode,
                            fontSize: 15,
                            color: context.textColor,
                            height: 1.7,
                          ),
                          textAlign: isRTL ? TextAlign.right : TextAlign.left,
                          textDirection: isRTL ? TextDirection.rtl : TextDirection.ltr,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              crossFadeState: _isExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
              duration: const Duration(milliseconds: 200),
            ),
          ],
        ),
      ),
    );
  }
}

// ============== PDF CONTENT ==============
class _PDFContentView extends StatefulWidget {
  final ContentItem content;
  final bool isDownloading;
  final double downloadProgress;
  final Future<void> Function() onDownload;
  final VoidCallback onCancel;

  const _PDFContentView({
    required this.content,
    required this.isDownloading,
    required this.downloadProgress,
    required this.onDownload,
    required this.onCancel,
  });

  @override
  State<_PDFContentView> createState() => _PDFContentViewState();
}

class _PDFContentViewState extends State<_PDFContentView> {
  
  Future<void> _downloadAndOpen() async {
    await widget.onDownload();
    // After download completes, open PDF viewer
    if (mounted && widget.content.isDownloaded && widget.content.localFilePath != null) {
      _openPdfViewer();
    }
  }

  void _openPdfViewer() {
    Navigator.push(context, MaterialPageRoute(
      builder: (context) => PDFViewerScreen(
        filePath: widget.content.localFilePath!,
        title: widget.content.title,
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    // If already downloaded, auto-open PDF viewer
    if (widget.content.isDownloaded && widget.content.localFilePath != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: context.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(Icons.picture_as_pdf, size: 40, color: context.primaryColor),
              ),
              const SizedBox(height: 24),
              AppText(
                widget.content.title,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: context.textColor),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: _openPdfViewer,
                icon: const Icon(Icons.visibility),
                label: AppText(context.l.openPdf),
                style: ElevatedButton.styleFrom(
                  backgroundColor: context.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: context.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(Icons.picture_as_pdf, size: 40, color: context.primaryColor),
            ),
            const SizedBox(height: 24),
            AppText(
              widget.content.title,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: context.textColor),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            
            if (widget.isDownloading) ...[
              SizedBox(
                width: 180,
                child: LinearProgressIndicator(
                  value: widget.downloadProgress > 0 ? widget.downloadProgress : null,
                  backgroundColor: context.primaryColor.withOpacity(0.2),
                  valueColor: AlwaysStoppedAnimation(context.primaryColor),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AppText('${(widget.downloadProgress * 100).toInt()}%'),
                  const SizedBox(width: 16),
                  TextButton(onPressed: widget.onCancel, child: AppText(context.l.cancel)),
                ],
              ),
            ] else ...[
              ElevatedButton.icon(
                onPressed: _downloadAndOpen,
                icon: const Icon(Icons.download),
                label: AppText(context.l.downloadPdf),
                style: ElevatedButton.styleFrom(
                  backgroundColor: context.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ============== MINIMAL AUDIO PLAYER ==============
class _AudioContentView extends StatefulWidget {
  final ContentItem content;
  final bool isDownloading;
  final double downloadProgress;
  final VoidCallback onDownload;
  final VoidCallback onCancel;

  const _AudioContentView({
    required this.content,
    required this.isDownloading,
    required this.downloadProgress,
    required this.onDownload,
    required this.onCancel,
  });

  @override
  State<_AudioContentView> createState() => _AudioContentViewState();
}

class _AudioContentViewState extends State<_AudioContentView> {
  late AudioPlayer _audioPlayer;
  bool _isPlaying = false;
  bool _isLoading = false;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;

  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();
    _setupAudioPlayer();
  }

  void _setupAudioPlayer() {
    _audioPlayer.onPlayerStateChanged.listen((state) {
      if (mounted) {
        setState(() {
          _isPlaying = state == PlayerState.playing;
          if (state == PlayerState.playing && _position == Duration.zero) {
            _isLoading = true;
          }
        });
      }
    });

    _audioPlayer.onDurationChanged.listen((duration) {
      if (mounted) setState(() => _duration = duration);
    });

    _audioPlayer.onPositionChanged.listen((position) {
      if (mounted) {
        setState(() {
          _position = position;
          _isLoading = false;
        });
      }
    });
  }

  Future<void> _playPause() async {
    if (_isPlaying) {
      await _audioPlayer.pause();
    } else {
      setState(() => _isLoading = true);
      // Play from local file if downloaded, otherwise stream
      if (widget.content.isDownloaded && widget.content.localFilePath != null) {
        await _audioPlayer.play(DeviceFileSource(widget.content.localFilePath!));
      } else {
        await _audioPlayer.play(UrlSource(widget.content.audioUrl ?? ''));
      }
    }
  }

  Future<void> _seek(double value) async {
    await _audioPlayer.seek(Duration(seconds: value.toInt()));
  }

  String _formatDuration(Duration d) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    return '${twoDigits(d.inMinutes.remainder(60))}:${twoDigits(d.inSeconds.remainder(60))}';
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const Spacer(),
          
          // Minimal player card
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: context.cardColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: context.primaryColor.withOpacity(0.1)),
            ),
            child: Column(
              children: [
                // Title
                AppText(
                  widget.content.title,
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: context.textColor),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 24),
                
                // Progress
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    trackHeight: 3,
                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                    overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
                  ),
                  child: Slider(
                    value: _position.inSeconds.toDouble().clamp(0, _duration.inSeconds.toDouble().clamp(1, double.infinity)),
                    max: _duration.inSeconds.toDouble().clamp(1, double.infinity),
                    onChanged: _seek,
                    activeColor: context.primaryColor,
                    inactiveColor: context.primaryColor.withOpacity(0.2),
                  ),
                ),
                
                // Time
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      AppText(_formatDuration(_position), style: TextStyle(fontSize: 12, color: context.secondaryTextColor)),
                      AppText(_formatDuration(_duration), style: TextStyle(fontSize: 12, color: context.secondaryTextColor)),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                
                // Controls
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      onPressed: () => _seek((_position.inSeconds - 10).clamp(0, _duration.inSeconds).toDouble()),
                      icon: Icon(Icons.replay_10, color: context.primaryColor),
                    ),
                    const SizedBox(width: 16),
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: context.primaryColor,
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        onPressed: _playPause,
                        icon: _isLoading
                            ? SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : Icon(_isPlaying ? Icons.pause : Icons.play_arrow, color: Colors.white),
                      ),
                    ),
                    const SizedBox(width: 16),
                    IconButton(
                      onPressed: () => _seek((_position.inSeconds + 10).clamp(0, _duration.inSeconds).toDouble()),
                      icon: Icon(Icons.forward_10, color: context.primaryColor),
                    ),
                  ],
                ),
                
                // Downloaded indicator
                if (widget.content.isDownloaded) ...[
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.download_done, size: 14, color: context.primaryColor),
                      const SizedBox(width: 4),
                      AppText(context.l.offline, style: TextStyle(fontSize: 12, color: context.primaryColor)),
                    ],
                  ),
                ],
              ],
            ),
          ),
          
          const Spacer(),
          
          // Download button
          if (!widget.content.isDownloaded) ...[
            if (widget.isDownloading) ...[
              LinearProgressIndicator(
                value: widget.downloadProgress > 0 ? widget.downloadProgress : null,
                backgroundColor: context.primaryColor.withOpacity(0.2),
                valueColor: AlwaysStoppedAnimation(context.primaryColor),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AppText('${(widget.downloadProgress * 100).toInt()}%'),
                  const SizedBox(width: 16),
                  TextButton(onPressed: widget.onCancel, child: AppText(context.l.cancel)),
                ],
              ),
            ] else ...[
              TextButton.icon(
                onPressed: widget.onDownload,
                icon: const Icon(Icons.download),
                label: AppText(context.l.downloadAudio),
              ),
            ],
          ],
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

// ============== MINIMAL VIDEO PLAYER ==============
class _VideoContentView extends StatefulWidget {
  final ContentItem content;
  final bool isDownloading;
  final double downloadProgress;
  final VoidCallback onDownload;
  final VoidCallback onCancel;

  const _VideoContentView({
    required this.content,
    required this.isDownloading,
    required this.downloadProgress,
    required this.onDownload,
    required this.onCancel,
  });

  @override
  State<_VideoContentView> createState() => _VideoContentViewState();
}

class _VideoContentViewState extends State<_VideoContentView> {
  VideoPlayerController? _videoController;
  ChewieController? _chewieController;
  bool _isInitialized = false;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _initializeVideo();
  }

  Future<void> _initializeVideo() async {
    try {
      // Play from local file if downloaded, otherwise stream
      if (widget.content.isDownloaded && widget.content.localFilePath != null) {
        _videoController = VideoPlayerController.file(File(widget.content.localFilePath!));
      } else {
        _videoController = VideoPlayerController.networkUrl(Uri.parse(widget.content.videoUrl ?? ''));
      }

      await _videoController!.initialize();

      _chewieController = ChewieController(
        videoPlayerController: _videoController!,
        autoPlay: false,
        looping: false,
        allowFullScreen: true,
        materialProgressColors: ChewieProgressColors(
          playedColor: context.primaryColor,
          handleColor: context.primaryColor,
          backgroundColor: context.primaryColor.withOpacity(0.2),
          bufferedColor: context.primaryColor.withOpacity(0.4),
        ),
      );

      if (mounted) setState(() => _isInitialized = true);
    } catch (e) {
      debugPrint('Video error: $e');
      if (mounted) setState(() => _hasError = true);
    }
  }

  @override
  void dispose() {
    _chewieController?.dispose();
    _videoController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: context.errorColor),
            const SizedBox(height: 12),
            AppText(context.l.videoPlaybackError, style: TextStyle(color: context.textColor)),
          ],
        ),
      );
    }

    if (!_isInitialized) {
      return Center(child: CircularProgressIndicator(color: context.primaryColor));
    }

    return Column(
      children: [
        // Video player
        Expanded(
          child: _chewieController != null
              ? Chewie(controller: _chewieController!)
              : const SizedBox.shrink(),
        ),
        
        // Download section
        if (!widget.content.isDownloaded)
          Container(
            padding: const EdgeInsets.all(16),
            child: widget.isDownloading
                ? Column(
                    children: [
                      LinearProgressIndicator(
                        value: widget.downloadProgress > 0 ? widget.downloadProgress : null,
                        backgroundColor: context.primaryColor.withOpacity(0.2),
                        valueColor: AlwaysStoppedAnimation(context.primaryColor),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          AppText('${(widget.downloadProgress * 100).toInt()}%'),
                          const SizedBox(width: 16),
                          TextButton(onPressed: widget.onCancel, child: AppText(context.l.cancel)),
                        ],
                      ),
                    ],
                  )
                : TextButton.icon(
                    onPressed: widget.onDownload,
                    icon: const Icon(Icons.download),
                    label: AppText(context.l.downloadVideo),
                  ),
          )
        else
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.download_done, size: 14, color: context.primaryColor),
                const SizedBox(width: 4),
                AppText(context.l.offline, style: TextStyle(fontSize: 12, color: context.primaryColor)),
              ],
            ),
          ),
      ],
    );
  }
}
