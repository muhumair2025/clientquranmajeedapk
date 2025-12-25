import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import '../themes/app_theme.dart';
import '../localization/app_localizations_extension.dart';
import '../services/lughat_service.dart';
import '../services/tafseer_service.dart';
import '../services/faidi_service.dart';
import '../services/common_models.dart';
import '../providers/font_provider.dart';

enum PlaybackMode { single, sequential, repeat }

class BulkAudioPlayerScreen extends StatefulWidget {
  final int initialSurahIndex;
  final int initialAyahIndex;
  final String surahName;
  final String sectionType; // lughat, tafseer, or faidi

  const BulkAudioPlayerScreen({
    super.key,
    required this.initialSurahIndex,
    required this.initialAyahIndex,
    required this.surahName,
    this.sectionType = 'lughat', // Default to lughat for backward compatibility
  });

  @override
  State<BulkAudioPlayerScreen> createState() => _BulkAudioPlayerScreenState();
}

class _BulkAudioPlayerScreenState extends State<BulkAudioPlayerScreen> 
    with TickerProviderStateMixin {
  late AudioPlayer _audioPlayer;
  bool _isPlaying = false;
  bool _isLoading = false;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;
  
  // Playback settings
  int _fromSurahIndex = 1;
  int _fromAyahIndex = 1;
  int _toSurahIndex = 1;
  int _toAyahIndex = 1;
  int _currentSurahIndex = 1;
  int _currentAyahIndex = 1;
  PlaybackMode _playbackMode = PlaybackMode.sequential;
  bool _autoPlayNext = true;
  
  // Animation controllers
  late AnimationController _rotationController;
  
  // Download related
  DownloadStatus _downloadStatus = DownloadStatus.notStarted;
  double _downloadProgress = 0.0;
  String? _localFilePath;
  
  // UI state
  bool _showSettings = false;
  List<Map<String, dynamic>> _availableAyahs = [];
  bool _isLoadingAyahs = true;

  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();
    
    // Initialize with passed values
    _fromSurahIndex = widget.initialSurahIndex;
    _fromAyahIndex = widget.initialAyahIndex;
    _toSurahIndex = widget.initialSurahIndex;
    _toAyahIndex = widget.initialAyahIndex;
    _currentSurahIndex = widget.initialSurahIndex;
    _currentAyahIndex = widget.initialAyahIndex;
    
    // Initialize animations
    _rotationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    
    _setupAudioPlayer();
    _loadSettings();
    _loadAvailableAyahs();
  }

  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Load saved settings
      final savedFromAyah = prefs.getInt('bulk_audio_from_ayah') ?? _fromAyahIndex;
      final savedToAyah = prefs.getInt('bulk_audio_to_ayah') ?? _toAyahIndex;
      final savedPlaybackMode = prefs.getInt('bulk_audio_playback_mode') ?? PlaybackMode.sequential.index;
      final savedAutoPlayNext = prefs.getBool('bulk_audio_auto_play_next') ?? true;
      
      setState(() {
        _fromAyahIndex = savedFromAyah;
        _toAyahIndex = savedToAyah;
        _currentAyahIndex = _fromAyahIndex; // Start from the selected "from" ayah
        _playbackMode = PlaybackMode.values[savedPlaybackMode];
        _autoPlayNext = savedAutoPlayNext;
      });
      
      debugPrint('Loaded settings: from=$_fromAyahIndex, to=$_toAyahIndex, current=$_currentAyahIndex');
      
      // Start auto play after loading settings
      _startAutoPlay();
    } catch (e) {
      debugPrint('Error loading settings: $e');
      // If settings loading fails, start with default values
      _startAutoPlay();
    }
  }

  Future<void> _saveSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      await prefs.setInt('bulk_audio_from_ayah', _fromAyahIndex);
      await prefs.setInt('bulk_audio_to_ayah', _toAyahIndex);
      await prefs.setInt('bulk_audio_playback_mode', _playbackMode.index);
      await prefs.setBool('bulk_audio_auto_play_next', _autoPlayNext);
      
      debugPrint('Settings saved: from=$_fromAyahIndex, to=$_toAyahIndex, mode=$_playbackMode, auto=$_autoPlayNext');
    } catch (e) {
      debugPrint('Error saving settings: $e');
    }
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    _rotationController.dispose();
    super.dispose();
  }

  void _setupAudioPlayer() {
    _audioPlayer.onPlayerStateChanged.listen((state) {
      if (mounted) {
        setState(() {
          _isPlaying = state == PlayerState.playing;
          _isLoading = state == PlayerState.playing && _position == Duration.zero;
        });
        
        if (state == PlayerState.playing) {
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

    _audioPlayer.onPlayerComplete.listen((_) {
      if (_autoPlayNext && _playbackMode == PlaybackMode.sequential) {
        _playNextAyah();
      } else if (_playbackMode == PlaybackMode.repeat) {
        _playCurrentAyah();
      }
    });
  }

  // Helper methods to use appropriate service based on section type
  Future<bool> _hasAudioData(int surahIndex, int ayahIndex) async {
    switch (widget.sectionType) {
      case 'lughat':
        return await LughatService.hasAudioData(surahIndex, ayahIndex);
      case 'tafseer':
        return await TafseerService.hasAudioData(surahIndex, ayahIndex);
      case 'faidi':
        return await FaidiService.hasAudioData(surahIndex, ayahIndex);
      default:
        return await LughatService.hasAudioData(surahIndex, ayahIndex);
    }
  }

  Future<dynamic> _getAudioData(int surahIndex, int ayahIndex) async {
    switch (widget.sectionType) {
      case 'lughat':
        return await LughatService.getAudioData(surahIndex, ayahIndex);
      case 'tafseer':
        return await TafseerService.getAudioData(surahIndex, ayahIndex);
      case 'faidi':
        return await FaidiService.getAudioData(surahIndex, ayahIndex);
      default:
        return await LughatService.getAudioData(surahIndex, ayahIndex);
    }
  }

  DownloadStatus _getDownloadStatus(int surahIndex, int ayahIndex) {
    switch (widget.sectionType) {
      case 'lughat':
        return LughatService.getDownloadStatus(surahIndex, ayahIndex, LughatType.audio);
      case 'tafseer':
        return TafseerService.getDownloadStatus(surahIndex, ayahIndex, TafseerType.audio);
      case 'faidi':
        return FaidiService.getDownloadStatus(surahIndex, ayahIndex, FaidiType.audio);
      default:
        return LughatService.getDownloadStatus(surahIndex, ayahIndex, LughatType.audio);
    }
  }

  double _getDownloadProgress(int surahIndex, int ayahIndex) {
    switch (widget.sectionType) {
      case 'lughat':
        return LughatService.getDownloadProgress(surahIndex, ayahIndex, LughatType.audio);
      case 'tafseer':
        return TafseerService.getDownloadProgress(surahIndex, ayahIndex, TafseerType.audio);
      case 'faidi':
        return FaidiService.getDownloadProgress(surahIndex, ayahIndex, FaidiType.audio);
      default:
        return LughatService.getDownloadProgress(surahIndex, ayahIndex, LughatType.audio);
    }
  }

  Future<String?> _getLocalFilePath(int surahIndex, int ayahIndex) async {
    switch (widget.sectionType) {
      case 'lughat':
        return await LughatService.getLocalFilePath(surahIndex, ayahIndex, LughatType.audio);
      case 'tafseer':
        return await TafseerService.getLocalFilePath(surahIndex, ayahIndex, TafseerType.audio);
      case 'faidi':
        return await FaidiService.getLocalFilePath(surahIndex, ayahIndex, FaidiType.audio);
      default:
        return await LughatService.getLocalFilePath(surahIndex, ayahIndex, LughatType.audio);
    }
  }

  Future<String> _downloadFile(int surahIndex, int ayahIndex, Function(double) onProgress, Function(String) onError) async {
    switch (widget.sectionType) {
      case 'lughat':
        return await LughatService.downloadFile(surahIndex, ayahIndex, LughatType.audio, onProgress, onError);
      case 'tafseer':
        return await TafseerService.downloadFile(surahIndex, ayahIndex, TafseerType.audio, onProgress, onError);
      case 'faidi':
        return await FaidiService.downloadFile(surahIndex, ayahIndex, FaidiType.audio, onProgress, onError);
      default:
        return await LughatService.downloadFile(surahIndex, ayahIndex, LughatType.audio, onProgress, onError);
    }
  }

  void _pauseDownload(int surahIndex, int ayahIndex) {
    switch (widget.sectionType) {
      case 'lughat':
        LughatService.pauseDownload(surahIndex, ayahIndex, LughatType.audio);
        break;
      case 'tafseer':
        TafseerService.pauseDownload(surahIndex, ayahIndex, TafseerType.audio);
        break;
      case 'faidi':
        FaidiService.pauseDownload(surahIndex, ayahIndex, FaidiType.audio);
        break;
      default:
        LughatService.pauseDownload(surahIndex, ayahIndex, LughatType.audio);
        break;
    }
  }

  Future<void> _resumeDownload(int surahIndex, int ayahIndex, Function(double) onProgress, Function(String) onError) async {
    switch (widget.sectionType) {
      case 'lughat':
        await LughatService.resumeDownload(surahIndex, ayahIndex, LughatType.audio, onProgress, onError);
        break;
      case 'tafseer':
        await TafseerService.resumeDownload(surahIndex, ayahIndex, TafseerType.audio, onProgress, onError);
        break;
      case 'faidi':
        await FaidiService.resumeDownload(surahIndex, ayahIndex, FaidiType.audio, onProgress, onError);
        break;
      default:
        await LughatService.resumeDownload(surahIndex, ayahIndex, LughatType.audio, onProgress, onError);
        break;
    }
  }

  Future<void> _deleteDownload(int surahIndex, int ayahIndex) async {
    switch (widget.sectionType) {
      case 'lughat':
        await LughatService.deleteDownload(surahIndex, ayahIndex, LughatType.audio);
        break;
      case 'tafseer':
        await TafseerService.deleteDownload(surahIndex, ayahIndex, TafseerType.audio);
        break;
      case 'faidi':
        await FaidiService.deleteDownload(surahIndex, ayahIndex, FaidiType.audio);
        break;
      default:
        await LughatService.deleteDownload(surahIndex, ayahIndex, LughatType.audio);
        break;
    }
  }

  Future<void> _loadAvailableAyahs() async {
    setState(() {
      _isLoadingAyahs = true;
    });

    List<Map<String, dynamic>> ayahs = [];
    
    // Load ayahs for the current surah
    for (int i = 1; i <= 286; i++) { // Assuming max ayahs in any surah
      try {
        final hasAudio = await _hasAudioData(_fromSurahIndex, i);
        if (hasAudio) {
          ayahs.add({
            'surahIndex': _fromSurahIndex,
            'ayahIndex': i,
            'hasAudio': true,
          });
        }
      } catch (e) {
        debugPrint('Error checking audio data for ${_fromSurahIndex}_$i: $e');
      }
    }

    setState(() {
      _availableAyahs = ayahs;
      _isLoadingAyahs = false;
      if (ayahs.isNotEmpty) {
        _toAyahIndex = ayahs.last['ayahIndex'];
      }
    });
  }

  Future<void> _startAutoPlay() async {
    await _checkDownloadStatus();
    await _playCurrentAyah();
  }

  Future<void> _checkDownloadStatus() async {
    final status = _getDownloadStatus(_currentSurahIndex, _currentAyahIndex);
    final progress = _getDownloadProgress(_currentSurahIndex, _currentAyahIndex);
    
    setState(() {
      _downloadStatus = status;
      _downloadProgress = progress;
    });
    
    if (_downloadStatus == DownloadStatus.completed) {
      final localPath = await _getLocalFilePath(_currentSurahIndex, _currentAyahIndex);
      if (mounted && localPath != null) {
        setState(() {
          _localFilePath = localPath;
        });
      }
    }
  }

  Future<void> _playCurrentAyah() async {
    await _checkDownloadStatus(); // Check download status for current ayah
    
    try {
      final audioData = await _getAudioData(_currentSurahIndex, _currentAyahIndex);
      if (audioData != null) {
        try {
          setState(() {
            _isLoading = true;
          });
          
          // Use local file if available, otherwise stream
          if (_localFilePath != null) {
            debugPrint('Playing local audio file: $_localFilePath');
            await _audioPlayer.play(DeviceFileSource(_localFilePath!));
          } else {
            debugPrint('Streaming audio from URL: ${audioData.content}');
            await _audioPlayer.play(UrlSource(audioData.content));
          }
        } catch (e) {
          debugPrint('Audio playback error: $e');
          _showError('Audio playback error: $e');
        }
      } else {
        _showError(context.l.vocabularyAudioNotAvailable);
      }
    } catch (e) {
      debugPrint('Error getting audio data: $e');
      _showError('Error loading audio: $e');
    }
  }

  void _playNextAyah() {
    if (_currentAyahIndex < _toAyahIndex) {
      setState(() {
        _currentAyahIndex++;
      });
      _playCurrentAyah();
    } else if (_currentSurahIndex < _toSurahIndex) {
      setState(() {
        _currentSurahIndex++;
        _currentAyahIndex = _fromAyahIndex;
      });
      _playCurrentAyah();
    } else {
      // Reached end
      if (_playbackMode == PlaybackMode.repeat) {
        setState(() {
          _currentSurahIndex = _fromSurahIndex;
          _currentAyahIndex = _fromAyahIndex;
        });
        _playCurrentAyah();
      } else {
        // Stop playing if not in repeat mode
        _audioPlayer.stop();
      }
    }
  }

  void _playPreviousAyah() {
    if (_currentAyahIndex > _fromAyahIndex) {
      setState(() {
        _currentAyahIndex--;
      });
      _playCurrentAyah();
    } else if (_currentSurahIndex > _fromSurahIndex) {
      setState(() {
        _currentSurahIndex--;
        _currentAyahIndex = _toAyahIndex;
      });
      _playCurrentAyah();
    }
    // If we're at the very beginning, don't do anything
  }

  Future<void> _playPause() async {
    try {
      if (_isPlaying) {
        await _audioPlayer.pause();
      } else {
        if (_position == Duration.zero) {
          await _playCurrentAyah();
        } else {
          await _audioPlayer.resume();
        }
      }
    } catch (e) {
      _showError('Playback error: $e');
    }
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showSuccessSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: AppTheme.primaryGreen,
        ),
      );
    }
  }

  Future<void> _startDownload() async {
    setState(() {
      _downloadStatus = DownloadStatus.downloading;
    });

    try {
      final localPath = await _downloadFile(
        _currentSurahIndex,
        _currentAyahIndex,
        (progress) {
          if (mounted) {
            setState(() {
              _downloadProgress = progress;
              
              if (progress >= 1.0) {
                _downloadStatus = DownloadStatus.completed;
              }
            });
            
            if (progress >= 1.0) {
              _showSuccessSnackBar(context.l.audioDownloadSuccess);
              
              _getLocalFilePath(_currentSurahIndex, _currentAyahIndex).then((localPath) {
                if (mounted && localPath != null) {
                  setState(() {
                    _localFilePath = localPath;
                  });
                }
              });
            }
          }
        },
        (error) {
          // Don't show error if download was cancelled by user
          if (error.toLowerCase().contains('cancelled') || 
              error.toLowerCase().contains('canceled')) {
            debugPrint('Download cancelled by user - not showing error');
            return;
          }
          
          if (mounted) {
            _showError('${context.l.downloadError}: $error');
          }
        },
      );

      if (mounted) {
        setState(() {
          _downloadStatus = DownloadStatus.completed;
          _localFilePath = localPath;
          _downloadProgress = 1.0;
        });
        
        if (_downloadProgress < 1.0) {
          _showSuccessSnackBar(context.l.audioDownloadSuccess);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _downloadStatus = DownloadStatus.failed;
        });
        _showError('${context.l.downloadError}: $e');
      }
    }
  }

  void _pauseDownloadCurrent() {
    try {
      _pauseDownload(_currentSurahIndex, _currentAyahIndex);
      if (mounted) {
        setState(() {
          _downloadStatus = DownloadStatus.paused;
          _downloadProgress = 0.0; // Reset progress
        });
        _showSuccessSnackBar(context.l.downloadCancelledStatus);
      }
    } catch (e) {
      debugPrint('Error stopping download: $e');
    }
  }

  Future<void> _resumeDownloadCurrent() async {
    setState(() {
      _downloadStatus = DownloadStatus.downloading;
    });

    try {
      await _resumeDownload(
        _currentSurahIndex,
        _currentAyahIndex,
        (progress) {
          if (mounted) {
            setState(() {
              _downloadProgress = progress;
              
              if (progress >= 1.0) {
                _downloadStatus = DownloadStatus.completed;
              }
            });
            
            if (progress >= 1.0) {
              _showSuccessSnackBar(context.l.audioDownloadSuccess);
              
              _getLocalFilePath(_currentSurahIndex, _currentAyahIndex).then((localPath) {
                if (mounted && localPath != null) {
                  setState(() {
                    _localFilePath = localPath;
                  });
                }
              });
            }
          }
        },
        (error) {
          // Don't show error if download was cancelled by user
          if (error.toLowerCase().contains('cancelled') || 
              error.toLowerCase().contains('canceled')) {
            debugPrint('Download cancelled by user - not showing error');
            return;
          }
          
          if (mounted) {
            _showError('${context.l.downloadError}: $error');
          }
        },
      );
    } catch (e) {
      if (mounted) {
        setState(() {
          _downloadStatus = DownloadStatus.failed;
        });
        _showError('${context.l.downloadError}: $e');
      }
    }
  }

  Future<void> _deleteDownloadCurrent() async {
    try {
      await _deleteDownload(_currentSurahIndex, _currentAyahIndex);
      setState(() {
        _downloadStatus = DownloadStatus.notStarted;
        _downloadProgress = 0.0;
        _localFilePath = null;
      });
      _showSuccessSnackBar(context.l.fileDeletedSuccess);
    } catch (e) {
      _showError('Delete error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Consumer<FontProvider>(
      builder: (context, fontProvider, child) {
        return Scaffold(
          backgroundColor: isDark ? AppTheme.darkBackground : AppTheme.lightBackground,
          appBar: AppBar(
            title: Text(
              context.l.bulkAudioPlayer,
              style: TextStyle(
                fontFamily: fontProvider.selectedFontOption.family,
              ),
            ),
            backgroundColor: AppTheme.primaryGreen,
            foregroundColor: Colors.white,
            actions: [
              IconButton(
                icon: const Icon(Icons.settings_rounded),
                onPressed: () => _showSettingsModal(isDark, fontProvider),
              ),
            ],
          ),
          body: _buildPlayerArea(isDark, fontProvider),
        );
      },
    );
  }

  void _showSettingsModal(bool isDark, FontProvider fontProvider) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (BuildContext context, StateSetter setModalState) {
          return Container(
            margin: const EdgeInsets.all(16),
            height: MediaQuery.of(context).size.height * 0.5,
            decoration: BoxDecoration(
              color: isDark ? AppTheme.darkSurface : Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: _buildSettingsContent(isDark, fontProvider, setModalState),
          );
        },
      ),
    );
  }

  Widget _buildSettingsContent(bool isDark, FontProvider fontProvider, StateSetter setModalState) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Settings Header
            Text(
              context.l.playbackSettings,
              style: context.textStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryGreen,
              ),
              textAlign: TextAlign.right,
              textDirection: TextDirection.rtl,
            ),
            const SizedBox(height: 12),
            
            // From/To Selection - More compact with instant update
            Row(
              textDirection: TextDirection.rtl,
              children: [
                Expanded(
                  child: _buildAyahSelector(
                    label: context.l.fromAyah,
                    value: _fromAyahIndex,
                    onTap: () => _showAyahSelector(true, setModalState),
                    isDark: isDark,
                    fontProvider: fontProvider,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildAyahSelector(
                    label: context.l.toAyah,
                    value: _toAyahIndex,
                    onTap: () => _showAyahSelector(false, setModalState),
                    isDark: isDark,
                    fontProvider: fontProvider,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Playback Mode - Compact chips with instant update
            Row(
              textDirection: TextDirection.rtl,
              children: PlaybackMode.values.map((mode) {
                final isSelected = _playbackMode == mode;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _playbackMode = mode;
                        });
                        setModalState(() {
                          _playbackMode = mode;
                        });
                        _saveSettings();
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: isSelected 
                              ? AppTheme.primaryGreen 
                              : (isDark ? AppTheme.darkBackground : AppTheme.lightGray),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isSelected 
                                ? AppTheme.primaryGreen 
                                : AppTheme.primaryGreen.withValues(alpha: 0.2),
                            width: isSelected ? 2 : 1.5,
                          ),
                          boxShadow: isSelected ? [
                            BoxShadow(
                              color: AppTheme.primaryGreen.withValues(alpha: 0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ] : null,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              _getPlaybackModeIcon(mode),
                              size: 16,
                              color: isSelected ? Colors.white : (isDark ? Colors.white70 : Colors.black54),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _getPlaybackModeText(mode),
                              textAlign: TextAlign.center,
                              style: context.textStyle(
                                fontSize: 12,
                                color: isSelected ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            
            const SizedBox(height: 12),
            
            // Auto play next toggle - Compact with instant update
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isDark 
                    ? AppTheme.primaryGreen.withOpacity(_autoPlayNext ? 0.15 : 0.08)
                    : AppTheme.primaryGreen.withOpacity(_autoPlayNext ? 0.1 : 0.05),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: AppTheme.primaryGreen.withOpacity(_autoPlayNext ? 0.4 : 0.2),
                  width: _autoPlayNext ? 2 : 1,
                ),
              ),
              child: Row(
                textDirection: TextDirection.rtl,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Switch(
                    value: _autoPlayNext,
                    onChanged: (value) {
                      setState(() {
                        _autoPlayNext = value;
                      });
                      setModalState(() {
                        _autoPlayNext = value;
                      });
                      _saveSettings();
                    },
                    activeColor: AppTheme.primaryGreen,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      textDirection: TextDirection.rtl,
                      children: [
                        Icon(
                          _autoPlayNext ? Icons.playlist_play_rounded : Icons.block_rounded,
                          size: 18,
                          color: AppTheme.primaryGreen,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          context.l.autoPlayNext,
                          style: context.textStyle(
                            fontSize: 13,
                            color: AppTheme.primaryGreen,
                            fontWeight: FontWeight.w600,
                          ),
                          textAlign: TextAlign.right,
                          textDirection: TextDirection.rtl,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAyahSelector({
    required String label,
    required int value,
    required VoidCallback onTap,
    required bool isDark,
    required FontProvider fontProvider,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: isDark 
              ? AppTheme.primaryGreen.withOpacity(0.08)
              : AppTheme.primaryGreen.withOpacity(0.05),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: AppTheme.primaryGreen.withOpacity(0.3),
            width: 1.5,
          ),
        ),
        child: Row(
          textDirection: TextDirection.rtl,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Icon(
              Icons.arrow_drop_down_rounded,
              size: 22,
              color: AppTheme.primaryGreen,
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    label,
                    style: context.textStyle(
                      fontSize: 11,
                      color: isDark ? Colors.white60 : Colors.grey[600],
                    ),
                    textAlign: TextAlign.right,
                    textDirection: TextDirection.rtl,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${context.l.ayah} $value',
                    style: context.textStyle(
                      fontSize: 13,
                      color: AppTheme.primaryGreen,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.right,
                    textDirection: TextDirection.rtl,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlayerArea(bool isDark, FontProvider fontProvider) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          // Current Ayah Info
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDark ? AppTheme.darkSurface : Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                Text(
                  widget.surahName,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryGreen,
                    fontFamily: fontProvider.selectedFontOption.family,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  '${context.l.ayah} $_currentAyahIndex',
                  style: TextStyle(
                    fontSize: 16,
                    color: isDark ? Colors.white70 : Colors.grey[600],
                    fontFamily: fontProvider.selectedFontOption.family,
                  ),
                ),
                const SizedBox(height: 16),
                
                // Static Audio Visualizer (Fixed height)
                Container(
                  height: 40, // Fixed height to prevent layout jumping
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 2),
                        width: 4,
                        height: _isPlaying 
                            ? (20 + (index % 3) * 10).toDouble()
                            : 20,
                        decoration: BoxDecoration(
                          color: AppTheme.primaryGreen.withValues(
                            alpha: _isPlaying ? 0.8 : 0.3,
                          ),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      );
                    }),
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 32),
          
          // Progress Slider
          Column(
            children: [
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  activeTrackColor: AppTheme.primaryGreen,
                  inactiveTrackColor: AppTheme.primaryGreen.withValues(alpha: 0.3),
                  thumbColor: AppTheme.primaryGreen,
                  overlayColor: AppTheme.primaryGreen.withValues(alpha: 0.2),
                  trackHeight: 4,
                ),
                child: Slider(
                  value: _duration.inSeconds > 0 
                      ? _position.inSeconds.toDouble().clamp(0, _duration.inSeconds.toDouble())
                      : 0,
                  max: _duration.inSeconds.toDouble(),
                  onChanged: (value) async {
                    final position = Duration(seconds: value.toInt());
                    await _audioPlayer.seek(position);
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _formatDuration(_position),
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.white70 : Colors.grey[600],
                        fontFamily: fontProvider.selectedFontOption.family,
                      ),
                    ),
                    Text(
                      _formatDuration(_duration),
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.white70 : Colors.grey[600],
                        fontFamily: fontProvider.selectedFontOption.family,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 32),
          
          // Control Buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
                      // Previous Ayah
              IconButton(
                onPressed: _currentAyahIndex > _fromAyahIndex || _currentSurahIndex > _fromSurahIndex
                    ? _playPreviousAyah
                    : null,
                icon: const Icon(Icons.skip_previous_rounded),
                iconSize: 36,
                color: (_currentAyahIndex > _fromAyahIndex || _currentSurahIndex > _fromSurahIndex)
                    ? AppTheme.primaryGreen
                    : Colors.grey[400],
              ),
              
              // Seek Backward
              IconButton(
                onPressed: () async {
                  final newPosition = _position - const Duration(seconds: 10);
                  final seekPosition = newPosition < Duration.zero ? Duration.zero : newPosition;
                  await _audioPlayer.seek(seekPosition);
                },
                icon: const Icon(Icons.replay_10_rounded),
                iconSize: 32,
                color: AppTheme.primaryGreen,
              ),
              
              // Play/Pause
              Container(
                decoration: BoxDecoration(
                  color: AppTheme.primaryGreen,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryGreen.withValues(alpha: 0.3),
                      blurRadius: 12,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: _isLoading
                    ? Container(
                        width: 64,
                        height: 64,
                        padding: const EdgeInsets.all(20),
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : IconButton(
                        onPressed: _playPause,
                        icon: AnimatedRotation(
                          turns: _isPlaying ? 1 : 0,
                          duration: const Duration(milliseconds: 300),
                          child: Icon(
                            _isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                            color: Colors.white,
                          ),
                        ),
                        iconSize: 32,
                      ),
              ),
              
              // Seek Forward
              IconButton(
                onPressed: () async {
                  final newPosition = _position + const Duration(seconds: 10);
                  final seekPosition = newPosition > _duration ? _duration : newPosition;
                  await _audioPlayer.seek(seekPosition);
                },
                icon: const Icon(Icons.forward_10_rounded),
                iconSize: 32,
                color: AppTheme.primaryGreen,
              ),
              
              // Next Ayah
              IconButton(
                onPressed: _currentAyahIndex < _toAyahIndex || _currentSurahIndex < _toSurahIndex
                    ? _playNextAyah
                    : null,
                icon: const Icon(Icons.skip_next_rounded),
                iconSize: 36,
                color: (_currentAyahIndex < _toAyahIndex || _currentSurahIndex < _toSurahIndex)
                    ? AppTheme.primaryGreen
                    : Colors.grey[400],
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Download Section
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isDark 
                  ? AppTheme.primaryGreen.withOpacity(0.08)
                  : AppTheme.primaryGreen.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppTheme.primaryGreen.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Row(
              textDirection: TextDirection.rtl,
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
                          color: AppTheme.primaryGreen,
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.right,
                        textDirection: TextDirection.rtl,
                      ),
                      if (_downloadStatus == DownloadStatus.downloading) ...[
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: _downloadProgress,
                            backgroundColor: AppTheme.primaryGreen.withOpacity(0.2),
                            valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primaryGreen),
                            minHeight: 6,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${(_downloadProgress * 100).toInt()}%',
                          style: context.textStyle(
                            fontSize: 11,
                            color: AppTheme.primaryGreen,
                          ),
                          textAlign: TextAlign.right,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          const Spacer(),
          
          // Queue Info
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? AppTheme.darkSurface : AppTheme.lightGray,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.l.playingRange,
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.white70 : Colors.grey[600],
                        fontFamily: fontProvider.selectedFontOption.family,
                      ),
                    ),
                    Text(
                      '${context.l.ayah} $_fromAyahIndex - $_toAyahIndex',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black,
                        fontFamily: fontProvider.selectedFontOption.family,
                      ),
                    ),
                  ],
                ),
                Icon(
                  _getPlaybackModeIcon(_playbackMode),
                  color: AppTheme.primaryGreen,
                  size: 20,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getPlaybackModeText(PlaybackMode mode) {
    switch (mode) {
      case PlaybackMode.single:
        return context.l.single;
      case PlaybackMode.sequential:
        return context.l.sequential;
      case PlaybackMode.repeat:
        return context.l.repeat;
    }
  }

  IconData _getPlaybackModeIcon(PlaybackMode mode) {
    switch (mode) {
      case PlaybackMode.single:
        return Icons.looks_one_rounded;
      case PlaybackMode.sequential:
        return Icons.playlist_play_rounded;
      case PlaybackMode.repeat:
        return Icons.repeat_rounded;
    }
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  void _showAyahSelector(bool isFrom, StateSetter? parentModalState) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Consumer<FontProvider>(
        builder: (context, fontProvider, child) {
          return Container(
            height: MediaQuery.of(context).size.height * 0.6,
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? AppTheme.darkSurface : Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                // Handle bar
                Container(
                  margin: const EdgeInsets.only(top: 12),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                
                // Header
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        isFrom ? context.l.fromAyah : context.l.toAyah,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black,
                          fontFamily: fontProvider.selectedFontOption.family,
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close_rounded),
                      ),
                    ],
                  ),
                ),
                
                // Quick Selection Buttons
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            setState(() {
                              if (isFrom) {
                                _fromAyahIndex = 1;
                                if (_toAyahIndex < _fromAyahIndex) {
                                  _toAyahIndex = _fromAyahIndex;
                                }
                                // Update current ayah to start from new "from" ayah
                                _currentAyahIndex = _fromAyahIndex;
                              } else {
                                _toAyahIndex = 1;
                              }
                            });
                            // Update parent modal instantly
                            if (parentModalState != null) {
                              parentModalState(() {});
                            }
                            _saveSettings(); // Save settings
                            Navigator.pop(context);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryGreen,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Text('${context.l.ayah} 1'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (!isFrom) // Only show for "to" selection
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              setState(() {
                                _toAyahIndex = _getMaxAyahForCurrentSurah();
                              });
                              // Update parent modal instantly
                              if (parentModalState != null) {
                                parentModalState(() {});
                              }
                              _saveSettings(); // Save settings
                              Navigator.pop(context);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryGold,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: Text('${context.l.ayah} ${_getMaxAyahForCurrentSurah()}'),
                          ),
                        ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Number input
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: TextField(
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: '${context.l.ayah} ${context.l.number}',
                      hintText: isFrom 
                          ? '1 - ${isFrom ? _toAyahIndex : _getMaxAyahForCurrentSurah()}'
                          : '$_fromAyahIndex - ${_getMaxAyahForCurrentSurah()}',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: AppTheme.primaryGreen),
                      ),
                    ),
                    onSubmitted: (value) {
                      final number = int.tryParse(value);
                      if (number != null) {
                        final maxAyah = _getMaxAyahForCurrentSurah();
                        
                        if (isFrom) {
                          if (number >= 1 && number <= _toAyahIndex) {
                            setState(() {
                              _fromAyahIndex = number;
                              // Update current ayah to start from new "from" ayah
                              _currentAyahIndex = _fromAyahIndex;
                            });
                            // Update parent modal instantly
                            if (parentModalState != null) {
                              parentModalState(() {});
                            }
                            _saveSettings(); // Save settings
                            Navigator.pop(context);
                          } else {
                            _showError('${context.l.ayah} number must be between 1 and $_toAyahIndex');
                          }
                        } else {
                          if (number >= _fromAyahIndex && number <= maxAyah) {
                            setState(() {
                              _toAyahIndex = number;
                            });
                            // Update parent modal instantly
                            if (parentModalState != null) {
                              parentModalState(() {});
                            }
                            _saveSettings(); // Save settings
                            Navigator.pop(context);
                          } else {
                            _showError('${context.l.ayah} number must be between $_fromAyahIndex and $maxAyah');
                          }
                        }
                      }
                    },
                  ),
                ),
                
                const SizedBox(height: 20),
                
                // Grid of ayah numbers
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: GridView.builder(
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 5,
                        childAspectRatio: 1.2,
                        crossAxisSpacing: 8,
                        mainAxisSpacing: 8,
                      ),
                      itemCount: _getMaxAyahForCurrentSurah(),
                      itemBuilder: (context, index) {
                        final ayahNumber = index + 1;
                        final isSelected = isFrom 
                            ? ayahNumber == _fromAyahIndex
                            : ayahNumber == _toAyahIndex;
                        final isEnabled = isFrom
                            ? ayahNumber <= _toAyahIndex
                            : ayahNumber >= _fromAyahIndex;
                        
                        return GestureDetector(
                          onTap: isEnabled ? () {
                            setState(() {
                              if (isFrom) {
                                _fromAyahIndex = ayahNumber;
                                // Update current ayah to start from new "from" ayah
                                _currentAyahIndex = _fromAyahIndex;
                              } else {
                                _toAyahIndex = ayahNumber;
                              }
                            });
                            // Update parent modal instantly
                            if (parentModalState != null) {
                              parentModalState(() {});
                            }
                            _saveSettings(); // Save settings
                            Navigator.pop(context);
                          } : null,
                          child: Container(
                            decoration: BoxDecoration(
                              color: isSelected 
                                  ? AppTheme.primaryGreen
                                  : isEnabled
                                      ? (isDark ? AppTheme.darkBackground : AppTheme.lightGray)
                                      : Colors.grey[300],
                              borderRadius: BorderRadius.circular(8),
                              border: isSelected ? null : Border.all(
                                color: AppTheme.primaryGreen.withValues(alpha: 0.3),
                              ),
                            ),
                            child: Center(
                              child: Text(
                                '$ayahNumber',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                  color: isSelected 
                                      ? Colors.white
                                      : isEnabled
                                          ? (isDark ? Colors.white : Colors.black)
                                          : Colors.grey[500],
                                  fontFamily: fontProvider.selectedFontOption.family,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                
                const SizedBox(height: 20),
              ],
            ),
          );
        },
      ),
    );
  }

  int _getMaxAyahForCurrentSurah() {
    // This is a simplified version. In a real app, you'd get this from your data
    // For now, returning a reasonable default
    final surahAyahCounts = {
      1: 7, 2: 286, 3: 200, 4: 176, 5: 120, 6: 165, 7: 206, 8: 75, 9: 129, 10: 109,
      11: 123, 12: 111, 13: 43, 14: 52, 15: 99, 16: 128, 17: 111, 18: 110, 19: 98, 20: 135,
      21: 112, 22: 78, 23: 118, 24: 64, 25: 77, 26: 227, 27: 93, 28: 88, 29: 69, 30: 60,
      31: 34, 32: 30, 33: 73, 34: 54, 35: 45, 36: 83, 37: 182, 38: 88, 39: 75, 40: 85,
      41: 54, 42: 53, 43: 89, 44: 59, 45: 37, 46: 35, 47: 38, 48: 29, 49: 18, 50: 45,
      51: 60, 52: 49, 53: 62, 54: 55, 55: 78, 56: 96, 57: 29, 58: 22, 59: 24, 60: 13,
      61: 14, 62: 11, 63: 11, 64: 18, 65: 12, 66: 12, 67: 30, 68: 52, 69: 52, 70: 44,
      71: 28, 72: 28, 73: 20, 74: 56, 75: 40, 76: 31, 77: 50, 78: 40, 79: 46, 80: 42,
      81: 29, 82: 19, 83: 36, 84: 25, 85: 22, 86: 17, 87: 19, 88: 26, 89: 30, 90: 20,
      91: 15, 92: 21, 93: 11, 94: 8, 95: 8, 96: 19, 97: 5, 98: 8, 99: 8, 100: 11,
      101: 11, 102: 8, 103: 3, 104: 9, 105: 5, 106: 4, 107: 7, 108: 3, 109: 6, 110: 3,
      111: 5, 112: 4, 113: 5, 114: 6
    };
    
    return surahAyahCounts[_currentSurahIndex] ?? 286; // Default to max if not found
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
          decoration: BoxDecoration(
            color: AppTheme.primaryGreen.withOpacity(0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: IconButton(
            onPressed: _startDownload,
            icon: const Icon(Icons.download_rounded),
            color: AppTheme.primaryGreen,
          ),
        );
      case DownloadStatus.downloading:
        return Container(
          decoration: BoxDecoration(
            color: Colors.orange.withOpacity(0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: IconButton(
            onPressed: _pauseDownloadCurrent,
            icon: const Icon(Icons.stop_rounded),
            color: Colors.orange,
          ),
        );
      case DownloadStatus.paused:
        return Container(
          decoration: BoxDecoration(
            color: AppTheme.primaryGreen.withOpacity(0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: IconButton(
            onPressed: _resumeDownloadCurrent,
            icon: const Icon(Icons.play_arrow_rounded),
            color: AppTheme.primaryGreen,
          ),
        );
      case DownloadStatus.completed:
        return Container(
          decoration: BoxDecoration(
            color: Colors.red.withOpacity(0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: IconButton(
            onPressed: _deleteDownloadCurrent,
            icon: const Icon(Icons.delete_rounded),
            color: Colors.red,
          ),
        );
    }
  }
}
