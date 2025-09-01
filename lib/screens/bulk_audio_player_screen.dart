import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import '../themes/app_theme.dart';
import '../localization/app_localizations_extension.dart';
import '../services/lughat_service.dart';
import '../providers/font_provider.dart';

enum PlaybackMode { single, sequential, repeat }

class BulkAudioPlayerScreen extends StatefulWidget {
  final int initialSurahIndex;
  final int initialAyahIndex;
  final String surahName;

  const BulkAudioPlayerScreen({
    super.key,
    required this.initialSurahIndex,
    required this.initialAyahIndex,
    required this.surahName,
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

  Future<void> _loadAvailableAyahs() async {
    setState(() {
      _isLoadingAyahs = true;
    });

    List<Map<String, dynamic>> ayahs = [];
    
    // For now, load ayahs for the current surah
    // In a real implementation, you'd load from your data source
    for (int i = 1; i <= 286; i++) { // Assuming max ayahs in any surah
      if (LughatService.hasAudioData(_fromSurahIndex, i)) {
        ayahs.add({
          'surahIndex': _fromSurahIndex,
          'ayahIndex': i,
          'hasAudio': true,
        });
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
    final status = LughatService.getDownloadStatus(_currentSurahIndex, _currentAyahIndex, LughatType.audio);
    final progress = LughatService.getDownloadProgress(_currentSurahIndex, _currentAyahIndex, LughatType.audio);
    
    setState(() {
      _downloadStatus = status;
      _downloadProgress = progress;
    });
    
    if (_downloadStatus == DownloadStatus.completed) {
      final localPath = await LughatService.getLocalFilePath(_currentSurahIndex, _currentAyahIndex, LughatType.audio);
      if (mounted && localPath != null) {
        setState(() {
          _localFilePath = localPath;
        });
      }
    }
  }

  Future<void> _playCurrentAyah() async {
    await _checkDownloadStatus(); // Check download status for current ayah
    
    final audioData = LughatService.getAudioData(_currentSurahIndex, _currentAyahIndex);
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
      final localPath = await LughatService.downloadFile(
        _currentSurahIndex,
        _currentAyahIndex,
        LughatType.audio,
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
              
              LughatService.getLocalFilePath(_currentSurahIndex, _currentAyahIndex, LughatType.audio).then((localPath) {
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

  void _pauseDownload() {
    LughatService.pauseDownload(_currentSurahIndex, _currentAyahIndex, LughatType.audio);
    setState(() {
      _downloadStatus = DownloadStatus.paused;
    });
  }

  Future<void> _resumeDownload() async {
    setState(() {
      _downloadStatus = DownloadStatus.downloading;
    });

    try {
      await LughatService.resumeDownload(
        _currentSurahIndex,
        _currentAyahIndex,
        LughatType.audio,
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
              
              LughatService.getLocalFilePath(_currentSurahIndex, _currentAyahIndex, LughatType.audio).then((localPath) {
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

  Future<void> _deleteDownload() async {
    try {
      await LughatService.deleteDownload(_currentSurahIndex, _currentAyahIndex, LughatType.audio);
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
                icon: Icon(_showSettings ? Icons.close : Icons.settings),
                onPressed: () {
                  setState(() {
                    _showSettings = !_showSettings;
                  });
                },
              ),
            ],
          ),
          body: Column(
            children: [
              // Settings Panel (collapsible)
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                height: _showSettings ? 300 : 0,
                child: _showSettings ? _buildSettingsPanel(isDark, fontProvider) : null,
              ),
              
              // Main Player Area
              Expanded(
                child: _buildPlayerArea(isDark, fontProvider),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSettingsPanel(bool isDark, FontProvider fontProvider) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.l.playbackSettings,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black,
              fontFamily: fontProvider.selectedFontOption.family,
            ),
          ),
          const SizedBox(height: 16),
          
          // From/To Selection
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.l.fromAyah,
                      style: TextStyle(
                        fontSize: 14,
                        color: isDark ? Colors.white70 : Colors.grey[600],
                        fontFamily: fontProvider.selectedFontOption.family,
                      ),
                    ),
                    const SizedBox(height: 4),
                    GestureDetector(
                      onTap: () => _showAyahSelector(true), // true for "from"
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        decoration: BoxDecoration(
                          color: isDark ? AppTheme.darkBackground : AppTheme.lightGray,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: AppTheme.primaryGreen.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                '${context.l.ayah} $_fromAyahIndex',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: isDark ? Colors.white : Colors.black,
                                  fontFamily: fontProvider.selectedFontOption.family,
                                ),
                              ),
                            ),
                            Icon(
                              Icons.arrow_drop_down_rounded,
                              size: 20,
                              color: AppTheme.primaryGreen,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.l.toAyah,
                      style: TextStyle(
                        fontSize: 14,
                        color: isDark ? Colors.white70 : Colors.grey[600],
                        fontFamily: fontProvider.selectedFontOption.family,
                      ),
                    ),
                    const SizedBox(height: 4),
                    GestureDetector(
                      onTap: () => _showAyahSelector(false), // false for "to"
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        decoration: BoxDecoration(
                          color: isDark ? AppTheme.darkBackground : AppTheme.lightGray,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: AppTheme.primaryGreen.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                '${context.l.ayah} $_toAyahIndex',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: isDark ? Colors.white : Colors.black,
                                  fontFamily: fontProvider.selectedFontOption.family,
                                ),
                              ),
                            ),
                            Icon(
                              Icons.arrow_drop_down_rounded,
                              size: 20,
                              color: AppTheme.primaryGreen,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Playback Mode
          Text(
            context.l.playbackMode,
            style: TextStyle(
              fontSize: 14,
              color: isDark ? Colors.white70 : Colors.grey[600],
              fontFamily: fontProvider.selectedFontOption.family,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: PlaybackMode.values.map((mode) {
              final isSelected = _playbackMode == mode;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _playbackMode = mode;
                      });
                      _saveSettings(); // Save settings
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected 
                            ? AppTheme.primaryGreen 
                            : (isDark ? AppTheme.darkBackground : AppTheme.lightGray),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isSelected 
                              ? AppTheme.primaryGreen 
                              : AppTheme.primaryGreen.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Text(
                        _getPlaybackModeText(mode),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          color: isSelected 
                              ? Colors.white 
                              : (isDark ? Colors.white : Colors.black),
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          fontFamily: fontProvider.selectedFontOption.family,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          
          const SizedBox(height: 16),
          
          // Auto play next toggle
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                context.l.autoPlayNext,
                style: TextStyle(
                  fontSize: 14,
                  color: isDark ? Colors.white : Colors.black,
                  fontFamily: fontProvider.selectedFontOption.family,
                ),
              ),
              Switch(
                value: _autoPlayNext,
                onChanged: (value) {
                  setState(() {
                    _autoPlayNext = value;
                  });
                  _saveSettings(); // Save settings
                },
                activeColor: AppTheme.primaryGreen,
              ),
            ],
          ),
        ],
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
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? AppTheme.darkSurface : Colors.white,
              borderRadius: BorderRadius.circular(12),
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
                Row(
                  children: [
                    Icon(
                      Icons.download_rounded,
                      color: AppTheme.primaryGreen,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _getDownloadStatusText(),
                        style: TextStyle(
                          fontSize: 14,
                          color: isDark ? Colors.white : Colors.black,
                          fontFamily: fontProvider.selectedFontOption.family,
                        ),
                      ),
                    ),
                    _buildDownloadButton(),
                  ],
                ),
                if (_downloadStatus == DownloadStatus.downloading)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: LinearProgressIndicator(
                      value: _downloadProgress,
                      backgroundColor: AppTheme.primaryGreen.withValues(alpha: 0.3),
                      valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryGreen),
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

  void _showAyahSelector(bool isFrom) {
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
        return IconButton(
          onPressed: _startDownload,
          icon: const Icon(Icons.download_rounded),
          color: AppTheme.primaryGreen,
        );
      case DownloadStatus.downloading:
        return IconButton(
          onPressed: _pauseDownload,
          icon: const Icon(Icons.pause_rounded),
          color: AppTheme.primaryGreen,
        );
      case DownloadStatus.paused:
        return IconButton(
          onPressed: _resumeDownload,
          icon: const Icon(Icons.play_arrow_rounded),
          color: AppTheme.primaryGreen,
        );
      case DownloadStatus.completed:
        return IconButton(
          onPressed: _deleteDownload,
          icon: const Icon(Icons.delete_rounded),
          color: Colors.red,
        );
    }
  }
}
